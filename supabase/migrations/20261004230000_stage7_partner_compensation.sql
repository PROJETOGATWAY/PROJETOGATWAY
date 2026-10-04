-- Stage 7: condição de Sócio e participação global separada da remuneração do Contador.
alter table public.profiles
  add column if not exists partner_enabled boolean not null default false,
  add column if not exists partner_participation_active boolean not null default false,
  add column if not exists partner_since timestamptz;

create table if not exists public.partner_rules(
  id uuid primary key default gen_random_uuid(),
  version integer not null,
  beneficiary_id uuid not null references public.profiles(id),
  configured_percent numeric(7,4) not null check(configured_percent between 0 and 100),
  active boolean not null default false,
  platform_fee_percent_at_activation numeric(7,4) not null check(platform_fee_percent_at_activation between 0 and 100),
  activated_at timestamptz,
  deactivated_at timestamptz,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(beneficiary_id,version)
);
create unique index if not exists partner_rules_one_active_per_beneficiary on public.partner_rules(beneficiary_id) where active=true;
create index if not exists partner_rules_beneficiary_idx on public.partner_rules(beneficiary_id,created_at desc);

create table if not exists public.partner_payment_snapshots(
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payment_records(id),
  beneficiary_id uuid not null references public.profiles(id),
  rule_id uuid not null references public.partner_rules(id),
  gross_amount_eur numeric(14,2) not null check(gross_amount_eur>0),
  configured_percent numeric(7,4) not null check(configured_percent between 0 and 100),
  applied_percent numeric(7,4) not null check(applied_percent between 0 and 100),
  created_at timestamptz not null default now(),
  unique(payment_id,beneficiary_id)
);
create index if not exists partner_payment_snapshots_beneficiary_idx on public.partner_payment_snapshots(beneficiary_id,created_at desc);

create table if not exists public.partner_entries(
  id uuid primary key default gen_random_uuid(),
  payment_id uuid not null references public.payment_records(id),
  beneficiary_id uuid not null references public.profiles(id),
  rule_id uuid not null references public.partner_rules(id),
  gross_amount_eur numeric(14,2) not null check(gross_amount_eur>0),
  configured_percent numeric(7,4) not null check(configured_percent between 0 and 100),
  applied_percent numeric(7,4) not null check(applied_percent between 0 and 100),
  amount_eur numeric(14,2) not null check(amount_eur>=0),
  created_at timestamptz not null default now(),
  unique(payment_id,beneficiary_id)
);
create index if not exists partner_entries_beneficiary_idx on public.partner_entries(beneficiary_id,created_at desc);

create table if not exists public.partner_adjustments(
  id uuid primary key default gen_random_uuid(),
  partner_entry_id uuid not null references public.partner_entries(id),
  payment_id uuid not null references public.payment_records(id),
  beneficiary_id uuid not null references public.profiles(id),
  amount_eur numeric(14,2) not null check(amount_eur<>0),
  reason text not null,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);
create unique index if not exists partner_adjustments_once_per_entry on public.partner_adjustments(partner_entry_id);
create index if not exists partner_adjustments_beneficiary_idx on public.partner_adjustments(beneficiary_id,created_at desc);

