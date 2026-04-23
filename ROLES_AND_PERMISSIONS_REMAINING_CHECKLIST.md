# Zerpai ERP — Roles & Permissions Remaining Checklist

Status: Updated after full codebase audit + smoke test
Date: 2026-04-15
Source of truth:
- [ROLES_AND_PERMISSIONS_PLAN.md](E:/zerpai-new/ROLES_AND_PERMISSIONS_PLAN.md)
- current backend/frontend runtime

---

## 1. Implemented

### 1.1 Auth Foundation
- Real Supabase login is enabled and working (smoke-tested 2026-04-15).
- Backend token validation active.
- Auth refresh flow exists.
- Forgot-password endpoint wiring exists.
- App router redirects unauthenticated users to login.
- `entityId` is now correctly resolved in `TenantMiddleware` (via `organisation_branch_master` with explicit `type` filter).
- `buildAuthenticatedUser` in `auth.service.ts` resolves `orgEntityId` before passing to user service.

### 1.2 Role Resolution
- `admin` is the only hardcoded bypass role.
- All other roles (HO Admin, Branch Admin, custom) are dynamic DB-backed instances managed from Settings > Roles.
- UUID-backed custom roles preserved through login.
- `roles` table is now `entity_id`-only (no `org_id`).
- Role permissions resolved via `entity_id` filter in `buildRolePermissions`.

### 1.3 Scope Enforcement
- Backend tenant middleware blocks cross-organization access for non-admin users.
- Backend tenant middleware enforces branch/warehouse scope via `accessibleBranchIds`.
- Entity ID cutover complete — all business tables filter by `entity_id` only.
- `users`, `roles`, `branch_user_access`, `branch_transaction_series` all updated to `entity_id`-only queries.

### 1.4 Settings Runtime
- Settings > Roles is DB-backed through the `roles` table.
- Settings > Users role labels aligned to current role model.
- Settings > Users and Settings > Roles action buttons gate off `users_roles` permission key.

### 1.5 Sidebar Navigation
- `zerpai_sidebar.dart` gates all 40+ module keys via `hasModuleAction`.
- Sidebar correctly hides modules the user has no permissions for.
- Gated keys: `item`, `item_groups`, `item_mapping`, `composite_items`, `assemblies`, `price_list`, `transfer_orders`, `inventory_adjustments`, `picklists`, `packages`, `shipments`, `customers`, `quotations`, `retainer_invoices`, `sales_orders`, `invoices`, `delivery_challans`, `customer_payments`, `sales_returns`, `credit_notes`, `ewaybill_perms`, `payment_links`, `recurring_invoices`, `vendors`, `purchase_orders`, `purchase_receives`, `bills`, `expenses`, `recurring_bills`, `recurring_expenses`, `vendor_payments`, `vendor_credits`, `manual_journals`, `recurring_journals`, `bulk_update`, `transaction_locking`, `opening_balances`, `chart_of_accounts`, `dashboard_charts`, `reports`, `documents`, `audit_logs`

### 1.6 Partial In-Screen Gating (18 files total)
The following files have `hasModuleAction` / `withModulePermission` checks:

**Accountant (3 files):**
- `accountant_chart_of_accounts_overview.dart` — `chart_of_accounts` view/create/edit/delete
- `accountant_chart_of_accounts_creation.dart` — `chart_of_accounts` create
- `widgets/accountant_chart_of_accounts_detail_panel.dart` — `chart_of_accounts` edit/delete

**Sales (2 files):**
- `sales_generic_list.dart` — dynamic keys (sales_orders, invoices, quotations, etc.) create/import/export/bulk
- `sales_order_overview.dart` — `sales_orders` create/edit

**Inventory (3 files):**
- `inventory_shipments_list.dart` — `shipments` view/create/edit/delete
- `inventory_packages_list.dart` — `packages` view/create/edit/delete
- `inventory_picklists_list.dart` — `picklists` view/create/edit/delete

**Purchases (2 files):**
- `purchases_purchase_orders_order_overview.dart` — `purchase_orders` create/view/edit/delete
- `purchases_bills_list.dart` — `bills` create/view/edit/delete

**Items (3 files):**
- `items_item_detail_components.dart` — `item` view/create/edit/delete + `assemblies` create
- `items_report_overview.dart` — `item` view/edit
- `items_report_body_actions.dart` — `item` view/create/edit/delete

**Settings (3 files):**
- `settings_users_user_overview.dart` — `users_roles` view
- `settings_users_user_creation.dart` — `users_roles` view
- `settings_users_roles_role_creation.dart` — `users_roles`

**Core Pages (2 files):**
- `settings_branch_profile_page.dart`
- `settings_roles_page.dart`

