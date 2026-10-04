-- Etapa 3: comprovantes aprovados/decididos não podem ser apagados pelo vendedor
drop policy if exists payment_proofs_delete_own_pending on storage.objects;
create policy payment_proofs_delete_own_pending on storage.objects for delete to authenticated
using(
  bucket_id='payment-proofs'
  and (storage.foldername(name))[1]=(select auth.uid()::text)
  and not exists(
    select 1 from public.payment_records p
    where p.seller_id=auth.uid() and p.proof_path=name and p.status in ('approved','rejected','under_review','estornado')
  )
);