create table if not exists public.partner_settlements(
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
create index if not exists partner_settlements_beneficiary_idx on public.partner_settlements(beneficiary_id,settlement_date desc);

create table if not exists public.partner_settlement_allocations(
  id uuid primary key default gen_random_uuid(),
  settlement_id uuid not null references public.partner_settlements(id),
  partner_entry_id uuid not null references public.partner_entries(id),
  amount_eur numeric(14,2) not null check(amount_eur>0),
  created_at timestamptz not null default now(),
  unique(settlement_id,partner_entry_id)
);

alter table public.partner_rules enable row level security;
alter table public.partner_payment_snapshots enable row level security;
alter table public.partner_entries enable row level security;
alter table public.partner_adjustments enable row level security;
alter table public.partner_settlements enable row level security;
alter table public.partner_settlement_allocations enable row level security;
revoke all on public.partner_rules,public.partner_payment_snapshots,public.partner_entries,public.partner_adjustments,public.partner_settlements,public.partner_settlement_allocations from anon,authenticated;
grant select on public.partner_rules,public.partner_payment_snapshots,public.partner_entries,public.partner_adjustments,public.partner_settlements,public.partner_settlement_allocations to authenticated;

drop policy if exists partner_rules_read on public.partner_rules;
create policy partner_rules_read on public.partner_rules for select to authenticated using(
  (select public.is_superadmin()) or ((select auth.uid())=beneficiary_id and exists(select 1 from public.profiles p where p.id=auth.uid() and p.partner_enabled=true))
);
drop policy if exists partner_snapshots_read on public.partner_payment_snapshots;
create policy partner_snapshots_read on public.partner_payment_snapshots for select to authenticated using(
  (select public.is_superadmin()) or ((select auth.uid())=beneficiary_id and exists(select 1 from public.profiles p where p.id=auth.uid() and p.partner_enabled=true))
);
drop policy if exists partner_entries_read on public.partner_entries;
create policy partner_entries_read on public.partner_entries for select to authenticated using(
  (select public.is_superadmin()) or ((select auth.uid())=beneficiary_id and exists(select 1 from public.profiles p where p.id=auth.uid() and p.partner_enabled=true))
);
drop policy if exists partner_adjustments_read on public.partner_adjustments;
create policy partner_adjustments_read on public.partner_adjustments for select to authenticated using(
  (select public.is_superadmin()) or ((select auth.uid())=beneficiary_id and exists(select 1 from public.profiles p where p.id=auth.uid() and p.partner_enabled=true))
);
drop policy if exists partner_settlements_read on public.partner_settlements;
create policy partner_settlements_read on public.partner_settlements for select to authenticated using(
  (select public.is_superadmin()) or ((select auth.uid())=beneficiary_id and exists(select 1 from public.profiles p where p.id=auth.uid() and p.partner_enabled=true))
);
drop policy if exists partner_allocations_read on public.partner_settlement_allocations;
create policy partner_allocations_read on public.partner_settlement_allocations for select to authenticated using(
  (select public.is_superadmin()) or exists(
    select 1 from public.partner_entries e join public.profiles p on p.id=e.beneficiary_id
    where e.id=partner_entry_id and e.beneficiary_id=auth.uid() and p.partner_enabled=true
  )
);

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('partner-settlement-proofs','partner-settlement-proofs',false,10485760,array['image/jpeg','image/png','image/webp','application/pdf'])
on conflict(id) do update set public=false,file_size_limit=10485760,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "partner settlement proof superadmin read" on storage.objects;
create policy "partner settlement proof superadmin read" on storage.objects for select to authenticated using(bucket_id='partner-settlement-proofs' and public.is_superadmin());
drop policy if exists "partner settlement proof superadmin write" on storage.objects;
create policy "partner settlement proof superadmin write" on storage.objects for insert to authenticated with check(bucket_id='partner-settlement-proofs' and public.is_superadmin());
drop policy if exists "partner settlement proof superadmin update" on storage.objects;
create policy "partner settlement proof superadmin update" on storage.objects for update to authenticated using(bucket_id='partner-settlement-proofs' and public.is_superadmin()) with check(bucket_id='partner-settlement-proofs' and public.is_superadmin());
drop policy if exists "partner settlement proof superadmin delete" on storage.objects;
create policy "partner settlement proof superadmin delete" on storage.objects for delete to authenticated using(bucket_id='partner-settlement-proofs' and public.is_superadmin());

create or replace function public.save_platform_settings(p_mbway_phone text,p_central_iban text,p_platform_fee_percent numeric,p_minimum_withdrawal_eur numeric,p_withdrawal_fixed_fee_eur numeric,p_withdrawals_paused boolean)
returns public.platform_settings language plpgsql security definer set search_path=''
as $function$
declare old_row public.platform_settings;new_row public.platform_settings;changes jsonb:='{}'::jsonb;counter_total numeric;partner_total numeric;division_total numeric;
begin
  if not public.is_superadmin() then raise exception 'Somente o superadministrador pode alterar as configurações globais'; end if;
  if p_platform_fee_percent is null or p_platform_fee_percent<0 or p_platform_fee_percent>100 then raise exception 'A taxa da JaguaPay deve estar entre 0 e 100%%'; end if;
  if p_minimum_withdrawal_eur is null or p_minimum_withdrawal_eur<0 then raise exception 'O mínimo de saque não pode ser negativo'; end if;
  if p_withdrawal_fixed_fee_eur is null or p_withdrawal_fixed_fee_eur<0 then raise exception 'A taxa fixa de saque não pode ser negativa'; end if;
  select * into old_row from public.platform_settings where id=1 for update;
  select coalesce(sum(cc.percent),0) into counter_total from public.counter_commissions cc join public.profiles p on p.id=cc.counter_id where cc.percent>0 and p.role='admin' and p.admin_level='contador' and p.status='active';
  select coalesce(sum(pr.configured_percent),0) into partner_total from public.partner_rules pr join public.profiles p on p.id=pr.beneficiary_id where pr.active=true and p.partner_enabled=true and p.partner_participation_active=true and p.status='active';
  division_total:=round(counter_total+partner_total,4);
  if p_platform_fee_percent<division_total then raise exception 'A nova taxa é incompatível com a divisão atual. Percentual comprometido: %; nova taxa: %.',division_total,p_platform_fee_percent; end if;
  update public.platform_settings set mbway_phone=nullif(trim(p_mbway_phone),''),central_iban=nullif(trim(p_central_iban),''),platform_fee_percent=round(p_platform_fee_percent,2),minimum_withdrawal_eur=round(p_minimum_withdrawal_eur,2),withdrawal_fixed_fee_eur=round(p_withdrawal_fixed_fee_eur,2),withdrawals_paused=coalesce(p_withdrawals_paused,false),initialized_at=coalesce(initialized_at,now()),updated_at=now(),updated_by=auth.uid() where id=1 returning * into new_row;
  if old_row.mbway_phone is distinct from new_row.mbway_phone then changes:=changes||jsonb_build_object('mbway_phone',jsonb_build_object('old',old_row.mbway_phone,'new',new_row.mbway_phone)); end if;
  if old_row.central_iban is distinct from new_row.central_iban then changes:=changes||jsonb_build_object('central_iban',jsonb_build_object('old',old_row.central_iban,'new',new_row.central_iban)); end if;
  if old_row.platform_fee_percent is distinct from new_row.platform_fee_percent then changes:=changes||jsonb_build_object('platform_fee_percent',jsonb_build_object('old',old_row.platform_fee_percent,'new',new_row.platform_fee_percent)); end if;
  if old_row.minimum_withdrawal_eur is distinct from new_row.minimum_withdrawal_eur then changes:=changes||jsonb_build_object('minimum_withdrawal_eur',jsonb_build_object('old',old_row.minimum_withdrawal_eur,'new',new_row.minimum_withdrawal_eur)); end if;
  if old_row.withdrawal_fixed_fee_eur is distinct from new_row.withdrawal_fixed_fee_eur then changes:=changes||jsonb_build_object('withdrawal_fixed_fee_eur',jsonb_build_object('old',old_row.withdrawal_fixed_fee_eur,'new',new_row.withdrawal_fixed_fee_eur)); end if;
  if old_row.withdrawals_paused is distinct from new_row.withdrawals_paused then changes:=changes||jsonb_build_object('withdrawals_paused',jsonb_build_object('old',old_row.withdrawals_paused,'new',new_row.withdrawals_paused)); end if;
  insert into public.audit_logs(actor_id,action,metadata) values(auth.uid(),'platform_settings.updated',jsonb_build_object('changed_at',now(),'changes',changes));
  return new_row;
end $function$;

create or replace function public.set_counter_commission(p_counter_id uuid,p_percent numeric)
returns public.counter_commissions language plpgsql security definer set search_path=''
as $function$
declare r public.counter_commissions;fee numeric;others numeric;partner_total numeric;
begin
  if not public.is_superadmin() then raise exception 'Somente o superadministrador pode definir comissões'; end if;
  if p_percent is null or p_percent<0 or p_percent>100 then raise exception 'Percentual inválido'; end if;
  if not exists(select 1 from public.profiles where id=p_counter_id and role='admin' and admin_level='contador') then raise exception 'Conta não é Contador'; end if;
  select platform_fee_percent into fee from public.platform_settings where id=1 for update;
  select coalesce(sum(percent),0) into others from public.counter_commissions where counter_id<>p_counter_id;
  select coalesce(sum(pr.configured_percent),0) into partner_total from public.partner_rules pr join public.profiles p on p.id=pr.beneficiary_id where pr.active=true and p.partner_enabled=true and p.partner_participation_active=true and p.status='active';
  if others+p_percent+partner_total>coalesce(fee,0) then raise exception 'A divisão do Contador e dos Sócios excederia a taxa da JaguaPay. Usado: %; taxa: %; disponível para o Contador: %.',round(others+partner_total,4),fee,round(fee-others-partner_total,4); end if;
  insert into public.counter_commissions(counter_id,percent,updated_by,updated_at) values(p_counter_id,round(p_percent,2),auth.uid(),now()) on conflict(counter_id) do update set percent=excluded.percent,updated_by=excluded.updated_by,updated_at=now() returning * into r;
  insert into public.audit_logs(actor_id,action,target_user_id,metadata) values(auth.uid(),'counter.commission_set',p_counter_id,jsonb_build_object('percent',r.percent));
  return r;
end $function$;

create or replace function public.save_partner_rule(p_partner_id uuid,p_configured_percent numeric,p_active boolean,p_reason text,p_remove boolean default false)
returns public.partner_rules language plpgsql security definer set search_path=''
as $function$
declare s public.platform_settings;target public.profiles;old_rule public.partner_rules;result public.partner_rules;v integer;counter_total numeric;partner_total numeric;
begin
  if not public.is_superadmin() then raise exception 'Somente o superadministrador pode gerenciar Sócios'; end if;
  if nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'O motivo da alteração é obrigatório'; end if;
  if p_configured_percent is null or p_configured_percent<0 or p_configured_percent>100 then raise exception 'O percentual do Sócio deve estar entre 0 e 100%%'; end if;
  select * into s from public.platform_settings where id=1 for update;
  select * into target from public.profiles where id=p_partner_id for update;
  if target.id is null or target.role<>'seller' then raise exception 'O Sócio deve ser um vendedor existente'; end if;
  if target.status<>'active' and not p_remove then raise exception 'Somente vendedores ativos podem receber a condição de Sócio'; end if;
  select * into old_rule from public.partner_rules where beneficiary_id=p_partner_id and active=true limit 1 for update;
  if p_active and not p_remove then
    select coalesce(sum(cc.percent),0) into counter_total from public.counter_commissions cc join public.profiles p on p.id=cc.counter_id where cc.percent>0 and p.role='admin' and p.admin_level='contador' and p.status='active';
    select coalesce(sum(pr.configured_percent),0) into partner_total from public.partner_rules pr join public.profiles p on p.id=pr.beneficiary_id where pr.active=true and pr.beneficiary_id<>p_partner_id and p.partner_enabled=true and p.partner_participation_active=true and p.status='active';
    if counter_total+partner_total+p_configured_percent>coalesce(s.platform_fee_percent,0) then raise exception 'Participação incompatível. Disponível para este Sócio: %; taxa JaguaPay: %.',round(s.platform_fee_percent-counter_total-partner_total,4),s.platform_fee_percent; end if;
  end if;
  if old_rule.id is not null then update public.partner_rules set active=false,deactivated_at=now(),updated_at=now() where id=old_rule.id; end if;
  select coalesce(max(version),0)+1 into v from public.partner_rules where beneficiary_id=p_partner_id;
  insert into public.partner_rules(version,beneficiary_id,configured_percent,active,platform_fee_percent_at_activation,activated_at,deactivated_at,created_by)
  values(v,p_partner_id,round(p_configured_percent,4),case when p_remove then false else p_active end,s.platform_fee_percent,case when p_active and not p_remove then now() end,case when p_active and not p_remove then null else now() end,auth.uid()) returning * into result;
  update public.profiles set partner_enabled=case when p_remove then false else true end,partner_participation_active=case when p_remove then false else p_active end,partner_since=case when p_remove then partner_since else coalesce(partner_since,now()) end,updated_at=now() where id=p_partner_id;
  insert into public.audit_logs(actor_id,target_user_id,action,metadata)
  values(auth.uid(),p_partner_id,case when p_remove then 'partner.removed' when p_active and old_rule.id is null then 'partner.granted' when p_active then 'partner.activated_or_changed' else 'partner.paused' end,jsonb_build_object('reason',trim(p_reason),'rule_id',result.id,'version',result.version,'configured_percent',result.configured_percent,'active',result.active,'removed',p_remove));
  return result;
end $function$;
revoke all on function public.save_partner_rule(uuid,numeric,boolean,text,boolean) from public,anon;
grant execute on function public.save_partner_rule(uuid,numeric,boolean,text,boolean) to authenticated;

create or replace function public.get_partner_management()
returns table(partner_id uuid,full_name text,email text,status public.user_status,partner_enabled boolean,partner_participation_active boolean,current_percent numeric,total_accrued_eur numeric,total_adjustments_eur numeric,total_paid_eur numeric,pending_eur numeric)
language plpgsql security definer set search_path=''
as $function$
begin
  if not public.is_superadmin() then raise exception 'Acesso negado'; end if;
  return query
  select p.id,p.full_name,p.email,p.status,p.partner_enabled,p.partner_participation_active,
    coalesce((select pr.configured_percent from public.partner_rules pr where pr.beneficiary_id=p.id order by pr.created_at desc limit 1),0),
    coalesce((select round(sum(e.amount_eur),2) from public.partner_entries e where e.beneficiary_id=p.id),0),
    coalesce((select round(sum(a.amount_eur),2) from public.partner_adjustments a where a.beneficiary_id=p.id),0),
    coalesce((select round(sum(s.amount_eur),2) from public.partner_settlements s where s.beneficiary_id=p.id),0),
    round(coalesce((select sum(e.amount_eur) from public.partner_entries e where e.beneficiary_id=p.id),0)+coalesce((select sum(a.amount_eur) from public.partner_adjustments a where a.beneficiary_id=p.id),0)-coalesce((select sum(s.amount_eur) from public.partner_settlements s where s.beneficiary_id=p.id),0),2)
  from public.profiles p
  where p.role='seller' and (p.partner_enabled=true or exists(select 1 from public.partner_rules pr where pr.beneficiary_id=p.id) or exists(select 1 from public.partner_entries pe where pe.beneficiary_id=p.id))
  order by p.full_name nulls last,p.email;
end $function$;
revoke all on function public.get_partner_management() from public,anon;
grant execute on function public.get_partner_management() to authenticated;

create or replace function public.get_my_partner_overview()
returns table(configured_percent numeric,active boolean,approved_gross_eur numeric,total_accrued_eur numeric,total_adjustments_eur numeric,total_paid_eur numeric,pending_eur numeric)
language plpgsql stable security definer set search_path=''
as $function$
declare latest public.partner_rules;
begin
  if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='seller' and p.status='active' and p.partner_enabled=true) then raise exception 'Acesso negado'; end if;
  select * into latest from public.partner_rules where beneficiary_id=auth.uid() order by created_at desc limit 1;
  return query
  select coalesce(latest.configured_percent,0),coalesce(latest.active,false),
    round(coalesce((select sum(pr.gross_amount_eur) from public.payment_records pr where pr.status='approved'),0),2),
    round(coalesce((select sum(e.amount_eur) from public.partner_entries e where e.beneficiary_id=auth.uid()),0),2),
    round(coalesce((select sum(a.amount_eur) from public.partner_adjustments a where a.beneficiary_id=auth.uid()),0),2),
    round(coalesce((select sum(s.amount_eur) from public.partner_settlements s where s.beneficiary_id=auth.uid()),0),2),
    round(coalesce((select sum(e.amount_eur) from public.partner_entries e where e.beneficiary_id=auth.uid()),0)+coalesce((select sum(a.amount_eur) from public.partner_adjustments a where a.beneficiary_id=auth.uid()),0)-coalesce((select sum(s.amount_eur) from public.partner_settlements s where s.beneficiary_id=auth.uid()),0),2);
