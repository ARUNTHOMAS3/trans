# Zerpai ERP — Full Performance Audit

Date: 2026-07-16  
Scope: `E:\\zerpai-new` Flutter Web + NestJS/Supabase/Drizzle/PostgreSQL  
Mode: read-only static audit; no application source fixes made.

## Audit method and evidence boundary

Scanned the complete tracked source surface available in this checkout:

- 766 Dart files under `lib/` (~584,525 lines).
- 169 TypeScript files under `backend/src/` (~45,002 lines).
- `web/`, `pubspec.yaml`, backend package/config, `current schema.md`,
  `REUSABLES.md`, performance plans, PRD, migration/governance files, and
  recent implementation history.
- Pattern inventory for rebuilds, providers, scrollables, intrinsic layout,
  controllers, async context use, non-null assertions, network calls, SQL
  access, pagination, logging, caches, and large files.

Static findings are risk evidence, not latency measurements. No production
database, Chrome trace, Lighthouse run, DevTools heap snapshot, or API p95
sample was available. Impact estimates below are hypotheses to validate with
the measurement plan in the roadmap.

### Baseline verification

- `flutter analyze --no-pub`: **failed** with 14 issues (warnings/info), ran
  105.1 seconds. Existing issues include unused fields/elements and deprecated
  Radio APIs; see exact analyzer paths in the command output and triage list
  below.
- `backend/npm.cmd run build`: **passed** (`nest build`).
- `git status`: only pre-existing user change
  `lib/shared/widgets/dialogs/edit_quantity_dialog.dart`; audit did not modify
  it or any source file.

## Executive Summary

Overall performance score: **46/100 (static risk score, not a benchmark)**

Issue counts:

- Critical: **2**
- High: **10**
- Medium: **13**
- Low: **5**

Most probable root cause is cumulative: dashboard and lookup endpoints move
large unbounded sets, the backend repeats auth/scope work on every request,
and several transactional Flutter pages rebuild huge widget trees through
hundreds of `setState` calls. This is amplified by client-side sorting,
filtering, pagination, intrinsic layout, shrink-wrapped lists, and controller
churn.

Expected improvement after the highest-ROI sequence (requires measurement):

- Initial/route interaction latency: **25–55% lower**.
- Dashboard/lookup API payload and latency: **40–80% lower**.
- Browser memory retained by cache and large response graphs: **20–45% lower**.
- Backend p95 on affected endpoints: **30–70% lower**.
- Network bytes on lookup/product flows: **50–85% lower**.

These are planning ranges, not measured claims.

## Critical Bottlenecks

### C1 — Dashboard summary performs full-table reads and JavaScript aggregation

- Severity: **Critical**
- Location: `backend/src/modules/reports/reports.service.ts:212-497`
- Evidence: `account_transactions`, inventory batches, purchase batches,
  bills, sales orders, purchase orders, and related rows are selected without
  row limits; totals, grouping, sorting, and top-N selection run in Node.
  Customer names are then fetched with five additional queries at lines
  `315-328`.
- Why it happens: the endpoint returns a small dashboard but computes it from
  raw history instead of SQL aggregates/materialized summaries.
- Impact: response size and Node heap grow with tenant history; CPU and GC
  pauses increase; the Flutter dashboard waits for the slowest query chain.
- Recommendation: replace each raw read with bounded SQL `SUM/COUNT/GROUP BY`
  queries, run independent aggregates in parallel, enforce date/entity
  predicates, and cache a short-lived tenant dashboard snapshot.
- Estimated gain: **highest**, potentially 50–90% fewer rows and 30–70% lower
  dashboard latency after indexes are verified.

### C2 — Every authenticated request performs remote token validation plus
scope/permission database fanout

- Severity: **Critical**
- Locations:
  - `backend/src/common/middleware/tenant.middleware.ts:559-575`
  - `backend/src/common/auth/auth.service.ts:753-773`
  - `backend/src/common/auth/auth.service.ts:497-565`
  - `backend/src/common/middleware/tenant.middleware.ts:250-390`
