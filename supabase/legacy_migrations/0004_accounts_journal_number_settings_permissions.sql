-- Ensure Journal Number Settings table is readable/writable by API roles.

GRANT USAGE ON SCHEMA public TO service_role, authenticated, anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.accounts_journal_number_settings TO service_role;
GRANT SELECT ON TABLE public.accounts_journal_number_settings TO authenticated, anon;
