drop policy if exists "public reads published listings" on public.listings;
create policy "public reads published listings"
  on public.listings for select
  to anon, authenticated
  using (status = 'published');

drop policy if exists "partners and admins read internal listings" on public.listings;
create policy "partners and admins read internal listings"
  on public.listings for select
  to authenticated
  using (public.is_admin() or partner_user_id = auth.uid()::text);

revoke execute on function public.current_app_role() from anon;
revoke execute on function public.is_admin() from anon;
revoke execute on function public.is_partner() from anon;
