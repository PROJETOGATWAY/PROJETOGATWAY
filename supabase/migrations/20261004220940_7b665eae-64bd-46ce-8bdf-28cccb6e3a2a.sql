create table if not exists public.counter_commissions(
  counter_id uuid primary key references public.profiles(id) on delete cascade,
  percent numeric not null default 0,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now()
);
grant select on public.counter_commissions to authenticated;
grant all on public.counter_commissions to service_role;
alter table public.counter_commissions enable row level security;
create policy counter_commissions_read on public.counter_commissions for select to authenticated using((select public.is_superadmin()) or counter_id=(select auth.uid()));

alter table public.compensation_entries drop constraint if exists compensation_entries_payment_id_key;
alter table public.compensation_entries alter column rule_id drop not null;
create unique index if not exists compensation_entries_payment_beneficiary on public.compensation_entries(payment_id,beneficiary_id);

create or replace function public.set_counter_commission(p_counter_id uuid,p_percent numeric)
returns public.counter_commissions language plpgsql security definer set search_path=''
as $$
declare r public.counter_commissions; fee numeric; others numeric;
begin
  if not public.is_superadmin() then raise exception 'Somente o superadministrador pode definir comissões'; end if;
  if p_percent is null or p_percent<0 then raise exception 'Percentual inválido'; end if;
  if not exists(select 1 from public.profiles where id=p_counter_id and role='admin' and admin_level='contador') then raise exception 'Conta não é Contador'; end if;
  select platform_fee_percent into fee from public.platform_settings where id=1;
  select coalesce(sum(percent),0) into others from public.counter_commissions where counter_id<>p_counter_id;
  if others+p_percent>coalesce(fee,0) then raise exception 'A soma das comissões (% por cento) não pode passar da taxa da JaguaPay (% por cento)', others+p_percent, fee; end if;
  insert into public.counter_commissions(counter_id,percent,updated_by,updated_at) values(p_counter_id,round(p_percent,2),auth.uid(),now())
  on conflict(counter_id) do update set percent=excluded.percent,updated_by=excluded.updated_by,updated_at=now() returning * into r;
  insert into public.audit_logs(actor_id,action,target_user_id,metadata) values(auth.uid(),'counter.commission_set',p_counter_id,jsonb_build_object('percent',r.percent));
  return r;
end $$;
revoke all on function public.set_counter_commission(uuid,numeric) from public,anon;
grant execute on function public.set_counter_commission(uuid,numeric) to authenticated;

create or replace function public.get_my_counter_overview()
returns table(percent numeric, platform_fee_percent numeric, jaguapay_gross_eur numeric, jaguapay_fees_eur numeric, total_accrued_eur numeric)
language sql stable security definer set search_path=''
as $$
  select coalesce((select c.percent from public.counter_commissions c where c.counter_id=auth.uid()),0),
    coalesce((select s.platform_fee_percent from public.platform_settings s where s.id=1),0),
    coalesce((select sum(gross_amount_eur) from public.payment_records where status='approved'),0),
    coalesce((select sum(fee_amount_eur) from public.payment_records where status='approved'),0),
    coalesce((select sum(amount_eur) from public.compensation_entries where beneficiary_id=auth.uid()),0)+coalesce((select sum(amount_eur) from public.compensation_adjustments where beneficiary_id=auth.uid()),0)
  where exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin' and p.admin_level='contador');
$$;
revoke all on function public.get_my_counter_overview() from public,anon;
grant execute on function public.get_my_counter_overview() to authenticated;

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

create or replace function public.admin_reverse_payment(p_payment_id uuid,p_reason text)
returns public.payment_records language plpgsql security definer set search_path=''
as $function$
declare p public.payment_records;result public.payment_records;e record;total numeric:=0;
begin
  if not public.is_admin_or_counter() then raise exception 'Acesso negado'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'O motivo do estorno é obrigatório'; end if;
  select * into p from public.payment_records where id=p_payment_id for update;
  if p.id is null or p.status<>'approved' then raise exception 'Somente vendas aprovadas podem ser estornadas'; end if;
  if exists(select 1 from public.payment_financial_ledger where payment_id=p_payment_id and entry_type='reversal_debit') then raise exception 'Esta venda já foi estornada'; end if;
  update public.payment_records set status='estornado',decision_reason=trim(p_reason),decided_by=(select auth.uid()),updated_at=now() where id=p_payment_id returning * into result;
  insert into public.payment_financial_ledger(seller_id,payment_id,entry_type,amount_eur,reason,created_by) values(p.seller_id,p.id,'reversal_debit',-p.net_amount_eur,trim(p_reason),(select auth.uid()));
  for e in select * from public.compensation_entries where payment_id=p.id for update loop
    insert into public.compensation_adjustments(compensation_entry_id,payment_id,beneficiary_id,amount_eur,reason,created_by) values(e.id,p.id,e.beneficiary_id,-e.amount_eur,'Estorno da venda: comissão revertida',(select auth.uid())) on conflict(compensation_entry_id) do nothing;
    total:=total+e.amount_eur;
  end loop;
  insert into public.audit_logs(actor_id,action,metadata) values((select auth.uid()),'payment.reversed',jsonb_build_object('payment_id',p.id,'reason',trim(p_reason),'compensation_reversed_eur',total));
  return result;
end $function$;