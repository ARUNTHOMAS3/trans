# Zerpai Performance Pain-Point Report (Project-Wide)

Date: 2026-05-16
Scope: Project-wide static audit across `lib/modules/*`, shared dialogs, and backend lookup APIs in `backend/src/modules/*`.
Method: Code-path inspection with API wiring cross-check (no synthetic benchmark run in this pass).

## Status Legend
- DONE: Implemented and verified in current codebase.
- PARTIAL: Improvement exists but only for some modules/flows.
- LEFT: Not implemented yet.

## Executive Summary
The same slowdown pattern appears project-wide in lookup management flows:
1. Add-one actions still call full-list sync APIs in many modules.
2. Items module still forces full bootstrap reload after sync.
3. Backend sync path still performs serial usage checks (N+1 behavior).
4. Hot paths still emit high-volume debug logs.

Impact: avoidable payload bloat, extra DB and API round-trips, longer modal save cycles, and backend IO/CPU overhead.

---

## What Is Already Done

### 1) Single-create fast path expanded for several item lookups
- Status: DONE (for covered lookup domains)
- Backend endpoints present:
  - `POST /products/lookups/manufacturers`
  - `POST /products/lookups/brands`
  - `POST /products/lookups/strengths`
  - `POST /products/lookups/categories`
  - `POST /products/lookups/storage-locations`
  - `POST /products/lookups/racks`
  - `POST /products/lookups/contents`
  - `POST /products/lookups/buying-rules`
  - `POST /products/lookups/drug-schedules`
- Evidence:
  - `backend/src/modules/products/products.controller.ts:147,159,203,281,310,428,445,486,515`
  - UI wiring now uses `onCreateOne` for manufacturer/brand/storage/content/strength/buying-rule/drug-schedule:
    - `lib/modules/items/items/presentation/sections/items_item_create_tabs.dart:247,260`
    - `lib/modules/items/items/presentation/sections/items_item_create_inventory.dart:323`
    - `lib/modules/items/items/presentation/sections/composition_section.dart:364,385,524,538`

### 2) Unit bulk check payload issue on dialog open
- Status: DONE
- Fix already applied: removed startup full-catalog `check-usage` preflight for units; targeted checks remain.
- Evidence trail: `log.md` entries 233+.

### 3) Manufacturer sync logging flood reduction
- Status: DONE
- Heavy per-item logging/preprocessing removed in manufacturer sync path.
- Evidence trail: `log.md` entry 227.

---

## Priority Matrix (Done vs Left)

## P0 (Highest)

### P0-1: Full-list sync still used for Add New in multiple non-Items modules
- Status: LEFT
- APIs impacted:
  - `POST /products/lookups/payment-terms/sync`
  - `POST /products/lookups/salespersons/sync`
  - `POST /products/lookups/categories/sync` (in remaining category dialogs)
  - `POST /shipment-preferences/sync`
- Where it happens:
  - Sales Order payment terms + salespersons:
    - `lib/modules/sales/presentation/sales_order_create.dart:394,525`
  - Purchase Order payment terms:
    - `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_create.dart:297`
  - Bills payment terms:
    - `lib/modules/purchases/bills/presentation/purchases_bills_create.dart:423`
  - Vendors payment terms:
    - `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_builders.dart:163`
  - Sales customer payment terms:
    - `lib/modules/sales/presentation/sections/sales_customer_builders.dart:623`
  - Composite item category manage:
    - `lib/modules/items/composite_items/presentation/items_composite_items_composite_creation.dart:219`
  - Item create category manage:
    - `lib/modules/items/items/presentation/items_item_create.dart:1337`
  - Shipment preferences sync:
    - `lib/modules/items/items/services/lookups_api_service.dart:680`
- Why it hurts:
  - Single-row edits can still post large list payloads with deactivation semantics.
- Gain if fixed:
  - Large reduction in modal save latency and payload size across Sales/Purchases/Composite flows.

### P0-2: Items sync path still forces full lookup bootstrap reload
- Status: LEFT
- Evidence:
  - `_syncGeneric` calls `loadLookupData(force: true)` after sync:
    - `lib/modules/items/items/controllers/items_controller.dart:1910`
  - Bootstrap API called uncached:
    - `lib/modules/items/items/services/lookups_api_service.dart:14-17`
- Why it hurts:
  - Every small lookup save can trigger global lookup reload.
- Gain if fixed:
  - Faster post-save UI readiness and fewer backend reads.

