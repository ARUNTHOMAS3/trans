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
