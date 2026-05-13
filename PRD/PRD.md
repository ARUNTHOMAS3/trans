# 📘 Product Requirements Document (PRD) - Comprehensive

> **📐 Entity Model Specification:** The tenancy and ownership architecture (how data is scoped by org vs. branch) is defined in [`PRD/prd_entity_model.md`](./prd_entity_model.md). All developers and AI agents must read that document before writing queries, API endpoints, or providers. It supplements this PRD and does not alter it.

## ⚠️ PRD Edit Policy

Do not edit PRD files unless explicitly requested by the user or team head.

## 🔒 Auth Policy (Pre-Production)

No authentication setup is allowed until production. The application must run without enforced login/RBAC/JWT in dev and staging. Auth UI may exist but must not be wired into routing until production approval.
**Last Edited:** 2026-01-30 03:53
**Last Edited Version:** 2.5

## 📅 Shared Date Picker Policy

The application standard date picker is `ZerpaiDatePicker` from `lib/shared/widgets/inputs/zerpai_date_picker.dart`. Wherever the shared anchored picker pattern is suitable, it must be reused instead of introducing fresh raw `showDatePicker(...)` implementations. Any deviation should be treated as an explicit exception, not the default.

## ♻️ Reusables Policy

Before creating any new shared widget, mixin, service, utility, helper, or reusable UI pattern, developers and agents must check `REUSABLES.md` at the project root first. If a suitable reusable already exists, it must be reused instead of duplicated. If no suitable reusable exists and a genuinely reusable abstraction is created, it must be added to `REUSABLES.md` immediately after creation. When a relevant reusable already exists, the developer or agent must explicitly tell the user which reusable can be used. When a new reusable is created, the developer or agent must explicitly tell the user so they can decide whether to promote it further. Reusables that should always be checked first include `FormDropdown<T>`, `CustomTextField`, `ZerpaiDatePicker`, `ZTooltip`, `GstinPrefillBanner`, `LicenceValidationMixin`, `ZerpaiLayout`, `ZButton`, `ZerpaiConfirmationDialog`, and `AppTheme` tokens.

## 🌐 Global Settings Policy

The application must prefer real DB-backed runtime data wherever a schema-backed source already exists. When real data is unavailable, the UI must show an explicit empty or error state instead of fabricated business values. Lookup defaults should resolve from DB-backed master rows rather than hardcoded IDs or labels. Reusable control behavior and visual styling should be centralized in shared sources. Warehouse master data, storage/location master data, accounting stock, and physical stock must remain separate concepts across schema, API, and UI. Shared environments must be updated with additive migrations and scoped upserts instead of destructive resets.
Primary save/create/confirm actions, cancel/secondary actions, upload controls, borders, and separators must also follow centralized project styling rules instead of per-screen color choices.
Any new database table created specifically for the global settings system must start with the `settings_` prefix.

---

## 1. Overview

### 1.1 Product Vision

Zerpai ERP is a **modern, online-first but offline-capable ERP system** built for Indian SMEs. The initial focus is on **retail, pharmacy, and trading businesses**, with a modular architecture designed for future expansion. It is engineered to support small internet interferences, ensuring operational continuity.

The system is designed to:

- Replace dependency on spreadsheets and fragmented, single-purpose tools.
- Provide a fast, responsive user experience for daily operations (POS, billing, inventory management).
- Ensure data integrity and correctness for critical business functions (inventory, GST, reporting).
- Support complex operational structures like **Head Office (HO) → Franchise-Owned, Franchise-Operated (FOFO) → Company-Owned, Company-Operated (COCO)**.
- Scale efficiently to support over 1000 branches on a single, robust database instance.

**Inspiration & Visual Reference:** The design and workflow of this ERP are heavily inspired by the Zoho Inventory web application. All developers and agents should use the following demo URL as a primary reference for UI, UX, and feature functionality:
`https://www.zoho.com/in/inventory/inventory-software-demo/#/home/inventory-dashboard`

If the demo page presents a signup dialog, it should be dismissed by clicking the 'cancel' or 'close' button. If any doubts about a feature or workflow remain after consulting the demo, the agent is encouraged to ask the user for clarification at any time.

### 1.2 Development Philosophy (Auth-Free Dev Stage)

To maximize development velocity and focus on core business logic, the initial development and testing stages will operate **without a formal authentication layer**.

- ✅ **No Enforced Login Flow:** The application boots directly to the home dashboard. Auth UI screens exist in `lib/modules/auth/`, but are not wired into routing yet.
- ❌ **No Role-Based Access Control (RBAC):** All features are accessible. Role-specific behavior may be simulated in the UI, but is not enforced at the API or database level.
- ❌ **No JWTs or Supabase Auth:** The backend does not require or validate authentication tokens.
- ✅ **Single Organizational Context:** The system operates under a polymorphic `entity_id` context referencing the `organisation_branch_master` table. This identifies the active Head Office or Branch for all transactions, replacing the legacy dual-column `org_id + branch_id` pattern.

This strategy allows for rapid iteration. The architecture is **"Auth-Ready,"** ensuring that a comprehensive security layer can be added later with minimal refactoring.

---

## 2. Agent Architecture

### 2.1 Overview

This project leverages a CLI-based AI agent for development, maintenance, and analysis tasks. The agent's architecture is designed for safe, efficient, and context-aware interaction with the codebase.

### 2.2 Core Components

- **Interactive CLI:** The primary interface for developers to interact with the agent.
- **Tool-Augmented Language Model:** The agent's core is a large language model with access to a suite of specialized tools for file system interaction, code manipulation, shell command execution, and web searches.
- **Contextual Understanding Engine:** The agent builds an in-memory model of the project by reading files, analyzing dependencies (`package.json`, `pubspec.yaml`), and inspecting the git history.
- **Safety & Verification Layer:** Before executing any command that modifies the file system or system state, the agent must explain its intent, and the user must provide explicit confirmation. After code changes, the agent is responsible for running linters and tests to ensure code quality.

---

## 3. Agent Responsibilities Matrix

| Domain                           | Responsibility                                                                           | Key Activities                                                                                                                                                                                                                                                                                                                      |
| :------------------------------- | :--------------------------------------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Frontend (Flutter)**           | Feature implementation, bug fixes, UI polishing, dependency management.                  | - Read/write `.dart` files. <br> - Run `flutter pub get`. <br> - **Adhere to the strict file naming convention for module files: `module_submodule_page.dart` (e.g., `sales_customers_customer_creation.dart`). This does not apply to root files like `main.dart` or `app.dart`.** <br> - Implement widgets based on design specs. |
| **Backend (NestJS)**             | API endpoint creation/modification, business logic implementation, database integration. | - Read/write `.ts` files for services, controllers, modules. <br> - Create and modify DTOs. <br> - Write and run tests.                                                                                                                                                                                                             |
| **Database (Supabase/Postgres)** | Schema migrations, data seeding, query optimization analysis.                            | - Read/create Drizzle schema migration files (`.sql`). <br> - Write SQL queries to analyze data. <br> - Advise on indexing strategies.                                                                                                                                                                                              |
| **Project Analysis**             | Codebase investigation, bug root-cause analysis, creating documentation.                 | - Use `glob` and `search_file_content` to map the codebase. <br> - Synthesize findings into reports (e.g., this PRD). <br> - Explain complex code sections.                                                                                                                                                                         |
| **Testing**                      | Writing and running unit, widget, and integration tests.                                 | - Identify and run test commands (`flutter test`, `npm run test`). <br> - Create new test files that mirror existing patterns.                                                                                                                                                                                                      |

---

## 4. AI Behavior Contracts

1.  **Mandate Adherence:** The agent MUST rigorously adhere to existing project conventions (coding style, naming, architecture). It will analyze surrounding code before making changes.
2.  **Verification First:** The agent will NEVER assume a library or framework is available. It MUST verify its usage via configuration files (`pubspec.yaml`, `package.json`) or imports.
3.  **Iterative Development:** For any feature or fix, the agent will follow a Test-Implement-Verify loop. It will write or run tests to validate its changes.
4.  **Minimal Viable Changes:** The agent will make the smallest, most targeted changes possible to achieve the user's goal, preferring multiple small `replace` operations over a single large `write_file`.
5.  **Safety and Explicitness:** The agent MUST explain any file system-modifying or command-execution actions before performing them.
6.  **No Assumption:** The agent must not make assumptions about the content of a file without reading it first.

---

## 5. Prompt Strategy

To ensure optimal performance from the AI agent, prompts should be:

- **Specific and Action-Oriented:** "Refactor the `ProductService` to use the `ProductRepository`" is better than "Fix the product code."
- **Context-Providing:** Include relevant file paths, function names, or error messages. Use `@` to reference files.
- **Goal-Oriented:** Describe the desired final state. "The `GET /products` endpoint should return a `404` if the product is not found," is better than "Change the product endpoint."
- **Iterative:** For complex tasks, break them down into smaller sub-tasks and present them to the agent one by one.

---

## 6. Memory Model

- **Short-Term (Context Window):** The agent holds the current conversation, recent tool outputs, and read files in an active context window. This is its primary working memory.
- **Long-Term (User-Directed):** The agent can use the `save_memory` tool to persist specific, user-provided facts across sessions (e.g., "My preferred state management library is Riverpod."). This is for personal preferences, not for project-specific context.
- **Implicit (File System):** The agent's primary "memory" of the project is the file system itself. It is designed to re-read files as needed rather than relying on a potentially stale internal representation.

---

## 7. Tooling & Integrations

**📄 Stack Reference:** See **[`prd_tech_stack.md`](./prd_tech_stack.md)** for the standalone, codebase-verified package inventory, deployment/runtime details, environment variables, and PRD-vs-implementation drift list. This section remains the locked high-level source of truth; `prd_tech_stack.md` should stay synchronized with it whenever dependencies, hosting, or runtime architecture change.

| Component           | Technology                        | Decision & Rationale                                                                                                                                                                                    |
| :------------------ | :-------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Frontend**        | Flutter Web                       | `Riverpod` for state management, `GoRouter` for routing (centralized in `lib/core/routing/app_router.dart`).                                                                                            |
| **Backend**         | NestJS (TypeScript)               | RESTful API. Corrects `prd.md` v1 which listed Next.js.                                                                                                                                                 |
| **Database**        | PostgreSQL                        | Hosted on Supabase.                                                                                                                                                                                     |
| **ORM**             | Drizzle ORM                       | Used for database migrations and queries in the backend.                                                                                                                                                |
| **HTTP Client**     | **Dio only**                      | Standardized on Dio. `http` package is deprecated and must be removed. Dio provides superior features like interceptors, error handling, and timeouts, crucial for an ERP.                              |
| **Local Storage**   | **Hive** & **shared_preferences** | **Decision Locked:** `Hive` is the definitive database for offline data (items, customers, POS drafts). `shared_preferences` is restricted to config-only data (UI flags, theme, last selected branch). |
| **Deployment**      | Vercel                            | Configuration files (`vercel.json`) are present for both frontend and backend.                                                                                                                          |
| **Storage**         | Cloudflare R2                     | For object storage like product images and documents.                                                                                                                                                   |
| **Version Control** | Git                               | Hosted on GitHub, with CI/CD workflows defined.                                                                                                                                                         |

### 7.1 Dependency Management Policy ⚠️ **MANDATORY**

**Rule: Use Latest Stable Dependencies (Caret Ranges Allowed)**

When adding or updating any dependency (npm packages, Flutter packages, system libraries), the following policy MUST be strictly followed:

- **Latest Stable Version Only:** Always use the latest stable (non-beta, non-alpha) version available at the time of addition.
- **No Deprecated Packages:** NEVER add a package that is marked as deprecated or archived. If a current dependency becomes deprecated, it must be replaced immediately with the recommended alternative.
- **Version Ranges:** Use caret ranges as the repo currently does (e.g., `"dio": "^5.9.0"`). Avoid pre-release tags unless explicitly approved.
- **Regular Updates:** Dependencies should be reviewed and updated monthly. Use `flutter pub outdated` and `npm outdated` to identify updates.
- **Security First:** If a security vulnerability is discovered in a dependency, update to the patched version immediately, even if it's a breaking change.

**Verification:**

Before adding any new dependency, the developer/agent MUST:

1. Check the package's repository for maintenance status (last update, open issues)
2. Verify it's not deprecated or archived
3. Check for known security vulnerabilities
4. Confirm it's the latest stable release

**Examples:**

- ✅ **Correct:** Adding `dio: ^5.9.0` when 5.9.0 is the latest stable
- ❌ **Incorrect:** Adding `http: ^0.13.0` (deprecated, use `dio` instead)
- ❌ **Incorrect:** Adding `provider: ^6.0.0` (use `riverpod` per architecture decision)

