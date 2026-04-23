# Enterprise Application Optimization Plan (v3)

This plan now includes the specific UX request to remove "slideshow-style" page transitions and implement a seamless content-only refresh.

## Status Snapshot (Updated: April 13, 2026 - 10:58 IST)

- **Completed now**:
  - Boot phase timing logs added in `main.dart` (`hive_init`, `config_box_open`, `core_boxes_open_parallel`, `env_load`, `supabase_init`, `first_frame_trigger`).
  - Hive core boxes are now opened in parallel via `Future.wait` instead of sequential open calls.
  - Timeout guardrails added for startup-critical phases (`Hive.initFlutter`, config box open, parallel box open, env load, Supabase init).
- **Partially complete**:
  - Auth rehydrate-first behavior is in place; fail-closed menu/page behavior exists but still requires full runtime role-matrix validation.
- **Completed now**:
  - Remaining `CustomTransitionPage` overlays in chart-of-accounts create/edit routes were switched to zero-animation (`child` passthrough) to remove slideshow/fade behavior.
- **Still pending**:
  - True lazy module-box open-by-first-use (instead of startup opening all module boxes).
  - Central mutation invalidation map (`endpoint -> providers`) rollout across modules.
  - Standardized no-raw-error-surface pass on all pages/controllers.
  - Startup degraded-mode payload fallbacks for optional backend modules.

## 1. UX Polish: Seamless Content Refresh

The current "slideshow" effect (new pages sliding over old ones) feels disruptive for an ERP. We will replace this with a **Seamless Content Swap**.

### **Transition Refactor (`app_router.dart`)**

- **Remove Slide Transitions**: Replace the default `MaterialPage` with `CustomTransitionPage` for all routes within the `ZerpaiShell`.
- **Zero-Latency Feed**: Use `transitionsBuilder: (context, anim, secondAnim, child) => child`. This removes the sliding animation entirely, making the middle content area refresh instantly when you click a link.
- **Static Shell Persistence**: Ensure that the **Sidebar** and **Navbar** remain completely static during navigation, with only the inner content area updating.

---

## 2. Startup & Entry Optimization

- **Parallel Hive**: Use `Future.wait` to open `config`, `settings`, and `auth` boxes simultaneously.
- **Lazy-Load Modules**: Postpone opening 15+ module-specific boxes until they are first accessed.
- **Single-Spinner Boot**: Synchronize HTML and Flutter splash screens to eliminate the "double loading" gap.
- **Auth Rehydrate First, Then Profile Refresh**: Restore user from cached `auth_token + user_data` immediately, then refresh `/auth/profile` in background to avoid null-user flicker after hard reload.
- **Fail-Closed Bootstrap**: Until auth session is rehydrated, keep module/menu gating closed; do not render unrestricted navigation during transient auth-null state.
- **Critical Route Prefetch**: On successful login, prefetch lightweight essentials (`/auth/profile`, org settings summary, role permissions payload) before first dashboard draw.
- **Startup Timeout Guardrails**: Add bounded timeouts per boot task (Hive, env, auth profile, lookups) and proceed with degraded mode instead of blocking app start indefinitely.

---

## 3. Real-Time State Synchronization

- **Reactive Invalidations**: Instead of manual "load" calls after saving, I will use `ref.invalidate(provider)`.
- **Instant Save Reflection**: This ensures that when you save an entry and return to the list, the new entry is already there without any manual refresh.
- **Mutation Invalidation Map**: Maintain a small central map of `endpoint -> providers to invalidate` to prevent stale lists and avoid over-invalidating the whole feature tree.
- **Optimistic Write Policy**: For simple list mutations (status toggles, labels), apply optimistic UI updates with rollback on API failure.

---

## 4. UI Streamlining

