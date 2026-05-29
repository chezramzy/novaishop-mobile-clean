create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.current_app_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select role from public.users where id = auth.uid()),
    'anon'
  );
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_app_role() = 'admin';
$$;

create or replace function public.is_partner()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_app_role() in ('seller', 'admin');
$$;

alter table public.partner_applications
  add column if not exists reviewed_at timestamptz,
  add column if not exists reviewed_by uuid references public.users(id);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  platform text not null check (platform in ('android', 'ios', 'web')),
  token text not null,
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

drop trigger if exists set_device_tokens_updated_at on public.device_tokens;
create trigger set_device_tokens_updated_at
before update on public.device_tokens
for each row execute function public.set_updated_at();

drop trigger if exists set_partner_applications_updated_at on public.partner_applications;
create trigger set_partner_applications_updated_at
before update on public.partner_applications
for each row execute function public.set_updated_at();

drop trigger if exists set_users_updated_at on public.users;
create trigger set_users_updated_at
before update on public.users
for each row execute function public.set_updated_at();

drop trigger if exists set_listings_updated_at on public.listings;
create trigger set_listings_updated_at
before update on public.listings
for each row execute function public.set_updated_at();

alter table public.users enable row level security;
alter table public.shops enable row level security;
alter table public.vendors enable row level security;
alter table public.categories enable row level security;
alter table public.listings enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.seller_order_groups enable row level security;
alter table public.payout_accounts enable row level security;
alter table public.payments enable row level security;
alter table public.payment_events enable row level security;
alter table public.refunds enable row level security;
alter table public.media enable row level security;
alter table public.kyc_documents enable row level security;
alter table public.moderation_cases enable row level security;
alter table public.listing_rejections enable row level security;
alter table public.audit_events enable row level security;
alter table public.reviews enable row level security;
alter table public.delivery_drivers enable row level security;
alter table public.deliveries enable row level security;
alter table public.coupons enable row level security;
alter table public.coupon_usages enable row level security;
alter table public.notifications enable row level security;
alter table public.vendor_reviews enable row level security;
alter table public.partner_applications enable row level security;
alter table public.device_tokens enable row level security;

drop policy if exists "users read own or admin" on public.users;
create policy "users read own or admin"
  on public.users for select
  to authenticated
  using (id = auth.uid() or public.is_admin());

drop policy if exists "users create own profile" on public.users;
create policy "users create own profile"
  on public.users for insert
  to authenticated
  with check (id = auth.uid());

drop policy if exists "users update own or admin" on public.users;
create policy "users update own or admin"
  on public.users for update
  to authenticated
  using (id = auth.uid() or public.is_admin())
  with check (id = auth.uid() or public.is_admin());

drop policy if exists "categories public read" on public.categories;
create policy "categories public read"
  on public.categories for select
  to anon, authenticated
  using (true);

drop policy if exists "anyone can submit partner applications" on public.partner_applications;
drop policy if exists "app can read partner application status by applicant id" on public.partner_applications;

drop policy if exists "partners create own application" on public.partner_applications;
create policy "partners create own application"
  on public.partner_applications for insert
  to authenticated
  with check (
    applicant_user_id = auth.uid()::text
    and status = 'new'
    and jsonb_typeof(product_images) = 'array'
    and jsonb_array_length(product_images) = 3
  );

drop policy if exists "partners read own application or admin" on public.partner_applications;
create policy "partners read own application or admin"
  on public.partner_applications for select
  to authenticated
  using (applicant_user_id = auth.uid()::text or public.is_admin());

drop policy if exists "admins update partner applications" on public.partner_applications;
create policy "admins update partner applications"
  on public.partner_applications for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "shops read internal owner or admin" on public.shops;
create policy "shops read internal owner or admin"
  on public.shops for select
  to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.vendors v
      where v.shop_id = shops.id and v.user_id = auth.uid()
    )
  );

drop policy if exists "admins manage shops" on public.shops;
create policy "admins manage shops"
  on public.shops for all
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "vendors read own or admin" on public.vendors;
create policy "vendors read own or admin"
  on public.vendors for select
  to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "vendors update own internal profile or admin" on public.vendors;
