drop policy if exists "coupons public active read" on public.coupons;
drop policy if exists "coupons admin manage" on public.coupons;

drop policy if exists "coupons partner read own" on public.coupons;
create policy "coupons partner read own"
  on public.coupons for select
  to authenticated
  using (
    (select public.is_admin())
    or exists (
      select 1
      from public.vendors v
      where v.id = coupons.vendor_id
        and v.user_id = (select auth.uid())
    )
  );

drop policy if exists "coupons partner create own" on public.coupons;
create policy "coupons partner create own"
  on public.coupons for insert
  to authenticated
  with check (
    (select public.is_admin())
    or exists (
      select 1
      from public.vendors v
      where v.id = coupons.vendor_id
        and v.user_id = (select auth.uid())
        and v.kyc_status = 'approved'
    )
  );

drop policy if exists "coupons partner update own" on public.coupons;
create policy "coupons partner update own"
  on public.coupons for update
  to authenticated
  using (
    (select public.is_admin())
    or exists (
      select 1
      from public.vendors v
      where v.id = coupons.vendor_id
        and v.user_id = (select auth.uid())
    )
  )
  with check (
    (select public.is_admin())
    or exists (
      select 1
      from public.vendors v
      where v.id = coupons.vendor_id
        and v.user_id = (select auth.uid())
    )
  );

drop policy if exists "coupons admin delete" on public.coupons;
create policy "coupons admin delete"
  on public.coupons for delete
  to authenticated
  using ((select public.is_admin()));

create or replace function public.validate_coupon_code(
  p_code text,
  p_order_amount numeric default 0
)
returns table (
  id uuid,
  code text,
  discount_type text,
  discount_value numeric,
  min_order_amount numeric,
  max_uses integer,
  used_count integer,
  valid_from timestamptz,
  valid_to timestamptz,
  active boolean,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    c.id,
    c.code,
    c.discount_type,
    c.discount_value,
    coalesce(c.min_order_amount, 0) as min_order_amount,
    coalesce(c.max_uses, 0) as max_uses,
    coalesce(c.used_count, 0) as used_count,
    c.valid_from,
    c.valid_to,
    c.active,
    c.created_at
  from public.coupons c
  where c.code = upper(trim(p_code))
    and c.active = true
    and now() >= c.valid_from
    and now() <= c.valid_to
    and coalesce(p_order_amount, 0) >= coalesce(c.min_order_amount, 0)
    and (
      coalesce(c.max_uses, 0) = 0
      or coalesce(c.used_count, 0) < coalesce(c.max_uses, 0)
    )
  order by c.created_at desc
  limit 1;
$$;

revoke execute on function public.validate_coupon_code(text, numeric)
  from public, anon;
grant execute on function public.validate_coupon_code(text, numeric)
  to authenticated;
