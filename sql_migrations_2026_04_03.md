-- ==========================================
-- ZERPAI ERP: ENTERPRISE SETTINGS & ACCOUNTS MIGRATION
-- DATE: 2026-04-03 (Revision 2)
-- MODULES: Settings, Accounts, Hierarchy, RBAC
-- ==========================================

-- 1. ENUMS & TYPES
DO $$ BEGIN
    -- FOCO: Franchise Owned Company Operated
    -- COCO: Company Owned Company Operated
    -- FICO: Franchise Invested Company Operated
    -- FOFO: Franchise Owned Franchise Operated
    CREATE TYPE public.branch_type AS ENUM ('FOCO', 'COCO', 'FICO', 'FOFO', 'WAREHOUSE');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. HIERARCHY MASTERS (LSGD - Kerala)
CREATE TABLE IF NOT EXISTS public.settings_districts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    state_id uuid NOT NULL, -- FK to public.states
    name character varying NOT NULL,
    code character varying,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.settings_local_bodies (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    district_id uuid NOT NULL REFERENCES public.settings_districts(id),
    name character varying NOT NULL,
    code character varying,
    body_type character varying NOT NULL CHECK (body_type::text = ANY (ARRAY['grama_panchayat'::character varying, 'municipality'::character varying, 'corporation'::character varying]::text[])),
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.settings_wards (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    local_body_id uuid NOT NULL REFERENCES public.settings_local_bodies(id),
    ward_no integer,
    name character varying NOT NULL,
    code character varying,
    is_active boolean NOT NULL DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);

-- Seeding table for bulk LSGD data imports
CREATE TABLE IF NOT EXISTS public.settings_lsgd_seed_stage (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    state_name character varying NOT NULL,
    district_name character varying NOT NULL,
    local_body_type character varying NOT NULL,
    local_body_name character varying NOT NULL,
    ward_name character varying,
    ward_no integer,
    processed boolean DEFAULT false
);

-- 3. ORGANIZATION UPDATES (High-Fidelity compliance)
ALTER TABLE public.organization 
ADD COLUMN IF NOT EXISTS system_id character varying,
ADD COLUMN IF NOT EXISTS is_drug_registered boolean NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS drug_licence_type character varying,
ADD COLUMN IF NOT EXISTS drug_license_20 character varying,
ADD COLUMN IF NOT EXISTS drug_license_21 character varying,
ADD COLUMN IF NOT EXISTS drug_license_20b character varying,
ADD COLUMN IF NOT EXISTS drug_license_21b character varying,
ADD COLUMN IF NOT EXISTS is_fssai_registered boolean NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS fssai_number character varying,
ADD COLUMN IF NOT EXISTS is_msme_registered boolean NOT NULL DEFAULT false,
ADD COLUMN IF NOT EXISTS msme_registration_type character varying,
ADD COLUMN IF NOT EXISTS msme_number character varying,
ADD COLUMN IF NOT EXISTS payment_stub_district_id uuid REFERENCES public.settings_districts(id),
ADD COLUMN IF NOT EXISTS payment_stub_local_body_id uuid REFERENCES public.settings_local_bodies(id),
ADD COLUMN IF NOT EXISTS payment_stub_ward_id uuid REFERENCES public.settings_wards(id);

-- 4. UNIFIED BRANCHING & ACCESS
CREATE TABLE IF NOT EXISTS public.settings_branches (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id uuid NOT NULL REFERENCES public.organization(id) ON DELETE CASCADE,
    name character varying NOT NULL,
    branch_code character varying NOT NULL,
    branch_type character varying CHECK (branch_type IS NULL OR (branch_type::text = ANY (ARRAY['FOFO'::character varying, 'COCO'::character varying, 'FICO'::character varying, 'FOCO'::character varying]::text[]))),
    system_id character varying,
    email character varying,
    phone character varying,
    gstin character varying,
    gstin_legal_name character varying,
    gstin_trade_name character varying,
    gstin_registered_on date,
    address_street_1 text,
    address_street_2 text,
    city character varying,
    state character varying,
    pincode character varying,
    country character varying NOT NULL DEFAULT 'India',
    district_id uuid REFERENCES public.settings_districts(id),
    local_body_id uuid REFERENCES public.settings_local_bodies(id),
    ward_id uuid REFERENCES public.settings_wards(id),
    is_primary boolean DEFAULT false NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);

-- MERGED: Unified Branch Access (Combines settings_branch_users + settings_user_location_access)
CREATE TABLE IF NOT EXISTS public.settings_branch_user_access (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id uuid NOT NULL REFERENCES public.organization(id) ON DELETE CASCADE,
    branch_id uuid NOT NULL REFERENCES public.settings_branches(id) ON DELETE CASCADE,
    user_id uuid NOT NULL, -- FK to public.users
    role_id uuid, -- Link to settings_roles if applicable
    is_default_branch boolean DEFAULT false,
    permissions jsonb DEFAULT '{}'::jsonb,
    created_at timestamp with time zone DEFAULT now()
);

-- 5. ACCOUNTS MODULE
CREATE TABLE IF NOT EXISTS public.accounts_fiscal_years (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id uuid NOT NULL REFERENCES public.organization(id),
    name character varying(100) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);

-- 6. BRANDING (Matched to live UI)
CREATE TABLE IF NOT EXISTS public.settings_branding (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    org_id uuid NOT NULL UNIQUE REFERENCES public.organization(id) ON DELETE CASCADE,
    accent_color character varying NOT NULL DEFAULT '#0088FF',
    theme_mode character varying NOT NULL DEFAULT 'light' CHECK (theme_mode::text = ANY (ARRAY['dark'::character varying, 'light'::character varying]::text[])),
    logo_url text,
    favicon_url text,
    keep_branding boolean DEFAULT false,
    updated_at timestamp with time zone DEFAULT now()
);

-- ==========================================
-- END OF MIGRATION
-- ==========================================
