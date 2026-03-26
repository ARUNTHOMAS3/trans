CREATE TABLE IF NOT EXISTS settings_branch_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES organization(id) ON DELETE CASCADE,
  business_type VARCHAR(20) NOT NULL,
  description TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT settings_branch_types_org_business_type_unique
    UNIQUE (org_id, business_type)
);

CREATE INDEX IF NOT EXISTS idx_settings_branch_types_org_id
  ON settings_branch_types (org_id);

CREATE OR REPLACE FUNCTION update_settings_branch_types_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_settings_branch_types_updated_at
  ON settings_branch_types;

CREATE TRIGGER trg_settings_branch_types_updated_at
  BEFORE UPDATE ON settings_branch_types
  FOR EACH ROW
  EXECUTE FUNCTION update_settings_branch_types_updated_at();

ALTER TABLE settings_branches
  DROP CONSTRAINT IF EXISTS settings_branches_branch_type_check;

UPDATE settings_branches
SET branch_type = UPPER(branch_type)
WHERE branch_type IS NOT NULL;

GRANT ALL ON public.settings_branch_types TO service_role;
GRANT ALL ON public.settings_branch_types TO authenticated;
GRANT ALL ON public.settings_branch_types TO anon;
