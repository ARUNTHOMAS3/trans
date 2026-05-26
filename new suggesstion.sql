1️⃣ HEADER TABLE
inventory_adjustment


CREATE TABLE inventory_adjustment (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    adjustment_no VARCHAR(50) UNIQUE NOT NULL,
    adjustment_type VARCHAR(20) NOT NULL CHECK (adjustment_type IN ('QUANTITY','VALUE')),

    entity_id UUID NOT NULL,      -- HO / Branch
  
    reference_number VARCHAR(100),
    adjustment_date DATE NOT NULL,

    account_id UUID NOT NULL,
    reason_id UUID NOT NULL,

    description TEXT,

    status VARCHAR(20) DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','APPROVED')),

    approved_by UUID,
    approved_at TIMESTAMP,

    created_by UUID,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);
2️⃣ REASONS TABLE (ENTITY-AWARE)
inventory_adjustment_reasons

CREATE TABLE inventory_adjustment_reasons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    entity_id UUID NULL, -- NULL = global, NOT NULL = entity-specific

    name VARCHAR(100) NOT NULL,
    type VARCHAR(20) CHECK (type IN ('QUANTITY','VALUE','BOTH')),

    is_active BOOLEAN DEFAULT TRUE,

    created_at TIMESTAMP DEFAULT NOW()
);
3️⃣ QUANTITY ADJUSTMENT – ITEMS
inventory_adjustment_items

CREATE TABLE inventory_adjustment_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    adjustment_id UUID NOT NULL REFERENCES inventory_adjustment(id) ON DELETE CASCADE,

    entity_id UUID NOT NULL,
  
    product_id UUID NOT NULL,

    quantity_before NUMERIC(14,4) NOT NULL,
    quantity_after NUMERIC(14,4) NOT NULL,
    quantity_adjusted NUMERIC(14,4) NOT NULL, -- + / -

    uom VARCHAR(20),

    created_at TIMESTAMP DEFAULT NOW()
);
4️⃣ QUANTITY ADJUSTMENT – BATCHES
inventory_adjustment_item_batches

CREATE TABLE inventory_adjustment_item_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    adjustment_item_id UUID NOT NULL REFERENCES inventory_adjustment_items(id) ON DELETE CASCADE,

    entity_id UUID NOT NULL,
    Bin_location_id UUID NULL,

    product_id UUID NOT NULL,
    batch_id UUID NOT NULL,

    quantity_in NUMERIC(14,4) DEFAULT 0,
    quantity_out NUMERIC(14,4) DEFAULT 0,

    created_at TIMESTAMP DEFAULT NOW()
);
5️⃣ VALUE ADJUSTMENT – ITEMS
inventory_adjustment_value_items

CREATE TABLE inventory_adjustment_value_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    adjustment_id UUID NOT NULL REFERENCES inventory_adjustment(id) ON DELETE CASCADE,

    entity_id UUID NOT NULL,

    product_id UUID NOT NULL,

    current_value NUMERIC(18,2) NOT NULL,
    changed_value NUMERIC(18,2) NOT NULL,
    adjusted_value NUMERIC(18,2) NOT NULL, -- + / -

    created_at TIMESTAMP DEFAULT NOW()
);
6️⃣ ACCOUNTING ENTRIES
inventory_adjustment_account_entries

CREATE TABLE inventory_adjustment_account_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    adjustment_id UUID NOT NULL REFERENCES inventory_adjustment(id) ON DELETE CASCADE,

    entity_id UUID NOT NULL,

    account_id UUID NOT NULL,

    debit NUMERIC(18,2) DEFAULT 0,
    credit NUMERIC(18,2) DEFAULT 0,

    created_at TIMESTAMP DEFAULT NOW()
);