### 7.1.1 Environment Configuration (Hybrid) 🌍

To support seamless transitions between local development and production deployment, the application MUST adhere to the following environment configuration rules:

1.  **Production (Release Mode):** When deployed (`flutter build web --release`), the app **MUST** automatically point to the hosted backend: `https://zabnix-backend.vercel.app`.
2.  **Development (Debug Mode on Web):** When running locally (`flutter run -d chrome`), the app **MUST** automatically point to the local backend: `http://localhost:3001`.
3.  **Fallback:** If neither of the above specific cases is true (e.g., mobile testing), the app **MUST** respect the `API_BASE_URL` defined in `.env` or passed via `--dart-define`.

**Implementation Reference:** This logic is centralized in `lib/shared/services/api_client.dart`.

---

## 7.2 Project Structure & File Organization 📁

**CRITICAL:** The Zerpai ERP project follows a strict, standardized folder structure for both frontend (Flutter) and backend (NestJS). This ensures:

- Predictable file locations
- Easy onboarding for new developers
- Clear separation of concerns
- Scalable architecture

**📄 Detailed Reference:** See **[`prd_folder_structure.md`](./prd_folder_structure.md)** for the complete folder structure guide, including:

- Frontend structure (`lib/core/`, `lib/shared/`, `lib/modules/`)
- Backend structure (`src/modules/`, `src/common/`, `src/database/`)
- File naming conventions (STRICT snake_case)
- Decision tree: "Where should I put this file?"
- Module internal structure (models/, providers/, presentation/)
- Asset organization
- Test directory structure

**Key Rules (Quick Reference):**

- **App infrastructure** (router, theme, API): `lib/core/`
- **Shell/navigation infrastructure** (sidebar, navbar, shell): `lib/core/layout/`
- **Reusable widgets** (forms, dialogs, layout wrappers, responsive UI): `lib/shared/widgets/`
- **Cross-feature services**: `lib/shared/services/`
- **Feature-specific code**: `lib/modules/<module>/`
- **File naming**: `module_submodule_page.dart` (e.g., `items_pricelist_pricelist_creation.dart`, `sales_orders_order_creation.dart`). Avoid `_screen` suffixes unless required for clarity.

**⚠️ ALL new code MUST follow this structure. See the detailed guide for full compliance.**

---

## 8. User Experience Flow

### 8.1 Sidebar Navigation Model (LOCKED)

The primary navigation is a Zoho-style collapsible sidebar. Current order (as implemented in `lib/core/layout/zerpai_sidebar.dart`):

1.  Home
2.  Items
    - Items
    - Composite Items
    - Item Groups
    - Price Lists
    - Item Mapping
3.  Inventory
    - Assemblies
    - Inventory Adjustments
    - Picklists
    - Packages
    - Shipments
    - Transfer Orders
4.  Sales
    - Customers
    - Retainer Invoices
    - Sales Orders
    - Invoices
    - Delivery Challans
    - Payments Received
    - Sales Returns
    - Credit Notes
    - e-Way Bills
5.  Purchases
    - Vendors
    - Expenses
    - Recurring Expenses
    - Purchase Orders
    - Bills
    - Recurring Bills
    - Payments Made
    - Vendor Credits
6.  Accountant
    - Manual Journals
    - Recurring Journals
    - Bulk Update
    - Transaction Locking
    - Opening Balances
7.  Accounts
    - Chart of Accounts
8.  Reports
9.  Documents
10. Audit Logs

Settings is a global routed area, but it is not part of the primary sidebar module stack.

### 8.2 Sales Workflow (STRICT)

The sales process follows a strict, status-driven lifecycle:
`Quotation` → `Sales Order` → `Invoice` → `Payment`

- Each step corresponds to a distinct database table.
- Inventory stock level is reduced ONLY upon **invoice confirmation**.
- The Point of Sale (POS) interface is a "mode" that can create invoices directly.

### 8.3 Purchase Workflow (STRICT)

The purchase process also follows a strict lifecycle:
`Purchase Order` → `Receipt` → `Bill` → `Payment`

- Inventory stock level is increased ONLY upon **goods receipt**.
- Financial totals are affected by Bills, not Purchase Orders.

### 8.4 POS Mode (CRITICAL)

The Point of Sale interface is a critical, performance-sensitive feature.

- **Design:** Keyboard-first, optimized for rapid data entry.
- **Performance:** Aims for near-zero API calls per keypress during a transaction.
- **Offline:** Must function during minor internet disruptions. It reads data from a local `Hive` database and syncs transactions in the background.

---

### 8.5 UI System & Design Governance

To ensure a consistent and professional look across the application, all UI components MUST adhere to the centrally defined theme and design governance rules.

**Rule:** See **Section 14: UI SYSTEM & DESIGN GOVERNANCE (GLOBAL)** for strict requirements on colors, typography, tables, and interaction behavior.
**Surface Rule:** All modal, popup, dropdown, menu, date-picker, popover, and overlay surfaces must default to pure white `#FFFFFF`; inherited Material tinting is not allowed unless explicitly approved in the design.

---

## 9. Reporting Requirements (V1)

### 9.1 Sales Report

- **Fields:** Invoice No, Invoice Date, Customer Name, GSTIN, Branch, Taxable Amount, CGST, SGST, IGST, Total Amount, Payment Status.
- **Filters:** Date range, Branch, Customer, Invoice status.
- **Exports:** CSV, Excel (XLSX).

### 9.2 Inventory Report

- **Fields:** Product Name, Product Code, Category, Current Stock, Reorder Level, Stock Value (cost-based), Branch.
- **Filters:** Branch, Category, Low stock only (checkbox).
- **Exports:** CSV, Excel.

### 9.3 GST Report (GSTR-1 Ready)

- **Fields:** Invoice No, Invoice Date, Customer GSTIN, Place of Supply, HSN Code, Taxable Value, CGST, SGST, IGST.
- **Filters:** Month, Branch.
- **Exports:** CSV (in GSTR-1 compatible structure), Excel.

### 9.4 Reporting Non-Goals (V1)

- NO custom report builder.
- NO real-time analytics or graph-heavy dashboards.
- NO direct/automatic GST filing with government portals.

---

## 10. Error Handling

### 10.1 Application Error Handling

- **Frontend:** User-facing errors (e.g., failed API calls, validation issues) will be displayed in non-intrusive snackbars or inline messages.
- **Backend (NestJS):** The backend uses standard NestJS exception filters. Business logic errors will return appropriate `4xx` status codes. Unhandled server errors will return a `500`. DTOs with `class-validator` handle request payload validation.

### 10.2 Agent Error Handling

- **Tool Failures:** If a tool fails, the agent will report the failure, re-read the relevant file to get fresh context, and attempt a corrected action.
- **Command Failures:** If a shell command fails, the agent will analyze `stderr` and `stdout` to diagnose the cause and attempt to fix the issue.

---

## 11. Security & Compliance

### 11.1 Authentication (Auth-Ready)

There is no active authentication in the dev stage. However, the architecture is prepared for it:

- **Database:** Schema includes `created_by_id` and `updated_by_id` fields.
- **Backend:** A `Guard` and `Strategy` (e.g., for JWTs) can be added as middleware.
- **Frontend:** The `supabase_flutter` library is included, ready for auth configuration.

- **Mandatory Columns:** Every business-owned table has an `entity_id` column (UUID, NOT NULL) that references the `organisation_branch_master.id`. This provides unified, polymorphic scoping for both Head Office and Branch entities.
- **Tenant Master:** The `organisation_branch_master` table acts as the canonical registry for all entities, with `type` (ORG/BRANCH) and `ref_id` (pointing to the specific `organization` or `branches` record).
- **RLS Policies:** RLS policies are developed alongside features but are **explicitly disabled** during the dev stage for simplicity. They will be activated before production.

### 11.3 Compliance

- **GST:** All relevant tables include fields for GSTIN, HSN codes, and tax rates. Calculations must be precise.
- **E-Way Bill:** The system will store data required for E-Way bills, but V1 will not integrate with government APIs.

---

## 12. Model Strategy

### 12.1 Data Model (Database)

**Decision Locked:** The database model is built for SaaS multi-tenancy from day one.

- **Products are Global:** The `products` table is a global resource, meaning a single product definition is available to all organizations on the platform. It does NOT contain an `entity_id`. This allows for a centralized product master. Organization-specific inventory and pricing will be handled in separate, branch-specific tables (e.g., `branch_inventory`).
  **Frontend Terminology Note:** The frontend UI and module naming uses **Items**, but the database and API must continue to use the global **`products`** table. Do not introduce a new `items` table or rename `products`; all UI "Item" flows map directly to `products`.

  ```sql
  -- Simplified Final Structure
  CREATE TABLE products (
    id UUID PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    item_code VARCHAR(100) NOT NULL,
    -- ... other global product fields
    UNIQUE(item_code)
  );
  ```

- **`items` Table is Deprecated:** The `items` table found in older schema versions is now deprecated. All new development must use the global `products` table.
- **Transactions are Entity-Scoped:** Sales (`invoices`), Purchases (`bills`), and other transactional records remain strictly scoped to an entity and MUST contain an `entity_id`.
- **Normalization:** The schema remains highly normalized with numerous lookup tables (`units`, `categories`, `brands`, etc.). The scoping of these tables (global vs. org-specific) will be decided on a case-by-case basis.

#### Options / Master Tables Naming (Effective Immediately)

If any options table / master lookup table is created in the database (dropdown options, selectable lists, static reference data), the table name MUST start with the owning module name.

- **New Table Naming (Mandatory):** All **current and future** tables created from this point forward must use the prefix format  
  `<module_name>_<table_name>` (snake_case). **Do not rename existing tables.**

**Naming Format**

`<module_name>_<options_descriptor>`

**Examples**

- `accounts_transaction_types`
- `accounts_account_categories`
- `inventory_item_units`
- `inventory_item_statuses`
- `reports_filter_fields`
- `reports_group_by_options`
- `settings_organization_profiles`
- `settings_company_id_labels`

**Scope & Enforcement**

- ✅ Applies to **ALL NEW TABLES** created from now onward
- ✅ Settings-owned tables are a mandatory special case and must always use the `settings_` prefix
- ❌ Do **NOT** rename or modify existing production tables
- 🔒 Existing schema remains untouched until a planned production refactor phase

**Future Note**
At a later production stage, existing tables may be renamed to comply with this convention as part of a controlled migration. This change is explicitly deferred and not part of the current scope.

#### 12.1.1 Global Entity Governance (HO-Branch Hierarchy)

1. **Read-Only Master:**
   - The products table is a HO-managed Global Master.
   - Branches (Tenant Level): Have Read-Only access. They are strictly prohibited from editing global fields (Item Name, SKU, HSN, etc.) directly in the master table.

2. **Workflow: product_requests**
   - If a branch requires a product not present in the global master, they must initiate a Product Request.
   - Logic: The request is stored in product_requests. Only users with Head Office (HO) privileges can approve these requests to merge them into the global products table.

3. **Entity-Specific Overrides:**
   - Pricing: Branches manage their specific selling rates via the Price List module.
   - Discounts: Branches apply discounts only at the point of transaction (Sales Order/Invoice).
   - Stock: Scoped to the `branch_inventory` table to ensure physical stock isolation.

### 12.2 State Model (Frontend)

- **State Management:** `Riverpod` is the sole state management solution.
- **Data Flow:** The application is **online-first**. UI should assume data is being fetched from the API via `Dio`.
- **Offline Capability:** To handle minor internet disruptions, fetched data (products, customers, etc.) is persisted to local `Hive` boxes. UI reads from the `Hive` cache for speed and resilience, while background processes handle API synchronization.

### 12.3 Schema Snapshot Compliance (MANDATORY)

- **Schema Reference:** `PRD/prd_schema.md` is the current schema snapshot.
- **Form Mapping:** Every creation/edit form must map to the corresponding table(s) in the schema snapshot.
- **No Drift:** Do not invent fields or tables outside the snapshot without a schema update.
- **Updates:** Schema will be updated periodically; refresh the snapshot when DB changes.
- **Destructive DB Safety (Mandatory):**
  - **Always run `npm run db:pull` first** before creating or altering tables, and generate changes based on the pulled schema.
  - **If a table exists in the DB but not in the schema snapshot, assume it was created by another developer. Do NOT delete or alter it.**
  - Be extra cautious with destructive commands (drop/alter). Default to non-destructive changes.

---

## 13. Implementation Plan & Risks

### 13.1 Immediate Implementation Priorities

This PRD represents the complete V1 feature set. There are no phases for the core logic. The following must be implemented:

