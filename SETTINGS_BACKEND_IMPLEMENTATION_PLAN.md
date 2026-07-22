# Settings Backend Implementation Plan

Last updated: 2026-07-20 16:08 IST

## Rules

- Source of truth: `current schema.md`.
- No blanket `settings_` table prefix.
- Use canonical schema tables and existing module routes first.
- Global lookup/master tables stay global and do not use `entity_id`.
- Tenant-owned settings records use `entity_id` from `@Tenant()`.
- Server-side lists default to `page_size=100`.
- Backend must build after every completed slice.

## Current Backend Coverage

- [x] Organization profile and branding via `lookups/org/:orgId`.
- [x] Branches and business types via `branches`.
- [x] Warehouses via `warehouses-settings`.
- [x] Zones and bins via `zones`.
- [x] Users, roles, location access via `users`.
- [x] Transaction series backend via `transaction-series`.
- [x] Basic transaction locking backend via `transaction-locking`.
- [x] GST taxpayer lookup via `gst/taxpayer-details`.
- [x] Setup lookup lists via `lookups`.

## Phase 1 - Taxes Backend

Schema tables:
- `tax_rates`
- `tax_groups`
- `tax_group_rates`
- `tds_sections`
- `tds_rates`
- `tds_groups`
- `tds_group_items`
- `tcs_natures`
- `tcs_rates`
- `tcs_higher_rate_reasons`

Backend owner:
- `backend/src/modules/settings-taxes/`

Status:
- [x] Create Nest module, controller, service.
- [x] GST tax rates CRUD.
- [x] GST tax groups CRUD with child rate mappings.
- [x] TDS sections CRUD.
- [x] TDS rates CRUD.
- [x] TDS groups CRUD with child rate mappings.
- [x] TCS natures CRUD.
- [x] TCS higher-rate reasons CRUD.
- [x] TCS rates CRUD.
- [ ] Bulk status/delete actions where UI needs them.
- [x] Register module in `AppModule`.
- [x] `npm.cmd run build`.

Routes built:
- `GET /settings-taxes/summary`
- `GET|POST /settings-taxes/rates`
- `PATCH|DELETE /settings-taxes/rates/:id`
- `GET|POST /settings-taxes/groups`
- `PATCH|DELETE /settings-taxes/groups/:id`
- `GET|POST /settings-taxes/tds/sections`
- `PATCH|DELETE /settings-taxes/tds/sections/:id`
- `GET|POST /settings-taxes/tds/rates`
- `PATCH|DELETE /settings-taxes/tds/rates/:id`
- `GET|POST /settings-taxes/tds/groups`
- `PATCH|DELETE /settings-taxes/tds/groups/:id`
- `GET|POST /settings-taxes/tcs/natures`
- `PATCH|DELETE /settings-taxes/tcs/natures/:id`
- `GET|POST /settings-taxes/tcs/higher-rate-reasons`
- `PATCH|DELETE /settings-taxes/tcs/higher-rate-reasons/:id`
- `GET|POST /settings-taxes/tcs/rates`
- `PATCH|DELETE /settings-taxes/tcs/rates/:id`

## Phase 2 - Wire Existing Settings Backends

No new backend unless current route cannot satisfy UI.

- [x] Wire Settings transaction-number-series provider/pages to `transaction-series`.
- [x] Align lock-configuration provider/pages to existing `transaction-locking`.
- [x] Extend `transaction-locking` with configuration routes over `record_locking`.
- [x] Keep `transaction_locks` separate from configurable `record_locking`.
- [x] Query live DB before wiring:
  - `transaction_series`: 3 existing rows.
  - `transaction_locks`: 0 rows.
  - `record_locking`: 0 rows.
- [x] `npm.cmd run build`.

Routes reused/built:
- Reused `GET|POST /transaction-series`
- Reused `PATCH|DELETE /transaction-series/:id`
- Added `GET|POST /transaction-locking/configurations`
- Added `PATCH|DELETE /transaction-locking/configurations/:id`

Notes:
- `record_locking.allow_or_restrict_actions` only accepts `Allow` or `Restrict`.
- The current schema does not include a persisted `allow_or_restrict_fields` column; the frontend now displays a safe default for that field when reading DB rows.

## Phase 3 - Setup Masters Backend

Schema tables:
- `currencies`
- `payment_terms`
- `units`
- `uqc`
- `date_format`
- `date_separator`
- `fiscal_years`
- `default_payment_terms`

