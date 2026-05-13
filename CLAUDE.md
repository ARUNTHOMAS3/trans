# CLAUDE.md — Zerpai ERP

This file governs how Claude should behave when working in this repository. Read it fully before taking any action.

---

## Project Overview

**Zerpai ERP** is a monorepo ERP system targeting Indian SMEs (retail, pharmacy, trading).

| Layer            | Technology                                    |
| ---------------- | --------------------------------------------- |
| Frontend         | Flutter (Dart) — Web + Android                |
| State Management | Riverpod (`flutter_riverpod`)                 |
| Navigation       | GoRouter (`lib/core/routing/app_router.dart`) |
| HTTP Client      | Dio (`lib/shared/services/api_client.dart`)   |
| Offline Storage  | Hive (products, customers, drafts)            |
| Backend          | NestJS (TypeScript)                           |
| ORM              | Drizzle ORM                                   |
| Database         | Supabase (PostgreSQL)                         |
| File Storage     | Cloudflare R2                                 |
| Deployment       | Vercel                                        |

---

## Hard Rules — Never Break These

### Frontend

- **Riverpod only** for state. Never suggest Provider, BLoC, or GetX.
- **Dio only** for HTTP. Never use the `http` package.
- **Hive only** for offline/local data. Never use shared_preferences for data storage (UI flags only).
- **Lucide Icons** as primary icon set. FontAwesome only for brand icons.
- **`app_theme.dart` tokens only** for colors, spacing, typography. No hardcoded values ever.
- **Dialogs, modals, popup menus, dropdown overlays, calendars, and similar floating surfaces default to pure white `#FFFFFF`**. Do not rely on inherited Material tinting for these components.
- **Use `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` as the default reusable date picker** wherever the shared anchored picker pattern is applicable. Do not add new raw `showDatePicker(...)` usages for standard ERP flows unless there is a specific exception.
- **Prefer real DB-backed data and DB-backed master defaults**, keep empty/error states explicit, centralize shared UI styling, and keep warehouse/storage/accounting/physical concepts separated.
- **Keep save/create buttons, cancel/secondary actions, upload controls, and borders/dividers on centralized theme styling** instead of per-screen color picks.
- **GoRouter only** for navigation. Never use `Navigator.push` directly.
- **Every screen, sub-screen, tab, and significant dialog state must be deep-linkable** via a named GoRouter route with path/query params so browser refresh, direct URL, and back-navigation restore full context without data loss.
- **Inter font** globally. No per-module font overrides.
- **Canonical Flutter structure**:
  - `lib/core/` = app infrastructure only
  - `lib/core/layout/` = shell/navigation infrastructure only
  - `lib/shared/widgets/` = reusable UI widgets and responsive UI primitives
  - `lib/shared/services/` = cross-feature services
  - `lib/modules/` = feature-specific code
  - Never treat `lib/core/widgets/` as the reusable widget home.

### Backend

- **Drizzle ORM only**. Never suggest Prisma, TypeORM, or raw SQL outside of Drizzle.
- **NestJS only**. Never suggest Express, Fastify, Hono, GraphQL, or tRPC.
- **class-validator + class-transformer** for all DTO validation.
- **Multi-tenancy is mandatory**: every query on business-owned tables must filter by `entity_id` (FK to `organisation_branch_master.id`). Resolve `entityId` from the `@Tenant()` decorator context — use `@Tenant('entityId')` in controllers. Never read `X-Org-Id` or `X-Branch-Id` headers manually in service methods.
- **`organisation_branch_master`** is the polymorphic entity registry: `type` = `'ORG'` or `'BRANCH'`, `ref_id` → actual `organization.id` or `branches.id`. All business tables reference it via `entity_id`.
- **Exception**: global lookup tables (`products`, `categories`, `brands`, `manufacturers`, `tax_rates`, `tax_groups`, `payment_terms`, `currencies`, `uqc`, `units`, `storage_conditions`, `buying_rules`, `drug_schedules`, `drug_strengths`, `contents`, `racks`, `shipment_preferences`, `tds_rates`, `tds_sections`, `tds_groups`, `price_lists`, `price_list_items`, `countries`, `states`, `timezones`, `gst_treatments`, `gstin_registration_types`, `business_types`, `hsn_sac_codes`, `composite_items`, `composite_item_parts`) have NO `entity_id`. Never add entity_id filtering to these tables.

