-- Migration: Inventory Adjustment Batch Linking Fixes
-- Date: 2026-05-02
-- IMPORTANT: Run manually in your DB environment. This file is NOT auto-executed.

BEGIN;

-- 1) Add missing link to stock layer used by approval posting flow.
ALTER TABLE public.inventory_adjustment_item_batches
  ADD COLUMN IF NOT EXISTS batch_stock_layer_id uuid;

-- 2) Add FK for bin_id (schema currently has bin_id column but no FK).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'inventory_adjustment_item_batches_bin_id_fkey'
  ) THEN
    ALTER TABLE public.inventory_adjustment_item_batches
      ADD CONSTRAINT inventory_adjustment_item_batches_bin_id_fkey
      FOREIGN KEY (bin_id) REFERENCES public.bin_master(id);
  END IF;
END $$;

-- 3) Add FK for batch_stock_layer_id.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'inventory_adjustment_item_batches_batch_stock_layer_id_fkey'
  ) THEN
    ALTER TABLE public.inventory_adjustment_item_batches
      ADD CONSTRAINT inventory_adjustment_item_batches_batch_stock_layer_id_fkey
      FOREIGN KEY (batch_stock_layer_id) REFERENCES public.batch_stock_layers(id);
  END IF;
END $$;

-- 4) Helpful indexes for joins/lookups.
CREATE INDEX IF NOT EXISTS idx_iab_adjustment_id
  ON public.inventory_adjustment_item_batches(adjustment_id);

CREATE INDEX IF NOT EXISTS idx_iab_adjustment_item_id
  ON public.inventory_adjustment_item_batches(adjustment_item_id);

CREATE INDEX IF NOT EXISTS idx_iab_batch_id
  ON public.inventory_adjustment_item_batches(batch_id);

CREATE INDEX IF NOT EXISTS idx_iab_bin_id
  ON public.inventory_adjustment_item_batches(bin_id);

CREATE INDEX IF NOT EXISTS idx_iab_batch_stock_layer_id
  ON public.inventory_adjustment_item_batches(batch_stock_layer_id);

COMMIT;