end $function$;
revoke all on function public.get_my_partner_overview() from public,anon;
grant execute on function public.get_my_partner_overview() to authenticated;

create or replace function public.adjust_partner_entry(p_entry_id uuid,p_amount_eur numeric,p_reason text)
returns public.partner_adjustments language plpgsql security definer set search_path=''
as $function$
declare e public.partner_entries;available numeric;result public.partner_adjustments;
begin
  if not public.is_superadmin() then raise exception 'Somente o superadministrador pode ajustar participações'; end if;
  if p_amount_eur is null or round(p_amount_eur,2)=0 then raise exception 'O ajuste deve ser diferente de zero'; end if;
  if nullif(trim(coalesce(p_reason,'')),'') is null then raise exception 'O motivo do ajuste é obrigatório'; end if;
  select * into e from public.partner_entries where id=p_entry_id for update;
  if e.id is null then raise exception 'Participação não encontrada'; end if;
  available:=round(e.amount_eur+coalesce((select sum(a.amount_eur) from public.partner_adjustments a where a.partner_entry_id=e.id),0)-coalesce((select sum(sa.amount_eur) from public.partner_settlement_allocations sa where sa.partner_entry_id=e.id),0),2);
  if p_amount_eur<0 and abs(round(p_amount_eur,2))>greatest(0,available) then raise exception 'O ajuste negativo excede o valor ainda disponível desta participação: %.',greatest(0,available); end if;
  insert into public.partner_adjustments(partner_entry_id,payment_id,beneficiary_id,amount_eur,reason,created_by) values(e.id,e.payment_id,e.beneficiary_id,round(p_amount_eur,2),trim(p_reason),auth.uid()) returning * into result;
  insert into public.audit_logs(actor_id,target_user_id,action,metadata) values(auth.uid(),e.beneficiary_id,'partner.adjustment_created',jsonb_build_object('entry_id',e.id,'payment_id',e.payment_id,'amount_eur',result.amount_eur,'reason',result.reason));
  return result;
