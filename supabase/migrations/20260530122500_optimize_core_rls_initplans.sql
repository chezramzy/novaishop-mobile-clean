-- Optimize core RLS policies by wrapping auth/helper calls in SELECT so they
-- are evaluated once per statement instead of per row.

drop policy if exists "users create own profile" on public.users;
create policy "users create own profile"
  on public.users for insert
  to authenticated
  with check (id = (select auth.uid()));

drop policy if exists "users read own or admin" on public.users;
create policy "users read own or admin"
  on public.users for select
  to authenticated
  using (id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "users update own or admin" on public.users;
create policy "users update own or admin"
  on public.users for update
  to authenticated
  using (id = (select auth.uid()) or (select public.is_admin()))
  with check (id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "partners create own application" on public.partner_applications;
create policy "partners create own application"
  on public.partner_applications for insert
  to authenticated
  with check (
    applicant_user_id = ((select auth.uid())::text)
    and status = 'new'
    and jsonb_typeof(product_images) = 'array'
    and jsonb_array_length(product_images) = 3
  );

drop policy if exists "partners read own application or admin" on public.partner_applications;
create policy "partners read own application or admin"
  on public.partner_applications for select
  to authenticated
  using (
    applicant_user_id = ((select auth.uid())::text)
    or (select public.is_admin())
  );

drop policy if exists "admins update partner applications" on public.partner_applications;
create policy "admins update partner applications"
  on public.partner_applications for update
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

drop policy if exists "vendors read own or admin" on public.vendors;
create policy "vendors read own or admin"
  on public.vendors for select
  to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "vendors update own internal profile or admin" on public.vendors;
create policy "vendors update own internal profile or admin"
  on public.vendors for update
  to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()))
  with check (user_id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "admins insert vendors" on public.vendors;
create policy "admins insert vendors"
  on public.vendors for insert
  to authenticated
  with check ((select public.is_admin()));

drop policy if exists "notifications read own or admin" on public.notifications;
create policy "notifications read own or admin"
  on public.notifications for select
  to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "notifications mark own read" on public.notifications;
create policy "notifications mark own read"
  on public.notifications for update
  to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()))
  with check (user_id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "admins create notifications" on public.notifications;
create policy "admins create notifications"
  on public.notifications for insert
  to authenticated
  with check ((select public.is_admin()));

drop policy if exists "orders create own" on public.orders;
create policy "orders create own"
  on public.orders for insert
  to authenticated
  with check (customer_id = (select auth.uid()));

drop policy if exists "orders read own or admin" on public.orders;
create policy "orders read own or admin"
  on public.orders for select
  to authenticated
  using (customer_id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "admins update orders" on public.orders;
create policy "admins update orders"
  on public.orders for update
  to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

drop policy if exists "partners and admins read internal listings" on public.listings;
create policy "partners and admins read internal listings"
  on public.listings for select
  to authenticated
  using (
    (select public.is_admin())
    or partner_user_id = ((select auth.uid())::text)
  );

drop policy if exists "partners update own listings or admin" on public.listings;
create policy "partners update own listings or admin"
  on public.listings for update
  to authenticated
  using (
    (select public.is_admin())
    or partner_user_id = ((select auth.uid())::text)
  )
  with check (
    (select public.is_admin())
    or (
      partner_user_id = ((select auth.uid())::text)
      and status in ('draft', 'pending_review', 'rejected', 'archived')
    )
  );

drop policy if exists "delivery drivers own or admin read" on public.delivery_drivers;
create policy "delivery drivers own or admin read"
  on public.delivery_drivers for select
  to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "delivery drivers own or admin update" on public.delivery_drivers;
create policy "delivery drivers own or admin update"
  on public.delivery_drivers for update
  to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()))
  with check (user_id = (select auth.uid()) or (select public.is_admin()));

drop policy if exists "device tokens own access" on public.device_tokens;
create policy "device tokens own access"
  on public.device_tokens for all
  to authenticated
  using (user_id = (select auth.uid()) or (select public.is_admin()))
  with check (user_id = (select auth.uid()) or (select public.is_admin()));
