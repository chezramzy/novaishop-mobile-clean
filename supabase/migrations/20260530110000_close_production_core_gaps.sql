create extension if not exists pgcrypto;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'private-kyc',
  'private-kyc',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update
set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create table if not exists public.addresses (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null references public.users(id) on delete cascade,
  label text not null,
  line text not null,
  city text not null,
  country text not null default 'France',
  phone text not null,
  is_default boolean not null default false,
  map_image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wishlist_items (
  id text primary key default gen_random_uuid()::text,
  user_id uuid not null references public.users(id) on delete cascade,
  listing_id text not null references public.listings(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, listing_id)
);

create table if not exists public.product_variants (
  id text primary key default gen_random_uuid()::text,
  listing_id text not null references public.listings(id) on delete cascade,
  options jsonb not null default '{}'::jsonb,
  price numeric(12, 2),
  inventory integer not null default 0 check (inventory >= 0),
  image_url text,
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.listing_images (
  id text primary key default gen_random_uuid()::text,
  listing_id text not null references public.listings(id) on delete cascade,
  bucket text not null default 'novaishop-media',
  object_key text,
  url text not null,
  sort_order integer not null default 0,
  is_primary boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists addresses_user_idx on public.addresses(user_id, created_at desc);
create index if not exists wishlist_items_user_idx on public.wishlist_items(user_id, created_at desc);
create index if not exists wishlist_items_listing_idx on public.wishlist_items(listing_id);
create index if not exists product_variants_listing_idx on public.product_variants(listing_id, active, sort_order);
create index if not exists listing_images_listing_idx on public.listing_images(listing_id, sort_order);
create index if not exists listings_partner_user_idx on public.listings(partner_user_id);
create index if not exists listings_status_created_idx on public.listings(status, created_at desc);
create index if not exists notifications_user_read_idx on public.notifications(user_id, read, created_at desc);

drop trigger if exists set_addresses_updated_at on public.addresses;
create trigger set_addresses_updated_at
before update on public.addresses
for each row execute function public.set_updated_at();

drop trigger if exists set_product_variants_updated_at on public.product_variants;
create trigger set_product_variants_updated_at
before update on public.product_variants
for each row execute function public.set_updated_at();

alter table public.addresses enable row level security;
alter table public.wishlist_items enable row level security;
alter table public.product_variants enable row level security;
alter table public.listing_images enable row level security;

drop policy if exists "addresses own access" on public.addresses;
create policy "addresses own access" on public.addresses
  for all to authenticated
  using (user_id = (select auth.uid()) or public.is_admin())
  with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists "wishlist own access" on public.wishlist_items;
create policy "wishlist own access" on public.wishlist_items
  for all to authenticated
  using (user_id = (select auth.uid()) or public.is_admin())
  with check (user_id = (select auth.uid()) or public.is_admin());

drop policy if exists "product variants public published read" on public.product_variants;
create policy "product variants public published read" on public.product_variants
  for select to anon, authenticated
  using (
    exists (
      select 1 from public.listings l
      where l.id = product_variants.listing_id
        and (
          l.status = 'published'
          or public.is_admin()
          or l.partner_user_id = (select auth.uid())::text
        )
    )
  );

drop policy if exists "product variants partner admin write" on public.product_variants;
create policy "product variants partner admin write" on public.product_variants
  for all to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.listings l
      where l.id = product_variants.listing_id
        and l.partner_user_id = (select auth.uid())::text
    )
  )
  with check (
    public.is_admin()
    or exists (
      select 1 from public.listings l
      where l.id = product_variants.listing_id
        and l.partner_user_id = (select auth.uid())::text
    )
  );

drop policy if exists "listing images public published read" on public.listing_images;
create policy "listing images public published read" on public.listing_images
  for select to anon, authenticated
  using (
    exists (
      select 1 from public.listings l
      where l.id = listing_images.listing_id
        and (
          l.status = 'published'
          or public.is_admin()
          or l.partner_user_id = (select auth.uid())::text
        )
    )
  );

drop policy if exists "listing images partner admin write" on public.listing_images;
create policy "listing images partner admin write" on public.listing_images
  for all to authenticated
  using (
    public.is_admin()
    or exists (
      select 1 from public.listings l
      where l.id = listing_images.listing_id
        and l.partner_user_id = (select auth.uid())::text
    )
  )
  with check (
    public.is_admin()
    or exists (
      select 1 from public.listings l
      where l.id = listing_images.listing_id
        and l.partner_user_id = (select auth.uid())::text
    )
  );

drop policy if exists "approved partners submit pending listings" on public.listings;
create policy "approved partners submit pending listings"
  on public.listings for insert
  to authenticated
  with check (
    status = 'pending_review'
    and partner_user_id = (select auth.uid())::text
    and exists (
      select 1
      from public.vendors v
      where v.id = listings.vendor_id
        and v.shop_id = listings.shop_id
        and v.user_id = (select auth.uid())
        and v.kyc_status = 'approved'
    )
  );

drop policy if exists "vendor reviews public read" on public.vendor_reviews;
drop policy if exists "vendor reviews internal read" on public.vendor_reviews;
create policy "vendor reviews internal read" on public.vendor_reviews
  for select to authenticated
  using (
    public.is_admin()
    or customer_id = (select auth.uid())
    or exists (
      select 1 from public.vendors v
      where v.id = vendor_reviews.vendor_id
        and v.user_id = (select auth.uid())
    )
  );

drop policy if exists "storage private kyc owner upload" on storage.objects;
create policy "storage private kyc owner upload"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'private-kyc'
    and (storage.foldername(name))[1] = 'uploads'
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );

