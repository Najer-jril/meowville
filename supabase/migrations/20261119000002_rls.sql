-- 002_rls.sql

-- Bersihkan policy lama kalau project pernah memakai schema.sql
do $$
declare t text;
begin
  foreach t in array array['profiles','cats','room_types','addons','reservations',
                           'reservation_addons','unit_blocks','daily_reports']
  loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists "dev full access" on public.%I', t);
  end loop;
end $$;

-- profiles
create policy "profiles read" on public.profiles for select to authenticated
  using (
    id = auth.uid()
    or role in ('admin', 'sitter')
    or public.my_role() in ('admin', 'sitter')
  );
create policy "profiles update" on public.profiles for update to authenticated
  using (id = auth.uid() or public.my_role() = 'admin')
  with check (id = auth.uid() or public.my_role() = 'admin');

-- cats
create policy "cats read" on public.cats for select to authenticated
  using (owner_id = auth.uid() or public.my_role() in ('admin', 'sitter'));
create policy "cats insert" on public.cats for insert to authenticated
  with check (owner_id = auth.uid());
create policy "cats update" on public.cats for update to authenticated
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

-- room_types
create policy "room types read" on public.room_types for select to authenticated
  using (true);
create policy "room types write" on public.room_types for all to authenticated
  using (public.my_role() = 'admin')
  with check (public.my_role() = 'admin');

-- addons
create policy "addons read" on public.addons for select to authenticated
  using (true);
create policy "addons write" on public.addons for all to authenticated
  using (public.my_role() = 'admin')
  with check (public.my_role() = 'admin');

-- reservations
create policy "reservations read" on public.reservations for select to authenticated
  using (owner_id = auth.uid() or public.my_role() in ('admin', 'sitter'));

-- reservation_addons
create policy "reservation addons read" on public.reservation_addons for select to authenticated
  using (exists (select 1 from public.reservations r where r.id = reservation_id));

-- unit_blocks
create policy "blocks read" on public.unit_blocks for select to authenticated
  using (true);
create policy "blocks delete" on public.unit_blocks for delete to authenticated
  using (public.my_role() = 'admin');

-- daily_reports
create policy "reports read" on public.daily_reports for select to authenticated
  using (
    public.my_role() in ('admin', 'sitter')
    or exists (
      select 1 from public.reservations r
      where r.id = reservation_id and r.owner_id = auth.uid()
    )
  );
create policy "reports insert" on public.daily_reports for insert to authenticated
  with check (
    reporter_id = auth.uid()
    and public.my_role() in ('admin', 'sitter')
    and exists (
      select 1 from public.reservations r
      where r.id = reservation_id and r.status = 'checked_in'
    )
  );

-- Fungsi hanya boleh dipanggil user yang login
revoke execute on all functions in schema public from public, anon;
grant execute on all functions in schema public to authenticated;
alter default privileges in schema public revoke execute on functions from public, anon;
