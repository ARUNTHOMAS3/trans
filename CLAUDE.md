# CLAUDE.md — Zerpai ERP

This file governs how Claude should behave when working in this repository. Read it fully before taking any action.

---

## Project Overview

**Zerpai ERP** is a monorepo ERP system targeting Indian SMEs (retail, pharmacy, trading).

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart) — Web + Android |
| State Management | Riverpod (`flutter_riverpod`) |
| Navigation | GoRouter (`lib/core/routing/app_router.dart`) |
| HTTP Client | Dio (`lib/shared/services/api_client.dart`) |
| Offline Storage | Hive (products, customers, drafts) |
| Backend | NestJS (TypeScript) |
| ORM | Drizzle ORM |
| Database | Supabase (PostgreSQL) |
| File Storage | Cloudflare R2 |
| Deployment | Vercel |

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
- **GoRouter only** for navigation. Never use Navigator.push directly.
- **Inter font** globally. No per-module font overrides.

### Backend
- **Drizzle ORM only**. Never suggest Prisma, TypeORM, or raw SQL outside of Drizzle.
- **NestJS only**. Never suggest Express, Fastify, Hono, GraphQL, or tRPC.
- **class-validator + class-transformer** for all DTO validation.
- **Multi-tenancy is mandatory**: every query on business-owned tables must filter by `org_id` via `X-Org-Id` header.
- **Exception**: `products` table is GLOBAL — it has no `org_id`. Never add org_id filtering to products queries.

### Database
- Always run `npm run db:pull` before creating or altering any table.
- Source of truth for schema: `PRD/prd_schema.md` and `backend/src/database/schema.ts`.
- Table naming: `<module_name>_<table_name>` in snake_case.
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
  shared/
    services/       # api_client.dart (Dio)
    widgets/        # reusable components
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
- `X-Org-Id` — organization identifier
- `X-Outlet-Id` — outlet/branch identifier

Tenant middleware intercepts all requests. All business queries filter by `org_id`. The `products` table is the only exception (global, shared across all orgs).

---

## UI Standards

### Case Rules (MANDATORY)
| Context | Case |
|---------|------|
| Page titles, section headings, sidebar items, buttons, table headers, dialog titles | **Title Case** |
| Form labels, placeholder text, helper text, validation errors, table cell values, badges, tooltips, empty states | **Sentence case** |
| SKU, GSTIN, and other identifier codes | **UPPERCASE** |
| ALL CAPS for non-abbreviations | **Prohibited** |

### Component Rules
- **Inputs**: Rectangular, 3-4px radius, thin light-gray border, ~36px height.
- **Numeric fields**: Must block non-numeric characters (alphabets, special chars).
- **Tables**: Server-side pagination, default 100 rows per page. Inline editing allowed.
- **Dropdowns**: White box with chevron. Searchable variants use a lookup button.
- **Buttons**: Primary green (`#22A95E`), secondary gray/outline.
- **Status indicators**: Colored text only — no pill badges.
- **Menus**: `MenuAnchor` for action menus, `FormDropdown` for form inputs.
- **Layout**: Dark sidebar (`~#2C3E50`), white cards on light-gray main canvas.

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
- Max outlets for best UX: < 50

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

| Purpose | Path |
|---------|------|
| Master PRD | `PRD/PRD.md` |
| DB Schema | `PRD/prd_schema.md` |
| UI Standards | `PRD/prd_ui.md` |
| Folder Structure | `PRD/prd_folder_structure.md` |
| Roadmap | `PRD/prd_roadmap.md` |
| Drizzle Schema | `backend/src/database/schema.ts` |
| Theme Tokens | `lib/core/theme/app_theme.dart` |
| Router | `lib/core/routing/app_router.dart` |
| API Client | `lib/shared/services/api_client.dart` |
