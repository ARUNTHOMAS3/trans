# Chrome DevTools Performance Audit — Zerpai ERP

Date: 2026-07-16  
Environment: `https://zerpai.pages.dev`  
Browser: Chrome, authenticated production session  
Renderer: Flutter Web CanvasKit  
Method: CDP `Performance`, `Profiler`, `Tracing`, `Network`, `Runtime`, and real browser navigation/clicks

## Evidence boundary

This is a browser-session profile, not a lab benchmark. Measurements include browser
startup, service worker, network, Flutter bootstrap, CanvasKit, and application work.
Request durations are from `Network.requestWillBeSent` to `Network.responseReceived`; they
are not server-only timings. Heap values are point-in-time values and GC is nondeterministic.

Routes profiled:

- `/60000000000/home`
- `/60000000000/inventory/adjustments`
- `/60000000000/sales/invoices`
- One real top-right control click from Sales Invoices, which opened the invoice-create route.

Screenshots were captured by the Chrome control session at each navigation/click. The
browser connector returned them as ephemeral session images; no source or production data
was changed. A short `Tracing.start`/`Tracing.end` profile completed successfully with 53
trace events.

# Executive Summary

| Signal | Result | Interpretation |
|---|---:|---|
| Passive settled FPS | ~62 FPS | Healthy while idle on the tested desktop page. |
| Largest Contentful Paint | 756–824ms | Good on these desktop navigations. |
| First Contentful Paint | 704–792ms | Good after document load. |
| CLS | 0.00 on all three route loads | No measurable load-time layout shift in this pass. |
| Largest observed INP-like event | 336ms `pointerup` | Poor; exceeds the 200ms “good” interaction target. |
| Largest observed frame gap | 316.6ms | Visible interaction jank/freeze. |
| Long tasks | 4–5 per route; 236–310ms max | Main-thread blocking is the primary browser-side issue. |
| API request waterfall | 32 API requests across captures | Stable bootstrap data is repeatedly fetched. |
| Slowest measured API | dashboard summary 3,295ms | Direct source of delayed dashboard readiness. |
| JS heap samples | 81.7–122.9MB in this pass | Not monotonic here; requires repeated-route heap snapshots. |
| TTI | Not directly exposed | CDP trace did not include a valid TTI marker. |

Overall verdict: initial desktop paint is acceptable, but interaction responsiveness and
request waterfalls are not enterprise-grade. The 336ms interaction and 316.6ms frame gap
are the strongest direct browser-side regressions. Earlier live audit evidence also found
390px/768px layout failure; this profile was desktop-only.

# Captured Route Profiles

## Home

| Metric | Value |
|---|---:|
| Navigation-to-settled observation | 6.708s including 3.5s settle and profiling overhead |
| First Paint / First Contentful Paint | 704ms / 704ms |
| LCP | 756ms; reported size 89,855 |
| CLS | 0 |
| Long tasks | 5; total 927ms; max 294ms |
| Script duration | 4.372s cumulative metric |
| Task duration | 5.219s cumulative metric |
| Layout / style recalculation | 2.179ms / 12.228ms |
| JS heap | 122.9MB |
| API/network events | 79 events |

CPU profile top samples: `(program)` 744ms, CanvasKit 261ms, garbage collector 116ms,
`Cb` 98ms, `dartProgram` 81ms, `a.Path.addPath` 50ms.

## Inventory Adjustments list

| Metric | Value |
|---|---:|
| First Paint / First Contentful Paint | 792ms / 792ms |
| LCP | 824ms; reported size 89,854 |
| CLS | 0 |
| Long tasks | 4; total 786ms; max 236ms |
| Script duration | 2.373s cumulative metric |
| Task duration | 2.961s cumulative metric |
| Layout / style recalculation | 2.028ms / 11.367ms |
| JS heap | 115.3MB |
| API/network events | 80 events; one loading failure |

CPU profile top samples: `(program)` 619ms, `dartProgram` 84ms, garbage collector 76ms,
CanvasKit 63ms, `getProgramParameter` 48ms, `getExtension` 46ms.

## Sales Invoices list

| Metric | Value |
|---|---:|
| First Paint / First Contentful Paint | 736ms / 736ms |
| LCP | 768ms; reported size 89,858 |
| CLS | 0 |
| Long tasks | 5; total 862ms; max 310ms |
| Script duration | 3.926s cumulative metric |
| Task duration | 4.543s cumulative metric |
| Layout / style recalculation | 1.549ms / 10.381ms |
| JS heap | 81.7MB after GC |
| API/network events | 88 events; one loading failure |

