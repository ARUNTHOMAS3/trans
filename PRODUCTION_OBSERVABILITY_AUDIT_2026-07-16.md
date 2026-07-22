# Zerpai ERP Production Observability Audit

Date: 2026-07-16
Environment: `https://zerpai.pages.dev`
Browser: Chrome, authenticated production session
Frontend: Flutter Web, CanvasKit
Scope: browser runtime evidence plus repository observability coverage
Method: CDP `Performance`, `Profiler`, `Tracing`, `Network`, `Runtime`, real navigation, and real pointer interaction

## Evidence boundary

This report follows the attached mandate: measure first, do not guess, and do not claim an optimization without evidence. Browser measurements below are real values from one authenticated desktop session. Request timings include browser scheduling, connection, preflight, server, and response delivery; they are not server-only timings. Heap values are point-in-time samples. No source code, database row, or production configuration was changed.

Flutter widget/provider counters, NestJS timings, Prisma timings, PostgreSQL plans, payload byte counts, and population-level Web Vitals were not exposed by the captured browser session. Those items are marked **not measured** and have an exact instrumentation path below.

# Executive Summary

| Measure | Result | Evidence status |
|---|---:|---|
| Desktop route LCP | 756–824 ms | Measured, 3 routes |
| Desktop route FCP | 704–792 ms | Measured, 3 routes |
| CLS | 0.00 | Measured, 3 routes |
| Passive settled FPS | ~62 FPS | Measured, 1-second sample |
| Largest interaction event | 336 ms pointerup | Measured, one real click |
| Largest frame gap | 316.6 ms | Measured, same click |
| Route long tasks | 4–5; 786–927 ms total | Measured |
| Post-click long tasks | 8; 1,522 ms total; 325 ms max | Measured |
| Slowest request | Dashboard summary, 3,295 ms | Measured client duration |
| Repeated bootstrap traffic | Org ×9, profile ×6, branches ×6 | Measured |
| JS heap samples | 81.7–122.9 MB | Measured point samples |
| TTI, GC frequency, payload bytes | Not measured | Instrumentation required |
| Backend/DB p50/p95/p99 | Not measured | Server/DB telemetry required |

Finding: idle desktop rendering is smooth, but interactive transitions are not. Main-thread long tasks and repeated bootstrap requests are the strongest verified bottlenecks. A score would be invented without route population, device tiers, backend latency, and memory-loop data; therefore no numeric overall score is assigned in this evidence-gated pass.

# Measurement Dashboard

## Route profiles

| Route | FCP/LCP | CLS | Long tasks | Max task | Script / task duration | Heap |
|---|---:|---:|---:|---:|---:|---:|
| Home | 704 / 756 ms | 0 | 5 / 927 ms | 294 ms | 4.372 / 5.219 s | 122.9 MB |
| Inventory adjustments | 792 / 824 ms | 0 | 4 / 786 ms | 236 ms | 2.373 / 2.961 s | 115.3 MB |
| Sales invoices | 736 / 768 ms | 0 | 5 / 862 ms | 310 ms | 3.926 / 4.543 s | 81.7 MB |

Layout duration was 1.549–2.179 ms per route snapshot; style recalculation was 10.381–12.228 ms. The short trace contained 53 events and no extracted Layout/Paint slice above the 5 ms extraction threshold. This points to main-thread/Dart/CanvasKit work, not a proven CSS layout bottleneck.

## Interaction profile

One real top-right control click from Sales Invoices opened invoice-create:

- pointerup: 336 ms.
- 8 long tasks after click; 1,522 ms cumulative; 325 ms maximum.
- 3 frame gaps over 50 ms; maximum gap 316.6 ms.
- CLS stayed 0.

This is direct evidence of a user-visible interaction stall.

## CPU and renderer samples

- Home: (program) 744 ms, CanvasKit 261 ms, GC 116 ms, Cb 98 ms, dartProgram 81 ms, a.Path.addPath 50 ms.
- Inventory: (program) 619 ms, Dart 84 ms, GC 76 ms, CanvasKit 63 ms.
- Sales: (program) 781 ms, CanvasKit 239 ms, Cb 85 ms, Dart 77 ms, getParameter 72 ms, GC 53 ms.

These are CPU-profile self-time samples, not total route cost.

# Top 20 Verified Browser Bottlenecks

