
-- Stage 7 follow-up: move Sócio participation from manual settlement to the seller wallet.
-- Seller withdrawals continue to use the existing payment_financial_ledger, so partner
-- credits become part of the same withdrawable balance without creating a second wallet.

create unique index if not exists payment_financial_ledger_partner_credit_once
  on public.payment_financial_ledger(seller_id,payment_id,entry_type)
  where entry_type='partner_credit' and payment_id is not null;

create unique index if not exists payment_financial_ledger_partner_reversal_once
  on public.payment_financial_ledger(seller_id,payment_id,entry_type)
  where entry_type='partner_reversal' and payment_id is not null;

-- One-time transition of legacy participation already apurada but not settled.
-- A settlement is considered settled only through its existing allocation records.
do $migration$
declare
  e record;
  net_due numeric;
  settlement_mismatch boolean;
  migration_actor uuid;

begin
  select p.id into migration_actor
  from public.profiles p
  where p.role='admin' and p.admin_level='superadmin' and p.status='active'
  order by p.created_at,p.id
  limit 1;
  if migration_actor is null then
    raise exception 'Não foi possível identificar o superadministrador para auditar a migração da carteira de Sócio';
  end if;
begin
  for e in
    select pe.id,pe.payment_id,pe.beneficiary_id,pe.amount_eur
    from public.partner_entries pe
    order by pe.created_at,pe.id
  loop
    select exists(
      select 1
      from public.partner_settlements ps
      where ps.beneficiary_id=e.beneficiary_id
        and round(ps.amount_eur,2)<>round(coalesce((
          select sum(a.amount_eur)
          from public.partner_settlement_allocations a
          where a.settlement_id=ps.id
        ),0),2)
    ) into settlement_mismatch;

    if settlement_mismatch then
      insert into public.audit_logs(actor_id,target_user_id,action,metadata)
      values(
        null,e.beneficiary_id,'partner.wallet_migration_inconsistency',
        jsonb_build_object(
          'partner_entry_id',e.id,
          'payment_id',e.payment_id,
          'reason','Acerto histórico sem alocação integral identificável; nenhum crédito automático foi criado.'
        )
      );
      continue;
    end if;

    select round(
      e.amount_eur
      +coalesce((select sum(a.amount_eur) from public.partner_adjustments a where a.partner_entry_id=e.id),0)
      -coalesce((select sum(a.amount_eur) from public.partner_settlement_allocations a where a.partner_entry_id=e.id),0)
    ,2) into net_due;

    if net_due>0 then
      insert into public.payment_financial_ledger(
        seller_id,payment_id,entry_type,amount_eur,reason,created_by
      )
      values(
        e.beneficiary_id,e.payment_id,'partner_credit',net_due,'Participação de sócio',migration_actor
      )
      on conflict(seller_id,payment_id,entry_type) where entry_type='partner_credit' and payment_id is not null do nothing;

      if found then
        insert into public.audit_logs(actor_id,target_user_id,action,metadata)
        values(
          null,e.beneficiary_id,'partner.wallet_migrated',
          jsonb_build_object(
            'partner_entry_id',e.id,
            'payment_id',e.payment_id,
            'amount_eur',net_due,
            'reason','Transição única da participação apurada e ainda não liquidada.'
          )
        );
      end if;
    elsif net_due<0 then
      insert into public.audit_logs(actor_id,target_user_id,action,metadata)
      values(
        null,e.beneficiary_id,'partner.wallet_migration_inconsistency',
        jsonb_build_object(
          'partner_entry_id',e.id,
          'payment_id',e.payment_id,
          'net_due_eur',net_due,
          'reason','Participação histórica com saldo líquido negativo; nenhum crédito automático foi criado.'
        )
      );
    end if;
  end loop;
end
$migration$;

create or replace function public.credit_partner_wallet_after_entry()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
begin
  if new.amount_eur>0 then
    insert into public.payment_financial_ledger(
      seller_id,payment_id,entry_type,amount_eur,reason,created_by
    )
    values(
      new.beneficiary_id,new.payment_id,'partner_credit',round(new.amount_eur,2),'Participação de sócio',auth.uid()
    )
    on conflict(seller_id,payment_id,entry_type) where entry_type='partner_credit' and payment_id is not null do nothing;
  end if;
  return new;
end
$function$;

drop trigger if exists partner_wallet_credit_after_entry on public.partner_entries;
create trigger partner_wallet_credit_after_entry
after insert on public.partner_entries
for each row
execute function public.credit_partner_wallet_after_entry();

create or replace function public.record_partner_wallet_adjustment()
returns trigger
language plpgsql
security definer
set search_path=''
as $function$
begin
  if new.amount_eur<>0 then
    insert into public.payment_financial_ledger(
      seller_id,payment_id,entry_type,amount_eur,reason,created_by
    )
    values(
      new.beneficiary_id,new.payment_id,'partner_reversal',round(new.amount_eur,2),
      case when new.amount_eur<0 then 'Estorno/ajuste de participação de sócio' else 'Crédito de ajuste de participação de sócio' end,
      auth.uid()
    )
    on conflict(seller_id,payment_id,entry_type) where entry_type='partner_reversal' and payment_id is not null do nothing;
  end if;
  return new;
end
$function$;

drop trigger if exists partner_wallet_adjustment_after_insert on public.partner_adjustments;
create trigger partner_wallet_adjustment_after_insert
after insert on public.partner_adjustments
for each row
execute function public.record_partner_wallet_adjustment();

create or replace function public.get_my_partner_wallet_summary()
returns table(
  credited_eur numeric,
  reversed_eur numeric,
  net_partner_wallet_eur numeric
)
language plpgsql
stable
security definer
set search_path=''
as $function$
begin
  if not exists(
    select 1 from public.profiles p
    where p.id=auth.uid() and p.role='seller' and p.status='active' and p.partner_enabled=true
  ) then
    raise exception 'Acesso negado';
  end if;

  return query
  select
    round(coalesce((
      select sum(l.amount_eur)
      from public.payment_financial_ledger l
      where l.seller_id=auth.uid() and l.entry_type='partner_credit'
    ),0),2),
    round(coalesce((
      select sum(l.amount_eur)
      from public.payment_financial_ledger l
      where l.seller_id=auth.uid() and l.entry_type='partner_reversal'
    ),0),2),
    round(coalesce((
      select sum(l.amount_eur)
      from public.payment_financial_ledger l
      where l.seller_id=auth.uid() and l.entry_type in('partner_credit','partner_reversal')
    ),0),2);
end
$function$;

revoke all on function public.get_my_partner_wallet_summary() from anon,public;
grant execute on function public.get_my_partner_wallet_summary() to authenticated;

-- New participation is now delivered to the existing seller wallet.
-- Keep old settlement records readable, but no longer expose the write RPC.
revoke execute on function public.create_partner_settlement(uuid,numeric,timestamptz,text,text,text,text) from public,anon,authenticated;

insert into public.audit_logs(actor_id,action,metadata)
values(
  null,'partner.wallet_credit_mode_enabled',
  jsonb_build_object(
    'mode','automatic_after_payment_approval',
    'manual_settlement_creation_disabled',true,
    'note','Participações novas entram na carteira de vendedor; acertos históricos permanecem apenas para consulta.'
  )
);