CPU profile top samples: `(program)` 781ms, CanvasKit 239ms, `(idle)` 125ms,
`Cb` 85ms, `dartProgram` 77ms, `getParameter` 72ms, garbage collector 53ms.

# Interaction Profile

A real pointer click was performed on the top-right control area of Sales Invoices. The
click opened the invoice-create route. After the click, the in-page observer recorded:

- Largest interaction event: `pointerup`, 336ms.
- Long tasks: 8; cumulative 1,522ms; maximum 325ms.
- Frame gaps above 50ms: 3.
- Maximum frame gap: 316.6ms.
- CLS remained 0.

This is direct evidence of a user-visible stall, even though passive route settling showed
about 62 FPS.

# Short Rendering Trace

Trace sequence:

1. `Tracing.start` with `devtools.timeline`, `blink.user_timing`, and
   `disabled-by-default-devtools.timeline`.
2. Real pointer click.
3. 1.2s observation window.
4. `Tracing.end` and `Tracing.tracingComplete` received.

Trace result: 53 events, complete trace. The longest `RunTask` slices in this short window
were approximately 17ms. No distinct Layout/Paint slice above the 5ms extraction threshold
was returned. This does not disprove the 336ms interaction stall: the Performance Timeline
observer measured the end-to-end event/frame delay, while this short trace was too narrow to
attribute every Flutter CanvasKit task to a named paint/layout slice.

# Top 20 Browser-Side Bottlenecks

| Rank | Severity | Evidence | Bottleneck |
|---:|---|---|---|
| 1 | Critical | 336ms pointerup; 316.6ms frame gap | Interaction blocks the main/UI thread. |
| 2 | Critical | 8 long tasks after click; max 325ms | Invoice-create transition performs heavy synchronous work. |
| 3 | High | Home max long task 294ms | Home bootstrap has a large blocking task. |
| 4 | High | Sales max long task 310ms | Sales list bootstrap blocks rendering. |
| 5 | High | Inventory max long task 236ms | Inventory list bootstrap blocks rendering. |
| 6 | High | Dashboard summary request 3,295ms | Dashboard API directly delays usable data. |
| 7 | High | Sales invoices request 2,742ms | Invoice list data path is slow. |
| 8 | High | Organization lookup 1,305–1,956ms, repeated | Tenant metadata is slow and fetched repeatedly. |
| 9 | High | 32 API events; org lookup ×9 | Duplicate tenant bootstrap traffic. |
| 10 | High | Profile ×6; branches ×6 | Auth/profile and branch data are refetched per route. |
| 11 | High | Invoice endpoint ×4 | Invoice list calls are duplicated across the session. |
| 12 | High | Dashboard summary ×3 | Dashboard aggregate request repeats. |
| 13 | High | Heap samples 81.7–122.9MB; GC 53–116ms | Memory/GC pressure is material during bootstrap. |
| 14 | Medium | CanvasKit 239–261ms CPU samples | Renderer startup/paint work consumes CPU. |
| 15 | Medium | `dartProgram` 77–84ms samples | Dart bootstrap/dispatch appears in CPU profile. |
| 16 | Medium | `(program)` 619–781ms samples | Browser main-thread program work dominates profiles. |
| 17 | Medium | `getParameter`/`getProgramParameter`/`getExtension` 45–72ms | WebGL/CanvasKit capability setup costs CPU. |
| 18 | Medium | 10–12ms style recalculation per route | Style work is small alone but repeated during route boot. |
| 19 | Medium | 29–31 resources per route | Route reloads pull substantial shared asset/resource sets. |
| 20 | Medium | 1 loading failure per inventory/sales capture | Asset/request reliability is not clean; inspect failed URLs. |

# FPS, Main Thread, Rendering, Paint, and Layout

## FPS and frame drops

- Passive one-second `requestAnimationFrame` sample: 62 frames, approximately 62 FPS.
- Passive route settling recorded no >50ms frame gaps.
- The real click changed the result: three >50ms gaps, maximum 316.6ms.
- Conclusion: the app can idle smoothly but drops frames during interaction/bootstrap.

## Main thread and JavaScript

- Route cumulative `ScriptDuration`: 2.373–4.372s.
- Route cumulative `TaskDuration`: 2.961–5.219s.
- CPU profiles show `(program)` as the largest bucket, followed by CanvasKit and Dart
  dispatch/initialization.
