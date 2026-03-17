# Audit Logs Implementation Report

## Scope

This report documents the full audit-system and audit-page implementation completed in this phase of work.

It covers:
- the database-backed central audit model
- backend cleanup to avoid double-logging
- the new backend reporting endpoint for audit logs
- frontend routing and sidebar integration
- the new Audit Logs page UI
- verification completed on both Flutter and backend

This file is intended to be a standalone implementation handoff and review document.

## Why This Change Was Made

The project needed a single reliable audit/history system that:
- captures inserts, updates, deletes, and truncates
- works across the current schema, not just one module
- remains compatible with the current auth-free development setup
- keeps historical logs visible even after archival
- supports a proper UI page for browsing and inspecting changes across modules

The earlier app-layer interceptor approach was not the right long-term source of truth once database-trigger auditing was introduced. That would have caused duplicate logging and weaker consistency.

So the implementation direction chosen was:
- central DB-trigger audit logging
- one audit view for both recent and archived history
- one backend endpoint to expose audit records to the frontend
- one dedicated audit page in the app

## Final Architecture

### Audit data source

The audit system now relies on the database as the source of truth.

Core concepts:
- `audit_logs`
  - hot/current log table
- `audit_logs_archive`
  - archived historical rows
- `audit_logs_all`
  - combined view over both tables

The UI and backend reporting path are designed around `audit_logs_all`, so archived logs remain visible in the audit page.

### Audit behavior

The intended behavior is:
- new saves are logged
- updates are logged
- deletes are logged
- truncates are logged
- old logs are archived monthly
- archived logs remain queryable and visible

### Auth-free compatibility

Because auth is not implemented yet, the audit design stays auth-ready without depending on auth tables.

Fallback actor behavior:
- `user_id` falls back to zero UUID
- `actor_name` falls back to `system`

This preserves audit continuity during the current development phase.

## Database Rollout Summary

The database audit rollout was handled outside the repo code changes, but it is a required dependency for the page and backend API to be meaningful.

The DB rollout includes:
- trigger-based row auditing
- truncate auditing
- append-only protection on audit tables
- archive support
- monthly archive scheduling
- automatic trigger attachment for future `public` tables

### Important Postgres fix

During the rollout, the event trigger function had to be corrected because this Postgres environment does not expose `object_name` in `pg_event_trigger_ddl_commands()`.

The fix was:
- parse table identity from `object_identity`
- recreate the event trigger using the corrected function

### Expected DB state after rollout

At the end of the DB rollout:
- current `public` tables should have row audit triggers
- current `public` tables should have truncate audit triggers
- `pg_cron` should have the monthly archive schedule active

### Archive behavior

Archive does not mean permanent deletion from the overall system.

The implemented behavior is:
- older rows are moved out of `audit_logs`
- those rows are inserted into `audit_logs_archive`
- the combined view `audit_logs_all` exposes both

So:
- yesterday's logs remain visible
- two-year-old logs remain visible
- the audit page should query the combined view-backed API only

## Backend Changes

## 1. Removed old interceptor-based audit wiring

### File changed
- [backend/src/app.module.ts](/e:/zerpai-new/backend/src/app.module.ts)

### What changed

Removed:
- `APP_INTERCEPTOR`
- `AuditInterceptor` import
- `AuditInterceptor` provider binding

### Why

The DB-trigger audit system is now the audit source of truth.

Keeping the old interceptor would create:
- duplicate log creation
- confusion about which audit layer is authoritative

### Result

The backend no longer attempts to create application-layer audit rows in parallel with the database-trigger system.

## 2. Added backend audit-logs reporting endpoint

### Files changed
- [backend/src/modules/reports/reports.controller.ts](/e:/zerpai-new/backend/src/modules/reports/reports.controller.ts)
- [backend/src/modules/reports/reports.service.ts](/e:/zerpai-new/backend/src/modules/reports/reports.service.ts)

### Endpoint added

- `GET /reports/audit-logs`

### Controller responsibilities

The controller now:
- accepts query parameters
- parses pagination values
- parses comma-separated tables
- parses comma-separated actions
- forwards normalized input to the reports service

### Supported query parameters

