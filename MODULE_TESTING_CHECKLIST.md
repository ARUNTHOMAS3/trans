# 🧪 Zerpai ERP — Post Entity Refactoring Testing Checklist

> **Purpose**: Verify all modules and their CRUD operations work correctly after the unified `entity_id` polymorphic tenancy migration.
> **Entity Model**: All scoped queries must use `entity_id` (FK → `organisation_branch_master`). Legacy `org_id` + `branch_id` columns are deprecated.
> **Legend**: ✅ Pass · ❌ Fail · ⚠️ Partial · ⏳ Pending

---

## 🔑 Pre-Flight Checks

- [ ] Backend server starts without TypeScript build errors (`npm run start:dev`)
- [ ] Flutter app compiles and loads on Chrome (`flutter run -d chrome`)
- [ ] `TenantMiddleware` resolves `entity_id` correctly from request headers
- [ ] `@Tenant()` decorator injects `TenantContext` in all controllers
- [ ] Supabase connection is active (health endpoint responds `/health`)
- [ ] No residual `org_id` / `branch_id` filtering in active service queries

---

## 1. 🏠 Home / Dashboard

| Operation | Frontend | Backend | Status |
|-----------|----------|---------|--------|
| Dashboard summary loads (sales, purchases, inventory KPIs) | [✓] | [✓] | ✅ |
| Branch-scoped metrics displayed correctly | [✓] | [✓] | ✅ |
| Charts / graphs render with real data | [✓] | [✓] | ✅ |

---

## 2. 📦 Items Module

### 2.1 Items

- [✓] **List**: Items list loads with correct branch-scoped data
- [✓] **Search**: Search by name / SKU returns relevant items
- [✓] **Create**: New item saves successfully (incl. tax, HSN, batch fields)
- [✓] **Read**: Item detail page loads all fields correctly
- [✓] **Update**: Editing an item saves changes without errors
- [✓] **Delete**: Deleting an item removes it from the list
- [ ] **Bulk Update**: Bulk update applies changes across selected items - Not checked
- [ ] **Warehouse Stocks**: Viewing per-warehouse stock works - Not checked
- [ ] **Stock Adjustment (Physical)**: Physical count adjustment saves correctly - Not checked
- [✓] **Item History**: Product history tab loads correctly - Not checked
- [ ] **Batch Info**: Batch details load for pharma items - Not checked
- [ ] **Composite Item Create**: Composite product creation works - Phase 2
- [ ] **Composite Item List**: Composite items list scoped to entity - Phase 2
- [✓] **Reorder Terms**: View/create/update/delete reorder rules for item - Not checked

### 2.2 Composite Items - Phase 2

- [ ] **List**: Composite items list loads
- [ ] **Create**: New composite item saves with parts/BOM
- [ ] **Read**: Composite item detail page loads correctly
- [ ] **Update**: Editing composite item saves changes
- [ ] **Delete**: Deleting composite item works

### 2.3 Item Groups - Phase 2

- [ ] **List**: Item groups list loads
- [ ] **Create**: New item group saves
- [ ] **Read**: Item group detail displays correctly
- [ ] **Update**: Edit item group works
- [ ] **Delete**: Remove item group works

### 2.4 Price Lists

- [✓] **List**: Price lists load correctly
- [✓] **Create**: New price list saves with line items
- [✓] **Read**: Price list detail opens correctly
- [✓] **Update**: Edit price list works
- [✓] **Delete**: Delete price list works
- [ ] **Assign to Customer**: Price list can be assigned to a customer - Not Implemented

### 2.5 Item Mapping - Not Implemented

- [ ] **List**: Item mapping list loads
- [ ] **Create**: New item mapping entry saves
- [ ] **Update**: Edit mapping works
- [ ] **Delete**: Remove mapping entry works

---

## 3. 🏭 Inventory Module

### 3.1 Assemblies - Phase 2

- [ ] **List**: Assembly jobs list loads
- [ ] **Create**: New assembly order saves
- [ ] **Read**: Assembly detail page loads
- [ ] **Update**: Edit assembly works
- [ ] **Complete**: Marking assembly as complete updates stock

### 3.2 Inventory Adjustments - Not Implemented

- [ ] **List**: Adjustments list loads with branch scope
- [ ] **Create**: New adjustment (add/remove/set) saves
- [ ] **Read**: Adjustment detail page loads
- [ ] **Update**: Edit draft adjustment works
- [ ] **Delete**: Delete draft adjustment works

