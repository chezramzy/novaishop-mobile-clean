do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'listings'
      and policyname = 'mobile partners can submit pending listings'
  ) then
    create policy "mobile partners can submit pending listings"
      on public.listings for insert
      to anon, authenticated
      with check (
        status = 'pending_review'
        and coalesce(attributes->>'submittedFrom', '') = 'mobile_app'
      );
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'listings'
      and policyname = 'mobile admin can read listings for moderation'
  ) then
    create policy "mobile admin can read listings for moderation"
      on public.listings for select
      to anon, authenticated
      using (true);
  end if;

  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'listings'
      and policyname = 'mobile admin can update listing moderation status'
  ) then
    create policy "mobile admin can update listing moderation status"
      on public.listings for update
      to anon, authenticated
      using (true)
      with check (status in ('pending_review', 'published', 'rejected', 'archived'));
  end if;
end $$;

alter table public.listings
  add column if not exists partner_user_id text;

create index if not exists listings_partner_user_id_idx
  on public.listings(partner_user_id);

create index if not exists listings_status_created_at_idx
  on public.listings(status, created_at desc);
