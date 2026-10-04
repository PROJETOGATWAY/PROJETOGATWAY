-- Stage 6 follow-up: isolate Contador to operational payment/withdrawal workflows
-- and remove seller-management access.

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $function$
  select exists(
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin' and p.status = 'active' and p.admin_level <> 'contador'
  );
$function$;

create or replace function public.is_admin_or_counter()
returns boolean
language sql
stable
security definer
set search_path = public
as $function$
  select exists(
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role = 'admin' and p.status = 'active'
  );
$function$;

create or replace function public.admin_approve_payment(p_payment_id uuid,p_receipt_id uuid default null,p_new_receipt_reference text default null,p_new_receipt_at timestamptz default null,p_new_receipt_amount_eur numeric default null,p_new_receipt_method text default null,p_new_receipt_observation text default null)
returns public.payment_records language plpgsql security definer set search_path=''
as $function$
declare p public.payment_records;rc public.central_receipts;result public.payment_records;
begin
  if not public.is_admin_or_counter() then raise exception 'Acesso negado'; end if;
  select * into p from public.payment_records where id=p_payment_id for update;
  if p.id is null then raise exception 'Lançamento não encontrado'; end if;
  if p.status not in('pending','under_review') then raise exception 'O lançamento já foi decidido'; end if;
  if p_receipt_id is not null then
    select * into rc from public.central_receipts where id=p_receipt_id for update;
    if rc.id is null then raise exception 'Recebimento não encontrado'; end if;
  else
    if nullif(trim(p_new_receipt_reference),'') is null or p_new_receipt_amount_eur is null or p_new_receipt_method is null then raise exception 'Selecione um recebimento existente ou informe os dados do recebimento real'; end if;
    if p_new_receipt_amount_eur<>p.gross_amount_eur then raise exception 'O valor do recebimento real deve ser exatamente igual ao valor da venda'; end if;
    if p_new_receipt_method<>p.payment_method then raise exception 'O método do recebimento real deve ser igual ao método da venda'; end if;
    insert into public.central_receipts(receipt_reference,received_at,amount_eur,payment_method,observation,seller_id,payment_id,created_by) values(trim(p_new_receipt_reference),coalesce(p_new_receipt_at,now()),p_new_receipt_amount_eur,p_new_receipt_method,p_new_receipt_observation,p.seller_id,p.id,(select auth.uid())) returning * into rc;
  end if;
  if rc.payment_id is not null and rc.payment_id<>p.id then raise exception 'Este recebimento já está vinculado a outra venda'; end if;
  if rc.amount_eur<>p.gross_amount_eur or rc.payment_method<>p.payment_method then raise exception 'Recebimento incompatível com a venda'; end if;
  if rc.payment_id is null then update public.central_receipts set payment_id=p.id,seller_id=p.seller_id where id=rc.id; end if;
  update public.payment_records set status='approved',approved_at=now(),receipt_id=rc.id,decided_by=(select auth.uid()),updated_at=now() where id=p.id returning * into result;
  insert into public.payment_financial_ledger(seller_id,payment_id,entry_type,amount_eur,reason,created_by) values(p.seller_id,p.id,'sale_credit',p.net_amount_eur,'Venda aprovada após conferência do recebimento real',(select auth.uid()));
  if p.compensation_rule_id is not null and p.compensation_beneficiary_id is not null and coalesce(p.compensation_percent_applied,0)>0 then
    insert into public.compensation_entries(payment_id,beneficiary_id,rule_id,gross_amount_eur,configured_percent,applied_percent,amount_eur) values(p.id,p.compensation_beneficiary_id,p.compensation_rule_id,p.gross_amount_eur,coalesce(p.compensation_percent_configured,0),coalesce(p.compensation_percent_applied,0),round(p.gross_amount_eur*coalesce(p.compensation_percent_applied,0)/100,2)) on conflict(payment_id) do nothing;
  end if;
  insert into public.audit_logs(actor_id,action,metadata) values((select auth.uid()),'payment.approved',jsonb_build_object('payment_id',p.id,'receipt_id',rc.id,'gross_amount_eur',p.gross_amount_eur,'fee_percent',p.fee_percent_snapshot,'net_amount_eur',p.net_amount_eur,'compensation_percent_applied',p.compensation_percent_applied));
  return result;
exception when unique_violation then raise exception 'Esta venda ou recebimento já foi processado por outro administrador';
end $function$;

create or replace function public.admin_escalate_payment(p_payment_id uuid,p_reason text)
returns public.payment_records language plpgsql security definer set search_path=''
as $function$
declare result public.payment_records;
begin
  if not public.is_admin_or_counter() then raise exception 'Acesso negado'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'O motivo da análise adicional é obrigatório'; end if;
  update public.payment_records set status='under_review',risk_reason=trim(p_reason),updated_at=now() where id=p_payment_id and status='pending' returning * into result;
  if result.id is null then raise exception 'O lançamento não está aguardando análise'; end if;
  insert into public.audit_logs(actor_id,action,metadata) values(auth.uid(),'payment.escalated',jsonb_build_object('payment_id',result.id,'reason',result.risk_reason));
  return result;
