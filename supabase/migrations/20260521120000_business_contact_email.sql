-- Store owner inbox for customer inquiries (contact form, messages).
alter table public.businesses
  add column if not exists contact_email text;

comment on column public.businesses.contact_email is
  'Email address that receives customer inquiries for this store.';
