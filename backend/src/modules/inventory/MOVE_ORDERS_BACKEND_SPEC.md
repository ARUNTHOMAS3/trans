# Move Orders Backend Specification

Date: 2026-05-09
Scope: Backend data model and completion stock flow for Move Orders.

## 1) Header Table: `inventory_move_orders`

```sql
CREATE TABLE inventory_move_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    entity_id UUID NOT NULL,
    warehouse_id UUID NOT NULL,
    move_order_number VARCHAR(50) NOT NULL UNIQUE,
    move_date TIMESTAMP NOT NULL,
    assignee_id UUID,
    notes TEXT,
    status VARCHAR(30) NOT NULL DEFAULT 'draft',
    created_by UUID,
    completed_by UUID,
    completed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT now(),
    updated_at TIMESTAMP DEFAULT now()
);
```

## 2) Item Table: `inventory_move_order_items`

```sql
CREATE TABLE inventory_move_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    move_order_id UUID NOT NULL
        REFERENCES inventory_move_orders(id)
        ON DELETE CASCADE,
    product_id UUID NOT NULL,
    qty NUMERIC(18,4) NOT NULL,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT now()
);
```

## 3) Source Allocation Table: `inventory_move_order_source_batches`

```sql
CREATE TABLE inventory_move_order_source_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    move_order_item_id UUID NOT NULL
        REFERENCES inventory_move_order_items(id)
        ON DELETE CASCADE,
    source_layer_id UUID NOT NULL,
    batch_id UUID NOT NULL,
    source_bin_id UUID NOT NULL,
    qty_out NUMERIC(18,4) NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);
```

## 4) Destination Allocation Table: `inventory_move_order_destination_bins`

```sql
CREATE TABLE inventory_move_order_destination_bins (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_batch_row_id UUID NOT NULL
        REFERENCES inventory_move_order_source_batches(id)
        ON DELETE CASCADE,
    destination_bin_id UUID NOT NULL,
    qty_in NUMERIC(18,4) NOT NULL,
    created_at TIMESTAMP DEFAULT now()
);
```

## Batch/Stock Layer Rules

Move Order does not create a new batch master record.

Destination stock movement must preserve:
- same `batch_id`
- same cost attributes (purchase rate / MRP context from source layer)
- same expiry/manufacturing attributes associated with batch
- same `warehouse_id`
- same `entity_id`

Only `bin_id` changes for the moved quantity.

### Example

Before:
- `L1`: `batch=B001`, `warehouse=MAIN`, `bin=A1`, `qty=10`

After moving all 10 to bin B2:
- `L1`: `batch=B001`, `warehouse=MAIN`, `bin=A1`, `qty=0`
- `L2`: `batch=B001`, `warehouse=MAIN`, `bin=B2`, `qty=10`

## Final Save Flow (when status becomes `COMPLETED`)

All operations must run in one DB transaction.

### Step 1: Reduce source layer qty

```sql
UPDATE batch_stock_layers
SET qty = qty - :qty_out
WHERE id = :source_layer_id;
```

### Step 2: Find destination layer

Match by:
- same `batch_id`
- same `warehouse_id`
- same `bin_id` (destination)
- same cost context (purchase rate / MRP)
- same vendor context
- same `entity_id`

### Step 3A: Destination layer exists

Increase qty:
- `qty = qty + :qty_in`

### Step 3B: Destination layer does not exist

Insert a new `batch_stock_layers` row with copied source-layer commercial/ownership context:
- same `batch_id`
- same `product_id`
- same `warehouse_id`
- same `entity_id`
- same `vendor_id`
- same `purchase_rate`
- same `mrp`
- new `bin_id` = selected destination bin

## `batch_transactions` Impact

Move Order completion writes inventory audit movements:
- `MOVE_OUT`
- `MOVE_IN`

These are inventory audit transactions only, not accounting journal transactions.