### Database

- Always run `npm run db:pull` before creating or altering any table.
- Source of truth for schema: `PRD/prd_schema.md` and `backend/src/database/schema.ts`.
- Table naming: `<module_name>_<table_name>` in snake_case.
- Settings-specific table naming: any new database table created for the global settings system must start with `settings_`.
- Never invent tables or columns not present in the schema.

---

## File Naming Convention (Flutter — STRICT)

Pattern: `<module>_<submodule>_<page>.dart`

Examples:

- `items_products_create.dart`
- `items_pricelist_pricelist_creation.dart`
- `sales_customers_customer_overview.dart`
- `accounts_manual_journal_create.dart`

Never deviate from this pattern.

---

## Module & Folder Structure (Flutter)

```
lib/
  core/
    routing/        # app_router.dart lives here
    theme/          # app_theme.dart lives here
    layout/         # shell/navigation infrastructure only
  shared/
    services/       # cross-feature services
    widgets/        # reusable UI components
  modules/
    home/
    items/
      items/
      composite_items/
      item_groups/
      pricelists/
    inventory/
    sales/
    accountant/
    purchases/
    reports/
    documents/
```

Each module follows: `models/`, `providers/`, `controllers/`, `repositories/`, `services/`, `presentation/pages/`, `presentation/widgets/`, `presentation/dialogs/`

---

## Sidebar Navigation (LOCKED ORDER)

1. Home
2. Items
3. Inventory
4. Sales
5. Accountant
6. Purchases
7. Reports
8. Documents

Never reorder or rename these.

---

## Backend Structure

```
backend/
  src/
    app.module.ts
    main.ts
    database/
      schema.ts       # Drizzle schema — source of truth
    common/           # middleware, guards, interceptors
    modules/          # one folder per domain module
```

Dev port: **3001**
Prod URL: `https://zabnix-backend.vercel.app`

---

## Multi-Tenancy

Every API request carries:

- `X-Org-Id` — organization system identifier (routing/auth)
- `X-Branch-Id` — branch identifier (optional, for branch-scoped sessions)
- `X-Entity-Id` — preferred header; direct `organisation_branch_master.id` for the active scope

`TenantMiddleware` intercepts all requests and resolves `entityId` on `req.tenantContext`. All business queries filter by `entity_id`. Use `@Tenant()` or `@Tenant('entityId')` in controllers instead of reading headers manually. The `products` table is the only exception (global, shared across all orgs).

---

## UI Standards

### Case Rules (MANDATORY)

| Context                                                                                                          | Case              |
| ---------------------------------------------------------------------------------------------------------------- | ----------------- |
| Page titles, section headings, sidebar items, buttons, table headers, dialog titles                              | **Title Case**    |
| Form labels, placeholder text, helper text, validation errors, table cell values, badges, tooltips, empty states | **Sentence case** |
| SKU, GSTIN, and other identifier codes                                                                           | **UPPERCASE**     |
| ALL CAPS for non-abbreviations                                                                                   | **Prohibited**    |

### Component Rules

- **Inputs**: Rectangular, 3-4px radius, thin light-gray border, ~36px height.
- **Numeric fields**: Must block non-numeric characters (alphabets, special chars).
- **Tables**: Server-side pagination, default 100 rows per page. Inline editing allowed.
- **Dropdowns**: White box with chevron. All dropdowns with selectable options use `FormDropdown<T>` from `lib/shared/widgets/inputs/dropdown_input.dart` — never `DropdownButtonFormField`. `FormDropdown` includes built-in search.
- **Buttons**: Primary green (`#22A95E`), secondary gray/outline.
- **Status indicators**: Colored text only — no pill badges.
- **Menus**: `MenuAnchor` for action menus, `FormDropdown` for form inputs.
- **Layout**: Dark sidebar (`~#2C3E50`), white cards on light-gray main canvas.
- **Tooltips**: Always use `ZTooltip` from `lib/shared/widgets/inputs/z_tooltip.dart` — never Flutter's built-in `Tooltip` widget. `ZTooltip` enforces a 220px max-width so text wraps compactly instead of rendering as a single long line. Trigger icon is `LucideIcons.helpCircle` at size 14-15. Tooltip text must be concise (1-2 short sentences max).

