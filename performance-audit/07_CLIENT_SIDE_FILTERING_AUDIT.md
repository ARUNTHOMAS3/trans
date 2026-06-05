# 07 — Client-Side Filtering, Sorting & Search Audit
> Zerpai ERP | In-Memory Data Processing Risk
> Audit Date: 2026-05-16 | Status: **SCALABILITY BLOCKER**

---

## Executive Summary

Client-side filtering and sorting is applied to unbounded in-memory datasets across
multiple list screens. The most severe case is `SalesGenericListScreen`, which combines
an in-memory sort (O(N log N)) and a full-dataset text search (O(N × M fields)) on
every keystroke. At production scale with 10,000+ records, this will produce visible
UI freezes on every sort or search interaction.

---

## Finding 1 — `SalesGenericListScreen` Sorts ALL Data In-Memory on Every Build

**Severity: CRITICAL**
**File:** `lib/modules/sales/presentation/sales_generic_list.dart` — lines 326–347

### Evidence
```dart
Widget _buildTable(BuildContext context, List<dynamic> data) {
  final sortedData = List<dynamic>.from(data); // ← Full copy every build
  sortedData.sort((a, b) {                     // ← O(N log N) every build
    dynamic valA = _getSortValue(a, _sortColumn);
    dynamic valB = _getSortValue(b, _sortColumn);
    ...
  });
  return LayoutBuilder(...);
}
```

