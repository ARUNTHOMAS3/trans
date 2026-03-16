-- Dummy Data for ZERPAI ERP Lookup Tables
-- Run this script in your Supabase SQL Editor
-- This script will CREATE missing tables first, then INSERT data.

-- ============================================================================
-- 1. TABLE CREATION (Ensure Schema Exists)
-- ============================================================================

CREATE TABLE IF NOT EXISTS units (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  unit_name VARCHAR(50) NOT NULL UNIQUE,
  unit_symbol VARCHAR(10),
  unit_type VARCHAR(50), 
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS manufacturers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  contact_info JSONB,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS brands (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL UNIQUE,
  manufacturer_id UUID REFERENCES manufacturers(id),
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS vendors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_name VARCHAR(255) NOT NULL UNIQUE,
  contact_person VARCHAR(255),
  email VARCHAR(255),
  phone VARCHAR(50),
  address TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS storage_locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  location_name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS racks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rack_code VARCHAR(50) NOT NULL UNIQUE,
  rack_name VARCHAR(255),
  storage_id UUID REFERENCES storage_locations(id),
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS reorder_terms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  term_name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

-- Note: 'account_type' enum might need to be created if it doesn't exist, 
-- but for robustness we'll simpler VARCHAR checks or rely on existing types if present.
-- For this script, we assume the Enum type 'account_type' might exist or we use text.
-- To avoid complex PL/SQL for enum checking, we just create table assuming standard types.
CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  account_code VARCHAR(50),
  account_name VARCHAR(255) NOT NULL UNIQUE,
  account_type VARCHAR(50), -- kept generic for safety in seed script
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tax_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tax_name VARCHAR(100) NOT NULL UNIQUE,
  tax_rate DECIMAL(5,2) NOT NULL,
  description TEXT,
  tax_type VARCHAR(50),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS contents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_name VARCHAR(255) NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS strengths (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  strength_name VARCHAR(100) NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shedule_name VARCHAR(100) NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS content_unit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

-- ============================================================================
-- 2. DATA INSERTION
-- ============================================================================

-- 0. UNITS (Essential for Product Creation)
INSERT INTO units (id, unit_name, unit_symbol, unit_type, is_active) VALUES
('10000000-0000-0000-0000-000000000001', 'Kilogram', 'kg', 'weight', true),
('10000000-0000-0000-0000-000000000002', 'Pieces', 'pcs', 'count', true),
('10000000-0000-0000-0000-000000000003', 'Liter', 'l', 'volume', true),
('10000000-0000-0000-0000-000000000004', 'Meter', 'm', 'length', true),
('10000000-0000-0000-0000-000000000005', 'Box', 'box', 'count', true)
ON CONFLICT (unit_name) DO NOTHING;

-- 1. MANUFACTURERS
INSERT INTO manufacturers (id, name, is_active) VALUES
('20000000-0000-0000-0000-000000000001', 'Cipla Ltd', true),
('20000000-0000-0000-0000-000000000002', 'Sun Pharma', true),
('20000000-0000-0000-0000-000000000003', 'Dr. Reddy''s Laboratories', true),
('20000000-0000-0000-0000-000000000004', 'Lupin Limited', true),
('20000000-0000-0000-0000-000000000005', 'Torrent Pharmaceuticals', true)
ON CONFLICT (name) DO NOTHING;

-- 2. BRANDS
INSERT INTO brands (id, name, is_active) VALUES
('30000000-0000-0000-0000-000000000001', 'Crocin', true),
('30000000-0000-0000-0000-000000000002', 'Dolo', true),
('30000000-0000-0000-0000-000000000003', 'Combiflam', true),
('30000000-0000-0000-0000-000000000004', 'Vicks', true),
('30000000-0000-0000-0000-000000000005', 'Disprin', true)
ON CONFLICT (name) DO NOTHING;

-- 3. VENDORS
INSERT INTO vendors (id, vendor_name, contact_person, email, phone, address, is_active) VALUES
('40000000-0000-0000-0000-000000000001', 'MedSupply Co.', 'Rajesh Kumar', 'rajesh@medsupply.com', '+91-9876543210', 'Mumbai, Maharashtra', true),
('40000000-0000-0000-0000-000000000002', 'PharmaDirect', 'Priya Sharma', 'priya@pharmadirect.com', '+91-9876543211', 'Delhi, India', true),
('40000000-0000-0000-0000-000000000003', 'HealthCare Distributors', 'Amit Patel', 'amit@healthcare.com', '+91-9876543212', 'Ahmedabad, Gujarat', true),
('40000000-0000-0000-0000-000000000004', 'MediTrade Solutions', 'Sneha Reddy', 'sneha@meditrade.com', '+91-9876543213', 'Hyderabad, Telangana', true),
('40000000-0000-0000-0000-000000000005', 'Global Pharma Suppliers', 'Vikram Singh', 'vikram@globalpharma.com', '+91-9876543214', 'Bangalore, Karnataka', true)
ON CONFLICT (vendor_name) DO NOTHING;

-- 4. STORAGE LOCATIONS
INSERT INTO storage_locations (id, location_name, description, is_active) VALUES
('50000000-0000-0000-0000-000000000001', 'Main Warehouse', 'Primary storage facility', true),
('50000000-0000-0000-0000-000000000002', 'Cold Storage', 'Temperature controlled storage', true),
('50000000-0000-0000-0000-000000000003', 'Retail Counter', 'Front desk storage', true),
('50000000-0000-0000-0000-000000000004', 'Back Office', 'Office storage area', true),
('50000000-0000-0000-0000-000000000005', 'Emergency Stock', 'Emergency medicines storage', true)
ON CONFLICT (location_name) DO NOTHING;

-- 5. RACKS
INSERT INTO racks (id, rack_code, rack_name, storage_id, is_active) VALUES
('60000000-0000-0000-0000-000000000001', 'R-A1', 'Rack A1', (SELECT id FROM storage_locations WHERE location_name = 'Main Warehouse' LIMIT 1), true),
('60000000-0000-0000-0000-000000000002', 'R-A2', 'Rack A2', (SELECT id FROM storage_locations WHERE location_name = 'Main Warehouse' LIMIT 1), true),
('60000000-0000-0000-0000-000000000003', 'R-B1', 'Rack B1', (SELECT id FROM storage_locations WHERE location_name = 'Main Warehouse' LIMIT 1), true),
('60000000-0000-0000-0000-000000000004', 'R-CS1', 'Cold Storage Rack 1', (SELECT id FROM storage_locations WHERE location_name = 'Cold Storage' LIMIT 1), true),
('60000000-0000-0000-0000-000000000005', 'R-RC1', 'Retail Counter Rack', (SELECT id FROM storage_locations WHERE location_name = 'Retail Counter' LIMIT 1), true)
ON CONFLICT (rack_code) DO NOTHING;

-- 6. REORDER TERMS
INSERT INTO reorder_terms (id, term_name, description, is_active) VALUES
('70000000-0000-0000-0000-000000000001', 'Weekly Reorder', 'Reorder every week', true),
('70000000-0000-0000-0000-000000000002', 'Monthly Reorder', 'Reorder every month', true),
('70000000-0000-0000-0000-000000000003', 'Quarterly Reorder', 'Reorder every quarter', true),
('70000000-0000-0000-0000-000000000004', 'On Demand', 'Reorder when needed', true),
('70000000-0000-0000-0000-000000000005', 'Auto Reorder', 'Automatic reorder when stock is low', true)
ON CONFLICT (term_name) DO NOTHING;

-- 7. ACCOUNTS (Chart of Accounts)
INSERT INTO accounts (id, account_code, account_name, account_type, is_active) VALUES
('80000000-0000-0000-0000-000000000001', 'ACC-1001', 'Sales Revenue', 'sales', true),
('80000000-0000-0000-0000-000000000002', 'ACC-2001', 'Cost of Goods Sold', 'expense', true),
('80000000-0000-0000-0000-000000000003', 'ACC-3001', 'Inventory Asset', 'inventory', true),
('80000000-0000-0000-0000-000000000004', 'ACC-4001', 'Accounts Receivable', 'asset', true),
('80000000-0000-0000-0000-000000000005', 'ACC-5001', 'Accounts Payable', 'purchase', true),
('80000000-0000-0000-0000-000000000006', 'ACC-6001', 'Purchase Expense', 'expense', true),
('80000000-0000-0000-0000-000000000007', 'ACC-7001', 'Operating Expenses', 'expense', true)
ON CONFLICT (account_name) DO NOTHING;

-- 8. TAX RATES
INSERT INTO tax_rates (id, tax_name, tax_rate, is_active) VALUES
('90000000-0000-0000-0000-000000000001', 'GST 0%', 0.00, true),
('90000000-0000-0000-0000-000000000002', 'GST 5%', 5.00, true),
('90000000-0000-0000-0000-000000000003', 'GST 12%', 12.00, true),
('90000000-0000-0000-0000-000000000004', 'GST 18%', 18.00, true),
('90000000-0000-0000-0000-000000000005', 'GST 28%', 28.00, true)
ON CONFLICT (tax_name) DO NOTHING;

-- 9. CONTENTS (Generic Names / Salts)
INSERT INTO contents (id, content_name, is_active) VALUES
('a0000000-0000-0000-0000-000000000001', 'Paracetamol', true),
('a0000000-0000-0000-0000-000000000002', 'Ibuprofen', true),
('a0000000-0000-0000-0000-000000000003', 'Amoxicillin', true),
('a0000000-0000-0000-0000-000000000004', 'Cetirizine', true),
('a0000000-0000-0000-0000-000000000005', 'Metformin', true)
ON CONFLICT (content_name) DO NOTHING;

-- 10. STRENGTHS
INSERT INTO strengths (id, strength_name, is_active) VALUES
('b0000000-0000-0000-0000-000000000001', '500 mg', true),
('b0000000-0000-0000-0000-000000000002', '650 mg', true),
('b0000000-0000-0000-0000-000000000003', '10 mg', true),
('b0000000-0000-0000-0000-000000000004', '200 mg', true),
('b0000000-0000-0000-0000-000000000005', '500 mg/5ml', true)
ON CONFLICT (strength_name) DO NOTHING;

-- 11. SCHEDULES (Drug Schedules)
INSERT INTO schedules (id, shedule_name, is_active) VALUES
('c0000000-0000-0000-0000-000000000001', 'Schedule H', true),
('c0000000-0000-0000-0000-000000000002', 'Schedule H1', true),
('c0000000-0000-0000-0000-000000000003', 'Schedule G', true),
('c0000000-0000-0000-0000-000000000004', 'Schedule X', true),
('c0000000-0000-0000-0000-000000000005', 'OTC', true)
ON CONFLICT (shedule_name) DO NOTHING;

-- 12. CONTENT UNITS
INSERT INTO content_unit (id, name, is_active) VALUES
('d0000000-0000-0000-0000-000000000001', 'mg', true),
('d0000000-0000-0000-0000-000000000002', 'g', true),
('d0000000-0000-0000-0000-000000000003', 'ml', true),
('d0000000-0000-0000-0000-000000000004', 'mcg', true),
('d0000000-0000-0000-0000-000000000005', '% w/v', true)
ON CONFLICT (name) DO NOTHING;

-- Verify the data was inserted
SELECT 'Units' as table_name, COUNT(*) as count FROM units WHERE is_active = true
UNION ALL
SELECT 'Manufacturers', COUNT(*) FROM manufacturers WHERE is_active = true
UNION ALL
SELECT 'Brands', COUNT(*) FROM brands WHERE is_active = true
UNION ALL
SELECT 'Vendors', COUNT(*) FROM vendors WHERE is_active = true
UNION ALL
SELECT 'Storage Locations', COUNT(*) FROM storage_locations WHERE is_active = true
UNION ALL
SELECT 'Racks', COUNT(*) FROM racks WHERE is_active = true
UNION ALL
SELECT 'Reorder Terms', COUNT(*) FROM reorder_terms WHERE is_active = true
UNION ALL
SELECT 'Accounts', COUNT(*) FROM accounts WHERE is_active = true
UNION ALL
SELECT 'Tax Rates', COUNT(*) FROM tax_rates WHERE is_active = true
UNION ALL
SELECT 'Contents', COUNT(*) FROM contents WHERE is_active = true
UNION ALL
SELECT 'Strengths', COUNT(*) FROM strengths WHERE is_active = true
UNION ALL
SELECT 'Schedules', COUNT(*) FROM schedules WHERE is_active = true
UNION ALL
SELECT 'Content Units', COUNT(*) FROM content_unit WHERE is_active = true;
