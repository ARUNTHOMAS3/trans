-- Disable RLS and grant permissions for tax groups tables
ALTER TABLE tax_groups DISABLE ROW LEVEL SECURITY;
ALTER TABLE tax_group_taxes DISABLE ROW LEVEL SECURITY;

GRANT ALL ON tax_groups TO postgres, service_role;
GRANT SELECT ON tax_groups TO anon, authenticated;

GRANT ALL ON tax_group_taxes TO postgres, service_role;
GRANT SELECT ON tax_group_taxes TO anon, authenticated;
