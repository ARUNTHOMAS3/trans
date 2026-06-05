# 03 — API Call Pattern & Network Efficiency Audit
> Zerpai ERP | Supabase + NestJS Backend
> Audit Date: 2026-05-16 | Status: **HIGH-IMPACT FINDINGS**

---

## Executive Summary

Three patterns dominate the API inefficiency surface: (1) sequential N+1 lookup fetching during
initialization, (2) full-collection refetch after every single mutation, and (3) a dashboard
summary that executes multiple independent queries instead of a single aggregated query.
The backend `products.service.ts` also applies an in-process sort/rank operation after fetching
up to 500 rows for a search — this is expensive client-side sorting at scale.

---

## Finding 1 — 16 Parallel API Calls at Items Module Initialization

**Severity: CRITICAL**
**File:** `lib/modules/items/items/services/lookups_api_service.dart`
**File:** `lib/modules/items/items/controllers/items_controller.dart`

### Evidence
`loadLookupData()` in `ItemsController` calls `getLookupBootstrap()` first.
If that fails, it falls back to a `Future.wait([...])` block with up to 16 calls:

```dart
// Fallback path — 16 concurrent network requests
await Future.wait([
  _fetchUnits(),
  _fetchCategories(),
  _fetchTaxRates(),
  _fetchTaxGroups(),
  _fetchBrands(),
  _fetchManufacturers(),
  _fetchRacks(),
  _fetchStorageConditions(),
  _fetchBuyingRules(),
  _fetchDrugSchedules(),
  _fetchDrugStrengths(),
  _fetchContents(),
  _fetchPaymentTerms(),
  _fetchPriceListItems(),
  _fetchCustomers(),
  _fetchReorderTerms(),
]);
```

On fast networks, `Future.wait` runs all 16 concurrently — still creates 16 HTTP round-trips
(16 TLS handshakes on cold start, 16 Supabase RLS evaluations). On slow connections or Supabase
cold-wake, this is a **16-connection storm at boot** that can take 5–12 seconds.

### Recommended Fix
Ensure `/api/products/lookup-bootstrap` remains the primary path and always succeeds.
The fallback path should not exist in production. Add a circuit-breaker with a timeout:
```dart
try {
  final data = await _apiService.getLookupBootstrap().timeout(const Duration(seconds: 8));
  _applyBootstrap(data);
} catch (e) {
  // Log and show degraded state, do NOT attempt 16 individual fetches
  _setDegradedLookupState();
}
```

---

## Finding 2 — Full List Refetch After Every CRUD Mutation

**Severity: HIGH**
**Files:**
- `lib/modules/sales/controllers/sales_order_controller.dart` — lines 157, 168, 207, 218
- `lib/modules/items/items/controllers/items_controller.dart` — line 864, 1004, 1080

### Evidence
```dart
// sales_order_controller.dart
Future<SalesOrder?> createSalesOrder(SalesOrder sale) async {
  final newSale = await _apiService.createSalesOrder(sale);
  await loadSalesOrders(); // ← Full list refetch: N+1 network roundtrip
  return newSale;
}

Future<SalesOrder?> updateSalesOrder(String id, SalesOrder sale) async {
  final updatedSale = await _apiService.updateSalesOrder(id, sale);
  await loadSalesOrders(); // ← Full list refetch
  return updatedSale;
}

// items_controller.dart — after create
state = state.copyWith(items: [hydratedItem, ...state.items], ...);
loadItems(); // ← Background full list refetch AFTER optimistic update
```

For items, the optimistic update is applied but then immediately followed by `loadItems()`
which re-fetches the full page of items. This means:
1. Optimistic state is set → UI updates ✅
2. Background fetch fires → state replaces again → second UI update (flicker) ⚠️

For sales orders: **no optimistic update** — user sees loading state for the entire
list reload duration.

### Recommended Fix
**Items (already partially done):** Remove the background `loadItems()` after create/update.
Trust the optimistic state until next explicit refresh.

**Sales Orders:** Apply optimistic updates:
```dart
Future<SalesOrder?> createSalesOrder(SalesOrder sale) async {
  final newSale = await _apiService.createSalesOrder(sale);
  // Optimistic prepend — no reload needed
  if (state.hasValue) {
    state = AsyncValue.data([newSale, ...state.value!]);
  }
  return newSale;
}
```

---

## Finding 3 — Dashboard Executes 5 Sequential or Parallel Supabase Queries

**Severity: HIGH**
**File:** `backend/src/modules/reports/reports.service.ts` — `getDashboardSummary()`

