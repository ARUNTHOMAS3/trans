# ZERPAI ERP     ” Monorepo

Modern ERP system targeting Indian SMEs (retail, pharmacy, trading). Flutter frontend (Web + Android) + NestJS backend + Supabase PostgreSQL.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart)     ” Web + Android |
| State Management | Riverpod (`flutter_riverpod`) |
| Navigation | GoRouter |
| HTTP Client | Dio |
| Offline Storage | Hive |
| Backend | NestJS (TypeScript) |
| ORM | Drizzle ORM |
| Database | Supabase (PostgreSQL) |
| File Storage | Cloudflare R2 |
| Deployment | Railway/Cloudflare Pages |

---

## Full Project Structure

```
zerpai-new/
             lib/                                  # Flutter frontend
  ‚                core/                             # App infrastructure only
  ‚     ‚                api/                          # API base config
  ‚     ‚                constants/                    # App-wide constants
  ‚     ‚                errors/                       # Error types & handling
  ‚     ‚                layout/                       # Shell / navigation infrastructure
  ‚     ‚                logging/                      # AppLogger
  ‚     ‚                models/                       # Core models (org, user session)
  ‚     ‚                pages/                        # Error page, maintenance page
  ‚     ‚                providers/                    # Core providers (org settings, branding)
  ‚     ‚                routing/                      # app_router.dart, app_routes.dart
  ‚     ‚                services/                     # Core services (auth service)
  ‚     ‚     ”         theme/                        # app_theme.dart     ” single source of truth for all tokens
  ‚     ‚
  ‚                data/                             # Legacy data layer (being migrated to modules/)
  ‚     ‚                models/
  ‚     ‚     ”         providers/
  ‚     ‚
  ‚                modules/                          # Feature modules
  ‚     ‚                accountant/                   # Accounting & journals
  ‚     ‚     ‚                manual_journals/          # Manual journal entry (create, list, detail)
  ‚     ‚     ‚     ‚                models/
  ‚     ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚                providers/
  ‚     ‚     ‚     ‚     ”         repositories/
  ‚     ‚     ‚                recurring_journals/       # Recurring journal automation
  ‚     ‚     ‚     ‚                models/
  ‚     ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚                providers/
  ‚     ‚     ‚     ‚     ”         repositories/
  ‚     ‚     ‚                models/
  ‚     ‚     ‚                presentation/
  ‚     ‚     ‚                providers/
  ‚     ‚     ‚     ”         repositories/
  ‚     ‚     ‚
  ‚     ‚                auth/                         # Login, session, token refresh
  ‚     ‚     ‚                controller/
  ‚     ‚     ‚                models/
  ‚     ‚     ‚                presentation/
  ‚     ‚     ‚                providers/
  ‚     ‚     ‚                repositories/
  ‚     ‚     ‚                services/
  ‚     ‚     ‚     ”         widgets/
  ‚     ‚     ‚
  ‚     ‚                branches/                     # Branch management
  ‚     ‚     ‚                controller/
  ‚     ‚     ‚                models/
  ‚     ‚     ‚     ”         presentation/
  ‚     ‚     ‚
  ‚     ‚                home/                         # Dashboard / home screen
  ‚     ‚     ‚                models/
  ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ”         providers/
  ‚     ‚     ‚
  ‚     ‚                inventory/                    # Inventory operations
  ‚     ‚     ‚                adjustments/              # Stock adjustments (create, edit, list, approve)
  ‚     ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚     ”         providers/
  ‚     ‚     ‚                assemblies/               # Assembly / kitting
  ‚     ‚     ‚     ‚     ”         presentation/
  ‚     ‚     ‚                move_orders/              # Inter-bin move orders
  ‚     ‚     ‚     ‚     ”         presentation/
  ‚     ‚     ‚                packages/                 # Packaging / packing
  ‚     ‚     ‚     ‚                data/
  ‚     ‚     ‚     ‚                models/
  ‚     ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚     ”         providers/
  ‚     ‚     ‚                picklists/                # Pick lists for fulfillment
  ‚     ‚     ‚     ‚                data/
  ‚     ‚     ‚     ‚                models/
  ‚     ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚     ”         providers/
  ‚     ‚     ‚                shipments/                # Outbound shipments
  ‚     ‚     ‚     ‚     ”         presentation/
  ‚     ‚     ‚                transfer_orders/          # Warehouse-to-warehouse transfers
  ‚     ‚     ‚     ‚     ”         presentation/
  ‚     ‚     ‚                models/                   # Shared inventory models (stock transfer, adjustment, etc.)
  ‚     ‚     ‚                providers/
  ‚     ‚     ‚     ”         repositories/
  ‚     ‚     ‚
  ‚     ‚                items/                        # Item / product master
  ‚     ‚     ‚                composite_items/          # BOM / composite items
  ‚     ‚     ‚     ‚                models/
  ‚     ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚     ”         providers/
  ‚     ‚     ‚                item_groups/              # Item group master
  ‚     ‚     ‚     ‚                controller/
  ‚     ‚     ‚     ‚                models/
  ‚     ‚     ‚     ‚     ”         presentation/
  ‚     ‚     ‚     ”         items/                    # Product master (create, edit, list, detail, report)
  ‚     ‚     ‚                    controllers/
  ‚     ‚     ‚                    models/
  ‚     ‚     ‚                    presentation/
  ‚     ‚     ‚         ‚                sections/         # Tab sections (overview, stock, pricing, etc.)
  ‚     ‚     ‚         ‚     ”         widgets/
  ‚     ‚     ‚                    repositories/
  ‚     ‚     ‚         ”         services/
  ‚     ‚     ‚
  ‚     ‚                mapping/                      # Account mapping / chart of accounts setup
  ‚     ‚     ‚                controller/
  ‚     ‚     ‚                models/
  ‚     ‚     ‚     ”         presentation/
  ‚     ‚     ‚
  ‚     ‚                pricelists/                   # Price list management
  ‚     ‚     ‚                branch_pricelist/         # Branch-level price overrides
  ‚     ‚     ‚     ‚                controllers/
  ‚     ‚     ‚     ‚                models/
  ‚     ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚                providers/
  ‚     ‚     ‚     ‚                repositories/
  ‚     ‚     ‚     ‚     ”         services/
  ‚     ‚     ‚     ”         pricelist/                # Global price lists
  ‚     ‚     ‚                    controllers/
  ‚     ‚     ‚                    models/
  ‚     ‚     ‚                    presentation/
  ‚     ‚     ‚                    providers/
  ‚     ‚     ‚                    repositories/
  ‚     ‚     ‚         ”         services/
  ‚     ‚     ‚
  ‚     ‚                printing/                     # Print / PDF generation
  ‚     ‚     ‚                models/
  ‚     ‚     ‚                presentation/
  ‚     ‚     ‚                repositories/
  ‚     ‚     ‚                services/
  ‚     ‚     ‚     ”         widgets/
  ‚     ‚     ‚
  ‚     ‚                purchases/                    # Purchase cycle
  ‚     ‚     ‚                bills/                    # Supplier bills / payables
  ‚     ‚     ‚     ‚                models/
  ‚     ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚                providers/
  ‚     ‚     ‚     ‚     ”         repositories/
  ‚     ‚     ‚                purchase_orders/          # Purchase orders
  ‚     ‚     ‚     ‚                models/
  ‚     ‚     ‚     ‚                notifiers/
  ‚     ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚                providers/
  ‚     ‚     ‚     ‚     ”         repositories/
  ‚     ‚     ‚                purchase_receives/        # GRN / goods receipt
  ‚     ‚     ‚     ‚                data/
  ‚     ‚     ‚     ‚                models/
  ‚     ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚                providers/
  ‚     ‚     ‚     ‚     ”         repositories/
  ‚     ‚     ‚                vendors/                  # Supplier master
  ‚     ‚     ‚     ‚                models/
  ‚     ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚                providers/
  ‚     ‚     ‚     ‚                repositories/
  ‚     ‚     ‚     ‚     ”         services/
  ‚     ‚     ‚     ”         services/
  ‚     ‚     ‚
  ‚     ‚                reports/                      # Reporting center
  ‚     ‚     ‚                controller/
  ‚     ‚     ‚                models/
  ‚     ‚     ‚                presentation/             # P&L, trial balance, ledger, sales reports, etc.
  ‚     ‚     ‚     ”         repositories/
  ‚     ‚     ‚
  ‚     ‚                sales/                        # Sales cycle
  ‚     ‚     ‚                controllers/
  ‚     ‚     ‚                models/                   # Sales order, invoice, customer models
  ‚     ‚     ‚                presentation/
  ‚     ‚     ‚     ‚                sections/
  ‚     ‚     ‚     ‚     ”         widgets/
  ‚     ‚     ‚                repositories/
  ‚     ‚     ‚     ”         services/
  ‚     ‚     ‚
  ‚     ‚     ”         settings/                     # App settings & user management
  ‚     ‚                    controller/
  ‚     ‚                    presentation/
  ‚     ‚                    providers/
  ‚     ‚                    users/                    # User management
  ‚     ‚         ‚                presentation/
  ‚     ‚         ‚     ”         providers/
  ‚     ‚         ”         users_roles/              # Roles & permissions
  ‚     ‚                        models/
  ‚     ‚             ”         providers/
  ‚     ‚
  ‚                shared/                           # Cross-feature reusables
  ‚     ‚                constants/
  ‚     ‚                mixins/                       # LicenceValidationMixin, etc.
  ‚     ‚                models/                       # Shared models (warehouse, bin, batch, etc.)
  ‚     ‚                providers/                    # Lookup providers, shared state
  ‚     ‚                responsive/                   # Breakpoints, responsive primitives
  ‚     ‚                services/                     # ApiClient, HiveService, sync/
  ‚     ‚                theme/
  ‚     ‚                utils/
  ‚     ‚     ”         widgets/                      # All reusable UI components
  ‚     ‚                    dialogs/                  # InventoryBatchBinSelectionDialog, ZerpaiConfirmationDialog, etc.
  ‚     ‚                    document/                 # ZerpaiDocumentView     ” reusable PDF/print layout
  ‚     ‚                    inputs/                   # FormDropdown, CustomTextField, ZerpaiDatePicker, ZTooltip, ZButton, etc.
  ‚     ‚                    reports/                  # Shared report table widgets
  ‚     ‚                    sections/                 # GstinPrefillBanner, shared ERP sections
  ‚     ‚                    tables/                   # ZerpaiDataTable, column customizer, etc.
  ‚     ‚                    texts/                    # Typography helpers
  ‚     ‚         ”         top_bar/                  # Page top bar / action bar
  ‚     ‚
  ‚     ”         utils/                            # Global utility functions
  ‚
             backend/                              # NestJS backend API
  ‚     ”         src/
  ‚                    common/                       # Cross-cutting concerns
  ‚         ‚                auth/                     # JWT guard, auth helpers
  ‚         ‚                decorators/               # @Tenant(), @CurrentUser()
  ‚         ‚                filters/                  # Global exception filters
  ‚         ‚                interceptors/             # Logging, transform interceptors
  ‚         ‚     ”         middleware/               # TenantMiddleware (resolves entity_id)
  ‚         ‚
  ‚                    database/                     # Drizzle schema & migrations
  ‚         ‚     ”         schema.ts                 # Source of truth for all DB tables
  ‚         ‚
  ‚                    modules/                      # Domain modules
  ‚         ‚                accountant/               # Journal entries, ledger, P&L
  ‚         ‚                branches/                 # Branch CRUD
  ‚         ‚                documents/                # Document generation
  ‚         ‚                email/                    # Email service
  ‚         ‚                gst/                      # GST lookup / GSTIN validation
  ‚         ‚                health/                   # Health check endpoint
  ‚         ‚                inventory/                # Adjustments, transfers, picklists, packages, move orders
  ‚         ‚     ‚                controllers/
  ‚         ‚     ‚     ”         services/
  ‚         ‚                lookups/                  # Master data lookups (units, tax, UQC, etc.)
  ‚         ‚                products/                 # Global product master + pricelists
  ‚         ‚     ‚                dto/
  ‚         ‚     ‚     ”         pricelists/
  ‚         ‚                purchases/                # Purchase orders, GRN, bills, vendors
  ‚         ‚     ‚                purchase-orders/
  ‚         ‚     ‚                purchase-receives/
  ‚         ‚     ‚     ”         vendors/
  ‚         ‚                redis/                    # Redis caching layer
  ‚         ‚                reports/                  # Report generation (trial balance, ledger, etc.)
  ‚         ‚                sales/                    # Sales orders, invoices, customers
  ‚         ‚                settings-zones/           # Warehouse zones & bin settings
  ‚         ‚                supabase/                 # Supabase client wrapper
  ‚         ‚                transaction-locking/      # Optimistic locking for concurrent edits
  ‚         ‚                transaction-series/       # Auto-numbering sequences (TO-xxxxx, PO-xxxxx, etc.)
  ‚         ‚                users/                    # User management & roles
  ‚         ‚     ”         warehouses-settings/      # Warehouse master, bins, racks
  ‚         ‚
  ‚                    db/                           # DB connection bootstrap
  ‚                    health/                       # Health module
  ‚                    lookups/                      # Lookup module (root level)
  ‚                    sequences/                    # Sequence helpers
  ‚                    app.module.ts
  ‚         ”         main.ts
  ‚
             PRD/                                  # Product requirements & governance
  ‚                PRD.md                            # Master PRD
  ‚                prd_schema.md                     # DB schema reference
  ‚                prd_ui.md                         # UI standards
  ‚                prd_folder_structure.md
  ‚     ”         prd_roadmap.md
  ‚
             supabase/
  ‚     ”         migrations/                       # SQL migration files
  ‚
             REUSABLES.md                          # Catalog of all shared widgets & services
             CLAUDE.md                             # AI agent governance rules
             pubspec.yaml                          # Flutter dependencies
             backend/package.json
  ”         README.md
```

