# Zerpai Observability Validation Report

Validation date: 2026-07-16 (Asia/Calcutta)

Scope: local Flutter Web + NestJS runtime, telemetry enabled and disabled
startup paths, authenticated browser smoke checks. No business data was
created or changed.

## Executive Summary

Result: **PARTIAL PASS**.

- Enabled startup: PASS after one observability defect was fixed.
- Backend compile/startup/health: PASS.
- Authenticated browser login: PASS with the enabled build.
- Core route smoke checks: PASS (home, inventory adjustments, sales invoices,
  manual journals list/create).
- Frontend telemetry emission: PASS; real API, provider, navigation, frame,
  long-task, and resource events were observed.
- Backend telemetry: PASS; HTTP and database events plus correlation IDs were
  observed in the NestJS terminal.
- Browser errors after the enabled smoke run: none from the application tab.
- Telemetry-off compilation/startup: PASS. Full off-mode login/regression
  replay: NOT COMPLETED because the browser-control session became unstable
  while the fresh off-mode tab was being driven. No pass is claimed for that
  portion.

## Startup Verification

### Frontend enabled

Command:

```text
flutter run -d chrome --web-port 53431
  --dart-define=ENABLE_PERFORMANCE_MONITORING=true
  --dart-define=PERFORMANCE_MONITORING_MODE=development
```

PASS. Flutter compiled and connected to Chrome. Boot output included Hive
initialization, environment loading, Supabase initialization, and the first
frame trigger.

Initial defect found during this run:

```text
RangeError: max must be in range 0 < max ≤ 2^32, was 0
```

Cause: web compilation of `1 << 32` produced zero for `Random.nextInt`.
Fix: `lib/core/observability/performance_telemetry.dart:269` now uses
`0x7fffffff`, preserving random correlation IDs without changing business
logic. `dart analyze lib/core/observability/performance_telemetry.dart` passes.

The application was restarted after the fix; the RangeError did not recur.

### Backend enabled

Command:

```text
$env:ENABLE_PERFORMANCE_MONITORING='true'
$env:PERFORMANCE_MONITORING_MODE='development'
npm.cmd run start:dev
```

PASS. Nest compilation reported `Found 0 errors`; the application started and
health returned HTTP 200 with database and Redis connected. Health response
also returned `X-Request-ID: 816eb42c-34c4-48f5-ac03-19dbf2d972ff`.

### Telemetry-off startup

Both processes were restarted with `ENABLE_PERFORMANCE_MONITORING=false`.
Nest compiled with zero errors and Flutter compiled/served successfully. A
fresh tab reached `/login`. Full authenticated replay is marked NOT TESTED
because the browser driver timed out during the off-mode form interaction.

## Login Verification

Enabled build: PASS.

Credentials were entered through the browser UI. The application navigated to
`/60000000000/home`. Browser telemetry recorded:

- `POST /api/v1/auth/login`, status `201`, duration `1579 ms`;
- request size `67` bytes, response size `1680` bytes;
- provider state transition `AuthLoading` → `Authenticated`;
- route transitions `/login` → `/home`.

Telemetry-off login: NOT TESTED to completion; no result is inferred.

## Frontend Observability Verification

| Feature | Result | Evidence |
|---|---|---|
| Feature flag initialization | PASS | Enabled build emitted telemetry; off build compiled without telemetry wiring claimed as active. |
| Correlation IDs | PASS | Events carried IDs such as `hkfvgn5c3s-8a59cu` and `hkfvimli3k-7c1tul`. |
| API duration/size/status | PASS | Login, dashboard, branches, and lookup `api_request` events. |
| Navigator observer | PASS | `route_push` events for `/login` and `/home`. |
| Riverpod observer | PASS | `provider_update` and `provider_add` events. |
| Scheduler/frame timings | PASS | `frame` events included duration, build, raster, dropped, long-frame. |
| Dropped/long-frame detection | PASS | Example: `duration_ms:1070.3`, `build_ms:1052.3`, `dropped:true`. |
| PerformanceObserver resources | PASS | Auth resource duration `1549.1 ms`; dashboard resource `2474.2 ms`. |
| Long-task observer | PASS | Browser long-task event `1074 ms`. |
| Navigation/resource observers | PASS | Resource and navigation debug callbacks were visible. |
| Search/filter/sort/table/dialog/dropdown/date-picker custom spans | NOT TESTED | No dedicated UI action was completed for every instrumented span. |
| JSON/CSV export | NOT TESTED | Authenticated export response was not obtained from the browser session. |

