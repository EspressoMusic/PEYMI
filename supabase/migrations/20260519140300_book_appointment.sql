create or replace function public.book_appointment(
  p_business_id uuid,
  p_appointment_date date,
  p_appointment_time time,
  p_customer_name text,
  p_customer_phone text,
  p_customer_email text default null,
  p_service_name text default 'Appointment',
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_business public.businesses%rowtype;
  v_settings public.business_appointment_settings%rowtype;
  v_dow int;
  v_slot_end time;
  v_duration interval;
  v_notice interval;
  v_id uuid;
begin
  if coalesce(trim(p_customer_name), '') = '' or coalesce(trim(p_customer_phone), '') = '' then
    return jsonb_build_object('ok', false, 'error', 'Name and phone are required');
  end if;

  select * into v_business from public.businesses where id = p_business_id;
  if not found then
    return jsonb_build_object('ok', false, 'error', 'Business not found');
  end if;

  if v_business.store_mode <> 'appointments' then
    return jsonb_build_object('ok', false, 'error', 'This business does not accept appointments');
  end if;

  if not public.business_accepts_customers(p_business_id) then
    return jsonb_build_object('ok', false, 'error', 'This business is currently unavailable');
  end if;

  select * into v_settings
  from public.business_appointment_settings
  where business_id = p_business_id;

  if not found then
    perform public.seed_default_business_availability(p_business_id);
    select * into v_settings
    from public.business_appointment_settings
    where business_id = p_business_id;
  end if;

  if p_appointment_date > current_date + v_settings.max_days_ahead then
    return jsonb_build_object('ok', false, 'error', 'Date is too far in the future');
  end if;

  v_duration := (v_settings.slot_duration_minutes || ' minutes')::interval;
  v_notice := (v_settings.booking_notice_minutes || ' minutes')::interval;
  v_dow := extract(dow from p_appointment_date)::int;
  v_slot_end := p_appointment_time + v_duration;

  if (p_appointment_date + p_appointment_time)::timestamp < (now() + v_notice) then
    return jsonb_build_object('ok', false, 'error', 'This time is no longer available');
  end if;

  if not exists (
    select 1 from public.business_availability a
    where a.business_id = p_business_id
      and a.day_of_week = v_dow
      and a.is_active = true
      and p_appointment_time >= a.start_time
      and v_slot_end <= a.end_time
  ) then
    return jsonb_build_object('ok', false, 'error', 'This time is not available');
  end if;

  if exists (
    select 1 from public.appointments ap
    where ap.business_id = p_business_id
      and ap.appointment_date = p_appointment_date
      and ap.appointment_time = p_appointment_time
      and ap.status <> 'cancelled'
  ) then
    return jsonb_build_object('ok', false, 'error', 'This time is no longer available');
  end if;

  insert into public.appointments (
    business_id,
    customer_user_id,
    customer_name,
    customer_phone,
    customer_email,
    service_name,
    appointment_date,
    appointment_time,
    status,
    notes
  ) values (
    p_business_id,
    auth.uid(),
    trim(p_customer_name),
    trim(p_customer_phone),
    nullif(trim(coalesce(p_customer_email, '')), ''),
    coalesce(nullif(trim(p_service_name), ''), 'Appointment'),
    p_appointment_date,
    p_appointment_time,
    'confirmed',
    nullif(trim(coalesce(p_notes, '')), '')
  )
  returning id into v_id;

  return jsonb_build_object('ok', true, 'appointment_id', v_id);
exception
  when unique_violation then
    return jsonb_build_object('ok', false, 'error', 'This time is no longer available');
end;
$$;

grant execute on function public.book_appointment(uuid, date, time, text, text, text, text, text) to anon, authenticated;