### 3.3 Picklists - Work In Progress

- [ ] **List**: Picklists list loads
- [ ] **Create**: New picklist saves
- [ ] **Read**: Picklist detail page loads
- [ ] **Update**: Edit picklist works
- [ ] **Delete**: Delete picklist works
- [ ] **Warehouse Items**: Fetch items available in a warehouse

### 3.4 Packages - Work In Progress

- [ ] **List**: Packages list loads
- [ ] **Create**: New package saves
- [ ] **Read**: Package detail page loads
- [ ] **Update**: Edit package works
- [ ] **Delete**: Delete package works

### 3.5 Shipments - Work In Progress

- [ ] **List**: Shipments list loads
- [ ] **Create**: New shipment saves
- [ ] **Read**: Shipment detail page loads
- [ ] **Update**: Edit shipment works
- [ ] **Delete**: Delete shipment works

### 3.6 Transfer Orders - Not Implemented

- [ ] **List**: Transfer orders list loads
- [ ] **Create**: New transfer order saves (source + destination branch)
- [ ] **Read**: Transfer order detail loads
- [ ] **Update**: Edit transfer order works
- [ ] **Approve / Receive**: Status transition works

---

## 4. 💰 Sales Module

### 4.1 Customers 

- [✓] **List**: Customers list loads with branch scope
- [x] **Search**: Search by name / GSTIN works
- [✓] **Create**: New customer saves (with billing/shipping address, GSTIN)
- [✓] **Read**: Customer detail page loads
- [✓] **Update**: Edit customer works
- [x] **Delete**: Delete customer works
- [ ] **Statistics**: Customer statistics tab loads

### 4.2 Retainer Invoices

- [ ] **List**: Retainer invoices list loads
- [ ] **Create**: New retainer invoice saves
- [ ] **Read**: Retainer invoice detail loads
- [ ] **Update**: Edit draft retainer invoice works
- [ ] **Delete**: Delete draft retainer invoice works

### 4.3 Sales Orders

- [ ] **List**: Sales orders list loads with status filters
- [ ] **Create**: New sales order saves (customer, items, tax)
- [ ] **Read**: Sales order detail page loads
- [ ] **Update**: Edit sales order works
- [ ] **Delete / Cancel**: Cancel order works
- [ ] **Convert to Invoice**: Convert SO → Invoice

### 4.4 Invoices

- [ ] **List**: Invoices list loads
- [ ] **Create**: New invoice saves (manual / from SO)
- [ ] **Read**: Invoice detail page loads
- [ ] **Update**: Edit draft invoice works
- [ ] **Delete**: Delete draft invoice works
- [ ] **Print / PDF**: Invoice PDF generation works
- [ ] **Payment Record**: Record payment against invoice

### 4.5 Delivery Challans

- [ ] **List**: Delivery challans list loads
- [ ] **Create**: New delivery challan saves
- [ ] **Read**: Delivery challan detail loads
- [ ] **Update**: Edit works
- [ ] **Delete**: Delete works

### 4.6 Payments Received

- [ ] **List**: Payments received list loads
- [ ] **Create**: New payment record saves
- [ ] **Read**: Payment detail loads
- [ ] **Update**: Edit payment works
- [ ] **Delete**: Delete payment works

### 4.7 Sales Returns

- [ ] **List**: Sales returns list loads
- [ ] **Create**: New return saves (against invoice)
- [ ] **Read**: Return detail loads
- [ ] **Update**: Edit works

### 4.8 Credit Notes

- [ ] **List**: Credit notes list loads
- [ ] **Create**: New credit note saves
- [ ] **Read**: Credit note detail loads
- [ ] **Update**: Edit draft credit note works
- [ ] **Delete**: Delete draft credit note works

### 4.9 e-Way Bills

- [ ] **List**: e-Way bills list loads
- [ ] **Create**: New e-Way bill saves
- [ ] **Read**: e-Way bill detail loads
- [ ] **Update**: Edit works
- [ ] **Delete**: Delete works

---

## 5. 🛒 Purchases Module

### 5.1 Vendors

- [ ] **List**: Vendors list loads with branch scope
- [ ] **Search**: Search vendors works
- [ ] **Create**: New vendor saves (GSTIN, address, payment terms)
- [ ] **Read**: Vendor detail page loads
- [ ] **Update**: Edit vendor works
- [ ] **Delete**: Delete vendor works

