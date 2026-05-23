-- Per-store terms/regulations text (owner-editable, public read).
alter table public.businesses
  add column if not exists store_terms text;

comment on column public.businesses.store_terms is 'Store-specific terms/regulations shown to customers';
