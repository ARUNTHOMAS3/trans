# ZERPAI ERP - Monorepo

Modern ERP system with Flutter frontend and NestJS backend.

## 📁 Monorepo Structure

```
zerpai_erp/
├── lib/                    # Flutter Frontend (Web + Android)
│   ├── core/               # Core utilities, API client
│   ├── data/               # Models, repositories
│   ├── modules/            # Feature modules
│   └── shared/             # Shared widgets, services
│
├── backend/                # NestJS Backend API
│   ├── src/
│   │   ├── products/       # Products module
│   │   ├── supabase/       # Supabase client
│   │   ├── common/         # Middleware (multi-tenant)
│   │   └── main.ts
│   └── package.json
│
├── supabase/               # Database
│   └── migrations/         # SQL migrations
│
├── pubspec.yaml            # Flutter dependencies
└── README.md
```

## 🚀 Tech Stack

- **Frontend**: Flutter (Web + Android), Riverpod, Dio
- **Backend**: NestJS, TypeScript, Supabase Client
- **Database**: Supabase (PostgreSQL) + Auth + Storage
- **Multi-tenancy**: entity_id scoping via `organisation_branch_master`

## 🎨 UI Surface Rule

- Dialogs, popup menus, dropdown overlays, date pickers, popovers, and similar floating surfaces must default to pure white `#FFFFFF`.
- Do not rely on inherited Material surface tinting for these components unless a design exception is explicitly requested.

## 🧱 Canonical Flutter Structure Rule

- `lib/core/` is for app infrastructure only: routing, theme, logging, shell layout, and bootstrap concerns.
- `lib/core/layout/` is only for app shell/navigation infrastructure such as sidebar, navbar, and shell metrics.
- `lib/shared/widgets/` is the canonical home for reusable widgets, dialogs, inputs, page wrappers, and responsive UI primitives.
- `lib/shared/services/` is the canonical home for cross-feature services consumed by modules and repositories.
- `lib/modules/` remains the home for feature-specific code.
- Do not use `lib/core/widgets/` as the reusable widget home.

## 📅 Shared Date Picker Rule

- Use `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart` as the standard reusable date picker across the app wherever the shared anchored picker pattern is feasible.
- Avoid new direct `showDatePicker(...)` usage for standard ERP date fields unless there is a documented reason the shared picker cannot be used.

## 🌐 Global Settings Rules

- Use real DB-backed runtime data wherever a schema-backed source exists; do not depend on dummy or demo values in active ERP flows.
- If real data is missing, show explicit empty/error states rather than inventing placeholder operational values.
- Resolve lookup defaults from DB-backed master rows where schema-backed masters exist instead of hardcoding IDs or visible labels.
- Reuse shared controls and centralized style sources for common ERP patterns instead of rebuilding local one-off variants.
- Use the shared responsive foundation for Flutter web layouts: global breakpoints, shared responsive table shells, shared responsive form rows/grids, shared responsive dialog width rules, and sidebar-aware shell/content metrics.
- New modules and major internal sub-screens must be deep-linkable through GoRouter so refresh, direct URL entry, and browser history preserve working context.
- Keep warehouse master data, storage/location master data, accounting stock, and physical stock logically separate.
- Prefer additive migrations and `INSERT ... ON CONFLICT DO UPDATE` style seeding over destructive resets in shared environments.
- Keep button and control styling consistent: primary save/create/confirm actions use the approved primary/success button styling, cancel/secondary actions use neutral secondary styling, upload controls follow the shared upload pattern, and borders/dividers use the approved light border tokens.

## 📐 Responsive Foundation Rule

- Flutter web layouts must use the shared responsive foundation instead of screen-local overflow patches.
- Foundation pieces:
  - global breakpoints in `lib/shared/responsive/breakpoints.dart`
  - shared responsive table shell for dense/wide tables
  - shared responsive form row/grid primitives for labels and fields
  - shared responsive dialog width rules
  - sidebar-aware shell/content metrics from the core layout layer

## 🛠️ Development Setup

### Prerequisites

- Flutter SDK 3.x
- Node.js 20+
- Supabase account

### 1. Database Setup

Run the migration in Supabase dashboard:

```bash
# Copy contents of: supabase/migrations/001_initial_schema_and_seed.sql
# Paste in: Supabase Dashboard → SQL Editor → New Query
```

### 2. Backend Setup

```bash
cd backend
npm install
npm run start:dev  # Runs on http://localhost:3001
```

### 3. Frontend Setup

```bash
flutter pub get
flutter run -d chrome
```

## 🌐 Environment Variables

### Frontend (.env)

```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
API_BASE_URL=http://localhost:3001
```

### Backend (backend/.env)

```env
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
PORT=3001
```

## 📊 Architecture

```
Flutter App
    ↓ REST API (dio)
NestJS Backend (Multi-tenant middleware)
    ↓ SQL Queries
Supabase PostgreSQL (RLS enabled)
```

## 🔒 Multi-Tenancy

Every request includes:

- `X-Org-Id` header (organization system ID, for routing/auth)
- `X-Branch-Id` header (branch identifier, optional)
- `X-Entity-Id` header (preferred — direct `organisation_branch_master.id`)

All business tables scope data through a single `entity_id uuid NOT NULL` column that is a FK to `organisation_branch_master(id)`. The `organisation_branch_master` table is the polymorphic entity registry — both orgs and branches resolve through it via `ref_id`. Use the `@Tenant()` decorator in controllers to access the resolved `TenantContext`.

**Global tables (no `entity_id`, shared across all tenants):** `products`, `categories`, `brands`, `manufacturers`, `tax_rates`, `tax_groups`, `payment_terms`, `currencies`, `uqc`, `units`, `storage_conditions`, `buying_rules`, `drug_schedules`, `drug_strengths`, `contents`, `racks`, `shipment_preferences`, `tds_rates`, `tds_sections`, `tds_groups`, `price_lists`, `price_list_items`, `countries`, `states`, `timezones`, `gst_treatments`, `gstin_registration_types`, `business_types`, `hsn_sac_codes`, `composite_items`, `composite_item_parts`.

## 📦 Available Scripts

### Backend

- `npm run start:dev` - Development mode
- `npm run build` - Production build
- `npm test` - Run tests

### Frontend

- `flutter run` - Run app
- `flutter build web` - Build for web
- `flutter test` - Run tests

## 🤝 Contributing

1. Create feature branch from `main`
2. Make changes
3. Test locally
4. Create pull request

## 📝 License

Private - ZABNIX Organization
