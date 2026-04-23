# Project Folder Structure & Module Map
**Last Updated: 2026-04-20 12:46:08**

## ⚠️ PRD Edit Policy

Do not edit PRD files unless explicitly requested by the user or team head.

## 🔒 Auth Policy (Pre-Production)

No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-29 17:15
**Last Edited Version:** 1.4

---

## 1. Overview

This document defines the **mandatory** folder structure and file organization standards for Zerpai ERP. Consistent structure ensures:

- Easy navigation for new developers
- Clear separation of concerns
- Scalable architecture
- Predictable file locations

**Rule:** ALL new code MUST follow this structure. Deviations require architecture team approval.

---

## 2. Application Module Hierarchy (MANDATORY)

This section defines the **official module structure** for Zerpai ERP. All modules, sub-modules, folders, and files MUST follow this hierarchy exactly.

### 2.1 Sidebar Structure – Modules & Sub-Modules

The following table defines the complete module hierarchy as it appears in the application sidebar:

| Main Module   | Sub-Modules                                                                                                                                          |
| ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Home**      | —                                                                                                                                                    |
| **Items**     | Items<br>Composite Items<br>Item Groups<br>Price Lists<br>Item Mapping                                                                              |
| **Inventory** | Assemblies<br>Inventory Adjustments<br>Picklists<br>Packages<br>Shipments<br>Transfer Orders                                                        |
| **Sales**     | Customers<br>Retainer Invoices<br>Sales Orders<br>Invoices<br>Delivery Challans<br>Payments Received<br>Sales Returns<br>Credit Notes<br>e-Way Bills |
| **Purchases** | Vendors<br>Expenses<br>Recurring Expenses<br>Purchase Orders<br>Bills<br>Recurring Bills<br>Payments Made<br>Vendor Credits                        |
| **Accountant**| Manual Journals<br>Recurring Journals<br>Bulk Update<br>Transaction Locking<br>Opening Balances                                                     |
| **Accounts**  | Chart of Accounts                                                                                                                                    |
| **Reports**   | —                                                                                                                                                    |
| **Documents** | —                                                                                                                                                    |
| **Audit Logs**| —                                                                                                                                                    |

### 2.2 Module Hierarchy Tree

```
Home
│
├── Items
│   ├── Items
│   ├── Composite Items
│   ├── Item Groups
│   ├── Price Lists
│   └── Item Mapping
│
├── Inventory
│   ├── Assemblies
│   ├── Inventory Adjustments
│   ├── Picklists
│   ├── Packages
│   ├── Shipments
│   └── Transfer Orders
│
├── Sales
│   ├── Customers
│   ├── Retainer Invoices
│   ├── Sales Orders
│   ├── Invoices
│   ├── Delivery Challans
│   ├── Payments Received
│   ├── Sales Returns
│   ├── Credit Notes
│   └── e-Way Bills
│
├── Purchases
│   ├── Vendors
│   ├── Expenses
│   ├── Recurring Expenses
│   ├── Purchase Orders
│   ├── Bills
│   ├── Recurring Bills
│   ├── Payments Made
│   └── Vendor Credits
│
├── Accountant
│   ├── Manual Journals
│   ├── Recurring Journals
│   ├── Bulk Update
│   ├── Transaction Locking
│   └── Opening Balances
│
├── Accounts
│   └── Chart of Accounts
│
├── Reports
│
├── Documents
│
└── Audit Logs
```

### 2.3 Folder Structure Mapping Rules

**CRITICAL:** When creating modules and sub-modules, follow these rules:

#### Rule 1: Sidebar Modules vs Code Roots

The sidebar currently exposes these top-level destinations:

- Home
- Items
- Inventory
- Sales
- Purchases
- Accountant
- Accounts
- Reports
- Documents
- Audit Logs

The current **feature code roots** under `lib/modules/` are:

```
lib/modules/
├── home/
├── items/
├── inventory/
├── sales/
├── purchases/
├── accountant/
├── reports/
```

Notes:

- `Accounts` is a separate sidebar destination, but it is currently implemented inside the `accountant` code root.
- `Documents` and `Audit Logs` are sidebar destinations and routes, but they do not yet have dedicated top-level module roots under `lib/modules/`.

#### Rule 2: Sub-Modules

Sub-modules are created as **nested folders** under their parent module:

**Example 1: Items Module**

```

lib/modules/items/
├── items/ # "Items" sub-module
├── composite_items/ # "Composite Items" sub-module
├── item_groups/ # "Item Groups" sub-module
├── pricelist/ # "Price Lists" sub-module
└── mapping/ # "Item Mapping" sub-module when implemented under the Items module

```

**Example 2: Sales Module**

