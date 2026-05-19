-- Storage buckets for business logos and product images

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('business-logos', 'business-logos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp']),
  ('product-images', 'product-images', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- Public read for logos/images
drop policy if exists storage_public_read_logos on storage.objects;
create policy storage_public_read_logos on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'business-logos');

drop policy if exists storage_public_read_products on storage.objects;
create policy storage_public_read_products on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'product-images');

-- Owners upload only into their business folder: {business_id}/file
drop policy if exists storage_owner_insert_logos on storage.objects;
create policy storage_owner_insert_logos on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'business-logos'
    and public.owns_business((storage.foldername(name))[1]::uuid)
  );

drop policy if exists storage_owner_insert_products on storage.objects;
create policy storage_owner_insert_products on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'product-images'
    and public.owns_business((storage.foldername(name))[1]::uuid)
  );

drop policy if exists storage_owner_update_delete on storage.objects;
create policy storage_owner_update_delete on storage.objects
  for update to authenticated
  using (
    bucket_id in ('business-logos', 'product-images')
    and public.owns_business((storage.foldername(name))[1]::uuid)
  );

drop policy if exists storage_owner_delete on storage.objects;
create policy storage_owner_delete on storage.objects
  for delete to authenticated
  using (
    bucket_id in ('business-logos', 'product-images')
    and public.owns_business((storage.foldername(name))[1]::uuid)
  );
