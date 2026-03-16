# PRD Compliance Analysis & Required Changes

## ⚠️ PRD Edit Policy

Do not edit PRD files unless explicitly requested by the user or team head.

## 🔒 Auth Policy (Pre-Production)

No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-29 17:15
**Last Edited Version:** 1.5

---

## ✅ ALREADY COMPLIANT

### 1. HTTP Client (Dio)

- ✅ `lib/shared/services/api_client.dart` exists and uses Dio
- ✅ No `http` package imports found in codebase
- ✅ API services use Dio (`products_api_service.dart`, `sales_order_api_service.dart`)

### 2. State Management (Riverpod)

- ✅ Using `flutter_riverpod` throughout
- ✅ Controllers follow Riverpod pattern

### 3. File Naming Convention (Partially Compliant)

- ✅ **Sales Module:** Files follow `sales_customers_customer_creation.dart` pattern
- ✅ **Items Module:** Renamed to `items_items_item_creation.dart`, `items_items_item_detail.dart`, `items_items_item_overview.dart`
- ✅ **Inventory Module:** Renamed to `inventory_assemblies_assembly_creation.dart`, `inventory_assemblies_assembly_overview.dart`

### 4. Menu & Dropdown System (Unified Refactor)

- ✅ All legacy `PopupMenuButton` instances replaced with `MenuAnchor`
- ✅ Input fields use `FormDropdown` consistently
- ✅ `_HoverableMenuItem` helper removed from the codebase
- ✅ `MenuItemButton` used as the standard menu item widget

### 5. Dependencies

- ✅ `dio: ^5.9.0` installed
- ✅ `hive: 2.2.3` installed (just added)
- ✅ `hive_flutter: 1.1.0` installed (just added)
- ✅ `flutter_riverpod: ^2.6.1` installed

---

---

### 1. **CRITICAL: UI System & Design Governance Non-Compliance** 🚨

**PRD Section:** 14  
**Issue:** Codebase contains hardcoded hex values, arbitrary spacing, and non-theme-linked styles.

**Required Actions:**

1.  **Centralize Theme:** Implement `lib/core/theme/app_theme.dart` with all tokens defined in PRD Section 14.2.
2.  **Audit Widgets:** Replace all literal `Color(0xFF...)` and `SizedBox(height: ...)` with theme/spacing tokens.
3.  **Table Refactor:** All tables must be updated to use a resizable column system.

**Impact:** Continued deviation will lead to fragmented UI that is impossible to maintain or skin globally.

---

### 2. **CRITICAL: Hive Not Initialized** 🚨

**PRD Section:** 12.2, 13.1, 13.3  
**Issue:** Hive is installed but never initialized in `main.dart`

**Current State:**

```dart
// lib/main.dart - NO HIVE INITIALIZATION
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");
  await Supabase.initialize(...);
  runApp(const ProviderScope(child: ZerpaiApp()));
}
```

**Required Change:**

```dart
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline storage
  await Hive.initFlutter();

  await dotenv.load(fileName: "assets/.env");
  await Supabase.initialize(...);
  runApp(const ProviderScope(child: ZerpaiApp()));
}
```

**Impact:** Without this, the entire offline capability architecture is non-functional.

---

### 2. **CRITICAL: No Hive Boxes/Adapters Created** 🚨

**PRD Section:** 12.2, 13.3  
**Issue:** No Hive boxes exist for Products, Customers, or POS drafts

**Required Actions:**

1. Create Hive Type Adapters for:
   - `Product` model (from `products` table)
   - `Customer` model
   - `SalesOrder` model (for POS drafts)
2. Register adapters in `main.dart`:

```dart
Hive.registerAdapter(ProductAdapter());
Hive.registerAdapter(CustomerAdapter());
```

3. Open boxes:

```dart
await Hive.openBox<Product>('products');
await Hive.openBox<Customer>('customers');
await Hive.openBox('pos_drafts');
```

**Files to Create:**

- `lib/modules/items/models/product_adapter.dart` (generated via `hive_generator`)
- `lib/modules/sales/models/customer_adapter.dart`

---

### 3. **CRITICAL: File Naming Convention Violations** 🚨

**PRD Section:** 7.2, 14.5  
**Convention:** `module_submodule_page.dart`

**Files That MUST Be Renamed:**

