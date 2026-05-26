-- ============================================================
-- Zerpai ERP — Inventory Adjustments Real Engine (Additive)
-- Date: 2026-04-29
-- NOTE: Run manually by environment owner.
-- ============================================================

-- 0) Enums (idempotent)
DO $$ BEGIN
  CREATE TYPE public.inventory_adjustment_status AS ENUM (
    'draft',
    'submitted',
    'approved',
    'rejected',
    'cancelled'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$ BEGIN
  CREATE TYPE public.inventory_adjustment_type AS ENUM ('quantity', 'value');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 1) Header (keeps existing plural naming for compatibility)
CREATE TABLE IF NOT EXISTS public.inventory_adjustments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id uuid NOT NULL REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT,
  product_id uuid REFERENCES public.products(id) ON DELETE RESTRICT,
  warehouse_id uuid REFERENCES public.warehouses(id) ON DELETE SET NULL,
  adjustment_number varchar(100) UNIQUE,
  adjustment_date timestamptz NOT NULL DEFAULT now(),
  adjustment_type public.inventory_adjustment_type NOT NULL DEFAULT 'quantity',
  reason_id uuid,
  reason varchar(255),
  reference_number varchar(100),
  notes text,
  account_id uuid,
  status public.inventory_adjustment_status NOT NULL DEFAULT 'draft',
  quantity_before numeric(15,2),
  quantity_adjusted numeric(15,2),
  quantity_after numeric(15,2),
  cost_price numeric(15,2),
  adjustment_value numeric(15,2),
  adjusted_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  approved_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  approved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.inventory_adjustments
  ADD COLUMN IF NOT EXISTS reason_id uuid,
  ADD COLUMN IF NOT EXISTS reason varchar(255);

-- 2) Reasons
CREATE TABLE IF NOT EXISTS public.inventory_adjustment_reasons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id uuid REFERENCES public.organisation_branch_master(id) ON DELETE CASCADE,
  name varchar(200) NOT NULL,
  code varchar(60),
  reason_type varchar(20) DEFAULT 'both',
  is_active boolean NOT NULL DEFAULT true,
  sort_order integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (entity_id, name)
);

ALTER TABLE public.inventory_adjustment_reasons
  ADD COLUMN IF NOT EXISTS reason_type varchar(20) DEFAULT 'both';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema='public'
      AND table_name='inventory_adjustments'
      AND constraint_name='fk_inventory_adjustments_reason_id'
  ) THEN
    ALTER TABLE public.inventory_adjustments
      ADD CONSTRAINT fk_inventory_adjustments_reason_id
      FOREIGN KEY (reason_id)
      REFERENCES public.inventory_adjustment_reasons(id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- 3) Quantity line items
CREATE TABLE IF NOT EXISTS public.inventory_adjustment_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adjustment_id uuid NOT NULL REFERENCES public.inventory_adjustments(id) ON DELETE CASCADE,
  entity_id uuid NOT NULL REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  quantity_before numeric(15,2) NOT NULL DEFAULT 0,
  quantity_adjusted numeric(15,2) NOT NULL DEFAULT 0,
  quantity_after numeric(15,2) NOT NULL DEFAULT 0,
  cost_price numeric(15,2),
  purchase_rate numeric(15,2),
  mrp numeric(15,2),
  adjustment_value numeric(15,2) NOT NULL DEFAULT 0,
  batch_id uuid REFERENCES public.batch_master(id) ON DELETE SET NULL,
  batch_reference varchar(150),
  batch_allocations jsonb NOT NULL DEFAULT '[]'::jsonb,
  reporting_tags jsonb NOT NULL DEFAULT '{}'::jsonb,
  mfd_month_year varchar(7),
  expiry_month_year varchar(7),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 4) Quantity batch allocations
