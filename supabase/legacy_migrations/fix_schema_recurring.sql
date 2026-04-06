-- Rename currency column to currency_code if it exists as 'currency'
DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'accounts_recurring_journals'
        AND column_name = 'currency'
    ) THEN
        ALTER TABLE public.accounts_recurring_journals 
        RENAME COLUMN currency TO currency_code;
    END IF;
END $$;

-- If the table doesn't exist, create it (safe fallback)
CREATE TABLE IF NOT EXISTS public.accounts_recurring_journals (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  profile_name character varying NOT NULL,
  repeat_every character varying NOT NULL, -- 'week', 'month', 'year'
  interval integer NOT NULL DEFAULT 1,
  start_date date NOT NULL,
  end_date date,
  never_expires boolean DEFAULT true,
  reference_number character varying,
  notes text,
  currency_code character varying DEFAULT 'INR'::character varying,
  reporting_method public.accounts_reporting_method DEFAULT 'accrual_and_cash'::public.accounts_reporting_method,
  status character varying DEFAULT 'active'::character varying, -- 'active', 'inactive', 'stopped'
  last_generated_date timestamp without time zone,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  created_by uuid,
  CONSTRAINT accounts_recurring_journals_pkey PRIMARY KEY (id)
);

-- Ensure Items table
CREATE TABLE IF NOT EXISTS public.accounts_recurring_journal_items (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  recurring_journal_id uuid NOT NULL,
  account_id uuid NOT NULL,
  description text,
  contact_id uuid,
  contact_type character varying,
  debit numeric DEFAULT 0.00,
  credit numeric DEFAULT 0.00,
  sort_order integer,
  CONSTRAINT accounts_recurring_journal_items_pkey PRIMARY KEY (id),
  CONSTRAINT accounts_recurring_journal_items_recur_journal_id_fkey FOREIGN KEY (recurring_journal_id) REFERENCES public.accounts_recurring_journals(id) ON DELETE CASCADE,
  CONSTRAINT accounts_recurring_journal_items_account_id_fkey FOREIGN KEY (account_id) REFERENCES public.accounts(id)
);

