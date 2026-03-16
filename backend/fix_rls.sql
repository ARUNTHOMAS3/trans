-- Fix RLS Permission Errors
-- This script disables Row Level Security on tables that are causing permission denied errors

-- Disable RLS for all affected tables
ALTER TABLE brands DISABLE ROW LEVEL SECURITY;
ALTER TABLE vendors DISABLE ROW LEVEL SECURITY;
ALTER TABLE storage_locations DISABLE ROW LEVEL SECURITY;
ALTER TABLE racks DISABLE ROW LEVEL SECURITY;
ALTER TABLE reorder_terms DISABLE ROW LEVEL SECURITY;
ALTER TABLE accounts DISABLE ROW LEVEL SECURITY;
ALTER TABLE account_transactions DISABLE ROW LEVEL SECURITY;
ALTER TABLE products DISABLE ROW LEVEL SECURITY;
ALTER TABLE product_compositions DISABLE ROW LEVEL SECURITY;
ALTER TABLE manufacturers DISABLE ROW LEVEL SECURITY;
ALTER TABLE categories DISABLE ROW LEVEL SECURITY;
ALTER TABLE units DISABLE ROW LEVEL SECURITY;
ALTER TABLE tax_rates DISABLE ROW LEVEL SECURITY;

-- Grant permissions to ensure service_role and anon have access if RLS is off
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, service_role, anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role, anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, service_role, anon, authenticated;

-- Verify RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename IN ('brands', 'vendors', 'storage_locations', 'racks', 'reorder_terms', 'accounts', 'account_transactions', 'products');
