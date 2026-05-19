-- Edge Functions update phone verification on profiles via service_role.
grant select, update on table public.profiles to service_role;
