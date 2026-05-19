create or replace function public.cancel_appointment(
  p_appointment_id uuid,
  p_customer_phone text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ap public.appointments%rowtype;
begin
  select * into v_ap from public.appointments where id = p_appointment_id;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'Appointment not found');
  end if;

  if public.owns_business(v_ap.business_id) or public.is_super_admin() then
    null;
  elsif p_customer_phone is not null
    and trim(p_customer_phone) <> ''
    and trim(v_ap.customer_phone) = trim(p_customer_phone) then
    null;
  else
    return jsonb_build_object('ok', false, 'error', 'Forbidden');
  end if;

  if v_ap.status = 'cancelled' then
    return jsonb_build_object('ok', true, 'already_cancelled', true);
  end if;

  update public.appointments
  set status = 'cancelled', updated_at = now()
  where id = p_appointment_id;

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.update_appointment_status(
  p_appointment_id uuid,
  p_status text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ap public.appointments%rowtype;
begin
  if p_status not in ('new', 'confirmed', 'cancelled', 'completed', 'no_show') then
    return jsonb_build_object('ok', false, 'error', 'Invalid status');
  end if;

  select * into v_ap from public.appointments where id = p_appointment_id;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'Not found');
  end if;

  if not (public.owns_business(v_ap.business_id) or public.is_super_admin()) then
    return jsonb_build_object('ok', false, 'error', 'Forbidden');
  end if;

  update public.appointments
  set status = p_status::public.appointment_status, updated_at = now()
  where id = p_appointment_id;

  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.join_appointment_waitlist(
  p_business_id uuid,
  p_appointment_date date,
  p_appointment_time time,
  p_customer_name text,
  p_customer_phone text,
  p_customer_email text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if coalesce(trim(p_customer_name), '') = '' or coalesce(trim(p_customer_phone), '') = '' then
    return jsonb_build_object('ok', false, 'error', 'Name and phone are required');
  end if;

  if not public.business_accepts_customers(p_business_id) then
    return jsonb_build_object('ok', false, 'error', 'This business is currently unavailable');
  end if;

  insert into public.appointment_waitlist (
    business_id,
    appointment_date,
    appointment_time,
    customer_name,
    customer_phone,
    customer_email,
    notify_status
  ) values (
    p_business_id,
    p_appointment_date,
    p_appointment_time,
    trim(p_customer_name),
    trim(p_customer_phone),
    nullif(trim(coalesce(p_customer_email, '')), ''),
    'waiting'
  );

  return jsonb_build_object('ok', true);
end;
$$;

grant execute on function public.cancel_appointment(uuid, text) to anon, authenticated;
grant execute on function public.update_appointment_status(uuid, text) to authenticated;
grant execute on function public.join_appointment_waitlist(uuid, date, time, text, text, text) to anon, authenticated;
grant execute on function public.set_business_store_mode(uuid, text) to authenticated;
grant execute on function public.seed_default_business_availability(uuid) to authenticated;

alter table public.business_appointment_settings enable row level security;
alter table public.business_availability enable row level security;
alter table public.appointment_waitlist enable row level security;

drop policy if exists appointment_settings_select on public.business_appointment_settings;
create policy appointment_settings_select on public.business_appointment_settings
  for select to anon, authenticated
  using (
    public.business_is_publicly_visible(business_id)
    or public.owns_business(business_id)
    or public.is_super_admin()
  );

drop policy if exists appointment_settings_manage_owner on public.business_appointment_settings;
create policy appointment_settings_manage_owner on public.business_appointment_settings
  for all to authenticated
  using (public.owns_business(business_id) or public.is_super_admin())
  with check (public.owns_business(business_id) or public.is_super_admin());

drop policy if exists business_availability_select on public.business_availability;
create policy business_availability_select on public.business_availability
  for select to anon, authenticated
  using (
    public.business_is_publicly_visible(business_id)
    or public.owns_business(business_id)
    or public.is_super_admin()
  );

drop policy if exists business_availability_manage_owner on public.business_availability;
create policy business_availability_manage_owner on public.business_availability
  for all to authenticated
  using (public.owns_business(business_id) or public.is_super_admin())
  with check (
    (public.owns_business(business_id) or public.is_super_admin())
    and public.owner_dashboard_unlocked(business_id)
  );

drop policy if exists appointment_waitlist_select_owner on public.appointment_waitlist;
create policy appointment_waitlist_select_owner on public.appointment_waitlist
  for select to authenticated
  using (public.owns_business(business_id) or public.is_super_admin());

drop policy if exists appointment_waitlist_insert_public on public.appointment_waitlist;
create policy appointment_waitlist_insert_public on public.appointment_waitlist
  for insert to anon, authenticated
  with check (public.business_accepts_customers(business_id));

drop policy if exists appointment_waitlist_update_owner on public.appointment_waitlist;
create policy appointment_waitlist_update_owner on public.appointment_waitlist
  for update to authenticated
  using (public.owns_business(business_id) or public.is_super_admin())
  with check (public.owns_business(business_id) or public.is_super_admin());

grant select on table public.business_appointment_settings to anon, authenticated;
grant insert, update, delete on table public.business_appointment_settings to authenticated;
grant select on table public.business_availability to anon, authenticated;
grant insert, update, delete on table public.business_availability to authenticated;
grant select, insert, update on table public.appointment_waitlist to authenticated;
grant insert on table public.appointment_waitlist to anon;

revoke all on function public.seed_default_business_availability(uuid) from anon;
