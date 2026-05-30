-- Allow real admin catalogue operations from the mobile admin console.

drop policy if exists "admins manage categories" on public.categories;
create policy "admins manage categories"
  on public.categories
  for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());
