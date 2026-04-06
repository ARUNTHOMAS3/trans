# Testing Results

## Purpose

This file records the test work completed in this session for the current repo state.

It covers:
- test modules added in this session
- commands run
- pass/fail status
- bugs discovered by the test pass
- fixes applied during the test pass
- remaining blockers

---

## 1. New Test Modules Added

### Backend

- [reports.controller.spec.ts](/e:/zerpai-new/backend/src/modules/reports/reports.controller.spec.ts)
  - verifies audit-log query parsing and normalization in `ReportsController`
  - covers:
    - page/pageSize parsing
    - comma-separated table parsing
    - comma-separated action parsing
    - invalid numeric input fallback

- [reports.service.spec.ts](/e:/zerpai-new/backend/src/modules/reports/reports.service.spec.ts)
  - verifies `ReportsService.getAuditLogs(...)`
  - covers:
    - page/pageSize clamping
    - recent vs archived scope behavior
    - query builder filter application
    - summary count generation from visible rows
    - search clause construction

### Flutter

- [reports_repository_test.dart](/e:/zerpai-new/test/modules/reports/repositories/reports_repository_test.dart)
  - verifies `ReportsRepository.getAuditLogs(...)`
  - covers:
    - query parameter forwarding
    - omission of blank optional values

### E2E

- [audit.spec.ts](/e:/zerpai-new/tests/e2e/audit.spec.ts)
  - adds smoke coverage for the new `/audit-logs` route
  - intended to verify:
    - route loads
    - `Audit Logs` heading is visible
    - `Activity Explorer` is visible
    - `All Logs` scope card is visible
    - `Entry Inspector` section is visible

---

## 2. Real Bug Found During Testing

### Bug

The new backend audit search code in [reports.service.ts](/e:/zerpai-new/backend/src/modules/reports/reports.service.ts) was building the Supabase `or(...)` search clause with literal strings like:

- `table_name.ilike.%${term}%`

instead of interpolating the actual value of `term`.

### Impact

Search on the audit endpoint would not have behaved correctly for free-text filtering.

### Fix Applied

Changed the search clause entries from quoted literals to template strings.

### Verification

The failing backend unit test passed immediately after the fix, and the backend build remained green.

---

## 3. Commands Run

### Targeted pre-flight runs

1. Backend targeted audit tests

```powershell
npm test --prefix backend -- reports.controller.spec.ts reports.service.spec.ts --runInBand
```

2. Flutter targeted audit repository test

```powershell
flutter test test/modules/reports/repositories/reports_repository_test.dart
```

3. Backend build after the bug fix

```powershell
npm run build --prefix backend
```

### Full suite runs

4. Full Flutter tests

```powershell
npm run test:flutter
```

5. Full backend tests

```powershell
npm run test:backend
```

6. Full Playwright suite

```powershell
npm run test:e2e
```

7. Playwright rerun with captured output

```powershell
cmd /c "npm run test:e2e > e2e_test_output.log 2>&1"
```

---

## 4. Results Summary

### Flutter

Status:
- passed

Command:
- `npm run test:flutter`

Observed result:
- `8` tests passed
- `0` failed

Covered files:
- [error_handler_test.dart](/e:/zerpai-new/test/core/utils/error_handler_test.dart)
- [manual_journal_model_test.dart](/e:/zerpai-new/test/modules/accountant/manual_journals/models/manual_journal_model_test.dart)
- [reports_repository_test.dart](/e:/zerpai-new/test/modules/reports/repositories/reports_repository_test.dart)

### Backend

Status:
- passed

Command:
- `npm run test:backend`

Observed result:
- `4` test suites passed
- `9` tests passed
- `0` failed

Passing suites:
- [reports.service.spec.ts](/e:/zerpai-new/backend/src/modules/reports/reports.service.spec.ts)
- [standard_response.interceptor.spec.ts](/e:/zerpai-new/backend/src/common/interceptors/standard_response.interceptor.spec.ts)
- [reports.controller.spec.ts](/e:/zerpai-new/backend/src/modules/reports/reports.controller.spec.ts)
- [health.controller.spec.ts](/e:/zerpai-new/backend/src/modules/health/health.controller.spec.ts)