Representative telemetry samples were printed in development mode with the
`[telemetry]` prefix. No telemetry exception appeared after the correlation-ID
fix.

## Backend Observability Verification

| Feature | Result | Evidence |
|---|---|---|
| Observability middleware | PASS | `http_request` events in Nest terminal. |
| Correlation/request IDs | PASS | Health response `X-Request-ID`; log correlation IDs matched request events. |
| Route/controller/handler timing | PASS | `HealthController.checkHealth`, `AccountantController.findAll` fields. |
| Request/response metadata | PASS | Method, path, status, request/response byte fields present. |
| Database timing | PASS | `database_query` event with `durationMs:9680.8357`, fingerprint, rows, error. |
| Slow query visibility | PASS | Slow startup/backfill query was visible in telemetry logs. |
| JSON export endpoint routing | PASS | `GET /api/v1/telemetry/export` mapped at startup. |
| Authenticated JSON/CSV export body | NOT TESTED | Direct unauthenticated probe correctly returned HTTP 401. |
| Disabled-mode emission | PASS (process evidence) | Backend false process started without `[telemetry]` startup/query lines. |

Unauthenticated export probe result was expected access control, not a defect:
HTTP 401 `Missing authorization header`.

## Browser Verification

Enabled authenticated tab:

- Dashboard rendered with KPI cards and quick actions.
- Manual Journal create rendered with account table, dropdown, currency field,
  and date control.
- Account dropdown opened successfully.
- Date control opened/closed without a Flutter exception.
- Route refresh/direct navigation recovered to the requested route.

Application-tab `clean.dev.logs({levels:["error"]})` and warning collection
returned empty after the enabled smoke flow.

An external Clarity script error was observed in a separate tab:
`TypeError: Cannot read properties of null (reading 'sequence')`. This came
from `scripts.clarity.ms`, not Zerpai application code or telemetry code.

## Console and Runtime Exceptions

Fixed defect:

- Severity: High during enabled startup.
- Reproduction: start Flutter with monitoring enabled; provider/browser
  telemetry callback runs.
- Root cause: `Random.nextInt(1 << 32)` becomes `nextInt(0)` on web.
- Resolution: bounded maximum changed to `0x7fffffff`.
- Verification: targeted Dart analysis passed; enabled restart/login/routes
  completed without recurrence.

Non-blocking external warning:

- Flutter/Chrome reported missing Noto glyph coverage for some characters in
  the development browser. This is unrelated to observability and was not
  changed in this validation.

## Network Observations

Measured enabled requests included dashboard summary (`2485 ms`, `1084` bytes),
branches (`892 ms`, `14616` bytes), and organization lookups (`1138 ms`,
`3301` bytes). These are application timings observed during local validation,
not production SLAs.

## Performance Comparison

No Chrome Performance trace or heap snapshot was captured; therefore FPS,
memory, CPU, LCP, INP, CLS, TTI, and telemetry overhead percentages are not
claimed.

Boot sub-measurements available from Flutter logs:

| Subsystem | Enabled run | Off run | Note |
|---|---:|---:|---|
| Hive init | 4 ms | 8 ms | Different cold/cache state; not a controlled benchmark. |
| Config box open | 48 ms | 67 ms | Different cache state. |
| Core boxes open | 146 ms | 139 ms | Comparable only directionally. |
| Environment load | 1 ms | 1 ms | Same local asset path. |

Conclusion: telemetry overhead cannot be estimated from this run; a controlled
repeatable benchmark with fresh tabs, identical cache state, and a DevTools
trace is required.

## Regression Testing

PASS for enabled smoke scope: authentication, route loading, direct refresh,
dashboard rendering, accountant form rendering, account dropdown opening, and
date control interaction.

NOT TESTED: CRUD submission, reports export, print, logout/session expiry,
every permission role, every module, authenticated telemetry export, and the
complete telemetry-off replay.

## Release Decision

Do not label observability validation fully complete yet. The enabled path is
usable after the correlation-ID fix. Before release, rerun a controlled
telemetry-off browser session and authenticated JSON/CSV export checks, then
capture a DevTools trace for overhead numbers.
