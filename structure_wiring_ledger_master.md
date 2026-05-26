# Full Structure Refactor Master Ledger (All Modules)

## Status
- Mode: Full refactor program
- Scope: Frontend + Backend code structure
- Docs move policy: No project governance markdown relocation
- Current status: `approved`
- Reviewed On: 2026-05-21

---

## 1. Domain Inventory

### Frontend domains (`lib/modules`)
- accountant
- auth
- branches
- home
- inventory
- items
- mapping
- pricelists
- printing
- purchases
- reports
- sales
- settings

### Backend domains (`backend/src/modules`)
- accountant
- branches
- documents
- email
- gst
- health
- inventory
- lookups
- products
- purchases
- redis
- reports
- sales
- settings-zones
- supabase
- transaction-locking
- transaction-series
- users
- warehouses-settings

---

## 2. Global Wiring Snapshot

### Frontend route registry source
- `lib/core/routing/app_router.dart`
- Total route blocks detected: full app domains (auth, settings, items, sales, inventory, purchases, reports, accountant, docs, audit)

### Backend endpoint registry source
- `backend/src/modules/**/controllers/*.ts`
- Controller annotations and endpoint decorators inventoried (`@Controller`, `@Get`, `@Post`, `@Put`, `@Patch`, `@Delete`)

---

## 3. Mandatory Duplicate/Drift Risks Detected

1. Pricing frontend duplicate source
- Canonical: `lib/modules/pricelists/**`
- Legacy duplicate: `lib/modules/items/pricelist/**`

2. Pricing backend duplicate controller/module
- Legacy `backend/src/modules/products/pricelist/*` path retired.
- Active canonical path: `backend/src/modules/products/pricelists/pricelist/*`.
- `app.module.ts` now imports canonical module path.

3. Core/pages business spillover
- `lib/core/pages/**` retired from runtime; no active imports found.
- Keep monitoring for reintroduction via new refactor batches.

4. Service-location drift
- Some modules still import mixed `core/services` and `shared/services` patterns.

---

## 4. Full Refactor Execution Batches

## Batch A (completed)
- Pricing consumer import rewires (selected high-impact files) to canonical `modules/pricelists/pricelist`.

## Batch B (next)
- Complete remaining frontend import rewires from `items/pricelist` -> `pricelists/pricelist` (repo-wide).
- No folder moves yet.

## Batch C
- Backend pricing module wire unification:
  - switch `app.module.ts` to canonical pricing module
  - keep endpoint compatibility
  - deprecate legacy duplicate module path
  - Status: completed in current workspace snapshot

## Batch D
- Settings extraction planning and safe relocation map:
  - map `lib/core/pages/settings_*` -> `lib/modules/settings/**`
  - route alias compatibility layer

## Batch E
- Reports + printing module normalization

## Batch F
- Inventory submodule structural normalization (one submodule at a time)
  - transfer_orders
  - move_orders
  - adjustments
  - picklists
  - packages
  - shipments

## Batch G
- Sales submodule structural normalization

## Batch H
- Purchases submodule structural normalization

## Batch I
- Accountant submodule structural normalization (last)

---

## 5. Pre-Move Gate (for every batch)

Required before moving files:
1. file-by-file wiring ledger for that batch
2. risk flags per file:
   - route-risk
   - provider-risk
   - contract-risk
   - tenant-scope-risk
3. rollback plan for batch

Required after each batch:
1. frontend analyzer pass
2. backend build pass
3. route smoke checks
4. feature smoke checks for touched module
5. log entry update

---

## 6. Batch B Ledger Seed (remaining pricing rewires)

Outstanding import group:
- locate all `items/pricelist` references repo-wide
- classify into:
  - direct model usage
  - provider usage
  - transitive exports

Action:
- rewrite to canonical imports only
- verify no legacy imports remain in runtime paths

---

## 7. Approval Marker
- Current status: `approved`
- Batch B + Batch C ledgers reviewed and accepted for execution continuation.

---

## 8. Full Program Status Matrix (All Modules)

Snapshot date: 2026-05-21

### 8.1 Global architecture status
- `DONE` Frontend root contract present: `app/bootstrap/config/core/shared/engines/modules/generated`.
- `DONE` Legacy roots retired from runtime: `lib/core/pages`, `lib/data`, `lib/utils`.
- `DONE` App router ownership cut over:
  - `lib/app/routing/app_router.dart` active owner
  - `lib/core/routing/app_router.dart` compatibility export shim.
