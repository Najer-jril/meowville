-- 003_rpc.sql

create function public.require_role(p_roles text[])
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Sesi berakhir, silakan login ulang';
  end if;
  if not (coalesce(public.my_role(), '') = any (p_roles)) then
    raise exception 'Akses ditolak';
  end if;
end;
$$;

-- Sisa unit per hari. p_type null berarti semua tipe kamar. p_end inklusif.
create function public.room_availability(p_type bigint, p_start date, p_end date)
returns table (
  room_type_id bigint,
  day date,
  units int,
  occupied int,
  pending int,
  blocked int
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    rt.id,
    d::date,
    rt.unit_count,
    (select count(*) from public.reservations r
      where r.room_type_id = rt.id and r.status in ('confirmed', 'checked_in')
        and r.check_in <= d and r.check_out > d)::int,
    (select count(*) from public.reservations r
      where r.room_type_id = rt.id and r.status = 'pending'
        and r.check_in <= d and r.check_out > d)::int,
    (select count(*) from public.unit_blocks b
      where b.room_type_id = rt.id and b.start_date <= d and b.end_date >= d)::int
  from public.room_types rt
  cross join generate_series(p_start, p_end, interval '1 day') as d
  where p_type is null or rt.id = p_type
  order by rt.id, d
$$;

create function public.create_reservation(
  p_cat bigint,
  p_type bigint,
  p_check_in date,
  p_check_out date,
  p_addons bigint[] default '{}',
  p_proof text default null
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_price int;
  v_left int;
  v_id bigint;
begin
  perform public.require_role(array['owner']);

  if p_check_out <= p_check_in then
    raise exception 'Tanggal check-out harus setelah check-in';
  end if;
  if p_check_in < public.today_wib() then
    raise exception 'Tanggal check-in sudah lewat';
  end if;
  if not exists (
    select 1 from public.cats
    where id = p_cat and owner_id = auth.uid() and not deleted
  ) then
    raise exception 'Data kucing tidak ditemukan';
  end if;

  -- Kunci baris tipe kamar supaya dua booking bersamaan diproses bergiliran
  select price into v_price from public.room_types
  where id = p_type and active
  for update;
  if v_price is null then
    raise exception 'Tipe kamar tidak tersedia';
  end if;

  if exists (
    select 1 from public.reservations
    where cat_id = p_cat
      and status in ('pending', 'confirmed', 'checked_in')
      and check_in < p_check_out and check_out > p_check_in
  ) then
    raise exception 'Kucing ini sudah punya reservasi di tanggal tersebut';
  end if;

  select min(a.units - a.occupied - a.pending - a.blocked) into v_left
  from public.room_availability(p_type, p_check_in, p_check_out - 1) a;
  if coalesce(v_left, 0) <= 0 then
    raise exception 'Kamar penuh di tanggal yang dipilih';
  end if;

  insert into public.reservations
    (cat_id, owner_id, room_type_id, check_in, check_out, room_price, payment_proof)
  values
    (p_cat, auth.uid(), p_type, p_check_in, p_check_out, v_price, p_proof)
  returning id into v_id;

  insert into public.reservation_addons (reservation_id, addon_id, price)
  select v_id, a.id, a.price
  from public.addons a
  where a.id = any (p_addons) and a.active;

  return v_id;
end;
$$;

create function public.cancel_reservation(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare r public.reservations;
begin
  perform public.require_role(array['owner', 'admin']);
  select * into r from public.reservations where id = p_id for update;
  if r.id is null or (public.my_role() = 'owner' and r.owner_id <> auth.uid()) then
    raise exception 'Reservasi tidak ditemukan';
  end if;
  if r.status not in ('pending', 'confirmed') then
    raise exception 'Reservasi dengan status ini tidak bisa dibatalkan';
  end if;
  update public.reservations set status = 'cancelled' where id = p_id;
end;
$$;

create function public.upload_payment_proof(p_id bigint, p_path text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_role(array['owner']);
  update public.reservations
  set payment_proof = p_path
  where id = p_id and owner_id = auth.uid() and status = 'pending';
  if not found then
    raise exception 'Bukti bayar hanya bisa diunggah untuk reservasi yang menunggu konfirmasi';
  end if;
end;
$$;

create function public.approve_reservation(p_id bigint, p_unit text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.reservations;
  t public.room_types;
  n int;
begin
  perform public.require_role(array['admin']);
  select * into r from public.reservations where id = p_id for update;
  if r.id is null then
    raise exception 'Reservasi tidak ditemukan';
  end if;
  if r.status <> 'pending' then
    raise exception 'Reservasi sudah diproses';
  end if;

  select * into t from public.room_types where id = r.room_type_id for update;
  if p_unit is null or p_unit !~ ('^' || t.prefix || '[0-9]+$') then
    raise exception 'Unit % tidak valid untuk tipe %', p_unit, t.name;
  end if;
  n := substring(p_unit from length(t.prefix) + 1)::int;
  if n < 1 or n > t.unit_count then
    raise exception 'Unit % tidak ada', p_unit;
  end if;

  if exists (
    select 1 from public.reservations x
    where x.room_type_id = r.room_type_id and x.unit = p_unit and x.id <> r.id
      and x.status in ('confirmed', 'checked_in')
      and x.check_in < r.check_out and x.check_out > r.check_in
  ) then
    raise exception 'Unit % sudah terisi di tanggal tersebut', p_unit;
  end if;
  if exists (
    select 1 from public.unit_blocks b
    where b.room_type_id = r.room_type_id and b.unit = p_unit
      and b.start_date < r.check_out and b.end_date >= r.check_in
  ) then
    raise exception 'Unit % sedang diblokir di tanggal tersebut', p_unit;
  end if;

  update public.reservations
  set status = 'confirmed', unit = p_unit
  where id = p_id;
end;
$$;

create function public.reject_reservation(p_id bigint, p_note text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_role(array['admin']);
  if coalesce(trim(p_note), '') = '' then
    raise exception 'Alasan penolakan wajib diisi';
  end if;
  update public.reservations
  set status = 'rejected', admin_note = trim(p_note)
  where id = p_id and status = 'pending';
  if not found then
    raise exception 'Reservasi sudah diproses';
  end if;
end;
$$;

create function public.check_in_reservation(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_role(array['sitter', 'admin']);
  update public.reservations
  set status = 'checked_in'
  where id = p_id and status = 'confirmed' and check_in <= public.today_wib();
  if not found then
    raise exception 'Check-in hanya untuk reservasi terkonfirmasi yang sudah masuk tanggalnya';
  end if;
end;
$$;

create function public.check_out_reservation(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_role(array['sitter', 'admin']);
  update public.reservations
  set status = 'completed'
  where id = p_id and status = 'checked_in';
  if not found then
    raise exception 'Kucing belum check-in';
  end if;
end;
$$;

create function public.add_unit_block(
  p_type bigint,
  p_unit text,
  p_start date,
  p_end date,
  p_reason text
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.reservations;
  v_id bigint;
begin
  perform public.require_role(array['admin']);
  if p_end < p_start then
    raise exception 'Tanggal selesai harus sama atau setelah tanggal mulai';
  end if;

  select * into r from public.reservations x
  where x.room_type_id = p_type and x.unit = p_unit
    and x.status in ('confirmed', 'checked_in')
    and x.check_in <= p_end and x.check_out > p_start
  order by x.check_in
  limit 1;
  if r.id is not null then
    raise exception 'Unit % punya reservasi pada % - %. Batalkan reservasinya terlebih dahulu.',
      p_unit, to_char(r.check_in, 'DD/MM'), to_char(r.check_out, 'DD/MM');
  end if;

  insert into public.unit_blocks (room_type_id, unit, start_date, end_date, reason)
  values (p_type, p_unit, p_start, p_end, coalesce(p_reason, ''))
  returning id into v_id;
  return v_id;
end;
$$;

create function public.delete_cat(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_role(array['owner']);
  if exists (
    select 1 from public.reservations
    where cat_id = p_id and status in ('pending', 'confirmed', 'checked_in')
  ) then
    raise exception 'Kucing masih punya reservasi aktif';
  end if;
  update public.cats set deleted = true
  where id = p_id and owner_id = auth.uid();
  if not found then
    raise exception 'Data kucing tidak ditemukan';
  end if;
end;
$$;

create function public.set_user_role(p_user uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_role(array['admin']);
  if p_user = auth.uid() then
    raise exception 'Tidak bisa mengubah role akun sendiri';
  end if;
  if p_role not in ('owner', 'admin', 'sitter') then
    raise exception 'Role tidak valid';
  end if;
  update public.profiles set role = p_role where id = p_user;
  if not found then
    raise exception 'Akun tidak ditemukan';
  end if;
end;
$$;

create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null then
    raise exception 'Sesi berakhir, silakan login ulang';
  end if;
  if exists (
    select 1 from public.reservations
    where owner_id = auth.uid() and status in ('pending', 'confirmed', 'checked_in')
  ) then
    raise exception 'Masih ada reservasi aktif. Batalkan atau selesaikan dulu.';
  end if;
  delete from auth.users where id = auth.uid();
end;
$$;

revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
