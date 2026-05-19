-- API role table privileges (RLS still enforces row access).

grant usage on schema public to anon, authenticated;

grant select on table public.profiles to authenticated;
grant insert, update on table public.profiles to authenticated;

grant select on table public.businesses to anon, authenticated;
grant insert, update on table public.businesses to authenticated;

grant select on table public.products to anon, authenticated;
grant insert, update, delete on table public.products to authenticated;

grant select, insert on table public.orders to anon, authenticated;
grant update on table public.orders to authenticated;

grant select, insert on table public.appointments to anon, authenticated;
grant update on table public.appointments to authenticated;

grant select, insert on table public.customer_messages to anon, authenticated;
grant update on table public.customer_messages to authenticated;

grant usage, select on all sequences in schema public to anon, authenticated;
