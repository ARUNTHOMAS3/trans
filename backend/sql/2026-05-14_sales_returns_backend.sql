BEGIN;

CREATE TABLE IF NOT EXISTS public.sales_returns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id uuid NOT NULL,
  customer_id uuid NOT NULL,
  rma_number varchar(50) NOT NULL,
  return_date date NOT NULL,
  warehouse_id uuid NOT NULL,
  reason text,
  reference_number varchar(100),
  contains_credit_only_goods boolean NOT NULL DEFAULT false,
  status varchar(30) NOT NULL DEFAULT 'draft',
  notes text,
  created_by uuid,
  approved_by uuid,
  approved_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.sales_return_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sales_return_id uuid NOT NULL,
  product_id uuid NOT NULL,
  sales_invoice_item_id uuid,
  invoiced_qty numeric(15,3) DEFAULT 0,
  already_returned_qty numeric(15,3) DEFAULT 0,
  return_qty numeric(15,3) DEFAULT 0,
  receivable_qty numeric(15,3) DEFAULT 0,
  credit_only_qty numeric(15,3) DEFAULT 0,
  remarks text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

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
      FOREIGN KEY (sales_return_id) REFERENCES public.sales_returns(id)
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