drop policy if exists "storage private kyc owner admin read" on storage.objects;
create policy "storage private kyc owner admin read"
  on storage.objects for select
  to authenticated
  using (
    bucket_id = 'private-kyc'
    and (
      public.is_admin()
      or (
        (storage.foldername(name))[1] = 'uploads'
        and (storage.foldername(name))[2] = (select auth.uid())::text
      )
    )
  );

drop policy if exists "storage private kyc owner update" on storage.objects;
create policy "storage private kyc owner update"
  on storage.objects for update
  to authenticated
  using (
    bucket_id = 'private-kyc'
    and (storage.foldername(name))[1] = 'uploads'
    and (storage.foldername(name))[2] = (select auth.uid())::text
  )
  with check (
    bucket_id = 'private-kyc'
    and (storage.foldername(name))[1] = 'uploads'
    and (storage.foldername(name))[2] = (select auth.uid())::text
  );

create or replace function public.submit_partner_listing(
  p_category_id text,
  p_title text,
  p_description text,
  p_price numeric,
  p_inventory integer,
  p_category_type text default 'product',
  p_currency text default 'XOF',
  p_image_url text default null,
  p_attributes jsonb default '{}'::jsonb,
  p_variants jsonb default '[]'::jsonb,
  p_images jsonb default '[]'::jsonb
)
returns public.listings
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  partner_vendor public.vendors;
  inserted_listing public.listings;
  base_slug text;
  resolved_slug text;
  variant jsonb;
  image jsonb;
  variant_options jsonb;
  variant_price numeric;
  variant_inventory integer;
  variant_image text;
  image_url text;
