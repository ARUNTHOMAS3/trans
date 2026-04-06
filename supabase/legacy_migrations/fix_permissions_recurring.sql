-- Disable RLS and Grant Permissions for Recurring Journals
-- 1. Recurring Journals Table
ALTER TABLE public.accounts_recurring_journals DISABLE ROW LEVEL SECURITY;

GRANT ALL ON public.accounts_recurring_journals TO anon;
GRANT ALL ON public.accounts_recurring_journals TO authenticated;
GRANT ALL ON public.accounts_recurring_journals TO service_role;

-- 2. Recurring Journal Items Table
ALTER TABLE public.accounts_recurring_journal_items DISABLE ROW LEVEL SECURITY;

GRANT ALL ON public.accounts_recurring_journal_items TO anon;
GRANT ALL ON public.accounts_recurring_journal_items TO authenticated;
GRANT ALL ON public.accounts_recurring_journal_items TO service_role;
