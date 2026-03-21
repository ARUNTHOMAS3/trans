-- ─────────────────────────────────────────────
-- Organization system ID
-- Add a user-facing numeric system ID separate from the UUID primary key.
-- ─────────────────────────────────────────────

CREATE SEQUENCE IF NOT EXISTS public.organization_system_id_seq
  START WITH 60000000000
  INCREMENT BY 1;

ALTER TABLE public.organization
  ADD COLUMN IF NOT EXISTS system_id VARCHAR(20);

ALTER TABLE public.organization
  ALTER COLUMN system_id SET DEFAULT nextval('public.organization_system_id_seq')::text;

UPDATE public.organization
SET system_id = nextval('public.organization_system_id_seq')::text
WHERE system_id IS NULL OR btrim(system_id) = '';

SELECT setval(
  'public.organization_system_id_seq',
  GREATEST(
    COALESCE(
      (SELECT MAX(system_id::bigint) FROM public.organization WHERE system_id ~ '^\d+$'),
      60000000000
    ),
    60000000000
  ),
  true
);

ALTER TABLE public.organization
  ALTER COLUMN system_id SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS organization_system_id_key
  ON public.organization(system_id);
