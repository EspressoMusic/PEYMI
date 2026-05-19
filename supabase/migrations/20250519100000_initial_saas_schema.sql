-- PEYMI SaaS platform — core schema
-- Run via: supabase db push (or Supabase SQL editor)

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$ begin
  create type public.user_role as enum (
    'super_admin',
    'business_owner',
    'employee',
    'customer'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.subscription_status as enum (
    'trial',
    'active',
    'past_due',
    'suspended',
    'cancelled'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.order_status as enum (
    'new',
    'confirmed',
    'in_progress',
    'ready',
    'completed',
    'cancelled'
  );
exception when duplicate_object then null;
end $$;

do $$ begin
  create type public.appointment_status as enum (
    'new',
    'confirmed',
    'in_progress',
    'completed',
    'cancelled'
  );
exception when duplicate_object then null;
end $$;

-- ---------------------------------------------------------------------------
-- Profiles (extends auth.users)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text,
  full_name text,
  phone text,
  phone_verified boolean not null default false,
  phone_verified_at timestamptz,
  role public.user_role not null default 'customer',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_role_idx on public.profiles (role);
create index if not exists profiles_phone_idx on public.profiles (phone);

-- ---------------------------------------------------------------------------
-- Businesses
-- ---------------------------------------------------------------------------
create table if not exists public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete restrict,
  business_name text not null,
  slug text not null,
  description text,
  logo_url text,
  phone text,
  business_type text,
  address text,
  opening_hours jsonb,
  subscription_status public.subscription_status not null default 'trial',
  past_due_grace_until timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint businesses_slug_unique unique (slug),
  constraint businesses_slug_format check (
    slug ~ '^[a-z0-9]+(?:-[a-z0-9]+)*$'
    and length(slug) >= 2
    and length(slug) <= 80
  )
);

create index if not exists businesses_owner_id_idx on public.businesses (owner_id);
create index if not exists businesses_slug_idx on public.businesses (slug);
create index if not exists businesses_subscription_idx on public.businesses (subscription_status, is_active);

-- ---------------------------------------------------------------------------
-- Products
-- ---------------------------------------------------------------------------
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  name text not null,
  description text,
  price numeric(12, 2) not null check (price >= 0),
  image_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists products_business_id_idx on public.products (business_id);
create index if not exists products_active_idx on public.products (business_id, is_active);

-- ---------------------------------------------------------------------------
-- Orders
-- ---------------------------------------------------------------------------
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  customer_user_id uuid references public.profiles (id) on delete set null,
  customer_name text not null,
  customer_phone text,
  customer_email text,
  items jsonb not null default '[]'::jsonb,
  status public.order_status not null default 'new',
  total_price numeric(12, 2) not null default 0 check (total_price >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint orders_items_is_array check (jsonb_typeof(items) = 'array')
);

create index if not exists orders_business_id_idx on public.orders (business_id);
create index if not exists orders_status_idx on public.orders (business_id, status);

-- ---------------------------------------------------------------------------
-- Appointments
-- ---------------------------------------------------------------------------
create table if not exists public.appointments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  customer_user_id uuid references public.profiles (id) on delete set null,
  customer_name text not null,
  customer_phone text,
  customer_email text,
  service_name text not null,
  appointment_date date not null,
  appointment_time time not null,
  status public.appointment_status not null default 'new',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists appointments_business_id_idx on public.appointments (business_id);
create index if not exists appointments_schedule_idx on public.appointments (business_id, appointment_date);

-- ---------------------------------------------------------------------------
-- Customer messages (contact / inbox per business)
-- ---------------------------------------------------------------------------
create table if not exists public.customer_messages (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses (id) on delete cascade,
  customer_user_id uuid references public.profiles (id) on delete set null,
  customer_name text,
  customer_phone text,
  customer_email text,
  message text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz
);

create index if not exists customer_messages_business_id_idx on public.customer_messages (business_id);

-- ---------------------------------------------------------------------------
-- Phone verification attempts (rate limiting; SMS via Edge Function)
-- ---------------------------------------------------------------------------
create table if not exists public.phone_verification_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  phone text not null,
  code_hash text not null,
  expires_at timestamptz not null,
  attempt_count int not null default 0,
  max_attempts int not null default 5,
  created_at timestamptz not null default now()
);

create index if not exists phone_verification_user_idx on public.phone_verification_attempts (user_id, created_at desc);

-- ---------------------------------------------------------------------------
-- updated_at trigger
-- ---------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

drop trigger if exists businesses_set_updated_at on public.businesses;
create trigger businesses_set_updated_at
  before update on public.businesses
  for each row execute function public.set_updated_at();

drop trigger if exists products_set_updated_at on public.products;
create trigger products_set_updated_at
  before update on public.products
  for each row execute function public.set_updated_at();

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
  before update on public.orders
  for each row execute function public.set_updated_at();

drop trigger if exists appointments_set_updated_at on public.appointments;
create trigger appointments_set_updated_at
  before update on public.appointments
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Auto-create profile on auth signup
-- ---------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', '')
  )
  on conflict (id) do update
    set email = excluded.email,
        updated_at = now();
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Promote first profile to super_admin (optional seed — change email in production)
-- update public.profiles set role = 'super_admin' where email = 'admin@example.com';