- `DONE` Navigation registry scaffolding present:
  - `lib/app/navigation/{app_module,navigation_registry,sidebar_builder,breadcrumbs,route_registry,search_registry}.dart`.
- `DONE` Backend legacy root duplicate cleanup:
  - removed `backend/src/health` and `backend/src/lookups`
  - canonical `backend/src/modules/health` and `backend/src/modules/lookups` retained.
- `DONE` Backend pricing canonicalization:
  - removed `backend/src/modules/products/pricelist/*`
  - active `backend/src/modules/products/pricelists/pricelist/*`
  - `backend/src/app.module.ts` imports canonical module.
- `IN_PROGRESS` Engine program:
  - `lib/engines/` root exists but sub-engine extraction is not yet completed.

### 8.2 Frontend module status
| Module | Status | Evidence | Remaining Work |
|---|---|---|---|
| settings | IN_PROGRESS | `settings/config/routes.dart` active; users/users_roles migrated under `presentation/pages`; module `shared/` exists | finish deeper decomposition targets (organization/taxes/customization/automation/integrations/preferences/approvals/branding/sequences) |
| reports | IN_PROGRESS | `reports/config/routes.dart` active and spread in app router | continue module-owned route extraction for any remaining report-related routes and normalize internal structure |
| printing | IN_PROGRESS | batch log indicates presentation migration completed | verify route ownership + module contract parity |
| inventory | IN_PROGRESS | submodules have `config/routes.dart` + `config/permissions.dart` placeholders | continue module-contract normalization and shared/business split |
| sales | IN_PROGRESS | route usage moved to `app/routing/app_router.dart`; credit_note + sales_return have config files | complete remaining submodule contract normalization and route extraction |
| purchases | IN_PROGRESS | bills/purchase_orders/purchase_receives/vendors have config files; presentation/pages migration logged | eliminate remaining legacy pricelist imports in purchase order create; continue contract normalization |
| accountant | IN_PROGRESS | manual_journals and recurring_journals config files present; migration logged | complete remaining top-level accountant structure normalization |
| items | IN_PROGRESS | items/item_groups/composite_items + pricelist config files present | complete legacy-to-canonical pricing dependency cleanup |
| pricelists | IN_PROGRESS | canonical `pricelists/pricelist` and `pricelists/branch_pricelist` active in routes | finish consumer rewires from `items/pricelist` and retire legacy duplicate when safe |
| auth | PENDING | module present, no dedicated refactor batch closed in current ledger | module contract pass + route ownership verification |
| branches | PENDING | module present, no dedicated refactor batch closed in current ledger | module contract pass + route ownership verification |
| home | PENDING | module present, no dedicated structural batch closed in current ledger | module contract pass + route ownership verification |
| mapping | PENDING | module present, no dedicated structural batch closed in current ledger | module contract pass + route ownership verification |

### 8.3 Backend domain status
| Backend Domain Area | Status | Evidence | Remaining Work |
|---|---|---|---|
| products/pricing | IN_PROGRESS | canonical pricing module active; legacy duplicate removed | endpoint smoke + response-shape verification across all pricing callers |
| health/lookups root duplicates | DONE | root duplicates removed, module paths retained | none |
| remaining backend domains | IN_PROGRESS | major structural cleanup started, many workspace changes active | domain-by-domain contract review, controller/service path normalization, verification gates per batch |

### 8.4 Known active blockers / deltas
1. Ledger approval gate:
   - CLOSED: master + pricing ledgers are `approved`.
2. Remaining legacy pricing import usage:
   - CLOSED: runtime search clear for `modules/items/pricelist` imports.
3. Engines extraction incomplete:
   - `lib/engines/*` sub-engine skeleton and cross-module business logic migration still pending.
4. Full module-contract compliance is not yet closed for all modules.

### 8.5 Verification state (latest)
- Frontend targeted analyzer pass:
  - `dart analyze lib/app/routing/app_router.dart lib/modules/settings/config/routes.dart lib/modules/reports/config/routes.dart` -> PASS.
- Backend build pass:
  - `npm.cmd run build` (workdir `backend/`) -> PASS.
- Global full-scope analyzer/build/smoke closure:
  - NOT YET CLOSED for the entire refactor program.
