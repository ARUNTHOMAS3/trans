# Zerpai ERP — Product Overview

## Purpose & Value Proposition

Zerpai ERP is a modern, online-first but offline-capable ERP system built for Indian SMEs, targeting retail, pharmacy, and trading businesses. It replaces fragmented spreadsheets and single-purpose tools with a unified, fast, GST-compliant platform.

Design inspiration: Zoho Inventory (https://www.zoho.com/in/inventory/inventory-software-demo/)

## Key Features

### Core Modules
- **Items** — Global product master (products table), composite items, item groups, price lists, item mapping
- **Inventory** — Assemblies, adjustments, picklists, packages, shipments, transfer orders
- **Sales** — Customers, quotations, sales orders, invoices, delivery challans, payments received, sales returns, credit notes, e-way bills, payment links, recurring invoices
- **Purchases** — Vendors, purchase orders, purchase receives, bills, expenses, payments made, vendor credits
- **Accountant** — Manual journals, recurring journals, bulk update, transaction locking, opening balances
- **Accounts** — Chart of accounts
- **Reports** — Daily sales, P&L, general ledger, trial balance, sales by customer, inventory valuation, audit logs
- **Settings** — Organization profile, branding, branches, warehouses, users, roles

### Business Capabilities
- GST-compliant invoicing (CGST/SGST/IGST, HSN/SAC codes, GSTR-1 ready)
- Multi-outlet / multi-branch support (HO → FOFO → COCO hierarchy)
- Offline-capable POS mode via Hive local cache
- Cloudflare R2 object storage for documents/images
- Audit logging on all mutations
- Transaction series / document numbering
- Print templates for invoices and documents

## Target Users

- Indian SME owners and managers (retail, pharmacy, trading)
- Head Office administrators managing franchise networks
- Outlet staff performing daily POS, billing, and inventory operations

## Operational Context

- **Multi-tenancy**: Single DB, row-level isolation by `org_id` + `outlet_id`
- **Auth stage**: Auth-free dev mode — app boots directly to dashboard; no login enforced
- **Data model**: `products` table is global (no `org_id`); all transactional tables are org-scoped
- **Stock rule**: Inventory decreases only on invoice confirmation; increases only on goods receipt
- **Workflow**: Quotation → Sales Order → Invoice → Payment (sales); Purchase Order → Receipt → Bill → Payment (purchases)
