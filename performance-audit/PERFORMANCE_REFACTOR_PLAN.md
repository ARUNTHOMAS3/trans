# Zerpai ERP — Performance Refactor Master Plan
> Based on the 8-Report Performance Audit Suite
> Generated: 2026-05-16 | Status: READY FOR IMPLEMENTATION

---

## Audit Coverage Summary

| Audit Report | Findings | Critical | High | Medium |
|-------------|---------|---------|------|--------|
| 01 — Widget Rebuild Churn | 4 | 1 | 2 | 1 |
| 02 — State Management Architecture | 4 | 1 | 2 | 1 |
| 03 — API Call Patterns | 5 | 1 | 3 | 1 |
| 04 — Pagination & Full-Table Fetch | 5 | 1 | 3 | 1 |
| 05 — Memory Leaks | 4 | 0 | 1 | 2 |
| 06 — Backend N+1 Queries | 5 | 2 | 2 | 1 |
| 07 — Client-Side Filtering | 5 | 2 | 1 | 2 |
| 08 — Cache Strategy | 4 | 1 | 2 | 1 |
| **Total** | **36** | **9** | **16** | **10** |

---

## Execution Principles

1. **NO blind refactors.** Every change is evidence-based from the audit.
2. **Maintain backward compatibility.** No breaking API contract changes without migration plan.
3. **Test each phase before proceeding.** Each phase has a verification checklist.
4. **Optimistic UI first.** Reduce perceived latency before optimizing actual latency.
5. **Database changes require migration.** All schema changes go through Supabase migrations.

---

## Phase 1 — High-ROI / Low-Risk Quick Wins
> **Target:** 3–5 working days | **Risk:** LOW | **Impact:** HIGH

### 1.1 Fix Dashboard N+1 Customer Query [BACKEND]
**File:** `backend/src/modules/reports/reports.service.ts` L189-201
```typescript
// Replace 5 individual .single() calls with 1 .in() call
const { data: customers } = await supabase
  .from('customers').select('id, display_name')
  .in('id', topCustomerIds).eq('entity_id', tenant.entityId);
const nameById = new Map(customers?.map(c => [c.id, c.display_name]) ?? []);
```

### 1.2 Add `mounted` Guards to TextEditingController Listeners [FRONTEND]
**Files:** All `_create.dart` screens with `addListener` callbacks
```dart
row.quantityCtrl.addListener(() {
  if (!mounted) return; // ADD to every listener
  ...
});
```

### 1.3 Fix Hive Box Lifecycle in SyncService [FRONTEND]
**File:** `lib/shared/services/sync/sync_service.dart`
```dart
@override void dispose() {
  _connectivitySubscription?.cancel();
  if (_draftsBox.isOpen) _draftsBox.close(); // ADD
  super.dispose();
}
```

### 1.4 Fix OverlayEntry Disposal [FRONTEND]
**File:** `lib/modules/sales/presentation/sales_generic_list.dart`
```dart
@override void dispose() {
  _overlayEntry?.remove(); _overlayEntry = null; // ADD
  _hideFilterMenu(); _horizontalScrollController.dispose(); super.dispose();
}
```

### 1.5 Harden Lookup Bootstrap — Remove 16-Call Fallback Path [FRONTEND]
**File:** `lib/modules/items/items/controllers/items_controller.dart`
Replace 16-concurrent-call fallback with graceful degraded state + error message.
Never fire 16 individual requests as fallback — show error instead.

### 1.6 Add Tiered TTL to ApiClient Cache [FRONTEND]
**File:** `lib/core/services/api_client.dart`
```dart
Future<ApiResponse> get(String path, {Duration? cacheTtl, bool noCache = false}) async {
  // Add cacheTtl override + noCache bypass
}
// Apply: lookups = 30min, transactional = 0s (noCache: true)
```

### 1.7 Pre-Compute Lookup Maps in ItemsState [FRONTEND]
**File:** `lib/modules/items/items/controllers/items_state.dart`
```dart
late final Map<String, String> categoryNameById = {
  for (final c in categories) c['id'] as String: c['name'] as String
};
```
Replace all `LookupUtils.getNameById(state.categories, id)` calls with `state.categoryNameById[id]`.

