-- Migration: outlets + settings_locations tables
-- outlets: core location/branch data per org
-- settings_locations: location-specific configuration (1:1 with outlets)

-- ── outlets ──────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS outlets (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id       UUID        NOT NULL REFERENCES organization(id) ON DELETE CASCADE,
  name         VARCHAR(255) NOT NULL,
  outlet_code  VARCHAR(50)  NOT NULL,
  gstin        VARCHAR(50),
  email        VARCHAR(255),
  phone        VARCHAR(50),
  address      TEXT,
  city         VARCHAR(100),
  state        VARCHAR(100),
  country      VARCHAR(100),
  pincode      VARCHAR(20),
  is_active    BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE outlets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_full_access" ON outlets
  USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_outlets_org_id ON outlets (org_id);

CREATE OR REPLACE FUNCTION update_outlets_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_outlets_updated_at ON outlets;
CREATE TRIGGER trg_outlets_updated_at
  BEFORE UPDATE ON outlets
  FOR EACH ROW EXECUTE FUNCTION update_outlets_updated_at();

GRANT ALL ON public.outlets TO service_role;
GRANT ALL ON public.outlets TO authenticated;
GRANT ALL ON public.outlets TO anon;

-- ── settings_locations ────────────────────────────────────────────────────────

DO $$ BEGIN
  CREATE TYPE location_type AS ENUM ('business', 'warehouse');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS settings_locations (
  id                UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  outlet_id         UUID          NOT NULL UNIQUE REFERENCES outlets(id) ON DELETE CASCADE,
  org_id            UUID          NOT NULL REFERENCES organization(id) ON DELETE CASCADE,
  location_type     location_type NOT NULL DEFAULT 'business',
  is_primary        BOOLEAN       NOT NULL DEFAULT FALSE,
  parent_outlet_id  UUID          REFERENCES outlets(id) ON DELETE SET NULL,
  logo_url          TEXT,
  created_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

ALTER TABLE settings_locations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "service_role_full_access" ON settings_locations
  USING (true) WITH CHECK (true);

CREATE INDEX IF NOT EXISTS idx_settings_locations_org_id    ON settings_locations (org_id);
CREATE INDEX IF NOT EXISTS idx_settings_locations_outlet_id ON settings_locations (outlet_id);

CREATE OR REPLACE FUNCTION update_settings_locations_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_settings_locations_updated_at ON settings_locations;
CREATE TRIGGER trg_settings_locations_updated_at
  BEFORE UPDATE ON settings_locations
  FOR EACH ROW EXECUTE FUNCTION update_settings_locations_updated_at();

GRANT ALL ON public.settings_locations TO service_role;
GRANT ALL ON public.settings_locations TO authenticated;
GRANT ALL ON public.settings_locations TO anon;
