# Tenancy And Schema

## Entity Classification

- Global resource: shared across all tenants, no `entity_id`. Examples: `products`, `categories`, `brands`, `manufacturers`, `tax_rates`, `tax_groups`, `payment_terms`, `currencies`, `uqc`, `units`, `storage_conditions`, `buying_rules`, `drug_schedules`, `drug_strengths`, `contents`, `racks`, `shipment_preferences`, `tds_rates`, `tds_sections`, `tds_groups`, `price_lists`, `price_list_items`, `countries`, `states`, `timezones`, `gst_treatments`, `gstin_registration_types`, `business_types`, `hsn_sac_codes`, `composite_items`, `composite_item_parts`.
- Business-owned record: belongs to an org or branch. Scoped via `entity_id`. Examples: invoices, customers, bills, vendors, manual journals, sales orders.

## Required Columns

- All business-owned tables require `entity_id uuid NOT NULL REFERENCES organisation_branch_master(id)` as the **single canonical tenant scope column**.
- Legacy `org_id` and `outlet_id` columns exist on some tables for backward compatibility only — do not use them as the primary filter in new queries.
- Global lookup tables must NOT have `entity_id`.

## organisation_branch_master

- Polymorphic entity registry: `type` = `'ORG'` or `'BRANCH'`.
- `ref_id` links to the actual `organization.id` or `branches.id`.
- `parent_id` links a branch entity row to its org entity row.
- All business tables reference it via `entity_id uuid NOT NULL`.
- Resolve `entityId` in controllers via `@Tenant()` or `@Tenant('entityId')` decorator — never read headers manually in services.

## Development Posture

- Use `X-Entity-Id` header (preferred) or `X-Org-Id` + `X-Branch-Id` for tenant context.
- Keep schema auth-ready even though runtime auth may be toggled.
- Avoid baking dev-only shortcuts into schema design.

## Mapping Rules

- Use `current schema.md` and `PRD/prd_schema.md` as the reference snapshots for field names and table existence.
- Do not reintroduce deprecated `items`-table thinking when the PRD now centers on `products`.
- For new lookups or master tables, follow the PRD naming convention rather than inventing inconsistent names.
- Settings-owned tables that are not yet renamed must still start with `settings_`; all renamed tables follow the standard module naming convention.
