-- Add track_serial_number column to products table
-- Date: 2026-01-20

ALTER TABLE products 
ADD COLUMN track_serial_number BOOLEAN DEFAULT false;

-- Add comment for documentation
COMMENT ON COLUMN products.track_serial_number IS 'Indicates whether serial number tracking is enabled for this product';

-- Create index for better query performance
CREATE INDEX idx_products_track_serial ON products(track_serial_number) WHERE track_serial_number = true;

-- Confirmation
SELECT 'track_serial_number column added successfully!' AS status;
