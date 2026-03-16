-- ZERPAI ERP - Franchise Model Schema
-- HO (Head Office) + FOFO/COCO Outlets
-- Single organization, multiple outlets

-- ============================================
-- DROP EXISTING TABLES (Clean Start)
-- ============================================
DROP TABLE IF EXISTS outlet_inventory CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS outlets CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS vendors CASCADE;

-- ============================================
-- 1. OUTLETS (Franchises & Company-Owned)
-- ============================================
CREATE TABLE IF NOT EXISTS outlets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outlet_code VARCHAR(50) NOT NULL UNIQUE,
  outlet_name VARCHAR(255) NOT NULL,
  outlet_type VARCHAR(50) NOT NULL CHECK (outlet_type IN ('HO', 'FOFO', 'COCO')),
  
  -- Contact & Location
  address TEXT,
  city VARCHAR(100),
  state VARCHAR(100),
  pincode VARCHAR(20),
  phone VARCHAR(50),
  email VARCHAR(255),
  
  -- License & Legal
  gstin VARCHAR(50),
  drug_license_no VARCHAR(100),
  
  -- Franchise details (for FOFO)
  franchise_owner_name VARCHAR(255),
  franchise_agreement_date DATE,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 2. USERS TABLE (COMMENTED OUT FOR DEVELOPMENT)
-- ============================================
-- Users table disabled during development - no authentication required
/*
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  email TEXT NOT NULL UNIQUE,
  full_name TEXT,
  phone VARCHAR(50),
  role TEXT NOT NULL CHECK (role IN ('super_admin', 'ho_admin', 'outlet_manager', 'outlet_staff')),
  outlet_id UUID REFERENCES outlets(id),  -- NULL for super_admin/ho_admin
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
*/

-- ============================================
-- 3. PRODUCTS (HO Managed - Global Catalog)
-- ============================================
CREATE TABLE IF NOT EXISTS products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Product Identity
  product_name VARCHAR(255) NOT NULL,
  generic_name VARCHAR(255),
  type VARCHAR(50) NOT NULL CHECK (type IN ('medicine', 'surgical', 'cosmetic', 'service')),
  
  -- Codes & Classification
  item_code VARCHAR(100) NOT NULL UNIQUE,
  sku VARCHAR(100) UNIQUE,
  hsn_code VARCHAR(50),
  
  -- Packaging
  unit VARCHAR(50) NOT NULL,  -- pcs, box, packet, strip
  pack_size INTEGER DEFAULT 1,  -- e.g., 10 tablets per strip
  
  -- Regulatory
  schedule VARCHAR(50),  -- H, H1, X, G
  is_prescription_required BOOLEAN DEFAULT false,
  
  -- Drug Details
  dosage_form VARCHAR(100),  -- Tablet, Capsule, Syrup, Injection
  strength VARCHAR(100),     -- 500mg, 1g, etc.
  manufacturer VARCHAR(255),
  
  -- Pricing (HO sets, same for all outlets)
  mrp DECIMAL(15,2) NOT NULL DEFAULT 0,
  ptr DECIMAL(15,2) NOT NULL DEFAULT 0,  -- Price to Retailer
  pts DECIMAL(15,2) DEFAULT 0,            -- Price to Stockist
  purchase_price DECIMAL(15,2) DEFAULT 0, -- HO purchase price
  
  -- Margin calculations
  margin_percent DECIMAL(5,2),
  gst_percent DECIMAL(5,2) DEFAULT 12,
  
  -- Categorization
  category_id UUID,
  
  -- Inventory Settings
  is_track_inventory BOOLEAN DEFAULT true,
  track_batch BOOLEAN DEFAULT true,
  expirable BOOLEAN DEFAULT true,
  shelf_life_days INTEGER,  -- e.g., 730 days (2 years)
  
  -- Reorder (HO level)
  min_stock_level INTEGER DEFAULT 0,
  reorder_quantity INTEGER DEFAULT 0,
  
  -- Flags
  is_active BOOLEAN DEFAULT true,
  is_high_value BOOLEAN DEFAULT false,
  is_narcotic BOOLEAN DEFAULT false,
  
  -- Metadata
  description TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by_id UUID,  -- Removed auth.users reference for development
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by_id UUID  -- Removed auth.users reference for development
);

-- ============================================
-- 4. OUTLET INVENTORY (Per-Outlet Stock)
-- ============================================
CREATE TABLE IF NOT EXISTS outlet_inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  outlet_id UUID NOT NULL REFERENCES outlets(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  
  -- Stock quantities
  current_stock INTEGER NOT NULL DEFAULT 0,
  reserved_stock INTEGER DEFAULT 0,  -- Pending sales
  available_stock INTEGER GENERATED ALWAYS AS (current_stock - reserved_stock) STORED,
  
  -- Batches
  batch_no VARCHAR(100),
  expiry_date DATE,
  
  -- Reorder (outlet-specific)
  min_stock_level INTEGER DEFAULT 0,
  max_stock_level INTEGER DEFAULT 0,
  
  -- Last updated
  last_stock_update TIMESTAMPTZ DEFAULT NOW(),
  
  -- Constraints
  UNIQUE(outlet_id, product_id, batch_no),
  CHECK (current_stock >= 0)
);

