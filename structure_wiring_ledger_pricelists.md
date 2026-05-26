# Structure Refactor Wiring Ledger (Price Lists + Branch Price Lists)

## Ledger Metadata
- Scope: Frontend `lib/**` and Backend `backend/src/**` only
- Purpose: File-by-file wiring map before any move
- Coverage: `pricelists/pricelist`, `pricelists/branch_pricelist`, legacy `items/pricelist`, route + backend module wiring
- Status: `approved`
- Date: 2026-05-21
- Reviewed On: 2026-05-21

---

## A. Frontend Route Wiring Ledger

| Route Name | Route Path | Page Entry File | Model Type in `extra` | Controller/Provider Chain | Repository/Service Chain | Risk Flags |
|---|---|---|---|---|---|---|
| `AppRoutes.priceLists` | `items/price-lists` | `lib/modules/pricelists/pricelist/presentation/pricelist_overview.dart` | N/A | `pricelist_provider.dart` notifiers | `pricelist_repository.dart` -> `ApiClient` -> `ApiEndpoints.priceLists` | provider-risk: medium |
| `AppRoutes.priceListsCreate` | `items/price-lists/create` | `lib/modules/pricelists/pricelist/presentation/pricelist_add.dart` | `PriceList` | `pricelist_provider.dart` | `pricelist_repository.dart` -> `/price-lists` POST | contract-risk: medium |
| `AppRoutes.priceListsEdit` | `items/price-lists/edit/:id` | `lib/modules/pricelists/pricelist/presentation/pricelist_edit.dart` | `PriceList` | `pricelist_provider.dart` | `pricelist_repository.dart` -> `/price-lists/:id` PUT/GET | route-risk: low |
| `AppRoutes.branchPriceLists` | `items/branch-price-lists` | `lib/modules/pricelists/branch_pricelist/presentation/branch_pricelist_overview_page.dart` | N/A | `branch_pricelist_provider.dart` | `branch_pricelist_repository.dart` -> `/price-lists?scope=BRANCH` | provider-risk: medium |
| `AppRoutes.branchPriceListsCreate` | `items/branch-price-lists/create` | `lib/modules/pricelists/branch_pricelist/presentation/branch_pricelist_add_page.dart` | `BranchPriceList` | `branch_pricelist_provider.dart` | `branch_pricelist_repository.dart` -> `/price-lists` POST (`price_scope=BRANCH`) | contract-risk: medium |
| `AppRoutes.branchPriceListsEdit` | `items/branch-price-lists/edit/:id` | `lib/modules/pricelists/branch_pricelist/presentation/branch_pricelist_edit_page.dart` | `BranchPriceList` | `branch_pricelist_provider.dart` | `branch_pricelist_repository.dart` -> `/price-lists/:id` PUT/GET | route-risk: low |

Primary route file reference:
- `lib/core/routing/app_router.dart` (pricing routes block around lines ~1220-1275)

---

## B. Frontend File-by-File Ledger (Canonical Pricing Module)

## B1. `lib/modules/pricelists/pricelist/`

| File | Current Role | Inbound Dependents | Outbound Dependencies | Target Path (no behavior change) | Risk |
|---|---|---|---|---|---|
| `models/pricelist_model.dart` | Main domain model | Router, screens, providers, external sales/purchases consumers | json serialization, pagination model | keep | provider-risk: high |
| `models/pricelist_model.g.dart` | generated serializers | model | generated only | keep | low |
| `models/pricelist_pagination.dart` | pagination model | provider/repository/screens | model types | keep | low |
| `repositories/pricelist_repository.dart` | canonical API repository (SELF scope) | provider/controller | `ApiClient`, `ApiEndpoints.priceLists` | keep (as source of truth) | contract-risk: high |
| `providers/pricelist_provider.dart` | Riverpod state + filters | multiple screens + external modules | repository + model | keep | provider-risk: high |
| `controllers/pricelist_controller.dart` | orchestration glue | screens | provider/repo | keep or merge into provider later (defer) | medium |
| `services/pricelist_service.dart` | helper/service layer | screens/controllers | repo/model | keep | medium |
| `presentation/pricelist_overview.dart` | list UI | router | providers, shared widgets | keep | low |
| `presentation/pricelist_add.dart` | create UI | router | providers, items controller, shared inputs | keep | medium |
| `presentation/pricelist_edit.dart` | edit UI | router | providers, recent-history, shared inputs | keep | medium |
| `presentation/widgets/volume_pricing_help_popover.dart` | shared submodule widget | add/edit screens | `ZTooltip`, `AppTheme` | keep | low |

## B2. `lib/modules/pricelists/branch_pricelist/`

