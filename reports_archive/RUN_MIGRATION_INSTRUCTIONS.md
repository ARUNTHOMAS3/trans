# Run Migration: Add track_serial_number Column

This migration adds the `track_serial_number` boolean column to the products table.

## Option 1: Using Supabase Dashboard (Recommended)

1. Go to your Supabase project dashboard: https://supabase.com/dashboard/project/jhaqdcstdxynrbsomadt
2. Navigate to **SQL Editor**
3. Click **New Query**
4. Copy and paste the following SQL:

```sql
-- Add track_serial_number column to products table
ALTER TABLE products 
ADD COLUMN track_serial_number BOOLEAN DEFAULT false;

-- Add comment for documentation
COMMENT ON COLUMN products.track_serial_number IS 'Indicates whether serial number tracking is enabled for this product';

-- Create index for better query performance
CREATE INDEX idx_products_track_serial ON products(track_serial_number) WHERE track_serial_number = true;

-- Confirmation
SELECT 'track_serial_number column added successfully!' AS status;
```

5. Click **Run** to execute the migration

## Option 2: Using Backend API (Alternative)

If you have database migration capabilities in your backend, you can run the migration file:
- File location: `supabase/migrations/004_add_track_serial_number.sql`

## Verification

After running the migration, verify it was successful by running:

```sql
SELECT column_name, data_type, column_default 
FROM information_schema.columns 
WHERE table_name = 'products' 
AND column_name = 'track_serial_number';
```

Expected result:
- column_name: `track_serial_number`
- data_type: `boolean`
- column_default: `false`

## Next Steps

After the database migration is complete, you'll need to update:
1. Backend TypeScript types/interfaces
2. Frontend Dart models
3. API endpoints (if needed)
