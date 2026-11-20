# 01. Database Supabase

Semua SQL di dokumen ini siap disalin ke file di `supabase/migrations/` lalu dijalankan berurutan di SQL Editor Supabase.

## 1. Struktur folder

```
supabase/
  migrations/
    001_schema.sql        tabel, index, trigger profil, my_role()
    002_rls.sql           Row Level Security
    003_rpc.sql           fungsi bisnis (reservasi, block, role, hapus akun)
    004_storage.sql       bucket dan policy foto
    005_master_data.sql   tipe kamar dan addon awal
  dev/
    reset.sql             drop semua tabel (hanya untuk project dev)
    seed_users.sql        akun dummy password123 (hanya untuk project dev)
```

Urutan pakai:

- Project dev: `dev/reset.sql`, lalu 001 sampai 005, lalu `dev/seed_users.sql`.
- Project prod: 001 sampai 005 saja. Akun admin dibuat manual (§7).

`dev/reset.sql` berisi bagian `drop trigger`, `drop function`, `drop table` dari `schema.sql` lama, ditambah:

```sql
drop function if exists public.my_role, public.guard_profile_update,
  public.guard_room_type_update, public.room_availability,
  public.create_reservation, public.cancel_reservation,
  public.upload_payment_proof, public.approve_reservation,
  public.reject_reservation, public.check_in_reservation,
  public.check_out_reservation, public.add_unit_block,
  public.delete_cat, public.set_user_role, public.delete_my_account,
  public.require_role, public.today_wib cascade;
delete from auth.users;
```

File di Storage tidak bisa dihapus dengan SQL. Kosongkan bucket dari dashboard (Storage > pilih bucket > pilih semua > Delete) kalau perlu.

`dev/seed_users.sql` berisi blok `do $$ ... insert into auth.users ...` dari `schema.sql` lama, lalu diakhiri:

```sql
update public.profiles p set name = s.name, phone = s.phone, role = s.role
from (values
  ('admin@gmail.com', 'Admin Meowville', '0811-0000-1111', 'admin'),
  ('nazeril.sitter@gmail.com', 'Nazeril Uzumaki', '0821-5566-7788', 'sitter'),
  ('nazril.ilham@gmail.com', 'Nazril Ilham', '0812-3456-7890', 'owner'),
  ('najer.pinkman@gmail.com', 'Najer Pinkman', '0857-1122-3344', 'owner')
) as s(email, name, phone, role)
where p.email = s.email;
```

Ini menggantikan tabel `seed` di fungsi `create_profile` lama, sehingga trigger produksi bersih dari data dummy.

## 2. `001_schema.sql`

Perubahan dibanding `schema.sql` lama:

| Perubahan | Alasan |
|---|---|
| Role dari signup selalu `owner` | Menutup B2 |
| `reservations.room_price` dan `reservation_addons.price` | Harga dikunci saat booking. Kalau admin mengubah harga, total reservasi lama dan laporan pendapatan tidak ikut berubah |
| FK `reservations.cat_id` dan `owner_id` jadi `on delete cascade` | Supaya `delete_my_account` tidak gagal karena FK. Konsekuensi: riwayat reservasi owner yang menghapus akun ikut hilang dari laporan |
| `daily_reports.reporter_id` nullable, `on delete set null` | Laporan tetap ada walau akun sitter dihapus |
| Check constraint nilai (harga, berat, jumlah unit) | Validasi terakhir di server |
| Index | Query per owner, per status, dan per rentang tanggal |
| `guard_profile_update` | Owner tidak bisa mengubah role atau email lewat PATCH |
| `guard_room_type_update` | Prefix tidak bisa diubah. Jumlah unit tidak bisa dikurangi kalau unit yang hilang masih dipakai |