```

lib/modules/sales/
├── customers/
├── retainer_invoices/
├── sales_orders/
├── invoices/
├── delivery_challans/
├── payments_received/
├── sales_returns/
├── credit_notes/
└── eway_bills/

```

**Example 3: Purchases Module**

```

lib/modules/purchases/
├── vendors/
├── purchase_orders/
├── expenses/
├── recurring_expenses/
├── bills/
├── recurring_bills/
├── payments_made/
└── vendor_credits/

```

**Example 4: Accountant Module**

```

lib/modules/accountant/
├── manual_journals/
├── recurring_journals/
├── presentation/ # bulk update, transaction locking, opening balances, chart of accounts
├── providers/
└── repositories/

```

#### Rule 3: File Naming Convention

All files MUST follow the exact pattern:

```

<module>_<sub_module>_<page>.dart

```

**Naming Logic:**

1. **Module Name:** Always the first word (e.g., `items`, `sales`).
2. **Sub-Module:** The nested option in the sidebar (e.g., `pricelist`, `customer`).
3. **Action/Page:** The specific screen type (e.g., `overview`, `creation`, `edit`). This can include the entity name if needed for clarity (e.g., `pricelist_creation`).
4. **No Redundancy:** Avoid adding a generic `_screen` or `_page` suffix unless necessary for clarity.

**Detailed Examples:**

- `items_pricelist_pricelist_creation.dart` (Items → Price Lists → Create)
- `items_pricelist_pricelist_overview.dart` (Items → Price Lists → Overview)
- `items_pricelist_pricelist_edit.dart` (Items → Price Lists → Edit)
- `sales_customers_customer_creation.dart` (Sales → Customers → Create)
- `sales_customers_customer_overview.dart` (Sales → Customers → Overview)

#### Rule 4: Standalone Modules

Modules without dedicated nested sub-modules (Home, Reports) follow the standard module structure:

```

lib/modules/home/
├── models/
├── providers/
├── controllers/
├── repositories/
└── presentation/
└── home_dashboard_overview.dart

```

### 2.4 Routing Convention

Routes MUST reflect the module hierarchy and be defined with **GoRouter** in `lib/core/routing/app_router.dart`:

```dart
GoRoute(
  path: '/home',
  builder: (context, state) => const HomeDashboardScreen(),
),
GoRoute(
  path: '/items/pricelists',
  builder: (context, state) => const PriceListOverviewScreen(),
),
GoRoute(
  path: '/sales/customers',
  builder: (context, state) => const SalesCustomersOverviewScreen(),
),
GoRoute(
  path: '/purchases/vendors',
  builder: (context, state) => const VendorsOverviewScreen(),
),
```

### 2.5 Compliance Checklist

Before creating a new module or sub-module, verify:

- [ ] Module name matches the official hierarchy table (Section 2.1)
- [ ] Folder structure follows nesting rules (Section 2.3)
- [ ] File names follow the `<parent>_<sub>_<entity>_<type>.dart` pattern
- [ ] Routes reflect the module hierarchy
- [ ] Sidebar navigation matches the official tree structure
- [ ] No deviations from the official module list without approval

### 2.6 Infrastructure & Utility Modules

In addition to the main business modules in the sidebar hierarchy, the following **infrastructure and utility modules** exist. These modules do NOT appear in the sidebar navigation but are essential for application functionality:

| Module       | Purpose                        | Location                | Sidebar Visibility     |
| ------------ | ------------------------------ | ----------------------- | ---------------------- |
| **home**     | Dashboard/Home screen          | `lib/modules/home/`     | ✅ Yes (as "Home")     |
| **auth**     | Authentication & authorization | `lib/modules/auth/`     | ❌ No (system module)  |
| **branches** | Branch management       | `lib/modules/branches/` | ❌ No (admin utility)  |
| **mapping**  | Data mapping utilities         | `lib/modules/mapping/`  | ❌ No (utility module) |
| **settings** | Application settings           | `lib/modules/settings/` | ❌ No (utility module) |

#### Module Details:

**1. Home Module (`lib/modules/home/`)**

- **Purpose:** Main dashboard/landing page after login
- **Sidebar:** Appears as "Home" in the sidebar
- **Structure:** Standard module structure (models, providers, controllers, presentation)
- **Note:** Previously named `dashboard/`, now standardized as `home/`

**2. Auth Module (`lib/modules/auth/`)**

- **Purpose:** User authentication UI (login, password reset)
- **Sidebar:** Not visible (auth UI exists but is not wired into routing yet)
- **Structure:** Standard module structure
- **Critical:** Required for application security when auth is enabled

**3. Branches Module (`lib/modules/branches/`)**

