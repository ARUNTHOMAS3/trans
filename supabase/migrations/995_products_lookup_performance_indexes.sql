BEGIN;

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX IF NOT EXISTS idx_manufacturers_active_name
ON public.manufacturers (is_active, name);

CREATE INDEX IF NOT EXISTS idx_brands_active_name
ON public.brands (is_active, name);

CREATE INDEX IF NOT EXISTS idx_vendors_active_display_name
ON public.vendors (is_active, display_name);

CREATE INDEX IF NOT EXISTS idx_accounts_active_system_name
ON public.accounts (is_active, system_account_name);

CREATE INDEX IF NOT EXISTS idx_accounts_active_user_name
ON public.accounts (is_active, user_account_name);

CREATE INDEX IF NOT EXISTS idx_storage_locations_active_name
ON public.storage_locations (is_active, location_name);

CREATE INDEX IF NOT EXISTS idx_racks_active_code
ON public.racks (is_active, rack_code);

CREATE INDEX IF NOT EXISTS idx_reorder_terms_active_name
ON public.reorder_terms (is_active, term_name);

CREATE INDEX IF NOT EXISTS idx_categories_active_name
ON public.categories (is_active, name);

CREATE INDEX IF NOT EXISTS idx_contents_active_name
ON public.contents (is_active, content_name);

CREATE INDEX IF NOT EXISTS idx_strengths_active_name
ON public.strengths (is_active, strength_name);

CREATE INDEX IF NOT EXISTS idx_buying_rules_active_name
ON public.buying_rules (is_active, buying_rule);

CREATE INDEX IF NOT EXISTS idx_schedules_active_name
ON public.schedules (is_active, shedule_name);

CREATE INDEX IF NOT EXISTS idx_manufacturers_name_trgm
ON public.manufacturers
USING gin (lower(name) gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_brands_name_trgm
ON public.brands
USING gin (lower(name) gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_vendors_display_name_trgm
ON public.vendors
USING gin (lower(display_name) gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_accounts_lookup_name_trgm
ON public.accounts
USING gin (lower(COALESCE(user_account_name, system_account_name)) gin_trgm_ops);

COMMIT;