end $function$;
revoke all on function public.adjust_partner_entry(uuid,numeric,text) from public,anon;
grant execute on function public.adjust_partner_entry(uuid,numeric,text) to authenticated;

create or replace function public.create_partner_settlement(p_beneficiary_id uuid,p_amount_eur numeric,p_settlement_date timestamptz,p_settlement_method text,p_reference text,p_proof_path text,p_observation text)
returns public.partner_settlements language plpgsql security definer set search_path=''
as $function$
declare result public.partner_settlements;remaining numeric:=round(p_amount_eur,2);pending numeric;e record;available numeric;allocation numeric;
begin
  if not public.is_superadmin() then raise exception 'Somente o superadministrador pode registrar acertos de Sócios'; end if;
  if p_amount_eur is null or p_amount_eur<=0 then raise exception 'O valor do acerto deve ser maior que zero'; end if;
  if p_settlement_method not in('transfer','central_retention') then raise exception 'Forma de acerto inválida'; end if;
  if p_settlement_method='transfer' and nullif(trim(coalesce(p_reference,'')) is null and nullif(trim(coalesce(p_proof_path,'')),'') is null then raise exception 'Transferência exige referência ou comprovante'; end if;
  if nullif(trim(coalesce(p_proof_path,'')),'') is not null and not exists(select 1 from storage.objects where bucket_id='partner-settlement-proofs' and name=trim(p_proof_path)) then raise exception 'O comprovante informado não foi encontrado no armazenamento privado'; end if;
  pending:=round(coalesce((select sum(e.amount_eur) from public.partner_entries e where e.beneficiary_id=p_beneficiary_id),0)+coalesce((select sum(a.amount_eur) from public.partner_adjustments a where a.beneficiary_id=p_beneficiary_id),0)-coalesce((select sum(s.amount_eur) from public.partner_settlements s where s.beneficiary_id=p_beneficiary_id),0),2);
  if pending<=0 then raise exception 'Não há saldo positivo pendente para este Sócio'; end if;
  if p_amount_eur>pending then raise exception 'O acerto excede o saldo positivo pendente de %.',pending; end if;
  insert into public.partner_settlements(beneficiary_id,amount_eur,settlement_date,settlement_method,reference,proof_path,observation,created_by)
  values(p_beneficiary_id,round(p_amount_eur,2),coalesce(p_settlement_date,now()),p_settlement_method,nullif(trim(p_reference),''),nullif(trim(p_proof_path),''),nullif(trim(p_observation),''),auth.uid())
  returning * into result;
  for e in
    select pe.id,greatest(0,round(pe.amount_eur+coalesce((select sum(a.amount_eur) from public.partner_adjustments a where a.partner_entry_id=pe.id),0)-coalesce((select sum(sa.amount_eur) from public.partner_settlement_allocations sa where sa.partner_entry_id=pe.id),0),2)) as available
    from public.partner_entries pe where pe.beneficiary_id=p_beneficiary_id order by pe.created_at,pe.id for update
  loop
    exit when remaining<=0;
    available:=e.available;
    if available>0 then allocation:=least(remaining,available);insert into public.partner_settlement_allocations(settlement_id,partner_entry_id,amount_eur) values(result.id,e.id,allocation);remaining:=round(remaining-allocation,2);end if;
  end loop;
  if remaining<>0 then raise exception 'Não foi possível alocar integralmente o acerto'; end if;
  insert into public.audit_logs(actor_id,target_user_id,action,metadata) values(auth.uid(),p_beneficiary_id,'partner.settlement_created',jsonb_build_object('settlement_id',result.id,'amount_eur',result.amount_eur,'method',result.settlement_method,'reference',result.reference));
  return result;
end $function$;
revoke all on function public.create_partner_settlement(uuid,numeric,timestamptz,text,text,text,text) from public,anon;
grant execute on function public.create_partner_settlement(uuid,numeric,timestamptz,text,text,text,text) to authenticated;

create or replace function public.create_payment_submission(p_gross_amount_eur numeric,p_payment_method text,p_reference text,p_order_id text,p_notes text,p_idempotency_key text)
returns public.payment_records language plpgsql security definer set search_path=''
as $function$
declare s public.platform_settings;result public.payment_records;fee numeric;r public.compensation_rules;effective numeric:=0;
begin
  if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='seller' and p.status='active') then raise exception 'Conta de vendedor indisponível'; end if;
  if p_gross_amount_eur is null or p_gross_amount_eur<=0 then raise exception 'O valor recebido deve ser maior que zero'; end if;
  if p_payment_method not in('mbway','iban') then raise exception 'Método de pagamento inválido'; end if;
  if nullif(trim(p_idempotency_key),'') is null then raise exception 'Identificador de envio ausente'; end if;
  select * into s from public.platform_settings where id=1;
  if s.initialized_at is null then raise exception 'As configurações de recebimento ainda não foram salvas'; end if;
  select * into result from public.payment_records where seller_id=auth.uid() and idempotency_key=p_idempotency_key limit 1;
  if result.id is not null then return result; end if;
  fee:=round(p_gross_amount_eur*s.platform_fee_percent/100,2);
  select * into r from public.compensation_rules where active=true limit 1;
  if r.id is not null and exists(select 1 from public.profiles p where p.id=r.beneficiary_id and p.role='admin' and p.admin_level='contador' and p.status='active') then effective:=least(r.configured_percent,s.platform_fee_percent); end if;
  insert into public.payment_records(seller_id,gross_amount_eur,fee_percent_snapshot,fee_amount_eur,net_amount_eur,status,reference,currency,payment_method,order_id,notes,mbway_phone_snapshot,central_iban_snapshot,idempotency_key,compensation_rule_id,compensation_beneficiary_id,compensation_percent_configured,compensation_percent_applied)
  values(auth.uid(),round(p_gross_amount_eur,2),s.platform_fee_percent,fee,round(p_gross_amount_eur-fee,2),'pending',nullif(trim(p_reference),''),'EUR',p_payment_method,nullif(trim(p_order_id),''),nullif(trim(p_notes),''),s.mbway_phone,s.central_iban,p_idempotency_key,case when r.id is not null then r.id end,case when r.id is not null then r.beneficiary_id end,case when r.id is not null then r.configured_percent end,case when r.id is not null then effective end)
  returning * into result;
  insert into public.partner_payment_snapshots(payment_id,beneficiary_id,rule_id,gross_amount_eur,configured_percent,applied_percent)
  select result.id,pr.beneficiary_id,pr.id,result.gross_amount_eur,pr.configured_percent,pr.configured_percent
  from public.partner_rules pr join public.profiles pp on pp.id=pr.beneficiary_id
  where pr.active=true and pp.partner_enabled=true and pp.partner_participation_active=true and pp.status='active'
  on conflict(payment_id,beneficiary_id) do nothing;
  return result;
