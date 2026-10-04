-- Contador overview: read-only global approved volume plus corrected own remuneration summary.
create or replace function public.get_my_compensation_summary()
returns table(configured_percent numeric, active boolean, total_accrued_eur numeric, total_adjustments_eur numeric, total_paid_eur numeric, pending_eur numeric)
language plpgsql
security definer
set search_path=''
as $function$
declare r public.compensation_rules;
begin
  if not exists(
    select 1 from public.profiles p
    where p.id=(select auth.uid())
      and p.role='admin'
      and p.admin_level='contador'
      and p.status='active'
  ) then raise exception 'Acesso negado'; end if;

  select cr.* into r
  from public.compensation_rules cr
  where cr.active=true
  limit 1;

  return query
  select
    coalesce(r.configured_percent,0),
    coalesce(r.active,false),
    round(coalesce((select sum(e.amount_eur) from public.compensation_entries e where e.beneficiary_id=(select auth.uid())),0),2),
    round(coalesce((select sum(a.amount_eur) from public.compensation_adjustments a where a.beneficiary_id=(select auth.uid())),0),2),
    round(coalesce((select sum(s.amount_eur) from public.compensation_settlements s where s.beneficiary_id=(select auth.uid())),0),2),
    round(
      coalesce((select sum(e.amount_eur) from public.compensation_entries e where e.beneficiary_id=(select auth.uid())),0)
      + coalesce((select sum(a.amount_eur) from public.compensation_adjustments a where a.beneficiary_id=(select auth.uid())),0)
      - coalesce((select sum(s.amount_eur) from public.compensation_settlements s where s.beneficiary_id=(select auth.uid())),0)
    ,2);
end $function$;

create or replace function public.get_counter_operation_overview()
returns table(approved_gross_eur numeric)
language plpgsql
stable
security definer
set search_path=''
as $function$
begin
  if not exists(
    select 1 from public.profiles p
    where p.id=(select auth.uid())
      and p.role='admin'
      and p.admin_level='contador'
      and p.status='active'
  ) then raise exception 'Acesso negado'; end if;

  return query
  select round(coalesce(sum(p.gross_amount_eur),0),2)
  from public.payment_records p
  where p.status='approved';
end $function$;

revoke all on function public.get_counter_operation_overview() from public;
grant execute on function public.get_counter_operation_overview() to authenticated;