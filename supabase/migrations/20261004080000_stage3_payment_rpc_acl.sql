-- Etapa 3: RPCs financeiras nunca ficam disponíveis para anon
revoke all on function public.create_payment_submission(numeric,text,text,text,text,text) from anon;
grant execute on function public.create_payment_submission(numeric,text,text,text,text,text) to authenticated;
revoke all on function public.finalize_payment_submission(uuid,text,text,bigint) from anon;
grant execute on function public.finalize_payment_submission(uuid,text,text,bigint) to authenticated;
revoke all on function public.cleanup_failed_payment_submission(uuid) from anon;
grant execute on function public.cleanup_failed_payment_submission(uuid) to authenticated;
revoke all on function public.admin_add_payment_note(uuid,text) from anon;
grant execute on function public.admin_add_payment_note(uuid,text) to authenticated;
revoke all on function public.admin_reject_payment(uuid,text) from anon;
grant execute on function public.admin_reject_payment(uuid,text) to authenticated;
revoke all on function public.admin_escalate_payment(uuid,text) from anon;
grant execute on function public.admin_escalate_payment(uuid,text) to authenticated;
revoke all on function public.admin_approve_payment(uuid,uuid,text,timestamptz,numeric,text,text) from anon;
grant execute on function public.admin_approve_payment(uuid,uuid,text,timestamptz,numeric,text,text) to authenticated;
revoke all on function public.admin_reverse_payment(uuid,text) from anon;
grant execute on function public.admin_reverse_payment(uuid,text) to authenticated;
