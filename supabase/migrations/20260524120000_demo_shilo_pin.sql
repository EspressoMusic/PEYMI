-- Demo store: canonical slug shilo, manager panel PIN 1234 (legacy slug shiki).

update public.businesses
set slug = 'shilo',
    manager_pin_hash = public.hash_manager_pin('1234'),
    contact_email = coalesce(nullif(trim(contact_email), ''), 'shilohdhd1@gmail.com'),
    updated_at = now()
where slug = 'shiki';

update public.businesses
set manager_pin_hash = public.hash_manager_pin('1234'),
    contact_email = coalesce(nullif(trim(contact_email), ''), 'shilohdhd1@gmail.com'),
    updated_at = now()
where slug = 'shilo';

update public.businesses
set store_mode = 'appointments',
    updated_at = now()
where slug = 'shilo';

do $$
declare
  v_id uuid;
begin
  select id into v_id from public.businesses where slug = 'shilo' limit 1;
  if v_id is not null then
    perform public.seed_default_business_availability(v_id);
  end if;
end $$;
