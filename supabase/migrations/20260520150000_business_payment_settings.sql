-- Customer-to-business payment instructions (pilot: manual / external only; no card processing).

create table if not exists public.business_payment_settings (
  business_id uuid primary key references public.businesses (id) on delete cascade,
  payment_enabled boolean not null default false,
  payment_mode text not null default 'manual',
  currency text not null default 'USD',
  payment_instructions text,
  external_payment_link text,
  payment_phone text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint business_payment_settings_mode_check check (
    payment_mode in (
      'manual',
      'external_link',
      'cash_on_delivery',
      'pay_on_arrival',
      'future_provider'
    )
  )
);

create index if not exists business_payment_settings_enabled_idx
  on public.business_payment_settings (business_id)
  where payment_enabled = true;

comment on table public.business_payment_settings is
  'Pilot: how customers pay the business directly (not Peymiz subscription billing).';

alter table public.business_payment_settings enable row level security;

drop policy if exists business_payment_settings_select on public.business_payment_settings;
create policy business_payment_settings_select on public.business_payment_settings
  for select to anon, authenticated
  using (
    public.business_accepts_customers(business_id)
    or public.business_is_publicly_visible(business_id)
    or public.owns_business(business_id)
    or public.is_super_admin()
  );

drop policy if exists business_payment_settings_manage_owner on public.business_payment_settings;
create policy business_payment_settings_manage_owner on public.business_payment_settings
  for all to authenticated
  using (public.owns_business(business_id) or public.is_super_admin())
  with check (public.owns_business(business_id) or public.is_super_admin());

grant select on table public.business_payment_settings to anon, authenticated;
grant insert, update, delete on table public.business_payment_settings to authenticated;

create or replace function public.touch_business_payment_settings_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists business_payment_settings_updated_at on public.business_payment_settings;
create trigger business_payment_settings_updated_at
  before update on public.business_payment_settings
  for each row execute function public.touch_business_payment_settings_updated_at();
