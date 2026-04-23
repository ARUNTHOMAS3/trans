create table if not exists public.purchase_receives (
  id uuid primary key default gen_random_uuid(),
  purchase_receive_number character varying not null,
  received_date date not null,
  vendor_name character varying,
  purchase_order_id uuid references public.purchase_orders(id),
  purchase_order_number character varying,
  warehouse_id uuid references public.warehouses(id),
  transaction_bin_id uuid references public.bin_master(id),
  transaction_bin_label character varying,
  status character varying not null default 'draft',
  notes text,
  entity_id uuid not null references public.organisation_branch_master(id),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists idx_purchase_receives_entity_id
  on public.purchase_receives(entity_id);

create index if not exists idx_purchase_receives_purchase_order_id
  on public.purchase_receives(purchase_order_id);

create index if not exists idx_purchase_receives_warehouse_id
  on public.purchase_receives(warehouse_id);

create table if not exists public.purchase_receive_items (
  id uuid primary key default gen_random_uuid(),
  purchase_receive_id uuid not null references public.purchase_receives(id) on delete cascade,
  item_id uuid references public.products(id),
  item_name character varying not null,
  description text,
  ordered numeric not null default 0,
  received numeric not null default 0,
  in_transit numeric not null default 0,
  quantity_to_receive numeric not null default 0,
  warehouse_id uuid references public.warehouses(id),
  bin_id uuid references public.bin_master(id),
  bin_label character varying,
  entity_id uuid not null references public.organisation_branch_master(id),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists idx_purchase_receive_items_receive_id
  on public.purchase_receive_items(purchase_receive_id);

create index if not exists idx_purchase_receive_items_item_id
  on public.purchase_receive_items(item_id);

create index if not exists idx_purchase_receive_items_entity_id
  on public.purchase_receive_items(entity_id);

create table if not exists public.purchase_receive_item_batches (
  id uuid primary key default gen_random_uuid(),
  purchase_receive_item_id uuid not null references public.purchase_receive_items(id) on delete cascade,
  product_id uuid not null references public.products(id),
  warehouse_id uuid references public.warehouses(id),
  bin_id uuid references public.bin_master(id),
  bin_label character varying,
  batch_no character varying not null,
  unit_pack character varying,
  mrp numeric,
  ptr numeric,
  quantity numeric not null default 0,
  foc_qty numeric not null default 0,
  manufacture_batch_number character varying,
  manufacture_date date,
  expiry_date date not null,
  is_damaged boolean not null default false,
  damaged_qty numeric not null default 0,
  entity_id uuid not null references public.organisation_branch_master(id),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now()
);

create index if not exists idx_pr_item_batches_item_id
  on public.purchase_receive_item_batches(purchase_receive_item_id);

create index if not exists idx_pr_item_batches_product_id
  on public.purchase_receive_item_batches(product_id);

create index if not exists idx_pr_item_batches_entity_id
  on public.purchase_receive_item_batches(entity_id);

create index if not exists idx_pr_item_batches_batch_no
  on public.purchase_receive_item_batches(batch_no);

create or replace function public.apply_purchase_receive_stock(p_receive_id uuid)
returns void
language plpgsql
as $$
declare
  r record;
  v_batch_id uuid;
  v_qty numeric;
  v_wh uuid;
  v_bin uuid;
begin
  for r in
    select
      pr.id as purchase_receive_id,
      pr.purchase_receive_number,
      pr.received_date,
      pr.entity_id,
      pri.id as purchase_receive_item_id,
      pri.item_id as product_id,
      coalesce(pri.warehouse_id, pr.warehouse_id, prib.warehouse_id) as warehouse_id,
      coalesce(pri.bin_id, pr.transaction_bin_id, prib.bin_id) as bin_id,
      prib.batch_no,
      prib.unit_pack,
      prib.mrp,
      prib.ptr,
      prib.quantity,
      prib.foc_qty,
      prib.manufacture_batch_number,
      prib.manufacture_date,
      prib.expiry_date
    from public.purchase_receives pr
    join public.purchase_receive_items pri
      on pri.purchase_receive_id = pr.id
    join public.purchase_receive_item_batches prib
      on prib.purchase_receive_item_id = pri.id
    where pr.id = p_receive_id
      and pr.status = 'received'
  loop
    v_qty := coalesce(r.quantity, 0) + coalesce(r.foc_qty, 0);
    v_wh := r.warehouse_id;
    v_bin := r.bin_id;

    if r.product_id is null then
      raise exception 'purchase_receive_item % is missing product_id', r.purchase_receive_item_id;
    end if;

    if v_wh is null then
      raise exception 'purchase_receive % cannot post stock without warehouse_id', r.purchase_receive_id;
    end if;

    if v_bin is null then
      raise exception 'purchase_receive % cannot post stock without bin_id', r.purchase_receive_id;
    end if;

    select bm.id
      into v_batch_id
    from public.batch_master bm
    where bm.product_id = r.product_id
      and bm.batch_no = r.batch_no
      and bm.expiry_date = r.expiry_date
    limit 1;

    if v_batch_id is null then
      insert into public.batch_master (
        product_id,
        batch_no,
        expiry_date,
        unit_pack,
        is_manufacture_details,
        manufacture_batch_number,
        manufacture_exp,
        is_active,
        created_by_entity_id,
        source_type
      )
      values (
        r.product_id,
        r.batch_no,
        r.expiry_date,
        r.unit_pack,
        case
          when r.manufacture_batch_number is not null or r.manufacture_date is not null then true
          else false
        end,
        r.manufacture_batch_number,
        r.manufacture_date,
        true,
        r.entity_id,
        'purchase_receive'
      )
      returning id into v_batch_id;
    end if;

    insert into public.batch_stock_layers (
      batch_id,
      product_id,
      entity_id,
      warehouse_id,
      bin_id,
      mrp,
      ptr,
      expiry_date,
      qty,
      foc_qty,
      ref_id,
      ref_type
    )
    values (
      v_batch_id,
      r.product_id,
      r.entity_id,
      v_wh,
      v_bin,
      r.mrp,
      r.ptr,
      r.expiry_date,
      coalesce(r.quantity, 0),
      coalesce(r.foc_qty, 0),
      r.purchase_receive_id,
      'PURCHASE_RECEIVE'
    );

    insert into public.batch_transactions (
      batch_id,
      product_id,
      entity_id,
      warehouse_id,
      bin_id,
      transaction_type,
      ref_id,
      ref_type,
      ref_no,
      qty_in,
      qty_out,
      rate,
      trans_date
    )
    values (
      v_batch_id,
      r.product_id,
      r.entity_id,
      v_wh,
      v_bin,
      'IN',
      r.purchase_receive_id,
      'PURCHASE_RECEIVE',
      r.purchase_receive_number,
      v_qty,
      0,
      r.ptr,
      now()
    );

    insert into public.branch_inventory (
      entity_id,
      product_id,
      current_stock,
      reserved_stock,
      batch_no,
      expiry_date,
      last_stock_update
    )
    values (
      r.entity_id,
      r.product_id,
      v_qty::integer,
      0,
      r.batch_no,
      r.expiry_date,
      now()
    )
    on conflict (entity_id, product_id, batch_no)
    do update set
      current_stock = public.branch_inventory.current_stock + excluded.current_stock,
      expiry_date = excluded.expiry_date,
      last_stock_update = now(),
      updated_at = now();
  end loop;
end;
$$;
