# Locked Decisions

## Product And Environment

- Auth is enabled in production; use `ENABLE_AUTH=false` dart-define or backend env toggle for local dev bypass.
- All business-owned tables scope data via `entity_id uuid NOT NULL REFERENCES organisation_branch_master(id)` — the single canonical tenant scope column.
- `organisation_branch_master` is the polymorphic entity registry: `type` = `'ORG'` or `'BRANCH'`, `ref_id` → actual `organization.id` or `branches.id`.
- Access resolved tenant context in controllers via `@Tenant()` or `@Tenant('entityId')` decorator — never read headers manually in services.
- Tenant headers: `X-Entity-Id` (preferred), `X-Org-Id` (routing), `X-Branch-Id` (optional branch scope).

## Technical Choices

- Frontend: Flutter.
- State: Riverpod.
- Navigation: GoRouter.
- HTTP: Dio only. Do not introduce the legacy `http` package.
- Offline data: Hive.
- Backend: NestJS.
- ORM and schema work: Drizzle ORM.
- Database: Supabase PostgreSQL.
- Deployment target: Vercel.

## Delivery And Safety

- Do not edit PRD files unless the user or team head explicitly asks for PRD changes.
- Use latest stable dependencies when adding packages.
- Verify a library exists in the repo before assuming it is available.
- Prefer targeted edits and a test-implement-verify loop.
- Respect the locked sidebar/module model and PRD-controlled UI rules.

## Product Rules Worth Rechecking

- Global lookup tables (`products`, `categories`, `brands`, `manufacturers`, `tax_rates`, `tax_groups`, `payment_terms`, `currencies`, `uqc`, `units`, `storage_conditions`, `buying_rules`, `drug_schedules`, `drug_strengths`, `contents`, `racks`, `shipment_preferences`, `tds_rates`, `tds_sections`, `tds_groups`, `price_lists`, `price_list_items`, `countries`, `states`, `timezones`, `gst_treatments`, `gstin_registration_types`, `business_types`, `hsn_sac_codes`, `composite_items`, `composite_item_parts`) are global and must NOT be scoped by `entity_id`.
- All business-owned transactional data must use `entity_id uuid NOT NULL REFERENCES organisation_branch_master(id)` as the tenant scope column.
- Any new database table created specifically for the global settings system must start with `settings_`.
- Server-side pagination is mandatory for tables, defaulting to 100 rows.
- `MenuAnchor` is mandatory for action menus and `FormDropdown` is mandatory for form selections.
- Dialogs, dropdowns, popup menus, date pickers, and overlay surfaces must default to pure white `#FFFFFF`; do not rely on inherited Material surface tinting unless explicitly approved.
- `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` is the standard reusable date picker for anchored business date inputs; do not add new raw `showDatePicker(...)` usage by default.
- Real DB-backed runtime data takes precedence over dummy/demo/mock values, master defaults should resolve from DB-backed rows, empty/error states must remain explicit, and warehouse/storage/accounting/physical concepts must stay separated across schema and UI.
- Save/create/confirm buttons, cancel/secondary actions, upload controls, and border/divider styling must remain centralized and consistent with the approved project theme rather than screen-local color choices.
- Responsive web behavior must come from the shared Flutter foundation: global breakpoints, shared responsive table shells, shared responsive form rows/grids, shared responsive dialog width rules, and sidebar-aware shell/content metrics instead of isolated screen-level overflow patches.
- New modules and major internal sub-screens must expose deep-linkable GoRouter routes so refresh, direct URL access, and browser navigation preserve the current working context.
