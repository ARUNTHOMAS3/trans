# ZERPAI ERP — Project Structure

## Monorepo Layout

```
zerpai-new/
├── lib/                    # Flutter frontend
├── backend/                # NestJS backend API
├── supabase/               # Legacy SQL migrations
├── assets/                 # Fonts, images, .env
├── web/                    # Flutter web entry (index.html, manifest)
├── windows/                # Flutter Windows runner
├── test/                   # Flutter unit/widget tests
├── tests/                  # Playwright e2e tests
├── docs/                   # Architecture and flow docs
├── PRD/                    # Product requirement documents
└── pubspec.yaml            # Flutter dependencies
```

## Flutter Frontend — lib/

```
lib/
├── main.dart               # App bootstrap: Hive, Supabase, Sentry init
├── app.dart                # Root widget (ProviderScope → ZerpaiApp)
├── core/                   # App infrastructure only
│   ├── api/                # Dio HTTP client setup
│   ├── constants/          # Colors, strings, sizes, API endpoints
│   ├── errors/             # AppException, error logger
│   ├── layout/             # Shell, sidebar, navbar (ZerpaiShell)
│   ├── logging/            # AppLogger
│   ├── models/             # OrgSettingsModel
│   ├── pages/              # Settings pages (org, branches, warehouses, zones)
│   ├── providers/          # App-level providers (branding, entity, org settings)
│   ├── routing/            # GoRouter config (app_router.dart, app_routes.dart)
│   ├── services/           # Core services (env, hive, image picker, dialog, sync)
│   ├── theme/              # AppTheme, AppTextStyles
│   └── utils/              # ErrorHandler
│
├── data/                   # Cross-module data layer
│   ├── models/             # Branch, Customer, User, Vendor models
│   └── providers/          # Auth provider, Branch provider
│
├── modules/                # Feature modules (self-contained)
│   ├── accountant/         # Chart of accounts, manual/recurring journals
│   ├── auth/               # Login, forgot/reset password, RBAC permission service
│   ├── branches/           # Branch controller and presentation
│   ├── home/               # Dashboard
│   ├── inventory/          # Assemblies, picklists, packages, shipments
│   ├── items/              # Items, composite items, item groups, price lists
│   ├── mapping/            # Item mapping
│   ├── printing/           # Print templates and services
│   ├── purchases/          # Vendors, purchase orders, receives, bills
│   ├── reports/            # Report screens and repositories
│   ├── sales/              # Customers, orders, invoices, payments, e-way bills
│   └── settings/           # Users, roles management
│
├── shared/                 # Reusable cross-feature code
│   ├── constants/          # Currency, GST, phone prefix constants
│   ├── mixins/             # LicenceValidationMixin
│   ├── models/             # AccountNode (shared model)
│   ├── responsive/         # Breakpoints, responsive layout primitives
│   │   ├── breakpoints.dart        # ZpBreakpoints + DeviceSize enum
│   │   ├── responsive_context.dart
│   │   ├── responsive_dialog.dart
│   │   ├── responsive_form.dart
│   │   ├── responsive_layout.dart
│   │   └── responsive_table_shell.dart
│   ├── services/           # Shared services (lookup, draft storage, bin locations)
│   ├── theme/              # Shared text styles
│   ├── utils/              # Tax engine, formatters, date utils, toast, form helpers
│   └── widgets/            # Canonical reusable widgets
│       ├── dialogs/
│       ├── inputs/         # ZerpaiDatePicker and other inputs
│       ├── reports/
│       ├── sections/
│       ├── sidebar/
│       ├── texts/
│       ├── top_bar/
│       ├── z_button.dart
│       ├── z_data_table_shell.dart
│       └── zerpai_layout.dart
│
└── utils/                  # Root-level utilities (date, formatters, validators)
```

## NestJS Backend — backend/src/

