# Tax Rates Migration Summary

## Overview
Renamed `tax_rates` table to `associated_taxes` and restructured the tax data to include CGST, SGST, and IGST classifications.

## Changes Made

### 1. Database Schema (`backend/src/db/schema.ts`)
- **Changed**: Renamed table from `tax_rates` to `associated_taxes`
- **Status**: ✅ Complete

### 2. Migration SQL (`backend/migrations/rename_tax_rates_to_associated_taxes.sql`)
- **Created**: SQL migration script
- **Actions**:
  - Renames `tax_rates` to `associated_taxes`
  - Clears existing data
  - Inserts new tax structure with tax_type classification
- **Status**: ⏳ Pending execution

### 3. Backend API Updates

#### Lookups Controller (`backend/src/lookups/lookups.controller.ts`)
- **Changed**: Updated both tableMap objects to reference `associated_taxes`
- **Status**: ✅ Complete

#### Products Service (`backend/src/modules/products/products.service.ts`)
- **Changed**: Updated all Supabase queries to use `associated_taxes`
- **Lines updated**: 233, 234, 264, 265, 848
- **Status**: ✅ Complete

### 4. Frontend Updates

#### Tax Rate Model (`lib/modules/items/items/models/tax_rate_model.dart`)
- **Status**: ✅ Already has `taxType` field

#### Default Tax Rates Section (`lib/modules/items/items/presentation/sections/default_tax_rates_section.dart`)
- **Changed**: Added filtering logic for interstate taxes
- **New Feature**: Interstate tax dropdown now shows only IGST type taxes
- **Status**: ✅ Complete

## New Tax Structure

### CGST (Central GST) - 5 rates
- CGST0 (0%)
- CGST2.5 (2.5%)
- CGST6 (6%)
- CGST9 (9%)
- CGST14 (14%)

### SGST (State GST) - 5 rates
- SGST0 (0%)
- SGST2.5 (2.5%)
- SGST6 (6%)
- SGST9 (9%)
- SGST14 (14%)

### IGST (Integrated GST) - 5 rates
- IGST0 (0%)
- IGST5 (5%)
- IGST12 (12%)
- IGST18 (18%)
- IGST28 (28%)

## Next Steps

### To Execute the Migration:

1. **Option 1: Supabase SQL Editor** (Recommended)
   - Open Supabase Dashboard
   - Go to SQL Editor
   - Copy and paste the contents of `backend/migrations/rename_tax_rates_to_associated_taxes.sql`
   - Execute the script

2. **Option 2: Using the Node.js Script**
   ```bash
   cd backend
   npx ts-node scripts/migrate-tax-rates.ts
   ```

### Post-Migration Verification:

1. Check that the table has been renamed:
   ```sql
   SELECT * FROM associated_taxes ORDER BY tax_type, tax_rate;
   ```

2. Verify the count:
   ```sql
   SELECT tax_type, COUNT(*) FROM associated_taxes GROUP BY tax_type;
   ```
   Expected result:
   - CGST: 5
   - SGST: 5
   - IGST: 5

3. Test the frontend:
   - Create/edit an item
   - Check that "Intra-state Tax" dropdown shows all taxes
   - Check that "Inter-state Tax" dropdown shows only IGST taxes

## Files Modified

### Backend
- ✅ `backend/src/db/schema.ts`
- ✅ `backend/src/lookups/lookups.controller.ts`
- ✅ `backend/src/modules/products/products.service.ts`
- ✅ `backend/migrations/rename_tax_rates_to_associated_taxes.sql` (created)
- ✅ `backend/scripts/migrate-tax-rates.ts` (created)

### Frontend
- ✅ `lib/modules/items/items/presentation/sections/default_tax_rates_section.dart`

## Important Notes

1. **No Foreign Key Constraints**: The table has no foreign key constraints, so renaming is safe
2. **Backward Compatibility**: The Drizzle schema export name (`taxRate`) remains unchanged to avoid breaking imports
3. **Frontend Filtering**: Interstate taxes are now filtered to show only IGST types as requested
4. **Data Loss**: The migration will **replace all existing tax data** with the new structure

## Rollback Plan

If needed, you can rollback by:
```sql
ALTER TABLE associated_taxes RENAME TO tax_rates;
-- Then restore your previous data from backup
```