| Rank | Severity | Evidence | Root-cause hypothesis to verify |
|---:|---|---|---|
| 1 | Critical | 336 ms pointerup; 316.6 ms frame gap | Synchronous route/create work blocks UI. |
| 2 | Critical | 8 post-click long tasks; max 325 ms | Invoice-create transition performs heavy work. |
| 3 | High | Home task max 294 ms | Home bootstrap has a blocking task. |
| 4 | High | Sales task max 310 ms | Sales list bootstrap blocks main thread. |
| 5 | High | Inventory task max 236 ms | Inventory bootstrap blocks main thread. |
| 6 | High | Dashboard summary 3,295 ms | Slow data path delays dashboard readiness. |
| 7 | High | Sales invoices 2,742 ms | Invoice list request is slow. |
| 8 | High | Org lookup 1,305–1,956 ms | Tenant lookup is slow and repeated. |
| 9 | High | Org lookup ×9 | Shared bootstrap is not deduplicated in session. |
| 10 | High | Profile ×6 | Auth/profile data is refetched per route. |
| 11 | High | Branches ×6 | Branch metadata is refetched per route. |
| 12 | High | Invoice endpoint ×4 | Invoice data request is repeated. |
| 13 | High | Dashboard summary ×3 | Aggregate request is repeated. |
| 14 | High | Heap 81.7–122.9 MB; GC 53–116 ms | Allocation/collection pressure exists. |
| 15 | Medium | CanvasKit 239–261 ms | Renderer startup/paint work costs CPU. |
| 16 | Medium | (program) 619–781 ms | Browser program work dominates samples. |
| 17 | Medium | Dart 77–84 ms | Dart bootstrap/dispatch contributes. |
| 18 | Medium | WebGL calls 45–72 ms | Capability/renderer setup costs CPU. |
| 19 | Medium | Style recalc 10–12 ms | Repeated bootstrap style work may compound. |
| 20 | Medium | One loading failure per list capture | Failed resource/request must be identified. |

These are the only top-20 claims supported by the current capture. A top-50 ranking for widgets, providers, SQL, payloads, or memory retainers is not reported because those measurements were not captured.

# Frontend Findings

## Verified

- Long tasks and the click frame gap show browser-side responsiveness failure.
- CanvasKit and Dart appear in CPU samples during route bootstrap.
- Desktop FCP/LCP/CLS are healthy in this narrow sample.
- One-second idle sampling is healthy; interaction sampling is not.

## Not measured yet

- Top 100 rebuilt widgets, build/raster durations, provider invalidations, ConsumerWidget rebuild fan-out, Future/Stream provider churn.
- JSON decode, sorting/filtering, table row creation, dialog/dropdown/date picker cost, controller disposal, animation and image/SVG cost.
- Exact Flutter file/widget mapping for the measured click.

## Required Flutter instrumentation

1. Add Timeline start/finish spans around route entry, page initialization, provider fetch/parse, JSON decode, table filtering/sorting, dropdown/date picker open, and dialog open.
2. Register SchedulerBinding addTimingsCallback and persist build, raster, and total frame durations with route and correlation IDs.
3. Use a debug-only rebuild counter (debugPrintRebuildDirtyWidgets plus a scoped counter) and ProviderObserver for Riverpod invalidation counts.
4. Wrap Dio/cache calls with request IDs, cache hit/miss, bytes, queue time, and decode duration. Redact tokens and business data.
5. Repeat with Flutter DevTools performance and memory timelines; capture exact widget names and source locations.

# Backend Findings

No NestJS controller, guard, interceptor, service, DTO, serializer, cache, or external API timing was available from the browser session. Client request duration cannot be attributed to any one backend layer.

## Required NestJS instrumentation

- Global request interceptor: request ID, route, status, bytes, queue time, handler time, serialization time, and total process.hrtime.bigint().
- Middleware/guard/permission spans: auth, organization, branch, RBAC, and validation durations, sampled without sensitive payloads.
- Prisma middleware/query events: query fingerprint, duration, rows, model, request ID, transaction ID, and error. Never log raw secrets or full values.
- OpenTelemetry/Prometheus histograms for p50/p95/p99 by route and status, plus in-flight requests, cache hit/miss, retry, and pool wait.

# Database Findings

No SQL text, query plan, row count, index usage, lock, deadlock, connection pool, or PostgreSQL wait event was captured. Claims about N+1, missing indexes, ILIKE, COUNT(*), joins, or OFFSET pagination would be speculation.

## Required PostgreSQL evidence

- Enable pg_stat_statements; export calls, total/mean/min/max time, rows, shared/local block hits/reads, temp blocks, and query fingerprints.
- Capture EXPLAIN (ANALYZE, BUFFERS, WAL, SETTINGS) for measured top queries.
- Sample pg_stat_activity, wait events, locks, deadlocks, and pool saturation.
- Correlate Prisma request IDs to API spans and database query fingerprints.
- Compare index scans/sequential scans and verify indexes against current schema.md; do not add speculative indexes.

# Network Findings

Measured endpoint counts across profiled captures:

| Endpoint | Count | Slow observation |
|---|---:|---:|
| /api/v1/lookups/org/{orgId} | 9 | 1,305–1,956 ms |
| /api/v1/auth/profile | 6 | up to 1,179 ms |
| /api/v1/branches | 6 | up to 1,037 ms |
| /api/v1/sales/invoices | 4 | 2,742 ms; another 1,200 ms |
| /api/v1/reports/dashboard-summary | 3 | 3,295 ms |
| /api/v1/inventory-adjustments | 2 | 1,196 ms |
| /api/v1/products/lookups/warehouses | 2 | not isolated as slowest |