- Long tasks, not layout duration, explain the observed freeze.

## Rendering, paint, and layout

- CDP exposed layout and style-recalculation metrics, not a standalone paint-duration
  counter in this target.
- Layout duration stayed 1.549–2.179ms per route snapshot.
- Recalc-style duration stayed 10.381–12.228ms.
- Short trace returned no extracted Layout/Paint slice above 5ms.
- CanvasKit CPU samples and the interaction frame gap indicate renderer/main-thread work
  remains significant even when CSS layout numbers look small.

# Memory and Garbage Collection

| Profile | JS heap | GC self-time in CPU profile |
|---|---:|---:|
| Home | 122.9MB | 116ms |
| Inventory Adjustments | 115.3MB | 76ms |
| Sales Invoices | 81.7MB | 53ms |

Heap did not grow monotonically in this shorter pass; Sales ended lower after collection.
That is a useful negative result, not a leak clearance. Earlier navigation testing showed
growth up to approximately 278MB before collection. A repeated ten-route loop with forced
GC and heap snapshots is still required.

# Network Waterfall

Combined API request counts from the profiled route captures:

| Endpoint | Count |
|---|---:|
| `/api/v1/lookups/org/{orgId}` | 9 |
| `/api/v1/auth/profile` | 6 |
| `/api/v1/branches` | 6 |
| `/api/v1/sales/invoices` | 4 |
| `/api/v1/reports/dashboard-summary` | 3 |
| `/api/v1/inventory-adjustments` | 2 |
| `/api/v1/products/lookups/warehouses` | 2 |

Slowest observed request timings:

- Dashboard summary: 3,295ms.
- Sales invoices: 2,742ms.
- Organization lookup: 1,956ms, 1,833ms, 1,708ms, 1,467ms, 1,448ms, 1,305ms.
- Sales invoices: another 1,200ms response.
- Inventory adjustments: 1,196ms.
- Auth profile: 1,179ms.
- Branch lookups: up to 1,037ms.

204 preflight and 200 actual pairs were observed in the session. Response bytes were not
captured, so payload-size conclusions remain open.

# Web Vitals and Interactivity

- LCP: 756ms home, 824ms inventory, 768ms sales — good for these desktop captures.
- FCP: 704ms home, 792ms inventory, 736ms sales.
- CLS: 0 for all profiled route loads.
- INP-like interaction: 336ms pointerup after real click — needs optimization.
- TTI: not directly available from this CDP surface; route load and long-task evidence show
  that document readiness is not equivalent to application readiness.
- TBT-style signal: long-task totals were 786–927ms on route loads and 1,522ms after the
  tested click. These are not Lighthouse TBT because the capture windows differ.

# Console, Warnings, and Browser Errors

Home reload after enabling `Log` captured 36 events:

- `net::ERR_BLOCKED_BY_CLIENT` for `https://www.clarity.ms/tag/w7bva8014n`.
- Apollo warnings for `uri`, `credentials`, and `headers`, plus Apollo code 17. These are
  likely React DevTools extension noise and should be rechecked in a clean profile.
- Service-worker/PWA logs: existing service worker, install prompt captured, first frame
  rendered.
- Many IndexedDB/object-store initialization logs (`products`, `customers`, `bills`,
  `stock_transactions`, `accountant`, `local_drafts`, and others). This is noisy and may
  obscure real errors.
- No confirmed Dart exception or application 401/429/500 appeared in the captured log set.

# What This Profile Does Not Prove

- It does not isolate backend SQL time from browser queueing/network time.
- It does not prove a memory leak; heap snapshots after forced GC are required.
- It does not provide a valid LCP/INP population for every route or role.
- It does not measure production devices with slow CPU/network throttling.
- It does not cover tablet/mobile in this profiling pass; the earlier live audit already
  documented severe 390px/768px layout failure.

# Priority Measurement Follow-Up

1. Repeat the same profiles in a clean Chrome profile with extensions disabled.
2. Capture a 10-route loop with heap snapshots after forced GC.
3. Add server timing/request IDs to correlate the 3.295s dashboard and 2.742s invoice
   requests with backend query plans.
4. Run a full Performance panel trace around invoice-create, account dropdown, date picker,
   table filtering, and rapid navigation.
5. Repeat at 4G/CPU 4× throttling and 390/768/1024px viewports.

No source code or production data was modified during this performance audit.
