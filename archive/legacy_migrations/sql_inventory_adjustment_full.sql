-- ============================================================
-- Zerpai ERP — Inventory Adjustments (ONLY REQUIRED TABLES)
-- Tables: public.inventory_adjustments, public.inventory_adjustment_items
-- Idempotent: safe to run multiple times
-- ============================================================

-- 1) ENUMS (used by inventory_adjustments)
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
  CREATE TYPE public.inventory_adjustment_type AS ENUM (
    'quantity',
    'value'
  );
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- 2) HEADER TABLE
CREATE TABLE IF NOT EXISTS public.inventory_adjustments (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id         uuid NOT NULL
                    REFERENCES public.organisation_branch_master(id)
                    ON DELETE RESTRICT,

  -- current backend compatibility (single-row fields still used)
  product_id        uuid REFERENCES public.products(id) ON DELETE RESTRICT,
  warehouse_id      uuid REFERENCES public.warehouses(id) ON DELETE SET NULL,

  adjustment_number varchar(100) UNIQUE,
  adjustment_date   timestamptz NOT NULL DEFAULT now(),
  adjustment_type   public.inventory_adjustment_type NOT NULL DEFAULT 'quantity',
  reason_id         uuid,
  reference_number  varchar(100),
  notes             text,
  account_id        uuid,
  status            public.inventory_adjustment_status NOT NULL DEFAULT 'draft',

  quantity_before   numeric(15,2),
  quantity_adjusted numeric(15,2),
  quantity_after    numeric(15,2),
  cost_price        numeric(15,2),
  adjustment_value  numeric(15,2),

  adjusted_by       uuid REFERENCES public.users(id) ON DELETE SET NULL,
  approved_by       uuid REFERENCES public.users(id) ON DELETE SET NULL,
  approved_at       timestamptz,

  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

-- Backfill/add-missing columns safely for existing environments
ALTER TABLE public.inventory_adjustments
  ADD COLUMN IF NOT EXISTS product_id uuid REFERENCES public.products(id) ON DELETE RESTRICT,
  ADD COLUMN IF NOT EXISTS warehouse_id uuid REFERENCES public.warehouses(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS adjustment_number varchar(100),
  ADD COLUMN IF NOT EXISTS adjustment_date timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS adjustment_type public.inventory_adjustment_type NOT NULL DEFAULT 'quantity',
  ADD COLUMN IF NOT EXISTS reason_id uuid,
  ADD COLUMN IF NOT EXISTS reference_number varchar(100),
  ADD COLUMN IF NOT EXISTS notes text,
  ADD COLUMN IF NOT EXISTS account_id uuid,
  ADD COLUMN IF NOT EXISTS status public.inventory_adjustment_status NOT NULL DEFAULT 'draft',
  ADD COLUMN IF NOT EXISTS quantity_before numeric(15,2),
  ADD COLUMN IF NOT EXISTS quantity_adjusted numeric(15,2),
  ADD COLUMN IF NOT EXISTS quantity_after numeric(15,2),
  ADD COLUMN IF NOT EXISTS cost_price numeric(15,2),
  ADD COLUMN IF NOT EXISTS adjustment_value numeric(15,2),
  ADD COLUMN IF NOT EXISTS adjusted_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS approved_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS approved_at timestamptz,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

CREATE UNIQUE INDEX IF NOT EXISTS ux_inventory_adjustments_adjustment_number
  ON public.inventory_adjustments(adjustment_number)
  WHERE adjustment_number IS NOT NULL;

-- 3) ITEM TABLE
CREATE TABLE IF NOT EXISTS public.inventory_adjustment_items (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adjustment_id     uuid NOT NULL
                    REFERENCES public.inventory_adjustments(id)
                    ON DELETE CASCADE,
  entity_id         uuid NOT NULL
                    REFERENCES public.organisation_branch_master(id)
                    ON DELETE RESTRICT,
  product_id        uuid NOT NULL
                    REFERENCES public.products(id)
                    ON DELETE RESTRICT,

  quantity_before   numeric(15,2) NOT NULL DEFAULT 0,
  quantity_adjusted numeric(15,2) NOT NULL DEFAULT 0,
  quantity_after    numeric(15,2) NOT NULL DEFAULT 0,
  cost_price        numeric(15,2),
  purchase_rate     numeric(15,2),
  mrp               numeric(15,2),
  adjustment_value  numeric(15,2) NOT NULL DEFAULT 0,

  batch_id          uuid REFERENCES public.batch_master(id) ON DELETE SET NULL,
  batch_reference   varchar(150),
  batch_allocations jsonb NOT NULL DEFAULT '[]'::jsonb,
  reporting_tags    jsonb NOT NULL DEFAULT '{}'::jsonb,
  mfd_month_year    varchar(7), -- MM/YYYY
  expiry_month_year varchar(7), -- MM/YYYY

  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.inventory_adjustment_items
  ADD COLUMN IF NOT EXISTS adjustment_id uuid REFERENCES public.inventory_adjustments(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS entity_id uuid REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT,
  ADD COLUMN IF NOT EXISTS product_id uuid REFERENCES public.products(id) ON DELETE RESTRICT,
  ADD COLUMN IF NOT EXISTS quantity_before numeric(15,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS quantity_adjusted numeric(15,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS quantity_after numeric(15,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS cost_price numeric(15,2),
  ADD COLUMN IF NOT EXISTS purchase_rate numeric(15,2),
  ADD COLUMN IF NOT EXISTS mrp numeric(15,2),
  ADD COLUMN IF NOT EXISTS adjustment_value numeric(15,2) NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS batch_id uuid REFERENCES public.batch_master(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS batch_reference varchar(150),
  ADD COLUMN IF NOT EXISTS batch_allocations jsonb NOT NULL DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS reporting_tags jsonb NOT NULL DEFAULT '{}'::jsonb,
  ADD COLUMN IF NOT EXISTS mfd_month_year varchar(7),
  ADD COLUMN IF NOT EXISTS expiry_month_year varchar(7),
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.inventory_adjustment_items
  ALTER COLUMN adjustment_id SET NOT NULL,
  ALTER COLUMN entity_id SET NOT NULL,
  ALTER COLUMN product_id SET NOT NULL;

-- 4) REASONS MASTER TABLE
CREATE TABLE IF NOT EXISTS public.inventory_adjustment_reasons (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id   uuid REFERENCES public.organisation_branch_master(id) ON DELETE CASCADE,
  name        varchar(200) NOT NULL,
  code        varchar(60),
  is_active   boolean NOT NULL DEFAULT true,
  sort_order  integer NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (entity_id, name)
);

ALTER TABLE public.inventory_adjustment_reasons
  ADD COLUMN IF NOT EXISTS entity_id uuid REFERENCES public.organisation_branch_master(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS name varchar(200),
  ADD COLUMN IF NOT EXISTS code varchar(60),
  ADD COLUMN IF NOT EXISTS is_active boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS sort_order integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.table_constraints
    WHERE constraint_schema = 'public'
      AND table_name = 'inventory_adjustments'
      AND constraint_name = 'fk_inventory_adjustments_reason_id'
  ) THEN
    ALTER TABLE public.inventory_adjustments
      ADD CONSTRAINT fk_inventory_adjustments_reason_id
      FOREIGN KEY (reason_id)
      REFERENCES public.inventory_adjustment_reasons(id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- Optional starter values (global defaults)
INSERT INTO public.inventory_adjustment_reasons (entity_id, name, code, sort_order)
VALUES
  (NULL, 'Damaged goods', 'DAMAGED', 10),
  (NULL, 'Stock Written off', 'WRITE_OFF', 20),
  (NULL, 'Stocktaking results', 'STOCKTAKE', 30),
  (NULL, 'Inventory Revaluation', 'REVALUE', 40)
ON CONFLICT (entity_id, name) DO NOTHING;

-- 5) ATTACHMENTS TABLE
CREATE TABLE IF NOT EXISTS public.inventory_adjustment_attachments (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  adjustment_id    uuid NOT NULL
                   REFERENCES public.inventory_adjustments(id)
                   ON DELETE CASCADE,
  entity_id        uuid NOT NULL
                   REFERENCES public.organisation_branch_master(id)
                   ON DELETE RESTRICT,
  file_name        varchar(255) NOT NULL,
  file_url         text NOT NULL,
  file_key         text,
  mime_type        varchar(120),
  file_size_bytes  bigint,
  uploaded_by      uuid REFERENCES public.users(id) ON DELETE SET NULL,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.inventory_adjustment_attachments
  ADD COLUMN IF NOT EXISTS adjustment_id uuid REFERENCES public.inventory_adjustments(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS entity_id uuid REFERENCES public.organisation_branch_master(id) ON DELETE RESTRICT,
  ADD COLUMN IF NOT EXISTS file_name varchar(255),
  ADD COLUMN IF NOT EXISTS file_url text,
  ADD COLUMN IF NOT EXISTS file_key text,
  ADD COLUMN IF NOT EXISTS mime_type varchar(120),
  ADD COLUMN IF NOT EXISTS file_size_bytes bigint,
  ADD COLUMN IF NOT EXISTS uploaded_by uuid REFERENCES public.users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE public.inventory_adjustment_attachments
  ALTER COLUMN adjustment_id SET NOT NULL,
  ALTER COLUMN entity_id SET NOT NULL,
  ALTER COLUMN file_name SET NOT NULL,
  ALTER COLUMN file_url SET NOT NULL;

-- 6) updated_at trigger helper
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_inventory_adjustments_updated_at ON public.inventory_adjustments;
CREATE TRIGGER trg_inventory_adjustments_updated_at
BEFORE UPDATE ON public.inventory_adjustments
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_inventory_adjustment_items_updated_at ON public.inventory_adjustment_items;
CREATE TRIGGER trg_inventory_adjustment_items_updated_at
BEFORE UPDATE ON public.inventory_adjustment_items
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_inventory_adjustment_reasons_updated_at ON public.inventory_adjustment_reasons;
CREATE TRIGGER trg_inventory_adjustment_reasons_updated_at
BEFORE UPDATE ON public.inventory_adjustment_reasons
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_inventory_adjustment_attachments_updated_at ON public.inventory_adjustment_attachments;
CREATE TRIGGER trg_inventory_adjustment_attachments_updated_at
BEFORE UPDATE ON public.inventory_adjustment_attachments
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 7) indexes
CREATE INDEX IF NOT EXISTS idx_inventory_adjustments_entity_date
  ON public.inventory_adjustments(entity_id, adjustment_date DESC);

CREATE INDEX IF NOT EXISTS idx_inventory_adjustments_entity_status
  ON public.inventory_adjustments(entity_id, status);

CREATE INDEX IF NOT EXISTS idx_inventory_adjustment_items_adjustment
  ON public.inventory_adjustment_items(adjustment_id);

CREATE INDEX IF NOT EXISTS idx_inventory_adjustment_items_product
  ON public.inventory_adjustment_items(product_id);

CREATE INDEX IF NOT EXISTS idx_inventory_adjustment_items_entity
  ON public.inventory_adjustment_items(entity_id);

CREATE INDEX IF NOT EXISTS idx_inventory_adjustment_reasons_entity_active
  ON public.inventory_adjustment_reasons(entity_id, is_active, sort_order);

CREATE INDEX IF NOT EXISTS idx_inventory_adjustment_attachments_adjustment
  ON public.inventory_adjustment_attachments(adjustment_id);

CREATE INDEX IF NOT EXISTS idx_inventory_adjustment_attachments_entity
  ON public.inventory_adjustment_attachments(entity_id);

-- 8) audit log function + triggers
CREATE OR REPLACE FUNCTION public.audit_inventory_adjustments_changes()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_entity_id uuid;
  v_record_id uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_entity_id := OLD.entity_id;
    v_record_id := OLD.id;
  ELSE
    v_entity_id := NEW.entity_id;
    v_record_id := NEW.id;
  END IF;

  INSERT INTO public.audit_logs (
    table_name,
    record_id,
    action,
    old_values,
    new_values,
    module_name,
    source,
    schema_name,
    record_pk,
    entity_id
  )
  VALUES (
    TG_TABLE_NAME,
    v_record_id,
    lower(TG_OP),
    CASE WHEN TG_OP = 'INSERT' THEN NULL ELSE to_jsonb(OLD) END,
    CASE WHEN TG_OP = 'DELETE' THEN NULL ELSE to_jsonb(NEW) END,
    'inventory_adjustments',
    'system',
    TG_TABLE_SCHEMA,
    v_record_id::text,
    v_entity_id
  );

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_inventory_adjustments ON public.inventory_adjustments;
CREATE TRIGGER trg_audit_inventory_adjustments
AFTER INSERT OR UPDATE OR DELETE ON public.inventory_adjustments
FOR EACH ROW EXECUTE FUNCTION public.audit_inventory_adjustments_changes();

DROP TRIGGER IF EXISTS trg_audit_inventory_adjustment_items ON public.inventory_adjustment_items;
CREATE TRIGGER trg_audit_inventory_adjustment_items
AFTER INSERT OR UPDATE OR DELETE ON public.inventory_adjustment_items
FOR EACH ROW EXECUTE FUNCTION public.audit_inventory_adjustments_changes();

DROP TRIGGER IF EXISTS trg_audit_inventory_adjustment_reasons ON public.inventory_adjustment_reasons;
CREATE TRIGGER trg_audit_inventory_adjustment_reasons
AFTER INSERT OR UPDATE OR DELETE ON public.inventory_adjustment_reasons
FOR EACH ROW EXECUTE FUNCTION public.audit_inventory_adjustments_changes();

DROP TRIGGER IF EXISTS trg_audit_inventory_adjustment_attachments ON public.inventory_adjustment_attachments;
CREATE TRIGGER trg_audit_inventory_adjustment_attachments
AFTER INSERT OR UPDATE OR DELETE ON public.inventory_adjustment_attachments
FOR EACH ROW EXECUTE FUNCTION public.audit_inventory_adjustments_changes();

-- 9) optional strict format checks for MM/YYYY fields
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'chk_inventory_adjustment_items_mfd_mm_yyyy'
  ) THEN
    ALTER TABLE public.inventory_adjustment_items
      ADD CONSTRAINT chk_inventory_adjustment_items_mfd_mm_yyyy
      CHECK (mfd_month_year IS NULL OR mfd_month_year ~ '^(0[1-9]|1[0-2])/[0-9]{4}$');
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'chk_inventory_adjustment_items_expiry_mm_yyyy'
  ) THEN
    ALTER TABLE public.inventory_adjustment_items
      ADD CONSTRAINT chk_inventory_adjustment_items_expiry_mm_yyyy
      CHECK (expiry_month_year IS NULL OR expiry_month_year ~ '^(0[1-9]|1[0-2])/[0-9]{4}$');
  END IF;
END $$;
