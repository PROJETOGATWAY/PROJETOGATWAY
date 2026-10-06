REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER ON public.admin_summary_reset FROM authenticated, anon;
REVOKE SELECT ON public.admin_summary_reset FROM anon;