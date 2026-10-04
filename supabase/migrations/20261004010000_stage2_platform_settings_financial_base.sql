-- Etapa 2: configurações globais e base financeira real para os painéis
create table if not exists public.platform_settings (
  id smallint primary key default 1 check (id = 1),
  mbway_phone text,
  central_iban text,
  platform_fee_percent numeric(5,2) not null default 20.00 check (platform_fee_percent >= 0 and platform_fee_percent <= 100),
  minimum_withdrawal_eur numeric(12,2) not null default 50.00 check (minimum_withdrawal_eur >= 0),
  withdrawal_fixed_fee_eur numeric(12,2) not null default 0.00 check (withdrawal_fixed_fee_eur >= 0),
  withdrawals_paused boolean not null default false,
  initialized_at timestamptz,
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id)
);

insert into public.platform_settings(id)
values(1)
on conflict (id) do nothing;

create table if not exists public.payment_records (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete restrict,
  gross_amount_eur numeric(12,2) not null check (gross_amount_eur > 0),
  fee_percent_snapshot numeric(5,2) not null check (fee_percent_snapshot >= 0 and fee_percent_snapshot <= 100),
  fee_amount_eur numeric(12,2) not null check (fee_amount_eur >= 0),
  net_amount_eur numeric(12,2) not null check (net_amount_eur >= 0),
  status text not null default 'pending' check (status in ('pending','under_review','approved','rejected')),
  reference text,
  submitted_at timestamptz not null default now(),
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.withdrawals (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.profiles(id) on delete restrict,
  amount_eur numeric(12,2) not null check (amount_eur > 0),
  fixed_fee_snapshot_eur numeric(12,2) not null check (fixed_fee_snapshot_eur >= 0),
  status text not null default 'requested' check (status in ('requested','approved','paid','rejected','cancelled')),
  created_at timestamptz not null default now(),
  confirmed_at timestamptz,
  updated_at timestamptz not null default now()
);

create index if not exists payment_records_seller_status_idx on public.payment_records(seller_id,status);
create index if not exists payment_records_seller_created_idx on public.payment_records(seller_id,created_at desc);
create index if not exists withdrawals_seller_status_idx on public.withdrawals(seller_id,status);
create index if not exists withdrawals_seller_created_idx on public.withdrawals(seller_id,created_at desc);

drop trigger if exists payment_records_updated_at on public.payment_records;
create trigger payment_records_updated_at before update on public.payment_records
for each row execute function public.set_updated_at();

drop trigger if exists withdrawals_updated_at on public.withdrawals;
create trigger withdrawals_updated_at before update on public.withdrawals
for each row execute function public.set_updated_at();

alter table public.platform_settings enable row level security;
alter table public.payment_records enable row level security;
alter table public.withdrawals enable row level security;

drop policy if exists platform_settings_select_active on public.platform_settings;
create policy platform_settings_select_active on public.platform_settings
for select to authenticated
using (exists(select 1 from public.profiles p where p.id=auth.uid() and p.status='active'));

drop policy if exists platform_settings_update_none on public.platform_settings;
create policy platform_settings_update_none on public.platform_settings
for update to authenticated using (false) with check (false);

drop policy if exists platform_settings_insert_none on public.platform_settings;
create policy platform_settings_insert_none on public.platform_settings for insert to authenticated with check (false);

drop policy if exists platform_settings_delete_none on public.platform_settings;
create policy platform_settings_delete_none on public.platform_settings for delete to authenticated using (false);

drop policy if exists payment_records_select_own_or_admin on public.payment_records;
create policy payment_records_select_own_or_admin on public.payment_records
for select to authenticated
using (seller_id=auth.uid() or public.is_admin());

drop policy if exists withdrawals_select_own_or_admin on public.withdrawals;
create policy withdrawals_select_own_or_admin on public.withdrawals
for select to authenticated
using (seller_id=auth.uid() or public.is_admin());

drop policy if exists payment_records_insert_none on public.payment_records;
create policy payment_records_insert_none on public.payment_records for insert to authenticated with check (false);
drop policy if exists payment_records_update_none on public.payment_records;
create policy payment_records_update_none on public.payment_records for update to authenticated using (false) with check (false);
drop policy if exists payment_records_delete_none on public.payment_records;
create policy payment_records_delete_none on public.payment_records for delete to authenticated using (false);

drop policy if exists withdrawals_insert_none on public.withdrawals;
create policy withdrawals_insert_none on public.withdrawals for insert to authenticated with check (false);
drop policy if exists withdrawals_update_none on public.withdrawals;
create policy withdrawals_update_none on public.withdrawals for update to authenticated using (false) with check (false);
drop policy if exists withdrawals_delete_none on public.withdrawals;
create policy withdrawals_delete_none on public.withdrawals for delete to authenticated using (false);

grant select on public.platform_settings to authenticated;
grant select on public.payment_records to authenticated;
grant select on public.withdrawals to authenticated;

create or replace function public.save_platform_settings(
  p_mbway_phone text,
  p_central_iban text,
  p_platform_fee_percent numeric,
  p_minimum_withdrawal_eur numeric,
  p_withdrawal_fixed_fee_eur numeric,
  p_withdrawals_paused boolean
)
returns public.platform_settings
language plpgsql
security definer
set search_path = ''
as $$
declare
  old_row public.platform_settings;
  new_row public.platform_settings;
  changes jsonb := '{}'::jsonb;
begin
  if not (select public.is_admin()) then
    raise exception 'Acesso negado';
  end if;

  if p_platform_fee_percent is null or p_platform_fee_percent < 0 or p_platform_fee_percent > 100 then
    raise exception 'A taxa da JaguaPay deve estar entre 0 e 100%%';
  end if;
  if p_minimum_withdrawal_eur is null or p_minimum_withdrawal_eur < 0 then
    raise exception 'O mínimo de saque não pode ser negativo';
  end if;
  if p_withdrawal_fixed_fee_eur is null or p_withdrawal_fixed_fee_eur < 0 then
    raise exception 'A taxa fixa de saque não pode ser negativa';
  end if;

  select * into old_row from public.platform_settings where id=1 for update;

  update public.platform_settings
  set mbway_phone=nullif(trim(p_mbway_phone),''),
      central_iban=nullif(trim(p_central_iban),''),
      platform_fee_percent=round(p_platform_fee_percent,2),
      minimum_withdrawal_eur=round(p_minimum_withdrawal_eur,2),
      withdrawal_fixed_fee_eur=round(p_withdrawal_fixed_fee_eur,2),
      withdrawals_paused=coalesce(p_withdrawals_paused,false),
      initialized_at=coalesce(initialized_at,now()),
      updated_at=now(),
      updated_by=auth.uid()
  where id=1
  returning * into new_row;

  if old_row.mbway_phone is distinct from new_row.mbway_phone then
    changes := changes || jsonb_build_object('mbway_phone',jsonb_build_object('old',old_row.mbway_phone,'new',new_row.mbway_phone));
  end if;
  if old_row.central_iban is distinct from new_row.central_iban then
    changes := changes || jsonb_build_object('central_iban',jsonb_build_object('old',old_row.central_iban,'new',new_row.central_iban));
  end if;
  if old_row.platform_fee_percent is distinct from new_row.platform_fee_percent then
    changes := changes || jsonb_build_object('platform_fee_percent',jsonb_build_object('old',old_row.platform_fee_percent,'new',new_row.platform_fee_percent));
  end if;
  if old_row.minimum_withdrawal_eur is distinct from new_row.minimum_withdrawal_eur then
    changes := changes || jsonb_build_object('minimum_withdrawal_eur',jsonb_build_object('old',old_row.minimum_withdrawal_eur,'new',new_row.minimum_withdrawal_eur));
  end if;
  if old_row.withdrawal_fixed_fee_eur is distinct from new_row.withdrawal_fixed_fee_eur then
    changes := changes || jsonb_build_object('withdrawal_fixed_fee_eur',jsonb_build_object('old',old_row.withdrawal_fixed_fee_eur,'new',new_row.withdrawal_fixed_fee_eur));
  end if;
  if old_row.withdrawals_paused is distinct from new_row.withdrawals_paused then
    changes := changes || jsonb_build_object('withdrawals_paused',jsonb_build_object('old',old_row.withdrawals_paused,'new',new_row.withdrawals_paused));
  end if;

  insert into public.audit_logs(actor_id,action,metadata)
  values(auth.uid(),'platform_settings.updated',jsonb_build_object('changed_at',now(),'changes',changes));

  return new_row;
end;
$$;

revoke all on function public.save_platform_settings(text,text,numeric,numeric,numeric,boolean) from public;
grant execute on function public.save_platform_settings(text,text,numeric,numeric,numeric,boolean) to authenticated;

create or replace function public.get_seller_dashboard()
returns table (
  available_balance_eur numeric,
  pending_balance_eur numeric,
  approved_volume_eur numeric,
  at_risk_eur numeric,
  reserved_withdrawals_eur numeric
)
language sql
security invoker
set search_path = ''
as $$
  select
    greatest(coalesce((select sum(p.net_amount_eur) from public.payment_records p where p.seller_id=(select auth.uid()) and p.status='approved'),0)
      - coalesce((select sum(w.amount_eur + w.fixed_fee_snapshot_eur) from public.withdrawals w where w.seller_id=(select auth.uid()) and w.status in ('approved','paid')),0),0),
    coalesce((select sum(p.net_amount_eur) from public.payment_records p where p.seller_id=(select auth.uid()) and p.status in ('pending','under_review')),0),
    coalesce((select sum(p.gross_amount_eur) from public.payment_records p where p.seller_id=(select auth.uid()) and p.status='approved'),0),
    coalesce((select sum(p.net_amount_eur) from public.payment_records p where p.seller_id=(select auth.uid()) and p.status='under_review'),0),
    coalesce((select sum(w.amount_eur + w.fixed_fee_snapshot_eur) from public.withdrawals w where w.seller_id=(select auth.uid()) and w.status in ('requested','approved')),0);
$$;

revoke all on function public.get_seller_dashboard() from public;
grant execute on function public.get_seller_dashboard() to authenticated;

do $$
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='platform_settings') then
      execute 'alter publication supabase_realtime add table public.platform_settings';
    end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='payment_records') then
      execute 'alter publication supabase_realtime add table public.payment_records';
    end if;
    if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename='withdrawals') then
      execute 'alter publication supabase_realtime add table public.withdrawals';
    end if;
  end if;
