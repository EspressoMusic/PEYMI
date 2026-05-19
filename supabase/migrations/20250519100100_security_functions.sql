-- Security helper functions (security definer, used by RLS)

create or replace function public.normalize_slug(input text)
returns text
language plpgsql
immutable
as $$
declare
  s text;
begin
  s := lower(trim(coalesce(input, '')));
  s := regexp_replace(s, '[^a-z0-9\s-]', '', 'g');
  s := regexp_replace(s, '\s+', '-', 'g');
  s := regexp_replace(s, '-+', '-', 'g');
  s := trim(both '-' from s);
  return s;
end;
$$;

create or replace function public.is_super_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.profiles
    where id = auth.uid()
      and role = 'super_admin'
  );
$$;

create or replace function public.owns_business(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.businesses b
    where b.id = p_business_id
      and b.owner_id = auth.uid()
  );
$$;

-- Public storefront: trial/active + is_active, or past_due within grace window
create or replace function public.business_accepts_customers(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.businesses b
    where b.id = p_business_id
      and b.is_active = true
      and (
        b.subscription_status in ('trial', 'active')
        or (
          b.subscription_status = 'past_due'
          and (b.past_due_grace_until is null or b.past_due_grace_until > now())
        )
      )
  );
$$;

create or replace function public.business_is_publicly_visible(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.businesses b
    where b.id = p_business_id
      and b.is_active = true
      and b.subscription_status not in ('suspended', 'cancelled')
  );
$$;

create or replace function public.owner_dashboard_unlocked(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.businesses b
    where b.id = p_business_id
      and b.owner_id = auth.uid()
      and b.is_active = true
      and b.subscription_status in ('trial', 'active', 'past_due')
  );
$$;

create or replace function public.current_user_phone_verified()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select phone_verified from public.profiles where id = auth.uid()),
    false
  );
$$;

-- Slug availability (callable by authenticated users)
create or replace function public.is_slug_available(p_slug text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select not exists (
    select 1 from public.businesses where slug = public.normalize_slug(p_slug)
  );
$$;

grant execute on function public.normalize_slug(text) to authenticated, anon;
grant execute on function public.is_slug_available(text) to authenticated, anon;
grant execute on function public.is_super_admin() to authenticated;
grant execute on function public.owns_business(uuid) to authenticated;
grant execute on function public.business_accepts_customers(uuid) to authenticated, anon;
grant execute on function public.business_is_publicly_visible(uuid) to authenticated, anon;
grant execute on function public.owner_dashboard_unlocked(uuid) to authenticated;
grant execute on function public.current_user_phone_verified() to authenticated;