-- ============================================
-- 5. CATEGORIES
-- ============================================
CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  parent_id UUID REFERENCES categories(id),
  display_order INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- 6. VENDORS/DISTRIBUTORS (HO Level)
-- ============================================
CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_name VARCHAR(255) NOT NULL UNIQUE,
  vendor_type VARCHAR(50) CHECK (vendor_type IN ('manufacturer', 'distributor', 'wholesaler')),
  
  -- Contact
  contact_person VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(50),
  address TEXT,
  
  -- Legal
  gstin VARCHAR(50),
  drug_license_no VARCHAR(100),
  
  -- Payment terms
  payment_terms VARCHAR(255),
  credit_days INTEGER DEFAULT 0,
  
  -- Status
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================
-- Outlets
CREATE INDEX IF NOT EXISTS idx_outlets_type ON outlets(outlet_type);
CREATE INDEX IF NOT EXISTS idx_outlets_active ON outlets(is_active);

-- Users
-- CREATE INDEX IF NOT EXISTS idx_users_outlet ON users(outlet_id); -- Disabled: users table commented out
-- CREATE INDEX IF NOT EXISTS idx_users_role ON users(role); -- Disabled: users table commented out

-- Products
CREATE INDEX IF NOT EXISTS idx_products_type ON products(type);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active);
CREATE INDEX IF NOT EXISTS idx_products_item_code ON products(item_code);
CREATE INDEX IF NOT EXISTS idx_products_hsn ON products(hsn_code);

-- Outlet Inventory
CREATE INDEX IF NOT EXISTS idx_inventory_outlet ON outlet_inventory(outlet_id);
CREATE INDEX IF NOT EXISTS idx_inventory_product ON outlet_inventory(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_expiry ON outlet_inventory(expiry_date);
CREATE INDEX IF NOT EXISTS idx_inventory_outlet_product ON outlet_inventory(outlet_id, product_id);

-- Categories
CREATE INDEX IF NOT EXISTS idx_categories_parent ON categories(parent_id);

-- ============================================
-- ROW LEVEL SECURITY - DISABLED FOR DEVELOPMENT
-- ============================================
-- All RLS policies and ENABLE statements have been removed for development.
-- Tables are now publicly accessible without authentication.
-- Re-enable RLS and policies before deploying to production.

-- ============================================
-- SEED DATA
-- ============================================
-- Insert HO outlet
INSERT INTO outlets (id, outlet_code, outlet_name, outlet_type, city, state, is_active)
VALUES (gen_random_uuid(), 'HO001', 'Head Office - Inventory', 'HO', 'Mumbai', 'Maharashtra', true)
ON CONFLICT (outlet_code) DO NOTHING;

-- Insert sample categories
INSERT INTO categories (name, description) VALUES
  ('Medicines - General', 'Over-the-counter and prescription medicines'),
  ('Medicines - Antibiotics', 'Antibiotic medications'),
  ('Surgical Items', 'Surgical equipment and disposables'),
  ('Services', 'Consultation and other services')
ON CONFLICT (name) DO NOTHING;

-- Insert sample products
INSERT INTO products (product_name, generic_name, type, item_code, sku, unit, hsn_code, dosage_form, strength, mrp, ptr, is_track_inventory, track_batch, expirable) VALUES
  ('Paracetamol 500mg', 'Paracetamol', 'medicine', 'MED-001', 'PARA-500', 'pcs', '30049099', 'Tablet', '500mg', 50.00, 40.00, true, true, true),
  ('Amoxicillin 500mg', 'Amoxicillin', 'medicine', 'MED-002', 'AMOX-500', 'pcs', '30041010', 'Capsule', '500mg', 120.00, 95.00, true, true, true),
  ('Surgical Gloves', 'Gloves', 'surgical', 'SUR-001', 'GLOVES-MED', 'pair', '40151100', NULL, 'Medium', 25.00, 20.00, true, false, false),
  ('General Consultation', NULL, 'service', 'SRV-001', 'CONSULT', 'service', '999311', NULL, NULL, 500.00, 500.00, false, false, false)
ON CONFLICT (item_code) DO NOTHING;

SELECT 'Franchise model schema created successfully!' AS status;
SELECT 'Model: HO + FOFO/COCO outlets with centralized products' AS architecture;