### 1.8 Add Warehouse Map Provider [FRONTEND]
**File:** `lib/shared/providers/lookup_providers.dart`
```dart
final warehouseMapProvider = Provider<Map<String,String>>((ref) {
  return {for (final w in ref.watch(allWarehousesProvider).asData?.value ?? [])
    w['id'] as String: w['name'] as String};
});
```

**Phase 1 Checklist:**
- [ ] Dashboard loads in < 500ms
- [ ] No assertion errors on rapid navigation from create screens
- [ ] Hot restart: no HiveError
- [ ] Items lookup: 1 request (not 16) in Network tab
- [ ] No ghost overlay after navigating away

---

## Phase 2 — Medium Complexity, High Impact
> **Target:** 5–10 working days | **Risk:** MEDIUM | **Impact:** HIGH

### 2.1 Per-Row Hover StatefulWidget [FRONTEND]
**File:** `lib/modules/sales/presentation/sections/sales_generic_list_table.dart`
Extract `MouseRegion` hover state into `_SalesTableRow extends StatefulWidget`.
Result: hover rebuilds 1 row, not N rows.

### 2.2 Cache Sort Result in SalesGenericListScreen [FRONTEND]
**File:** `lib/modules/sales/presentation/sales_generic_list.dart`
Add `_cachedSorted`, recompute only when data/sortColumn/sortDirection changes.
No recompute on hover events.

### 2.3 Replace `toJson()` Search with Pre-Computed `searchKey` [FRONTEND]
Add `String get searchKey` to `SalesOrder`, `SalesCustomer`, `SalesPayment` models.
Eliminates 10,000+ Map allocations per keystroke.

### 2.4 Optimistic Updates for SalesOrderController [FRONTEND]
**File:** `lib/modules/sales/controllers/sales_order_controller.dart`
After create/update: prepend/patch local list state. No full reload spinner.
Invalidate typed document providers explicitly after each mutation.

### 2.5 Remove Background `loadItems()` After Items CRUD [FRONTEND]
**File:** `lib/modules/items/items/controllers/items_controller.dart` L864, L1004
Trust optimistic state until explicit user refresh. Add refresh button to Items List.

### 2.6 Lightweight Select for Backend List/Search Endpoints [BACKEND]
**File:** `backend/src/modules/products/products.service.ts`
Add `PRODUCT_LIST_SELECT` (8 fields + 2 joins) vs existing `PRODUCT_SELECT_STRING` (12 joins).
Apply list select to `findAll()` and `searchProducts()`.
Apply detail select only to `findOne()`.

**Phase 2 Checklist:**
- [ ] Hover in 100-row table: 1 paint call in DevTools (not 100)
- [ ] Typing in search: no visible jank on 1,000-item list
- [ ] Create invoice: list updates immediately, no reload spinner
- [ ] Backend `/products?limit=20`: < 50KB payload
- [ ] Backend `/products/search?q=test`: < 200ms for 5,000-item catalog

---

## Phase 3 — Pagination & Database Efficiency
> **Target:** 5–7 working days | **Risk:** MEDIUM | **Impact:** CRITICAL at Scale

### 3.1 Add Pagination to All Sales Document List Providers
Backend: Add `?page=N&limit=50` to each document endpoint.
Frontend: Replace 8 unlimited `FutureProvider`s with `FutureProvider.family<..., int>`.
UI: Implement scroll-to-bottom next-page trigger in `SalesGenericListScreen`.

### 3.2 Preserve Items Pagination Position After CRUD
**File:** `lib/modules/items/items/controllers/items_controller.dart`
After update: patch local state only. Do NOT reset cursor.