### Evidence
```typescript
async getDashboardSummary(tenant: TenantContext) {
  // Query 1: accounts
  const { data: accounts } = await supabase.from('accounts').select(...);

  // Query 2: account_transactions (ALL transactions for balances)
  const { data: txs } = await supabase.from('account_transactions').select('account_id, debit, credit')...;

  // Query 3: sales_trend (another full scan of account_transactions)
  const { data: salesTrend } = await salesTrendQuery...;

  // Query 4: topCustomersData (ANOTHER full scan of account_transactions)
  const { data: topCustomersData } = await topCustomersQuery...;

  // Query 5: topCustomerIds.map(id => supabase.from('customers').select(...).eq('id', id))
  // ↑ N individual customer fetches (up to 5 separate queries)
  const topCustomers = await Promise.all(topCustomerIds.map(async (id) => { ... }));

  // Query 6 (optional): Drizzle raw SQL for topItems
}
```

**`account_transactions` is scanned 3 times** in a single dashboard load.
The `topCustomers` fetch is an N+1 pattern — up to 5 individual `customers` queries.

### Recommended Fix
Combine into a single PostgreSQL function or stored procedure for the dashboard,
or at minimum:
1. Fetch `account_transactions` once and derive all three metrics in memory
2. Replace the N+1 customer fetch with a single `.in('id', topCustomerIds)` query:
```typescript
const { data: customers } = await supabase
  .from('customers')
  .select('id, display_name')
  .in('id', topCustomerIds);
```

---

## Finding 4 — Backend Search Fetches 500 Rows Then Sorts In-Process

**Severity: HIGH**
**File:** `backend/src/modules/products/products.service.ts` — `searchProducts()` lines 756–800

### Evidence
```typescript
async searchProducts(q?: string, limit: number = 30, _branchId?: string) {
  const fetchLimit = Math.min(Math.max(limit * 5, 100), 500); // Fetches up to 500!

  const { data } = await supabase
    .from('products')
    .select(this.PRODUCT_SELECT_STRING) // ← Full join SELECT on 500 rows
    .or(`sku.ilike.%${q}%,ean.ilike.%${q}%,...`)
    .limit(fetchLimit); // 500 rows

  // Then in-process sort/rank in Node.js
  const rankRow = (row: any) => { ... };
  return data.sort((a, b) => rankRow(b) - rankRow(a)).slice(0, limit);
}
```

For a product catalog of 10,000+ items, `ilike.%query%` is a full sequential scan
unless a `GIN/trigram` index exists on those columns. Fetching 500 fully-joined rows
(with 10+ joined tables per row via `PRODUCT_SELECT_STRING`) and sorting them in Node.js
is extremely expensive.

### `PRODUCT_SELECT_STRING` Scope
The select joins: `units`, `categories`, `manufacturers`, `brands`, `vendors`, `accounts` (×3),
`racks`, `buying_rules`, `drug_schedules`, `storage_conditions`, `product_contents` (nested) —
**12 table joins per product row × 500 rows = 6,000 join operations per search**.

### Recommended Fix
1. Add PostgreSQL trigram indexes: `CREATE INDEX idx_products_name_trgm ON products USING GIN (product_name gin_trgm_ops);`
2. Use a lightweight select for search (id, name, sku, item_code, category name only)
3. Only fetch 30 rows server-side with `ts_rank` ordering
4. Move rank-scoring to a PostgreSQL function

---

## Finding 5 — `batchLookupProvider` Executes 2 Queries Per Product Line Item

**Severity: MEDIUM**
**File:** `lib/shared/providers/lookup_providers.dart` — `batchLookupProvider`

### Evidence
```dart
final batchLookupProvider = FutureProvider.family<List<Map<String,dynamic>>, String>((ref, productId) async {
  // Query 1: batch_master for the product
  final response = await supabase.from('batch_master').select('*')...

  // Query 2: batch_stock_layers for the same product
  final pricingResponse = await supabase.from('batch_stock_layers').select(...)...
  
  // Then merge in-memory
});
```

In a purchase receive or invoice with 20 line items, this fires **40 Supabase queries**
(2 per product) when line items are populated. These also run sequentially if not
parallelized in the calling widget.

### Recommended Fix
Create a backend endpoint `/api/products/batches?productIds=id1,id2,id3` that returns
batch + stock layer data in a single JOIN query for multiple products at once.

---

## Network Efficiency Summary

| Finding | Location | Extra Queries/Requests | Priority |
|---------|----------|----------------------|----------|
| 16-call lookup bootstrap fallback | ItemsController | 15 extra vs. 1 | 🔴 P0 |
| Full list refetch on CRUD | Sales/Items controllers | 1 extra per mutation | 🔴 P1 |
| Dashboard N+1 customer queries | reports.service.ts | Up to 5 extra | 🔴 P1 |
| Search fetches 500 joined rows | products.service.ts | 6,000 joins/search | 🟠 P2 |
| 2 queries per batch per line item | lookup_providers.dart | 2N queries per form | 🟠 P2 |
