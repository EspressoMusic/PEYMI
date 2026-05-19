-- Customer appointment history by phone (for in-app "my appointments" tab).
create or replace function public.get_customer_appointments(
  p_business_id uuid,
  p_customer_phone text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_phone text := trim(coalesce(p_customer_phone, ''));
  v_rows jsonb;
begin
  if v_phone = '' then
    return jsonb_build_object('ok', false, 'error', 'Phone is required');
  end if;

  if not public.business_is_publicly_visible(p_business_id) then
    return jsonb_build_object('ok', false, 'error', 'Business not available');
  end if;

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', a.id,
        'business_id', a.business_id,
        'customer_name', a.customer_name,
        'customer_phone', a.customer_phone,
        'customer_email', a.customer_email,
        'service_name', a.service_name,
        'appointment_date', a.appointment_date,
        'appointment_time', to_char(a.appointment_time, 'HH24:MI'),
        'status', a.status,
        'notes', a.notes
      )
      order by a.appointment_date desc, a.appointment_time desc
    ),
    '[]'::jsonb
  )
  into v_rows
  from public.appointments a
  where a.business_id = p_business_id
    and trim(a.customer_phone) = v_phone
    and a.appointment_date >= (current_date - interval '90 days');

  return jsonb_build_object('ok', true, 'appointments', v_rows);
end;
$$;

grant execute on function public.get_customer_appointments(uuid, text) to anon, authenticated;
