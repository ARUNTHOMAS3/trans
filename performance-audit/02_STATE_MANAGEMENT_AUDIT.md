# 02 — State Management Architecture Audit
> Zerpai ERP | Riverpod Provider Graph Analysis
> Audit Date: 2026-05-16 | Status: **STRUCTURAL RISKS**

---

## Executive Summary

The Riverpod provider graph has two structural problems: (1) a monolithic `StateNotifier` that
acts as a God Object for the entire items domain, and (2) multiple independent `FutureProvider`s
for sales document types that each independently fetch from the API with no shared invalidation
boundary. Neither issue is immediately crashing, but both create cascading invalidation and
excessive re-fetch patterns as the dataset grows.

---

## Finding 1 — ItemsController is a God Object (2,528 lines)

**Severity: CRITICAL**
**File:** `lib/modules/items/items/controllers/items_controller.dart`

### Evidence
- File has **2,528 lines** — far beyond any single-responsibility boundary
- `ItemsController` manages:
  - Product CRUD
  - Lookup data (16 endpoints at init)
  - Search/filter logic
  - Pagination/cursor logic
  - Offline draft management
  - Validation (duplicate code/SKU check)
  - Cache synchronization (`_syncLookupCache`)
  - `performSearch()` — full client-side search over loaded items

### State Size
`ItemsState` (286 lines) carries:
```dart
final List<Item> items;
final List<Map<String,dynamic>> units;
final List<Map<String,dynamic>> categories;
final List<Map<String,dynamic>> taxRates;
final List<Map<String,dynamic>> taxGroups;
final List<Map<String,dynamic>> brands;
final List<Map<String,dynamic>> manufacturers;
final List<Map<String,dynamic>> racks;
final List<Map<String,dynamic>> storageConditions;
final List<Map<String,dynamic>> buyingRules;
final List<Map<String,dynamic>> drugSchedules;
final List<Map<String,dynamic>> drugStrengths;
final List<Map<String,dynamic>> contents;
final List<Map<String,dynamic>> paymentTerms;
final List<Map<String,dynamic>> priceListItems;
// + UI flags: isLoading, isSaving, error, validationErrors, etc.
```

This violates single-responsibility and makes targeted state updates impossible.

### Recommended Architecture
```
itemsControllerProvider        → items list CRUD + pagination only
itemsLookupsProvider           → lookup data (FutureProvider, cached)
itemsSearchProvider            → derived from itemsControllerProvider via .select
itemsUiStateProvider           → isSaving, validationErrors
itemsOfflineDraftsProvider     → draft management
```

---

## Finding 2 — Eight Independent `FutureProvider`s for Sales Documents

**Severity: HIGH**
**File:** `lib/modules/sales/controllers/sales_order_controller.dart`

### Evidence
```dart
final salesQuotesProvider = FutureProvider<List<SalesOrder>>((ref) {
  return ref.watch(salesOrderApiServiceProvider).getSalesByType('quote');
});
final salesInvoicesProvider = FutureProvider<List<SalesOrder>>((ref) {
  return ref.watch(salesOrderApiServiceProvider).getSalesByType('invoice');
});
final salesCreditNotesProvider = FutureProvider<List<SalesOrder>>((ref) { ... });
final salesChallansProvider = FutureProvider<List<SalesOrder>>((ref) { ... });
final salesRetainerInvoicesProvider = FutureProvider<List<SalesOrder>>((ref) { ... });
final salesRecurringInvoicesProvider = FutureProvider<List<SalesOrder>>((ref) { ... });
final salesEWayBillsProvider = FutureProvider<List<SalesEWayBill>>((ref) { ... });
final salesPaymentLinksProvider = FutureProvider<List<SalesPaymentLink>>((ref) { ... });
```

**8 separate API calls fire when navigating to the Sales module.**
Each is independently cached by Riverpod but **none share an invalidation boundary**.
Creating a new invoice (via `salesOrderControllerProvider.createSalesOrder`) calls
`loadSalesOrders()` which only refreshes `salesOrderControllerProvider` — the 8 typed
list providers are NOT invalidated.

