-- Move Orders backend tables
-- Date: 2026-05-09

CREATE TABLE IF NOT EXISTS public.inventory_move_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id uuid NOT NULL REFERENCES public.organisation_branch_master(id),
  warehouse_id uuid NOT NULL REFERENCES public.warehouses(id),
  move_order_number varchar(50) NOT NULL UNIQUE,
  move_date timestamp NOT NULL,
  assignee_id uuid NULL REFERENCES public.users(id),
  notes text NULL,
  status varchar(30) NOT NULL DEFAULT 'draft',
  created_by uuid NULL REFERENCES public.users(id),
  completed_by uuid NULL REFERENCES public.users(id),
  completed_at timestamp NULL,
  created_at timestamp NOT NULL DEFAULT now(),
  updated_at timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.inventory_move_order_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  move_order_id uuid NOT NULL REFERENCES public.inventory_move_orders(id) ON DELETE CASCADE,
  product_id uuid NOT NULL REFERENCES public.products(id),
  qty numeric(18,4) NOT NULL,
  remarks text NULL,
  created_at timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.inventory_move_order_source_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  move_order_item_id uuid NOT NULL REFERENCES public.inventory_move_order_items(id) ON DELETE CASCADE,
  source_layer_id uuid NOT NULL REFERENCES public.batch_stock_layers(id),
  batch_id uuid NOT NULL REFERENCES public.batch_master(id),
  source_bin_id uuid NOT NULL REFERENCES public.bin_master(id),
  qty_out numeric(18,4) NOT NULL,
  created_at timestamp NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.inventory_move_order_destination_bins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_batch_row_id uuid NOT NULL REFERENCES public.inventory_move_order_source_batches(id) ON DELETE CASCADE,
  destination_bin_id uuid NOT NULL REFERENCES public.bin_master(id),
  qty_in numeric(18,4) NOT NULL,
  created_at timestamp NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_inventory_move_orders_entity_date
  ON public.inventory_move_orders(entity_id, move_date DESC);

CREATE INDEX IF NOT EXISTS idx_inventory_move_order_items_order
  ON public.inventory_move_order_items(move_order_id);

CREATE INDEX IF NOT EXISTS idx_inventory_move_order_source_item
  ON public.inventory_move_order_source_batches(move_order_item_id);

CREATE INDEX IF NOT EXISTS idx_inventory_move_order_destination_source
  ON public.inventory_move_order_destination_bins(source_batch_row_id);

