-- Enforce entity-scoped unique RMA numbers for sales returns
-- Safe to run multiple times.

CREATE UNIQUE INDEX IF NOT EXISTS sales_returns_entity_rma_number_uidx
ON public.sales_returns (entity_id, rma_number);