### Backend build

Status:
- passed

Command:
- `npm run build --prefix backend`

Observed result:
- Nest build completed successfully

### Playwright E2E

Status:
- failed

Command:
- `npm run test:e2e`

Observed result from [e2e_test_output.log](/e:/zerpai-new/e2e_test_output.log):
- `13` tests discovered
- `11` failed
- `2` skipped
- all recorded failures were `page.goto: net::ERR_CONNECTION_REFUSED`

Skipped tests:
- item edit/detail E2E tests that depend on `PW_ITEM_ID`

Failure pattern:
- every failing test attempted to load `http://localhost:3000/?enable-accessibility=true#...`
- the browser never reached the app shell
- failures happened before any route assertion logic could run

So the current E2E failure is:
- not an assertion-level route bug
- not a selector mismatch
- not an audit-screen-specific runtime failure

It is currently a local web-server/bootstrap failure for the Playwright target URL.

---

## 5. E2E Failure Details

### Primary blocker

All failing Playwright tests show:

- `net::ERR_CONNECTION_REFUSED`
- target:
  - `http://localhost:3000`

### What that means

Playwright attempted to open the Flutter web app but nothing was listening on the configured base URL/port when the tests ran.

### Affected suites

- [accountant.spec.ts](/e:/zerpai-new/tests/e2e/accountant.spec.ts)
- [audit.spec.ts](/e:/zerpai-new/tests/e2e/audit.spec.ts)
- [home.spec.ts](/e:/zerpai-new/tests/e2e/home.spec.ts)
- [items.spec.ts](/e:/zerpai-new/tests/e2e/items.spec.ts)

### Captured artifacts

Failure screenshots were generated under [test-results](/e:/zerpai-new/test-results).

Examples:
- [test-failed-1.png](/e:/zerpai-new/test-results/audit-Audit-Logs-should-load-the-audit-logs-workspace-shell-chromium/test-failed-1.png)
- [test-failed-1.png](/e:/zerpai-new/test-results/home-Home-Page-should-load-the-home-dashboard-chromium/test-failed-1.png)

### Most likely next checks

1. Verify Playwright `webServer` is actually able to start and bind on `localhost:3000`
2. Verify no local process/policy is blocking that port
3. If needed, run with an explicit base URL:

```powershell
$env:PLAYWRIGHT_BASE_URL = 'http://localhost:53431'
npm run test:e2e
```

and keep Flutter running separately on that exact port

---

## 6. Full Pass/Fail Matrix

### Passed

- Flutter unit tests
- Backend unit tests
- Backend build
- New audit repository test
- New audit controller test
- New audit service test

### Failed

- Full Playwright E2E run

### Notable distinction

The failed E2E run does **not** currently prove a functional bug in:
- the audit page
- accountant screens
- home screen
- items screens

It proves that the test browser could not connect to the app server on the configured URL.

---

## 7. Files Produced During Testing

- [TESTING_RESULTS_2026-03-17.md](/e:/zerpai-new/TESTING_RESULTS_2026-03-17.md)
- [e2e_test_output.log](/e:/zerpai-new/e2e_test_output.log)
- [playwright-report](/e:/zerpai-new/playwright-report)
- [test-results](/e:/zerpai-new/test-results)

---

## 8. Current Test Readiness Assessment

### Backend

Ready from a unit/build perspective:
- yes

### Flutter

Ready from a unit-test perspective:
- yes

### E2E

Ready from a stable execution perspective:
- not yet

Current blocker:
- Playwright target app URL is not reachable during the run

---

## 9. Recommended Next Step

The next highest-value testing step is not to add more assertions yet.

It is to make the E2E app boot path stable first:
- either fix Playwright `webServer` startup on `localhost:3000`
- or standardize on a manually started Flutter instance with `PLAYWRIGHT_BASE_URL`

After that, rerun:

```powershell
npm run test:e2e
```

and only treat any remaining failures as route/UI defects after connection is working.
