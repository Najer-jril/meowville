do $$
declare
    v_admin_id constant uuid := '00000000-0000-4000-a000-000000000001';
    v_password constant text := 'password123';
    r record;
begin
    for r in
        select *
        from (values
            ('00000000-0000-4000-a000-000000000001'::uuid, 'Admin Meowville', 'admin@meowville.test', '081200000001', 'admin'::user_role,false),
            ('00000000-0000-4000-a000-000000000011'::uuid, 'Najer Keeper', 'sitter1@meowville.test', '081200000011', 'pet_sitter'::user_role, true),
            ('00000000-0000-4000-a000-000000000012'::uuid, 'Najer Sitter', 'sitter2@meowville.test', '081200000012', 'pet_sitter'::user_role, true),
            ('00000000-0000-4000-a000-000000000021'::uuid, 'Najer 1', 'owner1@meowville.test', '081200000021', 'pet_owner'::user_role,  false),
            ('00000000-0000-4000-a000-000000000022'::uuid, 'Najer 2', 'owner2@meowville.test', '081200000022', 'pet_owner'::user_role,  false),
            ('00000000-0000-4000-a000-000000000023'::uuid, 'Najer 3', 'owner3@meowville.test', '081200000023', 'pet_owner'::user_role,  false)
        ) as t (id, name, email, whatsapp_number, role, created_by_admin)
    loop
        if exists (select 1 from auth.users where lower(email) = r.email) then
            continue;
        end if;

        insert into auth.users (
            instance_id, id, aud, role, email, encrypted_password,
            email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
            created_at, updated_at,
            confirmation_token, recovery_token, email_change_token_new, email_change
        ) values (
            '00000000-0000-0000-0000-000000000000', r.id,
            'authenticated', 'authenticated', r.email,
            extensions.crypt(v_password, extensions.gen_salt('bf')),
            now(),
            jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
            jsonb_build_object('name', r.name, 'whatsapp_number', r.whatsapp_number, 'role', r.role::text),
            now(), now(),
            '', '', '', ''
        );

        insert into auth.identities (
            provider_id, user_id, identity_data, provider,
            last_sign_in_at, created_at, updated_at
        ) values (
            r.id::text, r.id,
            jsonb_build_object('sub', r.id::text, 'email', r.email, 'email_verified', true),
            'email',
            now(), now(), now()
        );

        update public.users
        set role = r.role,
            whatsapp_number = r.whatsapp_number,
            created_by = case when r.created_by_admin then v_admin_id end
        where id = r.id;
    end loop;
end;
$$;

insert into rooms (room_type, description, included_services, price_per_night)
values
    ('Standard',
     'Kamar vertikal bertingkat dengan ventilasi memadai, hiding spot, kasur, dan litter box. Cocok untuk kucing kecil sampai sedang, kucing pemalu, dan inap singkat.',
     'Makan 2-3x sehari, Pembersihan litter box berkala, Penanganan dasar',
     150000),
    ('Deluxe',
     'Ruangan lebih tinggi dengan papan panjat bertingkat, scratcher, dan CCTV 24 jam. Cocok untuk kucing aktif yang suka memanjat.',
     'Makan 2-3x sehari, Pembersihan litter box berkala, Penanganan dasar, Laporan harian, Sesi solo playtime',
     250000),
    ('Suite',
     'Ruangan kaca luas yang terpisah dari kebisingan, dengan window view, cat tree besar, diffuser Feliway, dan CCTV 24 jam. Muat 2-3 kucing dari satu pemilik.',
     'Makan 2-3x sehari, Pembersihan litter box berkala, Laporan harian, Sesi solo playtime, Grooming sebelum pulang, Penyisiran bulu harian, Treats harian',
     400000)
on conflict (room_type) do nothing;

insert into room_units (room_id, unit_code)
select r.id, u.unit_code
from (values
    ('Standard', 'STD-01'), ('Standard', 'STD-02'), ('Standard', 'STD-03'), ('Standard', 'STD-04'),
    ('Deluxe', 'DLX-01'), ('Deluxe', 'DLX-02'), ('Deluxe', 'DLX-03'),
    ('Suite', 'STE-01'), ('Suite', 'STE-02')
) as u (room_type, unit_code)
join rooms r on r.room_type = u.room_type
on conflict (unit_code) do nothing;