- **Remove Blocking Dialogs**: Replace intrusive "Success" and "Loading" modal dialogs with non-blocking **Toasts** and **Skeletons**.
- **Linear Progress**: Add a discreet **LinearProgressIndicator** at the top of the content area for background operations (like auto-saving).
- **No Raw Exception Surfaces**: Standardize user-facing error copy; route detailed stack/server messages only to logs.
- **Skeleton Consistency**: Use shared skeleton blocks per screen type (table, form, dashboard cards) to avoid visual jitter.

---

## 5. Backend Startup & API Responsiveness (Suggested Additions)

- **Cold-Path Query Audit**: Profile the first-load APIs (`dashboard-summary`, settings lookups, users/roles) and remove N+1 query paths.
- **Index Validation for New Renamed Tables**: Recheck indexes on renamed tables (`roles`, `branch_users`, `transaction_series*`, etc.) so renamed objects do not regress performance.
- **Graceful Missing-Table Handling**: For optional modules (for example temporary missing inventory tables), return empty payload fallbacks instead of 500s where business-safe.
- **Response Budget Targets**:
  - P50 < 250ms for settings lookups.
  - P95 < 800ms for dashboard summary.
  - Hard timeout + degraded payload after 2s.

---

## 6. Observability & Regression Safety (Suggested Additions)

- **Boot Timeline Logs**: Emit structured timings for boot phases: `hive_init`, `env_load`, `auth_check`, `router_ready`, `first_frame`.
- **Auth Session Metrics**: Track `rehydrate_success`, `profile_refresh_success`, `refresh_token_success`, `forced_logout`.
- **Permission Drift Checks**: Add a debug-only startup assertion comparing sidebar-visible modules vs permissions payload keys.
- **Release Gate**: Before release, run fixed checks:
  1. hard refresh while logged in (role/user must persist),
  2. non-admin menu visibility,
  3. direct URL denial for unauthorized routes,
  4. logout and token clear on reload.

---

## User Review Required

> [!IMPORTANT]
>
> - **Transition Style**: Based on your feedback, I am opting for **Zero Animation** (instant swap). This is common in high-density ERPs (like Zoho) as it feels faster and more "local."
> - **Content Flash**: Since we are removing the transition, you might see a tiny frame of the "Skeleton" state during the swap. I will tune this to be as smooth as possible.

---

## Verification Plan

### Manual Verification

- **Navigation Test**: Click between "Sales" and "Inventory" and verify the Sidebar stays still while only the content area updates instantly.
- **Sync Test**: Create a new Sales Order and verify it appears in the list immediately after the "Save" button is clicked.
- **Auth Reload Test**: Hard refresh as branch user and verify name, role label, and context id remain populated.
- **Permission Gate Test**: Confirm restricted user cannot see unauthorized modules/buttons, including after page reload.
- **Degraded API Test**: Temporarily fail one non-critical lookup endpoint and verify app remains usable with inline warning, not full-screen crash.

# ZERPAI ERP Performance Optimization Plan

A comprehensive performance review targeting Flutter UI jank, slow database queries, and app startup/sync issues across the 87-entry development history.

---

## 1. Flutter UI Performance (High Priority)

### 1.1 ListView Optimization

**Current State**: 71 ListView matches across 49 files. Many likely use default `ListView` instead of `ListView.builder`.

**Issues**:

- `ListView(children: [...])` loads all items into memory immediately
- No `itemExtent` specified causing expensive layout calculations during scroll
- `settings_zones_create_page.dart` has 29 matches - likely complex form lists

**Recommendations**:

```dart
// Replace with:
ListView.builder(
  itemCount: items.length,
  itemExtent: 60, // Fixed height prevents layout thrashing
  itemBuilder: (context, index) => _buildRow(items[index]),
)
```

**Target Files** (priority order):

1. `lib/core/pages/settings_zones_create_page.dart` (29 matches)
2. `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_create.dart` (25 matches)
3. `sales_order_create.dart`, `settings_organization_profile_page.dart`

### 1.2 Image Loading Optimization

