-- Payment review follow-up: require direct receipt reference and return a clear duplicate-reference error.
create or replace function public.admin_approve_payment(p_payment_id uuid,p_receipt_id uuid default null,p_new_receipt_reference text default null,p_new_receipt_at timestamptz default null,p_new_receipt_amount_eur numeric default null,p_new_receipt_method text default null,p_new_receipt_observation text default null)
returns public.payment_records language plpgsql security definer set search_path=''
as $function$
declare p public.payment_records;rc public.central_receipts;result public.payment_records;c record;remaining numeric;applied numeric;
begin
  if not public.is_admin_or_counter() then raise exception 'Acesso negado'; end if;
  select * into p from public.payment_records where id=p_payment_id for update;
  if p.id is null then raise exception 'Lançamento não encontrado'; end if;
  if p.status not in('pending','under_review') then raise exception 'O lançamento já foi decidido'; end if;
  if p_receipt_id is not null then
    select * into rc from public.central_receipts where id=p_receipt_id for update;
    if rc.id is null then raise exception 'Recebimento não encontrado'; end if;
  else
    if nullif(trim(p_new_receipt_reference),'') is null or p_new_receipt_amount_eur is null or p_new_receipt_method is null then raise exception 'A referência do recebimento real é obrigatória'; end if;
    if p_new_receipt_amount_eur<>p.gross_amount_eur then raise exception 'O valor do recebimento real deve ser exatamente igual ao valor da venda'; end if;
    if p_new_receipt_method<>p.payment_method then raise exception 'O método do recebimento real deve ser igual ao método da venda'; end if;
    if exists(select 1 from public.central_receipts where receipt_reference=trim(p_new_receipt_reference)) then raise exception 'A referência do recebimento já está cadastrada. Confira a referência antes de aprovar.'; end if;
    insert into public.central_receipts(receipt_reference,received_at,amount_eur,payment_method,observation,seller_id,payment_id,created_by) values(trim(p_new_receipt_reference),coalesce(p_new_receipt_at,now()),p_new_receipt_amount_eur,p_new_receipt_method,p_new_receipt_observation,p.seller_id,p.id,(select auth.uid())) returning * into rc;
  end if;
  if rc.payment_id is not null and rc.payment_id<>p.id then raise exception 'Este recebimento já está vinculado a outra venda'; end if;
  if rc.amount_eur<>p.gross_amount_eur or rc.payment_method<>p.payment_method then raise exception 'Recebimento incompatível com a venda'; end if;
  if rc.payment_id is null then update public.central_receipts set payment_id=p.id,seller_id=p.seller_id where id=rc.id; end if;
  update public.payment_records set status='approved',approved_at=now(),receipt_id=rc.id,decided_by=(select auth.uid()),updated_at=now() where id=p.id returning * into result;
  insert into public.payment_financial_ledger(seller_id,payment_id,entry_type,amount_eur,reason,created_by) values(p.seller_id,p.id,'sale_credit',p.net_amount_eur,'Venda aprovada após conferência do recebimento real',(select auth.uid()));
  remaining:=coalesce(p.fee_percent_snapshot,0);
  for c in select cc.counter_id,cc.percent from public.counter_commissions cc join public.profiles pr on pr.id=cc.counter_id where cc.percent>0 and pr.role='admin' and pr.admin_level='contador' and pr.status='active' order by cc.percent desc loop
    applied:=least(c.percent,remaining);
    exit when applied<=0;
    insert into public.compensation_entries(payment_id,beneficiary_id,rule_id,gross_amount_eur,configured_percent,applied_percent,amount_eur) values(p.id,c.counter_id,null,p.gross_amount_eur,c.percent,applied,round(p.gross_amount_eur*applied/100,2)) on conflict(payment_id,beneficiary_id) do nothing;
    remaining:=remaining-applied;
  end loop;
  insert into public.audit_logs(actor_id,action,metadata) values((select auth.uid()),'payment.approved',jsonb_build_object('payment_id',p.id,'receipt_id',rc.id,'gross_amount_eur',p.gross_amount_eur,'fee_percent',p.fee_percent_snapshot,'net_amount_eur',p.net_amount_eur));
  return result;
exception when unique_violation then raise exception 'Esta venda ou recebimento já foi processado por outro administrador';
end $function$;