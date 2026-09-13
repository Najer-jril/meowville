create type user_role as enum ('pet_owner', 'pet_sitter', 'admin');
create type booking_status as enum ('Pending', 'Confirmed', 'Rejected', 'CheckedIn', 'CheckedOut', 'Cancelled');

create table users (
    id uuid primary key references auth.users (id) on delete cascade,
    name varchar(100) not null,
    email varchar(150) unique not null,
    password_hash text,
    whatsapp_number VARCHAR(20) NOT NULL,
    role user_role not null default 'pet_owner',
    created_by uuid references users (id),
    created_at timestamp not null default now()
);

create table pets (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users (id) on delete cascade,
    pet_name varchar(100) not null,
    breed varchar(50) not null,
    weight_kg decimal(5, 2) not null check (weight_kg > 0),
    aggressiveness_level varchar(20) check (aggressiveness_level in ('Low', 'Medium', 'High'))
);

create table rooms (
    id serial primary key,
    room_type varchar(20) unique not null check (room_type in ('Standard', 'Deluxe', 'Suite')),
    description text,
    included_services text not null,
    price_per_night decimal(12, 2) not null check (price_per_night >= 0),
    unit_quantity int not null check (unit_quantity > 0)
);

create table services (
    id serial primary key,
    service_name varchar(100) not null,
    description text,
    price decimal(12, 2) not null check (price >= 0),
    is_active boolean not null default true
);

create table room_blocks (
    id uuid primary key default gen_random_uuid(),
    room_id int not null references rooms (id) on delete cascade,
    date_start date not null,
    date_end date not null,
    blocked_units int not null default 1 check (blocked_units > 0),
    purpose varchar(100),
    created_by uuid not null references users (id),
    check (date_end >= date_start)
);

create table bookings (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users (id),
    pet_id uuid not null references pets (id),
    room_id int not null references rooms (id),
    checkin_date date not null,
    checkout_date date not null check (checkout_date > checkin_date),
    care_instructions text,
    total_price decimal(12, 2) not null check (total_price >= 0),
    status booking_status not null default 'Pending',
    confirmed_by uuid references users (id),
    created_at timestamp not null default now()
);

create table booking_services (
    id uuid primary key default gen_random_uuid(),
    booking_id uuid not null references bookings (id) on delete cascade,
    service_id int not null references services (id),
    price_at_booking decimal(12, 2) not null check (price_at_booking >= 0),
    unique (booking_id, service_id)
);

create table daily_logs (
    id uuid primary key default gen_random_uuid(),
    booking_id uuid not null references bookings (id) on delete cascade,
    log_date date not null default current_date,
    eating_time time,
    pet_mood varchar(50),
    note text,
    noted_by uuid references users (id)
);