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

update public.profiles p set name = s.name, role = s.role
from (values
  ('admin@gmail.com', 'Admin Meowville', 'admin'),
  ('nazeril.sitter@gmail.com', 'Nazeril Uzumaki', 'sitter'),
  ('nazril.ilham@gmail.com', 'Nazril Ilham', 'owner'),
  ('najer.pinkman@gmail.com', 'Najer Pinkman', 'owner')
) as s(email, name, role)
where p.email = s.email;
