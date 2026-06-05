BEGIN;

-- Sales Returns: add missing columns only if absent (no table recreation)
ALTER TABLE IF EXISTS public.sales_returns
  ADD COLUMN IF NOT EXISTS entity_id uuid,
  ADD COLUMN IF NOT EXISTS customer_id uuid,
  ADD COLUMN IF NOT EXISTS rma_number character varying,
  ADD COLUMN IF NOT EXISTS return_date date,
  ADD COLUMN IF NOT EXISTS warehouse_id uuid,
  ADD COLUMN IF NOT EXISTS reason text,
  ADD COLUMN IF NOT EXISTS reference_number character varying,
  ADD COLUMN IF NOT EXISTS contains_credit_only_goods boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS status character varying DEFAULT 'draft'::character varying,
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS created_by uuid,
  ADD COLUMN IF NOT EXISTS approved_by uuid,
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Sales Return Items: add missing columns only if absent (no table recreation)
ALTER TABLE IF EXISTS public.sales_return_items
  ADD COLUMN IF NOT EXISTS sales_return_id uuid,
  ADD COLUMN IF NOT EXISTS product_id uuid,
  ADD COLUMN IF NOT EXISTS sales_invoice_item_id uuid,
  ADD COLUMN IF NOT EXISTS invoiced_qty numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS already_returned_qty numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS return_qty numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS receivable_qty numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS credit_only_qty numeric DEFAULT 0,
  ADD COLUMN IF NOT EXISTS remarks text,
  ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Backfill safe defaults where nulls exist
UPDATE public.sales_returns
SET contains_credit_only_goods = false
WHERE contains_credit_only_goods IS NULL;

UPDATE public.sales_returns
SET status = 'draft'
WHERE status IS NULL OR btrim(status) = '';

UPDATE public.sales_return_items
SET invoiced_qty = 0
WHERE invoiced_qty IS NULL;

UPDATE public.sales_return_items
SET already_returned_qty = 0
WHERE already_returned_qty IS NULL;

UPDATE public.sales_return_items
SET return_qty = 0
WHERE return_qty IS NULL;

UPDATE public.sales_return_items
SET receivable_qty = 0
WHERE receivable_qty IS NULL;

UPDATE public.sales_return_items
SET credit_only_qty = 0
WHERE credit_only_qty IS NULL;

-- Ensure NOT NULL constraints for required columns once backfill is done
ALTER TABLE IF EXISTS public.sales_returns
  ALTER COLUMN entity_id SET NOT NULL,
  ALTER COLUMN customer_id SET NOT NULL,
  ALTER COLUMN rma_number SET NOT NULL,
  ALTER COLUMN return_date SET NOT NULL,
  ALTER COLUMN warehouse_id SET NOT NULL,
  ALTER COLUMN contains_credit_only_goods SET NOT NULL,
  ALTER COLUMN status SET NOT NULL;

ALTER TABLE IF EXISTS public.sales_return_items
  ALTER COLUMN sales_return_id SET NOT NULL,
  ALTER COLUMN product_id SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'sales_returns_entity_id_fkey'
  ) THEN
    ALTER TABLE public.sales_returns
      ADD CONSTRAINT sales_returns_entity_id_fkey
      FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'sales_returns_customer_id_fkey'
  ) THEN
    ALTER TABLE public.sales_returns
      ADD CONSTRAINT sales_returns_customer_id_fkey
      FOREIGN KEY (customer_id) REFERENCES public.customers(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'sales_returns_warehouse_id_fkey'
  ) THEN
    ALTER TABLE public.sales_returns
      ADD CONSTRAINT sales_returns_warehouse_id_fkey
      FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'sales_return_items_sales_return_id_fkey'
  ) THEN
    ALTER TABLE public.sales_return_items
      ADD CONSTRAINT sales_return_items_sales_return_id_fkey
      FOREIGN KEY (sales_return_id)
      REFERENCES public.sales_returns(id)
      ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'sales_return_items_product_id_fkey'
  ) THEN
    ALTER TABLE public.sales_return_items
      ADD CONSTRAINT sales_return_items_product_id_fkey
      FOREIGN KEY (product_id) REFERENCES public.products(id);
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS ux_sales_returns_entity_rma_number
  ON public.sales_returns(entity_id, rma_number);

CREATE INDEX IF NOT EXISTS idx_sales_returns_entity_return_date_status
  ON public.sales_returns(entity_id, return_date DESC, status);

CREATE INDEX IF NOT EXISTS idx_sales_return_items_sales_return_id
  ON public.sales_return_items(sales_return_id);

CREATE INDEX IF NOT EXISTS idx_sales_return_items_product_id
  ON public.sales_return_items(product_id);

COMMIT;
