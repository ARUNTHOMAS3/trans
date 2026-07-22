# Zerpai Production Release Validation — 2026-07-16

Target: `https://zerpai.pages.dev/login`  
Client: Chrome, authenticated production session, Flutter Web CanvasKit  
Method: direct pointer interaction, screenshots, CDP Network/Performance, browser logs  
Data safety: no record was created, edited, deleted, published, exported, or printed.

## Release Readiness

**FAIL for broad production release.** Desktop navigation and representative read-only
workflows worked, but a public `.env` deployment artifact and an unusable 390px
transaction form require remediation before releasing to all users.

## Executive Summary

| Area | Score | Evidence |
|---|---:|---|
| Overall health | 56/100 | Core desktop routes loaded; release blockers remain |
| Performance | 58/100 | Dashboard summary 2,366 ms; duplicate lookup traffic observed |
| UX | 52/100 | Desktop usable; account hierarchy and mobile form regressions observed |
| Stability | 78/100 | No Zerpai application errors in final browser-log sample |
| Responsiveness | 38/100 | Settings reflowed; manual journal form failed at 390px |
| Security | 30/100 | Public `.env` URL returned HTTP 200 |

## Critical Bugs

### C1 — Public production `.env` asset (Critical, security)

- Evidence: `GET https://zerpai.pages.dev/assets/assets/.env` returned HTTP 200,
  `application/octet-stream`, 526 bytes, and `Access-Control-Allow-Origin: *`.
- A keyword-only scan found no obvious `secret`, `password`, `private`, token, or API-key
  strings; values were not printed. Reachability itself is a deployment hygiene failure.
- Impact: future builds can publish credentials or tenant configuration accidentally.
- Recommendation: remove `.env` from the public artifact, move runtime configuration to
  non-secret public config, rotate any credential ever present in deployed revisions,
  and add a CI artifact deny-list.

### C2 — Manual Journal form unusable at 390px (Critical, responsive UX)

- Reproduction: set viewport to 390×844 and open
  `/60000000000/accountant/manual-journals/create`.
- Observed screenshot: form rendered as a tiny desktop-scale strip at the far left with
  most of the viewport blank; controls were not practically operable.
- The same session showed Settings reflowing correctly at 390px, proving this is a
  route/form responsive defect rather than a browser-wide viewport failure.
- Recommendation: fix the shared transaction-form breakpoint/layout owner, then rerun
  390/768/1024 screenshot gates.

## High Priority Bugs

### H1 — Dashboard bootstrap latency

CDP timings from a production home reload (actual 200 responses, excluding CORS
preflight 204s):

| Request | Duration | Encoded response |
|---|---:|---:|
| `/api/v1/auth/profile` | 1,209 ms | 500 bytes |
| `/api/v1/lookups/org/{org}` | 1,431 ms | 1,740 bytes |
| `/api/v1/reports/dashboard-summary` | 2,366 ms | 795 bytes |
| `/api/v1/branches` | 1,180 ms | 176 bytes |
| second org lookup | 1,077 ms | 1,717 bytes |

The dashboard eventually rendered KPI cards and an explicit empty chart state, but the
summary request is above a normal interactive target.

### H2 — Duplicate actual lookup request

The same home reload issued two actual 200 requests to the organization lookup endpoint
(1,431 ms and 1,077 ms). CORS preflight requests were also present. This creates
avoidable latency, parsing, provider invalidation, and backend load.

### H3 — Duplicate Sales Invoices fetch

On `/60000000000/sales/invoices`, CDP captured two actual 200 requests to
`/api/v1/sales/invoices` (encoded responses approximately 1,125 and 1,127 bytes).
Coalesce route/provider loads and verify cache invalidation ownership.

### H4 — Public request correlation is only partially observable

All sampled actual API requests carried `X-Request-ID` and tenant headers. Responses
carried a trace-related header, but no `X-Request-ID` response echo was observed. This
supports request-side correlation but makes browser-to-backend lookup harder. Add a
sanitized response correlation header or document the trace-header mapping.

## Medium Priority Bugs

### M1 — Account dropdown hierarchy regression

On the production Manual Journal form, the account popup opened and search worked, but
visible child rows (`Petty Cash`, `Undeposited Funds`, `Furniture and Equipment`,
`Advance Tax`) rendered without the requested bullets. Section labels (`Fixed Asset`,
`Other Current Asset`) were also visually similar to rows. Expected: bullets only on
selectable children, with category headers clearly distinct.