1.  **Database Schema Alignment:** Immediately ensure the `products` table is treated as a global resource, shared across all organizations. Any logic attempting to scope products by `entity_id` must be removed. The deprecated `items` table must be removed in a new migration. All other business-owned tables (e.g., `invoices`, `customers`) must still have an `entity_id`. Use the development organization's `entity_id` for testing.
2.  **HTTP Client Refactor:** Immediately deprecate the `http` package. All new API calls must use `Dio`. Create a single `api_client.dart` and refactor existing calls out of `http`.
3.  **Storage Strategy Implementation:** Immediately restrict `shared_preferences` to config only. All new offline data caching for entities like items, customers, and drafts must use `Hive`.
4.  **Full Feature Scope:** Implement the complete Inventory, Sales, Purchases, and Reporting modules as defined in this document.

### 13.2 Risks & Mitigations

- **Risk: Offline Complexity.** Syncing logic between the API and Hive can be complex.
  - **Mitigation:** Develop a robust, reusable repository pattern that abstracts away the Hive/API data sources. Prioritize sync logic for the POS workflow first.
- **Risk: Auth-Ready "Debt".** Adding auth later could still be difficult.
  - **Mitigation:** Write integration tests that simulate multiple `entity_id`s to ensure queries are correctly isolated, even without real authentication.
- **Risk: Performance Bottlenecks.** \* **Mitigation:** Implement aggressive pagination on all list views from the start. Use database query logging and analysis. Profile Flutter widget build times regularly.

---

## 14. UI SYSTEM & DESIGN GOVERNANCE (GLOBAL)

### 14.1 Design System Ownership (Hard Rule)

All UI colors, typography, spacing, and interaction behavior MUST originate from the centralized theme layer. No screen, widget, or component is allowed to define raw colors, fonts, or spacing inline. Any deviation requires explicit approval and theme update.
**Source of Truth:** `lib/core/theme/app_theme.dart` (Global)

### 14.2 Global Color Palette (STRICT)

| Purpose            | Token Name      | HEX       | Usage Rules                           |
| :----------------- | :-------------- | :-------- | :------------------------------------ |
| Sidebar Background | sidebarColor    | `#1F2633` | Left navigation background only       |
| App Background     | backgroundColor | `#FFFFFF` | All screens, modals, tables           |
| Primary Action     | primaryBlue     | `#3B7CFF` | Primary buttons, links, active states |
| Secondary Action   | accentGreen     | `#27C59A` | Success, confirm, positive indicators |
| Primary Text       | textPrimary     | `#1F2933` | Headings, table values                |
| Secondary Text     | textSecondary   | `#6B7280` | Labels, hints, metadata               |
| Borders / Dividers | borderColor     | `#D3D9E3` | Tables, cards, separators             |

**❌ MUST NOT:**

- Hardcode hex values in widgets.
- Introduce new colors per screen.
- Use opacity hacks instead of theme tokens.

### 14.3 Typography Rules (Non-Negotiable)

| Element        | Size | Weight | Color         |
| :------------- | :--- | :----- | :------------ |
| Page Title     | 18px | 600    | textPrimary   |
| Section Header | 15px | 600    | textPrimary   |
| Table Header   | 13px | 600    | textSecondary |
| Table Cell     | 13px | 400    | textPrimary   |
| Meta / Helper  | 12px | 400    | textSecondary |

**Font Family:** Inter (Global)
**Rule:** No custom fonts per module.

#### 14.3.1 UI Case Standards (MANDATORY)

| UI Element                  | Case Style            | Usage Rules                      | Examples                     | Must Not                                 |
| :-------------------------- | :-------------------- | :------------------------------- | :--------------------------- | :--------------------------------------- |
| Page / Screen Title         | Title Case            | Primary page identifier.         | Create Sales Order           | CREATE SALES ORDER, Create sales order   |
| Section Headings            | Title Case            | Grouping related content.        | Billing Information          | Billing information, BILLING INFORMATION |
| Sidebar Menu Items          | Title Case            | Consistent navigation labels.    | Inventory, Reports           | dashboard, DASHBOARD                     |
| Form Field Labels           | Sentence case         | Description for user input.      | Customer name, Invoice date  | Customer Name, CUSTOMER NAME             |
| Placeholder Text            | Sentence case         | Hint text inside inputs.         | Enter customer name          | Enter Customer Name                      |
| Primary / Secondary Buttons | Title Case            | Action-oriented, no punctuation. | Save, Create Invoice         | SAVE, save invoice                       |
| Table Column Headers        | Title Case            | Data labels for columns.         | Item Name, Unit Price, SKU   | Item name, ITEM NAME                     |
| Table Cell Values           | Sentence case / As-is | Displaying actual data.          | Pending, Paid                | PENDING                                  |
| Status Labels (Badges)      | Sentence case         | Short system-generated states.   | Draft, Partially delivered   | PARTIALLY DELIVERED                      |
| Helper Text                 | Sentence case         | Supporting guidance.             | This field is required       | This Field Is Required                   |
| Validation Errors           | Sentence case         | Human-readable errors.           | Enter a valid GST number     | Enter A Valid GST Number                 |
| Toast / Snackbar Messages   | Sentence case         | System feedback.                 | Invoice created successfully | INVOICE CREATED                          |
| Dialog Titles               | Title Case            | Modal or dialog headers.         | Delete Invoice               | Delete invoice                           |
| Dialog Body Text            | Sentence case         | Explanatory or warning text.     | This action cannot be undone | This Action Cannot Be Undone             |
| Empty State Messages        | Sentence case         | Informational text.              | No items found               | No Items Found                           |
| Tooltips                    | Sentence case         | Brief explanatory text.          | Click to refresh data        | Click To Refresh Data                    |

**Global Enforcement Rules:**

- **ALL CAPS is strictly prohibited** in UI text, except standard abbreviations (GST, SKU, ID).
- Case must never be used as a styling tool; use font weight or color instead.
- Mixed casing on the same screen is not allowed.
- User-entered data must be displayed exactly as entered.
- Any deviation requires explicit UX approval.

**PRD One-Line Principle:**
Destinations use Title Case. Instructions use sentence case. Actions use Title Case. Data stays untouched.

#### 14.3.2 Data Casing Policy (MANDATORY)

**1. Purpose**
Maintain data integrity and visual consistency without mutating user-entered data.

**2. Storage Rule (Non-Negotiable)**

- **Descriptive Data:** Store precisely as entered. No automatic mutation.
- **Identifiers:** Only identifiers (SKU, Item Code, HSN, GSTIN, System-generated refs) may be stored/enforced in UPPERCASE.

**3. Uppercase Display Rules**

| Context                 | Policy                        | Rationale                                        |
| :---------------------- | :---------------------------- | :----------------------------------------------- |
| **Tables / Lists**      | ✅ Allowed (Display-only)     | Optimized for scanning speed.                    |
| **Forms (Create/Edit)** | ❌ Strictly Prohibited        | Higher cognitive load; misleading about storage. |
| **Detail Screens**      | ⚠️ Limited & Controlled       | Allowed for headlines only; prefer Title Case.   |
| **PDFs / Invoices**     | ❌ Prohibited for descriptive | Legal and print readability requirements.        |
| **Exports / API**       | ❌ Strictly Prohibited        | System neutral; must be reversible.              |

**4. Design Enforcement Rules**

- Case is a presentation tool, not a data policy.
- Transformation must be display-only and non-destructive.
- **Identifiers** always use enforced uppercase everywhere.

**One-Line Principle:**
Store what the user means. Style what the UI needs. Never confuse the two.

---

#### 14.3.3 Iconography Rules (MANDATORY)

- **Primary Icon Set:** Lucide for ~95% of UI icons.
- **Brand Icons Only:** Use FontAwesome **only** for brand marks (WhatsApp, Google, etc.).
- **Packages:** `lucide_icons` (primary), `font_awesome_flutter` (brands only).

### 14.4 Layout & Spacing System

**Global Spacing Units:**

- Base unit: `8px`
- Allowed spacing only: `4, 8, 12, 16, 24, 32`
- Padding inside cards/tables: `16px`
- Modal padding: `24px`

**❌ MUST NOT:** Arbitrary spacing values are not allowed.

### 14.4.1 Layout Stability Rules (Golden Rules) — MANDATORY

These rules prevent overflow, unbounded constraints, and broken layouts. **All developers and AI agents MUST follow them strictly.**

1. **Expanded Rule (Overflow Fix):** Any child inside a `Row` or `Column` that can grow (e.g., `Text`, `TextField`, `ListView`) **must** be wrapped in `Expanded` or `Flexible` to respect available space.
2. **Scroll Rule (Unbounded Constraints Fix):** **Never** place `Expanded` inside a `SingleChildScrollView` or `ListView` in the same axis. Use `SizedBox`/`ConstrainedBox`, `CustomScrollView`, or `shrinkWrap: true` only when necessary.
3. **Safe Text Rule:** Any text from API/DB must define `maxLines` and `overflow` (e.g., `TextOverflow.ellipsis`) so long strings never break layout.
4. **Responsive Rule (Web Critical):** Avoid fixed pixel widths for major layout regions. Use `Flex`/`Expanded` ratios or `LayoutBuilder` constraints. Fixed widths are allowed only for icons, small controls, or min/max bounds.
5. **Constraint Inspection Rule:** If a layout breaks, check parent constraints first. Preferred hierarchy: `Scaffold -> Column -> Expanded -> Row -> Expanded -> Scrollable` for complex dashboards.
6. **Shared Responsive Foundation Rule:** Web-facing Flutter screens must use the shared responsive foundation rather than ad hoc overflow fixes: global breakpoints, shared responsive table shells for dense tables, shared responsive form rows/grids, shared responsive dialog width rules, and sidebar-aware shell/content metrics.
7. **Deep Linking Rule:** New modules and major internal sub-screens must expose deep-linkable GoRouter routes from the beginning so refresh, direct URL entry, and browser navigation preserve working context instead of dropping users back to a parent page.

### 14.5 Table System (CRITICAL SECTION)

#### 14.5.1 Table Behavior Rules (MANDATORY)

- All tables MUST be horizontally resizable.
- Column widths: Default: Auto, Minimum: 120px, Maximum: Unlimited.
- Column resizing must persist per user (local or server).

#### 14.5.2 Table Structure Rules

| Component | Rule                                   |
| :-------- | :------------------------------------- |
| Header    | Fixed, non-wrapping                    |
| Body Rows | Single-line, ellipsis overflow         |
| Hover     | Light highlight only (no color change) |
| Selection | Checkbox only (no row color inversion) |
| Sorting   | Column header click                    |
| Columns   | Toggleable via column manager          |

#### 14.5.3 Must / Must Not

**✅ MUST:**

- Support column visibility toggling.
- Support horizontal scroll.
- Match column order exactly across views.

**❌ MUST NOT:**

- Freeze widths permanently.
- Hardcode column sizes.
- Create table variants per screen.

#### 14.5.4 Pagination Standards (MANDATORY)

- **Mandatory Pagination:** ALL data tables and list views MUST implement server-side pagination.
- **Default Load:** `100` rows per page by default.
- **Page Size Options:** Users must be able to select from: `10, 25, 50, 100, 200`.
- **UI Components (Footer):**
  - **Total Count:** "Total Count: View" (loads total count only on click to preserve performance).
  - **Rows Selector:** A dropdown showing "[gear icon] X per page".
  - **Navigation:** Previous (`<`) and Next (`>`) arrows with record range display (e.g., `1 - 100`).
- **Implementation:** Pagination must be handled at the Repository/API level using `limit` and `offset` parameters.
- **Background Prefetching:** After the current page data is displayed, the system must background-fetch (queue) the next page's data to ensure instant transitions when the user clicks "Next".

### 14.6 Sidebar & Navigation Rules

**Expansion Behavior (Explicit Rule):**

- Clicking ANYWHERE on a parent menu item expands/collapses it.
- Chevron icon is NOT the only clickable area.
- Parent label, icon, and arrow all trigger expansion.
- **Applies to:** Sidebar, filters, accordions, nested lists.

### 14.13 Master-Detail Adaptive Pattern (Zoho Standard)

#### 1. Primary Navigation Flow (The "Transition" Rule):

- **Initial State:** When a user enters a main module (Items, Customers, Sales Orders, Invoices), the system MUST display a Full-Width Data Table.
- **Trigger:** Clicking on any row within the table triggers the Master-Detail Split View.
- **Split State:**
  - **Master Pane (Left):** The table transforms into a condensed list (30-40% width).
  - **Detail Pane (Right):** The remaining 60-70% width displays the selected record's full details using a tabbed navigation system.
