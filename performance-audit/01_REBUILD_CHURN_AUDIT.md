# 01 — Widget Rebuild Churn Audit
> Zerpai ERP | Flutter Web | Riverpod Architecture
> Audit Date: 2026-05-16 | Status: **CRITICAL FINDINGS**

---

## Executive Summary

The codebase exhibits **three systemic rebuild-churn patterns** that together produce cascading,
full-subtree re-renders on every state mutation. The most severe is in `ItemsState`, which is a
single monolithic object containing every lookup list. Any mutation — even saving a field — replaces
the entire state, forcing every `ref.watch(itemsControllerProvider)` consumer to rebuild.

---

## Finding 1 — Monolithic `ItemsState` Drives Full-Tree Rebuilds

**Severity: CRITICAL**
**File:** `lib/modules/items/items/controllers/items_state.dart`
**File:** `lib/modules/items/items/controllers/items_controller.dart`

### Evidence
`ItemsState` holds:
- `List<Item> items` — the full product list
- `List<Map<String,dynamic>>` for units, categories, taxRates, taxGroups, brands,
  manufacturers, racks, storageConditions, buyingRules, drugSchedules, drugStrengths,
  contents, paymentTerms, priceListItems, customers — **15+ separate lookup lists**

Every call to `state.copyWith(isSaving: true)` creates a new `ItemsState` object that
replaces all 15 lookup lists, causing **every widget watching `itemsControllerProvider`**
to rebuild — even if it only cares about `isSaving`.

```dart
// items_controller.dart line ~841 — a trivial save-flag flip
state = state.copyWith(isSaving: true, validationErrors: {});
// ↑ This rebuilds: ItemListScreen, ItemDetailScreen, every FormDropdown
//   that reads state.categories, state.units, etc.
```

### Root Cause
`ItemsState.copyWith()` always creates a new instance of the entire state object.
Riverpod's `StateNotifierProvider` emits a new value on every `state =` assignment,
causing all watchers to rebuild regardless of which field changed.

### Impact
- **Estimated rebuild count per save operation:** 20–40 widget rebuilds
- **Modules affected:** Items List, Items Detail, Items Create/Edit, any screen
  importing `itemsControllerProvider`

### Recommended Fix
Split into separate providers:
```dart
// Separate provider for lookup data (changes rarely)
final itemLookupsProvider = StateNotifierProvider<ItemLookupsNotifier, ItemLookupsState>(...);

// Separate provider for items list (changes on CRUD)
final itemsListProvider = StateNotifierProvider<ItemsListNotifier, ItemsListState>(...);

// Separate provider for UI flags (isSaving, validationErrors)
final itemsUiProvider = StateNotifierProvider<ItemsUiNotifier, ItemsUiState>(...);
```

---

## Finding 2 — `MouseRegion` / `onEnter` / `onExit` Rebuilds Entire Table

**Severity: HIGH**
**File:** `lib/modules/sales/presentation/sales_generic_list.dart` — lines 446–484

### Evidence
```dart
// Line 447–448 — called on EVERY row, EVERY mouse move
onEnter: (_) => _state(() => _hoveredRowId = id),
onExit:  (_) => _state(() => _hoveredRowId = null),
```

`_state(() => ...)` calls `setState()` on `_SalesGenericListScreenState`.
This triggers a full rebuild of the **entire table** (all N rows) on every
single mouse-over event, because:
1. `_hoveredRowId` is state on the root widget
2. Every row checks `_hoveredRowId == id` in its `Container.color`

For a table with 500 rows, this is **500 widget rebuilds per mouse-move event**.

### Root Cause
`_hoveredRowId` is lifted to the parent state instead of being managed per-row.

### Recommended Fix
Extract each row to a `StatefulWidget` that manages its own hover state:
```dart
class _SalesTableRow extends StatefulWidget { ... }
class _SalesTableRowState extends State<_SalesTableRow> {
  bool _hovered = false;
  // setState here only affects this one row
}
```

---

## Finding 3 — `_calculateTotals()` Calls `setState()` on TextEditingController Listeners

**Severity: HIGH**
**File:** `lib/modules/sales/presentation/sales_invoice_create.dart` — lines 110–114, 130–150

### Evidence
```dart
// Line 110–111 — listeners attached in initState
shippingCtrl.addListener(_calculateTotals);
adjustmentCtrl.addListener(_calculateTotals);

// _calculateTotals calls setState (line 193–196)
setState(() {
  subTotal = st;
  total = subTotal + taxTotal + shipping + adjustment;
});
```

And inside `_addItemRow` (line 136–150), **every new line item row** attaches
a `quantityCtrl.addListener(...)` that reads `ref.read(salesCustomersProvider)`
inside the callback — a `ref.read` inside a listener, not inside `build`.

### Root Cause
- Listeners trigger full-page rebuilds via `setState` every keystroke in any field
- `ref.read` inside a `TextEditingController` listener is valid but creates coupling
  between controller events and provider reads at non-build time

### Recommended Fix
Use `ValueNotifier<double>` for `subTotal`/`total` combined with `ValueListenableBuilder`
to only rebuild the summary footer, not the entire page.

---

## Finding 4 — `allSalesOrderItemsProvider` Iterates All Orders on Every Watch

**Severity: MEDIUM**
**File:** `lib/modules/sales/controllers/sales_order_controller.dart` — lines 94–123

### Evidence
```dart
final allSalesOrderItemsProvider = FutureProvider<List<WarehouseStockData>>((ref) async {
  final salesOrdersAsync = ref.watch(salesOrderControllerProvider);
  return salesOrdersAsync.maybeWhen(
    data: (orders) {
      // ↓ O(N²) — nested loop over ALL orders and ALL items
      for (var order in orders) {
        for (var item in order.items!) { ... }
      }
    },
    ...
  );
});
```

This provider **watches** `salesOrderControllerProvider` — meaning it re-executes the full
nested loop every time any sales order changes (create, update, status change, etc.).

### Recommended Fix
Move to a `select`-filtered watch:
```dart
ref.watch(salesOrderControllerProvider.select((state) =>
  state.asData?.value.length // only re-run if count changes
));
```
Or compute `allSalesOrderItemsProvider` lazily, on-demand, not reactively.

---

## Summary Table

| # | Finding | File | Severity | Rebuilds/Event |
|---|---------|------|----------|----------------|
| 1 | Monolithic ItemsState | items_controller.dart | 🔴 CRITICAL | 20–40 |
| 2 | MouseRegion in table root state | sales_generic_list.dart | 🔴 HIGH | N (all rows) |
| 3 | TextCtrl listeners → full setState | sales_invoice_create.dart | 🟠 HIGH | Full page |
| 4 | allSalesOrderItemsProvider O(N²) | sales_order_controller.dart | 🟡 MEDIUM | All orders |
