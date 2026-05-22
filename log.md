### Dev- Arun

<!-- LOG RULES START -->

### Zerpai Log Maintenance Rules

1. **Initialize/Locate**: If `log.md` exists in the root, read it first. If not, create it.
2. **Dev Attribution**: Always ensure the very first line of the file is `### Dev- Arun`.
3. **Structure**: Maintain a numbered list of features (e.g., `## 7. Feature Name`). Include a high-level description and bullet points for logic.
4. **File Categorization (CRITICAL)**: You MUST split the changed files into two distinct lists: 'Frontend Files' (`lib/...`) and 'Backend Files' (`backend/...`).
5. **Append Only**: Never delete previous entries. Always add new changes at the **bottom** of the file using `cat >> log.md <<'EOF'`.
6. **Timestamps**: Every batch of changes must end with: `Timestamp of Log Update: [Date] - [Time] (IST)`.
7. **Engineer-to-Engineer**: Write with technical depth, explaining 'why' architectural choices were made.
8. **Method**: Use bash heredoc append only: `cat >> e:/zerpai-new/log.md <<'EOF'` ... `EOF`. NEVER use `printf` with full-file rewrite. NEVER use the Edit tool on this file.
<!-- LOG RULES END -->

## 1. Sales Invoice UI & Feature Standardization (May 19, 2026)

