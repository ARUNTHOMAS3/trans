# Zerpai ERP Live Production QA, UX, and Performance Audit

Date: 2026-07-16  
Environment: `https://zerpai.pages.dev` production web application  
Client: Chrome, authenticated user session  
Frontend: Flutter Web using CanvasKit  
Audit mode: direct browser interaction, screenshots, CDP performance/network/log observation

## Scope and evidence boundary

This audit used the already authenticated production browser session and real pointer
interactions. It did not modify application data or source code. It covered the home
screen, representative Sales, Purchases, Inventory, Items, and Reports routes, route
refreshes, date-picker interaction, account-dropdown interaction, desktop/tablet/mobile
viewport checks, repeated navigation, and browser-side network/log observation.

The session exposed one authenticated role only. No alternate Administrator, Staff,
Inventory Manager, Sales User, Purchase User, Accountant, or Warehouse Staff credentials
were available, so role-specific authorization and workflows remain unverified. No
record was saved, deleted, exported, printed, or published during this audit.

The scores below are observational release-risk scores for this session, not a statistical
benchmark. Heap values are signals collected during navigation, not proof of a leak. The
companion source audit is `PERFORMANCE_AUDIT_REPORT_2026-07-16.md`.

# Executive Summary

| Measure | Score | Assessment |
|---|---:|---|
| Overall health | 48/100 | Desktop core screens load, but responsive failure is release-blocking. |
| Performance | 45/100 | Tested route transitions were 1.9–2.9s with duplicate bootstrap calls. |
| UX | 35/100 | Tablet/mobile layouts are unusable; desktop tables are overly wide. |
| Stability | 60/100 | No application crash observed, but initialization stalls and browser errors occurred. |
| Responsiveness | 25/100 | 390px and 768px viewports squeeze the shell/content into a narrow strip. |
| Production readiness | 40/100 | Desktop-only use is possible; broad deployment should wait for responsive and request fixes. |

Observed release blockers:

1. 390px and 768px layouts are functionally unusable.
2. Inventory adjustment refresh can leave the whole form in an initialization overlay for
   roughly five seconds.
3. Repeated authentication, organization, lookup, and product requests occur during
   route changes and reloads.
4. Heap usage increased from about 104 MB to 278 MB during rapid route navigation; this
   requires a clean-profile heap investigation before production scaling.

# Critical Issues

## C1 — Critical: mobile and tablet layouts are unusable

**Page:** Inventory Adjustments create; Sales Invoices  
**Reproduction:** Set viewport to 390×844 or 768×1024, navigate to the route, wait for
loading to finish.  
**Observed:** The sidebar remains visible but collapses to a narrow strip; form/table
content is squeezed into roughly 100–300px on the left while most of the viewport is
blank. Labels, controls, and table text are clipped or unreadable.  
**Expected:** A responsive shell should collapse navigation, reflow forms, and provide a
usable horizontal table strategy.  
**Likely cause:** Desktop shell/content width assumptions are still applied below the
responsive breakpoint; no effective mobile navigation/content mode is activated.  
**Impact:** Users on tablets or narrow browser windows cannot complete normal ERP work.  
**Recommendation:** Treat as a release blocker. Verify shared shell breakpoints and the
responsive form/table foundation before screen-specific patches.

## C2 — Critical: refresh initialization blocks the adjustment form

**Page:** Inventory Adjustments → New Adjustment  
**Reproduction:** Open the create route, refresh the browser, and observe the first five
seconds.  
**Observed:** A full-page dimmed state with centered `Zerpai ERP / Initializing...`
remains visible for approximately five seconds before controls become usable. The first
navigation also showed content beginning below the page title, consistent with scroll or
layout restoration occurring during initialization.  
**Expected:** Route-level loading should be short, scoped, and preserve an immediately
understandable skeleton with no apparent frozen form.  
**Likely cause:** Several bootstrap/look-up/auth calls are awaited together before the
form becomes interactive.  
**Impact:** Users may retry clicks, abandon the form, or perceive a failed page.  
**Recommendation:** Separate shell readiness from form readiness, expose field-level
loading, and instrument each bootstrap request.

