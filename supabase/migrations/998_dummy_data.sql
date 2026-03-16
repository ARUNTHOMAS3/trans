-- Comprehensive Dummy Data for Testing
-- Run this in Supabase SQL Editor

-- 1. UNITS (measurement units)
INSERT INTO units (id, unit_name, unit_symbol, is_base_unit, base_unit_id, conversion_factor) VALUES
('11111111-1111-1111-1111-111111111111', 'Piece', 'Pc', true, null, 1),
('22222222-2222-2222-2222-222222222222', 'Box (10 Pcs)', 'Box', false, '11111111-1111-1111-1111-111111111111', 10),
('33333333-3333-3333-3333-333333333333', 'Strip (10 Tablets)', 'Strip', false, '11111111-1111-1111-1111-111111111111', 10),
('44444444-4444-4444-4444-444444444444', 'Bottle', 'Btl', true, null, 1),
('55555555-5555-5555-5555-555555555555', 'Kilogram', 'kg', true, null, 1)
ON CONFLICT (id) DO NOTHING;

-- 2. CATEGORIES
INSERT INTO categories (id, name, description) VALUES
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Medicines', 'Pharmaceutical products'),
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'FMCG', 'Fast Moving Consumer Goods'),
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Cosmetics', 'Beauty and personal care'),
('dddddddd-dddd-dddd-dddd-dddddddddddd', 'Surgical Items', 'Medical equipment')
ON CONFLICT (id) DO NOTHING;

-- 3. TAX RATES
INSERT INTO tax_rates (id, tax_name, tax_rate, tax_type) VALUES
('ttttttt1-1111-1111-1111-111111111111', 'GST 0%', 0, 'GST'),
('ttttttt2-2222-2222-2222-222222222222', 'GST 5%', 5, 'GST'),
('ttttttt3-3333-3333-3333-333333333333', 'GST 12%', 12, 'GST'),
('ttttttt4-4444-4444-4444-444444444444', 'GST 18%', 18, 'GST'),
('ttttttt5-5555-5555-5555-555555555555', 'GST 28%', 28, 'GST')
ON CONFLICT (id) DO NOTHING;

-- 4. MANUFACTURERS
INSERT INTO manufacturers (id, name, country, contact_email) VALUES
('mmmmmmm1-1111-1111-1111-111111111111', 'Cipla', 'India', 'contact@cipla.com'),
('mmmmmmm2-2222-2222-2222-222222222222', 'Sun Pharma', 'India', 'contact@sunpharma.com'),
('mmmmmmm3-3333-3333-3333-333333333333', 'Dr. Reddys', 'India', 'contact@drreddys.com'),
('mmmmmmm4-4444-4444-4444-444444444444', 'Mankind Pharma', 'India', 'contact@mankind.com')
ON CONFLICT (id) DO NOTHING;

-- 5. BRANDS
INSERT INTO brands (id, name, manufacturer_id) VALUES
('bbbbbbb1-1111-1111-1111-111111111111', 'Cipla Health', 'mmmmmmm1-1111-1111-1111-111111111111'),
('bbbbbbb2-2222-2222-2222-222222222222', 'Sun Premium', 'mmmmmmm2-2222-2222-2222-222222222222'),
('bbbbbbb3-3333-3333-3333-333333333333', 'Reddys Care', 'mmmmmmm3-3333-3333-3333-333333333333'),
('bbbbbbb4-4444-4444-4444-444444444444', 'Mankind Plus', 'mmmmmmm4-4444-4444-4444-444444444444')
ON CONFLICT (id) DO NOTHING;

-- 6. VENDORS (Suppliers)
INSERT INTO vendors (id, vendor_name, contact_person, phone, email, address) VALUES
('vvvvvvv1-1111-1111-1111-111111111111', 'MedSupply Corp', 'Rajesh Kumar', '9876543210', 'rajesh@medsupply.com', 'Mumbai, Maharashtra'),
('vvvvvvv2-2222-2222-2222-222222222222', 'HealthCare Distributors', 'Priya Sharma', '9876543211', 'priya@healthcare.com', 'Delhi, NCR'),
('vvvvvvv3-3333-3333-3333-333333333333', 'PharmaLink', 'Amit Patel', '9876543212', 'amit@pharmalink.com', 'Ahmedabad, Gujarat')
ON CONFLICT (id) DO NOTHING;

-- 7. STORAGE LOCATIONS
INSERT INTO storage_locations (id, location_name, location_type) VALUES
('sssssss1-1111-1111-1111-111111111111', 'Main Warehouse', 'warehouse'),
('sssssss2-2222-2222-2222-222222222222', 'Cold Storage', 'cold_storage'),
('sssssss3-3333-3333-3333-333333333333', 'Retail Floor', 'retail')
ON CONFLICT (id) DO NOTHING;

