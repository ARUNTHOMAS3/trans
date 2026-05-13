# GEMINI.md — Zerpai ERP Project Context

> **Mandate**: Clarity Over Complexity.
> **Vision**: Exact Zoho Inventory Equivalence for Indian SMEs (Retail, Pharma, Trading).

## 🏗️ Project Overview

Zerpai ERP is a high-density, professional ERP system built for performance, offline capability, and precision. It focuses on keyboard-first POS workflows, GST/compliance handling, and multi-tenant scalability.

### 🛠️ Tech Stack

| Layer                | Technology                                                      |
| :------------------- | :-------------------------------------------------------------- |
| **Frontend**         | Flutter (Web/Android)                                           |
| **State Management** | Riverpod (`StateNotifier`, `Provider`)                          |
| **Navigation**       | GoRouter (Deep-linking mandatory with `/org_id/` prefix)        |
| **Backend**          | NestJS (TypeScript)                                             |
| **Database**         | Supabase (PostgreSQL) + Drizzle ORM                             |
| **Local Storage**    | Hive (Offline sync)                                             |
| **Styling**          | Centralized `AppTheme` tokens (Vanilla CSS approach in Flutter) |

## 📐 Architecture & Standards

### 1. "Gold Standard" Reusables

Strict adherence to `REUSABLES.md`. NEVER reinvent common widgets.

- **Form Inputs**: `CustomTextField`, `FormDropdown`, `ZerpaiDatePicker`.
- **Layout**: `ZDataTableShell`, `ZerpaiLayout`, `SettingsUsersRolesShell`.
- **Feedback**: `ZerpaiToast`, `ZTooltip`.

### 2. UI Governance

- **Surfaces**: Pure white (`#FFFFFF`) for main content areas.
- **Density**: Zoho-style high density. Row heights ~32px-40px. 14px checkboxes.
- **Colors**: Zoho Blue (`#0088FF`), Success Green (`#28A745`), Border Light (`#EEEEEE`).
- **Typography**: Inter font family. Headers often use ALL CAPS for section titles.

### 3. Navigation & Routing

- All pages must support deep-linking via `AppRoutes` and `AppRouter`.
- Routes follow the structure: `/:orgId/module/submodule`.
- Redirection logic in `app_router.dart` handles the default `_kDevOrgSystemId`.

### 4. File Naming Conventions

- Pages: `module_submodule_page.dart` (e.g., `settings_users_page.dart`).
- Controllers: `module_controller.dart`.
- Providers: `module_provider.dart`.

## 🚀 Building and Running

### Frontend (Flutter)

- **Install**: `flutter pub get`
- **Run**: `flutter run -d chrome` (Web) or `flutter run` (Android)
- **Build Runner**: `flutter pub run build_runner build --delete-conflicting-outputs`
- **Test**: `npm run test:flutter`

### Backend (NestJS)

- **Install**: `npm install` (inside `backend/`)
- **Run Dev**: `npm run start:dev`
- **Migration**: `npx drizzle-kit generate:pg`
- **Test**: `npm run test:backend`

### E2E Testing (Playwright)

- **Run**: `npm run test:e2e`

## 🛡️ Development Rules

1. **Multi-Tenancy**: Every database query on business-owned tables MUST filter by `entity_id` (FK to `organisation_branch_master.id`) using the `@Tenant('entityId')` decorator context. `organisation_branch_master` is the polymorphic entity registry: `type` = `'ORG'` or `'BRANCH'`, `ref_id` links to the actual `organization.id` or `branches.id`. Global lookup tables (`products`, `categories`, `brands`, `manufacturers`, `tax_rates`, `tax_groups`, `payment_terms`, `currencies`, `uqc`, `units`, `storage_conditions`, `buying_rules`, `drug_schedules`, `drug_strengths`, `contents`, `racks`, `shipment_preferences`, `tds_rates`, `tds_sections`, `tds_groups`, `price_lists`, `price_list_items`, `countries`, `states`, `timezones`, `gst_treatments`, `gstin_registration_types`, `business_types`, `hsn_sac_codes`, `composite_items`, `composite_item_parts`) have no `entity_id` and are shared across all tenants.
2. **Offline First**: Operations should be queued via local storage if connectivity is lost.
3. **API Consistency**: All backend responses must follow the `StandardResponseInterceptor` format (`{ data, meta }`).
4. **Security**: Protect `.env` files. Use `Supabase Service Role Key` only in backend services to bypass RLS when necessary.

---

_Last Updated: March 30, 2026_
backend/ (Full recursive access to src/ and configuration)
lib/ (Full recursive access to Flutter source)
supabase/ (For migrations)

# Project Policy

1 - Allow full read and search access to the E:/zerpai-new directory, including all subdirectories like backend/, lib/, docs/, supabase/, and PRD/.
2 - Allow write access to the backend/src/ and lib/ directories for implementing the refactor.
3 - Allow execution of npm, flutter, and prisma commands.
4 - Allow access to current schema.md and all plan/doc files in the root.
