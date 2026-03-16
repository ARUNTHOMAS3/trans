-- Ensure Accounts manual journal workflow tables are accessible to API roles.
-- This prevents "permission denied for table accounts_manual_journals" errors
-- during create/list/update/post operations.

GRANT USAGE ON SCHEMA public TO service_role, authenticated, anon;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.accounts_manual_journals TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.accounts_manual_journal_items TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.accounts_manual_journal_attachments TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.accounts_manual_journal_tag_mappings TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.account_transactions TO service_role;

GRANT SELECT ON TABLE public.accounts_manual_journals TO authenticated, anon;
GRANT SELECT ON TABLE public.accounts_manual_journal_items TO authenticated, anon;
GRANT SELECT ON TABLE public.accounts_manual_journal_attachments TO authenticated, anon;
GRANT SELECT ON TABLE public.accounts_manual_journal_tag_mappings TO authenticated, anon;
GRANT SELECT ON TABLE public.account_transactions TO authenticated, anon;

-- Contacts used in manual journal rows (customer/vendor dropdown)
GRANT SELECT ON TABLE public.customers TO service_role, authenticated, anon;
GRANT SELECT ON TABLE public.vendors TO service_role, authenticated, anon;