- `page`
- `pageSize`
- `search`
- `tables`
- `actions`
- `requestId`
- `source`
- `orgId`
- `outletId`
- `fromDate`
- `toDate`
- `scope`

### Service responsibilities

The reports service now:
- reads from `audit_logs_all`
- applies optional filters
- applies pagination
- orders newest-first by `created_at`
- returns rows plus a summary block

### Filtering supported in service

- org filter
- outlet filter
- request id filter
- source filter
- action filter
- table filter
- start date filter
- end date filter
- scope filter:
  - `recent`
  - `archived`
  - all
- free-text search across fields such as:
  - `table_name`
  - `record_pk`
  - `actor_name`
  - `module_name`
  - `request_id`
  - `source`
  - `action`

### Returned summary values

The response includes a summary block containing:
- `insertCount`
- `updateCount`
- `deleteCount`
- `truncateCount`
- `archivedCount`
- `visibleItems`

### Important correction during backend implementation

The first draft of this endpoint included accidental Dart-style syntax in the TypeScript controller/service.

This was corrected before final verification.

Examples of fixes made:
- replaced Dart parsing with TypeScript parsing
- replaced Dart list filtering calls with JS/TS array filtering
- replaced Dart `final`/`List<...>` patterns with proper TypeScript

That correction was necessary to make the backend compile cleanly.

## Frontend Changes

## 1. Route added for Audit Logs page

### Files changed
- [lib/core/routing/app_routes.dart](/e:/zerpai-new/lib/core/routing/app_routes.dart)
- [lib/core/routing/app_router.dart](/e:/zerpai-new/lib/core/routing/app_router.dart)

### What changed

Added a new route constant:
- `/audit-logs`

Added route wiring in GoRouter:
- the app can now navigate to `AuditLogsScreen`

### Result

The Audit Logs page now exists as a first-class top-level route.

## 2. Sidebar integration

### File changed
- [lib/core/layout/zerpai_sidebar.dart](/e:/zerpai-new/lib/core/layout/zerpai_sidebar.dart)

### What changed

Added:
- `Audit Logs` leaf item in the sidebar
- history icon mapping
- route matching so the item highlights when the audit page is active

### Placement

The sidebar entry was added after:
- `Documents`

This matches the requested placement.

## 3. Frontend repository support

### File changed
- [lib/modules/reports/repositories/reports_repository.dart](/e:/zerpai-new/lib/modules/reports/repositories/reports_repository.dart)

### What changed

Added:
- `getAuditLogs(...)`

This repository method:
- calls `reports/audit-logs`
- passes page, page size, filters, and scope
- returns the backend response payload for the audit screen

### Why

The new page needed a clean repository abstraction rather than directly coupling screen logic to raw API calls.

## 4. New Audit Logs page implementation

### File added
- [lib/modules/reports/presentation/reports_audit_logs_screen.dart](/e:/zerpai-new/lib/modules/reports/presentation/reports_audit_logs_screen.dart)

### Design goal

The page was designed to:
- fit the existing Zerpai layout and theme
- feel integrated with the current app rather than like an external admin console
- handle both broad audit browsing and detail inspection

### Overall layout

The page uses a 3-part layout:

1. Left explorer panel
- acts as a visual navigation/filter rail
- includes scope cards
- includes nested module/submodule structure

2. Main audit table
- shows paginated audit entries
- supports search and filter controls
- supports action and scope filtering

3. Right inspector panel
- shows metadata for the selected row
- shows changed columns
- shows old values JSON
- shows new values JSON

### Left panel behavior

The left panel includes:
- hero-style header
- scope cards:
  - `All Logs`
  - `Recent`
  - `Archived`
- nested module/submodule explorer

The nested tree was built as a table-mapping filter structure, not just a static menu.

### Module mapping included

The current tree covers:
- System
- Items
- Inventory
- Sales
- Purchases
- Accountant
- Tax and Compliance

Each node maps to one or more database tables so filtering is real.

Examples:
- Manual Journals maps to manual journal audit tables
- Price Lists maps to price-list related tables
- Vendors maps to vendor tables
- Accounts maps to accounts and account transactions

