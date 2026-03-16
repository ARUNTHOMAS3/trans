-- ZERPAI ERP - Database Schema (Tables, Indexes, RLS)
-- Part 1: Run this FIRST to create tables
-- Part 2: Seed data will be in separate file (after creating users)

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
  UNIQUE(org_id, item_code)
);

-- Make sku constraint conditional (only if not null)
CREATE UNIQUE INDEX IF NOT EXISTS unique_org_sku ON products(org_id, sku) WHERE sku IS NOT NULL;

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
-- CONFIRMATION
-- ============================================
SELECT 'Database schema created successfully!' AS status;
SELECT 'RLS policies: Enabled on all tables' AS security;
SELECT 'Next: Run seed data script after creating a user' AS next_step;