end $$;

create or replace function public.submit_payment(
  p_gross_amount_eur numeric,
  p_reference text default null
)
returns public.payment_records
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_settings public.platform_settings;
  result public.payment_records;
  fee_amount numeric;
begin
  if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='seller' and p.status='active') then
    raise exception 'Conta de vendedor indisponível';
  end if;
  if p_gross_amount_eur is null or p_gross_amount_eur <= 0 then
    raise exception 'O valor do pagamento deve ser maior que zero';
  end if;
  select * into current_settings from public.platform_settings where id=1;
  if current_settings.initialized_at is null then
    raise exception 'As configurações da operação ainda não foram inicializadas';
  end if;
  fee_amount := round(p_gross_amount_eur * current_settings.platform_fee_percent / 100,2);
  insert into public.payment_records(seller_id,gross_amount_eur,fee_percent_snapshot,fee_amount_eur,net_amount_eur,status,reference)
  values(auth.uid(),round(p_gross_amount_eur,2),current_settings.platform_fee_percent,fee_amount,round(p_gross_amount_eur-fee_amount,2),'pending',nullif(trim(p_reference),''))
  returning * into result;
  return result;
end;
$$;
revoke all on function public.submit_payment(numeric,text) from public;
grant execute on function public.submit_payment(numeric,text) to authenticated;

