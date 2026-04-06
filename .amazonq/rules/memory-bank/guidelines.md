# Zerpai ERP — Development Guidelines

## 1. Flutter Code Patterns

### File Naming (STRICT)
- Feature screens: `module_submodule_page.dart` (e.g., `sales_orders_order_creation.dart`, `items_pricelist_pricelist_creation.dart`)
- No `_screen` suffix unless required for clarity
- Root files (`main.dart`, `app.dart`) are exempt
- All files: `snake_case.dart`

### Widget Architecture
- All screens are `StatelessWidget` consuming Riverpod providers
- Named constructors for semantic variants:
  ```dart
  const ZButton.primary({required this.label, required this.onPressed, this.loading = false});
  const ZButton.secondary({required this.label, required this.onPressed});
  ```
- Use `ZButton.primary` for save/create/confirm; `ZButton.secondary` for cancel/back
- Never use raw `ElevatedButton` or `OutlinedButton` directly in feature screens — use `ZButton`

### Theme Usage (MANDATORY)
- All colors from `AppTheme.*` — never hardcode hex values in widgets
- All spacing from `AppTheme.space*` constants (4, 8, 12, 16, 24, 32)
- All text styles from `AppTheme.*` getters (`pageTitle`, `sectionHeader`, `tableHeader`, `tableCell`, `metaHelper`)
- Dialogs, popups, dropdowns: `backgroundColor: AppTheme.backgroundColor` (pure white `#FFFFFF`)
- Border radius: always `BorderRadius.circular(4)` (4px per PRD)

### Responsive Layout
- Use `ZpBreakpoints` from `lib/shared/responsive/breakpoints.dart` for all breakpoint checks
- Use `deviceSizeOf(context)` / `isDesktopWidth(width)` helpers — never raw `MediaQuery` comparisons
- Use `dialogWidthForWidth(width)` for dialog sizing
- Use `formColumnsForWidth(width)` for form grid columns
- Use `ResponsiveFormRow`, `ResponsiveLayout`, `ResponsiveTableShell` from `lib/shared/responsive/`
- Never use fixed pixel widths for major layout regions; use `Expanded`/`Flexible`/`LayoutBuilder`

### Layout Safety Rules
- Any growing child in `Row`/`Column` must be wrapped in `Expanded` or `Flexible`
- Never place `Expanded` inside `SingleChildScrollView` in the same axis
- All API/DB text must define `maxLines` and `overflow: TextOverflow.ellipsis`
- Preferred hierarchy: `Scaffold → Column → Expanded → Row → Expanded → Scrollable`

### State Management (Riverpod)
- All state via `flutter_riverpod` — no `setState` in feature screens
- Use `AsyncNotifier` for async data, `StateNotifier` for complex state
- Providers live in `modules/<module>/<sub>/providers/` or `modules/<module>/providers/`
- Access via `ref.watch` (reactive) or `ref.read` (one-shot in callbacks)

### Navigation (GoRouter)
- All navigation via `context.go(AppRoutes.xxx)` or `context.push(AppRoutes.xxx)`
- Named routes defined in `AppRoutes` constants (`lib/core/routing/app_routes.dart`)
- Deep-link query params: `?q=`, `?filter=`, `?tab=`, `?customerId=`, `?cloneId=`, `?fromOrderId=`
- Pass objects via `extra` parameter for in-memory navigation; use IDs for deep-linkable routes

### API Calls
- Use `ApiClient` from `lib/shared/services/api_client.dart` (singleton, auto-selects URL)
- Access via `ref.watch(apiClientProvider)` or `ref.watch(dioProvider)`
- Never use `http` package — Dio only
- POST/PUT/PATCH/DELETE automatically invalidate cache for the resource path
- GET uses 30-second in-memory cache; pass `useCache: false` to force refresh

### Date Picker
- Use `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart`
- Never call `showDatePicker(...)` directly for standard ERP date fields

### Shared Inputs
- `TextInput` / `CustomTextField` for text fields
- `DropdownInput` for dropdowns
- `CategoryDropdown` for category selection
- `ZSearchField` for search inputs
- `ZerpaiDatePicker` for dates
- `FileUploadButton` for file uploads
- `FieldLabel` for form labels

### Offline / Local Storage
- `Hive` for entity caching (items, customers, POS drafts)
- `shared_preferences` for config-only (UI flags, theme, last selected outlet)
- Never use `shared_preferences` for entity data

