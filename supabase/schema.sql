drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();
drop function if exists public.create_profile(auth.users);

drop table if exists
  daily_reports, unit_blocks, reservation_addons, reservations,
  addons, room_types, cats, profiles
cascade;

create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text not null unique,
  phone text not null default '',
  role text not null check (role in ('owner', 'admin', 'sitter')),
  photo text,
  joined_at timestamptz not null default now()
);

create function public.create_profile(u auth.users)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  meta jsonb := u.raw_user_meta_data;
  seed record;
begin
  select * into seed
  from (values
    ('admin@gmail.com', 'Admin Meowville', '0811-0000-1111', 'admin', null::text, timestamptz '2026-09-01'),
    ('nazeril.sitter@gmail.com', 'Nazeril Uzumaki',   '0821-5566-7788', 'sitter', null::text, timestamptz '2026-09-02'),
    ('nazril.ilham@gmail.com', 'Nazril Ilham', '0812-3456-7890', 'owner',  null::text, timestamptz '2026-09-03'),
    ('najer.pinkman@gmail.com', 'Najer Pinkman', '0857-1122-3344', 'owner',  null::text, timestamptz '2026-09-12')
  ) as s(email, name, phone, role, photo, joined_at)
  where s.email = u.email;

  insert into public.profiles (id, name, email, phone, role, photo, joined_at)
  values (
    u.id,
    coalesce(meta->>'name', seed.name, split_part(u.email, '@', 1)),
    u.email,
    coalesce(meta->>'phone', seed.phone, ''),
    coalesce(meta->>'role', seed.role, 'owner'),
    coalesce(meta->>'photo', seed.photo),
    coalesce(seed.joined_at, u.created_at)
  )
  on conflict (id) do nothing;
end;
$$;

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.create_profile(new);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create table cats (
  id bigint generated always as identity primary key,
  owner_id uuid not null references profiles(id) on delete cascade,
  name text not null,
  breed text not null default '',
  weight_kg numeric(4,1) not null,
  photo text,
  deleted boolean not null default false,
  created_at timestamptz not null default now()
);

create table room_types (
  id bigint generated always as identity primary key,
  name text not null,
  prefix text not null unique,
  description text not null default '',
  price integer not null,
  unit_count integer not null,
  facilities text[] not null default '{}',
  packages text[] not null default '{}',
  photo text,
  active boolean not null default true
);

create table addons (
  id bigint generated always as identity primary key,
  name text not null,
  description text not null default '',
  price integer not null,
  active boolean not null default true
);

create table reservations (
  id bigint generated always as identity primary key,
  cat_id bigint not null references cats(id),
  owner_id uuid not null references profiles(id),
  room_type_id bigint not null references room_types(id),
  check_in date not null,
  check_out date not null,
  status text not null default 'pending'
    check (status in ('pending','confirmed','checked_in','completed','rejected','cancelled')),
  unit text,
  payment_proof text,
  admin_note text,
  created_at timestamptz not null default now(),
  check (check_out > check_in)
);

create table reservation_addons (
  reservation_id bigint references reservations(id) on delete cascade,
  addon_id bigint references addons(id),
  primary key (reservation_id, addon_id)
);

create table unit_blocks (
  id bigint generated always as identity primary key,
  room_type_id bigint not null references room_types(id) on delete cascade,
  unit text not null,
  start_date date not null,
  end_date date not null,
  reason text not null default ''
);

create table daily_reports (
  id bigint generated always as identity primary key,
  reservation_id bigint not null references reservations(id) on delete cascade,
  reporter_id uuid not null references profiles(id),
  time timestamptz not null default now(),
  food text not null check (food in ('Habis','Sedikit','Gamau makan')),
  drink text not null check (drink in ('Normal','Sedikit','Banyak')),
  mood text not null check (mood in ('Aktif','Kalem','Agresif','Sakit')),
  note text not null default '',
  photo text
);

do $$
declare t text;
begin
  foreach t in array array['profiles','cats','room_types','addons','reservations',
                           'reservation_addons','unit_blocks','daily_reports']
  loop
    execute format('alter table %I enable row level security', t);
    execute format('create policy "dev full access" on %I for all to authenticated using (true) with check (true)', t);
  end loop;
end $$;

insert into room_types (name, prefix, description, price, unit_count, facilities, packages, photo, active) values
  ('Standard', 'S',
   'Kamar nyaman untuk satu kucing dengan kasur empuk dan rak panjat kecil.',
   50000, 4, '{AC,"Kasur empuk"}', '{Mainan,"Laporan harian"}',
   'assets/images/rooms/standar.jpg', true),
  ('Deluxe', 'D',
   'Kamar luas dan sejuk khusus anabul aktif dengan area vertikal yang nyaman.',
   85000, 3, '{AC,"Jendela besar","Panjat kucing"}', '{Mainan,"Laporan harian","Sisir bulu"}',
   'assets/images/rooms/deluxe.png', true),
  ('Suite', 'ST',
   'Suite dengan jendela taman, cat tree tinggi, dan ruang bermain pribadi.',
   130000, 2, '{AC,"Jendela taman","Cat tree",CCTV}', '{Mainan,"Laporan harian","Sisir bulu","Foto harian"}',
   'assets/images/rooms/suite.png', true),
  ('Presidential', 'P',
   'Kamar terbesar dengan webcam 24 jam untuk dipantau pemilik.',
   200000, 1, '{AC,Webcam,"Ruang bermain"}', '{Mainan,"Laporan harian","Webcam 24h"}',
   'assets/images/rooms/presidential.png', false);

insert into addons (name, description, price, active) values
  ('Grooming Lengkap', 'Mandi, sisir, potongin kuku, bersihin telinga', 80000, true),
  ('Mandi Jamur', 'Perawatan khusus untuk masalah jamur kulit', 45000, true),
  ('Potong Kuku', 'Potong dan rapikan kuku', 25000, true),
  ('Antar Jemput', 'Jemput dan antar kucing ke rumah', 60000, true),
  ('Sisir Bulu', 'Sisir dan rapikan bulu', 20000, true),
  ('Catnip Aromaterapi', 'Pijat dan aromaterapi untuk relaksasi', 90000, false);

delete from auth.users;

do $$
declare
  seed_email text;
  new_id uuid;
begin
  foreach seed_email in array array[
    'admin@gmail.com', 'nazeril.sitter@gmail.com',
    'nazril.ilham@gmail.com', 'najer.pinkman@gmail.com'
  ]
  loop
    new_id := gen_random_uuid();

    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password,
      email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
      created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
      '00000000-0000-0000-0000-000000000000', new_id,
      'authenticated', 'authenticated', seed_email,
      extensions.crypt('password123', extensions.gen_salt('bf')),
      now(), '{"provider":"email","providers":["email"]}', '{}',
      now(), now(),
      '', '', '', ''
    );

    insert into auth.identities (
      id, user_id, provider_id, provider, identity_data,
      last_sign_in_at, created_at, updated_at
    ) values (
      gen_random_uuid(), new_id, new_id::text, 'email',
      jsonb_build_object('sub', new_id::text, 'email', seed_email, 'email_verified', true),
      now(), now(), now()
    );
  end loop;
end $$;
