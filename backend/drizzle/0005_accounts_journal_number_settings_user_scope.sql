-- Scope journal number settings by user/org/outlet to avoid cross-account overrides.

ALTER TABLE public.accounts_journal_number_settings
  ADD COLUMN IF NOT EXISTS user_id uuid;

-- Remove duplicate rows for same scope before adding uniqueness.
WITH ranked AS (
  SELECT
    ctid,
    ROW_NUMBER() OVER (
      PARTITION BY
        org_id,
        COALESCE(outlet_id, '00000000-0000-0000-0000-000000000000'::uuid),
        COALESCE(user_id, '00000000-0000-0000-0000-000000000000'::uuid)
      ORDER BY id DESC
    ) AS rn
  FROM public.accounts_journal_number_settings
)
DELETE FROM public.accounts_journal_number_settings AS t
USING ranked AS r
WHERE t.ctid = r.ctid
  AND r.rn > 1;

CREATE UNIQUE INDEX IF NOT EXISTS accounts_journal_number_settings_scope_uq
ON public.accounts_journal_number_settings (
  org_id,
  COALESCE(outlet_id, '00000000-0000-0000-0000-000000000000'::uuid),
  COALESCE(user_id, '00000000-0000-0000-0000-000000000000'::uuid)
);
