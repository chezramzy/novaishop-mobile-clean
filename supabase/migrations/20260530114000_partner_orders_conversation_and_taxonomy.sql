alter table public.categories
  add column if not exists active boolean not null default true,
  add column if not exists sort_order integer not null default 0,
  add column if not exists form_template text not null default 'standard';

create index if not exists categories_parent_sort_idx
  on public.categories(parent_id, active, sort_order, name);

create or replace function public.update_partner_order_status(
  p_vendor_id text,
  p_order_id text,
  p_status text,
  p_tracking_number text default null
)
returns public.orders
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  updated_order public.orders;
  allowed_statuses text[] := array[
    'pending',
    'paid',
    'processing',
    'shipped',
    'delivered',
    'refunded',
    'cancelled'
  ];
begin
  if actor is null then
    raise exception 'Authentication required';
  end if;

  if not exists (
    select 1 from public.vendors v
    where v.id = p_vendor_id
      and (v.user_id = actor or public.is_admin())
  ) then
    raise exception 'Partner order access denied';
  end if;

  if p_status <> all(allowed_statuses) then
    raise exception 'Invalid order status';
  end if;

  update public.seller_order_groups
  set status = p_status
  where order_id = p_order_id
    and vendor_id = p_vendor_id;

  if not found then
    raise exception 'Partner order group not found';
  end if;

  if not exists (
    select 1 from public.seller_order_groups
    where order_id = p_order_id
      and status <> p_status
  ) then
    update public.orders
    set status = p_status
    where id = p_order_id
    returning * into updated_order;
  else
    select * into updated_order
    from public.orders
    where id = p_order_id;
  end if;

  insert into public.audit_events (actor_id, action, entity_type, entity_id, metadata)
  values (
    actor,
    'partner_order_status_updated',
    'order',
    p_order_id,
    jsonb_build_object(
      'vendorId', p_vendor_id,
      'status', p_status,
      'trackingNumber', nullif(trim(coalesce(p_tracking_number, '')), '')
    )
  );

  if updated_order.customer_id is not null then
    insert into public.notifications (user_id, type, title, message, link)
    values (
      updated_order.customer_id,
      'order_status',
      'Commande mise a jour',
      'Votre commande NovaShop est maintenant: ' || p_status || '.',
      '/orders'
    );
  end if;

  return updated_order;
end;
$$;

create or replace function public.confirm_order_conversation_delivery(
  p_conversation_id uuid
)
returns public.conversations
language plpgsql
security definer
set search_path = public
as $$
declare
  actor uuid := auth.uid();
  updated public.conversations;
begin
  if actor is null then
    raise exception 'Authentication required';
  end if;

  update public.conversations
  set status = 'buyer_confirmed',
      updated_at = now()
  where id = p_conversation_id
    and customer_id = actor
    and status = 'delivered'
  returning * into updated;

  if not found then
    raise exception 'Only delivered conversations can be confirmed by their buyer';
  end if;

  insert into public.conversation_messages (
    conversation_id,
    author,
    sender_id,
    body
  )
  values (
    p_conversation_id,
    'system',
    actor,
    'Livraison confirmee par l acheteur. Merci pour votre confiance.'
  );

  insert into public.conversation_events (conversation_id, event_type, payload)
  values (
    p_conversation_id,
    'buyer_confirmed_delivery',
    jsonb_build_object('confirmedBy', actor)
  );

  return updated;
end;
$$;

revoke execute on function public.update_partner_order_status(text, text, text, text)
from public, anon;
revoke execute on function public.confirm_order_conversation_delivery(uuid)
from public, anon;

grant execute on function public.update_partner_order_status(text, text, text, text)
to authenticated;
grant execute on function public.confirm_order_conversation_delivery(uuid)
to authenticated;
