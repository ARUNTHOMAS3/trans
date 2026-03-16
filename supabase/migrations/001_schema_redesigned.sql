-- ZERPAI ERP - Redesigned Schema with Global Product Master
-- Option B: Shared product catalog with org-specific customization

-- ============================================
-- 1. USERS TABLE (COMMENTED OUT FOR DEVELOPMENT)
-- ============================================
-- Users table disabled during development - no authentication required
/*
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'manager', 'staff')),
  org_id UUID NOT NULL,
  outlet_id UUID,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
*/

-- ============================================
-- 2. PRODUCT MASTER (Global - Shared by All Orgs)
-- ============================================
CREATE TABLE IF NOT EXISTS product_master (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Core product identity (global)
  generic_name VARCHAR(255) NOT NULL UNIQUE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('goods', 'service', 'inventory', 'non-inventory')),
  unit VARCHAR(50) NOT NULL,
  
  -- Regulatory & Classification (global)
  hsn_code VARCHAR(50),
  schedule VARCHAR(50),  -- Drug schedule (H, H1, X, etc.)
  is_bio_medicine BOOLEAN DEFAULT false,
  
  -- Common attributes
  description TEXT,
  dosage_form VARCHAR(100),  -- Tablet, Capsule, Syrup, etc.
  strength VARCHAR(100),     -- 500mg, 1g, etc.
  manufacturer VARCHAR(255),
  
  -- Metadata
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 3. ORGANIZATION PRODUCTS (Org-Specific Extensions)
-- ============================================
CREATE TABLE IF NOT EXISTS organization_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Link to global master
  product_master_id UUID NOT NULL REFERENCES product_master(id) ON DELETE CASCADE,
  org_id UUID NOT NULL,
  outlet_id UUID,  -- NULL = available to all outlets
  
  -- Org-specific naming & codes
  billing_name VARCHAR(255) NOT NULL,  -- What this org calls it
  alt_name VARCHAR(255),
  item_code VARCHAR(100) NOT NULL,     -- Org's internal code
  sku VARCHAR(100),                    -- Org's SKU
  
  -- Org-specific pricing
  mrp DECIMAL(15,2) DEFAULT 0,
  ptr DECIMAL(15,2) DEFAULT 0,
  custprice DECIMAL(15,2) DEFAULT 0,
  
  -- Org-specific categorization
  category_id UUID,  -- Org's category system
  vendor_id UUID,    -- Org's preferred vendor
  
  -- Org-specific flags
  is_referable BOOLEAN DEFAULT false,
  post_to_ecommerce BOOLEAN DEFAULT false,
  expirable BOOLEAN DEFAULT false,
  
  -- Inventory settings (org-specific)
  is_track_inventory BOOLEAN DEFAULT false,
  track_batch BOOLEAN DEFAULT false,
  reorder_pt INTEGER DEFAULT 0,
  reorderqty INTEGER DEFAULT 0,
  
  -- Tax preferences (org-specific)
  tax_preference VARCHAR(50) CHECK (tax_preference IN ('taxable', 'non-taxable', 'exempt')),
  exemption_reason TEXT,
  
  -- Status
  is_selectable BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  
  -- Audit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by_id UUID,  -- Removed auth.users reference for development
  last_modified_by UUID,  -- Removed auth.users reference for development
  last_modified_date TIMESTAMPTZ,
  
  -- Constraints
  UNIQUE(org_id, item_code),
  UNIQUE(org_id, product_master_id, outlet_id)  -- One entry per product per org per outlet
);

CREATE UNIQUE INDEX IF NOT EXISTS unique_org_product_sku 
  ON organization_products(org_id, sku) WHERE sku IS NOT NULL;

-- ============================================
-- 4. CATEGORIES TABLE (Org-Specific)
-- ============================================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  parent_id UUID REFERENCES categories(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(org_id, name)
);

-- ============================================
-- 5. VENDORS TABLE (Org-Specific)
-- ============================================
CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id UUID NOT NULL,
  vendor_name VARCHAR(255) NOT NULL,
  contact_person VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(50),
  address TEXT,
  gstin VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(org_id, vendor_name)
);

-- ============================================
-- INDEXES
-- ============================================
-- Product Master
CREATE INDEX IF NOT EXISTS idx_product_master_type ON product_master(type);
CREATE INDEX IF NOT EXISTS idx_product_master_hsn ON product_master(hsn_code);
CREATE INDEX IF NOT EXISTS idx_product_master_active ON product_master(is_active);

-- Organization Products
CREATE INDEX IF NOT EXISTS idx_org_products_org ON organization_products(org_id);
CREATE INDEX IF NOT EXISTS idx_org_products_master ON organization_products(product_master_id);
CREATE INDEX IF NOT EXISTS idx_org_products_org_outlet ON organization_products(org_id, outlet_id);
CREATE INDEX IF NOT EXISTS idx_org_products_category ON organization_products(category_id);
CREATE INDEX IF NOT EXISTS idx_org_products_vendor ON organization_products(vendor_id);
CREATE INDEX IF NOT EXISTS idx_org_products_selectable ON organization_products(is_selectable);

-- Other tables
CREATE INDEX IF NOT EXISTS idx_categories_org ON categories(org_id);
CREATE INDEX IF NOT EXISTS idx_vendors_org ON vendors(org_id);
-- CREATE INDEX IF NOT EXISTS idx_users_org ON users(org_id);  -- Disabled: users table commented out

-- ============================================
-- ROW LEVEL SECURITY - DISABLED FOR DEVELOPMENT
-- ============================================
-- All RLS policies and ENABLE statements have been removed for development.
-- Tables are now publicly accessible without authentication.
-- Re-enable RLS and policies before deploying to production.

-- ============================================
-- SAMPLE MASTER PRODUCTS
-- ============================================
INSERT INTO product_master (id, generic_name, type, unit, hsn_code, schedule, dosage_form, strength) VALUES
  (gen_random_uuid(), 'Paracetamol', 'goods', 'pcs', '30049099', 'Schedule H', 'Tablet', '500mg'),
  (gen_random_uuid(), 'Amoxicillin', 'goods', 'pcs', '30041010', 'Schedule H1', 'Capsule', '500mg'),
  (gen_random_uuid(), 'Surgical Gloves', 'goods', 'pair', '40151100', NULL, 'Gloves', 'Medium'),
  (gen_random_uuid(), 'Consultation Fee', 'service', 'service', '999311', NULL, NULL, NULL)
ON CONFLICT (generic_name) DO NOTHING;

SELECT 'Database schema created successfully!' AS status;
SELECT 'Architecture: Global Product Master + Org Extensions' AS design;
