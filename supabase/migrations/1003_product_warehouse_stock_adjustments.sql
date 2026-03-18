BEGIN;

CREATE TABLE IF NOT EXISTS public.product_warehouse_stock_adjustments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL,
  warehouse_id uuid NOT NULL,
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  adjustment_type text NOT NULL DEFAULT 'physical_count',
  previous_accounting_stock numeric(15,2) NOT NULL DEFAULT 0,
  previous_physical_stock numeric(15,2) NOT NULL DEFAULT 0,
  new_physical_stock numeric(15,2) NOT NULL DEFAULT 0,
  committed_stock numeric(15,2) NOT NULL DEFAULT 0,
  variance_qty numeric(15,2) NOT NULL DEFAULT 0,
  reason text NOT NULL,
  notes text,
  adjusted_at timestamp with time zone NOT NULL DEFAULT now(),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT product_warehouse_stock_adjustments_pkey PRIMARY KEY (id),
  CONSTRAINT product_warehouse_stock_adjustments_product_fkey
    FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE,
  CONSTRAINT product_warehouse_stock_adjustments_warehouse_fkey
    FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id) ON DELETE CASCADE,
  CONSTRAINT product_warehouse_stock_adjustments_type_check
    CHECK (adjustment_type IN ('physical_count'))
);

CREATE INDEX IF NOT EXISTS idx_product_warehouse_stock_adjustments_product
  ON public.product_warehouse_stock_adjustments (product_id, adjusted_at DESC);

CREATE INDEX IF NOT EXISTS idx_product_warehouse_stock_adjustments_warehouse
  ON public.product_warehouse_stock_adjustments (warehouse_id, adjusted_at DESC);

CREATE INDEX IF NOT EXISTS idx_product_warehouse_stock_adjustments_org_outlet
  ON public.product_warehouse_stock_adjustments (org_id, outlet_id);

DROP TRIGGER IF EXISTS trg_audit_row ON public.product_warehouse_stock_adjustments;
CREATE TRIGGER trg_audit_row
AFTER INSERT OR DELETE OR UPDATE ON public.product_warehouse_stock_adjustments
FOR EACH ROW
EXECUTE FUNCTION audit_row_changes();

DROP TRIGGER IF EXISTS trg_audit_truncate ON public.product_warehouse_stock_adjustments;
CREATE TRIGGER trg_audit_truncate
AFTER TRUNCATE ON public.product_warehouse_stock_adjustments
FOR EACH STATEMENT
EXECUTE FUNCTION audit_table_truncate();

COMMIT;