- **Purpose:** Multi-branch management for organizations
- **Sidebar:** Not in main sidebar (admin/settings feature)
- **Structure:** Standard module structure
- **Use Case:** Organizations with multiple physical locations

**4. Mapping Module (`lib/modules/mapping/`)**

- **Purpose:** Data transformation and mapping utilities
- **Sidebar:** Not visible (internal utility)
- **Structure:** May contain services, utilities, helpers
- **Use Case:** Data import/export, API response mapping

**5. Settings Module (`lib/modules/settings/`)**

- **Purpose:** Application configuration and user preferences
- **Sidebar:** May appear in user menu or separate settings screen
- **Structure:** Standard module structure
- **Use Case:** User preferences, app configuration, system settings

#### File Naming for Infrastructure Modules

Infrastructure modules follow the same naming convention:

```
<module>_<entity>_<type>.dart
```

**Examples:**

- `auth_auth_login.dart`
- `auth_auth_forgot_password.dart`
- `home_dashboard_overview.dart`
- `branches_branches_creation.dart`
- `settings_settings_preferences.dart`

#### Routing for Infrastructure Modules

```dart
// Infrastructure module routes
static const String home = '/home';
// Future auth routes (disabled until production approval)
static const String login = '/auth/login';
static const String register = '/auth/register';
static const String branches = '/branches';
static const String branchesCreate = '/branches/create';
static const String settings = '/settings';
static const String settingsPreferences = '/settings/preferences';
```

---

## 3. Frontend (Flutter) Structure

### 2.1 Root Directory Structure

```
zerpai_erp/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # Root app widget (MaterialApp.router + GoRouter)
│   │
│   ├── core/                        # ⭐ Core infrastructure (app-wide)
│   │   ├── routing/
│   │   │   └── app_router.dart      # GoRouter configuration
│   │   ├── theme/
│   │   │   ├── app_theme.dart       # ThemeData definitions
│   │   │   ├── app_colors.dart      # Color palette constants
│   │   │   └── app_text_styles.dart # Typography
│   │   ├── layout/                  # ⭐ App-wide layout components
│   │   │   ├── zerpai_sidebar.dart  # Main sidebar navigation
│   │   │   ├── zerpai_navbar.dart   # Top navigation bar
│   │   │   └── responsive_layout.dart
│   │   ├── constants/
│   │   │   ├── api_endpoints.dart   # Backend API URLs
│   │   │   ├── app_constants.dart   # App-wide constants
│   │   │   └── storage_keys.dart    # Hive/SharedPreferences keys
│   │   ├── utils/
│   │   │   ├── date_formatter.dart  # Date/time utilities
│   │   │   ├── currency_formatter.dart
│   │   │   ├── validators.dart      # Form validators
│   │   │   └── string_utils.dart
│   │   ├── extensions/              # ⭐ Dart extensions (separate)
│   │   │   ├── string_extensions.dart
│   │   │   ├── datetime_extensions.dart
│   │   │   └── build_context_extensions.dart
│   │   ├── api/
│   │   │   ├── dio_client.dart      # Dio singleton instance
│   │   │   ├── api_interceptors.dart # Auth token, logging
│   │   │   └── api_response.dart    # Standardized response wrapper
│   ├── shared/                      # ⭐ Reusable cross-feature building blocks
│   │   ├── widgets/
│   │   │   ├── inputs/              # Form controls, pickers, tooltips
│   │   │   ├── dialogs/             # Reusable dialogs
│   │   │   ├── reports/             # Reusable report shells
│   │   │   └── texts/
│   │   ├── services/                # Cross-feature services
│   │   └── responsive/              # Shared responsive primitives
│   │   ├── storage/
│   │   │   ├── hive_service.dart    # Hive initialization
│   │   │   └── preferences_service.dart
│   │   ├── logging/
│   │   │   └── app_logger.dart      # Logger configuration
│   │   └── monitoring/
│   │       └── health_indicator.dart # App health status widget
│   │
│   ├── shared/                      # ⭐ Shared providers/models only
│   │   ├── providers/
│   │   │   └── common_providers.dart # Shared providers (items, vendors)
│   │   └── models/
│   │       └── common_models.dart    # Shared models (Address, Contact)
│   │
│   └── modules/                     # ⭐ Feature modules (business logic)
│       ├── items/
│       │   ├── models/
│       │   │   └── items_items_item_model.dart
│       │   ├── providers/
│       │   │   └── items_items_item_provider.dart
│       │   ├── controllers/         # Business logic if complex
│       │   │   └── items_items_item_controller.dart
│       │   ├── repositories/
│       │   │   ├── items_items_item_repository.dart      # Abstract interface
│       │   │   └── items_items_item_repository_impl.dart # Implementation
│       │   └── presentation/
│       │       ├── items_pricelist_pricelist_overview.dart
│       │       ├── items_pricelist_pricelist_creation.dart
│       │       ├── items_items_item_detail.dart
│       │       └── widgets/
│       │           ├── items_items_item_card.dart
│       │           └── items_items_item_list_tile.dart
│       │
│       ├── sales/
│       │   ├── models/
│       │   │   ├── sales_orders_order_model.dart
│       │   │   ├── sales_customers_customer_model.dart
│       │   │   └── sales_invoices_invoice_model.dart
│       │   ├── providers/
│       │   │   └── sales_orders_provider.dart
│       │   ├── controllers/         # Complex business logic
│       │   │   └── sales_orders_order_controller.dart
│       │   ├── repositories/
│       │   │   ├── sales_orders_order_repository.dart
│       │   │   ├── sales_orders_order_repository_impl.dart
│       │   │   └── sales_customers_customer_repository.dart
│       │   └── presentation/
│       │       ├── sales_orders_order_overview.dart
│       │       ├── sales_orders_order_creation.dart
│       │       ├── sales_invoices_invoice_creation.dart
│       │       └── widgets/
│       │           ├── sales_orders_order_card.dart
│       │           └── sales_orders_summary_widget.dart
│       │
│       ├── purchases/
│       ├── inventory/
│       ├── reports/
│       └── documents/
│
├── assets/                          # ⭐ Static assets (outside lib/)
│   ├── images/
│   │   ├── logos/
│   │   │   └── zerpai_logo.png
│   │   └── items/
│   │       └── placeholder.png
│   ├── icons/
│   │   └── custom_icons.svg
│   └── fonts/
│       └── Roboto-Regular.ttf
│
├── test/                            # ⭐ Mirror lib/ structure EXACTLY
│   ├── modules/
│   │   ├── items/
│   │   │   ├── models/
│   │   │   │   └── items_items_item_model_test.dart
│   │   │   ├── providers/
│   │   │   │   └── items_items_item_provider_test.dart
│   │   │   ├── repositories/
│   │   │   │   └── items_items_item_repository_test.dart
│   │   │   └── presentation/
│   │   │       └── items_pricelist_pricelist_creation_test.dart
│   │   │
│   │   └── sales/
│   │       ├── models/
│   │       ├── providers/
│   │       └── presentation/
│   │
│   ├── core/
│   │   ├── utils/
│   │   │   └── currency_formatter_test.dart
│   │   ├── api/
│   │   │   └── dio_client_test.dart
│   │   └── widgets/
│   │       └── forms/
│   │           └── form_dropdown_test.dart
│   │
│   └── shared/
│       └── providers/
│           └── common_providers_test.dart
│
├── pubspec.yaml
├── analysis_options.yaml            # Linting rules
└── README.md
```

