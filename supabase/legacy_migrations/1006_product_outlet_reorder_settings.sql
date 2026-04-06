BEGIN;

ALTER TABLE IF EXISTS public.reorder_terms
  ADD COLUMN IF NOT EXISTS org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid;

ALTER TABLE IF EXISTS public.reorder_terms
  ADD COLUMN IF NOT EXISTS outlet_id uuid;

ALTER TABLE IF EXISTS public.reorder_terms
  ADD COLUMN IF NOT EXISTS quantity integer NOT NULL DEFAULT 1;

ALTER TABLE IF EXISTS public.reorder_terms
  ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone NOT NULL DEFAULT now();

ALTER TABLE IF EXISTS public.reorder_terms
  ALTER COLUMN quantity SET DEFAULT 1;

ALTER TABLE IF EXISTS public.reorder_terms
  DROP CONSTRAINT IF EXISTS reorder_terms_term_name_unique;

DROP INDEX IF EXISTS public.reorder_terms_term_name_unique;
DROP INDEX IF EXISTS public.idx_reorder_terms_org_outlet_term_name;
DROP INDEX IF EXISTS public.idx_reorder_terms_org_term_name_global;

CREATE UNIQUE INDEX IF NOT EXISTS idx_reorder_terms_org_outlet_term_name
  ON public.reorder_terms (org_id, outlet_id, lower(term_name))
  WHERE outlet_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_reorder_terms_org_term_name_global
  ON public.reorder_terms (org_id, lower(term_name))
  WHERE outlet_id IS NULL;

CREATE TABLE IF NOT EXISTS public.product_outlet_inventory_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  org_id uuid NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000'::uuid,
  outlet_id uuid,
  product_id uuid NOT NULL,
  reorder_point integer NOT NULL DEFAULT 0,
  reorder_term_id uuid,
  is_active boolean NOT NULL DEFAULT true,
  created_by_id uuid,
  updated_by_id uuid,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT product_outlet_inventory_settings_pkey PRIMARY KEY (id),
  CONSTRAINT product_outlet_inventory_settings_product_fkey
    FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE,
  CONSTRAINT product_outlet_inventory_settings_reorder_term_fkey
    FOREIGN KEY (reorder_term_id) REFERENCES public.reorder_terms(id) ON DELETE SET NULL,
  CONSTRAINT product_outlet_inventory_settings_reorder_point_check
    CHECK (reorder_point >= 0)
);

CREATE INDEX IF NOT EXISTS idx_product_outlet_inventory_settings_product
  ON public.product_outlet_inventory_settings (product_id);

CREATE INDEX IF NOT EXISTS idx_product_outlet_inventory_settings_org_outlet
  ON public.product_outlet_inventory_settings (org_id, outlet_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_product_outlet_inventory_settings_outlet_product
  ON public.product_outlet_inventory_settings (outlet_id, product_id)
  WHERE outlet_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_product_outlet_inventory_settings_org_product_global
  ON public.product_outlet_inventory_settings (org_id, product_id)
  WHERE outlet_id IS NULL;

INSERT INTO public.product_outlet_inventory_settings (
  org_id,
  outlet_id,
  product_id,
  reorder_point,
  reorder_term_id,
  is_active,
  created_at,
  updated_at
)
SELECT
  '00000000-0000-0000-0000-000000000000'::uuid,
  oi.outlet_id,
  p.id,
  COALESCE(p.reorder_point, 0),
  p.reorder_term_id,
  true,
  now(),
  now()
FROM public.products p
JOIN (
  SELECT DISTINCT product_id, outlet_id
  FROM public.outlet_inventory
  WHERE outlet_id IS NOT NULL
) oi
  ON oi.product_id = p.id
WHERE COALESCE(p.reorder_point, 0) > 0
   OR p.reorder_term_id IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO public.product_outlet_inventory_settings (
  org_id,
  outlet_id,
  product_id,
  reorder_point,
  reorder_term_id,
  is_active,
  created_at,
  updated_at
)
SELECT
  '00000000-0000-0000-0000-000000000000'::uuid,
  NULL,
  p.id,
  COALESCE(p.reorder_point, 0),
  p.reorder_term_id,
  true,
  now(),
  now()
FROM public.products p
WHERE (COALESCE(p.reorder_point, 0) > 0 OR p.reorder_term_id IS NOT NULL)
  AND NOT EXISTS (
    SELECT 1
    FROM public.outlet_inventory oi
    WHERE oi.product_id = p.id
      AND oi.outlet_id IS NOT NULL
  )
ON CONFLICT DO NOTHING;

DROP TRIGGER IF EXISTS trg_audit_row ON public.product_outlet_inventory_settings;
CREATE TRIGGER trg_audit_row
AFTER INSERT OR DELETE OR UPDATE ON public.product_outlet_inventory_settings
FOR EACH ROW
EXECUTE FUNCTION audit_row_changes();

DROP TRIGGER IF EXISTS trg_audit_truncate ON public.product_outlet_inventory_settings;
CREATE TRIGGER trg_audit_truncate
AFTER TRUNCATE ON public.product_outlet_inventory_settings
FOR EACH STATEMENT
EXECUTE FUNCTION audit_table_truncate();

COMMIT;
