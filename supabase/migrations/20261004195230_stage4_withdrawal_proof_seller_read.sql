drop policy if exists "withdrawal proof seller read own" on storage.objects;
create policy "withdrawal proof seller read own" on storage.objects for select to authenticated using (bucket_id='withdrawal-proofs' and (storage.foldername(name))[1]=auth.uid()::text);