# High Priority Issues

## H1 — Repeated bootstrap/API requests

CDP network observation found repeated calls during rapid navigation and refreshes:

| Endpoint | Observed count |
|---|---:|
| `/api/v1/lookups/org/{orgId}` | 6 |
| `/api/v1/auth/profile` | 4 |
| `/api/v1/branches?org_id=...` | 4 |
| `/api/v1/products?limit=200` | 4 |
| `/api/v1/accountant` | 4 |
| `/api/v1/inventory-adjustments/reasons` | 4 |
| `/api/v1/products/lookups/warehouses` | 4 |
| `/api/v1/inventory-adjustments` | 2 |
| `/api/v1/purchase-orders` | 2 |

Several requests appeared as a 204 preflight followed by a 200 actual response. The
repeated actual calls are the performance concern; preflight traffic amplifies it.

**Impact:** Extra latency, server load, duplicated parsing, and avoidable UI rebuilds.  
**Recommendation:** Add request coalescing and route/session-scoped caching for stable
profile, organization, branch, warehouse, reason, and accountant metadata. Confirm that
reloads intentionally invalidate data rather than recreating providers.

## H2 — Memory growth signal during navigation

Observed `JSHeapUsedSize` values increased approximately as follows during the route
batch:

`104 MB → 184 MB → 222 MB → 278 MB`.

This happened while visiting Items Report, Sales Customers/Invoices/Orders, Purchases
Vendors/Bills/Purchase Orders, and Inventory Adjustments. It is not sufficient to prove a
leak because Flutter and browser garbage collection are nondeterministic, but the trend
is high enough to require heap snapshots after forced GC in a clean profile.

## H3 — Inventory Adjustments table is too wide and clipped

**Page:** Inventory Adjustments list  
**Observed:** The title begins against the shell boundary, and the table extends through
many long columns (reference, created/modified users and times). The right side is
off-screen at desktop width and is not discoverable as a responsive table interaction.  
**Impact:** Users cannot reliably compare rows or reach all actions.  
**Recommendation:** Use the shared responsive table shell, prioritize columns, provide a
clear horizontal-scroll affordance or responsive row view, and validate shell padding.

## H4 — Route rendering often exceeds the documented two-second target

Measured navigation-to-observation times after `goto` and a 1.2s settle window:

| Route | Observed time |
|---|---:|
| Items Report | 2.86s |
| Sales Customers | 2.71s |
| Sales Invoices | 2.13s |
| Sales Orders | 2.14s |
| Purchases Vendors | 2.12s |
| Purchases Bills | 1.92s |
| Purchase Orders | 2.17s |
| Inventory Adjustments | 1.97s |

These are browser-session observations, not cold-cache lab measurements. Still, five
routes exceeded two seconds before the first settled screenshot.

## H5 — Desktop form wastes large viewport area

The New Adjustment form uses a narrow left content region while a large blank/dark area
remains on the right at 1920px width. This makes the page feel unfinished and leaves
less room for the already-wide transactional grid.

# Medium Priority Issues

## M1 — Date picker desktop smoke test passed, global coverage incomplete

On New Adjustment at desktop size, the shared date picker opened below the field, showed
July 2026, accepted next-month navigation to August 2026, and displayed the selected day.
The previously reported global date-picker misalignment was not reproduced on this one
route/viewport. Other forms, zoom levels, and narrow widths remain untested.

## M2 — Account dropdown hierarchy smoke test passed

On New Adjustment, section headers such as `Expense` rendered without bullets while child
accounts such as `Job costing`, `Labor`, `Materials`, and `Subcontractor` rendered with
bullets. The selected `Cost of Goods Sold` row showed the expected active blue treatment
and check icon. This matches the requested hierarchy on the tested route; it does not
prove every account dropdown uses the same owner.

## M3 — Loading feedback is present but too coarse

