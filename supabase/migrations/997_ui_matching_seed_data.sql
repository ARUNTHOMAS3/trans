-- COMPREHENSIVE SEED DATA - PROPER v4 UUID FORMAT
-- Fixed to pass class-validator @IsUUID() (version 4)
-- Run this in Supabase SQL Editor

BEGIN;

-- Clean start to allow ID updates
TRUNCATE TABLE product_compositions, products, racks, storage_locations, accounts, reorder_terms, vendors, brands, manufacturers, tax_rates, categories, units CASCADE;

-- ========================================
-- 1. UNITS
-- ========================================
INSERT INTO units (id, unit_name, unit_symbol, unit_type) VALUES
('11111111-1111-4111-a111-111111111111', '1 x 10', '1x10', 'count'),
('22222222-2222-4222-a222-222222222222', '1 x 15', '1x15', 'count'),
('33333333-3333-4333-a333-333333333333', 'Bottle', 'Btl', 'count'),
('44444444-4444-4444-a444-444444444444', 'Box', 'Box', 'count'),
('55555555-5555-4555-a555-555555555555', 'Pieces', 'pcs', 'count'),
('66666666-6666-4666-a666-666666666666', 'Strip', 'strip', 'count'),
('77777777-7777-4777-a777-777777777777', 'Kilogram', 'kg', 'weight'),
('88888888-8888-4888-a888-888888888888', 'Gram', 'g', 'weight'),
('99999999-9999-4999-a999-999999999999', 'Liter', 'L', 'volume'),
('aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa', 'Milliliter', 'ml', 'volume'),
('bbbbbbbb-1111-4222-a333-444444444444', 'Vial', 'vial', 'count'),
('cccccccc-1111-4222-a333-444444444444', 'Ampoule', 'amp', 'count'),
('dddddddd-1111-4222-a333-444444444444', 'Sachet', 'sach', 'count'),
('eeeeeeee-1111-4222-a333-444444444444', 'Roll', 'roll', 'count'),
('ffffffff-1111-4222-a333-444444444444', 'Packet', 'pkt', 'count'),
('00000000-1111-4222-a333-444444444444', 'Cartridge', 'cart', 'count'),
('22221111-1111-4222-a333-444444444444', 'Tube', 'tube', 'count'),
('33332222-1111-4222-a333-444444444444', 'Jar', 'jar', 'count'),
('44443333-1111-4222-a333-444444444444', 'Drum', 'drum', 'count'),
('55554444-1111-4222-a333-444444444444', 'Ton', 'ton', 'weight')
ON CONFLICT (unit_name) DO UPDATE SET 
  id = EXCLUDED.id,
  unit_symbol = EXCLUDED.unit_symbol,
  unit_type = EXCLUDED.unit_type;

-- ========================================
-- 2. MANUFACTURERS
-- ========================================
INSERT INTO manufacturers (id, name) VALUES
('11111111-aaaa-4bbb-accc-111111111111', 'Cipla'),
('22222222-aaaa-4bbb-accc-222222222222', 'Sun Pharma'),
('33333333-aaaa-4bbb-accc-333333333333', 'Dr. Reddy''s'),
('44444444-aaaa-4bbb-accc-444444444444', 'Lupin'),
('55555555-aaaa-4bbb-accc-555555555555', 'Alkem Laboratories')
ON CONFLICT (name) DO UPDATE SET id = EXCLUDED.id;

-- ========================================
-- 3. BRANDS
-- ========================================
INSERT INTO brands (id, name, manufacturer_id) VALUES
('bbbbbbbb-1111-4222-a333-111111111111', 'Brand A', '11111111-aaaa-4bbb-accc-111111111111'),
('bbbbbbbb-1111-4222-a333-222222222222', 'Brand B', '22222222-aaaa-4bbb-accc-222222222222'),
('bbbbbbbb-1111-4222-a333-333333333333', 'Generic', null)
ON CONFLICT (name) DO UPDATE SET 
  id = EXCLUDED.id,
  manufacturer_id = EXCLUDED.manufacturer_id;

-- ========================================
-- 4. VENDORS
-- ========================================
INSERT INTO vendors (id, vendor_name, vendor_type, phone) VALUES
('eeeeeeee-1111-4222-a333-111111111111', 'Vendor A', 'distributor', '+91-9876543210'),
('eeeeeeee-1111-4222-a333-222222222222', 'Vendor B', 'distributor', '+91-9876543211'),
('eeeeeeee-1111-4222-a333-333333333333', 'Vendor C', 'wholesaler', '+91-9876543212')
ON CONFLICT (vendor_name) DO UPDATE SET 
  id = EXCLUDED.id,
  vendor_type = EXCLUDED.vendor_type,
  phone = EXCLUDED.phone;

