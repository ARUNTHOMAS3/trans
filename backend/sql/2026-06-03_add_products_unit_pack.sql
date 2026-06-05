-- Adds the missing unit_pack column to public.products.
-- Keep this migration narrow: current DB truth already has lock_unit_pack.

alter table public.products
add column if not exists unit_pack character varying(50);

comment on column public.products.unit_pack
is 'Pack size label/value selected in item formulation flow, e.g. Box (10).';

