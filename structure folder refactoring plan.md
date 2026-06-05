# Zerpai ERP — FINAL CANONICAL STRUCTURE PLAN

This structure is based on:

* your sidebar
* settings screen
* current refactor direction
* frontend/backend symmetry
* modular ERP architecture
* your actual business domains

This is the REAL target structure.

---

# FRONTEND STRUCTURE

```txt id="8u8t7g"
lib/
├── app/
│
├── bootstrap/
│
├── config/
│
├── core/
│
├── shared/
│
├── engines/
│
├── modules/
│
├── generated/
│
└── main.dart
```

---

# APP LAYER

Application-level infrastructure only.

```txt id="2s6x6g"
app/
├── app.dart
├── app_shell.dart
│
├── routing/
│   ├── app_router.dart
│   ├── route_guards.dart
│   └── route_transitions.dart
│
├── navigation/
│   ├── app_module.dart
│   ├── navigation_registry.dart
│   ├── sidebar_builder.dart
│   ├── breadcrumbs.dart
│   ├── route_registry.dart
│   └── search_registry.dart
│
├── layouts/
│   ├── desktop_layout.dart
│   ├── tablet_layout.dart
│   └── mobile_layout.dart
│
├── theme/
│
├── startup/
│
└── localization/
```

---

# CORE LAYER

Pure infrastructure.

NO business modules here.

```txt id="uqpsij"
core/
├── api/
├── auth/
├── database/
├── storage/
├── networking/
├── constants/
├── exceptions/
├── middleware/
├── offline/
├── sync/
├── analytics/
├── permissions/
├── logging/
├── services/
├── utils/
└── helpers/
```

---

# SHARED LAYER

Global reusable UI/components ONLY.

```txt id="u5v8si"
shared/
├── widgets/
├── dialogs/
├── forms/
├── tables/
├── layouts/
├── responsive/
├── providers/
├── models/
├── mixins/
├── animations/
├── extensions/
└── helpers/
```

---

# ENGINES LAYER

Cross-module business engines.

```txt id="l40rka"
engines/
├── tax_engine/
├── pricing_engine/
├── inventory_engine/
├── accounting_engine/
├── workflow_engine/
├── approval_engine/
├── document_engine/
├── audit_engine/
├── print_engine/
├── notification_engine/
├── search_engine/
└── reporting_engine/
```

---

# MAIN MODULES

Based EXACTLY on your sidebar.

```txt id="qf2w9e"
modules/
├── home/
├── items/
├── pricelists/
├── inventory/
├── sales/
├── purchases/
├── accountant/
├── accounts/
├── reports/
├── documents/
├── auditlogs/
└── settings/
```

---

# ITEMS MODULE

From your sidebar:

* Items
* Composite Items
* Item Groups
* Item Mapping

```txt id="w2z7aq"
items/
├── items/
├── composite_items/
├── item_groups/
├── item_mapping/
└── shared/
```

---

# PRICELISTS MODULE

From sidebar:

* Price List
* Branch Price List

```txt id="33fdgm"
pricelists/
├── pricelist/
├── branch_pricelist/
└── shared/
```

---

# INVENTORY MODULE

From sidebar:

* Assemblies
* Inventory Adjustments
* Picklists
* Packages
* Shipments
* Transfer Orders
* Move Orders

```txt id="7t13su"
inventory/
├── assemblies/
├── inventory_adjustments/
├── picklists/
├── packages/
├── shipments/
├── transfer_orders/
├── move_orders/
├── warehouses/
├── stock/
└── shared/
```

---

# SALES MODULE

From sidebar:

* Customers
* Quotations
* Retailer Invoices
* Sales Orders
* Invoices
* Delivery Challans
* Payments Received
* Sales Returns
* Credit Notes
* e-Way Bills
* Payment Links
* Recurring Invoices

```txt id="axzjlwm"
sales/
├── customers/
├── quotations/
├── retailer_invoices/
├── sales_orders/
├── invoices/
├── delivery_challans/
├── payments_received/
├── sales_returns/
├── credit_notes/
├── eway_bills/
├── payment_links/
├── recurring_invoices/
└── shared/
```

---

# PURCHASES MODULE

From sidebar:

* Vendors
* Expenses
* Recurring Expenses
* Purchase Orders
* Purchase Receives
* Bills
* Recurring Bills
* Payments Made
* Vendor Credits

```txt id="97r8y0"
purchases/
├── vendors/
├── expenses/
├── recurring_expenses/
├── purchase_orders/
├── purchase_receives/
├── bills/
├── recurring_bills/
├── payments_made/
├── vendor_credits/
└── shared/
```

---

# ACCOUNTANT MODULE

From sidebar:

* Manual Journals
* Recurring Journals
* Bulk Update
* Transaction Locking
* Opening Balances

```txt id="djlwmx"
accountant/
├── chart_of_accounts/
├── manual_journals/
├── recurring_journals/
├── bulk_update/
├── transaction_locking/
├── opening_balances/
└── shared/
```

---

# ACCOUNTS MODULE

From sidebar:

* Chart Of Accounts

```txt id="jlwm8a"
accounts/
├── chart_of_accounts/
└── shared/
```

---

# REPORTS MODULE

```txt id="7jlwm9"
reports/
├── sales_reports/
├── inventory_reports/
├── accounting_reports/
├── audit_reports/
├── tax_reports/
├── financial_reports/
└── shared/
```

---

# DOCUMENTS MODULE

```txt id="xjlwm1"
documents/
├── attachments/
├── templates/
├── exports/
├── imports/
└── shared/
```

---

# AUDIT LOGS MODULE

```txt id="hjlwm5"
auditlogs/
├── activity_logs/
├── system_logs/
├── user_logs/
└── shared/
```

---

# SETTINGS MODULE

Based EXACTLY on your settings screen.

---

# ORGANIZATION SETTINGS

```txt id="yjlwm2"
organization/
├── profile/
├── branding/
├── branches/
├── warehouses/
├── approvals/
└── subscriptions/
```

---

# USERS & ROLES

```txt id="jlwmw4"
users_roles/
├── users/
├── roles/
├── permissions/
└── preferences/
```

---

# TAXES & COMPLIANCE

```txt id="jlwmf7"
taxes/
├── taxes/
├── direct_taxes/
├── eway_bills/
├── einvoicing/
└── msme/
```

---

# SETUP & CONFIGURATIONS

```txt id="zjlwm0"
setup/
├── general/
├── currencies/
├── reminders/
└── customer_portal/
```

---

# CUSTOMIZATION

```txt id="qjlwm6"
customization/
├── transaction_number_series/
├── pdf_templates/
├── email_notifications/
├── sms_notifications/
├── reporting_tags/
└── web_tabs/
```

---

# AUTOMATION

```txt id="jlwmr1"
automation/
├── workflow_rules/
├── workflow_actions/
├── workflow_logs/
└── triggers/
```

---

# INTEGRATIONS

From settings screen:

* Zoho Apps
* WhatsApp
* SMS Integrations
* Shipping
* Shopping Cart & POS
* eCommerce
* Accounting
* Sales & Marketing
* EDI
* Marketplace

```txt id="jlwmz9"
integrations/
├── zoho/
├── whatsapp/
├── sms/
├── shipping/
├── pos/
├── ecommerce/
├── accounting/
├── sales_marketing/
├── edi/
├── marketplace/
└── shared/
```

---

# DEVELOPER

```txt id="jjlwm4"
developer/
├── incoming_webhooks/
├── connections/
├── api_usage/
├── data_management/
├── deluge_components/
└── webforms/
```

---

# FINAL SETTINGS STRUCTURE

```txt id="jlwmt7"
settings/
├── organization/
├── users_roles/
├── taxes/
├── setup/
├── customization/
├── automation/
├── integrations/
├── developer/
└── shared/
```

---

# INTERNAL SUBMODULE STRUCTURE

Every submodule follows SAME structure.

Example:

```txt id="jlwmp8"
sales/
└── invoices/
    ├── data/
    ├── presentation/
    ├── providers/
    ├── widgets/
    ├── config/
    ├── routes/
    └── shared/
```

---

# DATA STRUCTURE

```txt id="3jlwmx"
data/
├── models/
├── repositories/
├── services/
├── datasource/
└── dto/
```

---

