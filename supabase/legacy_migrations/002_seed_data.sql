-- ZERPAI ERP - Seed Data
-- Run this AFTER creating a user in Supabase Auth
-- Replace YOUR_USER_ID_HERE with actual auth.users id

-- Get your user ID from: SELECT id FROM auth.users LIMIT 1;

DO $$
DECLARE
  sample_org_id UUID := gen_random_uuid();  -- Generate unique org
  sample_outlet_id UUID := gen_random_uuid();  -- Generate unique outlet
  your_user_id UUID := 'YOUR_USER_ID_HERE';  -- REPLACE THIS!
  cat_medicines UUID;
  cat_surgical UUID;
  vendor_abc UUID;
  vendor_xyz UUID;
BEGIN
  -- First, create user entry in users table
  INSERT INTO users (id, email, full_name, role, org_id, outlet_id)
  VALUES (
    your_user_id,
    'admin@example.com',  -- Match your Supabase Auth email
    'Admin User',
    'admin',
    sample_org_id,
    sample_outlet_id
  )
  ON CONFLICT (id) DO NOTHING;  -- Skip if already exists

  -- Insert sample categories
  INSERT INTO categories (org_id, name, description) VALUES
    (sample_org_id, 'Medicines', 'Pharmaceutical medicines')
    RETURNING id INTO cat_medicines;
    
  INSERT INTO categories (org_id, name, description) VALUES
    (sample_org_id, 'Surgical Items', 'Surgical equipment and supplies')
    RETURNING id INTO cat_surgical;

  -- Insert sample vendors
  INSERT INTO vendors (org_id, vendor_name, contact_person, phone) VALUES
    (sample_org_id, 'ABC Pharma', 'John Doe', '+91-9876543210')
    RETURNING id INTO vendor_abc;
    
  INSERT INTO vendors (org_id, vendor_name, contact_person, phone) VALUES
    (sample_org_id, 'XYZ Medical Supplies', 'Jane Smith', '+91-9876543211')
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
      true, true, your_user_id
    ),
    (
      sample_org_id, sample_outlet_id, 'goods',
      'Amoxicillin 500mg Capsule', 'MED-002', 'AMOX-500-CAP', 'pcs',
      cat_medicines, 120.00, 95.00, true, true,
      true, true, your_user_id
    ),
    (
      sample_org_id, sample_outlet_id, 'goods',
      'Surgical Gloves (Pair)', 'SUR-001', 'GLOVES-PAIR', 'pair',
      cat_surgical, 25.00, 20.00, true, false,
      false, true, your_user_id
    ),
    (
      sample_org_id, sample_outlet_id, 'service',
      'Consultation Fee - General', 'SRV-001', 'CONSULT-GEN', 'service',
      NULL, 500.00, 500.00, false, false,
      false, true, your_user_id
    );

  RAISE NOTICE 'Seed data inserted successfully!';
  RAISE NOTICE 'Org ID: %', sample_org_id;
  RAISE NOTICE 'Outlet ID: %', sample_outlet_id;
  RAISE NOTICE 'Products: 4, Categories: 2, Vendors: 2';
END $$;

-- Verify seed data
SELECT COUNT(*) AS product_count FROM products;
SELECT COUNT(*) AS category_count FROM categories;
SELECT COUNT(*) AS vendor_count FROM vendors;