end $function$;

create or replace function public.admin_reject_payment(p_payment_id uuid,p_reason text)
returns public.payment_records language plpgsql security definer set search_path=''
as $function$
declare result public.payment_records;
begin
  if not public.is_admin_or_counter() then raise exception 'Acesso negado'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'O motivo da rejeição é obrigatório'; end if;
  update public.payment_records set status='rejected',decision_reason=trim(p_reason),decided_by=auth.uid(),updated_at=now() where id=p_payment_id and status in ('pending','under_review') returning * into result;
  if result.id is null then raise exception 'O lançamento já foi decidido ou não existe'; end if;
  insert into public.audit_logs(actor_id,action,metadata) values(auth.uid(),'payment.rejected',jsonb_build_object('payment_id',result.id,'reason',result.decision_reason));
  return result;
end $function$;

create or replace function public.admin_reverse_payment(p_payment_id uuid,p_reason text)
returns public.payment_records language plpgsql security definer set search_path=''
as $function$
declare p public.payment_records;result public.payment_records;e public.compensation_entries;
begin
  if not public.is_admin_or_counter() then raise exception 'Acesso negado'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'O motivo do estorno é obrigatório'; end if;
  select * into p from public.payment_records where id=p_payment_id for update;
  if p.id is null or p.status<>'approved' then raise exception 'Somente vendas aprovadas podem ser estornadas'; end if;
  if exists(select 1 from public.payment_financial_ledger where payment_id=p_payment_id and entry_type='reversal_debit') then raise exception 'Esta venda já foi estornada'; end if;
  update public.payment_records set status='estornado',decision_reason=trim(p_reason),decided_by=(select auth.uid()),updated_at=now() where id=p_payment_id returning * into result;
  insert into public.payment_financial_ledger(seller_id,payment_id,entry_type,amount_eur,reason,created_by) values(p.seller_id,p.id,'reversal_debit',-p.net_amount_eur,trim(p_reason),(select auth.uid()));
  select * into e from public.compensation_entries where payment_id=p.id for update;
  if e.id is not null then insert into public.compensation_adjustments(compensation_entry_id,payment_id,beneficiary_id,amount_eur,reason,created_by) values(e.id,p.id,e.beneficiary_id,-e.amount_eur,'Estorno da venda: compensação proporcional revertida',(select auth.uid())) on conflict(compensation_entry_id) do nothing; end if;
  insert into public.audit_logs(actor_id,action,metadata) values((select auth.uid()),'payment.reversed',jsonb_build_object('payment_id',p.id,'reason',trim(p_reason),'compensation_reversed_eur',coalesce(e.amount_eur,0)));
  return result;
end $function$;

create or replace function public.admin_add_payment_note(p_payment_id uuid,p_note text)
returns public.payment_admin_notes language plpgsql security definer set search_path=''
as $function$
declare result public.payment_admin_notes;
begin
  if not public.is_admin_or_counter() then raise exception 'Acesso negado'; end if;
  if nullif(trim(p_note),'') is null then raise exception 'A anotação não pode ficar vazia'; end if;
  insert into public.payment_admin_notes(payment_id,admin_id,note) values(p_payment_id,auth.uid(),trim(p_note)) returning * into result;
  return result;
end $function$;

create or replace function public.admin_mark_withdrawal_paid(p_withdrawal_id uuid,p_payment_reference text,p_payment_proof_path text,p_paid_amount_brl numeric default null)
returns public.withdrawals language plpgsql security definer set search_path=''
as $function$
declare result public.withdrawals; target_seller uuid;
begin
  if not public.is_admin_or_counter() then raise exception 'Acesso negado'; end if;
  if nullif(trim(p_payment_reference),'') is null then raise exception 'A referência do pagamento é obrigatória'; end if;
  if nullif(trim(p_payment_proof_path),'') is null then raise exception 'O comprovante do pagamento é obrigatório'; end if;
  select seller_id into target_seller from public.withdrawals where id=p_withdrawal_id;
  if target_seller is null then raise exception 'Saque não encontrado'; end if;
  perform 1 from public.profiles where id=target_seller for update;
  select * into result from public.withdrawals where id=p_withdrawal_id for update;
  if result.status<>'processing' then raise exception 'O saque precisa estar Em processamento para ser marcado como Pago'; end if;
  if p_payment_proof_path not like result.seller_id::text || '/' || result.id::text || '/%' then raise exception 'Comprovante inválido para este saque'; end if;
  if not exists(select 1 from storage.objects where bucket_id='withdrawal-proofs' and name=p_payment_proof_path) then raise exception 'O comprovante não foi encontrado no armazenamento privado'; end if;
  if result.method_type_snapshot='pix' then
    if p_paid_amount_brl is null or p_paid_amount_brl<=0 then raise exception 'Informe o valor efetivamente transferido em BRL para Pix'; end if;
  else
    if p_paid_amount_brl is not null then raise exception 'Valor em BRL só é permitido para Pix'; end if;
  end if;
  update public.withdrawals set status='paid',payment_reference=trim(p_payment_reference),payment_proof_path=trim(p_payment_proof_path),paid_amount_brl=case when result.method_type_snapshot='pix' then round(p_paid_amount_brl,2) else null end,paid_at=now(),confirmed_at=now(),decided_by=auth.uid(),updated_at=now() where id=result.id returning * into result;
  insert into public.audit_logs(actor_id,target_user_id,action,metadata) values(auth.uid(),result.seller_id,'withdrawal.paid',jsonb_build_object('withdrawal_id',result.id,'amount_eur',result.amount_eur,'net_amount_eur',result.net_amount_eur,'payment_reference',result.payment_reference,'paid_amount_brl',result.paid_amount_brl));
  return result;
