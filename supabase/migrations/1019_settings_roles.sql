CREATE TABLE IF NOT EXISTS public.settings_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL REFERENCES public.organization(id) ON DELETE CASCADE,
  label VARCHAR(100) NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  permissions JSONB NOT NULL DEFAULT '{}',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_settings_roles_org_id
  ON public.settings_roles (org_id);

CREATE OR REPLACE FUNCTION public.update_settings_roles_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_settings_roles_updated_at
  ON public.settings_roles;

CREATE TRIGGER trg_settings_roles_updated_at
  BEFORE UPDATE ON public.settings_roles
  FOR EACH ROW
  EXECUTE FUNCTION public.update_settings_roles_updated_at();

ALTER TABLE public.settings_roles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "service_role_full_access" ON public.settings_roles;

CREATE POLICY "service_role_full_access" ON public.settings_roles
  USING (true) WITH CHECK (true);

GRANT ALL ON public.settings_roles TO service_role;
GRANT ALL ON public.settings_roles TO authenticated;
GRANT ALL ON public.settings_roles TO anon;
