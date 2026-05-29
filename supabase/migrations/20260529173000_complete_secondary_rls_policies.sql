create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke execute on function public.current_app_role() from anon, authenticated;
revoke execute on function public.is_admin() from anon, authenticated;
revoke execute on function public.is_partner() from anon, authenticated;
revoke execute on function public.review_partner_application(uuid, boolean, text) from anon;
grant execute on function public.review_partner_application(uuid, boolean, text) to authenticated;

drop policy if exists "storage public novaishop reads" on storage.objects;

drop policy if exists "audit events admin read" on public.audit_events;
create policy "audit events admin read" on public.audit_events for select to authenticated using (public.is_admin());

drop policy if exists "coupons public active read" on public.coupons;
create policy "coupons public active read" on public.coupons for select to anon, authenticated using (active = true);
drop policy if exists "coupons admin manage" on public.coupons;
create policy "coupons admin manage" on public.coupons for all to authenticated using (public.is_admin()) with check (public.is_admin());

drop policy if exists "coupon usages own or admin read" on public.coupon_usages;
create policy "coupon usages own or admin read" on public.coupon_usages for select to authenticated using (user_id = auth.uid() or public.is_admin());

drop policy if exists "delivery drivers own or admin read" on public.delivery_drivers;
create policy "delivery drivers own or admin read" on public.delivery_drivers for select to authenticated using (user_id = auth.uid() or public.is_admin());
drop policy if exists "delivery drivers own or admin update" on public.delivery_drivers;
create policy "delivery drivers own or admin update" on public.delivery_drivers for update to authenticated using (user_id = auth.uid() or public.is_admin()) with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "deliveries related read" on public.deliveries;
create policy "deliveries related read" on public.deliveries for select to authenticated using (
  public.is_admin()
  or exists (select 1 from public.orders o where o.id = deliveries.order_id and o.customer_id = auth.uid())
  or exists (select 1 from public.delivery_drivers d where d.id = deliveries.driver_id and d.user_id = auth.uid())
);

drop policy if exists "kyc documents own vendor or admin read" on public.kyc_documents;
create policy "kyc documents own vendor or admin read" on public.kyc_documents for select to authenticated using (
  public.is_admin()
  or exists (select 1 from public.vendors v where v.id = kyc_documents.vendor_id and v.user_id = auth.uid())
);

drop policy if exists "media owner or admin read" on public.media;
create policy "media owner or admin read" on public.media for select to authenticated using (owner_user_id = auth.uid() or public.is_admin());

drop policy if exists "moderation cases admin read" on public.moderation_cases;
create policy "moderation cases admin read" on public.moderation_cases for select to authenticated using (public.is_admin());

drop policy if exists "listing rejections admin read" on public.listing_rejections;
create policy "listing rejections admin read" on public.listing_rejections for select to authenticated using (public.is_admin());

drop policy if exists "payments related read" on public.payments;
create policy "payments related read" on public.payments for select to authenticated using (
  public.is_admin()
  or exists (select 1 from public.orders o where o.id = payments.order_id and o.customer_id = auth.uid())
);

drop policy if exists "payment events admin read" on public.payment_events;
create policy "payment events admin read" on public.payment_events for select to authenticated using (public.is_admin());

drop policy if exists "payout accounts vendor or admin read" on public.payout_accounts;
create policy "payout accounts vendor or admin read" on public.payout_accounts for select to authenticated using (
  public.is_admin()
  or exists (select 1 from public.vendors v where v.id = payout_accounts.vendor_id and v.user_id = auth.uid())
);

drop policy if exists "refunds related read" on public.refunds;
create policy "refunds related read" on public.refunds for select to authenticated using (
  public.is_admin()
  or exists (select 1 from public.orders o where o.id = refunds.order_id and o.customer_id = auth.uid())
);

drop policy if exists "seller order groups vendor or admin read" on public.seller_order_groups;
create policy "seller order groups vendor or admin read" on public.seller_order_groups for select to authenticated using (
  public.is_admin()
  or exists (select 1 from public.vendors v where v.id = seller_order_groups.vendor_id and v.user_id = auth.uid())
);

drop policy if exists "vendor reviews public read" on public.vendor_reviews;
create policy "vendor reviews public read" on public.vendor_reviews for select to anon, authenticated using (true);