create policy "vendors update own internal profile or admin"
  on public.vendors for update
  to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "admins insert vendors" on public.vendors;
create policy "admins insert vendors"
  on public.vendors for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "mobile partners can submit pending listings" on public.listings;
drop policy if exists "mobile admin can read listings for moderation" on public.listings;
drop policy if exists "mobile admin can update listing moderation status" on public.listings;

drop policy if exists "public reads published listings" on public.listings;
create policy "public reads published listings"
  on public.listings for select
  to anon, authenticated
  using (
    status = 'published'
    or public.is_admin()
    or partner_user_id = auth.uid()::text
  );

drop policy if exists "approved partners submit pending listings" on public.listings;
create policy "approved partners submit pending listings"
  on public.listings for insert
  to authenticated
  with check (
    status = 'pending_review'
    and partner_user_id = auth.uid()::text
    and exists (
      select 1 from public.vendors v
      where v.user_id = auth.uid() and v.kyc_status = 'approved'
    )
  );

drop policy if exists "partners update own listings or admin" on public.listings;
create policy "partners update own listings or admin"
  on public.listings for update
  to authenticated
  using (public.is_admin() or partner_user_id = auth.uid()::text)
  with check (
    public.is_admin()
    or (
      partner_user_id = auth.uid()::text
      and status in ('draft', 'pending_review', 'rejected', 'archived')
    )
  );

drop policy if exists "notifications read own or admin" on public.notifications;
create policy "notifications read own or admin"
  on public.notifications for select
  to authenticated
  using (user_id = auth.uid() or public.is_admin());

drop policy if exists "notifications mark own read" on public.notifications;
create policy "notifications mark own read"
  on public.notifications for update
  to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "admins create notifications" on public.notifications;
create policy "admins create notifications"
  on public.notifications for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "device tokens own access" on public.device_tokens;
create policy "device tokens own access"
  on public.device_tokens for all
  to authenticated
  using (user_id = auth.uid() or public.is_admin())
  with check (user_id = auth.uid() or public.is_admin());

drop policy if exists "orders read own or admin" on public.orders;
create policy "orders read own or admin"
  on public.orders for select
  to authenticated
  using (customer_id = auth.uid() or public.is_admin());

drop policy if exists "orders create own" on public.orders;
create policy "orders create own"
  on public.orders for insert
  to authenticated
  with check (customer_id = auth.uid());

drop policy if exists "admins update orders" on public.orders;
create policy "admins update orders"
  on public.orders for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "order items read related" on public.order_items;
create policy "order items read related"
  on public.order_items for select
  to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.orders o
      where o.id = order_items.order_id and o.customer_id = auth.uid()
    )
    or exists (
      select 1 from public.vendors v
      where v.id = order_items.vendor_id and v.user_id = auth.uid()
    )
  );

drop policy if exists "conversation admin read" on public.conversations;
create policy "conversation admin read"
  on public.conversations for select
  to authenticated
  using (public.is_admin());

drop policy if exists "conversation admin update" on public.conversations;
create policy "conversation admin update"
  on public.conversations for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());

drop policy if exists "conversation messages admin read" on public.conversation_messages;
create policy "conversation messages admin read"
  on public.conversation_messages for select
  to authenticated
  using (public.is_admin());

drop policy if exists "conversation messages admin send" on public.conversation_messages;
create policy "conversation messages admin send"
  on public.conversation_messages for insert
  to authenticated
  with check (public.is_admin() and author in ('nova_shop', 'system'));

drop policy if exists "conversation items admin read" on public.conversation_order_items;
create policy "conversation items admin read"
  on public.conversation_order_items for select
  to authenticated
  using (public.is_admin());

drop policy if exists "conversation events admin read" on public.conversation_events;
create policy "conversation events admin read"
  on public.conversation_events for select
  to authenticated
  using (public.is_admin());

drop policy if exists "reviews public read" on public.reviews;
create policy "reviews public read"
  on public.reviews for select
  to anon, authenticated
  using (true);

