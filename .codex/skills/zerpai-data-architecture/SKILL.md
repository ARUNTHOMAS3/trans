---
name: zerpai-data-architecture
description: Apply Zerpai ERP schema, tenancy, workflow, and backend integration rules when changing data models, SQL, Drizzle schema, NestJS services, repositories, APIs, or form-to-table mappings. Use when tasks touch `backend/`, `supabase/`, `PRD/prd_schema.md`, or any business workflow that depends on org, outlet, product, or transaction boundaries.
---

# Zerpai Data Architecture

Use this skill when code changes can affect data boundaries or business correctness. The critical decisions here are multi-tenancy shape, global product rules, and strict sales and purchase lifecycle behavior.

## Workflow

1. Read `references/tenancy-and-schema.md` before touching tables, DTOs, services, repositories, migrations, or data mapping logic.
2. Read `references/workflows-and-operability.md` when the task affects inventory movement, accounting, reporting, deployment assumptions, or auth readiness.
3. Classify each entity before editing:
   - global resource
   - org-scoped business record
   - outlet-scoped operational record
4. Preserve PRD workflow rules in API and database logic.

## Core Rules

- Global lookup tables (`products`, `categories`, `brands`, `manufacturers`, `tax_rates`, `tax_groups`, `payment_terms`, `currencies`, `uqc`, `units`, `storage_conditions`, `buying_rules`, `drug_schedules`, `drug_strengths`, `contents`, `racks`, `shipment_preferences`, `tds_rates`, `tds_sections`, `tds_groups`, `price_lists`, `price_list_items`, `countries`, `states`, `timezones`, `gst_treatments`, `gstin_registration_types`, `business_types`, `hsn_sac_codes`, `composite_items`, `composite_item_parts`) are global and must NOT carry `entity_id`.
- All business-owned tables (invoices, bills, customers, vendors, journals, etc.) must include `entity_id uuid NOT NULL REFERENCES organisation_branch_master(id)` as the single canonical tenant scope column.
- `organisation_branch_master` is the polymorphic entity registry: `type` = `'ORG'` or `'BRANCH'`, `ref_id` → actual `organization.id` or `branches.id`.
- Access resolved tenant context in controllers via `@Tenant()` or `@Tenant('entityId')` decorator — never read `X-Org-Id` or `X-Branch-Id` headers manually in service methods.
- Development remains auth-toggleable, but schema and architecture must stay auth-ready.
- All forms and payloads must map to the schema snapshot rather than inventing ad hoc fields.

## Operational Constraints

- Sales lifecycle: `Quotation -> Sales Order -> Invoice -> Payment`.
- Purchase lifecycle: `Purchase Order -> Receipt -> Bill -> Payment`.
- Reduce stock only on invoice confirmation.
- Increase stock only on goods receipt.
- Keep reporting and export behavior aligned to the underlying transactional tables.

## Reference Loading

- Use `references/tenancy-and-schema.md` for schema boundaries and column rules.
- Use `references/workflows-and-operability.md` for lifecycle logic, deployment posture, and monitoring-oriented expectations.
