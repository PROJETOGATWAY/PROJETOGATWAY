-- Etapa 3: saques futuros usam o razão financeiro real e preservam saldo negativo
create or replace function public.request_withdrawal(p_amount_eur numeric)
returns public.withdrawals
language plpgsql security definer set search_path=''
as $$
declare current_settings public.platform_settings;balance numeric;result public.withdrawals;
begin
 if not exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='seller' and p.status='active') then raise exception 'Conta de vendedor indisponível'; end if;
 select * into current_settings from public.platform_settings where id=1;
 if current_settings.initialized_at is null then raise exception 'Os saques ainda não estão disponíveis'; end if;
 if current_settings.withdrawals_paused then raise exception 'Novos saques estão pausados'; end if;
 if p_amount_eur is null or p_amount_eur<=0 then raise exception 'O valor do saque deve ser maior que zero'; end if;
 if p_amount_eur<current_settings.minimum_withdrawal_eur then raise exception 'O valor está abaixo do mínimo de saque'; end if;
 select coalesce((select sum(l.amount_eur) from public.payment_financial_ledger l where l.seller_id=auth.uid()),0)
   - coalesce((select sum(w.amount_eur+w.fixed_fee_snapshot_eur) from public.withdrawals w where w.seller_id=auth.uid() and w.status in ('requested','approved')),0)
 into balance;
 if balance<0 then raise exception 'Saldo disponível negativo: % EUR. Novos saques estão bloqueados',to_char(balance,'FM999999990.00'); end if;
 if p_amount_eur+current_settings.withdrawal_fixed_fee_eur>balance then raise exception 'Saldo disponível insuficiente'; end if;
 insert into public.withdrawals(seller_id,amount_eur,fixed_fee_snapshot_eur,status) values(auth.uid(),round(p_amount_eur,2),current_settings.withdrawal_fixed_fee_eur,'requested') returning * into result;
 return result;
end;
$$;
revoke all on function public.request_withdrawal(numeric) from public;
grant execute on function public.request_withdrawal(numeric) to authenticated;
