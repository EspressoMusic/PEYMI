-- Platform Terms of Use / Privacy Policy acceptance (business owners).

create table if not exists public.legal_acceptances (
  user_id uuid primary key references auth.users (id) on delete cascade,
  accepted_terms_at timestamptz not null,
  accepted_privacy_at timestamptz not null,
  terms_version text not null,
  privacy_version text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists legal_acceptances_versions_idx
  on public.legal_acceptances (terms_version, privacy_version);

alter table public.legal_acceptances enable row level security;

drop policy if exists legal_acceptances_select_own on public.legal_acceptances;
create policy legal_acceptances_select_own on public.legal_acceptances
  for select to authenticated
  using (user_id = auth.uid());

drop policy if exists legal_acceptances_insert_own on public.legal_acceptances;
create policy legal_acceptances_insert_own on public.legal_acceptances
  for insert to authenticated
  with check (user_id = auth.uid());

drop policy if exists legal_acceptances_update_own on public.legal_acceptances;
create policy legal_acceptances_update_own on public.legal_acceptances
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, update on table public.legal_acceptances to authenticated;

comment on table public.legal_acceptances is
  'Records when a user accepted Peymiz Terms of Use and Privacy Policy (versioned).';
