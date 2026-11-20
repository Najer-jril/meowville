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
