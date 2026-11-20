update storage.buckets set public = false
where id in ('avatars', 'cat-photos', 'report-photos');

-- URL publik lama menjadi path.
update public.profiles
set photo = regexp_replace(photo, '^https?://[^/]+/storage/v1/object/public/', '')
where photo ~ '/storage/v1/object/public/avatars/';

update public.cats
set photo = regexp_replace(photo, '^https?://[^/]+/storage/v1/object/public/', '')
where photo ~ '/storage/v1/object/public/cat-photos/';

update public.daily_reports
set photo = regexp_replace(photo, '^https?://[^/]+/storage/v1/object/public/', '')
where photo ~ '/storage/v1/object/public/report-photos/';

-- Foto hanya boleh file di folder pemiliknya sendiri, bukan URL luar.
alter table public.profiles add constraint profiles_photo_path check (
  photo is null
  or photo ~ ('^avatars/' || id::text || '/[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$')
) not valid;

alter table public.cats add constraint cats_photo_path check (
  photo is null
  or photo ~ ('^cat-photos/' || owner_id::text || '/[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$')
) not valid;

alter table public.daily_reports add constraint daily_reports_photo_path check (
  photo is null
  or photo ~ ('^report-photos/' || reporter_id::text || '/[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$')
) not valid;

-- Baca: pemilik folder (policy "list own files"), staf untuk semua foto,
-- owner untuk foto laporan reservasinya sendiri. Subquery daily_reports
-- tunduk pada RLS daily_reports, jadi owner hanya melihat laporannya.
create policy "staff read photos" on storage.objects for select to authenticated
  using (
    bucket_id in ('avatars', 'cat-photos', 'report-photos')
    and (select public.my_role()) in ('admin', 'sitter')
  );

create policy "owner read report photos" on storage.objects for select to authenticated
  using (
    bucket_id = 'report-photos'
    and exists (
      select 1 from public.daily_reports d
      where d.photo = 'report-photos/' || name
    )
  );
