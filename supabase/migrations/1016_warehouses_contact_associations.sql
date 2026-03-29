ALTER TABLE public.warehouses
  ADD COLUMN IF NOT EXISTS customer_id uuid REFERENCES public.customers(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS vendor_id uuid REFERENCES public.vendors(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_warehouses_customer_id
  ON public.warehouses(customer_id);

CREATE INDEX IF NOT EXISTS idx_warehouses_vendor_id
  ON public.warehouses(vendor_id);
