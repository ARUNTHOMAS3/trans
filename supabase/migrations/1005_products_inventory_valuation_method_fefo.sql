BEGIN;

ALTER TYPE public.inventory_valuation_method
ADD VALUE IF NOT EXISTS 'FEFO';

DO $$
DECLARE
  constraint_name text;
BEGIN
  FOR constraint_name IN
    SELECT con.conname
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE nsp.nspname = 'public'
      AND rel.relname = 'products'
      AND con.contype = 'c'
      AND pg_get_constraintdef(con.oid) ILIKE '%inventory_valuation_method%'
  LOOP
    EXECUTE format(
      'ALTER TABLE public.products DROP CONSTRAINT IF EXISTS %I',
      constraint_name
    );
  END LOOP;
END $$;

ALTER TABLE public.products
ADD CONSTRAINT products_inventory_valuation_method_check
CHECK (
  inventory_valuation_method IS NULL
  OR inventory_valuation_method IN (
    'FIFO',
    'LIFO',
    'FEFO',
    'Weighted Average',
    'Specific Identification'
  )
);

COMMIT;
