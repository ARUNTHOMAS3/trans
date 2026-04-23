# ZERPAI ERP — Development Guidelines

## Flutter Frontend Patterns

### File & Directory Naming
- Files use `snake_case` throughout: `sales_order_create.dart`, `items_item_detail.dart`
- Module files are prefixed with their module path: `sales_order_model.dart`, `purchases_bills_list.dart`
- Shared widgets live in `lib/shared/widgets/` — never in `lib/core/widgets/`
- Core infrastructure (routing, theme, shell) lives in `lib/core/` only

### Widget Structure
- Screens are `StatelessWidget` or `ConsumerWidget` (Riverpod)
- Use `ConsumerWidget` / `ConsumerStatefulWidget` when reading providers
- Wrap root app in `ProviderScope`
- Floating surfaces (dialogs, dropdowns, date pickers, popovers) default to pure white `#FFFFFF` — do not rely on Material surface tinting

### Routing (GoRouter)
- All authenticated routes are nested under `/:orgSystemId` (10–20 digit numeric)
- Route names are defined as string constants in `AppRoutes` class (`app_routes.dart`)
- Use named routes for navigation: `context.goNamed(AppRoutes.salesOrders)`
- Deep-link query params are the standard for pre-filling screens: `?customerId=`, `?cloneId=`, `?fromOrderId=`, `?tab=`
- Route guards use `redirect` callbacks — check `_hasStoredModuleAction()` for RBAC
- Static routes (e.g. `/create`) must be declared BEFORE dynamic routes (e.g. `/:id`) to avoid matching conflicts
- New modules must be deep-linkable; refresh and direct URL entry must preserve context

### State Management (Riverpod)
- Providers are defined per-module in `providers/` subdirectory
- Use `AsyncNotifier` / `StateNotifier` for mutable state
- App-level providers (branding, entity, org settings) live in `lib/core/providers/`
- Cross-feature services are consumed via providers from `lib/shared/services/`

### Responsive Layout
- Always use `ZpBreakpoints` from `lib/shared/responsive/breakpoints.dart` — never hardcode pixel values
- Breakpoints: compactMobile ≤479, mobile ≤599, tablet 600–1023, desktop 1024–1439, wideDesktop ≥1440
- Use `deviceSizeOf(context)` or `deviceSizeForWidth(width)` to get current `DeviceSize`
- Use `dialogWidthForWidth(width)` for dialog sizing, `formColumnsForWidth(width)` for form grids
- Use shared responsive primitives: `responsive_form.dart`, `responsive_table_shell.dart`, `responsive_dialog.dart`
- Do not patch overflow locally — use the shared responsive foundation

### Shared Widgets
- `ZerpaiDatePicker` (`lib/shared/widgets/inputs/zerpai_date_picker.dart`) is the standard date picker — avoid direct `showDatePicker()` calls
- `ZButton` (`lib/shared/widgets/z_button.dart`) for all buttons — primary/success for save/create, neutral secondary for cancel
- `ZDataTableShell` for data tables
- `ZerpaiLayout` as the standard page wrapper
- `FormRow` for label+field pairs in forms

### Offline / Hive
- All major entity types have typed Hive boxes registered at startup in `main.dart`
- Hive adapter IDs are fixed integers (1–15) — never reuse or change them
- On version bump, all boxes except `local_drafts` are cleared
- `local_drafts` box is opened after the version-bump clear loop to preserve user-authored drafts

### Error Handling
- Use `AppException` for typed errors on the frontend
- Sentry is initialized before app launch; use `Sentry.captureException()` for unexpected errors
- Show explicit empty/error states — never invent placeholder operational values

### GST / Indian Compliance
- Use `GstConstants` from `lib/shared/constants/gst_constants.dart`
- TDS/TCS type is always one of `['TDS', 'TCS']`
- HSN/SAC search uses the shared `HsnSacSearchModal` widget
- GSTIN prefill uses `GstinPrefillUtils` from `lib/shared/utils/gstin_prefill_utils.dart`

---

## NestJS Backend Patterns

### Module Structure
- Each feature is a NestJS module: `module.ts`, `controller.ts`, `service.ts`
- All modules are registered in `AppModule` (`src/app.module.ts`)
- `TenantMiddleware` is applied globally via `AppModule.configure()` — never skip it

