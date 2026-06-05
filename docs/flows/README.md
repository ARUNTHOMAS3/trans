# Zerpai ERP — Flow Diagrams

All diagrams use [Mermaid](https://mermaid.js.org/) syntax. Render in GitHub, VSCode (Mermaid Preview extension), or any Markdown viewer with Mermaid support.

## Index

### System Overview
| File | Description |
|------|-------------|
| [00_system_overview.md](00_system_overview.md) | Full architecture, module tree, multi-tenancy, data patterns |

---

### 01 — Auth
| File | Description |
|------|-------------|
| [01_auth/auth_flow.md](01_auth/auth_flow.md) | Login, logout, auth state machine, permission guards |

---

### 02 — Items
| File | Description |
|------|-------------|
| [02_items/items_overview.md](02_items/items_overview.md) | Module structure, Riverpod provider graph |
| [02_items/items_products.md](02_items/items_products.md) | Product list, create, edit, QuickStats overlay, backend service |
| [02_items/items_composite.md](02_items/items_composite.md) | Composite item creation and listing |
| [02_items/items_groups.md](02_items/items_groups.md) | Item groups create, list, delete with usage check |
| [02_items/items_pricelist.md](02_items/items_pricelist.md) | Price list creation, overview, volume ranges, DB schema |

---

### 03 — Sales
| File | Description |
|------|-------------|
| [03_sales/sales_overview.md](03_sales/sales_overview.md) | Sub-module map, route map, Riverpod providers |
| [03_sales/sales_customers.md](03_sales/sales_customers.md) | Customer create (with GSTIN lookup), list, detail, backend service |
| [03_sales/sales_orders_invoices.md](03_sales/sales_orders_invoices.md) | Create invoice, status machine, PO→Invoice, payment recording, shared list screen |
| [03_sales/sales_eway_bills.md](03_sales/sales_eway_bills.md) | E-Way bill creation and status flow |

---

### 04 — Purchases
| File | Description |
|------|-------------|
| [04_purchases/purchases_vendors.md](04_purchases/purchases_vendors.md) | Vendor create, list, backend service, DB schema |
| [04_purchases/purchases_orders.md](04_purchases/purchases_orders.md) | PO create, status machine, PO→Bill conversion |

---

### 05 — Inventory
| File | Description |
|------|-------------|
| [05_inventory/inventory_overview.md](05_inventory/inventory_overview.md) | Module structure, inventory event flow, route map |
| [05_inventory/inventory_assemblies.md](05_inventory/inventory_assemblies.md) | Assembly creation, stock adjustments, transfer orders, DB schema |

---

### 06 — Accountant
| File | Description |
|------|-------------|
| [06_accountant/accountant_overview.md](06_accountant/accountant_overview.md) | Module structure, route map, full API summary |
| [06_accountant/accountant_chart_of_accounts.md](06_accountant/accountant_chart_of_accounts.md) | COA tree load, state model, create account, sub-account types, ledger view |
| [06_accountant/accountant_manual_journals.md](06_accountant/accountant_manual_journals.md) | Journal create, status machine, clone/reverse, templates, DB schema |
| [06_accountant/accountant_recurring_journals.md](06_accountant/accountant_recurring_journals.md) | Recurring journal create, cron auto-run, manual trigger, DB schema |
| [06_accountant/accountant_opening_balances.md](06_accountant/accountant_opening_balances.md) | Opening balances flow, transaction locking, lock enforcement |

---

### 07 — Reports
| File | Description |
|------|-------------|
| [07_reports/reports_overview.md](07_reports/reports_overview.md) | All 7 reports: account transactions, GL, trial balance, P&L, sales by customer, inventory valuation, daily sales |

---

### 08 — Core Infrastructure
| File | Description |
|------|-------------|
| [08_core/core_routing.md](08_core/core_routing.md) | GoRouter boot, shell layout, route guards, deep linking |
| [08_core/core_api_client.md](08_core/core_api_client.md) | Dio ApiClient, 30s cache, standard response format, environment config |
| [08_core/core_offline_sync.md](08_core/core_offline_sync.md) | Hive boxes, offline fallback pattern, sync manager, draft auto-save |
| [08_core/core_tax_engine.md](08_core/core_tax_engine.md) | CGST/SGST/IGST calculation, GST invoice structure, GSTIN + HSN/SAC lookups |
| [08_core/core_backend_middleware.md](08_core/core_backend_middleware.md) | NestJS request lifecycle, tenant middleware, sequence numbering, Supabase connection |