- **Closure:** A "Close" (X) button on the detail pane returns the UI to the Full-Width Data Table state.

### 14.7 Modal & Overlay Rules

| Element       | Rule                           |
| :------------ | :----------------------------- |
| Modal Width   | Adaptive (min 420px)           |
| Background    | Dimmed overlay                 |
| Close         | Explicit close + outside click |
| Primary CTA   | Bottom-left (green/blue)       |
| Secondary CTA | Bottom-right (neutral)         |

**Rule:** No fullscreen modals unless explicitly required.

### 14.8 Reusability & Extensibility

- All UI patterns must be built as reusable components.
- No “one-off” UI logic inside screens.
- Tables, filters, dropdowns, menus must be drop-in compatible.

### 14.9 AI Development Enforcement Prompt

The AI agent must strictly follow the global UI system defined in `app_theme.dart`. No colors, spacing, fonts, or table behaviors may be hardcoded. All tables must support resizable columns and visibility control. Sidebar and expandable menus must expand on full-row click, not arrow-only. Any UI deviation must be rejected and corrected.

### 14.10 Future Safety Rule

- Existing production UI must not be altered.
- Improvements apply only to new or refactored modules.
- Migration will be handled separately at production stage.

### 14.11 Menu & Dropdown System (Unified Refactor)

To ensure a modern and consistent user interface, the application has standardized its menu and dropdown architecture:

- **MenuAnchor:** All legacy `PopupMenuButton` instances MUST be refactored to use `MenuAnchor`. This is the standard for all action-based menus and triggers.
- **MenuItemButton:** Use standard `MenuItemButton` widgets for children within a `MenuAnchor`.
- **FormDropdown:** For all form-based inputs and selections, use the `FormDropdown` component (defined in `dropdown_input.dart`). Do not use `MenuAnchor` or `DropdownButton` for form inputs.
- **Hover States:** Rely on the native hover and focus states of `MenuItemButton`. Custom implementations like `_HoverableMenuItem` are deprecated and should be removed.

### 14.12 Form UI System (Creation/Edit Pages) — MANDATORY

These rules define the visual and interaction standards for all **creation/edit pages** (e.g., New Customer, New Invoice). **All developers and AI agents MUST follow them strictly.**

#### 14.12.1 General Layout & Grid System

- **Sidebar Navigation (Left):** Dark theme (~`#2C3E50`). Accordion pattern; clicking parent expands children. Active tab uses green accent (~`#22A95E`) with a lighter background block.
- **Main Canvas (Right):** Light theme (white cards on very light gray background).
- **Header (Top):** Minimal; document title, breadcrumbs, and window controls (Close/Maximize).
- **Global Search:** Context-aware placeholder with keyboard shortcut hint (`/`).
- **Recent History:** Clock icon showing the last 5–10 visited records.
- **Form Alignment:** Left-aligned horizontal labels, fixed label column width, fluid input column.
- **Gutter:** Clear whitespace between label column and input column.
- **Sectioning:** Logical blocks separated by whitespace (avoid heavy borders).

#### 14.12.2 Input Fields & Text Entry

- **Standard Inputs:** Rectangular, slight radius (3–4px), thin light-gray border (~`#E0E0E0`), consistent height (~36px).
- **Focus State:** Blue or green border/glow to indicate focus.
- **Required Fields:** Red asterisk; label often red.
- **Text Areas:** Multi-line with resize handle (bottom-right diagonal lines). Optional helper text like "Max 500 characters".
- **Compound Inputs:** Multiple related fields on one row (e.g., [Salutation] [First Name] [Last Name]) with tight spacing.
- **Input Adornments:** Numeric fields with attached gray unit dropdowns on the right (e.g., kg, cm).
- **Numeric Restriction:** Fields expecting digits (Quantity, Rate, Price, Tax %, HSN, etc.) MUST NOT accept alphabetic characters. Validation/Formatters must be used to block non-numeric input at the source.

#### 14.12.3 Dropdowns & Select Menus

- **Standard Select:** White box with right chevron; placeholder in light gray.
- **Searchable Select (Autocomplete):** Input + dropdown; often paired with a green search/lookup button on the right.
- **Dropdown Content:** Grouped items; richer rows with status circle, primary line (name/code), secondary line (company/code).
- **Date Picker:** Field with calendar icon; dropdown panel with month/year header, arrows, 7-column grid, highlighted active date, and subtle "today" indicator.

#### 14.12.4 Tabular Input (Item Table)

- **Headers:** Uppercase, bold, small font (ITEM DETAILS, QUANTITY, RATE, TAX, AMOUNT).
- **Hardware Integration:** “Scan Item” button with barcode icon above table headers.
- **Context Filters:** Table-level selectors (e.g., Warehouse, Price List) between section header and grid.
- **Rows:** Empty-state row shows placeholder image + text ("Type or click to select an item.").
- **Inline Editing:** Text appears static until clicked.
- **Numeric Columns:** Right-aligned (quantity/rate/amount).
- **Row Actions:** On hover, show red delete (x) and drag handle (dotted grid) at far right.
- **Bulk Action:** "Add items in Bulk" below table.

#### 14.12.5 Tabs & Internal Navigation

- **Horizontal Tabs:** Text-only; selected state uses blue text + blue underline; default state is gray.
- **View Switcher Dropdown:** "All [Module]" dropdown with favorite star; list items show blue link styling.

#### 14.12.6 Buttons & Actions

- **Primary Action:** Green (~`#22A95E` to `#28A745`), white text, rounded corners.
- **Split Button:** Primary action with dropdown for alternatives (e.g., Save & Send).
- **Secondary Action:** Neutral/gray or outline; cancel is link/ghost.
- **Utility Icons:** Small gear/settings icons beside specific fields (outlined blue/gray).

#### 14.12.7 Feedback & Status Indicators

- **Info Icons:** Small "i" inside a circle; hover shows tooltip.
- **Inline Hints:** Gray helper text inside/below fields.
- **Status Tags (List View):** Colored text (no pill). APPROVED=Blue, RECEIVED=Green.
- **Validation:** Red input border + red error text below.

#### 14.12.8 Visual Language Summary

- **Font:** Sans-serif (high legibility).
- **Colors:** Primary=Green (actions), Secondary=Blue (links/selection), Alert=Red (required/delete).
- **Density:** High density, compact spacing for power users.

#### 14.12.8.1 Zoho Visual Language Tokens (Mandatory)

- **Page Background:** Pure white `#FFFFFF`.
- **Input Fill:** `#FFFFFF` (pure white, matching page background).
- **Dialog / Dropdown / Overlay Surface:** `#FFFFFF` only.
- **Input Border:** `#E0E0E0` (light gray).
- **Table Header Background:** `#F5F5F5`.
- **Primary Blue:** `#0088FF` (checkboxes, selected cards, active borders).
- **Required Asterisk:** `#D32F2F`.

#### 14.12.8.2 Form Field Specification (Greyed Boxes)

- **Label Column:** Fixed width ~160px, left-aligned, text color `#444444`.
- **Input Decoration (Flutter):**

```dart
InputDecoration(
  filled: true,
  fillColor: Color(0xFFFFFFFF),
  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
    borderRadius: BorderRadius.circular(4),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Color(0xFF0088FF), width: 1.5),
    borderRadius: BorderRadius.circular(4),
  ),
)
```

#### 14.12.8.3 Zoho UI/UX Spec Addendum (STRICT COMPLIANCE)

**Global Design Tokens**

| Element                 | Specification   | HEX / Value |
| :---------------------- | :-------------- | :---------- |
| Page Background         | Pure White      | `#FFFFFF`   |
| Input Fill Color        | Pure White      | `#FFFFFF`   |
| Dialog / Dropdown / Overlay Surface | Pure White | `#FFFFFF` |
| Border Color (Default)  | Light Grey      | `#E0E0E0`   |
| Border Color (Active)   | Zoho Blue       | `#0088FF`   |
| Primary Brand Color     | Zoho Blue       | `#0088FF`   |
| Success / Save Button   | Green           | `#28A745`   |
| Required Field Label    | Dark Red        | `#D32F2F`   |
| Primary Text Color      | Dark Charcoal   | `#444444`   |
| Secondary/Helper Text   | Medium Grey     | `#666666`   |
| Table Header Background | Light Tint Grey | `#F5F5F5`   |
| Border Radius           | Standard Radius | `4px`       |

**Layout & Spacing**

- **Form Label Width:** 160px fixed.
- **Row Spacing:** 20px between form rows.
- **Table Cell Padding:** 8px vertical / 12px horizontal.
- **Page Margins:** 24px padding on main scaffold area.
- **Field Max Width:** 400px for Percentage / Round Off / Currency fields.

**Component Specs**

- **White Box Input:** `filled: true`, `#FFFFFF` fill, `#E0E0E0` border, `#0088FF` focus at 1.5px.
- **Prefix/Suffix:** Currency symbols (₹, $) as `prefixText` inside the grey box; numbers right-aligned.
- **Selection Cards:** Selected = `#F0F7FF` bg, `#0088FF` border, blue check icon. Inactive = `#F9F9F9` bg, `#E0E0E0` border.
- **Dropdown Overlay:** Elevation 8 (shadow ~`rgba(0,0,0,0.15)`), selected row `#0088FF` with white text, check icon on far right.
- **Dropdown Search:** Only for Currency/Item dropdowns; disabled for Markup/Markdown and Round Off.

**Dynamic Table Logic (Price List)**

- **Unit Pricing Columns:** ITEM DETAILS | SALES/PURCHASE RATE | CUSTOM RATE.
- **Volume Pricing Columns:** ITEM DETAILS | SALES/PURCHASE RATE | START QTY | END QTY | CUSTOM RATE.
- **Ranges:** Stack within a single item row; “+ Add New Range” aligns left of quantity columns.
- **Alignment:** Item details left; rates/quantities right-aligned (`TextAlign.right`).

**Visibility Matrix**

| Component           | All Items | Individual Items |
| :------------------ | :-------- | :--------------- |
| Description         | Visible   | Visible          |
| Percentage (Markup) | Visible   | Hidden           |
| Round Off To        | Visible   | Hidden           |
| Currency Selection  | Visible   | Visible          |
| Items Data Table    | Hidden    | Visible          |
| Discount Checkbox   | Hidden    | Visible          |

**Interactive Behaviors**

- **Bulk Update Modal:** Horizontal row (Dropdown + Dropdown + “by” + Input + Dropdown). Footer buttons right-aligned (Update green, Cancel neutral).
- **Discount Helper Text:** Visible only if discount checkbox is true; blue, 12px, italic, directly below checkbox label.
- **Round Off Popover:** “View Examples” opens floating card with arrow and static examples table.
- **Currency Dropdown:** Searchable; selection updates all currency prefix texts in the table.

**Typography**

- **Primary Font:** Inter or Roboto.
- **Main Labels:** 14px, w500.
- **Table Body:** 13px, normal.
- **Table Headers:** 12px, bold, ALL CAPS.
- **Helper Text:** 12px, regular.

**Backend Payload (Next.js)**

- **Unit Pricing:** Single `custom_rate` number.
- **Volume Pricing:** `ranges[]` array with `{ start, end, rate }`.

#### 14.12.8.4 Dropdown Menu Zero-Tolerance Rules (STRICT)

**Box Rule (Width & Alignment)**

- **Max Width:** `400px` for dropdown overlays.
- **Alignment:** Left edge aligns to the input field’s left edge (no full-width stretch).

**Color & Border Reset**

- **Background:** `#FFFFFF` only.
- **Selected Bar:** `#0088FF` with white checkmark on far right.
- **Hover:** `#F5F5F5`.
- **Border:** 1px solid `#E0E0E0` around menu, subtle shadow (elevation ~4).

**Vertical Density**

- **Row Height:** 36–40px per item.
- **Padding:** `EdgeInsets.symmetric(horizontal: 12, vertical: 0)`.

**Layout Stability**

- **Label Width Lock:** Left labels (e.g., “Round Off To”, “Currency”) stay fixed at 160px and must not shift when menus open.

#### 14.12.9 Right Utility Bar (Collapsible Sidebar)

- **Right Utility Bar:** Fixed-position vertical icon strip at far right with a light-gray divider.
- **Icons:** Help (?), Updates (megaphone), Feedback (chat), App Switcher (grid), User Avatar.
- **Behavior:** Clicking an icon opens a right-side slide-out panel (overlay, no page navigation).

#### 14.12.10 Swap Interaction (Transfer Order)

- **Swap Control:** Circular two-arrow icon between Source/Destination warehouse fields.
- **Behavior:** Clicking swaps the values of the two dropdowns.
- **Placement:** Sits in the gutter between columns to imply it affects both fields.

