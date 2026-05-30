-- Keep category reads on the existing public policy and avoid duplicate
-- permissive SELECT policies for authenticated users.

drop policy if exists "admins manage categories" on public.categories;

drop policy if exists "admins insert categories" on public.categories;
create policy "admins insert categories"
  on public.categories
  for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "admins update categories" on public.categories;
create policy "admins update categories"
  on public.categories
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop index if exists public.listings_partner_user_idx;
drop index if exists public.listings_status_created_idx;
