-- Edge Functions (create-business, super-admin-business) use service_role.
grant select, insert, update on table public.businesses to service_role;

grant execute on function public.normalize_slug(text) to service_role;
grant execute on function public.is_slug_available(text) to service_role;