- Evidence: middleware calls `validateToken` for each protected request;
  `validateToken` calls Supabase `auth.getUser`, public-user lookup, org
  resolution, and `buildAuthenticatedUser`. That builder performs parallel
  organization/entity/user/branch reads, then role context and branch fallback
  reads. Scope checks can add entity, parent, and warehouse reads.
- Impact: login/session latency becomes a multiplier on every API call and
  request waterfalls; concurrent dashboard requests amplify Supabase and DB
  connection pressure.
- Recommendation: verify JWT locally where safe, cache a short-lived immutable
  auth context keyed by token hash/user+role version, invalidate on role or
  membership changes, and collapse entity/branch scope into one bounded query.
- Estimated gain: **20–60% lower authenticated API overhead**; validate with
  request timing and DB query counts before changing security semantics.

### H1 — Product payload is wide and list default is 1,000 rows

- Severity: **High**
- Locations: `backend/src/modules/products/products.service.ts:40-58,
  661-688`
- Evidence: `PRODUCT_SELECT_STRING` begins with `*` and joins units,
  categories, manufacturers, brands, vendors, three accounts, racks, buying
  rules, drug schedules, storage, and compositions. `findAll` defaults to
  `.limit(1000)` when the caller omits a limit.
- Impact: large JSON payloads, Supabase serialization, Dio decoding, Dart
  object allocation, and table rebuild cost.
- Recommendation: endpoint-specific projections; default server page size
  50–100; cursor pagination; fetch detail relations only on detail routes.
- Estimated gain: **30–80% lower product list bytes and decode time**.

### H2 — Product search overfetches 100–500 wide rows then ranks in Node

- Severity: **High**
- Location: `backend/src/modules/products/products.service.ts:729-826`
- Evidence: `fetchLimit` is clamped to 100–500 at lines `735-749`, four
  contains-style `ILIKE` predicates are used, and all candidates are sorted
  with regex/string scoring in JavaScript at `753-824`.
- Impact: search keystrokes consume DB, network, and Node CPU; without a
  cancellation/debounce contract the UI can queue stale searches.
- Recommendation: indexed prefix/trigram search, server-side ranking,
  `limit <= 30`, debounce and cancel in Flutter, return a compact row DTO.
- Estimated gain: **40–90% lower search CPU/bytes** on large catalogs.

### H3 — Global lookup bootstrap is forced uncached and fan-outs 17 datasets

- Severity: **High**
- Locations:
  - `lib/modules/items/items/services/lookups_api_service.dart:12-17`
  - `lib/modules/items/items/controllers/items_controller.dart:439-456`
  - `lib/modules/items/items/controllers/items_controller.dart:1258-1261`
  - `backend/src/modules/products/products.service.ts:2227-2292`
- Evidence: Flutter requests `/products/lookups/bootstrap` with
  `useCache: false`; sync completion explicitly clears cache and calls
  `loadLookupData(force: true)`. Backend launches 17 lookup reads in one
  `Promise.all`.
- Impact: repeated large payloads, memory churn, and login/item navigation
  stalls; parallelism reduces wall time but not total DB/bytes.
- Recommendation: tenant/versioned lookup cache, module-scoped lookup bundles,
  compact projections, invalidation by changed lookup, and no unconditional
  post-sync full reload.
- Estimated gain: **50–85% fewer lookup bytes/requests**.

### H4 — Lookup sync performs serial usage checks and O(N²) matching

- Severity: **High**
- Locations: `backend/src/modules/products/products.service.ts:1399-1635,
  2547-2650`
- Evidence: `checkLookupUsage` loops mapped tables serially, issuing one query
  per check. `syncTableMetadata` loads all current rows, uses repeated
  `existingRecords.find` and `incomingIds.includes`, then awaits usage checks
  serially for every ID to disable.
- Impact: sync time grows multiplicatively with lookup size and reference count;
  it blocks the forced Flutter reload.
