-- Payment review follow-up: Contador may read private payment proofs
-- through the existing authenticated storage flow, without making the bucket public.
drop policy if exists payment_proofs_read_seller_or_admin on storage.objects;
create policy payment_proofs_read_seller_or_admin on storage.objects
for select to authenticated
using (
  bucket_id='payment-proofs'
  and (
    (storage.foldername(name))[1]=(select auth.uid()::text)
    or public.is_admin_or_counter()
  )
);

revoke all on function public.is_admin_or_counter() from public;
grant execute on function public.is_admin_or_counter() to authenticated;
