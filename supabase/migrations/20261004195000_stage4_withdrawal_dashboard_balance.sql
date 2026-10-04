create or replace function public.get_seller_dashboard(p_start timestamptz default null,p_end timestamptz default null)
returns table(available_balance_eur numeric,pending_balance_eur numeric,approved_volume_eur numeric,at_risk_eur numeric,reserved_withdrawals_eur numeric)
language sql set search_path=''
as $$
select
 coalesce((select sum(l.amount_eur) from public.payment_financial_ledger l where l.seller_id=auth.uid()),0),
 coalesce((select sum(p.gross_amount_eur) from public.payment_records p where p.seller_id=auth.uid() and p.status='pending'),0),
 coalesce((select sum(p.gross_amount_eur) from public.payment_records p where p.seller_id=auth.uid() and p.status='approved' and (p_start is null or p.created_at>=p_start) and (p_end is null or p.created_at<p_end)),0)
 -coalesce((select sum(p.gross_amount_eur) from public.payment_records p where p.seller_id=auth.uid() and p.status='estornado' and (p_start is null or p.created_at>=p_start) and (p_end is null or p.created_at<p_end)),0),
 coalesce((select sum(p.gross_amount_eur) from public.payment_records p where p.seller_id=auth.uid() and p.status='under_review'),0),
 coalesce((select sum(w.amount_eur) from public.withdrawals w where w.seller_id=auth.uid() and w.status in ('requested','under_review','approved_for_payment','processing')),0);
$$;
revoke all on function public.get_seller_dashboard(timestamptz,timestamptz) from anon;
grant execute on function public.get_seller_dashboard(timestamptz,timestamptz) to authenticated;
