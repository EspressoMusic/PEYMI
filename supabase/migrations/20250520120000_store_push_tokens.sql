-- FCM tokens for customers subscribed to a store's deal notifications.
create table if not exists public.store_push_tokens (
  id uuid primary key default gen_random_uuid(),
  business_slug text not null,
  fcm_token text not null,
  platform text not null default 'android',
  locale text,
  updated_at timestamptz not null default now(),
  unique (business_slug, fcm_token)
);

create index if not exists store_push_tokens_slug_idx
  on public.store_push_tokens (business_slug);

alter table public.store_push_tokens enable row level security;

create policy "store_push_tokens_insert"
  on public.store_push_tokens
  for insert
  to anon, authenticated
  with check (
    char_length(trim(business_slug)) > 0
    and char_length(trim(fcm_token)) > 20
  );

create policy "store_push_tokens_update"
  on public.store_push_tokens
  for update
  to anon, authenticated
  using (true)
  with check (
    char_length(trim(business_slug)) > 0
    and char_length(trim(fcm_token)) > 20
  );
