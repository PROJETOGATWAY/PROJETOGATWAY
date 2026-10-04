-- Etapa 2: remove execução pública residual de funções internas
revoke all on function public.handle_new_user() from public;
revoke all on function public.is_admin() from public;
revoke all on function public.is_superadmin() from public;
grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_superadmin() to authenticated;