---

## 2. NestJS Backend Patterns

### Module Structure
Each module follows: `controller.ts` → `service.ts` → `module.ts`
Sub-features get their own subdirectory: `purchase-orders/controllers/`, `purchase-orders/services/`, `purchase-orders/dto/`

### Dependency Injection
```typescript
@Injectable()
export class ProductsService {
  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly r2StorageService: R2StorageService,
  ) {}
}
```

### Supabase Query Pattern
```typescript
const supabase = this.supabaseService.getClient();
const { data, error } = await supabase
  .from('table_name')
  .select('col1, col2, relation:other_table(id, name)')
  .eq('org_id', orgId)
  .eq('is_active', true)
  .order('created_at', { ascending: false });

if (error) throw new Error(error.message);
return data;
```

### UUID Sanitization (MANDATORY for all FK fields)
Always sanitize UUID fields before insert/update:
```typescript
private cleanUuid(value: any): string | null {
  if (!value || typeof value !== 'string') return null;
  const trimmed = value.trim();
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(trimmed) ? trimmed : null;
}
```

### Scope Resolution Pattern
```typescript
private resolveScope(orgId?: string | null, outletId?: string | null) {
  return {
    orgId: this.cleanUuid(orgId) ?? this.defaultOrgId,
    outletId: this.cleanUuid(outletId),
  };
}
```

### Soft Delete (MANDATORY)
Never hard-delete records. Always soft-delete:
```typescript
await supabase.from('table').update({ is_active: false }).eq('id', id);
```

### Upsert / Seeding Pattern
Use `onConflictDoNothing()` or `ON CONFLICT DO UPDATE` for idempotent seeding:
```typescript
await db.insert(uqc).values(item).onConflictDoNothing();
```

### Error Handling
- Use NestJS exceptions: `NotFoundException`, `BadRequestException`, `ConflictException`
- Unique constraint (code `23505`) → `ConflictException` with field-specific message
- Always include `error.message`, `error.details`, `error.hint` in thrown messages for frontend parsing

### Pagination
All list endpoints must support `limit` and `offset` query params:
```typescript
async findAll(limit?: number, offset?: number) {
  let query = supabase.from('products').select('*').order('created_at', { ascending: false });
  if (limit !== undefined) query = query.limit(limit);
  if (offset !== undefined) query = query.range(offset, offset + (limit ?? 100) - 1);
}
```
Default limit: 100. Page size options: 10, 25, 50, 100, 200.

### Multi-Tenant Scoping
Every org-scoped query must filter by `org_id`. Outlet-scoped queries also filter by `outlet_id`.
The `TenantMiddleware` injects `X-Org-Id` and `X-Outlet-Id` headers — read from `request.headers`.

### Audit Interceptor
The `AuditInterceptor` uses `ROUTE_TABLE_MAP` to pre-fetch old values before mutations.
When adding new routes, update `ROUTE_TABLE_MAP` with the correct table name (using the `<module>_<table>` prefix convention).

---

## 3. Database Patterns

### Table Naming (MANDATORY for new tables)
- Format: `<module_name>_<table_name>` (snake_case)
- Settings tables: always `settings_*` prefix
- Examples: `purchases_purchase_orders`, `accounts_manual_journals`, `settings_branches`
- Do NOT rename existing tables

### Schema Rules
- Every business-owned table must have `org_id uuid NOT NULL`
- Outlet-scoped tables must also have `outlet_id uuid`
- `products` table is global — no `org_id`
- All tables need `created_at`, `updated_at`, `created_by_id`, `updated_by_id`, `is_active`
- Primary keys: UUID type

### Migration Policy
- Always run `npm run db:pull` before creating or altering tables
- Use additive migrations only — never destructive resets in shared environments
- If a table exists in DB but not in schema snapshot, assume it was created by another developer — do NOT delete it
- Seeding: use `INSERT ... ON CONFLICT DO NOTHING` or `ON CONFLICT DO UPDATE`

### Drizzle Relations
- All relations defined in `backend/drizzle/relations.ts` (generated snapshot)
- Use `relationName` for disambiguating multiple FK references to the same table:
  ```typescript
  account_inventoryAccountId: one(accounts, {
    fields: [products.inventoryAccountId],
    references: [accounts.id],
    relationName: "products_inventoryAccountId_accounts_id"
  })
  ```

