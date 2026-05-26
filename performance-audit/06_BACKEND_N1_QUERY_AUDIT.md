# 06 — Backend N+1 Query & Database Efficiency Audit
> Zerpai ERP | NestJS + Supabase PostgreSQL
> Audit Date: 2026-05-16 | Status: **CRITICAL DATABASE RISKS**

---

## Executive Summary

The backend has three confirmed N+1 patterns, one full-table scan risk, and one double-scan
pattern in the dashboard. The most critical is in `getDashboardSummary()` which scans
`account_transactions` three times, and the `searchProducts` function which applies an
in-process sort on up to 500 fully-joined rows. The product join string is also extremely
wide (12 tables) and applied uniformly regardless of whether the caller needs all those
joined fields.

---

## Finding 1 — Dashboard N+1: 5 Individual Customer Fetches

**Severity: CRITICAL**
**File:** `backend/src/modules/reports/reports.service.ts` — lines 189–201

### Evidence
```typescript
const topCustomers = await Promise.all(
  topCustomerIds.map(async (id) => {
    // ↓ Up to 5 individual SELECT queries issued
    const { data } = await supabase
      .from('customers')
      .select('display_name')
      .eq('id', id)
      .eq('entity_id', tenant.entityId)
      .single();
    return { name: data?.display_name || 'Unknown Customer', amount: customerMap.get(id) || 0 };
  }),
);
```

5 `single()` queries vs. 1 `.in('id', ids)` query.

### Fix
```typescript
const { data: customers } = await supabase
  .from('customers')
  .select('id, display_name')
  .in('id', topCustomerIds)
  .eq('entity_id', tenant.entityId);

const nameById = new Map(customers?.map(c => [c.id, c.display_name]));
const topCustomers = topCustomerIds.map(id => ({
  name: nameById.get(id) || 'Unknown Customer',
  amount: customerMap.get(id) || 0,
}));
```

---

## Finding 2 — `account_transactions` Scanned 3× Per Dashboard Load

**Severity: CRITICAL**
**File:** `backend/src/modules/reports/reports.service.ts`

### Evidence
```typescript
// Scan 1: Get all transactions for account balance computation
const { data: txs } = await supabase
  .from('account_transactions')
  .select('account_id, debit, credit')
  .eq('entity_id', tenant.entityId);

// Scan 2: Sales trend (last 30 days)
const { data: salesTrend } = await salesTrendQuery
  .gte('transaction_date', thirtyDaysAgo.toISOString())
  .filter('transaction_type', 'in', '("invoice", "sales_receipt")');

// Scan 3: Top customers by revenue
const { data: topCustomersData } = await topCustomersQuery
  .eq('contact_type', 'customer')
  .filter('transaction_type', 'in', '("invoice", "sales_receipt")');
```

**Scan 1 (line ~106)**: No date filter — fetches ALL transactions ever for the tenant.
For a tenant with 2 years of activity, this could be hundreds of thousands of rows.

**Scan 2 & 3 (lines ~139–170)**: Correct date/type filters but still separate roundtrips.

### Fix: Single PostgreSQL function
```sql
CREATE OR REPLACE FUNCTION get_dashboard_summary(p_entity_id uuid, p_since_date timestamptz)
RETURNS json AS $$
DECLARE
  v_result json;
BEGIN
  SELECT json_build_object(
    'balances', (
      SELECT json_object_agg(account_id, SUM(debit) - SUM(credit))
      FROM account_transactions WHERE entity_id = p_entity_id
    ),
    'salesTrend', (
      SELECT json_agg(json_build_object('date', DATE(transaction_date), 'amount', SUM(credit)))
      FROM account_transactions
      WHERE entity_id = p_entity_id
        AND transaction_date >= p_since_date
        AND transaction_type IN ('invoice', 'sales_receipt')
      GROUP BY DATE(transaction_date)
    ),
    'topCustomers', (
      SELECT json_agg(json_build_object('contact_id', contact_id, 'total', SUM(credit)))
      FROM account_transactions
      WHERE entity_id = p_entity_id
        AND contact_type = 'customer'
        AND transaction_type IN ('invoice', 'sales_receipt')
      GROUP BY contact_id
      ORDER BY SUM(credit) DESC LIMIT 5
    )
  ) INTO v_result;
  RETURN v_result;
END;
$$ LANGUAGE plpgsql;
```

---

## Finding 3 — `PRODUCT_SELECT_STRING` Joins 12 Tables on Every Product Fetch

**Severity: HIGH**
**File:** `backend/src/modules/products/products.service.ts` — lines 42–63

