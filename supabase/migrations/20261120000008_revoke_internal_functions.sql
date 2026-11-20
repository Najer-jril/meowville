revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.set_reporter_name() from public, anon, authenticated;
revoke execute on function public.guard_profile_update() from public, anon, authenticated;
revoke execute on function public.guard_room_type_update() from public, anon, authenticated;
revoke execute on function public.guard_cat_update() from public, anon, authenticated;
revoke execute on function public.require_role(text[]) from public, anon, authenticated;
revoke execute on function public.valid_proof_path(text) from public, anon, authenticated;
