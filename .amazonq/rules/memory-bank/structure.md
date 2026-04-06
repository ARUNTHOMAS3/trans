# Zerpai ERP — Project Structure

## Monorepo Layout

```
zerpai-new/
├── lib/                    # Flutter frontend (Web + Android)
├── backend/                # NestJS backend API
├── supabase/migrations/    # PostgreSQL DDL migrations
├── assets/                 # Fonts, images, lottie, .env
├── web/                    # Flutter web shell (index.html, manifest)
├── test/                   # Flutter unit/widget tests
├── tests/e2e/              # Playwright end-to-end tests
├── PRD/                    # Product requirement documents
├── docs/                   # Flow diagrams and recovery notes
└── pubspec.yaml / backend/package.json
```

## Flutter Frontend (`lib/`)

```
lib/
├── main.dart               # App entry point, Hive + Riverpod bootstrap
├── app.dart                # MaterialApp + GoRouter wiring
├── core/                   # App infrastructure ONLY
│   ├── api/dio_client.dart             # Raw Dio instance
│   ├── constants/                      # api_endpoints, app_colors, sizes
│   ├── errors/                         # AppException, error_logger
│   ├── layout/                         # ZerpaiShell, ZerpaiSidebar, ZerpaiNavbar, shell_metrics
│   ├── logging/app_logger.dart
│   ├── models/org_settings_model.dart
│   ├── pages/                          # Settings pages (routed via GoRouter)
│   ├── providers/                      # org_settings_provider, app_branding_provider
│   ├── routing/app_router.dart         # GoRouter definition (all routes)
│   ├── routing/app_routes.dart         # Named route constants
│   ├── services/                       # api_client, hive_service, env_service, dialog_service
│   └── theme/app_theme.dart            # Centralized design system (colors, typography, spacing)
│
├── shared/                 # Reusable cross-feature code
│   ├── responsive/         # breakpoints, responsive_layout, responsive_form, responsive_dialog, responsive_table_shell
│   ├── services/           # api_client (canonical), lookup_service, draft_storage, sync/, storage_service
│   ├── theme/              # app_text_styles, text_styles
│   ├── utils/              # tax_engine, app_date_formatter, zerpai_toast, error_handler, report_utils
│   └── widgets/
│       ├── inputs/         # ZerpaiDatePicker, TextInput, DropdownInput, CategoryDropdown, ZSearchField, etc.
│       ├── dialogs/        # ZerpaiConfirmationDialog, UnsavedChangesDialog
│       ├── reports/        # ZerpaiReportShell
│       ├── top_bar/        # TopBar
│       ├── z_button.dart, z_data_table_shell.dart, z_row_actions.dart
│       ├── form_row.dart, zerpai_layout.dart, skeleton.dart
│       └── placeholder_screen.dart
│
├── modules/                # Feature-specific code
│   ├── accountant/         # Manual journals, recurring journals, chart of accounts, opening balances, transaction locking
│   ├── auth/               # Login, forgot password, user management (not wired to routing yet)
│   ├── branches/           # Branch create/list
│   ├── home/               # Dashboard overview
│   ├── inventory/          # Assemblies, picklists, packages, adjustments, transfers
│   ├── items/              # Items, composite items, item groups, price lists
│   ├── mapping/            # Item mapping
│   ├── printing/           # Print templates
│   ├── purchases/          # Vendors, purchase orders, purchase receives, bills
│   ├── reports/            # All report screens
│   ├── sales/              # Customers, orders, invoices, payments, challans, credit notes, e-way bills
│   └── settings/           # Settings overview, users, roles
│
└── utils/                  # Root-level utilities (date_utils, formatters, price_utils, validators)
```

### Module Internal Structure (canonical pattern)
```
modules/<module>/<sub-feature>/
├── models/         # Data classes / Freezed models
├── presentation/   # Screen widgets (naming: module_submodule_page.dart)
├── providers/      # Riverpod providers / notifiers
├── repositories/   # API + Hive data access
├── services/       # Business logic services
└── controllers/    # (some modules) ChangeNotifier controllers
```

## NestJS Backend (`backend/src/`)

```
backend/src/
├── main.ts                 # Bootstrap, CORS, global pipes/filters
├── app.module.ts           # Root module
├── common/
│   ├── auth/               # Auth module (JWT-ready, not enforced)
│   ├── filters/            # GlobalExceptionFilter
│   ├── interceptors/       # AuditInterceptor, StandardResponseInterceptor
│   └── middleware/         # TenantMiddleware (injects org_id/outlet_id)
├── db/
│   ├── schema.ts           # Drizzle table definitions (source of truth)
│   ├── relations.ts        # Drizzle relations
│   ├── db.ts               # Drizzle client instance
│   └── seed_uqc.ts         # UQC seed script
├── modules/
│   ├── products/           # Products CRUD + pricelist sub-module
│   ├── sales/              # Customers, sales orders, invoices, HSN/SAC
│   ├── purchases/          # Vendors, purchase orders, purchase receives
│   ├── inventory/          # Picklists, inventory service
│   ├── accountant/         # Manual journals, recurring journals, R2 storage, cron
│   ├── branches/           # Branches CRUD
│   ├── warehouses-settings/# Warehouse settings
│   ├── outlets/            # Outlets CRUD
│   ├── users/              # Users CRUD
│   ├── reports/            # Reports service + controller
│   ├── gst/                # GST service
│   ├── transaction-locking/# Transaction locking
│   ├── transaction-series/ # Document number sequences
│   └── supabase/           # Supabase client wrapper
├── currencies/             # Currencies module
├── lookups/                # Global + module lookups
├── sequences/              # Sequence generation
└── health/                 # Health check endpoint
```

## Database (`supabase/migrations/`)

- Numbered SQL migration files (001–1019+)
- Tables follow `<module>_<table_name>` prefix convention for new tables
- `settings_*` prefix mandatory for settings-owned tables
- RLS policies exist but are disabled for dev (`999_disable_rls_for_testing.sql`)
- `products` table is global (no `org_id`); all transactional tables have `org_id`

## Routing Architecture

- All app routes live under `/:orgSystemId/` prefix
- Dev hardcodes `orgSystemId = '0000000000'`
- GoRouter ShellRoute wraps all module routes inside `ZerpaiShell` (sidebar + navbar)
- Error/maintenance routes are outside the shell
- All list/detail screens support deep-linking with query params (`?q=`, `?filter=`, `?tab=`, `?customerId=`, etc.)

## Key Architectural Patterns

1. **Repository pattern** — each feature has a repository abstracting Dio API calls + Hive cache
2. **Riverpod providers** — all state via `flutter_riverpod`; `AsyncNotifier` / `StateNotifier` patterns
3. **Shared API client** — `lib/shared/services/api_client.dart` is the canonical Dio wrapper; auto-selects prod vs dev URL
4. **Multi-tenant middleware** — NestJS `TenantMiddleware` reads `X-Org-Id` / `X-Outlet-Id` headers
5. **Audit interceptor** — NestJS `AuditInterceptor` logs mutations using `ROUTE_TABLE_MAP`
6. **Drizzle ORM** — backend uses Drizzle for type-safe queries; `backend/drizzle/schema.ts` is the generated snapshot
7. **Offline-first** — Hive boxes cache entities; `shared_preferences` for config only
