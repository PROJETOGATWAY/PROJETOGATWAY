-- Etapa 3: o autor do recebimento real é sempre o administrador autenticado
drop policy if exists central_receipts_admin_insert on public.central_receipts;
create policy central_receipts_admin_insert on public.central_receipts
for insert to authenticated
with check(public.is_admin() and created_by=auth.uid());
