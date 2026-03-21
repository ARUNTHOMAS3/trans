-- Migration: settings_branding table
-- All settings-domain tables are prefixed with settings_

CREATE TABLE IF NOT EXISTS settings_branding (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id        UUID NOT NULL UNIQUE REFERENCES organization(id) ON DELETE CASCADE,
  accent_color  VARCHAR(7)  NOT NULL DEFAULT '#22A95E',  -- hex e.g. #22A95E
  theme_mode    VARCHAR(10) NOT NULL DEFAULT 'dark'
                  CHECK (theme_mode IN ('dark', 'light')),
  keep_branding BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS (service role bypasses this; anon/authenticated roles need explicit policies)
ALTER TABLE settings_branding ENABLE ROW LEVEL SECURITY;

-- Allow all operations — auth is handled at the NestJS middleware layer via org_id
CREATE POLICY "service_role_full_access" ON settings_branding
  USING (true) WITH CHECK (true);

-- Index for fast per-org lookup
CREATE INDEX IF NOT EXISTS idx_settings_branding_org_id
  ON settings_branding (org_id);

-- Auto-update updated_at on every row change
CREATE OR REPLACE FUNCTION update_settings_branding_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_settings_branding_updated_at ON settings_branding;
CREATE TRIGGER trg_settings_branding_updated_at
  BEFORE UPDATE ON settings_branding
  FOR EACH ROW EXECUTE FUNCTION update_settings_branding_updated_at();

-- Grant access to Supabase roles (service_role bypasses RLS but still needs table grants)
GRANT ALL ON public.settings_branding TO service_role;
GRANT ALL ON public.settings_branding TO authenticated;
GRANT ALL ON public.settings_branding TO anon;
