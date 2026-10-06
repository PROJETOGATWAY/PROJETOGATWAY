CREATE TABLE public.admin_summary_reset (id smallint PRIMARY KEY DEFAULT 1, reset_at timestamptz, reset_by uuid REFERENCES public.profiles(id), created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now());
GRANT SELECT ON public.admin_summary_reset TO authenticated;
GRANT ALL ON public.admin_summary_reset TO service_role;
ALTER TABLE public.admin_summary_reset ENABLE ROW LEVEL SECURITY;
CREATE POLICY admin_summary_reset_read ON public.admin_summary_reset FOR SELECT TO authenticated USING (public.is_admin());
CREATE TRIGGER admin_summary_reset_updated BEFORE UPDATE ON public.admin_summary_reset FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
INSERT INTO public.admin_summary_reset(id) VALUES (1);
CREATE FUNCTION public.get_admin_display_summary(p_start timestamptz DEFAULT NULL, p_end timestamptz DEFAULT NULL, p_seller_id uuid DEFAULT NULL) RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE cutoff timestamptz; effective_start timestamptz; result jsonb;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin() THEN RAISE EXCEPTION 'Acesso negado' USING ERRCODE='42501'; END IF;
 SELECT reset_at INTO cutoff FROM public.admin_summary_reset WHERE id=1;
 effective_start := CASE WHEN cutoff IS NULL THEN p_start WHEN p_start IS NULL THEN cutoff ELSE greatest(p_start,cutoff) END;
 SELECT to_jsonb(s) INTO result FROM public.admin_financial_summary(effective_start,p_end,p_seller_id) s;
 IF cutoff IS NOT NULL THEN
  result := result || jsonb_build_object(
   'sellers_available_eur',coalesce((SELECT sum(l.amount_eur) FROM public.payment_financial_ledger l WHERE l.entry_type IN ('sale_credit','reversal_debit') AND l.created_at>=cutoff AND (p_seller_id IS NULL OR l.seller_id=p_seller_id)),0),
   'sellers_reserved_eur',coalesce((SELECT sum(w.amount_eur) FROM public.withdrawals w WHERE w.status IN ('requested','under_review','approved_for_payment','processing') AND w.created_at>=cutoff AND (p_seller_id IS NULL OR w.seller_id=p_seller_id)),0),
   'withdrawals_awaiting_action',(SELECT count(*) FROM public.withdrawals w WHERE w.status IN ('requested','under_review','approved_for_payment','processing') AND w.created_at>=cutoff AND (p_seller_id IS NULL OR w.seller_id=p_seller_id))
  );
 END IF;
 RETURN jsonb_build_object('summary',result,'reset_at',cutoff,'can_reset',public.is_superadmin());
END $$;
REVOKE ALL ON FUNCTION public.get_admin_display_summary(timestamptz,timestamptz,uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_admin_display_summary(timestamptz,timestamptz,uuid) TO authenticated;
CREATE FUNCTION public.reset_admin_display_summary() RETURNS timestamptz LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
DECLARE cutoff timestamptz;
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_superadmin() THEN RAISE EXCEPTION 'Somente o superadministrador pode zerar o resumo' USING ERRCODE='42501'; END IF;
 PERFORM 1 FROM public.admin_summary_reset WHERE id=1 FOR UPDATE;
 cutoff := clock_timestamp();
 UPDATE public.admin_summary_reset SET reset_at=cutoff,reset_by=auth.uid(),updated_at=cutoff WHERE id=1;
 INSERT INTO public.audit_logs(actor_id,action,metadata) VALUES(auth.uid(),'admin.summary_reset',jsonb_build_object('reset_at',cutoff,'financial_records_preserved',true));
 RETURN cutoff;
END $$;
REVOKE ALL ON FUNCTION public.reset_admin_display_summary() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.reset_admin_display_summary() TO authenticated;