204 preflight/actual pairs were observed. Response byte sizes, compression, server timing, cache headers, retry counts, and cancellation were not captured. Use PerformanceObserver resource entries, response Server-Timing, request IDs, and CDP Network encoded sizes in the next run.

# Memory and CPU Findings

The short route pass produced point heaps of 122.9 MB, 115.3 MB, and 81.7 MB; this is not a monotonic leak proof. Earlier live navigation evidence reported growth up to approximately 278 MB before collection, but that run lacked forced-GC snapshots and is not sufficient to identify a retaining path.

Required proof: repeat a fixed ten-route loop, force GC where permitted, take heap snapshots at baseline/5/10 loops, compare retained objects and detached DOM/CanvasKit resources, and record CPU/GC time per loop.

# Flutter Web Findings

- CanvasKit CPU samples are material during bootstrap.
- No direct LCP/INP issue was observed on load; interaction jank was observed.
- CSS layout/style numbers are small relative to long tasks.
- TTI is not exposed by the captured CDP surface.
- Mobile/tablet layout was not profiled here; the companion live audit records 390px/768px shell/content squeeze and wide-table problems.

Required follow-up: full Performance panel trace around invoice creation, account dropdown, date picker, table filtering, rapid navigation, and a 390/768/1024 px matrix under 4G/4x CPU throttling.

# Source Correlation Status

The browser profile identifies route and interaction symptoms, not Dart source locations. Exact correlation must be added through route/request correlation IDs and timeline labels. The repository companion reports remain the place for static file/line findings; they do not convert into runtime measurements.

Correlation output required for each event:

route → widget/page → provider/notifier → repository/Dio call → Nest route → service → Prisma fingerprint → PostgreSQL plan

No source-level optimization is approved from this profile alone.

# Observability Gaps

| Requested metric | Current status | Exact evidence needed |
|---|---|---|
| Flutter rebuild top 100 | Not measured | Scoped rebuild counter + DevTools timeline |
| Provider churn | Not measured | Riverpod ProviderObserver |
| Widget build/raster | Not measured | FrameTiming + timeline spans |
| API p50/p95/p99 | Not measured | Server histograms, route population |
| SQL p50/p95/p99 | Not measured | pg_stat_statements + plans |
| Payload top 50 | Not measured | Encoded/decoded byte telemetry |
| Heap retainers/GC frequency | Not measured | Repeated snapshots + allocation timeline |
| TTI | Not measured | Full trace with app-ready marker |
| Paint/layout attribution | Partial | Full Performance panel trace |
| Cache/retry/cancel rates | Not measured | Client and server counters |

# Optimization Priority Matrix

| Priority | Evidence gate | Action after measurement |
|---|---|---|
| P0 | 336 ms click and 316.6 ms frame gap | Trace invoice-create transition; split verified synchronous work. |
| P0 | 3,295 ms dashboard request | Correlate API span to SQL plan before query changes. |
| P0 | 2,742 ms invoice request | Capture server/DB breakdown and payload size. |
| P1 | Org/profile/branch duplicates | Identify owner/cache lifecycle; deduplicate only after contract check. |
| P1 | Heap/GC samples | Run repeated snapshots; fix retaining path, not symptoms. |
| P1 | One failed resource per list capture | Record URL/status and fix only confirmed failure. |
| P2 | CanvasKit/WebGL CPU | Compare renderer/device matrix after app work is isolated. |
| P2 | Mobile/tablet squeeze | Reproduce with responsive test matrix and shared shell owners. |

# Required Next Capture

1. Clean Chrome profile, extensions disabled, production-safe account.
2. Full Performance panel trace with screenshots for the 3 routes and invoice create, account dropdown, date picker, filtering, and sorting.
3. 390/768/1024/1440 px runs at 4G and 4x CPU throttle.
4. Ten-route loop with heap snapshots after each loop and forced GC where safe.
5. Flutter timeline/provider/rebuild instrumentation enabled in a diagnostic build only.
6. NestJS request spans and Prisma query timing enabled with redaction.
7. PostgreSQL pg_stat_statements, plans, locks, and pool metrics captured for the same correlation IDs.
8. Export raw JSON traces, HAR, heap snapshots, server histograms, and query plans alongside the next report.

# Backlog (Evidence-First)

1. Trace and decompose invoice-create interaction stall.
2. Add request IDs and server timing for dashboard/invoice requests.
3. Measure and remove confirmed bootstrap duplicate requests.
4. Capture dashboard and invoice SQL plans before query changes.
5. Add Flutter frame/rebuild/provider instrumentation.
6. Run heap-retainer loop and fix confirmed leaks.
7. Identify failed resource URLs and repair confirmed asset/request failures.
8. Validate dropdown/date-picker/table interaction traces.
9. Run responsive and throttled performance matrix.
10. Re-score only after route, device, API, DB, and memory populations exist.

## Final verdict

The captured evidence proves an interaction responsiveness problem and repeated bootstrap/network work. It does not prove a specific Dart widget, provider, NestJS service, Prisma query, PostgreSQL index, or memory leak. Instrumentation and correlation above are required before applying or claiming optimizations.