| Current Name                             | Required Name                                            | Module      |
| ---------------------------------------- | -------------------------------------------------------- | ----------- |
| `adjustment_create_screen.dart`          | `inventory_adjustments_adjustment_creation.dart`         | Adjustments |
| `adjustments_list_screen.dart`           | `inventory_adjustments_adjustment_overview.dart`         | Adjustments |
| `branch_create_screen.dart`              | `settings_branches_branch_creation.dart`                 | Branches    |
| `branch_list_screen.dart`                | `settings_branches_branch_overview.dart`                 | Branches    |
| `composite_create_screen.dart`           | `items_composite_items_composite_creation.dart`          | Composite   |
| `composite_edit_screen.dart`             | `items_composite_items_composite_edit.dart`              | Composite   |
| `composite_list_screen.dart`             | `items_composite_items_composite_overview.dart`          | Composite   |
| `dashboard_screen.dart`                  | `home_dashboard_overview.dart`                           | Dashboard   |
| `itemgroup_create_screen.dart`           | `items_item_groups_item_group_creation.dart`             | Item Group  |
| `itemgroup_list_screen.dart`             | `items_item_groups_item_group_overview.dart`             | Item Group  |
| `mapping_create_screen.dart`             | `mapping_mapping_creation.dart`                          | Mapping     |
| `mapping_list_screen.dart`               | `mapping_mapping_overview.dart`                          | Mapping     |
| `pricelist_create_screen.dart`           | `items_pricelist_pricelist_creation.dart`                | Price List  |
| `pricelist_edit_screen.dart`             | `items_pricelist_pricelist_edit.dart`                    | Price List  |
| `pricelist_list_screen.dart`             | `items_pricelist_pricelist_overview.dart`                | Price List  |
| `purchase_create_screen.dart`            | `purchases_purchase_orders_purchase_order_creation.dart` | Purchases   |
| `purchases_list_screen.dart`             | `purchases_purchase_orders_purchase_order_overview.dart` | Purchases   |
| `reports_sales_sales_daily.dart`         | `reports_sales_sales_daily.dart`                         | Reports     |
| `reports_inventory_inventory_stock.dart` | `reports_inventory_inventory_stock.dart`                 | Reports     |
| `reports_reports_overview.dart`          | `reports_reports_overview.dart`                          | Reports     |
| `settings_screen.dart`                   | `settings_settings_overview.dart`                        | Settings    |
| `vendor_create_screen.dart`              | `purchases_vendors_vendor_creation.dart`                 | Vendors     |
| `vendor_list_screen.dart`                | `purchases_vendors_vendor_overview.dart`                 | Vendors     |
| `login_screen.dart`                      | `auth_auth_login.dart`                                   | Auth        |
| `forgot_password_screen.dart`            | `auth_auth_forgot_password.dart`                         | Auth        |

**Total Files to Rename:** 24 files

---

### 4. **CRITICAL: Missing API Client Centralization** 🚨

**PRD Section:** 13.1  
**Issue:** API client exists but not used consistently

**Current State:**

- `api_client.dart` exists ✅
- But services create their own Dio instances ❌

**Required Change:**
All API services must use the centralized `ApiClient`:

```dart
// WRONG (current):
class ProductsApiService {
  final Dio _dio = Dio(BaseOptions(baseUrl: '...'));
}

// CORRECT (required):
class ProductsApiService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Product>> getProducts() {
    return _apiClient.get('/products');
  }
}
```

---

### 5. **Missing: Repository Pattern for Offline Support** 🚨

**PRD Section:** 12.2, 13.2  
**Issue:** No repository layer to abstract Hive/API data sources

**Required Architecture:**

```
UI → Controller → Repository → [API Service + Hive Service]
```

**Files to Create:**

- `lib/modules/items/repositories/products_repository.dart`
- `lib/modules/sales/repositories/customers_repository.dart`
- `lib/shared/services/hive_service.dart`

**Example Repository:**

```dart
class ProductsRepository {
  final ProductsApiService _apiService;
  final HiveService _hiveService;

  Future<List<Product>> getProducts() async {
    try {
      // Try API first (online-first)
      final products = await _apiService.fetchProducts();
      // Cache to Hive
      await _hiveService.saveProducts(products);
      return products;
    } catch (e) {
      // Fallback to Hive (offline support)
      return _hiveService.getProducts();
    }
  }
}
```