| File | Current Role | Inbound Dependents | Outbound Dependencies | Target Path | Risk |
|---|---|---|---|---|---|
| `models/branch_pricelist_model.dart` | branch pricing model | router/screens/provider | json model | keep | medium |
| `models/branch_pricelist_model.g.dart` | generated serializers | model | generated only | keep | low |
| `models/branch_pricelist_pagination.dart` | pagination model | provider/screens | model types | keep | low |
| `repositories/branch_pricelist_repository.dart` | branch-scope API repository | provider/controller | `ApiClient`, `ApiEndpoints.priceLists` | keep (canonical for branch scope) | contract-risk: high |
| `providers/branch_pricelist_provider.dart` | Riverpod state for branch lists | screens | repository/model | keep | provider-risk: high |
| `controllers/branch_pricelist_controller.dart` | orchestration | screens | provider/repo | keep or merge later (defer) | medium |
| `services/branch_pricelist_service.dart` | helper/service | screens/controllers | repository | keep | medium |
| `presentation/branch_pricelist_overview_page.dart` | list UI | router | provider/shared widgets | keep | low |
| `presentation/branch_pricelist_add_page.dart` | create UI | router | provider/items controller/shared inputs | keep | medium |
| `presentation/branch_pricelist_edit_page.dart` | edit UI | router | provider/shared services/widgets | keep | medium |
| `presentation/widgets/volume_pricing_help_popover.dart` | submodule widget | add/edit screens | `ZTooltip`, `AppTheme` | keep | low |

---

## C. Frontend Legacy Duplicate Ledger (`items/pricelist`)

| Legacy File | Current Consumers | Problem | Planned Action | Target Canonical |
|---|---|---|---|---|
| `lib/modules/items/pricelist/models/pricelist_model.dart` | sales, purchases, navbar imports | duplicate model definition risk | replace imports gradually | `lib/modules/pricelists/pricelist/models/pricelist_model.dart` |
| `lib/modules/items/pricelist/providers/pricelist_provider.dart` | sales/purchases flows | dual provider state divergence risk | switch consumers to canonical provider | `lib/modules/pricelists/pricelist/providers/pricelist_provider.dart` |
| `lib/modules/items/pricelist/repositories/pricelist_repository.dart` | legacy provider/service | uses direct Dio/Hive path shape, diverges from canonical repository | deprecate after consumer migration | `lib/modules/pricelists/pricelist/repositories/pricelist_repository.dart` |
| `lib/modules/items/pricelist/services/pricelist_service.dart` | legacy screens/hooks | duplicate service behavior | migrate callers and remove later | `lib/modules/pricelists/pricelist/services/pricelist_service.dart` |
| `lib/modules/items/pricelist/controllers/pricelist_controller.dart` | legacy flow | duplicate orchestration | migrate and deprecate | `lib/modules/pricelists/pricelist/controllers/pricelist_controller.dart` |

### C1. Known cross-module imports still pointing to legacy path
- none (runtime search clear as of 2026-05-21)

Risk classification:
- route-risk: low
- provider-risk: low
- contract-risk: low

---

## D. Backend Wiring Ledger (Pricing)

## D1. Active backend module registration
| File | Observation | Risk |
|---|---|---|
| `backend/src/app.module.ts` | imports `PriceListModule` from `./modules/products/pricelists/pricelist/pricelist.module` (canonical path) | contract-risk: low |

## D2. Duplicate backend pricing controllers
| File | Base Route | Notes | Planned Canonical |
|---|---|---|---|
| `backend/src/modules/products/pricelists/pricelist/pricelist.controller.ts` | `@Controller("price-lists")` | active canonical controller; legacy duplicate path removed from runtime | canonical target (active) |

## D3. Backend endpoint-to-table map
| Endpoint | Controller Method | Tables Touched | Notes |
|---|---|---|---|
| `GET /price-lists` | `findAll` | `price_lists` (+ branch assignments in newer controller flow) | supports scope behavior |
| `GET /price-lists/:id` | `findOne` | `price_lists`, `price_list_items`, `price_list_volume_ranges`, `products` | enriched response |
| `POST /price-lists` | `create` | `price_lists`, `price_list_items`, `price_list_volume_ranges` | scope-based create |
| `PUT /price-lists/:id` | `update` | same as above + assignment tables (newer flow) | upsert/replace ranges |
| `DELETE /price-lists/:id` | `remove` | `price_lists` (plus relational cleanup by policy) | hard/soft behavior depends on implementation |
| `PATCH /price-lists/:id/deactivate` | `deactivate` | `price_lists` | status update |

Primary risk flags:
- route-risk: low
- contract-risk: low
- tenant-scope-risk: low (canonical tenant-aware backend pricing module active)

---

## E. Move Plan Mapping (No move executed yet)

| Current File/Area | Target Area | Move Type | Preconditions |
|---|---|---|---|
| `lib/modules/items/pricelist/**` | `lib/modules/pricelists/pricelist/**` | consumer import migration, then deprecate legacy | all consumer imports mapped + tests/analyze clean |
| sales/purchases imports to legacy pricing | switch to canonical pricing imports | import rewrite only | provider API parity confirmed |
| backend `modules/products/pricelist/*` | backend `modules/products/pricelists/pricelist/*` | AppModule wire swap + legacy retirement | completed in codebase; keep smoke verification in batch gates |

---

## F. Approval Checklist (must be true before any folder move)
- [x] Frontend ledger reviewed for all pricing files
- [x] Backend ledger reviewed for active module registration
- [x] Legacy import migration list approved
- [x] Risk acceptance signed for `provider-risk` and `tenant-scope-risk`
- [ ] Rollback branch created for first migration batch

Ledger status transition:
- `draft` -> `reviewed` -> `approved`

No move allowed until status is `approved`.
