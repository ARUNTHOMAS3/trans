-- Create missing lookup tables for Items module
-- Run this script in Supabase SQL Editor to create the schema structure

-- 1. CONTENTS
CREATE TABLE IF NOT EXISTS contents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_name VARCHAR(255) NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

-- 2. STRENGTHS
CREATE TABLE IF NOT EXISTS strengths (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  strength_name VARCHAR(100) NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

-- 3. CONTENT UNITS
CREATE TABLE IF NOT EXISTS content_unit (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(50) NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

-- 4. SCHEDULES (Drug Schedules)
CREATE TABLE IF NOT EXISTS schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  shedule_name VARCHAR(100) NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

-- 5. BUYING RULES
CREATE TABLE IF NOT EXISTS buying_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_rule VARCHAR(255) NOT NULL UNIQUE,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT now()
);

-- 6. PRODUCT COMPOSITIONS (Child table for Items)
CREATE TABLE IF NOT EXISTS product_compositions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  content_id UUID REFERENCES contents(id),
  strength_id UUID REFERENCES strengths(id),
  content_unit_id UUID REFERENCES content_unit(id),
  shedule_id UUID REFERENCES schedules(id),
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT now()
);
