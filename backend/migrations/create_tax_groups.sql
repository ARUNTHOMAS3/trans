-- Create tax_groups table
CREATE TABLE IF NOT EXISTS tax_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_group_name VARCHAR(100) NOT NULL UNIQUE,
    tax_rate DECIMAL(5, 2) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create tax_group_taxes junction table
CREATE TABLE IF NOT EXISTS tax_group_taxes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tax_group_id UUID REFERENCES tax_groups(id) ON DELETE CASCADE,
    tax_id UUID REFERENCES associate_taxes(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Populate tax_groups
INSERT INTO tax_groups (tax_group_name, tax_rate) VALUES
('GST0', 0.00),
('GST5', 5.00),
('GST12', 12.00),
('GST18', 18.00),
('GST28', 28.00)
ON CONFLICT (tax_group_name) DO NOTHING;

-- Link tax_groups to associate_taxes (CGST + SGST)
-- GST0
INSERT INTO tax_group_taxes (tax_group_id, tax_id)
SELECT tg.id, at.id FROM tax_groups tg, associate_taxes at
WHERE tg.tax_group_name = 'GST0' AND at.tax_name IN ('CGST0', 'SGST0')
ON CONFLICT DO NOTHING;

-- GST5
INSERT INTO tax_group_taxes (tax_group_id, tax_id)
SELECT tg.id, at.id FROM tax_groups tg, associate_taxes at
WHERE tg.tax_group_name = 'GST5' AND at.tax_name IN ('CGST2.5', 'SGST2.5')
ON CONFLICT DO NOTHING;

-- GST12
INSERT INTO tax_group_taxes (tax_group_id, tax_id)
SELECT tg.id, at.id FROM tax_groups tg, associate_taxes at
WHERE tg.tax_group_name = 'GST12' AND at.tax_name IN ('CGST6', 'SGST6')
ON CONFLICT DO NOTHING;

-- GST18
INSERT INTO tax_group_taxes (tax_group_id, tax_id)
SELECT tg.id, at.id FROM tax_groups tg, associate_taxes at
WHERE tg.tax_group_name = 'GST18' AND at.tax_name IN ('CGST9', 'SGST9')
ON CONFLICT DO NOTHING;

-- GST28
INSERT INTO tax_group_taxes (tax_group_id, tax_id)
SELECT tg.id, at.id FROM tax_groups tg, associate_taxes at
WHERE tg.tax_group_name = 'GST28' AND at.tax_name IN ('CGST14', 'SGST14')
ON CONFLICT DO NOTHING;

-- Verification
SELECT tg.tax_group_name, tg.tax_rate, string_agg(at.tax_name, ', ') as components
FROM tax_groups tg
JOIN tax_group_taxes tgt ON tg.id = tgt.tax_group_id
JOIN associate_taxes at ON tgt.tax_id = at.id
GROUP BY tg.tax_group_name, tg.tax_rate
ORDER BY tg.tax_rate;