Skeleton and initialization feedback exist, but the full-page initialization overlay
blocks all interaction for several seconds. Users receive no per-request explanation or
retry affordance.

## M4 — Dense transactional controls need narrow-width validation

Sticky bottom actions (`Save as Draft`, `Convert to Adjusted`, menu, `Cancel`) coexist
with a dense form/grid. At narrow widths, this composition is likely to compete for the
same constrained space and should be tested with keyboard focus and browser zoom.

# Low Priority Issues

## L1 — Extension-origin Apollo warnings

Repeated ApolloClient warnings came from a React DevTools extension URL, not the Zerpai
application bundle. They should not be counted as application defects, but a clean browser
profile should be used for release evidence.

## L2 — No direct 401, 429, or 500 response was observed

No such status appeared in the captured network events during the tested flows. This is a
positive observation, not proof that error handling is complete.

# Performance Bottlenecks (ranked)

1. **Responsive shell failure** — blocks all narrow-device work; highest business impact.
2. **Synchronous/aggregated route initialization** — approximately five seconds on a
   refreshed adjustment form.
3. **Duplicate profile and lookup requests** — repeated network, parsing, and provider
   invalidation cost.
4. **Unbounded or over-wide data tables** — expensive layout and poor interaction at
   desktop width; worse on tablet.
5. **Heap growth across route navigation** — possible retained providers/controllers,
   cached payloads, or delayed garbage collection.
6. **CanvasKit/font/asset startup cost** — production requests include `main.dart.js`,
   CanvasKit JavaScript/WASM, Inter font variants, symbol fonts, Lucide, FontAwesome, and
   Cupertino assets. Response bytes were not captured in this pass.
7. **Large lookup/product bootstrap payloads** — products requested with `limit=200` and
   multiple lookup families load on route entry.

# UX Improvements

- Make navigation responsive: collapse the sidebar at tablet/mobile breakpoints and keep
  a usable content width.
- Replace wide desktop-only grids with prioritized columns plus a responsive row/detail
  view.
- Keep form loading local to the form and allow shell navigation while metadata loads.
- Preserve title, scroll position, and action-bar placement consistently after refresh.
- Add explicit horizontal-scroll affordance where a grid must remain wide.
- Verify keyboard focus order, visible focus, escape-to-close behavior, and date-picker
  placement at 100%, 125%, and 200% browser zoom.
- Keep account section headings visually distinct from selectable child rows; retain the
  tested bullet hierarchy.

# Functional Bugs and Unverified Workflows

## Confirmed functional/usability defects

- Mobile/tablet route layout is unusable (C1).
- Adjustment refresh is blocked by a long full-page initialization state (C2).
- Inventory Adjustments list is clipped/over-wide (H3).

## Smoke-tested successfully

- Date picker opened and next-month navigation worked on New Adjustment desktop.
- Account dropdown search surface opened; section/child bullet hierarchy appeared correct.
- Core route navigation completed for the tested list pages without a blank-page crash.

## Not executed in this audit

No save, draft, publish, delete, export, print, logout, payment, invoice posting, stock
adjustment conversion, browser-back/deep-link recovery, offline retry, or alternate-role
authorization mutation was executed. These require a controlled test record policy and
role credentials. They must be included in the deployment test pass.

# Browser Errors

- One asynchronous listener error was observed while the app URL was active:
  `A listener indicated an asynchronous response by returning true, but the message
  channel closed before a response was received.` Attribution is uncertain and may be a
  browser extension rather than Zerpai; reproduce in a clean profile.
- One `net::ERR_BLOCKED_BY_CLIENT` loading failure was observed, consistent with an
  extension/ad-blocker interception. It is not evidence of a server failure until clean
  profile testing confirms it.

# Console Errors and Warnings

- Captured total: 53 warning/error entries across the session.
- Most were Apollo warnings from the React DevTools extension origin.
- No confirmed application Flutter exception, Dart stack trace, 401, 429, or 500 was
  observed during the exercised flows.
- The app-origin asynchronous listener error remains an attribution item for follow-up.

# Network Problems