```sql
-- 001_schema.sql

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique,
  phone text not null default '',
  role text not null default 'owner' check (role in ('owner', 'admin', 'sitter')),
  photo text,
  joined_at timestamptz not null default now()
);

create table public.cats (
  id bigint generated always as identity primary key,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check (length(trim(name)) > 0),
  breed text not null default '',
  weight_kg numeric(4,1) not null check (weight_kg > 0),
  photo text,
  deleted boolean not null default false,
  created_at timestamptz not null default now()
);
create index cats_owner_idx on public.cats (owner_id);

create table public.room_types (
  id bigint generated always as identity primary key,
  name text not null,
  prefix text not null unique check (prefix ~ '^[A-Z]{1,3}$'),
  description text not null default '',
  price integer not null check (price >= 0),
  unit_count integer not null check (unit_count between 1 and 99),
  facilities text[] not null default '{}',
  packages text[] not null default '{}',
  photo text,
  active boolean not null default true
);

create table public.addons (
  id bigint generated always as identity primary key,
  name text not null,
  description text not null default '',
  price integer not null check (price >= 0),
  active boolean not null default true
);

create table public.reservations (
  id bigint generated always as identity primary key,
  cat_id bigint not null references public.cats(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  room_type_id bigint not null references public.room_types(id),
  check_in date not null,
  check_out date not null,
  room_price integer not null,
  status text not null default 'pending'
    check (status in ('pending','confirmed','checked_in','completed','rejected','cancelled')),
  unit text,
  payment_proof text,
  admin_note text,
  created_at timestamptz not null default now(),
  check (check_out > check_in)
);
create index reservations_owner_idx on public.reservations (owner_id);
create index reservations_status_idx on public.reservations (status);
create index reservations_range_idx on public.reservations (room_type_id, check_in, check_out);

create table public.reservation_addons (
  reservation_id bigint not null references public.reservations(id) on delete cascade,
  addon_id bigint not null references public.addons(id),
  price integer not null,
  primary key (reservation_id, addon_id)
);

create table public.unit_blocks (
  id bigint generated always as identity primary key,
  room_type_id bigint not null references public.room_types(id) on delete cascade,
  unit text not null,
  start_date date not null,
  end_date date not null,
  reason text not null default '',
  check (end_date >= start_date)
);
create index unit_blocks_range_idx on public.unit_blocks (room_type_id, start_date, end_date);

create table public.daily_reports (
  id bigint generated always as identity primary key,
  reservation_id bigint not null references public.reservations(id) on delete cascade,
  reporter_id uuid references public.profiles(id) on delete set null,
  time timestamptz not null default now(),
  food text not null check (food in ('Habis','Sedikit','Gamau makan')),
  drink text not null check (drink in ('Normal','Sedikit','Banyak')),
  mood text not null check (mood in ('Aktif','Kalem','Agresif','Sakit')),
  note text not null default '',
  photo text
);
create index daily_reports_reservation_idx on public.daily_reports (reservation_id);

-- Role user yang sedang login. Dipakai di RLS dan RPC.
create function public.my_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select role from public.profiles where id = auth.uid()
$$;

-- Tanggal hari ini menurut WIB. Server Supabase memakai UTC.
create function public.today_wib()
returns date
language sql
stable
as $$
  select (now() at time zone 'Asia/Jakarta')::date
$$;

-- Profil dibuat otomatis saat signup. Role selalu owner.
create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, name, email, phone, role)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data->>'name'), ''), split_part(new.email, '@', 1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'phone', ''),
    'owner'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Owner dan sitter tidak boleh mengubah role atau email lewat REST.
-- auth.uid() null berarti dijalankan dari SQL Editor atau service role.
create function public.guard_profile_update()
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
  if new.role is distinct from old.role and coalesce(public.my_role(), '') <> 'admin' then
    raise exception 'Role tidak bisa diubah';
  end if;
  return new;
end;
$$;

create trigger profiles_guard
  before update on public.profiles
  for each row execute function public.guard_profile_update();

create function public.guard_room_type_update()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.prefix is distinct from old.prefix then
    raise exception 'Prefix tipe kamar tidak bisa diubah';
  end if;
  if new.unit_count < old.unit_count and exists (
    select 1 from public.reservations r
    where r.room_type_id = new.id
      and r.status in ('confirmed', 'checked_in')
      and substring(r.unit from length(new.prefix) + 1)::int > new.unit_count
  ) then
    raise exception 'Unit yang akan dihapus masih dipakai reservasi aktif';
  end if;
  return new;
end;
$$;

create trigger room_types_guard
  before update on public.room_types
  for each row execute function public.guard_room_type_update();
```

