drop function if exists public.request_withdrawal(numeric);
create or replace function public.get_seller_dashboard()
returns table(available_balance_eur numeric,pending_balance_eur numeric,approved_volume_eur numeric,at_risk_eur numeric,reserved_withdrawals_eur numeric)
language sql set search_path=''
as $$
select * from public.get_seller_dashboard(null,null);
$$;
revoke all on function public.get_seller_dashboard() from anon;
grant execute on function public.get_seller_dashboard() to authenticated;