### Summary
Aligned the Sales Invoice creation workflow (`sales_invoice_create.dart`) with the established ERP standards. Standardized the date picker widgets, implemented a full-parity file attachments UI, and unified dropdown item hover behaviors to ensure consistency and visual appeal.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/presentation/sales_invoice_create.dart`:
  - **Date Pickers Refactoring**: Replaced manual `showDatePicker` calls for `Invoice Date` and `Due Date` fields with the shared `ZerpaiDatePicker.show(...)` component utilizing unique `GlobalKey` references.
  - **File Attachment parity**: Added `_attachedFiles` state arrays, constraints checks (max 10 files, max 5MB size limit), conditional rendering of attachment badge, and implemented an interactive overlay showing files list with hover-to-delete options.
  - **Hover Visual Refinement**: Changed background hover highlight from standard blue/light-blue states to the unified `AppTheme.infoBlue` (`0xFF3B82F6`) and white text. Affected dropdown widgets include the accounts selection overlay, reporting tags dropdown, and the upload pop-up menu.

Timestamp of Log Update: May 19, 2026 - 12:10 PM (IST)
## 2. System Handoff & State Capture (May 20, 2026)

### Summary
Created a handoff directory containing all currently modified and untracked files across the frontend and backend stack.

### Detailed Engineering Changes

#### Frontend Files
- `lib/core/layout/zerpai_sidebar.dart`
- `lib/core/routing/app_router.dart`
- `lib/modules/inventory/packages/presentation/inventory_packages_create.dart`
- `lib/modules/inventory/shipments/presentation/inventory_shipments_create.dart`
- `lib/modules/inventory/shipments/presentation/inventory_shipments_edit.dart`
- `lib/modules/inventory/shipments/presentation/inventory_shipments_list.dart`
- `lib/modules/items/items/presentation/sections/formulation_section.dart`
- `lib/modules/purchases/bills/presentation/purchases_bills_create.dart`
- `lib/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart`
- `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_create.dart`
- `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_list.dart`
- `lib/modules/purchases/purchase_orders/repositories/purchases_purchase_orders_order_repository_impl.dart`
- `lib/modules/purchases/purchase_receives/models/purchases_purchase_receives_model.dart`
- `lib/modules/purchases/purchase_receives/presentation/purchases_purchase_receives_create.dart`
- `lib/modules/purchases/purchase_receives/presentation/purchases_purchase_receives_edit.dart`
- `lib/modules/purchases/purchase_receives/presentation/purchases_purchase_receives_list.dart`
- `lib/modules/sales/presentation/sales_invoice_create.dart`
- `lib/modules/sales/presentation/sales_order_create.dart`
- `lib/modules/sales/presentation/sales_order_list.dart`
- `lib/modules/sales/presentation/widgets/advanced_customer_search_dialog.dart`
- `lib/modules/sales/presentation/widgets/sales_item_quick_edit_dialog.dart`
- `lib/shared/widgets/email_composer.dart`

#### Backend Files
- `backend/drizzle/relations.ts`
- `backend/drizzle/schema.ts`
- `backend/src/app.module.ts`
- `backend/src/common/auth/auth.module.ts`
- `backend/src/common/auth/auth.service.ts`
- `backend/src/common/decorators/tenant.decorator.ts`
- `backend/src/common/filters/global_exception.filter.ts`
- `backend/src/common/interceptors/audit.interceptor.ts`
- `backend/src/common/interceptors/standard_response.interceptor.spec.ts`
- `backend/src/common/interceptors/standard_response.interceptor.ts`
- `backend/src/common/middleware/tenant.middleware.ts`
- `backend/src/database/schema.ts`
- `backend/src/db/db.ts`
- `backend/src/db/relations.ts`
- `backend/src/db/schema.ts`
- `backend/src/health/health.controller.ts`
- `backend/src/health/health.module.ts`
- `backend/src/lookups/global-lookups.controller.ts`
- `backend/src/lookups/lookups.controller.ts`
- `backend/src/lookups/lookups.module.ts`
- `backend/src/main.ts`
- `backend/src/modules/accountant/accountant.controller.ts`
- `backend/src/modules/accountant/accountant.module.ts`
- `backend/src/modules/accountant/accountant.service.ts`
- `backend/src/modules/accountant/r2-storage.service.ts`
- `backend/src/modules/accountant/recurring-journals.cron.service.ts`
- `backend/src/modules/branches/branches.controller.ts`
- `backend/src/modules/branches/branches.module.ts`
- `backend/src/modules/branches/branches.service.ts`
- `backend/src/modules/documents/documents.module.ts`
- `backend/src/modules/gst/gst.controller.ts`
- `backend/src/modules/gst/gst.module.ts`
- `backend/src/modules/gst/gst.service.ts`
- `backend/src/modules/health/health.controller.spec.ts`
- `backend/src/modules/health/health.controller.ts`
- `backend/src/modules/health/health.module.ts`
- `backend/src/modules/inventory/controllers/packages.controller.ts`
- `backend/src/modules/inventory/controllers/picklists.controller.ts`
- `backend/src/modules/inventory/inventory.module.ts`
- `backend/src/modules/inventory/inventory.service.ts`
- `backend/src/modules/inventory/services/packages.service.ts`
- `backend/src/modules/inventory/services/picklists.service.ts`
- `backend/src/modules/lookups/global-lookups.controller.ts`
- `backend/src/modules/lookups/lookups.controller.ts`
- `backend/src/modules/lookups/lookups.module.ts`
- `backend/src/modules/products/dto/create-product.dto.ts`
- `backend/src/modules/products/dto/update-product.dto.ts`
- `backend/src/modules/products/pricelist/pricelist.controller.ts`
- `backend/src/modules/products/pricelist/pricelist.module.ts`
- `backend/src/modules/products/products.controller.ts`
- `backend/src/modules/products/products.module.ts`
- `backend/src/modules/products/products.service.ts`
- `backend/src/modules/purchases/purchase-orders/controllers/purchase-orders.controller.ts`
- `backend/src/modules/purchases/purchase-orders/dto/create-purchase-order.dto.ts`
- `backend/src/modules/purchases/purchase-orders/dto/update-purchase-order.dto.ts`
- `backend/src/modules/purchases/purchase-orders/entities/purchase-order.entity.ts`
- `backend/src/modules/purchases/purchase-orders/purchase-orders.module.ts`
- `backend/src/modules/purchases/purchase-orders/services/purchase-orders.service.ts`
- `backend/src/modules/purchases/purchase-receives/controllers/purchase-receives.controller.ts`
- `backend/src/modules/purchases/purchase-receives/dto/create-purchase-receive.dto.ts`
- `backend/src/modules/purchases/purchase-receives/dto/update-purchase-receive.dto.ts`
- `backend/src/modules/purchases/purchase-receives/entities/purchase-receive.entity.ts`
- `backend/src/modules/purchases/purchase-receives/purchase-receives.module.ts`
- `backend/src/modules/purchases/purchase-receives/services/purchase-receives.service.ts`
- `backend/src/modules/purchases/purchases.module.ts`
- `backend/src/modules/purchases/vendors/controllers/vendors.controller.ts`
- `backend/src/modules/purchases/vendors/dto/create-vendor.dto.ts`
- `backend/src/modules/purchases/vendors/dto/update-vendor.dto.ts`
- `backend/src/modules/purchases/vendors/entities/vendor.entity.ts`
- `backend/src/modules/purchases/vendors/services/vendors.service.ts`
- `backend/src/modules/purchases/vendors/vendors.module.ts`
- `backend/src/modules/reports/reports.controller.spec.ts`
- `backend/src/modules/reports/reports.controller.ts`
- `backend/src/modules/reports/reports.module.ts`
- `backend/src/modules/reports/reports.service.spec.ts`
- `backend/src/modules/reports/reports.service.ts`
- `backend/src/modules/sales/controllers/customers.controller.ts`
- `backend/src/modules/sales/controllers/sales.controller.ts`
- `backend/src/modules/sales/dto/create-customer.dto.ts`
- `backend/src/modules/sales/dto/update-customer.dto.ts`
- `backend/src/modules/sales/entities/customer.entity.ts`
- `backend/src/modules/sales/sales.module.ts`
- `backend/src/modules/sales/services/customers.service.ts`
- `backend/src/modules/sales/services/hsn-sac.service.ts`
- `backend/src/modules/sales/services/sales.service.ts`
- `backend/src/modules/settings-zones/dto/bulk-bin-action.dto.ts`
- `backend/src/modules/settings-zones/dto/bulk-zone-action.dto.ts`
- `backend/src/modules/settings-zones/settings-zones.controller.ts`
- `backend/src/modules/settings-zones/settings-zones.service.ts`
- `backend/src/modules/supabase/supabase.module.ts`
- `backend/src/modules/supabase/supabase.service.ts`
- `backend/src/modules/transaction-locking/transaction-locking.controller.ts`
- `backend/src/modules/transaction-locking/transaction-locking.module.ts`
- `backend/src/modules/transaction-locking/transaction-locking.service.ts`
- `backend/src/modules/transaction-series/transaction-series.controller.ts`
- `backend/src/modules/transaction-series/transaction-series.module.ts`
- `backend/src/modules/transaction-series/transaction-series.service.ts`
- `backend/src/modules/users/users.controller.ts`
- `backend/src/modules/users/users.module.ts`
- `backend/src/modules/users/users.service.ts`
- `backend/src/modules/warehouses-settings/warehouses-settings.controller.ts`
- `backend/src/modules/warehouses-settings/warehouses-settings.module.ts`
- `backend/src/modules/warehouses-settings/warehouses-settings.service.ts`
- `backend/src/sequences/sequences.controller.ts`
- `backend/src/sequences/sequences.module.ts`
- `backend/src/sequences/sequences.service.ts`

Timestamp of Log Update: May 20, 2026 - 10:27 AM (IST)



## 3. Sales Invoice Reference Field & Layout Adjustments (May 20, 2026)

### Summary
Enhanced the Sales Invoice creation screen (`sales_invoice_create.dart`) by adding a dedicated `Reference#` input field positioned above the `Invoice#` textbox and aligning table bottom border treatments. Cleaned up the reporting tags banner layout by removing superfluous bottom borders.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/presentation/sales_invoice_create.dart`:
  - **Reference# Field Addition**: Added `referenceCtrl` and introduced a new `Reference#` text field layout directly above `Invoice#`.
  - **Data Hydration & Save Integration**: Updated `_hydrateFromInitialOrder` to populate `referenceCtrl` with `order.reference`. Refactored `_saveSalesInvoice` payload mapping to store `referenceCtrl.text` in the `reference` column (falling back to `orderNumberCtrl.text` if empty).
  - **Table Bottom Color Realignment**: Updated table bottom border container background to render grey (`Color(0xFFF3F4F6)`) when `_showAdditionalInfo` is active, matching `sales_order_create.dart` design.
  - **Reporting Tags Border Adjustment**: Removed the `bottom: BorderSide(color: _kBorder)` constraint from the container decoration wrapping `_buildReportingTags` to eliminate redundant horizontal border lines.