drop policy if exists "reviews create own" on public.reviews;
create policy "reviews create own"
  on public.reviews for insert
  to authenticated
  with check (customer_id = auth.uid());

drop policy if exists "storage authenticated novaishop uploads" on storage.objects;
create policy "storage authenticated novaishop uploads"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'novaishop-media'
    and (storage.foldername(name))[1] = 'uploads'
    and (storage.foldername(name))[2] = auth.uid()::text
  );

drop policy if exists "storage public novaishop reads" on storage.objects;
create policy "storage public novaishop reads"
  on storage.objects for select
  to anon, authenticated
  using (bucket_id = 'novaishop-media');

create or replace function public.review_partner_application(
  application_id uuid,
  approve boolean,
  note text default null
)
returns public.partner_applications
language plpgsql
security definer
set search_path = public
as $$
declare
  app public.partner_applications;
  applicant uuid;
  shop_id text;
  resolved_vendor_id text;
  actor uuid := auth.uid();
  next_status text := case when approve then 'approved' else 'rejected' end;
begin
  if actor is null or not public.is_admin() then
    raise exception 'Admin privileges required';
  end if;

  select * into app
  from public.partner_applications
  where id = application_id
  for update;

  if not found then
    raise exception 'Partner application not found';
  end if;

  begin
    applicant := app.applicant_user_id::uuid;
  exception when others then
    applicant := null;
  end;

  update public.partner_applications
  set
    status = next_status,
    admin_notes = nullif(trim(coalesce(note, '')), ''),
    reviewed_at = now(),
    reviewed_by = actor
  where id = application_id
  returning * into app;

  if approve and applicant is not null then
    update public.users
    set role = 'seller'
    where id = applicant;

    select v.id, v.shop_id into resolved_vendor_id, shop_id
    from public.vendors v
    where v.user_id = applicant
    limit 1;

    if shop_id is null then
      shop_id := gen_random_uuid()::text;
      insert into public.shops (
        id,
        vendor_id,
        name,
        slug,
        description,
        focus
      )
      values (
        shop_id,
        gen_random_uuid()::text,
        'NovaShop Partner Workspace',
        'partner-' || applicant::text,
        'Internal NovaShop partner workspace',
        '["product"]'::jsonb
      );
    end if;

    if resolved_vendor_id is null then
      resolved_vendor_id := gen_random_uuid()::text;
      update public.shops
      set vendor_id = resolved_vendor_id
      where id = shop_id;

      insert into public.vendors (
        id,
        user_id,
        shop_id,
        kyc_status,
        payout_account_status,
        commission_rate,
        documents_complete,
        seller_type,
        legal_name,
        onboarding_profile
      )
      values (
        resolved_vendor_id,
        applicant,
        shop_id,
        'approved',
        'pending',
        0.12,
        false,
        null,
        null,
        jsonb_build_object(
          'partnerApplicationId', application_id,
          'source', 'mobile_app'
        )
      );
    else
      update public.vendors
      set kyc_status = 'approved',
          updated_at = now()
      where id = resolved_vendor_id;
    end if;

    insert into public.notifications (user_id, type, title, message, read, link)
    values (
      applicant,
      'partner_application_approved',
      'Demande partenaire approuvee',
      'Votre espace partenaire est actif. Vous pouvez ajouter vos produits.',
      false,
      '/partner/home'
    );
  elsif not approve and applicant is not null then
    insert into public.notifications (user_id, type, title, message, read, link)
    values (
      applicant,
      'partner_application_rejected',
      'Demande partenaire refusee',
      coalesce(nullif(trim(note), ''), 'Votre demande partenaire a ete refusee. Contactez le support pour plus de details.'),
      false,
      '/support/partner-application'
    );
  end if;

  insert into public.audit_events (actor_id, action, entity_type, entity_id, metadata)
  values (
    actor,
    case when approve then 'partner_application.approved' else 'partner_application.rejected' end,
    'partner_application',
    application_id::text,
    jsonb_build_object('note', note, 'applicantUserId', app.applicant_user_id)
  );

  return app;
end;
$$;
