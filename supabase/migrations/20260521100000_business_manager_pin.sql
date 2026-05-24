-- Per-store manager panel PIN (bcrypt hash). Plain PIN never stored.

create extension if not exists pgcrypto;

alter table public.businesses
  add column if not exists manager_pin_hash text;

comment on column public.businesses.manager_pin_hash is
  'Bcrypt hash of owner-chosen manager panel PIN (crypt/gen_salt).';

create or replace function public.hash_manager_pin(p_pin text)
returns text
language sql
volatile
security definer
set search_path = public, extensions
as $$
  select crypt(trim(p_pin), gen_salt('bf'::text));
$$;

revoke all on function public.hash_manager_pin(text) from public;
grant execute on function public.hash_manager_pin(text) to service_role;

create or replace function public.verify_business_manager_pin(p_slug text, p_pin text)
returns boolean
language sql
stable
security definer
set search_path = public, extensions
as $$
  select exists (
    select 1
    from public.businesses b
    where b.slug = public.normalize_slug(p_slug)
      and b.manager_pin_hash is not null
      and length(trim(coalesce(p_pin, ''))) >= 4
      and b.manager_pin_hash = crypt(trim(p_pin), b.manager_pin_hash)
  );
$$;

grant execute on function public.verify_business_manager_pin(text, text) to anon, authenticated;

create or replace function public.update_my_business_manager_pin(p_pin text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_business_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Unauthorized';
  end if;
  if length(trim(coalesce(p_pin, ''))) < 4 then
    raise exception 'Manager password must be at least 4 characters';
  end if;

  select b.id into v_business_id
  from public.businesses b
  where b.owner_id = auth.uid()
  order by b.created_at desc
  limit 1;

  if v_business_id is null then
    raise exception 'No owned business found';
  end if;

  update public.businesses
  set manager_pin_hash = public.hash_manager_pin(p_pin),
      updated_at = now()
  where id = v_business_id;
end;
$$;

grant execute on function public.update_my_business_manager_pin(text) to authenticated;