begin
  if actor is null then
    raise exception 'Authentication required';
  end if;

  select * into partner_vendor
  from public.vendors
  where user_id = actor and kyc_status = 'approved'
  limit 1;

  if not found then
    raise exception 'Approved partner profile required';
  end if;

  if nullif(trim(p_title), '') is null then
    raise exception 'Product title is required';
  end if;

  if p_price < 0 or p_inventory < 0 then
    raise exception 'Invalid price or inventory';
  end if;

  base_slug := regexp_replace(lower(trim(p_title)), '[^a-z0-9]+', '-', 'g');
  base_slug := trim(both '-' from base_slug);
  if base_slug = '' then
    base_slug := 'produit';
  end if;
  resolved_slug := base_slug || '-' || substr(gen_random_uuid()::text, 1, 8);

  insert into public.listings (
    vendor_id,
    shop_id,
    category_id,
    category_type,
    slug,
    title,
    description,
    status,
    price,
    currency,
    inventory,
    featured,
    image_url,
    attributes,
    partner_user_id
  )
  values (
    partner_vendor.id,
    partner_vendor.shop_id,
    p_category_id,
    p_category_type,
    resolved_slug,
    trim(p_title),
    trim(p_description),
    'pending_review',
    p_price,
    p_currency,
    p_inventory,
    false,
    nullif(trim(coalesce(p_image_url, '')), ''),
    coalesce(p_attributes, '{}'::jsonb) || jsonb_build_object(
      'partnerUserId', actor::text,
      'submittedFrom', 'mobile_app'
    ),
    actor::text
  )
  returning * into inserted_listing;

  if jsonb_typeof(coalesce(p_variants, '[]'::jsonb)) = 'array' then
    for variant in select * from jsonb_array_elements(coalesce(p_variants, '[]'::jsonb))
    loop
      variant_options := coalesce(variant->'options', '{}'::jsonb);
      variant_price := nullif(variant->>'price', '')::numeric;
      variant_inventory := coalesce(nullif(variant->>'inventory', '')::integer, p_inventory);
      variant_image := nullif(trim(coalesce(variant->>'imageUrl', variant->>'image_url', '')), '');

      insert into public.product_variants (
        listing_id,
        options,
        price,
        inventory,
        image_url,
        sort_order
      )
      values (
        inserted_listing.id,
        variant_options,
        variant_price,
        variant_inventory,
        variant_image,
        coalesce(nullif(variant->>'sortOrder', '')::integer, 0)
      );
    end loop;
  end if;

  if jsonb_typeof(coalesce(p_images, '[]'::jsonb)) = 'array' then
    for image in select * from jsonb_array_elements(coalesce(p_images, '[]'::jsonb))
    loop
      image_url := nullif(trim(coalesce(image->>'url', image->>'publicUrl', '')), '');
      if image_url is not null then
        insert into public.listing_images (
          listing_id,
          bucket,
          object_key,
          url,
          sort_order,
          is_primary
        )
        values (
          inserted_listing.id,
          coalesce(nullif(image->>'bucket', ''), 'novaishop-media'),
          nullif(image->>'objectKey', ''),
          image_url,
          coalesce(nullif(image->>'sortOrder', '')::integer, 0),
          coalesce((image->>'isPrimary')::boolean, false)
        );
      end if;
    end loop;
  end if;

  insert into public.audit_events (actor_id, action, entity_type, entity_id, metadata)
  values (
    actor,
    'partner_listing_submitted',
    'listing',
    inserted_listing.id,
    jsonb_build_object('status', 'pending_review')
  );

  return inserted_listing;
end;
$$;

create or replace function public.review_listing(
  p_listing_id text,
  p_approve boolean,
  p_note text default null
)
returns public.listings
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  reviewed public.listings;
  partner uuid;
  next_status text := case when p_approve then 'published' else 'rejected' end;
begin
  if actor is null or not public.is_admin() then
    raise exception 'Admin privileges required';
  end if;

  update public.listings
  set status = next_status,
      updated_at = now()
  where id = p_listing_id
  returning * into reviewed;

  if not found then
    raise exception 'Listing not found';
  end if;

  if not p_approve then
    insert into public.listing_rejections (listing_id, actor_id, reason)
    values (p_listing_id, actor, coalesce(nullif(trim(p_note), ''), 'Produit refuse par moderation'));
  end if;

  if reviewed.partner_user_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
    partner := reviewed.partner_user_id::uuid;
    insert into public.notifications (user_id, type, title, message, link)
    values (
      partner,
      case when p_approve then 'listing_approved' else 'listing_rejected' end,
      case when p_approve then 'Produit publie' else 'Produit refuse' end,
      case
        when p_approve then 'Votre produit "' || reviewed.title || '" est publie dans le catalogue NovaShop.'
        else 'Votre produit "' || reviewed.title || '" a ete refuse. Consultez la note admin.'
      end,
      '/partner/products'
    );
  end if;

  insert into public.audit_events (actor_id, action, entity_type, entity_id, metadata)
  values (
    actor,
    case when p_approve then 'listing_approved' else 'listing_rejected' end,
    'listing',
    p_listing_id,
    jsonb_build_object('note', p_note)
  );

  return reviewed;