### Multi-Tenancy
- `entity_id uuid NOT NULL` (FK to `organisation_branch_master.id`) is the **single canonical tenant scope column** on all business tables — use it for all query filters
- Never filter by `org_id` or `outlet_id` alone in new code; those legacy columns exist on some tables for backward compatibility only
- Tenant context is resolved by `TenantMiddleware` from `X-Org-Id`, `X-Branch-Id`, or `X-Entity-Id` request headers
- Access resolved context in controllers via `@Tenant()` or `@Tenant('entityId')` decorator — never read headers manually in service methods
- `organisation_branch_master` is the polymorphic entity registry: `type` = `'ORG'` or `'BRANCH'`, `ref_id` → actual `organization.id` or `branches.id`

### API Conventions
- Global prefix: `/api/v1`
- All responses are wrapped by `StandardResponseInterceptor`: `{ data, message, statusCode }`
- Validation uses `ValidationPipe` with `whitelist: true`, `forbidNonWhitelisted: true`, `transform: true`
- DTOs use `class-validator` decorators (`@IsString()`, `@IsUUID()`, `@IsOptional()`, etc.)
- Use `@nestjs/mapped-types` `PartialType` / `OmitType` for update DTOs

### Drizzle ORM
- Schema source of truth: `backend/drizzle/schema.ts` (generated) — do not hand-edit
- Working schema for queries: `backend/src/db/schema.ts`
- Relations defined in `backend/drizzle/relations.ts` using `relations()` from `drizzle-orm/relations`
- Relation naming convention for ambiguous FKs: `tableName_columnName_referencedTable_id` (e.g. `products_inventoryAccountId_accounts_id`)
- Self-referential relations use `relationName` to disambiguate (e.g. `categories_parentId_categories_id`)
- Seeding uses `db.insert(table).values(item).onConflictDoNothing()` — never destructive resets

### Database Schema Conventions
- All PKs are `uuid().defaultRandom().primaryKey()`
- **Tenant scope**: `entity_id uuid NOT NULL` FK to `organisation_branch_master(id)` is the single canonical scope column on all business tables
- Legacy `org_id` and `outlet_id` columns exist on some tables for backward compatibility — do not use them as the primary filter in new queries
- `organisation_branch_master`: `id` is the entity PK; `ref_id` links to `organization.id` or `branches.id`; `type` is `'ORG'` or `'BRANCH'`
- Monetary fields: `numeric({ precision: 15, scale: 2 })` with `.default('0.00')`
- Quantity fields: `numeric({ precision: 15, scale: 3 })` with `.default('0.000')`
- Timestamps: `timestamp("created_at", { withTimezone: true, mode: 'string' }).defaultNow()`
- Enum constraints use `check()` with SQL `ANY (ARRAY[...])` pattern
- Indexes use `index("idx_tablename_columns").using("btree", ...)`
- Unique constraints use `unique("tablename_column_key").on(table.column)`

### Security
- Helmet is enabled by default (CSP disabled to avoid blocking Flutter web)
- CORS origins are configurable via `CORS_ORIGINS` env var (comma-separated)
- JWT auth via `@nestjs/passport` + `passport-jwt`; auth can be toggled via `ENABLE_AUTH` env var
- Never expose service role keys to the frontend

### Background Jobs
- BullMQ queues managed via `RedisModule`
- BullBoard admin UI at `/api/v1/admin/queues` (toggleable via `ENABLE_BULL_BOARD`)
- Scheduled tasks use `@nestjs/schedule` `@Cron()` decorator

---

## Database / Migration Patterns

- Prefer additive migrations — never drop columns or tables in shared environments
- Use `INSERT ... ON CONFLICT DO NOTHING` (or `DO UPDATE`) for seed data
- Keep warehouse/location master data, accounting stock, and physical stock logically separate
- Lookup/master tables (UQC, currencies, GST treatments, etc.) are global — no `entity_id`, seeded once and referenced by FK
- `organisation_branch_master` is the polymorphic entity table — both orgs and branches resolve through it via `ref_id`
- When adding a new business table, always include `entity_id uuid NOT NULL REFERENCES organisation_branch_master(id)` as the tenant scope column

---

## General Code Quality

- Minimal comments — make code self-documenting through clear naming
- No hardcoded IDs or visible labels for DB-backed masters; resolve from DB rows
- No dummy/placeholder values in active ERP flows — show explicit empty/error states
- Keep button styling consistent: primary actions use approved primary/success tokens, cancel uses neutral secondary
- Borders and dividers use approved light border tokens — do not invent local color values