### Keyboard Shortcuts

- `Ctrl+S` — Save / Draft
- `Ctrl+Enter` — Publish / Save & Post
- `Esc` — Cancel (with Discard Guard if form is dirty)
- `/` — Focus Search
- `Alt+N` — New entry visual indicator

All shortcut tooltips must show the key combo (e.g., "Save (Ctrl+S)").

---

## GST & Indian Business Context

- Target market: Indian SMEs (retail, pharmacy, trading)
- GST compliance is a core requirement — invoices, bills, and reports must be GST-aware
- GSTIN codes always stored and displayed in UPPERCASE
- Fiscal year follows Indian standard (April–March)

---

## Logging

Replace all `print()` statements with `AppLogger`:

- Debug info → `AppLogger.debug(module: '...', data: ...)`
- Warnings → `AppLogger.warning(module: '...', data: ...)`
- Errors → `AppLogger.error(module: '...', data: ...)`

Never use `print()` in new or modified code.

---

## Performance Targets

- API response time: < 500ms (p95)
- Page load: < 2 seconds
- DB queries: < 200ms
- Error rate: < 0.1%

---

## Scale Limits (V1.0)

- Max products: 50,000
- Max concurrent users: 100
- Max branches for best UX: < 50

---

## Reusables — Check Before Creating

Before writing any new shared widget, mixin, service, utility, or helper:

1. **Check `REUSABLES.md`** at the project root — it catalogs every reusable component in `lib/shared/` and `lib/core/`.
2. If a suitable reusable exists, use it. Do not duplicate it.
3. If no match exists and you create something genuinely reusable, **add it to `REUSABLES.md`** immediately.
4. **Tell the user** when you find an existing reusable they could use, including which one it is, or when you create a new one so they can decide whether to promote it.

Key reusables to always check first: `FormDropdown<T>`, `CustomTextField`, `ZerpaiDatePicker`, `ZTooltip`, `GstinPrefillBanner`, `LicenceValidationMixin`, `ZerpaiLayout`, `ZButton`, `ZerpaiConfirmationDialog`, `AppTheme` tokens.

---

## What NOT to Do

- Do not suggest React, Vue, Next.js, Tailwind, or any web framework — this is a Flutter project
- Do not add `org_id` filtering to the `products` table
- Do not use Prisma, TypeORM, or raw SQL outside Drizzle
- Do not hardcode colors, spacing, or typography values
- Do not use `print()` — use `AppLogger`
- Do not invent DB tables or columns not in `PRD/prd_schema.md`
- Do not run migrations without first running `npm run db:pull`
- Do not reorder the sidebar navigation
- Do not deviate from the `module_submodule_page.dart` file naming pattern

---

## Key Reference Files

| Purpose                     | Path                                  |
| --------------------------- | ------------------------------------- |
| Reusable components catalog | `REUSABLES.md`                        |
| Master PRD                  | `PRD/PRD.md`                          |
| DB Schema                   | `PRD/prd_schema.md`                   |
| UI Standards                | `PRD/prd_ui.md`                       |
| Folder Structure            | `PRD/prd_folder_structure.md`         |
| Roadmap                     | `PRD/prd_roadmap.md`                  |
| Drizzle Schema              | `backend/src/database/schema.ts`      |
| Theme Tokens                | `lib/core/theme/app_theme.dart`       |
| Router                      | `lib/core/routing/app_router.dart`    |
| API Client                  | `lib/shared/services/api_client.dart` |
