-- Backfill-safe migration for fiscal years table used by Accounts module.
-- Equivalent to provided DDL, with IF NOT EXISTS guard for repeatable deploys.

CREATE TABLE IF NOT EXISTS public.accounts_fiscal_years (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid NULL,
  name character varying(50) NOT NULL,
  start_date date NOT NULL,
  end_date date NOT NULL,
  is_active boolean NULL DEFAULT true,
  created_at timestamp without time zone NULL DEFAULT now(),
  CONSTRAINT accounts_fiscal_years_pkey PRIMARY KEY (id)
) TABLESPACE pg_default;
