import { createServerFn, createMiddleware } from '@tanstack/react-start';
import { requireSupabaseAuth } from '@/integrations/supabase/auth-middleware';
import { z } from 'zod';

// Scoped to these calls so existing authentication flows remain unchanged.
const summaryAuth = createMiddleware({ type: 'function' }).client(async ({ next }) => {
  const { getSupabase } = await import('./supabase');
  const { data } = await getSupabase().auth.getSession();
  const token = data.session?.access_token;
  return next({ headers: token ? { Authorization: `Bearer ${token}` } : {} });
});

export const getAdminDisplaySummary = createServerFn({ method: 'POST' })
  .middleware([summaryAuth, requireSupabaseAuth])
  .inputValidator(z.object({ start: z.string().datetime().nullable(), end: z.string().datetime().nullable(), sellerId: z.string().uuid().nullable() }))
  .handler(async ({ data, context }) => {
    const { data: result, error } = await context.supabase.rpc('get_admin_display_summary', {
      p_start: data.start ?? undefined, p_end: data.end ?? undefined, p_seller_id: data.sellerId ?? undefined,
    });
    if (error) throw new Error('Não foi possível carregar o resumo. Tente novamente.');
    return result;
  });

export const resetAdminDisplaySummary = createServerFn({ method: 'POST' })
  .middleware([summaryAuth, requireSupabaseAuth])
  .handler(async ({ context }) => {
    const { data: allowed, error: roleError } = await context.supabase.rpc('is_superadmin');
    if (roleError || !allowed) throw new Error('Somente o superadministrador pode zerar o resumo.');
    const { data, error } = await context.supabase.rpc('reset_admin_display_summary');
    if (error) throw new Error('Não foi possível zerar o resumo. Tente novamente.');
    return data;
  });