### 5.2 Expenses

- [ ] **List**: Expenses list loads
- [ ] **Create**: New expense saves
- [ ] **Read**: Expense detail loads
- [ ] **Update**: Edit expense works
- [ ] **Delete**: Delete expense works

### 5.3 Recurring Expenses

- [ ] **List**: Recurring expenses list loads
- [ ] **Create**: New recurring expense saves with schedule
- [ ] **Read**: Recurring expense detail loads
- [ ] **Update**: Edit recurring expense works
- [ ] **Delete**: Delete recurring expense works

### 5.4 Purchase Orders

- [ ] **List**: PO list loads with status filters
- [ ] **Create**: New PO saves (vendor, items, tax)
- [ ] **Read**: PO detail page loads
- [ ] **Update**: Edit PO works
- [ ] **Delete**: Delete PO works

### 5.5 Bills

- [ ] **List**: Bills list loads
- [ ] **Create**: New bill saves (from PO or manual)
- [ ] **Read**: Bill detail page loads
- [ ] **Update**: Edit draft bill works
- [ ] **Delete**: Delete draft bill works
- [ ] **Payment**: Record payment against bill

### 5.6 Recurring Bills

- [ ] **List**: Recurring bills list loads
- [ ] **Create**: New recurring bill saves
- [ ] **Read**: Recurring bill detail loads
- [ ] **Update**: Edit works
- [ ] **Delete**: Delete works

### 5.7 Payments Made

- [ ] **List**: Payments made list loads
- [ ] **Create**: New payment saves
- [ ] **Read**: Payment detail loads
- [ ] **Update**: Edit payment works
- [ ] **Delete**: Delete payment works

### 5.8 Vendor Credits

- [ ] **List**: Vendor credits list loads
- [ ] **Create**: New vendor credit saves
- [ ] **Read**: Vendor credit detail loads
- [ ] **Update**: Edit works
- [ ] **Delete**: Delete works

---

## 6. 📒 Accountant Module

### 6.1 Manual Journals

- [ ] **List**: Manual journals list loads with branch scope
- [ ] **Create**: New journal entry saves (debit/credit lines)
- [ ] **Read**: Journal detail page loads
- [ ] **Update**: Edit draft journal works
- [ ] **Delete**: Delete draft journal works
- [ ] **Status Change**: Approve/publish journal works
- [ ] **Clone**: Clone journal creates a copy
- [ ] **Reverse**: Reverse journal creates contra entry
- [ ] **Attachments**: View and upload attachments to journal
- [ ] **Create Template from Journal**: Save as template works

### 6.2 Recurring Journals

- [ ] **List**: Recurring journals list loads
- [ ] **Create**: New recurring journal saves with schedule
- [ ] **Read**: Recurring journal detail loads
- [ ] **Update**: Edit recurring journal works
- [ ] **Delete**: Delete recurring journal works
- [ ] **Clone**: Clone recurring journal works
- [ ] **Generate Child**: Manual trigger generates child journal
- [ ] **Status Change**: Pause/resume/activate recurring journal

### 6.3 Bulk Update

- [ ] **Search Transactions**: Filter transactions by account/date/amount
- [ ] **Bulk Update**: Reassign transactions to a different account

### 6.4 Transaction Locking

- [ ] **List Locks**: View locked modules/periods
- [ ] **Lock Module**: Lock a module for a date period
- [ ] **Unlock Module**: Unlock a locked module

### 6.5 Opening Balances

- [ ] **View**: Opening balances page loads
- [ ] **Save**: Save opening balances for accounts

---

## 7. 📊 Accounts Module

### 7.1 Chart of Accounts

- [ ] **List**: All accounts load grouped by type
- [ ] **Create**: New account saves
- [ ] **Read**: Account detail + transaction history loads
- [ ] **Update**: Edit account works
- [ ] **Delete**: Delete account works (if no transactions)
- [ ] **Search**: Search accounts by name/code works
- [ ] **Filter by Group**: Filter by account type/group works
- [ ] **Closing Balance**: Closing balance calculated correctly

---

## 8. 📈 Reports Module

