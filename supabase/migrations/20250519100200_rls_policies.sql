-- Row Level Security policies

alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.appointments enable row level security;
alter table public.customer_messages enable row level security;
alter table public.phone_verification_attempts enable row level security;

-- ---------------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------------
drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select to authenticated
  using (id = auth.uid() or public.is_super_admin());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update to authenticated
  using (id = auth.uid() or public.is_super_admin())
  with check (id = auth.uid() or public.is_super_admin());

-- Users cannot self-promote to super_admin via RLS
drop policy if exists profiles_update_own_no_role_escalation on public.profiles;
-- Enforced via trigger below

-- ---------------------------------------------------------------------------
-- businesses
-- ---------------------------------------------------------------------------
drop policy if exists businesses_select_public on public.businesses;
create policy businesses_select_public on public.businesses
  for select to anon, authenticated
  using (public.business_is_publicly_visible(id) or owner_id = auth.uid() or public.is_super_admin());

drop policy if exists businesses_insert_verified_owner on public.businesses;
create policy businesses_insert_verified_owner on public.businesses
  for insert to authenticated
  with check (
    owner_id = auth.uid()
    and public.current_user_phone_verified()
    and public.is_slug_available(slug)
  );

drop policy if exists businesses_update_owner on public.businesses;
create policy businesses_update_owner on public.businesses
  for update to authenticated
  using (owner_id = auth.uid() or public.is_super_admin())
  with check (owner_id = auth.uid() or public.is_super_admin());

drop policy if exists businesses_delete_super_admin on public.businesses;
create policy businesses_delete_super_admin on public.businesses
  for delete to authenticated
  using (public.is_super_admin());

-- ---------------------------------------------------------------------------
-- products
-- ---------------------------------------------------------------------------
drop policy if exists products_select_public on public.products;
create policy products_select_public on public.products
  for select to anon, authenticated
  using (
    (is_active = true and public.business_is_publicly_visible(business_id))
    or public.owns_business(business_id)
    or public.is_super_admin()
  );

drop policy if exists products_insert_owner on public.products;
create policy products_insert_owner on public.products
  for insert to authenticated
  with check (
    public.owns_business(business_id)
    and public.owner_dashboard_unlocked(business_id)
  );

drop policy if exists products_update_owner on public.products;
create policy products_update_owner on public.products
  for update to authenticated
  using (public.owns_business(business_id) or public.is_super_admin())
  with check (public.owns_business(business_id) or public.is_super_admin());

drop policy if exists products_delete_owner on public.products;
create policy products_delete_owner on public.products
  for delete to authenticated
  using (public.owns_business(business_id) or public.is_super_admin());

-- ---------------------------------------------------------------------------
-- orders
-- ---------------------------------------------------------------------------
drop policy if exists orders_select_owner on public.orders;
create policy orders_select_owner on public.orders
  for select to authenticated
  using (public.owns_business(business_id) or public.is_super_admin() or customer_user_id = auth.uid());

drop policy if exists orders_insert_customer on public.orders;
create policy orders_insert_customer on public.orders
  for insert to anon, authenticated
  with check (public.business_accepts_customers(business_id));

drop policy if exists orders_update_owner on public.orders;
create policy orders_update_owner on public.orders
  for update to authenticated
  using (public.owns_business(business_id) or public.is_super_admin())
  with check (public.owns_business(business_id) or public.is_super_admin());

-- ---------------------------------------------------------------------------
-- appointments
-- ---------------------------------------------------------------------------
drop policy if exists appointments_select_owner on public.appointments;
create policy appointments_select_owner on public.appointments
  for select to authenticated
  using (public.owns_business(business_id) or public.is_super_admin() or customer_user_id = auth.uid());

drop policy if exists appointments_insert_customer on public.appointments;
create policy appointments_insert_customer on public.appointments
  for insert to anon, authenticated
  with check (public.business_accepts_customers(business_id));

drop policy if exists appointments_update_owner on public.appointments;
create policy appointments_update_owner on public.appointments
  for update to authenticated
  using (public.owns_business(business_id) or public.is_super_admin())
  with check (public.owns_business(business_id) or public.is_super_admin());

-- ---------------------------------------------------------------------------
-- customer_messages
-- ---------------------------------------------------------------------------
drop policy if exists messages_select_owner on public.customer_messages;
create policy messages_select_owner on public.customer_messages
  for select to authenticated
  using (public.owns_business(business_id) or public.is_super_admin());

drop policy if exists messages_insert_customer on public.customer_messages;
create policy messages_insert_customer on public.customer_messages
  for insert to anon, authenticated
  with check (public.business_accepts_customers(business_id));

drop policy if exists messages_update_owner on public.customer_messages;
create policy messages_update_owner on public.customer_messages
  for update to authenticated
  using (public.owns_business(business_id) or public.is_super_admin())
  with check (public.owns_business(business_id) or public.is_super_admin());

-- ---------------------------------------------------------------------------
-- phone_verification_attempts — only service role / edge functions should write;
-- users can read their own recent attempts count via edge function only.
-- ---------------------------------------------------------------------------
drop policy if exists phone_attempts_no_direct on public.phone_verification_attempts;
create policy phone_attempts_no_direct on public.phone_verification_attempts
  for all to authenticated
  using (false)
  with check (false);

-- ---------------------------------------------------------------------------
-- Prevent role escalation on profiles
-- ---------------------------------------------------------------------------
create or replace function public.prevent_profile_role_escalation()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not public.is_super_admin() then
    if new.role is distinct from old.role then
      new.role := old.role;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_prevent_role_escalation on public.profiles;
create trigger profiles_prevent_role_escalation
  before update on public.profiles
  for each row execute function public.prevent_profile_role_escalation();

-- Set business_owner role when user creates first business
create or replace function public.set_owner_role_on_business_create()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.profiles
  set role = 'business_owner', updated_at = now()
  where id = new.owner_id
    and role = 'customer';
  return new;
end;
$$;

drop trigger if exists businesses_set_owner_role on public.businesses;
create trigger businesses_set_owner_role
  after insert on public.businesses
  for each row execute function public.set_owner_role_on_business_create();
