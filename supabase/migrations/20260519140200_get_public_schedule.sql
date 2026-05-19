create or replace function public.get_public_appointment_schedule(
  p_slug text,
  p_from_date date,
  p_to_date date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_business public.businesses%rowtype;
  v_settings public.business_appointment_settings%rowtype;
  v_day date;
  v_dow int;
  v_slot time;
  v_slot_end time;
  v_duration interval;
  v_notice interval;
  v_now timestamptz := now();
  v_days jsonb := '[]'::jsonb;
  v_slots jsonb;
  v_closed boolean;
  v_is_booked boolean;
  v_is_past boolean;
  v_available_count int;
begin
  select * into v_business
  from public.businesses
  where slug = public.normalize_slug(p_slug);

  if not found then
    return jsonb_build_object('error', 'not_found');
  end if;

  if not public.business_is_publicly_visible(v_business.id) then
    return jsonb_build_object('error', 'unavailable');
  end if;

  if v_business.store_mode <> 'appointments' then
    return jsonb_build_object('error', 'not_appointment_mode');
  end if;

  select * into v_settings
  from public.business_appointment_settings
  where business_id = v_business.id;

  if not found then
    perform public.seed_default_business_availability(v_business.id);
    select * into v_settings
    from public.business_appointment_settings
    where business_id = v_business.id;
  end if;

  v_duration := (v_settings.slot_duration_minutes || ' minutes')::interval;
  v_notice := (v_settings.booking_notice_minutes || ' minutes')::interval;

  if p_to_date > (current_date + v_settings.max_days_ahead) then
    p_to_date := current_date + v_settings.max_days_ahead;
  end if;

  v_day := p_from_date;
  while v_day <= p_to_date loop
    v_dow := extract(dow from v_day)::int;
    v_slots := '[]'::jsonb;
    v_closed := true;
    v_available_count := 0;

    for v_slot, v_slot_end in
      select a.start_time, a.end_time
      from public.business_availability a
      where a.business_id = v_business.id
        and a.day_of_week = v_dow
        and a.is_active = true
      order by a.start_time
    loop
      v_closed := false;
      while v_slot < v_slot_end loop
        v_is_past := (v_day + v_slot)::timestamp < (v_now + v_notice);
        select exists (
          select 1 from public.appointments ap
          where ap.business_id = v_business.id
            and ap.appointment_date = v_day
            and ap.appointment_time = v_slot
            and ap.status <> 'cancelled'
        ) into v_is_booked;

        if not v_is_past then
          if not v_is_booked then
            v_available_count := v_available_count + 1;
          end if;
          v_slots := v_slots || jsonb_build_array(
            jsonb_build_object(
              'time', to_char(v_slot, 'HH24:MI'),
              'status', case when v_is_booked then 'booked' else 'available' end
            )
          );
        end if;

        v_slot := v_slot + v_duration;
      end loop;
    end loop;

    v_days := v_days || jsonb_build_array(
      jsonb_build_object(
        'date', to_char(v_day, 'YYYY-MM-DD'),
        'closed', v_closed,
        'available_count', v_available_count,
        'fully_booked', not v_closed and v_available_count = 0
          and jsonb_array_length(v_slots) > 0,
        'slots', v_slots
      )
    );

    v_day := v_day + 1;
  end loop;

  return jsonb_build_object(
    'business_id', v_business.id,
    'store_mode', v_business.store_mode,
    'accepts_customers', public.business_accepts_customers(v_business.id),
    'slot_duration_minutes', v_settings.slot_duration_minutes,
    'timezone', v_settings.timezone,
    'days', v_days
  );
end;
$$;

grant execute on function public.get_public_appointment_schedule(text, date, date) to anon, authenticated;