### P0-3: Vendor fast-path still missing
- Status: LEFT (intentionally deferred)
- Evidence:
  - Vendor supports only sync in API service:
    - `lib/modules/items/items/services/lookups_api_service.dart:290-294`
  - Backend has `vendors/sync`, no create-one endpoint:
    - `backend/src/modules/products/products.controller.ts:247`
- Why it matters:
  - Vendor flows remain on full sync path while other lookups improved.

---

## P1 (High)

### P1-1: Backend lookup sync deactivation still uses serial usage checks
- Status: LEFT
- Evidence:
  - Generic path loops `idsToDisable` and calls `checkLookupUsage` one-by-one:
    - `backend/src/modules/products/products.service.ts:3192-3195`
  - Reorder-term path has same serial pattern:
    - `backend/src/modules/products/products.service.ts:2394-2395`
- Why it hurts:
  - N+1 query behavior on larger sync batches.
- Gain if fixed:
  - Significant DB round-trip reduction for larger catalogs.

### P1-2: Hot-path debug logging still heavy in lookup APIs
- Status: PARTIAL
- Evidence remaining:
  - Backend logs in unit usage/sync and generic sync:
    - `backend/src/modules/products/products.service.ts:1411,1540,1547,1555,3105,3272,3295`
  - Frontend payload dumps in lookup service:
    - `lib/modules/items/items/services/lookups_api_service.dart:50-58,425-444,606-618`
  - Controller-level sync logs:
    - `backend/src/modules/products/products.controller.ts:91-97,181-187`
- Why it hurts:
  - IO overhead and noisy operations in frequent flows.
- Gain if fixed:
  - Lower request overhead and cleaner operational logging.

---

## P2 (Medium)

### P2-1: `syncUnits` remains row-by-row write loop
- Status: LEFT
- Evidence:
  - Loop-based per-row update/insert in `syncUnits`:
    - `backend/src/modules/products/products.service.ts:1437-1493`
- Why it hurts:
  - Scales poorly as unit list grows.

### P2-2: Payment terms dialog architecture is still full-sync only
- Status: LEFT
- Evidence:
  - `ManagePaymentTermsDialog` has no `onCreateOne` fast path; save persists entire edited table:
    - `lib/shared/widgets/inputs/manage_payment_terms_dialog.dart`
  - All consumers call `syncPaymentTerms(items)` directly.
- Why it hurts:
  - Add-one or rename flows still treated like bulk sync operations.

### P2-3: Dual lookup stacks create maintenance/perf drift risk
- Status: LEFT
- Evidence:
  - `products` lookup controller with specialized routes:
    - `backend/src/modules/products/products.controller.ts`
  - separate generic lookup sync controller:
    - `backend/src/modules/lookups/lookups.controller.ts:175,222`
- Why it hurts:
  - Flow behavior and optimization can diverge by endpoint family.

---

## P3 (Lower / Hygiene)

### P3-1: Remaining category manage dialogs not using create-one path
- Status: LEFT
- Evidence:
  - Item create and composite item category dialogs use `syncCategories` only:
    - `lib/modules/items/items/presentation/items_item_create.dart:1337`
    - `lib/modules/items/composite_items/presentation/items_composite_items_composite_creation.dart:219`

### P3-2: Misc module-level hardcoded debug prints in high-frequency paths
- Status: LEFT
- Evidence examples:
  - `debugPrint` and `console.log` in frequently used services/repositories:
    - `backend/src/modules/users/users.service.ts:782`
    - `backend/src/modules/supabase/supabase.service.ts:29`
    - `lib/modules/sales/presentation/sales_order_create.dart` (load flows)

---

## Recommended Execution Order (Project-Wide)

1. Convert payment terms/salespersons/category remaining dialogs to create-one fast path and keep sync only for bulk edits.
2. Stop forced global lookup bootstrap reload after each items sync; use targeted local merge.
3. Batch backend usage checks for deactivate candidates (single query pattern with `IN`).
4. Reduce lookup-path logging to counters/IDs-length with env-gated verbose mode.
5. Refactor `syncUnits` to batched upsert.
6. Unify or clearly separate lookup stacks (`products/lookups` vs `lookups`) to prevent optimization drift.

---

## Current Overall Status Snapshot

- DONE: 4
- PARTIAL: 2
- LEFT: 8

Interpretation: progress is now cross-module (items sync path + shared payment-terms payload optimization), but high-impact backlog remains in backend usage-check batching and remaining full-sync dialogs.