### 1.7 Permission Infrastructure
- `PermissionService.hasModuleAction(user, moduleKey, action)` — single check
- `PermissionService.hasAllModuleActions(user, checks)` — AND logic
- `PermissionService.hasAnyModuleAction(user, checks)` — OR logic
- `ModulePermissionWrapper` / `withModulePermission()` — hides or disables widget
- `ModulePermissionAllWrapper`, `ModulePermissionAnyWrapper` — multi-check wrappers
- Module aliases wired: `shipments` ↔ `sales_shipments`, `ewaybill_perms` ↔ `ewaybill_settings`

---

## 2. Gaps — Full Audit (2026-04-15)

### Overall Coverage
| Module | Presentation Files | Gated Files | Coverage |
|---|---|---|---|
| Accountant | ~5 | 3 | 60% |
| Sales | 45+ | 2 | 4% |
| Inventory | ~9 | 3 | 33% |
| Purchases | ~8 | 2 | 25% |
| Items | 55+ | 3 | 5% |
| Reports | 11 | 0 | **0%** |
| Home/Dashboard | 4 | 0 | **0%** |
| Settings (non-users) | 10+ | 0 | **0%** |
| Printing/Documents | 1+ | 0 | **0%** |

**Total: ~18 gated out of 100+ presentation files — 18% coverage**

---

## 3. Pending — In-Screen Action Gating

### 3.1 Route-Level Gating (not done)
- `app_router.dart` has zero `redirect` guards based on permissions.
- Users can bypass sidebar by navigating directly to a URL.
- **Required**: Add `redirect` on `GoRoute` entries that checks `hasModuleAction` for the route's module key. If no permission → redirect to `/unauthorized` or home.
- Priority: **high**

### 3.2 Reports Module — ZERO GATING
All 11 screens ungated. Required: gate each by `reports` + category + action.
- `reports_center_screen.dart` — `reports` view
- `reports_audit_logs_screen.dart` — `audit_logs` view
- `reports_account_transactions.dart` — `reports` view
- `reports_general_ledger_screen.dart` — `reports` view
- `reports_profit_and_loss_screen.dart` — `reports` view
- `reports_trial_balance_screen.dart` — `reports` view
- `reports_inventory_inventory_stock.dart` — `reports` view
- `reports_inventory_valuation_screen.dart` — `reports` view
- `reports_sales_by_customer_screen.dart` — `reports` view
- `reports_reports_overview.dart` — `reports` view
- `reports_center_screen.dart` export/schedule/share actions — `reports` export/schedule/share
- Priority: **high**

### 3.3 Sales Module — 4% Coverage
- `sales_order_create.dart` — `sales_orders` create (save/submit buttons)
- `sales_quotation_create.dart` — `quotations` create
- `sales_invoice_create.dart` — `invoices` create
- `sales_credit_note_create.dart` — `credit_notes` create
- `sales_delivery_challan_create.dart` — `delivery_challans` create
- `sales_retainer_invoice_create.dart` — `retainer_invoices` create
- `sales_recurring_invoice_create.dart` — `recurring_invoices` create
- `sales_payment_create.dart` — `customer_payments` create
- `sales_payment_link_create.dart` — `payment_links` create
- `sales_eway_bill_create.dart` — `ewaybill_perms` create
- `sales_customer_create.dart` — `customers` create
- `sales_customer_overview.dart` (sections) — `customers` edit/delete
- All sales section dialogs (bulk actions, import/export) — respective module + action
- Priority: **high**

### 3.4 Purchases Module — 25% Coverage
- `purchases_purchase_orders_create.dart` — `purchase_orders` create
- `purchases_purchase_receives_list.dart` — `purchase_receives` view/create/delete
- `purchases_purchase_receives_create.dart` — `purchase_receives` create
- `purchases_vendors_vendor_list.dart` — `vendors` view/create/delete
- `purchases_vendors_vendor_create.dart` — `vendors` create
- `purchases_bills_create.dart` — `bills` create
- Vendor detail sections (bank details edit/delete) — `vendor_bank_details` edit/delete
- Priority: **high**

### 3.5 Items Module — 5% Coverage
- `items_item_create.dart` / `items_item_list.dart` / `items_item_detail.dart` — `item` create/edit/delete
- `items_composite_items_composite_creation.dart` / `_listview.dart` — `composite_items` create/edit/delete
- `inventory_itemgroup_itemgroup_create.dart` / `_list.dart` — `item_groups` create/edit/delete
- `items_pricelist_pricelist_overview.dart` / `_creation.dart` / `_edit.dart` — `price_list` create/edit/delete
- `inventory_mapping_mapping_create.dart` / `_list.dart` — `item_mapping` edit
- Import/export dialogs in items — `item` Import Items / Export Items
- Priority: **high**

