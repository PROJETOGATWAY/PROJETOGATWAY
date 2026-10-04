-- Etapa 2: regras transacionais para congelar configurações vigentes
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