exception when unique_violation then
  select * into result from public.payment_records where seller_id=auth.uid() and idempotency_key=p_idempotency_key limit 1;
  if result.id is not null then return result; end if;
  raise;
end $function$;

create or replace function public.admin_approve_payment(p_payment_id uuid,p_receipt_id uuid default null,p_new_receipt_reference text default null,p_new_receipt_at timestamptz default null,p_new_receipt_amount_eur numeric default null,p_new_receipt_method text default null,p_new_receipt_observation text default null)
returns public.payment_records language plpgsql security definer set search_path=''
as $function$
declare p public.payment_records;rc public.central_receipts;result public.payment_records;c record;ps record;remaining_percent numeric;applied numeric;partner_fee_remaining numeric;partner_amount numeric;
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
    insert into public.central_receipts(receipt_reference,received_at,amount_eur,payment_method,observation,seller_id,payment_id,created_by) values(trim(p_new_receipt_reference),coalesce(p_new_receipt_at,now()),p_new_receipt_amount_eur,p_new_receipt_method,p_new_receipt_observation,p.seller_id,p.id,auth.uid()) returning * into rc;
  end if;
  if rc.payment_id is not null and rc.payment_id<>p.id then raise exception 'Este recebimento já está vinculado a outra venda'; end if;
  if rc.amount_eur<>p.gross_amount_eur or rc.payment_method<>p.payment_method then raise exception 'Recebimento incompatível com a venda'; end if;
  if rc.payment_id is null then update public.central_receipts set payment_id=p.id,seller_id=p.seller_id where id=rc.id; end if;
  update public.payment_records set status='approved',approved_at=now(),receipt_id=rc.id,decided_by=auth.uid(),updated_at=now() where id=p.id returning * into result;
  insert into public.payment_financial_ledger(seller_id,payment_id,entry_type,amount_eur,reason,created_by) values(p.seller_id,p.id,'sale_credit',p.net_amount_eur,'Venda aprovada após conferência do recebimento real',auth.uid());
  remaining_percent:=coalesce(p.fee_percent_snapshot,0);
  for c in select cc.counter_id,cc.percent from public.counter_commissions cc join public.profiles pr on pr.id=cc.counter_id where cc.percent>0 and pr.role='admin' and pr.admin_level='contador' and pr.status='active' order by cc.percent desc loop
    applied:=least(c.percent,remaining_percent);
    exit when applied<=0;
    insert into public.compensation_entries(payment_id,beneficiary_id,rule_id,gross_amount_eur,configured_percent,applied_percent,amount_eur)
    values(p.id,c.counter_id,null,p.gross_amount_eur,c.percent,applied,round(p.gross_amount_eur*applied/100,2))
    on conflict(payment_id,beneficiary_id) do nothing;
    remaining_percent:=remaining_percent-applied;
  end loop;
  partner_fee_remaining:=greatest(0,round(p.fee_amount_eur-coalesce((select sum(e.amount_eur) from public.compensation_entries e where e.payment_id=p.id),0),2));
  for ps in select s.beneficiary_id,s.rule_id,s.configured_percent,s.applied_percent,s.gross_amount_eur from public.partner_payment_snapshots s where s.payment_id=p.id and s.applied_percent>0 order by s.beneficiary_id loop
    exit when partner_fee_remaining<=0;
    partner_amount:=least(round(ps.gross_amount_eur*ps.applied_percent/100,2),partner_fee_remaining);
    if partner_amount>0 then
      insert into public.partner_entries(payment_id,beneficiary_id,rule_id,gross_amount_eur,configured_percent,applied_percent,amount_eur)
      values(p.id,ps.beneficiary_id,ps.rule_id,ps.gross_amount_eur,ps.configured_percent,ps.applied_percent,partner_amount)
      on conflict(payment_id,beneficiary_id) do nothing;
      partner_fee_remaining:=round(partner_fee_remaining-partner_amount,2);
    end if;
  end loop;
  insert into public.audit_logs(actor_id,action,metadata) values(auth.uid(),'payment.approved',jsonb_build_object('payment_id',p.id,'receipt_id',rc.id,'gross_amount_eur',p.gross_amount_eur,'fee_percent',p.fee_percent_snapshot,'net_amount_eur',p.net_amount_eur,'partner_participations_eur',coalesce((select sum(pe.amount_eur) from public.partner_entries pe where pe.payment_id=p.id),0)));
  return result;