insert into services (service_name, description, price)
select s.service_name, s.description, s.price
from (values
    ('Feliway Diffuser', 'Diffuser feromon tambahan untuk menenangkan kucing yang mudah stres.', 50000),
    ('Medical Grooming', 'Mandi jamur, potong kuku, dan pembersihan telinga.', 75000),
    ('Custom Diet / Medication', 'Pemberian obat harian atau wet food khusus dari pemilik.', 35000)
) as s (service_name, description, price)
where not exists (
    select 1 from services where service_name = s.service_name
);

insert into pets (id, user_id, pet_name, breed, weight_kg, aggressiveness_level, sex)
values
    ('00000000-0000-4000-b000-000000000001', '00000000-0000-4000-a000-000000000021', 'Mochi',  'Persia',            4.20, 'Low',    'Betina'),
    ('00000000-0000-4000-b000-000000000002', '00000000-0000-4000-a000-000000000021', 'Oyen',   'Domestik',          5.10, 'Medium', 'Jantan'),
    ('00000000-0000-4000-b000-000000000003', '00000000-0000-4000-a000-000000000022', 'Luna',   'British Shorthair', 3.80, 'Low',    'Betina'),
    ('00000000-0000-4000-b000-000000000004', '00000000-0000-4000-a000-000000000022', 'Garong', 'Maine Coon',        7.50, 'High',   'Jantan'),
    ('00000000-0000-4000-b000-000000000005', '00000000-0000-4000-a000-000000000023', 'Kiki',   'Ragdoll',           4.60, 'Low',    'Betina')
on conflict (id) do nothing;

insert into bookings (
    id, user_id, pet_id, room_id, room_unit_id, assigned_sitter_id,
    checkin_date, checkout_date, care_instructions, total_price,
    status, confirmed_by, created_at
)
select
    b.id, p.user_id, b.pet_id, r.id, ru.id, b.sitter_id,
    current_date + b.checkin_offset, current_date + b.checkout_offset,
    b.care_instructions,
    r.price_per_night * (b.checkout_offset - b.checkin_offset),
    b.status::booking_status, b.confirmed_by,
    now() - b.created_ago
from (values
    ('00000000-0000-4000-c000-000000000001'::uuid, '00000000-0000-4000-b000-000000000001'::uuid,
     'Deluxe', 'DLX-01', '00000000-0000-4000-a000-000000000011'::uuid, -2, 3,
     'Makan wet food dua kali sehari. Sisir bulu setiap sore.', 'CheckedIn',
     '00000000-0000-4000-a000-000000000001'::uuid, interval '5 days'),
    ('00000000-0000-4000-c000-000000000002', '00000000-0000-4000-b000-000000000004',
     'Suite', 'STE-01', '00000000-0000-4000-a000-000000000012', -3, 0,
     'Agresif ke kucing lain, jangan digabung saat playtime.', 'CheckedIn',
     '00000000-0000-4000-a000-000000000001', interval '6 days'),
    ('00000000-0000-4000-c000-000000000003', '00000000-0000-4000-b000-000000000005',
     'Standard', 'STD-01', '00000000-0000-4000-a000-000000000011', 0, 3,
     null, 'Confirmed',
     '00000000-0000-4000-a000-000000000001', interval '2 days'),
    ('00000000-0000-4000-c000-000000000004', '00000000-0000-4000-b000-000000000002',
     'Standard', null, null, 5, 8,
     'Alergi ayam. Pakai makanan kering yang dibawa sendiri.', 'Pending',
     null, interval '3 hours'),
    ('00000000-0000-4000-c000-000000000005', '00000000-0000-4000-b000-000000000003',
     'Deluxe', null, null, 7, 10,
     null, 'Pending',
     null, interval '40 minutes'),
    ('00000000-0000-4000-c000-000000000006', '00000000-0000-4000-b000-000000000001',
     'Suite', 'STE-02', '00000000-0000-4000-a000-000000000012', -20, -15,
     null, 'CheckedOut',
     '00000000-0000-4000-a000-000000000001', interval '25 days'),
    ('00000000-0000-4000-c000-000000000007', '00000000-0000-4000-b000-000000000005',
     'Standard', null, null, -10, -8,
     null, 'Cancelled',
     '00000000-0000-4000-a000-000000000001', interval '14 days'),
    ('00000000-0000-4000-c000-000000000008', '00000000-0000-4000-b000-000000000003',
     'Standard', null, null, 2, 4,
     null, 'Rejected',
     '00000000-0000-4000-a000-000000000001', interval '1 day')
) as b (
    id, pet_id, room_type, unit_code, sitter_id, checkin_offset, checkout_offset,
    care_instructions, status, confirmed_by, created_ago
)
join pets p on p.id = b.pet_id
join rooms r on r.room_type = b.room_type
left join room_units ru on ru.unit_code = b.unit_code
on conflict (id) do nothing;

