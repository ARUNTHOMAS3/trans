ALTER TABLE public.organization
  ADD COLUMN IF NOT EXISTS organization_language character varying(50) NULL DEFAULT 'English',
  ADD COLUMN IF NOT EXISTS communication_languages text[] NOT NULL DEFAULT ARRAY['English']::text[];

UPDATE public.organization
SET
  organization_language = COALESCE(NULLIF(organization_language, ''), 'English'),
  communication_languages = CASE
    WHEN communication_languages IS NULL OR cardinality(communication_languages) = 0
      THEN ARRAY['English']::text[]
    ELSE communication_languages
  END,
  updated_at = now()
WHERE organization_language IS NULL
   OR organization_language = ''
   OR communication_languages IS NULL
   OR cardinality(communication_languages) = 0;