---

### 2.2 Folder Purposes (Flutter)

| Folder             | Purpose                            | Examples                                                        |
| ------------------ | ---------------------------------- | --------------------------------------------------------------- |
| **`lib/core/`**    | App infrastructure only            | Router, theme, logger, shell layout, bootstrap wiring           |
| **`lib/shared/`**  | Reusable UI and cross-feature code | Widgets, services, responsive primitives, shared models         |
| **`lib/modules/`** | Feature-specific code (isolated)   | Sales, items, inventory                                         |
| **`assets/`**      | Images, fonts, icons               | Item images, app logo                                           |
| **`test/`**        | All tests (mirrors `lib/` exactly) | Unit, widget, integration tests                                 |

**Key Distinction:**

- **`core/`**: Infrastructure that the app NEEDS to run (router, theme, logging, shell layout)
- **`shared/`**: Reusable UI and cross-feature services/models used across modules
- **`modules/`**: Feature-specific business logic

---

### 2.3 Module Internal Structure (Mandatory Pattern)

**Every module MUST follow this standardized structure:**

```
lib/modules/<module_name>/
├── models/              # Data models (DTOs, entities)
│   └── <module>_<submodule>_<entity>_model.dart
│
├── providers/           # Riverpod providers (state management)
│   └── <module>_<submodule>_provider.dart
│
├── controllers/         # Business logic (if complex enough to separate)
│   └── <module>_<submodule>_<entity>_controller.dart
│
├── repositories/        # Data access layer (API calls, Hive)
│   ├── <module>_<submodule>_<entity>_repository.dart      # Abstract interface
│   └── <module>_<submodule>_<entity>_repository_impl.dart # Implementation
│
└── presentation/        # UI layer
    ├── <module>_<submodule>_<page>.dart
    └── widgets/         # Module-specific widgets only
        └── <module>_<submodule>_<widget>.dart
```

**When to use `controllers/`:**

