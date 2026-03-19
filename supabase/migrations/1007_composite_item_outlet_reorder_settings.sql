BEGIN;

CREATE TABLE IF NOT EXISTS public.composite_item_outlet_inventory_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  composite_item_id uuid NOT NULL,
  reorder_point integer NOT NULL DEFAULT 0,
  reorder_term_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  created_by_id uuid,
  updated_by_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT composite_item_outlet_inventory_settings_pkey PRIMARY KEY (id),
  CONSTRAINT composite_item_outlet_inventory_settings_composite_item_fkey
    FOREIGN KEY (composite_item_id) REFERENCES public.composite_items(id) ON DELETE CASCADE,
  CONSTRAINT composite_item_outlet_inventory_settings_reorder_term_fkey
    FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id) ON DELETE SET NULL,
  CONSTRAINT composite_item_outlet_inventory_settings_reorder_point_check
    CHECK (reorder_point >= 0)
);

CREATE INDEX IF NOT EXISTS idx_composite_item_outlet_inventory_settings_item
  ON public.composite_item_outlet_inventory_settings (composite_item_id);

CREATE INDEX IF NOT EXISTS idx_composite_item_outlet_inventory_settings_org_outlet
  ON public.composite_item_outlet_inventory_settings (org_id, outlet_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_composite_item_outlet_inventory_settings_outlet_item
  ON public.composite_item_outlet_inventory_settings (outlet_id, composite_item_id)
  WHERE outlet_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_composite_item_outlet_inventory_settings_org_item_global
  ON public.composite_item_outlet_inventory_settings (org_id, composite_item_id)
  WHERE outlet_id IS NULL;

INSERT INTO public.composite_item_outlet_inventory_settings (
  org_id,
  outlet_id,
  composite_item_id,
  reorder_point,
  reorder_term_id,
  is_active,
  created_at,
  updated_at
)
SELECT
  '00000000-0000-0000-0000-000000000000'::uuid,
  NULL,
  ci.id,
  COALESCE(ci.reorder_point, 0),
  ci.reorder_term_id,
  true,
  now(),
  now()
FROM public.composite_items ci
WHERE COALESCE(ci.reorder_point, 0) > 0
   OR ci.reorder_term_id IS NOT NULL
ON CONFLICT DO NOTHING;

DROP TRIGGER IF EXISTS trg_audit_row ON public.composite_item_outlet_inventory_settings;
CREATE TRIGGER trg_audit_row
AFTER INSERT OR DELETE OR UPDATE ON public.composite_item_outlet_inventory_settings
FOR EACH ROW
EXECUTE FUNCTION audit_row_changes();

DROP TRIGGER IF EXISTS trg_audit_truncate ON public.composite_item_outlet_inventory_settings;
CREATE TRIGGER trg_audit_truncate
AFTER TRUNCATE ON public.composite_item_outlet_inventory_settings
FOR EACH STATEMENT
EXECUTE FUNCTION audit_table_truncate();

COMMIT;