create or replace function public.request_withdrawal(p_amount_eur numeric)
returns public.withdrawals
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_settings public.platform_settings;
  balance numeric;
  result public.withdrawals;
begin
  if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='seller' and p.status='active') then
    raise exception 'Conta de vendedor indisponível';
  end if;
  select * into current_settings from public.platform_settings where id=1;
  if current_settings.initialized_at is null then
    raise exception 'Os saques ainda não estão disponíveis';
  end if;
  if current_settings.withdrawals_paused then
    raise exception 'Novos saques estão pausados';
  end if;
  if p_amount_eur is null or p_amount_eur <= 0 then
    raise exception 'O valor do saque deve ser maior que zero';
  end if;
  if p_amount_eur < current_settings.minimum_withdrawal_eur then
    raise exception 'O valor está abaixo do mínimo de saque';
  end if;
  select greatest(coalesce((select sum(p.net_amount_eur) from public.payment_records p where p.seller_id=auth.uid() and p.status='approved'),0)
    - coalesce((select sum(w.amount_eur+w.fixed_fee_snapshot_eur) from public.withdrawals w where w.seller_id=auth.uid() and w.status in ('requested','approved','paid')),0),0)
    into balance;
  if p_amount_eur + current_settings.withdrawal_fixed_fee_eur > balance then
    raise exception 'Saldo disponível insuficiente';
  end if;
  insert into public.withdrawals(seller_id,amount_eur,fixed_fee_snapshot_eur,status)
  values(auth.uid(),round(p_amount_eur,2),current_settings.withdrawal_fixed_fee_eur,'requested')
  returning * into result;
  return result;
end;
$$;
revoke all on function public.request_withdrawal(numeric) from public;
grant execute on function public.request_withdrawal(numeric) to authenticated;