- ✅ Complex business logic (multiple steps, calculations)
- ✅ Coordination between multiple repositories
- ✅ State transformations beyond simple CRUD
- ❌ Simple CRUD operations (keep in providers)

**Example (Items → Price Lists):**

```
lib/modules/items/
├── models/
│   └── items_pricelist_pricelist_model.dart
├── providers/
│   └── items_pricelist_provider.dart
├── controllers/                         # Optional for simple modules
│   └── items_pricelist_controller.dart
├── repositories/
│   ├── items_pricelist_repository.dart         # Interface
│   └── items_pricelist_repository_impl.dart    # Implementation
└── presentation/
    ├── items_pricelist_pricelist_overview.dart
    ├── items_pricelist_pricelist_creation.dart
    └── widgets/
        └── items_pricelist_card.dart
```

---

### 2.4 File Naming Rules (Strict)

**Rule:** All files MUST use `snake_case` format: `module_submodule_page.dart`

**Format:** `<module>_<submodule>_<page>.dart`

**Examples:**

| ✅ Correct                                | ❌ Wrong                                              |
| ----------------------------------------- | ----------------------------------------------------- |
| `items_pricelist_pricelist_creation.dart` | `ItemsPriceListCreate.dart` (PascalCase)              |
| `sales_orders_order_creation.dart`        | `sales_order_create_screen.dart` (old suffix pattern) |
| `items_items_item_card.dart`              | `ItemCard.dart` (PascalCase)                          |
| `sales_orders_provider.dart`              | `sales-provider.dart` (kebab-case)                    |
| `api_interceptors.dart`                   | `APIInterceptors.dart` (abbreviation uppercase)       |

**Page Types:**

- `*_overview.dart` (List/Registry view)
- `*_creation.dart` (Creation form)
- `*_edit.dart` (Edit form)
- `*_detail.dart` (Detail view)

**Widget Types:**

- `*_card.dart`
- `*_list_tile.dart`
- `*_dialog.dart`
- `*_sheet.dart`

---

### 2.5 Where Things Go (Decision Tree)

**"Where should I put this file?"**

```
START
│
├─ Is it specific to ONE module? (e.g., SalesOrderCard)
│  └─ YES → lib/modules/<module>/presentation/widgets/
│  └─ NO → Continue
│
├─ Is it app infrastructure or layout? (router, theme, sidebar, navbar, API client)
│  └─ YES → lib/core/<category>/
│  └─ NO → Continue
│
├─ Is it a reusable UI widget? (FormDropdown, ZTooltip, dialogs, page wrappers)
│  └─ YES → lib/shared/widgets/<category>/
│  └─ NO → Continue
│
├─ Is it a cross-feature service? (ApiClient, StorageService, LookupService, HiveService)
│  └─ YES → lib/shared/services/
│  └─ NO → Continue
│
├─ Is it a shared provider or model? (itemsProvider, Address model)
│  └─ YES → lib/shared/<providers|models>/
│  └─ NO → Continue
│
├─ Is it a utility/helper function?
│  └─ YES → lib/core/utils/
│  └─ NO → Continue
│
└─ Is it a Dart extension?
   └─ YES → lib/core/extensions/
```

**Examples:**

| Component                 | Location                                                              | Rationale              |
| ------------------------- | --------------------------------------------------------------------- | ---------------------- |
| App router (GoRouter)     | `lib/core/routing/app_router.dart`                                    | Core infrastructure    |
| **Sidebar navigation** ⭐ | `lib/core/layout/zerpai_sidebar.dart`                                 | Core shell component   |
| **Navbar** ⭐             | `lib/core/layout/zerpai_navbar.dart`                                  | Core shell component   |
| App theme                 | `lib/core/theme/app_theme.dart`                                       | Core infrastructure    |
| Dio client                | `lib/core/api/dio_client.dart`                                        | Core infrastructure    |
| **FormDropdown** ⭐       | `lib/shared/widgets/inputs/dropdown_input.dart`                       | Shared reusable widget |
| **ZerpaiDatePicker** ⭐   | `lib/shared/widgets/inputs/zerpai_date_picker.dart`                   | Shared reusable widget |
| **ZTooltip** ⭐           | `lib/shared/widgets/inputs/z_tooltip.dart`                            | Shared reusable widget |
| StorageService            | `lib/shared/services/storage_service.dart`                            | Shared service         |
| Currency formatter        | `lib/core/utils/currency_formatter.dart`                              | Core utility           |
| String extensions         | `lib/core/extensions/string_extensions.dart`                          | Core extension         |
| Shared model              | `lib/shared/models/common_models.dart`                                | Shared model           |
| SalesOrderCard            | `lib/modules/sales/presentation/widgets/sales_orders_order_card.dart` | Module-specific widget |
| Item model                | `lib/modules/items/models/items_items_item_model.dart`                | Module-specific        |
| Items provider            | `lib/modules/items/providers/items_items_item_provider.dart`          | Module-specific        |

