-- Prasyarat dashboard pemilik, penjaga, dan admin. Lihat planning/00_schema_changes.md.
-- Migrasi ini tidak bisa dijalankan sebagian: langkah 7 membaca rooms.unit_quantity,
-- langkah 8 membuangnya.

-- 1. Unit kamar. rooms tetap memegang tier, room_units memegang unit fisik.
create table room_units (
    id serial primary key,
    room_id int not null references rooms (id) on delete cascade,
    unit_code varchar(10) not null unique,
    is_active boolean not null default true
);

-- 2. Kelamin dan foto kucing.
alter table pets
    add column sex varchar(10) check (sex in ('Jantan', 'Betina')),
    add column photo_url text;

-- 3. Waktu tulis dan foto laporan harian.
alter table daily_logs
    add column created_at timestamp not null default now(),
    add column photo_url text;

-- 4. Penugasan penjaga, unit kamar, bukti bayar, jejak perubahan.
alter table bookings
    add column assigned_sitter_id uuid references users (id),
    add column room_unit_id int references room_units (id),
    add column payment_proof_url text,
    add column updated_at timestamp not null default now();

-- 5. Indeks untuk query dashboard yang dipakai tiap kali layar dibuka.
create index on room_units (room_id);
create index on bookings (assigned_sitter_id);
create index on bookings (status, checkin_date);
create index on bookings (status, checkout_date);
create index on bookings (user_id, checkin_date desc);
create index on daily_logs (booking_id, log_date);

-- 6. updated_at terisi sendiri setiap baris bookings berubah.
create or replace function set_updated_at()
returns trigger as $$
begin
    new.updated_at = now();
    return new;
end;
$$ language plpgsql;

create trigger bookings_set_updated_at
    before update on bookings
    for each row execute function set_updated_at();

-- 7. Seed unit kamar sebanyak unit_quantity tiap tier.
--    Dijalankan SEBELUM kolom unit_quantity dibuang.
insert into room_units (room_id, unit_code)
select r.id,
       case r.room_type
           when 'Standard' then 'STD-'
           when 'Deluxe' then 'DLX-'
           else 'STE-'
       end || lpad(g::text, 2, '0')
from rooms r
cross join generate_series(1, 99) g
where g <= r.unit_quantity;

-- 8. Kapasitas sekarang tunggal: jumlah baris room_units yang aktif.
alter table rooms drop column unit_quantity;

-- 9. Pembuatan baris users pindah ke trigger. Klien tidak lagi menyisipkan
--    baris users, jadi pendaftaran tidak bergantung pada ada tidaknya sesi.
create or replace function handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.users (id, name, email, whatsapp_number, role)
    values (
        new.id,
        coalesce(new.raw_user_meta_data ->> 'name', ''),
        new.email,
        coalesce(new.raw_user_meta_data ->> 'whatsapp_number', ''),
        -- Peran dari klien dijepit di sini. Nilai selain pet_sitter jatuh
        -- ke pet_owner, termasuk percobaan menulis 'admin'.
        case new.raw_user_meta_data ->> 'role'
            when 'pet_sitter' then 'pet_sitter'::user_role
            else 'pet_owner'::user_role
        end
    );
    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function handle_new_auth_user();

-- 10. RLS.
alter table users enable row level security;
alter table pets enable row level security;
alter table bookings enable row level security;
alter table daily_logs enable row level security;
alter table rooms enable row level security;
alter table room_units enable row level security;
alter table room_blocks enable row level security;
alter table services enable row level security;
alter table booking_services enable row level security;

-- security definer supaya pembacaan role tidak ikut terjegal policy users.
create or replace function current_role_name()
returns text
language sql
stable
security definer
set search_path = public
as $$
    select role::text from users where id = auth.uid();
$$;

-- users
create policy users_read on users for select to authenticated
    using (id = auth.uid() or current_role_name() in ('pet_sitter', 'admin'));

create policy users_insert_self on users for insert to authenticated
    with check (id = auth.uid() and role in ('pet_owner', 'pet_sitter'));

create policy users_update_self on users for update to authenticated
    using (id = auth.uid()) with check (id = auth.uid());

-- Supabase memberi authenticated hak UPDATE pada seluruh tabel, dan REVOKE
-- per kolom tidak berlaku selama hak tingkat tabel masih ada. Hak tabel dicabut
-- dulu, lalu hanya kolom profil yang dibuka. role tidak termasuk.
revoke update on users from authenticated;
grant update (name, whatsapp_number) on users to authenticated;

-- pets
create policy pets_read on pets for select to authenticated
    using (user_id = auth.uid() or current_role_name() in ('pet_sitter', 'admin'));

create policy pets_write_owner on pets for all to authenticated
    using (user_id = auth.uid()) with check (user_id = auth.uid());

-- bookings
create policy bookings_read on bookings for select to authenticated
    using (user_id = auth.uid() or current_role_name() in ('pet_sitter', 'admin'));

create policy bookings_insert_owner on bookings for insert to authenticated
    with check (user_id = auth.uid());

-- Longgar dengan sengaja: penjaga memproses check-in tamu yang belum ditugaskan.
create policy bookings_update_staff on bookings for update to authenticated
    using (current_role_name() in ('pet_sitter', 'admin'));

-- daily_logs
create policy daily_logs_read on daily_logs for select to authenticated
    using (
        current_role_name() in ('pet_sitter', 'admin')
        or exists (
            select 1 from bookings b
            where b.id = daily_logs.booking_id and b.user_id = auth.uid()
        )
    );

create policy daily_logs_write_staff on daily_logs for insert to authenticated
    with check (current_role_name() in ('pet_sitter', 'admin'));

create policy daily_logs_update_author on daily_logs for update to authenticated
    using (noted_by = auth.uid() or current_role_name() = 'admin');

-- Katalog: semua yang sudah masuk boleh membaca, hanya admin boleh mengubah.
create policy rooms_read on rooms for select to authenticated using (true);
create policy room_units_read on room_units for select to authenticated using (true);
create policy room_blocks_read on room_blocks for select to authenticated using (true);
create policy services_read on services for select to authenticated using (true);

create policy rooms_write_admin on rooms for all to authenticated
    using (current_role_name() = 'admin') with check (current_role_name() = 'admin');
create policy room_units_write_admin on room_units for all to authenticated
    using (current_role_name() = 'admin') with check (current_role_name() = 'admin');
create policy room_blocks_write_admin on room_blocks for all to authenticated
    using (current_role_name() = 'admin') with check (current_role_name() = 'admin');
create policy services_write_admin on services for all to authenticated
    using (current_role_name() = 'admin') with check (current_role_name() = 'admin');

-- booking_services ikut izin booking induknya.
create policy booking_services_read on booking_services for select to authenticated
    using (
        exists (
            select 1 from bookings b
            where b.id = booking_services.booking_id
              and (b.user_id = auth.uid()
                   or current_role_name() in ('pet_sitter', 'admin'))
        )
    );

create policy booking_services_insert_owner on booking_services for insert to authenticated
    with check (
        exists (
            select 1 from bookings b
            where b.id = booking_services.booking_id and b.user_id = auth.uid()
        )
    );