#### 14.12.11 Inside-Input Actions (Config Gear)

- **Embedded Gear:** Gear icon appears **inside** the input on the right edge (auto-number fields).
- **Meaning:** Field is auto-generated; gear opens configuration (prefix/sequence), not manual input.

#### 14.12.12 Advanced Table Row Actions (Kebab Menu)

- **Row Actions:** Red delete (x), drag handle, and vertical ellipsis (⋮) for advanced options.
- **Menu Options:** Clone row, add description row, show additional fields (discount, serial, etc.).

#### 14.12.13 Breadcrumb & Back Navigation

- **Header Pattern:** Module Icon → Back Arrow → Page Title.
- **Behavior:** Back arrow returns to the list view (one-click up).

#### 14.12.14 Dropdown Visual Hierarchy (Rich List)

- **Active Row:** Blue background (~`#408DFB`) with white text.
- **Scrollbar:** Slim floating scrollbar (webkit-style).
- **Row Layout:** Primary line (bold/normal) + secondary line (smaller/gray).

#### 14.12.15 Placeholder Date Formatting

- **Format Hint:** Empty date fields show `dd-MM-yyyy` as placeholder.

#### 14.12.16 Currency Prefix Alignment

- **Prefix:** Currency symbol (₹/INR) outside the input or non-editable prefix.
- **Alignment:** Totals column aligns currency symbols vertically for clean numeric columns.

#### 14.12.17 Checkbox Grouping (Progressive Disclosure)

- **Checkbox Style:** Standard square checkbox with label to the right.
- **Behavior:** Certain checkboxes appear only when relevant (indented, progressive disclosure).

#### 14.12.18 Link Styling in List Views

