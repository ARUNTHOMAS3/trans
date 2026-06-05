# 08 — API Cache Strategy Audit
> Zerpai ERP | ApiClient Response Cache Analysis
> Audit Date: 2026-05-16 | Status: **STALE DATA RISK + OVER-INVALIDATION**

---

## Executive Summary

The `ApiClient` implements a manual in-memory response cache with a 30-second TTL.
The cache key is the full URL path, and invalidation is keyed by the **first path segment**
(e.g., `accountant`). This creates two serious risks: (1) ERP data that changes frequently
(stock levels, invoice status) remains stale for up to 30 seconds without the user knowing,
and (2) cache invalidation by path prefix can over-invalidate unrelated endpoints that share
the same prefix.

---

## Finding 1 — 30-Second Cache TTL on ERP Transactional Data

**Severity: HIGH**
**File:** `lib/core/services/api_client.dart`

### Evidence
```dart
// The cache mechanism in ApiClient
static const Duration _cacheTtl = Duration(seconds: 30);
final Map<String, _CacheEntry> _responseCache = {};

Future<ApiResponse> get(String path, ...) async {
  final cacheKey = _buildCacheKey(path, queryParams);
  final cached = _responseCache[cacheKey];
  if (cached != null && !cached.isExpired) {
    return cached.response; // Returns stale data up to 30s old
  }
  ...
  _responseCache[cacheKey] = _CacheEntry(response: response, ...);
}
```

### ERP Data Staleness Risk
| Data Type | Acceptable Stale Time | 30s Cache Risk |
|-----------|----------------------|----------------|
| Invoice status | Real-time | 🔴 CRITICAL — user sees wrong status |
| Stock level | Real-time | 🔴 CRITICAL — overselling risk |
| Customer balance | 5–15 minutes | 🟡 Acceptable |
| Payment status | Real-time | 🔴 CRITICAL |
| Product price | 1–5 minutes | 🟡 Acceptable |
| Lookup data (units, categories) | 1 hour | ✅ Fine |
| Dashboard summary | 5 minutes | 🟡 Acceptable |

**The 30s TTL is applied uniformly to ALL endpoints.** There is no differentiation
between transactional data (stock, invoices) and reference data (lookup tables).

### Recommended Fix
Implement tiered TTL caching:
```dart
static const Map<String, Duration> _cacheTtlByPrefix = {
  'lookup-bootstrap': Duration(minutes: 30), // Lookup data is stable
  'categories': Duration(minutes: 30),
  'units': Duration(minutes: 30),
  'tax-rates': Duration(minutes: 30),
  'dashboard': Duration(minutes: 5),         // Dashboard: 5 min acceptable
  'customers': Duration(minutes: 2),         // Customer list: 2 min
  'products': Duration(seconds: 30),         // Products: 30s ok for list
};

// Transactional endpoints: NO cache (or 0s TTL)
static const Set<String> _noCacheEndpoints = {
  '/sales',
  '/purchases',
  '/payments',
  '/inventory/stock',
  '/picklists',
  '/packages',
};
```

---

## Finding 2 — Cache Invalidation by First Path Segment Causes Over-Invalidation

**Severity: HIGH**
**File:** `lib/core/services/api_client.dart`

### Evidence
```dart
void invalidateCache(String pathPrefix) {
  final keysToRemove = _responseCache.keys
    .where((key) => key.contains('/$pathPrefix/') || key.endsWith('/$pathPrefix'))
    .toList();
  keysToRemove.forEach(_responseCache.remove);
}
```

The invalidation is triggered with the first path segment. If the backend is restructured
or if paths share common prefixes, this could:
1. **Under-invalidate**: A cached `/accountant/transactions` entry won't be cleared when
   invalidating `accountant` if the key is stored differently
2. **Over-invalidate**: Clearing `products` would also clear any path containing "products"
   as a substring — including `/composite-products/...` or `/products-reports/...`

Additionally, the comment in the source says "invalidate cache for a specific module" but
the implementation uses `.contains()` (substring match) rather than segment-boundary matching.

### Recommended Fix
Use explicit cache group tagging:
```dart
// Tag each cached response with its domain group
void cacheResponse(String path, ApiResponse response, {String? group}) {
  _responseCache[path] = _CacheEntry(response: response, group: group);
}

void invalidateCacheGroup(String group) {
  _responseCache.removeWhere((_, entry) => entry.group == group);
}

// Usage:
await get('/products', cacheGroup: 'products');
invalidateCacheGroup('products'); // Only removes 'products' group entries
```

---

## Finding 3 — No Cache Invalidation After SalesOrder Mutations

**Severity: HIGH**
**File:** `lib/modules/sales/controllers/sales_order_controller.dart`

### Evidence
After `createSalesOrder()`, `updateSalesOrder()`, or `deleteSalesOrder()`, the code calls
`loadSalesOrders()` which re-fetches from the API. However, because the `ApiClient` cache
has a 30-second TTL, the re-fetch may return the **cached pre-mutation response** if the
mutation happened within the cache window.

```dart
Future<SalesOrder?> createSalesOrder(SalesOrder sale) async {
  final newSale = await _apiService.createSalesOrder(sale);
  await loadSalesOrders(); // ← May return cached (stale) list!
  return newSale;
}
```

If `createSalesOrder` POST completes at T=0, and the last GET `/sales-orders` was cached
at T=-25s, the subsequent `loadSalesOrders()` GET at T=0 returns the cached response from
T=-25s — which **does NOT include the newly created order**.

### Fix
The mutation endpoints should call `invalidateCache('sales')` (or the tagged group) before
the subsequent GET:
```dart
Future<SalesOrder?> createSalesOrder(SalesOrder sale) async {
  final newSale = await _apiService.createSalesOrder(sale);
  _apiClient.invalidateCacheGroup('sales'); // ← Ensure next GET is fresh
  await loadSalesOrders();
  return newSale;
}
```

---

## Finding 4 — Riverpod `FutureProvider` Cache + `ApiClient` Cache = Double Caching

**Severity: MEDIUM**

### Evidence
Riverpod's `FutureProvider` caches its last successful result until the provider is
invalidated or the widget tree disposes it. The `ApiClient` caches the raw HTTP response
for 30 seconds. This creates a **two-layer cache**:

```
User navigates back to Sales Invoices list
  → Riverpod still holds previous FutureProvider result (no network call)
     OR
  → Riverpod re-fetches → ApiClient returns 30s cached HTTP response
     → Stale data shown in UI
```

Since `salesInvoicesProvider` is a global `FutureProvider` (not auto-disposed), it
persists across navigation. The API cache provides a secondary layer that may mask
the stale Riverpod data when a re-fetch is triggered.

### Recommended Architecture
- For transactional data (invoices, orders): use `FutureProvider.autoDispose` so data
  is always fresh on mount
- For lookup data (categories, units): use `FutureProvider` with long cache TTL

---

## Cache Health Summary

| Endpoint Type | Current TTL | Recommended TTL | Risk |
|--------------|------------|-----------------|------|
| Lookup/reference data | 30s | 30 minutes | 🟢 Undercached |
| Dashboard | 30s | 5 minutes | 🟢 Undercached |
| Product list | 30s | 30s | ✅ OK |
| Sales orders/invoices | 30s | 0s (no cache) | 🔴 CRITICAL — stale data |
| Stock/inventory levels | 30s | 0s (no cache) | 🔴 CRITICAL — wrong stock |
| Payments | 30s | 0s (no cache) | 🔴 CRITICAL — wrong balance |
| Customer list | 30s | 2 minutes | 🟡 Slightly risky |
