-- Custom SQL migration file, put your code below! --

DO $$
BEGIN
  CREATE TYPE public.accounts_reporting_method AS ENUM (
    'accrual_and_cash',
    'accrual_only',
    'cash_only'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.accounts_manual_journal_status AS ENUM (
    'draft',
    'published'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.accounts_journal_template_type AS ENUM (
    'debit',
    'credit'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE public.accounts_contact_type AS ENUM (
    'customer',
    'vendor'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.accounts_fiscal_years (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  outlet_id uuid NULL,
  name character varying(50) NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.accounts_journal_number_settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  outlet_id uuid NULL,
  auto_generate boolean DEFAULT true,
  prefix character varying(20),
  next_number integer DEFAULT 1,
  is_manual_override_allowed boolean DEFAULT false
);

CREATE TABLE IF NOT EXISTS public.accounts_journal_templates (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  outlet_id uuid NULL,
  template_name character varying(255) NOT NULL,
  reference_number character varying(100),
  notes text,
  reporting_method public.accounts_reporting_method,
  currency_code character varying(10) DEFAULT 'INR',
  is_active boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.accounts_manual_journals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  outlet_id uuid NULL,
  journal_number character varying(100) NOT NULL,
  fiscal_year_id uuid NULL REFERENCES public.accounts_fiscal_years(id),
  reference_number character varying(100),
  journal_date date DEFAULT CURRENT_DATE,
  notes text,
  is_13th_month_adjustment boolean DEFAULT false,
  reporting_method public.accounts_reporting_method DEFAULT 'accrual_and_cash',
  currency_code character varying(10) DEFAULT 'INR',
  status public.accounts_manual_journal_status DEFAULT 'draft',
  total_amount numeric(15,2) DEFAULT 0.00,
  created_by uuid,
  created_at timestamp without time zone DEFAULT now(),
  CONSTRAINT accounts_manual_journals_journal_number_unique UNIQUE (journal_number)
);

CREATE TABLE IF NOT EXISTS public.accounts_manual_journal_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  outlet_id uuid NULL,
  manual_journal_id uuid NOT NULL REFERENCES public.accounts_manual_journals(id) ON DELETE CASCADE,
  account_id uuid NOT NULL REFERENCES public.accounts(id),
  description text,
  contact_id uuid,
  contact_type public.accounts_contact_type,
  debit numeric(15,2) DEFAULT 0.00,
  credit numeric(15,2) DEFAULT 0.00,
  sort_order integer
);

CREATE TABLE IF NOT EXISTS public.accounts_journal_template_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  outlet_id uuid NULL,
  template_id uuid NOT NULL REFERENCES public.accounts_journal_templates(id) ON DELETE CASCADE,
  account_id uuid NOT NULL REFERENCES public.accounts(id),
  description text,
  contact_id uuid,
  contact_type public.accounts_contact_type,
  type public.accounts_journal_template_type
);

CREATE TABLE IF NOT EXISTS public.accounts_reporting_tags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  outlet_id uuid NULL,
  tag_name character varying(100) NOT NULL,
  is_active boolean DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.accounts_manual_journal_tag_mappings (
  manual_journal_item_id uuid NOT NULL REFERENCES public.accounts_manual_journal_items(id) ON DELETE CASCADE,
  reporting_tag_id uuid NOT NULL REFERENCES public.accounts_reporting_tags(id) ON DELETE CASCADE,
  CONSTRAINT accounts_manual_journal_tag_mappings_pkey PRIMARY KEY (
    manual_journal_item_id,
    reporting_tag_id
  )
);

CREATE TABLE IF NOT EXISTS public.accounts_manual_journal_attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000',
  outlet_id uuid NULL,
  manual_journal_id uuid NOT NULL REFERENCES public.accounts_manual_journals(id) ON DELETE CASCADE,
  file_name character varying(255) NOT NULL,
  file_path text NOT NULL,
  file_size integer,
  uploaded_at timestamp without time zone DEFAULT now()
);

ALTER TABLE public.account_transactions
  ADD COLUMN IF NOT EXISTS source_id uuid,
  ADD COLUMN IF NOT EXISTS source_type character varying(50);
