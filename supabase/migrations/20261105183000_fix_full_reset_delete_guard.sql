-- Fix: Supabase SQL guard requires explicit WHERE on DELETE statements.
CREATE OR REPLACE FUNCTION public.reset_admin_display_summary()
RETURNS timestamptz LANGUAGE plpgsql SECURITY DEFINER SET search_path = ''
AS $$
DECLARE cutoff timestamptz;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_superadmin() THEN
  RAISE EXCEPTION 'Somente o superadministrador pode executar o RESET' USING ERRCODE='42501';
 END IF;
 PERFORM 1 FROM public.admin_summary_reset WHERE id=1 FOR UPDATE;
 cutoff:=clock_timestamp();
 DELETE FROM public.compensation_settlement_allocations WHERE true;
 DELETE FROM public.compensation_adjustments WHERE true;
 DELETE FROM public.compensation_entries WHERE true;
 DELETE FROM public.compensation_settlements WHERE true;
 DELETE FROM public.partner_settlement_allocations WHERE true;
 DELETE FROM public.partner_adjustments WHERE true;
 DELETE FROM public.partner_entries WHERE true;
 DELETE FROM public.partner_payment_snapshots WHERE true;
 DELETE FROM public.partner_settlements WHERE true;
 DELETE FROM public.payment_financial_ledger WHERE true;
 DELETE FROM public.withdrawals WHERE true;
 DELETE FROM public.payment_admin_notes WHERE true;
 DELETE FROM public.central_receipts WHERE true;
 DELETE FROM public.payment_records WHERE true;
 DELETE FROM public.notifications WHERE true;
 DELETE FROM public.audit_logs WHERE true;
 IF to_regclass('private.financial_test_cleanup_backups') IS NOT NULL THEN
  DELETE FROM private.financial_test_cleanup_backups WHERE true;
 END IF;
 UPDATE public.admin_summary_reset SET reset_at=cutoff,reset_by=auth.uid(),updated_at=cutoff WHERE id=1;
 INSERT INTO public.audit_logs(actor_id,action,metadata)
 VALUES(auth.uid(),'admin.full_financial_reset',jsonb_build_object(
  'reset_at',cutoff,'transaction_history_deleted',true,'wallet_ledger_deleted',true,
  'commission_and_partner_entries_deleted',true,'accounts_and_roles_preserved',true,
  'platform_settings_preserved',true,'withdrawal_methods_preserved',true,'commission_rules_preserved',true
 ));
 RETURN cutoff;
END;
$$;
REVOKE ALL ON FUNCTION public.reset_admin_display_summary() FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.reset_admin_display_summary() TO authenticated;