-- 8. RACKS
INSERT INTO racks (id, rack_code, rack_name, storage_location_id) VALUES
('rrrrrrr1-1111-1111-1111-111111111111', 'A1', 'Rack A1 - Medicines', 'sssssss1-1111-1111-1111-111111111111'),
('rrrrrrr2-2222-2222-2222-222222222222', 'B1', 'Rack B1 - FMCG', 'sssssss1-1111-1111-1111-111111111111'),
('rrrrrrr3-3333-3333-3333-333333333333', 'C1', 'Rack C1 - Cosmetics', 'sssssss3-3333-3333-3333-333333333333')
ON CONFLICT (id) DO NOTHING;

-- 9. REORDER TERMS
INSERT INTO reorder_terms (id, term_name, days) VALUES
('ttttttt1-term-term-term-111111111111', 'Weekly', 7),
('ttttttt2-term-term-term-222222222222', 'Bi-Weekly', 14),
('ttttttt3-term-term-term-333333333333', 'Monthly', 30)
ON CONFLICT (id) DO NOTHING;

-- 10. ACCOUNTS (Chart of Accounts)
INSERT INTO accounts (id, account_name, account_code, account_type) VALUES
('aaaaacc1-1111-1111-1111-111111111111', 'Sales - Retail', '4001', 'income'),
('aaaaacc2-2222-2222-2222-222222222222', 'Sales - Wholesale', '4002', 'income'),
('aaaaacc3-3333-3333-3333-333333333333', 'Cost Of Goods Sold', '5001', 'expense'),
('aaaaacc4-4444-4444-4444-444444444444', 'Inventory - Medicines', '1301', 'asset'),
('aaaaacc5-5555-5555-5555-555555555555', 'Inventory - FMCG', '1302', 'asset')
ON CONFLICT (id) DO NOTHING;

-- 11. SAMPLE PRODUCTS
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
  'ppppppp1-1111-1111-1111-111111111111',
  'goods',
  'Paracetamol 500mg',
  'MED-001',
  'PARA-500',
  '11111111-1111-1111-1111-111111111111', -- Piece
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', -- Medicines
  'taxable',
  'ttttttt3-3333-3333-3333-333333333333', -- GST 12%
  'ttttttt3-3333-3333-3333-333333333333',
  'mmmmmmm1-1111-1111-1111-111111111111', -- Cipla
  'bbbbbbb1-1111-1111-1111-111111111111',
  10.00,
  'aaaaacc1-1111-1111-1111-111111111111', -- Sales - Retail
  7.50,
  'aaaaacc3-3333-3333-3333-333333333333', -- COGS
  'vvvvvvv1-1111-1111-1111-111111111111',
  'aaaaacc4-4444-4444-4444-444444444444', -- Inventory
  'FIFO',
  'sssssss1-1111-1111-1111-111111111111',
  'rrrrrrr1-1111-1111-1111-111111111111',
  true
),
(
  'ppppppp2-2222-2222-2222-222222222222',
  'goods',
  'Hand Sanitizer 500ml',
  'FMCG-001',
  'SANI-500',
  '44444444-4444-4444-4444-444444444444', -- Bottle
  'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', -- FMCG
  'taxable',
  'ttttttt4-4444-4444-4444-444444444444', -- GST 18%
  'ttttttt4-4444-4444-4444-444444444444',
  'mmmmmmm2-2222-2222-2222-222222222222',
  'bbbbbbb2-2222-2222-2222-222222222222',
  150.00,
  'aaaaacc1-1111-1111-1111-111111111111',
  100.00,
  'aaaaacc3-3333-3333-3333-333333333333',
  'vvvvvvv2-2222-2222-2222-222222222222',
  'aaaaacc5-5555-5555-5555-555555555555',
  'Weighted Average',
  'sssssss1-1111-1111-1111-111111111111',
  'rrrrrrr2-2222-2222-2222-222222222222',
  true
)
ON CONFLICT (id) DO NOTHING;

-- Summary
SELECT 'Dummy data inserted successfully!' as status;
SELECT 'Units: ' || COUNT(*) as count FROM units;
SELECT 'Categories: ' || COUNT(*) as count FROM categories;
SELECT 'Tax Rates: ' || COUNT(*) as count FROM tax_rates;
SELECT 'Manufacturers: ' || COUNT(*) as count FROM manufacturers;
SELECT 'Brands: ' || COUNT(*) as count FROM brands;
SELECT 'Vendors: ' || COUNT(*) as count FROM vendors;
SELECT 'Storage Locations: ' || COUNT(*) as count FROM storage_locations;
SELECT 'Racks: ' || COUNT(*) as count FROM racks;
SELECT 'Reorder Terms: ' || COUNT(*) as count FROM reorder_terms;
SELECT 'Accounts: ' || COUNT(*) as count FROM accounts;
SELECT 'Products: ' || COUNT(*) as count FROM products;