### Main table behavior

The main table shows:
- time
- module
- section
- action
- actor
- request id
- scope

Action rows are styled with different badges so the page is easier to scan visually.

### Inspector behavior

When a row is selected, the right panel shows:
- module
- section
- table
- actor
- record
- source
- request id
- created timestamp
- changed columns
- old values
- new values

### Data behavior

The page supports:
- full search
- request ID filtering
- source filtering
- module/submodule filtering
- action filtering
- date range filtering
- scope filtering
- server-side pagination

### Important behavior tied to the archive system

The page does not treat archives as a separate dead area.

Instead:
- recent and archived rows are both supported in one experience
- scope cards let the user switch between them
- all data remains reachable through the same page because backend reads from `audit_logs_all`

## Why This UI Structure Was Chosen

The page was requested to handle logs from all sections and to include a more visual side-navigation concept inspired by the screenshots provided.

Instead of creating a generic table-only page, the chosen structure was:
- left visual exploration rail
- center operational list
- right detail inspector

This supports three different user workflows:
- browse by module
- search/filter for a specific event
- inspect exact old/new value changes

That structure is more appropriate for an audit page than a simple flat report table.

## Files Changed

The complete implementation touched these files:

### Backend
- [backend/src/app.module.ts](/e:/zerpai-new/backend/src/app.module.ts)
- [backend/src/modules/reports/reports.controller.ts](/e:/zerpai-new/backend/src/modules/reports/reports.controller.ts)
- [backend/src/modules/reports/reports.service.ts](/e:/zerpai-new/backend/src/modules/reports/reports.service.ts)

### Frontend
- [lib/core/routing/app_routes.dart](/e:/zerpai-new/lib/core/routing/app_routes.dart)
- [lib/core/routing/app_router.dart](/e:/zerpai-new/lib/core/routing/app_router.dart)
- [lib/core/layout/zerpai_sidebar.dart](/e:/zerpai-new/lib/core/layout/zerpai_sidebar.dart)
- [lib/modules/reports/repositories/reports_repository.dart](/e:/zerpai-new/lib/modules/reports/repositories/reports_repository.dart)
- [lib/modules/reports/presentation/reports_audit_logs_screen.dart](/e:/zerpai-new/lib/modules/reports/presentation/reports_audit_logs_screen.dart)

### Documentation updated
- [log.md](/e:/zerpai-new/log.md)

## Verification Completed

### Flutter verification

Ran:
- `dart format` on touched Flutter files
- `dart analyze` on:
  - audit screen
  - app routes
  - app router
  - sidebar
  - reports repository

Result:
- no issues found

### Backend verification

Ran:
- `npm run build --prefix backend`
- `npm test --prefix backend -- --runInBand`

Result:
- backend build passed
- backend Jest tests passed

### What was not done in this implementation pass

Not completed here:
- a full manual UI review of the live audit page with production-like data
- export/download from the audit page
- saved filters
- advanced timeline grouping
- deep link into source record screens from audit rows

Those are follow-up improvements, not blockers for the current implementation.

## How To Review This Change

Recommended review steps:

1. Confirm database audit rollout exists in the target environment.
2. Start backend and frontend.
3. Open `/audit-logs`.
4. Confirm sidebar placement after `Documents`.
5. Confirm rows are returned from the backend.
6. Test search.
7. Test action filters.
8. Test module/submodule filters.
9. Test recent vs archived scope switching.
10. Click a row and inspect old/new JSON.
11. Confirm older archived logs are still visible through the same page.

## Known Assumptions

- The SQL audit rollout has already been applied in the target database.
- `audit_logs_all` exists and is queryable.
- data may show `system` as actor when the backend does not provide request-scoped user metadata yet

This is expected in the current auth-free stage of the project.

## Final Outcome

The project now has:
- a centralized DB-backed audit model
- a backend API for audit exploration
- a dedicated Audit Logs route
- sidebar access to the page
- a themed audit UI capable of handling logs across all major modules

This is the first complete end-to-end audit browsing implementation in the repo, and it is aligned with the current production direction:
- DB triggers as source of truth
- archived history preserved
- auth-free now, auth-ready later
