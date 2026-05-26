# 04 — Pagination & Full-Table Fetch Audit
> Zerpai ERP | Data Volume & Scalability Risk
> Audit Date: 2026-05-16 | Status: **SCALABILITY BLOCKER**

---

## Executive Summary

Multiple list screens load unbounded datasets into memory. The `ItemsController` implements
cursor-based pagination infrastructure but it is not consistently used. Sales documents
(`salesInvoicesProvider`, `salesQuotesProvider`, etc.) load **all records** with no
pagination at all. At enterprise scale (5,000+ items, 50,000+ invoices), this becomes
a memory and rendering blocker.

---

## Finding 1 — Sales Document Lists Load All Records (No Pagination)

**Severity: CRITICAL**
**File:** `lib/modules/sales/controllers/sales_order_controller.dart`

### Evidence
```dart
// All 8 sales document providers load ALL records
final salesInvoicesProvider = FutureProvider<List<SalesOrder>>((ref) {
  return ref.watch(salesOrderApiServiceProvider).getSalesByType('invoice');
  // ↑ No limit, no offset, no cursor — ALL invoices for the tenant
});

final salesCustomersProvider = FutureProvider<List<SalesCustomer>>((ref) async {
  final apiService = ref.watch(salesOrderApiServiceProvider);
  return apiService.getCustomers();
  // ↑ ALL customers loaded into memory
});
```

At 10,000 customers or 50,000 invoices, these calls:
1. Exhaust NestJS/Supabase response payload limits
2. Load entire lists into Flutter's Dart VM heap
3. Force the `SalesGenericListScreen` to render ALL rows via `ListView.builder`
   (even though `ListView.builder` is efficient, the DATA is all in memory)

### Scale Projections
| Entity | Records at 1 Year | Memory Estimate |
|--------|-------------------|-----------------|
| Invoices | 15,000–50,000 | 30–100 MB in Dart heap |
| Sales Orders | 10,000–30,000 | 20–60 MB |
| Customers | 500–5,000 | 2–10 MB |
| Products | 5,000–50,000 | 15–100 MB |

---

## Finding 2 — `ItemsController` Has Pagination But `loadItems()` Loads Page 1 Only

**Severity: HIGH**
**File:** `lib/modules/items/items/controllers/items_controller.dart`

### Evidence
The controller has cursor-based pagination (`getProductsCursor`) and a `loadMoreItems()`
method. However, `loadItems()` resets pagination and loads only page 1 (default 50 items).

After every CRUD operation (`createItem`, `updateItem`, `deleteItem`, `updateItemsBulk`),
the code calls `loadItems()` which:
1. Resets `currentPage` and `cursor`
2. Fetches only the first page
3. Does NOT preserve the user's scroll position or current page

A user on page 3 (items 101–150) who edits an item will be **reset to page 1** after save.

### Recommended Fix
After a successful mutation, instead of calling `loadItems()`:
1. Apply the mutation locally via `copyWith(items: updatedList)`
2. Only call `loadItems()` if the local state might be stale (e.g., after a bulk operation
   from another session or after a network reconnect)

---

## Finding 3 — `SalesGenericListScreen` Applies Client-Side Sort on Every Build

**Severity: HIGH**
**File:** `lib/modules/sales/presentation/sales_generic_list.dart` — lines 327–347

### Evidence
```dart
Widget _buildTable(BuildContext context, List<dynamic> data) {
  // ↓ Creates a NEW sorted list copy on EVERY rebuild
  final sortedData = List<dynamic>.from(data);
  sortedData.sort((a, b) { ... });
  
  return LayoutBuilder(...);
}
```

`_buildTable` is called on every `build()` call. The `List.from(data)` + `.sort()` is
O(N log N) and runs on the UI thread. For 10,000 records, this could take 50–200ms per
rebuild (skipping frames on 60 FPS target).

