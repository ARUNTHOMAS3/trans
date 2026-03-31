# GEMINI.md — Zerpai ERP Project Context

> **Mandate**: Clarity Over Complexity.
> **Vision**: Exact Zoho Inventory Equivalence for Indian SMEs (Retail, Pharma, Trading).

## 🏗️ Project Overview
Zerpai ERP is a high-density, professional ERP system built for performance, offline capability, and precision. It focuses on keyboard-first POS workflows, GST/compliance handling, and multi-tenant scalability.

### 🛠️ Tech Stack
| Layer | Technology |
| :--- | :--- |
| **Frontend** | Flutter (Web/Android) |
| **State Management** | Riverpod (`StateNotifier`, `Provider`) |
| **Navigation** | GoRouter (Deep-linking mandatory with `/org_id/` prefix) |
| **Backend** | NestJS (TypeScript) |
| **Database** | Supabase (PostgreSQL) + Drizzle ORM |
| **Local Storage** | Hive (Offline sync) |
| **Styling** | Centralized `AppTheme` tokens (Vanilla CSS approach in Flutter) |

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
1. **Multi-Tenancy**: Every database query MUST filter by `org_id` or `outlet_id`, except for the global `products` table.
2. **Offline First**: Operations should be queued via local storage if connectivity is lost.
3. **API Consistency**: All backend responses must follow the `StandardResponseInterceptor` format (`{ data, meta }`).
4. **Security**: Protect `.env` files. Use `Supabase Service Role Key` only in backend services to bypass RLS when necessary.

---
*Last Updated: March 30, 2026*
