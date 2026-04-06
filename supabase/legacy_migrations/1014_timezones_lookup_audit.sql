-- TODO(geo-master-data): We are only expanding production-facing country/state
-- coverage for India right now. Seed non-India states/provinces in a separate
-- additive migration later, once the required country rollout is approved.
-- Do not mix that future global state seed with this timezone hardening
-- migration.

CREATE TABLE IF NOT EXISTS public.timezones (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name character varying(150) NOT NULL,
  tzdb_name character varying(100) NOT NULL,
  utc_offset character varying(10) NOT NULL,
  display character varying(255) NOT NULL,
  country_id uuid NULL,
  is_active boolean NOT NULL DEFAULT true,
  sort_order smallint NOT NULL DEFAULT 0,
  CONSTRAINT timezones_pkey PRIMARY KEY (id)
);

ALTER TABLE public.timezones
  ALTER COLUMN name TYPE character varying(150),
  ALTER COLUMN name SET NOT NULL,
  ALTER COLUMN tzdb_name TYPE character varying(100),
  ALTER COLUMN tzdb_name SET NOT NULL,
  ALTER COLUMN utc_offset TYPE character varying(10),
  ALTER COLUMN utc_offset SET NOT NULL,
  ALTER COLUMN display TYPE character varying(255),
  ALTER COLUMN display SET NOT NULL,
  ALTER COLUMN is_active SET DEFAULT true,
  ALTER COLUMN is_active SET NOT NULL,
  ALTER COLUMN sort_order SET DEFAULT 0,
  ALTER COLUMN sort_order SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'timezones_name_key'
      AND conrelid = 'public.timezones'::regclass
  ) THEN
    ALTER TABLE public.timezones
      ADD CONSTRAINT timezones_name_key UNIQUE (name);
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'timezones_country_id_fkey'
      AND conrelid = 'public.timezones'::regclass
  ) THEN
    ALTER TABLE public.timezones
      ADD CONSTRAINT timezones_country_id_fkey
      FOREIGN KEY (country_id)
      REFERENCES public.countries (id)
      ON DELETE SET NULL;
  END IF;
END $$;

DROP TRIGGER IF EXISTS trg_audit_row ON public.timezones;
CREATE TRIGGER trg_audit_row
AFTER INSERT OR DELETE OR UPDATE ON public.timezones
FOR EACH ROW
EXECUTE FUNCTION audit_row_changes();

DROP TRIGGER IF EXISTS trg_audit_truncate ON public.timezones;
CREATE TRIGGER trg_audit_truncate
AFTER TRUNCATE ON public.timezones
FOR EACH STATEMENT
EXECUTE FUNCTION audit_table_truncate();

GRANT SELECT ON TABLE public.timezones TO anon, authenticated, service_role;