- Recommendation: map IDs/names into `Map` objects, bulk query references with
  `IN`, use set difference, batch deactivation checks, and return compact
  upsert results.
- Estimated gain: **70–95% lower sync CPU/query count** for large lookup sets.

### H5 — Transactional Flutter pages are giant rebuild surfaces

- Severity: **High**
- Locations (largest files):
  - `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`
    (18,428 lines; 192 `setState` matches)
  - `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`
    (14,649; 199)
  - `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`
    (14,627; 104)
  - `lib/modules/sales/credit_note/presentation/pages/credit_note_create_page.dart`
    (12,320; 168)
  - `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
    (10,764; 163)
- Evidence: hundreds of local `setState` sites in single page owners and deep
  form/table composition. This is static evidence of broad invalidation risk;
  it is not a frame trace.
- Impact: typing or changing one line item may rebuild the full form, table,
  totals, dialogs, and responsive layout.
- Recommendation: extract line-item/editor/totals sections, use focused
  Riverpod providers/notifiers, `select` only required fields, keep immutable
  row keys, and profile rebuild counts in DevTools.
- Estimated gain: **20–50% lower frame build time** on create screens.

### H6 — Intrinsic and shrink-wrap layout multiplies table/layout passes

- Severity: **High**
- Evidence: repo-wide static inventory found 96 `shrinkWrap: true` matches in
  58 files, 102 `Intrinsic*` matches in 36 files, 295
  `SingleChildScrollView` matches, and 249 `ListView` matches. High-density
  examples include bills create (4 scroll views/9 lists), invoices create
  (6/5), and purchase-orders create (3/5).
- Locations: examples
  `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`,
  `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`,
  `lib/modules/items/item_trade_setup/presentation/pages/item_trade_setup_overview_page.dart`.
- Impact: intrinsic measurement and nested scrollables defeat virtualization,
  increase layout work, and raise overflow risk on web.
- Recommendation: one primary scroll owner per route, bounded table viewport,
  `Sliver`/virtualized rows, fixed/known row extents, and remove intrinsic
  sizing from repeated rows.
- Estimated gain: **10–40% lower layout cost**, larger on long tables.

### H7 — Resource/controller churn risks leaks and per-build allocation

- Severity: **High**
- Evidence and locations:
  - `lib/modules/settings/users_roles/presentation/pages/settings_users_roles_role_creation.dart:334,346`
    creates `TextEditingController` in build.
  - `lib/shared/widgets/sections/license_registration_section.dart:165`
    creates fallback controller in build.
  - `lib/modules/accountant/presentation/pages/accountant_settings_screen.dart:94`
    creates a controller in widget construction path.
  - `lib/modules/items/items/presentation/sections/items_item_create_settings.dart:20`
    creates a `ScrollController` in a dialog builder.
  - `lib/modules/accountant/manual_journals/presentation/pages/manual_journal_templates_list_screen.dart:141`
    creates a local scroll controller without an owner-level dispose.
  - `lib/modules/sales/customers/presentation/sections/sales_customer_primary_info_section.dart:324`
    creates a controller in the build path.
- Inventory: 1,660 resource-allocation matches across 185 files with dispose
  implementations; 17 allocation files had no matching dispose by static
  heuristic. These require manual ownership validation.
- Recommendation: allocate in `initState`/state objects, dispose exactly once,
  avoid controllers in builders, and add leak tests for dialog open/close.
- Estimated gain: **memory stability and fewer GC spikes**, not safely
  quantifiable without heap snapshots.

### H8 — Root/provider rebuild scope is wider than necessary

- Severity: **High**
- Locations:
  - `lib/app.dart:29-38`: root watches branding and auth and rebuilds
    `MaterialApp.router`.
  - `lib/modules/home/providers/dashboard_provider.dart:146-169`: provider
    watches Dio, auth, entity, and user identity, then fetches immediately.
  - `lib/modules/settings/automation/providers/workflow_governance_provider.dart:8-93`:
    11 derived providers all watch one global `ChangeNotifier`.
- Impact: auth/branding/entity changes invalidate router/theme or all workflow
  projections; dashboard requests can repeat after dependency changes.
- Recommendation: use stable `ProviderScope` overrides, `ref.select`, explicit
  refresh commands, `autoDispose` where route-scoped, and precomputed workflow
  snapshots instead of recomputing every provider on each event.
- Estimated gain: **15–40% fewer unnecessary rebuilds** in affected routes.

### H9 — Audit interceptor adds database work to every write

- Severity: **High**
- Locations: `backend/src/common/interceptors/audit.interceptor.ts:170-269,
  343-358, 360-375`
- Evidence: PUT/PATCH/DELETE fetch the old record with `select("*")` before
  handler execution; all writes then insert an audit row.
- Impact: write latency and payload increase; broad old-row reads are costly on
  large records. Fire-and-forget logging can also create unbounded concurrent
  writes under burst traffic.
- Recommendation: table-specific audit projections, transaction/outbox or
  bounded queue, sampling for non-critical API actions, and timing metrics.
- Estimated gain: **10–35% lower write p95** for audited routes.

### H10 — API cache is unbounded and has broad invalidation

- Severity: **High/Medium boundary**
- Location: `lib/core/services/api_client.dart:56-99, 646-696`
- Evidence: singleton cache map has 30-second TTL, cleanup only during GET
  lookup, no max entries/bytes, and invalidation removes keys containing the
  first path segment. GET caching is enabled by default, while force refresh
  still writes the response.
- Impact: large lookup/product responses remain retained until another GET;
  broad invalidation creates cache misses and request bursts.
- Recommendation: bounded LRU/byte budget, per-resource policies, explicit
  invalidation keys, request coalescing, and `CancelToken` support.
- Estimated gain: **20–45% lower retained cache memory**; latency benefit
  depends on hit rate.

## Frontend Findings

### Rebuild and state pressure

- 5,237 `setState` matches across 259 files; the largest create pages listed
  above are the primary frame-budget risk.
- 663 `ref.watch` matches across 205 files and 316 Consumer/provider matches
  across 201 files indicate substantial reactive surface. Counts do not prove
  misuse; profile rebuild counts before refactoring.
- `workflowRuntimeStoreProvider` is a global singleton ChangeNotifier. Every
  `notifyListeners()` can invalidate 11 derived providers and repeatedly scan
  up to 500 events.

### Tables, filtering, and pagination

- Only four `DataTable` files were found; most tables are custom rows/lists,
  making virtualization and key stability route-specific.
- Client-side page slicing/filtering exists in
  `lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_list_panel.dart:220,293-298`,
  `lib/modules/accountant/manual_journals/presentation/widgets/recurring_journals_list_panel.dart:66,151-154`,
  and `lib/modules/accountant/payments_received/presentation/pages/accountant_payments_received_overview_screen.dart:51,281-282,1424-1425`.
  These operate on the complete loaded list; move filtering/page windows to
  API queries for high-cardinality data.

### Async/lifecycle risk inventory

- 2,740 non-null assertions across 302 files and 167 async-context proximity
  matches were found. These are risk inventories, not proof of crashes.
  Manually review mounted checks around:
  `lib/modules/purchases/expenses/presentation/pages/purchases_expenses_create_page.dart:1905-1981`,
  `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:6503-6511`,
  and `lib/modules/inventory/move_orders/presentation/pages/inventory_move_orders_create.dart:2230-2281`.
- Add analyzer rules/tests for `context.mounted`, cancel in-flight searches,
  and dispose verification.

## Backend Findings

- `backend/src/modules/products/products.service.ts` is 2,902 lines;
  expenses 2,317, sales 2,276, inventory adjustments 2,091, users 1,716,
  recurring expenses 1,704. These are hotspot candidates for service
  decomposition and query-level profiling.
- 918 `.from(...)` calls across 41 files and 106 `select("*")` calls across
  27 files show broad Supabase reads. Top `select("*")` concentrations are
  sales, expenses, inventory adjustments, users, recurring expenses,
  products, and accountant services.
- Only 20 files use `.range(...)` and 16 use `.limit(...)`; pagination is not
  a repo-wide invariant. Enforce bounded defaults and reject unbounded list
  endpoints.
- 26 `Promise.all` sites are positive parallelism, but must be bounded and
  paired with compact projections; parallel full-table reads still overload DB.
- `backend/src/main.ts:24-25` accepts 50 MB JSON/urlencoded bodies. This is a
  memory and CPU spike risk; use route-specific limits and streaming uploads.
- `backend/src/main.ts:105-123` globally transforms/validates DTOs and logs
  full validation payloads at `116-120`; avoid serializing sensitive/large
  values in error paths.
- `backend/src/db/db.ts:20-30` creates a postgres client without explicit pool
  limits/timeouts and executes startup `ALTER TABLE ... IF NOT EXISTS`. Move
  DDL to migrations and configure pool/idle/connect timeouts explicitly.

## Database Findings

- Runtime access is mixed: Supabase client calls dominate while Drizzle
  `postgres-js` is also used (`backend/src/db/db.ts`, reports raw SQL), and
  both `backend/src/db/schema.ts` and `backend/drizzle/schema.ts` exist in
  addition to `current schema.md`. This drift prevents a safe static claim
  that every production query has the intended index.
- `backend/drizzle/schema.ts` contains useful indexes (entity/product/status
  and account lookup indexes), but their deployment and parity with
  `current schema.md` require migration/live-DB verification.
- Candidate queries needing `EXPLAIN (ANALYZE, BUFFERS)`:
  product contains search (`products.service.ts:737-749`), dashboard account
  transaction scans (`reports.service.ts:212-321`), batch stock aggregation
  (`reports.service.ts:340-373`), and audit old-row reads
  (`audit.interceptor.ts:343-354`).
- Search uses contains-style ILIKE; confirm trigram indexes and selectivity.
  Do not add indexes blindly: capture plans and index usage first.
- Dashboard uses application-side `COUNT`/SUM/reduction and can force large
  sequential reads. Replace with indexed aggregate queries and date/entity
  predicates.
- Pagination is mixed; prioritize cursor pagination for products, ledger,
  transactions, audit logs, and any list that can exceed one page.

## Network Findings

- Lookup bootstrap is explicitly uncached in Flutter and fan-outs 17 backend
  reads (`lookups_api_service.dart:12-17`, `products.service.ts:2227-2278`).
- `ApiClient` has no observed shared cancellation/coalescing contract; search
  endpoints can therefore return stale responses after rapid typing.
- Wide product projections and dashboard raw rows overfetch. Add response-size
  and request-duration interceptors with route, tenant, status, bytes, and
  cache-hit fields.
- `web/index.html:33-35` sets `no-cache, no-store, must-revalidate`, disabling
  repeat-load caching for the HTML entrypoint. Keep immutable hashed bundles
  cacheable while using short cache only for HTML/config.
- Clarity loads asynchronously on every page at `web/index.html:37-49`.
  Measure its startup/CPU impact and gate it behind consent/production
  sampling if it affects first meaningful paint.
- No repository evidence of deferred Flutter imports, workers, or route-level
  code splitting. Confirm generated bundle composition with a release build
  and browser performance profile before investing.

## Memory Findings

- `_responseCache` retains arbitrary response graphs with no entry/byte cap
  (`lib/core/services/api_client.dart:62-92`).
- Controllers created in build/dialog builders can retain text/value graphs or
  trigger repeated allocations (H7 locations).
- Dashboard and lookup endpoints deserialize large arrays into Node/Dart maps;
  both sides retain duplicate representations during mapping/reduction.
- Workflow store caps `_events` at 500 (`lib/core/workflow/workflow_runtime_store.dart:64-68`)
  but holds additional queues/maps and exposes copied/unmodifiable collections;
  repeated snapshot construction should be measured.
- Add heap snapshots after 30 minutes of navigation, cache byte telemetry,
  and open/close dialog leak tests. No leak is declared proven without these.

## CPU Findings

- Dashboard reductions/sorts scan raw rows repeatedly (`reports.service.ts:237-285,
  301-328, 379-421, 437-499`).
- Product search computes regex/ranking and sort in Node (`products.service.ts:753-826`).
- Lookup sync uses repeated linear `find`, `includes`, and serial checks
  (`products.service.ts:2585-2636`).
- Workflow derived providers repeatedly scan event/queue collections on each
  notification (`workflow_runtime_store.dart:175-255`).
- Flutter intrinsic layout and shrink-wrap counts indicate extra layout passes;
  giant `setState` pages increase build CPU.
- Date formatting, JSON conversion, and table filtering should be moved out of
  build methods and memoized/selector-scoped where traces confirm hotspots.

## Flutter Web Findings

- `pubspec.yaml:90-107` declares fonts/assets; the assets tree contains about
  20 MB, including ~18.5 MB of font files while only five font files are
  declared. Remove unused font binaries after verifying branding requirements.
- `web/index.html:33-35` disables entrypoint caching; use correct immutable
  caching for versioned JS/assets.
- No renderer selection, deferred import, worker, or bundle budget was found
  in the scanned source. Measure release `main.dart.js`/CanvasKit size and
  startup on representative Chrome hardware.
- Static paint inventory: 78 `CustomPaint` matches in 47 files, 38
  `Image.network` matches in 30 files, 30 `Opacity` matches in 19 files, and
  14 `SvgPicture` matches in six files. Audit large images, SVG complexity,
  repaint boundaries, and opacity layers in DevTools rather than assuming all
  are slow.
- Analyzer currently reports 14 issues and therefore is not a clean baseline.
  Backend build passes; no release web build was run in this read-only audit.

## Architecture Findings

- Runtime data access has three competing truths: `current schema.md`,
  `backend/src/db/schema.ts`, and `backend/drizzle/schema.ts`, while services
  use Supabase and Drizzle. This increases query/index drift and makes caching
  ownership unclear.
- Product service and transactional Flutter pages are god files. Split by
  bounded query/use-case and UI section while preserving module ownership and
  reusable widget rules.
- Global singleton state (`WorkflowRuntimeStore`, `ApiClient`) is convenient
  but needs explicit lifecycle, cache limits, and invalidation contracts.
- Performance plan targets (FMP <2 s, route transition <300 ms, API p95 <500
  ms, duplicate calls reduced 50%+) are documented, but current telemetry does
  not prove compliance. Add route/API/frame metrics before declaring success.

## Quick Wins (less than 30 minutes each)

1. Add route timing, response bytes, cache-hit, and query-count logging to
   `ApiClient`/backend with sampling.
2. Cap product `findAll` default to 50–100 and require explicit pagination.
3. Debounce/cancel product search and cap server result to 30 compact rows.
4. Remove controller construction from build methods at the H7 locations.
5. Add a max-entry/byte limit to `_responseCache` and expose cache metrics.
6. Replace full validation-error value logging in `backend/src/main.ts` with
   field/type-safe summaries.
7. Audit unused font binaries and remove only after visual verification.
8. Triage the 14 analyzer issues and make `flutter analyze --no-pub` clean.

## Medium Optimizations (1–3 hours)

1. Split lookup bootstrap into versioned, module-scoped bundles and cache them.
2. Convert lookup sync matching to maps/sets and bulk usage queries.
3. Add server cursor pagination and compact DTOs to product, account, contact,
   transaction, and audit lists.
4. Extract one high-traffic invoice/bill line-item editor into focused
   providers and profile rebuild counts.
5. Remove nested scroll ownership and intrinsic sizing from one large table
   route; add row keys and bounded viewport.
6. Add auth-context caching with role/membership-version invalidation, after
   security review.
7. Replace dashboard raw reads with bounded aggregate queries and a short TTL.
8. Configure Postgres pool, connection, statement, and idle timeouts.

## Major Refactors (1–5 days)

1. Build a single authoritative query/schema migration path and verify indexes
   against `current schema.md` in CI.
2. Introduce a report aggregation layer/materialized summary for dashboard and
   chart workloads.
3. Decompose `products.service.ts` into lookup, product-list, search, sync,
   and usage-query services with endpoint-specific projections.
4. Replace global ChangeNotifier workflow projections with event-indexed
   snapshots/selectors.
5. Establish a reusable virtualized ERP table shell with server pagination,
   loading/empty/error states, and row-level rebuild boundaries.
6. Add browser performance CI budgets for bundle size, FMP, route transition,
   long tasks, and heap after scripted navigation.

## Top 20 Highest-ROI Fixes

1. SQL-aggregate dashboard summary (`reports.service.ts:212-497`).
2. Cache/collapse per-request auth and tenant scope resolution.
3. Replace 17-way uncached lookup bootstrap.
4. Enforce compact product projections and 50–100 row pagination.
5. Server-rank product search with trigram/prefix indexes.
6. Bulk/parallelize lookup usage checks.
7. Replace O(N²) lookup sync matching with maps/sets.
8. Extract invoice/bill line-item state from giant `setState` pages.
9. Remove intrinsic/shrink-wrap/nested scrollables from high-volume tables.
10. Add request cancellation/coalescing to search and lookup calls.
11. Bound ApiClient cache by bytes and entries.
12. Add auth-context cache with secure invalidation.
13. Replace audit `select("*")` old-row reads with projections/outbox.
14. Move list filtering and paging server-side.
15. Configure DB pool and query timeouts.
16. Remove per-build controller allocations and prove dialog disposal.
17. Precompute workflow snapshots instead of 11 scans per event.
18. Enable correct immutable web asset caching and measure Clarity cost.
19. Reduce 50 MB global body limits to route-specific limits.
20. Remove unused font payload and enforce bundle budgets.

## Performance Roadmap

### Week 1 — Measure and stop obvious amplification

- Add frontend/backend timing, payload, cache, DB query-count, and error
  correlation IDs.
- Capture Chrome DevTools traces for login, dashboard, product search, invoice
  create, and a 1,000-row table.
- Triage analyzer issues; establish release web build and Lighthouse baseline.
- Cap list defaults, body limits, cache size, and search result size.

### Week 2 — Remove overfetch and duplicate work

- Implement dashboard SQL aggregates and product compact DTOs.
- Split/cache lookup bootstrap; remove unconditional forced reload.
- Add search debounce/cancel and server ranking.
- Validate indexes with `EXPLAIN (ANALYZE, BUFFERS)` on the candidate queries.

### Week 3 — Reduce Flutter frame and memory cost

- Extract one invoice/bill editor into granular providers.
- Replace nested scrollables/intrinsic sizing in the top two table routes.
- Fix controller ownership/disposal findings and add leak regression tests.
- Replace workflow global recomputation with indexed snapshots/selectors.

### Week 4 — Harden architecture and enforce budgets

- Consolidate schema/migration authority and document Supabase/Drizzle
  boundaries.
- Add cursor pagination and bounded response contracts to remaining high-volume
  endpoints.
- Add CI budgets for bundle size, FMP, route latency, long tasks, API p95,
  payload bytes, and heap growth.
- Re-run the exact scripted scenarios and compare against the Week 1 baseline.

## Required next measurements

Before coding broad refactors, capture p50/p95/p99 for the five scenarios,
rows/bytes/query counts per endpoint, Flutter build/raster durations, provider
rebuild counts, long-task durations, and heap before/after 30-minute scripted
navigation. The static audit identifies where to measure; it cannot substitute
for those traces.