---

## 3. Backend (NestJS) Structure

### 3.1 Root Directory Structure

```
backend/
├── src/
│   ├── main.ts                      # App entry point
│   ├── app.module.ts                # Root module
│   │
│   ├── modules/                     # ⭐ Feature modules
│   │   ├── items/
│   │   │   ├── items.module.ts
│   │   │   ├── items.controller.ts
│   │   │   ├── items.service.ts
│   │   │   ├── entities/
│   │   │   │   └── item.entity.ts
│   │   │   └── dto/
│   │   │       ├── create-item.dto.ts
│   │   │       └── update-item.dto.ts
│   │   │
│   │   ├── sales/
│   │   │   ├── sales.module.ts
│   │   │   ├── orders/
│   │   │   │   ├── orders.controller.ts
│   │   │   │   ├── orders.service.ts
│   │   │   │   └── dto/
│   │   │   ├── invoices/
│   │   │   └── customers/
│   │   │
│   │   ├── auth/                    # Future - authentication
│   │   ├── users/
│   │   └── reports/
│   │
│   ├── common/                      # ⭐ Shared utilities
│   │   ├── decorators/              # Custom decorators
│   │   │   └── roles.decorator.ts
│   │   ├── guards/                  # Auth guards
│   │   │   └── jwt-auth.guard.ts
│   │   ├── interceptors/            # Request/response interceptors
│   │   │   └── logging.interceptor.ts
│   │   ├── filters/                 # Exception filters
│   │   │   └── http-exception.filter.ts
│   │   ├── pipes/                   # Validation pipes
│   │   │   └── validation.pipe.ts
│   │   └── dto/                     # Shared DTOs
│   │       └── pagination.dto.ts
│   │
│   ├── config/                      # ⭐ Configuration
│   │   ├── database.config.ts       # Drizzle/Supabase config
│   │   ├── app.config.ts
│   │   └── env.validation.ts
│   │
│   ├── database/                    # ⭐ Database layer (Drizzle)
│   │   ├── schema/
│   │   │   ├── items.schema.ts
│   │   │   ├── sales.schema.ts
│   │   │   └── index.ts
│   │   ├── migrations/
│   │   │   └── 0001_initial_schema.sql
│   │   └── drizzle.config.ts
│   │
│   └── health/                      # Health check endpoint
│       └── health.controller.ts
│
├── test/                            # E2E and unit tests
│   ├── app.e2e-spec.ts
│   └── items/
│       └── items.controller.spec.ts
│
├── package.json
├── tsconfig.json
├── nest-cli.json
└── README.md
```

---

### 3.2 Backend Module Pattern (NestJS Standard)

**Every module MUST follow:**

```
src/modules/<module>/
├── <module>.module.ts           # Module definition
├── <module>.controller.ts       # REST endpoints
├── <module>.service.ts          # Business logic
├── entities/                    # Database entities (if using TypeORM)
│   └── <entity>.entity.ts
└── dto/                         # Data Transfer Objects
    ├── create-<entity>.dto.ts
    ├── update-<entity>.dto.ts
    └── <entity>-response.dto.ts
```

**Example (Items):**

```
src/modules/items/
├── items.module.ts
├── items.controller.ts       # @Get(), @Post(), etc.
├── items.service.ts          # Business logic
└── dto/
    ├── create-item.dto.ts
    └── update-item.dto.ts
```

---

### 3.3 Backend File Naming (NestJS Convention)

**Format:** `<entity>.<type>.ts`

**Examples:**

| File Type   | Naming Pattern             | Example                  |
| ----------- | -------------------------- | ------------------------ |
| Module      | `<module>.module.ts`       | `items.module.ts`        |
| Controller  | `<module>.controller.ts`   | `items.controller.ts`    |
| Service     | `<module>.service.ts`      | `items.service.ts`       |
| DTO         | `<action>-<entity>.dto.ts` | `create-item.dto.ts`     |
| Entity      | `<entity>.entity.ts`       | `item.entity.ts`         |
| Guard       | `<name>.guard.ts`          | `jwt-auth.guard.ts`      |
| Interceptor | `<name>.interceptor.ts`    | `logging.interceptor.ts` |

---

## 4. Asset Organization

### 4.1 Assets Folder Structure

