-- Stage 6: remuneração do Contador
-- Regra interna: base no bruto aprovado, sem alterar taxa ou saldo do vendedor.

create table if not exists public.compensation_rules (
  id uuid primary key default gen_random_uuid(),
  version integer not null unique,
  beneficiary_id uuid not null references public.profiles(id),
  configured_percent numeric(7,4) not null check (configured_percent between 0 and 100),
  active boolean not null default false,
  platform_fee_percent_at_activation numeric(7,4) not null check (platform_fee_percent_at_activation between 0 and 100),
  activated_at timestamptz,
  deactivated_at timestamptz,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists compensation_rules_one_active on public.compensation_rules(active) where active=true;

create table if not exists public.compensation_entries (
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null unique references public.payment_records(id),
  beneficiary_id uuid not null references public.profiles(id),
  rule_id uuid not null references public.compensation_rules(id),
  gross_amount_eur numeric(14,2) not null check(gross_amount_eur>0),
  configured_percent numeric(7,4) not null,
  applied_percent numeric(7,4) not null,
  amount_eur numeric(14,2) not null check(amount_eur>=0),
  created_at timestamptz not null default now(),
  check(applied_percent between 0 and configured_percent),
  check(amount_eur=round(gross_amount_eur*applied_percent/100,2))
);
create index if not exists compensation_entries_beneficiary_idx on public.compensation_entries(beneficiary_id,created_at desc);

create table if not exists public.compensation_adjustments (
  id uuid primary key default gen_random_uuid(),
  compensation_entry_id uuid not null references public.compensation_entries(id),
  payment_id uuid not null references public.payment_records(id),
  beneficiary_id uuid not null references public.profiles(id),
  amount_eur numeric(14,2) not null check(amount_eur<>0),
  reason text not null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);
create unique index if not exists compensation_adjustments_once_per_entry on public.compensation_adjustments(compensation_entry_id);

create table if not exists public.compensation_settlements (
  id uuid primary key default gen_random_uuid(),
  beneficiary_id uuid not null references public.profiles(id),
  amount_eur numeric(14,2) not null check(amount_eur>0),
  settlement_date timestamptz not null,
  settlement_method text not null check(settlement_method in('transfer','central_retention')),
  reference text,
  proof_path text,
  observation text,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);
create index if not exists compensation_settlements_beneficiary_idx on public.compensation_settlements(beneficiary_id,settlement_date desc);

create table if not exists public.compensation_settlement_allocations (
  id uuid primary key default gen_random_uuid(),
  settlement_id uuid not null references public.compensation_settlements(id),
  compensation_entry_id uuid not null references public.compensation_entries(id),
  amount_eur numeric(14,2) not null check(amount_eur>0),
  created_at timestamptz not null default now(),
  unique(settlement_id,compensation_entry_id)
);

alter table public.payment_records
  add column if not exists compensation_rule_id uuid references public.compensation_rules(id),
  add column if not exists compensation_beneficiary_id uuid references public.profiles(id),
  add column if not exists compensation_percent_configured numeric(7,4),
  add column if not exists compensation_percent_applied numeric(7,4);

alter table public.compensation_rules enable row level security;
alter table public.compensation_entries enable row level security;
alter table public.compensation_adjustments enable row level security;
alter table public.compensation_settlements enable row level security;
alter table public.compensation_settlement_allocations enable row level security;
revoke all on public.compensation_rules,public.compensation_entries,public.compensation_adjustments,public.compensation_settlements,public.compensation_settlement_allocations from anon,authenticated;
grant select on public.compensation_rules,public.compensation_entries,public.compensation_adjustments,public.compensation_settlements,public.compensation_settlement_allocations to authenticated;

create policy compensation_rules_read on public.compensation_rules for select to authenticated using((select public.is_superadmin()) or beneficiary_id=(select auth.uid()));
create policy compensation_entries_read on public.compensation_entries for select to authenticated using((select public.is_superadmin()) or beneficiary_id=(select auth.uid()));
create policy compensation_adjustments_read on public.compensation_adjustments for select to authenticated using((select public.is_superadmin()) or beneficiary_id=(select auth.uid()));
create policy compensation_settlements_read on public.compensation_settlements for select to authenticated using((select public.is_superadmin()) or beneficiary_id=(select auth.uid()));
create policy compensation_allocations_read on public.compensation_settlement_allocations for select to authenticated using((select public.is_superadmin()) or exists(select 1 from public.compensation_entries e where e.id=compensation_entry_id and e.beneficiary_id=(select auth.uid())));

-- As funções abaixo devem permanecer protegidas por is_superadmin()/is_admin() e search_path vazio.
-- O SQL completo aplicado no projeto é mantido na migração remota stage6_counter_compensation.


-- Functions applied in the linked project:
CREATE OR REPLACE FUNCTION public.admin_approve_payment(p_payment_id uuid, p_receipt_id uuid DEFAULT NULL::uuid, p_new_receipt_reference text DEFAULT NULL::text, p_new_receipt_at timestamp with time zone DEFAULT NULL::timestamp with time zone, p_new_receipt_amount_eur numeric DEFAULT NULL::numeric, p_new_receipt_method text DEFAULT NULL::text, p_new_receipt_observation text DEFAULT NULL::text)
 RETURNS payment_records
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare p public.payment_records;rc public.central_receipts;result public.payment_records;begin if not public.is_admin() then raise exception 'Acesso negado';end if;select * into p from public.payment_records where id=p_payment_id for update;if p.id is null then raise exception 'Lançamento não encontrado';end if;if p.status not in('pending','under_review') then raise exception 'O lançamento já foi decidido';end if;if p_receipt_id is not null then select * into rc from public.central_receipts where id=p_receipt_id for update;if rc.id is null then raise exception 'Recebimento não encontrado';end if;else if nullif(trim(p_new_receipt_reference),'') is null or p_new_receipt_amount_eur is null or p_new_receipt_method is null then raise exception 'Selecione um recebimento existente ou informe os dados do recebimento real';end if;if p_new_receipt_amount_eur<>p.gross_amount_eur then raise exception 'O valor do recebimento real deve ser exatamente igual ao valor da venda';end if;if p_new_receipt_method<>p.payment_method then raise exception 'O método do recebimento real deve ser igual ao método da venda';end if;insert into public.central_receipts(receipt_reference,received_at,amount_eur,payment_method,observation,seller_id,payment_id,created_by) values(trim(p_new_receipt_reference),coalesce(p_new_receipt_at,now()),p_new_receipt_amount_eur,p_new_receipt_method,p_new_receipt_observation,p.seller_id,p.id,(select auth.uid())) returning * into rc;end if;if rc.payment_id is not null and rc.payment_id<>p.id then raise exception 'Este recebimento já está vinculado a outra venda';end if;if rc.amount_eur<>p.gross_amount_eur or rc.payment_method<>p.payment_method then raise exception 'Recebimento incompatível com a venda';end if;if rc.payment_id is null then update public.central_receipts set payment_id=p.id,seller_id=p.seller_id where id=rc.id;end if;update public.payment_records set status='approved',approved_at=now(),receipt_id=rc.id,decided_by=(select auth.uid()),updated_at=now() where id=p.id returning * into result;insert into public.payment_financial_ledger(seller_id,payment_id,entry_type,amount_eur,reason,created_by) values(p.seller_id,p.id,'sale_credit',p.net_amount_eur,'Venda aprovada após conferência do recebimento real',(select auth.uid()));if p.compensation_rule_id is not null and p.compensation_beneficiary_id is not null and coalesce(p.compensation_percent_applied,0)>0 then insert into public.compensation_entries(payment_id,beneficiary_id,rule_id,gross_amount_eur,configured_percent,applied_percent,amount_eur) values(p.id,p.compensation_beneficiary_id,p.compensation_rule_id,p.gross_amount_eur,coalesce(p.compensation_percent_configured,0),coalesce(p.compensation_percent_applied,0),round(p.gross_amount_eur*coalesce(p.compensation_percent_applied,0)/100,2)) on conflict(payment_id) do nothing;end if;insert into public.audit_logs(actor_id,action,metadata) values((select auth.uid()),'payment.approved',jsonb_build_object('payment_id',p.id,'receipt_id',rc.id,'gross_amount_eur',p.gross_amount_eur,'fee_percent',p.fee_percent_snapshot,'net_amount_eur',p.net_amount_eur,'compensation_percent_applied',p.compensation_percent_applied));return result;exception when unique_violation then raise exception 'Esta venda ou recebimento já foi processado por outro administrador';end $function$


CREATE OR REPLACE FUNCTION public.admin_reverse_payment(p_payment_id uuid, p_reason text)
 RETURNS payment_records
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare p public.payment_records;result public.payment_records;e public.compensation_entries;begin if not public.is_admin() then raise exception 'Acesso negado';end if;if nullif(trim(p_reason),'') is null then raise exception 'O motivo do estorno é obrigatório';end if;select * into p from public.payment_records where id=p_payment_id for update;if p.id is null or p.status<>'approved' then raise exception 'Somente vendas aprovadas podem ser estornadas';end if;if exists(select 1 from public.payment_financial_ledger where payment_id=p_payment_id and entry_type='reversal_debit') then raise exception 'Esta venda já foi estornada';end if;update public.payment_records set status='estornado',decision_reason=trim(p_reason),decided_by=(select auth.uid()),updated_at=now() where id=p_payment_id returning * into result;insert into public.payment_financial_ledger(seller_id,payment_id,entry_type,amount_eur,reason,created_by) values(p.seller_id,p.id,'reversal_debit',-p.net_amount_eur,trim(p_reason),(select auth.uid()));select * into e from public.compensation_entries where payment_id=p.id for update;if e.id is not null then insert into public.compensation_adjustments(compensation_entry_id,payment_id,beneficiary_id,amount_eur,reason,created_by) values(e.id,p.id,e.beneficiary_id,-e.amount_eur,'Estorno da venda: compensação proporcional revertida',(select auth.uid())) on conflict(compensation_entry_id) do nothing;end if;insert into public.audit_logs(actor_id,action,metadata) values((select auth.uid()),'payment.reversed',jsonb_build_object('payment_id',p.id,'reason',trim(p_reason),'compensation_reversed_eur',coalesce(e.amount_eur,0)));return result;end $function$


CREATE OR REPLACE FUNCTION public.create_compensation_settlement(p_beneficiary_id uuid, p_amount_eur numeric, p_settlement_date timestamp with time zone, p_settlement_method text, p_reference text, p_proof_path text, p_observation text)
 RETURNS compensation_settlements
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare result public.compensation_settlements;remaining numeric:=round(p_amount_eur,2);pending numeric;e record;begin if not public.is_superadmin() then raise exception 'Somente o superadministrador pode registrar acertos';end if;if p_amount_eur is null or p_amount_eur<=0 then raise exception 'O valor do acerto deve ser maior que zero';end if;if p_settlement_method not in('transfer','central_retention') then raise exception 'Forma de acerto inválida';end if;if p_settlement_method='transfer' and nullif(trim(coalesce(p_reference,'')),'') is null and nullif(trim(coalesce(p_proof_path,'')),'') is null then raise exception 'Transferência exige referência ou comprovante';end if;select greatest(0,round(coalesce((select sum(amount_eur) from public.compensation_entries where beneficiary_id=p_beneficiary_id),0)+coalesce((select sum(amount_eur) from public.compensation_adjustments where beneficiary_id=p_beneficiary_id),0)-coalesce((select sum(amount_eur) from public.compensation_settlements where beneficiary_id=p_beneficiary_id),0),2)) into pending;if p_amount_eur>pending then raise exception 'O acerto excede o saldo positivo pendente';end if;insert into public.compensation_settlements(beneficiary_id,amount_eur,settlement_date,settlement_method,reference,proof_path,observation,created_by) values(p_beneficiary_id,round(p_amount_eur,2),coalesce(p_settlement_date,now()),p_settlement_method,nullif(trim(p_reference),''),nullif(trim(p_proof_path),''),nullif(trim(p_observation),''),(select auth.uid())) returning * into result;for e in select ce.id,greatest(0,round(ce.amount_eur+coalesce((select sum(a.amount_eur) from public.compensation_adjustments a where a.compensation_entry_id=ce.id),0)-coalesce((select sum(sa.amount_eur) from public.compensation_settlement_allocations sa where sa.compensation_entry_id=ce.id),0),2)) available from public.compensation_entries ce where ce.beneficiary_id=p_beneficiary_id order by ce.created_at,ce.id for update loop exit when remaining<=0;if e.available>0 then insert into public.compensation_settlement_allocations(settlement_id,compensation_entry_id,amount_eur) values(result.id,e.id,least(remaining,e.available));remaining:=round(remaining-least(remaining,e.available),2);end if;end loop;if remaining<>0 then raise exception 'Não foi possível alocar integralmente o acerto';end if;insert into public.audit_logs(actor_id,target_user_id,action,metadata) values((select auth.uid()),p_beneficiary_id,'compensation.settlement_created',jsonb_build_object('settlement_id',result.id,'amount_eur',result.amount_eur,'method',result.settlement_method,'reference',result.reference));return result;end $function$


CREATE OR REPLACE FUNCTION public.create_payment_submission(p_gross_amount_eur numeric, p_payment_method text, p_reference text, p_order_id text, p_notes text, p_idempotency_key text)
 RETURNS payment_records
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare s public.platform_settings;result public.payment_records;fee numeric;r public.compensation_rules;effective numeric:=0;begin if not exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='seller' and p.status='active') then raise exception 'Conta de vendedor indisponível';end if;if p_gross_amount_eur is null or p_gross_amount_eur<=0 then raise exception 'O valor recebido deve ser maior que zero';end if;if p_payment_method not in('mbway','iban') then raise exception 'Método de pagamento inválido';end if;if nullif(trim(p_idempotency_key),'') is null then raise exception 'Identificador de envio ausente';end if;select * into s from public.platform_settings where id=1;if s.initialized_at is null then raise exception 'As configurações de recebimento ainda não foram salvas';end if;select * into result from public.payment_records where seller_id=(select auth.uid()) and idempotency_key=p_idempotency_key limit 1;if result.id is not null then return result;end if;fee:=round(p_gross_amount_eur*s.platform_fee_percent/100,2);select * into r from public.compensation_rules where active=true limit 1;if r.id is not null and exists(select 1 from public.profiles p where p.id=r.beneficiary_id and p.role='admin' and p.admin_level='contador' and p.status='active') then effective:=least(r.configured_percent,s.platform_fee_percent);end if;insert into public.payment_records(seller_id,gross_amount_eur,fee_percent_snapshot,fee_amount_eur,net_amount_eur,status,reference,currency,payment_method,order_id,notes,mbway_phone_snapshot,central_iban_snapshot,idempotency_key,compensation_rule_id,compensation_beneficiary_id,compensation_percent_configured,compensation_percent_applied) values((select auth.uid()),round(p_gross_amount_eur,2),s.platform_fee_percent,fee,round(p_gross_amount_eur-fee,2),'pending',nullif(trim(p_reference),''),'EUR',p_payment_method,nullif(trim(p_order_id),''),nullif(trim(p_notes),''),s.mbway_phone,s.central_iban,p_idempotency_key,case when r.id is not null then r.id end,case when r.id is not null then r.beneficiary_id end,case when r.id is not null then r.configured_percent end,case when r.id is not null then effective end) returning * into result;return result;exception when unique_violation then select * into result from public.payment_records where seller_id=(select auth.uid()) and idempotency_key=p_idempotency_key limit 1;if result.id is not null then return result;end if;raise;end $function$


