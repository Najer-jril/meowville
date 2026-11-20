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