---

### 6. **Missing: API Response Format Standardization** 🚨

**PRD Section:** 18.3  
**Issue:** Backend responses don't follow PRD standard

**Required Format:**

```json
{
  "data": {
    /* payload */
  },
  "meta": {
    "page": 1,
    "limit": 50,
    "total": 250,
    "timestamp": "2026-01-20T23:12:00Z"
  }
}
```

**Action:** Backend API controllers must be updated to return this format.

---

### 7. **Missing: Structured Logging** 🚨

**PRD Section:** 18.2  
**Issue:** No structured logging implementation

**Required:**

- Add `logger` package to `pubspec.yaml`
- Create `lib/core/logging/app_logger.dart`
- Add contextual logging (org_id, user_id, request_id)

---

### 8. **Missing: Error Handling Standards** 🚨

**PRD Section:** 10.1  
**Issue:** Inconsistent error handling across controllers

**Required:**

- Create `lib/core/errors/app_exceptions.dart`
- Standardize error responses
- Add user-friendly error messages

---

### 9. **Missing: Environment Variables** 🚨

**PRD Section:** 16.3  
**Issue:** No `.env.example` file

**Required Files:**

- `.env.example` (committed to git)
- `.env.local` (gitignored, developer-specific)

**Example `.env.example`:**

```env
# Backend
API_BASE_URL=http://localhost:3001

# Supabase
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_anon_key

# Feature Flags
ENABLE_OFFLINE_MODE=true
```

---

### 10. **Missing: Testing Infrastructure** 🚨

**PRD Section:** 17  
**Issue:** No test files exist

**Required:**

- Create `test/` directory structure mirroring `lib/`
- Minimum 70% code coverage
- Unit tests for all controllers
- Widget tests for complex UI components

---

### 11. **Deprecated: `http` Package Still in Dependencies** ⚠️

**PRD Section:** 7, 13.1  
**Issue:** `http: ^1.2.2` in `pubspec.yaml`

**Action:**

```bash
flutter pub remove http
```

---

### 12. **Missing: Code Formatting Enforcement** ⚠️

**PRD Section:** 14.1  
**Issue:** No pre-commit hooks or CI checks

**Required:**

- Run `dart format .` on entire codebase
- Add GitHub Actions workflow for format checks

---

## 📊 PRIORITY MATRIX

| Priority | Item                              | Effort  | Impact           |
| -------- | --------------------------------- | ------- | ---------------- |
| **P0**   | Initialize Hive in main.dart      | 5 min   | CRITICAL         |
| **P0**   | Create Hive adapters              | 2 hours | CRITICAL         |
| **P0**   | Rename 24 files to PRD convention | 1 hour  | HIGH             |
| **P1**   | Create Repository pattern         | 4 hours | HIGH             |
| **P1**   | Remove `http` package             | 5 min   | MEDIUM           |
| **P1**   | Centralize API client usage       | 2 hours | MEDIUM           |
| **P2**   | Add structured logging            | 3 hours | MEDIUM           |
| **P2**   | Create `.env.example`             | 30 min  | LOW              |
| **P3**   | Add testing infrastructure        | 8 hours | HIGH (long-term) |
| **P3**   | Standardize API responses         | 4 hours | MEDIUM           |

---

## 🎯 RECOMMENDED IMPLEMENTATION ORDER

### Phase 1: Foundation (Day 1)

1. Initialize Hive in `main.dart`
2. Remove `http` package
3. Create `.env.example`
4. Run `dart format .`

### Phase 2: Offline Architecture (Day 2-3)

5. Create Hive adapters for Product, Customer
6. Implement Repository pattern
7. Create HiveService

### Phase 3: Standardization (Day 4)

8. Rename all 24 files
9. Update all imports
10. Centralize API client usage

### Phase 4: Quality (Day 5+)

11. Add structured logging
12. Implement error handling standards
13. Create test infrastructure

---

## 📝 NOTES

- **Auth-Free Development:** PRD states no authentication in dev stage, current implementation has Supabase auth initialized but unused. This is acceptable.
- **Products vs Items:** Frontend correctly uses "Items" terminology while mapping to `products` table.
- **Sales Module:** Already mostly compliant with naming conventions.

---

**End of Report**
