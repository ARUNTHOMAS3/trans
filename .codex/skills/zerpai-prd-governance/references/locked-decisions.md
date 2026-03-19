# Locked Decisions

## Product And Environment

- Treat Zerpai ERP as an auth-free development project until production approval.
- Do not enforce login, RBAC, JWT validation, or auth-gated routing in dev or staging.
- Allow auth UI to exist in `lib/modules/auth/`, but keep it disconnected from the active routing flow unless explicitly requested.
- Assume a single hardcoded development `org_id` with selectable `outlet_id`, while keeping schema columns ready for real multi-tenancy.

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

- Products are global and must not be scoped by `org_id`.
- Business-owned transactional data remains organization-scoped.
- Server-side pagination is mandatory for tables, defaulting to 100 rows.
- `MenuAnchor` is mandatory for action menus and `FormDropdown` is mandatory for form selections.
- Dialogs, dropdowns, popup menus, date pickers, and overlay surfaces must default to pure white `#FFFFFF`; do not rely on inherited Material surface tinting unless explicitly approved.
- `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` is the standard reusable date picker for anchored business date inputs; do not add new raw `showDatePicker(...)` usage by default.
- Real DB-backed runtime data takes precedence over dummy/demo/mock values, master defaults should resolve from DB-backed rows, empty/error states must remain explicit, and warehouse/storage/accounting/physical concepts must stay separated across schema and UI.
- Save/create/confirm buttons, cancel/secondary actions, upload controls, and border/divider styling must remain centralized and consistent with the approved project theme rather than screen-local color choices.
- Responsive web behavior must come from the shared Flutter foundation: global breakpoints, shared responsive table shells, shared responsive form rows/grids, shared responsive dialog width rules, and sidebar-aware shell/content metrics instead of isolated screen-level overflow patches.
- New modules and major internal sub-screens must expose deep-linkable GoRouter routes so refresh, direct URL access, and browser navigation preserve the current working context.