`_buildTable` is called from `build()` every time the widget rebuilds (which happens
on every mouse hover due to `_hoveredRowId` state changes — see Audit #01).

### Estimated Cost
| Dataset Size | Sort Time (estimated, 60Hz) | Frame Budget |
|-------------|---------------------------|--------------|
| 100 records | ~0.5ms | ✅ Safe |
| 1,000 records | ~5–10ms | ⚠️ Near-limit |
| 10,000 records | ~50–100ms | 🔴 Frame drop |
| 50,000 records | ~500ms+ | 🔴 UI freeze |

### Fix Strategy
1. Cache sorted data, recompute only when `data`, `_sortColumn`, or `_isAscending` changes
2. Move to server-side sorting (`?sort=column&order=asc`)
3. Apply sorting in the provider using `select`:
   ```dart
   final sorted = ref.watch(salesInvoicesProvider.select((asyncVal) =>
     asyncVal.asData?.value.sorted((a, b) => ...) ?? []
   ));
   ```

---

## Finding 2 — `_matchesGlobalSearch` Serializes Every Item via `toJson()` Per Keystroke

**Severity: CRITICAL**
**File:** `lib/modules/sales/presentation/sales_generic_list.dart` — lines 272–324

### Evidence
```dart
bool _matchesGlobalSearch(dynamic item) {
  final values = <String>[];

  try {
    final map = item.toJson(); // ← Serialize to JSON map (allocation)
    if (map is Map<String, dynamic>) {
      for (final value in map.values) {
        addValue(value); // ← String conversion for every field
      }
    }
  } catch (_) {}

  // ↓ Then also manual field extraction by type (redundant work)
  if (item is SalesCustomer) {
    addValue(item.displayName);
    addValue(item.companyName);
    addValue(item.email);
    addValue(item.phone);
  } else if (item is SalesOrder) {
    addValue(item.saleNumber);
    addValue(item.reference);
    ...
  }
  ...
  return values.any((value) => value.contains(_searchQuery));
}
```

For 10,000 invoices: every search keystroke triggers `10,000 × toJson()` serializations.
`toJson()` on a `SalesOrder` allocates a new `Map<String, dynamic>` with all fields.
This is equivalent to creating 10,000 new maps per second during typing.

### Fix: Pre-Computed Search Strings
```dart
// When data loads, pre-compute a searchable string per item
extension SalesOrderSearchable on SalesOrder {
  String get searchKey =>
    '${saleNumber} ${reference} ${status} ${customer?.displayName}'
    .toLowerCase();
}

// In filter:
bool _matchesGlobalSearch(dynamic item) {
  return (item as dynamic).searchKey.contains(_searchQuery);
}
```

---

## Finding 3 — `ItemsController.performSearch()` Filters In-Memory List

**Severity: HIGH**
**File:** `lib/modules/items/items/controllers/items_controller.dart`

### Evidence
`performSearch(String query)` in `ItemsController` filters `state.items` (the full
in-memory items list) for queries under 3 characters, then falls back to API search
for longer queries. The threshold of 3 characters means short queries (e.g., "ABC")
still filter thousands of in-memory items.

### Recommended Fix
Use server-side search for all queries ≥ 2 characters via the backend
`searchProducts` endpoint (already exists). Remove client-side fallback filtering.

---

## Finding 4 — `LookupUtils.getNameById()` Does Linear Scan on Every Table Row

**Severity: MEDIUM**
**File:** `lib/shared/utils/lookup_utils.dart`
**Used In:** `lib/modules/items/items/presentation/items_item_list.dart` — line 151

### Evidence
```dart
// items_item_list.dart — called per row in the table
ZTableCell(
  child: Text(
    LookupUtils.getNameById(categories, item.categoryId),
    // ↑ Linear scan O(N) through categories list for every row
  ),
),
```

With 500 items displayed and 100 categories, this is 500 × 100 = **50,000 list element
comparisons** per render.

### Fix: Pre-Compute Lookup Maps
```dart
// In ItemsState or a derived provider
Map<String, String> get categoryNameById =>
  Map.fromEntries(categories.map((c) => MapEntry(c['id'] as String, c['name'] as String)));

// In the widget:
Text(state.categoryNameById[item.categoryId] ?? '-')
// ↑ O(1) hash map lookup instead of O(N) linear scan
```

---

## Finding 5 — `warehouseNameProvider` Linear Scan on Every `ref.watch`

**Severity: MEDIUM**
**File:** `lib/shared/providers/lookup_providers.dart` — lines 19–26

### Evidence
```dart
final warehouseNameProvider = Provider.family<String, String>((ref, id) {
  final warehouses = ref.watch(allWarehousesProvider).asData?.value ?? [];
  final match = warehouses.firstWhere(
    (w) => w['id'] == id,   // ← O(N) linear scan per warehouse ID lookup
    orElse: () => {'name': '-'},
  );
  return match['name'];
});
```

If a screen uses `warehouseNameProvider` for 20 warehouse IDs, it runs 20 linear
scans through the warehouses list on every rebuild of any warehouse-watching widget.

### Fix
```dart
// Use a Map-based lookup provider instead
final warehouseMapProvider = Provider<Map<String, String>>((ref) {
  final warehouses = ref.watch(allWarehousesProvider).asData?.value ?? [];
  return Map.fromEntries(warehouses.map((w) => MapEntry(w['id'] as String, w['name'] as String)));
});

final warehouseNameProvider = Provider.family<String, String>((ref, id) {
  return ref.watch(warehouseMapProvider)[id] ?? '-';
  // ↑ O(1) always
});
```

---

## Client-Side Processing Risk Matrix

| Operation | Dataset | Trigger | Complexity | Risk |
|-----------|---------|---------|------------|------|
| Table sort in `_buildTable` | All N records | Every rebuild | O(N log N) | 🔴 CRITICAL |
| `_matchesGlobalSearch` with `toJson` | All N records | Every keystroke | O(N × M) | 🔴 CRITICAL |
| `performSearch` in-memory filter | Loaded items | Short queries | O(N) | 🟠 HIGH |
| `LookupUtils.getNameById` per row | N rows × M lookups | Every render | O(N × M) | 🟡 MEDIUM |
| `warehouseNameProvider` linear scan | K warehouses | Every widget rebuild | O(K) per lookup | 🟡 MEDIUM |