Timestamp of Log Update: May 20, 2026 - 1:00 PM (IST)

## 4. Connection of Sales Invoice Screen to Backend DB & Bug Fixes (May 22, 2026)

### Summary
Successfully integrated the Sales Invoice creation screen (`sales_invoice_create.dart`) with the NestJS backend and PostgreSQL database, enabling direct and package-linked invoice saving, robust batch/bin resolution, customized listing interfaces, and clean database column mappings.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/presentation/sales_invoice_create.dart`:
  - **Dynamic Save Integration**: Connected the submit button to `ref.read(salesOrderApiServiceProvider).createInvoice(...)` with automatic salesperson, customer, and warehouse UUID resolution.
  - **Background Batch/Bin Resolution**: Implemented asynchronous lookups during save to resolve string names of batches and bin locations to their respective database UUIDs (`batchId`, `layerId`, `binId`).
  - **Selective Batch Dialog Pre-filling**: Added an `isFromPackage` parameter to the `_InvoiceSelectBatchesDialog` widget constructor.
  - **Selective Batch Lookup Short-circuiting**: Refactored `_loadInitialData()` inside the dialog state to bypass the automatic database pre-fetch when `widget.isFromPackage` is `false`, ensuring direct invoice batches are only loaded upon user interaction.
- `lib/modules/sales/services/sales_order_api_service.dart`:
  - **API Service Layer**: Added Dio HTTP endpoints `createInvoice(...)`, `getInvoices()`, and `getInvoiceById(id)` to map sales invoices frontend payloads.
- `lib/core/routing/app_router.dart`:
  - **Custom Overview Routing**: Updated `AppRoutes.salesInvoices` builder to map to `SalesInvoiceOverviewScreen` rather than the standard `SalesGenericListScreen` for tailored listing visualizer.
- `lib/modules/sales/presentation/sales_invoice_list.dart`:
  - **Invoice Overview Visualizer [NEW]**: Implemented a responsive high-density listing interface displaying customer names, totals, outstanding balances, and custom search filters.

#### Backend Files
- `backend/src/db/schema.ts` & `backend/drizzle/schema.ts`:
  - **Sales Order Items Schema Updates**: Appended `hsnCode`, `accounts`, and `pricelist` columns to match database definitions.
  - **Inventory Package Items Schema Updates**: Appended `batchNo`, `binLocation`, and `foc` columns to the package item registry.
- `backend/src/modules/sales/controllers/sales.controller.ts`:
  - **REST API Endpoints**: Exposed `@Get("invoices")`, `@Get("invoices/:id")`, and `@Post("invoices")` routes protected under the multi-tenant context.
- `backend/src/modules/sales/services/sales.service.ts`:
  - **Core Persistence Logic**: Implemented `createInvoice()`, `getInvoices()`, and `getInvoiceById()` methods executing safe, multi-tenant queries on `invoice_master`, `invoice_items`, `invoice_item_batches`, and `batch_transactions`.
  - **is_delete Constraint Resolution**: Passed `is_delete: false` to the `invoice_master` insert payload to satisfy database NOT NULL constraints and resolve the Postgres 500 save error.

Timestamp of Log Update: May 22, 2026 - 10:20 PM (IST)

## 5. Sales Invoice Save Validation & Select Batch Dialog Tweak (May 22, 2026)

### Summary
Fixed a critical PostgreSQL NOT NULL constraint violation for `hsn_code` in `invoice_items` by ensuring comprehensive product HSN code mapping/fallback logic in the backend `createInvoice` routine. Additionally, updated the `_InvoiceSelectBatchesDialogState` initialization flow on the frontend to skip auto-selecting the first bin location unless the item specifically originates from a package.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/presentation/sales_invoice_create.dart`:
  - **Conditional Bin Auto-loading Avoidance**: Modified `_loadInitialData()` to skip pre-filling `row.binLocationCtrl.text = _binLocations.first` for new batch rows when `widget.isFromPackage` is `false`, ensuring direct invoice items start with an unselected bin location.

