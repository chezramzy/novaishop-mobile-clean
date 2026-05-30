revoke execute on function public.submit_partner_listing(
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
) from public, anon;

revoke execute on function public.review_listing(text, boolean, text)
from public, anon;

revoke execute on function public.create_order_conversation_from_cart(jsonb)
from public, anon;

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

grant execute on function public.review_listing(text, boolean, text)
to authenticated;

grant execute on function public.create_order_conversation_from_cart(jsonb)
to authenticated;

create index if not exists coupon_usages_order_id_idx
  on public.coupon_usages(order_id);
create index if not exists coupon_usages_user_id_idx
  on public.coupon_usages(user_id);
create index if not exists coupons_vendor_id_idx
  on public.coupons(vendor_id);
create index if not exists listing_rejections_actor_id_idx
  on public.listing_rejections(actor_id);
create index if not exists listings_category_id_idx
  on public.listings(category_id);
create index if not exists order_items_listing_id_idx
  on public.order_items(listing_id);
create index if not exists partner_applications_reviewed_by_idx
  on public.partner_applications(reviewed_by);
create index if not exists payments_payout_account_id_idx
  on public.payments(payout_account_id);
create index if not exists refunds_order_id_idx
  on public.refunds(order_id);
create index if not exists reviews_customer_id_idx
  on public.reviews(customer_id);
create index if not exists vendor_reviews_customer_id_idx
  on public.vendor_reviews(customer_id);
create index if not exists vendor_reviews_order_id_idx
  on public.vendor_reviews(order_id);