### Recommended Fix
Cache the sorted data:
```dart
// Compute once when data or sort config changes
List<dynamic>? _cachedSorted;
String _lastSortColumn = '';
bool _lastSortAscending = true;

List<dynamic> _getSortedData(List<dynamic> data) {
  if (_cachedSorted == null
      || _lastSortColumn != _sortColumn
      || _lastSortAscending != _isAscending) {
    _cachedSorted = List.from(data)..sort(...);
    _lastSortColumn = _sortColumn;
    _lastSortAscending = _isAscending;
  }
  return _cachedSorted!;
}
```

---

## Finding 4 — `_matchesGlobalSearch()` Runs `toJson()` on Every Item on Every Search Change

**Severity: HIGH**
**File:** `lib/modules/sales/presentation/sales_generic_list.dart` — lines 175–323

### Evidence
```dart
List<dynamic> _applyGlobalSearchFilter(List<dynamic> data) {
  if (_searchQuery.isEmpty) return data;
  return data.where(_matchesGlobalSearch).toList();
}

bool _matchesGlobalSearch(dynamic item) {
  // ↓ Calls toJson() on EVERY item for EVERY search character typed
  final map = item.toJson();
  for (final value in map.values) {
    addValue(value); // string conversion
  }
  // Then also type-checks and field-extracts for specific types
  if (item is SalesCustomer) { ... }
  else if (item is SalesOrder) { ... }
  // ...
}
```

Every keystroke in the search box filters the full in-memory dataset by calling
`toJson()` on every item. For 10,000 sales orders, this is 10,000 serialization
operations per keystroke. At 60 WPM (5 chars/sec), that's 50,000 serialization
operations per second on the main thread.

### Recommended Fix
1. Use server-side search with debounced API calls
2. Pre-compute a `searchableString` per item at data load time (not per keystroke)
3. Add 300ms debounce before triggering filter

---

## Finding 5 — `products.service.ts::findAll()` Has a Hard-Coded 1,000 Row Default

**Severity: HIGH**
**File:** `backend/src/modules/products/products.service.ts` — lines 688–715

### Evidence
```typescript
async findAll(limit?: number, offset?: number) {
  let query = supabase
    .from('products')
    .select(this.PRODUCT_SELECT_STRING) // Full 12-join select
    .order('created_at', { ascending: false });

  if (limit !== undefined && !isNaN(limit)) {
    query = query.limit(limit);
  } else if (limit === undefined) {
    query = query.limit(1000); // ← Hard-coded 1,000 row cap
  }
  ...
  return Promise.all(products.map((p) => this.mapProduct(p)));
  // ↑ Calls mapProduct() 1,000 times in-process
}
```

- 1,000 fully-joined rows (12 joins each) = **12,000 join results to serialize**
- `Promise.all(products.map(p => this.mapProduct(p)))` runs 1,000 async `mapProduct`
  calls simultaneously — this can overwhelm the Node.js event loop

### Recommended Fix
- Set default to 50–100, require explicit opt-in for larger pages
- Use `findAllCursor()` (already implemented) as the primary list endpoint
- Remove `Promise.all` with `mapProduct` for list endpoints; use lightweight DTO mapping

---

## Pagination Status Matrix

| Module | Pagination Type | Default Limit | Has "Load More"? | Issue |
|--------|----------------|---------------|-------------------|-------|
| Items | Cursor-based | 50 | ✅ Yes | Resets to p1 after CRUD |
| Sales Invoices | None | Unlimited | ❌ No | All records loaded |
| Sales Orders | None | Unlimited | ❌ No | All records loaded |
| Sales Customers | None | Unlimited | ❌ No | All customers in memory |
| Sales Quotes | None | Unlimited | ❌ No | All records loaded |
| Sales Payments | None | Unlimited | ❌ No | All records loaded |
| Backend findAll | Hard-capped | 1,000 | N/A | 1,000 row default |
| Backend search | Hard-capped | 500 | N/A | 500 joined rows |