---

## 4. UI/UX Standards

### Text Case Rules
| Element | Case |
|---|---|
| Page/screen titles, section headings, sidebar items, buttons, table headers, dialog titles | Title Case |
| Form labels, placeholder text, helper text, validation errors, toasts, status badges, dialog body | Sentence case |
| User-entered data | Display as-is |
| ALL CAPS | Strictly prohibited (except abbreviations: GST, SKU, ID, HSN) |

### Color Tokens (use AppTheme.* — never hardcode)
| Token | Hex | Use |
|---|---|---|
| `sidebarColor` | `#1F2633` | Sidebar background only |
| `backgroundColor` | `#FFFFFF` | All screens, modals, tables |
| `primaryBlue` | `#3B7CFF` | Primary buttons, links, active states |
| `accentGreen` | `#27C59A` | Success, confirm, positive |
| `textPrimary` | `#1F2933` | Headings, table values |
| `textSecondary` | `#6B7280` | Labels, hints, metadata |
| `borderColor` | `#D3D9E3` | Tables, cards, separators |

### Typography (AppTheme getters)
| Style | Size | Weight | Color |
|---|---|---|---|
| `pageTitle` | 18px | 600 | textPrimary |
| `sectionHeader` | 15px | 600 | textPrimary |
| `tableHeader` | 13px | 600 | textSecondary |
| `tableCell` | 13px | 400 | textPrimary |
| `metaHelper` | 12px | 400 | textSecondary |

### Table Standards
- All tables must support horizontal scroll and column visibility toggling
- Default: 100 rows per page; options: 10, 25, 50, 100, 200
- Pagination footer: total count (lazy), rows-per-page selector, prev/next arrows with range display
- Column headers: Title Case, non-wrapping, sortable on click
- Body rows: single-line, `TextOverflow.ellipsis`
- Hover: light highlight only — no color inversion

### Spacing (AppTheme.space* constants only)
Allowed values: 4, 8, 12, 16, 24, 32 (base unit: 8px)
- Card/table padding: 16px
- Modal padding: 24px
- No arbitrary spacing values

---

## 5. Recurring Idioms

### Lookup Bootstrap (parallel fetch)
```typescript
const [units, categories, taxRates] = await Promise.all([
  this.getUnits(),
  this.getCategories(),
  this.getTaxRates(),
]);
return { units, categories, taxRates };
```

### Outlet-Specific with Org Fallback
```typescript
// Try outlet-specific first, fall back to org-level
if (scope.outletId) {
  const { data } = await supabase.from('table').eq('outlet_id', scope.outletId)...;
  if (data) return data;
}
const { data } = await supabase.from('table').is('outlet_id', null)...;
return data;
```

### Payload Cleanup Before Insert
```typescript
Object.keys(insertPayload).forEach(
  (key) => (insertPayload[key] === undefined || insertPayload[key] === null) && delete insertPayload[key]
);
```

### Flutter Provider Pattern
```dart
final apiClient = ref.watch(apiClientProvider);
final response = await apiClient.get('products', queryParameters: {'limit': '100'});
```

### GoRouter Deep-Link with Query Params
```dart
context.go('/${orgId}/sales/invoices/create?customerId=$customerId&fromOrderId=$orderId');
```

### Responsive Dialog Width
```dart
final width = MediaQuery.of(context).size.width;
final dialogWidth = dialogWidthForWidth(width); // from breakpoints.dart
```

---

## 6. What NOT to Do

- ❌ Never hardcode `org_id` UUIDs in new code (use `resolveScope` or read from headers)
- ❌ Never use `http` package — Dio only
- ❌ Never use `provider` package — Riverpod only
- ❌ Never call `showDatePicker(...)` directly — use `ZerpaiDatePicker`
- ❌ Never hardcode hex colors in widgets — use `AppTheme.*`
- ❌ Never use `shared_preferences` for entity data — use Hive
- ❌ Never hard-delete DB records — always soft-delete with `is_active: false`
- ❌ Never create a new `items` table — use the global `products` table
- ❌ Never add auth/RBAC enforcement until production approval
- ❌ Never use `lib/core/widgets/` for reusable widgets — use `lib/shared/widgets/`
- ❌ Never run destructive DB commands without first running `npm run db:pull`
- ❌ Never use ALL CAPS in UI text (except standard abbreviations)