- Repeated actual requests for stable session/lookup data were observed (H1).
- Preflight 204 plus actual 200 sequences amplify request count.
- Product lookup request used `limit=200`; payload byte size was not measured.
- Response sizes, server timing headers, and backend SQL timings were not available from
  this browser-only pass, so payload and database conclusions require a server trace.
- No direct 401/429/500 appeared in the captured events.

# Flutter Web Observations

- CanvasKit was active: `canvaskit.js` and `canvaskit.wasm` loaded.
- Flutter's canvas renderer limits ordinary DOM inspection; this audit therefore relied
  on screenshots, accessibility interaction, CDP performance, and network events.
- The narrow viewport failure is consistent with shell breakpoint/content-constraint
  failure rather than a single field-level widget defect.
- Initial loading skeletons and a full initialization overlay are visible, but the latter
  blocks useful work for several seconds.
- Desktop table density and wide grids are likely to increase layout/paint work as rows
  grow; row counts and frame traces were not available in this pass.

# Coverage Matrix

| Area | Coverage |
|---|---|
| Home | Visited and visually inspected |
| Items | Report route visited |
| Sales | Customers, Invoices, Orders visited |
| Purchases | Vendors, Bills, Purchase Orders visited |
| Inventory | Adjustments list and create visited; date/account controls exercised |
| Reports | Profit & Loss route opened; no mutation executed |
| Accountant | Route inventory known, not exercised in live session |
| Settings | Not exercised |
| Remaining Inventory/Procurement | Not fully exercised |
| CRUD/export/print/logout/offline | Not executed |
| Alternate roles | Inaccessible: no alternate credentials in active session |

The repository route inventory contains additional Accountant, Reports, Settings, Items,
Sales, Inventory, and Purchases screens. This live session cannot honestly claim every
route or role was tested; the untested surface is a deployment risk and should be audited
with a role matrix and seeded test records.

# Recommendations

## Quick wins (<30 minutes)

- Reproduce the 390px/768px failures in a clean browser profile and mark the affected
  breakpoints as release-blocking.
- Capture request IDs and timings for profile/org/lookups on one route refresh.
- Remove extension noise from evidence by repeating console/network capture in a clean
  profile.
- Add an explicit loading timeout/retry message to the adjustment initialization state.

## Medium improvements (1–4 hours)

- Coalesce/cache profile, organization, branch, warehouse, reason, and accountant lookup
  requests per authenticated session.
- Validate the shared shell's responsive breakpoints and shared responsive table/form
  primitives using 390, 768, 1024, and 1440px fixtures.
- Instrument route-start, first-content, interactive, and API-duration metrics.
- Add a focused heap-retention test: navigate the same ten routes repeatedly, force GC,
  and compare detached controllers/listeners/provider state.

## Major improvements (1–5 days)

- Refactor route bootstrap into independently loading feature data with request
  cancellation and deduplication.
- Replace wide tables with responsive row/detail patterns and server-side pagination where
  row counts justify it.
- Run a full role-based workflow suite covering create/edit/approve/post/delete/export/
  print and failure paths with seeded records.
- Capture production-like Chrome traces, payload sizes, server timings, and Flutter frame
  timelines before setting a release gate.

## Long-term architecture improvements

- Establish a shared session/lookup cache with explicit invalidation and tenant scoping.
- Add route-level performance budgets and CI smoke tests for responsive screenshots.
- Add browser observability for API waterfalls, long tasks, JS heap, route TTI, and failed
  assets, correlated with backend request IDs.
- Maintain a role × route × workflow test matrix and require clean-profile evidence before
  deployment to thousands of users.

# Final Audit Verdict

The production build is usable for a subset of desktop list navigation, and the tested
date-picker/account-dropdown controls behaved correctly on the New Adjustment desktop
route. It is not ready for broad multi-device deployment: responsive layout failure,
long initialization blocking, duplicate bootstrap traffic, wide-table clipping, and the
heap-growth signal require remediation and a second clean-profile, role-based audit.

No source code or production data was modified during this audit.