Catatan "hapus tipe kamar" dan "hapus addon" di use case: diwujudkan sebagai nonaktifkan (`active = false`), karena tipe kamar dan addon direferensikan oleh reservasi lama. UI yang sekarang sudah memakai toggle aktif.

## 3. `002_rls.sql`

Matriks akses:

| Tabel | Owner | Sitter | Admin |
|---|---|---|---|
| `profiles` | baca diri sendiri dan profil staff, ubah diri sendiri | baca semua, ubah diri sendiri | baca dan ubah semua |
| `cats` | baca, tambah, ubah milik sendiri | baca semua | baca semua |
| `room_types`, `addons` | baca semua | baca semua | baca dan tulis |
| `reservations` | baca milik sendiri | baca semua | baca semua |
| `reservation_addons` | ikut reservasi yang bisa dibaca | sama | sama |
| `unit_blocks` | baca | baca | baca dan hapus (tambah lewat RPC) |
| `daily_reports` | baca laporan reservasi sendiri | baca semua, tambah | baca semua, tambah |

Owner perlu membaca profil staff karena `pet_report_screen.dart:145` menampilkan nama pelapor.

Semua perubahan status reservasi tidak punya policy `insert` atau `update`, jadi hanya bisa lewat RPC di 003.

```sql
-- 002_rls.sql

-- Bersihkan policy lama kalau project pernah memakai schema.sql
do $$
declare t text;
begin
  foreach t in array array['profiles','cats','room_types','addons','reservations',
                           'reservation_addons','unit_blocks','daily_reports']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "dev full access" on public.%I', t);
  end loop;
end $$;

-- profiles
create policy "profiles read" on public.profiles for select to authenticated
  using (
    id = auth.uid()
    or role in ('admin', 'sitter')
    or public.my_role() in ('admin', 'sitter')
  );
create policy "profiles update" on public.profiles for update to authenticated
  using (id = auth.uid() or public.my_role() = 'admin')
  with check (id = auth.uid() or public.my_role() = 'admin');

-- cats
create policy "cats read" on public.cats for select to authenticated
  using (owner_id = auth.uid() or public.my_role() in ('admin', 'sitter'));
create policy "cats insert" on public.cats for insert to authenticated
  with check (owner_id = auth.uid());
create policy "cats update" on public.cats for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- room_types
create policy "room types read" on public.room_types for select to authenticated
  using (true);
create policy "room types write" on public.room_types for all to authenticated
  using (public.my_role() = 'admin')
  with check (public.my_role() = 'admin');

-- addons
create policy "addons read" on public.addons for select to authenticated
  using (true);
create policy "addons write" on public.addons for all to authenticated
  using (public.my_role() = 'admin')
  with check (public.my_role() = 'admin');

-- reservations
create policy "reservations read" on public.reservations for select to authenticated
  using (owner_id = auth.uid() or public.my_role() in ('admin', 'sitter'));

-- reservation_addons
create policy "reservation addons read" on public.reservation_addons for select to authenticated
  using (exists (select 1 from public.reservations r where r.id = reservation_id));

-- unit_blocks
create policy "blocks read" on public.unit_blocks for select to authenticated
  using (true);
create policy "blocks delete" on public.unit_blocks for delete to authenticated
  using (public.my_role() = 'admin');

-- daily_reports
create policy "reports read" on public.daily_reports for select to authenticated
  using (
    public.my_role() in ('admin', 'sitter')
    or exists (
      select 1 from public.reservations r
      where r.id = reservation_id and r.owner_id = auth.uid()
    )
  );
create policy "reports insert" on public.daily_reports for insert to authenticated
  with check (
    reporter_id = auth.uid()
    and public.my_role() in ('admin', 'sitter')
    and exists (
      select 1 from public.reservations r
      where r.id = reservation_id and r.status = 'checked_in'
    )
  );

-- Fungsi hanya boleh dipanggil user yang login
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
alter default privileges in schema public revoke execute on functions from public, anon;
```