---

## Architecture

```
Flutter Web / Android
        ‚
        ‚  REST (Dio)  +  X-Org-Id / X-Branch-Id / X-Entity-Id headers
        –¼
NestJS Backend            TenantMiddleware resolves entity_id
        ‚
        ‚  Drizzle ORM (type-safe queries)
        –¼
Supabase PostgreSQL            entity_id scoping on all business tables
        ‚
Cloudflare R2            file / image storage
```

---

## Sidebar Navigation (locked order)

| # | Module |
|---|---|
| 1 | Home |
| 2 | Items |
| 3 | Inventory |
| 4 | Sales |
| 5 | Accountant |
| 6 | Purchases |
| 7 | Reports |
| 8 | Documents |

---

## Multi-Tenancy

Every API request carries:

- `X-Org-Id`     ” organization system identifier
- `X-Branch-Id`     ” branch identifier (optional)
- `X-Entity-Id`     ” direct `organisation_branch_master.id` for the active scope

`TenantMiddleware` resolves `entityId` on `req.tenantContext`. All business queries filter by `entity_id`. Use `@Tenant()` or `@Tenant('entityId')` in controllers     ” never read headers manually in service methods.

**Global tables (no `entity_id`, shared across all tenants):** `products`, `categories`, `brands`, `manufacturers`, `tax_rates`, `tax_groups`, `payment_terms`, `currencies`, `uqc`, `units`, `storage_conditions`, `buying_rules`, `drug_schedules`, `drug_strengths`, `contents`, `racks`, `shipment_preferences`, `tds_rates`, `tds_sections`, `tds_groups`, `price_lists`, `price_list_items`, `countries`, `states`, `timezones`, `gst_treatments`, `gstin_registration_types`, `business_types`, `hsn_sac_codes`, `composite_items`, `composite_item_parts`.

