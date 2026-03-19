BEGIN;

GRANT USAGE ON SCHEMA public TO postgres, service_role, anon, authenticated;

ALTER TABLE IF EXISTS public.product_outlet_inventory_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.composite_item_outlet_inventory_settings DISABLE ROW LEVEL SECURITY;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.product_outlet_inventory_settings
TO postgres, service_role, anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.composite_item_outlet_inventory_settings
TO postgres, service_role, anon, authenticated;

COMMIT;
