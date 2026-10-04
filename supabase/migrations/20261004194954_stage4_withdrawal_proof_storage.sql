insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('withdrawal-proofs','withdrawal-proofs',false,10485760,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict (id) do update set public=false,file_size_limit=10485760,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "withdrawal proof admin read" on storage.objects;
create policy "withdrawal proof admin read" on storage.objects for select to authenticated using (bucket_id='withdrawal-proofs' and public.is_admin());
drop policy if exists "withdrawal proof admin write" on storage.objects;
create policy "withdrawal proof admin write" on storage.objects for insert to authenticated with check (bucket_id='withdrawal-proofs' and public.is_admin());
drop policy if exists "withdrawal proof admin update" on storage.objects;
create policy "withdrawal proof admin update" on storage.objects for update to authenticated using (bucket_id='withdrawal-proofs' and public.is_admin()) with check (bucket_id='withdrawal-proofs' and public.is_admin());
drop policy if exists "withdrawal proof admin delete" on storage.objects;
create policy "withdrawal proof admin delete" on storage.objects for delete to authenticated using (bucket_id='withdrawal-proofs' and public.is_admin());