CREATE OR REPLACE FUNCTION public.deactivate_counter_compensation(p_reason text)
 RETURNS compensation_rules
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare r public.compensation_rules;begin if not public.is_superadmin() then raise exception 'Somente o superadministrador pode desativar a remuneração';end if;if nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'O motivo da desativação é obrigatório';end if;select * into r from public.compensation_rules where active=true limit 1 for update;if r.id is null then raise exception 'Nenhuma remuneração ativa';end if;update public.compensation_rules set active=false,deactivated_at=now(),updated_at=now() where id=r.id returning * into r;insert into public.audit_logs(actor_id,target_user_id,action,metadata) values((select auth.uid()),r.beneficiary_id,'compensation.deactivated',jsonb_build_object('reason',trim(p_reason),'rule_id',r.id,'version',r.version));return r;end $function$


CREATE OR REPLACE FUNCTION public.get_compensation_balances()
 RETURNS TABLE(beneficiary_id uuid, total_accrued_eur numeric, total_adjustments_eur numeric, total_paid_eur numeric, pending_eur numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not public.is_superadmin() then raise exception 'Acesso negado'; end if;
  return query
  select e.beneficiary_id,
    round(sum(e.amount_eur),2),
    round(coalesce((select sum(a.amount_eur) from public.compensation_adjustments a where a.beneficiary_id=e.beneficiary_id),0),2),
    round(coalesce((select sum(s.amount_eur) from public.compensation_settlements s where s.beneficiary_id=e.beneficiary_id),0),2),
    greatest(0,round(sum(e.amount_eur)+coalesce((select sum(a.amount_eur) from public.compensation_adjustments a where a.beneficiary_id=e.beneficiary_id),0)-coalesce((select sum(s.amount_eur) from public.compensation_settlements s where s.beneficiary_id=e.beneficiary_id),0),2))
  from public.compensation_entries e group by e.beneficiary_id;
end $function$


CREATE OR REPLACE FUNCTION public.get_my_compensation_summary()
 RETURNS TABLE(configured_percent numeric, active boolean, total_accrued_eur numeric, total_adjustments_eur numeric, total_paid_eur numeric, pending_eur numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare r public.compensation_rules;
begin
  if not exists(select 1 from public.profiles p where p.id=(select auth.uid()) and p.role='admin' and p.admin_level='contador' and p.status='active') then raise exception 'Acesso negado'; end if;
  select cr.* into r from public.compensation_rules cr where cr.active=true limit 1;
  return query
  select coalesce(r.configured_percent,0),coalesce(r.active,false),
    round(coalesce((select sum(e.amount_eur) from public.compensation_entries e where e.beneficiary_id=(select auth.uid())),0),2),
    round(coalesce((select sum(a.amount_eur) from public.compensation_adjustments a where a.beneficiary_id=(select auth.uid())),0),2),
    round(coalesce((select sum(s.amount_eur) from public.compensation_settlements s where s.beneficiary_id=(select auth.uid())),0),2),
    greatest(0,round(coalesce((select sum(e.amount_eur) from public.compensation_entries e where e.beneficiary_id=(select auth.uid())),0)+coalesce((select sum(a.amount_eur) from public.compensation_adjustments a where a.beneficiary_id=(select auth.uid())),0)-coalesce((select sum(s.amount_eur) from public.compensation_settlements s where s.beneficiary_id=(select auth.uid())),0),2));
end $function$


CREATE OR REPLACE FUNCTION public.remove_counter(p_user_id uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare target public.profiles; restored_role text; r public.compensation_rules;
begin
  if not public.is_superadmin() then raise exception 'Somente o superadministrador pode remover contadores'; end if;
  if nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'O motivo da remoção é obrigatório'; end if;
  select * into target from public.profiles where id=p_user_id for update;
  if target.id is null or target.role<>'admin' or target.admin_level<>'contador' then raise exception 'Contador não encontrado'; end if;
  select * into r from public.compensation_rules where active=true and beneficiary_id=p_user_id limit 1 for update;
  if r.id is not null then update public.compensation_rules set active=false,deactivated_at=now(),updated_at=now() where id=r.id; end if;
  restored_role:=coalesce(nullif(target.counter_previous_role,''),'seller');
  if restored_role not in ('seller','admin') then restored_role:='seller'; end if;
  update public.profiles set role=restored_role::public.user_role,admin_level='standard',counter_previous_role=null,updated_at=now() where id=target.id;
  insert into public.audit_logs(actor_id,target_user_id,action,metadata) values(auth.uid(),target.id,'counter.removed',jsonb_build_object('reason',trim(p_reason),'restored_role',restored_role,'compensation_deactivated',r.id is not null));
end $function$


CREATE OR REPLACE FUNCTION public.save_compensation_rule(p_beneficiary_id uuid, p_configured_percent numeric, p_active boolean, p_reason text)
 RETURNS compensation_rules
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$ declare s public.platform_settings;t public.profiles;old public.compensation_rules;result public.compensation_rules;v integer;begin if not public.is_superadmin() then raise exception 'Somente o superadministrador pode alterar a remuneração';end if;if nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'O motivo da alteração é obrigatório';end if;select * into s from public.platform_settings where id=1;if p_configured_percent is null or p_configured_percent<0 then raise exception 'O percentual não pode ser negativo';end if;if p_configured_percent>s.platform_fee_percent then raise exception 'O percentual do Contador não pode exceder a taxa global atual';end if;if p_active and p_beneficiary_id is null then raise exception 'Confirme um beneficiário antes de ativar a remuneração';end if;if p_beneficiary_id is not null then select * into t from public.profiles where id=p_beneficiary_id for update;if t.id is null or t.role<>'admin' or t.admin_level<>'contador' or t.status<>'active' then raise exception 'O beneficiário precisa ser um Contador ativo';end if;end if;select * into old from public.compensation_rules where active=true limit 1 for update;select coalesce(max(version),0)+1 into v from public.compensation_rules;if old.id is not null then update public.compensation_rules set active=false,deactivated_at=now(),updated_at=now() where id=old.id;end if;insert into public.compensation_rules(version,beneficiary_id,configured_percent,active,platform_fee_percent_at_activation,activated_at,deactivated_at,created_by) values(v,p_beneficiary_id,round(p_configured_percent,4),p_active,s.platform_fee_percent,case when p_active then now() end,case when p_active then null else now() end,(select auth.uid())) returning * into result;insert into public.audit_logs(actor_id,target_user_id,action,metadata) values((select auth.uid()),p_beneficiary_id,'compensation.rule_changed',jsonb_build_object('reason',trim(p_reason),'rule_id',result.id,'version',result.version,'configured_percent',result.configured_percent,'active',result.active));return result;end $function$


CREATE OR REPLACE FUNCTION public.suspend_counter(p_user_id uuid, p_reason text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r public.compensation_rules;
begin
  if not public.is_superadmin() then raise exception 'Somente o superadministrador pode suspender contadores'; end if;
  if nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'O motivo da suspensão é obrigatório'; end if;
  update public.profiles set status='suspended',suspended_at=now(),suspension_reason=trim(p_reason),updated_at=now() where id=p_user_id and role='admin' and admin_level='contador';
  if not found then raise exception 'Contador não encontrado'; end if;
  select * into r from public.compensation_rules where active=true and beneficiary_id=p_user_id limit 1 for update;
  if r.id is not null then update public.compensation_rules set active=false,deactivated_at=now(),updated_at=now() where id=r.id; end if;
  insert into public.audit_logs(actor_id,target_user_id,action,metadata) values(auth.uid(),p_user_id,'counter.suspended',jsonb_build_object('reason',trim(p_reason),'compensation_deactivated',r.id is not null));
end $function$