- **Primary Identifier:** Blue link (e.g., Order # / RMA #) navigates to document.
- **Secondary Data:** Black/gray text; may be non-clickable or filter-only.
- **Sort Indicators:** Column headers show up/down arrows on hover/active.

#### 14.12.19 Draft vs Live Status Visuals

- **Save as Draft:** Neutral/gray (low urgency).
- **Save and Send:** Green (high urgency).
- **Cancel:** Text-only, no background (escape hatch).

#### 14.12.20 Organization Switcher (Tenant Selector)

- **Location:** Top-right header, near the primary “New (+)” action.
- **Design:** Dropdown text link showing current org (e.g., “ZABNIX PRIVATE L...”).
- **Behavior:** Switches between organizations without logout (multi-entity support).

#### 14.12.21 Master Checkbox (Bulk Selection)

- **Header Checkbox:** Far-left of table header.
- **Logic:** Unchecked = none, checked = all visible rows, indeterminate (dash) = partial selection.

#### 14.12.22 Sidebar Hamburger Toggle

- **Location:** Top-left near logo.
- **Behavior:** Collapses sidebar to icon-only mini mode to expand canvas width.

#### 14.12.23 Semantic Status Colors (Text-Only)

- **Approved/Open:** Blue text.
- **Received/Closed:** Green text.
- **Draft/Void:** Black/gray text.

#### 14.12.24 Round Off Logic (Footer Calculation)

- **Row Placement:** Between Subtotal and Total.
- **Behavior:** Auto-calculates rounding difference; optionally editable for manual adjustment.

#### 14.12.25 Reference # vs Order Number

- **Order Number:** Auto-generated; uses gear/config and is typically non-editable.
- **Reference #:** User-entered customer PO/reference field (standard text input).

#### 14.12.26 Attachment Module

- **Section:** “Attach File(s) to Transfer Order” (or equivalent).
- **Controls:** Upload button with cloud/arrow icon; dropdown source selector.
- **Constraints:** Microcopy shows limits (e.g., max 5 files, 10MB each).

#### 14.12.27 Currency & Locale Indicators

- **Currency Code:** Displayed as INR where applicable.
- **Formatting:** Two decimal places (0.00) and right-aligned numeric columns with aligned decimals.

#### 14.12.28 Guided Action Links (Empty States)

- **Empty State CTA:** Instructional text + a single action button (e.g., “Add Items”).
- **Behavior:** Guides users to the next required step, not a blank table.

#### 14.12.29 Active Tab Sidebar Indicator

- **Visual:** Vertical green bar on far left edge of the active sidebar item.
- **Purpose:** Clear active state via position + color.

#### 14.12.30 Mandatory Label Styling

- **Rule:** Entire label text turns red for required fields (not just the asterisk).

#### 14.12.31 Terms Dropdown Logic

- **Behavior:** Selecting payment terms (e.g., Net 15/Net 360) auto-updates Due Date.
- **Type:** Trigger input (changes dependent fields).

#### 14.12.32 PDF Template Switcher (Footer)

- **Location:** Bottom-right footer of creation forms (e.g., Retainer Invoice, Delivery Challan).
- **Design:** “PDF Template: Standard Template” with a Change action.
- **Behavior:** Pre-save print configuration (template selection before saving).

#### 14.12.33 Just-in-Time Stock Visibility

- **Location:** Under item table in Transfer Order.
- **Design:** “CURRENT AVAILABILITY” with Source Stock / Destination Stock.
- **Behavior:** Real-time population based on selected items; prevents invalid transfers.

#### 14.12.34 HSN Lookup (External Search)

- **Location:** Item creation → HSN Code field.
- **Design:** Blue magnifying-glass icon (distinct from dropdown chevron).
- **Behavior:** Opens modal/global lookup (external GST/HSN database).

#### 14.12.35 Rich-Content Dropdowns (Card List)

- **Location:** Package / Sales Order selection dropdowns.
- **Design:** Micro-card items with left badge, blue primary line, gray secondary line.
- **Purpose:** Disambiguate similar IDs quickly.

#### 14.12.36 Progressive Disclosure (Toggle Checkboxes)

- **Location:** Item creation → Sellable / Purchasable.
- **Behavior:** Toggles visibility of Sales/Purchase info blocks to reduce clutter.

#### 14.12.37 Dynamic Primary Button Text

- **Behavior:** Primary CTA text changes by module context (e.g., “Save and Send”, “Generate picklist”).
- **Goal:** Action-oriented labeling for clarity.

#### 14.12.38 Inventory Tracking Shortcut

- **Location:** Sales Order footer (right).
- **Design:** Small blue link with box icon (“Inventory Tracking”).
- **Behavior:** Cross-module quick view of stock history/availability.

#### 14.12.39 GST/Tax Trigger Fields

- **GST Treatment:** Controls GSTIN visibility/required state.
- **Place of Supply:** Auto-populates from address, allows override.

#### 14.12.40 Live Chat Integration

- **Locations:** Bottom bar (“Smart Chat”), sidebar (“Chats”).
- **Behavior:** Internal chat/command palette; `Ctrl+Space` hint for quick access.

---

## 15. File Naming Convention (STRICT)

All files MUST follow the following format:

- eg if its sales module customer option customer create page: `sales_customers_customer_creation.dart`
- sales module customer option customer overview page: `sales_customers_customer_overview.dart`
- All files (current and future) MUST adhere to this pattern.

---


## 14. Development Consistency Standards

To maintain code quality, readability, and a cohesive development workflow across a team, the following standards are to be adopted.

### 14.1 Automated Code Formatting

To eliminate debates about style, formatting is automated and non-negotiable.

- **Flutter (Dart):** The standard `dart format` tool is the source of truth. It should be run before committing. A CI check will fail any PR that contains unformatted code.
- **Backend (TypeScript):** **Prettier** is used for automated formatting. A `.prettierrc` configuration file will be maintained in the `backend` directory.

### 14.2 Static Analysis & Linting

Code quality is enforced through static analysis.

- **Flutter (Dart):** The project's `analysis_options.yaml` is configured with a strict ruleset. All code must pass `flutter analyze` without errors or warnings.
- **Backend (TypeScript):** **ESLint** is used with a shared `.eslintrc.json` configuration in the `backend` directory.

### 14.3 Conventional Commit Messages

All Git commit messages MUST follow the **Conventional Commits** specification. This improves history readability and enables automated changelog generation.

- **Format:** `<type>(<scope>): <subject>`
- **Examples:**
  - `feat(sales): add validation to the invoice creation form`
  - `fix(inventory): prevent negative stock on direct POS sales`
  - `docs(prd): update theme and color palette section`
  - `refactor(auth): simplify token refresh logic`

### 14.4 Git Branching Strategy

A simplified Git-Flow model is used, with explicit instructions for daily workflow:

- `main`: Contains production-ready code for completed modules. No direct commits are allowed. Merges happen only from the `dev` branch for a release.
- `dev`: The primary development branch. All feature and fix branches are merged here.
- `feat/<feature-name>`: Branches for new features. These branches MUST follow a kebab-case naming convention derived from the feature being developed (e.g., `feat/gstr1-report`, `feat/sales-customer-create-page`).
- `fix/<issue-name>`: Branches for bug fixes. These branches should also follow a kebab-case naming convention (e.g., `fix/pos-sync-error`, `fix/inventory-stock-calculation`).

**Daily Workflow & Commit Discipline:**

1.  All work MUST be done in `feat/*` or `fix/*` branches, adhering to the naming convention.
2.  After completing a module, option, or significant change, and _after_ thorough local testing, the developer/agent MUST push their changes to the respective `feature/<name>` or `fix/<name>` branch.
3.  At the end of each workday (or upon completion of a logical unit of work), all changes from the feature/fix branch MUST be merged into the `dev` branch.
4.  Code gets into `dev` via a **Pull Request**, which must be reviewed by at least one other team member.

### 14.5 Architectural Adherence

All development must adhere to the architectural decisions locked in this PRD. Key points include:

- **State Management:** `Riverpod` is the sole solution for new state management.
- **HTTP Client:** `Dio` must be used for all new API calls.
- **Workflows:** The strict `Sales` and `Purchase` status-driven workflows must be followed.
- **File Naming:** The `module_submodule_page.dart` convention is mandatory for all new module files.

### 14.6 Continuous Integration (CI)

The CI pipeline (GitHub Actions) is the ultimate gatekeeper for code quality. The following checks MUST pass on every Pull Request before it can be merged:

1.  **Code Formatting Check:** Fails if `dart format` or `prettier` would make changes.
2.  **Linting/Static Analysis:** Fails if `flutter analyze` or `npm run lint` reports any issues.
3.  **Automated Tests:** Fails if any tests (`flutter test`, `npm run test`) do not pass.

### 14.7 One-Time Consistency Audit & Refactoring Plan

To bring the existing codebase into compliance with these standards, the following one-time audit and refactoring project will be undertaken. This process requires careful planning and execution to minimize disruption.

**General Guidelines:**

- **Dedicated Branch:** All refactoring work MUST occur in a dedicated `consistency-refactor` (or similar) long-lived branch. This prevents interference with ongoing feature development.
- **Phased Approach:** The entire process will be broken down into manageable phases, with clear communication to all developers and AI agents.
- **Automate Where Possible:** Leverage scripts for bulk formatting, linting fixes, and import updates to minimize manual effort and human error.
- **Regular Syncs:** Maintain frequent merges from `develop` into the refactor branch to avoid merge hell.

# PRD: Zerpai ERP (Phase 1: Foundation & Core ERP)
**Last Updated: 2026-04-20 12:50:00**

**Phase 1: Automated Code Formatting (The Easy Win)**
This step involves running the formatters across the entire project. It's low-risk and provides immediate, widespread consistency.

1.  **Flutter:** Run `dart format .` across the entire `lib` directory.
2.  **Backend:** Configure a `.prettierrc` file in the `backend` directory and run Prettier on all TypeScript files.
3.  **Commit:** All these purely stylistic changes should be committed in a single, dedicated commit with a message like `chore: apply automated formatting to entire codebase`. This keeps them separate from any logic changes.

**Phase 2: Static Analysis & Linting Fixes (Iterative Approach)**
This step addresses code quality warnings reported by the linters. It's best tackled incrementally.

1.  **Analyze Baseline:** Run `flutter analyze` and `npm run lint` to get a comprehensive baseline report of all current violations.
2.  **Initial Fixes:** Address all critical errors (e.g., compile-time errors due to new lint rules) immediately.
3.  **Incremental Rollout:** Instead of fixing everything at once, enable a small set of new, impactful lint rules. Fix all violations introduced by these rules. Repeat this process, enabling more rules and fixing violations, until the desired level of strictness is achieved.
4.  **Prioritization:** Prioritize fixing lint issues in commonly modified or critical modules first.

**Phase 3: File Naming Convention Refactoring (Careful & Surgical)**
This is a manual and delicate process.

1.  **Audit & List:** I can provide an initial audit of the `lib/modules` directory, listing all files that do not conform to the `module_submodule_page.dart` convention.
2.  **Module by Module:** Tackle file renaming one module or even one sub-module at a time.
3.  **IDE Refactoring Tools:** ALWAYS use the IDE's refactoring tools (e.g., Flutter/Dart: "Rename" functionality) to ensure all imports are automatically updated. Avoid manual renaming.
4.  **Verification:** After each module's file renames, ensure the project still compiles and all relevant tests pass before moving to the next.

**Phase 4: Integrate CI Enforcement**
Once the codebase is largely formatted, linted, and renamed according to the new standards, activate the CI gates.

1.  **Update CI Workflows:** Modify the GitHub Actions workflows (as described in Section 14.6) to include jobs that run the formatter, linter, and tests with strict failure conditions.
2.  **Final Merge:** Once the `consistency-refactor` branch is stable, clean, and passes all new CI checks, it can be merged into `develop`. From this point forward, the standards are self-enforcing.

---

## 15. AI Agent Operational Protocol

This section defines the behavior, permissions, and core directives for any AI agent interacting with this project. It supersedes the general guidelines in Sections 2, 4, 6, and 10.2.

**15.1 Core Mandates & Behavior**

1.  **Adherence to Convention:** The agent's highest priority is to rigorously adhere to existing project conventions (coding style, architecture, file naming). It must analyze surrounding code before making any changes.
2.  **Verification Before Action:** The agent must NEVER assume a library, framework, or dependency is available. It must verify its usage via configuration files (`pubspec.yaml`, `package.json`) or by observing imports in existing files.
3.  **Test-Driven Implementation:** For any new feature or bug fix, the agent must follow a Test-Implement-Verify loop. It is expected to write or run tests to validate its changes.
4.  **Explicitness:** The agent MUST explain the purpose of any file system modification or shell command execution before requesting permission to run it.

**15.2 Command & Tool Permissions**

The agent is granted broad authority to use its tools to fulfill tasks, with the following critical exceptions:

- ✅ **Allowed:** Full use of tools for file creation (`write_file`), file modification (`replace`), directory listing (`ls`), directory creation (`mkdir`), code analysis, dependency management (`flutter pub`, `npm`), and version control (`git`).

- ❌ **Strictly Forbidden:** The agent is **NEVER** permitted to execute commands or use tools that perform destructive or permission-altering operations. This includes, but is not limited to:
  - **Deletion:** `rm`, `del`, `rmdir`
  - **Directory Navigation:** `cd` (The agent must always work from the project root and use full or relative paths for all file operations).
  - **Permission Changes:** `chmod`, `chown`, `icacls`.

The agent must find non-destructive alternatives to achieve its goals (e.g., using `write_file` with an empty string to clear a file instead of deleting and recreating it).

**15.3 Memory Model**

- **Short-Term (Context Window):** The agent holds the current conversation, recent tool outputs, and read files in its active context. This is its primary working memory.
- **Long-Term (User-Directed):** The agent may use the `save_memory` tool to persist specific, user-provided facts or preferences across sessions. This is for user personalization, not project context.
- **Implicit (File System):** The agent's primary "memory" of the project is the file system itself. It is designed to re-read files as needed rather than relying on a potentially stale internal representation.

**15.4 Frontend Performance & UI Patterns**

1.  **Performance-First:** All frontend code should be written with performance as a primary consideration. The goal is to create a fast, responsive user experience.
2.  **Skeleton Loading Mandate:** For any page, view, or complex component that fetches data over the network, a **skeleton UI** (e.g., shimmering placeholders that mimic the final layout) **MUST** be displayed while the data is loading. A simple loading spinner is not sufficient for a good user experience in these cases.

**15.5 Agent Error Handling**

- **Tool Failures:** If a tool fails, the agent will report the failure, re-read the relevant file to get fresh context, and attempt a corrected action.
- **Command Failures:** If a shell command fails, the agent will analyze `stderr` and `stdout` to diagnose the cause and attempt to fix the issue.

---

## 16. Environment & Configuration Management

Effective management of environment-specific configuration is critical for consistent development, testing, and deployment across various environments (development, staging, production) and for seamless migration to cloud platforms like AWS or Azure.

### 16.1 Purpose

This section defines the standard for handling environment variables, ensuring that sensitive data and configuration specific to each deployment context are managed securely and consistently without being committed directly into version control.

### 16.2 Required Environment Variables

All necessary application and service configurations should be managed as environment variables. A non-exhaustive list of typical categories includes:

- **Database Credentials:** Supabase URL, Supabase Anon Key.
- **Third-Party API Keys:** Any external service credentials.
- **Application Settings:** Debug flags, base URLs for backend services, feature toggles.
- **Deployment Specifics:** Port numbers, logging levels.

### 16.3 `.env` File Strategy

The project utilizes `.env` files (managed by `flutter_dotenv` for Flutter and `dotenv` for NestJS) to handle environment variables during local development.

- **`.env.example` (Committed):** This file serves as a template. It MUST contain all required environment variable names with placeholder values or default development values. It is committed to version control and kept up-to-date with any new required variables.
- **`.env` (Gitignored - Optional):** Developers can create this file at the project root for shared development configurations that are not sensitive but vary from `.env.example`. This file should generally be empty or contain non-sensitive defaults that are used by all developers unless overridden. This file SHOULD be explicitly `.gitignore`d.
- **`.env.local` (Gitignored - Mandatory):** This file is for local, developer-specific overrides and sensitive information. It MUST NOT be committed to version control. Each developer will maintain their own `.env.local` file based on the `.env.example` template, filling in their specific local development credentials and overrides.

### 16.4 Process for Adding/Changing Variables

1.  **Define:** Any new configuration required by the application MUST first be defined as a new variable in `.env.example` with a placeholder or default value.
2.  **Document:** Briefly document the purpose of the new variable in comments within `.env.example` if its name is not self-explanatory.
3.  **Implement:** Update the application code to read the new variable from the environment.
4.  **Communicate:** Inform the team about the new variable and its purpose, especially if it requires local setup in `.env.local`.

### 16.5 Future Cloud Alignment

For production deployments (AWS, Azure), these `.env` variables will be seamlessly integrated with cloud-native secret management services (e.g., AWS Secrets Manager, Azure Key Vault, AWS Parameter Store). This approach ensures that sensitive credentials are never hardcoded and are managed securely across all environments.

---

## 17. Testing Strategy & Quality Gates

A robust testing strategy is fundamental to delivering high-quality, reliable software. This section outlines the requirements for testing across the Zerpai ERP project.

### 17.1 Testing Philosophy

Quality is a shared responsibility. All code developed for Zerpai ERP must be accompanied by appropriate tests to ensure functionality, prevent regressions, and meet defined quality standards.

### 17.2 Code Coverage Goals

- **Target:** A minimum of **70% code coverage** (line and branch) is required for all new and modified code in both frontend (Dart) and backend (TypeScript) modules.
- **Enforcement:** Code coverage will be measured and enforced via CI pipelines. Pull requests that fall below the defined threshold will be blocked.

### 17.3 Test Types & Requirements

All new features, bug fixes, and significant refactors MUST include relevant tests.

1.  **Unit Tests:**
    - **Purpose:** To verify individual functions, methods, or small classes in isolation.
    - **Requirements:** Mandatory for all business logic (e.g., services, repositories, utility functions), data model transformations, and all `Riverpod` providers (state notifiers, futures, streams).
    - **Focus:** Test inputs, outputs, and edge cases.

2.  **Widget Tests (Flutter Frontend):**
    - **Purpose:** To verify the UI behavior of a single widget or small widget tree.
    - **Requirements:** Mandatory for complex UI components, custom widgets, widgets with user interaction (buttons, forms), conditional rendering logic, or local state management.
    - **Focus:** Ensure widgets render correctly, respond to user input as expected, and update their state appropriately.

3.  **Integration Tests (Backend - NestJS):**
    - **Purpose:** To verify the interaction between multiple components, such as a controller, service, and database interaction.
    - **Requirements:** All new API endpoints MUST have integration tests that validate the full request-response cycle, including request payload validation (DTOs), service business logic, and database operations.
    - **Focus:** Ensure endpoints behave as per contract, handle valid and invalid inputs, and return correct responses.

4.  **End-to-End (E2E) Tests (Future Goal):**
    - **Purpose:** To simulate real user scenarios and interactions across the entire application stack.
    - **Status:** Not a V1 deliverable, but a crucial future goal for validating critical user flows (e.g., a complete POS sale, creating a purchase order, generating a report).

### 17.4 Test File Location Convention

Test files should mirror the directory structure of the code they are testing and reside in the respective `test/` directory.

- **Flutter (Dart):** For a source file at `lib/path/to/my_widget.dart`, its test file should be located at `test/path/to/my_widget_test.dart`.
- **Backend (TypeScript):** For a source file at `src/path/to/my-service.ts`, its test file should be located at `test/path/to/my-service.spec.ts`.

### 17.5 Critical Test Scenarios (Mandatory Coverage)

These scenarios MUST have comprehensive test coverage due to their business-critical nature:
**Financial Accuracy:**

- GST calculations (CGST/SGST/IGST for all combinations)
- Invoice total calculations (discounts, taxes, shipping)
- Payment allocation and balance tracking
  **Data Integrity:**
- Inventory stock updates (invoice confirmation, goods receipt)
- Multi-branch stock isolation
- Concurrent transaction handling
  **Offline/Sync:**
- Hive sync conflict resolution
- Queue retry logic for failed API calls
- Data consistency after network restoration
  **Workflows:**
- Complete Sales flow: Quote → SO → Invoice → Payment
- Complete Purchase flow: PO → Receipt → Bill → Payment

---

## 18. API & Logging Standards

This section outlines the standards for API documentation and application logging, crucial for maintainability, debugging, and production readiness.

### 18.1 API Documentation Standards

- **Standard:** All APIs must be documented using the **OpenAPI (Swagger)** specification.
- **Backend Implementation:** The NestJS backend will leverage the `@nestjs/swagger` package to automatically generate and maintain API documentation from code annotations (DTOs, controllers, etc.).
- **Requirements:**
  - All new API endpoints MUST be fully documented.
  - Documentation MUST include clear descriptions, parameters (path, query, body), request/response schemas, and example values.
  - All Data Transfer Objects (DTOs) and API models MUST be clearly defined.
- **Access:** The generated API documentation will be accessible via a `/api-docs` endpoint in development and staging environments.

### 18.2 Logging Standards

Comprehensive and structured logging is vital for monitoring, debugging, and auditing the application in production environments.

- **Structured Logging:** All logs MUST be structured (preferably in JSON format) to facilitate easy ingestion, parsing, and analysis by centralized logging systems (e.g., AWS CloudWatch Logs, Azure Monitor, ELK Stack).
- **Logging Levels:** Adhere to standard logging levels:
  - `DEBUG`: Detailed information for development and diagnosis.
  - `INFO`: High-level events, application flow.
  - `WARN`: Potentially harmful situations.
  - `ERROR`: Error events that might still allow the application to continue.
  - `FATAL`: Very severe error events that will likely cause the application to abort.
- **Backend (NestJS):** Implement a structured logger (e.g., [Winston](https://github.com/winstonjs/winston) or [Pino](https://getpino.io/)) integrated with NestJS's custom logging provider.
- **Frontend (Flutter):** Utilize a configurable logging package (e.g., `logger`) that supports different log levels and potentially structured output.
- **Contextual Logging:** All logs MUST include relevant context for easier debugging. This includes:
  - `timestamp`
  - `service` / `module` / `function` name
  - `entity_id` (where applicable)
  - `user_id` (where applicable)
  - `correlation_id` / `request_id` (for tracing requests across services).
- **Sensitive Data Protection:** **NEVER** log sensitive information such as passwords, API keys, Personally Identifiable Information (PII), payment details, or any other confidential data. Implement redaction or filtering for any potential sensitive data.

### 18.3 API Response Format Standards

All API responses MUST follow this consistent structure:
**Success Response:**

```json
{
  "data": {
    /* actual payload */
  },
  "meta": {
    "page": 1,
    "limit": 50,
    "total": 250,
    "timestamp": "2026-01-20T23:12:00Z"
  }
}
```

**Error Response:**

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid product data",
    "details": {
      "field": "product_name",
      "reason": "Product name is required"
    },
    "timestamp": "2026-01-20T23:12:00Z"
  }
}
```

**Pagination Standard:**

- Query params: `?page=1&limit=50&sort=created_at:desc`
- Default limit: `50`
- Max limit: `200`

---

## 19. Schema Migration & Data Evolution Strategy

### 19.1 Overview

As the system evolves, database schema changes are inevitable. This section outlines the strategy for managing schema migrations, particularly the critical transition from the deprecated `items` table to the global `products` table.

### 19.2 Migration Philosophy

- **Zero Downtime:** All migrations must be designed to run without requiring application downtime.
- **Backward Compatible:** Where possible, migrations should maintain backward compatibility during a transition period.
- **Automated & Repeatable:** Migrations must be scripted and version-controlled, ensuring they can be reliably applied across all environments.
- **Tested:** All migrations must be tested in development and staging before production deployment.

### 19.3 Items → Products Migration Plan

**Background:** The legacy `items` table is deprecated. All new development uses the global `products` table (no `org_id`). This migration plan ensures a smooth transition.
**Current Status (Phase 1 - Dual Support):**

- Frontend maintains backward-compatible provider aliases:
  - `itemsProvider` → `productsProvider`
  - `itemsControllerProvider` → `productsControllerProvider`
- All new code uses `products` table and [Product](cci:2://file:///D:/K4NN4N/zerpai_erp/lib/modules/products/models/product_model.dart:3:0-451:1) model
- Legacy references being systematically refactored
1. **Data Copy (if legacy items exist):**
   ```sql
   INSERT INTO products (...)
   SELECT ... FROM items
   WHERE NOT EXISTS (SELECT 1 FROM products WHERE products.item_code = items.item_code);
   ```

2. **Foreign Key Updates:**
   Update all referencing tables:
   - `invoice_items.item_id` → `product_id`
   - `purchase_order_items.item_id` → `product_id`
   - `branch_inventory.product_id` (replaces legacy `branch_id_inventory.item_id`)
   - `sales_order_items.item_id` → `product_id`
   ```

Remove all provider aliases from codebase
Drop items*deprecated*\* table after 2 stable production releases
Update documentation to remove all items references
19.4 Rollback Strategy
Migration script includes rollback logic
Test rollback procedure in staging
Maintain items table backup for emergency recovery
Document rollback steps in deployment runbook
19.5 Verification Checklist
Before marking migration complete:

All foreign keys successfully updated
Zero orphaned records (validation queries pass)
Application builds without compilation errors
All integration tests pass
Manual smoke tests of critical flows (create invoice, POS sale)
Staging deployment successful
No production errors after 48 hours

---

## 20. Security Implementation Standards

### 20.1 Overview

While the development phase operates without active authentication (auth-free dev stage), the architecture is designed to be **"Auth-Ready"** from day one. This section outlines the security standards that MUST be implemented before production deployment.

### 20.2 Authentication Requirements (Pre-Production)

**Authentication Method:**

- **Primary:** Supabase Auth with JWT (JSON Web Tokens)
- **Session Management:**
  - **Access Token:** 1-hour validity (short-lived for security)
  - **Refresh Token:** 7-day validity (allows persistent sessions)
  - Automatic token refresh handled by Supabase client libraries
- **Multi-Factor Authentication (MFA):** Optional but recommended for admin roles (`super_admin`, `ho_admin`)

**Implementation Checklist:**

- [ ] Supabase Auth configured in frontend (`supabase_flutter` package)
- [ ] JWT validation middleware added to NestJS backend
- [ ] Login screen implemented with email/password
- [ ] Password reset flow implemented
- [ ] Session persistence across browser refreshes
- [ ] Automatic token refresh on expiry
- [ ] Logout functionality clears all auth tokens

### 20.3 Authorization & Access Control

**Row-Level Security (RLS):**

All business-owned tables MUST have Supabase RLS policies enabled:

```sql
CREATE POLICY "Users can only access their entity's customers"
ON customers
FOR ALL
USING (entity_id = (SELECT entity_id FROM users WHERE id = auth.uid()));

-- Example: RLS policy for branch_inventory
CREATE POLICY "Users can only access stock for their branch"
ON branch_inventory
FOR ALL
USING (entity_id = (SELECT entity_id FROM users WHERE id = auth.uid()));
```

**Role-Based Access Control (RBAC):**

Roles defined in `users.role` column:

- **`super_admin`:** Full system access across all organizations (platform admin)
- **`ho_admin`:** Full access within own organization, all branches
- **`branch_manager`:** Full access within assigned branch only
- **`branch_staff`:** Limited access (POS, view reports) within assigned branch

**Backend Guards (NestJS):**

```typescript
// Example: Guard to verify organization access
@Injectable()
export class EntityAccessGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user; // From JWT
    const requestedEntityId = request.params.entity_id;

    return user.entity_id === requestedEntityId || user.role === 'super_admin';
  }
}

// Usage in controller
@UseGuards(JwtAuthGuard, EntityAccessGuard)
@Get('entities/:entity_id/customers')
async getCustomers(@Param('entity_id') entityId: string) {
  // ...
}
```

### 20.4 Data Security

**Encryption:**

- **In Transit:** All API calls MUST use HTTPS/TLS 1.3 minimum
- **At Rest:** Database encryption provided by Supabase (AES-256)
- **Sensitive Fields:** Additional application-level encryption for highly sensitive data (optional for v1, required for PCI compliance if storing payment info)

**Data Protection Standards:**

- **Passwords:** Never store plaintext passwords (Supabase Auth handles hashing with bcrypt)
- **API Keys:** Store in environment variables (`.env.local`), never in code
- **Personal Identifiable Information (PII):**
  - Minimize collection
  - Encrypt customer email/phone if required by compliance
  - Implement data retention policies
- **Audit Logs:** Track all sensitive operations (invoice creation, payment, stock adjustments) with user attribution

### 20.5 Input Validation & Sanitization

**Backend (NestJS):**

Use DTOs with `class-validator` decorators for all API inputs:

```typescript
import { IsString, IsUUID, IsOptional, IsNumber, Min } from "class-validator";

export class CreateInvoiceDto {
  @IsUUID()
  customer_id: string;

  @IsNumber()
  @Min(0)
  total_amount: number;

  @IsString()
  @IsOptional()
  notes?: string;
}
```

**Frontend (Flutter):**

- All user inputs must be validated before submission
- Use `TextFormField` validators
- Sanitize inputs to prevent injection attacks (though backend is primary defense)

### 20.6 API Security

**Rate Limiting:**

Implement rate limiting to prevent abuse:

```typescript
// NestJS Throttler configuration
ThrottlerModule.forRoot({
  ttl: 60, // Time window in seconds
  limit: 100, // Max requests per window per IP
}),
```

**CORS Configuration:**

```typescript
// Allow only trusted origins in production
app.enableCors({
  origin: process.env.FRONTEND_URL || "http://localhost:3000",
  credentials: true,
});
```

**API Key Management:**

- Internal APIs: JWT authentication
- External integrations: API keys stored in secure secrets manager
- Rotate API keys every 90 days

### 20.7 Security Audit & Compliance

**Pre-Production Security Checklist:**

- [ ] All RLS policies implemented and tested
- [ ] JWT authentication functional on all protected endpoints
- [ ] HTTPS enforced (HTTP redirects to HTTPS)
- [ ] CORS properly configured (no wildcard `*` in production)
- [ ] Rate limiting active
- [ ] Input validation on all endpoints
- [ ] SQL injection testing completed (use parameterized queries)
- [ ] XSS vulnerability testing completed
- [ ] CSRF protection implemented (if using cookies)
- [ ] Security headers configured (CSP, HSTS, X-Frame-Options)
- [ ] Dependency vulnerability scan passed (`npm audit`, `flutter pub audit`)
- [ ] Secrets not exposed in frontend code or logs
- [ ] Error messages don't leak sensitive info

**Ongoing Security Practices:**

- Monthly dependency updates and vulnerability scans
- Quarterly security review of new features
- Penetration testing before major releases
- Incident response plan documented

### 20.8 Compliance Considerations

**GST Compliance (India):**

- All invoice data must be tamperproof (consider digital signatures for invoices)
- Retain all tax records for minimum 7 years
- Implement audit trails for all tax-related modifications

**Data Privacy:**

- Implement GDPR-style data export capability (even if not EU-based, good practice)
- Allow customers to request data deletion
- Privacy policy and terms of service clearly displayed

**Future Certifications:**

- ISO 27001 (Information Security Management) - for enterprise clients
- SOC 2 Type II - for SaaS compliance
- PCI DSS - if handling payment card data directly

---

## 21. Disaster Recovery & Business Continuity

### 21.1 Backup Strategy

**Database Backups (Supabase):**

- **Automated Daily Backups:** Supabase provides automated daily backups (retained for 7 days on free tier, 30+ days on paid)
- **Point-in-Time Recovery (PITR):** Enable PITR for production (allows restore to any point in last 7 days)
- **Manual Backups:** Before major migrations or releases, create manual backup snapshots
- **Backup Testing:** Monthly restore drills to verify backup integrity

**Code & Configuration:**

- **Git Repository:** Primary source of truth (GitHub)
- **Environment Variables:** Documented in `.env.example`, backed up in secure secrets manager (AWS Secrets Manager/1Password)

**Recovery Objectives:**

- **RTO (Recovery Time Objective):** < 4 hours for production database
- **RPO (Recovery Point Objective):** < 24 hours (daily backups minimum)
- **Critical Data RPO:** < 1 hour (for transaction data, consider more frequent backups)

### 21.2 Incident Response Plan

**Severity Levels:**

- **P0 (Critical):** System down, data loss, security breach → Response: Immediate
- **P1 (High):** Major feature broken, significant user impact → Response: < 2 hours
- **P2 (Medium):** Minor feature broken, workaround available → Response: < 24 hours
- **P3 (Low):** Cosmetic issues, feature requests → Response: Next sprint

**Incident Response Runbook:**

1. **Detect:** Monitoring alerts or user reports
2. **Assess:** Determine severity level
3. **Communicate:** Notify stakeholders (internal team, users if needed)
4. **Mitigate:** Implement immediate fix or workaround
5. **Resolve:** Deploy permanent fix
6. **Post-Mortem:** Document incident, root cause, prevention steps

**Runbook Location:** `docs/runbooks/` directory

### 21.3 Data Retention & Archival

- **Active Data:** All transactions kept in primary database
- **Archival:** Data older than 3 years moved to cold storage (optional, for large organizations)
- **Legal Requirements:** GST documents retained for 7 years minimum (India compliance)
- **User Data Deletion:** Allow organization admins to request data deletion (GDPR-style)
- **Soft Delete:** Critical records (invoices, payments) are soft-deleted (marked inactive) rather than hard-deleted

---

## 22. Deployment & Release Management

### 22.1 CI/CD Pipeline (GitHub Actions)

**On Pull Request to `dev`:**

1. ✅ Code formatting check (`dart format --set-exit-if-changed`, `prettier --check`)
2. ✅ Linting (`flutter analyze`, `npm run lint`)
3. ✅ Unit tests (`flutter test`, `npm run test`)
4. ✅ Build verification (`flutter build web --release`, `npm run build`)
5. ✅ Security scan (`npm audit`, dependency vulnerability check)
6. ✅ Code coverage report (must meet 70% threshold)

**Status:** PR is **blocked from merging** if any check fails.

**On Merge to `dev` (Staging Deployment):**

1. All PR checks passed
2. Deploy backend to **Vercel staging**
3. Deploy frontend to **Vercel staging**
4. Run integration tests against staging
5. Automated smoke tests on staging environment

**On Merge to `main` (Production Release):**

1. Create git tag with version (e.g., `v1.0.0`)
2. Generate release notes from commits (conventional commits)
3. Run database migrations (if any) - **manual approval required**
4. Deploy backend to **Vercel production**
5. Deploy frontend to **Vercel production**
6. Run post-deployment health checks
7. Monitor error rates for 2 hours (auto-rollback if error spike detected)

### 22.2 Versioning Strategy

**Semantic Versioning:** `MAJOR.MINOR.PATCH`

- **MAJOR:** Breaking API changes, major architectural changes (e.g., v1.0.0 → v2.0.0)
- **MINOR:** New features, backward compatible (e.g., v1.0.0 → v1.1.0)
- **PATCH:** Bug fixes, small improvements (e.g., v1.0.0 → v1.0.1)

**Release Cadence:**

- **Minor Releases:** Every 2 weeks (sprint cycle)
- **Patch Releases:** As needed for critical bugs (can be released any time)
- **Major Releases:** Quarterly or when significant breaking changes needed

**Release Naming (Optional):** Can use codenames for Major releases (e.g., "Himalaya" for v1.0, "Ganges" for v2.0)

### 22.3 Rollback Procedure

If production deployment fails or critical bugs discovered post-deployment:

**Immediate Rollback (< 15 minutes):**

1. **Application Code:** Revert to last known good version via Vercel rollback (one-click)
2. **Verify:** Check health endpoint returns 200 OK
3. **Monitor:** Confirm error rates return to normal

**Database Rollback (If Migration Ran):**

1. **Execute Rollback Script:** Every migration MUST have a tested rollback script
   ```bash
   npm run migration:rollback
   ```
2. **Validation:** Run integrity checks to ensure data consistency
3. **Application Restart:** May be needed to reconnect to rolled-back schema

**Post-Rollback:**

1. **Communication:** Notify users of downtime/issues (if user-facing)
2. **Incident Report:** Create post-mortem document
3. **Action Items:** Identify what went wrong, steps to prevent recurrence

**Rollback Testing:** ALL migrations must have rollback procedures tested in staging before production.

### 22.4 Deployment Checklist

Before deploying to production:

- [ ] All tests passing in CI
- [ ] Code reviewed and approved
- [ ] Database migration script tested in staging (if applicable)
- [ ] Rollback procedure documented and tested
- [ ] Release notes prepared
- [ ] Monitoring alerts configured for new features
- [ ] Stakeholders notified of deployment window
- [ ] Backup created (especially if migration involved)

---

## 23. Monitoring & Observability Strategy

### 23.1 Application Performance Monitoring (APM)

**Tools:**

- **Error Tracking:** Sentry (frontend + backend)
- **Performance Monitoring:** Vercel Analytics
- **Log Aggregation:** Vercel Logs (basic), upgrade to Datadog/LogRocket for advanced

**Key Metrics to Track:**

**Error Metrics:**

- **Error Rate:** Errors per minute (alert if > 10 errors/min)
- **Error Types:** Categorize (500 server errors, 400 validation errors, UI crashes)
- **Affected Users:** How many unique users hit errors

**Performance Metrics:**

- **API Response Time:** p50, p95, p99 for all endpoints
- **Throughput:** Requests per second (RPS)
- **Database Query Time:** Slow query alerts (> 1s execution time)
- **Frontend Metrics:**
  - Page Load Time (First Contentful Paint)
  - Time to Interactive (TTI)
  - Core Web Vitals (LCP, FID, CLS)

**Alerting Thresholds:**

| Metric               | Threshold              | Action                       |
| -------------------- | ---------------------- | ---------------------------- |
| Error rate spike     | > 20 errors in 5 min   | Page on-call engineer        |
| API p95 latency      | > 2s                   | Slack alert to #engineering  |
| Database CPU         | > 80%                  | Urgent investigation         |
| Background job queue | > 1000 pending         | Scale workers                |
| Health check fails   | 3 consecutive failures | Auto-rollback + page on-call |

### 23.2 Business Metrics Dashboard

Track critical business operations (for product analytics):

**Daily Metrics:**

- **Daily Active Users (DAU):** Unique users per day
- **Invoices Created:** Per day, per organization
- **POS Transactions:** Volume, average ticket size
- **Revenue Processed:** Total invoice amounts

**Operational Metrics:**

- **Sync Errors:** Offline → Online sync failure rate
- **Stock Movements:** Inventory changes per day
- **Report Generation:** Most used reports

**Tool:** Google Analytics 4 or Mixpanel for user behavior tracking

### 23.3 Health Check Endpoints

**Backend Health Check:**

```typescript
// src/health/health.controller.ts
@Controller("health")
export class HealthController {
  @Get()
  async healthCheck() {
    const dbHealthy = await this.checkDatabaseConnection();
    const status = dbHealthy ? "healthy" : "unhealthy";

    return {
      status,
      timestamp: new Date().toISOString(),
      version: process.env.APP_VERSION || "unknown",
      services: {
        database: dbHealthy ? "up" : "down",
        redis: "not_configured", // Future
      },
    };
  }

  private async checkDatabaseConnection(): Promise<boolean> {
    try {
      await this.db.query("SELECT 1");
      return true;
    } catch {
      return false;
    }
  }
}
```

**Frontend Health Indicator:**

```dart
// lib/core/monitoring/health_indicator.dart
class HealthIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkBackendHealth(),
      builder: (context, snapshot) {
        if (snapshot.data == true) {
          return Icon(Icons.cloud_done, color: Colors.green);
        }
        return Icon(Icons.cloud_off, color: Colors.red);
      },
    );
  }
}
```

**Uptime Monitoring:**

- Use external service (UptimeRobot, Better Uptime, or Vercel built-in)
- Ping `/api/health` every 5 minutes
- Alert if downtime > 2 minutes

### 23.4 Logging Best Practices

**Structured Logging Format (JSON):**

```typescript
{
  "level": "info",
  "timestamp": "2026-01-20T23:56:00Z",
  "service": "products-api",
  "message": "Product created successfully",
  "context": {
    "entity_id": "uuid-123",
    "user_id": "uuid-456",
    "product_id": "uuid-789",
    "correlation_id": "req-xyz"
  }
}
```

**Log Levels Usage:**

- **DEBUG:** Development only, verbose details
- **INFO:** Normal operations (product created, invoice sent)
- **WARN:** Unusual but handled (retry on API timeout)
- **ERROR:** Application errors that need attention
- **FATAL:** System-critical failures

**Correlation IDs:** Track requests across services using `x-correlation-id` header

---

## 24. User Onboarding Strategy

### 24.1 Initial Setup Flow (For New Organizations)

**Step 1: Organization Setup**

- Company name, GSTIN, address
- Business type (retail, pharmacy, trading)
- Fiscal year configuration (April-March for India)
- Tax registration details

**Step 2: First Branch Creation**

- Branch name, type (HO/COCO/FOFO)
- Address, contact details
- Drug license number (if pharmacy)
- GST registration (if different from HO)

**Step 3: Initial Data Import (Optional but Recommended)**

- **Products:** Guided CSV import with downloadable template
- **Customers:** Optional CSV import
- **Initial Stock:** Enter opening inventory levels

**Step 4: User Invitation**

- Invite branch managers/staff via email
- Set roles and permissions (manager, staff, admin)
- Users receive welcome message on first app launch (auth-free pre-production)

**Step 5: Onboarding Checklist (In-App)**

Progressive disclosure checklist shown on dashboard:

- [ ] ✅ Organization profile completed
- [ ] ✅ First branch created
- [ ] Add your first product
- [ ] Add your first customer
- [ ] Create your first invoice
- [ ] Complete your first POS sale
- [ ] Generate your first sales report
- [ ] Set up stock reorder alerts

**Gamification:** Show progress bar (0% → 100%), celebrate milestones

### 24.2 In-App Guidance

**First-Time User Experience (FTUE):**

- **Product Tour:** Optional walkthrough on first app launch (can be skipped)
- **Contextual Tooltips:** Appear on first visit to each screen
- **Empty States:** Actionable with clear CTAs
  - _"No products yet. Add your first product to get started"_ [+ Add Product button]
  - _"No invoices found. Create your first invoice"_ [+ New Invoice button]

**Help Resources:**

- **Help Icon (?):** Available on every screen, links to relevant help article
- **Video Tutorials:** Embedded 2-3 minute videos for complex workflows
- **Search Help:** Searchable knowledge base

### 24.3 Training Materials & Documentation

**Video Tutorials (YouTube Channel):**

1. Getting Started with Zerpai ERP (5 min)
2. Adding Products & Managing Inventory (3 min)
3. Creating Your First Invoice (2 min)
4. Using the POS Interface (4 min)
5. Generating Sales Reports (3 min)
6. Understanding GST in Zerpai (5 min)

**Knowledge Base Articles:**

- How-to guides for every major feature
- FAQ section (common questions)
- Troubleshooting guides
- Best practices

**Release Notes:**

- Published with every release
- Highlight new features, bug fixes
- Link to detailed documentation

**Onboarding Email Sequence:**

- Day 0: Welcome message on first app launch
- Day 1: "Getting started" guide
- Day 3: "Top 5 features you should know"
- Day 7: "Need help? Here's how to contact support"
- Day 14: "Tips for GST compliance"

### 24.4 Sample Data Option

**Demo Mode:**

- Allow users to explore with pre-populated sample data
- Sample products, customers, invoices
- Clearly labeled "SAMPLE DATA - This is not real"
- One-click to clear sample data and start fresh

---

## 25. Known Limitations & Future Roadmap

### 25.1 V1.0 Scope Limitations

**Explicitly OUT of Scope for V1.0:**

- ❌ **Mobile Native Apps:** Flutter Web only, no iOS/Android native apps (Roadmap: v2.0)
- ❌ **E-Commerce Integration:** No Shopify/WooCommerce/Amazon sync (Roadmap: v1.5)
- ❌ **Government Portal Integration:** No direct GST e-filing, no e-Way bill generation API integration (Roadmap: v2.0)
- ❌ **Advanced Reporting:** No custom report builder, no pivot tables, no visual dashboards (Roadmap: v1.3)
- ❌ **Manufacturing Module:** No production planning, Bill of Materials (BOM), work orders (Roadmap: v3.0)
- ❌ **Multi-Currency:** INR only for v1.0 (Roadmap: v2.0 for international expansion)
- ❌ **Advanced Inventory:** Bin/rack location tracking schema exists but no UI (Roadmap: v1.2)
- ❌ **Payment Gateway Integration:** No Razorpay/Stripe integration for automated payment collection (Roadmap: v1.4)
- ❌ **Barcode Scanner:** POS supports manual entry only, no hardware scanner integration (Roadmap: v1.2)
- ❌ **Email Marketing:** No bulk email campaigns, newsletters (Roadmap: v2.5)
- ❌ **CRM Features:** No lead management, sales pipeline (Roadmap: v2.5)

### 25.2 Technical Debt Items (Known Issues Deferred)

**Deferred to Post-V1.0:**

- **Offline Sync:** Basic conflict resolution (last-write-wins), advanced merge strategies needed
- **Stock Reorder Automation:** No automatic purchase order generation when stock hits reorder point
- **Batch Processing:** No bulk operations (e.g., bulk discount update across products)
- **Excel Import:** Limited to basic CSV, no complex Excel formulas or multi-sheet support
- **Report Formats:** CSV/Excel only, no PDF export (especially for invoices - workaround: browser print)
- **Search:** Basic text search, no advanced filters or full-text search
- **Audit Trails:** Basic logging, no comprehensive audit dashboard
- **Multi-Language:** English only, no i18n/l10n (Roadmap: v2.0 for Hindi, regional languages)

### 25.3 Performance Considerations

**Scale Limits (V1.0):**

- **Products:** Tested up to 50,000 products per database
- **Concurrent Users:** 100 simultaneous users per organization
- **Branches:** Recommended max 50 branches per organization (can scale higher with performance tuning)
- **Transactions:** Designed for 10,000 invoices/month per organization

**If you exceed these limits:** Contact support for enterprise plan with dedicated infrastructure.

### 25.4 Future Roadmap (Tentative)

**V1.1 (February 2026) - Polish & Performance**

- Performance optimizations based on production feedback
- Report enhancements (new report types)
- Bug fixes from v1.0 user feedback
- Mobile-responsive UI improvements

**V1.2 (March 2026) - Inventory Enhancements**

- Barcode scanner integration (USB/Bluetooth)
- Bin/rack location tracking UI
- Low stock alerts dashboard
- Stock transfer between branches

**V1.3 (April 2026) - Advanced Reporting**

- Custom report builder
- Visual charts and graphs
- Scheduled reports (email daily/weekly)
- PDF export for invoices

**V1.4 (May 2026) - Payments & Automation**

- Razorpay/Stripe integration
- Payment link generation
- Automatic payment reminder emails
- Recurring invoice automation

**V1.5 (Q3 2026) - E-Commerce Integration**

- Shopify integration (two-way sync)
- WooCommerce integration
- Amazon Seller Central (basic)
- Inventory sync across channels

**V2.0 (Q4 2026) - Multi-Platform & Compliance**

- iOS and Android native apps
- Multi-currency support (USD, EUR, GBP)
- GST e-filing portal integration
- E-Way bill generation API
- Multi-language support (Hindi, Tamil, Telugu)

**V2.5 (Q1 2027) - CRM & Marketing**

- Lead and opportunity management
- Sales pipeline visualization
- Email marketing campaigns
- Customer loyalty programs

**V3.0 (Q2 2027) - Manufacturing Module**

- Bill of Materials (BOM) management
- Production planning
- Work order tracking
- Raw material procurement

### 25.5 Feedback & Feature Requests

**How to submit feature requests:**

- GitHub Discussions (public roadmap voting)
- In-app feedback widget
- Email: feedback@zerpai.com

**Prioritization Criteria:**

1. Number of user votes
2. Alignment with product vision
3. Technical feasibility
4. Resource availability

**Transparency:** Public roadmap board (GitHub Projects / Notion) where users can track progress
