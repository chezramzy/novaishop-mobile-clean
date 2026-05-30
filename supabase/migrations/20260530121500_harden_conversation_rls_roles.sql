-- Conversation tables are part of authenticated order messaging only.
-- Avoid public-role policies and wrap auth.uid() for RLS initplan performance.

drop policy if exists "customers read own conversations" on public.conversations;
create policy "customers read own conversations"
  on public.conversations
  for select
  to authenticated
  using (customer_id = (select auth.uid()));

drop policy if exists "customers create own conversations" on public.conversations;
create policy "customers create own conversations"
  on public.conversations
  for insert
  to authenticated
  with check (customer_id = (select auth.uid()));

drop policy if exists "customers update own delivery status" on public.conversations;
create policy "customers update own delivery status"
  on public.conversations
  for update
  to authenticated
  using (customer_id = (select auth.uid()))
  with check (customer_id = (select auth.uid()));

drop policy if exists "participants read participants" on public.conversation_participants;
create policy "participants read participants"
  on public.conversation_participants
  for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1
      from public.conversations c
      where c.id = conversation_participants.conversation_id
        and c.customer_id = (select auth.uid())
    )
  );

drop policy if exists "customers create participant rows" on public.conversation_participants;
create policy "customers create participant rows"
  on public.conversation_participants
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.conversations c
      where c.id = conversation_participants.conversation_id
        and c.customer_id = (select auth.uid())
    )
  );

drop policy if exists "customers read own messages" on public.conversation_messages;
create policy "customers read own messages"
  on public.conversation_messages
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.conversations c
      where c.id = conversation_messages.conversation_id
        and c.customer_id = (select auth.uid())
    )
  );

drop policy if exists "customers send own messages" on public.conversation_messages;
create policy "customers send own messages"
  on public.conversation_messages
  for insert
  to authenticated
  with check (
    author in ('customer', 'system')
    and exists (
      select 1
      from public.conversations c
      where c.id = conversation_messages.conversation_id
        and c.customer_id = (select auth.uid())
    )
  );

drop policy if exists "customers read own order items" on public.conversation_order_items;
create policy "customers read own order items"
  on public.conversation_order_items
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.conversations c
      where c.id = conversation_order_items.conversation_id
        and c.customer_id = (select auth.uid())
    )
  );

drop policy if exists "customers create own order items" on public.conversation_order_items;
create policy "customers create own order items"
  on public.conversation_order_items
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.conversations c
      where c.id = conversation_order_items.conversation_id
        and c.customer_id = (select auth.uid())
    )
  );

drop policy if exists "customers read own events" on public.conversation_events;
create policy "customers read own events"
  on public.conversation_events
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.conversations c
      where c.id = conversation_events.conversation_id
        and c.customer_id = (select auth.uid())
    )
  );
