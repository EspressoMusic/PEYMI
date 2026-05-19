-- Security hardening: tamper-resistant profiles/businesses + lock down internal RPC.

-- ---------------------------------------------------------------------------
-- Profiles: block self-service role / phone verification bypass
-- ---------------------------------------------------------------------------
create or replace function public.prevent_profile_sensitive_self_update()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_super_admin() then
    return new;
  end if;

  if auth.uid() is null or auth.uid() <> old.id then
    return new;
  end if;

  if new.role is distinct from old.role then
    new.role := old.role;
  end if;

  if new.phone_verified is distinct from old.phone_verified then
    new.phone_verified := old.phone_verified;
    new.phone_verified_at := old.phone_verified_at;
  end if;

  if old.phone_verified and new.phone is distinct from old.phone then
    new.phone := old.phone;
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_prevent_role_escalation on public.profiles;
drop trigger if exists profiles_prevent_sensitive_self_update on public.profiles;
create trigger profiles_prevent_sensitive_self_update
  before update on public.profiles
  for each row execute function public.prevent_profile_sensitive_self_update();

create or replace function public.enforce_profile_insert_defaults()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_super_admin() then
    return new;
  end if;

  if auth.uid() is not null and auth.uid() = new.id then
    new.role := 'customer';
    new.phone_verified := false;
    new.phone_verified_at := null;
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_enforce_insert_defaults on public.profiles;
create trigger profiles_enforce_insert_defaults
  before insert on public.profiles
  for each row execute function public.enforce_profile_insert_defaults();

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
  for insert to authenticated
  with check (
    id = auth.uid()
    and role = 'customer'
    and phone_verified = false
  );

-- ---------------------------------------------------------------------------
-- Businesses: owners cannot change billing / activation fields
-- ---------------------------------------------------------------------------
create or replace function public.prevent_business_billing_tamper()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if public.is_super_admin() then
    return new;
  end if;

  if auth.uid() is not null and auth.uid() = old.owner_id then
    new.subscription_status := old.subscription_status;
    new.is_active := old.is_active;
    new.past_due_grace_until := old.past_due_grace_until;
    new.owner_id := old.owner_id;
  end if;

  return new;
end;
$$;

drop trigger if exists businesses_prevent_billing_tamper on public.businesses;
create trigger businesses_prevent_billing_tamper
  before update on public.businesses
  for each row execute function public.prevent_business_billing_tamper();

-- ---------------------------------------------------------------------------
-- Revoke EXECUTE on internal/trigger functions (not user-facing RPC)
-- ---------------------------------------------------------------------------
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.prevent_profile_role_escalation() from public, anon, authenticated;
revoke all on function public.prevent_profile_sensitive_self_update() from public, anon, authenticated;
revoke all on function public.enforce_profile_insert_defaults() from public, anon, authenticated;
revoke all on function public.prevent_business_billing_tamper() from public, anon, authenticated;
revoke all on function public.set_owner_role_on_business_create() from public, anon, authenticated;
revoke all on function public.set_updated_at() from public, anon, authenticated;

revoke all on function public.is_super_admin() from anon;
revoke all on function public.owns_business(uuid) from anon;
revoke all on function public.owner_dashboard_unlocked(uuid) from anon;
revoke all on function public.current_user_phone_verified() from anon;
