create or replace function public.listings_search_vector_update()
returns trigger
language plpgsql
set search_path = public
as $function$
begin
  new.search_vector := to_tsvector('french', coalesce(new.title, '') || ' ' || coalesce(new.description, ''));
  return new;
end;
$function$;

revoke execute on function public.current_app_role() from public, anon, authenticated;
revoke execute on function public.is_admin() from public, anon, authenticated;
revoke execute on function public.is_partner() from public, anon, authenticated;
revoke execute on function public.review_partner_application(uuid, boolean, text) from public, anon;
grant execute on function public.review_partner_application(uuid, boolean, text) to authenticated;
revoke execute on function public.sync_auth_user() from public, anon, authenticated;
