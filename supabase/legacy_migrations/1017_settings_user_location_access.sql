CREATE TABLE IF NOT EXISTS public.settings_user_location_access (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES public.organization(id) ON DELETE CASCADE,
  user_id UUID NOT NULL,
  outlet_id UUID NOT NULL,
  is_default_business BOOLEAN NOT NULL DEFAULT FALSE,
  is_default_warehouse BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT settings_user_location_access_unique
    UNIQUE (org_id, user_id, outlet_id)
);

CREATE INDEX IF NOT EXISTS idx_settings_user_location_access_org_user
  ON public.settings_user_location_access (org_id, user_id);

CREATE INDEX IF NOT EXISTS idx_settings_user_location_access_outlet
  ON public.settings_user_location_access (outlet_id);

CREATE OR REPLACE FUNCTION public.update_settings_user_location_access_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_settings_user_location_access_updated_at
  ON public.settings_user_location_access;

CREATE TRIGGER trg_settings_user_location_access_updated_at
  BEFORE UPDATE ON public.settings_user_location_access
  FOR EACH ROW
  EXECUTE FUNCTION public.update_settings_user_location_access_updated_at();

ALTER TABLE public.settings_user_location_access ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_role_full_access" ON public.settings_user_location_access;

CREATE POLICY "service_role_full_access" ON public.settings_user_location_access
  USING (true) WITH CHECK (true);

GRANT ALL ON public.settings_user_location_access TO service_role;
GRANT ALL ON public.settings_user_location_access TO authenticated;
GRANT ALL ON public.settings_user_location_access TO anon;
