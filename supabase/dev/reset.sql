-- Hanya untuk project dev. Menghapus semua tabel, fungsi, dan user.
-- File di Storage tidak ikut terhapus. Kosongkan bucket dari dashboard kalau perlu.

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user();
drop function if exists public.create_profile(auth.users);

drop policy if exists "upload to own folder" on storage.objects;
drop policy if exists "staff upload report photos" on storage.objects;
drop policy if exists "admin upload room photos" on storage.objects;
drop policy if exists "read payment proofs" on storage.objects;
drop policy if exists "list own files" on storage.objects;
drop policy if exists "delete own files" on storage.objects;

drop table if exists
  public.daily_reports, public.unit_blocks, public.reservation_addons, public.reservations,
  public.addons, public.room_types, public.cats, public.profiles
cascade;

drop function if exists public.my_role, public.guard_profile_update,
  public.guard_room_type_update, public.room_availability,
  public.create_reservation, public.cancel_reservation,
  public.upload_payment_proof, public.approve_reservation,
  public.reject_reservation, public.check_in_reservation,
  public.check_out_reservation, public.add_unit_block,
  public.delete_cat, public.set_user_role, public.delete_my_account,
  public.require_role, public.today_wib cascade;

delete from auth.users;