end;
$$;

create or replace function public.create_order_conversation_from_cart(
  p_items jsonb
)
returns public.conversations
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  item jsonb;
  listing_row public.listings;
  variant_row public.product_variants;
  conversation_row public.conversations;
  qty integer;
  item_listing_id text;
  item_variant_id text;
  item_options jsonb;
  unit_amount numeric(12, 2);
  line_total numeric(12, 2);
  order_total numeric(12, 2) := 0;
  summary text := 'Nouvelle demande de commande:';
begin
  if actor is null then
    raise exception 'Authentication required';
  end if;

  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Cart is empty';
  end if;

  insert into public.conversations (customer_id, status, title, total_amount)
  values (actor, 'awaiting_confirmation', 'Commande NovaShop', 0)
  returning * into conversation_row;

  insert into public.conversation_participants (
    conversation_id,
    user_id,
    role,
    display_as
  )
  values (conversation_row.id, actor, 'customer', 'NovaShop')
  on conflict (conversation_id, user_id) do nothing;

  for item in select * from jsonb_array_elements(p_items)
  loop
    item_listing_id := item->>'listingId';
    item_variant_id := nullif(item->>'variantId', '');
    qty := coalesce(nullif(item->>'quantity', '')::integer, 0);
    item_options := coalesce(item->'options', '{}'::jsonb);

    if qty <= 0 then
      raise exception 'Invalid quantity';
    end if;

    select * into listing_row
    from public.listings
    where id = item_listing_id
      and status = 'published'
    for share;

    if not found then
      raise exception 'Product unavailable';
    end if;

    unit_amount := listing_row.price;

    if item_variant_id is not null then
      select * into variant_row
      from public.product_variants
      where id = item_variant_id
        and listing_id = listing_row.id
        and active = true
      for share;

      if not found then
        raise exception 'Variant unavailable';
      end if;

      if variant_row.inventory < qty then
        raise exception 'Variant stock unavailable';
      end if;

      unit_amount := coalesce(variant_row.price, listing_row.price);
      item_options := coalesce(variant_row.options, item_options);
    elsif listing_row.inventory < qty then
      raise exception 'Product stock unavailable';
    end if;

    line_total := unit_amount * qty;
    order_total := order_total + line_total;
    summary := summary || E'\n- ' || qty || ' x ' || listing_row.title;

    insert into public.conversation_order_items (
      conversation_id,
      listing_id,
      variant_id,
      title,
      quantity,
      unit_price,
      total_price,
      options
    )
    values (
      conversation_row.id,
      listing_row.id,
      item_variant_id,
      listing_row.title,
      qty,
      unit_amount,
      line_total,
      item_options
    );
  end loop;

  summary := summary || E'\nTotal estime: ' || round(order_total)::text || ' XOF';

  update public.conversations
  set total_amount = order_total,
      updated_at = now()
  where id = conversation_row.id
  returning * into conversation_row;

  insert into public.conversation_messages (
    conversation_id,
    author,
    sender_id,
    body
  )
  values (
    conversation_row.id,
    'system',
    actor,
    summary
  );

  insert into public.conversation_events (conversation_id, event_type, payload)
  values (
    conversation_row.id,
    'created_from_cart',
    jsonb_build_object('total', order_total, 'itemCount', jsonb_array_length(p_items))
  );

  return conversation_row;
end;
$$;

grant execute on function public.submit_partner_listing(
  text,
  text,
  text,
  numeric,
  integer,
  text,
  text,
  text,
  jsonb,
  jsonb,
  jsonb
) to authenticated;

grant execute on function public.review_listing(text, boolean, text) to authenticated;
grant execute on function public.create_order_conversation_from_cart(jsonb) to authenticated;