Baris `revoke` dan `grant` di akhir juga dijalankan ulang di akhir `003_rpc.sql`, karena fungsi baru dibuat di sana.

## 4. `003_rpc.sql`

Daftar fungsi:

| Fungsi | Dipanggil oleh | Endpoint |
|---|---|---|
| `room_availability(p_type, p_start, p_end)` | owner (step kamar), admin (kalender, dashboard) | `POST /rest/v1/rpc/room_availability` |
| `create_reservation(...)` | owner | `POST /rest/v1/rpc/create_reservation` |
| `cancel_reservation(p_id)` | owner, admin | `.../cancel_reservation` |
| `upload_payment_proof(p_id, p_path)` | owner | `.../upload_payment_proof` |
| `approve_reservation(p_id, p_unit)` | admin | `.../approve_reservation` |
| `reject_reservation(p_id, p_note)` | admin | `.../reject_reservation` |
| `check_in_reservation(p_id)` | sitter, admin | `.../check_in_reservation` |
| `check_out_reservation(p_id)` | sitter, admin | `.../check_out_reservation` |
| `add_unit_block(...)` | admin | `.../add_unit_block` |
| `delete_cat(p_id)` | owner | `.../delete_cat` |
| `set_user_role(p_user, p_role)` | admin | `.../set_user_role` |
| `delete_my_account()` | semua | `.../delete_my_account` |

Pesan `raise exception` muncul di response sebagai `{"code":"P0001","message":"..."}`. `ApiClient._errorMessage` sudah membaca key `message`, jadi pesan bahasa Indonesia langsung tampil di snackbar.

Aturan tanggal: `check_in` dan `check_out` adalah tanggal, malam yang dihitung adalah `check_in <= hari < check_out`. Block unit memakai `start_date <= hari <= end_date` (inklusif), sama dengan `UnitBlock.covers` di Flutter.

```sql
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
  if p_unit !~ ('^' || t.prefix || '[0-9]+$') then
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
```

Catatan `delete_my_account`: Supabase melarang `delete from storage.objects` langsung lewat SQL, jadi foto milik user dihapus oleh app lewat Storage API sebelum RPC ini dipanggil (05-flutter-core.md §3, `StorageService.deleteOwnFiles`). Hapus dari `auth.users` akan cascade ke `profiles`, `cats`, `reservations`, `reservation_addons`, dan `daily_reports` milik reservasi itu. Admin terakhir sebaiknya tidak menghapus akunnya sendiri; tombol hapus akun cukup ditampilkan untuk owner dan sitter.

## 5. `004_storage.sql`

| Bucket | Public | Path | Siapa yang upload | Isi kolom DB |
|---|---|---|---|---|
| `cat-photos` | ya | `<uid>/<timestamp>.jpg` | owner | URL public lengkap |
| `avatars` | ya | `<uid>/<timestamp>.jpg` | semua | URL public lengkap |
| `report-photos` | ya | `<uid>/<timestamp>.jpg` | sitter, admin | URL public lengkap |
| `room-photos` | ya | `<uid>/<timestamp>.jpg` | admin | URL public lengkap |
| `payment-proofs` | tidak | `<uid>/<timestamp>.jpg` | owner | path objek saja, misalnya `3f2c.../1731650000000.jpg` |