```
assets/
├── images/
│   ├── logos/
│   │   ├── zerpai_logo.png          # Main app logo
│   │   └── zerpai_logo_white.png
│   ├── placeholders/
│   │   ├── item_placeholder.png
│   │   └── user_placeholder.png
│   └── onboarding/
│       ├── welcome_1.png
│       └── welcome_2.png
│
├── icons/
│   ├── custom/                      # Custom SVG icons
│   │   └── barcode_scanner.svg
│   └── ...
│
└── fonts/                           # Custom fonts (if needed)
    └── Roboto-Regular.ttf
```

### 4.2 Asset Path Constants

**Create:** `lib/core/constants/asset_paths.dart`

```dart
class AssetPaths {
  // Images
  static const String logo = 'assets/images/logos/zerpai_logo.png';
  static const String itemPlaceholder = 'assets/images/placeholders/item_placeholder.png';

  // Icons
  static const String barcodeIcon = 'assets/icons/custom/barcode_scanner.svg';
}
```

**Usage:**

```dart
Image.asset(AssetPaths.logo)
```

---

## 5. Testing Folder Structure

### 5.1 Test Directory (Mirrors lib/)

```
test/
├── modules/
│   ├── items/
│   │   ├── models/
│   │   │   └── items_items_item_model_test.dart
│   │   ├── providers/
│   │   │   └── items_items_item_provider_test.dart
│   │   ├── repositories/
│   │   │   └── items_items_item_repository_test.dart
│   │   └── presentation/
│   │       └── items_pricelist_pricelist_creation_test.dart
│   │
│   └── sales/
│       └── ...
│
├── core/
│   ├── widgets/
│   │   └── forms/
│   │       └── form_dropdown_test.dart
│   ├── utils/
│   │   └── currency_formatter_test.dart
│   └── api/
│       └── dio_client_test.dart
│
└── integration/                     # End-to-end tests
    └── sales_order_flow_test.dart
```

### 5.2 Test File Naming

**Format:** `<original_file_name>_test.dart`

**Examples:**

- `items_items_item_model.dart` → `items_items_item_model_test.dart`
- `sales_orders_provider.dart` → `sales_orders_provider_test.dart`
- `items_pricelist_pricelist_creation.dart` → `items_pricelist_pricelist_creation_test.dart`

---

## 6. Configuration Files Location

### 6.1 Root-Level Config Files

```
zerpai_erp/
├── .env.example                 # Environment variable template
├── .env.local                   # Your local overrides (gitignored)
├── pubspec.yaml                 # Flutter dependencies
├── analysis_options.yaml        # Dart linting rules
├── .gitignore
├── README.md
└── .github/
    └── workflows/
        ├── flutter-ci.yml       # CI/CD for frontend
        └── nest-ci.yml          # CI/CD for backend
```

### 6.2 Backend Config

```
backend/
├── .env.example
├── .env.local                   # Gitignored
├── package.json
├── tsconfig.json
├── nest-cli.json
└── drizzle.config.ts            # Drizzle ORM config
```

---

## 7. Common Mistakes to Avoid

### ❌ Don't Do This:

```
# Wrong - mixed concerns
lib/widgets/
├── sales_order_card.dart        # Module-specific, should be in modules/sales/
├── form_dropdown.dart           # Generic, correct location
└── items_items_item_overview.dart         # Module-specific, wrong location

# Wrong - flat structure in module
lib/modules/sales/
├── sales_order.dart             # Missing folder (models/)
├── sales_provider.dart          # Missing folder (providers/)
└── sales_orders_order_overview.dart  # Missing folder (presentation/)

# Wrong - inconsistent naming
lib/modules/sales/presentation/
├── SalesOrderCreate.dart        # PascalCase - WRONG
├── sales-order-edit.dart        # kebab-case - WRONG
└── salesOrderDetail.dart        # camelCase - WRONG
```

### ✅ Do This Instead:

```
# Correct - clear separation
lib/shared/widgets/inputs/
└── dropdown_input.dart          # Generic, reusable

lib/modules/sales/presentation/widgets/
└── sales_orders_order_card.dart        # Module-specific

# Correct - organized structure
lib/modules/sales/
├── models/
│   └── sales_orders_order_model.dart
├── providers/
│   └── sales_orders_provider.dart
└── presentation/
    └── sales_orders_order_creation.dart

# Correct - snake_case naming
lib/modules/sales/presentation/
├── sales_orders_order_creation.dart
├── sales_orders_order_edit.dart
└── sales_orders_order_detail.dart
```

---

## 8. Migration Plan (Existing Code)

### 8.1 Audit Current Structure

**Run this to find violations:**

```bash
# Find PascalCase files
Get-ChildItem -Path lib -Recurse -Filter "*.dart" |
  Where-Object { $_.Name -cmatch '[A-Z]' }

# Find files in wrong locations
# (manual review needed)
```

