-- Ensure demo store shilo receives customer inquiries at the owner inbox.
update public.businesses
set contact_email = 'shilohdhd1@gmail.com',
    updated_at = now()
where slug = 'shilo'
  and coalesce(nullif(trim(contact_email), ''), '') = '';

update public.businesses
set contact_email = 'shilohdhd1@gmail.com',
    updated_at = now()
where slug = 'shiki'
  and coalesce(nullif(trim(contact_email), ''), '') = '';
