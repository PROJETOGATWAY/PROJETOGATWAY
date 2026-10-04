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