### 8.2 Refactoring Checklist

- [ ] Move `app_router.dart` to `lib/core/routing/`
- [ ] Move theme files to `lib/core/theme/`
- [ ] Move API client to `lib/core/api/`
- [ ] Organize module internals (models/, providers/, presentation/)
- [ ] Move reusable widgets to `lib/shared/widgets/`
- [ ] Move cross-feature services to `lib/shared/services/`
- [ ] Rename any PascalCase files to snake_case
- [ ] Update all import statements

---

## 9. Enforcement

### 9.1 Linting Rules

**Add to `analysis_options.yaml`:**

```yaml
linter:
  rules:
    # File naming
    file_names: true # Enforces snake_case

    # Import organization
    directives_ordering: true

    # Code quality
    avoid_print: true
    prefer_const_constructors: true
```

### 9.2 Code Review Checklist

Before approving any PR, verify:

- [ ] File follows naming convention (`snake_case`)
- [ ] File is in correct folder (per decision tree)
- [ ] Module has proper internal structure
- [ ] No PascalCase or kebab-case filenames
- [ ] Imports are organized (core → shared → modules)
- [ ] Tests exist in mirrored structure

---

## 10. Quick Reference

### When Creating a New Module:

```bash
# 1. Create folder structure
mkdir -p lib/modules/<module>/{models,providers,repositories,presentation/widgets}

# 2. Create files with correct naming
# models/<module>_<submodule>_<entity>_model.dart
# providers/<module>_<submodule>_provider.dart
# repositories/<module>_<submodule>_<entity>_repository.dart
# presentation/<module>_<submodule>_<page>.dart

# 3. Create corresponding tests
mkdir -p test/modules/<module>/{models,providers,presentation}
```

### When Adding a Shared Widget:

```bash
# 1. Identify category
# - forms/, layout/, common/, dialogs/

# 2. Create in shared/widgets/<category>/
touch lib/shared/widgets/inputs/new_widget.dart

# 3. Add test
touch test/shared/widgets/new_widget_test.dart
```

---

## 11. Review & Updates

**This structure is LOCKED for v1.0**

Changes require:

1. Architecture team discussion
2. Migration plan for existing code
3. Documentation update
4. Team notification

**Document Owner:** Engineering Lead  
**Next Review:** After v1.0 launch

---

## 12. Widget Code Organization (The "Part" File Standard)

To maintain code readability and manage large widget files (especially complex forms and detail screens), Zerpai ERP uses a **Part-File Sectioning** pattern.

### 12.1 When to Segment

A widget file SHOULD be segmented into part files if:

- The file exceeds **1000 lines** of code.
- The `build` method is excessively complex or contains multiple logical UI sections (e.g., Primary Info, Address, Tabs).
- The file contains large private helper methods for building UI.

### 12.2 Segmentation Pattern

Segmented widgets follow the `part` / `part of` directive pattern.

1. **Main File**: `lib/modules/<module>/presentation/<widget_name>.dart`
   - Defines the `StatefulWidget` or `ConsumerStatefulWidget`.
   - Defines the `State` class.
   - Contains lifecycle methods (`initState`, `dispose`).
   - Declares all controllers and state variables.
   - Contains the high-level `build` method.
   - Declares `part 'sections/<widget_name>_<section>.dart';`.

2. **Section Files**: `lib/modules/<module>/presentation/sections/<widget_name>_<section>.dart`
   - Uses `part of '../<widget_name>.dart';`.
   - Uses **Extensions on the State class** to encapsulate UI builder methods.
   - Accesses private state and controllers directly from the state class.

### 12.3 Directory Structure for Sections

Sections MUST be placed in a `sections/` subdirectory relative to the presentation folder.

```
presentation/
├── my_feature_creation.dart
└── sections/
    ├── my_feature_create_primary_info.dart
    ├── my_feature_create_address_section.dart
    └── my_feature_create_footer.dart
```

### 12.4 Rules for Segmentation

- **No Logic Changes**: Purely move code from the main file to any part file without altering business logic, conditions, or rules.
- **State Ownership**: All state variables and controllers MUST remain in the main file's state class.
- **Naming**: Section files MUST be named `<widget_name_snake_case>_<section_name>.dart`.
- **Extension Naming**: Extensions SHOULD be named `<SectionName>Section`.

### 12.5 Future Maintenance

**Maintenance Rule**: When adding new fields, widgets, or logic to a segmented screen, developers MUST place the new code in the corresponding file within the `sections/` folder (or create a new section file if appropriate) rather than growing the main widget file. This ensures the main file remains a clean entry point and state container.

---

**Last Updated:** 2026-01-21  
**Status:** Mandatory for all complex widgets.
