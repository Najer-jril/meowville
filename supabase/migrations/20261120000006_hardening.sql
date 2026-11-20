create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, name, email, role)
  values (
    new.id,
    left(coalesce(nullif(trim(new.raw_user_meta_data->>'name'), ''), split_part(new.email, '@', 1)), 100),
    new.email,
    'owner'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

alter table public.profiles drop column phone;

-- Pengaturan aplikasi (satu baris). Diubah admin lewat Supabase Dashboard.
create table public.app_settings (
  id boolean primary key default true check (id),
  demo_mode boolean not null default true,
  bank_name text not null default '',
  bank_account text not null default '',
  bank_holder text not null default '',
  support_email text not null default '',
  updated_at timestamptz not null default now()
);

insert into public.app_settings (demo_mode, bank_name, bank_account, bank_holder, support_email)
values (true, 'Bank Demo', '0000 0000 00', 'Meowville Demo', 'meowville@najer.dev');

alter table public.app_settings enable row level security;
-- Dibaca juga sebelum login (kontak support di layar lupa kata sandi).
create policy "settings read" on public.app_settings for select to anon, authenticated
  using (true);

-- Nama pelapor disimpan di laporan, supaya owner tidak perlu membaca profil staf
alter table public.daily_reports add column reporter_name text not null default '';

create function public.set_reporter_name()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.reporter_name := coalesce(
    (select name from public.profiles where id = new.reporter_id), '');
  return new;
end;
$$;

create trigger daily_reports_reporter_name
  before insert on public.daily_reports
  for each row execute function public.set_reporter_name();

update public.daily_reports d set reporter_name = p.name
from public.profiles p where p.id = d.reporter_id;

-- Guard kolom yang tidak boleh diubah lewat REST
create or replace function public.guard_profile_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is null then
    return new;
  end if;
  if new.email is distinct from old.email then
    raise exception 'Email tidak bisa diubah';
  end if;
  if new.joined_at is distinct from old.joined_at then
    raise exception 'Tanggal bergabung tidak bisa diubah';
  end if;
  if new.role is distinct from old.role and coalesce(public.my_role(), '') <> 'admin' then
    raise exception 'Role tidak bisa diubah';
  end if;
  return new;
end;
$$;

-- Kolom deleted hanya boleh diubah lewat RPC delete_cat, supaya cek
-- reservasi aktif tidak bisa dilewati dan kucing yang dihapus tidak bisa
-- dikembalikan lewat PATCH.
create function public.guard_cat_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if auth.uid() is not null
     and new.deleted is distinct from old.deleted
     and coalesce(current_setting('meowville.cat_delete', true), '') <> 'on' then
    raise exception 'Gunakan menu hapus kucing';
  end if;
  return new;
end;
$$;

create trigger cats_guard
  before update on public.cats
  for each row execute function public.guard_cat_update();

-- Batas data
alter table public.profiles add constraint profiles_name_len check (length(name) <= 100) not valid;
alter table public.cats add constraint cats_name_len check (length(name) <= 50) not valid;
alter table public.cats add constraint cats_breed_len check (length(breed) <= 50) not valid;
alter table public.cats add constraint cats_weight_max check (weight_kg <= 30) not valid;
alter table public.room_types add constraint room_types_name_len check (length(name) <= 50) not valid;
alter table public.room_types add constraint room_types_desc_len check (length(description) <= 500) not valid;
alter table public.addons add constraint addons_name_len check (length(name) <= 50) not valid;
alter table public.addons add constraint addons_desc_len check (length(description) <= 200) not valid;
alter table public.reservations add constraint reservations_price_nonneg check (room_price >= 0) not valid;
alter table public.reservation_addons add constraint reservation_addons_price_nonneg check (price >= 0) not valid;
alter table public.daily_reports add constraint daily_reports_note_len check (length(note) <= 500) not valid;

-- Index FK (advisor unindexed_foreign_keys)
create index reservations_cat_idx on public.reservations (cat_id);
create index reservation_addons_addon_idx on public.reservation_addons (addon_id);
create index daily_reports_reporter_idx on public.daily_reports (reporter_id);

-- Fungsi
alter function public.today_wib() set search_path = '';

-- Rentang dibatasi supaya tidak bisa dipakai untuk query sangat besar.
drop function public.room_availability(bigint, date, date);
create function public.room_availability(p_type bigint, p_start date, p_end date)
returns table (
  room_type_id bigint,
  day date,
  units int,
  occupied int,
  pending int,
  blocked int
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if p_end < p_start or p_end - p_start > 400 then
    raise exception 'Rentang tanggal tidak valid';
  end if;
  return query
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
  order by rt.id, d;
end;
$$;

-- Path bukti bayar harus file milik user sendiri di bucket payment-proofs.
create function public.valid_proof_path(p_path text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_path ~ ('^' || auth.uid()::text || '/[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$')
    and exists (
      select 1 from storage.objects
      where bucket_id = 'payment-proofs' and name = p_path
    )
$$;

create or replace function public.create_reservation(
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
  if p_check_in > public.today_wib() + 180 then
    raise exception 'Reservasi paling jauh 180 hari ke depan';
  end if;
  if p_check_out - p_check_in > 30 then
    raise exception 'Lama menginap maksimal 30 malam';
  end if;
  if p_proof is not null and not public.valid_proof_path(p_proof) then
    raise exception 'Bukti bayar tidak valid';
  end if;
  if not exists (
    select 1 from public.cats
    where id = p_cat and owner_id = auth.uid() and not deleted
  ) then
    raise exception 'Data kucing tidak ditemukan';
  end if;
  -- Reservasi pending ikut mengurangi kapasitas, jadi jumlahnya dibatasi
  -- supaya satu akun tidak bisa memblokir semua kamar.
  if (
    select count(*) from public.reservations
    where owner_id = auth.uid() and status = 'pending'
  ) >= 2 then
    raise exception 'Maksimal 2 reservasi menunggu konfirmasi. Selesaikan pembayaran atau batalkan salah satunya.';
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

create or replace function public.upload_payment_proof(p_id bigint, p_path text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_role(array['owner']);
  if not public.valid_proof_path(p_path) then
    raise exception 'Bukti bayar tidak valid';
  end if;
  update public.reservations
  set payment_proof = p_path
  where id = p_id and owner_id = auth.uid() and status = 'pending';
  if not found then
    raise exception 'Bukti bayar hanya bisa diunggah untuk reservasi yang menunggu konfirmasi';
  end if;
end;
$$;

-- Owner hanya membatalkan reservasi yang masih menunggu. Reservasi
-- terkonfirmasi dibatalkan admin (sesuai Ketentuan Layanan).
create or replace function public.cancel_reservation(p_id bigint)
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
  if public.my_role() = 'owner' and r.status <> 'pending' then
    raise exception 'Reservasi yang sudah dikonfirmasi dibatalkan melalui admin';
  end if;
  if r.status not in ('pending', 'confirmed') then
    raise exception 'Reservasi dengan status ini tidak bisa dibatalkan';
  end if;
  update public.reservations set status = 'cancelled' where id = p_id;
end;
$$;

create or replace function public.check_in_reservation(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_role(array['sitter', 'admin']);
  update public.reservations
  set status = 'checked_in'
  where id = p_id and status = 'confirmed'
    and check_in <= public.today_wib() and check_out > public.today_wib();
  if not found then
    raise exception 'Check-in hanya untuk reservasi terkonfirmasi yang sedang berjalan';
  end if;
end;
$$;

create or replace function public.add_unit_block(
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
  t public.room_types;
  n int;
  v_id bigint;
begin
  perform public.require_role(array['admin']);
  if p_end < p_start then
    raise exception 'Tanggal selesai harus sama atau setelah tanggal mulai';
  end if;

  select * into t from public.room_types where id = p_type for update;
  if t.id is null then
    raise exception 'Tipe kamar tidak ditemukan';
  end if;
  if p_unit is null or p_unit !~ ('^' || t.prefix || '[0-9]+$') then
    raise exception 'Unit % tidak valid untuk tipe %', p_unit, t.name;
  end if;
  n := substring(p_unit from length(t.prefix) + 1)::int;
  if n < 1 or n > t.unit_count then
    raise exception 'Unit % tidak ada', p_unit;
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
  values (p_type, p_unit, p_start, p_end, left(coalesce(p_reason, ''), 200))
  returning id into v_id;
  return v_id;
end;
$$;

-- Cek kepemilikan dulu supaya status reservasi kucing orang lain tidak bocor.
create or replace function public.delete_cat(p_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.require_role(array['owner']);
  if not exists (
    select 1 from public.cats
    where id = p_id and owner_id = auth.uid() and not deleted
  ) then
    raise exception 'Data kucing tidak ditemukan';
  end if;
  if exists (
    select 1 from public.reservations
    where cat_id = p_id and status in ('pending', 'confirmed', 'checked_in')
  ) then
    raise exception 'Kucing masih punya reservasi aktif';
  end if;
  perform set_config('meowville.cat_delete', 'on', true);
  update public.cats set deleted = true where id = p_id;
  perform set_config('meowville.cat_delete', 'off', true);
end;
$$;

-- Penghapusan akun sekarang dilakukan Edge Function `delete-account`
-- (menghapus file Storage lalu auth user). Fungsi ini hanya memeriksa
-- apakah akun boleh dihapus, dan dipanggil Edge Function atas nama user.
drop function public.delete_my_account();

create function public.assert_can_delete_account()
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
  if exists (
    select 1 from public.reservations
    where owner_id = auth.uid() and status in ('pending', 'confirmed', 'checked_in')
  ) then
    raise exception 'Masih ada reservasi aktif. Batalkan atau selesaikan dulu.';
  end if;
  if public.my_role() = 'admin'
     and (select count(*) from public.profiles where role = 'admin') <= 1 then
    raise exception 'Admin terakhir tidak bisa menghapus akun. Jadikan akun lain admin terlebih dahulu.';
  end if;
end;
$$;

-- RLS: (select ...) supaya dievaluasi sekali per query, dan policy write
-- dipisah per aksi (advisor auth_rls_initplan, multiple_permissive_policies)
drop policy "profiles read" on public.profiles;
drop policy "profiles update" on public.profiles;
drop policy "cats read" on public.cats;
drop policy "cats insert" on public.cats;
drop policy "cats update" on public.cats;
drop policy "room types write" on public.room_types;
drop policy "addons write" on public.addons;
drop policy "reservations read" on public.reservations;
drop policy "blocks delete" on public.unit_blocks;
drop policy "reports read" on public.daily_reports;
drop policy "reports insert" on public.daily_reports;

-- Owner hanya melihat profilnya sendiri. Admin dan sitter melihat semua.
create policy "profiles read" on public.profiles for select to authenticated
  using (id = (select auth.uid()) or (select public.my_role()) in ('admin', 'sitter'));
create policy "profiles update" on public.profiles for update to authenticated
  using (id = (select auth.uid()) or (select public.my_role()) = 'admin')
  with check (id = (select auth.uid()) or (select public.my_role()) = 'admin');

create policy "cats read" on public.cats for select to authenticated
  using (owner_id = (select auth.uid()) or (select public.my_role()) in ('admin', 'sitter'));
create policy "cats insert" on public.cats for insert to authenticated
  with check (owner_id = (select auth.uid()));
create policy "cats update" on public.cats for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy "room types insert" on public.room_types for insert to authenticated
  with check ((select public.my_role()) = 'admin');
create policy "room types update" on public.room_types for update to authenticated
  using ((select public.my_role()) = 'admin')
  with check ((select public.my_role()) = 'admin');
create policy "room types delete" on public.room_types for delete to authenticated
  using ((select public.my_role()) = 'admin');

create policy "addons insert" on public.addons for insert to authenticated
  with check ((select public.my_role()) = 'admin');
create policy "addons update" on public.addons for update to authenticated
  using ((select public.my_role()) = 'admin')
  with check ((select public.my_role()) = 'admin');
create policy "addons delete" on public.addons for delete to authenticated
  using ((select public.my_role()) = 'admin');

create policy "reservations read" on public.reservations for select to authenticated
  using (owner_id = (select auth.uid()) or (select public.my_role()) in ('admin', 'sitter'));

create policy "blocks delete" on public.unit_blocks for delete to authenticated
  using ((select public.my_role()) = 'admin');

create policy "reports read" on public.daily_reports for select to authenticated
  using (
    (select public.my_role()) in ('admin', 'sitter')
    or exists (
      select 1 from public.reservations r
      where r.id = reservation_id and r.owner_id = (select auth.uid())
    )
  );
create policy "reports insert" on public.daily_reports for insert to authenticated
  with check (
    reporter_id = (select auth.uid())
    and (select public.my_role()) in ('admin', 'sitter')
    and exists (
      select 1 from public.reservations r
      where r.id = reservation_id and r.status = 'checked_in'
    )
  );

-- Fungsi hanya boleh dipanggil user yang login
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
