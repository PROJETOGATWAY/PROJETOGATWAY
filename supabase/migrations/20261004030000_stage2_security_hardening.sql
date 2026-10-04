-- Etapa 2: endurecimento de permissões das funções SECURITY DEFINER
alter function public.set_updated_at() set search_path = '';

revoke all on function public.bootstrap_superadmin(text) from anon, authenticated;
grant execute on function public.bootstrap_superadmin(text) to service_role;

revoke all on function public.handle_new_user() from anon, authenticated, service_role;

revoke all on function public.is_admin() from anon;
grant execute on function public.is_admin() to authenticated;

revoke all on function public.is_superadmin() from anon;
grant execute on function public.is_superadmin() to authenticated;

revoke all on function public.invite_admin_record(text) from anon;
grant execute on function public.invite_admin_record(text) to authenticated;

revoke all on function public.reactivate_seller(uuid,text) from anon;
grant execute on function public.reactivate_seller(uuid,text) to authenticated;

revoke all on function public.revoke_admin(uuid,text) from anon;
grant execute on function public.revoke_admin(uuid,text) to authenticated;

revoke all on function public.suspend_seller(uuid,text) from anon;
grant execute on function public.suspend_seller(uuid,text) to authenticated;

revoke all on function public.update_my_profile(text) from anon;
grant execute on function public.update_my_profile(text) to authenticated;

revoke all on function public.save_platform_settings(text,text,numeric,numeric,numeric,boolean) from anon;
grant execute on function public.save_platform_settings(text,text,numeric,numeric,numeric,boolean) to authenticated;

revoke all on function public.submit_payment(numeric,text) from anon;
grant execute on function public.submit_payment(numeric,text) to authenticated;

revoke all on function public.request_withdrawal(numeric) from anon;
grant execute on function public.request_withdrawal(numeric) to authenticated;
