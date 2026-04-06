-- Ensure Accounts fiscal-year table is readable by API roles.
-- Root cause observed: 42501 permission denied for table accounts_fiscal_years.

GRANT USAGE ON SCHEMA public TO service_role, authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.accounts_fiscal_years TO service_role;
GRANT SELECT ON TABLE public.accounts_fiscal_years TO authenticated, anon;