Bukti bayar adalah data sensitif, jadi private. Owner pemilik folder dan admin membacanya lewat signed URL.

```sql
-- 004_storage.sql

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('cat-photos', 'cat-photos', true, 5242880, '{image/jpeg,image/png,image/webp}'),
  ('avatars', 'avatars', true, 5242880, '{image/jpeg,image/png,image/webp}'),
  ('report-photos', 'report-photos', true, 5242880, '{image/jpeg,image/png,image/webp}'),
  ('room-photos', 'room-photos', true, 5242880, '{image/jpeg,image/png,image/webp}'),
  ('payment-proofs', 'payment-proofs', false, 5242880, '{image/jpeg,image/png,image/webp}')
on conflict (id) do nothing;

create policy "upload to own folder" on storage.objects for insert to authenticated
  with check (
    bucket_id in ('cat-photos', 'avatars', 'payment-proofs')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "staff upload report photos" on storage.objects for insert to authenticated
  with check (
    bucket_id = 'report-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
    and public.my_role() in ('sitter', 'admin')
  );

create policy "admin upload room photos" on storage.objects for insert to authenticated
  with check (
    bucket_id = 'room-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
    and public.my_role() = 'admin'
  );

create policy "read payment proofs" on storage.objects for select to authenticated
  using (
    bucket_id = 'payment-proofs'
    and ((storage.foldername(name))[1] = auth.uid()::text or public.my_role() = 'admin')
  );

create policy "list own files" on storage.objects for select to authenticated
  using ((storage.foldername(name))[1] = auth.uid()::text);

create policy "delete own files" on storage.objects for delete to authenticated
  using ((storage.foldername(name))[1] = auth.uid()::text);
```

Bucket public tidak butuh policy `select` untuk dibaca lewat URL `/object/public/...`. Policy "list own files" dan "delete own files" dipakai saat user menghapus akun dan saat foto lama diganti.

## 6. Setting Supabase Auth (dashboard)

Kerjakan di kedua project.

| Menu | Setting | Nilai |
|---|---|---|
| Authentication > Sign In / Providers > Email | Enable email provider | on |
| | Confirm email | on (butuh SMTP). Kalau SMTP belum siap, matikan dulu di dev saja |
| | Minimum password length | 8, sama dengan validasi di form registrasi |
| Authentication > Emails > SMTP Settings | Custom SMTP | Resend (`smtp.resend.com`, port 465, user `resend`, password API key) atau Brevo. Sender: domain sendiri, atau alamat bawaan penyedia |
| Authentication > Emails > Templates > Reset Password | Body | Tampilkan kode OTP (lihat di bawah) |
| Authentication > Emails > Templates > Confirm signup | Body | Bahasa Indonesia |
| Authentication > Rate Limits | Email per jam | Naikkan ke 30 setelah SMTP aktif |
| Authentication > URL Configuration | Site URL | URL GitHub Pages (06 §6), supaya link konfirmasi email membuka halaman yang ada |

Template "Reset Password":

```html
<h2>Reset password Meowville</h2>
<p>Masukkan kode berikut di aplikasi Meowville:</p>
<p style="font-size:28px;font-weight:bold;letter-spacing:6px">{{ .Token }}</p>
<p>Kode berlaku 1 jam. Abaikan email ini kalau kamu tidak meminta reset password.</p>
```

Alur reset tanpa deep link:

1. `POST /auth/v1/recover` body `{"email": "..."}`
2. User memasukkan kode 6 digit dari email.
3. `POST /auth/v1/verify` body `{"type": "recovery", "email": "...", "token": "123456"}`. Response berisi session.
4. `PUT /auth/v1/user` dengan `Authorization: Bearer <access_token dari langkah 3>` body `{"password": "..."}`