CREATE TABLE IF NOT EXISTS public.inventory_adjustment_item_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adjustment_id uuid NOT NULL REFERENCES public.inventory_adjustments(id) ON DELETE CASCADE,
  adjustment_item_id uuid NOT NULL REFERENCES public.inventory_adjustment_items(id) ON DELETE CASCADE,
  entity_id uuid NOT NULL REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  warehouse_id uuid REFERENCES public.warehouses(id) ON DELETE SET NULL,
  bin_id uuid,
  batch_id uuid REFERENCES public.batch_master(id) ON DELETE SET NULL,
  batch_reference varchar(150),
  quantity_in numeric(15,2) NOT NULL DEFAULT 0,
  quantity_out numeric(15,2) NOT NULL DEFAULT 0,
  rate numeric(15,2),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 5) Value line items
CREATE TABLE IF NOT EXISTS public.inventory_adjustment_value_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adjustment_id uuid NOT NULL REFERENCES public.inventory_adjustments(id) ON DELETE CASCADE,
  entity_id uuid NOT NULL REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT,
  product_id uuid NOT NULL REFERENCES public.products(id) ON DELETE RESTRICT,
  batch_id uuid REFERENCES public.batch_master(id) ON DELETE SET NULL,
  batch_stock_layer_id uuid,
  current_value numeric(18,2) NOT NULL DEFAULT 0,
  changed_value numeric(18,2) NOT NULL DEFAULT 0,
  adjusted_value numeric(18,2) NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 6) Inventory-adjustment account entries (staging/source table)
CREATE TABLE IF NOT EXISTS public.inventory_adjustment_account_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adjustment_id uuid NOT NULL REFERENCES public.inventory_adjustments(id) ON DELETE CASCADE,
  entity_id uuid NOT NULL REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT,
  account_id uuid NOT NULL REFERENCES public.accounts(id) ON DELETE RESTRICT,
  debit numeric(18,2) NOT NULL DEFAULT 0,
  credit numeric(18,2) NOT NULL DEFAULT 0,
  description text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- 7) Indexes
CREATE INDEX IF NOT EXISTS idx_inv_adj_entity_date
  ON public.inventory_adjustments(entity_id, adjustment_date DESC);
CREATE INDEX IF NOT EXISTS idx_inv_adj_entity_status
  ON public.inventory_adjustments(entity_id, status);
CREATE INDEX IF NOT EXISTS idx_inv_adj_items_adj
  ON public.inventory_adjustment_items(adjustment_id);
CREATE INDEX IF NOT EXISTS idx_inv_adj_items_entity
  ON public.inventory_adjustment_items(entity_id, product_id);
CREATE INDEX IF NOT EXISTS idx_inv_adj_item_batches_adj
  ON public.inventory_adjustment_item_batches(adjustment_id, adjustment_item_id);
CREATE INDEX IF NOT EXISTS idx_inv_adj_item_batches_entity
  ON public.inventory_adjustment_item_batches(entity_id, product_id, batch_id);
CREATE INDEX IF NOT EXISTS idx_inv_adj_value_items_adj
  ON public.inventory_adjustment_value_items(adjustment_id);
CREATE INDEX IF NOT EXISTS idx_inv_adj_value_items_entity
  ON public.inventory_adjustment_value_items(entity_id, product_id, batch_id);
CREATE INDEX IF NOT EXISTS idx_inv_adj_acc_entries_adj
  ON public.inventory_adjustment_account_entries(adjustment_id);

-- 8) Basic format checks
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='chk_inv_adj_items_mfd_mm_yyyy'
  ) THEN
    ALTER TABLE public.inventory_adjustment_items
      ADD CONSTRAINT chk_inv_adj_items_mfd_mm_yyyy
      CHECK (mfd_month_year IS NULL OR mfd_month_year ~ '^(0[1-9]|1[0-2])/[0-9]{4}$');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='chk_inv_adj_items_expiry_mm_yyyy'
  ) THEN
    ALTER TABLE public.inventory_adjustment_items
      ADD CONSTRAINT chk_inv_adj_items_expiry_mm_yyyy
      CHECK (expiry_month_year IS NULL OR expiry_month_year ~ '^(0[1-9]|1[0-2])/[0-9]{4}$');
  END IF;
END $$;