Backend owner:
- `backend/src/modules/settings-setup/`

Status:
- [x] Currency list/create/update/deactivate using canonical `currencies`.
- [x] Payment terms CRUD/defaults.
- [x] Units CRUD and usage guard via existing `products/lookups/units` routes.
- [x] UQC read/list mapping via existing `products/lookups/uqc` route.
- [ ] Date/fiscal/general preference persistence using canonical org/entity tables.
- [x] `npm.cmd run build` for payment terms slice.
- [x] `npm.cmd run build` for units/UQC slice.

Routes built:
- `GET /settings-setup/payment-terms`
- `POST /settings-setup/payment-terms`
- `PATCH /settings-setup/payment-terms/:id`
- `DELETE /settings-setup/payment-terms/:id`
- `POST /settings-setup/payment-terms/:id/default`
- Reused `GET /products/lookups/units`
- Reused `POST /products/lookups/units/sync`
- Reused `POST /products/lookups/units/check-usage`
- Reused `GET /products/lookups/uqc`
- `GET /settings-setup/currencies`
- `POST /settings-setup/currencies`
- `PATCH /settings-setup/currencies/:id`
- `DELETE /settings-setup/currencies/:id`
- `GET /settings-setup/date-formats`
- `GET /settings-setup/date-separators`
- `GET /settings-setup/fiscal-years`

Notes:
- Reuses existing canonical tables `payment_terms` and `default_payment_terms`.
- No SQL or table creation in this phase.
- Delete marks `payment_terms.is_active=false` to preserve FKs from purchase orders, sales orders, bills, and default payment terms.
- Settings payment terms page now reads/writes DB rows instead of local `_defaultTerms`.
- Settings units page now reads DB units/UQC and no longer seeds demo units or hardcoded UQC options.
- Unit delete uses existing sync route with `is_active=false` instead of removing referenced rows.
- Settings currencies page now reads DB currencies and no longer seeds demo currencies or sample exchange-rate rows.
- Currency exchange-rate import is disabled with an explicit message until `currency_exchange_rates` exists.

## Phase 4 - Customization Backend

Schema tables:
- `reporting_tags`
- Existing print/template tables: confirm before coding.
- Existing email notification tables: confirm before coding.
- Existing custom field tables: confirm before coding.

Status:
- [x] Reporting tags CRUD with `entity_id`.
- [ ] Print/PDF template backend only after schema confirmation.
- [ ] Email notification backend only after schema confirmation.
- [ ] Custom fields backend only after schema confirmation.
- [x] `npm.cmd run build` for reporting tags slice.

Routes built:
- `GET /settings-customization/reporting-tags`
- `POST /settings-customization/reporting-tags`
- `PATCH /settings-customization/reporting-tags/:id`
- `DELETE /settings-customization/reporting-tags/:id`

Notes:
- Reuses existing canonical `reporting_tags`.
- Settings reporting tags page no longer seeds demo rows.
- Advanced tag options/module mappings need final SQL tables before full persistence.

## Phase 5 - Module Settings Persistence

Settings pages:
- Sales: invoices, sales orders, credit notes, delivery challans, retainer invoices.
- Purchase: purchase orders, purchase receives, expenses.
- Inventory: shipments, stock counts, transfer orders.

Status:
- [ ] Map each page field to `current schema.md`.
- [ ] Reuse existing transactional/default tables where present.
- [ ] Add minimal backend routes only for fields with real schema ownership.
- [ ] Avoid placeholder tables.
- [ ] `npm.cmd run build`.

## Phase 6 - Approvals / Workflow Settings

Current state:
- Approval UI uses hardcoded/local records.
- Schema only confirms `purchase_request_approval` for purchase requests.

Status:
- [ ] Confirm whether broader approval/workflow tables exist in updated schema.
- [ ] If only purchase request approval exists, backend only that workflow first.
- [ ] Do not invent a generic approval engine table without schema/product confirmation.
- [ ] `npm.cmd run build`.

## Verification Log

- [x] Phase 1 backend build passed.
- [x] Phase 2 backend build passed.
- [x] Phase 3A payment terms backend build passed.
- [x] Phase 3B units/UQC backend build passed.
- [x] Phase 3C currencies backend build passed.
- [x] Phase 4A reporting tags backend build passed.
- [ ] Phase 5 backend build passed.
- [ ] Phase 6 backend build passed.
