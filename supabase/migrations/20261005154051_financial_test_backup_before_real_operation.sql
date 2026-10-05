-- One-time private backup of financial test data before the Aron Pay real-operation reset.
-- The private schema is intentionally not exposed through the Supabase Data API.

create schema if not exists private;

create table if not exists private.financial_test_cleanup_backups (
  backup_id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  scope text not null,
  data jsonb not null,
  storage_objects jsonb not null
);

insert into private.financial_test_cleanup_backups (scope, data, storage_objects)
select
  'pre_real_operation_financial_test_set_2026-10-05',
  jsonb_build_object(
    'central_receipts', coalesce((select jsonb_agg(to_jsonb(t)) from public.central_receipts t), '[]'::jsonb),
    'compensation_adjustments', coalesce((select jsonb_agg(to_jsonb(t)) from public.compensation_adjustments t), '[]'::jsonb),
    'compensation_entries', coalesce((select jsonb_agg(to_jsonb(t)) from public.compensation_entries t), '[]'::jsonb),
    'compensation_settlement_allocations', coalesce((select jsonb_agg(to_jsonb(t)) from public.compensation_settlement_allocations t), '[]'::jsonb),
    'compensation_settlements', coalesce((select jsonb_agg(to_jsonb(t)) from public.compensation_settlements t), '[]'::jsonb),
    'notifications', coalesce((select jsonb_agg(to_jsonb(t)) from public.notifications t), '[]'::jsonb),
    'partner_adjustments', coalesce((select jsonb_agg(to_jsonb(t)) from public.partner_adjustments t), '[]'::jsonb),
    'partner_entries', coalesce((select jsonb_agg(to_jsonb(t)) from public.partner_entries t), '[]'::jsonb),
    'partner_payment_snapshots', coalesce((select jsonb_agg(to_jsonb(t)) from public.partner_payment_snapshots t), '[]'::jsonb),
    'partner_settlement_allocations', coalesce((select jsonb_agg(to_jsonb(t)) from public.partner_settlement_allocations t), '[]'::jsonb),
    'partner_settlements', coalesce((select jsonb_agg(to_jsonb(t)) from public.partner_settlements t), '[]'::jsonb),
    'payment_admin_notes', coalesce((select jsonb_agg(to_jsonb(t)) from public.payment_admin_notes t), '[]'::jsonb),
    'payment_financial_ledger', coalesce((select jsonb_agg(to_jsonb(t)) from public.payment_financial_ledger t), '[]'::jsonb),
    'payment_records', coalesce((select jsonb_agg(to_jsonb(t)) from public.payment_records t), '[]'::jsonb),
    'withdrawals', coalesce((select jsonb_agg(to_jsonb(t)) from public.withdrawals t), '[]'::jsonb)
  ),
  coalesce((
    select jsonb_agg(to_jsonb(o))
    from storage.objects o
    where o.bucket_id in ('payment-proofs','withdrawal-proofs')
  ), '[]'::jsonb);
