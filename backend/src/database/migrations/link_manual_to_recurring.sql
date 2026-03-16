-- Add recurring_journal_id to accounts_manual_journals
ALTER TABLE public.accounts_manual_journals 
ADD COLUMN IF NOT EXISTS recurring_journal_id uuid;

-- Add foreign key constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'accounts_manual_journals_recurring_journal_id_fkey'
    ) THEN
        ALTER TABLE public.accounts_manual_journals
        ADD CONSTRAINT accounts_manual_journals_recurring_journal_id_fkey 
        FOREIGN KEY (recurring_journal_id) 
        REFERENCES public.accounts_recurring_journals(id) 
        ON DELETE SET NULL;
    END IF;
END $$;
