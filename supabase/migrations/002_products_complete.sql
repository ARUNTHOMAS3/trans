-- ZERPAI ERP - Complete Products Schema Migration
-- Version: 2.0 (Revised based on UI screenshots + feedback)
-- Date: 2026-01-08

-- ============================================
-- DROP EXISTING TABLES (Clean Start)
-- ============================================
DROP TABLE IF EXISTS product_compositions CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS racks CASCADE;
DROP TABLE IF EXISTS reorder_terms CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS tax_rates CASCADE;
DROP TABLE IF EXISTS manufacturers CASCADE;
DROP TABLE IF EXISTS brands CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS storage_locations CASCADE;
DROP TABLE IF EXISTS vendors CASCADE;

-- ============================================
-- LOOKUP TABLES (Master Data)
-- ============================================

-- 1. UNITS
CREATE TABLE units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_name VARCHAR(50) NOT NULL UNIQUE,
  unit_symbol VARCHAR(10),
  unit_type VARCHAR(50) CHECK (unit_type IN ('count', 'weight', 'volume', 'length')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. CATEGORIES
CREATE TABLE categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  parent_id UUID REFERENCES categories(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TAX RATES
CREATE TABLE tax_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tax_name VARCHAR(100) NOT NULL UNIQUE,
  tax_rate DECIMAL(5,2) NOT NULL,
  tax_type VARCHAR(50) CHECK (tax_type IN ('IGST', 'CGST', 'SGST')),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. MANUFACTURERS
CREATE TABLE manufacturers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  contact_info JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. BRANDS
CREATE TABLE brands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  manufacturer_id UUID REFERENCES manufacturers(id),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ACCOUNTS
CREATE TABLE accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_name VARCHAR(255) NOT NULL UNIQUE,
  account_type VARCHAR(50) CHECK (account_type IN ('sales', 'purchase', 'inventory', 'expense', 'asset')),
  account_code VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. STORAGE LOCATIONS
CREATE TABLE storage_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_name VARCHAR(255) NOT NULL UNIQUE,
  temperature_range VARCHAR(50),
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. RACKS
CREATE TABLE racks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rack_code VARCHAR(50) NOT NULL UNIQUE,
  rack_name VARCHAR(255),
  storage_id UUID REFERENCES storage_locations(id),
  capacity INTEGER,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. REORDER TERMS
CREATE TABLE reorder_terms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  term_name VARCHAR(255) NOT NULL UNIQUE,
  preset_formula VARCHAR(100),
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. VENDORS
CREATE TABLE vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_name VARCHAR(255) NOT NULL UNIQUE,
  vendor_type VARCHAR(50) CHECK (vendor_type IN ('manufacturer', 'distributor', 'wholesaler')),
  contact_person VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(50),
  address TEXT,
  gstin VARCHAR(50),
  drug_license_no VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- MAIN TABLE: PRODUCTS
-- ============================================
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- =====================================
  -- BASIC INFORMATION
  -- =====================================
  type VARCHAR(50) NOT NULL CHECK (type IN ('goods', 'service')),
  product_name VARCHAR(255) NOT NULL,
  billing_name VARCHAR(255),
  item_code VARCHAR(100) NOT NULL UNIQUE,
  sku VARCHAR(100) UNIQUE,
  unit_id UUID NOT NULL REFERENCES units(id),
  category_id UUID REFERENCES categories(id),
  is_returnable BOOLEAN DEFAULT false,
  push_to_ecommerce BOOLEAN DEFAULT false,
  
  -- Tax & Regulatory
  hsn_code VARCHAR(50),
  tax_preference VARCHAR(50) CHECK (tax_preference IN ('taxable', 'non-taxable', 'exempt')),
  intra_state_tax_id UUID REFERENCES tax_rates(id),
  inter_state_tax_id UUID REFERENCES tax_rates(id),
  
  -- Images
  primary_image_url TEXT,
  image_urls JSONB,
  
  -- =====================================
  -- SALES INFORMATION
  -- =====================================
  selling_price DECIMAL(15,2),  -- OPTIONAL (not required)
  selling_price_currency VARCHAR(10) DEFAULT 'INR',
  mrp DECIMAL(15,2),
  ptr DECIMAL(15,2),
  sales_account_id UUID REFERENCES accounts(id),
  sales_description TEXT,
  
  -- =====================================
  -- PURCHASE INFORMATION
  -- =====================================
  cost_price DECIMAL(15,2),
  cost_price_currency VARCHAR(10) DEFAULT 'INR',
  purchase_account_id UUID REFERENCES accounts(id),
  preferred_vendor_id UUID REFERENCES vendors(id),
  purchase_description TEXT,
  
  -- =====================================
  -- FORMULATION
  -- =====================================
  length DECIMAL(10,2),
  width DECIMAL(10,2),
  height DECIMAL(10,2),
  dimension_unit VARCHAR(10) DEFAULT 'cm',
  weight DECIMAL(10,2),
  weight_unit VARCHAR(10) DEFAULT 'kg',
  manufacturer_id UUID REFERENCES manufacturers(id),
  brand_id UUID REFERENCES brands(id),
  mpn VARCHAR(100),  -- Manufacturer Part Number
  upc VARCHAR(20),   -- Universal Product Code (number-only)
  isbn VARCHAR(20),
  ean VARCHAR(20),   -- European Article Number (number-only)
  
  -- =====================================
  -- COMPOSITION
  -- =====================================
  track_assoc_ingredients BOOLEAN DEFAULT false,
  buying_rule VARCHAR(100),
  schedule_of_drug VARCHAR(50),
  
  -- =====================================
  -- INVENTORY SETTINGS
  -- =====================================
  is_track_inventory BOOLEAN DEFAULT true,
  track_bin_location BOOLEAN DEFAULT false,
  track_batches BOOLEAN DEFAULT false,
  inventory_account_id UUID REFERENCES accounts(id),
  inventory_valuation_method VARCHAR(50) CHECK (inventory_valuation_method IN ('FIFO', 'LIFO', 'Weighted Average', 'Specific Identification')),
  storage_id UUID REFERENCES storage_locations(id),
  rack_id UUID REFERENCES racks(id),
  reorder_point INTEGER DEFAULT 0,
  reorder_term_id UUID REFERENCES reorder_terms(id),
  
  -- =====================================
  -- STATUS FLAGS
  -- =====================================
  is_active BOOLEAN DEFAULT true,
  is_lock BOOLEAN DEFAULT false,
  
  -- =====================================
  -- SYSTEM FIELDS
  -- =====================================
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by_id UUID,  -- Removed auth.users reference for development
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  updated_by_id UUID  -- Removed auth.users reference for development
);

-- ============================================
-- CHILD TABLE: PRODUCT COMPOSITIONS
-- ============================================
CREATE TABLE product_compositions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  content_name VARCHAR(255) NOT NULL,
  strength DECIMAL(10,2) NOT NULL,
  strength_unit VARCHAR(20) NOT NULL,
  schedule VARCHAR(50),
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(product_id, content_name)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

-- Products
CREATE INDEX idx_products_type ON products(type);
CREATE INDEX idx_products_item_code ON products(item_code);
CREATE INDEX idx_products_sku ON products(sku) WHERE sku IS NOT NULL;
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_unit ON products(unit_id);
CREATE INDEX idx_products_manufacturer ON products(manufacturer_id);
CREATE INDEX idx_products_brand ON products(brand_id);
CREATE INDEX idx_products_vendor ON products(preferred_vendor_id);
CREATE INDEX idx_products_active ON products(is_active);
CREATE INDEX idx_products_ecommerce ON products(push_to_ecommerce);
CREATE INDEX idx_products_hsn ON products(hsn_code);

-- Product Compositions
CREATE INDEX idx_compositions_product ON product_compositions(product_id);

-- Categories
CREATE INDEX idx_categories_parent ON categories(parent_id);
CREATE INDEX idx_categories_active ON categories(is_active);

-- Racks
CREATE INDEX idx_racks_storage ON racks(storage_id);

-- Brands
CREATE INDEX idx_brands_manufacturer ON brands(manufacturer_id);

-- ============================================
-- ROW LEVEL SECURITY - DISABLED FOR DEVELOPMENT
-- ============================================
-- All RLS policies and ENABLE statements have been removed for development.
-- Tables are now publicly accessible without authentication.
-- Re-enable RLS and policies before deploying to production.

-- ============================================
-- SEED DATA
-- ============================================

-- Units
INSERT INTO units (unit_name, unit_symbol, unit_type) VALUES
  ('Pieces', 'pcs', 'count'),
  ('Box', 'box', 'count'),
  ('Strip', 'strip', 'count'),
  ('Packet', 'packet', 'count'),
  ('Bottle', 'bottle', 'count'),
  ('Kilogram', 'kg', 'weight'),
  ('Gram', 'g', 'weight'),
  ('Liter', 'L', 'volume'),
  ('Milliliter', 'ml', 'volume')
ON CONFLICT (unit_name) DO NOTHING;

-- Categories
INSERT INTO categories (name, description) VALUES
  ('Medicines - General', 'Over-the-counter and prescription medicines'),
  ('Medicines - Antibiotics', 'Antibiotic medications'),
  ('Medicines - Analgesics', 'Pain relief medications'),
  ('Surgical Items', 'Surgical equipment and disposables'),
  ('Cosmetics', 'Beauty and personal care products'),
  ('Services', 'Consultation and other services'),
  ('OTHER BRANDS', 'Other brand products')
ON CONFLICT (name) DO NOTHING;

-- Tax Rates
INSERT INTO tax_rates (tax_name, tax_rate, tax_type) VALUES
  ('IGST 0%', 0.00, 'IGST'),
  ('IGST 5%', 5.00, 'IGST'),
  ('IGST 12%', 12.00, 'IGST'),
  ('IGST 18%', 18.00, 'IGST'),
  ('IGST 28%', 28.00, 'IGST')
ON CONFLICT (tax_name) DO NOTHING;

-- Accounts
INSERT INTO accounts (account_name, account_type, account_code) VALUES
  ('Sales - Retail', 'sales', 'SAL-001'),
  ('Purchase', 'purchase', 'PUR-001'),
  ('Inventory Account', 'inventory', 'INV-001')
ON CONFLICT (account_name) DO NOTHING;

-- Storage Locations
INSERT INTO storage_locations (location_name, temperature_range, description) VALUES
  ('Room Temperature', '15-25°C', 'Normal storage'),
  ('Below 50°C', '<50°C', 'Cool storage'),
  ('Refrigerated', '2-8°C', 'Refrigerator storage'),
  ('Frozen', '<0°C', 'Freezer storage')
ON CONFLICT (location_name) DO NOTHING;

-- Racks
INSERT INTO racks (rack_code, rack_name) VALUES
  ('A1', 'Rack A1'),
  ('A2', 'Rack A2'),
  ('B1', 'Rack B1'),
  ('B2', 'Rack B2'),
  ('R-001', 'Rack 001')
ON CONFLICT (rack_code) DO NOTHING;

-- Reorder Terms
INSERT INTO reorder_terms (term_name, preset_formula, description) VALUES
  ('Reorder Point + 10', 'reorder_point + 10', 'Add 10 units to reorder point'),
  ('Reorder Point + 20', 'reorder_point + 20', 'Add 20 units to reorder point'),
  ('Reorder Point + 50', 'reorder_point + 50', 'Add 50 units to reorder point'),
  ('Prescription Not Needed', NULL, 'No prescription required'),
  ('Doctor Prescription Required', NULL, 'Requires doctor prescription')
ON CONFLICT (term_name) DO NOTHING;

-- Manufacturers
INSERT INTO manufacturers (name) VALUES
  ('Cipla'),
  ('Sun Pharma'),
  ('Dr. Reddy''s'),
  ('Lupin'),
  ('Alkem Laboratories')
ON CONFLICT (name) DO NOTHING;

-- Brands
INSERT INTO brands (name) VALUES
  ('Brand A'),
  ('Brand B'),
  ('Generic')
ON CONFLICT (name) DO NOTHING;

-- Vendors
INSERT INTO vendors (vendor_name, vendor_type, phone) VALUES
  ('Vendor A', 'distributor', '+91-9876543210'),
  ('Vendor B', 'distributor', '+91-9876543211'),
  ('ABC Pharma', 'manufacturer', '+91-9876543212')
ON CONFLICT (vendor_name) DO NOTHING;

-- ============================================
-- CONFIRMATION
-- ============================================
SELECT 'Products schema created successfully!' AS status;
SELECT '12 tables created with indexes and RLS policies' AS info;
SELECT COUNT(*) AS unit_count FROM units;
SELECT COUNT(*) AS category_count FROM categories;
SELECT COUNT(*) AS tax_rate_count FROM tax_rates;
