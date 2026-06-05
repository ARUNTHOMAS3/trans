BEGIN;

CREATE TABLE IF NOT EXISTS public.transfer_order_master (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_no varchar(50) NOT NULL,
  transfer_date date NOT NULL,
  entity_id uuid NOT NULL,
  source_warehouse_id uuid NOT NULL,
  destination_warehouse_id uuid NOT NULL,
  status varchar(30) NOT NULL DEFAULT 'DRAFT',
  reason text,
  created_by uuid,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT transfer_order_master_status_chk CHECK (
    status IN ('DRAFT', 'INITIATED', 'RECEIVED', 'CANCELLED')
  ),
  CONSTRAINT transfer_order_master_source_dest_diff_chk CHECK (
    source_warehouse_id <> destination_warehouse_id
  ),
  CONSTRAINT transfer_order_master_entity_fkey
    FOREIGN KEY (entity_id) REFERENCES public.organisation_branch_master(id),
  CONSTRAINT transfer_order_master_source_wh_fkey
    FOREIGN KEY (source_warehouse_id) REFERENCES public.warehouses(id),
  CONSTRAINT transfer_order_master_destination_wh_fkey
    FOREIGN KEY (destination_warehouse_id) REFERENCES public.warehouses(id)
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_transfer_order_master_entity_transfer_no
  ON public.transfer_order_master(entity_id, transfer_no);

CREATE INDEX IF NOT EXISTS idx_transfer_order_master_entity_date_status
  ON public.transfer_order_master(entity_id, transfer_date DESC, status);

CREATE TABLE IF NOT EXISTS public.transfer_order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_order_id uuid NOT NULL,
  product_id uuid NOT NULL,
  qty_requested numeric(15,3) NOT NULL,
  qty_transferred numeric(15,3) NOT NULL DEFAULT 0,
  unit varchar(20),
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT transfer_order_items_transfer_order_fkey
    FOREIGN KEY (transfer_order_id) REFERENCES public.transfer_order_master(id)
    ON DELETE CASCADE,
  CONSTRAINT transfer_order_items_product_fkey
    FOREIGN KEY (product_id) REFERENCES public.products(id),
  CONSTRAINT transfer_order_items_qty_requested_chk CHECK (qty_requested > 0),
  CONSTRAINT transfer_order_items_qty_transferred_chk CHECK (qty_transferred >= 0)
);

CREATE INDEX IF NOT EXISTS idx_transfer_order_items_order_product
  ON public.transfer_order_items(transfer_order_id, product_id);

CREATE TABLE IF NOT EXISTS public.transfer_order_source_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_item_id uuid NOT NULL,
  batch_id uuid NOT NULL,
  layer_id uuid NOT NULL,
  warehouse_id uuid NOT NULL,
  bin_id uuid NOT NULL,
  qty numeric(15,3) NOT NULL,
  CONSTRAINT transfer_order_source_batches_item_fkey
    FOREIGN KEY (transfer_item_id) REFERENCES public.transfer_order_items(id)
    ON DELETE CASCADE,
  CONSTRAINT transfer_order_source_batches_batch_fkey
    FOREIGN KEY (batch_id) REFERENCES public.batch_master(id),
  CONSTRAINT transfer_order_source_batches_layer_fkey
    FOREIGN KEY (layer_id) REFERENCES public.batch_stock_layers(id),
  CONSTRAINT transfer_order_source_batches_wh_fkey
    FOREIGN KEY (warehouse_id) REFERENCES public.warehouses(id),
  CONSTRAINT transfer_order_source_batches_bin_fkey
    FOREIGN KEY (bin_id) REFERENCES public.bin_master(id),
  CONSTRAINT transfer_order_source_batches_qty_chk CHECK (qty > 0)
);

CREATE INDEX IF NOT EXISTS idx_transfer_order_source_batches_item
  ON public.transfer_order_source_batches(transfer_item_id);

CREATE INDEX IF NOT EXISTS idx_transfer_order_source_batches_layer
  ON public.transfer_order_source_batches(layer_id);

CREATE TABLE IF NOT EXISTS public.transfer_order_destination_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_item_id uuid NOT NULL,
  source_batch_id uuid NOT NULL,
  destination_batch_id uuid NOT NULL,
  destination_warehouse_id uuid NOT NULL,
  destination_bin_id uuid NOT NULL,
  qty numeric(15,3) NOT NULL,
  CONSTRAINT transfer_order_destination_batches_item_fkey
    FOREIGN KEY (transfer_item_id) REFERENCES public.transfer_order_items(id)
    ON DELETE CASCADE,
  CONSTRAINT transfer_order_destination_batches_source_batch_fkey
    FOREIGN KEY (source_batch_id) REFERENCES public.batch_master(id),
  CONSTRAINT transfer_order_destination_batches_destination_batch_fkey
    FOREIGN KEY (destination_batch_id) REFERENCES public.batch_master(id),
  CONSTRAINT transfer_order_destination_batches_wh_fkey
    FOREIGN KEY (destination_warehouse_id) REFERENCES public.warehouses(id),
  CONSTRAINT transfer_order_destination_batches_bin_fkey
    FOREIGN KEY (destination_bin_id) REFERENCES public.bin_master(id),
  CONSTRAINT transfer_order_destination_batches_qty_chk CHECK (qty > 0)
);

CREATE INDEX IF NOT EXISTS idx_transfer_order_destination_batches_item
  ON public.transfer_order_destination_batches(transfer_item_id);

CREATE TABLE IF NOT EXISTS public.transfer_order_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_order_id uuid NOT NULL,
  action varchar(50) NOT NULL,
  action_by uuid,
  action_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT transfer_order_logs_transfer_order_fkey
    FOREIGN KEY (transfer_order_id) REFERENCES public.transfer_order_master(id)
    ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_transfer_order_logs_order_time
  ON public.transfer_order_logs(transfer_order_id, action_at DESC);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'ux_batch_stock_layers_unique_layer_key'
  ) THEN
    ALTER TABLE public.batch_stock_layers
      ADD CONSTRAINT ux_batch_stock_layers_unique_layer_key
      UNIQUE (batch_id, product_id, entity_id, warehouse_id, bin_id);
  END IF;
END $$;

COMMIT;