```
backend/src/
├── main.ts                 # Bootstrap: Helmet, CORS, ValidationPipe, BullBoard
├── app.module.ts           # Root module, TenantMiddleware applied globally
├── common/
│   ├── auth/               # JWT auth module, guards, strategies
│   ├── decorators/         # Custom decorators
│   ├── filters/            # GlobalExceptionFilter
│   ├── interceptors/       # StandardResponseInterceptor
│   └── middleware/         # TenantMiddleware (X-Org-Id / X-Branch-Id / X-Entity-Id)
├── modules/
│   ├── accountant/         # Chart of accounts, journals, opening balances
│   ├── branches/           # Branch management
│   ├── documents/          # Document storage
│   ├── email/              # Resend email integration
│   ├── gst/                # GST rates and compliance
│   ├── inventory/          # Stock, adjustments, assemblies
│   ├── lookups/            # Global lookup tables
│   ├── products/           # Items, price lists
│   ├── purchases/          # Vendors, POs, bills
│   ├── redis/              # BullMQ queues, BullBoard
│   ├── reports/            # Report queries
│   ├── sales/              # Sales orders, invoices, payments
│   ├── settings-zones/     # Warehouse zones and bins
│   ├── supabase/           # Supabase client module
│   ├── transaction-locking/
│   ├── transaction-series/ # Auto-numbering sequences
│   ├── users/              # User management
│   └── warehouses-settings/
├── sequences/              # Sequence generation service
├── db/                     # Drizzle ORM schema, relations, seed scripts
└── database/               # Schema alias
```

## Database — Drizzle ORM

- Schema defined in `backend/drizzle/schema.ts` (generated) and `backend/src/db/schema.ts`
- Relations in `backend/drizzle/relations.ts` and `backend/src/db/relations.ts`
- Migrations in `backend/drizzle/` (SQL files 0002–0009)
- Legacy Supabase migrations in `supabase/legacy_migrations/`
- Config: `backend/drizzle.config.ts`

## Routing Architecture

- All app routes are prefixed with `/:orgSystemId` (10–20 digit numeric org identifier)
- GoRouter handles deep linking, auth guards, and RBAC redirects
- Route permission rules defined as `_kRoutePermissionRules` list in `app_router.dart`
- Public routes: `/login`, `/forgot-password`, `/reset-password`, `/not-found`, `/unauthorized`, `/error`, `/maintenance`
- Shell routes wrapped in `ZerpaiShell` (sidebar + navbar)

## Multi-Tenancy Model

- Every API request carries `X-Org-Id`, `X-Branch-Id` (optional), and `X-Entity-Id` (preferred) headers
- `TenantMiddleware` extracts these and resolves `entityId` on `req.tenantContext` by looking up `organisation_branch_master`
- All business tables scope data via a **single** `entity_id uuid NOT NULL` column — FK to `organisation_branch_master(id)`
- `organisation_branch_master` is the polymorphic entity registry: `type` is `'ORG'` or `'BRANCH'`, `ref_id` points to the actual `organization.id` or `branches.id`
- Use `@Tenant()` or `@Tenant('entityId')` decorator in controllers to access the resolved `TenantContext` — never read headers manually in services
- Legacy `org_id` and `outlet_id` columns exist on some tables for backward compatibility but `entity_id` is the canonical scope column for all new queries
- Entity hierarchy: Organization → Branches → Warehouses → Zones → Bins

**Global tables (no `entity_id`, shared across all tenants):**
`products`, `categories`, `brands`, `manufacturers`, `tax_rates`, `tax_groups`, `payment_terms`, `currencies`, `uqc`, `units`, `storage_conditions`, `buying_rules`, `drug_schedules`, `drug_strengths`, `contents`, `racks`, `shipment_preferences`, `tds_rates`, `tds_sections`, `tds_groups`, `price_lists`, `price_list_items`, `countries`, `states`, `timezones`, `gst_treatments`, `gstin_registration_types`, `business_types`, `hsn_sac_codes`, `composite_items`, `composite_item_parts`

## Key Architectural Patterns

- Flutter state: Riverpod providers (StateNotifier / AsyncNotifier pattern)
- Offline support: Hive boxes for all major entity types, version-bump cache clearing
- API: Dio client with base URL from env, `X-Org-Id` / `X-Branch-Id` / `X-Entity-Id` headers injected globally
- Backend responses: Wrapped in `StandardResponseInterceptor` envelope
- Error handling: `GlobalExceptionFilter` on backend; `AppException` + Sentry on frontend
- Background jobs: BullMQ queues with BullBoard admin UI at `/api/v1/admin/queues`
