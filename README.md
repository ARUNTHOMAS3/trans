# ZERPAI ERP â€” Monorepo

Modern ERP system targeting Indian SMEs (retail, pharmacy, trading). Flutter frontend (Web + Android) + NestJS backend + Supabase PostgreSQL.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) â€” Web + Android |
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
â”œâ”€â”€ lib/                                  # Flutter frontend
â”‚   â”œâ”€â”€ core/                             # App infrastructure only
â”‚   â”‚   â”œâ”€â”€ api/                          # API base config
â”‚   â”‚   â”œâ”€â”€ constants/                    # App-wide constants
â”‚   â”‚   â”œâ”€â”€ errors/                       # Error types & handling
â”‚   â”‚   â”œâ”€â”€ layout/                       # Shell / navigation infrastructure
â”‚   â”‚   â”œâ”€â”€ logging/                      # AppLogger
â”‚   â”‚   â”œâ”€â”€ models/                       # Core models (org, user session)
â”‚   â”‚   â”œâ”€â”€ pages/                        # Error page, maintenance page
â”‚   â”‚   â”œâ”€â”€ providers/                    # Core providers (org settings, branding)
â”‚   â”‚   â”œâ”€â”€ routing/                      # app_router.dart, app_routes.dart
â”‚   â”‚   â”œâ”€â”€ services/                     # Core services (auth service)
â”‚   â”‚   â””â”€â”€ theme/                        # app_theme.dart â€” single source of truth for all tokens
â”‚   â”‚
â”‚   â”œâ”€â”€ data/                             # Legacy data layer (being migrated to modules/)
â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â””â”€â”€ providers/
â”‚   â”‚
â”‚   â”œâ”€â”€ modules/                          # Feature modules
â”‚   â”‚   â”œâ”€â”€ accountant/                   # Accounting & journals
â”‚   â”‚   â”‚   â”œâ”€â”€ manual_journals/          # Manual journal entry (create, list, detail)
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ providers/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚   â”œâ”€â”€ recurring_journals/       # Recurring journal automation
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ providers/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”œâ”€â”€ providers/
â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ auth/                         # Login, session, token refresh
â”‚   â”‚   â”‚   â”œâ”€â”€ controller/
â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”œâ”€â”€ providers/
â”‚   â”‚   â”‚   â”œâ”€â”€ repositories/
â”‚   â”‚   â”‚   â”œâ”€â”€ services/
â”‚   â”‚   â”‚   â””â”€â”€ widgets/
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ branches/                     # Branch management
â”‚   â”‚   â”‚   â”œâ”€â”€ controller/
â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ home/                         # Dashboard / home screen
â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â””â”€â”€ providers/
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ inventory/                    # Inventory operations
â”‚   â”‚   â”‚   â”œâ”€â”€ adjustments/              # Stock adjustments (create, edit, list, approve)
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ providers/
â”‚   â”‚   â”‚   â”œâ”€â”€ assemblies/               # Assembly / kitting
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚   â”œâ”€â”€ move_orders/              # Inter-bin move orders
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚   â”œâ”€â”€ packages/                 # Packaging / packing
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ data/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ providers/
â”‚   â”‚   â”‚   â”œâ”€â”€ picklists/                # Pick lists for fulfillment
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ data/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ providers/
â”‚   â”‚   â”‚   â”œâ”€â”€ shipments/                # Outbound shipments
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚   â”œâ”€â”€ transfer_orders/          # Warehouse-to-warehouse transfers
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚   â”œâ”€â”€ models/                   # Shared inventory models (stock transfer, adjustment, etc.)
â”‚   â”‚   â”‚   â”œâ”€â”€ providers/
â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ items/                        # Item / product master
â”‚   â”‚   â”‚   â”œâ”€â”€ composite_items/          # BOM / composite items
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ providers/
â”‚   â”‚   â”‚   â”œâ”€â”€ item_groups/              # Item group master
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ controller/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚   â””â”€â”€ items/                    # Product master (create, edit, list, detail, report)
â”‚   â”‚   â”‚       â”œâ”€â”€ controllers/
â”‚   â”‚   â”‚       â”œâ”€â”€ models/
â”‚   â”‚   â”‚       â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚       â”‚   â”œâ”€â”€ sections/         # Tab sections (overview, stock, pricing, etc.)
â”‚   â”‚   â”‚       â”‚   â””â”€â”€ widgets/
â”‚   â”‚   â”‚       â”œâ”€â”€ repositories/
â”‚   â”‚   â”‚       â””â”€â”€ services/
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ mapping/                      # Account mapping / chart of accounts setup
â”‚   â”‚   â”‚   â”œâ”€â”€ controller/
â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â””â”€â”€ presentation/
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ pricelists/                   # Price list management
â”‚   â”‚   â”‚   â”œâ”€â”€ branch_pricelist/         # Branch-level price overrides
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ controllers/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ providers/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ repositories/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ services/
â”‚   â”‚   â”‚   â””â”€â”€ pricelist/                # Global price lists
â”‚   â”‚   â”‚       â”œâ”€â”€ controllers/
â”‚   â”‚   â”‚       â”œâ”€â”€ models/
â”‚   â”‚   â”‚       â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚       â”œâ”€â”€ providers/
â”‚   â”‚   â”‚       â”œâ”€â”€ repositories/
â”‚   â”‚   â”‚       â””â”€â”€ services/
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ printing/                     # Print / PDF generation
â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”œâ”€â”€ repositories/
â”‚   â”‚   â”‚   â”œâ”€â”€ services/
â”‚   â”‚   â”‚   â””â”€â”€ widgets/
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ purchases/                    # Purchase cycle
â”‚   â”‚   â”‚   â”œâ”€â”€ bills/                    # Supplier bills / payables
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ providers/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚   â”œâ”€â”€ purchase_orders/          # Purchase orders
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ notifiers/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ providers/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚   â”œâ”€â”€ purchase_receives/        # GRN / goods receipt
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ data/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ providers/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚   â”œâ”€â”€ vendors/                  # Supplier master
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ providers/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ repositories/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ services/
â”‚   â”‚   â”‚   â””â”€â”€ services/
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ reports/                      # Reporting center
â”‚   â”‚   â”‚   â”œâ”€â”€ controller/
â”‚   â”‚   â”‚   â”œâ”€â”€ models/
â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/             # P&L, trial balance, ledger, sales reports, etc.
â”‚   â”‚   â”‚   â””â”€â”€ repositories/
â”‚   â”‚   â”‚
â”‚   â”‚   â”œâ”€â”€ sales/                        # Sales cycle
â”‚   â”‚   â”‚   â”œâ”€â”€ controllers/
â”‚   â”‚   â”‚   â”œâ”€â”€ models/                   # Sales order, invoice, customer models
â”‚   â”‚   â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚   â”‚   â”‚   â”œâ”€â”€ sections/
â”‚   â”‚   â”‚   â”‚   â””â”€â”€ widgets/
â”‚   â”‚   â”‚   â”œâ”€â”€ repositories/
â”‚   â”‚   â”‚   â””â”€â”€ services/
â”‚   â”‚   â”‚
â”‚   â”‚   â””â”€â”€ settings/                     # App settings & user management
â”‚   â”‚       â”œâ”€â”€ controller/
â”‚   â”‚       â”œâ”€â”€ presentation/
â”‚   â”‚       â”œâ”€â”€ providers/
â”‚   â”‚       â”œâ”€â”€ users/                    # User management
â”‚   â”‚       â”‚   â”œâ”€â”€ presentation/
â”‚   â”‚       â”‚   â””â”€â”€ providers/
â”‚   â”‚       â””â”€â”€ users_roles/              # Roles & permissions
â”‚   â”‚           â”œâ”€â”€ models/
â”‚   â”‚           â””â”€â”€ providers/
â”‚   â”‚
â”‚   â”œâ”€â”€ shared/                           # Cross-feature reusables
â”‚   â”‚   â”œâ”€â”€ constants/
â”‚   â”‚   â”œâ”€â”€ mixins/                       # LicenceValidationMixin, etc.
â”‚   â”‚   â”œâ”€â”€ models/                       # Shared models (warehouse, bin, batch, etc.)
â”‚   â”‚   â”œâ”€â”€ providers/                    # Lookup providers, shared state
â”‚   â”‚   â”œâ”€â”€ responsive/                   # Breakpoints, responsive primitives
â”‚   â”‚   â”œâ”€â”€ services/                     # ApiClient, HiveService, sync/
â”‚   â”‚   â”œâ”€â”€ theme/
â”‚   â”‚   â”œâ”€â”€ utils/
â”‚   â”‚   â””â”€â”€ widgets/                      # All reusable UI components
â”‚   â”‚       â”œâ”€â”€ dialogs/                  # InventoryBatchBinSelectionDialog, ZerpaiConfirmationDialog, etc.
â”‚   â”‚       â”œâ”€â”€ document/                 # ZerpaiDocumentView â€” reusable PDF/print layout
â”‚   â”‚       â”œâ”€â”€ inputs/                   # FormDropdown, CustomTextField, ZerpaiDatePicker, ZTooltip, ZButton, etc.
â”‚   â”‚       â”œâ”€â”€ reports/                  # Shared report table widgets
â”‚   â”‚       â”œâ”€â”€ sections/                 # GstinPrefillBanner, shared ERP sections
â”‚   â”‚       â”œâ”€â”€ tables/                   # ZerpaiDataTable, column customizer, etc.
â”‚   â”‚       â”œâ”€â”€ texts/                    # Typography helpers
â”‚   â”‚       â””â”€â”€ top_bar/                  # Page top bar / action bar
â”‚   â”‚
â”‚   â””â”€â”€ utils/                            # Global utility functions
â”‚
â”œâ”€â”€ backend/                              # NestJS backend API
â”‚   â””â”€â”€ src/
â”‚       â”œâ”€â”€ common/                       # Cross-cutting concerns
â”‚       â”‚   â”œâ”€â”€ auth/                     # JWT guard, auth helpers
â”‚       â”‚   â”œâ”€â”€ decorators/               # @Tenant(), @CurrentUser()
â”‚       â”‚   â”œâ”€â”€ filters/                  # Global exception filters
â”‚       â”‚   â”œâ”€â”€ interceptors/             # Logging, transform interceptors
â”‚       â”‚   â””â”€â”€ middleware/               # TenantMiddleware (resolves entity_id)
â”‚       â”‚
â”‚       â”œâ”€â”€ database/                     # Drizzle schema & migrations
â”‚       â”‚   â””â”€â”€ schema.ts                 # Source of truth for all DB tables
â”‚       â”‚
â”‚       â”œâ”€â”€ modules/                      # Domain modules
â”‚       â”‚   â”œâ”€â”€ accountant/               # Journal entries, ledger, P&L
â”‚       â”‚   â”œâ”€â”€ branches/                 # Branch CRUD
â”‚       â”‚   â”œâ”€â”€ documents/                # Document generation
â”‚       â”‚   â”œâ”€â”€ email/                    # Email service
â”‚       â”‚   â”œâ”€â”€ gst/                      # GST lookup / GSTIN validation
â”‚       â”‚   â”œâ”€â”€ health/                   # Health check endpoint
â”‚       â”‚   â”œâ”€â”€ inventory/                # Adjustments, transfers, picklists, packages, move orders
â”‚       â”‚   â”‚   â”œâ”€â”€ controllers/
â”‚       â”‚   â”‚   â””â”€â”€ services/
â”‚       â”‚   â”œâ”€â”€ lookups/                  # Master data lookups (units, tax, UQC, etc.)
â”‚       â”‚   â”œâ”€â”€ products/                 # Global product master + pricelists
â”‚       â”‚   â”‚   â”œâ”€â”€ dto/
â”‚       â”‚   â”‚   â””â”€â”€ pricelists/
â”‚       â”‚   â”œâ”€â”€ purchases/                # Purchase orders, GRN, bills, vendors
â”‚       â”‚   â”‚   â”œâ”€â”€ purchase-orders/
â”‚       â”‚   â”‚   â”œâ”€â”€ purchase-receives/
â”‚       â”‚   â”‚   â””â”€â”€ vendors/
â”‚       â”‚   â”œâ”€â”€ redis/                    # Redis caching layer
â”‚       â”‚   â”œâ”€â”€ reports/                  # Report generation (trial balance, ledger, etc.)
â”‚       â”‚   â”œâ”€â”€ sales/                    # Sales orders, invoices, customers
â”‚       â”‚   â”œâ”€â”€ settings-zones/           # Warehouse zones & bin settings
â”‚       â”‚   â”œâ”€â”€ supabase/                 # Supabase client wrapper
â”‚       â”‚   â”œâ”€â”€ transaction-locking/      # Optimistic locking for concurrent edits
â”‚       â”‚   â”œâ”€â”€ transaction-series/       # Auto-numbering sequences (TO-xxxxx, PO-xxxxx, etc.)
â”‚       â”‚   â”œâ”€â”€ users/                    # User management & roles
â”‚       â”‚   â””â”€â”€ warehouses-settings/      # Warehouse master, bins, racks
â”‚       â”‚
â”‚       â”œâ”€â”€ db/                           # DB connection bootstrap
â”‚       â”œâ”€â”€ health/                       # Health module
â”‚       â”œâ”€â”€ lookups/                      # Lookup module (root level)
â”‚       â”œâ”€â”€ sequences/                    # Sequence helpers
â”‚       â”œâ”€â”€ app.module.ts
â”‚       â””â”€â”€ main.ts
â”‚
â”œâ”€â”€ PRD/                                  # Product requirements & governance
â”‚   â”œâ”€â”€ PRD.md                            # Master PRD
â”‚   â”œâ”€â”€ prd_schema.md                     # DB schema reference
â”‚   â”œâ”€â”€ prd_ui.md                         # UI standards
â”‚   â”œâ”€â”€ prd_folder_structure.md
â”‚   â””â”€â”€ prd_roadmap.md
â”‚
â”œâ”€â”€ supabase/
â”‚   â””â”€â”€ migrations/                       # SQL migration files
â”‚
â”œâ”€â”€ REUSABLES.md                          # Catalog of all shared widgets & services
â”œâ”€â”€ CLAUDE.md                             # AI agent governance rules
â”œâ”€â”€ pubspec.yaml                          # Flutter dependencies
â”œâ”€â”€ backend/package.json
â””â”€â”€ README.md
```

---

## Architecture

```
Flutter Web / Android
      â”‚
      â”‚  REST (Dio)  +  X-Org-Id / X-Branch-Id / X-Entity-Id headers
      â–¼
NestJS Backend  â”€â”€  TenantMiddleware resolves entity_id
      â”‚
      â”‚  Drizzle ORM (type-safe queries)
      â–¼
Supabase PostgreSQL  â”€â”€  entity_id scoping on all business tables
      â”‚
Cloudflare R2  â”€â”€  file / image storage
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

- `X-Org-Id` â€” organization system identifier
- `X-Branch-Id` â€” branch identifier (optional)
- `X-Entity-Id` â€” direct `organisation_branch_master.id` for the active scope

`TenantMiddleware` resolves `entityId` on `req.tenantContext`. All business queries filter by `entity_id`. Use `@Tenant()` or `@Tenant('entityId')` in controllers â€” never read headers manually in service methods.

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

Private â€” ZABNIX Organization