-- ========================================
-- 5. CATEGORIES
-- ========================================
INSERT INTO categories (id, name, description) VALUES
('cccccccc-1111-4222-a333-111111111111', 'Medicines - General', 'Over-the-counter and prescription medicines'),
('cccccccc-1111-4222-a333-222222222222', 'Medicines - Antibiotics', 'Antibiotic medications'),
('cccccccc-1111-4222-a333-333333333333', 'Medicines - Analgesics', 'Pain relief medications'),
('cccccccc-1111-4222-a333-444444444444', 'Surgical Items', 'Surgical equipment and disposables'),
('cccccccc-1111-4222-a333-555555555555', 'Cosmetics', 'Beauty and personal care products'),
('cccccccc-1111-4222-a333-666666666666', 'Services', 'Consultation and other services'),
('cccccccc-1111-4222-a333-777777777777', 'OTHER BRANDS', 'Other brand products')
ON CONFLICT (name) DO UPDATE SET 
  id = EXCLUDED.id,
  description = EXCLUDED.description;

-- ========================================
-- 6. TAX RATES
-- ========================================
INSERT INTO tax_rates (id, tax_name, tax_rate, tax_type) VALUES
('aaaaaaaa-1111-4222-a333-000000000000', 'GST 0%', 0.00, 'CGST'),
('aaaaaaaa-1111-4222-a333-555555555555', 'GST 5%', 5.00, 'CGST'),
('aaaaaaaa-1111-4222-a333-121212121212', 'GST 12%', 12.00, 'CGST'),
('aaaaaaaa-1111-4222-a333-181818181818', 'GST 18%', 18.00, 'CGST'),
('aaaaaaaa-1111-4222-a333-282828282828', 'GST 28%', 28.00, 'CGST'),
('bbbbbbbb-2222-4333-a444-000000000000', 'IGST 0%', 0.00, 'IGST'),
('bbbbbbbb-2222-4333-a444-555555555555', 'IGST 5%', 5.00, 'IGST'),
('bbbbbbbb-2222-4333-a444-121212121212', 'IGST 12%', 12.00, 'IGST'),
('bbbbbbbb-2222-4333-a444-181818181818', 'IGST 18%', 18.00, 'IGST'),
('bbbbbbbb-2222-4333-a444-282828282828', 'IGST 28%', 28.00, 'IGST')
ON CONFLICT (tax_name) DO UPDATE SET 
  id = EXCLUDED.id,
  tax_rate = EXCLUDED.tax_rate,
  tax_type = EXCLUDED.tax_type;

-- ========================================
-- 7. ACCOUNTS
-- ========================================
INSERT INTO accounts (id, account_name, account_type, account_code) VALUES
('aaaaaaaa-3333-4444-a555-111111111111', 'Sales - Retail', 'sales', 'SAL-001'),
('aaaaaaaa-3333-4444-a555-222222222222', 'Sales - Wholesale', 'sales', 'SAL-002'),
('bbbbbbbb-aaaa-4bbb-accc-111111111111', 'Cost Of Goods Sold', 'expense', 'COGS-001'),
('bbbbbbbb-aaaa-4bbb-accc-222222222222', 'Purchase Account', 'purchase', 'PUR-001'),
('cccccccc-aaaa-4bbb-accc-111111111111', 'Inventory - Medicines', 'inventory', 'INV-001'),
('cccccccc-aaaa-4bbb-accc-222222222222', 'Inventory - FMCG', 'inventory', 'INV-002'),
('cccccccc-aaaa-4bbb-accc-333333333333', 'Inventory - General', 'inventory', 'INV-003')
ON CONFLICT (account_name) DO UPDATE SET 
  id = EXCLUDED.id,
  account_type = EXCLUDED.account_type,
  account_code = EXCLUDED.account_code;

-- ========================================
-- 8. STORAGE LOCATIONS
-- ========================================
INSERT INTO storage_locations (id, location_name, temperature_range, description) VALUES
('dddddddd-1111-4222-a333-111111111111', 'Room Temperature', '15-25°C', 'Normal storage'),
('dddddddd-1111-4222-a333-222222222222', 'Below 50°C', '<50°C', 'Cool storage'),
('dddddddd-1111-4222-a333-333333333333', 'Refrigerated', '2-8°C', 'Refrigerator storage'),
('dddddddd-1111-4222-a333-444444444444', 'Frozen', '<0°C', 'Freezer storage')
ON CONFLICT (location_name) DO UPDATE SET 
  id = EXCLUDED.id,
  temperature_range = EXCLUDED.temperature_range,
  description = EXCLUDED.description;

