-- Functions for store mode appointments (part 2)

create or replace function public.seed_default_business_availability(p_business_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  d int;
begin
  insert into public.business_appointment_settings (business_id)
  values (p_business_id)
  on conflict (business_id) do nothing;

  delete from public.business_availability where business_id = p_business_id;

  for d in 0..4 loop
    insert into public.business_availability (business_id, day_of_week, start_time, end_time, is_active)
    values (p_business_id, d, time '09:00', time '17:00', true);
  end loop;
end;
$$;

create or replace function public.process_appointment_waitlist_on_cancel()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'cancelled' and old.status is distinct from 'cancelled' then
    update public.appointment_waitlist
    set notify_status = 'notified'
    where business_id = new.business_id
      and appointment_date = new.appointment_date
      and appointment_time = new.appointment_time
      and notify_status = 'waiting';
  end if;
  return new;
end;
$$;

drop trigger if exists appointments_waitlist_on_cancel on public.appointments;
create trigger appointments_waitlist_on_cancel
  after update of status on public.appointments
  for each row execute function public.process_appointment_waitlist_on_cancel();
