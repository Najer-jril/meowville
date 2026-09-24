-- Admin membuat akun penjaga atau admin lain tanpa keluar dari sesinya.
--
-- auth.signUp dari aplikasi tidak bisa dipakai untuk ini:
--   1. sesi admin tertimpa oleh sesi akun baru,
--   2. trigger handle_new_auth_user menjepit role ke pet_owner/pet_sitter,
--      jadi akun admin mustahil dibuat,
--   3. users.created_by tidak pernah terisi.
-- Fungsi ini menulis auth.users dan auth.identities langsung, lalu menetapkan
-- role dan created_by pada baris public.users yang dibuat trigger.

create or replace function admin_create_staff_account(
    p_name text,
    p_email text,
    p_password text,
    p_role user_role
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
    v_admin_id uuid := auth.uid();
    v_user_id uuid := gen_random_uuid();
    v_name text := btrim(coalesce(p_name, ''));
    v_email text := lower(btrim(coalesce(p_email, '')));
begin
    if v_admin_id is null or current_role_name() is distinct from 'admin' then
        raise exception 'Hanya admin yang boleh membuat akun staf.'
            using errcode = '42501';
    end if;

    -- 22023 dibaca aplikasi sebagai galat isian; pesannya tampil apa adanya.
    if p_role is null or p_role not in ('pet_sitter', 'admin') then
        raise exception 'Hak akses staf harus penjaga atau admin.'
            using errcode = '22023';
    end if;
    if v_name = '' or length(v_name) > 100 then
        raise exception 'Nama lengkap wajib diisi, maksimal 100 karakter.'
            using errcode = '22023';
    end if;
    if v_email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
       or length(v_email) > 150 then
        raise exception 'Format email belum benar, contoh nama@contoh.com.'
            using errcode = '22023';
    end if;
    if length(coalesce(p_password, '')) < 8 then
        raise exception 'Kata sandi minimal 8 karakter.'
            using errcode = '22023';
    end if;

    if exists (select 1 from auth.users where lower(email) = v_email)
       or exists (select 1 from users where lower(email) = v_email) then
        raise exception 'Email ini sudah dipakai akun lain.'
            using errcode = '23505';
    end if;

    -- Kolom token diisi string kosong, bukan NULL: GoTrue gagal memindai NULL
    -- pada kolom ini saat akun tersebut masuk.
    insert into auth.users (
        instance_id, id, aud, role, email, encrypted_password,
        email_confirmed_at, raw_app_meta_data, raw_user_meta_data,
        created_at, updated_at,
        confirmation_token, recovery_token, email_change_token_new, email_change
    ) values (
        '00000000-0000-0000-0000-000000000000', v_user_id,
        'authenticated', 'authenticated', v_email,
        crypt(p_password, gen_salt('bf')),
        now(),
        jsonb_build_object('provider', 'email', 'providers', jsonb_build_array('email')),
        jsonb_build_object('name', v_name, 'whatsapp_number', '', 'role', p_role::text),
        now(), now(),
        '', '', '', ''
    );

    insert into auth.identities (
        provider_id, user_id, identity_data, provider,
        last_sign_in_at, created_at, updated_at
    ) values (
        v_user_id::text, v_user_id,
        jsonb_build_object('sub', v_user_id::text, 'email', v_email, 'email_verified', true),
        'email',
        now(), now(), now()
    );

    -- Trigger on_auth_user_created sudah menyisipkan baris users dengan role
    -- terjepit (admin menjadi pet_owner). Tetapkan role dan pembuatnya di sini.
    update users
    set role = p_role,
        created_by = v_admin_id
    where id = v_user_id;

    return v_user_id;
end;
$$;

revoke all on function admin_create_staff_account(text, text, text, user_role)
    from public, anon;
grant execute on function admin_create_staff_account(text, text, text, user_role)
    to authenticated;