### 3.3 Add PostgreSQL Trigram Indexes [DATABASE MIGRATION]
**New file:** `supabase/migrations/YYYYMMDD_add_search_indexes.sql`
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_products_name_trgm ON products USING GIN (product_name gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_sku_trgm ON products USING GIN (sku gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_products_active ON products(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_account_tx_entity_date ON account_transactions(entity_id, transaction_date DESC);
CREATE INDEX IF NOT EXISTS idx_batch_master_product ON batch_master(product_id) WHERE is_active = true;
```

### 3.4 Reduce Backend Default Page Size
**File:** `backend/src/modules/products/products.service.ts`
Default `findAll` limit: 1,000 → 100. Hard cap: 1,000 → 500.

**Phase 3 Checklist:**
- [ ] Sales Invoices: first 50 load in < 1s
- [ ] Scroll to bottom: next page fetch fires
- [ ] Edit item: user stays on same page
- [ ] Product search EXPLAIN ANALYZE: uses index scan (not seq scan)
- [ ] account_transactions queries: use index scan

---

## Phase 4 — State Architecture Refactor
> **Target:** 10–15 working days | **Risk:** HIGH | **Do in feature branch**

### 4.1 Split ItemsController God Object (2,528 lines)
```
itemsLookupsProvider    → FutureProvider (lookup data only, 30min cache)
itemsListNotifier       → StateNotifier (CRUD + pagination, no lookups)
itemsUiProvider         → StateProvider (isSaving, validationErrors)
itemsOfflineDraftsProvider → StateNotifier (Hive drafts only)
```
Migrate screens one-by-one. Remove old provider after all screens migrated.

### 4.2 Unify Sales Document Providers
```dart
final salesDocumentsProvider = FutureProvider.autoDispose<SalesDocumentsBundle>((ref) async {
  // 1 fetch for all document types
});
// All typed providers become derived (no-network) Providers
```

**Phase 4 Checklist:**
- [ ] Changing `isSaving`: ItemListScreen does NOT rebuild
- [ ] Items lookup: 1 request (not 16) always
- [ ] Sales module entry: 1 API call (not 8)
- [ ] Create sales order: all document lists update immediately
- [ ] Flutter DevTools: < 3 rebuilds per save in Items

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Phase 4 breaks a screen | High | High | Feature branch + full regression |
| Pagination breaks deep-linked URLs | Medium | High | Encode page/cursor in route params |
| Removing background `loadItems()` causes stale UI | Medium | Medium | Add manual refresh button |
| Trigram index migration locks large tables | Low | High | `CREATE INDEX CONCURRENTLY` + off-hours |

---

## Performance Improvement Projections

| Phase | Load Time | Server Load | Memory | Rebuild Count |
|-------|-----------|------------|--------|---------------|
| Baseline | 100% | 100% | 100% | 100% |
| After Phase 1 | 85% | 80% | 98% | 95% |
| After Phase 2 | 60% | 65% | 90% | 30% |
| After Phase 3 | 40% | 40% | 60% | 25% |
| After Phase 4 | 20% | 30% | 40% | 5% |

---

## Files Inventory by Phase

### Phase 1 (Quick Wins)
- `backend/src/modules/reports/reports.service.ts`
- `lib/shared/services/sync/sync_service.dart`
- `lib/modules/sales/presentation/sales_invoice_create.dart`
- `lib/modules/sales/presentation/sales_order_create.dart`
- `lib/modules/sales/presentation/sales_generic_list.dart`
- `lib/modules/items/items/controllers/items_controller.dart` (bootstrap only)
- `lib/core/services/api_client.dart`
- `lib/modules/items/items/controllers/items_state.dart`
- `lib/shared/providers/lookup_providers.dart`

### Phase 2 (Medium)
- `lib/modules/sales/presentation/sections/sales_generic_list_table.dart`
- `lib/modules/sales/models/sales_order_model.dart`
- `lib/modules/sales/models/sales_customer_model.dart`
- `lib/modules/sales/controllers/sales_order_controller.dart`
- `lib/modules/items/items/controllers/items_controller.dart`
- `backend/src/modules/products/products.service.ts`

### Phase 3 (Pagination + DB)
- `supabase/migrations/YYYYMMDD_add_search_indexes.sql` (new)
- `backend/src/modules/sales/services/sales.service.ts`
- `lib/modules/sales/controllers/sales_order_controller.dart`

### Phase 4 (Architecture)
- `lib/modules/items/items/controllers/` (split into 4 providers)
- `lib/modules/sales/controllers/sales_order_controller.dart` (unify)
- All screens watching `itemsControllerProvider` (update references)
