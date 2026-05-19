-- Store mode (products vs appointments) + scheduling tables + secure booking RPCs.

-- ---------------------------------------------------------------------------
-- businesses.store_mode
-- ---------------------------------------------------------------------------
alter table public.businesses
  add column if not exists store_mode text not null default 'products';

alter table public.businesses
  drop constraint if exists businesses_store_mode_check;

alter table public.businesses
  add constraint businesses_store_mode_check
  check (store_mode in ('products', 'appointments'));

-- ---------------------------------------------------------------------------
-- appointments: notes + status (add no_show)
-- ---------------------------------------------------------------------------
alter table public.appointments
  add column if not exists notes text;

do $$ begin
  alter type public.appointment_status add value if not exists 'no_show';
exception
  when duplicate_object then null;
end $$;

-- Prevent double booking (active appointments only)
create unique index if not exists appointments_unique_active_slot
  on public.appointments (business_id, appointment_date, appointment_time)
  where status <> 'cancelled';

-- ---------------------------------------------------------------------------
-- business_appointment_settings
-- ---------------------------------------------------------------------------
create table if not exists public.business_appointment_settings (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  slot_duration_minutes int not null default 30 check (slot_duration_minutes > 0 and slot_duration_minutes <= 240),
  booking_notice_minutes int not null default 60 check (booking_notice_minutes >= 0),
  max_days_ahead int not null default 30 check (max_days_ahead > 0 and max_days_ahead <= 365),
  timezone text not null default 'Asia/Jerusalem',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint business_appointment_settings_business_unique unique (business_id)
);

-- ---------------------------------------------------------------------------
-- business_availability
-- ---------------------------------------------------------------------------
create table if not exists public.business_availability (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  day_of_week int not null check (day_of_week >= 0 and day_of_week <= 6),
  start_time time not null,
  end_time time not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint business_availability_time_order check (end_time > start_time)
);

create index if not exists business_availability_business_idx
  on public.business_availability (business_id, day_of_week);

-- ---------------------------------------------------------------------------
-- appointment_waitlist
-- ---------------------------------------------------------------------------
create table if not exists public.appointment_waitlist (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  appointment_date date not null,
  appointment_time time not null,
  customer_name text not null,
  customer_phone text not null,
  customer_email text,
  notify_status text not null default 'waiting',
  created_at timestamptz not null default now(),
  constraint appointment_waitlist_notify_status_check
    check (notify_status in ('waiting', 'notified', 'booked', 'cancelled'))
);

create index if not exists appointment_waitlist_lookup_idx
  on public.appointment_waitlist (business_id, appointment_date, appointment_time, notify_status);

-- ---------------------------------------------------------------------------
-- updated_at triggers
-- ---------------------------------------------------------------------------
drop trigger if exists business_appointment_settings_set_updated_at on public.business_appointment_settings;
create trigger business_appointment_settings_set_updated_at
  before update on public.business_appointment_settings
  for each row execute function public.set_updated_at();

drop trigger if exists business_availability_set_updated_at on public.business_availability;
create trigger business_availability_set_updated_at
  before update on public.business_availability
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Default availability: Sun–Thu 09:00–17:00
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Waitlist processing on cancel
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Public schedule (no customer PII)
-- ---------------------------------------------------------------------------
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
  v_has_availability boolean;
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
      v_slot := v_slot;
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

-- ---------------------------------------------------------------------------
-- Book appointment (anti double-booking)
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Cancel appointment (owner or customer by phone)
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Owner: update appointment status
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Waitlist join
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Set store mode (owner / super admin)
-- ---------------------------------------------------------------------------
create or replace function public.set_business_store_mode(
  p_business_id uuid,
  p_store_mode text
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_store_mode not in ('products', 'appointments') then
    return jsonb_build_object('ok', false, 'error', 'Invalid store mode');
  end if;

  if not (public.owns_business(p_business_id) or public.is_super_admin()) then
    return jsonb_build_object('ok', false, 'error', 'Forbidden');
  end if;

  if not public.owner_dashboard_unlocked(p_business_id) and not public.is_super_admin() then
    return jsonb_build_object('ok', false, 'error', 'Dashboard locked');
  end if;

  update public.businesses
  set store_mode = p_store_mode, updated_at = now()
  where id = p_business_id;

  if p_store_mode = 'appointments' then
    perform public.seed_default_business_availability(p_business_id);
  end if;

  return jsonb_build_object('ok', true, 'store_mode', p_store_mode);
end;
$$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
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

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------
grant select on table public.business_appointment_settings to anon, authenticated;
grant insert, update, delete on table public.business_appointment_settings to authenticated;

grant select on table public.business_availability to anon, authenticated;
grant insert, update, delete on table public.business_availability to authenticated;

grant select, insert, update on table public.appointment_waitlist to authenticated;
grant insert on table public.appointment_waitlist to anon;

grant execute on function public.get_public_appointment_schedule(text, date, date) to anon, authenticated;
grant execute on function public.book_appointment(uuid, date, time, text, text, text, text, text) to anon, authenticated;
grant execute on function public.cancel_appointment(uuid, text) to anon, authenticated;
grant execute on function public.update_appointment_status(uuid, text) to authenticated;
grant execute on function public.join_appointment_waitlist(uuid, date, time, text, text, text) to anon, authenticated;
grant execute on function public.set_business_store_mode(uuid, text) to authenticated;
grant execute on function public.seed_default_business_availability(uuid) to authenticated;

revoke all on function public.seed_default_business_availability(uuid) from anon;
revoke all on function public.process_appointment_waitlist_on_cancel() from public, anon, authenticated;
