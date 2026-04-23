# ZERPAI ERP — Product Overview

## Purpose & Value Proposition

ZERPAI is a modern, multi-tenant ERP system built for Indian SMBs. It targets businesses that need GST-compliant sales, purchasing, inventory, and accounting workflows in a single platform. The tagline is "Clarity Over Complexity."

## Key Features & Capabilities

### Sales
- Quotations, Sales Orders, Invoices, Retainer Invoices
- Delivery Challans, Credit Notes, Sales Returns
- Payments Received, Payment Links, Recurring Invoices
- e-Way Bills (GST compliance)
- Customer management with GST treatment tracking

### Purchases
- Vendors, Purchase Orders, Purchase Receives
- Bills, Vendor Credits, Payments Made
- Recurring Bills and Expenses

### Inventory
- Stock tracking with batch/serial number support
- Assemblies (bill of materials)
- Picklists, Packages, Shipments
- Transfer Orders between warehouses
- Inventory Adjustments
- FEFO (First Expired, First Out) valuation support

### Items / Products
- Item master with HSN/SAC codes
- Composite Items (bundles)
- Item Groups and Item Mapping
- Price Lists (sales and purchase, percentage-based or fixed)

### Accounting
- Chart of Accounts (multi-level)
- Manual Journals and Recurring Journals
- Journal Templates
- Opening Balances
- Transaction Locking
- Bulk Account Updates

### Reports
- Profit & Loss, General Ledger, Trial Balance
- Sales by Customer, Daily Sales
- Inventory Valuation
- Account Transactions
- Audit Logs

### Settings & Administration
- Multi-branch / multi-outlet organization model
- Warehouse and Zone/Bin location management
- User management with RBAC (role-based access control)
- Organization and Branch branding/profile
- Transaction Series (auto-numbering)
- GST settings, TDS/TCS rates
- Currency management

## Target Users

- Indian SMB owners and finance teams
- Warehouse and inventory managers
- Sales and purchase teams operating across multiple branches/outlets
- Accountants needing GST-compliant journal and reporting workflows

## Deployment Targets

- Flutter Web (primary)
- Flutter Android (secondary)
- Backend deployed on Vercel (serverless NestJS)
- Database on Supabase (PostgreSQL + Auth + Storage)

## Multi-Tenancy Model

- All business tables scope data via `entity_id uuid NOT NULL` — FK to `organisation_branch_master(id)`
- `organisation_branch_master`: `type` = `'ORG'` or `'BRANCH'`; `ref_id` links to actual `organization.id` or `branches.id`
- Headers: `X-Org-Id` (routing), `X-Branch-Id` (optional), `X-Entity-Id` (preferred direct scope)
- Use `@Tenant()` / `@Tenant('entityId')` decorator in controllers — never read headers manually in services
- **Global tables (no `entity_id`):** `products`, `categories`, `brands`, `manufacturers`, `tax_rates`, `tax_groups`, `payment_terms`, `currencies`, `uqc`, `units`, `storage_conditions`, `buying_rules`, `drug_schedules`, `drug_strengths`, `contents`, `racks`, `shipment_preferences`, `tds_rates`, `tds_sections`, `tds_groups`, `price_lists`, `price_list_items`, `countries`, `states`, `timezones`, `gst_treatments`, `gstin_registration_types`, `business_types`, `hsn_sac_codes`, `composite_items`, `composite_item_parts`