insert into booking_services (booking_id, service_id, price_at_booking)
select bs.booking_id, s.id, s.price
from (values
    ('00000000-0000-4000-c000-000000000001'::uuid, 'Custom Diet / Medication'),
    ('00000000-0000-4000-c000-000000000002'::uuid, 'Feliway Diffuser'),
    ('00000000-0000-4000-c000-000000000004'::uuid, 'Medical Grooming'),
    ('00000000-0000-4000-c000-000000000006'::uuid, 'Medical Grooming')
) as bs (booking_id, service_name)
join services s on s.service_name = bs.service_name
join bookings b on b.id = bs.booking_id
on conflict (booking_id, service_id) do nothing;

update bookings b
set total_price = r.price_per_night * (b.checkout_date - b.checkin_date)
                  + coalesce((
                      select sum(bs.price_at_booking)
                      from booking_services bs
                      where bs.booking_id = b.id
                  ), 0)
from rooms r
where r.id = b.room_id
  and b.id::text like '00000000-0000-4000-c000-%';

insert into daily_logs (id, booking_id, log_date, eating_time, pet_mood, note, noted_by, created_at)
select
    l.id, l.booking_id, current_date + l.day_offset, l.eating_time::time,
    l.pet_mood, l.note, l.noted_by,
    (current_date + l.day_offset) + l.eating_time::time + interval '30 minutes'
from (values
    ('00000000-0000-4000-d000-000000000001'::uuid, '00000000-0000-4000-c000-000000000001'::uuid, -2, '08:00',
     'Pemalu', 'Masih menyesuaikan diri, lebih banyak diam di hiding spot. Wet food habis setengah.',
     '00000000-0000-4000-a000-000000000011'::uuid),
    ('00000000-0000-4000-d000-000000000002', '00000000-0000-4000-c000-000000000001', -1, '08:15',
     'Tenang', 'Mulai mau keluar kamar. Makan habis, disisir 10 menit tanpa rewel.',
     '00000000-0000-4000-a000-000000000011'),
    ('00000000-0000-4000-d000-000000000003', '00000000-0000-4000-c000-000000000001', 0, '07:45',
     'Ceria', 'Ikut sesi playtime pagi, main tongkat bulu sekitar 15 menit.',
     '00000000-0000-4000-a000-000000000011'),
    ('00000000-0000-4000-d000-000000000004', '00000000-0000-4000-c000-000000000002', -3, '09:00',
     'Waspada', 'Mendesis saat pintu dibuka. Dibiarkan sendiri, makan setelah ditinggal.',
     '00000000-0000-4000-a000-000000000012'),
    ('00000000-0000-4000-d000-000000000005', '00000000-0000-4000-c000-000000000002', -2, '08:30',
     'Tenang', 'Sudah tidak mendesis. Tidur lama di cat tree dekat jendela.',
     '00000000-0000-4000-a000-000000000012'),
    ('00000000-0000-4000-d000-000000000006', '00000000-0000-4000-c000-000000000002', -1, '08:20',
     'Ceria', 'Nafsu makan bagus, litter box normal. Siap dijemput besok.',
     '00000000-0000-4000-a000-000000000012'),
    ('00000000-0000-4000-d000-000000000007', '00000000-0000-4000-c000-000000000006', -19, '08:00',
     'Tenang', 'Makan habis, banyak tidur.',
     '00000000-0000-4000-a000-000000000012'),
    ('00000000-0000-4000-d000-000000000008', '00000000-0000-4000-c000-000000000006', -16, '08:10',
     'Ceria', 'Grooming selesai, kuku sudah dipotong.',
     '00000000-0000-4000-a000-000000000012')
) as l (id, booking_id, day_offset, eating_time, pet_mood, note, noted_by)
join bookings b on b.id = l.booking_id
on conflict (id) do nothing;

insert into room_blocks (id, room_id, date_start, date_end, blocked_units, purpose, created_by)
select
    '00000000-0000-4000-e000-000000000001', r.id,
    current_date + 12, current_date + 14, 1, 'Maintenance',
    '00000000-0000-4000-a000-000000000001'
from rooms r
where r.room_type = 'Standard'
on conflict (id) do nothing;