**Current State**: 14 matches using `Image.network` - no evidence of `CachedNetworkImage`

**Issue**: Images reload from network on every screen visit, causing:

- Network bandwidth waste
- UI jank during image decode
- No offline image support

**Recommendation**:
Add `cached_network_image: ^3.4.1` to `pubspec.yaml` and replace:

```dart
// From:
Image.network(url)

// To:
CachedNetworkImage(
  imageUrl: url,
  placeholder: (context, url) => CircularProgressIndicator(),
  errorWidget: (context, url, error) => Icon(Icons.error),
  memCacheWidth: 200, // Resize to display size
)
```

### 1.3 Provider Rebuild Scope Issues

**Current State**: 129 ConsumerWidget/ConsumerStatefulWidget matches

**Risk**: Wide-scoped providers causing unnecessary rebuilds across entire widget trees

**Recommendation**:

- Use `select` API to watch specific properties:

```dart
// Instead of:
final user = ref.watch(userProvider);

// Use:
final userName = ref.watch(userProvider.select((u) => u.name));
```

- Split large providers into smaller, focused units
- Profile with Flutter DevTools "Performance" tab to identify hot rebuild paths

---

## 2. Database Query Performance (Critical)

### 2.1 Backend N+1 Query Risk

**Current State**: `products.service.ts` (lines 29-50) has heavy SELECT with 10+ joins:

```typescript
unit:units(id, unit_name),
category:categories(id, name),
manufacturer:manufacturers(id, name),
// ... 7 more joins
```

**Issue**: When fetching 100 products, this triggers 100×10 = 1000 individual queries

**Recommendation**:
Implement DataLoader pattern or batch loading:

```typescript
// Use Supabase's nested select carefully
// Or implement manual batching:
const products = await this.getProductIds(tenant);
const [units, categories, manufacturers] = await Promise.all([
  this.getUnitsForProducts(products.map((p) => p.unit_id)),
  this.getCategoriesForProducts(products.map((p) => p.category_id)),
  // ...
]);
// Merge in application layer
```

**Priority Services to Audit**:

1. `products.service.ts` (124 query matches - highest risk)
2. `global-lookups.controller.ts` (49 matches)
3. `branches.service.ts` (48 matches)
4. `accountant.service.ts` (42 matches)

### 2.2 Add Database Connection Pooling

**Current State**: Drizzle ORM with Supabase client - unclear if connection pooling configured

**Recommendation**:

```typescript
// In db.ts or supabase module:
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  max: 20, // Max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 2000,
});
```

### 2.3 Query Result Caching Layer

**Current State**: No evidence of query-level caching in backend

**Recommendation**: Add Redis-backed query cache for expensive lookups:

- Master data (units, categories, tax rates) - 1 hour TTL
- User permissions - 5 minute TTL
- Reports - 15 minute TTL with cache-bust on data mutation

---

## 3. App Startup & Sync Optimization

### 3.1 Hive Box Lazy Loading

**Current State**: `main.dart` opens 16+ boxes at startup (lines 193-214)

**Current Pattern** (good):

```dart
final boxesToOpen = boxDefinitions.entries
  .where((entry) => entry.key != 'config')
  .map((entry) => _openTypedBox(entry.key, entry.value))
  .toList();
final openedBoxes = await Future.wait(boxesToOpen); // Parallel
```

**Issue**: All boxes open even if user never visits those modules

**Recommendation**: Implement lazy box opening:

```dart
// Only open critical boxes at startup:
const criticalBoxes = ['auth', 'config', 'settings'];

// Defer others to first use:
Future<Box> getLazyBox(String name) async {
  if (Hive.isBoxOpen(name)) return Hive.box(name);
  return await Hive.openBox(name);
}
```

### 3.2 API Cache TTL Extension

**Current State**: `api_client.dart` (line 21) - 30-second cache TTL