#### Backend Files
- `backend/src/modules/sales/services/sales.service.ts`:
  - **Item Field Resolution Integration**: Called `resolveItemFields()` at the start of `createInvoice()` to fetch and populate HSN code fallbacks from the `products` table.
  - **Null/String "null" HSN Handling**: Updated the mapping in `resolveItemFields()` to convert `null` or explicit string `"null"` values of `hsnCode`/`hsn_code` to the default `"0"` value, preventing PostgreSQL not-null constraint errors on `invoice_items`.

Timestamp of Log Update: May 22, 2026 - 10:45 PM (IST)

## 6. Expiry Date Formatting Fix for PostgreSQL (May 22, 2026)

### Summary
Resolved a critical backend crash during invoice persistence caused by date format mismatch. The frontend UI collects expiry dates in the dd-MM-yyyy format, but PostgreSQL expects standard ISO YYYY-MM-DD date structures. Implemented robust string-to-date translation in the NestJS service.

### Detailed Engineering Changes

#### Backend Files
- `backend/src/modules/sales/services/sales.service.ts`:
  - **parseToIsoDate Helper**: Introduced a robust date parsing utility method that matches formats like `DD-MM-YYYY` using regex and transforms them safely to Postgres-compatible `YYYY-MM-DD`, falling back to standard `Date` conversions or original strings as a safety default.
  - **Batch Insertion Alignment**: Applied `parseToIsoDate` to `batch.expiryDate` mapping within the `createInvoice` loop, ensuring seamless DB insertion of batch details without throwing "date/time field value out of range" 500 errors.

