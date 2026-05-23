-- Run once in Supabase Dashboard → SQL Editor (project qruzhluqmmzlcxksftuh)
-- Or: .\tools\apply_supabase_sql.ps1  (needs SUPABASE_ACCESS_TOKEN in .env)

alter table public.businesses
  add column if not exists store_terms text;

comment on column public.businesses.store_terms is 'Store-specific terms/regulations shown to customers';
