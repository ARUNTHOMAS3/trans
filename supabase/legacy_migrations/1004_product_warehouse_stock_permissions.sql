BEGIN;

ALTER TABLE IF EXISTS public.product_warehouse_stocks DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.product_warehouse_stock_adjustments DISABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE public.product_warehouse_stocks TO postgres, service_role, anon, authenticated;
GRANT ALL ON TABLE public.product_warehouse_stock_adjustments TO postgres, service_role, anon, authenticated;

GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, service_role, anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, service_role, anon, authenticated;

COMMIT;
