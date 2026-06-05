create table if not exists public.product_types (
  id uuid primary key default gen_random_uuid(),
  name character varying(120) not null unique,
  description text,
  is_active boolean not null default true,
  created_at timestamp without time zone not null default now()
);

alter table public.products
add column if not exists product_type_id uuid;

alter table public.products
drop constraint if exists products_product_type_id_fkey;

alter table public.products
add constraint products_product_type_id_fkey
foreign key (product_type_id)
references public.product_types(id);

create index if not exists idx_products_product_type_id
on public.products(product_type_id);

insert into public.product_types (name, description)
values
  ('Medicine', 'Prescription or regulated medicine'),
  ('OTC', 'Over-the-counter product'),
  ('Ayurveda', 'Ayurvedic or traditional medicine product')
on conflict (name) do nothing;
