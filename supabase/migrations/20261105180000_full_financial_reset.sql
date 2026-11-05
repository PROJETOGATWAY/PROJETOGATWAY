-- RESET financeiro completo acionado apenas pelo superadministrador.
-- Preserva contas/auth, cargos, configurações da plataforma, métodos de saque e regras percentuais.
-- Remove histórico transacional e valores que alimentam carteiras e indicadores.

CREATE OR REPLACE FUNCTION public.reset_admin_display_summary()
RETURNS timestamptz
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  cutoff timestamptz;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_superadmin() THEN
    RAISE EXCEPTION 'Somente o superadministrador pode executar o RESET'
      USING ERRCODE = '42501';
  END IF;

  PERFORM 1 FROM public.admin_summary_reset WHERE id = 1 FOR UPDATE;
  cutoff := clock_timestamp();

  DELETE FROM public.compensation_settlement_allocations;
  DELETE FROM public.compensation_adjustments;
  DELETE FROM public.compensation_entries;
  DELETE FROM public.compensation_settlements;

  DELETE FROM public.partner_settlement_allocations;
  DELETE FROM public.partner_adjustments;
  DELETE FROM public.partner_entries;
  DELETE FROM public.partner_payment_snapshots;
  DELETE FROM public.partner_settlements;

  DELETE FROM public.payment_financial_ledger;
  DELETE FROM public.withdrawals;
  DELETE FROM public.payment_admin_notes;
  DELETE FROM public.central_receipts;
  DELETE FROM public.payment_records;
  DELETE FROM public.notifications;
  DELETE FROM public.audit_logs;

  IF to_regclass('private.financial_test_cleanup_backups') IS NOT NULL THEN
    DELETE FROM private.financial_test_cleanup_backups;
  END IF;

  UPDATE public.admin_summary_reset
     SET reset_at = cutoff,
         reset_by = auth.uid(),
         updated_at = cutoff
   WHERE id = 1;

  INSERT INTO public.audit_logs(actor_id, action, metadata)
  VALUES (
    auth.uid(),
    'admin.full_financial_reset',
    jsonb_build_object(
      'reset_at', cutoff,
      'transaction_history_deleted', true,
      'wallet_ledger_deleted', true,
      'commission_and_partner_entries_deleted', true,
      'accounts_and_roles_preserved', true,
      'platform_settings_preserved', true,
      'withdrawal_methods_preserved', true,
      'commission_rules_preserved', true
    )
  );

  RETURN cutoff;
END;
$$;

REVOKE ALL ON FUNCTION public.reset_admin_display_summary() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reset_admin_display_summary() TO authenticated;