Akun yang dibuat admin (sitter atau admin lain) memakai `POST /auth/v1/signup` biasa, lalu `set_user_role`. Kalau "Confirm email" menyala, staff harus mengklik link konfirmasi di email sebelum bisa login. Beri tahu staff saat akun dibuat.

## 7. Data awal produksi

`005_master_data.sql` berisi dua `insert` untuk `room_types` dan `addons` dari `schema.sql` lama, tanpa perubahan. Kolom `photo` tetap path asset (`assets/images/rooms/...`), karena `AppPhoto` tetap mendukung asset.

Akun admin produksi:

1. Authentication > Users > Add user > Create new user. Isi email asli dan password kuat, centang "Auto Confirm User".
2. SQL Editor:
   ```sql
   update public.profiles set role = 'admin', name = 'Admin Meowville', phone = '08xx'
   where email = 'email-admin@domain.com';
   ```

Akun demo untuk reviewer Google (dibuat dengan cara yang sama):

| Email | Role | Kegunaan |
|---|---|---|
| `demo.owner@<domain>` | owner | Isi 1 kucing dan 1 reservasi contoh |
| `demo.sitter@<domain>` | sitter | |
| `demo.admin@<domain>` | admin | Opsional. Kalau tidak ingin reviewer melihat data asli, cukup beri owner dan sitter |

## 8. Uji RLS dan RPC dengan curl

Ambil token tiap role:

```bash
URL=https://<ref>.supabase.co
KEY=sb_publishable_xxx
token() {
  curl -s "$URL/auth/v1/token?grant_type=password" \
    -H "apikey: $KEY" -H "Content-Type: application/json" \
    -d "{\"email\":\"$1\",\"password\":\"password123\"}" | jq -r .access_token
}
OWNER=$(token najer.pinkman@gmail.com)
ADMIN=$(token admin@gmail.com)
SITTER=$(token nazeril.sitter@gmail.com)
OWNER_ID=$(curl -s "$URL/auth/v1/user" -H "apikey: $KEY" -H "Authorization: Bearer $OWNER" | jq -r .id)
```

| # | Uji | Perintah | Harus |
|---|---|---|---|
| T1 | Owner menaikkan role sendiri | `curl -s -X PATCH "$URL/rest/v1/profiles?id=eq.$OWNER_ID" -H "apikey: $KEY" -H "Authorization: Bearer $OWNER" -H "Content-Type: application/json" -d '{"role":"admin"}'` | Error `Role tidak bisa diubah` |
| T2 | Signup dengan role admin | `curl -s "$URL/auth/v1/signup" -H "apikey: $KEY" -H "Content-Type: application/json" -d '{"email":"x@test.com","password":"password123","data":{"role":"admin"}}'` lalu cek `profiles` | Role `owner` |
| T3 | Owner membaca semua reservasi | `curl -s "$URL/rest/v1/reservations?select=owner_id" -H "apikey: $KEY" -H "Authorization: Bearer $OWNER"` | Hanya baris dengan `owner_id` miliknya |
| T4 | Owner insert reservasi langsung | `POST /rest/v1/reservations` | 401/403 (tidak ada policy insert) |
| T5 | Owner approve | `POST /rest/v1/rpc/approve_reservation` | `Akses ditolak` |
| T6 | Booking saat penuh | Buat `unit_count` reservasi pending di tanggal sama, lalu satu lagi | `Kamar penuh di tanggal yang dipilih` |
| T7 | Approve unit bentrok | Approve dua reservasi bertumpuk dengan unit sama | Yang kedua `Unit ... sudah terisi` |
| T8 | Sitter tambah laporan untuk reservasi belum check-in | `POST /rest/v1/daily_reports` | Ditolak RLS |
| T9 | Anon memanggil RPC | `rpc/room_availability` tanpa header Authorization | `permission denied` |
| T10 | Upload ke folder orang lain | `POST /storage/v1/object/cat-photos/<uid-lain>/a.jpg` | 403 |