### 3.6 Inventory Module — 33% Coverage
- `inventory_assemblies_assembly_overview.dart` — `assemblies` view/create/edit/delete
- `inventory_assemblies_assembly_creation.dart` — `assemblies` create
- Create forms for shipments, packages, picklists — respective module create
- Transfer orders screens (not yet built or ungated) — `transfer_orders` create/edit/approve
- Priority: **medium**

### 3.7 Accountant Module — 60% Coverage
- `accountant_manual_journals_overview_screen.dart` — `manual_journals` view/create/edit/delete
- `manual_journals_detail_panel.dart` — `manual_journals` edit/delete
- `recurring_journal_overview_screen.dart` — `recurring_journals` view/create/edit/delete
- `recurring_journals_detail_panel.dart` — `recurring_journals` edit/delete
- `accountant_transaction_locking_screen.dart` — `transaction_locking` view/edit
- `accountant_settings_screen.dart` — general_prefs view/edit
- Priority: **medium**

### 3.8 Home/Dashboard — ZERO GATING
- `home_dashboard_overview.dart` and chart/metric widgets — `dashboard_charts` view
- Dashboard charts should be hidden or replaced with a locked placeholder if `dashboard_charts` view is missing
- Priority: **medium**

### 3.9 Settings (non-users/roles) — ZERO GATING
- Branches create/edit/delete screens — `branches` create/edit/delete (currently no dedicated permission key — use `general_prefs` or add `branches` key to scheme)
- Warehouses create/edit/delete — `warehouses` create/edit/delete
- Zones/bins screens — `zones` create/edit/delete
- Transaction series screens — `transaction_series` view/edit
- Priority: **medium**

### 3.10 Printing/Documents — ZERO GATING
- `printing_templates_overview.dart` — `documents` view/create/edit
- Priority: **low**

---

## 4. Pending — Backend

### 4.1 Remaining Backend Endpoint Audit
- Verify remaining inventory submodules (assemblies, transfer orders, stock counting) enforce entity_id scope
- Verify expenses endpoints use tenant context
- Verify all submodule controllers use `@Tenant('entityId')` decorator rather than reading headers manually
- Priority: **high**

### 4.2 `transaction_series.org_id` Still Exists
- The cleanup SQL did not drop `org_id` from `transaction_series` (was not in target list)
- Column is unused by code but still present in DB
- Add to a follow-up cleanup SQL or leave as-is
- Priority: **low**

### 4.3 `user_branch_access` Unique Constraint
- Constraint is on `(org_id, user_id, branch_id)` — `org_id` still exists
- When `org_id` is eventually dropped from this table, constraint must be updated to `(entity_id, user_id, branch_id)`
- Priority: **low**

---

## 5. Pending — End-to-End Testing

### 5.1 4-Role Test Matrix
Run through the full matrix with:
- `admin` (zabnixprivatelimited@gmail.com)
- HO Admin role (full operational, no branch scope)
- Branch Admin role (scoped to one branch)
- Custom role with limited permissions (e.g. view-only)

Test per role:
- [ ] Login succeeds, correct token issued
- [ ] Sidebar shows/hides correct modules
- [ ] Navigating directly to gated URL redirects (after route-level gating is implemented)
- [ ] Create/edit/delete buttons hidden or disabled when permission missing
- [ ] API returns 403 for unauthorized actions (not just UI hiding)
- [ ] Data scoped to assigned branches only
- [ ] Reports filtered by assigned branches
- Priority: **high**

### 5.2 Settings > Users / Roles Propagation
- Verify: changing a role's permissions in Settings > Roles → user logs out + back in → new permissions take effect
- Verify: assigning a new role to a user → takes effect on next login
- Priority: **medium**

### 5.3 Logout / Session UX
- Confirm logout clears token and redirects to login
- Confirm expired token triggers re-login (not a crash)
- Confirm browser refresh preserves deep-link route after re-auth
- Priority: **medium**

---

## 6. Recommended Execution Order

1. Add route-level redirect guards in `app_router.dart` (prevents URL bypass)
2. Gate Reports module (0% → 100%) — highest-value single module to lock down
3. Gate Purchases remaining screens (25% → 100%)
4. Gate Sales remaining create/edit/detail screens (4% → ~80%)
5. Gate Items remaining screens (5% → ~80%)
6. Gate Accountant remaining screens (60% → 100%)
7. Gate Home/Dashboard charts
8. Gate Inventory assemblies + create forms
9. Gate Settings non-users screens
10. Run 4-role end-to-end test matrix
11. Fix any discovered gaps in role propagation / session UX
