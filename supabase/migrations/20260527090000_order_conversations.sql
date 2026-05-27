create extension if not exists pgcrypto;

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null,
  status text not null default 'draft'
    check (status in (
      'draft',
      'awaiting_confirmation',
      'confirmed',
      'preparing',
      'out_for_delivery',
      'delivered',
      'buyer_confirmed',
      'cancelled'
    )),
  title text not null default 'Commande NovaShop',
  total_amount numeric(12, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversation_participants (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null,
  role text not null check (role in ('customer', 'partner', 'admin', 'support')),
  display_as text not null default 'NovaShop',
  created_at timestamptz not null default now(),
  unique (conversation_id, user_id)
);

create table if not exists public.conversation_messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  author text not null check (author in ('customer', 'nova_shop', 'system')),
  sender_id uuid,
  body text not null check (length(trim(body)) > 0),
  created_at timestamptz not null default now()
);

create table if not exists public.conversation_order_items (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  listing_id text not null,
  variant_id text,
  title text not null,
  quantity integer not null check (quantity > 0),
  unit_price numeric(12, 2) not null check (unit_price >= 0),
  total_price numeric(12, 2) not null check (total_price >= 0),
  options jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.conversation_events (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  event_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists conversations_customer_idx
  on public.conversations(customer_id, updated_at desc);
create index if not exists conversation_messages_thread_idx
  on public.conversation_messages(conversation_id, created_at);
create index if not exists conversation_items_thread_idx
  on public.conversation_order_items(conversation_id);
create index if not exists conversation_events_thread_idx
  on public.conversation_events(conversation_id, created_at);

alter table public.conversations enable row level security;
alter table public.conversation_participants enable row level security;
alter table public.conversation_messages enable row level security;
alter table public.conversation_order_items enable row level security;
alter table public.conversation_events enable row level security;

create policy "customers read own conversations"
  on public.conversations for select
  using (customer_id = auth.uid());

create policy "customers create own conversations"
  on public.conversations for insert
  with check (customer_id = auth.uid());

create policy "customers update own delivery status"
  on public.conversations for update
  using (customer_id = auth.uid())
  with check (customer_id = auth.uid());

create policy "participants read participants"
  on public.conversation_participants for select
  using (
    user_id = auth.uid()
    or exists (
      select 1 from public.conversations c
      where c.id = conversation_id and c.customer_id = auth.uid()
    )
  );

create policy "customers create participant rows"
  on public.conversation_participants for insert
  with check (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id and c.customer_id = auth.uid()
    )
  );

create policy "customers read own messages"
  on public.conversation_messages for select
  using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id and c.customer_id = auth.uid()
    )
  );

create policy "customers send own messages"
  on public.conversation_messages for insert
  with check (
    author in ('customer', 'system')
    and exists (
      select 1 from public.conversations c
      where c.id = conversation_id and c.customer_id = auth.uid()
    )
  );

create policy "customers read own order items"
  on public.conversation_order_items for select
  using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id and c.customer_id = auth.uid()
    )
  );

create policy "customers create own order items"
  on public.conversation_order_items for insert
  with check (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id and c.customer_id = auth.uid()
    )
  );

create policy "customers read own events"
  on public.conversation_events for select
  using (
    exists (
      select 1 from public.conversations c
      where c.id = conversation_id and c.customer_id = auth.uid()
    )
  );

alter publication supabase_realtime add table public.conversation_messages;
alter publication supabase_realtime add table public.conversations;
