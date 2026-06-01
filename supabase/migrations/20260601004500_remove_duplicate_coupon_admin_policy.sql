drop policy if exists "coupons admin manage" on public.coupons;

drop policy if exists "coupons admin delete" on public.coupons;
create policy "coupons admin delete"
  on public.coupons for delete
  to authenticated
  using ((select public.is_admin()));