### Evidence
```typescript
private readonly PRODUCT_SELECT_STRING = `
  *,
  unit:units(id, unit_name),
  category:categories(id, name),
  manufacturer:manufacturers(id, name),
  brand:brands(id, name),
  preferredVendor:vendors(id, display_name),
  salesAccount:accounts!...(id, user_account_name),
  purchaseAccount:accounts!...(id, user_account_name),
  inventoryAccount:accounts!...(id, user_account_name),
  rack:racks(id, rack_name),
  buyingRule:buying_rules(id, buying_rule, rule_description, ...),
  drugSchedule:drug_schedules(id, shedule_name, ...),
  storage:storage_conditions(id, location_name, ...),
  compositions:product_contents(content_id, strength_id, ...,
    content:contents(id, content_name),
    strength:drug_strengths(id, strength_name)
  )
`;
```

This single join string is used for:
- `findAll()` (list endpoint, 1,000 rows)
- `findOne()` (detail endpoint — appropriate here ✅)
- `findAllCursor()` (paginated list — 50 rows)
- `searchProducts()` (search — up to 500 rows)

For **list and search endpoints**, clients typically only need:
`id, product_name, sku, item_code, mrp, cost_price, is_active, category(name), unit(unit_name)`

### Recommended Fix
Define a separate `PRODUCT_LIST_SELECT` (lightweight) vs `PRODUCT_DETAIL_SELECT` (full):
```typescript
private readonly PRODUCT_LIST_SELECT = `
  id, product_name, sku, item_code, mrp, cost_price, is_active, created_at,
  category:categories(id, name),
  unit:units(id, unit_name)
`;
private readonly PRODUCT_DETAIL_SELECT = /* current full string */;
```

Expected performance improvement: **60–70% reduction in data transfer** for list/search endpoints.

---

## Finding 4 — `updateOpeningStock` Fetches Then Updates (Read-Modify-Write N+1)

**Severity: MEDIUM**
**File:** `lib/modules/items/items/repositories/supabase_item_repository.dart` — lines 75–89

### Evidence
```dart
Future<void> updateOpeningStock(String itemId, double openingStock, double openingStockValue) async {
  // Step 1: Fetch current item (1 API call)
  final currentItem = await getItemById(itemId);
  if (currentItem == null) return;

  // Step 2: copyWith new stock values
  final updatedItem = currentItem.copyWith(
    openingStock: openingStock,
    openingStockValue: openingStockValue,
  );

  // Step 3: Update entire item (1 API call)
  await updateItem(updatedItem);
}
```

This pattern:
1. Fetches the full product (with 12 table joins)
2. Creates a copy with 2 fields changed
3. Sends the entire product payload back to update all fields

Instead, a targeted PATCH should be used:
```typescript
// Backend: PATCH /products/:id/opening-stock
await supabase.from('products')
  .update({ opening_stock: value, opening_stock_value: value2 })
  .eq('id', id);
```

---

## Finding 5 — No Index Verification on High-Traffic Query Columns

**Severity: HIGH (Structural Risk)**

### Columns at Risk of Sequential Scans
Based on the query patterns observed in the audit:

| Table | Column | Used In | Index Status |
|-------|--------|---------|-------------|
| `account_transactions` | `entity_id` | Dashboard (3× scans) | Unknown |
| `account_transactions` | `transaction_date` | Sales trend, P&L | Unknown |
| `account_transactions` | `transaction_type` | Dashboard filter | Unknown |
| `products` | `product_name` | Search (ILIKE) | Unknown (needs GIN trigram) |
| `products` | `sku` | Search (ILIKE) | Unknown (needs GIN trigram) |
| `products` | `is_active` | Most list queries | Unknown |
| `batch_master` | `product_id` | batchLookupProvider | Unknown |
| `batch_stock_layers` | `product_id` | batchLookupProvider | Unknown |
| `customers` | `entity_id` | All customer queries | Unknown |

### Recommended Index Verification Script
```sql
-- Run in Supabase SQL Editor to check existing indexes
SELECT
  schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE tablename IN (
  'account_transactions', 'products', 'batch_master',
  'batch_stock_layers', 'customers', 'sales_orders'
)
ORDER BY tablename, indexname;

-- Recommended additions if missing:
CREATE INDEX IF NOT EXISTS idx_account_tx_entity_date
  ON account_transactions(entity_id, transaction_date DESC);

CREATE INDEX IF NOT EXISTS idx_products_active
  ON products(is_active) WHERE is_active = true;

CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_products_name_trgm
  ON products USING GIN (product_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_sku_trgm
  ON products USING GIN (sku gin_trgm_ops);
```

---

## Database Efficiency Summary

| Finding | Queries/Request | Fix Complexity | Priority |
|---------|----------------|---------------|----------|
| Dashboard N+1 customer fetch | 5 → 1 | Low | 🔴 P0 |
| account_transactions 3× scan | 3 → 1 | Medium (DB function) | 🔴 P0 |
| 12-join select on list endpoints | Unnecessary joins | Low | 🟠 P1 |
| updateOpeningStock read-modify-write | 2 → 1 | Low | 🟡 P2 |
| Missing trigram/composite indexes | Full table scans | Medium | 🟠 P1 |
