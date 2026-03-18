BEGIN;

CREATE TABLE IF NOT EXISTS public.product_warehouse_stocks (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL,
  warehouse_id uuid NOT NULL,
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  opening_stock numeric(15,2) NOT NULL DEFAULT 0,
  opening_stock_value numeric(15,2) NOT NULL DEFAULT 0,
  accounting_stock numeric(15,2) NOT NULL DEFAULT 0,
  physical_stock numeric(15,2) NOT NULL DEFAULT 0,
  committed_stock numeric(15,2) NOT NULL DEFAULT 0,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT product_warehouse_stocks_pkey PRIMARY KEY (id),
  CONSTRAINT product_warehouse_stocks_product_id_fkey
    FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE,
  CONSTRAINT product_warehouse_stocks_warehouse_id_fkey
    FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id) ON DELETE CASCADE,
  CONSTRAINT product_warehouse_stocks_unique_product_warehouse
    UNIQUE (product_id, warehouse_id)
);

CREATE INDEX IF NOT EXISTS idx_product_warehouse_stocks_product
  ON public.product_warehouse_stocks (product_id);

CREATE INDEX IF NOT EXISTS idx_product_warehouse_stocks_warehouse
  ON public.product_warehouse_stocks (warehouse_id);

CREATE INDEX IF NOT EXISTS idx_product_warehouse_stocks_org_outlet
  ON public.product_warehouse_stocks (org_id, outlet_id);

CREATE OR REPLACE FUNCTION public.set_product_warehouse_stocks_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_product_warehouse_stocks_updated_at
  ON public.product_warehouse_stocks;

CREATE TRIGGER trg_product_warehouse_stocks_updated_at
BEFORE UPDATE ON public.product_warehouse_stocks
FOR EACH ROW
EXECUTE FUNCTION public.set_product_warehouse_stocks_updated_at();

DROP TRIGGER IF EXISTS trg_audit_row ON public.product_warehouse_stocks;
CREATE TRIGGER trg_audit_row
AFTER INSERT OR DELETE OR UPDATE ON public.product_warehouse_stocks
FOR EACH ROW
EXECUTE FUNCTION audit_row_changes();

DROP TRIGGER IF EXISTS trg_audit_truncate ON public.product_warehouse_stocks;
CREATE TRIGGER trg_audit_truncate
AFTER TRUNCATE ON public.product_warehouse_stocks
FOR EACH STATEMENT
EXECUTE FUNCTION audit_table_truncate();

COMMIT;