- [ ] **Dashboard Summary**: KPI cards load with branch-scoped data
- [ ] **Profit & Loss**: P&L statement loads for date range
- [ ] **General Ledger**: General ledger renders with account entries
- [ ] **Account Transactions**: Filtered transactions by account load
- [ ] **Trial Balance**: Trial balance loads correctly
- [ ] **Sales by Customer**: Sales by customer report loads
- [ ] **Inventory Valuation**: Inventory valuation by branch loads
- [ ] **Daily Sales**: Daily sales report loads
- [ ] **Inventory Stock**: Current stock levels load

---

## 9. 📄 Documents Module

- [ ] **List**: Documents list loads for branch
- [ ] **Upload**: Document upload saves correctly
- [ ] **View**: Document preview/download works

---

## 10. 🕵️ Audit Logs Module

- [ ] **List**: Audit logs list loads
- [ ] **Filter by Table**: Filter by table name works
- [ ] **Filter by Action**: Filter by INSERT/UPDATE/DELETE works
- [ ] **Filter by Date Range**: Date range filter works
- [ ] **Filter by Actor**: Filter by user works
- [ ] **Filter by Request ID**: Request ID filter works
- [ ] **Search**: Full-text search works

---

## 11. ⚙️ Settings Module

### 11.1 Organization & Branches

- [✓] **Branches List**: Branches list loads
- [✓] **Branch Create**: New branch saves
- [✓] **Branch Detail**: Branch detail loads
- [✓] **Branch Update**: Edit branch works
- [✓] **Branch Delete**: Delete branch works
- [✓] **Business Types**: Business types dropdown loads

### 11.2 Users & Roles

- [✓] **Users List**: Users list loads with branch scope
- [✓] **User Create**: New user record saves
- [✓] **User Detail**: User detail page loads
- [✓] **User Update**: Edit user works
- [✓] **User Status**: Activate/deactivate user works
- [✓] **User Delete**: Delete user works
- [✓] **Set Default Branch**: Set user's default branch works
- [✓] **Location Access**: View/update user branch access works
- [✓] **Role Catalog**: Roles list loads
- [✓] **Role Create**: New role saves with permissions
- [✓] **Role Update**: Edit role permissions works
- [✓] **Role Delete**: Delete role works

### 11.3 Warehouses

- [✓] **List**: Warehouses list loads
- [✓] **Create**: New warehouse saves
- [✓] **Read**: Warehouse detail loads
- [✓] **Update**: Edit warehouse works
- [✓] **Delete**: Delete warehouse works

### 11.4 Zones & Bin Locations

- [ ] **Zones List**: Zones list loads for branch
- [ ] **Zone Create**: New zone saves
- [ ] **Zone Disable**: Disable zone works
- [ ] **Bin List**: Bins within a zone load
- [ ] **Bin Create**: New bin saves within zone
- [ ] **Bin Update**: Edit bin works
- [ ] **Bin Delete**: Delete bin works
- [ ] **Bulk Action**: Bulk zone/bin actions work
- [ ] **Get Counts**: Zone/bin counts loads correctly

### 11.5 Transaction Series

- [✓] **List**: Transaction series list loads
- [✓] **Create**: New series numbering rule saves
- [✓] **Read**: Series detail loads
- [✓] **Update**: Edit series works
- [✓] **Delete**: Delete series works

---

## 12. 🖨️ Printing Module

- [ ] **Templates List**: Print templates list loads
- [ ] **Create Template**: New print template saves
- [ ] **Edit Template**: Edit template works
- [ ] **Preview Template**: Template preview renders correctly
- [ ] **Print Invoice**: Print from invoice page works

---

## 🔍 Tenancy Isolation Tests

> Critical: These tests ensure `entity_id` scoping is working correctly and data does not leak across tenants.

- [ ] **Cross-Entity Isolation**: Items created under entity A do NOT appear when browsing as entity B
- [ ] **Sales Isolation**: Sales orders created under branch A do NOT show in branch B
- [ ] **Purchase Isolation**: Purchase orders scoped correctly per entity
- [ ] **Report Scope**: Reports only show data for the active entity
- [ ] **Audit Log Scope**: Audit logs filtered to active entity
- [ ] **User Scope**: Users list shows only users for the active entity
- [ ] **TenantContext in Headers**: Missing `X-Entity-Id` header returns `400 Bad Request` or tenant resolution error

---

## 🐛 Notes / Failed Tests

> Use this section to record failing tests with error details.

| Module | Operation | Error Message | Status |
|--------|-----------|---------------|--------|
| | | | |

---

**Last Updated**: April 20, 2026 — 14:04 IST
**Updated By**: Post Entity Refactoring Audit