exception when unique_violation then raise exception 'Esta venda ou recebimento já foi processado por outro administrador'; end $function$;

create or replace function public.admin_reverse_payment(p_payment_id uuid,p_reason text)
returns public.payment_records language plpgsql security definer set search_path=''
as $function$
declare p public.payment_records;result public.payment_records;e record;total numeric:=0;partner_total numeric:=0;
begin
  if not public.is_admin_or_counter() then raise exception 'Acesso negado'; end if;
  if nullif(trim(p_reason),'') is null then raise exception 'O motivo do estorno é obrigatório'; end if;
  select * into p from public.payment_records where id=p_payment_id for update;
  if p.id is null or p.status<>'approved' then raise exception 'Somente vendas aprovadas podem ser estornadas'; end if;
  if exists(select 1 from public.payment_financial_ledger where payment_id=p_payment_id and entry_type='reversal_debit') then raise exception 'Esta venda já foi estornada'; end if;
  update public.payment_records set status='estornado',decision_reason=trim(p_reason),decided_by=auth.uid(),updated_at=now() where id=p_payment_id returning * into result;
  insert into public.payment_financial_ledger(seller_id,payment_id,entry_type,amount_eur,reason,created_by) values(p.seller_id,p.id,'reversal_debit',-p.net_amount_eur,trim(p_reason),auth.uid());
  for e in select * from public.compensation_entries where payment_id=p.id for update loop
    insert into public.compensation_adjustments(compensation_entry_id,payment_id,beneficiary_id,amount_eur,reason,created_by) values(e.id,p.id,e.beneficiary_id,-e.amount_eur,'Estorno da venda: comissão revertida',auth.uid()) on conflict(compensation_entry_id) do nothing;
    total:=total+e.amount_eur;
  end loop;
  for e in select * from public.partner_entries where payment_id=p.id for update loop
    insert into public.partner_adjustments(partner_entry_id,payment_id,beneficiary_id,amount_eur,reason,created_by) values(e.id,p.id,e.beneficiary_id,-e.amount_eur,'Estorno da venda: participação proporcional revertida',auth.uid()) on conflict(partner_entry_id) do nothing;
    partner_total:=partner_total+e.amount_eur;
  end loop;
  insert into public.audit_logs(actor_id,action,metadata) values(auth.uid(),'payment.reversed',jsonb_build_object('payment_id',p.id,'reason',trim(p_reason),'compensation_reversed_eur',total,'partner_reversed_eur',partner_total));
  return result;
end $function$;

revoke all on function public.get_my_partner_overview() from public,anon;
grant execute on function public.get_my_partner_overview() to authenticated;