### Data Consistency Risk
After creating a quote or invoice:
- `salesOrderControllerProvider` → refreshed ✅
- `salesQuotesProvider` → stale ❌
- `salesInvoicesProvider` → stale ❌

### Recommended Fix
```dart
// Single provider that fetches all sales documents once
final salesDocumentsProvider = FutureProvider<SalesDocumentsBundle>((ref) async {
  final api = ref.watch(salesOrderApiServiceProvider);
  final [orders, payments, eWayBills, paymentLinks] = await Future.wait([
    api.getAllSalesOrders(),
    api.getPayments(),
    api.getEWayBills(),
    api.getPaymentLinks(),
  ]);
  return SalesDocumentsBundle(orders, payments, eWayBills, paymentLinks);
});

// Derived providers using .select
final salesInvoicesProvider = Provider<List<SalesOrder>>((ref) =>
  ref.watch(salesDocumentsProvider).asData?.value.invoices ?? []
);
```

---

## Finding 3 — `salesOrdersByCustomerProvider` Fetches Server Then Filters Client-Side

**Severity: MEDIUM**
**File:** `lib/modules/sales/controllers/sales_order_controller.dart` — lines 83–92

### Evidence
```dart
final salesOrdersByCustomerProvider =
    FutureProvider.family<List<SalesOrder>, String>((ref, customerId) async {
  final orders = await apiService.getSalesOrdersByCustomer(customerId);

  // ↓ Client-side post-filter after server fetch
  return orders.where((order) {
    final nestedCustomerId = order.customer?.id ?? '';
    return order.customerId == customerId || nestedCustomerId == customerId;
  }).toList();
});
```

The client-side `where` filter after the server call indicates that the backend's
`getSalesOrdersByCustomer` doesn't filter precisely by `customer_id` — it returns
a superset that then needs client-side filtering. This is a classic data contract leak.

### Recommended Fix
Ensure `getSalesOrdersByCustomer` backend route uses a strict `WHERE customer_id = $1`
clause and remove the client-side filter entirely.

---

## Finding 4 — `FutureProvider` with `ref.watch` Inside `itemRow._addItemRow`

**Severity: MEDIUM**
**File:** `lib/modules/sales/presentation/sales_invoice_create.dart` — lines 137–142

### Evidence
```dart
row.quantityCtrl.addListener(() {
  // ↓ ref.read inside a TextEditingController listener
  final customers = ref.read(salesCustomersProvider).asData?.value ?? [];
  final priceLists = ref.read(filteredPriceListsProvider).asData?.value ?? [];
  _updateRowRate(row, customer, priceLists);
  _calculateTotals();
});
```

`ref.read` inside a controller listener is correct (vs `ref.watch`), but this listener
is registered inside `setState(() { ... })` in `_addItemRow()`. Every time a row is added,
a new listener is registered — but the old listener from a row that's been replaced is
not guaranteed to be cleaned up, since row disposal only calls `row.dispose()` which
disposes the `TextEditingController` (not the listener reference in Riverpod).

### Risk: Memory leak if rows are frequently added/removed in long sessions.

---

## Provider Graph Risk Summary

| Provider | Type | Issue |
|----------|------|-------|
| `itemsControllerProvider` | StateNotifier | God Object, 2,528 lines |
| `salesQuotesProvider` | FutureProvider | Not invalidated on create |
| `salesInvoicesProvider` | FutureProvider | Not invalidated on create |
| `salesCreditNotesProvider` | FutureProvider | Not invalidated on create |
| `salesChallansProvider` | FutureProvider | Not invalidated on create |
| `salesRetainerInvoicesProvider` | FutureProvider | Not invalidated on create |
| `salesRecurringInvoicesProvider` | FutureProvider | Not invalidated on create |
| `allSalesOrderItemsProvider` | FutureProvider | Watches all orders, O(N²) |
| `salesOrdersByCustomerProvider` | FutureProvider.family | Client-side filter after fetch |
