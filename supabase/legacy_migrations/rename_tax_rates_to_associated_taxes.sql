-- =====================================================
-- Migration: Rename tax_rates to associated_taxes
-- Date: 2026-02-07
-- Description: Rename table and populate with CGST, SGST, IGST data
-- =====================================================

-- Step 1: Rename the table
ALTER TABLE IF EXISTS tax_rates RENAME TO associated_taxes;

-- Step 2: Clear existing data
TRUNCATE TABLE associated_taxes;

-- Step 3: Insert new tax data with tax_type classification
INSERT INTO associated_taxes (tax_name, tax_rate, tax_type, is_active) VALUES
-- CGST Rates
('CGST6', 6.00, 'CGST', true),
('CGST0', 0.00, 'CGST', true),
('CGST2.5', 2.50, 'CGST', true),
('CGST9', 9.00, 'CGST', true),
('CGST14', 14.00, 'CGST', true),

-- SGST Rates
('SGST6', 6.00, 'SGST', true),
('SGST0', 0.00, 'SGST', true),
('SGST2.5', 2.50, 'SGST', true),
('SGST9', 9.00, 'SGST', true),
('SGST14', 14.00, 'SGST', true),

-- IGST Rates (for Interstate transactions)
('IGST0', 0.00, 'IGST', true),
('IGST5', 5.00, 'IGST', true),
('IGST12', 12.00, 'IGST', true),
('IGST18', 18.00, 'IGST', true),
('IGST28', 28.00, 'IGST', true);

-- Step 4: Verify the migration
SELECT 
    tax_type,
    COUNT(*) as count,
    STRING_AGG(tax_name || ' (' || tax_rate || '%)', ', ' ORDER BY tax_rate) as taxes
FROM associated_taxes
WHERE is_active = true
GROUP BY tax_type
ORDER BY tax_type;

-- Display all records
SELECT * FROM associated_taxes ORDER BY tax_type, tax_rate;