# PRESENTATION STRUCTURE

```txt id="5jlwmq"
presentation/
├── pages/
├── dialogs/
├── sections/
├── tables/
├── forms/
└── state/
```

---

# BACKEND STRUCTURE

NestJS backend mirroring frontend domains.

```txt id="djlwm3"
backend/
└── src/
    ├── app.module.ts
    ├── common/
    ├── config/
    ├── database/
    ├── middleware/
    ├── guards/
    ├── interceptors/
    ├── decorators/
    ├── pipes/
    ├── filters/
    ├── jobs/
    ├── events/
    ├── websocket/
    ├── integrations/
    ├── engines/
    └── modules/
```

---

# BACKEND MAIN MODULES

```txt id="8jlwm7"
modules/
├── home/
├── items/
├── pricelists/
├── inventory/
├── sales/
├── purchases/
├── accountant/
├── accounts/
├── reports/
├── documents/
├── auditlogs/
└── settings/
```

---

# BACKEND SUBMODULE EXAMPLE

```txt id="tjlwm2"
sales/
├── customers/
├── quotations/
├── invoices/
├── payments/
└── shared/
```

---

# BACKEND INTERNAL STRUCTURE

Example:

```txt id="cjlwm6"
sales/
└── invoices/
    ├── dto/
    ├── entities/
    ├── controllers/
    ├── services/
    ├── repositories/
    ├── validators/
    ├── guards/
    ├── events/
    ├── listeners/
    ├── jobs/
    └── tests/
```

---

# BACKEND ENGINES

```txt id="qjlwm4"
engines/
├── tax_engine/
├── pricing_engine/
├── inventory_engine/
├── accounting_engine/
├── workflow_engine/
├── approval_engine/
├── document_engine/
├── audit_engine/
└── reporting_engine/
```

---

# IMPORTANT RULES

---

# RULE 1

Sidebar structure = module structure.

---

# RULE 2

Frontend and backend domains MUST mirror each other.

---

# RULE 3

Business logic NEVER inside shared/.

---

# RULE 4

core/ NEVER imports modules/.

---

# RULE 5

Only globally reusable UI goes into shared/.

---

# RULE 6

Business reusable UI goes into:

```txt id="5jlwm1"
modules/<domain>/shared/
```

---

# RULE 7

Every module owns:

```txt id="zjlwm5"
routes
permissions
providers
widgets
pages
repositories
```

---

# RULE 8

No giant:

```txt id="jjlwm8"
app_routes.dart
```

or:

```txt id="1jlwm9"
all_providers.dart
```

style monoliths later.

---

# FINAL RESULT

This structure gives you:

* scalable ERP architecture
* domain ownership
* clean navigation mapping
* backend/frontend symmetry
* easier onboarding
* easier scaling
* easier permissions
* easier search indexing
* easier future modules

without turning the project into unmaintainable spaghetti later.

---

# EXECUTION BRIDGE (Current Repo -> Canonical)

## Snapshot Status (2026-05-21)

### Already aligned
- Frontend root present:
  - `lib/{app,bootstrap,config,core,shared,engines,modules,generated}`
- Router ownership:
  - canonical owner `lib/app/routing/app_router.dart`
  - compatibility shim `lib/core/routing/app_router.dart`
- Navigation scaffolding present:
  - `lib/app/navigation/{app_module,navigation_registry,sidebar_builder,breadcrumbs,route_registry,search_registry}.dart`
- Legacy roots retired from runtime:
  - `lib/core/pages/` removed
  - `lib/data/` removed
  - `lib/utils/` removed
- Backend duplicate cleanup aligned:
  - canonical pricing path active `backend/src/modules/products/pricelists/pricelist/*`
  - legacy `backend/src/modules/products/pricelist/*` retired

### Partially aligned
- Module-by-module internal contract alignment remains incomplete:
  - many modules still mix old/new internal layout conventions.
- Engines layer exists, but domain engine extraction is not complete.
- Full frontend/backend mirror by business domain exists partially, not fully.

### Not yet aligned / pending
- Remaining canonical domains to formalize in code ownership:
  - `accounts/`, `documents/`, `auditlogs/` full module contract parity.