```dart
bool get isExpired => DateTime.now().difference(timestamp).inSeconds > 30;
```

**Issue**: 30 seconds is too short for ERP data that changes infrequently

**Recommendation**:

- Master data (products, customers): 5 minutes
- Settings/config: 10 minutes
- Transactional data: 1 minute
- Implement per-endpoint TTL configuration:

```dart
final Map<String, Duration> ttlMap = {
  '/products': Duration(minutes: 5),
  '/settings': Duration(minutes: 10),
  '/orders': Duration(minutes: 1),
};
```

### 3.3 Persistent Cache with Hive

**Current State**: In-memory cache only (`_responseCache = {}`)

**Issue**: Cache lost on app restart, causing redundant API calls

**Recommendation**: Implement Hive-backed persistent cache:

```dart
class PersistentApiCache {
  final Box<CachedResponse> _cacheBox;

  Future<void> cacheResponse(String key, dynamic data) async {
    await _cacheBox.put(key, CachedResponse(
      data: data,
      timestamp: DateTime.now(),
    ));
  }

  CachedResponse? getCachedResponse(String key) {
    final cached = _cacheBox.get(key);
    if (cached == null) return null;
    if (cached.isExpired) {
      _cacheBox.delete(key);
      return null;
    }
    return cached;
  }
}
```

---

## 4. Quick Wins (Can Implement Today)

### 4.1 Add Flutter Performance Monitoring

```dart
// In main.dart, add to _initApp:
if (kProfileMode) {
  Timeline.startSync('appStartup');
  // ... init code
  Timeline.finishSync();
}
```

### 4.2 Debounce Search Inputs

Many search dialogs (`sales_generic_list_search_dialog.dart`) likely lack debouncing:

```dart
final _searchDebouncer = Debouncer(milliseconds: 300);

onSearchChanged(String value) {
  _searchDebouncer.run(() => performSearch(value));
}
```

### 4.3 Optimize Zone/Bins Runtime Store

From log entry #41, #47 - Zones/Bins uses temporary JSON store. As noted in deferred TODO, this should move to database with proper indexing for pagination performance.

---

## 5. Implementation Priority

**Phase 1 (This Week)**:

1. ✅ Add `cached_network_image` dependency
2. ✅ Audit top 5 ListView-heavy files for builder pattern
3. ✅ Extend API cache TTL to 2 minutes minimum

**Phase 2 (Next Sprint)**:

1. Implement Hive-backed persistent API cache
2. Add database connection pooling
3. Lazy-load non-critical Hive boxes

**Phase 3 (Ongoing)**:

1. DataLoader pattern for backend N+1 queries
2. Redis query caching for master data
3. Provider scoping optimization with `select` API

---

## 6. Performance Metrics to Track

Add to your logging/monitoring:

```dart
// In api_client.dart:
debugPrint('⏱️ [api] $path took ${stopwatch.elapsedMilliseconds}ms');

// In main.dart (already present - good!):
debugPrint('⏱️ [boot] hive_init=${hiveInitWatch.elapsedMilliseconds}ms');
debugPrint('⏱️ [boot] core_boxes_open_parallel=${hiveBoxesWatch.elapsedMilliseconds}ms');

// Track these in Sentry or analytics:
- Time to first frame
- API response times (p50, p95, p99)
- Cache hit rates
- Image load times
```

---

## Key Files Requiring Attention

**Frontend**:

- `lib/main.dart` - Startup optimization, lazy box loading
- `lib/core/services/api_client.dart` - Cache TTL, persistent cache
- `lib/modules/items/items/presentation/sections/items_item_create_images.dart` - Image caching
- `lib/core/pages/settings_zones_create_page.dart` - ListView optimization

**Backend**:

- `backend/src/modules/products/products.service.ts` - N+1 query pattern
- `backend/src/db/db.ts` - Connection pooling
- `backend/src/modules/redis/redis.service.ts` - Extend for query caching