-- ========================================
-- 9. RACKS
-- ========================================
INSERT INTO racks (id, rack_code, rack_name, storage_id) VALUES
('eeeeeeee-aaaa-4bbb-accc-111111111111', 'A1', 'Rack A1 - Medicines', 'dddddddd-1111-4222-a333-111111111111'),
('eeeeeeee-aaaa-4bbb-accc-222222222222', 'A2', 'Rack A2 - FMCG', 'dddddddd-1111-4222-a333-111111111111'),
('eeeeeeee-aaaa-4bbb-accc-333333333333', 'B1', 'Rack B1 - Cosmetics', 'dddddddd-1111-4222-a333-111111111111'),
('eeeeeeee-aaaa-4bbb-accc-444444444444', 'B2', 'Rack B2 - Surgical', 'dddddddd-1111-4222-a333-111111111111'),
('eeeeeeee-aaaa-4bbb-accc-555555555555', 'R-001', 'Rack 001', 'dddddddd-1111-4222-a333-111111111111')
ON CONFLICT (rack_code) DO UPDATE SET 
  id = EXCLUDED.id,
  rack_name = EXCLUDED.rack_name,
  storage_id = EXCLUDED.storage_id;

-- ========================================
-- 10. REORDER TERMS
-- ========================================
INSERT INTO reorder_terms (id, term_name, preset_formula, description) VALUES
('ffffffff-aaaa-4bbb-accc-111111111111', 'Reorder Point + 10', 'reorder_point + 10', 'Add 10 units to reorder point'),
('ffffffff-aaaa-4bbb-accc-222222222222', 'Reorder Point + 20', 'reorder_point + 20', 'Add 20 units to reorder point'),
('ffffffff-aaaa-4bbb-accc-333333333333', 'Reorder Point + 50', 'reorder_point + 50', 'Add 50 units to reorder point'),
('ffffffff-aaaa-4bbb-accc-444444444444', 'Prescription Not Needed', null, 'No prescription required'),
('ffffffff-aaaa-4bbb-accc-555555555555', 'Doctor Prescription Required', null, 'Requires doctor prescription')
ON CONFLICT (term_name) DO UPDATE SET 
  id = EXCLUDED.id,
  preset_formula = EXCLUDED.preset_formula,
  description = EXCLUDED.description;

-- ========================================
-- 11. SAMPLE PRODUCTS
-- ========================================
INSERT INTO products (
  id, type, product_name, item_code, sku, unit_id, category_id,
  tax_preference, intra_state_tax_id, inter_state_tax_id,
  manufacturer_id, brand_id,
  selling_price, sales_account_id,
  cost_price, purchase_account_id, preferred_vendor_id,
  inventory_account_id, inventory_valuation_method,
  storage_id, rack_id,
  is_active
) VALUES
(
  'aaaaaaaa-bbbb-4ccc-addd-111111111111',
  'goods',
  'Paracetamol 500mg Tablet',
  'MED-001',
  'PARA-500',
  '55555555-5555-4555-a555-555555555555',
  'cccccccc-1111-4222-a333-111111111111',
  'taxable',
  'aaaaaaaa-1111-4222-a333-121212121212',
  'bbbbbbbb-2222-4333-a444-121212121212',
  '11111111-aaaa-4bbb-accc-111111111111',
  'bbbbbbbb-1111-4222-a333-333333333333',
  10.00,
  'aaaaaaaa-3333-4444-a555-111111111111',
  7.50,
  'bbbbbbbb-aaaa-4bbb-accc-111111111111',
  'eeeeeeee-1111-4222-a333-111111111111',
  'cccccccc-aaaa-4bbb-accc-111111111111',
  'FIFO',
  'dddddddd-1111-4222-a333-111111111111',
  'eeeeeeee-aaaa-4bbb-accc-111111111111',
  true
),
(
  'aaaaaaaa-bbbb-4ccc-addd-222222222222',
  'goods',
  'Amoxicillin 500mg Capsule',
  'MED-002',
  'AMOX-500',
  '66666666-6666-4666-a666-666666666666',
  'cccccccc-1111-4222-a333-222222222222',
  'taxable',
  'aaaaaaaa-1111-4222-a333-121212121212',
  'bbbbbbbb-2222-4333-a444-121212121212',
  '22222222-aaaa-4bbb-accc-222222222222',
  'bbbbbbbb-1111-4222-a333-111111111111',
  120.00,
  'aaaaaaaa-3333-4444-a555-111111111111',
  95.00,
  'bbbbbbbb-aaaa-4bbb-accc-111111111111',
  'eeeeeeee-1111-4222-a333-222222222222',
  'cccccccc-aaaa-4bbb-accc-111111111111',
  'Weighted Average',
  'dddddddd-1111-4222-a333-222222222222',
  'eeeeeeee-aaaa-4bbb-accc-111111111111',
  true
)
ON CONFLICT (item_code) DO NOTHING;

COMMIT;

-- ========================================
-- VERIFICATION
-- ========================================
SELECT '✅ Seed data upserted successfully!' as status;
SELECT '✅ Units: ' || COUNT(*) as count FROM units;
