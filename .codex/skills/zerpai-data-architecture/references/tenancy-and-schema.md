# Tenancy And Schema

## Entity Classification

- Global resource: shared across organizations. Example: `products`.
- Org-scoped record: belongs to one organization. Examples: invoices, customers, bills.
- Outlet-scoped record: tied to an outlet or branch. Example: outlet inventory.

## Required Columns

- Business-owned tables generally require `org_id uuid NOT NULL`.
- Outlet-scoped tables require `outlet_id` and may also require `org_id`.
- `products` is the exception and must remain global without `org_id`.

## Development Posture

- Use a single hardcoded development `org_id` where the app needs context.
- Keep schema auth-ready even though runtime auth is deferred.
- Avoid baking dev-only shortcuts into schema design.

## Mapping Rules

- Use `PRD/prd_schema.md` as the reference snapshot for field names and table existence.
- Do not reintroduce deprecated `items`-table thinking when the PRD now centers on `products`.
- For new lookups or master tables, follow the PRD naming convention rather than inventing inconsistent names.
- For settings-owned tables, the naming convention is stricter: any new table created for the global settings system must start with `settings_`.
