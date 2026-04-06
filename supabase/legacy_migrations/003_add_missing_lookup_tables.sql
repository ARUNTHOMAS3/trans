-- Add missing lookup tables for product composition and drug management
-- These tables are referenced by the backend but were missing from the schema

-- Contents Table (for product composition ingredients)
CREATE TABLE IF NOT EXISTS contents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_content VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Strengths Table (for product composition strength values)
CREATE TABLE IF NOT EXISTS strengths (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_strength VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Buying Rules Table (for purchase rules and regulations)
CREATE TABLE IF NOT EXISTS buying_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  rule_name VARCHAR(255) NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Drug Schedules Table (for drug classification and scheduling)
CREATE TABLE IF NOT EXISTS drug_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  regulatory_info TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_contents_active ON contents(is_active);
CREATE INDEX IF NOT EXISTS idx_strengths_active ON strengths(is_active);
CREATE INDEX IF NOT EXISTS idx_buying_rules_active ON buying_rules(is_active);
CREATE INDEX IF NOT EXISTS idx_drug_schedules_active ON drug_schedules(is_active);

-- Insert some common seed data
INSERT INTO contents (item_content) VALUES
  ('Paracetamol'),
  ('Ibuprofen'),
  ('Amoxicillin'),
  ('Cetirizine'),
  ('Omeprazole')
ON CONFLICT (item_content) DO NOTHING;

INSERT INTO strengths (item_strength) VALUES
  ('500mg'),
  ('250mg'),
  ('100mg'),
  ('10mg'),
  ('5mg')
ON CONFLICT (item_strength) DO NOTHING;

INSERT INTO buying_rules (rule_name, description) VALUES
  ('Prescription Required', 'Requires valid prescription from registered medical practitioner'),
  ('OTC - Over The Counter', 'Can be sold without prescription'),
  ('Controlled Substance', 'Requires special authorization and record keeping')
ON CONFLICT (rule_name) DO NOTHING;

INSERT INTO drug_schedules (schedule_name, description) VALUES
  ('Schedule H', 'Prescription drug - requires prescription'),
  ('Schedule H1', 'Restricted prescription drug'),
  ('Schedule X', 'Narcotic and psychotropic substances'),
  ('Non-Scheduled', 'Over-the-counter drugs')
ON CONFLICT (schedule_name) DO NOTHING;

SELECT '✅ Missing lookup tables created successfully!' as status;
