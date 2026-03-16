-- ZERPAI ERP - Supabase Database Schema
-- Run this in Supabase SQL Editor

-- ============================================
-- 1. USERS TABLE (COMMENTED OUT FOR DEVELOPMENT)
-- ============================================
-- Users table disabled during development - no authentication required
-- Uncomment and modify for production use
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
-- 2. PRODUCTS TABLE (with multi-tenancy)
-- ============================================
CREATE TABLE IF NOT EXISTS products (
  -- Primary Key
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  
  -- Multi-tenant fields
  org_id UUID NOT NULL,
  outlet_id UUID,
  
  -- Core Identification
  type VARCHAR(50) NOT NULL CHECK (type IN ('goods', 'service', 'inventory', 'non-inventory')),
  billing_name VARCHAR(255) NOT NULL,
  alt_name VARCHAR(255),
  item_code VARCHAR(100) NOT NULL,
  sku VARCHAR(100),
  unit VARCHAR(50) NOT NULL,
  
  -- Categorization & Tax
  category_id UUID,
  is_referable BOOLEAN DEFAULT false,
  post_to_pub_to_ecommerce BOOLEAN DEFAULT false,
  hsn_code VARCHAR(50),
  tax_preference VARCHAR(50) CHECK (tax_preference IN ('taxable', 'non-taxable', 'exempt')),
  exemption_reason TEXT,
  tax_id UUID,
  is_composition BOOLEAN DEFAULT false,
  
  -- Pricing & Purchase
  buying_rate_id UUID,
  schedule_id UUID,
  mrp DECIMAL(15,2) DEFAULT 0,
  ptr DECIMAL(15,2) DEFAULT 0,
  piramids_id UUID,
  description TEXT,
  expirable BOOLEAN DEFAULT false,
  custprice DECIMAL(15,2) DEFAULT 0,
  purchase_pren_id UUID,
  vendor_id UUID,
  
  -- Inventory Management
  is_track_inventory BOOLEAN DEFAULT false,
  track_batch BOOLEAN DEFAULT false,
  inventory_account_id UUID,
  inventory_valuation_method VARCHAR(50) CHECK (inventory_valuation_method IN ('FIFO', 'LIFO', 'Weighted Average', 'Specific Identification')),
  storage_id UUID,
  reorder_pt INTEGER DEFAULT 0,
  reorderqty INTEGER DEFAULT 0,
  reorder_terms_id UUID,
  
  -- Regulatory & Flags
  is_bio_loc BOOLEAN DEFAULT false,
  is_other BOOLEAN DEFAULT false,
  is_locks BOOLEAN DEFAULT false,
  is_selectable BOOLEAN DEFAULT true,
  
  -- Audit Fields
  created_at TIMESTAMPTZ DEFAULT NOW(),
  created_by_id UUID,  -- Removed auth.users reference for development
  last_modified_by UUID,  -- Removed auth.users reference for development
  last_modified_date TIMESTAMPTZ,
  
  -- Constraints
  UNIQUE(org_id, item_code),
  UNIQUE(org_id, sku)
);

-- ============================================
-- 3. CATEGORIES TABLE
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
-- 4. VENDORS TABLE
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
-- INDEXES for Performance
-- ============================================
CREATE INDEX IF NOT EXISTS idx_products_org_outlet ON products(org_id, outlet_id);
CREATE INDEX IF NOT EXISTS idx_products_type ON products(type);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_vendor ON products(vendor_id);
CREATE INDEX IF NOT EXISTS idx_products_selectable ON products(is_selectable);
CREATE INDEX IF NOT EXISTS idx_products_item_code ON products(item_code);

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
-- SEED DATA
-- ============================================

-- Generate sample org_id and user_id
-- NOTE: Replace these UUIDs with actual auth.users() IDs after creating users
DO $$
DECLARE
  sample_org_id UUID := '00000000-0000-0000-0000-000000000001';
  sample_outlet_id UUID := '00000000-0000-0000-0000-000000000002';
  sample_user_id UUID := '00000000-0000-0000-0000-000000000003';
  cat_medicines UUID;
  cat_surgical UUID;
  vendor_abc UUID;
  vendor_xyz UUID;
BEGIN
  -- Insert sample categories
  INSERT INTO categories (id, org_id, name, description) VALUES
    (gen_random_uuid(), sample_org_id, 'Medicines', 'Pharmaceutical medicines')
    RETURNING id INTO cat_medicines;
    
  INSERT INTO categories (id, org_id, name, description) VALUES
    (gen_random_uuid(), sample_org_id, 'Surgical Items', 'Surgical equipment and supplies')
    RETURNING id INTO cat_surgical;

  -- Insert sample vendors
  INSERT INTO vendors (id, org_id, vendor_name, contact_person, phone) VALUES
    (gen_random_uuid(), sample_org_id, 'ABC Pharma', 'John Doe', '+91-9876543210')
    RETURNING id INTO vendor_abc;
    
  INSERT INTO vendors (id, org_id, vendor_name, contact_person, phone) VALUES
    (gen_random_uuid(), sample_org_id, 'XYZ Medical Supplies', 'Jane Smith', '+91-9876543211')
    RETURNING id INTO vendor_xyz;

  -- Insert sample products
  INSERT INTO products (
    org_id, outlet_id, type, billing_name, item_code, sku, unit,
    category_id, mrp, ptr, is_track_inventory, track_batch,
    expirable, is_selectable, created_by_id
  ) VALUES
    (
      sample_org_id, sample_outlet_id, 'goods', 
      'Paracetamol 500mg Tablet', 'MED-001', 'PARA-500-TAB', 'pcs',
      cat_medicines, 50.00, 40.00, true, true,
      true, true, sample_user_id
    ),
    (
      sample_org_id, sample_outlet_id, 'goods',
      'Amoxicillin 500mg Capsule', 'MED-002', 'AMOX-500-CAP', 'pcs',
      cat_medicines, 120.00, 95.00, true, true,
      true, true, sample_user_id
    ),
    (
      sample_org_id, sample_outlet_id, 'goods',
      'Surgical Gloves (Pair)', 'SUR-001', 'GLOVES-PAIR', 'pair',
      cat_surgical, 25.00, 20.00, true, false,
      false, true, sample_user_id
    ),
    (
      sample_org_id, sample_outlet_id, 'service',
      'Consultation Fee - General', 'SRV-001', 'CONSULT-GEN', 'service',
      NULL, 500.00, 500.00, false, false,
      false, true, sample_user_id
    );

END $$;

-- ============================================
-- CONFIRMATION
-- ============================================
SELECT 'Database schema and seed data created successfully!' AS status;
SELECT 'Tables created: users, products, categories, vendors' AS info;
SELECT COUNT(*) AS product_count FROM products;
SELECT COUNT(*) AS category_count FROM categories;
SELECT COUNT(*) AS vendor_count FROM vendors;
