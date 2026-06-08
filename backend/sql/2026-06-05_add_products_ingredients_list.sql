alter table public.products
add column if not exists ingredients_list text;

comment on column public.products.ingredients_list
is 'Raw ingredients list text imported from Truemeds or maintained from item create more info.';
