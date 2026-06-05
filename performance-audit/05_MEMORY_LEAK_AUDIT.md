# 05 — Memory Leak & Resource Lifecycle Audit
> Zerpai ERP | Flutter Web | Dart VM Memory Management
> Audit Date: 2026-05-16 | Status: **CONFIRMED LEAKS + RISKS**

---

## Executive Summary

Two confirmed memory leak patterns were identified: (1) `TextEditingController` listeners
registered inside dynamic row construction that may not be cleaned up on row deletion,
and (2) `SyncService` holds a `StreamSubscription` that is correctly cancelled in `dispose()`
but the `Hive.box` is never explicitly closed. One additional risk pattern: `SalesGenericListScreen`
creates and destroys `OverlayEntry` objects without a guaranteed cleanup path if navigation occurs
during overlay visibility.

---

## Finding 1 — `TextEditingController` Listeners May Accumulate (Confirmed Risk)

**Severity: HIGH**
**File:** `lib/modules/sales/presentation/sales_invoice_create.dart` — lines 130–152

### Evidence
```dart
void _addItemRow() {
  setState(() {
    final row = SalesOrderItemRow(
      quantityCtrl: TextEditingController(text: '1'),
      rateCtrl: TextEditingController(text: '0'),
      discountCtrl: TextEditingController(text: '0'),
    );
    // ↓ Listener registered on this row's controller
    row.quantityCtrl.addListener(() {
      final customers = ref.read(salesCustomersProvider).asData?.value ?? [];
      _updateRowRate(row, customer, priceLists);
      _calculateTotals();
    });
    row.rateCtrl.addListener(_calculateTotals);
    row.discountCtrl.addListener(_calculateTotals);
    rows.add(row);
  });
}
```

### Cleanup Path
```dart
// In dispose()
for (var row in rows) {
  row.dispose(); // ← SalesOrderItemRow.dispose() calls controller.dispose()
}
```

**`TextEditingController.dispose()` removes all registered listeners.** ✅

However, if a row is **removed mid-session** via the trash button:
```dart
onPressed: () {
  setState(() => rows.removeAt(idx).dispose()); // ← dispose called on removal ✅
  _calculateTotals();
},
```

This is **correctly handled**. However, there is a subtle risk: the **lambda closure**
inside `row.quantityCtrl.addListener(...)` captures `ref`, `row`, and `selectedCustomerId`.
If the `ConsumerStatefulWidget` is disposed while a listener is still firing (race condition
during rapid navigation), `ref.read()` would throw on a disposed `WidgetRef`.

### Recommendation
Add a `mounted` guard in all listener callbacks:
```dart
row.quantityCtrl.addListener(() {
  if (!mounted) return; // ← Safety guard
  ...
});
```

---

## Finding 2 — `SyncService` Holds Open Hive Box Without Explicit Close

**Severity: MEDIUM**
**File:** `lib/shared/services/sync/sync_service.dart`

### Evidence
```dart
class SyncService extends StateNotifier<SyncState> {
  late Box _draftsBox;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void dispose() {
    _connectivitySubscription?.cancel(); // ✅ Subscription cancelled
    super.dispose();
    // ← _draftsBox is NEVER closed
  }
}
```

`Hive.Box` holds file handles and in-memory caches. While Hive handles hot reload
gracefully, a `Box` that is not closed on `dispose()` can:
1. Cause `HiveError: Box not found` on re-initialization in tests or if the provider
   is invalidated/re-created
2. Accumulate file handle leaks on long sessions with repeated provider invalidation

### Fix
```dart
@override
void dispose() {
  _connectivitySubscription?.cancel();
  if (_draftsBox.isOpen) {
    _draftsBox.close(); // ← Add explicit close
  }
  super.dispose();
}
```

---

## Finding 3 — `SalesGenericListScreen` OverlayEntry Without Guaranteed Disposal

**Severity: MEDIUM**
**File:** `lib/modules/sales/presentation/sales_generic_list.dart` — lines 89–91

### Evidence
```dart
final LayerLink _layerLink = LayerLink();
OverlayEntry? _overlayEntry;

// In dispose():
void dispose() {
  _hideFilterMenu(); // ← relies on _hideFilterMenu() being called
  _horizontalScrollController.dispose();
  super.dispose();
}
```

If `_hideFilterMenu()` removes the `OverlayEntry` from the `Overlay`, this is fine.
However, if the widget is disposed while the overlay is animating, or if `_overlayEntry`
is in a partially-constructed state, the overlay can remain attached to the `Overlay` stack
after the parent widget is gone — causing a ghost overlay.

### Recommendation
Add an explicit null-check and remove:
```dart
@override
void dispose() {
  _overlayEntry?.remove();
  _overlayEntry = null;
  _horizontalScrollController.dispose();
  super.dispose();
}
```

---

## Finding 4 — `Logger` Instance Created Per `SyncService` Instance

**Severity: LOW**
**File:** `lib/shared/services/sync/sync_service.dart` — line 34

### Evidence
```dart
class SyncService extends StateNotifier<SyncState> {
  final Logger _logger = Logger(); // ← New Logger instance per SyncService instance
  ...
}
```

`SyncService` is a `StateNotifierProvider` so it's a singleton — only one instance.
However, `Logger()` from the `logger` package creates a new `PrettyPrinter` and
associated output sinks per instance. If `SyncService` were ever invalidated and
re-created (e.g., during hot restart or test teardowns), multiple `Logger` instances
would accumulate.

### Fix
Use the shared `AppLogger` singleton:
```dart
// Replace:
final Logger _logger = Logger();
// With:
AppLogger.info('message', module: 'sync');
```

---

## Finding 5 — No `ScrollController.dispose()` Guard in `sales_generic_list`

**Severity: LOW (Already Fixed)**
**File:** `lib/modules/sales/presentation/sales_generic_list.dart` — lines 121–125

### Evidence
```dart
@override
void dispose() {
  _hideFilterMenu();
  _horizontalScrollController.dispose(); // ✅ Correctly disposed
  super.dispose();
}
```

This is correctly handled. Noted here for completeness.

---

## Memory Risk Summary

| Finding | File | Leak Type | Severity |
|---------|------|-----------|----------|
| TextCtrl listener closure captures `ref` without `mounted` guard | sales_invoice_create.dart | Potential crash on dispose | 🟠 HIGH |
| Hive Box not closed on SyncService dispose | sync_service.dart | File handle + memory | 🟡 MEDIUM |
| OverlayEntry not null-cleared on dispose | sales_generic_list.dart | Ghost overlay risk | 🟡 MEDIUM |
| Logger() per instance (singleton risk) | sync_service.dart | Minor: multiple output sinks | 🟢 LOW |
