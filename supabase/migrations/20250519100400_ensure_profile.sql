-- Create profile row if missing (e.g. user signed up before trigger/migrations).

create or replace function public.ensure_my_profile()
returns public.profiles
language plpgsql
security definer
set search_path = public
as $$
declare
  p public.profiles;
  v_email text;
begin
  if auth.uid() is null then
    raise exception 'Not authenticated';
  end if;

  v_email := coalesce(auth.jwt() ->> 'email', '');

  insert into public.profiles (id, email, full_name)
  values (
    auth.uid(),
    v_email,
    coalesce(auth.jwt() ->> 'full_name', '')
  )
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();

  select * into p from public.profiles where id = auth.uid();
  return p;
end;
$$;

revoke all on function public.ensure_my_profile() from public;
grant execute on function public.ensure_my_profile() to authenticated;

drop policy if exists profiles_insert_own on public.profiles;
create policy profiles_insert_own on public.profiles
  for insert to authenticated
  with check (id = auth.uid());
-- Defaults enforced by enforce_profile_insert_defaults trigger (see security_hardening migration).
