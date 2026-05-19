-- Demo store used in-app (slug shiki): ensure appointment mode + default hours.
update public.businesses
set store_mode = 'appointments', updated_at = now()
where slug = 'shiki';

do $$
declare
  v_id uuid;
begin
  select id into v_id from public.businesses where slug = 'shiki' limit 1;
  if v_id is not null then
    perform public.seed_default_business_availability(v_id);
  end if;
end $$;
