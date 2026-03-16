# Supabase Migration Instructions

## Step 1: Create Tables (Required)

Run this file in Supabase SQL Editor:
```
supabase/migrations/001_schema_only.sql
```

This creates:
- ✅ Tables: users, products, categories, vendors
- ✅ Indexes for performance
- ✅ RLS policies for multi-tenancy

## Step 2: Create a User (Required)

1. Go to Supabase Dashboard → Authentication → Users
2. Click "Add user" → "Create new user"
3. Enter email (e.g., `admin@example.com`) and password
4. Click "Create user"
5. **Copy the user ID** (UUID) from the user list

## Step 3: Insert Seed Data (Optional)

1. Open `supabase/migrations/002_seed_data.sql`
2. Replace `YOUR_USER_ID_HERE` with the user ID from Step 2
3. Run the modified SQL in Supabase SQL Editor

This inserts:
- 2 categories (Medicines, Surgical Items)
- 2 vendors (ABC Pharma, XYZ Medical Supplies)
- 4 products (Paracetamol, Amoxicillin, Gloves, Consultation)

## Verification

After running, verify in Supabase Table Editor:
```sql
SELECT COUNT(*) FROM products;    -- Should show 4
SELECT COUNT(*) FROM categories;  -- Should show 2
SELECT COUNT(*) FROM vendors;     -- Should show 2
```

## Notes

- The seed data script generates unique org_id and outlet_id
- These IDs will be printed in the query output
- You'll need these IDs for API testing (X-Org-Id header)