-- 9) Updated-at trigger
CREATE OR REPLACE FUNCTION public.zerpai_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_inv_adj_updated_at ON public.inventory_adjustments;
CREATE TRIGGER trg_inv_adj_updated_at
BEFORE UPDATE ON public.inventory_adjustments
FOR EACH ROW EXECUTE FUNCTION public.zerpai_set_updated_at();

DROP TRIGGER IF EXISTS trg_inv_adj_items_updated_at ON public.inventory_adjustment_items;
CREATE TRIGGER trg_inv_adj_items_updated_at
BEFORE UPDATE ON public.inventory_adjustment_items
FOR EACH ROW EXECUTE FUNCTION public.zerpai_set_updated_at();

DROP TRIGGER IF EXISTS trg_inv_adj_item_batches_updated_at ON public.inventory_adjustment_item_batches;
CREATE TRIGGER trg_inv_adj_item_batches_updated_at
BEFORE UPDATE ON public.inventory_adjustment_item_batches
FOR EACH ROW EXECUTE FUNCTION public.zerpai_set_updated_at();

DROP TRIGGER IF EXISTS trg_inv_adj_value_items_updated_at ON public.inventory_adjustment_value_items;
CREATE TRIGGER trg_inv_adj_value_items_updated_at
BEFORE UPDATE ON public.inventory_adjustment_value_items
FOR EACH ROW EXECUTE FUNCTION public.zerpai_set_updated_at();

DROP TRIGGER IF EXISTS trg_inv_adj_acc_entries_updated_at ON public.inventory_adjustment_account_entries;
CREATE TRIGGER trg_inv_adj_acc_entries_updated_at
BEFORE UPDATE ON public.inventory_adjustment_account_entries
FOR EACH ROW EXECUTE FUNCTION public.zerpai_set_updated_at();

-- 10) Optional: stock auto-update hook from batch_transactions (for inventory adjustment sources)
CREATE OR REPLACE FUNCTION public.apply_inventory_adjustment_batch_txn()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  delta numeric;
  branch_row_id uuid;
  current_stock_val numeric;
  reserved_stock_val numeric;
  adjustment_exists boolean;
BEGIN
  IF NEW.ref_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT EXISTS(
    SELECT 1
    FROM public.inventory_adjustments
    WHERE id = NEW.ref_id
      AND entity_id = NEW.entity_id
  ) INTO adjustment_exists;

  -- Only process inventory adjustments and ignore other module writes.
  IF NOT adjustment_exists THEN
    RETURN NEW;
  END IF;

  delta := COALESCE(NEW.qty_in, 0) - COALESCE(NEW.qty_out, 0);

  -- Keep branch_inventory aligned for list-level stock visibility.
  SELECT id, current_stock, reserved_stock
    INTO branch_row_id, current_stock_val, reserved_stock_val
  FROM public.branch_inventory
  WHERE entity_id = NEW.entity_id
    AND product_id = NEW.product_id
  ORDER BY updated_at DESC
  LIMIT 1;

  IF branch_row_id IS NULL THEN
    INSERT INTO public.branch_inventory (
      entity_id, product_id, current_stock, reserved_stock, available_stock,
      min_stock_level, max_stock_level, last_stock_update, created_at, updated_at
    ) VALUES (
      NEW.entity_id, NEW.product_id, GREATEST(0, delta), 0, GREATEST(0, delta),
      0, 0, now(), now(), now()
    );
  ELSE
    UPDATE public.branch_inventory
    SET current_stock = GREATEST(0, COALESCE(current_stock_val, 0) + delta),
        available_stock = GREATEST(0, COALESCE(current_stock_val, 0) + delta - COALESCE(reserved_stock_val, 0)),
        last_stock_update = now(),
        updated_at = now()
    WHERE id = branch_row_id;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_apply_inventory_adjustment_batch_txn ON public.batch_transactions;
CREATE TRIGGER trg_apply_inventory_adjustment_batch_txn
AFTER INSERT ON public.batch_transactions
FOR EACH ROW EXECUTE FUNCTION public.apply_inventory_adjustment_batch_txn();