### M2 — Wide desktop tables need responsive affordance

Items, vendors, chart of accounts, and purchase-order tables loaded, but several columns
required a wide viewport/horizontal extent. No crash occurred; narrow transactional
views remain at risk until shared responsive table behavior is applied.

### M3 — Invalid deep link shows framework error page

An intentionally invalid `/60000000000/items` URL displayed `GoException: no routes for
location`. Correct sidebar routes worked. This is not counted as a data defect, but a
production-friendly not-found route would be preferable.

## Verified Production Workflows

Loaded successfully without a Zerpai application exception:

- Home/dashboard
- Items report
- Inventory Adjustments
- Sales Invoices list and create form
- Purchase Orders
- Vendors
- Expenses
- Accountant Manual Journals list and create form
- Reports Center and Profit & Loss
- Chart of Accounts
- Settings

Manual Journal account dropdown and shared date picker opened. The July 2026 calendar
displayed the selected day and month navigation. Invoice customer dropdown also opened
with search and New Customer action. No save/publish action was invoked.

## Browser Findings

- Final `prod.dev.logs` sample: 0 error entries, 0 warning entries.
- Earlier session warnings were attributable to browser extensions/service-worker setup;
  one `net::ERR_BLOCKED_BY_CLIENT` script failure was observed and is not confirmed as
  Zerpai-origin.
- CDP Performance sample after dashboard settle: JS heap used 140,855,072 bytes
  (~134.3 MiB), heap total 191,606,784 bytes (~182.6 MiB), 259 nodes, 339 listeners,
  script duration 0.149 ms, task duration 0.832 ms, layout/recalc samples 0.
- This is a point sample, not a leak determination. No clean-profile forced-GC series
  was captured.

## Network Findings

- Home reload produced 126 captured CDP events, including expected CORS preflight 204s.
- Actual sampled API responses were 200; no 401/429/500 was observed in exercised flows.
- One client-blocked script event occurred; attribution requires a clean browser profile.
- Public `.env` request is the highest network/security finding.

## Observability Validation

| Feature | Result | Evidence / boundary |
|---|---|---|
| Request ID on frontend API request | PASS | `X-Request-ID` present on actual API requests |
| Tenant correlation headers | PASS | Present on sampled actual requests |
| Response trace header | PASS | Trace-related response header observed |
| Response `X-Request-ID` echo | NOT OBSERVED | No echo in sampled responses |
| API duration/response size | PASS | CDP request/response/finished timings and bytes |
| Route/provider/frame telemetry | NOT TESTED | Production console telemetry is suppressed/not visible |
| PerformanceObserver/long-task/LCP/CLS/INP | NOT TESTED | Page evaluation surface did not expose entries |
| Backend/controller/database telemetry | NOT TESTED | No backend console/export access in this browser session |
| JSON/CSV telemetry export | NOT TESTED | No authenticated export UI exercised |
| Feature-flag off comparison | NOT TESTED | Production flag state not exposed in UI |

## Responsive Findings

Settings page visual checks passed at 390, 768, 1024, 1366, 1440, and 1920px. Measured
document/body width equaled viewport width at each size (no global horizontal overflow).
The Manual Journal create route nevertheless failed at 390px as C2. Route-specific
responsive screenshot coverage is therefore mandatory; global width equality is not a
pass for every screen.

## Security Findings

- Authenticated navigation to `/login` redirected to `/60000000000/home`, confirming
  session persistence for this session.
- Profile menu exposed expected account/role controls and a Sign Out action; sign-out,
  expiry, unauthorized access, and clean-session protected-route checks were **NOT
  TESTED** to avoid destroying the only authorized session.
- Public `.env` artifact remains a release blocker.

## Regression Findings

Read-only navigation, list rendering, empty states, dropdown opening, date-picker opening,
refresh recovery, reports, and settings remained functional. No source code or business
data was changed during validation. CRUD, approvals, posting, payment, export/print,
offline recovery, alternate roles, and ten-minute idle retention are **NOT TESTED**.

## Final Recommendation

**NO — do not release this build to all users yet.**

Release can be reconsidered after removing/rotating the public `.env` artifact, fixing the
390px transaction-form layout, deduplicating bootstrap/API loads, and rerunning a clean
profile role/workflow audit with authenticated observability export evidence.