---

## Development Setup

### Prerequisites

- Flutter SDK 3.x
- Node.js 20+
- Supabase account

### 1. Backend

```bash
cd backend
npm install
cp .env.example .env   # fill in Supabase + DB credentials
npm run start:dev      # http://localhost:3001
```

### 2. Frontend

```bash
flutter pub get
pwsh -File .\scripts\run-web.ps1
```

The launcher reads local `backend/.env` first, then `.env.local`, `.env`, and
`assets/.env` as fallbacks. It forwards only the browser-safe public values
required by Flutter Web, so developers do not retype `--dart-define` flags.

---

## Environment Variables

### Frontend build-time configuration

```env
API_BASE_URL=http://localhost:3001
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key
```

Flutter Web does not bundle or load `.env` files. Pass public client
configuration at build time; `scripts/run-web.ps1` reads ignored local
configuration and supplies the same defines without printing their values.
Never pass service-role keys, database passwords, JWT secrets, or private API
keys to the frontend.

### Backend (`backend/.env`)

```env
PORT=3001
SUPABASE_URL=your_supabase_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
DRIZZLE_DATABASE_URL=your_postgres_connection_string
DATABASE_URL=your_postgres_connection_string
```

---

## Key Reference Files

| Purpose | Path |
|---|---|
| Reusable components catalog | `REUSABLES.md` |
| AI agent governance | `CLAUDE.md` |
| Master PRD | `PRD/PRD.md` |
| DB schema | `PRD/prd_schema.md` |
| UI standards | `PRD/prd_ui.md` |
| Drizzle schema (source of truth) | `backend/src/database/schema.ts` |
| Theme tokens | `lib/core/theme/app_theme.dart` |
| Router | `lib/core/routing/app_router.dart` |
| API client | `lib/shared/services/api_client.dart` |

---

## Available Scripts

### Backend

```bash
npm run start:dev   # dev server (port 3001)
npm run build       # production build
npm run db:pull     # pull schema from Supabase
npm test            # run tests
```

### Frontend

```bash
pwsh -File .\scripts\run-web.ps1   # web dev on localhost:53431; reads ignored backend/.env first
# Optional alternate port:
pwsh -File .\scripts\run-web.ps1 -WebPort 53432
flutter build web       # production web build
flutter build apk       # Android APK
flutter test            # run tests
```

---

## License

Private     ” ZABNIX Organization

