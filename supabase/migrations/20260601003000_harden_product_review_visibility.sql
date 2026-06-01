drop policy if exists "reviews public read" on public.reviews;
drop policy if exists "reviews published or related read" on public.reviews;
create policy "reviews published or related read"
  on public.reviews for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.listings l
      where l.id = reviews.listing_id
        and l.status = 'published'
    )
    or (select public.is_admin())
    or customer_id = (select auth.uid())
    or exists (
      select 1
      from public.listings l
      where l.id = reviews.listing_id
        and l.partner_user_id = ((select auth.uid())::text)
    )
  );

drop policy if exists "reviews create own" on public.reviews;
drop policy if exists "reviews create own published listing" on public.reviews;
create policy "reviews create own published listing"
  on public.reviews for insert
  to authenticated
  with check (
    customer_id = (select auth.uid())
    and exists (
      select 1
      from public.listings l
      where l.id = reviews.listing_id
        and l.status = 'published'
    )
  );
