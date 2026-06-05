-- Phase: Items Purchase Rep Lookup
-- Additive migration only.

BEGIN;

CREATE TABLE IF NOT EXISTS public.sales_reps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  entity_id uuid REFERENCES public.organisation_branch_master(id),
  name varchar(255) NOT NULL,
  number varchar(100),
  brand_id uuid REFERENCES public.brands(id),
  division varchar(255),
  area varchar(255),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sales_reps_entity_active_name
  ON public.sales_reps (entity_id, is_active, name);

ALTER TABLE public.products
  ADD COLUMN IF NOT EXISTS rep_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'products_rep_id_fkey'
  ) THEN
    ALTER TABLE public.products
      ADD CONSTRAINT products_rep_id_fkey
      FOREIGN KEY (rep_id) REFERENCES public.sales_reps(id);
  END IF;
END $$;

COMMIT;