Timestamp of Log Update: May 22, 2026 - 10:55 PM (IST)

## 7. Sales Invoice List Binding & Parsing Fix (May 22, 2026)

### Summary
Resolved a critical issue where saved sales invoices were not displaying on the "All Invoices" screen. The overview page was bound to salesInvoicesProvider which fetched from /sales?type=invoice (reading the sales_orders table) instead of the dedicated /sales/invoices endpoint (reading the invoice_master table). Updated the provider routing and enhanced SalesOrder.fromJson to seamlessly parse invoice_master database fields.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/controllers/sales_order_controller.dart:
  - **salesInvoicesProvider Route Alignment**: Refactored the provider to fetch dynamic lists directly using the dedicated getInvoices() method on SalesOrderApiService targeting the /sales/invoices endpoint.
- lib/modules/sales/models/sales_order_model.dart:
  - **SalesOrder.fromJson Field Normalization**: Added robust key fallbacks to parse invoice_master columns returned by the backend:
    - Mapped invoice_number/invoiceNumber to saleNumber.
    - Mapped invoice_date/invoiceDate to saleDate.
    - Mapped due_date/dueDate to expectedShipmentDate (the listing due date representation).
    - Mapped subtotal to subTotal.
    - Mapped grand_total/grandTotal to total.
    - Mapped adjustment_amount/adjustmentAmount to adjustment.
    - Mapped terms_conditions/termsConditions to termsAndConditions.
    - Mapped subject to reference.

Timestamp of Log Update: May 22, 2026 - 11:06 PM (IST)

## 8. Schema Relation Cache Error Resolution in getInvoices (May 22, 2026)

### Summary
Resolved a critical backend 500 error on fetching sales invoices (`GET /sales/invoices`) where Supabase/PostgREST failed with "Could not find a relationship between 'invoice_master' and 'customers' in the schema cache". This occurred due to the absence of the explicit foreign key schema mapping cached in Supabase's PostgREST layer. Restructured the backend retrieval method to fetch invoice records first and then resolve customer data separately.

### Detailed Engineering Changes

#### Backend Files
- `backend/src/modules/sales/services/sales.service.ts`:
  - **Independent Customer Queries in getInvoices**: Refactored `getInvoices(orgId)` to execute simple, unjoined queries on the `invoice_master` table. Used a separate batch select on `customers` based on distinct customer IDs, matching records back in TypeScript memory. This avoids joining tables directly in the Supabase API call, bypasses relational schema cache problems entirely, and replicates the successful pattern used in `getInvoiceById`.

Timestamp of Log Update: May 22, 2026 - 11:15 PM (IST)