- Settings deep decomposition target structure (organization/taxes/setup/customization/automation/integrations/developer) not fully materialized.
- Remaining legacy pricing import usage:
  - `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`
  - still imports `modules/items/pricelist/*`.

---

## Next Execution Order (Canonical-first)

1. Finalize ledger approvals (`reviewed` -> `approved`) for full program gate.
2. Close remaining legacy `items/pricelist` imports to canonical `pricelists`.
3. Run module-contract normalization by domain:
   - settings -> reports/documents/auditlogs -> inventory -> sales -> purchases -> accountant/accounts -> items/pricelists -> home/auth/branches/mapping.
4. Build backend mirror normalization per same domain order.
5. Extract cross-domain business logic into `lib/engines/*` and backend `src/engines/*`.
6. Run full verification closure:
   - frontend full analyze
   - backend full build
   - route/deeplink smoke
   - CRUD smoke per domain

---

## Safety lock (explicit)

- Do not delete `handoff_backups` (including backend handoff folders) until user explicitly approves cleanup after full screen/page validation.

---

## Strict Architecture Enforcement (Effective Immediately)

1. Separate Business vs Infrastructure
- Business behavior stays module-owned (`lib/modules/<domain>/...`).
- Infrastructure stays app/platform-owned (`lib/core/...`, `lib/shared/services/...`, engines infra).
- Never mix invoice/tax/workflow business with printer driver/network/storage wiring in one file.

2. Module Ownership for Export/Import/Print
- Business export/import/print belongs to owning domain module.
- Printing platform concerns (drivers/renderer/spooler/queue/adapters) belong to shared infra/engine layer.
- No new global cross-domain business dump services.

3. Naming Discipline
- New files must be owner-specific and role-specific.
- Avoid generic sink naming for new feature code (`helpers`, `utils`, `common`, ambiguous `services/widgets`).
- Use predictable suffixes: `_page`, `_widget|_dialog|_card`, `_service`, `_repository`, `_model`.

4. Routing Decomposition
- No new giant route ownership.
- Module route files own feature routes; central router composes them.
- Deep-linkability remains mandatory for screen/sub-screen/tab/modal states.

5. Settings Must Stay Subdivided
- Settings work must map only to:
  - `organization`, `users_roles`, `taxes`, `setup`, `customization`, `automation`, `integrations`, `developer`.
- Do not add new catch-all settings business pages.

6. Reporting Engine Direction
- New report work should prefer extractable builders/filters/exporters/templates over monolithic page logic.

7. State Management Safety
- No growth of giant transactional `setState` files when extraction boundary exists.
- Prefer incremental provider/notifier/controller extraction without runtime rewrites.

8. Compatibility-First Migration
- Keep shims until import-zero verification and smoke validation pass.
- No same-batch ownership move + destructive deletion.

---

# 2026-05-24 Governance Hardening Addendum

## A. Structure Documentation Sync Rule

1. `current structure.md` is runtime snapshot owner.
2. `structure folder refactoring plan.md` is target-state + migration owner.
3. `PRD/prd_folder_structure.md` is policy owner.
4. All three must be updated together whenever folder ownership/moves happen.

## B. File/Folder Creation Rule (Stricter)

1. New file/folder must declare owner domain before creation.
2. No creation in transitional roots unless explicitly marked as compatibility shim.
3. New folder under `lib/modules/` must map to sidebar/canonical domain only.
4. If placing in `shared/`, author must prove cross-domain reuse.
5. Any new top-level folder requires architecture note in `log.md`.

## C. Incoming Handoff Merge Rule (Stricter)

1. Mandatory backup first: `backups/refactor-batches/<timestamp>-<scope>/`.
2. Mandatory compatibility phase: keep old path shim export until import-zero.
3. No destructive delete in same batch as move.
4. Must run verification for touched scope before marking merged.
5. Must append merge decision note + risk note to `log.md`.
6. Handoff folders/backups cannot be removed without explicit sign-off.

## D. Merge Checklist (Required)

- [ ] owner domain confirmed
- [ ] canonical target path confirmed
- [ ] backup created
- [ ] compatibility shim added (if moved)
- [ ] imports rewired
- [ ] analyzer/build clean
- [ ] log updated
- [ ] rollback path documented
