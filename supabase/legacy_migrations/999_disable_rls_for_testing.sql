-- ============================================
-- DISABLE RLS FOR DEVELOPMENT ENVIRONMENT
-- ============================================
-- WARNING: This disables Row Level Security completely.
-- Only use in development/testing environments!
-- This migration ensures all tables are publicly accessible without authentication.

-- Core product and inventory tables
ALTER TABLE IF EXISTS products DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS product_compositions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS product_master DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS organization_products DISABLE ROW LEVEL SECURITY;

-- Lookup and reference tables
ALTER TABLE IF EXISTS units DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS manufacturers DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS brands DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS vendors DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS storage_locations DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS racks DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS tax_rates DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS reorder_terms DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS accounts DISABLE ROW LEVEL SECURITY;

-- Franchise and outlet tables (if they exist)
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'franchises') THEN
        ALTER TABLE franchises DISABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'users') THEN
        ALTER TABLE users DISABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'outlets') THEN
        ALTER TABLE outlets DISABLE ROW LEVEL SECURITY;
    END IF;
    
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'outlet_inventory') THEN
        ALTER TABLE outlet_inventory DISABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Confirmation message
SELECT 'RLS DISABLED on all tables for development environment' AS status;
SELECT 'Database is now publicly accessible - use ONLY in development!' AS warning;

-- Note: To re-enable RLS later for production:
-- 1. Run your main migration file which includes ENABLE ROW LEVEL SECURITY statements
-- 2. Or manually run: ALTER TABLE <table_name> ENABLE ROW LEVEL SECURITY;
-- 3. Ensure all policies are recreated for each table