end $function$;

create or replace function public.admin_set_withdrawal_status(p_withdrawal_id uuid,p_status text,p_reason text default null)
returns public.withdrawals language plpgsql security definer set search_path=''
as $function$
declare result public.withdrawals; old_status text; target_seller uuid;
begin
  if not public.is_admin_or_counter() then raise exception 'Acesso negado'; end if;
  select seller_id into target_seller from public.withdrawals where id=p_withdrawal_id;
  if target_seller is null then raise exception 'Saque não encontrado'; end if;
  perform 1 from public.profiles where id=target_seller for update;
  select * into result from public.withdrawals where id=p_withdrawal_id for update;
  old_status:=result.status;
  if p_status='under_review' and result.status<>'requested' then raise exception 'Transição inválida'; end if;
  if p_status='approved_for_payment' and result.status not in ('requested','under_review') then raise exception 'Transição inválida'; end if;
  if p_status='processing' and result.status<>'approved_for_payment' then raise exception 'O saque precisa estar aprovado para pagamento'; end if;
  if p_status in ('rejected','cancelled') then
    if result.status in ('paid','processing','rejected','cancelled') then raise exception 'Este saque não pode ser rejeitado ou cancelado'; end if;
    if nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'O motivo é obrigatório'; end if;
  else
    if p_status not in ('under_review','approved_for_payment','processing') then raise exception 'Estado administrativo inválido'; end if;
  end if;
  update public.withdrawals set status=p_status,decision_reason=case when p_status in ('rejected','cancelled') then trim(p_reason) else decision_reason end,decided_by=auth.uid(),updated_at=now() where id=result.id returning * into result;
  if p_status in ('rejected','cancelled') then insert into public.payment_financial_ledger(seller_id,withdrawal_id,entry_type,amount_eur,reason,created_by) values(result.seller_id,result.id,'withdrawal_release',result.amount_eur,case when p_status='rejected' then 'Liberação de reserva por rejeição' else 'Liberação de reserva por cancelamento administrativo' end,auth.uid()); end if;
  insert into public.audit_logs(actor_id,target_user_id,action,metadata) values(auth.uid(),result.seller_id,'withdrawal.status_changed',jsonb_build_object('withdrawal_id',result.id,'from_status',old_status,'to_status',p_status,'reason',p_reason));
  return result;
end $function$;

drop policy if exists "profiles_select_self_or_admin" on public.profiles;
create policy "profiles_select_self_or_admin" on public.profiles for select to public using (id=auth.uid() or public.is_admin());

drop policy if exists payment_records_select_own_or_admin on public.payment_records;
create policy payment_records_select_own_or_admin on public.payment_records for select to public using (seller_id=auth.uid() or public.is_admin_or_counter());

drop policy if exists withdrawals_select_own_or_admin on public.withdrawals;
create policy withdrawals_select_own_or_admin on public.withdrawals for select to public using (seller_id=auth.uid() or public.is_admin_or_counter());

drop policy if exists central_receipts_admin_select on public.central_receipts;
create policy central_receipts_admin_select on public.central_receipts for select to public using (public.is_admin_or_counter());

drop policy if exists central_receipts_admin_insert on public.central_receipts;
create policy central_receipts_admin_insert on public.central_receipts for insert to public with check (public.is_admin_or_counter() and created_by=auth.uid());

drop policy if exists payment_admin_notes_admin_select on public.payment_admin_notes;
create policy payment_admin_notes_admin_select on public.payment_admin_notes for select to public using (public.is_admin_or_counter());

drop policy if exists payment_admin_notes_admin_insert on public.payment_admin_notes;
create policy payment_admin_notes_admin_insert on public.payment_admin_notes for insert to public with check (public.is_admin_or_counter());

revoke all on function public.is_admin_or_counter() from public;
grant execute on function public.is_admin_or_counter() to authenticated;
