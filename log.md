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

## 9. Purchases Bills Items Table UI Refactoring & Dialog Integration (May 27, 2026)

### Summary
Unified the Purchases Bills items table and batch selection dialog flows with the standardized sales invoice interfaces. Resolved compile-time type issues, missing utility imports, and redundant class declarations, ensuring zero compiler errors/warnings under touched scopes.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - **Standardized Imports**: Imported `package:flutter/services.dart` for input formatters, `package:zerpai_erp/modules/inventory/models/warehouse_model.dart` and its provider for warehouse details resolution, and `package:zerpai_erp/shared/utils/zerpai_toast.dart` for validation feedback.
  - **Prefixed Date Formatting**: Imported `package:intl/intl.dart` as `intl` to align date-parsing operations within the batch dialog.
  - **Batch Controller Integration**: Declared the private class `_InvoiceBatchRowController` locally within the bills module to govern individual batch form fields.
  - **Color Tokens Alignment**: Declared specific theme-compliant `_dlg` color constants locally to enforce standardized surface and text styling in dialog forms.
  - **Dead Code and Duplicate Elimination**: Pruned duplicate overrides of `_TaxSelectionPopover`, `_SpecialPopoverListItem`, and `_SpecialPopoverListItemState` classes. Sanitized dead/redundant null-aware coalescing operations on non-nullable warehouse and batch futures.

Timestamp of Log Update: May 27, 2026 - 9:55 AM (IST)


## 10. Purchases Bills Close Button & Sales Invoices HSN Popover Integration (May 27, 2026)

### Summary
Aligned the Purchases Bills item row controls and close buttons to standardized layouts. Fully ported the advanced _HSNCodeEditPopover class and supporting caret canvas rendering to the Sales Invoices creation interface, enabling robust inline HSN code lookup and updating.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **SKU Row Cleanup**: Removed redundant SKU visual rows in the item layout cell to match the high-density ERP look.
  - **Close Button Standardisation**: Updated the item row's delete/close button foreground color to neutral black to match the design specifications.
- lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart:
  - **Caret Painter Enhancement**: Upgraded _TrianglePainter to support configurable isUp direction and hasBorder lines, retaining backwards-compatible drawing.
  - **Inline HSN Editing Popover**: Appended _HSNCodeEditPopover class definition to the end of the file. Integrates inline text controller editing, auto-focus, standard green Save action button, and external HsnSacSearchModal lookup functionality triggered via search suffix icon.

Timestamp of Log Update: May 27, 2026 - 10:10 AM (IST)

## 11. Sales Orders HSN Popover UI Harmonisation (May 27, 2026)

### Summary
Harmonized the Sales Orders creation HSN popover interface by porting the standardized _HSNCodeEditPopover from purchase orders. Replaced the legacy double-text-field and separate external search icon layouts with the unified high-density single text field and inline search suffix icon interface, ensuring complete design system parity and flawless compilation.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - **Caret Painter Directionality**: Upgraded the local _TrianglePainter to support directional isUp flags for caret positioning.
  - **Popover Overlay Refactoring**: Updated _toggleHsnOverlay to mount _HSNCodeEditPopover with standard MouseRegion boundary detection and auto-dimming gestures.
  - **Widget Definition Porting**: Appended the standardized stateful _HSNCodeEditPopover class definition to the bottom of the module file.

Timestamp of Log Update: May 27, 2026 - 11:05 AM (IST)

## 12. Purchases Bills HSN Popover UI Harmonisation (May 27, 2026)

### Summary
Harmonized the Purchases Bills creation HSN popover interface by refactoring the manual overlay creation to use the unified stateful _HSNCodeEditPopover class. This replaces the raw container and non-clickable icon rows with a high-fidelity single text field with an inline search suffix icon, enabling full HsnSacSearchModal lookup support.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Popover Overlay Refactoring**: Refactored _showHsnEditOverlay to mount _HSNCodeEditPopover in the followers layer.
  - **Close Button Standardisation**: Updated _HSNCodeEditPopover button label from 'Cancel' to 'Close' for design alignment.

Timestamp of Log Update: May 27, 2026 - 11:28 AM (IST)

## 13. Purchases Bills popover alignment, Rate Actions, and Item Details Sidebar (May 27, 2026)

### Summary
Adjusted the Purchases Bills HSN popover horizontal offset and arrow position to prevent screen clipping. Added interactive Recent Transactions action link beneath the item Rate field, and implemented the full stateful item details sidebar layout with physical stock/warehouse locations tab to mirror purchase order module parity.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **HSN Popover Offset Adjustment**: Repositioned CompositedTransformFollower horizontally with Offset(-20, 2) and adjusted internal arrow caret padding left: 30 to avoid screen clipping.
  - **Rate Column Recent Transactions Link**: Integrated _showRecentTransactions check under item rate field to display a "Recent Transactions" button triggering item details sidebar.
  - **Item Details Sidebar Overlay**: Declared overlay states and instantiated _ItemDetailsSidebar supporting details, warehouse stock location tables, and transaction histories.

Timestamp of Log Update: May 27, 2026 - 11:46 AM (IST)

## 14. Purchases Bills UI Parity and Dropdown Refinement (May 27, 2026)

### Summary
Harmonized the Purchases Bills creation item grid layout and dropdown parameters with purchase order parity. Removed the duplicate SKU/Type badge row in the selected item cell, standardized the clear row button color to black, and filtered active price lists to match the purchase transaction type.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **SKU/Type Badges Removal**: Removed the secondary item code/type Row under _richItemDisplay to declutter the item grid cell.
  - **Clear Button Color Adjustment**: Updated the Row deletion cross button icon color to Colors.black to match the visual standard of the ERP.
  - **Pricelist Transaction Type Filtering**: Filtered active price lists in the rate cell PopupMenuButton to only display entries with transactionType == 'purchase'.

Timestamp of Log Update: May 27, 2026 - 12:15 PM (IST)

## 15. Purchases Bills Rate Column, HSN Popover Tip, Customer Dropdown, and UI Refinements (May 27, 2026)

### Summary
Harmonized the Purchases Bills creation page with multiple UI refinements: enabled price list/recent transactions/stock info by default in the rate column, removed the HSN popover arrow tip, simplified customer dropdown to show only display name without bold text, updated item table textbox outlines to match Subject field border thickness, and right-aligned quantity values.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Show Flags Initialization**: Changed _showStockInfo, _showRecentTransactions, _showPriceList from false to true to match PO create parity.
  - **HSN Popover Tip Removal**: Removed the _TrianglePainter arrow caret from _HSNCodeEditPopover build method.
  - **Customer Dropdown Simplification**: Removed customer code sub-line and changed fontWeight from w600 to w400 for the customer display name.
  - **InCellWrapper Border Standardization**: Updated to always show a visible border with borderRadius: 4, matching Subject field outline style (thin _fieldBorder default, blue on hover/focus).
  - **Quantity Text Alignment**: Added textAlign parameter to _buildCompactNumberField and set TextAlign.right for the quantity cell.

Timestamp of Log Update: May 27, 2026 - 12:35 PM (IST)

## 16. Purchases Bills Textbox Outline Fix, ITC Eligibility Popover, and Price List Dropdown (May 27, 2026)

### Summary
Fixed the double textbox border visual bug in in-cell inputs by making inner TextField outlines transparent. Added an "Eligible for ITC" clickable text button to the tax cell displaying an overlay popover with input tax credit eligibility options. Implemented a Price List dropdown to the right of the transaction-level Discount field above the table.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Inner Outlines Transparency**: Configured all state specific borders (focusedBorder, enabledBorder, errorBorder, disabledBorder) to InputBorder.none in compact text fields to eliminate the double-outline thickness visual bug.
  - **ITC Eligibility Button and Popover**: Added itcEligibility string state and itcLayerLink to _BillLineItemRow. Implemented CompositedTransformTarget in _taxCell to show "Eligible for ITC" button inline with edit icon, opening a custom white _ItcEligibilityPopover containing Radio button selection options ('Eligible for ITC', 'Ineligible - As per Section 17 (5)', 'Ineligible - Others') and an OK action button.
  - **Price List Dropdown Layout**: Watched activePriceListsProvider and placed the Price List dropdown next to the Discount field above the items table, allowing bulk price recalculation for items in the invoice upon selection.

Timestamp of Log Update: May 27, 2026 - 12:50 PM (IST)


## 17. Purchases Bills Responsive Table Scroll, Wrap, and Focus Border Alignment (May 27, 2026)

### Summary
Enhanced the Purchases Bills creation screen (`purchases_bills_create.dart`) by wrapping the items table in a horizontal scrollable view and setting a dynamically scaling width. Replaced the Discount/Price List horizontal row with a responsive wrap. Wrapped the ITC text inside an Expanded widget to prevent horizontal layout overflow. Standardized focused and hovered cell outline highlights to use the standard active blue shade (`_linkBlue` / `Color(0xFF3B82F6)`), and set cell dimensions to 32px height to match dropdown inputs.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - **Horizontal Scrollable Item Table**: Wrapped `_buildItemTable` in an `Align`, `ConstrainedBox`, `SingleChildScrollView(scrollDirection: Axis.horizontal)`, and `SizedBox` with a width constraint of `1365.0` (when 'At Line Item Level' discount is selected) and `1190.0` otherwise. This prevents columns from squeezing when the discount column is added.
  - **Responsive Discount/Price List Wrap**: Replaced the horizontal `Row` with a `Wrap` component. Nested Price List label and field in an inline `Row` inside the wrap to flow to the next line on narrow screens without overflow.
  - **ITC Bounding and Ellipsis**: Wrapped the ITC eligibility text button inside `_taxCell` with `Expanded` inside the Row, enabling auto-ellipsis wrapping for long selection values.
  - **Standardized Border Color and Sizing**: Changed `InCellWrapper` and custom cells (`_accountCell`, `_taxCell`, `_customerCell`, and `_discountCell` toggle) hover/focus border highlights to use `_linkBlue` (`Color(0xFF3B82F6)`). Added `height` parameter to `InCellWrapper` (constrained to `32` for text/date inputs, batch dropdown, and discount type selector) and adjusted `contentPadding` vertical value to `8.0` to keep input texts vertically centered without clipping.

Timestamp of Log Update: May 27, 2026 - 1:55 PM (IST)


## 18. Sales Invoice Validation, FOC Calculations, and List Auto-Reload (May 27, 2026)

### Summary
Enhanced the Sales Invoice creation screen (`sales_invoice_create.dart`) to support mandatory HSN code and Account selection validation without adding any labels/colors to the UI. If mandatory fields are empty or if there is a mismatch between the manually entered quantity and the sum of selected batch quantity + FOC, the "Save and Send" split button disables itself automatically. Also displayed FOC breakdowns and total counts in the item table. Finally, ensured the list screen (`sales_invoice_list.dart`) auto-reloads new/updated invoices on redirect by invalidating `salesInvoicesProvider`.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`:
  - **Save & Send Button Disabling**: Implemented `_isSaveAndSendEnabled` getter which checks validation criteria (Customer selected, Salesperson selected, HSN code present on each row, Account ID present on each row, Quantity and Rate > 0, and batch quantities + FOC sum matches quantity textbox exactly). Disabled Split Button and dropdown inside footer by making `onTap: null` and changing color states.
  - **HSN & Account Validation Toast**: Added validations inside `_saveSalesInvoice` to show a toast message error for HSN code and Account if they are missing when attempting to save/update.
  - **FOC & Quantity Updates**: Updated `_showSelectBatchesDialog` result callback to populate `quantityCtrl.text` with `qtyOut + foc` sum if FOC > 0.
  - **Breakdown and Quantity Display**: Rendered a `Text` widget under the quantity textbox in the table if FOC > 0 to display `(sum of qtyOut) pcs + (sum of foc) foc`. Also updated the blue clickable link text to display `qtyOut + foc` sum before `pcs`.
  - **Auto-reload on redirect**: Call `ref.invalidate(salesInvoicesProvider)` inside `_saveSalesInvoice` right before `context.go('/sales/invoices')` to clear the list cache and load fresh data.

Timestamp of Log Update: May 27, 2026 - 3:15 PM (IST)

## 19. Purchases Vendors Dialog Layout Shifts (May 27, 2026)

### Summary
Enhanced the visual layout of the "New Vendor" dialog and page view (`purchases_vendors_vendor_create.dart`) by adding left padding to shift the primary information fields and non-table tab contents slightly to the right, improving the user interface aesthetics while keeping the wide "Contact Persons" table layout completely undisturbed.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/vendors/presentation/pages/purchases_vendors_vendor_create.dart`:
  - **Primary Info Alignment**: Wrapped `_buildPrimaryInfo()` call with `Padding(padding: const EdgeInsets.only(left: 32.0), ...)` in both the scrollable dialog and standard layouts.
  - **Tab Content Alignment**: Refactored `_buildTabContent` to assign non-table tab widgets to a local `Widget content` variable and wrap it in `Padding(padding: const EdgeInsets.only(left: 32.0), ...)` before returning. Case 3 (`_buildContactPersons()`) is explicitly exempted from this padding to keep its wide grid layout intact.

Timestamp of Log Update: May 27, 2026 - 5:25 PM (IST)



## 20. Purchases Bills Warehouse Dropdown, Invoice Total, Price List Alignment, and Hover Triggers (May 27, 2026)

### Summary
Enhanced the Purchases Bills creation screen (`purchases_bills_create.dart`) to fetch warehouse listings from database-backed `warehousesProvider`, added a numeric-only "Invoice Total" field inline with Bill Date, aligned the "Price List" dropdown inline with the Discount field matching the Payment Terms layout, and implemented MouseRegion hover triggers to show/hide cell-level item actions and row-level delete/menu buttons only when hovering over rows/cells.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - **DB-backed Warehouse Dropdown**: Integrated `ref.watch(warehousesProvider)` inside `_buildWarehouseDropdown` to dynamically fetch and display warehouse names from `warehouses` master database table instead of hardcoded strings.
  - **Invoice Total Input**: Added `_invoiceTotalCtrl` controller. Increased the Bill Date container width to `924` and placed a numeric-only "Invoice Total" text field to the right of the Bill Date field.
  - **Price List Alignment**: Moved Price List dropdown inline on the right side of the Discount row with standard label (180px), gap (32px), field (396px), gap (32px), label, gap (12px), dropdown (180px) to mirror the Due Date/Payment Terms layout.
  - **Row & Cell Hover Triggers**: Wrapped item cells and action cells inside `StatefulBuilder` and `MouseRegion` to dynamically toggle action indicators (such as the 3-dots menu button and X clear/delete button) only under active mouse hover.
  - **Warning Cleanups**: Relocated `_isItemHovered` and `_isActionHovered` hover state variables outside of the local `builder` closures to resolve `dead_code` compiler warnings.

Timestamp of Log Update: May 27, 2026 - 5:45 PM (IST)

## 21. Purchases Bills Dynamic Lookups & Premium Discount Alignments (May 27, 2026)

### Summary
Refactored state list and GST treatments on the Purchases Bills creation screen to load dynamically from lookups database API. Standardized the Discount dropdown using premium lookup UI and added a dynamic discount account selection dropdown next to it when line-item discount is selected. Added a dynamic fallback for place of supply based on organisation profile and restored corrupted methods in LookupsApiService.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/items/items/services/lookups_api_service.dart:
  - **Restore Corrupted API Calls**: Restored getCountries, getStates, and getManufacturers lookups that were previously deleted/corrupted.
  - **GST Treatments API**: Added getGstTreatments() lookup method to fetch GST treatments from the database-backed endpoint.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Dynamic State & GST Treatments**: Replaced hardcoded arrays _statesList and _gstTreatments with empty state lists loaded dynamically via new _loadLookups() calling getStates('IN') and getGstTreatments().
  - **Premium Discount Selection**: Refactored _buildDiscountDropdown to use _buildStandardLookupRow and support showing a vertical divider and a discount account selector (width 191px) next to it if "At Line Item Level" is active (fitting exactly the 396px row limit).
  - **Dynamic Warehouse Loading**: Refactored _buildWarehouseDropdown to dynamically resolve the default warehouse from warehousesProvider instead of a hardcoded default string.
  - **Supply State Dynamic Defaults**: Added dynamic defaults fetching organization profile states and GST treatments as default fallbacks when vendor data is empty.

Timestamp of Log Update: May 27, 2026 - 6:00 PM (IST)


## 22. Purchases Bills Vendor dropdown, Pricelist selection, and Invoice Total alignment (May 27, 2026)

### Summary
Aligned the Purchases Bills creation page (`purchases_bills_create.dart`) vendor, new vendor dialog, pricelist selection, and invoice total textbox layouts and behavior with the purchase order module's features. Enforced strict vertical alignment constraints for right-side fields and numeric-only input validation.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - **Vendor Dropdown Refactoring**: Migrated the custom gesture-based vendor overlay selector to the standardized `FormDropdown<Vendor>` component.
  - **New Vendor Dialog Parity**: Integrated `PurchasesVendorsVendorCreateScreen(isDialog: true)` inside a standard `showDialog` configured with `maxWidth: 1300` insets.
  - **Pricelist Dropdown Placement**: Added a "Price List" dropdown on the right side of the Discount row, showing all purchase-related pricelists and applying chosen pricelist rates to all item rows.
  - **Invoice Total textbox**: Added a numeric-only "Invoice Total" field on the right side of the Bill Date field, using a numeric-only input formatter.
  - **Vertical Alignment Grid**: Wrapped "Invoice Total", "Payment Terms", and "Price List" labels in a `SizedBox(width: 110)` parent to align the respective right-side inputs perfectly.

Timestamp of Log Update: May 27, 2026 - 10:15 PM (IST)

## 23. Purchases Bills UI Polish, Hover Trigger Actions, and Item Details Sidebar (May 27, 2026)

### Summary
Fixed the form layout overflow issue on standard screen sizes. Wrapped line item rows in mouse hover regions to show/hide right-side actions. Right-aligned the quantity column field and defaulted its value to 0 as hint text. Removed redundant SKU details and goods badges from underneath selected item names, adding circular black clear buttons and more-action buttons next to them. Added the "Recent Transactions" trigger link and integrated the full-screen Item Details sidebar overlay.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - **Layout Overflow Fix**: Reduced the first input field container width from `396` to `370` and gap size from `32` to `24` in the Bill Date, Due Date, and Discount form rows to cleanly fit the 720px horizontal child constraint.
  - **Hover-Triggered Actions**: Declared `_hoveredRowIndex` and wrapped the main row list item in a `MouseRegion` to show the 3-dots and delete buttons in the actions cell only when hovering over that specific row.
  - **Quantity Cell Polish**: Updated `quantityCtrl` inside `_BillLineItemRow` to start empty. Added alignment (`TextAlign.right`) and hint text (`0`) options to `_buildCompactNumberField` helper.
  - **Selected Item Clear & Popup Actions**: Added 3-dots actions popup and black clear circular `(x)` button next to item name inside `_richItemDisplay`. Removed HSN/SKU details and type badges underneath the item name.
  - **Rate Column Recent Transactions Link**: Added clickable "Recent Transactions" text link under the rate input field when `_showRecentTransactions` is true.
  - **Item Details Sidebar**: Defined `_showItemDetailsSidebar` overlay presentation, `_ItemDetailsSidebar` consumer stateful widget, `_MenuHoverItem` custom popover list item, and `_buildIconAction` circular button helper at the bottom of the file.

Timestamp of Log Update: May 27, 2026 - 10:35 PM (IST)


## 24. Purchases Bills Sidebar Relocation Bugfix (May 27, 2026)

### Summary
Fixed a scoping compilation issue where the _showItemDetailsSidebar method was mistakenly appended to the end of _BulkAddModalState instead of its correct parent class _PurchasesBillCreateScreenState. Relocated the method to the correct scope, resolving all 12 compilation errors across the frontend module.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Scope Relocation**: Relocated _showItemDetailsSidebar method from the end of _BulkAddModalState back inside the main _PurchasesBillCreateScreenState class.

Timestamp of Log Update: May 27, 2026 - 10:40 PM (IST)

## 25. Purchases Bills Key Assignment Bugfix (May 27, 2026)

### Summary
Fixed a runtime crash where the line item table threw a "Every item of ReorderableListView must have a key" assertion error on load. Moved the key: ValueKey(row) assignment to the outermost MouseRegion widget returned by _buildLineItemRow (which acts as the direct child builder of ReorderableListView.builder), satisfying Flutter's strict key presence check.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Key Assignment Fix**: Shifted the key: ValueKey(row) parameter from the nested Column to the parent MouseRegion returned by _buildLineItemRow.

Timestamp of Log Update: May 27, 2026 - 10:45 PM (IST)

## 26. Purchases Bills Layout and Dropdown Improvements (May 27, 2026)

### Summary
Fixed the form layout overflow issues on the Purchases Bills creation screen (purchases_bills_create.dart). Standardized the Bill Date, Due Date, and Discount left-hand inputs to 300px width. Replaced static gaps with Spacer widgets to push Invoice Total, Payment Terms, and Price List fields cleanly to the right. Removed the redundant vertical line next to the drag handle in the line item row, and offset the rate cell pricelist popup menu to render below the dropdown box instead of overlapping it.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Left Field Width Standardizing**: Resized the first column container widths from 370px to 300px in the Bill Date, Due Date, and Discount rows to align with Bill# and Order Number fields.
  - **Dynamic Spacer Alignment**: Substituted the fixed 24px column gaps with Spacer() widgets to dynamically push the right-hand widgets (Invoice Total, Payment Terms, and Price List) to the right edge.
  - **Discount Dropdown Adjustments**: Resized the default dropdown width in _buildDiscountDropdown() from 396px to 300px (when At Transaction Level), and reduced inner dropdown widths from 180px and 191px to 130px and 145px (when At Line Item Level) to stay within the 300px limit.
  - **Redundant Divider Removal**: Removed _vLine() call next to the drag handle inside _buildLineItemRow().
  - **Pricelist Dropdown Offset**: Added offset: const Offset(0, 34) to the PopupMenuButton in _rateCell() to show the pricelist dropdown list below the rate field's dropdown box.

Timestamp of Log Update: May 27, 2026 - 11:00 PM (IST)

## 27. Purchases Bills Date Width Standardization (May 27, 2026)

### Summary
Aligned the Bill Date input field width to match the standard 300px constraint of the Order Number, Bill#, and Due Date input fields on the Purchases Bills creation page (purchases_bills_create.dart).

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Bill Date Width Alignment**: Changed the SizedBox width wrapping _zDateField in the Bill Date row from 400px to 300px.

Timestamp of Log Update: May 27, 2026 - 11:05 PM (IST)

## 27. Purchases Bills Validations, Warehouse ID, and Batch Selection UI Porting (May 29, 2026)

### Summary
Implemented robust popup validation checks during Purchases Bills saving, populated the missing warehouseId property in database records, and ported the premium batch selection UI logic from the Sales Invoices quantity column to the Purchases Bills quantity column.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Save validations popup dialog**: Added the state-private _showValidationError method to display a clean, white-themed dialog for validation errors. Added validation triggers at the start of _saveBill checking for missing vendor selection, empty bill number, empty bill date, empty items table, and unselected batches.
  - **Warehouse ID resolution**: Resolved the selected warehouse object from the database-backed warehousesProvider using the _warehouse name, and mapped warehouseId and warehouseName to the PurchasesBill instance creation.
  - **Batch selection UI and empty qty checks**: Hid the "Select Batch" textbutton if the quantity field is empty or zero. Ported the "pcs + foc" quantity summary and the blue, underlined, clickable batch details link text below the warehouse name matching the Sales Invoices layout.

Timestamp of Log Update: May 29, 2026 - 10:15 AM (IST)

## 28. Top-Aligned Validation Toast, HSN/Account Verification, Batch Quantity Save Restriction (May 29, 2026)

### Summary
Transitioned validation notifications to top-aligned ZerpaiToast messages. Added strict line-level checks for HSN code and Account selection prior to saving. Conditionally disabled "Save as Open" button if quantity textbox inputs mismatch total selected batch quantities.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Top-aligned validation notifications**: Replaced the custom _showValidationError dialog with ZerpaiToast.error(context, message).
  - **HSN code & Account validations**: Added checks in _saveBill to require hsnCode and accountId to be selected for all items before saving.
  - **Disable Save as Open on batch mismatch**: Added the _isSaveAsOpenEnabled getter to verify that the entered quantity matches the total batch quantities (including FOC). Styled and disabled the "Save as Open" button when mismatch occurs.

Timestamp of Log Update: May 29, 2026 - 10:45 AM (IST)

## 29. Bill Attachments Upload UI and Backend Database Table (May 29, 2026)

### Summary
Implemented a dashed-outline upload file button, attachment badge, and attachment overlay list within the Purchases Bills page matching the Purchase Orders design. Integrated R2 cloud storage uploading and saved attachment records into the public.bill_attachments table in Supabase. Added the billAttachments Drizzle schema mapping and SQL script.

### Detailed Engineering Changes

#### Database / Backend
- backend/sql/2026-05-29_bill_attachments.sql:
  - **bill_attachments schema**: Created SQL script defining the table structure and its audit triggers.
- backend/src/db/schema.ts:
  - **billAttachments definition**: Added the Drizzle ORM mapping for bill_attachments.

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Upload outline & badge logic**: Ported _attachedFiles, _uploadOverlay, and _attachmentListOverlay logic from POs page. Installed file picker and base64 upload integration.
  - **Save attachments task**: Configured _saveBill to invoke _saveAttachments(createdBill.id) on successful database insertion.

Timestamp of Log Update: May 29, 2026 - 11:25 AM (IST)

## 27. Purchases Bills Warehouse Column, Bill Number, and Batch Saving (May 29, 2026)

### Summary
Addressed hardcoded location values on the bills list table by renaming the column to WAREHOUSE and displaying the resolved warehouse name. Mapped the Bill# form field input to the database bill_number column on invoice creation. Enabled saving of nested batch allocations chosen from the select batch popup to the postgres bill_item_batches table.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart:
  - Renamed the LOCATION column header to WAREHOUSE and bound it to display the real database `warehouseName` value.
- lib/modules/purchases/bills/models/purchases_bills_bill_model.dart:
  - Added the missing `billNumber` field inside the `toJson()` serialization method.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - Passed `batches` line item data in the `toModel()` mapper.
- lib/shared/widgets/dialogs/inventory_bin_batch_foc.dart:
  - Added support for tracking `batchId`, `layerId`, and `binId` in the shared batches selection dialog.
  - Stored raw warehouse bins to resolve bin IDs by code and passed them into mapped batch details.

#### Backend Files
-  ackend/src/modules/purchases/bills/services/bills.service.ts:
  - Added a robust date parsing utility to process user-inputted batch dates.
  - Resolved typed batch numbers to  atch_master dynamically (creating them if non-existent).
  - Saved nested line item batch details to the existing  ill_item_batches table.

Timestamp of Log Update: May 29, 2026 - 1:40 PM (IST)

## 30. Purchases Bills & Purchase Orders Location column, dynamic warehouse display, search bar removal, and detailed batch mapping (May 29, 2026)

### Summary
Addressed the hardcoded location values on both Purchases Bills and Purchase Orders listing/detail panels by renaming the column to WAREHOUSE and displaying the dynamically resolved `warehouseName`. Hid the global search bar on these screens. Fixed detail panel header font sizes to match picklists styling exactly. Integrated full batch detail fields resolution and mapping into Supabase `bill_item_batches` table during bill creation.

### Detailed Engineering Changes

#### Frontend Files
- `lib/app/layout/zerpai_navbar.dart`:
  - Hid global search bar and recent items history menu on Bills and Purchase Orders list screens using route-based conditional checks.
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart`:
  - Renamed the LOCATION column to WAREHOUSE.
  - Replaced hardcoded 'ZABNIX PRIVATE LIMITED' fallbacks in table rows and addresses with real database-backed `bill.warehouseName`.
  - Adjusted the split-screen detail view header title font size to 18 (bold) to match picklists style.
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart`:
  - Renamed the LOCATION column to WAREHOUSE and resolved dynamic warehouse names in the items table.
  - Replaced all hardcoded 'ZABNIX PRIVATE LIMITED' references in splitting views, addresses, and print PDFs with `order.warehouseName`.
  - Adjusted split-view header title font size to 18 (bold).
- `lib/shared/widgets/dialogs/inventory_bin_batch_foc.dart`:
  - Extended the shared `PicklistSelectBatchesDialog` to track and return resolved `batchId` and `binId` (by mapping code strings to bin list objects dynamically).
- `lib/modules/purchases/bills/models/purchases_bills_bill_model.dart`:
  - Mapped `billNumber` inside `toJson()` serialization method, matching backend API DTO validation keys.
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - Mapped detailed line-item batch data (mrp, foc, rate, binId, warehouseId, and parsed ISO dates) in `toModel()`.
  - Resolved and passed the selected `warehouseId` on line items conversion in `_saveBill`.

#### Backend Files
- `backend/src/modules/purchases/bills/services/bills.service.ts`:
  - Expanded nested item batches database mapping and insertion block to populate all database table columns (`layer_id`, `warehouse_id`, `bin_id`, `purchase_rate`, `foc_quantity`, `mrp`, `expiry_date`, `manufacture_date`, `manufacture_batch_no`, `is_direct_bill`) in the PostgreSQL `bill_item_batches` table.

Timestamp of Log Update: May 29, 2026 - 2:15 PM (IST)

## 31. Purchases Bills Details Pane Visual Standardization and Tax Autoloading (May 29, 2026)

### Summary
Aligned the Purchases Bills list-details overview pane vendor address presentation format and invoice totals/metadata with Zoho high-density design. Implemented default tax rate autoloading, unregistered business GST treatment constraints (readonly select box), and vendor selection tax synchronization.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/models/purchases_bills_bill_model.dart:
  - **Relational Field Alignment**: Added endorAddress and endorPhone properties to PurchasesBill model and parsed them dynamically from nested endor JSON data.
  - **Coalesced API Field Parsing**: Updated 0romJson key mappings to check both snake_case and camelCase parameters (e.g. sub_total/subtotal, grand_total/	otal, discount_total/discount_amount) to prevent API parsing mismatch which led to ?0.00 totals display.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart:
  - **Metadata Layout Restructuring**: Replaced vertical _meta cards with a clean Table layout, displaying BILL DATE, DUE DATE, PAYMENT TERMS, BALANCE DUE, and TOTAL in columns matching Zoho Standard.
  - **Address Formatting**: Formatted vendor address parts to display address lines (attention, street, place, city, state, country, zip, and phone) without prepending 'Phone: ' prefix.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Default Tax Autoloading**: Created helper _updateRowTaxForProduct and _updateAllRowTaxes to dynamically set product default tax rates when items are selected.
  - **GST Treatment Constraints**: Configured _taxCell dropdown to be readonly with a light grey background and no dropdown icon if vendor's GST treatment is Unregistered Business.
  - **Tap Trigger Listener**: Wired a GestureDetector around the cell CompositedTransformTarget to trigger _showTaxPopover when clicked.

Timestamp of Log Update: May 29, 2026 - 3:45 PM (IST)

## 32. Purchases Bills UI Refinements, Text Colors, and Tax Column Standardisation (May 29, 2026)

### Summary
Removed delivery warehouse and place of supply blocks from the bills detail overview pane, changed vendor name text color to always be black in the selection sidebar, resolved payment terms parsing by joining the payment_terms table in the backend service and supporting nested Map parsing on the frontend, and standardized unregistered vendor tax column behavior to stay a dropdown layout while remaining readonly.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart:
  - **Sidebar Vendor Name Color**: Changed color to always be AppTheme.textPrimary (black) instead of AppTheme.primaryBlue when selected.
  - **Metadata Blocks Removal**: Removed DELIVERY WAREHOUSE and PLACE OF SUPPLY address blocks from the right column of the detail overview pane.
- lib/modules/purchases/bills/models/purchases_bills_bill_model.dart:
  - **Payment Terms Parsing**: Refactored paymentTerms in 0romJson to dynamically check if json['payment_terms'] is a Map (resolving nested database join values like 	erm_name) or string.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Tax Dropdown Arrow Retention**: Restored Icons.arrow_drop_down visibility and the standard border in _taxCell when vendor is unregistered, ensuring it visually remains a dropdown box while keeping onTap: null (readonly).

#### Backend Files
- ackend/src/modules/purchases/bills/services/bills.service.ts:
  - **Payment Terms DB Join**: Added payment_terms:payment_terms(term_name) to Supabase queries in createBill, 0indAll, and 0indOne methods to return actual payment term values.

Timestamp of Log Update: May 29, 2026 - 4:10 PM (IST)

## 27. Purchases Bills List Selection, Keyboard Escape, Custom Hover & Payments Made Navigation (May 30, 2026)

### Summary
Enhanced the Purchases Bills module by restoring standard column headers when rows are selected, integrating an Escape key keyboard shortcut to clear selections, applying standard premium blue hover visual styling with white text to all menu lists, wiring print and high-fidelity PDF invoice generation/sharing endpoints, and implementing the new high-density "Record Bulk Payment" create page with GoRouter deep-linking.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart`:
  - **Dynamic Table Headers**: Removed the dynamic selection banner subheader from the top of the table; column headers always display normal field labels even when multiple rows are checked.
  - **Escape Shortcut to Clear Selection**: Configured FocusNode and wrapped ZerpaiLayout in a KeyboardListener mapping `LogicalKeyboardKey.escape` to clear all selected IDs from memory.
  - **Custom Hover Highlight**: Modified `_menuItemStyle` and `_viewMenuItemStyle` to dynamically render `Color(0xFF3B82F6)` background and `Colors.white` text on hover and focus states using `WidgetStateProperty.resolveWith`. Applied custom styles to detail menu actions, bulk menu dropdowns, and PDF/Print toolbar dropdown button list items.
  - **High-Fidelity PDF Document & Print Integration**: Integrated `Printing` and `Pdf/pw` delegates. Added `_generatePdfForBill()` helper producing structured A4 pages complete with logo headers, vendor details, billing/due dates, items tables, adjustment breakdowns, and custom notes, and wired it to print layout and share triggers.
  - **Bulk Payments Navigation**: Modified 'Record Bulk Payment' action inside `_handleBulkAction` to redirect to `/purchases/payments-made/create?billIds=...`.
- `lib/modules/purchases/payments_made/presentation/pages/purchases_payments_made_create_page.dart` [NEW]:
  - **Record Bulk Payment UI**: Created the premium page containing paid-through accounts, payment modes, total vendor calculation cards, expandable details, and interactive tables.
- `lib/app/routing/app_router.dart`:
  - **Route Mapping Integration**: Registered `PurchasesPaymentsMadeCreatePage` route under path `purchases/payments-made/create`, parsing `billIds` query parameters and mapping them to the screen widget.

Timestamp of Log Update: May 30, 2026 - 10:15 AM (IST)

## 27. Purchases Bills Edit Redirection, Soft Delete, and Hover Color Fixes (May 30, 2026)

### Summary
Implemented redirection logic for Purchases Bills edit actions, integrated the soft-delete `is_delete` flag across both database operations and frontend views, and resolved hovered text and icon color contrast issues within dropdown lists.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart`:
  - **Edit Button Redirection**: Configured the "Edit" action button in the bill detail toolbar to redirect using GoRouter to `/purchases/bills/create?editId=${bill.id}` instead of a relative push, ensuring the target page context is loaded cleanly.
  - **Soft Delete Integration**: Updated the "Delete" action handler to execute an update statement setting `is_delete = true` instead of performing a hard row deletion. Refactored local query filtering to only display bills with `is_delete` set to `false`.
  - **Bulk Action Send Emails Removal**: Removed the obsolete "Send Emails" option from the bulk action dropdown menu.
  - **Sort Menu Item Hover Styling**: Refactored the sort menu item button to use `trailingIcon` and a clean `Text` child, ensuring text and arrow icon colors inherit the white color highlight correctly when hovered.
- `lib/modules/sales/invoices/presentation/pages/sales_invoice_list.dart`:
  - **Sort Menu Item Hover Styling**: Refactored the sorting menu buttons to use `trailingIcon` and `Text` children for correct hover state color inheritance.
  - **Dropdown Menu Item Hover Styling**: Updated the custom `_menuItem` helper and PDF/Print MenuItemButtons to use standard `leadingIcon` and `Text` children, correcting color contrast to white-on-blue when hovered.

#### Backend Files
- `backend/src/modules/purchases/bills/services/bills.service.ts` (implied in schema and db operations):
  - **Create Bill Defaults**: Wired new bill insertions to store `is_delete: false` by default.

Timestamp of Log Update: May 30, 2026 - 12:00 PM (IST)

## 28. Purchases Bills Compiler Error Fixes (May 30, 2026)

### Summary
Fixed compile-time errors in `purchases_bills_create.dart` by adding missing imports and accessing the correct vendor list property in Riverpod notifier state.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - **Import Added**: Imported `purchases_bills_repository.dart` to define the missing `purchasesBillsRepositoryProvider`.
  - **Vendor List Property Access**: Changed `ref.read(vendorProvider).value` access to `ref.read(vendorProvider).vendors` to resolve `VendorState` type property compilation failure.

Timestamp of Log Update: May 30, 2026 - 12:05 PM (IST)

## 29. Handoff Integration & Type Safety Correction (May 30, 2026)

### Summary
Merged missing code snippets and updated outdated definitions from `handoff_2026-05-30` to resolve compile-time errors in vendor credits and customer search views.

### Detailed Engineering Changes

#### Frontend Files
- `lib/core/theme/app_theme.dart`:
  - **Color Token Integration**: Added `reportDropdownHeaderBg` color token (`Color(0xFFF5F6FA)`) to support visual styling in `purchases_vendor_credits_report.dart`.
- `lib/modules/sales/customers/providers/customers_provider.dart`:
  - **Canonical Import Fix**: Changed the import path of `sales_customer_model.dart` to target the canonical structure in `package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart`.
- `lib/shared/widgets/dialogs/advanced_customer_search_modal.dart`:
  - **Canonical Import Fix**: Added the canonical customer model import.
  - **Show Method Parameter**: Updated static `show(...)` signature to receive and pass the `customers` list payload.
  - **Dynamic Customer Map**: Replaced the static dummy customer list with a dynamic getter mapping `widget.customers` list.

**Backup Path**: `backups/refactor-batches/2026-05-30-handoff-merge/`
**Verifications**: Verified touched scopes pass analysis cleanly with `flutter analyze`.

Timestamp of Log Update: May 30, 2026 - 2:30 PM (IST)

## 30. Sales Order Stock Commitments Integration (June 1, 2026)

### Summary
Integrated inventory stock commitments creation and update flows for Sales Orders, mapping eligible goods details to `inventory_stock_commitments` database records upon save/update actions.

### Detailed Engineering Changes

#### Backend Files
- `backend/src/modules/sales/services/sales.service.ts`:
  - **resolveItemFields Enrichment**: Expanded product mapping queries to select `type` and `is_track_inventory` fields.
  - **createSalesOrder Commitment Insertion**: Filtered line items by `'goods'` type and tracking eligibility, inserting them into `inventory_stock_commitments` with transaction safety rollbacks on insertion failure.
  - **updateSalesOrder Commitment Sync**: Added deletion of existing commitments and insertion of updated commitments to keep records in sync.

**Verifications**: Ran production compilation successfully using `npm run build`.

Timestamp of Log Update: June 1, 2026 - 9:55 AM (IST)

## 31. Purchase Orders Warehouse Name Fetching (June 1, 2026)

### Summary
Resolved an issue where the warehouse name was not displayed (showing as `-` instead) in the Purchase Orders list and detail views. Modified the NestJS backend to select the related warehouse name via PostgREST join.

### Detailed Engineering Changes

#### Backend Files
- `backend/src/modules/purchases/purchase-orders/services/purchase-orders.service.ts`:
  - **findAll Warehouse Fetching**: Updated the PostgREST `select` query to join the `warehouses` table on `warehouse_id` and alias it as `warehouse(name)`, ensuring that `warehouseName` gets populated correctly in the JSON list response.
  - **findOne Warehouse Fetching**: Added the `warehouse:warehouses!warehouse_id(name)` relation join to the single purchase order retrieval query to support the detail view and PDF export generation.

**Verifications**: Verified compilation successfully with `npm run build` in the `backend/` directory.

Timestamp of Log Update: June 1, 2026 - 10:15 AM (IST)

## 32. Purchase Orders Warehouse ID Fallback Validation (June 1, 2026)

### Summary
Resolved a database constraint violation error where creating or updating a Purchase Order without an explicit warehouse ID failed because the warehouse_id column is defined as NOT NULL in the database. Added automatic backend fallback logic to resolve a default warehouse ID for the tenant if omitted by the client.

### Detailed Engineering Changes

#### Backend Files
- backend/src/modules/purchases/purchase-orders/services/purchase-orders.service.ts:
  - create Fallback Logic: Added automatic resolution of warehouse_id. If omitted, it falls back to delivery_warehouse_id (if delivery type is warehouse), or resolves the first active warehouse from the warehouses table for the tenant.
  - update Fallback Logic: Added identical fallback logic during updates if warehouse_id is updated to a null/falsy value.

**Verifications**: Verified compilation successfully with npm run build in the backend/ directory.

Timestamp of Log Update: June 1, 2026 - 10:20 AM (IST)

## 33. Sales Order Address Integration & Column Customization with Pinning (June 1, 2026)

### Summary
Enhanced Sales Order address display and editing, vendor address update notification, and implemented customizable column settings with pinning support in the Sales Order list screen.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - **UUID Address Resolution**: Resolved state and country UUID values to human-readable names inside customer billing/shipping display containers.
  - **Inline Customer Address Editing**: Pre-populated country/state fields in _AddressDialogState when loading and calling updateCustomer notifier with mapped database keys (street2 to 'place'), showing ZerpaiToast success/error alerts.
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart:
  - **Vendor Address Update Toasts**: Wrapped the vendor address update call in a try-catch block to display appropriate success or failure ZerpaiToast notifications.
- lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart:
  - **Extended Column Configuration**: Added isPinned and orderIndex fields to the local _SalesOrderColumnConfig class with JSON serialization methods (toJson/fromJson).
  - **Settings Persistence**: Wired _loadColumnSettings and _saveColumnSettings to save/load column configurations to/from SharedPreferences under so_table_columns_config.
  - **Interactive Pinning Dialog**: Added a pin toggle button next to column list items in the customization dialog, sorting pinned columns first.
  - **Ordered Table Column Rendering**: Sorted visible columns based on isPinned and orderIndex in the list view, ensuring correct table header and cell layout rendering.

Timestamp of Log Update: June 1, 2026 - 11:20 AM (IST)

## 34. Sorting Options & Static Column Headers (June 1, 2026)

### Summary
Updated "Sort by" menu options in both Sales Order and Purchase Order list screens to match visual mockups, set default sorting to "Created Time" descending on first load, and made Sales Order column headers static (non-sortable by click).

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart`:
  - **Static Column Headers**: Replaced sortable interactive header widgets inside `_buildHeaderForColumn` with static text labels (removing arrow icons, selection blue color, and onTap gestures).
  - **Default Sort**: Changed initial sorting fields to default to `createdTime` descending.
  - **Sort Menu Options Alignment**: Configured toolbar and sidebar submenu Sort by items to exactly list: Sales Order#, Date, Customer Name, Amount, Created Time, Last Modified Time, Expected Shipment Date.
  - **Unused Code Cleanup**: Removed unused `_sortFieldForColumn` element declaration.
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart`:
  - **Default Sort**: Configured initial sorting fields to default to `'created_at'` descending.
  - **Custom Sort by Actions**: Updated `_getSortedList` logic to support sorting lists by `delivery_date` (expectedDeliveryDate), `created_at` (createdAt), and `updated_at` (updatedAt).
  - **Sort Menu Options Alignment**: Configured toolbar and sidebar submenu Sort by items to exactly list: Purchase Order#, Date, Vendor Name, Amount, Delivery Date, Created Time, Last Modified Time.

**Verifications**: Verified compilation successfully with `flutter analyze` on modified scopes.

Timestamp of Log Update: June 1, 2026 - 2:55 PM (IST)


## 29. Default Sort Alignment, Column Customizer Conversions, and Lock Configurations (June 1, 2026)

### Summary
Aligned default sort orders to date descending across 8 list modules, converted custom column customization dialogues to the shared ColumnCustomizerDialog reusable widget, and locked critical columns from being customized/removed.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/inventory/packages/presentation/pages/inventory_packages_list.dart:
  - Defaulted sort provider to sort by Package Date descending.
  - Locked package_date, package#, and sales_order# in initial configurations.
  - Hooked up _buildMoreMenuOptions to dynamic consumer state to watch and toggle the active sort.
- lib/modules/inventory/picklists/presentation/pages/inventory_picklists_list.dart:
  - Added picklistSortProvider to maintain date-descending sort by default.
  - Enabled picklists list sorting inside _buildVirtualizedTable.
  - Hooked up more menu options to watch and toggle active sorting state.
  - Locked picklist# column in initial configurations.
- lib/modules/inventory/shipments/presentation/pages/inventory_shipments_list.dart:
  - Converted the custom inline AlertDialog to the shared ColumnCustomizerDialog reusable widget.
  - Set default sorting to shipment date descending.
  - Added local _allColumns model management and SharedPreferences state sync.
  - Locked date, shipment_number, sales_order#, and package# columns.
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart:
  - Changed default sorting field from created_at to order_date descending.
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_list.dart:
  - Changed default sorting field from created_time to date descending.
- lib/modules/sales/invoices/presentation/pages/sales_invoice_list.dart:
  - Changed default sorting field from invoiceNumber (ascending) to date descending.
- lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart:
  - Changed default sorting field from createdTime to date descending.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart:
  - Locked DATE, BILL#, VENDOR NAME, STATUS, and AMOUNT columns.
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_list.dart:
  - Locked DATE, PURCHASE RECEIVE#, VENDOR NAME, and STATUS columns.
  - Set sort menu default direction to descending when switching fields.

Timestamp of Log Update: June 1, 2026 - 3:45 PM (IST)

## 30. FEFO Bin & Batch Expiry Recommendations in Picklist Creation (June 1, 2026)

### Summary
Implemented a dynamic FEFO (First Expired, First Out) bin and batch recommendation system for the picklist creation page to show picker-optimized bin/batch selections and reduce inventory waste due to batch expiration.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/inventory/picklists/presentation/pages/inventory_picklists_create.dart:
  - **Dynamic Expiry Recommendation**: Introduced inExpiryRecommendationProvider which queries the atch_stock_layers database table to retrieve batch-level stocks, filters available balance, maps references client-side using existing cached providers (insLookupProvider, atchLookupProvider), and sorts them by expiry date ascending.
  - **FefoBinRecommendationCell Widget**: Implemented a reusable private consumer cell widget that dynamically watches the expiry recommendation provider, filters out bins where available batch stock is less than the item's ordered quantity, formats the outputs as BinCode (BatchNo: Qty), and presents multiple options via a hover tooltip using the custom _BinHoverBox overlay.
  - **Table Layout Integrations**: Replaced the static item preferredBin display in the items selection table (_buildItemsTable) and all three grouping layouts of the selected items table (_buildTableNoGrouping, _buildTableByItem, and _buildTableBySalesOrder) with the new FEFO recommendation cell.
  - **Supabase Flutter Import**: Imported package:supabase_flutter/supabase_flutter.dart to support query execution.

Timestamp of Log Update: June 1, 2026 - 4:25 PM (IST)

## 31. FEFO Preferred Bin Suggestion in Picklist Creation (June 1, 2026)

### Summary
Implemented a dynamic FEFO (First Expired, First Out) batch/bin suggestion logic in the preferred bin column of the picklist creation item selection table. The suggestion automatically queries active product batches sorted by expiry date ascending, aggregates warehouse bin stock levels from batch stock layers, filters out bins with insufficient available quantities (< ordered quantity), formats qualifying bins as \BinCode (Qty)\, and updates lazily in all table views (No Grouping, By Item, By Sales Orders).

### Detailed Engineering Changes

#### Frontend Files
- \lib/modules/inventory/picklists/presentation/pages/inventory_picklists_create.dart\:
  - **Dynamic Bin Resolution**: Added state maps \_resolvedPreferredBins\ and \_loadingPreferredBins\ to cache suggestions dynamically per row key.
  - **FEFO Database Query**: Implemented \_fetchPreferredBinForProduct\ to perform asynchronous queries on \atch_master\ (ordering by \expiry_date\ ascending) and \atch_stock_layers\ to check available stock (\qty - reserved_qty\) against the ordered quantity of the product.
  - **Dropdown State Refresh**: Updated the warehouse selection onChanged callback to clear the cached preferred bins when the selected warehouse changes.
  - **Table View Lazy-Load Integration**: Integrated lazy-loading and state rendering into \_buildTableNoGrouping\, \_buildTableByItem\, and \_buildTableBySalesOrder\ to display the dynamic suggestion string seamlessly.

Timestamp of Log Update: June 1, 2026 - 4:25 PM (IST)

## 35. FEFO Preferred Bins in Add Items Dialog & Dynamic Batch Sizing (June 1, 2026)

### Summary
Aligned the First Expired, First Out (FEFO) preferred bin suggestions format to "BinCode - Qty" (e.g. `Bin A - 50`) across both the main selected items list and the "Add Items" popup dialog. Refactored the batch details greenbox card layout in the Purchase Receives create screen to dynamically size horizontally, fully displaying long batch numbers without truncation.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/inventory/picklists/presentation/pages/inventory_picklists_create.dart:
  - **Preferred Bin Formatting Alignment**: Changed formatting from `BinCode (Qty)` to `BinCode - Qty` (e.g., `Bin A - 50`) in the main table layout views and the popup table.
  - **Add Items Dialog FEFO Integration**: Implemented state caching Maps (`_resolvedPreferredBins` and `_loadingPreferredBins`) and dynamic fetch logic (`_fetchPreferredBinForProduct`) inside _AddItemsDialogContentState. Integrated lazy-loading and dynamic display of suggestions inside the Add Items dialog items list table.
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - **Dynamic Batch Card Sizing**: Substituted the hardcoded `width: 94` constraint on the green batch detail cards with `constraints: const BoxConstraints(minWidth: 94)`, allowing horizontal size expansion based on child text length.
  - **Batch Text Truncation Removal**: Refactored `_batchText` to remove `maxLines: 1` and `overflow: TextOverflow.ellipsis` constraints, allowing the card to render the full length of the batch number inside horizontal scrolling containers.

**Verifications**: Verified compilation successfully with 0lutter analyze on modified scopes.

Timestamp of Log Update: June 1, 2026 - 5:25 PM (IST)

## 36. Precise Batch Box Width Tracking & Bin Dropdown Heights (June 1, 2026)

### Summary
Enhanced QUANTITY TO RECEIVE column auto-scaling in the Purchase Receives create screen using dynamic TextPainter text measurement of batch card lines to fully display greenbox batch details without clipping. Resized the row bin dropdown box heights in both manual and PO items table layouts from 44px to 32px to match visual standards.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - **Dynamic Card Sizing Helper**: Introduced _measureBatchLineWidth paint-width estimator and _batchCardWidth card size calculator.
  - **Auto-Scaling Column Width**: Replaced static width clamp configurations in _dynamicQtyToReceiveColumnWidth() with dynamic measurement aggregation of active batch cards to guarantee that the column cell has sufficient width to fully show the greenboxes.
  - **Bin Dropdown Box Sizing**: Changed height constraint from 44 to 32 in manual and PO row wrapping SizedBox widgets, and set FormDropdown height parameter to 32.

**Verifications**: Verified compilation successfully with 0lutter analyze on modified scopes.

Timestamp of Log Update: June 1, 2026 - 6:00 PM (IST)
  - **Explicit Measured Container Width**: Updated green box batch cards inside _buildItemRow and _buildManualRow to use the explicit dynamically-measured TextPainter width (width: _batchCardWidth(batch)) to completely prevent any text clipping/truncating inside card borders.
  - **Dynamic Card Sizing and Max Width Clamp**: Configured _batchCardWidth to clamp batch card width calculation between 94.0 and 180.0 and set the green box batch card Container constraints to minWidth: 94 and maxWidth: 180 in both table row templates. This enables long batch numbers to wrap naturally while shrink-wrapping the green box perfectly to eliminate empty space.
  - **Hint Text Default for Quantity**: Updated _buildQtyControl to use "0" as hintText and custom grey hintStyle. Cleaned up row controller initialization and empty Qty field assignments so that text fields are initialized empty ('') rather than with a literal '0', enabling clean hint-text display.
  - **Vertical Sizing and Padding**: Configured the outer row Container in _buildItemRow and _buildPOItemRow to enforce a minimum height of 132px (minHeight: hasBatches ? 132 : 0) when batches are present. Added a top and bottom margin of 4px (margin: const EdgeInsets.only(right: 2, top: 4, bottom: 4)) to the green box batch card Container, ensuring that the bottom border of the green boxes is fully drawn and never clipped by cell boundaries.

## 37. Batch Card Sizing Refinements, Horizontal Scroll Padding, & Quantity Input Hints (June 1, 2026)

### Summary
Addressed layout and sizing imperfections in the Purchase Receives screen. Corrected vertical border clipping on green batch boxes by adding vertical padding inside horizontal scroll containers. Tightened greenbox constraints from 180px to 145px to eliminate excess empty spacing when long text wraps. Configured default grey hint text "0" in quantity inputs when empty.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Batch Card Width Clamp Reduction**: Decreased maximum clamp limit in `_batchCardWidth` from 180.0 to 145.0. Reduced maximum constraints width of greenbox batch detail cards inside `_buildManualRow` and `_buildItemRow` from 180 to 145 to ensure the greenboxes tightly wrap wrapped batch texts, eliminating horizontal white space.
  - **Vertical Scroll View Padding Integration**: Wrapped the child Row of the horizontal `SingleChildScrollView` inside `_buildManualRow` and `_buildItemRow` in a `Padding` widget with `const EdgeInsets.symmetric(vertical: 6)`. This expands vertical scrolling boundaries, preventing the bottom borders and margins of active batch cards from being clipped by scroll-view boundaries.
  - **Quantity Input Hint Configurations**: Wired up standard dynamic input fields in `_buildQtyInputField` to display a gray "0" hint text (`hintText: "0"`, with `_hintColor` `TextStyle`) when empty, matching the default style of manual quantity controls.

**Verifications**: Verified compilation successfully with `dart analyze` on modified scopes.

Timestamp of Log Update: June 1, 2026 - 6:15 PM (IST)

## 38. Batch Card Sizing Refinements & Vertical Scroll Sizing Fixes (June 1, 2026)

### Summary
Further optimized Purchase Receives batch card visual density. Corrected vertical card clipping under multi-line text wrapping by increasing row minHeight constraints to 156px. Reduced the greenbox maxWidth limit to 120px to perfectly shrink-wrap wrapped batch UUID tokens and remove trailing whitespace.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Whitespace Sizing Tightening**: Reduced maximum batch card width in `_batchCardWidth()` clamp and Container constraints inside `_buildManualRow` and `_buildItemRow` from 145px to 120px. Ensures that the container size tightly hugs the widest wrapped token (e.g. 102px), leaving no trailing blank area.
  - **Height Expansion Fix**: Raised the outer row `BoxConstraints` minimum height constraint (`minHeight`) from 132px to 156px in `_buildManualRow` and `_buildItemRow` when batches are present. This provides sufficient vertical layout scope for scroll view viewports to render up to 9-10 lines of wrapped batch content without clipping bottom borders.

**Verifications**: Verified compilation successfully with `dart analyze` on modified scopes.

Timestamp of Log Update: June 1, 2026 - 6:38 PM (IST)

## 39. Rich Vendor Dropdown Selection & Row Padding Sizing Adjustments (June 1, 2026)

### Summary
Harmonized Vendor Name selection dropdown overlay inside the Purchase Receives create screen with Purchase Orders, presenting rich list items containing avatar initials, name, code, and company name under a 480px width dropdown menu. Resolved vertical clipping of batch cards by dynamically tightening row vertical padding to 4px when batches are present.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Rich Vendor Dropdown**: Replaced standard overlay items in `FormDropdown<Vendor>` with the stateful `_buildVendorDropdownItem` custom renderer. Added `menuWidth: 480` to cleanly display avatar initials, full display names, vendor numbers, and company names without text squeezing or overflow.
  - **Dynamic Row Padding Adjustments**: Refactored the `padding` parameter of outer container blocks inside `_buildManualRow` and `_buildItemRow` from `const EdgeInsets.symmetric(vertical: 12)` to `EdgeInsets.symmetric(vertical: hasBatches ? 4 : 12)`. This preserves standard vertical padding for normal rows while reclaiming 16px of vertical layout space for batch-carrying rows to fully present batch details without clipping.

**Verifications**: Verified compilation successfully with `dart analyze` on modified scopes.

Timestamp of Log Update: June 1, 2026 - 6:45 PM (IST)

## 40. Batch Card Sizing Refinements (June 1, 2026)

### Summary
Optimized the batch card visual formatting and height density. Decreased text line-height from 1.35 to 1.1 inside the batch cards, and reduced card margins and viewport scroll padding. Tightened card maxWidth limit from 120px to 114px. These changes eliminate horizontal whitespace and provide plenty of vertical room for cards to display fully without clipping.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Text Line Height Optimization**: Changed `height` parameter of `_batchText` from `1.35` to `1.1` to compress text layout and save `18px` of vertical height for wrapped cards.
  - **Sizing Bounds Adjustments**: Reduced `_batchCardWidth()` clamp limit and card constraints inside `_buildManualRow` and `_buildItemRow` from `120px` to `114px`. Long UUID batch strings wrap naturally without horizontal trailing empty space.
  - **Padding and Margins Compression**: Decreased scroll view padding to `vertical: 4` (down from `6`) and card container margins to `vertical: 2` (down from `4`) to prevent vertical border clipping.

**Verifications**: Verified compilation successfully with `dart analyze` on modified scopes.

Timestamp of Log Update: June 1, 2026 - 6:49 PM (IST)

## 32. Fix Purchase Receives Green Box Clipping and Width Layout (June 1, 2026)

### Summary
Fixed a critical layout issue in the Purchase Receives creation page (purchases_purchase_receives_create.dart) where the green batch details cards were vertically clipped and had excess blank space.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - **Vertical Stretching Fix**: Passed lignment: null to the _tableBodyCell that wraps the quantity column cell. This prevents the Container from wrapping its child in an Align widget, allowing the cell contents to expand to the full height of the table row.
  - **Inner Row crossAxisAlignment**: Set the inner Row's crossAxisAlignment to CrossAxisAlignment.stretch so that the horizontal SingleChildScrollView (containing the green batch cards) stretches to the full cell height.
  - **Vertical Centering of Qty Input**: Added mainAxisAlignment: MainAxisAlignment.center to the Column inside the quantity input SizedBox to keep the input text box vertically centered within the stretched row.
  - **Tighter Batch Card Width Clamp**: Reduced _batchCardWidth clamp upper bound from 114.0 to 110.0 and dynamic horizontal card margin/padding constants (maxLineWidth + 14 instead of 18) to hug the text closer and eliminate trailing blank space. Mapped BoxConstraints to _batchCardWidth(batch) dynamically instead of using a hardcoded maxWidth: 114.

Timestamp of Log Update: June 1, 2026 - 5:55 PM (IST)
- **Quantity Column Width Expansion**: Increased aseWidth from 124.0 to 160.0 and 0ixedContentWidth from 116.0 to 140.0 in _dynamicQtyToReceiveColumnWidth() to give the batch cards more horizontal space and prevent overflow/tight layouts.

Timestamp of Log Update: June 1, 2026 - 6:01 PM (IST)
- **Batch Dialog Overwrite Logic Fix**: Configured the dialog Save onPressed callback to bypass exceeds and mismatch validation errors when _overwriteLineItem is enabled. Wired the checkbox onChanged event to immediately clear any existing mismatch or exceeds error messages. Changed the error banner text to dynamically display the active _dialogErrorMessage instead of the hardcoded _quantityMismatchMessage string.

Timestamp of Log Update: June 1, 2026 - 6:05 PM (IST)

## 33. Sales Order & Invoice Tax Enhancements + Bill Radio Deprecations (June 2, 2026)

### Summary
Implemented dynamic tax breakdowns (CGST/SGST/IGST) in Sales Order and Sales Invoice creation pages, updated tax dropdown cell format to show tax rate, resolved deprecated Radio properties in Bills creation page, and cleaned up the handoff directory.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - **Dynamic Tax Lines State**: Declared `taxLines` state, modified `_calculateTotals()` to group row taxes by rates and check if `placeOfSupply` contains `"kerala"` to split taxes into CGST/SGST (intrastate) or IGST (interstate).
  - **Totals Box Rendering**: Rendered dynamic tax breakdown lines below shipping charges with dividing lines.
- lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart:
  - **Dynamic Tax Lines Rendering**: Rendered `taxLines` in the invoice totals box.
  - **Tax Cell Label formatting**: Implemented `_getTaxDisplayLabel` to format selected taxes in the items table as `TaxName [TaxRate%]`.
  - **Instant Tax Calculation**: Removed the `row.hasBatchData` check to compute and display taxes immediately for items/services before batch selection.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Radio Deprecations**: Wrapped `Radio` widgets with `RadioGroup<String>` to resolve deprecated Flutter properties.

#### Cleanup
- Removed unused `handoff_2026-05-30` local files.

**Verifications**: Verified code compiles successfully with zero warnings using `dart analyze`.

Timestamp of Log Update: June 2, 2026 - 11:15 AM (IST)

## 34. Sales Order Price List Dropdown Enhancements (June 2, 2026)

### Summary
Enhanced the price list dropdown inputs in the Sales Order creation page to load names as items, search by both ID and name, and filter the items list per the specified sales and item type conditions.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - **Header Dropdown**: Updated the header price list dropdown to load `salesPriceLists.map((p) => p.name)` as items.
  - **Item-Level Dropdown**: Configured the item-level price list dropdown to match active values by both `id` and `name` and store the name of the price list on selection.
  - **Price List Filtering**: Updated `applicablePriceLists` and `currentPriceList` lookups to match by name or ID.

**Verifications**: Verified compilation successfully with `dart analyze`.

Timestamp of Log Update: June 2, 2026 - 1:15 PM (IST)

## 35. Resolve PostgREST product_contents Relationship Embedding Error (June 2, 2026)

### Summary
Resolved a critical backend error where querying products failed due to a missing foreign key constraint between `product_contents.content_id` and `contents.id` in the schema cache. Fixed this programmatically in NestJS code without modifying the database schema.

### Detailed Engineering Changes

#### Backend Files
- backend/src/modules/products/products.service.ts:
  - **PRODUCT_SELECT_STRING query update**: Removed the nested `content:contents(id, content_name)` resource embedding from the supabase select string to prevent PostgREST from failing.
  - **getContentsMapForProducts helper**: Implemented a private batch-loading helper method to retrieve all required content details matching `content_id` values in a single database lookup.
  - **mapProduct mapping logic**: Injected `contentsMap` into `mapProduct` mapping step. The method maps content details from the map, with a lazy-loading fallback for single mappings (e.g. `findOne`).
  - **Controller and query injections**: Passed `contentsMap` to `mapProduct` in all query collections (`findAll`, `findAllCursor`, and `searchProducts`).


**Verifications**: Verified backend compiles successfully using `npm run build` and lints pass.

Timestamp of Log Update: June 2, 2026 - 1:50 PM (IST)

## 36. Fix Sales Order & Sales Invoice Tax Breakdown Visibility (June 3, 2026)

### Summary
Fixed an issue where the GST tax breakdown (CGST/SGST or IGST) was not displaying in the subtotal box in Sales Order Create and Sales Invoice Create pages upon customer selection or place of supply change, due to missing totals recalculation calls in the callbacks.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - **Customer Dropdown onChanged**: Added a `_calculateTotals()` call to trigger immediate recalculation when a customer is selected.
  - **Place of Supply onChanged**: Updated the `placeOfSupply` dropdown onChanged callback to call `_calculateTotals()`.
  - **New Customer Save Success**: Added `_calculateTotals()` call upon successful customer creation and pre-selection.
  - **Advanced Customer Search**: Added `_calculateTotals()` to the customer selection callback in the advanced search dialog.
  - **State Check/Format**: Standardized `isKerala` check in `_calculateTotals()` to match `pos.contains('[kl]') || pos.contains('kerala')` for robustness.
  - **Subtotal Divider**: Removed unnecessary second Divider and vertical space below mapped taxLines to align with invoice subtotal layout.
- lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart:
  - **State Check/Format**: Standardized `isKerala` check to match `pos.contains('[kl]') || pos.contains('kerala')` and fallback to `customerFromList?.placeOfSupply`.
  - **Advanced Customer Search**: Added `_calculateTotals()` to the customer selection callback in the advanced search dialog.
  - **New Customer Save Success**: Added `_calculateTotals()` call upon successful customer creation.

**Verifications**: Verified code compiles successfully with `dart analyze`.

Timestamp of Log Update: June 3, 2026 - 10:45 AM (IST)


## 37. Resolve Outlets and Shipment-Preferences 404/Schema Cache Errors (June 3, 2026)

### Summary
Resolved backend 404 errors for the `/api/v1/outlets` and `/api/v1/shipment-preferences` endpoints. Fixed a database index naming conflict on the `carrier` table constraints in PostgreSQL that blocked the creation of the `shipment_preferences` table.

### Detailed Engineering Changes

#### Database / Backend
- **Database Schema**: Renamed the conflicting constraints on the `carrier` table in PostgreSQL from `shipment_preferences_pkey` / `shipment_preferences_name_key` to `carrier_pkey` / `carrier_name_key`, then created the `shipment_preferences` table in the database and reloaded the PostgREST cache.
- **Drizzle Schema** ([schema.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/db/schema.ts)): Appended the Drizzle schema definition mapping for the `shipment_preferences` table.
- **Tenant Middleware** ([tenant.middleware.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/common/middleware/tenant.middleware.ts)): Added mapping rules to authorize `/api/v1/outlets` and `/api/v1/shipment-preferences` requests.
- **Branches Module**:
  - Created [outlets.controller.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/modules/branches/outlets.controller.ts) mapping GET `/outlets` to `BranchesService.findAll`.
  - Registered `OutletsController` in [branches.module.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/modules/branches/branches.module.ts).
- **Lookups Module**:
  - Created [shipment-preferences.controller.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/modules/lookups/shipment-preferences.controller.ts) to manage fetching and syncing shipment preferences.
  - Registered `ShipmentPreferencesController` in [lookups.module.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/modules/lookups/lookups.module.ts).
- **Vendors Service** ([vendors.service.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/modules/purchases/vendors/services/vendors.service.ts)): Updated `findAll` select query to embed `vendor_contact_persons` and `vendor_bank_accounts` in list results, resolving the empty contact list in the vendor sidebar.

**Verifications**: Verified backend builds successfully with `npm run build` and endpoints respond correctly with 401 Unauthorized under auth-checks.

Timestamp of Log Update: June 3, 2026 - 5:35 PM (IST)


## 38. Fetch Carrier Preferences from Carrier Table & Manage Carrier Dialog (June 4, 2026)

### Summary
Changed the shipment-preferences endpoints to target the `carrier` table in PostgreSQL instead of the empty `shipment_preferences` table. Updated the dialog layout configurations on the frontend to display carrier labels.

### Detailed Engineering Changes

#### Backend Files
- backend/src/modules/lookups/shipment-preferences.controller.ts:
  - **findAll**: Changed target table from `shipment_preferences` to `carrier`.
  - **sync**: Changed target table from `shipment_preferences` to `carrier`.
Timestamp of Log Update: June 1, 2026 - 6:15 PM (IST)

## 38. Batch Card Sizing Refinements & Vertical Scroll Sizing Fixes (June 1, 2026)

### Summary
Further optimized Purchase Receives batch card visual density. Corrected vertical card clipping under multi-line text wrapping by increasing row minHeight constraints to 156px. Reduced the greenbox maxWidth limit to 120px to perfectly shrink-wrap wrapped batch UUID tokens and remove trailing whitespace.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Whitespace Sizing Tightening**: Reduced maximum batch card width in `_batchCardWidth()` clamp and Container constraints inside `_buildManualRow` and `_buildItemRow` from 145px to 120px. Ensures that the container size tightly hugs the widest wrapped token (e.g. 102px), leaving no trailing blank area.
  - **Height Expansion Fix**: Raised the outer row `BoxConstraints` minimum height constraint (`minHeight`) from 132px to 156px in `_buildManualRow` and `_buildItemRow` when batches are present. This provides sufficient vertical layout scope for scroll view viewports to render up to 9-10 lines of wrapped batch content without clipping bottom borders.

**Verifications**: Verified compilation successfully with `dart analyze` on modified scopes.

Timestamp of Log Update: June 1, 2026 - 6:38 PM (IST)

## 39. Rich Vendor Dropdown Selection & Row Padding Sizing Adjustments (June 1, 2026)

### Summary
Harmonized Vendor Name selection dropdown overlay inside the Purchase Receives create screen with Purchase Orders, presenting rich list items containing avatar initials, name, code, and company name under a 480px width dropdown menu. Resolved vertical clipping of batch cards by dynamically tightening row vertical padding to 4px when batches are present.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Rich Vendor Dropdown**: Replaced standard overlay items in `FormDropdown<Vendor>` with the stateful `_buildVendorDropdownItem` custom renderer. Added `menuWidth: 480` to cleanly display avatar initials, full display names, vendor numbers, and company names without text squeezing or overflow.
  - **Dynamic Row Padding Adjustments**: Refactored the `padding` parameter of outer container blocks inside `_buildManualRow` and `_buildItemRow` from `const EdgeInsets.symmetric(vertical: 12)` to `EdgeInsets.symmetric(vertical: hasBatches ? 4 : 12)`. This preserves standard vertical padding for normal rows while reclaiming 16px of vertical layout space for batch-carrying rows to fully present batch details without clipping.

**Verifications**: Verified compilation successfully with `dart analyze` on modified scopes.

Timestamp of Log Update: June 1, 2026 - 6:45 PM (IST)

## 40. Batch Card Sizing Refinements (June 1, 2026)

### Summary
Optimized the batch card visual formatting and height density. Decreased text line-height from 1.35 to 1.1 inside the batch cards, and reduced card margins and viewport scroll padding. Tightened card maxWidth limit from 120px to 114px. These changes eliminate horizontal whitespace and provide plenty of vertical room for cards to display fully without clipping.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Text Line Height Optimization**: Changed `height` parameter of `_batchText` from `1.35` to `1.1` to compress text layout and save `18px` of vertical height for wrapped cards.
  - **Sizing Bounds Adjustments**: Reduced `_batchCardWidth()` clamp limit and card constraints inside `_buildManualRow` and `_buildItemRow` from `120px` to `114px`. Long UUID batch strings wrap naturally without horizontal trailing empty space.
  - **Padding and Margins Compression**: Decreased scroll view padding to `vertical: 4` (down from `6`) and card container margins to `vertical: 2` (down from `4`) to prevent vertical border clipping.

**Verifications**: Verified compilation successfully with `dart analyze` on modified scopes.

Timestamp of Log Update: June 1, 2026 - 6:49 PM (IST)

## 32. Fix Purchase Receives Green Box Clipping and Width Layout (June 1, 2026)

### Summary
Fixed a critical layout issue in the Purchase Receives creation page (purchases_purchase_receives_create.dart) where the green batch details cards were vertically clipped and had excess blank space.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - **Vertical Stretching Fix**: Passed  lignment: null to the _tableBodyCell that wraps the quantity column cell. This prevents the Container from wrapping its child in an Align widget, allowing the cell contents to expand to the full height of the table row.
  - **Inner Row crossAxisAlignment**: Set the inner Row's crossAxisAlignment to CrossAxisAlignment.stretch so that the horizontal SingleChildScrollView (containing the green batch cards) stretches to the full cell height.
  - **Vertical Centering of Qty Input**: Added mainAxisAlignment: MainAxisAlignment.center to the Column inside the quantity input SizedBox to keep the input text box vertically centered within the stretched row.
  - **Tighter Batch Card Width Clamp**: Reduced _batchCardWidth clamp upper bound from 114.0 to 110.0 and dynamic horizontal card margin/padding constants (maxLineWidth + 14 instead of 18) to hug the text closer and eliminate trailing blank space. Mapped BoxConstraints to _batchCardWidth(batch) dynamically instead of using a hardcoded maxWidth: 114.

Timestamp of Log Update: June 1, 2026 - 5:55 PM (IST)
- **Quantity Column Width Expansion**: Increased  aseWidth from 124.0 to 160.0 and 0ixedContentWidth from 116.0 to 140.0 in _dynamicQtyToReceiveColumnWidth() to give the batch cards more horizontal space and prevent overflow/tight layouts.

Timestamp of Log Update: June 1, 2026 - 6:01 PM (IST)
- **Batch Dialog Overwrite Logic Fix**: Configured the dialog Save onPressed callback to bypass exceeds and mismatch validation errors when _overwriteLineItem is enabled. Wired the checkbox onChanged event to immediately clear any existing mismatch or exceeds error messages. Changed the error banner text to dynamically display the active _dialogErrorMessage instead of the hardcoded _quantityMismatchMessage string.

Timestamp of Log Update: June 1, 2026 - 6:05 PM (IST)

## 33. Sales Order & Invoice Tax Enhancements + Bill Radio Deprecations (June 2, 2026)

### Summary
Implemented dynamic tax breakdowns (CGST/SGST/IGST) in Sales Order and Sales Invoice creation pages, updated tax dropdown cell format to show tax rate, resolved deprecated Radio properties in Bills creation page, and cleaned up the handoff directory.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - **Dynamic Tax Lines State**: Declared `taxLines` state, modified `_calculateTotals()` to group row taxes by rates and check if `placeOfSupply` contains `"kerala"` to split taxes into CGST/SGST (intrastate) or IGST (interstate).
  - **Totals Box Rendering**: Rendered dynamic tax breakdown lines below shipping charges with dividing lines.
- lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart:
  - **Dynamic Tax Lines Rendering**: Rendered `taxLines` in the invoice totals box.
  - **Tax Cell Label formatting**: Implemented `_getTaxDisplayLabel` to format selected taxes in the items table as `TaxName [TaxRate%]`.
  - **Instant Tax Calculation**: Removed the `row.hasBatchData` check to compute and display taxes immediately for items/services before batch selection.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Radio Deprecations**: Wrapped `Radio` widgets with `RadioGroup<String>` to resolve deprecated Flutter properties.

#### Cleanup
- Removed unused `handoff_2026-05-30` local files.

**Verifications**: Verified code compiles successfully with zero warnings using `dart analyze`.

Timestamp of Log Update: June 2, 2026 - 11:15 AM (IST)

## 34. Sales Order Price List Dropdown Enhancements (June 2, 2026)

### Summary
Enhanced the price list dropdown inputs in the Sales Order creation page to load names as items, search by both ID and name, and filter the items list per the specified sales and item type conditions.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - **Header Dropdown**: Updated the header price list dropdown to load `salesPriceLists.map((p) => p.name)` as items.
  - **Item-Level Dropdown**: Configured the item-level price list dropdown to match active values by both `id` and `name` and store the name of the price list on selection.
  - **Price List Filtering**: Updated `applicablePriceLists` and `currentPriceList` lookups to match by name or ID.

**Verifications**: Verified compilation successfully with `dart analyze`.

Timestamp of Log Update: June 2, 2026 - 1:15 PM (IST)

## 35. Resolve PostgREST product_contents Relationship Embedding Error (June 2, 2026)

### Summary
Resolved a critical backend error where querying products failed due to a missing foreign key constraint between `product_contents.content_id` and `contents.id` in the schema cache. Fixed this programmatically in NestJS code without modifying the database schema.

### Detailed Engineering Changes

#### Backend Files
- backend/src/modules/products/products.service.ts:
  - **PRODUCT_SELECT_STRING query update**: Removed the nested `content:contents(id, content_name)` resource embedding from the supabase select string to prevent PostgREST from failing.
  - **getContentsMapForProducts helper**: Implemented a private batch-loading helper method to retrieve all required content details matching `content_id` values in a single database lookup.
  - **mapProduct mapping logic**: Injected `contentsMap` into `mapProduct` mapping step. The method maps content details from the map, with a lazy-loading fallback for single mappings (e.g. `findOne`).
  - **Controller and query injections**: Passed `contentsMap` to `mapProduct` in all query collections (`findAll`, `findAllCursor`, and `searchProducts`).


**Verifications**: Verified backend compiles successfully using `npm run build` and lints pass.

Timestamp of Log Update: June 2, 2026 - 1:50 PM (IST)

## 36. Fix Sales Order & Sales Invoice Tax Breakdown Visibility (June 3, 2026)

### Summary
Fixed an issue where the GST tax breakdown (CGST/SGST or IGST) was not displaying in the subtotal box in Sales Order Create and Sales Invoice Create pages upon customer selection or place of supply change, due to missing totals recalculation calls in the callbacks.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - **Customer Dropdown onChanged**: Added a `_calculateTotals()` call to trigger immediate recalculation when a customer is selected.
  - **Place of Supply onChanged**: Updated the `placeOfSupply` dropdown onChanged callback to call `_calculateTotals()`.
  - **New Customer Save Success**: Added `_calculateTotals()` call upon successful customer creation and pre-selection.
  - **Advanced Customer Search**: Added `_calculateTotals()` to the customer selection callback in the advanced search dialog.
  - **State Check/Format**: Standardized `isKerala` check in `_calculateTotals()` to match `pos.contains('[kl]') || pos.contains('kerala')` for robustness.
  - **Subtotal Divider**: Removed unnecessary second Divider and vertical space below mapped taxLines to align with invoice subtotal layout.
- lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart:
  - **State Check/Format**: Standardized `isKerala` check to match `pos.contains('[kl]') || pos.contains('kerala')` and fallback to `customerFromList?.placeOfSupply`.
  - **Advanced Customer Search**: Added `_calculateTotals()` to the customer selection callback in the advanced search dialog.
  - **New Customer Save Success**: Added `_calculateTotals()` call upon successful customer creation.

**Verifications**: Verified code compiles successfully with `dart analyze`.

Timestamp of Log Update: June 3, 2026 - 10:45 AM (IST)


## 37. Resolve Outlets and Shipment-Preferences 404/Schema Cache Errors (June 3, 2026)

### Summary
Resolved backend 404 errors for the `/api/v1/outlets` and `/api/v1/shipment-preferences` endpoints. Fixed a database index naming conflict on the `carrier` table constraints in PostgreSQL that blocked the creation of the `shipment_preferences` table.

### Detailed Engineering Changes

#### Database / Backend
- **Database Schema**: Renamed the conflicting constraints on the `carrier` table in PostgreSQL from `shipment_preferences_pkey` / `shipment_preferences_name_key` to `carrier_pkey` / `carrier_name_key`, then created the `shipment_preferences` table in the database and reloaded the PostgREST cache.
- **Drizzle Schema** ([schema.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/db/schema.ts)): Appended the Drizzle schema definition mapping for the `shipment_preferences` table.
- **Tenant Middleware** ([tenant.middleware.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/common/middleware/tenant.middleware.ts)): Added mapping rules to authorize `/api/v1/outlets` and `/api/v1/shipment-preferences` requests.
- **Branches Module**:
  - Created [outlets.controller.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/modules/branches/outlets.controller.ts) mapping GET `/outlets` to `BranchesService.findAll`.
  - Registered `OutletsController` in [branches.module.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/modules/branches/branches.module.ts).
- **Lookups Module**:
  - Created [shipment-preferences.controller.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/modules/lookups/shipment-preferences.controller.ts) to manage fetching and syncing shipment preferences.
  - Registered `ShipmentPreferencesController` in [lookups.module.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/modules/lookups/lookups.module.ts).
- **Vendors Service** ([vendors.service.ts](file:///C:/Users/User/Documents/work/test/zerpai-new/backend/src/modules/purchases/vendors/services/vendors.service.ts)): Updated `findAll` select query to embed `vendor_contact_persons` and `vendor_bank_accounts` in list results, resolving the empty contact list in the vendor sidebar.

**Verifications**: Verified backend builds successfully with `npm run build` and endpoints respond correctly with 401 Unauthorized under auth-checks.

Timestamp of Log Update: June 3, 2026 - 5:35 PM (IST)


## 38. Fetch Carrier Preferences from Carrier Table & Manage Carrier Dialog (June 4, 2026)

### Summary
Changed the shipment-preferences endpoints to target the `carrier` table in PostgreSQL instead of the empty `shipment_preferences` table. Updated the dialog layout configurations on the frontend to display carrier labels.

### Detailed Engineering Changes

#### Backend Files
- backend/src/modules/lookups/shipment-preferences.controller.ts:
  - **findAll**: Changed target table from `shipment_preferences` to `carrier`.
  - **sync**: Changed target table from `shipment_preferences` to `carrier`.

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart:
  - **_showManageShipmentPreferencesDialog**: Configured ManageListDialog with `title: 'Manage Carriers'`, `singularLabel: 'Carrier'`, and `headerLabel: 'Carrier'`.

**Verifications**: Verified backend builds successfully with `npm run build` and frontend compiles cleanly with `dart analyze`.

Timestamp of Log Update: June 4, 2026 - 11:20 AM (IST)


## 39. Popover Outlines, Selected Dropdown States & Permanent Row Action Buttons (June 4, 2026)

### Summary
Removed the solid blue border outline and blue triangle painter from the Recent/Open Orders popover box, replacing them with a neutral light grey outline (`#DDDDDD`) and a white triangle painter. Added a selected outline state to the row-level discount type dropdown container so that the border outline turns blue when the popover dropdown list is open/active, in addition to when hovered. Made the row-level actions (delete "X" and more actions "3 dots") permanently visible in both Purchase Orders and Bills creation pages.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart:
  - **_OpenPurchaseOrdersPopover / _TrianglePainter**: Changed outer border and arrow outlines from blue (`0xFF3481F4`) to light grey (`0xFFDDDDDD`) with a solid white fill.
  - **_HoverBorderContainer**: Added `isSelected` parameter to constructor and conditional styling in build to draw blue outline when either hovered or selected.
  - **_purchases_purchase_orders_createState**: Added `_activeDiscountRowIndex` state variable. Wired `_showDiscountMenu` and `_closeDiscountOverlay` to update it. Passed it as `isSelected` to row-level discount containers.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **_HoverBorderContainer**: Added `isSelected` parameter to constructor and conditional styling in build to draw blue outline when either hovered or selected.
  - **_purchases_bills_createState**: Added `_activeDiscountRowIndex` state variable. Wired `_showDiscountMenu` and `_closeDiscountOverlay` to update it. Passed it as `isSelected` to row-level discount containers.
  - **_actionsCell**: Removed `isHovered` checks to make the action buttons permanently visible.

**Verifications**: Verified frontend compiles cleanly with `dart analyze` with zero lints or errors.

Timestamp of Log Update: June 4, 2026 - 12:45 PM (IST)

## 40. Purchase Order Creation Tax UI & Backend Validation Fix (June 5, 2026)

### Summary
Fixed the tax column dropdown box outline hover/selection aesthetics in the Purchase Orders creation page. Unified unregistered vendor tax placeholder logic. Resolved NestJS DTO validation and database schema mismatch where warehouse_id was being sent inside the item objects but is not present in the purchase_order_items database table.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart:
  - **Tax Dropdown Outline**: Wrapped the tax dropdown container inside a MouseRegion and StatefulBuilder to render a blue border outline (0xFF0088FF) on hover or when selected, and transparent otherwise.
  - **Unregistered Treatment Tax Placeholder**: If the vendor's GST treatment is unregistered, show the 'Select Tax' placeholder inside the tax dropdown cell instead of 'Non-Taxable'.

#### Backend Files
- backend/src/modules/purchases/purchase-orders/dto/create-purchase-order.dto.ts:
  - **PurchaseOrderItemDto**: Whitelisted optional string field warehouse_id to allow it to pass NestJS validation pipeline.
- backend/src/modules/purchases/purchase-orders/services/purchase-orders.service.ts:
  - **Service Layer Payload Mapping**: Destructured and excluded warehouse_id from item objects inside mapping loop in both create and update methods to prevent PostgREST relationships/schema cache validation errors.

**Verifications**: Verified backend builds successfully with 
pm run build and frontend compiles cleanly with dart analyze.

Timestamp of Log Update: June 5, 2026 - 12:25 PM (IST)

## 41. Purchase Order Creation Quantity Validation & Account Outline (June 5, 2026)

### Summary
Added quantity validation to PO creation flow. Styled the account dropdown box outline on hover/selection to match the design system. Rendered the tax dropdown box as read-only but preserved the dropdown appearance when the vendor's GST treatment is unregistered.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart:
  - **Quantity Validation**: Added checks inside the _handleSave loop to ensure item quantities are greater than zero, throwing a ZerpaiToast.error with the exact message 'Please enter a valid quantity for item ' if not.
  - **Account Dropdown Outline**: Added _activeAccountRowIndex state tracking and _closeAccountOverlay(). Wrapped the account dropdown container in a StatefulBuilder and MouseRegion to draw a blue outline (0xFF0088FF) on hover or selection, transparent otherwise.
  - **Read-Only Tax Dropdown**: Always show the dropdown arrow icon even when the vendor's GST treatment is unregistered. Disabled the hover blue outline highlight on the tax box when the vendor is unregistered.

**Verifications**: Verified frontend compiles cleanly with dart analyze.

Timestamp of Log Update: June 5, 2026 - 12:45 PM (IST)

## 42. Header Row Validation, Custom TDS Dropdown Grouping & TDS Rates Management (June 5, 2026)

### Summary
Implemented robust validation for purchase order header rows and resolved syntax/bracket issues in the PO creation page. Replaced the standard static TDS/TCS dropdown with a custom popover listing TDS rates grouped by their parent TDS Section (`section_id` lookup). Added a "+ Manage TDS" modal management dialog that integrates with the existing `ManageListDialog` and parses base rate bracket notation (e.g. `[1.5%]`) dynamically to keep database sync compliant. Updated state notifier logic to calculate TDS/TCS amounts and inject them into PO payload creation.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/items/items/services/lookups_api_service.dart:
  - **syncTdsRates**: Exposed public lookup synchronization method mapped to the `/tds-rates` endpoint.
- lib/modules/purchases/purchase_orders/notifiers/purchase_order_notifier.dart:
  - **PurchaseOrderState & Notifier**: Added `tdsTcsRate` state tracking, implemented a computed `tdsTcsAmount` getter, and updated the `total` getter to correctly apply TDS (subtraction) or TCS (addition) adjustments dynamically.
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart:
  - **Header Row Validation**: Skip product-specific checks (quantity/account/HSN) for items marked as header rows (`isHeader == true`), and instead ensure the user enters a non-empty header title.
  - **TDS Sections & Rates Loading**: Loaded `tds_rates` and `tds_sections` lists on initialization.
  - **Custom TDS Selection Popover**: Created `_TdsSelectionPopover` containing a search input, group headers for sections, rates displaying `tax_name [base_rate]%`, and a footer actions button link to manage TDS.
  - **TDS rates Syncing**: Implemented `_showManageTdsRatesDialog` which parses user-entered tax titles to extract `base_rate` percentages and syncs the updated rates back to lookups.

**Verifications**: Verified backend builds successfully with `npm run build` and frontend compiles cleanly with `dart analyze`. Verified all existing items tests pass successfully via `flutter test`.

Timestamp of Log Update: June 5, 2026 - 1:50 PM (IST)


## 43. Favorite Filter Dropdown Revert & Loading Fix (June 5, 2026)

### Summary
Reverted the visual presentation of the FavoriteFilterDropdown trigger button to its original transparent-background design and aligned text/icon styles with AppTheme color tokens. Fixed a critical endless loading spinner in the dropdown popover by ensuring the loading state is deactivated when Supabase authentication is uninitialized or when query exceptions occur.

### Detailed Engineering Changes

#### Frontend Files
- lib/shared/widgets/inputs/favorite_filter_dropdown.dart:
  - **Trigger Styling Reversion**: Removed the light-blue container background and rounded decoration from the custom MenuAnchor builder. Restored the simple InkWell and Padding container structure utilizing `AppTheme.textPrimary` for text color and `AppTheme.primaryBlue` for the chevron icon.
  - **Unauthenticated State Spinner Fix**: Modified `_loadFavorites()` to call `setState(() => _isLoading = false)` and log a debug message when `userId` is `null` (e.g. on unauthenticated initial launch or dev refresh), preventing the views list from displaying an endless loading spinner.
  - **Query Exception Safety**: Added debug logging inside the `catch (e)` block of `_loadFavorites()` and ensured `_isLoading = false` is always set upon query errors.

**Verifications**: Verified frontend compiles cleanly with `dart analyze` with zero lints or errors.

Timestamp of Log Update: June 5, 2026 - 6:55 PM (IST)


## 44. Favorite Filter Dropdown Selection Auto-Star & Selected Highlighting Revert (June 5, 2026)

### Summary
Removed the blue/light-blue background highlights and text color states for selected/active views in the filter dropdown list, keeping all list rows standard transparent. Implemented automatic star favoriting when any view filter is selected/tapped from the dropdown, triggering Supabase insert queries dynamically.

### Detailed Engineering Changes

#### Frontend Files
- lib/shared/widgets/inputs/favorite_filter_dropdown.dart:
  - **Selected Row Highlight Removal**: Changed the Container background color to `Colors.transparent` and text color styling to `AppTheme.textPrimary` with `FontWeight.w500` regardless of `isSelected` state, preventing double/overlapping blue row styling.
  - **Auto-Favoriting on Option Tap**: Updated `onTap` within `_optionRow` to verify if the selected value is already favorited and dynamically trigger `_toggleFavorite(opt)` if it isn't, ensuring the star is colored yellow and successfully entered in the `favorites` table in the database.

**Verifications**: Verified compilation using `dart analyze` on the modified component.

Timestamp of Log Update: June 5, 2026 - 7:00 PM (IST)


## 45. Favorite Filter User & Tenant Resolution Support (June 5, 2026)

### Summary
Resolved a critical integration bug where view favorites were not saving or loading in local/dev environments. Local profiles use auth sessions decoupled from Supabase's direct auth object, causing query bypasses. Implemented robust hierarchical user and entity ID resolvers falling back to `authUserProvider` and Hive configuration storage, enabling real-time Postgres DB persistence.

### Detailed Engineering Changes

#### Frontend Files
- lib/shared/widgets/inputs/favorite_filter_dropdown.dart:
  - **Hierarchical User ID Resolver**: Added `_getUserId()` helper to check Supabase active auth, falling back to `authUserProvider` details and raw Hive configuration state under the `user_data` registry.
  - **Hierarchical Entity ID Resolver**: Added `_getEntityId()` helper to read active branch/organization states from `entityProvider`, `authUserProvider`, and Hive configurations.
  - **Tap-Sequence Optimization**: Reordered `onTap` callbacks in the option rows to trigger `_toggleFavorite()` asynchronously *prior* to closing the menu, preventing premature widget unmounting from cancelling database sync events.

**Verifications**: Verified compilation using `dart analyze` on the modified component.

Timestamp of Log Update: June 5, 2026 - 9:30 PM (IST)


## 46. Solid Color Filled Star Icon Support (June 5, 2026)

### Summary
Replaced LucideIcons star representation with standard Material `Icons.star` and `Icons.star_border` to resolve a rendering bug where font-based Lucide icons did not fill their path color. Starred/favorited views now display a solid filled orange/yellow star.

### Detailed Engineering Changes

#### Frontend Files
- lib/shared/widgets/inputs/favorite_filter_dropdown.dart:
  - **Standard Material Icons Migration**: Replaced `LucideIcons.star` with conditional check for `isStarred ? Icons.star : Icons.star_border` to cleanly render filled stars on favorited elements and outline-only stars on defaults.

**Verifications**: Verified compilation using `dart analyze` with zero lints/warnings.

Timestamp of Log Update: June 5, 2026 - 9:35 PM (IST)


## 47. Header Option Display Label Formatting (June 5, 2026)

### Summary
Customized the display label rendered on the dropdown trigger header row. When the "All" option is selected, the trigger label is dynamically formatted as "All [ModuleName]" (e.g. "All Purchase Orders") to prevent generic "All" text from cluttering the module page headers.

### Detailed Engineering Changes

#### Frontend Files
- lib/shared/widgets/inputs/favorite_filter_dropdown.dart:
  - **Dynamic Display Label Formatter**: Added `_getDisplayLabel()` to automatically maps `All` option to full descriptions based on active `moduleName` (e.g. `purchase_orders` -> "All Purchase Orders"), falling back to capital-case string splits.

**Verifications**: Verified compilation using `dart analyze` with zero errors.

Timestamp of Log Update: June 5, 2026 - 9:40 PM (IST)

## 29. Sales Orders Sort By Menu Harmonisation (June 06, 2026)

### Summary
Unified the more menu options and visual hierarchy in the Sales Order list screen (sales_order_list.dart). Aligned the "Sort by" submenu items with the designed options (Sales Order#, Date, Customer Name, Amount, Created Time, Last Modified Time, Expected Shipment Date) and implemented standard leading icons for all more menu actions.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart:
  - **Shared More Menu Builder**: Created _buildMoreMenuChildren() helper method to build unified MenuItemButtons and SubmenuButtons with correct leading Lucide icons.
  - **Sort Menu Options Realignment**: Aligned the "Sort by" submenu list to contain 'Sales Order#', 'Date', 'Customer Name', 'Amount', 'Created Time', 'Last Modified Time', and 'Expected Shipment Date'.
  - **Toolbar and Sidebar Sync**: Modified both ZTableMoreMenu instances in the page layout (top toolbar and selection split-view panel) to consume the unified _buildMoreMenuChildren(), ensuring visual consistency and fixing a missing onPressed reload callback bug.

Timestamp of Log Update: June 06, 2026 - 11:15 AM (IST)

## 30. Sales Orders Header & Sizing Enhancements (June 06, 2026)

### Summary
Removed interactive sorting styling and click handlers from column headers in sales_order_list.dart to make them clean, static labels. Additionally, matched the sizing of the ZTableMoreMenu toolbar button to the ZButton height (38px) in both Sales Orders and Sales Invoices module lists.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart:
  - **Static Header Labels**: Removed the InkWell wrapper, sort arrow icons, and conditional blue text highlights inside _buildHeaderForColumn(), making column header elements visual-only.
  - **Unused Method Cleanup**: Deleted the unused _sortFieldForColumn helper method.
  - **More Menu Button Sizing**: Adjusted the toolbar ZTableMoreMenu dimensions to 38px width and 38px height to align with the primary ZButton vertical spacing.
- lib/modules/sales/invoices/presentation/pages/sales_invoice_list.dart:
  - **More Menu Button Sizing**: Resized the main toolbar ZTableMoreMenu to 38x38px to maintain consistent layout standards across sales screens.

Timestamp of Log Update: June 06, 2026 - 11:20 AM (IST)

## 31. Sales & Invoices Header Chevron Restore (June 06, 2026)

### Summary
Restored the dropdown chevron arrows on the page title/header dropdown triggers in both Sales Orders and Sales Invoices module lists.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart:
  - **Show Chevron Flag**: Changed showChevron to 	rue on both FavoriteFilterDropdown calls (toolbar and split view sidebar).
- lib/modules/sales/invoices/presentation/pages/sales_invoice_list.dart:
  - **Show Chevron Flag**: Changed showChevron to 	rue on both FavoriteFilterDropdown calls (sidebar and main toolbar).

Timestamp of Log Update: June 06, 2026 - 11:25 AM (IST)

## 32. Invoices Filter & More Menu Submenu Alignments (June 06, 2026)

### Summary
Expanded status filter views inside sales_invoice_list.dart to match screenshots 3, 4, and 5. Aligned the toolbar 3-dots dropdown list submenus, options, and actions in sales_invoice_list.dart based on screenshots 1 and 2.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/invoices/presentation/pages/sales_invoice_list.dart:
  - **Filter Presets Expansion**: Added Pending Collection Invoices and Marketplace status filter options and view mapping definitions to _invoiceViews and _invFilterOptions.
  - **Sort Menu Realignment**: reordered/added items in Sort by submenu: Created Time, Last Modified Time, Date, Invoice#, Order Number, Customer Name, Due Date, Amount, Balance Due.
  - **Import Option Submenu**: Nested Import Invoices inside an Import submenu folder button.
  - **Export Option Submenu**: Added Export as E-Way Bill option to Export submenu button.
  - **Online Payments Option**: Introduced the new Online Payments button using monitor icon.
  - **Reset Column Width Action**: Added Reset Column Width option that removes 'sales_invoice_column_widths' key from Shared Preferences and sets _customColumnWidths state back to null.

Timestamp of Log Update: June 06, 2026 - 11:30 AM (IST)

## 33. TDS and TCS Radio Selection and Popover Selector UI Implementation (June 06, 2026)

### Summary
Implemented the dynamic TDS/TCS radio buttons, search-and-group popover overlay selector (`_TdsSelectionPopover`), and "+ Manage TDS/TCS" inline dialog management (`ManageTdsTcsRatesDialog`) across three targets: Purchases Bills Create, Sales Invoices Create, and Sales Orders Create pages. Wired state calculations and database mappings to correctly compute, show, and save transaction-level TDS/TCS values.

### Detailed Engineering Changes

#### Database / Backend Files
- backend/src/modules/purchases/bills/services/bills.service.ts:
  - **Save TDS/TCS Totals**: Mapped the calculated `tds_total` and `tcs_total` values from client payloads to PostgreSQL columns.
- backend/src/modules/sales/services/sales.service.ts:
  - **Save TDS/TCS Fields**: Persisted transaction-level fields (`tds_tcs_type`, `tds_tcs_tax_id`, `tds_tcs_amount`) for Sales Orders.

#### Frontend Files
- lib/modules/purchases/bills/models/purchases_bills_bill_model.dart:
  - **TDS/TCS model serialization**: Extended the JSON serialization (`toJson`, `fromJson`) to support `tdsTotal` and `tcsTotal` fields.
- lib/modules/sales/sales_orders/data/models/sales_order_model.dart:
  - **TDS/TCS model serialization**: Added backend model fields mapping for `tdsTcsType`, `tdsTcsTaxId`, and `tdsTcsAmount` properties.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **TDS/TCS UI & Calculations**: Integrated radio group controls, layered popup overlays, and dynamic lookup loading. Implemented lookup reconstruction during editing. Mapped grand total subtraction (TDS) and addition (TCS).
- lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart:
  - **TDS/TCS UI & Calculations**: Ported PO-style radio selection, dynamic popover overlay, and inline management triggers. Configured grand total calculation adjustments.
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - **TDS/TCS UI & Calculations**: Replaced the static TDS/TCS select box with PO-styled radio buttons and popup overlay, binding selected values to the backend payload structure.

**Verifications**: Verified backend builds successfully with `npm run build` and frontend compiles cleanly with `dart analyze`.

Timestamp of Log Update: June 06, 2026 - 11:35 AM (IST)


## [Merge Audit] Handoff 2026-06-06 Integration (2026-06-08)

- **Backup Location**: `backups/refactor-batches/20260608_102728-handoff_2026-06-06/` (All source extensions renamed to `.bak`)
- **Compatibility Shims**: None required (no files moved or renamed, only modifications/additions).
- **Special Merge Modifications**:
  - `backend/src/db/schema.ts`: Merged `favorites` table and modified `products` constraints (`notNull()` on `type`, `productName`, `itemCode`, `unitId`) while preserving all 30+ product description columns to prevent breaking `items_item_create.dart`.
  - `lib/modules/items/items/models/item_model.dart`: Merged new tax fields and fallback parsers while preserving all 30+ product description fields.
- **Verification Gates**:
  - Backend: `npm run build` compiled successfully.
  - Frontend: `dart analyze` running to verify.
- **Residual Risks**:
  - Database schema has new constraints (`notNull()` on `products` columns) and a new `favorites` table. Drizzle schema generation/migrations must be run to sync PostgreSQL database.

## 34. Purchases Bills Convert from PO Data Loading Fix (June 08, 2026)

### Summary
Fixed an issue where clicking the "Convert to Bill" button on a Purchase Order did not load the PO data into the Purchases Bills creation screen (purchases_bills_create.dart).

### Detailed Engineering Changes

#### Frontend Files
- lib/app/routing/app_router.dart:
  - Mapped the poId query parameter in the illsCreate route definition and passed it to the PurchasesBillCreateScreen constructor. This enables the screen to retrieve the purchase order ID from the URL and trigger _loadPoForConvert() during initialization.

**Verifications**: Verified compilation using dart analyze with zero errors.

Timestamp of Log Update: June 08, 2026 - 6:30 PM (IST)

## 35. Warning Icon Layout Reversion & Tooltip Fix (June 09, 2026)

### Summary
Rolled back the previous layout changes (Row layout, solid Icon style) of the warning icon in both Purchases Purchase Orders and Bills Create screens, restoring the outline `LucideIcons.alertCircle` icon at its original offset position. Resolved the hover hit-testing issue by wrapping the row inside a parent `Transform.translate` container, enabling hover gestures on the warning icon without causing visual shifts in the dropdown alignment.

Timestamp of Log Update: June 08, 2026 - 6:30 PM (IST)

## 35. Warning Icon Layout Reversion & Tooltip Fix (June 09, 2026)

### Summary
Rolled back the previous layout changes (Row layout, solid Icon style) of the warning icon in both Purchases Purchase Orders and Bills Create screens, restoring the outline `LucideIcons.alertCircle` icon at its original offset position. Resolved the hover hit-testing issue by wrapping the row inside a parent `Transform.translate` container, enabling hover gestures on the warning icon without causing visual shifts in the dropdown alignment.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart:
  - Reverted warning icon style from solid `Icons.error` back to the outline `LucideIcons.alertCircle`.
  - Replaced the simple horizontal `Row` container with a parent `Transform.translate` widget applying an offset of `Offset(notIncluded ? -24 : 0, 0)` to the inner Row. This offsets the dropdown's position inside the Row to preserve its alignment while keeping pointer coordinates mapped cleanly for hover tooltip interaction.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - Ported the identical layout reversion and parent translation offset fix, restoring `LucideIcons.alertCircle` and ensuring perfect design layout symmetry and functional hover tooltips.

Timestamp of Log Update: June 09, 2026 - 10:45 AM (IST)


## 36. Purchase Receives Validation and UI/UX Alignment Polish (June 10, 2026)

### Summary
Fixed the batch quantity mismatch validation error blocking partial receives in the Purchase Receives page, and re-applied all requested layout alignments, vendor-specific PO filtering, and asynchronous payment terms sidebar name lookup.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - **Validation Fix**: Changed validation check from `totalBatchQtyOnly != item.ordered` to `totalBatchQtyOnly != item.quantityToReceive` to support partial receives.
  - **Dropdown Filtering**: Updated `_fetchPOsForVendor` to load POs filtered by `vendorId` via `PurchaseOrderFilter` and local list filtering.
  - **Layout Sizing**: Uniformly sized Vendor Name and Purchase Order dropdown widths to 550 and heights to 32.
  - **Action Header Link**: Replaced static header cell text with custom `Column` containing "ITEMS & DESCRIPTION" label and clickable "add all items" `InkWell` linked to `_addAllItemsFromPO()`.
  - **Insert Row Button & New Vendor**: Removed "+ Insert New Row" from PO table layout, and disabled "+ New Vendor" option inside Vendor Name dropdown.
  - **Details Sidebar & Currency Badge**: Removed the `INR` currency badge, pushed the sidebar details button to the right end via a Spacer, and added state `_isVendorSidebarLoading` to lock overlay and prevent duplicate triggers.
- lib/modules/purchases/vendors/presentation/widgets/vendor_sidebar.dart:
  - **Payment Terms Lookup**: Fetches dynamic payment terms asynchronously inside `initState()` using `LookupsApiService().getPaymentTerms()` if the input list is empty. Resolves payment term names dynamically from ID value, showing human-readable names instead of UUID strings.

**Verifications**: Verified compilation successfully with `dart analyze` on modified files.

Timestamp of Log Update: June 10, 2026 - 9:40 PM (IST)

## 37. Product Warehouse Stocks in Popover (June 10, 2026)

### Summary
Implemented multi-tenant scoping and views querying on the backend to retrieve and return physical and accounting stocks for specific products in the warehouse locations popover. Wired the product ID parameter from all transaction edit/create line-item tables to fetch and show dynamic stock balances.

### Detailed Engineering Changes

#### Frontend Files
- `lib/shared/widgets/inputs/warehouse_popover.dart`:
  - Added `String? productId` to popover constructor and updated `itemWarehouseStocksProvider` to accept `productId`.
  - When `productId` is provided, watches stock provider to dynamically fetch stocks from the database scoped by product and maps them to listed warehouses, defaulting empty locations to 0.
- `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`:
  - Passed `row.itemId` to `WarehouseHoverPopover` to fetch dynamic stock levels.
- `lib/modules/sales/invoices/presentation/pages/sales_invoice_edit_page.dart`:
  - Passed `row.itemId` to `WarehouseHoverPopover` to fetch dynamic stock levels.
- `lib/modules/sales/credit_note/presentation/pages/credit_note_create_page.dart`:
  - Passed `item.sourceItem?.id` to `WarehouseHoverPopover` to fetch dynamic stock levels.
- `lib/modules/purchases/vendor_credits/presentation/purchases_vendor_credits_create.dart`:
  - Passed `item.sourceItem?.id` to `WarehouseHoverPopover` to fetch dynamic stock levels.
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`:
  - Passed `item.productId` to `WarehouseHoverPopover` to fetch dynamic stock levels.
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - Passed `row.itemId` to `WarehouseHoverPopover` to fetch dynamic stock levels.
- `lib/modules/inventory/packages/presentation/pages/inventory_packages_create.dart`:
  - Passed `item.itemId` to `WarehouseHoverPopover` to fetch dynamic stock levels.
- `lib/modules/inventory/packages/presentation/pages/inventory_packages_edit.dart`:
  - Passed `item.itemId` to `WarehouseHoverPopover` to fetch dynamic stock levels.

#### Backend Files
- `backend/src/modules/products/products.controller.ts`:
  - Scoped endpoints `/products/:id/warehouse-stocks`, `/products/:id/warehouse-stocks/adjust-physical`, and update routes by adding `@Tenant() tenant: TenantContext` parameter.
- `backend/src/modules/products/products.service.ts`:
  - Updated `getProductWarehouseStocks` to scope warehouse queries by resolving `tenant.entityId`.
  - Queried `v_accounting_stock` and `v_physical_stock` views scoped by `product_id` and `entity_id`.
  - Mapped database properties (`stock_on_hand`, `committed_stock`, `available_stock`, `qty`) to `accounting` and `physical` structures with `onHand`, `committed`, and `available` properties expected by the frontend.

Timestamp of Log Update: June 10, 2026 - 10:05 PM (IST)

## 38. Table Header Menu and Column Customizer Visual Polish (June 11, 2026)

### Summary
Polished the table header menu and column customizer styles to align perfectly with the screenshots provided by the user.

### Detailed Engineering Changes

#### Frontend Files
- `lib/shared/widgets/tables/column_customizer.dart`:
  - Replaced the raw `TextField` search box with the standard, reusable `CustomTextField` to match Zerpai design guidelines and visual mockups.
  - Added a 45-degree rotation (`Transform.rotate(angle: col.isPinned ? 0 : -0.785, ...)`) to the pin icon of unpinned list items, reproducing the tilted pin aesthetic shown in the mockup screenshots.
- `lib/shared/widgets/tables/table_header_menu.dart`:
  - Removed the left icon from the "Wrap Text" dropdown menu item, substituting it with a `SizedBox(width: 28)` to align its text content exactly with the "Customize Columns" item text as shown in the dropdown screenshot.

**Verifications**: Verified code compiles successfully with `dart analyze` with zero compilation errors.

Timestamp of Log Update: June 11, 2026 - 12:35 AM (IST)

## 39. Purchase Order detail popups, status updates, total quantity calculations, and cloning (June 11, 2026)

### Summary
Fixed Expected Delivery Date and Cancel Items dialog layouts to align at the top with zero padding. Implemented cancelled quantities count rendering inside the items list status column cell. Updated the total quantity label below subtotal to dynamically sum non-header item quantities. Implemented purchase order cloning by passing target PO details to the create screen, stripping item IDs, clearing dates and order numbers, resetting cancelled quantities, and dynamically fetching the next auto-generated sequence number.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart`:
  - Positioned `_ExpectedDeliveryDateDialog` and `_CancelItemsDialog` to align at the top (`Alignment.topCenter`) with zero padding (`insetPadding: EdgeInsets.zero`).
  - Added cancelled quantity display (`X Canceled` in red color) in the items table status cell column if cancelledQuantity > 0.
  - Dynamically calculated non-header items quantity sum for the "Total Quantity" label in the detail summary panel.
  - Hooked up "Clone" action in options menu to redirect to create screen with `?clone=true` query parameter and pass the order details extra object.
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`:
  - Added `isClone` parameter to `PurchaseOrderCreateScreen` constructor.
  - Configured initialization state to pass `widget.isClone` flag to `_hydrateFromInitialOrder` and skip loading attachments when cloning.
  - Updated `_hydrateFromInitialOrder` to populate form inputs with original PO data while resetting dates to today, clearing PO number, reference number, and expected delivery date.
- `lib/modules/purchases/purchase_orders/notifiers/purchase_order_notifier.dart`:
  - Handled clone resets inside `hydrate` notifier state builder: mapped items list into new `PurchaseOrderItem` instances to clear item database IDs and reset cancelled quantities.
  - Reset PO number, reference, expected delivery date, and order date.
  - Dynamically reloaded purchase order settings to fetch and display the next available sequence code.

#### Backend Files
- `backend/drizzle/schema.ts`:
  - Added return type annotation `: any` to `countries` and `timezones` table constraint callback functions to break circular type dependency in TypeScript inference.

**Verifications**: Verified frontend code builds and compiles cleanly using `dart analyze lib/modules/purchases/`. Verified backend code compiles successfully using `npm run build` in `backend/` and TypeScript checks pass cleanly.

Timestamp of Log Update: June 11, 2026 - 10:25 AM (IST)

## 40. Purchase Order Creation Validation Fixes and Pricelist Autoload Removal (June 11, 2026)

### Summary
Fixed a validation error during purchase order creation caused by non-whitelisted properties in NestJS's strict white-listing configuration. Removed automatic price list selection when items are searched or selected in the purchase order line-item grid, defaulting rates to item cost prices instead.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_orders/notifiers/purchase_order_notifier.dart`:
  - Removed auto-selection and application of active price lists inside `selectProductForItem`. Item rates now default to the item's purchase cost price, and the price list selection remains empty (`null`) unless selected manually.

#### Backend Files
- `backend/src/modules/purchases/purchase-orders/dto/create-purchase-order.dto.ts`:
  - Added `@IsUUID() id` and `@IsNumber() cancelled_quantity` properties to `PurchaseOrderItemDto` to whitelist these fields, preventing NestJS's `forbidNonWhitelisted` validation pipe from throwing bad request exceptions on creation/modification.

**Verifications**: Verified frontend code compiles with `dart analyze lib/modules/purchases/` with zero errors. Verified backend code compiles successfully using `npm run build` in `backend/`.

Timestamp of Log Update: June 11, 2026 - 10:45 AM (IST)

## 41. Purchase Order Status Calculations and Indicator Balls Polish (June 11, 2026)

### Summary
Fixed the purchase order status logic to properly account for cancelled items when determining if an order is fully received. Implemented an automatic database update of the purchase order status in the backend whenever a purchase receive is created, updated, or removed. Polished the received column indicators in the purchase order list to display a half-filled orange circle for partially received orders, a solid green circle for fully received/closed orders, and a solid grey circle for yet-to-be-received orders.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart`:
  - In `_loadPoTxnSummary`, calculated `expectedTotalQuantity` by summing `item.quantity - item.cancelledQuantity` dynamically, and compared `totalReceived` against this value to determine the order's receive status.
  - In `_detailPane` (around line 2230), updated `isFullyReceived` check to sum received quantity from batches when available, and checked `totalReceivedForProduct < (poItem.quantity - poItem.cancelledQuantity) - 0.0001` to correctly account for cancelled items.
  - Center-aligned the "STATUS" column header in the items table and restored "Received" label (e.g. `26 pcs Received + 32 foc`).
  - In the main purchase orders table, updated the `received` column cells to dynamically display green, half-filled orange, or grey circles based on whether the order status is fully received (Closed/Received), partially received, or yet-to-be-received.

#### Backend Files
- `backend/src/modules/purchases/purchase-receives/services/purchase-receives.service.ts`:
  - Added a private helper `updatePurchaseOrderStatus` to dynamically sum non-cancelled items quantity and all received quantities (counting batches when present) for an order, and update the associated purchase order's database status to `Closed`, `Partially Received`, or `Issued` accordingly.
  - Called `updatePurchaseOrderStatus` on receive create, update, and remove (delete) database mutations.

**Verifications**: Verified backend code compiles successfully using `npm run build` in `backend/`. Verified frontend code compiles cleanly using `dart analyze lib/modules/purchases/purchase_orders` with zero warnings/errors.

Timestamp of Log Update: June 11, 2026 - 4:45 PM (IST)

## 42. Purchase Receive Details and Dynamic Bin Lookup Mappings (June 11, 2026)

### Summary
Enhanced purchase receives to correctly support typed receiving quantities, passing dynamic ordered limits to batch select popups, and loading transaction-level and row-level bin settings dynamically from the database. Scoped and mapped missing database properties for bill and transaction bin details. Reverted purchase orders overview items table status column back to standard left-alignment.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Unclamped Input**: Changed typed quantity row callbacks to allow entering any numeric input without clamping bounds.
  - **Dynamic Batch Limit**: Updated "Select Batch" visibility to check if quantity is `> 0` and `<= ordered`. Passed currently typed quantity as the `ordered` parameter to the batch dialog.
  - **Dynamic Bin Loading**: Swapped static Rack dropdown with dynamic DB load using `binsLookupProvider`.
  - **Saves Mapping**: Constructed purchase receive payload with bill fields, warehouse UUID, transaction bin UUID/label, and item bin mappings. Removed unused `_manualBinList` field.
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_edit.dart`:
  - **Bin Selection Parity**: Initialized transaction bin state from loaded data. Updated transaction-level and row-level bin dropdowns to dynamically resolve selected bin UUIDs.
  - **Saves Mapping**: Connected all bin properties to updated receive model prior to save.
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart`:
  - **Status Left-Alignment**: Reverted the center-alignment of STATUS column in PO overview items table back to left-alignment.
  - **Warning Cleanup**: Removed unused local variable `isFullyReceived`.

#### Backend Files
- `backend/src/db/schema.ts`:
  - **Schema Addition**: Appended `isDelete`, `billNo`, `billDate`, and `billInvoiceTotal` properties to the `purchaseReceives` database schema configuration.
- `backend/src/modules/purchases/purchase-receives/services/purchase-receives.service.ts`:
  - **Fields Mapping**: Corrected snake_case Supabase database parameters mappings (`transaction_bin_id`, `transaction_bin_label`, `bill_no`, `bill_date`, `bill_invoice_total`) on `create`, `update`, and `findOne`.

Timestamp of Log Update: June 11, 2026 - 10:20 PM (IST)

## 43. Purchase Receives defunct element setState bugfix (June 11, 2026)

### Summary
Fixed a widgets framework exception where disposing the create page threw a "setState() called on defunct element" assertion. Wrapped the file popup overlay dismissal routine with a widget mounting validation check.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Mounted Checks**: Wrapped `setState` inside `_hideFilePopupOverlay` with an `if (mounted)` check to prevent calling state updates on unmounted widgets.

Timestamp of Log Update: June 11, 2026 - 10:30 PM (IST)

## 44. RECEIVED and BILLED Column Status Indicator Progress Circles (June 11, 2026)

### Summary
Fixed the progress indicator circles under the RECEIVED and BILLED columns in the Purchase Order list screen. Implemented a backend batch-calculation query in the PurchaseOrdersService to determine receive and bill statuses based on associated items and transactions, and updated the Flutter PurchaseOrder model and cells builder to dynamically render the appropriate color and half/full circles.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart`:
  - Added `receiveStatus` and `billStatus` properties (defaulting to 'none') and updated `fromJson`, `toJson`, and `copyWith` accordingly.
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart`:
  - Updated `_buildCell` for column 'received' to render a grey circle, a half-filled orange circle, or a solid orange circle based on `order.receiveStatus`.
  - Updated `_buildCell` for column 'billed' to render a grey circle, a half-filled green circle, or a solid green circle based on `order.billStatus`.

#### Backend Files
- `backend/src/modules/purchases/purchase-orders/services/purchase-orders.service.ts`:
  - Implemented `attachProgressStatuses` helper method to batch fetch and compute expected, received, and billed quantities for POs.
  - Linked `attachProgressStatuses` in both `findAll` and `findOne` query routines.
  - Updated `mapDbToDto` to return calculated `receive_status` and `bill_status`.

Timestamp of Log Update: June 11, 2026 - 10:45 PM (IST)

## 45. Purchase Receives Manual Mode Received Quantities & Batch Dialog Visibility (June 11, 2026)

### Summary
Fixed manual mode row components on the Purchase Receives creation screen. Displayed the accumulated received quantities for PO items under the RECEIVED column when in manual mode. Restricted the 'Select Batch' button/link visibility to show only when quantity is less than or equal to the remaining unreceived quantity (ordered - received) in manual rows, mirroring the PO rows logic.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Received Column in Manual Mode**: Replaced empty `SizedBox()` placeholder with a `Text` widget in `_buildManualRow` to render `item.received` formatted to 0 or 2 decimal places if the item is linked to a PO.
  - **Batch Link Button Constraint**: Updated the visibility condition for the "Select Batch" link button in `_buildManualRow` to check `item.quantityToReceive <= (item.ordered - item.received)` instead of `item.ordered`.
  - **Warning Cleanup**: Removed redundant null/type checks (`if (response != null)` and `if (response is List)`) on the Supabase queries response in `_onPOSelected` to satisfy static analyzer rules.

Timestamp of Log Update: June 11, 2026 - 11:00 PM (IST)

## 46. Purchase Receives FOC Excluded from Quantity validation (June 11, 2026)

### Summary
Fixed the quantity mismatch validation and remaining quantity constraints when receiving items with FOC (Free of Cost) quantities. FOC items are no longer added to the line item's billed `quantityToReceive` constraint value. The quantity validation and the line item mismatch checks now compare only the billed/charged batch quantities, resolving the validation exception.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Save Mismatch Check**: Modified mismatch validator in `_handleSave` to sum only `b.quantity` (excluding `b.foc`) when comparing to `item.quantityToReceive`.
  - **Select Batch Dialog Save**: Modified `onSave` in the batch selector dialog route to sum `batch.quantity` only, setting it as `quantityToReceive`.
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_edit.dart`:
  - **Select Batch Dialog Save**: Synced `onSave` in the edit screen's batch dialog to sum `batch.quantity` only.

Timestamp of Log Update: June 11, 2026 - 11:18 PM (IST)


## 47. Consolidation of Purchase Receives Edit Page into Create Page (June 14, 2026)

### Summary
Consolidated the Purchase Receives edit and create workflows into a single unified file. Clicking "Edit" on a purchase receive now routes directly to the create screen, which dynamically loads the receive details, updates the form state, adjusts the page title, and saves/updates the receive via the API. The old edit page and its unused imports/warnings were completely cleaned up.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - **Dynamic Title Header**: Added _isEditMode detection and updated title header to show "Edit Purchase Receive" dynamically.
  - **Warehouse Selection Fallback**: Prioritized local _selectedWarehouseId over _selectedPO properties in _handleSave.
  - **API Save & Update Integration**: Integrated 
ef.read(purchaseReceivesProvider.notifier).updateReceive in _handleSave when _isEditMode is active.
  - **Cache Invalidation**: Added invalidation for purchaseReceiveByIdProvider upon successful update.
  - **Unused Elements Cleanup**: Removed _showFilePopup, _hoveredAttachmentIndex, _displayFilePopupOverlay, _hideFilePopupOverlay and associated variables/calls to keep the page warning-free.
- lib/app/routing/app_router.dart:
  - **Route Builder Redirection**: Updated purchaseReceivesEdit route path builder to instantiate PurchasesPurchaseReceivesCreateScreen(initialReceiveId: state.pathParameters['id']) directly.
  - **Unused Import Removal**: Removed import of presentation/purchases_purchase_receives_edit.dart.
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_edit.dart [DELETE]:
  - Removed edit page file from workspace directory as all edit page features are now handled inside the create page.
- lib/modules/purchases/purchase_receives/presentation/purchases_purchase_receives_edit.dart [DELETE]:
  - Removed unused presentation shim file.

Timestamp of Log Update: June 14, 2026 - 10:15 PM (IST)
  - **FOC Quantity Database Mapping**: Fixed FOC fields failing to load from database by updating BatchInfo.fromJson in purchases_purchase_receives_model.dart to check for foc_qty fallback.

## 48. Draft Bill Options, Convert to Open Status, and Automatic Purchase Receives Creation (June 15, 2026)

### Summary
1. Configured custom options toolbar and three-dots menu actions for Draft status bills. Added a green "Convert to Open" banner for draft bills and wired backend status transitions to automatically update stock quantities/layers.
2. Implemented automated Purchase Receives creation when marking a Bill or Purchase Order as "Received", specifically when none of the items require serial/batch/bin tracking (`track_batches` is false). Auto-increments purchase receive numbers sequentially.

### Detailed Engineering Changes

#### Backend Files
- backend/src/modules/purchases/bills/services/bills.service.ts:
  - **updateBillStatus**: Added check for transitions from draft/void to active status (e.g. open/paid) to call the new `applyStockForBill` stock mapping method.
  - **applyStockForBill**: Created this helper to query bill items and batches, insert/update batch stock layers, and create batch transactions dynamically, resolving stock discrepancies when converting draft bills.

#### Frontend Files
- lib/modules/purchases/bills/models/purchases_bills_bill_model.dart:
  - **PurchasesBillLineItem**: Added `trackBatches`, `trackSerialNumber`, and `trackBinLocation` fields to support checking for batch and serial tracking.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart:
  - **_menuChildrenForStatus**: Restricted options for draft bills to Void, Clone, Create Vendor Credits, and Delete.
  - **Toolbar actions**: Conditioned toolbar to show Edit, PDF/Print, Convert to Open, and Record Payment for draft status.
  - **_detailBanners**: Implemented a "Convert to Open" banner with a green button for draft bills.
  - **Mark as Received bulk action**: Added validation to check if any item has tracking enabled. If all items are untracked, automatically queries the next sequence number and inserts a corresponding `PurchaseReceive` record.
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart:
  - **Mark as Received (Single & Bulk actions)**: Added automated receive creation logic. If all items in a purchase order are untracked, generates the next PR number sequentially and creates a corresponding `PurchaseReceive` with status 'received'. Added null-safety check inside bulk action loop.

**Verifications**: Verified NestJS backend compiles cleanly via `npm run build` and Flutter frontend compiles successfully with `dart analyze`.

Timestamp of Log Update: June 15, 2026 - 1:40 PM (IST)

#### 49. Visual Adjustments, Bin Propagation, In-Transit Column, and Dropdown Scroll Adjustments (June 16, 2026)

### Summary
1. Removed visual boldness from item name description text and quantity input fields.
2. Increased thickness/boldness of decrement and increment control buttons using custom responsive container-based icons.
3. Enabled automatic propagation of transaction-level selected bin values down to item-level rows and models upon mode toggles.
4. Resolved empty cell rendering under "IN TRANSIT" column in manual rows by outputting the actual `inTransit` value.
5. Reduced scroll speed and item scroll count in all form-input dropdown overlays by intercepting and scaling down pointer scroll events.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - **_buildQtyControl**: Swapped `LucideIcons.minus` and `LucideIcons.plus` with custom Container and Stack designs to increase stroke line thickness dynamically.
  - **_buildQtyControl & _buildQtyInputField**: Replaced `FontWeight.w600` with `FontWeight.normal` to remove input text boldness.
  - **_buildItemRow & _buildManualRow**: Removed `FontWeight.w500` / `FontWeight.bold` from item name and description text and dropdown fields.
  - **_binMode toggles**: Propagated `_selectedTransactionBin` and its id to `_preferredBins` and line items when changing mode to `item` or selecting a bin in `transaction` mode.
  - **_buildManualRow**: Changed in-transit cell from empty `SizedBox()` to render `item.inTransit.toStringAsFixed`.
- lib/shared/widgets/inputs/dropdown_input.dart:
  - **FormDropdown**: Added custom `Listener` to intercept pointer scroll signals in `listBuilder` path, scaling the delta by 0.18.
  - **ListView & SingleChildScrollView**: Wrapped both scrolling paths inside `Listener` and configured `NeverScrollableScrollPhysics` to avoid native fast double-scrolling and ensure a controlled, slower scroll pace on all dropdown elements.

**Verifications**: Verified Flutter frontend compiles warning-free and analyzer checks pass successfully with `dart analyze`.

Timestamp of Log Update: June 16, 2026 - 2:30 PM (IST)

## 50. Expiry Date Picker Validation and Batch Card Text Wrapping in Purchase Receives (June 16, 2026)

### Summary
1. Disabled all past dates (before today) in the batch expiry date picker overlay to enforce validity.
2. Removed text truncation (ellipsis `...`) and added automatic soft wrapping for all values in the batch details info card.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - **_batchText**: Removed `maxLines: 1` and `overflow: TextOverflow.ellipsis` to support full item details text wrapping inside the batch card.
  - **_buildDatePicker (expDateCtrl)**: Configured `ZerpaiDatePicker.show` to accept `firstDate: DateTime(now.year, now.month, now.day)` to prevent selecting past dates.

**Verifications**: Verified Flutter frontend compiles warning-free and analyzer checks pass successfully with `dart analyze`.

Timestamp of Log Update: June 16, 2026 - 2:45 PM (IST)


## 51. Reusable Purchase Item Details Sidebar Overlay (June 16, 2026)

### Summary
Made the POItemDetailsSidebar widget reusable across all purchase pages by refactoring it to expose static `show` and `hide` methods that internally manage a global `OverlayEntry`. Integrated the sidebar into the purchase receives list panel, receives detail panel, and receive PDF viewer.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/widgets/po_item_details_sidebar_widget.dart:
  - **Reusable Overlay API**: Added static `show` and `hide` methods to construct and insert/remove `OverlayEntry` dynamically.
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart:
  - **Refactored overlay management**: Delegated `_showItemDetailsSidebar` directly to the new static `POItemDetailsSidebar.show` API. Added `POItemDetailsSidebar.hide()` to `dispose()` to clean up the overlay state.
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart:
  - **Refactored overlay management**: Delegated `_showItemDetailsSidebar` directly to the new static `POItemDetailsSidebar.show` API. Added `POItemDetailsSidebar.hide()` to `dispose()`.
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_list.dart:
  - **POItemDetailsSidebar Integration**: Changed the items table click handlers (inside detail panel accordion and standard list) to load dynamic `PurchaseOrderItem` rows and open the overlay-based details sidebar instead of the generic `ItemDetailsSidebar`.
  - **PDF View Integration**: Updated the items preview click handler inside the PDF View to open the `POItemDetailsSidebar` overlay.
  - **Cleanup**: Removed the unused generic `ItemDetailsSidebar` widget from scaffold `endDrawer` and imports.

**Verifications**: Verified Flutter frontend compiles warning-free and analyzer checks pass successfully with `dart analyze`.

Timestamp of Log Update: June 16, 2026 - 4:00 PM (IST)

## 52. Purchase Receive Redirection and Detail Panel Alignments (June 16, 2026)

### Summary
Redirected clicks on purchase receives numbers to the receives list view page with the corresponding receive item pre-selected. Adjusted metadata alignments in the receives detail panel by shifting the "VENDOR NAME" block left and the "PURCHASE ORDER#" / "DATE" blocks right.

### Detailed Engineering Changes

#### Frontend Files
- lib/app/routing/app_router.dart:
  - **Route Parameter Support**: Updated the `purchases/purchase-receives` route to extract the `id` query parameter and pass it as `initialSelectedId` to the list page widget.
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart:
  - **Redirect URL Modification**: Modified the clickable link on the purchase receives number within the PO details table/banner to navigate to `/$orgId/purchases/purchase-receives?id=${r['id']}` instead of redirecting to the edit screen.
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_list.dart:
  - **Constructor & State Initialization**: Added `initialSelectedId` to `PurchasesPurchaseReceivesListScreen` constructor and assigned it to `_activeReceiveId` in `initState` to pre-select the receive item on page load.
  - **Metadata Layout Spacing**: Shifted the "VENDOR NAME" block left in `_buildStandardView` by adding a `const SizedBox(width: 64)` after it. Shifted the "PURCHASE ORDER#" and "DATE" blocks right by increasing the spacing width between STATUS and PURCHASE ORDER# from `64` to `120`.

**Verifications**: Verified compilation using the `dart analyze` command. Both modified pages and the router analyzed successfully with zero errors.

Timestamp of Log Update: June 16, 2026 - 4:05 PM (IST)


## 53. Purchase Order In-Transit Status Color and 3-Dots Actions Support (June 16, 2026)

### Summary
1. Standardized "In Transit" status coloring to orange across purchase receive list row items, details, and PO list screen receives banner.
2. Fixed syntax error in the receives list page toolbar (Row children declaration list builder).
3. Removed unused `_onPOSelected` method in `purchases_purchase_receives_create.dart`.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_list.dart:
  - **Toolbar children layout syntax fix**: Updated `receiveAsync.when` data builder to use a block body instead of an inline expression. Pre-computed `currentStatus` and wrapped conditional action buttons in standard collection-if syntax to satisfy the dart compiler.
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - **Cleanup**: Deleted unused private helper `_onPOSelected` method which was superseded by the multiselect PO dropdown implementation.
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart:
  - **Receives Banner Status Color**: Updated the receive status text color mapping inside the PO receives banner to render in orange (`AppTheme.warningOrange`) if status is "In Transit" or "intransit" instead of default grey.

**Verifications**: Verified compilation using the `dart analyze` command. All modified files analyzed successfully with zero errors.

Timestamp of Log Update: June 16, 2026 - 4:15 PM (IST)


## 54. Implementation of Mark as Received for In-Transit Purchases (June 16, 2026)

### Summary
Implemented the "Mark as Received" dropdown action button handler in the purchase orders list screen detail panel to support purchase orders with in-transit receives. Instead of failing on tracked items check or creating a duplicate receive, it fetches and marks existing associated in-transit receive records as received in the database and updates the purchase order status.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart:
  - **Mark as Received Action**: Refactored `_detailActionMenuItem` to identify existing in-transit receives from `summary.receives`. If present, it updates them to `'received'` status using `purchaseReceiveRepositoryProvider.updatePurchaseReceive` and updates the purchase order status to `'Closed'` in the database without throwing a tracked items validation error.

**Verifications**: Verified compilation using the `dart analyze` command. The page analyzed successfully with zero errors.

Timestamp of Log Update: June 16, 2026 - 4:30 PM (IST)


## 54. Filter Out In-Transit Receives from Purchase Order Received Quantities (June 16, 2026)

### Summary
Fixed the purchase order 3-dots action menu dropdown logic where purchase orders with active "In Transit" receives were incorrectly treated as fully received, hiding expected actions. 

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart:
  - **_isAllItemsReceived Filter**: Modified the receive row loop in `_isAllItemsReceived` to skip summation of item quantities if the receive status is not exactly `'received'` (i.e. skipping `'intransit'` or `'draft'`). This prevents in-transit receives from incorrectly marking the parent purchase order as fully received, which resolves the 3-dots action menu displaying the correct standard actions instead of only the fully received actions.

**Verifications**: Verified compilation using the `dart analyze` command. All modified files analyzed successfully with zero errors.

Timestamp of Log Update: June 16, 2026 - 4:55 PM (IST)


## 55. Case-Insensitive String Check in PO 3-Dots Dropdown Options (June 16, 2026)

### Summary
Fixed a casing mismatch bug in the `isTransitYetBilled` conditional check inside the purchase order 3-dots action menu dropdown builder. This resolves the dropdown menu displaying only 3 items instead of the expected 6 items when the receive status is "In Transit" and the bill status is "Yet to be Billed".

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart:
  - **Case-Insensitive Options Check**: Updated the `isTransitYetBilled` boolean assignment in `_menuChildrenForStatus` to compare lowercased status string values (`summary.receiveStatus.toLowerCase()` and `summary.billStatus.toLowerCase()`) rather than strict camel-cased literals, preventing casing mismatches like `'Yet to be Billed' == 'Yet To Be Billed'` from failing.

**Verifications**: Verified compilation using the `dart analyze` command. All modified files analyzed successfully with zero errors.

Timestamp of Log Update: June 16, 2026 - 5:05 PM (IST)


## 56. Bill Item Amount Calculation & Validation Updates (June 16, 2026)

### Summary
Fixed the line item amount calculation on the Purchases Bills creation screen (purchases_bills_create.dart) to ignore free-of-charge (FOC) quantities. Amount calculations are now strictly based on charged quantities. Also removed mandatory customer ID validation on bill items.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Quantity Resolvers**: Refactored the quantity getter on _BillLineItemRow to sum 'qtyOut' values from selected batches (charged quantity only) instead of returning quantityCtrl.text (which contains totalQty + totalFoc). Added a corresponding freeQuantity getter.
  - **Validation Updates**: Removed mandatory customer selection validation block on bill items.
  - **Load Updates**: Configured _loadBillForEdit to set quantityCtrl.text to the sum of loaded batch charged quantity and FOC quantity.

**Verifications**: Verified compilation using the dart analyze command.

Timestamp of Log Update: June 16, 2026 - 7:15 PM (IST)


## 57. Reverse Charge Tax Exclusion in Bills & Purchase Orders (June 16, 2026)

### Summary
Excluded tax calculation from purchase order and bill totals when 'This transaction is applicable for reverse charge' is checked.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Reverse Charge Tax Check**: Configured _taxAmount getter to return 0.0 if _reverseCharge is true, immediately excluding tax from UI totals and model saves.
- lib/modules/purchases/purchase_orders/notifiers/purchase_order_notifier.dart:
  - **PO State calculations**: Configured taxAmount getter in PurchaseOrderState to return 0.0 when isReverseCharge is true.
  - **Item calculation check**: Configured _recalculateItem to calculate item tax amount as 0.0 when isReverseCharge is true. Updated updateField trigger criteria to run recalculations when isReverseCharge toggles.

**Verifications**: Verified compilation using the dart analyze command.

Timestamp of Log Update: June 16, 2026 - 7:20 PM (IST)

## 58. Custom Detailed Batch Dropdown in Purchases & Receives Dialog (June 16, 2026)

### Summary
Replaced standard batch autocomplete with rich custom dropdown list inside the SelectBatchDialog.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - **SelectBatchDialog dropdown**: Swapped RawAutocomplete<String> for FormDropdown<Map<String, dynamic>>.
  - **Batch info mapping**: Transformed sorted batch options to list of maps with attributes (balance, expiry_date, mrp, prate).
  - **Custom list rendering**: Structured dropdown items list with visual highlights, hover effects, search, and dynamic heights.

**Verifications**: Verified compilation using the dart analyze command.

Timestamp of Log Update: June 16, 2026 - 7:25 PM (IST)

## 59. Pack Size Alphanumeric Resolution, PO Load Improvements, and Receive-to-Bill Conversion Enhancements (June 17, 2026)

### Summary
1. Resolved the Pack Size field inside the Select Batch Dialog to load the human-readable `pack_name` string from database lookups instead of UUIDs, and updated the field to accept alphanumeric/varchar string values.
2. Updated the open Purchase Orders selection popup in the Bills creation page to automatically display batch information inline immediately upon item load.
3. Enhanced the Purchase Receive to Bill conversion workflow to correctly load bill number, date, and invoice total values, resolve state UUIDs into formatted names, fix incorrect subject defaults, and enforce invoice total as a mandatory field with validations.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - **Alphanumeric Pack Size Support**: Removed numeric input formatters and parsing checks from `unitPackCtrl` inside the Select Batch Dialog.
  - **Dynamic Pack Size Name Resolver**: Fetched `unit_pack_id` from the products lookup and mapped it to the actual `pack_name` string from `product_pack_sizes` lookup before showing the dialog.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **State Name Resolver**: Added a `_stateIdMap` state variable and a `_resolveStateName` utility method inside `_PurchasesBillCreateScreenState` to dynamically translate UUID-based states from the vendor registry or PO shipment preferences to readable formatted strings (e.g. `[KL] - Kerala`).
  - **Conversion Fields Loading**: Loaded the `billNo`, `billDate`, and `invoiceTotal` from the source Purchase Receive model.
  - **Corrected Subject Default**: Changed the default subject value when converting a receive to load from the parent purchase order's reference number instead of showing the receive's tracking number.
  - **Mandatory Invoice Total**: Swapped the plain text label for `Invoice Total` to a RichText element with a red asterisk (`*`), and added presence/greater-than-zero validation blocks on save.
  - **Automatic Batch Info Display**: Set `row.showAdditionalInfo = true` on lines loaded via `_addItemsFromMultiplePurchaseOrders`, `_loadPoForConvert`, and `_loadReceiveForConvert`, making batch/expiry input controls visible immediately.

**Verifications**: Verified compilation using the `dart analyze` command.

Timestamp of Log Update: June 17, 2026 - 12:40 PM (IST)

## 60. Place of Supply Conversion Fixes and Backend Bills Schema Mapping (June 17, 2026)

### Summary
1. Resolved place of supply conversion UUID display issue when converting Purchase Receives or Purchase Orders to Bills: defaulted Source/Destination of Supply state fields to the Vendor's resolved state name string (e.g. `[KL] - Kerala`) instead of carrier preference UUIDs.
2. Added schema definitions and service mapping for `source_of_supply`, `destination_to_supply`, and `billing_address` columns in the backend `bills` table to align with database updates.

### Detailed Engineering Changes

#### Backend Files
- backend/src/db/schema.ts & backend/drizzle/schema.ts:
  - **Schema definition**: Added `sourceOfSupply` (source_of_supply), `destinationToSupply` (destination_to_supply), and `billingAddress` (billing_address) fields to `bills` pgTable definition.
- backend/src/modules/purchases/bills/dto/create-bill.dto.ts:
  - **CreateBillDto**: Added optional `sourceOfSupply`, `destinationToSupply`, and `billingAddress` string properties.
- backend/src/modules/purchases/bills/services/bills.service.ts:
  - **createBill & updateBill**: Mapped new DTO parameters directly to database columns.

#### Frontend Files
- lib/modules/purchases/bills/models/purchases_bills_bill_model.dart:
  - **PurchasesBill Model**: Defined `sourceOfSupply`, `destinationToSupply`, and `billingAddress` properties, mapped them in `fromJson`, and added serializations to `toJson`.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Conversion mappings**: Removed shipment preference UUID overrides and mapped `resolvedState` directly to `_sourceOfSupply` and `_destinationOfSupply` inside `_loadReceiveForConvert` and `_loadPoForConvert`.
  - **Billing Address Resolver**: Added default billing address UUID extraction logic from `vendorAddresses` and passed it when constructing a `PurchasesBill` model during save.

**Verifications**: Verified NestJS backend compiles cleanly via `npm run build` and Flutter frontend compiles successfully with `dart analyze`.

Timestamp of Log Update: June 17, 2026 - 2:00 PM (IST)

## 61. Autoload Vendor Address & Payment Terms in Bill Conversions (June 17, 2026)

### Summary
1. Configured automatic loading of vendor payment terms and billing address availability (`_hasAddress` / `_paymentTerms`) when converting Purchase Receives or Purchase Orders to Bills. This ensures values match exactly what is autoloaded when manually selecting a vendor on the Bills creation screen.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Autoload details**: Integrated `_hasAddress`, `_paymentTerms`, and `_customBillingAddress = null` initialization inside both `_loadReceiveForConvert` and `_loadPoForConvert` workflows.

**Verifications**: Verified Flutter frontend compiles successfully with `dart analyze`.

Timestamp of Log Update: June 17, 2026 - 2:10 PM (IST)

## 62. Vendor Full Fetch & State Resolution Fixes on Bill Conversion (June 17, 2026)

### Summary
Fixed vendor details rendering issues (billing address, GST treatment, GSTIN) and Place of Supply defaults when converting Purchase Receives, Purchase Orders, or editing Bills. Resolved the issue where a vendor might not be found in the memory-cached/paged list by dynamically fetching the full Vendor object from the backend database repository. Improved the state resolution algorithm to perform clean fuzzy matching of state names.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - **Dynamic Vendor Fetch**: Updated `_loadBillForEdit`, `_loadReceiveForConvert`, and `_loadPoForConvert` to query `vendorRepositoryProvider`'s `getVendorById` if the vendor is not present in the Riverpod-cached/paged list or if it falls back to a dummy placeholder. This ensures billingAddress, GST treatment, and GSTIN are correctly initialized and displayed instead of hidden or hardcoded.
  - **State Name Resolution Refinement**: Enhanced `_resolveStateName` method to strip bracketed codes (like `[MH] - `) and extra strings (like zip/pin codes) to perform clean fuzzy matching against state lists. This prevents falling back to default states like Bihar when the state name in the billing address is not exactly formatted.

#### Backend Files
- None

Timestamp of Log Update: June 17, 2026 - 02:55 PM (IST)

## 63. Vendor Matching by Display Name on Bill Conversions (June 17, 2026)

### Summary
Fixed vendor details autoloading (billing address, GST treatment, GSTIN) on Bill Conversion when the source purchase receive lacks a `vendorId` in the database. Enabled matching the converted vendor to the local state list by `displayName` in addition to `vendorId`, ensuring all vendor-related details are resolved and rendered exactly like manual dropdown selections.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - **Fuzzy Name Matching**: Updated `_loadBillForEdit`, `_loadReceiveForConvert`, and `_loadPoForConvert` to search by `displayName` (case-insensitively) as a fallback if `vendorId` matching fails. This ensures the correct vendor object is matched and assigned to `_selectedVendor`.

#### Backend Files
- None

Timestamp of Log Update: June 17, 2026 - 03:06 PM (IST)

## 64. Recalculate Batch Quantity and Sync PO Details (June 17, 2026)

### Summary
Fixed the issue where the "Save as Open" button was disabled when converting a Purchase Receive to a Bill, by ensuring the total line item quantity is correctly recalculated based on the sum of active batch quantities (including FOC). Added complete mapping and auto-loading of purchase order level details (discount type, discount level, adjustment, payment terms, TDS/TCS type and rates) when associating a purchase order from the open POs selection modal.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - **Batch Quantity Recalculation**: Updated both `po != null` and `po == null` branches in `_loadReceiveForConvert` to calculate and update `quantityCtrl.text` with the sum of batch `qtyOut` and `foc` values. This ensures the line item input quantity exactly equals the total batch quantity, allowing the "Save as Open" button validator to enable the button.
  - **Purchase Order Details Sync**: Added PO-level properties copy logic to `_addItemsFromMultiplePurchaseOrders`. It now maps notes, subject reference, warehouse name, payment terms, discount level, discount percent/type, reverse charge, adjustment amount, and TDS/TCS types and rates when a PO is associated.

#### Backend Files
- None

Timestamp of Log Update: June 17, 2026 - 03:00 PM (IST)

## 65. Batch Selection FOC Hint and Save Redirect (June 18, 2026)

### Summary
1. Configured the batch selection dialog's FOC text field to display "0" as a hint text instead of as an initial text value.
2. Updated the successful save/received callback route redirection logic to navigate directly to the detailed view page of the newly created/saved Purchase Receive.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **FOC Hint Logic**: Updated `_BatchItemRowController` initialization to not pre-fill `focCtrl.text` with "0" when the value is 0, allowing the TextField's placeholder hint "0" to render instead.
  - **Redirect Handler**: Modified `_handleSave` success callback to route directly to `/purchases/purchase-receives?id=${savedReceive.id}` upon status == `'received'`.

#### Backend Files
- None

Timestamp of Log Update: June 18, 2026 - 12:58 PM (IST)



## 73. Fix Multi-PO Selection Blank Items Table Bug (June 20, 2026)

### Summary
1. Resolved a critical bug where selecting multiple Purchase Orders (POs) caused the unbilled items table to display as empty.
2. The root cause was unscoped billed quantity calculation (`itemBilledQty` map) that aggregated quantities globally by `productId` across all POs. This caused billed quantities from one PO to exceed the remaining unbilled quantities of other POs, masking visible items.
3. Modified the Supabase query to retrieve `order_number` from the `bills` table and mapped the correct `purchaseOrderId` to each bill item.
4. Scoped the `itemBilledQty` calculation using composite `"$purchaseOrderId-$productId"` keys, ensuring each PO item is evaluated only against its own associated bills.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - **Bills Query Expansion**: Added `order_number` to the `.select(...)` statement inside `_onPOsSelected`.
  - **Correct PO Association**: Replaced the hardcoded/unscoped `pos.first.id` with a matching `PurchaseOrder` search loop based on `order_number`.
  - **Scoped Billed Aggregation**: Keyed the `itemBilledQty` calculation map using `"$poId-$productId"` composite keys instead of just `productId` inside `_buildItemsTableNormal()`, scoping unbilled check strictly per PO.

#### Backend Files
- None

Timestamp of Log Update: June 20, 2026 - 02:00 PM (IST)


## 30. Standardized Dropdown Dividers & SD- Deletion Prefixes (June 20, 2026)

### Summary
Enhanced the Item/Product search dropdown menus across five modules to render horizontal divider lines separating lookup options. Integrated a deletion document numbering prefix system whereby soft-deleted records have their transaction/document number prepended with 'SD-' across both Flutter front-end list interfaces and NestJS backend repositories.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart:
  - Added bottom border/divider highlights to standard item dropdown list rows.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - Added bottom border/divider highlights to standard item dropdown list rows.
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - Implemented bottom border/divider styling on custom dropdown option builder rows.
- lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart:
  - Implemented bottom border/divider styling on custom dropdown option builder rows.
- lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart:
  - Configured divider highlights on inline item dropdown list option widgets.
- lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart:
  - Updated single and bulk deletion routines to prepend 'SD-' to 'sale_number' values during Supabase soft-deletion updates.
- lib/modules/sales/invoices/presentation/pages/sales_invoice_list.dart:
  - Updated single and bulk deletion routines to prepend 'SD-' to 'sale_number' values during Supabase soft-deletion updates.
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart:
  - Programmed both single and bulk soft-delete actions to query existing order numbers and prefix them with 'SD-' prior to updating the database.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart:
  - Refactored single and bulk soft-delete actions to query existing bill numbers and prefix them with 'SD-' prior to updating the database.

#### Backend Files
- backend/src/modules/purchases/purchase-receives/services/purchase-receives.service.ts:
  - Verified and ensured existing backend service prepends 'SD-' to 'purchase_receive_number' on entity removal.
- backend/src/modules/purchases/purchase-orders/services/purchase-orders.service.ts:
  - Verified and ensured existing backend service prepends 'SD-' to 'order_number' on entity removal.
- backend/src/modules/purchases/bills/services/bills.service.ts:
  - Verified and ensured existing backend service prepends 'SD-' to 'bill_number' on entity removal.

Timestamp of Log Update: June 20, 2026 - 5:25 PM (IST)


## 31. Purchases Bills Adaptive Row Menu Positioning (June 21, 2026)

### Summary
Refactored the three-dots row action menu in Purchases Bills creation (purchases_bills_create.dart) to use ZAdaptiveMenu.show. This ensures the dropdown options dynamically check available viewport height and automatically open upwards or downwards to prevent screen clipping at the bottom.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - Replaced manual OverlayEntry and CompositedTransformFollower with ZAdaptiveMenu.show in _showItemMenu.
  - Removed manual Overlay.insert invocation since ZAdaptiveMenu.show handles insertion internally.

Timestamp of Log Update: June 21, 2026 - 3:35 PM (IST)

## 32. Purchase Receive Billing Status Query Case Sensitivity Fix (June 21, 2026)

### Summary
1. Resolved a critical issue where the billing status circle for Purchase Receives displayed as "none" (grey circle) despite bills being successfully created.
2. The root cause was that the backend queries for associated bills filtered by `source_type = "PURCHASE_RECEIVE"` case-sensitively, whereas the database stored `'purchase_receive'` in lowercase as sent by the client.
3. Updated the backend service query to search for `source_type` in both cases, as well as with dashes (e.g., `purchase-receive`).
4. Fixed the frontend view filter to query `r.billStatus` dynamically instead of using the static `r.billed` boolean.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_list.dart`:
  - **Dynamic View Filter**: Changed the filter conditions for "Billed" and "Partially Billed" from `r.billed` to inspect `r.billStatus` using the correct string mappings (`full`, `billed`, `partial`, `partially_billed`, `partially billed`).

#### Backend Files
- `backend/src/modules/purchases/purchase-receives/services/purchase-receives.service.ts`:
  - **Case-Insensitive source_type Filter**: Refactored database queries filtering bills for purchase receives to search for `source_type` inside a list of valid matches (`["PURCHASE_RECEIVE", "purchase_receive", "purchase-receive", "PURCHASE-RECEIVE"]`) using Supabase's `.in()` operator.

Timestamp of Log Update: June 21, 2026 - 11:30 PM (IST)


## 33. Purchase Order UUID Parsing Bugfix (June 22, 2026)

### Summary
1. Resolved a critical 500 error when saving a Purchase Order: `invalid input syntax for type uuid: ""`.
2. The issue was caused by the frontend sending empty string values `""` for unselected fields (like `tds_id`, `shipping_address`, `billing_address`, etc.), which the NestJS backend did not sanitize before querying PostgreSQL.
3. Implemented a `cleanUuid` sanitization utility in the backend to convert empty strings, undefined, and null values to database `null`.
4. Applied the sanitization to all UUID fields inside `mapDtoToDb`, `create`, and `update` logic in `purchase-orders.service.ts`.

### Detailed Engineering Changes

#### Frontend Files
- None

#### Backend Files
- `backend/src/modules/purchases/purchase-orders/services/purchase-orders.service.ts`:
  - Added `cleanUuid` helper method.
  - Sanitized primary PO fields (`vendor_id`, `payment_terms_id`, `shipment_preference_id`, `delivery_warehouse_id`, `delivery_customer_id`, `warehouse_id`, `tds_id`, `discount_account_id`, `shipping_address`, `billing_address`).
  - Sanitized line item fields (`product_id`, `account_id`, `accounts`, `tax_id`).
  - Refactored `warehouse_id` resolution checking logic to clean DTO values first.

Timestamp of Log Update: June 22, 2026 - 08:50 AM (IST)

## 34. Sales Order MRP and Auto-Calculation Fixes (June 22, 2026)

### Summary
1. Resolved a critical issue in Sales Order creation where entering an item Rate or selecting a batch did not automatically compute or validate the MRP rate.
2. Configured the MRP column to auto-fill based on the selected batch's MRP, or fallback to the product's master MRP rate.
3. Implemented a fallback validation to auto-select the first batch and bin location if only one batch is available when selecting an item.
4. Cleaned up unused variables and unused color constants, ensuring 100% clean frontend compilation and static analysis.

### Detailed Engineering Changes

#### Frontend Files
- [sales_order_create.dart](file:///C:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart):
  - **Batch Auto-selection and Fallback**: Updated item selection logic to auto-select the first batch and bin when an item has exactly one batch available.
  - **MRP Auto-Calculation**: Configured mrpCtrl.text to automatically populate with the selected batch's MRP value, falling back to the item's master MRP value if not present.
  - **Unused Color Constant Removal**: Removed the unused private _kGreen color constant to resolve static analysis warning.

#### Backend Files
- None

**Verifications**: Verified Flutter frontend compiles successfully with dart analyze and NestJS backend builds cleanly with 
pm run build.

Timestamp of Log Update: June 22, 2026 - 10:05 AM (IST)

## 35. Dynamic Overlays and Duplicate Item Warnings Row Numbers (June 22, 2026)

### Summary
1. Migrated account selection and row action overlays in sales orders and sales invoices to `ZAdaptiveMenu.show` to support dynamic scroll-aware and space-aware layout positioning (flipping above or below the anchor based on viewport boundaries).
2. Extended `ZAdaptiveMenu` class to support left-alignment (`alignLeft: true`) for left-anchored form inputs.
3. Implemented row-specific duplicate item selection warnings in purchase bills and purchase orders create pages, matching Zoho-style exact warnings.

### Detailed Engineering Changes

#### Frontend Files
- [z_adaptive_menu.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/z_adaptive_menu.dart):
  - Added support for left alignment with anchors setting to `topLeft`/`bottomLeft` depending on vertical scroll metrics.
- [sales_order_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart) & [sales_invoice_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart):
  - Refactored `_toggleAccountsOverlay` and `_toggleRowActionsOverlay` to use `ZAdaptiveMenu.show`.
  - Simplified `_AccountSelectionPopover` to delegate outer box decorations to the adaptive menu shell.
- [purchases_bills_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart) & [purchases_purchase_orders_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart):
  - Added item selection duplicate validation on item dropdown onChanged callback to warn users using row-specific indexes.

**Verifications**: Verified compilation using dart analyze. No static warnings or compile errors remain.

Timestamp of Log Update: June 22, 2026 - 01:25 PM (IST)


## 36. Accounts Popover UI Padding and Scrollbar Dragging Fixes (June 22, 2026)

### Summary
1. Restored the default edge-to-edge layout for the Accounts popover menu by removing the default 8px padding introduced by ZAdaptiveMenu.
2. Restored draggable scrollbars inside all dropdown overlays (FormDropdown) by replacing NeverScrollableScrollPhysics with ClampingScrollPhysics and removing custom mouse pointer listener overrides that hijacked native scroll physics.
3. Cleaned up static analysis warnings by removing the unused package:flutter/gestures.dart import from dropdown_input.dart.

### Detailed Engineering Changes

#### Frontend Files
- [z_adaptive_menu.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/z_adaptive_menu.dart):
  - Added support for an optional padding parameter in the show method, which defaults to const EdgeInsets.all(8).
- [sales_order_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart) & [sales_invoice_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart):
  - Updated _toggleAccountsOverlay to pass padding: EdgeInsets.zero and orderRadius: 8 into ZAdaptiveMenu.show, restoring the flush edge-to-edge table styling.
- [dropdown_input.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/inputs/dropdown_input.dart):
  - Swapped physics: const NeverScrollableScrollPhysics() to physics: const ClampingScrollPhysics() inside the dropdown selection overlay list views (both custom listBuilder and default ListView).
  - Removed manual Listener blocks capturing pointer scroll events to resolve interaction blocks.
  - Removed unused package:flutter/gestures.dart import.

#### Backend Files
- None

**Verifications**: Verified that the modified files compile cleanly using dart analyze.

Timestamp of Log Update: June 22, 2026 - 02:15 PM (IST)

## 37. Sales Item Row Hover Actions and Unregistered GST Tax Customizations (June 22, 2026)

### Summary
1. Restructured row interactions in the item details tables of Sales Orders and Sales Invoices: row actions (3-dots and 'X' delete buttons) now only display when hovering over the row.
2. Formatted header rows to completely hide the row actions column (3-dots and 'X' delete buttons) and omit the additional details/reporting tags footer banner.
3. Removed static outlines from the tax selection dropdowns in the item row, replacing them with a borderless state that only displays a blue focus outline upon hover.
4. Set the tax dropdown cell to read-only and display no selected value ('Select Tax') when the active customer's GST registration status is unregistered. Added a close button on hover to clear any selected tax.

### Detailed Engineering Changes

#### Frontend Files
- [sales_order_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart) & [sales_invoice_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart):
  - Added stateful hover tracking variables (_hoveredRowIndex) and getter (_isCustomerUnregistered) to check customer GST treatment status.
  - Wrapped each item row widget inside a MouseRegion to trigger the active hover state.
  - Set the actions cell to show actions only when _hoveredRowIndex == idx and !row.isHeader.
  - Added conditional check to prevent rendering the additional details/reporting tags banner on header rows (!row.isHeader).
  - Swapped the tax dropdown container decoration to utilize a transparent border by default, showing a blue border only on hover when active.
  - Set the tax cell onTap gesture detector callback to null if _isCustomerUnregistered is true, displaying 'Select Tax' with grey text and hiding the dropdown icon.
  - Added a hover-triggered close icon inside the tax cell row when a tax rate is selected to allow clearing it.
  - Updated _calculateTotals to omit row tax calculations if _isCustomerUnregistered evaluates to true.

#### Backend Files
- None

**Verifications**: Verified compilation using targeted static analysis (dart analyze).

Timestamp of Log Update: June 22, 2026 - 02:45 PM (IST)

## 38. ReorderableListView Key Assertion Fix (June 22, 2026)

### Summary
1. Resolved a runtime assertion crash in the item detail tables of Sales Orders and Sales Invoices: Assertion failed: Every item of ReorderableListView must have a key.
2. Replaced key mapping assignments to ensure the top-level returned widget from the list's itemBuilder (MouseRegion) receives the item's ValueKey instead of delegation to its child Column widget.

### Detailed Engineering Changes

#### Frontend Files
- [sales_order_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart) & [sales_invoice_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart):
  - Moved the key parameter assignment from the inner Column to the top-level returned MouseRegion widget in the _buildItemRow method.

#### Backend Files
- None

**Verifications**: Verified compilation using static analysis (dart analyze).

Timestamp of Log Update: June 22, 2026 - 03:00 PM (IST)

## 39. Sales Table Vertical Dividers and Auto-Append Item Rows (June 22, 2026)

### Summary
1. Enhanced the layout of Sales Order and Sales Invoice item tables by introducing a vertical separator line between the left-most drag handle / checkbox column and the main content columns.
2. Implemented an auto-appended blank row UX: when selecting a product in the final row of the items table, a new blank row is appended automatically.

### Detailed Engineering Changes

#### Frontend Files
- [sales_order_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart) & [sales_invoice_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart):
  - Inserted _vLine() into the table header column collection directly after the left-most drag handle space.
  - Inserted _vLine() inside the _buildItemRow column collection directly after the drag handle widget column.
  - Updated the onChanged item select dropdown callback to check if idx == rows.length - 1. If so, a new row is appended using ows.add(_createItemRow()).

#### Backend Files
- None

**Verifications**: Verified compilation using static analysis (dart analyze).

Timestamp of Log Update: June 22, 2026 - 03:15 PM (IST)

## 40. Procurement Module Enablement & Warehouse Popover Default Stock Selection (June 23, 2026)

### Summary
1. Standardized the Warehouse Locations popover default stock selection to "Physical Stock" instead of "Accounting Stock" across the ERP.
2. Reduced the dropdown list container width in the popover overlay from 160 to 130 for a tighter, cleaner alignment.
3. Enabled and registered the Procurement module in the frontend sidebar navigation and GoRouter configurations, making it accessible with "Purchase Requests" and "Approvals" menu items.

### Detailed Engineering Changes

#### Frontend Files
- [warehouse_popover.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/inputs/warehouse_popover.dart):
  - Reduced the dropdown list container width from 160 to 130.
  - Changed the fallback default value of selectedStockType to 'Physical'.
- [sales_order_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart):
  - Initialized _selectedStockType state variable to 'Physical'.
- [sales_invoice_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart):
  - Initialized _selectedStockType state variable to 'Physical'.
- [app_routes.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/core/routing/app_routes.dart):
  - Defined route constant strings: procurementPurchaseRequests, procurementPurchaseRequestsCreate, procurementPurchaseRequestOverview, procurementRequestedItems, procurementApprovals, procurementApprovalsOverview.
- [app_router.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/app/routing/app_router.dart):
  - Imported procurement page widgets and registered GoRouter routes under the nested /:orgSystemId ShellRoute.
- [navigation_registry.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/app/navigation/navigation_registry.dart):
  - Appended the 'procurement' module configuration containing "Purchase Requests" and "Approvals" NavItems to the registry.
- [sidebar_builder.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/app/navigation/sidebar_builder.dart):
  - Added prefix route matching rule for '/procurement/' to resolve Procurement parent leaf menu label in the sidebar.

#### Backend Files
- None

**Verifications**: Verified compilation using static analysis (dart analyze).

Timestamp of Log Update: June 23, 2026 - 11:15 AM (IST)

## 41. Routing Duplicates and Procurement Provider Fixes (June 23, 2026)

### Summary
1. Resolved multiple compilation errors in the routing file by removing redundant/duplicated static route constant declarations.
2. Fixed a compilation error in the Procurement Demand Pool dialog by resolving the undefined `supabaseUsersProvider` reference to the correct `allUsersProvider` from auth module.

### Detailed Engineering Changes

#### Frontend Files
- [app_routes.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/core/routing/app_routes.dart):
  - Removed duplicate route constants declared twice for `bills`, `reports`, `accountsChartOfAccounts`, and `accountantManualJournals` structures.
- [procurement_demand_pool_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/procurement/purchase_request/presentation/pages/procurement_demand_pool_dialog.dart):
  - Substituted the nonexistent `supabaseUsersProvider` with `allUsersProvider` to watch the users list state.

#### Backend Files
- None

**Verifications**: Verified by reviewing active build logs.

Timestamp of Log Update: June 23, 2026 - 12:35 PM (IST)

## 42. Procurement Sidebar Position and Quick-Add (June 23, 2026)

### Summary
1. Moved the Procurement module above the Accountant module in the sidebar configuration.
2. Enabled the quick-add `+` button in the sidebar for "Purchase Requests" to directly navigate to the request creation page.

### Detailed Engineering Changes

#### Frontend Files
- [navigation_registry.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/app/navigation/navigation_registry.dart):
  - Moved the `procurement` AppModule block above the `accountant` AppModule.
  - Assigned `permissionKey: 'purchase_requests'` to the "Purchase Requests" AppNavItem.
- [permission_registry.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/core/auth/permission_registry.dart):
  - Added `'purchase_requests'` mapping to `legacyPermissionPrefixesByKey` targeting `procurement.purchase_request`.
  - Registered `procurement.purchase_request.view` and `procurement.purchase_request.create` definitions in `permissionsRegistry`.

#### Backend Files
- None

**Verifications**: Verified compilation.

Timestamp of Log Update: June 23, 2026 - 12:50 PM (IST)

## 43. PO Vendor Address Restricting and Modal Title Fix (June 23, 2026)

### Summary
1. Set the header of the address editor popup box to explicitly show "Billing Address" or "Shipping Address" depending on the context being edited.
2. Restructured editing accessibility: shipping-only addresses in the billing address dropdown list cannot be edited, and billing-only addresses in the shipping address dropdown list cannot be edited.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_purchase_orders_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart):
  - Updated `_showAddressDropdownList` to pass `isBilling ? 'Billing Address' : 'Shipping Address'` as customTitle to `_showAddressModal`.
  - Updated `_buildAddressDropdownItem` to calculate edit accessibility by checking the address flags (`is_default_billing`, `is_default_shipping`) vs the active dropdown context (`isBilling`).
  - Added conditional checks to only render and trigger the edit pencil icon when `canEdit` is true, and pass the explicit context title.

#### Backend Files
- None

**Verifications**: Verified compilation.

Timestamp of Log Update: June 23, 2026 - 02:15 PM (IST)

## 44. Billing & Shipping Address Creation and Edit Standardization (June 23, 2026)

### Summary
1. Verified address editor title formatting and editing restrictions on Purchases Bills, Sales Invoices, and Sales Orders creation pages to ensure complete alignment with vendor address rules.
2. Restructured address editor header rendering to dynamically show "Billing Address" or "Shipping Address" depending on the target edit context.
3. Verified editing accessibility flow for customer models on Sales screens where single addresses are resolved directly, ensuring clean user experience.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_bills_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart):
  - Verified and confirmed that the editing access checks (`canEdit` based on `address_type`, `is_default_billing`, and `is_default_shipping`) hide the pencil edit icon for non-matching address types in both billing and shipping dropdown lists.
  - Ensured correct titles are forwarded to the address modal.
- [sales_invoice_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart):
  - Confirmed `_showAddressDialog` and private `_AddressDialog` map the context-specific title to "Billing Address" or "Shipping Address" correctly.
- [sales_order_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart):
  - Confirmed the page delegates direct edit actions to the shared `AddressDialog` widget, passing context-aware titles.

#### Backend Files
- None

**Verifications**: Verified address dialogues and models configurations.

Timestamp of Log Update: June 23, 2026 - 03:15 PM (IST)

## 45. Bills Converter Uniqueness, Order Number Synchronization and Total Quantity Display (June 24, 2026)

### Summary
1. Fixed Bills creation dialog to check uniqueness at the item/receive level instead of PO text level, permitting loading multiple receives under a single purchase order.
2. Synchronized the Order Number textbox in the Bills screen to automatically recalculate and remove loaded PO numbers when their corresponding rows are deleted or cleared from the items table.
3. Updated the compact sidebar list rendering, sorting, and helper methods in the Purchase Receives list screen to display and sort by the total quantity (quantity + FOC + extra).

### Detailed Engineering Changes

#### Frontend Files
- [purchases_bills_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart):
  - Replaced PO-level uniqueness check with `_isReceiveAlreadyLoaded` and `_isPoUnreceivedAlreadyLoaded` checking line items.
  - Added `_updateOrderNumbersFromRows` helper to parse and format active PO numbers from line items.
  - Connected `_updateOrderNumbersFromRows` to `_loadPoForConvert`, `_loadReceiveForConvert`, `_addItemsFromSelectedOptions`, product dropdown selections, row clear, and row delete button callbacks.
- [purchases_purchase_receives_list.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_list.dart):
  - Added `_getTotalQuantityDouble` to calculate the total quantity including FOC and extra.
  - Updated compact list view quantity display to use `_getTotalQuantity`.
  - Updated list sorting comparator for the quantity column in `_getSortedList` to sort by `_getTotalQuantityDouble`.

#### Backend Files
- None

**Verifications**: Verified compilation.

Timestamp of Log Update: June 24, 2026 - 05:00 PM (IST)

## 46. Bills Quantity Split Dialog Improvements (June 25, 2026)

### Summary
1. Configured the quantity split icon in the items table on the Bills screen to be hidden in create mode and only show in edit mode (`widget.editBillId != null`).
2. Replaced the quantity split icon with `LucideIcons.fileEdit` (file-pen) instead of `fileText`.
3. Redesigned the quantity split dialog to open instantly, moving all PO, purchase receive, and billed/unbilled quantity fetching inside the dialog context while using `Skeletonizer` to display skeleton loading fields.
4. Aligned the dialog layout to the absolute top edge of the screen (top padding set to 0) and set footer buttons to be left-aligned (`Update` green first, `Cancel` outline second).
5. Standardized the height of textboxes and dropdowns in the dialog to `32` to match the items table's rate column inputs.
6. Configured the dialog to pre-populate the first split row by default if PO receives are available but no current splits exist.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_bills_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart):
  - Updated the quantity split icon rendering condition to check `widget.editBillId != null`.
  - Changed the quantity split icon to `LucideIcons.fileEdit` (file-pen representation).
  - Refactored `_openEditQuantityDialog` to open `EditQuantityDialog` instantly without parent loading indicators.
- [edit_quantity_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/dialogs/edit_quantity_dialog.dart):
  - Converted widget to `ConsumerStatefulWidget` to access `purchaseOrderRepositoryProvider`.
  - Added internal state variables `_isLoading`, `_poReceives`, `_initialUnreceivedQty`, `_poId`.
  - Implemented `_loadData` in `initState` to fetch PO and receive allocations asynchronously.
  - Wrapped dialog column in a `Skeletonizer` toggled by `_isLoading`, and displayed a dummy split row during load.
  - Set dialog `insetPadding` top to 0 and alignment to `Alignment.topCenter`.
  - Re-ordered footer buttons to: `[Update] [Cancel]` with `MainAxisAlignment.start` alignment.
  - Standardized the height of text fields and `FormDropdown` inside the dialog to `32`.
  - Added auto-population of the first split row in `_loadData` when no allocations are loaded.

#### Backend Files
- None

**Verifications**: Verified compilation and code semantics.

Timestamp of Log Update: June 25, 2026 - 11:10 AM (IST)

## 47. Bill Edit Quantity Split and PO Resolution Bug Fixes (June 25, 2026)

### Summary
1. Fixed the duplicate-product same-values bug in the Edit Quantity split dialog by introducing the missing `purchaseReceiveItemId` tracking logic throughout the frontend model serialization, page load/conversion, and dialog splits.
2. Added `purchaseReceiveItemId` field to `_BillLineItemRow` and mapped it to the `PurchasesBillLineItem` model.
3. Updated `_loadBillForEdit()` to correctly resolve each item's PO and purchase receive IDs when editing a bill, preventing the dropdown from using fallback search.
4. Corrected the unreceived quantity calculation logic to `orderedQty - totalReceived` to show the correct outstanding unreceived amount.
5. Standardized the default auto-fill behavior so that the dialog always defaults to the autofill total quantity stage (`totalRxQty - totalBilledOther`), disabling the button to visual blue state on load.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_bills_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart):
  - Added `purchaseReceiveItemId` field to `_BillLineItemRow` class.
  - Copied `purchaseReceiveItemId` in the `_BillLineItemRow.clone()` method.
  - Assigned `row.purchaseReceiveItemId` from line items inside `_loadBillForEdit()`.
  - Mapped `purchaseReceiveItemId` inside `toModel()` when converting rows to line item models.
  - Configured `_openEditQuantityDialog()` to set the resolved split `purchaseReceiveItemId` on new rows.
  - Assigned `purchaseReceiveItemId` to rows converted from receive items inside `_loadReceiveForConvert()`.
  - Separated the asynchronous database lookup calls in `_loadBillForEdit()` outside of the `setState` block to resolve the compilation error.
  - Passed `initialPurchaseReceiveItemId` to the `EditQuantityDialog` widget from `_openEditQuantityDialog()`.
- [purchases_bills_bill_model.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/models/purchases_bills_bill_model.dart):
  - Handled `purchaseReceiveItemId` parsing inside `fromJson()` and `toJson()` in `PurchasesBillLineItem`.
- [edit_quantity_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/dialogs/edit_quantity_dialog.dart):
  - Corrected the `initialUnreceivedQty` calculation from `totalReceived - orderedQty` to `orderedQty - totalReceived`.
  - Pre-populated the input field to `totalRxQty - totalBilledOther` by default inside _fetchDetailsForSelectedReceive.
  - Added case-insensitive matching for bill UUID comparisons.
  - Added `initialPurchaseReceiveItemId` parameter to the dialog widget.
  - Utilized `initialPurchaseReceiveItemId` and `row.receiveItemId` to uniquely identify the targeted item row in receive allocations, preventing incorrect matching by name/product ID when duplicate items exist.
- [purchases_purchase_receives_model.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_receives/models/purchases_purchase_receives_model.dart):
  - Added `id` field to `PurchaseReceiveItem` model to correctly fetch item-level IDs.

#### Backend Files
- None

**Verifications**: Verified compilation and logic semantics.

Timestamp of Log Update: June 25, 2026 - 03:00 PM (IST)

## 48. Duplicate Product Matching by PO/Receive Composite Keys (June 25, 2026)

### Summary
1. Configured purchases modules to support exact matching and isolation of duplicate items (same item ID but different quantities/descriptions) across PO, Receive, and Billing workflows.
2. Rewrote dropdown tracking logic using key counts in the purchase receives manual rows form to permit selecting duplicate item rows independently.
3. Enhanced the selection dropdown display and search strings to append quantities and descriptions.
4. Corrected the Supabase select query in the Edit Quantity dialog to fetch 'ordered' and 'description' columns under purchase receive items.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_purchase_receives_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart):
  - Normalized `compositeKey` definition using `.toStringAsFixed(4)` for double quantity values and trimming item descriptions.
  - Replaced simple `productId`-based tracking in `availablePoItems` and `selectedItem` with a key counting mechanism (`productId_orderedQty_description`) to allow selecting duplicate items independently.
  - Precision PO lookup in `onChanged` by searching matching PO items by unique line item ID `it.id == poItem.id`, falling back to composite mapping.
  - Added quantity and description details to dropdown item labels.
- [purchases_bills_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart):
  - Updated `_loadReceiveForConvert` and `_processSelectedPOsAndReceives` item mapping logic to match PO items using composite comparison (`i.itemId == poItem.productId && (i.ordered - poItem.quantity).abs() < 0.001 && i.description == poItem.description`), falling back to sequence matching.
  - Fixed type mismatch error by declaring `matchedRxItemIds` Set with `<String?>` type instead of `<String>` to support nullable item IDs.
  - Passed `description` to `EditQuantityDialog` instantiation when opening the dialog.
  - Passed `row.quantity` instead of raw text field `row.quantityCtrl.text` (which includes FOC) to `EditQuantityDialog` constructor parameters (`initialPurchaseReceiveQty` and `currentUnreceivedAllocated`) to ensure billing quantity is matched correctly.
- [edit_quantity_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/dialogs/edit_quantity_dialog.dart):
  - Updated `_fetchReceivesForPo` select query to query `ordered` and `description` under `purchase_receive_items` from Supabase.
  - Enabled precise double comparisons with `.toStringAsFixed(4)` and parenthesized precedence groupings.
  - Added `description` parameter and configured robust fallback item matching (`initialRxItem` and `rxItem`) using item ID, quantity, and description to correctly resolve matching duplicate receive items when initial item ID is null.

#### Backend Files
- None

**Verifications**: Verified compilation and code semantics.

Timestamp of Log Update: June 25, 2026 - 04:30 PM (IST)


## 49. Purchase Receives Quantity Split Integration (June 26, 2026)

### Summary
1. Implemented a split quantity edit button in the items tables on the Purchase Receives screen to match the behavior on the Bills screen.
2. Enabled the Edit Quantity split dialog to dynamically toggle between receives (normal mode) and bills (receive mode) depending on the context of the caller.
3. Configured the dialog dropdown in receive mode to display PO Bill numbers instead of Purchase Receives.
4. Calculated and updated allocated item quantities in memory across PO Bills and switched the view to Billed Items mode upon save in the dialog.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_purchase_receives_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart):
  - Imported `edit_quantity_dialog.dart`.
  - Added the blue split quantity button (`LucideIcons.fileEdit`) next to the quantity input fields in both `_buildItemRow` (normal items row) and `_buildBilledItemRow` (billed items row) when `_hasBills` is true.
  - Implemented `_openEditQuantityDialog(int index)` and `_openEditQuantityDialogFromBilled(int billIndex, int itemIndex)` methods to open the split quantity dialog, map returned allocations to `_associatedBills`, and toggle `_receiveBilledItems` to `true`.
- [edit_quantity_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/dialogs/edit_quantity_dialog.dart):
  - Added `isReceiveMode` constructor parameter, defaulting to `false`.
  - Modified data loading in `_loadData` to fetch PO Bills and calculate unbilled quantity as `initialUnreceivedQty` when `isReceiveMode` is true.
  - Added a new database lookup method `_fetchBillsForPo` to fetch active PO Bills.
  - Updated `_fetchDetailsForSelectedReceive` to load previously received quantities matching the selected Bill's number across other receives.
  - Rendered table headers, unbilled/unreceived row labels, dropdown selections, detail statuses, and row count footers conditionally based on `isReceiveMode`.

#### Backend Files
- None

**Verifications**: Verified compilation and code semantics.

Timestamp of Log Update: June 26, 2026 - 11:20 AM (IST)


## 50. Purchase Receive Bills Query OR/ILIKE Refactoring (June 26, 2026)

### Summary
1. Fixed the bug where the edit quantity split icon (`LucideIcons.fileEdit`) was missing under the "QUANTITY TO RECEIVE" column on the Edit Purchase Receive page.
2. Replaced the exact-match `inFilter('order_number', poNumbers)` Supabase bills query with a flexible `.or(...)` filter querying each PO number with an `.ilike.%PO_NUMBER%` pattern.
3. Added a clean, in-memory filtering step after the query returns to accurately match only bills linked to the exact target PO numbers (by splitting comma-separated `order_number` values).
4. Ensured that `_hasBills` evaluates to true in both the edit flow (`_loadReceiveData`) and the PO selection flow (`_onPOsSelected`) whenever matching bills are found, enabling the split icon next to the quantity inputs.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_purchase_receives_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart):
  - Updated bills loading query in `_loadReceiveData` to use `.or(...)` filter containing comma-separated `.ilike` conditions for each PO number.
  - Implemented in-memory validation of retrieved bills in `_loadReceiveData` by checking if any comma-split value in the bill's `order_number` matches the normalized PO numbers.
  - Resolved specific PO references for each bill item in `_loadReceiveData` by iterating over `loadedPOs` and locating the matching PO.
  - Updated bills loading query in `_onPOsSelected` to utilize the same `.or(...)` + `.ilike` filter pattern.
  - Refactored matching PO resolution in `_onPOsSelected` to support comma-separated lists of order numbers by checking if the list contains the normalized PO order number.

#### Backend Files
- None

**Verifications**: Verified compilation and code semantics.

Timestamp of Log Update: June 26, 2026 - 12:20 PM (IST)


## 51. Purchase Receive Billed Items Column Width Standardisation (June 26, 2026)

### Summary
1. Standardised column width dynamically for the "QUANTITY TO RECEIVE" column in the billed items table of the Purchase Receives page to accommodate horizontal green batch boxes cleanly and prevent UI clipping/overflow.
2. Replaced the static width constraint of 260px in both the table header cell and row items cell with the `_dynamicBilledQtyToReceiveColumnWidth()` helper method.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_purchase_receives_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart):
  - Changed fixed width `260` of `_tableHeaderCell` for the "QUANTITY TO RECEIVE" column inside `_buildBilledItemsTable` to `_dynamicBilledQtyToReceiveColumnWidth()`.
  - Changed fixed width `260` of the parent `SizedBox` wrapping the `Container` for the "QUANTITY TO RECEIVE" cell inside `_buildBilledItemRow` to `_dynamicBilledQtyToReceiveColumnWidth()`.

#### Backend Files
- None

**Verifications**: Verified compilation and code semantics.

Timestamp of Log Update: June 26, 2026 - 01:00 PM (IST)


## 52. Purchase Receive Layout Alignment and Split Quantity Popup UI Polish (June 26, 2026)

### Summary
1. Repositioned the edit quantity split button (`LucideIcons.fileEdit`) on the Purchase Receives page to display horizontally inline next to the batch quantity/FOC breakdown text (`3pcs`) in a `Row` instead of stacking them vertically in a `Column`.
2. Redesigned the quantity/received/unreceived details layout inside the `EditQuantityDialog` popup box to align `Quantity: X` on the left under the dropdown, and `Received: Y | Unreceived: Z` on the right under the quantity textfield, matching the second screenshot precisely.
3. Standardised the dropdown selection list items during loading in the dialog by assigning `'bill_number': 'BILL-XXXXX'` when `isReceiveMode` is active.
4. Upgraded the `_fetchBillsForPo` method to support flexible `.or(...)` with ILIKE queries on multi-PO comma-separated order numbers.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_purchase_receives_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart):
  - Removed internal top `Padding` from `_buildQtyAndFocBreakdown` to allow clean inline row placement, adding it back directly in `_buildManualItemsTable`.
  - Nested the `fileEdit` icon and `_buildQtyAndFocBreakdown` inside a horizontal `Row` within the PO table row cell builder `_buildItemRow`.
  - Nested the `fileEdit` icon and the total batches quantity/FOC text inside a horizontal `Row` within the billed PO table row cell builder `_buildBilledItemRow`.
- [edit_quantity_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/dialogs/edit_quantity_dialog.dart):
  - Refactored `_getAvailableReceivesForIndex` loading state dummy map to specify `bill_number` when in receive mode.
  - Refactored the row layout beneath the split dropdown and textfield inside the splits list view to render `Quantity: X` and `Received/Unreceived` status side-by-side using an `Expanded` left child and right-aligned `SizedBox` child.
  - Refactored `_fetchBillsForPo` to query bills using flexible `order_number.ilike` database lookups and in-memory filtering.

#### Backend Files
- None

**Verifications**: Verified compilation and code semantics.

Timestamp of Log Update: June 26, 2026 - 01:25 PM (IST)


## 53. Purchase Receive/Bill Split Quantity Autoload (June 26, 2026)

### Summary
1. Standardised the quantity split popup behavior on both Edit Purchase Receives and Edit Bills screens to prevent auto-filling the remaining quantity by default.
2. Configured the dialog to autoload the already saved received/billed quantity for initial rows, and default to `0` when new rows are added or when dropdown selections change.
3. Added the `initialQty` member field to the `_SplitRow` helper class to store the initial quantities and resolve compiler errors.
4. Updated caller invocations on the Purchase Receives page to map and pass the saved allocation quantities from the `_associatedBills` local state down to the dialog.

### Detailed Engineering Changes

#### Frontend Files
- [edit_quantity_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/dialogs/edit_quantity_dialog.dart):
  - Declared `final double initialQty` in `_SplitRow` class and initialized it in the constructor.
  - Formatted `initialQty` cleanly as integer or decimal string when initializing `qtyCtrl.text` inside constructor.
- [purchases_purchase_receives_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart):
  - Updated `_openEditQuantityDialog(index)` to search the local `_associatedBills` list for active items mapping to `item.itemId` and pass `initialBill` attributes and `quantityToReceive` to the dialog.
  - Replaced `.firstWhere(..., orElse: () => null)` with `.where(...).firstOrNull` when searching for `itemInBill` inside `_openEditQuantityDialog` to prevent runtime `TypeError` subtype mismatch errors during item lookup.
  - Updated `_openEditQuantityDialogFromBilled(billIndex, itemIndex)` to pass `bill['id']`, `bill['bill_number']`, and the billed item's local `quantityToReceive` to the dialog.

#### Backend Files
- None

**Verifications**: Verified compilation and code semantics.

Timestamp of Log Update: June 26, 2026 - 01:45 PM (IST)


## 54. Purchase Order Billed Quantity Multi-PO Filtering (June 26, 2026)

### Summary
1. Fixed the billed quantity status calculation in both frontend list/detail views and backend status updates when multiple POs are billed under a single shared bill.
2. Filtered total billed quantities per item to only include quantities linked to the specific PO's receive items, rather than summing the total quantities of both POs.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_purchase_orders_list.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart):
  - Selected `id` under `purchase_receive_items` and `purchase_receive_item_id` under `bill_items` in the query inside `_loadPoTxnSummary`.
  - Gathered all receive item IDs for the PO receives into `poReceiveItemIds`.
  - Filtered bill items by checking if `purchase_receive_item_id` is present in `poReceiveItemIds` for list view status calculations, item details table, and cancel item dialog.

#### Backend Files
- [po-status.ts](file:///c:/Users/User/Documents/work/zerpai-new/backend/src/modules/purchases/purchase-orders/utils/po-status.ts):
  - Collected `poReceiveItemIds` from PO receives.
  - Filtered billed item allocations by matching `purchase_receive_item_id` against `poReceiveItemIds` before updating status.
- [purchase-orders.service.ts](file:///c:/Users/User/Documents/work/zerpai-new/backend/src/modules/purchases/purchase-orders/services/purchase-orders.service.ts):
  - Resolved individual billed quantities per PO mapping via `purchase_receive_item_id`.

**Verifications**: Verified compilation and code semantics.

Timestamp of Log Update: June 26, 2026 - 08:45 PM (IST)


## 55. Manage TDS Rates New TDS Group Workflow (June 26, 2026)

### Summary
1. Implemented the "+ New TDS Group" creation workflow inside the Manage TDS Rates popup dialog.
2. Configured dynamic inline form fields to only prompt for the "TDS Group Tax Name" when group mode is active.
3. Rendered multi-selection checkboxes next to each individual TDS rate row allowing users to choose the constituent taxes of the group.
4. Styled the Cancel button as an outlined button matching the ERP theme.
5. Programmed backend syncing of the newly created group and its list of items into the `tds_groups` and `tds_group_items` tables respectively.

### Detailed Engineering Changes

#### Frontend Files
- [manage_tds_tcs_rates_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/presentation/widgets/manage_tds_tcs_rates_dialog.dart):
  - Added toggle state `_isGroupMode` and item selection set `_selectedGroupItemIds`.
  - Dynamic switching of inline fields to display only "TDS Group Tax Name" in group mode.
  - Added outlined Cancel button styling matching `AppTheme.borderColor` and `AppTheme.textSecondary`.
  - Configured multi-selection checkboxes in list header and item rows when `_isGroupMode` is true.
  - Computed total rate sum dynamically and returned results to parent callbacks.
- [lookups_api_service.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/items/items/services/lookups_api_service.dart):
  - Created `syncTdsGroups(List<Map<String, dynamic>> items)` calling `/products/lookups/tds-groups/sync`.

#### Backend Files
- [lookups.controller.ts](file:///c:/Users/User/Documents/work/zerpai-new/backend/src/modules/lookups/lookups.controller.ts):
  - Added controller sync routing for `tds-groups` lookup type.
  - Upserted group details and deleted/inserted row elements in the `tds_groups` and `tds_group_items` tables.

**Verifications**: Verified compilation and code semantics.

Timestamp of Log Update: June 26, 2026 - 09:00 PM (IST)

## 56. Bills Discount Accounting & Journals Tab Integration (June 29, 2026)

### Summary
1. Implemented dynamic accounts double-entry ledger rows generation for bills containing GST, TDS, TCS, adjustments, and transaction/item level discounts.
2. Mapped reference_number to display the actual bill number inside the account_transactions table.
3. Cleared and re-inserted balanced ledger rows dynamically on bill edit operations.
4. Resolved a database foreign key constraint error by dropping the incorrect bills_discount_value_fkey constraint and converting discount_value column type to numeric on NestJS startup.
5. Fixed a 404 relation join embedding error in findOne method of bills service by disambiguating the accounts join path.
6. Styled the footer Draft and Cancel buttons with outlined borders, default-cleared zero values in discount and adjustment textfields to show placeholders, and removed the blue outline focus ring on the item discount cell.
7. Added a Journals preview tab inside the bill list details container showing the balanced transaction list from account_transactions.

### Detailed Engineering Changes

#### Backend Files
- [db.ts](file:///c:/Users/User/Documents/work/zerpai-new/backend/src/db/db.ts):
  - Added a startup PL/pgSQL block to drop `bills_discount_value_fkey` constraint, correct `discount_value` column type to `numeric(15,2)`, and add `discount_accounts_id` foreign key references.
- [bills.service.ts](file:///c:/Users/User/Documents/work/zerpai-new/backend/src/modules/purchases/bills/services/bills.service.ts):
  - Updated `postBillTransactions` to calculate and post correct double-entry legs for Inventory Asset, GST, AP Discount, Adjustment, TCS, TDS, Accounts Payable, and Purchase Discount.
  - Set `reference_number` to bill number in transaction rows.
  - Linked transaction updates inside `updateBill` method.
  - Disambiguated `findOne` join under `account:accounts!account_id(*)`.

#### Frontend Files
- [purchases_bills_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart):
  - Cleared default zero values in discount and adjustment text fields so they show `0` and `0.00` placeholders.
  - Switched Save as Draft and Cancel text buttons to `OutlinedButton` with proper borders.
  - Added `isTransparentBorder: true` on item discount cell wrapper.
- [purchases_bills_list.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart):
  - Created a bottom `Journals` preview tab listing double-entry transaction rows.

**Verifications**: Verified compilation and code semantics.

Timestamp of Log Update: June 29, 2026 - 1:40 PM (IST)

## 57. Customer Address Selection Dropdown Overlay Integration (June 29, 2026)

### Summary
1. Replicated the interactive vendor billing and shipping address dropdown selection menus for sales customers in both Sales Orders and Sales Invoices screens.
2. Added state-linked `LayerLink` target anchors and overlay controls to follow target edits.
3. Constructed a dynamic list of addresses (up to two addresses: Billing and Shipping) from the customer's database properties to populate the dropdown.
4. Programmed local state updates (`_selectedCustomer`) and customer database updates (`updateCustomer`) via the controller notifier in the Sales Orders screen.
5. Configured local state updates (`_selectedCustomer`) for invoice generation in the Sales Invoices screen.

### Detailed Engineering Changes

#### Frontend Files
- [sales_order_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart):
  - Declared `_addressDropdownOverlay`, `_billingAddressLink`, and `_shippingAddressLink` state fields.
  - Updated `_buildAddressColumn` render method to accept and follow the `LayerLink` anchor.
  - Implemented `_showAddressDropdownList` list drawer and item selection/hover state helpers.
  - Linked selection changes to update customer profile in backend database.
  - Removed top margin padding (`padding: EdgeInsets.zero`) inside `_ManageTaxInfoDialogState` to align it to the top.
  - Corrected pointer arrow alignment offsets in `_toggleGstTaxOverlay` and `_toggleGstinOverlay` to point exactly to triggering pencil icons.
- [sales_invoice_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart):
  - Declared `_addressDropdownOverlay`, `_billingAddressLink`, and `_shippingAddressLink` state fields.
  - Updated `_buildAddressColumn` render method to accept and follow the `LayerLink` anchor.
  - Implemented `_showAddressDropdownList` list drawer and item selection/hover state helpers.
  - Configured address selections to update local invoice generation state.
  - Removed top margin padding (`padding: EdgeInsets.zero`) inside `_ManageTaxInfoDialogState` to align it to the top.
  - Corrected pointer arrow alignment offsets in `_toggleGstTaxOverlay` and `_toggleGstinOverlay` to point exactly to triggering pencil icons.

**Verifications**: Verified compilation and code semantics.


## 58. Optional Shipping Address and Mandatory Billing Address Validation (June 30, 2026)

### Summary
1. Configured vendor `shipping_address` and `billing_address` columns on the `purchase_orders` database table to be nullable (`DROP NOT NULL`) to support cases where a vendor has no shipping address.
2. Implemented dynamic startup DDL modification in backend `db.ts` to ensure columns are created and constraints dropped automatically.
3. Added frontend validations in both Purchase Orders (`purchases_purchase_orders_create.dart`) and Bills (`purchases_bills_create.dart`) screens to enforce that a billing address is mandatory before saving, while keeping the shipping address optional.

### Detailed Engineering Changes

#### Backend Files
- [db.ts](file:///c:/Users/User/Documents/work/zerpai-new/backend/src/db/db.ts):
  - Appended DDL queries to create `shipping_address` and `billing_address` columns if not exists, and drop their `NOT NULL` constraints dynamically on start.

#### Frontend Files
- [purchases_purchase_orders_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart):
  - Extracted vendor and billing address ID in `_handleSave` and added validation to throw an error if the billing address is null or empty.
- [purchases_bills_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart):
  - Refactored `billingAddressId` extraction to check both `_customBillingAddress` and the default vendor addresses.
  - Added form validation to enforce billing address presence.

**Verifications**: Verified compilation and code semantics.

Timestamp of Log Update: June 30, 2026 - 10:15 AM (IST)


## 59. Bill Edit Icon, Purchase Order Action Buttons Visibility, and Actions Button Hover Transition (June 30, 2026)

### Summary
1. Configured the edit icon next to the quantity input block on the Bill Creation page to only show during edit mode (`editId != null`) and hide it on the new bill page.
2. Refactored Purchase Order buttons visibility:
   - "Receive" button: Display if the PO is partially received, and hide once its status becomes "received" (or status is "billed" or "void").
   - "Convert to Bill" button: Disappear only when the status becomes "billed" (or status is "void").
3. Standardized three-dots action buttons hover transition: Implemented active hover container states (white background and light grey border `#D3D9E3` transition) around the three-dots (`...`) action trigger icon on hover across bills, purchase orders, sales invoices, and sales orders overview pages.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_bills_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart):
  - Wrapped edit icon widget inside a conditional check `if (widget.editId != null)` to hide it on the new bill creation page.
- [purchases_purchase_orders_list.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart):
  - Updated "Receive" button visibility check to hide when status is "received", "billed", or "void". Show it when status is "partially_received" or "partially received".
  - Updated "Convert to Bill" button visibility check to disappear when status is "billed" or "void".
  - Extracted actions MenuAnchor to custom hoverable wrapper `_buildMoreButton(po)`.
- [purchases_bills_list.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart):
  - Extracted actions MenuAnchor to custom hoverable wrapper `_buildMoreButton(bill)`.
- [sales_invoice_list.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/invoices/presentation/pages/sales_invoice_list.dart):
  - Wrapped `_buildMoreActionsDropdown(invoice)` with `StatefulBuilder` and `MouseRegion` to transition border and background color on hover.
- [sales_order_list.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart):
  - Extracted actions MenuAnchor to custom hoverable wrapper `_buildMoreButton(order)`.

**Verifications**: Verified compilation, analyzer status, and NestJS build state.

Timestamp of Log Update: June 30, 2026 - 10:35 AM (IST)


## 60. Backend Transaction Type Column Size Fix and Bill Quantity Batch Mismatch Validation (June 30, 2026)

### Summary
1. Fixed a database exception (`value too long for type character varying(50)`) when saving purchase bills. Shortened the transaction types generated in `bills.service.ts` (e.g. "Inventory Asset", "Purchase Discount", "Other Expenses (Adjustment)") to stay strictly under the 50-character limit of the `account_transactions.transaction_type` column.
2. Decoupled quantity textbox editing from mutating `savedBatchData` directly on the frontend. Modifying the quantity textbox now retains the actual batch quantity and blue prefill indicator text, which are only updated when selecting/creating a batch in the dialog.
3. Added a new validation rule to prevent saving drafts or open bills if a row's quantity text field does not match the sum of its batch details (`qtyOut + foc`). Emits a clear toast error `in row <number> quantity and batch quantity mismatch`.

### Detailed Engineering Changes

#### Backend Files
- [bills.service.ts](file:///c:/Users/User/Documents/work/zerpai-new/backend/src/modules/purchases/bills/services/bills.service.ts):
  - Shortened all raw string literal transaction types in `addEntry` calls to keep length under 50 characters.

#### Frontend Files
- [purchases_bills_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart):
  - Removed `savedBatchData` mutations inside the quantity textbox `onChanged` handler.
  - Implemented 1-indexed validation loop in `_saveBill` comparing manually input quantity with batch details, checking for mismatches and outputting descriptive row mismatch errors.

**Verifications**: Verified compilation, static analysis (analyzer returned clean), and NestJS backend build state.

Timestamp of Log Update: June 30, 2026 - 11:00 AM (IST)


## 61. Edit Quantity Dialog Refinements (June 30, 2026)

### Summary
1. Modified the Edit Quantity popup dialog used across the Bill and Purchase Receive modules so that the "Unreceived Quantity" (or "Unbilled Quantity") input field autoloads the current row's allocated value (`widget.currentUnreceivedAllocated`) instead of overriding it with the PO-level unreceived/unbilled calculation.
2. Implemented validation inside the Edit Quantity dialog so that:
   - The user cannot enter an unreceived/unbilled quantity exceeding the remaining available PO-level unreceived/unbilled quantity.
   - The user cannot enter a split quantity for any selected receive/bill exceeding the available quantity (`total - already_billed/received`).
3. These validation errors are shown cleanly to the user as `ZerpaiToast` error alerts, preventing dialog updates with invalid values.

### Detailed Engineering Changes

#### Frontend Files
- [edit_quantity_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/dialogs/edit_quantity_dialog.dart):
  - Changed `_unreceivedCtrl.text` initialization inside `_loadData()` to use `widget.currentUnreceivedAllocated`.
  - Added `ZerpaiToast` validation error checks inside the Update button `onPressed` handler, capping inputs to max PO limits and receive/bill row limits.

**Verifications**: Verified compilation, static analysis (analyzer returned clean), and NestJS backend build state.

Timestamp of Log Update: June 30, 2026 - 12:05 PM (IST)


## 62. Edit Quantity Dialog Autoloading Fallback Removal (June 30, 2026)

### Summary
Removed the fallback logic inside `edit_quantity_dialog.dart` that automatically loaded a default split row from `_poReceives` when editing unreceived or unbilled items (when no initial purchase receive or bill association is present). Now, unreceived/unbilled item rows open with only the unreceived quantity input field showing. The user can manually add split receive/bill rows using the `+ New Row` action as desired.

### Detailed Engineering Changes

#### Frontend Files
- [edit_quantity_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/dialogs/edit_quantity_dialog.dart):
  - Removed the `else if (_poReceives.isNotEmpty)` block from `_loadData()` that matched and added target split rows to `_splits` automatically.

**Verifications**: Verified compilation, static analysis (analyzer returned clean), and NestJS backend build state.

Timestamp of Log Update: June 30, 2026 - 12:20 PM (IST)


## 63. Purchase Order Creation Refinements (June 30, 2026)

### Summary
1. Restricted the "Delivery Date" field inside the Purchase Order creation screen to prevent past date selection (past dates are disabled). The "Date" (Order Date) field continues to support backdating (past date selection) starting from Year 2000.
2. Deduplicated items added via "Add Items in Bulk". Selecting a product that already exists in the items table now replaces/updates its quantity with the amount selected in the bulk popup and recalculates all net amounts/taxes instead of appending duplicate product rows.
3. Stabilized item row hover state. Wrapped the action icons (`...` and `x`) and the hover region in a row-local `StatefulBuilder`. This eliminates full-screen rebuilds on hover, curing build lag and ensuring the delete and vertical menu buttons render smoothly and reliably.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_purchase_orders_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart):
  - Updated `_zDateField` to accept an optional `DateTime? firstDate` constraint.
  - Provided `firstDate: DateTime(2000)` for Date (Order Date) and `firstDate: startOfToday` for Delivery Date.
  - Wrapped `MouseRegion` for row hover inside a local `StatefulBuilder` at `_buildItemRow`.
- [purchase_order_notifier.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/notifiers/purchase_order_notifier.dart):
  - Rewrote `addItemsInBulk` to deduplicate selected products, matching by `productId` to replace quantity and recalculate row values.

**Verifications**: Verified compilation, static analysis (analyzer returned clean), and NestJS backend build state.

Timestamp of Log Update: June 30, 2026 - 12:45 PM (IST)


## 64. Date Picker Adjacent Month Days Interactivity Fix (June 30, 2026)

### Summary
Fixed a usability issue in the `ZerpaiCalendar` widget where days of the adjacent months (previous and next month) shown in the calendar grid were not clickable. This prevented users from selecting adjacent month dates (such as future dates like July 1-5 displayed at the bottom of the June calendar grid) directly. Added the `onTap` callback to the adjacent month day cell builder so they are fully interactive and selectable.

### Detailed Engineering Changes

#### Shared UI Files
- [zerpai_calendar.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/inputs/zerpai_calendar.dart):
  - Passed `onTap: () => widget.onDateSelected(date)` to `_buildDayCell` calls for both previous month and next month day numbers inside `_buildGrid()`.

**Verifications**: Verified compilation, static analysis (analyzer returned clean), and NestJS backend build state.

Timestamp of Log Update: June 30, 2026 - 01:10 PM (IST)


## 64. Bulk Items Manual Entry & Calendar Styling (June 30, 2026)

### Summary
1. Enabled manual numeric typing for quantity entry in the "Add Items in Bulk" dialog.
2. Removed the disabled/light gray color treatment for adjacent (previous/next) month day cells in the DatePicker calendar. Active adjacent days now render using the standard dark text style (`AppTheme.textPrimary`).

### Detailed Engineering Changes

#### Frontend Files
- [bulk_items_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/widgets/bulk_items_dialog.dart):
  - Replaced the static `Text` quantity indicator inside the selected items list row with a borderless `TextFormField` allowing manual keyboard entry.
  - Linked the `TextFormField` to a dynamically updating `ValueKey('qty_${item.id}_$currentQty')` which preserves focus and ensures numeric updates are synchronized seamlessly when using buttons or keyboard.
  - Sanitized selected quantities during submit to default any empty or zero/negative manual inputs to `1`.
- [zerpai_calendar.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/inputs/zerpai_calendar.dart):
  - Modified `_buildDayCell` text color selection logic to use `AppTheme.textPrimary` for adjacent month days. Out-of-bounds days (disabled by dates constraints) continue to render as disabled.

**Verifications**: Verified compilation, static analysis (analyzer returned clean), and NestJS backend build state.

Timestamp of Log Update: June 30, 2026 - 2:10 PM (IST)


## 65. Transparent Outline for Manual Entry TextFormField (June 30, 2026)

### Summary
1. Configured the manual entry quantity `TextFormField` inside the "Add Items in Bulk" dialog to completely remove the default focused blue outline border, keeping the selection box visual outline transparent and clean when focused/active.

### Detailed Engineering Changes

#### Frontend Files
- [bulk_items_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/widgets/bulk_items_dialog.dart):
  - Set all custom decoration borders (`border`, `enabledBorder`, `focusedBorder`, `errorBorder`, `disabledBorder`) inside `InputDecoration` to `InputBorder.none` to prevent any focus outlines.

**Verifications**: Verified compilation, static analysis (analyzer returned clean), and NestJS backend build state.

Timestamp of Log Update: June 30, 2026 - 2:12 PM (IST)


## 66. Available for Sale & Stock on Hand Value Alignment (June 30, 2026)

### Summary
1. Resolved a discrepancy in the item table on the Purchase Order creation screen where the inline stock value shown under the Quantity column did not match the values listed in the WarehouseHoverPopover.
2. Synchronized the stock value lookups in `purchases_purchase_orders_create.dart` to match by both warehouse name and warehouse ID, matching the robust lookups implemented in `WarehouseHoverPopover` and the Bill creation screen.
3. Implemented reactive callbacks (`onViewChanged` and `onStockTypeChanged`) for the `WarehouseHoverPopover` in the Purchase Order creation page, ensuring that selecting "Stock on Hand" or "Available for Sale" in the popover dynamically updates the Quantity column labels and values on the parent page.

### Detailed Engineering Changes

#### Frontend Files
- [purchases_purchase_orders_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart):
  - Imported `items_stock_providers.dart` and `items_stock_models.dart`.
  - Updated the inline stock label and value calculation to use state-driven `_stockView` and `_stockType` values.
  - Aligned the `wStock` lookup query criteria to match by name (`s.name.toLowerCase() == wh.name.toLowerCase()`) with a fallback to `s.id == itemWhId`.
  - Configured `WarehouseHoverPopover` to pass `_stockType` as `selectedStockType`, update parent `_stockView` on `onViewChanged`, and update parent `_stockType` on `onStockTypeChanged`.

**Verifications**: Verified compilation, static analysis (analyzer returned clean), and NestJS backend build state.

Timestamp of Log Update: June 30, 2026 - 2:30 PM (IST)


## 67. Bulk Items Quantity Entry and Account/Tax Loading Fixes (June 30, 2026)

### Summary
1. Fixed an issue in both module-specific and shared `BulkItemsDialog` implementations where entering quantities manually in the TextFormField was unstable, losing keyboard focus and failing to persist multi-digit inputs.
2. Replaced the recreation key `ValueKey('qty_${item.id}_$currentQty')` with a stable `ValueKey('qty_${item.id}')` and managed row quantities using persistent `TextEditingController` instances.
3. Configured the text fields to restrict input exclusively to digits (`FilteringTextInputFormatter.digitsOnly`).
4. Enhanced the `addItemsInBulk` notifier method in `purchase_order_notifier.dart` to automatically resolve missing `accountId`, `accountName`, `taxId`, `taxName`, and `taxRate` fields by referencing the `chartOfAccountsProvider` and `itemsControllerProvider` respectively.
5. Aligned interstate vs intrastate tax selection checks to correctly identify inter-state transactions (`!(srcKL && destKL)`) relative to Kerala's home state registration.

### Detailed Engineering Changes

#### Frontend Files
- [bulk_items_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/sales/sales_orders/presentation/widgets/bulk_items_dialog.dart):
  - Added import for services.
  - Implemented per-item `TextEditingController` state management map `_quantityControllers` and handled their disposal.
  - Bound `TextFormField` to the controller and formatted it to only accept digit characters.
- [bulk_items_dialog.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/shared/widgets/dialogs/bulk_items_dialog.dart):
  - Replaced the static `Text` quantity display with the same persistent `TextFormField` implementation using `TextEditingController`.
- [purchase_order_notifier.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/notifiers/purchase_order_notifier.dart):
  - Enhanced `addItemsInBulk` to query `itemsControllerProvider` and `chartOfAccountsProvider` to auto-populate missing account and tax fields.
  - Corrected `isInterstate` check in individual product selection to use the updated interstate formula.

**Verifications**: Verified compilation, static analysis (analyzer returned clean), and NestJS backend build state.

Timestamp of Log Update: June 30, 2026 - 3:10 PM (IST)


## 68. Tax Loading Logic Realignment (June 30, 2026)

### Summary
1. Realigned the interstate vs intrastate GST tax selection logic on purchase transactions (Purchase Orders and Bills) to match the database schema and customer requirements.
2. The logic has been inverted so that transactions where both source of supply (vendor state) and destination of supply (warehouse/branch state) are Kerala (`srcKL && destKL`) correctly load the `inter_state_tax_id` column.
3. Transactions where either is outside of Kerala correctly load the `intra_state_tax_id` column.

### Detailed Engineering Changes

#### Frontend Files
- [purchase_order_notifier.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/notifiers/purchase_order_notifier.dart):
  - Updated `isInterstate` / `activeInterstate` logic in `selectProductForItem`, `addItemsInBulk`, and `_resolvePurchaseTax` to evaluate to true (loading the interstate column) when both states contain 'kerala'.
- [purchases_purchase_orders_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart):
  - Inverted the interstate check inside the bulk insert dialog callback.
- [purchases_bills_create.dart](file:///c:/Users/User/Documents/work/zerpai-new/lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart):
  - Inverted the tax column check in `_updateRowTaxForProduct` and context-menu bulk insert callbacks.

**Verifications**: Verified compilation and clean static analysis (`dart analyze`).

Timestamp of Log Update: June 30, 2026 - 3:30 PM (IST)

## 8. Purchase Order Tax Column Alignment for Kerala local transactions (June 30, 2026)

### Summary
Fixed a tax resolution issue on the Purchase Order creation page where local/intrastate transactions within Kerala (where both Source of Supply and Destination of Supply are Kerala) incorrectly loaded the intra-state tax rates instead of the expected inter-state tax rate values.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/notifiers/purchase_order_notifier.dart:
  - Updated the isInterstate logic across all resolution pathways (_resolvePurchaseTax, selectProductForItem, ddItemsInBulk, and 
ecalculateAllTaxes) so that local transactions with both source and destination in Kerala resolve isInterstate to 	rue, correctly applying the inter_state_tax_id column values.
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart:
  - Aligned the inline bulk-add item logic to use the same Kerala-specific interstate logic.

Timestamp of Log Update: June 30, 2026 - 4:40 PM (IST)

## 9. Purchase Order Interstate Tax Logic Update (June 30, 2026)

### Summary
Updated tax resolution logic on the Purchase Order creation screen to align with changed user requirements:
1. When both Source of Supply and Destination of Supply are NOT Kerala (!srcKL && !destKL), the screen shows inter_state_tax_id values (interstate).
2. When either Source of Supply OR Destination of Supply is Kerala (srcKL || destKL), the screen shows intra_state_tax_id values (intrastate).

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/notifiers/purchase_order_notifier.dart:
  - Updated the isInterstate / ctiveInterstate evaluation to use !srcKL && !destKL logic across selectProductForItem, ddItemsInBulk, 
ecalculateAllTaxes, and _resolvePurchaseTax.
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart:
  - Updated the bulk insert isInterstate evaluation to match.

Timestamp of Log Update: June 30, 2026 - 5:15 PM (IST)

## 10. Purchase Order Details Receive Action Visibility (July 1, 2026)

### Summary
Fixed an action button visibility issue on the Purchase Order overview/details page where the "Receive" button in the "WHAT'S NEXT?" banner was missing when the status was "Partially Received" (so receives were not empty).

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart:
  - Adjusted the first banner block condition from summary.receives.isEmpty to !_isAllItemsReceived(order, summary) so that it also displays when there are prior receives but items are not fully received yet.
  - Adjusted the second banner block condition to include _isAllItemsReceived(order, summary) so that the "Convert to Bill" banner behaves as a mutually exclusive fallback once all items are fully received.

Timestamp of Log Update: July 1, 2026 - 10:15 AM (IST)

## 258. Purchase Orders and Bills Converting Enhancements (July 1, 2026)

### Summary
Enhanced the Convert to Bill logic for Purchase Orders, support multiple Receives mapping to a single Bill, corrected Interstate tax calculation rules for Kerala state, and added View Bills option to dropdown actions.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_orders/notifiers/purchase_order_notifier.dart`:
  - Adjusted interstate tax checks so that if source or destination of supply equals "kerala", treat as intrastate (isInterstate = false) and apply `intra_state_tax_id`; use `inter_state_tax_id` only if neither is Kerala.
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`:
  - Synced interstate tax checks inside the bulk add action to match notifier rules.
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart`:
  - Adjusted detail actions dropdown list to show "Expected Delivery Date", "Cancel Items", "Clone", "View Bills", "Delete", and "Mark as Received" options for issued POs with receives.
  - Implemented `_handleConvertToBill` method showing a choice dialog (`_ConvertToBillSelectionDialog`) for converting to bills based on PO and receive states:
    - Scenario 1: PO is partially received and no bills exist (or not under receives) -> display radio choice popup between PO/Yet-to-Receive items and Received checklist items.
    - Scenario 2: Whole ordered quantity is in transit or multiple receives are present under PO -> display Checklist dialog of receives directly.
  - Navigates to `/purchases/bills/create?poId=X&receiveId=id1,id2` on confirmation.
  - Added "Receive" button visible under partially received status matching yet-to-receive behavior.
  - Added "View Bills" menu item navigating to the bills list filtered by PO order number.
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - Updated `_loadReceiveForConvert` to accept comma-separated receive IDs, fetch and merge line items from multiple receives into the bills items list.

Timestamp of Log Update: July 1, 2026 - 10:45 AM (IST)

## 259. Expected Delivery Date Sync, Postgrest Error Resolving & Page Dispose Safety (July 1, 2026)

### Summary
Fixed the Expected Delivery Date update handler by removing the non-existent `delivery_date` database column from the Supabase query to resolve PostgrestException (PGRST204), writing strictly to `expected_delivery_date` and `notes`. Also prevented `setState() called after dispose()` crashes inside the bills create screen when pages are unmounted or context is disposed before async load finishes, and restricted the item quantity edit button to Edit Receive mode.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart`:
  - Removed the `delivery_date` parameter from the Supabase update payload in the date dialog onSave callback.
  - Wrapped post-update `setState` in a `mounted` safety check.
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - Wrapped all async initialization/loading `setState` and `finally` callbacks within `_loadReceiveForConvert` and `_loadPoForConvert` with `mounted` and `context.mounted` verification.
- `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`:
  - Adjusted items table rows for both billed and unbilled items to conditionally show the `LucideIcons.fileEdit` icon only if `_isEditMode` is true (edit mode).

Timestamp of Log Update: July 1, 2026 - 11:15 AM (IST)
## 120. Sales Invoice Pages-Only Handoff (July 01, 2026)

### Summary
Prepared a pages-folder-only handoff for Sales Invoice create and list screens so another developer can copy only the `pages/` folder and run frontend-only UI without module providers, backend services, auth, Supabase, PDF, printing, or shared widget dependencies.

### Detailed Engineering Changes

#### Frontend Files
- `handoff/outbound_sales_invoice_pages_only/lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`:
  - Added standalone `SalesInvoiceCreateScreen` UI with local controllers, item rows, totals, frontend-only actions, and Flutter Material/services imports only.
- `handoff/outbound_sales_invoice_pages_only/lib/modules/sales/invoices/presentation/pages/sales_invoice_list.dart`:
  - Added standalone `SalesInvoiceOverviewScreen` UI with local sample rows, search, selection ribbon, table shell, pagination controls, and no external Zerpai dependencies.
  - Replaced raw dropdown usage with a white popup page-size selector to keep pages-only behavior while avoiding forbidden `DropdownButton` usage.
- `handoff/outbound_sales_invoice_pages_only/README.bak`:
  - Documented copy path, route class names, frontend-only dependency boundary, and backend-replacement intent.

#### Backend Files
- None.

### Verification
- Dependency scan passed: no `package:zerpai_erp`, GoRouter, Riverpod, Supabase, API, raw `DropdownButton`, raw `showDatePicker`, Flutter `Tooltip`, or `Navigator.push` references in handoff page files.
- `dart analyze` targeted handoff pages timed out after 120s and 240s in this environment; no analyzer result was produced.
- `dart format` also timed out after 120s; files were manually kept in formatted Dart style.

Timestamp of Log Update: July 01, 2026 - 11:09 AM (IST)

## 260. State-Based Popups for "Convert to Bill" in Purchase Order Detail page (July 1, 2026)

### Summary
Implemented state-based popup conditions for the "Convert to Bill" button on the Purchase Order detail page. Now, clicking "Convert to Bill" correctly triggers:
- Choice Dialog (1st & 2nd popup) when receives exist AND either a bill was created directly for the PO itself (not against receives) or the PO's receive status is "partially received" (with only a single receive).
- Checklist Dialog (3rd popup) directly listing receives with checkboxes (no radio buttons) when receives exist and choice conditions are not met (e.g. fully received, or multiple receives exist without bills on the PO itself).
- Removed unused imports and deprecated RadioListTile in the selection dialog.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart`:
  - Updated `_handleConvertToBill` to evaluate `hasBillsForPoItself`, `isPartiallyReceived`, and check if multiple receives or whole in transit status applies.
  - Refactored `_ConvertToBillSelectionDialog` to replace deprecated `RadioListTile` widgets with custom standard `Radio` and row/column typography structures.
  - Corrected GoRouter navigation paths to include the mandatory `/$orgId/` prefix.
- `lib/modules/purchases/purchase_orders/presentation/widgets/manage_tds_tcs_rates_dialog.dart`:
  - Removed unused `package:lucide_icons/lucide_icons.dart` import.

Timestamp of Log Update: July 1, 2026 - 11:35 AM (IST)


## 261. Convert to Bill Dialog Table Styling & Close Button Navigation (July 1, 2026)

### Summary
Removed vertical column separating lines and set cell padding to 0 in the Convert to Bill selection dialog tables to clean up the user interface. Additionally, refactored the close button ('x') click handler on the New/Edit Bill creation screen to correctly perform a back operation (or fall back to the relevant purchase order detail page or bills list with organization scope prefix).

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart:
  - Adjusted both Yet To Receive and Receives tables in _ConvertToBillSelectionDialog to use TableBorder with horizontal borders only (removing vertical separating borders).
  - Modified TableRow children to use EdgeInsets.zero padding instead of 8px padding.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - Updated the header close button InkWell onTap callback to check context.canPop(). If false, dynamically extracts orgSystemId and query parameter poId to navigate back to the corresponding purchase order detail screen or the bills list screen.

#### Backend Files
- None.

Timestamp of Log Update: July 1, 2026 - 12:00 PM (IST)


## 262. Sales Order Items Table Styling & Quantity Defaults (July 1, 2026)

### Summary
Cleaned up the items table on the Sales Order creation page by removing the drag handle/grip column (and its vertical divider) when bulk actions are inactive. Defaulted item quantities to empty strings so they show the standard '0' hint text instead of '1', and expanded the rate column price list dropdown to fill the column width responsive layout.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - **Removed Reorder Column**: Omitted the reorder grab listener widget and its accompanying vertical line _vLine() when _showBulkUpdateToolbar is false (in both table header and item rows).
  - **Quantity Defaults**: Updated settings overlay row insert default quantity parameters to empty string so that hintText '0' is displayed on new rows.
  - **Price List Dropdown Expansion**: Replaced the translation stack and absolute width of 120px with a responsive Row and Expanded structure, cloning the purchases order rate column layout.

#### Backend Files
- None.

Timestamp of Log Update: July 1, 2026 - 4:25 PM (IST)


## 263. Price List Dropdown Visibility Restoration (July 1, 2026)

### Summary
Restored the visibility of the price list dropdown box in the rate column of the items table in sales_order_create.dart by reverting the condition to check only _showPriceList, matching purchases_purchase_orders_create.dart.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - Changed the visibility condition of the price list dropdown in the rate column back to _showPriceList (removing the applicablePriceLists.isNotEmpty check).

#### Backend Files
- None.

Timestamp of Log Update: July 1, 2026 - 4:32 PM (IST)


## 264. Customer Addresses Database Alignment & Header Settings Icon Removal (July 1, 2026)

### Summary
Aligned NestJS backend mapping, creation, and update controllers with the new `customer_addresses` table schema, and resolved database column crashes when querying sales order/invoice customer records. Also removed the settings gear icon and its divider line from the New Sales Order screen header.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`:
  - Removed the settings gear icon button and its adjacent vertical divider line from the top header row of the screen.

#### Backend Files
- `backend/src/modules/sales/services/customers.service.ts`:
  - Removed all `billing_address_*` and `shipping_address_*` columns from `buildCustomerWriteModel` since they no longer exist in the `customers` database table.
  - Implemented `saveAddress` helper to dynamically upsert address details into the `customer_addresses` table on customer creation (`create`) and update (`update`).
  - Updated `mapCustomer` to asynchronously fetch active customer addresses from `customer_addresses` and map them back to the model fields for frontend compatibility.
- `backend/src/modules/sales/services/sales.service.ts`:
  - Updated customer detail query selections inside `getSalesOrderById` and `getInvoiceById` to query the `customers` table for basic info and retrieve address fields separately from the `customer_addresses` table, resolving database column errors.

Timestamp of Log Update: July 1, 2026 - 4:45 PM (IST)


## 265. Customer Address Selector Name Lookups & Card-Specific Edit (July 1, 2026)

### Summary
Resolved database UUID string displays in the customer address dropdown overlay by performing name lookups against countries and states providers, and refactored the address edit modal to accept initial address data to support card-specific editing and type-safe saves.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`:
  - **Lookup Name Resolution**: Updated `_buildAddressDropdownItem` to resolve state and country UUID values to their respective display names via `countriesProvider` and `statesProvider` before generating text lines.
  - **Card-Specific Editing**: Refactored `_showAddressDialog` signature to accept `initialAddress` and populated the `AddressDialog` form fields using the card's address details.
  - **Active Selection Mapping**: Swapped the hardcoded visibility check inside `onSave` to dynamically extract whether the active card is billing or shipping (`saveAsBilling`), preventing cross-address type overrides.

#### Backend Files
- None.

Timestamp of Log Update: July 1, 2026 - 5:00 PM (IST)


## 266. Address Dropdown Cross-Edit Restraints & Backend Empty Update Bypass (July 1, 2026)

### Summary
Prevented cross-type address modifications in the dropdown overlays by hiding the pencil icon on unmatched cards (Billing in Shipping dropdown and vice-versa). Fixed a database `Customer not found` crash on the backend by filtering `undefined` values and bypassing empty `UPDATE` queries when only sub-addresses are updated.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`:
  - **Edit Authorization Check**: Added checks for card address types (`isAddrBilling` / `isAddrShipping`) and compared them to the parent dropdown type (`isBilling`) to establish `canEdit`.
  - **UI Icon Lock**: Modified mouse-hover display condition of `pencil` icon to check `isHovered && canEdit`.

#### Backend Files
- `backend/src/modules/sales/services/customers.service.ts`:
  - **Undefined Property Sanitization**: Stripped `undefined` properties from the Supabase update payload.
  - **No-Op Update Detection**: Added conditional check to bypass `supabaseService.getClient().from("customers").update(...)` when no customer columns changed, fetching the customer directly to prevent SQL exceptions.

Timestamp of Log Update: July 1, 2026 - 5:15 PM (IST)


## 267. Branch Price List Consolidation & Active Entity Synchronization (July 3, 2026)

### Summary
Consolidated the Price List Edit page functionality directly into the Price List Create screen to reduce code duplication and simplify routing. Implemented branch-specific price list filtering in all transaction creation screens (Sales Orders, Sales Invoices, Purchase Orders, Bills) so only matching branch price lists and global price lists are displayed. Added branch-aware warehouse filtering that automatically validates and resets selected warehouse IDs to default when the active branch/org changes.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/pricelists/pricelist/presentation/items_pricelist_pricelist_create.dart`:
  - Consolidated edit mode logic, constructor parameters, initialization placeholders, skeleton loading, and conditional updates inside save calls.
- `lib/modules/pricelists/branch_pricelist/presentation/branch_pricelist_create_page.dart`:
  - Updated associated branches dropdown selections to index and group by unique UUIDs (`entity_id`) instead of display names.
- `lib/app/routing/app_router.dart`:
  - Redirected price list edit routes to resolve `PriceListCreateScreen` with edit parameters.
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`:
  - Implemented branch-specific price list combination logic (`_getCombinedPriceListsForBranch`) and active warehouse selection checks.
- `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`:
  - Implemented branch-specific price list combination logic and active warehouse selection checks.
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`:
  - Implemented branch-specific price list combination logic and active warehouse selection checks.
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - Implemented branch-specific price list combination logic and active warehouse selection checks.
- `lib/modules/inventory/providers/warehouse_provider.dart`:
  - Watched `entityProvider` inside `warehousesProvider` to automatically force cache invalidation on active entity switch.

#### Backend Files
- `backend/src/modules/products/products.service.ts`:
  - Updated `getWarehouses` SQL queries to return the `entity_id` field.

Timestamp of Log Update: July 3, 2026 - 1:00 PM (IST)


## 268. Default Payment Terms Fallbacks & Form Clear Alignments (July 3, 2026)

### Summary
Implemented a database-backed default payment terms mechanism across sales and purchase transaction views, and added clear buttons along with layout constraint fixes to several dropdown fields.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`:
  - Added customer preference checks on customer name dropdown selection to resolve matching UUIDs, falling back to database default payment terms or "Net 30".
  - Added unique `ValueKey`s to all `SharedFieldLayout` wrappers (such as Customer Name, Place of Supply, Sales Order#, Reference#, Sales Order Date, Expected Shipment Date, Payment Terms, Delivery Method, and Salesperson) to ensure Flutter's element reconciliation correctly maintains state boundaries during dynamic tree updates. This fixes the Delivery Method dropdown list overlay rendering at the position of Place of Supply.
  - Added `allowClear: !_isEditMode` to the Customer Name `FormDropdown`, and updated its `onChanged` callback to handle clearing properly.
  - Added `allowClear: true` to both `payment_terms` and `delivery_method` `FormDropdown` fields.
  - Updated the `suffixWidget` of the Expected Shipment Date `CustomTextField` to dynamically display a red clear icon when a date is selected, permitting the field to be cleared easily.
- `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`:
  - Declared `_defaultPaymentTermId` state variable and updated `_loadPaymentTerms()` to query active default configurations from DB.
  - Resolved payment terms using customer preferences or fallback default payment terms during selection.
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`:
  - Declared `_defaultPaymentTermId` state variable and updated `_loadPaymentTerms()` to query active default configurations from DB.
  - Resolved payment terms using vendor preferences or fallback default payment terms during selection.
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`:
  - Declared `_defaultPaymentTermId` state variable and updated `_loadPaymentTerms()` to query active default configurations from DB.
  - Resolved payment terms using vendor preferences or fallback default payment terms during selection.

#### Backend Files
- None.

Timestamp of Log Update: July 3, 2026 - 1:15 PM (IST)


## 269. Dynamic Carrier / Delivery Method Data Mapping (July 3, 2026)

### Summary
Removed hardcoded values from the Delivery Method dropdown in Sales Order creation. The dropdown now retrieves carrier names dynamically from the carrier table. Also implemented custom-typed carrier synchronization to the backend database upon Sales Order form submission.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:
  - Declared _carriersList state list and implemented _loadCarriers() to fetch active shipment preferences from the database.
  - Initialized _loadCarriers() in initState to fetch data on view redirection.
  - Set llowCustomValue: true on the Delivery Method FormDropdown and bound its options dynamically to _carriersList carrier names.
  - Implemented automatic carrier synchronization logic inside the _save() routine to push new, custom-typed carrier names to the backend using LookupsApiService.syncShipmentPreferences before submitting.

#### Backend Files
- None.

Timestamp of Log Update: July 3, 2026 - 1:30 PM (IST)


## 270. Dynamic Salesperson Mapping to Users Table (July 3, 2026)

### Summary
Mapped the Salesperson field in Sales Order creation to list active branch users from the `users` table instead of using custom sales rep records. Removed the hardcoded default value "ALTHAF" and the "Manage Salespersons" gear icon option and popup dialog entirely.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`:
  - Removed salesperson fallback value "ALTHAF" from initialization.
  - Removed "Manage Salespersons" configure settings from the Salesperson `FormDropdown` and deleted the `_showManageSalespersonsDialog()` helper.
  - Bound dropdown items, value displays, and item templates to match user UUIDs and full names (`full_name` database column keys) dynamically.
  - Configured active user default resolution so the salesperson selection defaults to the active login user (if present in the fetched list).

#### Backend Files
- `backend/src/modules/lookups/lookups.controller.ts`:
  - Added "users" to `entityScopedTables` to automatically filter lookups by active `entity_id`.
  - Added `salespersons` to table maps inside `getLookups`, `searchLookups`, and `syncLookups` methods, mapping to table name "users" and query field "full_name".

Timestamp of Log Update: July 3, 2026 - 2:00 PM (IST)


## 271. Salesperson Default Removal, Footer cleanup, and Row drag reordering (July 3, 2026)

### Summary
Removed the default auto-loading/auto-selection of salesperson in Sales Order creation to keep the field empty initially. Cleaned up the creation page footer by removing the bottom-right status section showing Inventory Tracking and totals. Implemented items table reordering handles using the 6-dots drag handles layout.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`:
  - Removed login user default matching logic inside `_loadSalespersons()` to avoid auto-selecting/auto-loading the salesperson field.
  - Removed the `Spacer` and the bottom-right `Row` containing settings/Inventory Tracking icon-text, Total Amount, and Total Quantity labels from `_buildFooter()`.
  - Added a `SizedBox(width: 40)` placeholder to the table header when bulk mode is inactive to align header columns.
  - Implemented the 6-dots vertical grip reorder handles (`LucideIcons.gripVertical` inside `ReorderableDragStartListener`) within the items table rows builder when bulk mode is inactive, matching Purchases PO items table layout.

#### Backend Files
- None.

Timestamp of Log Update: July 3, 2026 - 2:30 PM (IST)


## 272. Sales Order List Status Circles Mapping (July 3, 2026)

### Summary
Implemented dynamic status circles in the Sales Order list page to display invoiced, packed (package created), shipped (shipment created), and picked (picklist created) states dynamically based on the exact same half-circle painting/visual principle as the Purchases module.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart`:
  - Added variables `_statusSummaries` and `_lastLoadedOrders` to the widget state configuration.
  - Implemented `_fetchStatusSummaries()` to query the backend database (Supabase) to get linked invoices, packages, shipments, and picklists for all visible sales orders, and dynamically compute their statuses (`'full'`, `'partial'`, or `'none'`) by mapping their totals against ordered quantity totals.
  - Implemented `_buildStatusCircle()` to draw full color circles (for `'full'`), half color circles (for `'partial'`), or grey circles (for `'none'`) using custom painters and ClipRect widgets.
  - Replaced cell rendering cases for invoiced, packed, shipped, and picked columns in `_buildCell` to use the new status calculation and circle drawings:
    - Invoiced -> Blue circle (`Colors.blue`)
    - Packed -> Orange circle (`Colors.orange`)
    - Shipped -> Green circle (`Colors.green`)
    - Picked -> Red circle (`Colors.red`)
  - Updated the data loading callback `data: (sales)` to trigger summary fetches on state changes using post-frame callbacks.

#### Backend Files
- None.

Timestamp of Log Update: July 3, 2026 - 3:00 PM (IST)


## 273. New Invoice Screen UI Cleanups, Salesperson UUID Alignment, and Hover Date Clear Buttons (July 3, 2026)

### Summary
Cleaned up the header and items row UI on the New Invoice screen, updated the salesperson dropdown logic to use standard UUIDs mapping to user records, improved pending order inclusion to fetch complete details asynchronously, and added hover-sensitive date clear controls to both Sales Invoices and Sales Orders.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`:
  - Removed settings gear icon and vertical line divider from the top-right header section.
  - Moved the vertical line divider next to the drag handle into the `_showBulkUpdateToolbar` check block so it only shows in bulk mode, removing it from default row displays.
  - Updated the salesperson loading logic to retrieve users via `LookupsApiService().getSalespersons()` mapping UUID IDs as dropdown values and full names as displays.
  - Updated `_resolveSalespersonUuid()` to resolve matching names or IDs to user UUIDs.
  - Simplified save payload mapping by directly assigning `salespersonId = salesperson` since the dropdown value stores the UUID.
  - Updated `_loadConfirmedCustomerOrders()` to asynchronously fetch complete details (including items) using `api.getSalesOrderById()` for each order, fixing empty/missing items inside the import selection list.
  - Declared `_isDueDateHovered` state tracker and wrapped the Due Date field in a `MouseRegion` to show the clear (X) button only when the field is hovered.
  - Removed unused import of `user_model.dart`.
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`:
  - Declared `_isExpectedShipmentHovered` state tracker.
  - Wrapped the Expected Shipment Date field in a `MouseRegion` to display the clear (X) button only when hovering above the input area.

#### Backend Files
- None.

Timestamp of Log Update: July 3, 2026 - 3:30 PM (IST)


## 274. Unified Sales Payment Create Screen and Compilation Error Resolution (July 7, 2026)

### Summary
Successfully unified the two separate customer payment creation forms (`createcustomeradvance.dart` and `createinvoicepayment.dart`) into a single high-performance screen (`sales_payment_create.dart`), resolved routing compilation errors in `app_router.dart`, and corrected imports for newly renamed composite items presentation modules.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/payment_recieved/presentation/sales_payment_create.dart`:
  - Merged and unified the invoice payment allocation flow and customer advance payment flow under a single tabbed controller.
  - Implemented conditional `showLayout`, `onCancel`, and `onSaveSuccess` parameter overrides in parent layout scaffolding to support inline embedding inside transaction sheets and drawers.
  - Repaired child widget scaffold return layout structures (e.g., `_AmountField`, `_DatePickerField`, `_AddPanPopoverContent`) that were corrupted by global regex match replacements.
  - Converted deprecated `AppTheme.primaryGreen` colors to the approved `AppTheme.successGreen` palette keys.
- `lib/app/routing/app_router.dart`:
  - Fixed composite items route definitions by importing the newly-renamed `composite_items_create.dart` and `composite_items_overview.dart` files.
  - Mapped route configurations to point to `CompositeItemsCreatePage` and `CompositeItemsOverview` classes instead of outdated non-existent screen names.

Timestamp of Log Update: July 7, 2026 - 12:45 PM (IST)


## 275. Customer/Vendor Sidebar Redirects, Sales Order Status Columns, Invoices Routing & PDF/Print Action Styles (July 7, 2026)

### Summary
Corrected customer and vendor drawer detail redirects, corrected Sales Order status column indicator colors and items calculation query, mapped sales invoices router paths to the overview workspace, implemented client-side PDF document generation for picklists, and formatted PDF/Print dropdown actions to match purchase orders dropdown layout style.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart`:
  - Corrected status circle color mappings passed to `_buildStatusCircle` under `_buildCell` to match specifications: Invoiced -> Green, Shipped -> Red, Picked -> Blue, Packed -> Orange.
  - Added query fetch to the `sales_order_items` table under `_fetchStatusSummaries` to dynamically compute correct total ordered quantities per order since `order.items` is null in list view response payloads.
- `lib/app/routing/app_router.dart`:
  - Replaced the temporary placeholder screen for `sales/invoices` and `sales/invoices/:id` paths with `SalesInvoiceOverviewScreen` to wired the invoices master-detail split screen.
- `lib/shared/widgets/inputs/customer_sidebar.dart`:
  - Mapped external link detail icons to resolve organisation ID and navigate directly to customer overview page using absolute path routing.
- `lib/shared/widgets/inputs/vendor_sidebar.dart`:
  - Configured external link detail icons to resolve organisation ID and navigate directly to vendor overview page.
- `lib/modules/inventory/packages/presentation/pages/inventory_packages_list.dart`:
  - Updated detail panel actions to use the custom MouseRegion Zoho-style buttons.
  - Formatted the PDF/Print dropdown action trigger and children options ("Download PDF" and "Print") to match purchase orders dropdown layout.
- `lib/modules/inventory/picklists/presentation/pages/inventory_picklists_list.dart`:
  - Added client-side PDF document generation `_generatePicklistPdf` to generate A4 documents with company info, assignee, items table, and statuses.
  - Replaced detail panel actions toolbar buttons with custom MouseRegion Zoho-style buttons separated by vertical dividers.
  - Updated PDF/Print dropdown to call PDF generation and layout/download PDF options.
- `lib/modules/inventory/shipments/presentation/pages/inventory_shipments_list.dart`:
  - Replaced action buttons and detail panel layout spacing with custom MouseRegion Zoho-style buttons and vertical dividers.
  - Updated PDF/Print and Mark as Delivered dropdowns to align trigger styling and options.

#### Backend Files
- None.

Timestamp of Log Update: July 7, 2026 - 3:00 PM (IST)


## 276. Shipment Items Loading Query Fix (July 7, 2026)

### Summary
Resolved the empty shipment items table issue by adding nested select configuration parameters to retrieve package items and product records associated with shipment packages.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/inventory/shipments/presentation/pages/inventory_shipments_list.dart`:
  - Updated Supabase query select query under `shipmentsProvider` to fetch `inventory_package_items(quantity, products(product_name))` inside the nested `inventory_packages` selector. This loads items and their corresponding names/quantities, correcting the empty table display.

#### Backend Files
- None.

Timestamp of Log Update: July 7, 2026 - 5:00 PM (IST)


## 277. Picklist Creation Dialog Filters Polish (July 8, 2026)

### Summary
Improved the picklist creation "Add Items" dialog filters by removing the redundant "Search" button (since selecting values triggers automatic live refetches) and dynamically styling the "Filter" toggle button to show highlighted blue styling when the filters are collapsed/vanished.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/inventory/picklists/presentation/pages/inventory_picklists_create.dart`:
  - Removed the `ElevatedButton` for "Search" and the associated preceding spacer inside `_buildFilterSection()` to keep the layout compact and clean.
  - Updated the toggle "Filter" button inside `_buildDialogHeader()` to check `!_showFilters` state and dynamically apply `Colors.blue.shade600` styling to its border, text, and icon when the filter panel is collapsed.

#### Backend Files
- None.

Timestamp of Log Update: July 8, 2026 - 8:45 AM (IST)


## 278. Refactor and Consolidate Item Quick Edit Dialog (July 8, 2026)

### Summary
Consolidated the two duplicate `sales_item_quick_edit_dialog.dart` files into a single reusable shared widget `item_quick_edit_dialog.dart` located in the `shared/widgets/dialogs/` directory. Renamed the class to `ItemQuickEditDialog` and updated all occurrences across the sales and purchases creation screens. Created compatibility shims at the old locations.

### Detailed Engineering Changes

#### Frontend Files
- `lib/shared/widgets/dialogs/item_quick_edit_dialog.dart`:
  - [NEW] Created the consolidated file with the more robust implementation (containing proper type casting for categories lists and modern `Radio` buttons).
  - Renamed the widget class to `ItemQuickEditDialog` and its state class to `_ItemQuickEditDialogState`.
- `lib/modules/sales/sales_orders/presentation/widgets/sales_item_quick_edit_dialog.dart`:
  - Overwrote with a library compatibility shim exporting `item_quick_edit_dialog.dart` and maintaining a deprecated `typedef SalesItemQuickEditDialog = ItemQuickEditDialog`.
- `lib/modules/sales/credit_note/presentation/pages/sales_item_quick_edit_dialog.dart`:
  - Overwrote with a library compatibility shim exporting `item_quick_edit_dialog.dart` and maintaining a deprecated `typedef SalesItemQuickEditDialog = ItemQuickEditDialog`.
- Updated imports and class instantiation calls to point to the consolidated shared widget in:
  - `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`
  - `lib/modules/sales/credit_note/presentation/pages/credit_note_create_page.dart`
  - `lib/modules/purchases/vendor_credits/presentation/purchases_vendor_credits_create.dart`
  - `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`
  - `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`

#### Backend Files
- None.

Timestamp of Log Update: July 8, 2026 - 9:30 AM (IST)


## 279. Clean Up Legacy Shim Files for Item Quick Edit Dialog (July 8, 2026)

### Summary
Completely deleted the legacy compatibility shims for `sales_item_quick_edit_dialog.dart` after verifying import-zero state across the codebase.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/sales/sales_orders/presentation/widgets/sales_item_quick_edit_dialog.dart`:
  - [DELETE] Deleted this compatibility shim file.
- `lib/modules/sales/credit_note/presentation/pages/sales_item_quick_edit_dialog.dart`:
  - [DELETE] Deleted this compatibility shim file.
- `lib/modules/sales/credit_note/presentation/sales_item_quick_edit_dialog.dart`:
  - [DELETE] Deleted this compatibility export shim file.
- `lib/shared/widgets/dialogs/bulk_items_dialog.dart`:
  - Updated a commented-out import reference to point to `item_quick_edit_dialog.dart`.

#### Backend Files
- None.

Timestamp of Log Update: July 8, 2026 - 9:45 AM (IST)


## 280. Formulation Section Pack Sizes Type Refinement (July 8, 2026)

### Summary
Fixed a runtime `TypeError` in `FormulationSection` where string elements inside the dynamic `packSizeOptions` list triggered a subtype error during Map key dereferencing (`pack['id']`). Cleaned up warning items in `item_quick_edit_dialog.dart`.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/items/items/presentation/sections/formulation_section.dart`:
  - Updated the item mapping logic under `_packStyleDropdown()` to perform safe type introspection (distinguishing between nullable, String, Map, and custom model inputs) before retrieving unit pack names, eliminating `TypeError: "id": type 'String' is not a subtype of type 'int'`.
- `lib/shared/widgets/dialogs/item_quick_edit_dialog.dart`:
  - Fixed dead code / non-nullable warnings inside both Goods/Service unit dropdown `displayStringForValue` callbacks by returning `id` directly.

#### Backend Files
- None.

Timestamp of Log Update: July 8, 2026 - 9:55 AM (IST)


## 281. Replace Legacy QuickNewItemDialog with ItemQuickEditDialog (July 8, 2026)

### Summary
Replaced all occurrences of `QuickEditItemDialog` and `QuickNewItemDialog` in `composite_items_create.dart` with the new reusable `ItemQuickEditDialog`. Completely deleted `quick_new_item_dialog.dart` as it is no longer referenced anywhere in the codebase.

### Detailed Engineering Changes

#### Frontend Files
- `lib/modules/items/composite_items/presentation/composite_items_create.dart`:
  - Replaced the import of `quick_new_item_dialog.dart` with `item_quick_edit_dialog.dart`.
  - Updated `_showEditAssociateItemDialog` to fetch the matched product from the global products state and display `ItemQuickEditDialog`.
  - Updated both settings dropdown action callbacks (for goods and services) to present `ItemQuickEditDialog` initialized with a new template `Item`.
- `lib/shared/widgets/dialogs/quick_new_item_dialog.dart`:
  - [DELETE] Deleted this file entirely.

#### Backend Files
- None.

Timestamp of Log Update: July 8, 2026 - 10:00 AM (IST)

## 282. Integration of Purchases Expenses & Recurring Expenses Modules (July 8, 2026)

### Summary
Successfully merged and integrated purchases expenses and recurring expenses modules across the frontend (Flutter) and backend (NestJS). Configured routing paths, imported module registrations on both sides, resolved multi-tenancy resolution via tenant middleware, and fixed compilation issues without altering core theme styles.

### Detailed Engineering Changes

#### Frontend Files
- [app_routes.dart](file:///c:/Users/User/Documents/work/zerpai/lib/core/routing/app_routes.dart):
  - Added `expensesReceiptsInbox` and `recurringExpensesCustomView` route constants.
- [app_router.dart](file:///c:/Users/User/Documents/work/zerpai/lib/app/routing/app_router.dart):
  - Imported new page widgets (`ExpensesReportPage`, `ExpensesCreatePage`, `ExpensesReceiptsInboxPage`, `ExpensesOverview`, `PurchasesRecurringExpensesPage`, `PurchasesRecurringExpensesCreatePage`, `PurchasesRecurringExpensesCustomViewPage`).
  - Added GoRouter route paths for `/purchases/expenses`, `/purchases/expenses/create`, `/purchases/expenses/receipts-inbox`, `/purchases/expenses/:id`, `/purchases/recurring-expenses`, `/purchases/recurring-expenses/create`, and `/purchases/recurring-expenses/custom-view`.
- Modified newly added pages/widgets under `lib/modules/purchases/expenses` and `lib/modules/purchases/recurring_expences`:
  - Replaced all occurrences of `AppTheme.transparent` with Flutter's native `Colors.transparent` to resolve linter errors.

#### Backend Files
- [purchases.module.ts](file:///c:/Users/User/Documents/work/zerpai/backend/src/modules/purchases/purchases.module.ts):
  - Registered `ExpensesModule` and `RecurringExpensesModule` under purchases import/export dependencies.
- [tenant.middleware.ts](file:///c:/Users/User/Documents/work/zerpai/backend/src/common/middleware/tenant.middleware.ts):
  - Registered the `/api/v1/recurring-expenses` prefix mapping to the `recurring_expenses` module key for multi-tenant entity resolution.

#### Backups Created
- Backup location: [20260708_155738-expenses/](file:///c:/Users/User/Documents/work/zerpai/backups/refactor-batches/20260708_155738-expenses) (renamed all backed up files to `.bak`).

Timestamp of Log Update: July 8, 2026 - 4:45 PM (IST)

## 18. PO Approval Dialog Enhancements & API Integration (July 10, 2026)

### Summary
Enhanced the branch Purchase Order approval workflow for Starlex Healthcare Pvt. Ltd. by displaying credit limits in the awaiting approval dialog, removing unnecessary column layouts, and introducing automated picklist and sales order generation upon approval.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart:
  - Added creditLimit field to the PurchaseOrder model with mapping and copying support.
- lib/modules/sales/sales_orders/data/services/sales_order_api_service.dart:
  - Added pprovePurchaseOrders call to hit the new POST endpoint.
- lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart:
  - Modified columns in _RemainingPoApprovalDialog: removed "WAREHOUSE", renamed "BRANCH" to "CUSTOMER", and added "CREDIT LIMIT".
  - Replaced the dialog footer "Close" button with left-aligned "Approve" and "Cancel" buttons.
  - Linked the "Approve" button to call the POST endpoint, notify on success/error, invalidate provider state, and close the dialog.

#### Backend Files
- ackend/src/modules/sales/services/sales.service.ts:
  - Updated getAwaitingPoApprovals() to resolve each branch's corresponding customer record via the ssociated_branch_id and the branch's 
ef_id inside organisation_branch_master, returning the resolved credit_limit.
  - Implemented pprovePurchaseOrders() to convert selected branch POs into confirmed Sales Orders (status: 'confirmed') and automatically generate a linked picklist (status: 'DRAFT') and its picklist_items (status: 'YET_TO_START', qty_picked: 0.0).
- ackend/src/modules/sales/controllers/sales.controller.ts:
  - Exposed the POST route /api/v1/sales/awaiting-po-approvals/approve.

Timestamp of Log Update: July 10, 2026 - 10:45 AM (IST)

## 19. PO Approval Error Handling & Database Constraints Resolution (July 10, 2026)

### Summary
Fixed a database insertion error in PO approval workflow where the ccounts column in sales_order_items was missing, violating its not-null database constraint. Also converted the error message display from a bottom screen SnackBar to a custom popup error dialog.

### Detailed Engineering Changes

#### Frontend Files
- lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart:
  - Replaced the bottom screen SnackBar error message with a custom styled Dialog modal error popup using showDialog matching the Zerpai UI design framework.

#### Backend Files
- ackend/src/modules/sales/services/sales.service.ts:
  - Fixed pprovePurchaseOrders to query product sales_account_id and fall back to the default sales account of Starlex ORG to fill the ccounts column of sales_order_items.

Timestamp of Log Update: July 10, 2026 - 11:00 AM (IST)

## 20. Clone/Void Logic & Convert to PO Dropship Support in Sales/Purchase Orders (July 11, 2026)

### Summary
Implemented "Clone" and "Void" operations for Sales Orders, resolved item loading issues when converting Sales Orders to Purchase Orders, and added support for complete and partial dropshipping where custom customer addresses are passed automatically. Also ensured dropship purchase orders render as a new PO form (not edit mode) and only show the "DropShip To" address instead of standard delivery controls.

### Detailed Engineering Changes

#### Frontend Files
- [app_router.dart](file:///c:/Users/User/Documents/work/zerpai/lib/app/routing/app_router.dart):
  - Passed isClone query parameters to SalesOrderCreateScreen.
  - Passed isClone, isDropship, dropshipCustomerName, and dropshipAddress query parameters to PurchaseOrderCreateScreen.
- [sales_order_create.dart](file:///c:/Users/User/Documents/work/zerpai/lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart):
  - Added isClone field and constructor parameter to SalesOrderCreateScreen.
  - Decoupled _isEditMode so it resolves to false when isClone is true, ensuring cloning creates a new record instead of modifying the existing one.
  - Implemented _hydrateFromInitialOrder for cloning: clears salesOrderNumberCtrl, referenceCtrl, sets order date to today, sets expected shipment date to null, and resets item cancelled quantities to 0.0.
  - Added deep-link check in initState to fetch initial sales order by widget.cloneId when widget.initialOrder is null.
- [purchases_purchase_orders_create.dart](file:///c:/Users/User/Documents/work/zerpai/lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart):
  - Added isClone, isDropship, dropshipCustomerName, and dropshipAddress fields/parameters to PurchaseOrderCreateScreen.
  - Decoupled _isEditMode to evaluate to false when either isClone or isDropship is true.
  - Rendered a custom "DropShip To" row with customer details instead of the "Delivery Address" input controls when isDropship is true.
  - Implemented _hydrateFromInitialOrder: clears poNumberCtrl, refCtrl, sets order date to today, expected delivery date to null, and resets item cancelled quantities to 0.0 when cloning or dropshipping.
- [sales_order_list.dart](file:///c:/Users/User/Documents/work/zerpai/lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart):
  - Handled "Void" action by updating status to 'void' in Supabase and invalidating controllers/refreshing cache.
  - Handled "Clone" action by routing with clone=true and cloneId.
  - Redesigned the "Cancel Sales Order Items" dialog: set width to 850px, styled headers, left-aligned buttons, and computed accurate invoiced/shipped quantities dynamically using database queries.
  - Implemented complete and partial dropshipping dialog choices: allowed selecting items, copy descriptions preference, and resolved stock mapping before routing to PO creation with dropship parameters.

#### Backend Files
- None.

Timestamp of Log Update: July 11, 2026 - 11:30 AM (IST)
## 21. Sales Order & Invoice Create Compilation Resolution (July 11, 2026)

### Summary
Resolved compiler and analysis errors caused by brace mismatches and incorrect scoping of the _HoverableSalesDescription and _HoverableSalesDescriptionState classes in both the Sales Orders and Invoices create screens.

### Detailed Engineering Changes

#### Frontend Files
- [sales_order_create.dart](file:///c:/Users/User/Documents/work/zerpai/lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart):
  - Removed early class closing brace in _buildDescriptionField.
  - Shifted _HoverableSalesDescription and _HoverableSalesDescriptionState outside the _SalesOrderCreateScreenState class to the bottom of the file, restoring the class scope of the remaining helper methods.
- [sales_invoice_create.dart](file:///c:/Users/User/Documents/work/zerpai/lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart):
  - Removed early class closing brace in _buildDescriptionField.
  - Shifted _HoverableSalesDescription and _HoverableSalesDescriptionState outside the _SalesInvoiceCreateScreenState class to the bottom of the file, resolving similar compiler diagnostics.
- [index.html](file:///c:/Users/User/Documents/work/zerpai/web/index.html):
  - Added Open Graph meta tags to satisfy SEO checklist verification requirements.

#### Backend Files
- None.

Timestamp of Log Update: July 11, 2026 - 12:00 PM (IST)


## 22. Dropshipping & Convert to Purchase Order Enhancements (July 11, 2026)

### Summary
Implemented complete and partial dropshipping workflows when converting a Sales Order to a Purchase Order. Added automated mapping of customer addresses, select-items dialog, preferred copy of descriptions, and custom "DropShip To" address rendering on the PO creation page. Also resolved border styling issues on PO line item descriptions.

### Detailed Engineering Changes

#### Frontend Files
- [app_router.dart](file:///c:/Users/User/Documents/work/zerpai/lib/app/routing/app_router.dart):
  - Parsed `isDropship`, `dropshipCustomerName`, and `dropshipAddress` query parameters from the URI and passed them to the `PurchaseOrderCreateScreen`.
- [purchases_purchase_orders_create.dart](file:///c:/Users/User/Documents/work/zerpai/lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart):
  - Integrated `isDropship`, `dropshipCustomerName`, and `dropshipAddress` fields.
  - Decoupled `_isEditMode` to evaluate to `false` when `isDropship` is active, ensuring the dropshipped order generates a new PO form instead of updating an existing one.
  - Hydrated the PO items from the Sales Order extra payload, mapping descriptions correctly, clearing quantities cancelled/received/billed, setting date to today, and resetting delivery dates.
  - Built a custom "DropShip To" display row when `isDropship` is true, overriding the standard warehouse delivery controls to show the customer address.
  - Fixed border rendering on the line item description input fields by setting all input borders to `InputBorder.none` to resolve styling issues.
- [sales_order_list.dart](file:///c:/Users/User/Documents/work/zerpai/lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart):
  - Updated `_convertToPurchaseOrder` to present a dialog asking the user to choose between Complete Dropship or Partial Dropship.
  - In the dropship configuration modal, allowed selecting specific items, choosing whether to copy item descriptions, and displaying customer shipping/billing addresses.
  - Extracted and formatted the customer's shipping address (falling back to billing address) to pass as query parameters.
  - Routed to PO create screen with the populated extra payload (items, vendor) and dropship query flags.

#### Backend Files
- None.

Timestamp of Log Update: July 11, 2026 - 1:00 PM (IST)

## 1) [2026-07-01 15:43:06] Handoff1-07-2026 Arun residual merge triage and canonical integration

- Scope:
  - inbound handoff folder reviewed: `E:\Chrome Downloads\qs\handoff merge\handoff1-07-2026 arun`
  - repo target: `E:\zerpai-new`
  - backup: `E:\zerpai-new\backups\refactor-batches\20260701-154026-handoff1-07-2026-arun`

- Frontend Files:
  - `lib/shared/widgets/dialogs/bulk_items_dialog.dart`
    - Merged the still-missing shared bulk-item quantity-entry behavior from the handoff into the canonical shared dialog instead of leaving quantity changes limited to the sales-order-local dialog.
    - Added persistent `TextEditingController` ownership for selected-row quantity cells so manual numeric typing no longer loses focus or collapses on rebuild.
    - Replaced the static quantity label with a digits-only `TextFormField`, kept plus/minus steppers, and synchronized typed values back into `_itemQuantities`.
    - Hardened row removal/controller disposal so deselect/remove paths do not leak controller instances.
    - Normalized submit payload so empty or non-positive typed values still fail soft to `1` instead of emitting invalid selected quantities.
  - `lib/shared/widgets/inputs/zerpai_calendar.dart`
    - Merged the remaining handoff visual rule for adjacent-month active dates to render with the same primary dark text treatment as current-month active dates while preserving the existing disabled-date styling and clickability.

- Backend Files:
  - No backend files were overwritten in this batch.
  - Reviewed residual handoff backend files against current repo copies and intentionally skipped blind merge where the handoff content was stale, already superseded locally, or contradicted current repo truth sources:
    - `backend/src/db/db.ts`
    - `backend/src/modules/lookups/lookups.controller.ts`
    - `backend/src/modules/purchases/bills/controllers/bills.controller.ts`
    - `backend/src/modules/purchases/bills/dto/create-bill.dto.ts`
    - `backend/src/modules/purchases/bills/services/bills.service.ts`
    - `backend/src/modules/purchases/purchase-orders/dto/create-purchase-order.dto.ts`
    - `backend/src/modules/purchases/purchase-orders/services/purchase-orders.service.ts`
    - `backend/src/modules/purchases/purchase-orders/utils/po-status.ts`
    - `backend/src/modules/purchases/purchase-receives/services/purchase-receives.service.ts`
  - Why skipped:
    - `current schema.md` still declares `purchase_orders.shipping_address` and `purchase_orders.billing_address` as `uuid NOT NULL`, so the handoff startup DDL that relaxed those columns to nullable was not merged.
    - Multiple backend handoff files were older than the current working repo copy and would have removed newer account-visibility, multi-PO bill matching, DTO field coverage, or receive/bill allocation logic.

- Additional reviewed inbound files not force-merged:
  - `lib/shared/widgets/inputs/dropdown_input.dart`
  - `lib/shared/widgets/inputs/warehouse_popover.dart`
  - These were left as-is because the residual handoff copies did not represent a safe strict improvement over the current repo state.

- Verification:
  - Ran `dart format lib/shared/widgets/dialogs/bulk_items_dialog.dart lib/shared/widgets/inputs/zerpai_calendar.dart`
    - Result: pass.
  - Ran `flutter analyze --no-pub lib/shared/widgets/dialogs/bulk_items_dialog.dart lib/shared/widgets/inputs/zerpai_calendar.dart`
    - Result: `No issues found!`

- Residual risks / follow-up context:
  - The repo still contains broader uncommitted frontend handoff work outside this residual merge slice; those files were not rewritten here.
  - `paths.txt` referenced `lib/shared/widgets/dialogs/edit_quantity_dialog.dart`, but that source file no longer exists inside the residual handoff folder, so the existing repo copy remains the live working version.
  - This batch intentionally prioritized canonical merge safety over folder-copy parity.

Timestamp of Log Update: July 1, 2026 - 3:43 PM (IST)

## 2) [2026-07-15 13:03:14] Shared dropdown/date-picker stabilization and deletion audit

- Scope:
  - stabilized shared account selection overlay rebuild behavior after manual-journal account selection
  - corrected shared calendar weekday/day-grid alignment and adjacent-month styling drift
  - normalized one remaining raw date-picker usage to the shared ZerpaiDatePicker
  - audited current tracked deletions after .git metadata swap to separate real code deletes from backup/history noise

- Frontend Files:
  - lib/shared/widgets/inputs/account_tree_dropdown.dart
    - Hardened overlay rebuild scheduling so overlay refresh requests triggered during widget build are deferred to the next frame instead of calling markNeedsBuild() mid-build.
    - This directly addresses the _OverlayEntryWidget ... called during build failure seen after selecting accounts in manual journals.
  - lib/modules/purchases/recurring_expences/presentation/widgets/account_tree_dropdown_with_add_widget.dart
    - Mirrored the same deferred overlay rebuild guard in the recurring-expenses account dropdown variant so the account-dropdown family behaves consistently.
  - lib/shared/widgets/inputs/zerpai_calendar.dart
    - Replaced the free-flowing day-cell Wrap layout with a deterministic 6x7 table grid so weekday headers and day cells stay aligned.
    - Restored proper adjacent-month text treatment so non-current-month days no longer render with the same emphasis as current-month active dates.
  - lib/modules/inventory/shipments/presentation/pages/inventory_shipments_list.dart
    - Replaced one remaining raw showDatePicker(...) call with the shared ZerpaiDatePicker.show(...) contract using a real 	argetKey, keeping calendar behavior aligned with the shared picker path.

- Backend Files:
  - No backend files changed in this batch.

- Deletion audit:
  - Most current D entries are tracked backup/history artifacts (.bak, handoff docs, duplicate schema copies) exposed by the swapped .git metadata rather than fresh functional deletions from the current workspace.
  - Real tracked Dart page deletions verified in current diff:
    - lib/modules/inventory/packages/presentation/pages/inventory_packages_edit.dart
      - No active route or live import currently resolves to this page file.
      - Remaining file lib/modules/inventory/packages/presentation/inventory_packages_edit.dart is only a stale export shim pointing at the deleted page.
      - Disposition: leave deleted page as-is; treat the shim as stale/orphaned follow-up cleanup rather than restore the old screen blindly.
    - lib/modules/pricelists/branch_pricelist/presentation/branch_pricelist_edit_page.dart
      - No active route/import currently depends on the deleted edit page.
      - Current routing/use has shifted to ranch_pricelist_create_page.dart and related live overview/create flow.
      - Disposition: leave deleted edit page as-is; it appears superseded rather than accidentally removed from the active route graph.

- Verification:
  - Ran dart format lib/shared/widgets/inputs/account_tree_dropdown.dart lib/modules/purchases/recurring_expences/presentation/widgets/account_tree_dropdown_with_add_widget.dart lib/shared/widgets/inputs/zerpai_calendar.dart lib/modules/inventory/shipments/presentation/pages/inventory_shipments_list.dart
    - Result: pass.
  - Ran dart analyze lib/shared/widgets/inputs/account_tree_dropdown.dart lib/modules/purchases/recurring_expences/presentation/widgets/account_tree_dropdown_with_add_widget.dart lib/shared/widgets/inputs/zerpai_calendar.dart lib/modules/inventory/shipments/presentation/pages/inventory_shipments_list.dart
    - Result: No issues found!

- Residual risks / follow-up context:
  - Manual journal row-height/layout shifts can still make the grid feel visually jumpy when GST warning rows expand; the build-crash/overlay issue is fixed, but some local table polish remains separate from the shared overlay owner fix.
  - If you want a cleaner git surface next, the stale export shim lib/modules/inventory/packages/presentation/inventory_packages_edit.dart is a safe candidate for explicit cleanup once you confirm no external branch still imports it.

Timestamp of Log Update: July 15, 2026 - 1:03 PM (IST)

## 3) [2026-07-15 13:49:15] Repo-wide shim retirement, route/import repair, and analyzer stabilization

- Scope:
  - completed repo-wide retirement of pure export compatibility shims and stale wrapper files under `lib/`
  - preserved canonical owners under `app/`, `core/`, `shared/`, and module `presentation/pages/` paths by rewiring imports instead of restoring legacy duplicate wrappers
  - repaired shim-removal fallout until full `dart analyze lib` returned with no hard errors
  - kept the earlier shared dropdown/date-picker stabilization intact while continuing the wider cleanup

- Frontend Files:
  - Shim families retired from app/core/shared ownership:
    - `lib/core/layout/zerpai_navbar.dart`
    - `lib/core/layout/zerpai_shell.dart`
    - `lib/core/layout/zerpai_sidebar.dart`
    - `lib/core/providers/org_settings_provider.dart`
    - `lib/core/routing/app_router.dart`
    - `lib/core/services/hive_adapters.dart`
    - `lib/core/services/hive_service.dart`
    - `lib/shared/services/api_client.dart`
    - `lib/shared/utils/error_handler.dart`
    - These were compatibility/export wrappers only. Live ownership already exists in the canonical `app/`, `core/api`, `core/services`, or `core/utils` paths, so keeping both copies only preserved ambiguity.
  - Shim families retired from accountant presentation wrappers:
    - `lib/modules/accountant/manual_journals/presentation/manual_journal_create_screen.dart`
    - `lib/modules/accountant/manual_journals/presentation/manual_journal_template_create_screen.dart`
    - `lib/modules/accountant/manual_journals/presentation/manual_journal_templates_list_screen.dart`
    - `lib/modules/accountant/manual_journals/presentation/manual_journals_overview_screen.dart`
    - `lib/modules/accountant/presentation/accountant_settings_screen.dart`
    - `lib/modules/accountant/recurring_journals/presentation/recurring_journal_create_screen.dart`
    - `lib/modules/accountant/recurring_journals/presentation/recurring_journal_overview_screen.dart`
    - Canonical live screens remain under `presentation/pages/` and router imports were rewired to those page owners.
  - Shim families retired from inventory/items/purchases/reports/sales/settings wrappers:
    - legacy `presentation/*.dart` wrapper files that only re-exported `presentation/pages/*.dart` or equivalent owner files were removed across:
      - inventory adjustments / assemblies / move orders / packages / picklists / shipments / transfer orders
      - items composite-items and items item-create/detail wrappers
      - purchases bills / purchase orders / purchase receives / vendors wrappers
      - reports presentation wrappers
      - sales credit-note / customers / delivery challans / eway bills / invoices / payment links / payments received / quotations / recurring invoices / retainer invoices / sales orders / sales return wrappers
      - settings users / users_roles / pdf_templates wrappers
    - Result: pure-export shim inventory is now empty repo-wide.
  - Credit-note local wrapper cleanup:
    - removed legacy sales-credit-note local dialog/input wrappers that duplicated shared owners:
      - `lib/modules/sales/credit_note/dialogs/advanced_customer_search_modal.dart`
      - `lib/modules/sales/credit_note/dialogs/bulk_items_dialog.dart`
      - `lib/modules/sales/credit_note/inputs/custom_text_field.dart`
      - `lib/modules/sales/credit_note/inputs/dropdown_input.dart`
      - `lib/modules/sales/credit_note/inputs/file_upload_button.dart`
      - `lib/modules/sales/credit_note/inputs/warehouse_popover.dart`
      - `lib/modules/sales/credit_note/inputs/z_tooltip.dart`
    - These were wrapper-style redirects into shared dialog/input owners and were safe to retire once imports moved to the shared implementations.
  - Real import-fallout fixes after shim removal:
    - `lib/modules/accountant/manual_journals/providers/manual_journal_provider.dart`
      - moved import to `core/utils/error_handler.dart` after retiring `shared/utils/error_handler.dart` shim.
    - `lib/modules/home/providers/dashboard_provider.dart`
      - moved import to `core/services/api_client.dart` after retiring `shared/services/api_client.dart` shim.
    - `lib/modules/pricelists/branch_pricelist/presentation/branch_pricelist_overview_page.dart`
      - replaced deleted `core/routing/app_router.dart` import with canonical `core/routing/app_routes.dart` owner.
    - `lib/modules/pricelists/pricelist/presentation/items_pricelist_pricelist_overview.dart`
      - same route-owner correction to `core/routing/app_routes.dart`.
    - `lib/modules/procurement/config/routes.dart`
      - removed dead references to non-existent approval/purchase-request route builders and returned an explicit empty route list because procurement routes are currently composed elsewhere; this removes analyzer breakage without inventing duplicate route ownership.
    - `lib/modules/sales/payments_received/presentation/pages/sales_payment_create.dart`
      - aligned the model import with the actual live `payment_recieved` owner path so the createPayment contract resolves the same concrete model type expected by the repository/API layer.
    - `lib/modules/inventory/adjustments/presentation/pages/inventory_adjustments_overview_screen.dart`
      - corrected the list-panel import to the canonical sibling page file after the legacy wrapper deletion.
    - `lib/modules/inventory/picklists/presentation/pages/inventory_picklists_list.dart`
      - corrected the package-screen import to the canonical `packages/presentation/pages/inventory_packages_list.dart` owner after wrapper deletion.
  - Real deletion classification:
    - `lib/modules/inventory/packages/presentation/pages/inventory_packages_edit.dart`
      - this is the one deleted page file that did not have a remaining live page owner replacement in the same folder. Current route/import graph no longer references it, so it remained deleted rather than being restored blindly.
    - `lib/modules/pricelists/branch_pricelist/presentation/branch_pricelist_edit_page.dart`
      - still absent from the live route/import graph; retained deletion state.
    - Most other deleted Dart files in this batch were not business-feature removals. They were compatibility shims or wrapper files whose live implementation already exists in page/shared/core owners.
  - Repo-wide outcome metrics:
    - deleted Dart shim/wrapper files currently visible in git diff: `98`
    - touched Dart files visible in git diff: `544`
    - pure export shim inventory after cleanup: `0`
    - note: the touched-file count is larger than the deleted-wrapper set because import rewires landed across a very dirty existing worktree and earlier formatting churn already existed before this batch.

- Backend Files:
  - No backend files changed in this shim-retirement batch.

- Verification:
  - Ran `dart format lib/modules/inventory/adjustments/presentation/pages/inventory_adjustments_overview_screen.dart lib/modules/inventory/picklists/presentation/pages/inventory_picklists_list.dart`
    - Result: pass.
  - Ran `dart analyze lib`
    - Result: no hard errors.
    - Remaining non-blocking analyzer output: `17 issues found`.
    - Remaining issues are warning/info cleanup only, concentrated in:
      - `lib/modules/pricelists/pricelist/presentation/items_pricelist_pricelist_edit.dart`
      - `lib/modules/purchases/purchase_returns/presentation/purchases_purchase_returns_report.dart`
      - `lib/shared/widgets/dialogs/edit_quantity_dialog.dart`
      - deprecated radio API usage in `lib/modules/purchases/payments_made/presentation/pages/purchases_payments_made_list.dart`
      - deprecated radio API usage in `lib/modules/purchases/vendors/presentation/dialogs/clone_vendor_dialog.dart`

- Smoothness / safety notes:
  - Shared dropdown/date-picker owner fixes from batch 2 remain in place and were not regressed by the shim pass.
  - The shim retirement reduced route/import indirection substantially, which should make future refresh/debug behavior more predictable because pages now import canonical owners directly instead of chaining through legacy wrapper files.
  - I did not restore deleted wrapper files simply to silence missing imports; each break was repaired by pointing callers at the actual owner file.
  - I intentionally stopped at analyzer-clean-hard-errors rather than broad warning cleanup so this batch stays focused on structural retirement and does not mix unrelated refactors into the same pass.

- Residual risks / follow-up context:
  - The worktree remains globally noisy because of many unrelated pre-existing frontend/backend modifications and backup/doc deletions from the swapped `.git` history; those were not normalized in this batch.
  - The remaining 17 analyzer warnings/info are good next-step cleanup candidates, but they are not shim-removal regressions.
  - If you want, the next safe pass is either:
    - warning-only analyzer cleanup, or
    - visual/manual QA on the manual-journal table and shared date/dropdown flows now that structural wrapper indirection is gone.

Timestamp of Log Update: July 15, 2026 - 1:49 PM (IST)

## 4) [2026-07-15 15:29:00] Repo-wide Flutter runtime hardening: overlay lifecycle, nullable callback safety, and journal init guards

- Scope:
  - hardened shared dropdown overlay rebuild timing to stop overlay markNeedsBuild() calls from firing during active widget build/layout phases
  - added sidebar overlay/timer disposal so floating submenu state cannot outlive the sidebar widget lifecycle
  - removed repo-wide high-confidence nullable callback force unwraps (`v!`) across dropdown/radio/checkbox flows that could throw under null callbacks or tri-state interactions
  - guarded manual-journal and recurring-journal initialization/build paths so optional source objects are captured once and dereferenced safely
  - kept the batch minimal and ownership-aligned: shared fix in shared owner, layout fix in shell owner, local null-safety fixes only where runtime risk was concrete

- Frontend Files:
  - `lib/shared/widgets/inputs/dropdown_input.dart`
    - Imported `SchedulerBinding` and mirrored the deferred overlay rebuild pattern already used in `account_tree_dropdown.dart`.
    - Added `_overlayRebuildQueued` and deferred rebuild scheduling so shared form dropdown overlays no longer attempt `markNeedsBuild()` during forbidden scheduler phases.
    - This is the shared-owner fix for the reported awkward post-selection dropdown behavior and the prior `_OverlayEntryWidget` assertion class.
  - `lib/app/layout/zerpai_sidebar.dart`
    - Added `dispose()` to cancel `_hideTimer` and remove `_submenuOverlay` through `_removeFloatingMenu()` before teardown.
    - This closes a real lifecycle gap where the sidebar could leave overlay/timer work behind after route/layout transitions.
  - `lib/modules/accountant/manual_journals/presentation/pages/manual_journal_create_screen.dart`
    - Captured `initialJournal` / `template` into local guarded variables during `initState()` before hydration.
    - Removed direct optional dereference reliance in the journal builder by sourcing `id` / `createdAt` from the guarded local object with fallback defaults.
    - This keeps edit/template/create entry paths stable even if future callers toggle constructor combinations or delayed route state.
  - `lib/modules/accountant/recurring_journals/presentation/pages/recurring_journal_create_screen.dart`
    - Guarded initial hydration for `initialJournal` and `initialManualJournal`.
    - Replaced nullable callback force unwraps for custom frequency unit, never-expires checkbox, and currency selection with null-safe assignments.
  - `lib/modules/accountant/presentation/pages/accountant_settings_screen.dart`
    - Removed force unwraps from base-currency and rounding-type dropdown callbacks.
  - `lib/modules/inventory/packages/presentation/pages/inventory_packages_create.dart`
    - Removed force unwraps from manufacture-details / FOC / overwrite checkboxes using `v ?? false`.
  - `lib/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart`
    - Removed force unwraps from export-format radio callbacks.
  - `lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart`
    - Removed force unwrap from payment-mode dropdown callback.
  - `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`
    - Removed restart-monthly checkbox force unwrap.
    - Refactored `_selectVendor(...)` to capture `tdsRateId`, `paymentTerms`, and `sourceOfSupply` once and reuse them without repeated nullable re-unwrap expressions.
    - This eliminated the remaining analyzer/runtime-sensitive nullable dereferences in the vendor autofill path.
  - `lib/modules/sales/payments_received/presentation/pages/sales_payment_create.dart`
    - Removed force unwrap from payment-mode dropdown callback.
  - `lib/modules/sales/delivery_challans/presentation/pages/sales_delivery_challan_create.dart`
    - Removed force unwraps from challan-type dropdown and row item selection callbacks.
  - `lib/modules/sales/recurring_invoices/presentation/pages/sales_recurring_invoice_create.dart`
    - Removed force unwraps from frequency dropdown and row item selection callbacks.
  - `lib/modules/sales/customers/presentation/sections/sales_customer_dialogs.dart`
    - Removed force unwrap from customer search-type selector callback.
  - `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`
    - Removed force unwrap from phone-code dropdown callback inside the invoice customer/contact flow.
  - `lib/shared/widgets/dialogs/address_dialog.dart`
    - Removed force unwrap from phone-code dropdown callback inside the shared address dialog.
  - `lib/modules/sales/credit_note/presentation/pages/sales_item_quick_edit_dialog.dart`
    - Removed force unwraps from tax preference, valuation method, and inline radio callback flows.
  - `lib/modules/sales/sales_orders/presentation/widgets/sales_item_quick_edit_dialog.dart`
    - Removed the same force unwrap pattern from the sales-order quick-edit twin so both item-edit variants stay behaviorally aligned.
  - `lib/shared/widgets/dialogs/item_quick_edit_dialog.dart`
    - Removed the same force unwrap pattern from the shared item quick-edit dialog, keeping the shared/local variants consistent.

- Backend Files:
  - No backend files changed in this runtime-hardening batch.

- Verification:
  - Re-scan before patching:
    - Ran `rg -n 'v!' lib --glob '*.dart'`.
    - Result: 31 force-unwrap callback occurrences concentrated in shared dialogs, accountant flows, purchase flows, and sales quick-edit/create flows.
  - Post-patch re-scan:
    - Ran `rg -n 'v!' lib --glob '*.dart'`.
    - Result: no remaining `v!` matches under `lib/`.
    - Ran `rg -n 'initialJournal!|initialManualJournal!' lib --glob '*.dart'`.
    - Result: no remaining recurring/manual journal init force-unwrap matches.
  - Formatting:
    - Ran `dart format` across all 18 touched Dart files, then re-ran it once for `purchases_purchase_orders_create.dart` after the final vendor-guard follow-up patch.
    - Result: pass.
  - Analyzer validation:
    - Ran `flutter analyze --no-pub lib/shared/widgets/inputs/dropdown_input.dart lib/app/layout/zerpai_sidebar.dart lib/modules/accountant/presentation/pages/accountant_settings_screen.dart lib/modules/accountant/recurring_journals/presentation/pages/recurring_journal_create_screen.dart lib/modules/accountant/manual_journals/presentation/pages/manual_journal_create_screen.dart lib/modules/inventory/packages/presentation/pages/inventory_packages_create.dart`.
    - Result: `No issues found!`
    - Ran `flutter analyze --no-pub lib/modules/sales/credit_note/presentation/pages/sales_item_quick_edit_dialog.dart lib/modules/sales/sales_orders/presentation/widgets/sales_item_quick_edit_dialog.dart lib/shared/widgets/dialogs/item_quick_edit_dialog.dart lib/shared/widgets/dialogs/address_dialog.dart lib/modules/sales/customers/presentation/sections/sales_customer_dialogs.dart lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`.
    - Result: `No issues found!`
    - Ran `flutter analyze --no-pub lib/modules/sales/payments_received/presentation/pages/sales_payment_create.dart lib/modules/sales/delivery_challans/presentation/pages/sales_delivery_challan_create.dart lib/modules/sales/recurring_invoices/presentation/pages/sales_recurring_invoice_create.dart`.
    - Result: `No issues found!`
    - Ran `flutter analyze --no-pub lib/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart`.
    - Result: `No issues found!`
    - Ran `flutter analyze --no-pub lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart`.
    - Result: `No issues found!`
    - Ran `flutter analyze --no-pub lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`.
    - Result: `No issues found!`
    - One earlier attempt to analyze the whole changed set in a single command timed out; validation was then completed successfully in split batches to get deterministic results per file group.

- Smoothness / safety notes:
  - Shared dropdown rebuild timing is now aligned with the already-hardened account-tree dropdown owner, so dropdown overlays across the repo follow the same safe scheduler-phase contract.
  - Sidebar teardown now actively cleans its floating submenu state instead of relying on route replacement to clean overlays implicitly.
  - The null-safety pass intentionally targeted callback/runtime hazards only; it did not mix broader visual redesign or table-layout refactors into the same batch.

- Residual risks / follow-up context:
  - Remaining `widget.template!` matches in other modules are still guarded by surrounding `if (widget.template != null)` checks and were not part of the failing accountant/shared runtime paths addressed here.
  - This batch improves crash/assertion safety and interaction smoothness, but it does not yet redesign wider layout-density issues such as large-table responsiveness or form-height polish outside the touched owners.

Timestamp of Log Update: July 15, 2026 - 3:29 PM (IST)


## 5) [2026-07-16 11:55:58] Feature-flagged production observability system

- Scope:
  - implemented shared Flutter and NestJS observability owners without changing
    business rules, DTO contracts, tenant filtering, transaction workflows, or
    database schema
  - default-off feature flag:
    - Flutter: ENABLE_PERFORMANCE_MONITORING dart-define
    - Backend: ENABLE_PERFORMANCE_MONITORING environment variable
  - bounded in-memory collectors and configurable sampling prevent unbounded
    telemetry retention
  - all exported records omit raw payloads, tokens, passwords, bind values, and
    SQL text

- Frontend Files:
  - lib/core/observability/performance_telemetry.dart
    - added compile-time enablement, console/development/production modes,
      sampling, correlation IDs, bounded event storage, JSON/CSV export
    - added dart:developer Timeline spans and measureSync/measureAsync helpers
    - added SchedulerBinding.addTimingsCallback for build/raster/total frame
      timing, dropped-frame, and long-frame events
    - added Riverpod ProviderObserver hooks for provider add/update/dispose
      invalidation signals
    - added NavigatorObserver route push/pop events
  - lib/core/observability/dio_telemetry_interceptor.dart
    - records API method/path/status/duration/request bytes/response bytes/error
    - injects X-Request-ID correlation header
    - measures response payload size without logging response content
  - lib/core/observability/browser_performance_observer.dart
    - added conditional web/stub export so non-web targets do not import JS APIs
  - lib/core/observability/browser_performance_observer_web.dart
    - observes supported resource, longtask, event, paint, LCP, and layout-shift
      PerformanceObserver entries
  - lib/core/observability/browser_performance_observer_stub.dart
    - no-op implementation for non-JS platforms
  - lib/main.dart
    - starts telemetry before runApp only when enabled
    - installs ProviderObserver only when enabled
  - lib/app/routing/app_router.dart
    - installs NavigatorObserver only when enabled
  - lib/core/services/api_client.dart
    - installs Dio telemetry interceptor only when enabled
    - records cache lookup hit/miss events
    - preserves existing timestamp request IDs when telemetry is disabled and
      preserves the telemetry correlation ID when enabled

- Backend Files:
  - backend/src/common/observability/observability.service.ts
    - added sampled bounded collector, HTTP/database record helpers, JSON/CSV
      export, console mode, and correlation ID generation
  - backend/src/common/observability/correlation.middleware.ts
    - creates or propagates X-Request-ID and attaches request start time
    - no-op path when monitoring is disabled
  - backend/src/common/observability/observability.interceptor.ts
    - measures route/controller/handler/status/request bytes/response bytes/
      total request duration
    - counts chunked response writes so response size is captured when no
      Content-Length header exists
  - backend/src/common/observability/observability.controller.ts
    - added protected operational export endpoint:
      /api/v1/telemetry/export?format=json|csv
    - sets no-store and content type; existing tenant/auth middleware remains
      responsible for access control
  - backend/src/app.module.ts
    - registers observability service/controller/interceptor
    - orders correlation middleware before tenant middleware
  - backend/src/main.ts
    - registers global observability interceptor after existing audit and
      standard-response interceptors
  - backend/src/db/db.ts
    - uses a feature-flagged Postgres client proxy to time tagged-template and
      unsafe query promises
    - records hashed query fingerprints, duration, row count, and errors
    - emits query-submitted events without storing SQL text
  - backend/src/common/interceptors/standard_response.interceptor.ts
    - leaves telemetry export responses unwrapped so JSON/CSV formats remain
      machine-readable

- Documentation:
  - OBSERVABILITY.md
    - implementation plan, Mermaid architecture, modified/new file inventory,
      telemetry/logging schemas, correlation flow, metrics catalog, dashboard
      panels, rollout order, safety boundaries

- Verification:
  - dart format on all new/touched observability Dart files: pass
  - dart analyze lib/core/observability: No issues found
  - dart analyze touched Flutter integration files:
    - lib/main.dart
    - lib/core/services/api_client.dart
    - lib/app/routing/app_router.dart
    - Result: No issues found
  - npm.cmd run build in backend: exit=0
  - git diff --check: pass; only CRLF normalization warnings
  - existing unrelated edit lib/shared/widgets/dialogs/edit_quantity_dialog.dart
    was preserved and not modified by this batch

- Residual risks / explicit limits:
  - global Flutter hooks cannot identify individual widget build duration or
    service-method duration without owner-local span calls; helper APIs are
    provided for those boundaries
  - response bytes are exact for writes observed by the interceptor; upstream
    compression byte counts require proxy/server telemetry
  - Drizzle query proxy covers tagged-template and unsafe promise execution;
    connection wait/pool usage requires driver/DB exporter metrics
  - no telemetry database table or migration was added, avoiding schema drift
  - no optimization was performed; telemetry must be reviewed and correlated
    before performance changes are proposed

Timestamp of Log Update: July 16, 2026 - 11:55 AM (IST)


## 6) [2026-07-16 12:03:14] Observability web-build verification follow-up

- Verification:
  - Ran flutter build web --release with:
    - ENABLE_PERFORMANCE_MONITORING=true
    - PERFORMANCE_MONITORING_MODE=production
  - Result: web_exit=0.
  - This validates the conditional package:web PerformanceObserver path used
    by the enabled Flutter Web build.
  - Re-ran dart analyze on observability and all Flutter integration owners:
    - Result: No issues found.
  - Re-ran npm.cmd run build in backend:
    - Result: backend_exit=0.

- Safety:
  - The monitoring flag remains default-off.
  - No optimization, schema migration, business workflow change, or unrelated
    worktree cleanup was performed.

Timestamp of Log Update: July 16, 2026 - 12:03 PM (IST)


## 7) [2026-07-16 12:08:06] Enabled Flutter Web observer compile verification

- Verification:
  - Rebuilt Flutter Web release with
    ENABLE_PERFORMANCE_MONITORING=true and production telemetry mode after
    retaining the browser PerformanceObserver instance.
  - Result: Flutter reported Built build/web.
  - This confirms the package:web conditional observer path compiles in the
    enabled web target after the final telemetry adjustment.

Timestamp of Log Update: July 16, 2026 - 12:08 PM (IST)


## 8) [2026-07-16 12:09:20] Consolidated Zerpai ERP delivery ledger — UI hardening, shim retirement, audits, and observability

- Purpose:
  - consolidated current-session engineering work into one append-only handoff
    entry so future agents can trace what changed, why it changed, and what
    remains intentionally unimplemented
  - this entry supplements, and does not replace, the detailed entries above

- Source-of-truth and governance work completed:
  - refreshed current schema.md as the database authority
  - refreshed REUSABLES.md before shared-owner changes
  - reviewed the recent log.md history and implementation direction
  - reviewed AGENTS.md, PRD governance, Flutter placement rules, tenancy rules,
    workflow rules, migration constraints, and monitoring expectations
  - preserved the required ownership hierarchy:
    - lib/core for infrastructure
    - lib/shared for cross-feature reusable services/widgets
    - lib/modules for business features
    - backend/src/common for cross-cutting backend infrastructure
  - preserved tenant-safe entity_id architecture and existing auth/permission
    flow
  - avoided schema migrations, telemetry tables, business DTO changes, and
    workflow changes

- Frontend Files — shared UI/runtime hardening already completed:
  - lib/shared/widgets/inputs/dropdown_input.dart
    - deferred overlay rebuild requests out of active build/layout phases
    - removed the shared _OverlayEntryWidget markNeedsBuild assertion class
    - retained consistent dropdown behavior for all FormDropdown consumers
  - lib/shared/widgets/inputs/account_tree_dropdown.dart
    - applied the same scheduler-safe overlay rebuild ownership to account trees
  - lib/modules/purchases/recurring_expences/presentation/widgets/
    account_tree_dropdown_with_add_widget.dart
    - mirrored account-tree overlay scheduling for recurring expenses
  - lib/shared/widgets/inputs/zerpai_calendar.dart
    - replaced free-flowing day-cell layout with deterministic 6x7 alignment
    - corrected weekday header/day-cell alignment
    - corrected adjacent-month active/disabled styling
  - lib/modules/inventory/shipments/presentation/pages/
    inventory_shipments_list.dart
    - replaced remaining raw date picker usage with shared ZerpaiDatePicker
  - lib/app/layout/zerpai_sidebar.dart
    - disposes hide timers and floating submenu overlays during teardown
  - accountant/manual-journal and recurring-journal pages
    - guarded nullable initialization paths
    - removed unsafe initial journal/template dereferences
    - kept create/edit/template hydration behavior intact
  - callback safety pass:
    - removed high-confidence nullable callback force unwraps from shared
      dialogs, accountant, procurement, purchases, and sales flows
    - covered dropdown, checkbox, radio, tax, payment, vendor, item, and
      customer callback paths
    - confirmed no remaining v! callback matches under lib/

- Shim/deletion retirement completed:
  - retired pure export compatibility shims repo-wide after import-zero review
  - rewired callers to canonical app/core/shared/module owners
  - removed duplicate presentation wrappers across inventory, items, purchases,
    reports, sales, settings, and accountant areas
  - repaired import fallout in:
    - manual journal provider
    - dashboard provider
    - price-list overview pages
    - procurement route composition
    - sales payment model ownership
    - inventory adjustment and picklist page imports
  - classified real Dart deletions:
    - inventory_packages_edit.dart has no active route/import owner and remains
      deleted rather than being restored blindly
    - branch_pricelist_edit_page.dart is absent from the active route/import
      graph and remains deleted as a superseded page
  - preserved backup/history artifacts exposed by swapped git metadata
  - did not restore deleted .bak/history files or create duplicate wrappers

- Frontend verification for UI/runtime/shim work:
  - dart format passed on all touched UI/runtime files
  - targeted Flutter analyzer runs returned No issues found
  - full lib analyzer reached no hard errors; remaining warnings were
    pre-existing/non-blocking cleanup outside the focused batches
  - verified no remaining v! callback matches under lib/
  - did not alter unrelated user edit:
    lib/shared/widgets/dialogs/edit_quantity_dialog.dart

- Browser and production QA evidence captured:
  - artifacts:
    - CHROME_DEVTOOLS_PERFORMANCE_AUDIT_2026-07-16.md
    - LIVE_PRODUCTION_QA_AUDIT_2026-07-16.md
    - PERFORMANCE_AUDIT_REPORT_2026-07-16.md
    - PRODUCTION_OBSERVABILITY_AUDIT_2026-07-16.md
  - profiled authenticated production Flutter Web CanvasKit routes:
    - home
    - inventory adjustments
    - sales invoices
    - invoice-create interaction
  - measured browser evidence:
    - passive settled FPS approximately 62
    - route FCP 704–792 ms
    - route LCP 756–824 ms
    - CLS 0 in the three route captures
    - route long tasks 4–5 per route
    - route maximum long tasks 236–310 ms
    - click interaction 336 ms
    - maximum interaction frame gap 316.6 ms
    - post-click long tasks 8, cumulative 1,522 ms, maximum 325 ms
    - route heap samples 81.7–122.9 MB
    - CanvasKit CPU samples 239–261 ms
  - measured request repetition:
    - organization lookup nine times
    - auth profile six times
    - branches six times
    - sales invoices four times
    - dashboard summary three times
    - inventory adjustments twice
    - warehouse lookup twice
  - slow client-observed requests:
    - dashboard summary 3,295 ms
    - sales invoices 2,742 ms
    - organization lookup 1,305–1,956 ms
    - inventory adjustments 1,196 ms
    - auth profile 1,179 ms
    - branches up to 1,037 ms
  - console observations:
    - Clarity request blocked by client
    - Apollo warnings likely extension noise
    - service-worker/PWA and IndexedDB initialization logs
    - no confirmed Dart exception or application 401/429/500 in capture
  - documented evidence limits:
    - browser timings are not server-only timings
    - no proof of a memory leak without repeated forced-GC snapshots
    - no Flutter widget/provider or PostgreSQL query attribution was claimed

- Static performance/observability audit completed:
  - separated measured browser values from unmeasured Flutter, backend, and DB
    values
  - documented exact instrumentation needed for:
    - Flutter frame/rebuild/provider spans
    - Dio/cache/decode metrics
    - NestJS request/guard/validation/serialization timings
    - Prisma/Drizzle query timings
    - PostgreSQL plans, locks, pool, and pg_stat_statements
    - browser resource/longtask/LCP/INP/CLS observation
    - repeated heap snapshots and allocation timelines
  - explicitly avoided estimated speed gains or invented p50/p95/p99 values

- Frontend observability implementation:
  - new owner: lib/core/observability/performance_telemetry.dart
    - compile-time ENABLE_PERFORMANCE_MONITORING flag, default false
    - console/development/production modes
    - configurable sampling
    - bounded 2,000-event in-memory collector
    - session/request correlation IDs
    - dart:developer Timeline spans
    - measureSync and measureAsync helpers
    - JSON and CSV export
    - SchedulerBinding frame build/raster/total timing
    - dropped-frame and long-frame markers
    - Riverpod add/update/dispose observer hooks
    - navigation push/pop observer hooks
  - new Dio owner:
    lib/core/observability/dio_telemetry_interceptor.dart
    - request/response/error duration
    - method/path/status
    - request/response encoded byte counts
    - correlation header propagation
    - redaction-by-omission of response/body contents
  - new browser conditional owners:
    - browser_performance_observer.dart
    - browser_performance_observer_web.dart
    - browser_performance_observer_stub.dart
    - web path observes supported resource, longtask, event, paint, LCP, and
      layout-shift PerformanceObserver entries
    - stub path keeps non-JS targets build-safe
    - web observer retained globally to prevent lifecycle garbage collection
  - integration files:
    - lib/main.dart starts monitoring before runApp only when enabled and
      installs ProviderObserver conditionally
    - lib/app/routing/app_router.dart installs NavigatorObserver conditionally
    - lib/core/services/api_client.dart installs Dio telemetry conditionally,
      records cache hits/misses, and preserves existing request-ID behavior when
      monitoring is disabled

- Backend observability implementation:
  - new owner: backend/src/common/observability/observability.service.ts
    - environment flag, sampling, bounded 5,000-record collector
    - HTTP/database record helpers
    - correlation ID generation
    - console mode
    - JSON/CSV export
    - no raw SQL, bind values, passwords, tokens, or business payloads
  - new correlation middleware:
    backend/src/common/observability/correlation.middleware.ts
    - propagates or creates X-Request-ID
    - stores request start time
    - no-op when monitoring disabled
  - new global interceptor:
    backend/src/common/observability/observability.interceptor.ts
    - records method/path/controller/handler/status
    - records request and response bytes
    - measures total request duration
    - counts chunked writes when Content-Length is absent
  - new operational controller:
    backend/src/common/observability/observability.controller.ts
    - JSON export endpoint
    - CSV export endpoint
    - no-store response headers
    - existing tenant/auth middleware remains access boundary
  - integration:
    - backend/src/app.module.ts registers service/controller/interceptor and
      orders correlation middleware before tenant middleware
    - backend/src/main.ts registers global observability interceptor
    - standard response interceptor bypasses telemetry export so JSON/CSV remain
      machine-readable
  - database instrumentation:
    backend/src/db/db.ts
    - feature-flagged Postgres client proxy
    - times tagged-template and unsafe promise execution
    - records hashed query fingerprint, duration, row count, and errors
    - emits query-submitted records without storing SQL text
    - leaves raw client path untouched when monitoring is disabled

- Documentation created:
  - OBSERVABILITY.md
    - implementation plan
    - Mermaid architecture diagram
    - modified/new file inventory
    - telemetry schema
    - logging/export schema
    - correlation flow
    - metrics catalog
    - dashboard design
    - implementation order
    - safety boundaries and known measurement limits

- Verification completed:
  - dart format: pass
  - dart analyze lib/core/observability: No issues found
  - dart analyze all touched Flutter integration owners: No issues found
  - npm.cmd run build from backend: backend_exit=0
  - Flutter Web release build with monitoring enabled:
    - ENABLE_PERFORMANCE_MONITORING=true
    - PERFORMANCE_MONITORING_MODE=production
    - result: Built build/web
  - git diff --check: pass; only expected line-ending normalization warnings
  - no source database migration executed
  - no production data modified
  - no optimization or business logic refactor performed

- Current uncommitted worktree notes:
  - existing user edit remains:
    lib/shared/widgets/dialogs/edit_quantity_dialog.dart
  - existing audit artifacts remain untracked for review
  - new observability source/docs remain untracked until user stages them
  - unrelated prior worktree noise was preserved rather than normalized
  - no commit, push, reset, or destructive cleanup was performed

- Explicit remaining limits:
  - global Flutter hooks cannot automatically name every widget build duration
    or every service-method span without owner-local wrapper calls
  - database driver connection wait/pool usage requires driver/DB exporter data
  - compressed wire-byte counts require proxy/server telemetry
  - population p50/p95/p99 values require sustained production samples
  - next safe step is telemetry-enabled staging capture and correlation review,
    not optimization

Timestamp of Log Update: July 16, 2026 - 12:09 PM (IST)

## 9) [2026-07-16 12:56:02] Observability runtime validation and startup defect fix

- Scope:
  - validated Flutter Web and NestJS startup with performance monitoring
    enabled;
  - authenticated browser smoke-tested dashboard and core ERP routes;
  - exercised accountant manual-journal account dropdown and date control;
  - validated frontend and backend telemetry evidence from live runtime logs;
  - restarted both applications with monitoring disabled for flag-off startup
    verification;
  - no business records were created, edited, published, or deleted.

- Frontend Files:
  - `lib/core/observability/performance_telemetry.dart`
    - fixed `_newCorrelationId()` web runtime failure at line 269;
    - previous `Random.nextInt(1 << 32)` compiled to `nextInt(0)` in the web
      runtime and raised `RangeError: max must be in range 0 < max ≤ 2^32,
      was 0` during provider/browser telemetry callbacks;
    - bounded random maximum to `0x7fffffff`, preserving unique correlation
      IDs while remaining valid for Dart Web JavaScript number semantics;
    - no business, routing, persistence, or UI behavior changed.
  - `OBSERVABILITY_VALIDATION_REPORT_2026-07-16.md`
    - added complete evidence-backed validation report, feature matrix,
      runtime exception record, performance measurement limits, and release
      decision.

- Backend Files:
  - no backend source changes in this validation batch;
  - backend was restarted twice with explicit feature flags to validate both
    enabled and disabled process paths.

- Enabled startup evidence:
  - Flutter command used:
    `flutter run -d chrome --web-port 53431 --dart-define=ENABLE_PERFORMANCE_MONITORING=true --dart-define=PERFORMANCE_MONITORING_MODE=development`;
  - frontend compiled and connected to Chrome after the correlation-ID fix;
  - backend command used with `ENABLE_PERFORMANCE_MONITORING=true` and
    `PERFORMANCE_MONITORING_MODE=development`;
  - Nest watch compilation reported `Found 0 errors`;
  - health endpoint returned HTTP 200 with database and Redis connected;
  - health response emitted `X-Request-ID` and backend telemetry recorded the
    same request correlation value.

- Enabled login and route smoke evidence:
  - browser login with the authorized test credentials succeeded;
  - final URL after login: `/60000000000/home`;
  - route checks reached:
    - `/60000000000/inventory/adjustments`;
    - `/60000000000/sales/invoices`;
    - `/60000000000/accountant/manual-journals`;
    - `/60000000000/accountant/manual-journals/create`;
  - dashboard rendered KPI cards and quick actions;
  - manual-journal form rendered table, account selector, currency selector,
    and date control;
  - account dropdown opened successfully;
  - date control opened/closed without an application exception;
  - direct route refresh recovered to the requested route.

- Frontend telemetry evidence captured in Chrome console:
  - `api_request` login: POST, status 201, duration 1579 ms, request 67 bytes,
    response 1680 bytes;
  - `api_request` dashboard summary: status 200, duration 2485 ms,
    response 1084 bytes;
  - `api_request` branches: status 200, duration 892 ms, response 14616
    bytes;
  - `api_request` organization lookup: status 200, duration 1138 ms,
    response 3301 bytes;
  - `provider_update` and `provider_add` events observed;
  - `route_push` events observed for `/login` and `/home`;
  - `frame` events contained duration, build, raster, dropped, and long-frame
    fields; a measured startup frame reached 1070.3 ms with build 1052.3 ms;
  - browser `longtask` event measured 1074 ms;
  - browser resource entries measured auth resource at 1549.1 ms and dashboard
    resource at 2474.2 ms;
  - correlation IDs were present on emitted records;
  - application-tab error and warning collection returned empty after the
    enabled smoke flow.

- Backend telemetry evidence captured in Nest terminal:
  - `http_request` health event included method/path/status/controller/handler,
    duration, and correlation ID;
  - `http_request` accountant event included
    `AccountantController.findAll` and duration 685.249 ms;
  - database query event included hashed query fingerprint, duration
    9680.8357 ms, row count, and error flag;
  - telemetry export route mapped during Nest startup;
  - unauthenticated export probe correctly returned HTTP 401, proving the
    existing auth boundary remains active; authenticated JSON/CSV body export
    was not completed in this browser session.

- Disabled-mode evidence:
  - backend restarted with `ENABLE_PERFORMANCE_MONITORING=false`; Nest
    compilation reported zero errors and startup completed without telemetry
    startup/query records;
  - frontend restarted with matching false defines; Flutter compiled and a
    fresh tab reached `/login`;
  - full off-mode login/navigation replay was not completed because the Chrome
    automation session became unstable during the fresh-tab form interaction;
  - no off-mode performance overhead percentage is claimed;
  - pre-existing tabs retained their already-loaded enabled Dart bundle and
    were not used as off-mode telemetry evidence.

- Verification commands:
  - `dart analyze lib/core/observability/performance_telemetry.dart`
    - pass: `No issues found!`;
  - enabled Flutter runtime restart after patch
    - pass: login/routes/telemetry completed without RangeError;
  - backend enabled and disabled watch builds
    - pass: `Found 0 errors`;
  - no schema migration, production data mutation, optimization, or unrelated
    source rewrite performed.

- Runtime limitations and residual risks:
  - no Chrome Performance trace/heap snapshot captured in this validation;
    therefore FPS, CPU, memory, LCP, INP, CLS, TTI, and telemetry-overhead
    percentages remain unverified;
  - search/filter/sort/table/dialog custom spans were not individually invoked;
  - authenticated telemetry export and complete false-flag regression remain
    pending;
  - external Clarity script emitted a `sequence` null error in a separate tab;
    source was `scripts.clarity.ms`, not Zerpai code;
  - unrelated Noto font coverage warning was observed in development Chrome;
  - existing user edit `lib/shared/widgets/dialogs/edit_quantity_dialog.dart`
    was preserved.

Timestamp of Log Update: July 16, 2026 - 12:56 PM (IST)

## 10) [2026-07-16 14:42:45] Production Release Validation — July 16, 2026 (latest deployed build)

Scope: live `https://zerpai.pages.dev/login`, authenticated Chrome session, read-only
runtime validation. No source code or business data mutation performed. Full report:
`PRODUCTION_RELEASE_VALIDATION_2026-07-16.md`.

Runtime coverage completed: home/dashboard; Items report; Inventory Adjustments; Sales
Invoices list/create; Purchase Orders; Vendors; Expenses; Accountant Manual Journals
list/create; Reports Center; Profit & Loss; Chart of Accounts; Settings. Account popup,
customer popup, date picker, refresh recovery, and authenticated `/login` redirect were
exercised. Sign-out, CRUD save/publish/delete, exports, alternate roles, and expiry were
not executed because only one authorized session was available and no mutation policy was
provided.

Measured browser/CDP evidence:
- Home reload captured 126 CDP events; actual API responses returned 200 and CORS
  preflights returned 204.
- Actual API durations: auth/profile 1,209 ms; organization lookup 1,431 ms plus a
  duplicate 1,077 ms lookup; dashboard summary 2,366 ms; branches 1,180 ms.
- Sales invoices navigation made two actual `/api/v1/sales/invoices` requests (encoded
  responses about 1,125 and 1,127 bytes).
- Actual API requests carried `X-Request-ID` and tenant headers. Responses exposed a
  trace-related header; no response `X-Request-ID` echo observed.
- Settled CDP sample: JS heap used 140,855,072 bytes (~134.3 MiB), heap total
  191,606,784 bytes (~182.6 MiB), 259 nodes, 339 listeners, script duration 0.149 ms,
  task duration 0.832 ms. Point sample only; no leak conclusion.
- Final application log sample contained zero Zerpai errors and zero warnings. One
  `net::ERR_BLOCKED_BY_CLIENT` script failure remained extension/client attribution,
  not confirmed application failure.

Release blockers found:
1. Public `https://zerpai.pages.dev/assets/assets/.env` returned HTTP 200,
   `application/octet-stream`, 526 bytes, wildcard CORS. Keyword-only scan found no
   obvious secret names; artifact exposure still requires removal, deny-list CI, and
   credential rotation review.
2. Manual Journal create route at 390×844 rendered as a tiny desktop strip with most of
   viewport blank; form not practically operable. Settings reflowed at 390px, so issue is
   route/form-specific.
3. Account dropdown child rows lacked requested bullets in production screenshot; category
   headers and selectable rows were visually insufficiently distinct.

Observability status: request headers/API timing/response bytes verified; route/provider/
frame/PerformanceObserver/long-task/LCP/CLS/INP telemetry, backend/database telemetry,
authenticated JSON/CSV export, and production flag-off comparison not observable in this
session and remain NOT TESTED. Final recommendation: NO broad release until public asset,
mobile form, and duplicate/latency issues are remediated and clean-profile role/workflow
validation is rerun.

Timestamp of Log Update: July 16, 2026 - 01:31 PM (IST)

## 11) [2026-07-16 14:41:43] Frontend .env exposure removal and build-define configuration

- Scope:
  - removed the Flutter Web `.env` asset packaging path that caused the public
    `assets/assets/.env` deployment artifact;
  - removed runtime dotenv loading and standardized frontend configuration on
    compile-time `--dart-define` values;
  - checked Git tracking/ignore state before deciding whether a Git removal was
    required;
  - verified dependency resolution, source analysis, deploy-script syntax, and
    a fresh release web build.

- Root cause:
  - `pubspec.yaml` declared `assets/.env` as a Flutter asset. Flutter therefore
    copied the file under the generated web path `assets/assets/.env`.
  - `lib/main.dart` and `lib/core/services/api_client.dart` also loaded values
    at runtime through `flutter_dotenv`, which made the asset path part of the
    application configuration contract.
  - The deployed production artifact previously returned HTTP 200 for that
    path. Even though the keyword-only scan did not identify an obvious secret
    name, publishing any environment file is unsafe and unnecessary.

- Git audit:
  - `git ls-files --stage -- assets/.env` returned no entries: the file was not
    tracked by the current Git metadata, so `git rm --cached` was not required.
  - `git check-ignore -v assets/.env` resolved to `.gitignore:411:assets/.env`.
  - The local ignored file remains available only as an internal build-input
    source for `deploy-web.ps1`; it is no longer a Flutter asset and is not
    copied into the web output.
  - Existing generated build residue `build/flutter_assets/assets/.env` was
    removed explicitly. Generated build directories remain ignored and were not
    added to Git.

- Frontend Files:
  - `pubspec.yaml`
    - removed the direct `flutter_dotenv` dependency;
    - removed `assets/.env` from the Flutter asset list while preserving images
      and lottie assets.
  - `pubspec.lock`
    - removed the resolved `flutter_dotenv` package entry after dependency
      resolution.
  - `lib/main.dart`
    - removed the dotenv import and both Sentry/Supabase runtime fallback loads;
    - reads `SENTRY_DSN`, `SUPABASE_URL`, and `SUPABASE_ANON_KEY` only through
      `String.fromEnvironment`;
    - fails with an actionable build-define error when required public config is
      absent; no environment values are printed.
  - `lib/core/services/env_service.dart`
    - converted the previously unused dotenv-backed service to a build-define
      service;
    - kept the existing validation API and development/production helpers.
  - `lib/core/services/api_client.dart`
    - removed dotenv fallback for `API_BASE_URL`;
    - preserves debug-web localhost behavior and build-define override while
      retaining the existing release Railway default.

- Deployment / documentation Files:
  - `deploy-web.ps1`
    - reads ignored `.env.local` first, then ignored `assets/.env`, solely as a
      local deployment input;
    - requires `SUPABASE_URL` and `SUPABASE_ANON_KEY` and optionally passes
      `SENTRY_DSN` via `--dart-define`;
    - never prints configuration values and no longer relies on a packaged
      runtime asset.
  - `README.md`
    - replaced frontend `.env` loading instructions with explicit build-time
      define examples;
    - documents that service-role keys, database passwords, JWT secrets, and
      private API keys must never be passed to Flutter Web.

- Security boundary:
  - Supabase URL and anon/public client key are the only Supabase values accepted
    by the frontend build path.
  - Service-role keys, database credentials, JWT signing secrets, and private
    API keys remain backend-only and are not read or emitted by this change.
  - Internal testing may continue using the ignored local file as input, but any
    value that was previously reachable from a deployed artifact must be
    rotated before production release.

- Verification:
  - `flutter pub get` — pass; dependencies resolved and `flutter_dotenv` removed
    from the lockfile.
  - `dart analyze lib/main.dart lib/core/services/env_service.dart lib/core/services/api_client.dart`
    — pass: `No issues found!`.
  - PowerShell parser validation for `deploy-web.ps1` — pass.
  - `flutter build web --release` with local values supplied only as hidden
    command arguments — pass: `Built build\\web`.
  - `build/web/assets/assets/.env` — absent after fresh build.
  - `build/flutter_assets/assets/.env` — stale generated residue removed.
  - Git check — `assets/.env` untracked and ignored; no Git deletion required.
  - WebAssembly dry-run warning remains unrelated: one existing
    `dart:html` import in procurement report code; it does not block the normal
    JavaScript release build.

- Residual risks:
  - Build-time defines are embedded in the browser bundle by design; only public
    client configuration may be supplied.
  - Existing previously deployed copies/CDN caches require a fresh deployment
    and cache purge according to the hosting provider before exposure is gone.
  - Rotate any credentials that may have been present in historical or deployed
    environment artifacts before broad production release.

Timestamp of Log Update: July 16, 2026 - 2:41 PM (IST)

## 12) [2026-07-16 14:42:45] Deployment guard against environment-file artifacts

- Deployment File:
  - `deploy-web.ps1`
    - added a post-build recursive check for `.env` files under `build/web`;
    - deployment now fails closed before Wrangler upload if any environment file
      is present in the generated public artifact;
    - the guard reports only the safety violation and never prints file content
      or configuration values.

- Verification:
  - the preceding release build produced no `.env` files under `build/web`;
  - the deploy script was syntax-checked successfully after adding the guard.

- Rationale:
  - build-time defines are intentional public client configuration, but a
    packaged environment file is an accidental and preventable exposure;
  - failing before upload protects against stale build output, reintroduced
    asset declarations, or future script regressions.

Timestamp of Log Update: July 16, 2026 - 2:42 PM (IST)

## 13) [2026-07-16 15:55:33] API client test cleanup after dotenv retirement

- Frontend Files:
  - `test/core/services/api_client_test.dart`
    - removed the obsolete `flutter_dotenv` import;
    - removed `dotenv.testLoad(...)` setup because `ApiClient` now reads
      configuration only from compile-time defines/defaults;
    - preserved all response-standardizer, cache, and expiry assertions.

- Verification:
  - `flutter test test/core/services/api_client_test.dart`
    - pass: 12 tests passed.
  - No production source behavior changed.

- Scope boundary:
  - unrelated analyzer warnings/TODOs in price-list, purchase-return,
    quantity-dialog, radio, and payment files were not changed in this focused
    dotenv-removal follow-up.

Timestamp of Log Update: July 16, 2026 - 3:55 PM (IST)

## 14) [2026-07-16 16:42:04] Local Flutter startup fix for missing build defines

- Runtime symptom:
  - localhost showed `Initialization Failed` with missing
    `SUPABASE_URL`/`SUPABASE_ANON_KEY` after browser data was cleared.
  - Cache/cookie deletion could not fix this because the values are compile-time
    configuration, not browser state.

- Root cause:
  - the active Flutter process on port `51765` was launched by the IDE with
    `--start-paused` and no `--dart-define` arguments;
  - after dotenv removal, `main.dart` correctly rejected missing configuration
    before Supabase initialization.

- Frontend / tooling Files:
  - `scripts/run-web.ps1`
    - added a local launcher that reads only `SUPABASE_URL`,
      `SUPABASE_ANON_KEY`, and optional `API_BASE_URL` from ignored
      `.env.local`;
    - passes them as hidden build-time defines;
    - never prints configuration values and never loads an environment asset at
      runtime.
  - `README.md`
    - replaced the bare `flutter run -d chrome` shortcut with
      `pwsh -File .\\scripts\\run-web.ps1`.

- Runtime recovery:
  - stopped only the workspace Flutter process occupying port `51765`;
  - relaunched the same port with the required public build defines;
  - Flutter connected to Chrome successfully;
  - `GET http://localhost:51765` returned HTTP 200;
  - served HTML contained neither `Initialization Failed` nor the missing
    Supabase configuration error.

- Verification:
  - PowerShell parser check for `scripts/run-web.ps1` — pass.
  - local public configuration keys present in ignored `.env.local` — pass;
    values were not printed.
  - no source fallback or secret exposure was reintroduced.

Timestamp of Log Update: July 16, 2026 - 4:42 PM (IST)

## 15) [2026-07-16 16:56:38] Detailed local initialization incident record

- User-visible symptom:
  - Chrome at `http://localhost:51765` displayed the Flutter debug banner and
    centered `Initialization Failed` content.
  - The visible exception stated that Supabase URL or anon key was missing and
    instructed passing `SUPABASE_URL` and `SUPABASE_ANON_KEY` through
    `--dart-define`.
  - Clearing site cache, cookies, and storage did not change the result because
    the missing values were never present in the compiled Dart environment.

- Evidence collected:
  - The failed listener was owned by a workspace Flutter `dartvm` process.
  - Its launch command included `flutter_tools.snapshot run`, Chrome, and
    `--start-paused`, but no Supabase build-define arguments.
  - This matched the error exactly; no browser-storage corruption was involved.

- Root-cause chain:
  1. dotenv asset packaging/runtime fallback was intentionally removed to stop
     public `.env` exposure.
  2. `main.dart` now reads Supabase configuration only through compile-time
     `String.fromEnvironment` values.
  3. The IDE/Codex generic launch path still started Flutter without those
     defines.
  4. Supabase initialization correctly stopped rather than using an unsafe
     runtime asset or invented configuration.

- Implemented remediation:
  - Added `scripts/run-web.ps1` as the canonical local web launcher.
  - Launcher reads only these names from ignored `.env.local`:
    `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and optional `API_BASE_URL`.
  - Launcher passes values as build-time defines and prints only a generic
    “values hidden” status message.
  - Launcher rejects missing required keys before starting Flutter.
  - No service-role key, database password, JWT secret, private API key, or
    other backend-only value is read or passed to the frontend.
  - Updated README frontend commands to use the launcher.

- Recovery execution:
  - Confirmed port `51765` was owned by the failed workspace Flutter process.
  - Stopped only that process and verified the port released.
  - Relaunched Flutter on port `51765` with the three public build defines,
    without printing their values.
  - Flutter reported successful Chrome connection after compilation.
  - During the successful run, `GET http://localhost:51765` returned HTTP 200;
    response content contained neither `Initialization Failed` nor the missing
    Supabase configuration message.

- Follow-up state check:
  - At `2026-07-16 16:56:38`, a later probe found port `51765` closed because
    the interactive Flutter process had ended after the validation session.
  - This does not invalidate the successful define-aware startup evidence; it
    means the local server must be started again with the launcher for a new
    session.

- Files changed in this incident:
  - `scripts/run-web.ps1` — new local define-aware launcher.
  - `README.md` — documented launcher command.
  - `log.md` — append-only incident and verification history.

- Verification:
  - PowerShell AST parse for `scripts/run-web.ps1`: pass.
  - Local public key-name presence check: pass; values were not output.
  - Define-aware Flutter startup: pass.
  - Chrome connection: pass.
  - Local HTTP probe during active run: HTTP 200.
  - Initialization-failure text during active run: absent.
  - `git diff --check`: pass; only normal line-ending warnings.

- Operational instruction:
  - Start local web with `pwsh -File .\\scripts\\run-web.ps1`.
  - Do not fix this symptom by restoring `.env` asset loading or placing
    secrets in Flutter source/assets.

Timestamp of Log Update: July 16, 2026 - 4:56 PM (IST)

## 16) [2026-07-16 14:42:45] Historical Git exposure review

- Git history evidence:
  - current index/worktree: `assets/.env` is not tracked;
  - historical commits still contain path history:
    - `a08a95b4` — initial commit added `assets/.env`;
    - `0948a70f` — later modified `assets/.env`;
    - `48a072db` — deleted `assets/.env`;
    - `fe47f91f` — explicitly stopped tracking `assets/.env`.
  - Therefore the current deployment source is clean, but old Git objects may
    still retain historical environment content depending on repository hosting
    retention and clone reachability.

- Action boundary:
  - no history rewrite or force-push was performed; rewriting shared Git history
    is destructive and would require explicit release-owner approval;
  - current-state removal, ignore protection, build-output removal, and deploy
    fail-closed validation are complete;
  - rotate any credential that may ever have been stored in the historical file,
    even if current keyword scans show no obvious private-key label.

Timestamp of Log Update: July 16, 2026 - 2:42 PM (IST)

## 17) [2026-07-17 13:03:41] Settings handoff integration, route wiring, shared control compatibility, and web build validation

- Scope:
  - source handoff reviewed: `E:\Chrome Downloads\settings pages`
  - handoff inventory: 18 folders, 202 files (71 Dart snapshots, 102 markdown notes, and 29 gitkeep/other artifacts)
  - target repo: `E:\zerpai-new`
  - backup created before ownership changes: `backups/refactor-batches/20260717-settings-handoff`
  - no backend or database file was copied because the handoff documentation contains no API contract, DTO, migration, or schema-backed persistence implementation.

- Handoff selection and ownership decisions:
  - selected the latest/largest Expenses handoff from `handoff_purchase_expense_settings` over the older duplicate in `handoff settings sales and purchase`.
  - selected the latest taxation pages from `handoff_taxation_and_compliance` for e-Invoicing and e-Way Bills.
  - selected the canonical lower-case module destinations required by AGENTS.md instead of copying old `SettingsRoutes`, old global router files, old sidebar snapshots, or old overview snapshots.
  - retained the current app router composition and connected feature routes through module settings route builders.
  - did not merge duplicate/conflicting handoff route/sidebar implementations because they would overwrite current tenant-prefixed GoRouter ownership and reintroduce stale path conventions.
  - did not restore handoff-only backup files or documentation into active source trees.

- Frontend Files — settings feature pages integrated:
  - `lib/modules/settings/setup/presentation/pages/settings_general_page.dart`
  - `lib/modules/settings/taxes/direct_taxes/presentation/pages/direct_taxes_create_page.dart`
  - `lib/modules/settings/taxes/presentation/pages/settings_taxes_overview_page.dart`
  - `lib/modules/settings/taxes/presentation/pages/settings_tax_create_page.dart`
  - `lib/modules/settings/taxes/presentation/pages/settings_tax_import_page.dart`
  - `lib/modules/settings/taxes/presentation/widgets/settings_taxes_section_rail.dart`
  - `lib/modules/settings/taxes/e_invoicing/presentation/pages/e_invoicing_page.dart`
  - `lib/modules/settings/taxes/e_way_bills/presentation/pages/e_way_bills_page.dart`
  - `lib/modules/settings/setup/currencies/presentation/pages/currencies_settings_page.dart`
  - `lib/modules/settings/setup/payment_terms/presentation/pages/payment_terms_settings_page.dart`
  - `lib/modules/settings/setup/reminders/presentation/pages/settings_reminders_page.dart`
  - `lib/modules/settings/setup/units_of_measurement/presentation/pages/settings_units_of_measurement_page.dart`
  - `lib/modules/settings/general/customers_and_vendors/presentation/pages/customers_and_vendors_settings_page.dart`
  - `lib/modules/settings/items/presentation/pages/settings_items_page.dart`
  - `lib/modules/settings/items/presentation/pages/items_custom_field_create_page.dart`
  - `lib/modules/settings/approvals/approval/presentation/pages/approval_create_page.dart`
  - `lib/modules/settings/approvals/approval/presentation/pages/approval_report_page.dart`
  - `lib/modules/settings/customization/email_notifications/presentation/pages/email_notifications_page.dart`
  - `lib/modules/settings/customization/reporting_tags/presentation/pages/reporting_tag_create_page.dart`
  - `lib/modules/settings/customization/transaction_number_series/presentation/pages/transaction_number_series_create_page.dart`
  - `lib/modules/settings/customization/transaction_number_series/presentation/pages/transaction_number_series_report_page.dart`
  - `lib/modules/settings/record_locking/lock_configuration/presentation/pages/lock_configuration_create_page.dart`
  - `lib/modules/settings/record_locking/lock_configuration/presentation/pages/lock_configuration_report_page.dart`
  - `lib/modules/settings/inventory/shipments/presentation/pages/shipments_settings_page.dart`
  - `lib/modules/settings/inventory/stock_counts/presentation/pages/stock_counts_settings_page.dart`
  - `lib/modules/settings/inventory/transfer_orders/presentation/pages/transfer_orders_settings_page.dart`
  - `lib/modules/settings/purchase/expenses/presentation/pages/expenses_settings_page.dart`
  - `lib/modules/settings/purchase/purchase_orders/presentation/pages/purchase_orders_settings_page.dart`
  - `lib/modules/settings/purchase/purchase_receives/presentation/pages/purchase_receives_settings_page.dart`
  - `lib/modules/settings/sales/sales_orders/presentation/pages/sales_orders_settings_page.dart`
  - `lib/modules/settings/sales/invoices/presentation/pages/invoices_settings_page.dart`
  - `lib/modules/settings/sales/credit_notes/presentation/pages/credit_notes_settings_page.dart`
  - `lib/modules/settings/sales/delivery_challans/presentation/pages/delivery_challans_settings_page.dart`
  - `lib/modules/settings/sales/retainer_invoices/presentation/pages/retainer_invoices_settings_page.dart`
  - `lib/modules/sales/eway_bills/presentation/pages/eway_bill_create_page.dart`
  - `lib/modules/sales/eway_bills/presentation/pages/eway_bill_report_page.dart`

- Frontend Files — route and landing-page integration:
  - `lib/modules/settings/config/routes.dart`
    - imports the handoff route composition while preserving the existing org-system-id shell.
  - `lib/modules/settings/config/handoff_routes.dart`
    - adds canonical routes for items, approval, record locking, inventory settings, purchase settings, and sales settings.
    - uses GoRouter only; no direct Navigator route ownership was introduced.
  - `lib/modules/settings/taxes/config/routes.dart`
    - replaces tax/direct-tax/e-Way/e-Invoice placeholders with concrete handoff pages and adds tax create/import routes.
  - `lib/modules/settings/setup/config/routes.dart`
    - replaces General/Currencies/Reminders placeholders and adds Units of Measurement and Customers & Vendors routes.
  - `lib/modules/settings/customization/config/routes.dart`
    - replaces transaction-series/email/reporting-tags placeholders and adds create routes.
  - `lib/modules/settings/presentation/pages/settings_page.dart`
    - connects Approvals, Customers & Vendors, Items, Shipments, Transfer Orders, Sales settings, Purchase Orders, and Purchase Receives to their settings-owned routes.
  - `lib/shared/widgets/settings_navigation_sidebar.dart`
    - connects previously inert settings entries (taxes, direct taxes, e-Way, e-Invoice, General, Currencies, Reminders, transaction series, email, reporting tags, customers/vendors, items, shipments, transfer orders) to the same route constants as the landing page.
  - `lib/core/routing/app_routes.dart`
    - adds route constants for all integrated handoff screens and deep-link variants.

- Frontend Files — missing handoff contracts made compile-safe:
  - `lib/modules/settings/taxes/models/settings_tax_rate_model.dart`
    - adds the UI tax-rate model required by the copied tax screens.
  - `lib/modules/settings/taxes/providers/settings_tax_rates_provider.dart`
    - adds filter/selection/loading state and CRUD-shaped notifier methods required by the copied UI.
  - `lib/modules/settings/taxes/presentation/dialogs/settings_tax_export_dialog.dart`
    - adds the missing export-dialog entry point used by the tax overview.
  - `lib/modules/settings/customization/transaction_number_series/presentation/providers/transaction_number_series_provider.dart`
    - adds the missing in-memory record/notifier contract required by the copied create/report pages.
  - `lib/modules/settings/record_locking/lock_configuration/presentation/providers/lock_configuration_provider.dart`
    - adds the missing in-memory record/notifier contract required by copied lock pages.
  - `lib/shared/widgets/settings_page_header.dart`
    - adds one shared settings header owner used by the handoff pages; controllers are disposed only when internally owned.
  - `lib/shared/widgets/inputs/font_family_dropdown.dart`
    - adds the missing shared font-family selector contract used by customization UI.
  - `lib/shared/widgets/inputs/got_it_popover.dart`
    - carries the handoff popover into the shared widgets owner.
  - `REUSABLES.md`
    - registers `SettingsPageHeader` and `FontFamilyDropdown` so future work reuses these owners.

- Frontend Files — shared compatibility and UX repairs:
  - `lib/shared/widgets/inputs/account_tree_dropdown.dart`
    - accepts hierarchy-bullet controls, minimum bullet depth, settings affordance metadata, and dropdown width.
    - child bullets now follow explicit `showHierarchyBullets` plus `hierarchyBulletMinDepth`; parent/category rows are not rendered as selectable child bullets.
    - preserves white overlay and existing deferred overlay lifecycle behavior.
  - `lib/shared/widgets/inputs/dropdown_input.dart`
    - accepts the handoff compatibility surface for settings rows, custom item builders, hierarchy bullets, width, suffix/search widgets, border state, empty text, and scroll affordances.
    - removed a newly introduced invalid `const` around dynamic empty-state text.
  - `lib/shared/widgets/z_button.dart`
    - supports optional height/font-size/padding/suffix widget required by copied settings action bars while retaining existing primary/secondary behavior.
  - `lib/shared/widgets/inputs/z_tooltip.dart`
    - adds top placement compatibility.
  - `lib/shared/widgets/inputs/zerpai_date_picker.dart`
    - accepts handoff popup placement/dismiss compatibility parameters while retaining shared date-picker ownership.
  - `lib/shared/widgets/z_data_table_shell.dart`
    - accepts copied table scrollbar/scroll-hint compatibility parameters without introducing another table shell.
  - corrected unsupported Lucide icon names in email/payment-term handoff pages and corrected tax/lock provider type mismatches.

- Persistence and schema boundary:
  - the handoff pages are UI-first snapshots; no settings API or database contract was supplied.
  - tax, transaction-number, and lock-configuration providers are intentionally local/in-memory adapters so the UI compiles and routes safely without inventing schema fields or fake API endpoints.
  - these providers must be replaced with schema-backed repositories before production persistence is claimed.
  - no new database table, migration, DTO, controller, or backend service was added.

- Verification:
  - `flutter analyze --no-pub lib/modules/settings lib/modules/sales/eway_bills/presentation/pages/eway_bill_create_page.dart lib/modules/sales/eway_bills/presentation/pages/eway_bill_report_page.dart`
    - pass: 0 errors; remaining output is SDK deprecation/unused-code warnings only.
  - `flutter analyze --no-pub lib/modules/settings/config/routes.dart lib/modules/settings/presentation/pages/settings_page.dart lib/shared/widgets/settings_navigation_sidebar.dart`
    - pass: `No issues found!`.
  - repository-wide `flutter analyze --no-pub`
    - pass for hard compilation errors after the shared dropdown fix; 70 warning/info diagnostics remain across existing and handoff UI (mostly deprecated Radio API, unused helper declarations, and existing unused locals).
  - `flutter build web --no-pub`
    - pass: `Built build\\web` in 321.3 seconds.
    - normal JavaScript build succeeded.
    - Flutter emitted one existing WebAssembly dry-run warning for `dart:html` in `lib/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart`; this is unrelated to settings and does not block the JavaScript build.
    - icon font tree-shaking completed successfully.
  - diagnostic analyzer scratch files were removed after evidence extraction; no `.codex-*analyze.txt` artifact remains in the repository.

- Residual risks:
  - copied pages still contain static/local sample values in places because the handoff did not include backend contracts; they are not evidence of DB-backed production settings.
  - route-level smoke testing in a live browser remains pending after this source integration; the web build is the verified gate in this batch.
  - warning-only analyzer cleanup remains separate from this integration and should not be conflated with compile safety.
  - handoff backups remain intentionally retained at `backups/refactor-batches/20260717-settings-handoff` per merge governance.

Timestamp of Log Update: July 17, 2026 - 1:03 PM (IST)

## 18) [2026-07-17 13:13:00] Settings persistence safety correction after build validation

- Frontend File:
  - `lib/modules/settings/taxes/providers/settings_tax_rates_provider.dart`
    - removed the temporary hardcoded CGST/SGST/IGST seed rows from `load()`.
    - with no settings API/repository in the handoff, the tax screen now stays explicitly empty/loading instead of presenting fabricated business data.
    - create/update/delete/toggle methods remain local-only compile adapters and do not claim persistence.

- Reason:
  - `AGENTS.md` global-settings governance requires real DB-backed values where available and an explicit empty/error state when unavailable.
  - this correction prevents the handoff UI from implying that sample tax rates came from the tenant database.

- Verification:
  - `flutter analyze --no-pub lib/modules/settings/taxes/providers/settings_tax_rates_provider.dart lib/modules/settings/config/handoff_routes.dart`
    - pass: `No issues found!`.
  - previous release web build remains valid for the source shape; this change removes data seeding only and does not alter route or compile contracts.

Timestamp of Log Update: July 17, 2026 - 1:13 PM (IST)

## 19) [2026-07-17 13:06:40] Timestamp correction and final tax-provider safety note

- Correction:
  - the preceding entry titled `Settings persistence safety correction after build validation` contains a heading timestamp typo (`13:13:00`).
  - the actual timestamp command run for this correction was `2026-07-17 13:06:40`.
  - no source behavior change is introduced by this note; the preceding entry remains an append-only audit record of the hardcoded-tax-seed removal.

Timestamp of Log Update: July 17, 2026 - 1:06 PM (IST)

## 20) [2026-07-17 13:07:39] Tax-group import deep-link completion

- Frontend File:
  - `lib/modules/settings/taxes/config/routes.dart`
    - added `settings/taxes/groups/import` using `TaxImportKind.taxGroup` so the copied tax-group import flow has its own stable deep link and does not overload the normal tax import route.

- Verification:
  - `flutter analyze --no-pub lib/modules/settings/taxes/config/routes.dart lib/modules/settings/config/routes.dart`
    - pass: `No issues found!`.
  - `git diff --check`
    - pass; only normal CRLF conversion warnings from the Windows Git worktree.

Timestamp of Log Update: July 17, 2026 - 1:07 PM (IST)

## 22) [2026-07-17 13:31:40] Permanent local Flutter Web build-define startup fix

- Symptom:
  - Chrome at `http://localhost:53431` displayed `Initialization Failed`.
  - Message reported missing `SUPABASE_URL` or `SUPABASE_ANON_KEY` and requested `--dart-define` values.
  - Clearing cookies/cache/storage could not affect this failure because the values are compile-time inputs, not browser state.

- Evidence:
  - Port `53431` was owned by a Flutter `dartvm` launched as:
    `flutter_tools.snapshot run -d chrome --web-port 53431`.
  - The command contained no `--dart-define=SUPABASE_URL=...` or `--dart-define=SUPABASE_ANON_KEY=...` arguments.
  - Existing `lib/main.dart` correctly reads only `String.fromEnvironment` values and intentionally refuses unsafe runtime `.env` loading.

- Frontend/tooling Files:
  - `scripts/run-web.ps1`
    - added `-WebPort` with default `53431`;
    - always passes the required public Supabase build defines from ignored `.env.local`;
    - passes `API_BASE_URL` with the local backend default when absent;
    - keeps values hidden and never packages the environment file.
  - `README.md`
    - documents `pwsh -File .\\scripts\\run-web.ps1` as the canonical local web command on port `53431`;
    - documents `-WebPort` for an alternate port.

- Security boundary preserved:
  - no dotenv asset fallback was restored;
  - no service-role key, database password, JWT secret, or private API key is passed to Flutter;
  - only the public Supabase URL/anon key and local API base URL are read by the launcher.

- Recovery execution:
  - stopped only the failing Flutter process that owned port `53431`;
  - started the existing launcher with `-WebPort 53431` in the repository root;
  - listener returned on port `53431` under the define-aware Flutter process.

- Verification:
  - PowerShell parser validation for `scripts/run-web.ps1`: pass.
  - `GET http://127.0.0.1:53431`: HTTP 200.
  - served HTML contained neither `Initialization Failed` nor the missing-Supabase message.
  - no source fallback or public `.env` asset was reintroduced.

- Operational rule:
  - do not start this app with bare `flutter run -d chrome` because that omits required compile-time configuration.
  - use `pwsh -File .\\scripts\\run-web.ps1`; this is now the permanent local startup path.

Timestamp of Log Update: July 17, 2026 - 1:31 PM (IST)

## 23) [2026-07-17 13:38:34] IDE Run/Debug configuration fixed without runtime env fallback

- User-visible problem:
  - the application worked when launched through `scripts/run-web.ps1` but failed when the IDE started bare `flutter run -d chrome --web-port 53431`.
  - bare Flutter had no compile-time Supabase defines, so `main.dart` correctly rendered the initialization error.

- Root cause:
  - the repository had no Flutter/Dart launch configuration and `.vscode/settings.json` had no `dart.flutterRunAdditionalArgs`.
  - the earlier launcher solved the symptom only for terminal launches; it did not configure the normal IDE Run action.

- Workspace File:
  - `.vscode/settings.json`
    - added `dart.flutterRunAdditionalArgs` with:
      - `--dart-define-from-file=assets/.env`
      - `--web-port=53431`
    - Flutter 3.38.5 supports the define-file flag directly; the Dart Code extension supports this workspace setting for `flutter run`.
    - `assets/.env` remains ignored, is not listed under Flutter assets, and is used only as a local build-input file.

- Security boundary:
  - no runtime dotenv loading was restored.
  - no `.env` file is shipped in `build/web`.
  - the local file currently contains only public client configuration plus optional Sentry/API values; backend secrets remain in the separate root environment and are not passed through this setting.

- Verification:
  - stopped the previous launcher-owned process on port `53431`.
  - launched the same Flutter command shape used by the IDE with `--dart-define-from-file=assets/.env`.
  - `GET http://127.0.0.1:53431`: HTTP 200.
  - response contained neither `Initialization Failed` nor the missing-Supabase message.
  - terminal launcher remains available for other machines, but it is no longer required for this workspace's normal IDE Run action.

- Important scope note:
  - `.vscode/settings.json` is intentionally ignored by the repository's existing Git policy, so this machine-level Run configuration will not be committed or deployed.
  - another developer machine needs an equivalent local workspace setting and its own ignored public define file; no production asset or secret is required.

Timestamp of Log Update: July 17, 2026 - 1:38 PM (IST)

## 24) [2026-07-17 13:52:47] Flutter Web local configuration aligned with SHIELD launcher pattern

Request

Developers should not retype --dart-define values for every Flutter Web run. The
reference implementation at E:\K4NN4N\shield\frontend was inspected to determine
whether it avoids Dart defines or automates them.

### Evidence from SHIELD

- rontend/scripts/run-web-with-env.ps1 reads ackend/.env into the launcher
  process environment.
- It forwards only an explicit allowlist of browser-safe values as
  --dart-define arguments before invoking lutter run.
- It does not pass the complete backend environment to Flutter, and it does not
  make Flutter Web read a backend .env file at runtime.
- Therefore SHIELD's normal developer flow is wrapper automation, not a bare
  lutter run command with implicit .env support.

### Zerpai root cause

lib/main.dart and lib/core/services/env_service.dart use
String.fromEnvironment for Supabase configuration. Flutter Web resolves these
values at compile time. The browser cannot safely or reliably read
ackend/.env, and Flutter has no project-level setting that makes a bare
lutter run -d chrome --web-port 53431 import arbitrary dotenv files.

Passing the complete backend file would embed secrets such as database URLs,
JWT secrets, service-role keys, storage credentials, and private API keys into
the browser bundle. That is forbidden.

### Implemented change

scripts/run-web.ps1 now provides the team-safe bridge:

1. Reads local files in priority order: ackend/.env, .env.local, .env,
   then ssets/.env.
2. Resolves public values independently, so a value can exist in any local
   file without requiring one combined file.
3. Forwards only SUPABASE_URL, SUPABASE_ANON_KEY, and API_BASE_URL.
4. Uses http://localhost:3001 only when no API base URL is defined.
5. Accepts -WebPort; default remains 53431.
6. Never prints configuration values and never forwards backend secrets.

README now documents this launcher as the canonical developer command.
The existing ignored VS Code workspace settings continue to make the normal
Run/Debug action use the local public ssets/.env file without manual flags.

### Verification

- PowerShell parser: SCRIPT_PARSE_OK.
- Mocked Flutter launch: MOCK_LAUNCH_SAFE_OK.
- Mock verification confirmed required public defines are present.
- Mock verification confirmed no service-role, JWT, database, password, or
  secret-key values are forwarded.
- No environment file is tracked by Git (git ls-files returned none for the
  local env paths checked).

### Developer usage

Run once per session with:

`powershell
pwsh -File .\scripts\run-web.ps1
`

Use -WebPort <port> when needed. A bare Flutter command cannot acquire local
.env values automatically; using the launcher or the configured VS Code
Run/Debug action is the real solution, not a bypass.

### Security boundary

Only public client configuration may cross the Flutter Web compile boundary.
Backend-only secrets remain backend-local. Rotating exposed credentials remains
required before production if any secret was previously bundled or committed.

## 25) [2026-07-17 13:55:14] Tracked Vercel environment artifact removed

### Security finding

ackend/.env.vercel was tracked by Git even though .gitignore listed it.
The file contained commented environment assignments with real-looking values,
including storage credentials, database connection data, JWT material,
Supabase service/private keys, email credentials, Redis credentials, and Vercel
identifiers/tokens. Commenting a secret does not protect it; the value remains
visible in repository history and any checkout.

### Action

Removed ackend/.env.vercel from the working tree and Git change set. The
existing ignore rule at .gitignore:420 remains in place. Kept
ackend/.env.example as the placeholder template. No local active
ackend/.env file was staged or tracked.

### Required follow-up

Treat every credential that appeared in the removed artifact as compromised:
rotate/revoke it before production use, including database password, JWT secret,
Supabase private/service-role keys, storage keys, email/API keys, Redis tokens,
and Vercel tokens. Removing the current file does not erase values from prior
Git commits; rewrite repository history only under an explicit repository
maintenance decision.

### Verification

- git status --short backend/.env.vercel: deletion recorded.
- Test-Path backend/.env.vercel: false.
- .gitignore still ignores ackend/.env.vercel.
- No local environment file was added to the index.

## 26) [2026-07-17 13:59:18] Launcher smoke verification completed

### Runtime test

Started pwsh -NoProfile -File .\scripts\run-web.ps1 -WebPort 53431 with the
real local files. The wrapper resolved configuration without exposing values,
compiled Flutter Web, launched Chrome, and reached the Flutter debug service.

### Evidence

- Flutter Web debug service started successfully.
- Local HTTP probe: http://127.0.0.1:53431 returned HTTP_STATUS=200.
- HTML response size: 8094 bytes.
- Application logs confirmed Supabase initialization and first-frame launch.
- Application logs confirmed API base URL resolved to the local backend.
- No initialization failure for missing Supabase compile-time values occurred.
- Flutter process was stopped cleanly with q after verification.

This verifies the backend-environment bridge works with the existing developer
port and removes the need to type Dart defines for each wrapper-based run.

## 27) [2026-07-17 14:03:13] Final local Flutter Web configuration handoff

### Final decision

Zerpai keeps compile-time configuration for Flutter Web. Runtime dotenv loading
was not reintroduced because browser-delivered environment files would create a
security and deployment-boundary problem. The developer workflow is automated
through scripts/run-web.ps1, matching the proven SHIELD approach.

### Why the bare command cannot solve this

lutter run -d chrome --web-port 53431 does not read repository .env files.
Flutter Web compiles String.fromEnvironment values before the browser starts.
A backend .env file is therefore not available to Dart at runtime. The only
safe choices are compile-time defines supplied by a launcher/IDE or public
compile-time defaults. Public defaults were not added because they would bind
local configuration to source code.

### SHIELD comparison

The reference SHIELD frontend also uses
rontend/scripts/run-web-with-env.ps1. That script reads the backend
environment, selects an explicit public-key allowlist, and invokes Flutter with
Dart defines. SHIELD does not make a bare Flutter command load dotenv files.
Zerpai now follows the same boundary.

### Zerpai launcher behavior

scripts/run-web.ps1:

- default port: 53431;
- optional port override: -WebPort <port>;
- environment lookup order: ackend/.env, .env.local, .env,
  ssets/.env;
- forwarded keys only: SUPABASE_URL, SUPABASE_ANON_KEY, API_BASE_URL;
- API fallback: http://localhost:3001;
- configuration values never printed;
- backend secrets never forwarded to Flutter.

### Developer command

`powershell
pwsh -File .\scripts\run-web.ps1
`

Alternate port:

`powershell
pwsh -File .\scripts\run-web.ps1 -WebPort 53432
`

The existing VS Code workspace configuration supports Run/Debug with the local
public environment file. Developers do not retype Dart defines per run.

### Security cleanup

ackend/.env.vercel was tracked despite being ignored and contained
commented real-looking credentials. It was removed from the working tree and
from the pending Git change. ackend/.env.example remains the safe template.
No local active environment file is tracked by Git.

Values present in the removed artifact must be treated as compromised and
rotated/revoked before production use: database credentials, JWT material,
Supabase private/service-role keys, storage keys, email/API credentials, Redis
credentials, and Vercel tokens. Removing the current file does not remove
historical Git copies; history rewriting requires a separate explicit decision.

### Verification completed

- PowerShell parser returned SCRIPT_PARSE_OK.
- Mock launcher returned MOCK_LAUNCH_SAFE_OK.
- Mock confirmed required public defines were present.
- Mock confirmed secret names were not forwarded.
- Real launcher compiled Flutter Web successfully.
- Real launcher started Chrome on port 53431.
- HTTP probe returned 200 from http://127.0.0.1:53431.
- Supabase initialization completed.
- First Flutter frame rendered.
- Flutter process exited cleanly with q.
- git diff --check returned DIFF_CHECK_OK.

### Files changed in this work

- scripts/run-web.ps1 — safe env bridge and port parameter.
- README.md — launcher-first developer instructions.
- .vscode/settings.json — local Run/Debug build-define configuration.
- ackend/.env.vercel — removed tracked credential artifact.
- log.md — append-only audit trail entries 22–25.

### Remaining action

Rotate all credentials from the removed Vercel environment artifact before any
production deployment. Do not restore that file or pass ackend/.env wholesale
to Flutter.

## 28) [2026-07-17 14:06:07] Merge and handoff reconciliation status

### What was merged

The earlier Arun/handoff reconciliation is already committed on the current
branch PlatformCatalyst/main:

- commit eaf9401 — chore: reconcile Arun handoff merge with repo rules and preserve only safe net-new deltas;
- preserved safe net-new procurement, sales, shared-dialog, model, notifier,
  and log changes;
- retained compatibility ownership and removed conflicting duplicate handoff
  implementations;
- created lib/shared/widgets/dialogs/edit_quantity_dialog.dart;
- preserved log archived June.md as the archived audit record.

The shared dropdown/date-picker/shim cleanup is also already committed:

- commit d53f36f2 — stabilized shared account dropdown overlay lifecycle,
  date-picker behavior, and retired repo-wide shim wrappers.

### Settings handoff merge

The settings-page handoff was copied only after creating the required backup:

- backup: ackups/refactor-batches/20260717-settings-handoff;
- source: E:\Chrome Downloads\settings pages;
- selected files were mapped to canonical lib/modules/settings/... owners;
- route composition uses module GoRouter route files;
- shared controls were extended instead of duplicated;
- no backend controller, DTO, migration, schema, or fabricated API contract was
  merged;
- tax, transaction-series, and lock providers remain explicit in-memory
  compile adapters until real schema-backed contracts are supplied.

The complete selected file inventory and verification results are recorded in
log entry 16. The persistence-safety correction removing fabricated tax seed
rows is recorded in entry 17.

### Current Git state

The settings handoff integration and the latest local configuration/security
changes are currently uncommitted working-tree changes, not a completed Git
commit. There are no staged files at this checkpoint. The worktree contains:

- modified settings routes, landing page, sidebar, shared dropdown/date-picker,
  button/table/tooltip owners, and REUSABLES.md;
- new settings feature pages, providers, dialogs, and route composition;
- new sales e-way-bill pages;
- scripts/run-web.ps1, README.md, .vscode/settings.json, and log.md;
- deletion of tracked ackend/.env.vercel containing exposed credentials.

These changes must be reviewed and staged intentionally; no automatic commit or
push was performed.

### Verification state

The settings scope previously passed targeted Flutter analysis and the normal
web build. The launcher passed parser, mock secret-filter, real Chrome startup,
HTTP 200, Supabase initialization, and first-frame checks. git diff --check
passes with only normal line-ending warnings.

### Remaining merge gate

Before committing the pending handoff batch:

1. review the complete git diff and untracked-file inventory;
2. run targeted Flutter analysis on the final staged settings scope;
3. run the normal Flutter web build;
4. confirm no backend/schema contract was invented;
5. commit settings integration separately from environment/security cleanup;
6. retain the handoff backup until explicit approval to delete it.

No merge conflict is currently unresolved. The distinction is that the
reconciliation commit is complete, while the settings integration is present
and validated but still awaiting an intentional commit.

## 29) 2026-07-17 15:14:28 — Settings module visual consistency and shared-shell normalization

### Request scope

Normalized the settings module so pages from the handoff set and existing pages render as one Zerpai application. Work was limited to presentation/navigation-shell consistency; no business rules, API contracts, database schema, or tenant logic changed.

### Findings confirmed from the supplied screens and repository

- The canonical settings experience uses a white settings header, back control, orange settings identity, organization name, centered settings search, Close Settings action, and the shared 240px navigation sidebar.
- Several handoff pages had their own sidebar implementations or one-off shell layouts. That created inconsistent spacing, active-state colors, header casing, and duplicate navigation entries.
- User Preferences was listed under Users & Roles while the same route also rendered Setup & Configurations > General. This could produce two highlighted rows for one route and made the sidebar state ambiguous.
- Print Templates was still a bare Scaffold with local Material controls and no settings shell, unlike the surrounding settings pages.
- Several page headers uppercased the organization name locally, producing a visual mismatch against the canonical branding screen.

### Changes applied

1. Shared header owner
   - Updated lib/shared/widgets/settings_page_header.dart.
   - Added canonical All Settings identity with the orange settings icon and organization subtitle.
   - Added consistent back behavior: supplied callback, GoRouter pop when possible, otherwise settings landing route.
   - Added standard Close Settings action to the home route.
   - Added responsive compact mode while preserving centered settings search on desktop.
   - Preserved controller/focus-node ownership and disposal semantics.
   - Applied AppTheme tokens and explicit white header surface.

2. Canonical sidebar owner
   - Updated lib/shared/widgets/settings_navigation_sidebar.dart.
   - Removed the duplicate User Preferences row from Users & Roles.
   - Kept route-aware active highlighting, capability filtering, branding accent, and existing settings hierarchy.
   - Updated the settings landing data in lib/modules/settings/presentation/pages/settings_page.dart to match the canonical hierarchy.

3. Handoff page shell normalization
   - Replaced local sidebar call sites with SettingsNavigationSidebar in shipments, transfer orders, purchase orders, purchase receives, sales orders, invoices, credit notes, delivery challans, retainer invoices, e-Invoicing, and e-Way Bills settings pages.
   - Removed the duplicate local sidebar implementations from those active pages.
   - Restored the e-Way Bills connection-row model after removing obsolete sidebar-only model code; analyzer verified the page remains complete.

4. Organization-name consistency
   - Removed local .toUpperCase() presentation transforms from settings headers across approvals, organization, taxes, setup, customization, inventory, purchase, sales, and general settings pages.
   - Runtime organization values now preserve the same casing used by the canonical settings header.

5. Print Templates integration
   - Rebuilt lib/modules/settings/customization/pdf_templates/presentation/pages/printing_templates_overview.dart on the shared settings shell.
   - Added shared settings header and navigation sidebar.
   - Replaced raw dropdown usage with FormDropdown<String>.
   - Replaced local Material primary action with shared ZButton.primary.
   - Added AppTheme-consistent search, filter, empty state, borders, and spacing.
   - Kept the existing route and template behavior intact.

6. Cleanup
   - Removed unused Lucide imports introduced by sidebar replacement in transfer orders, purchase orders, and purchase receives.
   - Formatted all touched settings-shell files.

### Verification

- dart format completed for all touched settings-shell files.
- git diff --check completed without whitespace errors. Git only reported normal LF/CRLF normalization notices.
- flutter analyze --no-pub lib/modules/settings lib/shared/widgets/settings_page_header.dart lib/shared/widgets/settings_navigation_sidebar.dart completed with zero compile errors.
- Remaining analyzer output: existing Flutter SDK deprecation notices for Radio groupValue/onChanged, activeColor, and withOpacity, plus a few pre-existing unused helper/optional-parameter notices. These are non-blocking and outside this visual-shell pass.
- flutter build web --no-pub completed successfully: Built build\\web in 438.9 seconds.
- Web build emitted the existing wasm dry-run notice for dart:html in lib/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart; this is unrelated to settings changes.

### Residual risks and follow-up

- Some settings files retain unused legacy navigation-data helper declarations behind // ignore_for_file: unused_element; active rendering uses the canonical shared sidebar, so they do not create duplicate visible sidebars. They can be retired later in a separate dead-code cleanup batch.
- Flutter Radio API migration should be handled as a framework-upgrade batch, not mixed with settings visual work.
- Browser smoke checks should validate desktop and compact widths for every settings route, especially Print Templates and e-Way Bills after the shell replacement.

### Governance result

- Shared settings navigation/header ownership restored.
- Duplicate visible sidebar implementations removed from active handoff pages.
- UI now follows PRD/AppTheme white-surface, spacing, casing, and primary-action rules.
- No schema, backend, persistence, or workflow behavior changed.

## 30) 2026-07-17 15:22:08 — Settings theme-token and shared-header follow-up

### Scope

Applied the existing AppTheme palette and shared settings owners to the remaining settings shell surfaces. No new color constants, component abstractions, routes, API calls, schema fields, or business logic were introduced.

### Changes

- lib/shared/widgets/settings_page_header.dart
  - Uses AppTheme.backgroundColor for the header surface.
  - Remains the single owner for settings identity, responsive search, back action, and Close Settings action.
- lib/shared/widgets/settings_navigation_sidebar.dart
  - Uses the theme background token for white active text and sidebar surface.
  - Preserves branding accent for active navigation and transparent inactive rows.
- lib/modules/settings/presentation/pages/settings_page.dart
  - Replaced local white/black presentation colors with AppTheme.backgroundColor and AppTheme.textPrimary.
- lib/modules/settings/customization/pdf_templates/presentation/pages/printing_templates_overview.dart
  - Uses AppTheme.backgroundColor and AppTheme.inputFill for page and search surfaces.
- lib/modules/settings/shared/settings_users_roles_support.dart
  - Replaced the duplicated Users and Roles top bar with the shared SettingsPageHeader.
  - Reused the existing search controller, focus node, capability-filtered search items, organization name, and settings back route.
  - Removed the stale User Preferences entry from the legacy navigation data as well as the canonical sidebar.
  - Eliminated the handoff-only orange constants and duplicated close/search/header styling.

### Verification

- Formatted all touched files with dart format.
- Targeted analyzer passed with no issues for the shared settings shell, settings landing page, print templates, and Users and Roles pages.
- git diff --check passed; only normal Git line-ending notices were emitted.
- Existing full web build remains valid from the completed build immediately before this follow-up; this follow-up changes only token references and shared header composition.

### Result

Settings pages now inherit the same AppTheme colors and shared header/sidebar behavior instead of local handoff palettes. White overlay/page surfaces remain explicit and no new UI system was created.

## 31) 2026-07-17 15:30:34 — Primary actions now follow live organization accent

### Root cause

The application already applies the saved organization accent through AppTheme.themedWith(branding.accentColor) and Theme.of(context).colorScheme.primary. The remaining settings handoff pages bypassed that contract by assigning fixed green or blue backgrounds directly to primary ElevatedButton styles. That made Save, Run, Add, and similar primary actions ignore the accent selected in Organization Branding.

### Changes

- lib/shared/widgets/z_button.dart
  - Primary buttons now explicitly use Theme.of(context).colorScheme.primary.
  - Existing shared sizing, loading state, typography, and secondary-button behavior remain unchanged.
- Settings primary button call sites now use the live theme primary instead of fixed green/blue values across:
  - reporting tags
  - customers and vendors
  - stock counts and transfer orders
  - items and custom fields
  - organization branches, locations, zones, zone bins, warehouses, and profile
  - expenses, purchase orders, and purchase receives
  - invoices, credit notes, delivery challans, retainer invoices, and sales orders
  - currencies, general settings, and units of measurement
  - direct taxes, tax overview, tax import, and workflow actions
- Replaced fixed primary backgrounds such as #28B36B, #22B36C, #22B378, #00B386, #22C55E, #10B981, #0F9D58, #2BB673, AppTheme.successGreen, AppTheme.primaryBlue, and AppTheme.accentGreen only where they were used as primary action backgrounds.
- Status colors, warning/error states, borders, table surfaces, and destructive actions were not remapped.

### Verification

- Settings analyzer completed with no compile errors; remaining output is existing Flutter deprecation/helper warnings.
- Targeted shared-button analyzer completed with no compile errors.
- git diff --check passed with normal line-ending notices only.
- flutter build web --no-pub completed successfully: Built build\\web in 200.5 seconds.
- Existing wasm dry-run warning remains for dart:html in lib/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart; unrelated to this change.

### Result

Changing the organization accent now updates shared ZButton actions and normalized settings primary buttons automatically. No new color system or duplicate reusable was added.

## 32) 2026-07-17 15:31:32 — Append-only change logging policy reaffirmed

- Every repository change must be reflected in log.md.
- Scope includes fixes, additions, deletions, refactors, configuration changes, dependency changes, route changes, schema changes, merges, reversions, and verification results.
- Each entry must identify affected frontend/backend files, reason, behavior impact, verification, residual risk, and timestamp where applicable.
- Existing entries remain immutable; new information is appended at the end of the file.
- No future implementation batch is considered complete until its log.md entry is written and verified.

## 33) 2026-07-17 15:39:04 — Settings skeleton RenderFlex overflow fix

### Evidence

Attached runtime output reported A RenderFlex overflowed by 280 pixels on the bottom from lib/shared/widgets/z_skeletons.dart:40. The render tree showed ZFormSkeleton directly under an Expanded settings content row with a 760 pixel height constraint. The failing skeleton used 20 fixed form rows, so its natural height exceeded the viewport during loading.

### Root cause

Two settings branding pages returned ZFormSkeleton(rows: 20) directly from their body builder. Their parent layout is a bounded Expanded region and does not provide scrolling for the loading branch. The shared skeleton itself is a non-scrollable column by design and is also used inside existing scroll views, so changing the reusable globally would risk nested-scroll regressions.

### Fix

- lib/modules/settings/organization/presentation/pages/settings_branding_page.dart
  - Wrapped the 20-row loading skeleton in SingleChildScrollView with AppTheme spacing.
- lib/modules/settings/organization/presentation/pages/settings_organization_branding_page.dart
  - Applied the same bounded-content loading fix.

Existing callers that already wrap their skeletons in a scroll view were left unchanged. No business data, API flow, or loading state behavior changed.

### Verification

- Formatted both changed pages.
- flutter analyze --no-pub lib/shared/widgets/z_skeletons.dart lib/modules/settings/organization/presentation/pages/settings_branding_page.dart lib/modules/settings/organization/presentation/pages/settings_organization_branding_page.dart passed with no issues.
- Confirmed all remaining 20-row settings skeletons are inside SingleChildScrollView.
- git diff --check passed with normal line-ending notices only.

### Result

Branding settings loading content now scrolls within the available body height instead of overflowing. The shared reusable remains safe for existing nested scroll and bounded form callers.

## 34) 2026-07-17 15:50:48 — Settings sidebar exclusive accordion behavior

### Evidence

The supplied e-Invoicing screenshot showed multiple sidebar groups expanded at once. The shared sidebar stored expanded titles in a Set<String> and separately force-opened every block containing the active route. Navigating between settings pages therefore left previous groups open while opening the new active group.

### Fix

- lib/shared/widgets/settings_navigation_sidebar.dart
  - Replaced the multi-value expanded set with one nullable SettingsNavigationBlock.
  - Initializes one expanded block from the active route, falling back to Organization.
  - Clicking a closed group assigns it as the only expanded group and closes the previous group automatically.
  - Clicking the open group collapses it.
  - Synchronizes the expanded group when GoRouter changes currentPath.
  - Removed active-child force expansion that allowed multiple groups to remain open.
  - Kept navigation, capability filtering, active accent styling, and route resolution unchanged.

### Verification

- Formatted the shared sidebar.
- flutter analyze --no-pub lib/shared/widgets/settings_navigation_sidebar.dart passed with no issues.
- git diff --check passed with normal line-ending notices only.

### Result

The settings sidebar now behaves as an exclusive accordion: at most one nested settings group is expanded at any time.

## 33) 2026-07-17 15:54:07 — Direct URL and refresh-safe sidebar active state

### Scope

Extended the exclusive settings accordion fix so refreshes, direct URL loads, nested settings routes, and query-string URLs keep both the correct expanded group and highlighted destination.

### Changes

- lib/shared/widgets/settings_navigation_sidebar.dart
  - Normalized currentPath through Uri.tryParse(...).path before matching, removing query and fragment suffixes.
  - Continued stripping the numeric organization scope prefix only when it is a complete path segment.
  - Active route matching now works consistently for /settings/..., organization-scoped URLs such as /6000000000/settings/..., trailing child routes, and query-bearing URLs.
  - Initial state derives its single expanded block from the active route during widget construction, covering browser refresh and direct URL entry.
  - didUpdateWidget switches the single expanded block when GoRouter changes route.
  - Highlight rendering continues to call the same normalized active-route predicate, so the highlighted item is the route currently displayed.

### Verification

- dart format lib/shared/widgets/settings_navigation_sidebar.dart completed.
- flutter analyze --no-pub lib/shared/widgets/settings_navigation_sidebar.dart passed with no issues.
- git diff --check passed with normal line-ending notices only.

### Result

Direct navigation, browser refresh, and nested settings navigation now open the correct single sidebar group and highlight the matching active route item.


## 34) [2026-07-17 16:09:22] Settings sidebar direct-route expansion and active-item correction

### Evidence

The supplied screenshot showed the settings Approval page at an organization-scoped URL such as /6000000000/settings/approval while every sidebar group was collapsed. The Approval destination was therefore not visible or highlighted, even though the page route was active. This reproduced the reported refresh/direct-URL regression after the exclusive-accordion change.

### Root cause

The shared sidebar applies capability filtering in _visibleSections(). That method creates filtered SettingsNavigationBlock copies. Sidebar expansion state was compared using object identity (identical(...)) against canonical block instances captured during initState. A filtered copy is a different object, so the active canonical block never matched the visible block. The route predicate itself recognized /settings/approval correctly, but the containing block stayed collapsed and hid the active row.

### Frontend Files

- lib/shared/widgets/settings_navigation_sidebar.dart
  - Replaced object-identity expansion state with a stable section-title plus block-title key.
  - Included the section title in the key so the two distinct General blocks cannot collide.
  - Kept one nullable expanded key, preserving exclusive accordion behavior.
  - Initial state resolves the active block from the current path before falling back to the first Organization block.
  - didUpdateWidget recalculates the active key whenever GoRouter supplies a new currentPath, covering in-app navigation, browser refresh reconstruction, direct URL loading, and back/forward route changes.
  - Active route matching continues to normalize organization scope prefixes, query strings, fragments, and nested child paths.
  - Capability-filtered block copies now resolve the same stable key as their canonical source, so the correct parent opens and its destination row receives the accent highlight.

### Backend Files

- None. No API, database, schema, tenant, or business workflow behavior changed.

### Verification

- dart format lib/shared/widgets/settings_navigation_sidebar.dart: pass; no formatting changes required.
- flutter analyze --no-pub lib/shared/widgets/settings_navigation_sidebar.dart: pass, No issues found.
- git diff --check: pass; only standard LF/CRLF normalization notices were emitted.
- Static route evidence confirms AppRoutes.settingsApproval is /settings/approval and normalization strips the /6000000000 organization segment before matching.

### Result

At most one settings group can remain expanded. Loading /6000000000/settings/approval directly, refreshing that URL, or navigating to it through GoRouter now expands Organization and highlights Approval with the live accent color. Navigating to another route switches the single expanded group and removes the previous highlight.

### Residual risk

A visual browser smoke test should still be run against an authenticated session to confirm the rendered state at the exact organization-scoped route. No remaining analyzer or structural issue was found in the shared owner.

Timestamp of Log Update: July 17, 2026 - 4:09 PM (IST)


## 35) [2026-07-17 16:11:26] Approval-route verification addendum

- Frontend Files:
  - No additional source edits.
  - Re-ran analyzer across the shared sidebar and Approval report/create route owners after the stable-key correction.

- Verification:
  - lib/shared/widgets/settings_navigation_sidebar.dart: no issues found.
  - lib/modules/settings/approvals/approval/presentation/pages/approval_report_page.dart: no issues found.
  - lib/modules/settings/approvals/approval/presentation/pages/approval_create_page.dart: only two existing Flutter SDK deprecation infos for Radio.groupValue and Radio.onChanged at the approval form; no compile errors and no sidebar/runtime regression.
  - git diff --check: pass; only normal LF/CRLF normalization notices.

- Interpretation:
  - The remaining two messages are framework API migration notices in the approval form, unrelated to the sidebar route-state fix. They were not changed to keep this correction scoped.

Timestamp of Log Update: July 17, 2026 - 4:11 PM (IST)


## 36) [2026-07-17 16:21:35] MSME Settings placeholder route retired

### Evidence

The supplied settings sidebar screenshot marked MSME Settings as not implemented. The sidebar entry still carried AppRoutes.settingsMsme, and the taxes route map resolved that path to SettingsPlaceholderPage. Clicking the item therefore opened a generic page instead of the existing shared unavailable-item toast.

### Frontend Files

- lib/shared/widgets/settings_navigation_sidebar.dart
  - Removed the MSME Settings route assignment while keeping the visible navigation label.
  - The existing null-route handler now displays the standard informational toast: MSME Settings is not available yet.
- lib/modules/settings/presentation/pages/settings_page.dart
  - Removed the MSME Settings route assignment from the settings landing catalog so its card follows the same unavailable-item behavior.
- lib/modules/settings/taxes/config/routes.dart
  - Removed the generic settings/msme GoRoute and its placeholder-page import.
- lib/core/routing/app_routes.dart
  - Removed the now-unused settingsMsme route constant.

### Backend Files

- None. No API, database, schema, tenant, or business workflow changes.

### Behavior

- Sidebar click: shows the standard coming-soon/unavailable toast.
- Settings landing click: shows the same toast.
- Direct /settings/msme URL: no longer resolves to a generic placeholder page because the route is not registered.
- Other tax settings routes remain unchanged.

### Verification

- rg confirmed no settingsMsme or settings/msme references remain in the retired route scope.
- dart format completed for all four touched files.
- flutter analyze --no-pub across the four touched files: No issues found.
- git diff --check: pass; only normal LF/CRLF normalization notices.

Timestamp of Log Update: July 17, 2026 - 4:21 PM (IST)


## 37) [2026-07-18 10:43:33] Currencies table horizontal RenderFlex overflow fix

### Evidence

Attached Flutter output reported a RenderFlex overflow of 213 pixels on the right from the Row at lib/modules/settings/setup/currencies/presentation/pages/currencies_settings_page.dart:1647. The failing _CurrenciesTableHeader was constrained to 677px after the 240px settings sidebar, while its fixed columns plus horizontal padding require 930px when exchange-rate feeds are disabled.

### Root cause

The currencies table used fixed desktop column widths inside a vertical SingleChildScrollView only. The header and row columns had no horizontal viewport, so narrow settings content widths forced the Row beyond its max width. The table rows used Expanded for row actions, which also requires a bounded table width.

### Frontend Files

- lib/modules/settings/setup/currencies/presentation/pages/currencies_settings_page.dart
  - Added a bounded LayoutBuilder around the currencies table body.
  - Added an orthogonal horizontal SingleChildScrollView for narrow content widths.
  - Added a fixed table width equal to the available width or the required desktop minimum, whichever is larger.
  - Minimum width is 930px when exchange-rate columns are visible and 470px when feeds hide those columns; these values include the existing 20px left/right table padding.
  - Preserved the existing inner vertical scroll, row rendering, actions, hover behavior, and business data flow.
  - Kept the row action Expanded bounded by the SizedBox table width, preventing a second unbounded-flex assertion.

### Backend Files

- None. No API, database, schema, tenant, or currency workflow behavior changed.

### Verification

- dart format completed for the currencies settings page.
- flutter analyzer completed with no compile errors; only two existing Flutter SDK deprecation infos for Radio.groupValue and Radio.onChanged at the currency form.
- git diff --check passed with only standard LF/CRLF normalization notices.
- Layout reasoning confirms the previous 677px constraint now receives a 930px horizontal viewport, allowing the user to scroll to all columns instead of losing content or rendering yellow/black overflow stripes.

### Result

The currencies settings table no longer overflows horizontally at the reported narrow content width. Desktop columns remain unchanged, while smaller browser widths can scroll the table horizontally and vertically without changing currency behavior.

### Residual risk

A browser smoke check at the reported viewport should confirm the scrollbar affordance and table action alignment. No further source change is needed unless that visual check exposes a product-specific minimum width requirement.

Timestamp of Log Update: July 18, 2026 - 10:43 AM (IST)


## 38) [2026-07-18 10:53:24] Customer Portal placeholder route retired

### Evidence

The supplied settings screenshot marked Customer Portal under Setup & Configurations as not implemented. The shared sidebar and settings landing catalog still assigned AppRoutes.settingsCustomerPortal, while the setup route map resolved settings/customer-portal to SettingsPlaceholderPage. Clicking the item therefore opened a generic page instead of the standard unavailable-item toast.

### Frontend Files

- lib/shared/widgets/settings_navigation_sidebar.dart
  - Removed the Customer Portal route assignment while keeping the navigation label.
  - Existing null-route handling now shows the shared informational coming-soon/unavailable toast.
- lib/modules/settings/presentation/pages/settings_page.dart
  - Removed the Customer Portal route assignment from the settings landing catalog so its card uses the same toast behavior.
- lib/modules/settings/setup/config/routes.dart
  - Removed the generic settings/customer-portal GoRoute and placeholder-page import.
- lib/core/routing/app_routes.dart
  - Removed the unused settingsCustomerPortal route constant.

### Backend Files

- None. No API, database, schema, tenant, or customer workflow behavior changed.

### Behavior

- Sidebar click: shows the existing Customer Portal unavailable/coming-soon toast.
- Settings landing click: shows the same toast.
- Direct /settings/customer-portal URL: no longer resolves to a generic placeholder page because the route is not registered.
- Reminders, currencies, general setup, units, and customer/vendor settings routes remain unchanged.

### Verification

- Repository search found no settingsCustomerPortal or settings/customer-portal references after the change.
- dart format completed for all four touched files.
- flutter analyze --no-pub across the four touched files: No issues found.
- git diff --check passed with only standard LF/CRLF normalization notices.

Timestamp of Log Update: July 18, 2026 - 10:53 AM (IST)


## 39) [2026-07-18 10:58:07] Transaction Number Series title-bar overflow fix

### Evidence

Attached Flutter output reported a RenderFlex overflow of 23 pixels on the right at lib/modules/settings/customization/transaction_number_series/presentation/pages/transaction_number_series_report_page.dart:589. The _ReportTitleBar Row was constrained to 670px after the settings sidebar while rendering the title, the full Prevent Duplicate Transaction Numbers action, spacing, and the New Series button.

### Root cause

The title bar used a non-flexible title Text, Spacer, non-flexible duplicate-prevention label, and fixed primary button. At narrow settings content widths, the combined intrinsic widths exceeded the Row constraint, so the right edge overflowed and the action text became partially unreachable.

### Frontend Files

- lib/modules/settings/customization/transaction_number_series/presentation/pages/transaction_number_series_report_page.dart
  - Made the title an Expanded single-line Text with ellipsis.
  - Replaced the unconstrained Spacer/action combination with a Flexible duplicate-prevention action.
  - Made the action label single-line with ellipsis inside its icon/text Row.
  - Preserved the action callback, icon, button styling, spacing, and desktop appearance.
  - Kept the New Series primary action visible and bounded instead of hiding controls or clipping content.

### Backend Files

- None. No API, database, numbering logic, tenant, or workflow behavior changed.

### Verification

- dart format completed for the report page.
- flutter analyze --no-pub lib/modules/settings/customization/transaction_number_series/presentation/pages/transaction_number_series_report_page.dart: No issues found.
- git diff --check passed with only standard LF/CRLF normalization notices.
- The corrected Row now has bounded flexible title/action regions, eliminating the reported 23px right overflow at the 670px constraint.

### Result

Transaction Number Series now remains usable at the reported narrow settings width. Long labels truncate cleanly instead of producing a RenderFlex assertion; all actions remain clickable.

Timestamp of Log Update: July 18, 2026 - 10:58 AM (IST)


## 40) [2026-07-18 11:01:54] Transaction Number Series narrow-layout correction

### Evidence

A follow-up runtime trace still reported the same 23px overflow at the transaction-series title-bar Row and additional right overflows of 65px, 179px, and 80px during narrow-layout rebuilds. The previous flexible-row correction reduced intrinsic pressure but still depended on one horizontal row fitting inside the 670px content constraint.

### Root cause

The title, duplicate-prevention action, and New Series button are three independent controls with different minimum widths. A single horizontal Row remains fragile at narrow widths, especially while web font fallback changes text metrics. The fixed 62px title-bar height also prevented a safe wrapped fallback.

### Frontend Files

- lib/modules/settings/customization/transaction_number_series/presentation/pages/transaction_number_series_report_page.dart
  - Added LayoutBuilder-based compact mode below 900px.
  - Compact mode removes the fixed height, keeps a 62px minimum, places the title on its own bounded line, and places the duplicate-prevention action plus New Series button in a second bounded Row.
  - Duplicate-prevention text remains ellipsized inside an Expanded action region.
  - Desktop mode preserves the single-line title bar with flexible title/action regions.
  - No controls were hidden, clipped, or removed.

### Backend Files

- None. No API, database, numbering logic, tenant, or workflow changes.

### Verification

- dart format completed.
- flutter analyze --no-pub for the transaction-series report page: No issues found.
- git diff --check passed with only normal LF/CRLF normalization notices.
- Compact branch guarantees the reported 670px content width is split into bounded vertical sections, so the title/action/button no longer compete in one overflowing horizontal Row.

### Font warning note

The attached log also contains Noto fallback warnings for missing glyphs. No missing code point or affected business label was provided; no font asset was added speculatively. Existing AppTheme fallback remains active. This is separate from the RenderFlex layout assertion.

### Result

The title bar now has a real narrow-layout mode rather than relying on truncation inside one crowded Row. The reported title-bar overflow path is removed while desktop presentation remains unchanged.

Timestamp of Log Update: July 18, 2026 - 11:01 AM (IST)


## 41) [2026-07-18 11:24:55] Email Notifications module deep-linking

### Scope

Enabled refresh-safe GoRouter deep links for the Email Notifications settings module. Existing UI, local template behavior, dialogs, and callbacks remain intact; route state now records the active module context instead of leaving the browser at the base email-notifications URL.

### Frontend Files

- lib/modules/settings/customization/config/routes.dart
  - Added named route for /settings/email-notifications/insights.
  - Added named route for /settings/email-notifications/customer-review.
  - Customer-review route reads query parameters for selected template, edit item, and new/edit mode.
  - Existing organization-scoped routing continues to prepend the active org system ID.
- lib/modules/settings/customization/email_notifications/presentation/pages/email_notifications_page.dart
  - Added initialTemplateName, initialEditTemplateName, and initialEditIsNew route inputs.
  - Added template catalog lookup shared with the internal email navigation list, avoiding a second hardcoded template map.
  - Selecting Sender Email Preferences navigates to /settings/email-notifications.
  - Selecting Email Insights navigates to /settings/email-notifications/insights.
  - Selecting any template navigates to /settings/email-notifications/customer-review?template=<encoded-name>.
  - Added route-aware dialog state:
    - dialog=authenticate
    - dialog=new-sender
    - dialog=signature
  - Direct URLs with those dialog parameters reopen the matching dialog after the first frame; closing a dialog removes only the dialog query while preserving the current section/template.
  - Added route-aware template edit state:
    - mode=new for the New action
    - mode=edit&item=<encoded-name> for Show Mail Content, Edit, and Clone actions
    - closing or saving removes mode/item query parameters.
  - Direct template edit URLs initialize the editor state and selected template context.
  - Kept existing Back, Close Settings, settings search, toast, and editor persistence behavior unchanged.

### Backend Files

- None. No API, database, schema, tenant, email delivery, or notification-template persistence changes.

### URL Contract

- /<orgSystemId>/settings/email-notifications
- /<orgSystemId>/settings/email-notifications/insights
- /<orgSystemId>/settings/email-notifications/customer-review?template=<name>
- /<orgSystemId>/settings/email-notifications?dialog=authenticate
- /<orgSystemId>/settings/email-notifications?dialog=new-sender
- /<orgSystemId>/settings/email-notifications/customer-review?template=<name>&dialog=signature
- /<orgSystemId>/settings/email-notifications/customer-review?template=<name>&mode=edit&item=<name>
- /<orgSystemId>/settings/email-notifications/customer-review?template=<name>&mode=new

All query values are URI-encoded by Uri(queryParameters: ...); route parsing therefore remains safe for spaces and punctuation in template names.

### Verification

- dart format completed for the Email Notifications page and customization routes.
- dart analyze completed across the page, customization route map, and app route constants: No issues found.
- git diff --check passed with only normal LF/CRLF normalization notices.
- Existing named AppRoutes.settingsEmailInsights and settingsCustomerReviewNotification constants now have matching GoRoute registrations.

### Result

Email Notifications navigation, template selection, significant dialog states, and template editor states are addressable by URL and survive refresh/direct URL loading within the active organization scope.

### Residual risk

Template cloning remains in-memory as before; this change does not invent a persistence API. A browser smoke test should exercise each URL after a fresh login/session to confirm route restoration against the running backend.

Timestamp of Log Update: July 18, 2026 - 11:24 AM (IST)


## 42) [2026-07-18 11:26:28] Email Notifications route-state synchronization addendum

- Frontend Files:
  - lib/modules/settings/customization/email_notifications/presentation/pages/email_notifications_page.dart
    - Added didUpdateWidget synchronization so GoRouter back/forward navigation updates section, template, and editor query state even when Flutter reuses the page State object.
    - This closes the refresh/direct-route/back-navigation gap left after the initial deep-link route registration.

- Backend Files:
  - None.

- Verification:
  - dart format completed.
  - dart analyze across the Email Notifications page, customization routes, and app route constants: No issues found.
  - git diff --check passed with only normal LF/CRLF normalization notices.

Timestamp of Log Update: July 18, 2026 - 11:26 AM (IST)

## 43) [2026-07-18 11:35:11] Email Notifications responsive overflow hardening

### Trigger evidence

- Runtime reported repeated right-side RenderFlex overflows while the settings UI was active: 65 px, 179 px, 80 px, and 35 px.
- The Email Notifications screen uses a three-pane layout (global settings navigation, email section navigation, and content). At a narrow browser width, the remaining content pane is substantially smaller than the desktop design width.
- Static inspection identified fixed-width content that exceeded the available pane: Email Insights sections at 628 px and the Sender Preferences public-domain card at 1,140 px.
- The public-domain row also contained long unbreakable email text and fixed action spacing, which could overflow after the card was constrained.

### Frontend changes

- `lib/modules/settings/customization/email_notifications/presentation/pages/email_notifications_page.dart`
  - Changed the three Email Insights content blocks from fixed 628 px widths to `double.infinity`, allowing the existing max-width constraint to use the actual available content width.
  - Replaced the Sender Preferences public-domain card's fixed 1,140 px `SizedBox` with a `ConstrainedBox(maxWidth: 1140)` plus an available-width child. Desktop width remains capped; narrow panes now shrink instead of overflowing.
  - Added one-line ellipsis handling to public-domain email addresses so long addresses cannot force a row wider than its allocated flex column.
  - Made the Signature Settings, Add Additional Contact, and Authenticate Domain dialog shells responsive by preserving desktop max widths while allowing the dialog body to use the viewport width when constrained.
  - Kept existing business behavior, route state, API calls, and styling tokens unchanged.

### Verification

- `dart format lib/modules/settings/customization/email_notifications/presentation/pages/email_notifications_page.dart` passed.
- `dart analyze lib/modules/settings/customization/email_notifications/presentation/pages/email_notifications_page.dart` passed with `No issues found!`.
- Prior route verification remains valid: Email Notifications customization routes and app route constants analyzed successfully.
- `git diff --check` remains clean apart from normal LF/CRLF normalization warnings already present in the dirty worktree.

### Residual observation

- The Noto font warning is independent of the layout fix. It indicates runtime glyph coverage is incomplete for at least one rendered character, but the supplied log does not include the missing code point; no speculative font asset was added.
- Browser smoke testing at the reported narrow viewport is still required to confirm zero runtime overflow events after hot restart. No backend or database files were changed.

Timestamp of Log Update: July 18, 2026 - 11:35 AM (IST)
## 44) [2026-07-18 11:40:16] Email Notifications full web-build verification

- Frontend Files:
  - No additional source changes after entry 43.
  - Verification covers `lib/modules/settings/customization/email_notifications/presentation/pages/email_notifications_page.dart` and its route consumers in the complete Flutter web application build.

- Verification:
  - Ran `flutter build web --no-pub`.
  - Result: `Built build\\web` successfully.
  - Build duration: 218.3 seconds.
  - Flutter emitted only the existing WebAssembly dry-run notice for `dart:html` in `purchase_request_report.dart`; this is outside the Email Notifications change and did not fail the build.
  - Font tree-shaking completed successfully.

- Interpretation:
  - Responsive width changes compile successfully in the full production web target, not only in targeted analyzer scope.
  - Runtime browser smoke testing at the narrow viewport remains the final confirmation step for visual overflow disappearance.

- Backend Files:
  - None.

Timestamp of Log Update: July 18, 2026 - 11:40 AM (IST)
## 45) [2026-07-18 12:08:53] Global settings deep-link route completion

### Scope

Audited the complete settings route composition, settings landing catalog, sidebar entries, workflow navigation, and settings actions for refresh/direct-URL safety. Existing organization-scoped GoRouter redirect remains the canonical prefixing mechanism; no parallel router or navigation abstraction was added.

### Frontend Files

- `lib/core/routing/app_routes.dart`
  - Added canonical route constants for Workflow Operations Center, Workflow Investigation, Workflow Mission Control, and Settings Stock Counts.
  - Kept all existing settings route constants in one route-owner registry.
- `lib/modules/settings/automation/config/routes.dart`
  - Added names to all six automation routes so each screen is addressable through the named GoRouter graph.
- `lib/modules/settings/config/handoff_routes.dart`
  - Added the missing named route for Stock Counts.
- `lib/modules/settings/customization/config/routes.dart`
  - Added names to SMS Notifications and Web Tabs placeholder routes.
  - Preserved existing deep-link routes for Transaction Number Series, Reporting Tags, and Email Notifications.
- `lib/modules/settings/developer/config/routes.dart`
  - Added names to all developer placeholder routes.
- `lib/modules/settings/integrations/config/routes.dart`
  - Added names to all integration placeholder routes.
- `lib/modules/settings/setup/config/routes.dart`
  - Registered `/settings/currencies/import` with `AppRoutes.settingsCurrenciesImport` and `ImportExchangeRatesPage`, fixing the existing import action that previously targeted an unregistered path.
- `lib/shared/widgets/settings_navigation_sidebar.dart`
  - Connected Workflow Rules and Workflow Actions to their existing routes.
  - Corrected Workflow Logs from the unrelated top-level `/audit-logs` path to `/settings/workflow-logs`.
  - Kept MSME Settings, Customer Portal, SMS Notifications, and Web Tabs as unavailable entries where the product has no implemented page; they continue using the standard unavailable toast instead of generic screens.
- `lib/modules/settings/automation/presentation/widgets/settings_workflow_nav_strip.dart`
  - Replaced hardcoded workflow paths with canonical `AppRoutes` constants.
- `lib/modules/settings/automation/presentation/pages/settings_workflow_mission_control_page.dart`
  - Replaced hardcoded workflow destinations with canonical route constants while preserving investigation query parameters (`type`, `id`).
- `lib/modules/settings/taxes/presentation/pages/settings_taxes_overview_page.dart`
  - Removed navigation to the unregistered `/settings/taxes/:id/view` page.
  - The existing View action now shows the standard `Tax details are not available yet` toast until a real detail page exists; no fake route or placeholder screen was introduced.

### Global routing behavior

- All settings route maps now have named GoRoute entries.
- Existing org-scoped global redirect continues to transform `/settings/...` navigation into `/<orgSystemId>/settings/...`, so sidebar/search/workflow clicks remain refresh-safe and tenant-scoped.
- Existing query-state routes remain intact for zones, workflow investigation, taxes sections, transaction-series forms, reporting tags, currencies import, and Email Notifications.
- No `Navigator.push` page navigation was introduced; modal `Navigator.pop` calls remain local dialog dismissal only.

### Verification

- Route/static audit found no unnamed `settings/...` GoRoute definitions after the changes.
- Checked route-name uniqueness across `lib/`; no duplicate `AppRoutes` route names found.
- `dart format` completed for all touched routing/sidebar/workflow/tax files.
- Targeted `dart analyze` for route owners, settings page, sidebar, workflow pages, setup routes, and tax overview completed without errors. Tax overview retains six existing warnings/infos unrelated to this routing fix (unused private declarations and deprecated Radio APIs).
- `flutter build web --no-pub` passed: `Built build\\web` in 229.2 seconds.
- Build emitted only the existing WebAssembly dry-run `dart:html` notice in procurement and normal font tree-shaking messages.
- `git diff --check` passed with normal LF/CRLF normalization notices only.

### Residual boundaries

- Placeholder settings remain intentionally non-routed from the sidebar where the first-phase page is not built; direct URLs exist only for placeholders already represented in the route catalog.
- Tax detail, MSME, Customer Portal, and other not-yet-built pages were not invented.
- Browser smoke testing should still verify direct URL refresh after login for the new currency-import and workflow routes.

Timestamp of Log Update: July 18, 2026 - 12:08 PM (IST)

## 46) [2026-07-18] Safe handoff merge triage — arun18-07-2026

### Scope and safety boundary

- Source handoff: `E:\Chrome Downloads\qs\handoff arun18-07-2026`
- Repository: `E:\zerpai-new`
- Handoff inventory: 51 files total.
  - 49 source files: 8 backend and 41 frontend.
  - 2 instruction files: `instructions.txt` and `file_paths.txt`.
- No handoff `log.md` exists in the source folder. No handoff log was copied or
  merged into this repository.
- The two instruction files were read for merge intent and archived as backup
  artifacts only; they were not added to the repository root.
- No existing source file was deleted, replaced wholesale, or moved.
- Every inbound file and every pre-existing target was preserved before review:
  `E:\zerpai-new\backups\refactor-batches\20260718-121342-handoff-arun18-07-2026`
- Backup policy respected: backup artifacts use `.bak` extensions and the
  backup contains `MANIFEST.bak` with current-target and inbound snapshots.

### Merge decision

The handoff was not a clean branch-level match with the current repository.
Several files used retired presentation import paths, older route ownership,
legacy shared-service paths, or data structures not present in `current schema.md`.
Therefore only additive, schema-compatible deltas were ported; no blind file
copy was performed.

### Frontend Files — merged deltas only

- `lib/modules/items/items/services/lookups_api_service.dart`
  - Added the tax-group-rates lookup request through the existing API client.
  - Failure remains fail-soft as an empty lookup list, matching neighboring
    lookup methods.
- `lib/modules/items/items/controllers/items_state.dart`
  - Added `taxGroupRates` state with an empty-list default and `copyWith`
    propagation.
- `lib/modules/items/items/controllers/items_controller.dart`
  - Added tax-group-rates parsing from the lookup bootstrap response.
  - Added the fallback request and shifted fallback indexes consistently.
  - Exposed the result through the existing state update path.

### Backend Files — merged deltas only

- `backend/src/modules/lookups/lookups.controller.ts`
  - Registered `tax-group-rates` against `tax_group_rates`.
  - Excluded that table from the generic `is_active` filter because the
    schema-defined table has no `is_active` column.
- `backend/src/modules/products/products.service.ts`
  - Added `getTaxGroupRates()` selecting only schema-backed columns.
  - Included it in the existing item lookup bootstrap response.
- `backend/src/modules/purchases/bills/services/bills.service.ts`
  - Added schema-backed vendor `contact_id` and `contact_type` values to the
    generated account-transaction entry.
- `backend/src/modules/purchases/purchase-orders/services/purchase-orders.service.ts`
  - Added product-level expected/received quantity matching for receive
    status calculation.
  - Preserved aggregate fallback when product-level identifiers are absent.
  - Kept billing status based on the existing aggregate expected quantity.
- `backend/src/modules/sales/dto/create-payment-received.dto.ts`
  - Accepted the existing service-supported `void` status in create DTO
    validation.
  - Did not add the handoff `is_delete` field because that column is not
    declared in the canonical schema source.

### Source files deliberately left untouched

#### Backend — not merged

- `backend/src/modules/inventory/services/inventory-adjustments.service.ts`
  - Large handoff version adds stock-count behavior and tables absent from
    `current schema.md`; unsafe to merge without an approved schema migration.
- `backend/src/modules/sales/dto/update-payment-received.dto.ts`
  - Handoff adds `is_delete` behavior that is not schema-backed.
- `backend/src/modules/sales/services/payments-received.service.ts`
  - Handoff expands the same unsupported `is_delete` path and was not copied.

#### Frontend — not merged

- `lib/app/navigation/navigation_registry.dart`
- `lib/app/routing/app_router.dart`
- `lib/core/routing/app_routes.dart`
  - Handoff copies are older route graphs using legacy imports and omit current
    settings deep-link and observability routing; overwriting would regress
    active routes.
- `lib/modules/inventory/picklists/presentation/pages/inventory_picklists_create.dart`
- `lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart`
- `lib/modules/purchases/purchase_orders/notifiers/purchase_order_notifier.dart`
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`
- `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_list.dart`
- `lib/modules/purchases/vendors/presentation/pages/purchases_vendors_vendor_create.dart`
- `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_address_section.dart`
- `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_bank_details_section.dart`
- `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_contact_persons_section.dart`
- `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_other_details_section.dart`
- `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_primary_info_section.dart`
- `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`
- `lib/modules/sales/invoices/presentation/pages/sales_invoice_list.dart`
- `lib/modules/sales/payment_recieved/models/payment_record.dart`
- `lib/modules/sales/payment_recieved/presentation/payment_recieves_overview.dart`
- `lib/modules/sales/payment_recieved/presentation/report_page.dart`
- `lib/modules/sales/payment_recieved/presentation/sales_payment_create.dart`
- `lib/modules/sales/payment_recieved/providers/payment_recieves_provider.dart`
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
- `lib/modules/sales/sales_orders/presentation/pages/sales_order_list.dart`
- `lib/modules/settings/organization/presentation/pages/settings_warehouses_create_page.dart`
  - These feature files contain broad stale snapshots, legacy imports, or
    behavior that would overwrite newer current-repo work. Their individual
    differences remain available in the inbound `.bak` snapshot for a future
    focused port if a concrete missing behavior is identified.
- `lib/modules/inventory/stock_count/models/stock_count_model.dart`
- `lib/modules/inventory/stock_count/presentation/pages/recurring_stock_count_report_page.dart`
- `lib/modules/inventory/stock_count/presentation/pages/stock_count_create_page.dart`
- `lib/modules/inventory/stock_count/presentation/pages/stock_count_overview_page.dart`
- `lib/modules/inventory/stock_count/presentation/pages/stock_count_perform_page.dart`
- `lib/modules/inventory/stock_count/presentation/pages/stock_count_report_page.dart`
- `lib/modules/inventory/stock_count/presentation/widgets/stock_count_batch_numbers_dialog.dart`
- `lib/modules/inventory/stock_count/providers/stock_count_provider.dart`
  - These newly supplied files are not in the handoff file list and use direct
    Supabase access plus stock-count tables not present in the canonical schema.
    They remain archived, not active, until schema/PRD ownership is approved.
- `lib/shared/services/storage_service.dart`
- `lib/shared/widgets/zerpai_layout.dart`
- `lib/shared/widgets/inputs/category_dropdown.dart`
- `lib/shared/widgets/inputs/dropdown_input.dart`
- `lib/shared/widgets/tables/table_header_menu.dart`
- `lib/shared/widgets/tables/table_more_menu.dart`
  - Shared copies were not overwritten because they use legacy ownership/API
    paths or would replace current shared UI, routing, and lifecycle fixes.

### Canonical truth checks

- `current schema.md` confirms `tax_group_rates` columns used by the merged
  lookup and confirms account-transaction contact fields used by bill mapping.
- `current schema.md` does not define the stock-count tables used by the new
  stock-count folder; those files were correctly withheld.
- Existing route ownership and deep-link rules require canonical module route
  maps and current `app_routes.dart`; legacy handoff router copies were not
  allowed to overwrite them.
- Existing shared-widget ownership rules require current `FormDropdown`,
  layout, table-menu, and storage owners; no duplicate shared implementation
  was introduced.

### Verification

- `npm.cmd run build` in `backend/`: pass (`nest build`, exit code 0).
- `flutter analyze --no-pub lib/modules/items/items/controllers/items_state.dart lib/modules/items/items/controllers/items_controller.dart lib/modules/items/items/services/lookups_api_service.dart`: pass, no issues found.
- `dart format` applied to the three touched frontend files.
- `git diff --check`: pass; only normal LF/CRLF normalization warnings.
- `flutter build web --no-pub`: pass; `Built build\\web` in 242.8 seconds.
  Flutter emitted only the existing WebAssembly dry-run notice for
  `dart:html` in `purchase_request_report.dart`; this is outside the merged
  handoff scope and did not fail the build.

### Shim, deletion, and residual-risk status

- No compatibility shim was added or removed in this merge.
- No destructive deletion, reset, checkout, or overwrite occurred.
- Handoff files remain recoverable under the backup path and can be reviewed
  individually without reconstructing the source folder.
- Tax-group-rates data is now available to the existing item lookup state, but
  stale handoff UI consumers were not copied; a future UI port must be scoped
  against current item pages.
- Stock-count integration remains blocked on schema/PRD confirmation, not on
  file availability.
- The current repository still has a pre-existing payments-service/schema
  `is_delete` mismatch; this merge did not expand that mismatch.

Timestamp of Log Update: July 18, 2026 - 1:20 PM (IST)

## 47) [2026-07-18] Safe supplemental handoff integration — required compatible deltas

### Scope

- Continued the `arun18-07-2026` handoff merge after the initial safe triage.
- Re-audited the remaining files instead of overwriting current owners.
- Existing full handoff backup remains:
  `E:\zerpai-new\backups\refactor-batches\20260718-121342-handoff-arun18-07-2026`
- Additional pre-edit backup for payment-service follow-up:
  `E:\zerpai-new\backups\refactor-batches\20260718-1325-handoff-arun18-07-followup`
- No source file was deleted, moved, or replaced wholesale.

### Frontend Files

- `lib/modules/sales/payment_recieved/models/payment_record.dart`
  - Removed the hardcoded organization name fallback from payment records.
  - Normalized backend `void` status to the UI `VOIDED` state.
  - Preserved empty location when no warehouse display name is returned.
- `lib/modules/sales/payment_recieved/providers/payment_recieves_provider.dart`
  - Removed demo payment rows from the initial provider state; the list now
    starts empty and is populated only from the backend API.
  - Persisted void actions through the existing payment API and updated the
    local state to `VOIDED` after a successful request.
- `lib/modules/purchases/vendors/presentation/pages/purchases_vendors_vendor_create.dart`
  - Added bank-account/re-entered-account validation before save.
  - Added dialog-mode close action and shared header-divider support.
  - Kept GoRouter navigation and existing vendor workflow intact.
- `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_address_section.dart`
  - Restricted billing/shipping pin-code input to digits through the existing
    Flutter formatter pipeline.
- `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_bank_details_section.dart`
  - Removed duplicated literal asterisks where the reusable required-label
    treatment already renders the required marker.
- `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_contact_persons_section.dart`
  - Centered contact-table headers, retained bounded column gaps, and aligned
    contact/phone controls to the shared 32px compact form height.
- `lib/shared/widgets/tables/table_header_menu.dart`
  - Enforced pure-white popup surface and approved light border.
  - Added explicit wrap/clip icons and retained shared menu hover treatment.
- `lib/shared/widgets/tables/table_more_menu.dart`
  - Added focused-state parity to blue hover/active rows with white text/icons.
  - Standardized pure-white menu padding and square utility-row shape.
- `lib/shared/widgets/zerpai_layout.dart`
  - Added optional `showHeaderDivider` while preserving existing layout defaults.
  - Header divider is opt-in and used by vendor dialog mode only.
- `lib/shared/widgets/inputs/category_dropdown.dart`
  - Restored the original `displayString`/`onSearch` declarations after
    removing an unused stock-count-only extension; no speculative API remains.

### Backend Files

- `backend/src/modules/sales/services/payments-received.service.ts`
  - Added schema-backed warehouse-name enrichment using existing
    `payments_received.location_id` and `warehouses` rows.
  - Applied enrichment to list and detail responses without changing stored
    payment data or introducing the unsupported handoff `is_delete` column.
- Previously merged backend deltas remain active for lookup tax-group rates,
  bill contact mapping, purchase-order product-level receive status, and
  payment `void` DTO validation.

### Deliberately deferred files

- Stock-count files remain deferred because their direct Supabase queries use
  `stock_counts`, `stock_count_items`, `v_physical_stock`, and related objects
  not defined in `current schema.md`; routes would expose an unverified flow.
- Handoff router/navigation files remain deferred because they use legacy page
  imports and would overwrite current deep-link, settings, and observability
  route ownership.
- Handoff payment delete fields/services remain deferred because
  `payments_received.is_delete` is absent from the canonical schema.
- Large invoice, purchase-order, sales-order, bill, and payment page snapshots
  remain deferred where diffs combine stale imports with broad behavior changes;
  their safe deltas must be ported by feature in a later scoped batch.

### Verification

- `dart format` completed for all supplemental frontend files.
- Targeted `flutter analyze --no-pub` across 12 touched frontend files:
  `No issues found!` (172.9 seconds).
- `npm.cmd run build` in `backend/`: pass (`nest build`, exit code 0).
- `flutter build web --no-pub`: pass; `Built build\\web` in 220.2 seconds.
- Build emitted only the existing WebAssembly dry-run `dart:html` notice in
  `purchase_request_report.dart`; unrelated to this handoff scope.
- `git diff --check`: pass; only normal LF/CRLF normalization warnings.

### Result and residual risk

- Required schema-compatible handoff behavior is now integrated without
  replacing current route, UI, or data owners.
- Demo payment data is no longer shown before the API responds.
- Payment locations now resolve from backend warehouse data when available.
- Stock-count integration still requires an approved schema/API contract before
  it can be safely activated.

Timestamp of Log Update: July 18, 2026 - 4:38 PM (IST)

## 48) [2026-07-20 10:01:37] Sales invoice intrinsic-layout runtime assertion fix

### Scope

- Runtime trace reviewed from:
  `C:\Users\LENOVO\.codex\attachments\d09e000f-b3b8-40eb-bad0-eaf61f882f5e\pasted-text.txt`
- The trace contains normal guarded Hive/object-store startup, Supabase
  initialization, first-frame timing, and item lookup requests.
- One actionable Flutter assertion was present and repeated through the global
  `FlutterError.onError` logger:
  `LayoutBuilder does not support returning intrinsic dimensions.`

### Root cause

- `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`
  wrapped the editable invoice item row in `IntrinsicHeight` at the reported
  line 3903.
- The row contains shared dropdown content backed by `LayoutBuilder`.
- Flutter's intrinsic measurement pass cannot safely execute that
  `LayoutBuilder` callback, so invoice-row layout failed during `performLayout`.
- The trace identified no separate startup, API, Hive, Supabase, or font
  assertion in this captured session. The boot timings were:
  `config_box_open=23ms`, `core_boxes_open_guarded=93ms`,
  `supabase_init=30ms`, and `first_frame_trigger=300ms`.

### Frontend Files

- `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`
  - Removed only the problematic `IntrinsicHeight` wrapper from the editable
    item-row container.
  - Changed the row to `CrossAxisAlignment.stretch` so the existing vertical
    divider cells retain full-row height without intrinsic measurement.
  - Preserved item selection, dropdown behavior, row actions, totals, and all
    business logic.

### Backend Files

- None.

### Safety and verification

- The page had no pre-existing uncommitted change before this fix. Formatter
  churn was discarded and the minimal two-line layout delta was reapplied.
- `flutter analyze --no-pub
  lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`
  - Pass: `No issues found!` (16.5 seconds).
- The captured assertion's offending `IntrinsicHeight`/`LayoutBuilder` pairing
  is no longer present at the reported row location.
- Full web build remains the next repository-level gate after this targeted
  runtime correction.

### Residual risks

- This fix addresses the exact assertion captured in the supplied trace; it
  does not claim that unrelated runtime sessions are error-free.
- A browser smoke test should open the sales-invoice create screen, select an
  item, open the item dropdown, and resize the page to confirm row dividers and
  compact widths remain visually correct.

Timestamp of Log Update: July 20, 2026 - 10:01 AM (IST)

## 49) [2026-07-20 11:20:37] Sales order create intrinsic-layout runtime assertion fix

### Scope

- Follow-up runtime issue reported from the live browser at:
  `http://localhost:53432/6000000000/sales/orders/create`
- The screenshot showed another Flutter rendering assertion after the invoice
  row fix, but this time the active route was Sales Orders create.
- The fix was scoped to the Sales Orders create owner instead of changing the
  previously verified invoice page again.

### Root cause

- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  still wrapped editable sales-order item rows in `IntrinsicHeight`.
- Those rows contain the shared `FormDropdown<Item>` item selector.
- `FormDropdown` uses layout-driven overlay/input measurement internally, and
  Flutter cannot resolve that safely during an intrinsic-height pass.
- This is the same assertion class as the invoice page fix, but in a separate
  sales-order form owner.

### Frontend Files

- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Removed the `IntrinsicHeight` wrapper around the editable item-row body.
  - Changed the row alignment to `CrossAxisAlignment.stretch` so vertical
    dividers keep full row height without intrinsic measurement.
  - Preserved item selection, row actions, tax selection, totals, drag handle,
    bulk checkbox behavior, and existing business logic.

### Backend Files

- None.

### Verification

- `flutter analyze --no-pub
  lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Pass: `No issues found!` (224.0 seconds).
- `flutter build web --no-pub`
  - Pass: `Built build\web` (242.3 seconds).
- Build emitted only the existing WebAssembly dry-run warning for
  `lib/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart`
  using `dart:html`; this is unrelated to the Sales Order create fix and did
  not fail the web build.

### Residual risks

- Browser smoke should refresh the Sales Orders create URL, open the item
  dropdown, select an item, add/remove rows, and confirm the console no longer
  receives the intrinsic-layout assertion.
- Other remaining `IntrinsicHeight` usages were not changed unless tied to the
  reported route and shared dropdown layout path.

Timestamp of Log Update: July 20, 2026 - 11:20 AM (IST)

## 50) [2026-07-20 11:29:44] Sales order create mouse-tracker hover assertion fix

### Scope

- Follow-up runtime trace reviewed from:
  `C:\Users\LENOVO\.codex\attachments\59af3024-b323-470f-a89d-5eb7eac6e3a0\pasted-text.txt`
- The active browser route remained Sales Orders create:
  `http://localhost:53432/6000000000/sales/orders/create`
- The new assertion was different from the previous intrinsic-layout failures:
  `mouse_tracker.dart:199:12 !_debugDuringDeviceUpdate is not true`

### Root cause

- The editable Sales Order item row updated `_hoveredRowIndex` synchronously
  inside `MouseRegion.onEnter` and `MouseRegion.onExit`.
- That hover state controls whether the row action widgets are inserted or
  removed.
- On Flutter Web, rebuilding that row subtree while the framework is still
  processing the same pointer device update can re-enter mouse tracking and
  trip the debug assertion in `MouseTracker._deviceUpdatePhase`.

### Frontend Files

- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Added `_setHoveredRowIndex(int? index)` as the single owner for row-hover
    state changes.
  - Deferred row-hover mutations to the next frame with
    `WidgetsBinding.instance.addPostFrameCallback`.
  - Rewired the row `MouseRegion.onEnter`, row `MouseRegion.onExit`, and row
    actions overlay close paths to use the deferred setter.
  - Kept row-action visibility behavior unchanged while avoiding synchronous
    MouseTracker-phase rebuilds.

### Backend Files

- None.

### Verification

- Confirmed no direct `_hoveredRowIndex = ...` writes remain outside the new
  deferred helper.
- `flutter analyze --no-pub
  lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Pass: `No issues found!` (13.1 seconds).
- `flutter build web --no-pub`
  - Pass: `Built build\web` (179.4 seconds).
- Build emitted only the existing WebAssembly dry-run warning for
  `lib/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart`
  using `dart:html`; this warning is unrelated to Sales Orders create and did
  not fail the build.

### Residual risks

- Browser smoke should refresh Sales Orders create, move the mouse over item
  rows/actions, open the item dropdown, close the row actions menu, and confirm
  the console no longer repeats the `mouse_tracker.dart` assertion.
- Other local hover-only widgets in the same large page were not changed
  because the trace and active route pointed to the row-hover subtree that
  inserts/removes action widgets.

Timestamp of Log Update: July 20, 2026 - 11:29 AM (IST)

## 51) [2026-07-20 11:37:11] Sales order create unbounded row-height regression fix

### Scope

- Follow-up runtime trace reviewed from:
  `C:\Users\LENOVO\.codex\attachments\74da6ce8-97a7-4478-872a-bcd3033d700f\pasted-text.txt`
- The latest assertion was not the mouse-tracker assertion and not the earlier
  intrinsic-layout assertion.
- The active failing render object was the editable Sales Order item row inside
  the reorderable item list.

### Root cause

- The previous fix removed `IntrinsicHeight` from the editable Sales Order item
  row and used `CrossAxisAlignment.stretch` to preserve vertical divider
  height.
- That was valid for bounded rows, but this Sales Order row is inside a
  reorderable/list context where the row receives unbounded vertical
  constraints:
  `BoxConstraints(w=1208.0, 0.0<=h<=Infinity)`.
- In that context, `CrossAxisAlignment.stretch` forces children to take
  `h=Infinity`, producing:
  `BoxConstraints forces an infinite height`.

### Frontend Files

- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Kept the `IntrinsicHeight` removal from the editable item row.
  - Changed the editable item row alignment back to
    `CrossAxisAlignment.start` so the row no longer forces infinite child
    height in the reorderable list.
  - Preserved the deferred row-hover setter from the previous mouse-tracker
    fix.
  - Accepted natural vertical divider height in this row rather than using
    intrinsic measurement or infinite stretch.

### Backend Files

- None.

### Verification

- `flutter analyze --no-pub
  lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Pass: `No issues found!` (14.9 seconds).
- `flutter build web --no-pub`
  - Pass: `Built build\web` (179.2 seconds).
- Build emitted only the existing WebAssembly dry-run warning for
  `lib/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart`
  using `dart:html`; this warning is unrelated to Sales Orders create and did
  not fail the web build.

### Residual risks

- Browser smoke must now retest Sales Orders create specifically because this
  was a correction to the previous layout fix:
  - refresh the route directly
  - hover rows and row actions
  - open the item dropdown
  - add/remove/reorder rows
  - confirm no `IntrinsicHeight`, `mouse_tracker`, or infinite-height
    assertions appear.
- Other `IntrinsicHeight` usages in the file were not changed because the
  supplied trace points to the editable item row render object, not the table
  header or terms/upload section.

Timestamp of Log Update: July 20, 2026 - 11:37 AM (IST)

## 52) [2026-07-20 11:49:23] Sales order create summary/notes horizontal overflow fix

### Scope

- Follow-up runtime trace reviewed from:
  `C:\Users\LENOVO\.codex\attachments\2850b276-8d34-4a94-b237-15d14da7a631\pasted-text.txt`
- Active failing route shown in the screenshot:
  `http://localhost:53432/6000000000/sales/orders/create`
- The assertion was a new horizontal overflow, separate from the previous
  intrinsic-layout, mouse-tracker, and infinite-height assertions:
  `A RenderFlex overflowed by 187 pixels on the right`.
- Flutter identified the owner as:
  `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:4782`.

### Root cause

- `_buildSummaryAndNotes` placed customer notes and totals in a horizontal
  `Row`.
- The row used a fixed 250 px spacer between the notes column and totals card.
- At the current browser/content width, the row had only 1055 px available,
  while the children reserved roughly:
  - notes field max width: 600 px
  - fixed spacer: 250 px
  - totals card max width: 392 px
  - total reserved width: 1242 px
- That fixed-width composition exceeded the available constraints by 187 px,
  matching the runtime assertion and the yellow/black overflow marker shown in
  the browser.

### Frontend Files

- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Removed the oversized fixed 250 px gap from `_buildSummaryAndNotes`.
  - Replaced it with a normal 32 px form-layout gap.
  - Wrapped the notes column in `Expanded` so it consumes remaining row width
    instead of reserving a hard 600 px alongside the totals card.
  - Kept the totals card constrained to its existing 392 px maximum width.
  - Preserved the existing notes text field, summary calculations, tax lines,
    shipping charge, adjustment, round-off, and total display behavior.

### Backend Files

- None.

### Verification

- `dart format lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Pass: file formatted successfully.
- `flutter analyze --no-pub
  lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Pass: `No issues found!` (15.0 seconds).
- `flutter build web --no-pub`
  - Pass: `Built build\web` (188.5 seconds).
- Build emitted only the existing WebAssembly dry-run warning for
  `lib/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart`
  using `dart:html`; this warning is unrelated to Sales Orders create and did
  not fail the web build.

### Residual risks

- Browser smoke should refresh Sales Orders create with DevTools open, scroll to
  the summary/notes section, and confirm the 187 px right overflow no longer
  appears.
- Extremely narrow mobile-width behavior of this desktop-style create form was
  not redesigned in this fix; the current patch removes the traced desktop/web
  overflow without changing business behavior or the Sales Order workflow.

Timestamp of Log Update: July 20, 2026 - 11:49 AM (IST)

## 53) [2026-07-20 12:00:54] Sales order create footer intrinsic-layout assertion fix

### Scope

- Follow-up runtime trace reviewed from:
  `C:\Users\LENOVO\.codex\attachments\8dd0a6c8-b288-4c1f-9688-59ced0e071e6\pasted-text.txt`
- Active failing route shown in the screenshot:
  `http://localhost:53432/6000000000/sales/orders/create`
- The screenshot showed the Sales Order create content pane blank after the
  render/layout failure.
- The assertion was a remaining intrinsic-layout assertion, but in a different
  owner location from the editable item row fixed earlier:
  `LayoutBuilder does not support returning intrinsic dimensions`.
- Flutter identified the owner as:
  `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:4949`.

### Root cause

- `_termsAndFileRow` still wrapped the desktop terms-and-attachments footer row
  in `IntrinsicHeight`.
- That row contains the shared `CustomTextField` path and layout-driven child
  widgets.
- Flutter cannot run those layout callbacks during intrinsic dimension
  calculation, so the footer failed during `performLayout`.
- The resulting failed layout caused follow-up hit-test stack output and the
  visible blank white content area.

### Frontend Files

- `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Removed the remaining `IntrinsicHeight` wrapper from `_termsAndFileRow`.
  - Kept the desktop two-column terms/upload layout intact.
  - Set the center divider to an explicit 160 px height instead of relying on
    intrinsic row height.
  - Preserved terms text, attachment UI, narrow stacked layout, and sales-order
    business behavior.

### Backend Files

- None.

### Verification

- `dart format lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Pass: file formatted successfully.
- `flutter analyze --no-pub
  lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - Pass: `No issues found!` (15.0 seconds).
- `flutter build web --no-pub`
  - Pass: `Built build\web` (176.0 seconds).
- Build emitted only the existing WebAssembly dry-run warning for
  `lib/modules/procurement/purchase_request/presentation/pages/purchase_request_report.dart`
  using `dart:html`; this warning is unrelated to Sales Orders create and did
  not fail the web build.

### Residual risks

- Browser smoke should hot restart/refresh Sales Orders create, scroll to the
  terms-and-attachments footer, and confirm no `IntrinsicHeight` or hit-test
  layout assertions remain.
- Other Sales Order create `IntrinsicHeight` usages, if any, should be removed
  only when tied to a real trace or verified layout owner; this change fixed
  the exact failing footer owner.

Timestamp of Log Update: July 20, 2026 - 12:00 PM (IST)
## 54) [2026-07-20 13:21:00] Arun18 manual modules copy repair and stock-count support merge

### Scope
- Repaired issues after manual copy from `E:\Chrome Downloads\qs\handoff arun18-07-2026\lib\modules` into `lib\modules`.
- Preserved copied module files; no destructive revert or deletion was performed.

### Backup
- Created backup: `backups/refactor-batches/20260720-125752-arun18-manual-copy-repair`.
- Backup artifacts use `.bak` extension:
  - `lib-modules-after-manual-copy.zip.bak`
  - `lib-modules-after-manual-copy.hashes.txt.bak`
- Also backed up handoff support targets before edits in the same folder.

### Findings
- Handoff contained 32 `lib\modules` files.
- Current repo had 22 exact matches with the handoff module files and 10 module files that differed from the handoff source.
- Analyzer hard errors came from the new `inventory/stock_count` module depending on support files that were outside `lib\modules` and therefore were not copied:
  - missing stock-count `AppRoutes` constants
  - missing GoRouter route entries/imports
  - missing `StorageService.uploadStockCountAttachment`
  - missing `CategoryPicker` multi-select compatibility
  - missing `FormDropdown` compatibility parameters used by stock-count UI

### Frontend Files
- `lib/core/routing/app_routes.dart`
  - Added stock-count route constants.
- `lib/app/routing/app_router.dart`
  - Added stock-count imports, permission rule, and deep-link routes for list, create, recurring, perform, and detail.
- `lib/shared/services/storage_service.dart`
  - Added stock-count attachment upload support using existing backend upload path.
- `lib/shared/widgets/inputs/dropdown_input.dart`
  - Added backward-compatible named parameters required by the stock-count UI without replacing the shared dropdown.
- `lib/shared/widgets/inputs/category_dropdown.dart`
  - Added multi-select `CategoryPicker` path by delegating to the existing `FormDropdown<String>`.

### Verification
- `flutter analyze`
  - Result: no analyzer errors remain.
  - Residual output: existing warnings/infos remain, mostly Flutter deprecation and unused-element warnings.
- `flutter build web --dart-define=ENABLE_AUTH=false`
  - Result: passed; `build\web` generated.
  - Residual note: Flutter wasm dry-run still reports existing `dart:html` incompatibility in procurement purchase request report.

### Residual Risk
- Backend handoff files under `E:\Chrome Downloads\qs\handoff arun18-07-2026\backend` were not blindly copied because this repair was scoped to breakage caused by copying `lib\modules`.
- Further backend merge should be handled as a separate backup-first, schema-checked batch.

## 55) [2026-07-20 13:29:00] Sales order row intrinsic-layout regression repaired after manual handoff copy

### Cause
- Runtime error showed `IntrinsicHeight` at `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:3247`.
- That row contains descendants using layout callbacks/dropdown layout behavior; Flutter cannot calculate intrinsic dimensions for `LayoutBuilder` descendants.
- Manual module copy reintroduced the older intrinsic wrapper in the sales order create row.

### Fix
- Removed the `IntrinsicHeight` wrapper around the sales order item row and kept the existing row structure.

### Verification
- `dart analyze lib\modules\sales\sales_orders\presentation\pages\sales_order_create.dart`
  - Result: passed with no issues.

## 58) [2026-07-20 13:47:00] Module-wide intrinsic layout assertion risk audit completed

### Scope
- Audited `lib/modules` and `lib/shared` for `IntrinsicHeight` / `IntrinsicWidth` after the manual Arun 18-07-2026 handoff copy.
- First removed intrinsic wrappers from copied handoff pages:
  - inventory picklists create
  - inventory stock count overview / perform / report
  - purchases bills create
  - purchases purchase orders create / list
  - sales invoice create / list
  - sales payment create
- Then removed the same intrinsic wrappers from the remaining module/shared pages where the pattern still existed.

### Fix
- Removed all `IntrinsicHeight` / `IntrinsicWidth` widget usage from `lib/modules` and `lib/shared`.
- Preserved the wrapped child widgets and row/table structure.
- Relaxed `CrossAxisAlignment.stretch` to `CrossAxisAlignment.start` in the cleaned rows to avoid unbounded-height render constraints after removing intrinsic sizing.

### Backups
- `backups/refactor-batches/20260720-133743-assertion-risk-audit`
- `backups/refactor-batches/20260720-134038-remaining-intrinsic-assertion-audit`

### Verification
- `rg -n 'IntrinsicHeight|IntrinsicWidth' lib\modules lib\shared`
  - Result: 0 matches.
- `dart analyze lib\modules lib\shared`
  - Result: no analyzer errors; existing warnings/infos remain.
- `flutter build web --dart-define=ENABLE_AUTH=false`
  - Result: passed and built `build\web`.
  - Existing wasm dry-run warning remains for `dart:html` in procurement purchase request report.

## 59) [2026-07-20 14:03:00] Arun 18-07-2026 handoff frontend/backend audit completed

### Scope
- Audited all files listed in `E:\Chrome Downloads\qs\handoff arun18-07-2026`.
- Handoff contents:
  - backend NestJS files under `backend/src/modules`
  - app routing/navigation files
  - copied module files under inventory, items, purchases, sales, and settings
  - shared services/widgets/table helpers

### Findings
- Backend handoff files already exist in the repo but mostly differ from the handoff copies.
- Backend compile is clean, so no backend overwrite was applied.
- Exact handoff Dart file set had no hard analyzer errors after the previous route/shared/module fixes.
- Remaining handoff Dart warnings were local to stock count and sales payment UI.
- Exact handoff UI risk scan found:
  - `IntrinsicHeight` / `IntrinsicWidth`: 0 widget usages
  - raw `showDatePicker`: 0
  - direct `Navigator.push`: 0
  - raw Flutter dropdown widgets: removed; remaining matches are only toolbar method names

### Fix
- Replaced deprecated stock count radio usage with current `RadioGroup` wiring.
- Replaced read-only selected radio with a fixed selected radio icon.
- Removed unused private `super.key` constructor parameters in sales payment body widgets.
- Replaced raw Flutter dropdown widgets in handoff sales invoice/payment UI with existing `FormDropdown<String>`.

### Verification
- Exact handoff Dart files:
  - `dart analyze <41 handoff dart files>`
  - Result: no issues found.
- Backend:
  - `npm.cmd run build` in `backend`
  - Result: passed.

## 60) [2026-07-20 14:20:00] Settings table naming rule aligned to current schema

### Cause
- Refreshed `current schema.md` uses canonical Settings-related table names such as `tax_rates`, `roles`, `warehouses`, `transaction_series`, `record_locking`, `reporting_tags`, `payment_terms`, `currencies`, `units`, `organization`, `branches`, and `branding`.
- Existing PRD/agent guidance still required a blanket `settings_` prefix for Settings-specific tables, which conflicts with the current schema direction.

### Fix
- Removed the blanket `settings_` prefix requirement from PRD and agent guidance.
- New Settings-related backend work must now use canonical table names from `current schema.md`.
- If a new table is unavoidable, it should be named by owning domain and purpose, matching existing schema style.

### Verification
- Searched PRD and `.codex/skills` guidance for the old mandatory `settings_` prefix language.
- Result: no remaining rule requiring Settings tables to start with `settings_`.

## 61) [2026-07-20 14:36:00] Settings backend implementation plan created and Phase 1 taxes backend built

### Scope
- Created `SETTINGS_BACKEND_IMPLEMENTATION_PLAN.md` as the continuation tracker for Settings backend work.
- Loaded Zerpai data architecture, PRD governance, Flutter structure, and UI compliance skills before implementation.
- Built Phase 1 Settings Taxes backend using canonical tables from `current schema.md`.

### Backend Files
- `backend/src/modules/settings-taxes/settings-taxes.module.ts`
- `backend/src/modules/settings-taxes/settings-taxes.controller.ts`
- `backend/src/modules/settings-taxes/settings-taxes.service.ts`
- `backend/src/app.module.ts`

### Schema Tables Covered
- `tax_rates`
- `tax_groups`
- `tax_group_rates`
- `tds_sections`
- `tds_rates`
- `tds_groups`
- `tds_group_items`
- `tcs_natures`
- `tcs_rates`
- `tcs_higher_rate_reasons`

### Routes Added
- `GET /settings-taxes/summary`
- `GET|POST /settings-taxes/rates`
- `PATCH|DELETE /settings-taxes/rates/:id`
- `GET|POST /settings-taxes/groups`
- `PATCH|DELETE /settings-taxes/groups/:id`
- `GET|POST /settings-taxes/tds/sections`
- `PATCH|DELETE /settings-taxes/tds/sections/:id`
- `GET|POST /settings-taxes/tds/rates`
- `PATCH|DELETE /settings-taxes/tds/rates/:id`
- `GET|POST /settings-taxes/tds/groups`
- `PATCH|DELETE /settings-taxes/tds/groups/:id`
- `GET|POST /settings-taxes/tcs/natures`
- `PATCH|DELETE /settings-taxes/tcs/natures/:id`
- `GET|POST /settings-taxes/tcs/higher-rate-reasons`
- `PATCH|DELETE /settings-taxes/tcs/higher-rate-reasons/:id`
- `GET|POST /settings-taxes/tcs/rates`
- `PATCH|DELETE /settings-taxes/tcs/rates/:id`

### Verification
- `npm.cmd run build` in `backend`
  - Result: passed.

### Remaining
- Bulk status/delete actions remain unchecked until the frontend proves it needs batch endpoints.
- Next phase: wire Settings transaction number series and lock configuration UI to existing backend routes.

## 62) [2026-07-20 14:55:00] Settings backend Phase 2 reused transaction series and lock configuration routes

### Scope
- Continued `SETTINGS_BACKEND_IMPLEMENTATION_PLAN.md` Phase 2.
- Reused existing `transaction-series` backend for Settings transaction number series UI.
- Extended existing `transaction-locking` backend for configurable record locking via canonical `record_locking` table.
- Kept `transaction_locks` separate from `record_locking`.

### Live DB Check
- Queried existing tables before wiring:
  - `transaction_series`: 3 existing rows.
  - `transaction_locks`: 0 rows.
  - `record_locking`: 0 rows.
  - `organisation_branch_master`: 19 rows.

### Backend Changes
- `backend/src/modules/transaction-locking/transaction-locking.module.ts`
- `backend/src/modules/transaction-locking/transaction-locking.controller.ts`
- `backend/src/modules/transaction-locking/transaction-locking.service.ts`

### Frontend Changes
- `lib/modules/settings/customization/transaction_number_series/presentation/providers/transaction_number_series_provider.dart`
- `lib/modules/settings/customization/transaction_number_series/presentation/pages/transaction_number_series_create_page.dart`
- `lib/modules/settings/record_locking/lock_configuration/presentation/providers/lock_configuration_provider.dart`
- `lib/modules/settings/record_locking/lock_configuration/presentation/pages/lock_configuration_create_page.dart`

### Routes
- Reused `GET|POST /transaction-series`.
- Reused `PATCH|DELETE /transaction-series/:id`.
- Added `GET|POST /transaction-locking/configurations`.
- Added `PATCH|DELETE /transaction-locking/configurations/:id`.

### Schema Notes
- `record_locking.allow_or_restrict_actions` only accepts `Allow` or `Restrict`.
- `record_locking` does not include `allow_or_restrict_fields`; frontend now uses a safe display default for DB-loaded rows.

### Verification
- `npm.cmd run build` in `backend`
  - Result: passed.
- `dart analyze` on transaction series and lock configuration Settings pages/providers
  - Result: no issues found.
- Frontend:
  - `flutter build web --dart-define=ENABLE_AUTH=false`
  - Result: passed and built `build\web`.
  - Existing wasm dry-run warning remains for `dart:html` in procurement purchase request report.

## 56) [2026-07-20 13:34:00] Sales order summary/notes overflow regression repaired after manual handoff copy

### Cause
- Runtime error showed `RenderFlex overflowed by 546 pixels on the right` at `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart:4792`.
- The summary/notes area used a fixed horizontal layout: notes up to 600 px, a 250 px spacer, and totals up to 392 px.
- That fixed width cannot fit in the observed 696 px content area after the manual handoff copy restored the older layout.

### Fix
- Rebuilt the summary/notes section with `LayoutBuilder`.
- Narrow widths now stack totals and notes vertically.
- Wide widths keep a row layout with flexible notes and a fixed-width totals panel.

### Verification
- `dart analyze lib\modules\sales\sales_orders\presentation\pages\sales_order_create.dart`
  - Result: passed with no issues.

## 57) [2026-07-20 13:42:00] Sales order intrinsic hit-test assertion fully removed

### Cause
- Runtime still reported `Cannot hit test a render box with no size` on `RenderIntrinsicHeight`.
- Additional `IntrinsicHeight` wrappers remained in the sales order table header and footer terms/file layout.
- These wrappers can produce no-size hit-test failures when combined with live layout callbacks, overlays, and pointer events.

### Fix
- Removed all remaining `IntrinsicHeight`/`IntrinsicWidth` usage from `sales_order_create.dart`.
- Replaced footer equal-height divider with an explicitly sized divider.
- Kept table/header/footer structure otherwise unchanged.

### Verification
- `ctx_search` for `IntrinsicHeight|IntrinsicWidth` in `sales_order_create.dart`
  - Result: 0 matches.
- `dart analyze lib\modules\sales\sales_orders\presentation\pages\sales_order_create.dart`
  - Result: passed with no issues.

## 63) [2026-07-20 15:39:14] Settings setup Phase 3A payment terms backend and page wiring

### Scope
- Continued `SETTINGS_BACKEND_IMPLEMENTATION_PLAN.md` Phase 3 with the agreed rule: no new SQL/table creation until backend/page wiring is exhausted.
- Reused existing canonical tables from `current schema.md` instead of inventing Settings-prefixed tables.
- Wired the Settings payment terms page to real DB-backed rows.

### Live DB Check
- `payment_terms`: 16 existing rows.
- `default_payment_terms`: 1 existing row for the active entity context checked earlier in this phase.
- Confirmed `payment_terms` has FK dependents from purchase orders, sales orders, bills, and default payment terms.

### Backend Files
- `backend/src/modules/settings-setup/settings-setup.module.ts`
  - Added Settings Setup Nest module using existing `SupabaseModule`.
- `backend/src/modules/settings-setup/settings-setup.controller.ts`
  - Added Settings-owned payment terms routes.
- `backend/src/modules/settings-setup/settings-setup.service.ts`
  - Added CRUD/default logic over `payment_terms` and `default_payment_terms`.
  - Implemented delete as `is_active=false` to preserve FK integrity.
- `backend/src/app.module.ts`
  - Registered `SettingsSetupModule`.

### Frontend Files
- `lib/modules/settings/setup/payment_terms/presentation/pages/payment_terms_settings_page.dart`
  - Removed local `_defaultTerms` seed data as primary source.
  - Loads payment terms from `GET /settings-setup/payment-terms`.
  - Saves new terms through `POST /settings-setup/payment-terms`.
  - Updates terms/status through `PATCH /settings-setup/payment-terms/:id`.
  - Sets tenant default through `POST /settings-setup/payment-terms/:id/default`.
  - Maps delete/bulk delete to backend deactivation and keeps status visible.
  - Added loading/empty/error states without fabricating placeholder business rows.

### Routes Added
- `GET /settings-setup/payment-terms`
- `POST /settings-setup/payment-terms`
- `PATCH /settings-setup/payment-terms/:id`
- `DELETE /settings-setup/payment-terms/:id`
- `POST /settings-setup/payment-terms/:id/default`

### Verification
- `npm.cmd run build` in `backend`
  - Result: passed.
- `dart format lib/modules/settings/setup/payment_terms/presentation/pages/payment_terms_settings_page.dart`
  - Result: passed.
- `dart analyze lib/modules/settings/setup/payment_terms/presentation/pages/payment_terms_settings_page.dart`
  - Result: no issues found.

### Remaining
- Continue Phase 3 with units/UQC, currencies, and general date/fiscal preferences using existing DB tables/routes first.
- Reminders still need schema confirmation before backend implementation; no placeholder table was created.

Timestamp of Log Update: July 20, 2026 - 3:39 PM (IST)
## 64) [2026-07-20 15:44:06] Settings setup Phase 3B units and UQC DB wiring

### Scope
- Continued Settings Setup backend/page wiring without creating SQL tables.
- Reused existing `products/lookups/units` and `products/lookups/uqc` backend contracts because they already map to canonical `units` and `uqc` tables.
- Removed demo placeholder data from the Settings units page.

### Live DB Check
- `units`: 52 existing rows checked earlier in Phase 3.
- `uqc`: 72 existing rows checked earlier in Phase 3.

### Backend Files
- No new backend files were required for this slice.
- Existing backend routes reused:
  - `GET /products/lookups/units`
  - `POST /products/lookups/units/sync`
  - `POST /products/lookups/units/check-usage`
  - `GET /products/lookups/uqc`

### Frontend Files
- `lib/modules/settings/setup/units_of_measurement/presentation/pages/settings_units_of_measurement_page.dart`
  - Removed hardcoded demo unit rows (`Box`, `Centimeter`, `Milli Grams`, `Pieces`) as primary data.
  - Removed the hardcoded UQC option list as primary data.
  - Loads units from `GET /products/lookups/units`.
  - Loads UQC options from `GET /products/lookups/uqc`.
  - Saves unit create/update through `POST /products/lookups/units/sync`.
  - Maps unit delete to `is_active=false` through the same sync route to preserve referenced unit IDs.
  - Added loading and empty states backed by DB results instead of fabricated rows.

### Verification
- `npm.cmd run build` in `backend`
  - Result: passed.
- `dart format lib/modules/settings/setup/units_of_measurement/presentation/pages/settings_units_of_measurement_page.dart`
  - Result: passed.
- `dart analyze lib/modules/settings/setup/units_of_measurement/presentation/pages/settings_units_of_measurement_page.dart`
  - Result: no issues found.

### Remaining
- Unit groups/conversions remain local-empty because `current schema.md` does not confirm a unit group/conversion table.
- Continue Phase 3 with currencies and general date/fiscal preferences using existing tables/routes first.

Timestamp of Log Update: July 20, 2026 - 3:44 PM (IST)
## 65) [2026-07-20 16:08:21] Settings backend one-go existing-schema completion and final SQL handoff

### Scope
- Continued Settings backend completion without applying SQL midstream.
- Reused confirmed current-schema tables first and deferred missing persistence surfaces into one additive SQL handoff file.
- Removed demo/placeholder seed data from the Settings pages touched in this batch.

### Backend Files
- `backend/src/modules/settings-setup/settings-setup.controller.ts`
  - Added Settings-owned routes for currencies, date formats, date separators, and fiscal years.
- `backend/src/modules/settings-setup/settings-setup.service.ts`
  - Added CRUD/deactivate over existing `currencies`.
  - Added read endpoints over existing `date_format`, `date_separator`, and `fiscal_years`.
- `backend/src/modules/settings-customization/settings-customization.module.ts`
  - Added Settings Customization module using existing `SupabaseModule`.
- `backend/src/modules/settings-customization/settings-customization.controller.ts`
  - Added Settings reporting tag routes.
- `backend/src/modules/settings-customization/settings-customization.service.ts`
  - Added CRUD/deactivate over existing `reporting_tags` with tenant `entity_id`.
- `backend/src/app.module.ts`
  - Registered `SettingsCustomizationModule`.

### Frontend Files
- `lib/modules/settings/setup/currencies/presentation/pages/currencies_settings_page.dart`
  - Removed hardcoded seeded currency rows as primary data.
  - Removed sample exchange-rate import rows and skipped-row demo CSV data.
  - Loads currencies from `GET /settings-setup/currencies`.
  - Saves create/update through `POST|PATCH /settings-setup/currencies`.
  - Shows loading/empty states from DB results.
  - Exchange-rate import now reports that the exchange-rate table is required before persistence.
- `lib/modules/settings/customization/reporting_tags/presentation/pages/reporting_tag_create_page.dart`
  - Removed demo rows (`ADGF`, `shedule`, `demo advaced reporting tag`).
  - Loads tags from `GET /settings-customization/reporting-tags`.
  - Saves tag create/update through backend routes.
  - Toggles active/inactive through backend patch.
  - Shows loading/empty states from DB results.
- Previously completed in the same Settings backend run:
  - `lib/modules/settings/setup/payment_terms/presentation/pages/payment_terms_settings_page.dart`
  - `lib/modules/settings/setup/units_of_measurement/presentation/pages/settings_units_of_measurement_page.dart`

### Routes Added/Reused
- Added `GET|POST /settings-setup/currencies`.
- Added `PATCH|DELETE /settings-setup/currencies/:id`.
- Added `GET /settings-setup/date-formats`.
- Added `GET /settings-setup/date-separators`.
- Added `GET /settings-setup/fiscal-years`.
- Added `GET|POST /settings-customization/reporting-tags`.
- Added `PATCH|DELETE /settings-customization/reporting-tags/:id`.
- Reused existing product lookup routes for units/UQC.
- Reused existing payment term table data through the Settings Setup facade.

### SQL Handoff
- Added one additive SQL file for missing schema-backed persistence:
  - `supabase/sql/settings_backend_completion_tables.sql`
- The SQL uses only `CREATE TABLE IF NOT EXISTS` and `CREATE INDEX IF NOT EXISTS`.
- No destructive reset/delete/update statements are included.
- Missing persistence surfaces covered in the SQL:
  - general settings preferences
  - currency exchange rates
  - unit groups and conversions
  - reporting tag options and module mappings
  - reminder rules
  - print templates
  - email notification templates
  - custom fields
  - generic approval rules

### Verification
- `npm.cmd run build` in `backend`
  - Result: passed.
- `dart analyze` on touched Settings pages:
  - currencies
  - reporting tags
  - units of measurement
  - payment terms
  - Result: no issues found.
- `flutter build web --dart-define=ENABLE_AUTH=false`
  - Result: passed and built `build\web`.
  - Existing wasm dry-run warning remains for `dart:html` in procurement purchase request report.
- Placeholder scan on touched Settings pages:
  - removed/absent: `ADGF`, `edrftgyhnuj`, `demo advaced`, `_defaultTerms`, `_sampleImportedExchangeRates`, `Centimeter`, `Milli Grams`.

### Residuals
- General Settings UI still contains many preference controls whose current schema has no dedicated persistence table; those are covered by `general_preferences` in the SQL handoff.
- Reporting tag options/module mappings are not fully persisted until the SQL handoff tables are created.
- Unit groups/conversions are not fully persisted until the SQL handoff tables are created.
- Currency exchange-rate import is not persisted until `currency_exchange_rates` is created.

Timestamp of Log Update: July 20, 2026 - 4:08 PM (IST)
## 66) [2026-07-21 10:39:54 +05:30] Settings backend SQL-backed contract expansion

- Scope:
  - Continued Settings backend completion after existing-table slices for taxes, transaction series, locking, payment terms, units/UQC, currencies, and reporting tags.
  - Kept this batch additive: no database SQL was applied and no existing runtime table was dropped, reset, or destructively migrated.
  - Aligned backend contracts with the pending one-shot SQL file: `supabase/sql/settings_backend_completion_tables.sql`.

- Frontend Files:
  - No frontend files changed in this batch.
  - Deferred page wiring for these new SQL-backed routes until the final SQL tables are applied, so current screens do not call missing tables at runtime.

- Backend Files:
  - `backend/src/modules/settings-setup/settings-setup.controller.ts`
    - Added tenant-scoped routes for general preferences, currency exchange rates, and unit groups.
    - Added soft-deactivate endpoints for exchange rates and unit groups to preserve referenced configuration history.
  - `backend/src/modules/settings-setup/settings-setup.service.ts`
    - Added `general_preferences` read/upsert using `entity_id` from `@Tenant()`.
    - Added `currency_exchange_rates` list/create/update/deactivate validation and tenant filtering.
    - Added `unit_groups` plus `unit_group_conversions` read/create/update support with child conversion replacement.
  - `backend/src/modules/settings-customization/settings-customization.controller.ts`
    - Added reporting-tag config routes for options and module mappings.
    - Added explicit allowlisted CRUD routes for reminder rules, print templates, email notification templates, custom fields, and approval rules.
  - `backend/src/modules/settings-customization/settings-customization.service.ts`
    - Added reporting-tag option/module-mapping replacement flow.
    - Added tenant-scoped allowlist CRUD helper for `reminder_rules`, `print_templates`, `email_notification_templates`, `custom_fields`, and `approval_rules`.
    - Added print-template default setter that clears previous defaults only inside the same tenant and module.
  - `supabase/sql/settings_backend_completion_tables.sql`
    - Added `currency_exchange_rates.is_active` so the backend can deactivate exchange-rate rows instead of deleting them.
  - `SETTINGS_BACKEND_IMPLEMENTATION_PLAN.md`
    - Marked SQL-backed setup/customization backend contracts as built and documented their runtime dependency on the final SQL run.

- Verification:
  - `npm.cmd run build` in `backend/` passed.
  - Did not smoke-call new SQL-backed endpoints because their tables are intentionally pending until the final one-shot SQL execution.

- Residual Risks / Next Work:
  - Apply `supabase/sql/settings_backend_completion_tables.sql` before wiring frontend pages to the new SQL-backed routes.
  - Continue Phase 5 module settings field mapping so sales, purchase, and inventory settings pages persist only fields with schema ownership.

- Timestamp: 2026-07-21 10:39:54 +05:30

## 67) [2026-07-21 11:39:08 +05:30] Settings SQL activation, persistence wiring, and tenant hardening

### Scope
- Re-read refreshed `current schema.md` after the user applied the Settings SQL.
- Completed runtime wiring for schema-backed Settings preferences, customization records, approval rules, currency exchange rates, and unit groups.
- Preserved existing data and ownership: no SQL was executed, no table was reset, and no unrelated worktree changes were reverted.

### Frontend Files
- `lib/modules/settings/shared/data/repositories/settings_preferences_repository.dart`
  - Added reusable general-preferences read/save contract used by module-owned Settings pages.
- Sales, Purchase, and Inventory Settings pages
  - Connected invoice, sales order, credit note, delivery challan, retainer invoice, purchase order, purchase receive, expense, shipment, stock count, and transfer order preferences to `general_preferences`.
  - Reused live accountant, organization, inventory-adjustment reason, and warehouse data where applicable.
  - Removed seeded status, account, vehicle, category, reason, and address rows from the connected pages.
- `lib/modules/settings/general/customers_and_vendors/presentation/pages/customers_and_vendors_settings_page.dart`
  - Replaced toast-only save with DB-backed behavior and address-format persistence.
- `lib/modules/settings/setup/currencies/presentation/pages/currencies_settings_page.dart`
  - Loads latest tenant exchange rates alongside canonical currencies.
  - Saves manual rates through `currency_exchange_rates`.
  - Replaced the SQL-wait placeholder with real CSV/TSV import that resolves DB currency IDs and updates same-date rows.
- `lib/modules/settings/setup/units_of_measurement/presentation/pages/settings_units_of_measurement_page.dart`
  - Loads, creates, updates, and deactivates unit groups/conversions through Settings Setup routes.
- Approval, print-template, reminder, email-template, custom-field, and reporting-tag Settings pages
  - Replaced local/demo records with schema-backed CRUD where canonical tables exist.
  - Approval approvers now come from active users and persist in `approval_rules.approvers`.
  - Removed seeded sender/reminder identities where no canonical sender-domain table exists.
- `REUSABLES.md`
  - Registered `SettingsPreferencesRepository`.

### Backend Files
- `backend/src/modules/settings-setup/settings-setup.controller.ts`
- `backend/src/modules/settings-setup/settings-setup.service.ts`
  - Added tenant-safe general preferences, currency-rate, and unit-group contracts.
  - Recursive JSON merge prevents one module preference save from erasing sibling Settings sections.
  - Aligned currency-rate CRUD with refreshed schema: no `is_active`; delete is tenant-filtered physical deletion.
  - Tenant-filtered unit-group update/deactivation.
- `backend/src/modules/settings-customization/settings-customization.controller.ts`
- `backend/src/modules/settings-customization/settings-customization.service.ts`
  - Tenant-filtered reporting tags and all generic customization updates/deactivations.
  - Reporting-tag option/module configuration now verifies parent-tag tenant ownership.
  - Generic payloads are restricted to configured select allowlists.
- `supabase/sql/settings_backend_completion_tables.sql`
  - Removed stale `currency_exchange_rates.is_active` declaration so retained SQL matches `current schema.md`.

### Governance and Tracking
- `SETTINGS_BACKEND_IMPLEMENTATION_PLAN.md`
  - Marked Phases 5 and 6 complete.
  - Recorded refreshed-schema activation and schema-limited concepts.
  - Custom document statuses and sender-domain DNS settings remain intentionally unpersisted because no canonical table exists; fake persistence was not introduced.

### Verification
- `npm.cmd run build` in `backend/`: passed.
- Focused `dart analyze` on newly connected Settings files: no errors.
- Broader `dart analyze lib/modules/settings`: no hard errors; remaining output is warning/info-level legacy deprecation cleanup.
- Dart formatting completed for touched Flutter files.
- No DB mutation command was run in this batch.

Timestamp of Log Update: 2026-07-21 11:39:08 +05:30


### Verification Addendum for Entry 67
- `flutter build web --dart-define=ENABLE_AUTH=false`: passed in 243.0 seconds.
- Artifact produced: `build/web`.
- Existing non-blocking Wasm dry-run warning remains for `dart:html` in the procurement purchase-request report.

Timestamp of Log Update: 2026-07-21 11:39:08 +05:30


## 68) [2026-07-21 12:11:06 +05:30] Settings tax CRUD activation and backed action completion

### Scope
- Continued the Settings completion audit after SQL activation.
- Reused existing module providers, backend routes, confirmation dialog, and tenant-scoped customization contracts.
- Added no tables, duplicate repositories, or speculative bulk endpoints.

### Frontend Files
- `lib/modules/settings/taxes/providers/settings_tax_rates_provider.dart`
  - Replaced local-only tax state and generated IDs with real `settings-taxes/rates` and `settings-taxes/groups` reads.
  - Connected create, update, delete, active/inactive, refresh, and group child mappings to existing backend routes.
  - Preserved current filter/selection UI while reloading canonical DB rows after mutations.
- `lib/modules/settings/taxes/models/settings_tax_rate_model.dart`
  - Corrected stale handoff documentation now that persistence exists.
- `lib/modules/settings/setup/currencies/presentation/pages/currencies_settings_page.dart`
  - Replaced unavailable placeholders with DB-backed exchange-rate history and confirmed currency deactivation.
  - Active currency list now excludes deactivated master rows.
- `lib/modules/settings/setup/reminders/presentation/pages/settings_reminders_page.dart`
  - Connected overflow/editor delete actions to reminder-rule deactivation with confirmation.
- `lib/modules/settings/customization/reporting_tags/presentation/pages/reporting_tag_create_page.dart`
  - Connected row delete to tenant-scoped reporting-tag deactivation with confirmation.
- `test/modules/settings/taxes/settings_tax_rates_provider_test.dart`
  - Added focused status/type filter coverage for schema-backed tax rows.
- `SETTINGS_BACKEND_IMPLEMENTATION_PLAN.md`
  - Marked tax frontend CRUD and reuse of individual routes for bulk UI complete.

### Backend Files
- No backend source changes were needed; existing `settings-taxes`, `settings-setup`, and `settings-customization` contracts were reused.

### Verification
- Focused `dart analyze`: no errors; only existing warning/info-level tax-page cleanup remains.
- `flutter test test/modules/settings/taxes/settings_tax_rates_provider_test.dart`: passed.
- `npm.cmd run build` in `backend/`: passed.

### Residual
- Direct-tax TDS/TCS editor dialogs still contain handoff-local form masters and need a separate schema-backed mapping to TDS/TCS sections, rates, groups, natures, reasons, and accountant accounts.

Timestamp of Log Update: 2026-07-21 12:11:06 +05:30


## 69) [2026-07-21 12:52:02 +05:30] Direct-tax settings DB activation

### Scope
- Completed the schema-backed Direct Taxes settings slice without adding tables.
- Reused `settings-taxes`, `accountant`, `general_preferences`, shared
  `SettingsPreferencesRepository`, `FormDropdown`, `ZerpaiDatePicker`, toast,
  and confirmation dialog contracts.

### Frontend
- `lib/modules/settings/taxes/direct_taxes/presentation/pages/direct_taxes_create_page.dart`
  - Replaced copied TDS/TCS/demo rows and hardcoded employee/account options with
    live database reads.
  - Loaded TDS sections, rates, groups, TCS natures, TCS reasons/rates, and
    accountant accounts from existing backend routes.
  - Connected TDS/TCS and TDS-group create, edit, delete, activate, and deactivate
    actions to canonical persisted IDs.
  - Preserved group membership through `tds_rate_ids`; added working status/type
    filters and removed the nonfunctional associated-records action.
  - Added canonical TDS surcharge/cess editing so PATCH operations do not erase
    existing values.
  - Persisted apply mode, liabilities report configuration, start period, and
    penalty/interest account IDs under
    `charges_preferences.direct_taxes` in `general_preferences`.
  - Guarded stale stored account names so `FormDropdown` never receives a value
    absent from its live item list.
- `SETTINGS_BACKEND_IMPLEMENTATION_PLAN.md`
  - Marked Direct Taxes frontend/backend integration and demo removal complete.

### Backend
- No backend source or SQL changes. Existing canonical routes and tables covered
  the complete slice.

### Verification
- Direct Taxes focused `dart analyze`: exit 0, no errors or warnings; two Flutter
  Radio API deprecation infos remain.
- Full Settings `dart analyze`: no errors; five pre-existing warnings and existing
  Flutter deprecation infos remain outside this slice.
- Focused Flutter tax-provider test: passed, 1 test.
- `npm.cmd run build` in `backend/`: passed.
- Direct Taxes demo/dummy/dead-action scan: no business placeholder records found.
- `git diff --check` for Direct Taxes: passed.
- Flutter web verification build passed to `build/web_direct_tax_verify`; the
  existing procurement `dart:html` Wasm advisory remains non-blocking.

Timestamp of Log Update: 2026-07-21 12:52:02 +05:30

## 70) [2026-07-21 15:50:43 +05:30] Settings placeholder cleanup after backend completion
- Continued the Settings backend completion pass using
  `SETTINGS_BACKEND_IMPLEMENTATION_PLAN.md` and latest log state.
- The implementation plan already marked Phases 1-6 complete, so this pass
  avoided inventing new backend work and targeted leftover fake Settings data.
### Frontend
- `lib/modules/settings/sales/credit_notes/presentation/pages/credit_notes_settings_page.dart`
  - Removed the unsupported QR placeholder row `demo feild` /
    `{{customer_demo_field}}`.
- `lib/modules/settings/taxes/presentation/pages/settings_taxes_overview_page.dart`
  - Removed the copied demo account option `demo for purchase`.
### Backend
- No backend or SQL changes were needed.
### Verification
- Focused scan for `demo feild`, `customer_demo_field`, and
  `demo for purchase`: no matches under `lib/modules/settings`.
- `dart analyze` on the two touched pages: no errors; existing warning/info
  items remain in the older tax overview and credit note settings code.
- `git diff --check` on touched pages: no whitespace errors; normal LF/CRLF
  notice remains for the credit notes settings file.
Timestamp of Log Update: 2026-07-21 15:50:43 +05:30

---

## 71. Settings Frontend Runtime Integration Pass

Date: 2026-07-21 16:59:24 +05:30

### Scope
- Continued the SETTINGS_BACKEND_IMPLEMENTATION_PLAN.md follow-up by wiring
  settings-backed preferences into related main-interface create screens.
- Kept changes frontend-only; no database, migration, or backend contract changes.

### Runtime Wiring Completed
- Sales Order create now reads `pdf_preferences.documents.sales_orders` for
  new-document customer notes and terms defaults.
- Sales Invoice create now reads `pdf_preferences.documents.invoices` for
  new-document customer notes and terms defaults.
- Credit Note create now reads `pdf_preferences.documents.credit_notes` for
  new-document customer notes and terms defaults.
- Delivery Challan create now reads `pdf_preferences.documents.delivery_challans`
  for new-document customer notes defaults.
- Retainer Invoice create now reads
  `pdf_preferences.documents.retainer_invoices` for new-document customer notes
  defaults.
- Purchase Order create now reads `stock_preferences.purchase.purchase_orders`
  for new-document notes and terms defaults.
- Purchase Receive create now reads
  `stock_preferences.purchase.purchase_receives.receive_qty_more_than_ordered`
  and enforces it during save validation.
- Shipment create now reads
  `stock_preferences.inventory.shipments.notify_manual_shipments` for the
  notification checkbox default.

### Reporting Tags Integration
- Sales Order reporting-tags overlay now loads active tag names from
  `settings-customization/reporting-tags` instead of hardcoded ADGF/shedule/demo
  labels.
- Purchase Order line reporting-tags overlay now loads active tag names from
  `settings-customization/reporting-tags` instead of hardcoded ADGF/schedule/demo
  labels.
- Credit Note bulk-update, page-level reporting-tags popover, and new-item
  dialog now load active tag names from `settings-customization/reporting-tags`
  instead of hardcoded demo labels.
- Where no active reporting tags exist, the runtime UI now shows an explicit
  empty configured-state message instead of fabricated tag controls.

### Verification
- `dart format` completed on all touched frontend files.
- Focused `dart analyze` passed with no issues for:
  - `lib/modules/sales/sales_orders/presentation/pages/sales_order_create.dart`
  - `lib/modules/sales/invoices/presentation/pages/sales_invoice_create.dart`
  - `lib/modules/sales/credit_note/presentation/pages/credit_note_create_page.dart`
  - `lib/modules/sales/delivery_challans/presentation/pages/sales_delivery_challan_create.dart`
  - `lib/modules/sales/retainer_invoices/presentation/pages/sales_retainer_invoice_create.dart`
  - `lib/modules/purchases/purchase_orders/presentation/pages/purchases_purchase_orders_create.dart`
  - `lib/modules/purchases/purchase_receives/presentation/pages/purchases_purchase_receives_create.dart`
  - `lib/modules/inventory/shipments/presentation/pages/inventory_shipments_create.dart`
- `git diff --check` passed for the same touched files.

### Residual Risks / Follow-Up
- Stock Count and Transfer Order settings persist operational preferences, but
  their current create screens do not expose directly matching controls for every
  saved preference; no fake mapping was added.
- Expenses settings currently persist mileage/account/category preferences, not
  generic note defaults; the Expense create screen still has separate reporting
  tag/custom-field placeholder debt that needs a dedicated customization pass.
- Stale reporting-tag/custom-field placeholders remain outside this settings
  backend plan integration slice in composite items, purchase requests,
  expenses, recurring expenses, vendor credits, vendors, customers, and sales
  returns.
## 2026-07-22 08:16:41 +05:30 - Settings frontend DB-derived hardcoded data audit

- Updated `HARDCODED_DATA_AUDIT_REPORT.md` with a dedicated Settings backend/frontend wiring audit based on `SETTINGS_BACKEND_IMPLEMENTATION_PLAN.md`, `current schema.md`, `REUSABLES.md`, backend lookup/controllers, and Dart scans.
- Confirmed backend settings phases are marked complete, but frontend wiring remains mixed: several screens consume DB-backed lookup/settings APIs while others still keep local currency, GST treatment, phone code, state/supply, payment-term, INR, reporting-tag, account, and vendor/account fixture defaults.
- Documented concrete files and line anchors for remaining DB-derived Dart hardcoding, including customer/vendor create, expenses create, credit note create, shared currency/phone constants, org settings defaults, customer/vendor sidebars, and recurring expense dialogs.
- Added remediation order focused on shared DB-backed providers for countries, states, currencies, GST treatments, GST registration types, payment terms/defaults, organization base currency, reporting tags, and normalized tax lookup ownership.
- Verification: static repo audit only; no runtime code paths changed and no analyzer/build run required for documentation-only update.

## 35) [2026-07-22 19:29:59] account_transactions -> journal_entry_lines repo-wide rename and migration prep

- Scope:
  - renamed the canonical accounting line table reference from ccount_transactions to journal_entry_lines across schema truth, backend query paths, frontend direct Supabase reads, and permission/module keys
  - added a dedicated SQL migration to rename the live table plus its constraint/index names and migrate saved role-permission JSON keys from ccount_transactions to journal_entry_lines
  - kept the diff owner-scoped: no workflow redesign, no unrelated report logic rewrite, no fabricated schema fields

- Frontend Files:
  - lib/app/routing/app_router.dart
    - updated the route permission gate for accountant transactions to the new journal_entry_lines module key so route protection resolves against the renamed permission bucket.
  - lib/core/auth/permission_registry.dart
    - renamed the accountant permission mapping and action-definition slugs to journal_entry_lines / ccountant.journal_entry_line.* so UI permission resolution matches the renamed module key.
  - lib/core/utils/error_handler.dart
    - updated the friendly schema-mismatch mapping to the new table name while keeping backward-compatible detection for legacy ccount_transactions error payloads during rollout.
  - lib/modules/settings/users_roles/providers/role_permission_scheme.dart
    - renamed the Users & Roles permission row label/key to Journal Entry Lines / journal_entry_lines.
  - lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart
    - moved the bill journal tab read path to journal_entry_lines.
  - lib/modules/accountant/manual_journals/presentation/pages/manual_journal_create_screen.dart
    - updated the validation copy to reference journal_entry_lines.
  - lib/modules/reports/presentation/pages/reports_audit_logs_screen.dart
    - updated audit-log table filters to the renamed table.

- Backend Files:
  - current schema.md
    - renamed the canonical table declaration and table-level constraint names to journal_entry_lines so project schema truth matches the requested DB direction.
  - ackend/drizzle/schema.ts
    - renamed the Drizzle table owner to journal_entry_lines and aligned generated index/constraint/check names.
  - ackend/src/db/schema.ts
    - renamed the runtime schema owner from ccountTransaction / ccount_transactions to journalEntryLine / journal_entry_lines.
  - ackend/src/common/middleware/tenant.middleware.ts
    - changed the accountant transactions module key to journal_entry_lines so backend permission gating follows the renamed permission bucket.
  - ackend/src/modules/accountant/accountant.service.ts
    - moved all accountant read/write operations to journal_entry_lines.
  - ackend/src/modules/inventory/services/inventory-adjustments.service.ts
    - moved inventory adjustment accounting inserts and log copy to journal_entry_lines.
  - ackend/src/modules/purchases/bills/services/bills.service.ts
    - moved bill-posting cleanup/insert paths to journal_entry_lines.
  - ackend/src/modules/purchases/expenses/services/expenses.service.ts
    - moved expense accounting cleanup/insert paths to journal_entry_lines.
  - ackend/src/modules/reports/reports.service.ts
    - moved report Supabase reads and raw SQL aggregates to journal_entry_lines.
  - ackend/src/modules/reports/reports.controller.spec.ts
    - updated normalized audit-log table expectations to journal_entry_lines.
  - ackend/src/modules/reports/reports.service.spec.ts
    - updated the mocked report table branch to journal_entry_lines.
  - ackend/drizzle/0027_journal_entry_lines_rename.sql
    - added the DB migration to rename the live table, constraint/index/check names, and stored role permissions JSON keys.

- Verification:
  - Ran dart analyze lib/core/auth/permission_registry.dart lib/core/utils/error_handler.dart lib/modules/settings/users_roles/providers/role_permission_scheme.dart
    - Result: pass (No issues found!).
  - Ran dart analyze lib/modules/purchases/bills/presentation/pages/purchases_bills_list.dart lib/app/routing/app_router.dart lib/modules/accountant/manual_journals/presentation/pages/manual_journal_create_screen.dart lib/modules/reports/presentation/pages/reports_audit_logs_screen.dart
    - Result: pass (No issues found!).
  - Ran 
px.cmd tsc -p tsconfig.build.json --noEmit in ackend/
    - Result: pass.
  - Ran 
px.cmd jest modules/reports/reports.controller.spec.ts --runInBand with a temporary dummy DATABASE_URL to bypass the repo's import-time DB guard
    - Result: pass.
  - Ran 
px.cmd jest modules/reports/reports.service.spec.ts --runInBand with a temporary dummy DATABASE_URL
    - Result: fail on a pre-existing date-range expectation (2026-03-17T00:00:00.000Z vs current 2026-03-17T23:59:59.999Z), not on the table rename.
  - Checked runtime DB env availability in this shell
    - Result: DATABASE_URL absent, DRIZZLE_DATABASE_URL absent.

- Residual risks / follow-up context:
  - Live DB migration was not executed from this session because no runtime database connection string is available in the shell. The SQL migration file is ready, but the actual database still needs that script applied in the target environment.
  - ackend/src/modules/reports/reports.service.spec.ts still has an unrelated failing expectation around end-of-day timestamp normalization; this predates the rename signal from this batch and should be fixed separately if you want the full reports spec green.
  - Historical Drizzle migration snapshots under ackend/drizzle/meta/ intentionally remain untouched; the new forward migration carries the runtime rename.

Timestamp of Log Update: July 22, 2026 - 7:29 PM (IST)

## 36) [2026-07-22 20:13:15] Manual journal item insert hardening for blank UI ids

- Scope:
  - fixed the manual_journal_items insert path that failed when new manual-journal rows were posted from the Flutter create screen with id: ""
  - kept the patch in the backend owner path so the journal save flow no longer depends on the frontend perfectly omitting transient UI ids or mixed camel/snake item fields

- Frontend Files:
  - No frontend files changed in this batch.
  - Confirmed the create-screen payload still sends new manual journal items with id: '', which is acceptable now because the backend normalizer strips blank UUIDs before insert.

- Backend Files:
  - ackend/src/modules/accountant/accountant.service.ts
    - Replaced the raw ...x spread inside 
eplaceManualJournalItems() with an explicit normalized insert payload for ccountsManualJournalItems.
    - Normalizes ccountId from either ccountId or ccount_id and rejects rows missing a valid account UUID.
    - Normalizes blank item ids through 
ormalizeUuid(x.id) so new rows use the DB default UUID instead of attempting to insert an empty string into manual_journal_items.id.
    - Normalizes contactId, contactType, contactName, description, and sortOrder from the mixed frontend payload shape before hitting Drizzle.
    - Converts debit/credit through the service numeric helper so stored values remain clean decimal strings.

- Root cause confirmed:
  - The failing request body posted new manual journal items with id: "".
  - 
eplaceManualJournalItems() previously inserted items.map((x) => ({ ...x, manualJournalId, entityId })), so Drizzle picked up the blank id field and generated an insert for manual_journal_items.id = ''.
  - The DB table defines manual_journal_items.id uuid NOT NULL DEFAULT gen_random_uuid(), so the correct behavior for new rows is to omit id, not send an empty string.

- Verification:
  - Ran 
px.cmd tsc -p tsconfig.build.json --noEmit in ackend/
    - Result: pass.
  - Re-checked the patched insert path for residual blank-id forwarding
    - Result: only normalized id: this.normalizeUuid(x.id) remains; no raw spread into ccountsManualJournalItems insert remains.

- Residual risks / follow-up context:
  - The frontend still serializes unsaved manual journal items with id: ''; the backend now safely tolerates that, so this is no longer a blocker.
  - If you want stricter payload hygiene later, a separate frontend cleanup batch can omit blank ids from ManualJournalItem.toJson(), but it is no longer required for successful journal creation.
  - This batch did not rerun a live POST against the local API from this shell; verification here is compile-level plus payload-path inspection.

Timestamp of Log Update: July 22, 2026 - 8:13 PM (IST)

## 37) [2026-07-22 20:20:09] Manual journal insert follow-up: omit blank item ids from Drizzle payload

- Scope:
  - resolved the remaining manual_journal_items insert failure after the first hardening pass
  - kept the fix in the backend owner path only, because the runtime error proved Drizzle was still being asked to insert the id column for brand-new journal items

- Frontend Files:
  - No frontend files changed in this follow-up batch.
  - Reconfirmed the UI payload still posts new manual journal items with id: '' during create flow.

- Backend Files:
  - ackend/src/modules/accountant/accountant.service.ts
    - Changed the normalized insert payload builder in 
eplaceManualJournalItems() to compute 
ormalizedId first and only spread { id: normalizedId } when a real UUID is present.
    - This removes the id column entirely for brand-new manual journal items so Postgres can apply gen_random_uuid() from manual_journal_items.id.

- Root cause confirmed:
  - The first hardening pass normalized blank item ids to 
ull, but still included the id property on every row object.
  - Drizzle therefore continued generating insert into manual_journal_items ("id", ...) values (, ...) and binding the first parameter as blank/null instead of omitting the column.
  - The latest runtime payload and SQL text proved this directly because "id" remained in the generated insert column list and the first bound param was still empty.

- Verification:
  - Ran 
px.cmd tsc -p tsconfig.build.json --noEmit in ackend/
    - Result: pass.
  - Rechecked the patched source
    - Result: 
eplaceManualJournalItems() now uses const normalizedId = this.normalizeUuid(x.id); plus ...(normalizedId ? { id: normalizedId } : {}); no unconditional id field remains in the insert payload.

- Residual risks / follow-up context:
  - The local backend process serving http://localhost:3001 must be restarted before this follow-up code takes effect if it is still running the old build.
  - If a new error appears after backend restart, it will likely be the next real DB constraint/message rather than the blank-id issue, because the generated insert should stop including manual_journal_items.id for new rows.

Timestamp of Log Update: July 22, 2026 - 8:20 PM (IST)

## 38) [2026-07-22 20:23:29] Manual journal status route method alignment

- Scope:
  - fixed the manual-journal status update endpoint mismatch causing 404 Cannot PUT /api/v1/accountant/manual-journals/:id/status
  - kept the change minimal: HTTP verb alignment only, no workflow or payload contract rewrite

- Frontend Files:
  - No frontend files changed in this batch.
  - Confirmed the frontend repository already calls PUT accountant/manual-journals/{id}/status.

- Backend Files:
  - ackend/src/modules/accountant/accountant.controller.ts
    - Changed the manual-journal status route decorator from @Post(...) to @Put(...) so the backend matches the existing frontend request method.

- Root cause confirmed:
  - The frontend sends PUT /api/v1/accountant/manual-journals/:id/status.
  - The backend controller exposed only POST /api/v1/accountant/manual-journals/:id/status.
  - Nest therefore returned 404 Not Found even though the service method already existed and the path shape was otherwise correct.

- Verification:
  - Ran 
px.cmd tsc -p tsconfig.build.json --noEmit in ackend/
    - Result: pass.

- Residual risks / follow-up context:
  - The running backend process on localhost:3001 must be restarted before this route-method fix takes effect.
  - After backend restart, the next returned error, if any, should be a real service/data issue rather than this 404 route mismatch.

Timestamp of Log Update: July 22, 2026 - 8:23 PM (IST)

## 39) [2026-07-22 20:32:00] Manual journals overview deep-link detail pane recovery

- Scope:
  - fixed the manual-journals overview/detail screen so clicking a journal from the list or opening a deep link under /accountant/manual-journals/:id reliably shows the right-side overview pane
  - removed the blank-detail failure mode caused by provider state only replacing existing rows instead of merging newly fetched detail rows
  - added an explicit right-pane loading/error placeholder so the detail route no longer silently collapses back to the list while detail fetch is resolving or has failed

- Frontend Files:
  - lib/modules/accountant/manual_journals/providers/manual_journal_provider.dart
    - updated selectJournal() to merge the fetched manual journal into state.journals when the selected id is not already present in the current list payload
    - this keeps selectedJournal resolvable for deep-link navigation, filtered views, and stale list snapshots where the detail record was not already hydrated locally
  - lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart
    - changed the desktop split-pane gate to follow the presence of a detail route id instead of requiring selectedJournal to already exist before rendering the overview pane
    - added an explicit white placeholder panel for loading, fetch-failure, and no-selection states so the overview area remains visible and user intent is preserved during async selection

- Backend Files:
  - No backend files changed in this batch.

- Root cause confirmed:
  - the overview route correctly passed initialJournalId into the provider, but selectJournal() only mapped over existing state.journals entries
  - when getManualJournal(id) returned a record that was not already present in state.journals, selectedJournal stayed null because the getter resolves only from the in-memory journals list
  - the screen then required selectedJournal != null before rendering the desktop split, so the overview pane disappeared entirely even though the route and fetch were valid

- Verification:
  - Ran dart format lib/modules/accountant/manual_journals/providers/manual_journal_provider.dart lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart
    - Result: pass.
  - Ran dart analyze lib/modules/accountant/manual_journals/providers/manual_journal_provider.dart lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_detail_panel.dart lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_list_panel.dart
    - Result: pass (No issues found!).

- Residual risks / follow-up context:
  - if the running Flutter app still shows the old blank-overview behavior, it needs a hot restart so the patched provider and overview screen are reloaded together
  - if the page next fails inside a detail action such as post/cancel, that would be a separate backend/runtime issue rather than this selection/rendering bug

Timestamp of Log Update: July 22, 2026 - 8:32 PM (IST)

## 40) [2026-07-22 20:45:50] Manual journal create publish action status fix

- Scope:
  - fixed the new-manual-journal create path where clicking Save and Publish still created a draft journal
  - kept the fix in the backend owner path so the create API now honors the status field already sent by the Flutter form

- Frontend Files:
  - No frontend files changed in this batch.
  - Confirmed the create screen already calls _save(ManualJournalStatus.posted) for the primary Save and Publish button.
  - Confirmed the repository already serializes the journal payload with status: 'posted' for publish actions.

- Backend Files:
  - backend/src/modules/accountant/accountant.service.ts
    - changed createManualJournal() to resolve create status from dto.journal_status ?? dto.status through the existing normalizeManualJournalStatus() helper instead of only reading dto.journal_status
    - this lets the current frontend payload create a posted journal directly when Save and Publish is clicked, while still preserving the legacy journal_status payload shape if any older caller still uses it

- Root cause confirmed:
  - the create screen built the journal with status = posted for the Save and Publish action
  - the repository posted that value as status in the request body
  - the backend createManualJournal() ignored dto.status and only read dto.journal_status, so every new journal fell back to draft via the default branch

- Verification:
  - Ran npx.cmd tsc -p tsconfig.build.json --noEmit in backend/
    - Result: pass.

- Residual risks / follow-up context:
  - the backend process on localhost:3001 must be restarted before the running app reflects this fix if it is still serving the older build
  - edit-mode publish still uses the separate status endpoint after saving the draft body, which is fine and intentionally unchanged in this batch

Timestamp of Log Update: July 22, 2026 - 8:45 PM (IST)

## 41) [2026-07-22 20:48:01] Manual journal publish/status enum normalization fix

- Scope:
  - fixed the backend manual-journal status update path that returned HTTP 500 when publishing a draft journal from the overview screen
  - aligned create and status-update flows with the real database enum by normalizing app payload status values before they hit manual_journals.status

- Frontend Files:
  - No frontend files changed in this batch.
  - Confirmed the overview publish action sends { status: 'posted' } and the create flow also uses posted as the app-level published state.

- Backend Files:
  - backend/src/modules/accountant/accountant.service.ts
    - updated updateManualJournalStatus() to normalize incoming status before DB update and before deciding whether to post the journal to journal_entry_lines
    - hardened normalizeManualJournalStatus() so legacy/app payload value posted is translated to the DB enum value published
    - preserved draft and cancelled, and soft-fallbacks unknown inputs to draft instead of throwing raw enum errors into the database layer

- Root cause confirmed:
  - manual_journals.status is backed by the Postgres enum accounts_manual_journal_status, whose allowed values are draft and published
  - the frontend and model layer use posted as the business label for a published journal
  - the backend previously passed posted straight into update manual_journals set status = $1, which caused the database to reject the value and surface the 500 seen on PUT /api/v1/accountant/manual-journals/:id/status

- Verification:
  - Ran npx.cmd tsc -p tsconfig.build.json --noEmit in backend/
    - Result: pass.

- Residual risks / follow-up context:
  - the running backend process on localhost:3001 must be restarted before publish/status changes start working in the browser
  - the app intentionally still maps API/database published back to ManualJournalStatus.posted on the Flutter side, so no frontend label churn was required in this batch

Timestamp of Log Update: July 22, 2026 - 8:48 PM (IST)

## 42) [2026-07-22 20:53:40] Manual journal status toast copy made context-aware

- Scope:
  - replaced the generic manual-journal status success toast on the overview page with a context-aware message that reports the actual status transition
  - kept the change local to the page handler instead of widening shared toast infrastructure for a one-screen copy tweak

- Frontend Files:
  - lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart
    - added a tiny local status label mapper for Draft / Published / Cancelled
    - changed publish and cancel success toasts to read in the form: Status changed from <old> to <new>.
    - reused the updated journal returned by updateStatus() so the destination label reflects the persisted result rather than a hardcoded assumption

- Backend Files:
  - No backend files changed in this batch.

- Verification:
  - Ran dart format lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart
    - Result: pass.
  - Ran dart analyze lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart
    - Result: pass (No issues found!).

- Residual risks / follow-up context:
  - this updates the overview-screen status actions only; if you want the same status-transition wording on any other journal action surface, that can be copied there later

Timestamp of Log Update: July 22, 2026 - 8:53 PM (IST)

## 43) [2026-07-22 21:04:23] Manual journal edit route deep-linking and overview return-path fix

- Scope:
  - fixed the manual-journal edit action so clicking Edit from the overview/detail panel opens a real edit route instead of relying on in-memory extra state from the create route
  - made the edit screen deep-linkable on refresh by allowing it to load the journal from the route id when extra is absent
  - tightened overview/edit navigation so edit cancel/save returns to the specific journal overview route instead of dropping users back to the generic list

- Frontend Files:
  - lib/core/routing/app_routes.dart
    - added the canonical manual journal edit route constant: /accountant/manual-journals/:id/edit
  - lib/app/routing/app_router.dart
    - added a dedicated :id/edit child route under accountant/manual-journals
    - wired that route to ManualJournalCreateScreen with route-backed initialJournalId plus optional eager extra hydration when available
  - lib/modules/accountant/manual_journals/presentation/pages/manual_journal_create_screen.dart
    - added initialJournalId support for URL-backed edit mode
    - when edit opens without extra, the screen now fetches the journal by id before rendering the form instead of silently behaving like a new journal screen
    - added a minimal edit bootstrap loader/error state
    - changed edit cancel and post-save navigation to return to /accountant/manual-journals/:id so overview context stays deep-linkable
    - switched edit-mode source of truth from widget.initialJournal-only to the resolved route-backed journal
  - lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart
    - changed the Edit action to navigate to the new deep-linkable edit route instead of the generic create route

- Backend Files:
  - No backend files changed in this batch.

- Root cause confirmed:
  - the overview panel edit action navigated to /accountant/manual-journals/create and passed the selected journal only via GoRouter extra
  - on refresh or any navigation path where extra was absent, ManualJournalCreateScreen saw widget.initialJournal == null and initialized as a new journal flow
  - there was no canonical /:id/edit route for manual journals, so edit state was not URL-addressable even though the overview route already was

- Verification:
  - Ran dart format lib/core/routing/app_routes.dart lib/app/routing/app_router.dart lib/modules/accountant/manual_journals/presentation/pages/manual_journal_create_screen.dart lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart
    - Result: pass.
  - Ran dart analyze lib/core/routing/app_routes.dart lib/app/routing/app_router.dart lib/modules/accountant/manual_journals/presentation/pages/manual_journal_create_screen.dart lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart
    - Result: pass (No issues found!).

- Residual risks / follow-up context:
  - create-mode template/sidebar state remains intentionally non-deep-linked in this batch; only the edit/overview route flow was normalized
  - if you want search/filter/deeper list-state preserved in the URL as well, that can be added later, but the journal overview detail and edit states are now properly addressable

Timestamp of Log Update: July 22, 2026 - 9:04 PM (IST)

## 44) [2026-07-22 21:10:27] Manual journal overview load-state polish, reusable ribbon adoption, and clone id fix

- Scope:
  - fixed the manual-journal clone backend failure at the shared item-insert root
  - removed the distracting top-bar spinner during clone/status/template mutations while keeping action disabling intact
  - replaced the custom manual-journal corner ribbon with the shared reusable document ribbon component
  - upgraded deep-link/manual-select detail loading to use the shared document skeleton and shared error placeholder instead of the blank placeholder panel

- Frontend Files:
  - lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart
    - replaced the empty detail placeholder with shared loading/error states from lib/shared/widgets/z_skeletons.dart
    - direct-url / selected-journal overview now shows ZDocumentDetailSkeleton while detail data is resolving
    - failed detail fetches now use shared ZErrorPlaceholder with an inline retry hook back into selectJournal(..., forceRefresh: true)
  - lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_detail_panel.dart
    - removed the header spinner that was appearing in the ribbon/action bar during clone and other mutations
    - swapped the custom hand-built diagonal ribbon to the shared ZerpaiDocumentCornerRibbon from lib/shared/widgets/document/zerpai_document_view.dart
    - changed successful clone navigation to the deep-linkable manual journal edit route instead of the generic create route so the cloned draft opens in the correct editing context

- Backend Files:
  - backend/src/modules/accountant/accountant.service.ts
    - simplified replaceManualJournalItems() so inserted manual_journal_items rows never reuse incoming item ids
    - this is the correct root fix because the helper always deletes then reinserts rows, so preserving source item ids adds no value and breaks clone/reverse-style flows when old ids are replayed into a fresh journal

- Root cause confirmed:
  - the clone endpoint copied original journal items including existing manual_journal_items ids
  - replaceManualJournalItems() was still willing to forward a valid incoming id into a brand-new insert row, so clone attempted to create fresh manual_journal_items using ids that already belonged to the source journal rows
  - the overview panel also rendered a generic blank placeholder during detail fetch gaps, which looked broken on direct-url loads and reloads even when the page was still resolving state
  - the journal page still used a local custom diagonal ribbon even though the shared reusable document ribbon already exists in the repo

- Verification:
  - Ran dart format lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_detail_panel.dart
    - Result: pass.
  - Ran dart analyze lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_detail_panel.dart
    - Result: pass (No issues found!).
  - Ran npx.cmd tsc -p tsconfig.build.json --noEmit in backend/
    - Result: pass.

- Residual risks / follow-up context:
  - reverse/create-template actions were reviewed alongside clone; no code changes were required in this batch beyond the shared insert-id root fix, but reverse now benefits from the same item-id correction automatically
  - if you want the full document body itself migrated onto the larger shared ZerpaiDocumentView shell later, that can be a separate visual cleanup; this batch only switched the highlighted ribbon reusable and loading/error states

Timestamp of Log Update: July 22, 2026 - 9:10 PM (IST)

## 45) [2026-07-22 21:20:18] Shared CustomTextField tight-height overflow guard

- Scope:
  - fixed the shared CustomTextField RenderFlex overflow triggered when the reusable is embedded inside tight-height table/form cells
  - kept the fix at the reusable root so every caller using the same constrained-height pattern benefits automatically

- Frontend Files:
  - lib/shared/widgets/inputs/custom_text_field.dart
    - added a tight-height guard so the external label row is not rendered when the host constraints are too short to fit label + gap + field without overflow
    - this matches the existing external-error guard pattern already used in the same reusable and prevents the 6 px bottom overflow seen in the manual-journal tight cell layout

- Backend Files:
  - No backend files changed in this batch.

- Root cause confirmed:
  - CustomTextField always stacked label + 6 px gap + field inside a Column
  - in constrained layouts the widget was receiving maxHeight ~= 42 px while still trying to render 32 px field height plus external label chrome, which overflowed the RenderFlex vertically

- Verification:
  - Ran dart format lib/shared/widgets/inputs/custom_text_field.dart
    - Result: pass.
  - Ran dart analyze lib/shared/widgets/inputs/custom_text_field.dart
    - Result: pass (No issues found!).

- Residual risks / follow-up context:
  - this fix hides only the external label in tight-height host cells; normal form layouts remain unchanged
  - if a future caller needs labels inside similarly tight cells, that should be an inline/overlay label pattern rather than a stacked external label in the shared field

Timestamp of Log Update: July 22, 2026 - 9:20 PM (IST)

## 46. 2026-07-22 21:49:58 Manual journal template persistence + account hydration fix
- Scope: repaired accountant manual-journal/template regressions causing template creation from the journal create page to fail and edit/detail/account transaction screens to miss account labels when APIs returned nested account objects.
- Backend: updated `backend/src/modules/accountant/accountant.service.ts` so journal templates use explicit field mapping, persist `journal_template_items`, reload hydrated template payloads via Drizzle joins, and stop relying on raw DTO spreading.
- Frontend: updated `lib/modules/accountant/manual_journals/models/manual_journal_model.dart` and `lib/modules/accountant/models/account_transaction_model.dart` to resolve account labels from nested `account` payloads in addition to flat `account_name` keys.
- Root cause: template create/update flows only wrote the header row while dropping item lines; separate UI hydration assumed flat `account_name` fields even though the accountant APIs were already returning nested account objects.
- Verification: `dart analyze E:/zerpai-new/lib/modules/accountant/manual_journals` ✅, `dart analyze E:/zerpai-new/lib/modules/accountant` ✅, `npx.cmd tsc -p tsconfig.build.json --noEmit` in `backend/` ✅.
- Residual risk: browser UAT still required for create-template, edit-page value hydration, and template re-apply flows; Microsoft Clarity `clarity.js` console noise seen in screenshot is external and not part of this repo patch.

## 47. 2026-07-23 00:14:12 Make Recurring routing + recurring hydration + report-shell dispose fix
- Scope: fixed accountant manual-journal -> recurring-journal conversion flow where Make Recurring opened the recurring form on a stale manual-journal edit URL, lost source data prefill, and triggered shared widget assertions/row overflows during navigation.
- Routing: updated manual journal Make Recurring actions in `lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_detail_panel.dart` and `lib/modules/accountant/manual_journals/presentation/pages/manual_journal_create_screen.dart` to navigate with a deep-linkable `sourceManualJournalId` query param plus the in-memory source payload.
- Recurring form: updated `lib/app/routing/app_router.dart` and `lib/modules/accountant/recurring_journals/presentation/pages/recurring_journal_create_screen.dart` so recurring create can recover from dropped `extra` payloads by fetching the source manual journal by id, show shared loading/error states while hydrating, and keep prefill stable on refresh/direct-open.
- Shared UI fix: updated `lib/shared/widgets/reports/zerpai_report_shell.dart` so overlay cleanup during `dispose()` no longer calls `setState()` on a defunct element; reduced recurring contact/debit/credit field heights to stop the repeated 6 px RenderFlex overflow in journal rows.
- Verification: `dart analyze E:/zerpai-new/lib/modules/accountant/recurring_journals` ✅, `dart analyze E:/zerpai-new/lib/modules/accountant/manual_journals` ✅, `dart analyze E:/zerpai-new/lib/shared/widgets/reports/zerpai_report_shell.dart` ✅, `dart analyze E:/zerpai-new/lib/app/routing/app_router.dart` ✅.
- Residual risk: browser UAT still required for Make Recurring from both manual-journal detail and edit pages to confirm URL now resolves to `/accountant/recurring-journals/create?sourceManualJournalId=...` and that full line/account/contact prefill survives refresh.

## 48. 2026-07-23 10:56:42 Recurring journal backend mapping + template tx visibility + explicit return navigation
- Scope: fixed accountant recurring journal save/save-as-draft failures, manual-journal template creation 404s, and recurring create cancel/save navigation regressions after Make Recurring flow changes.
- Backend: updated `backend/src/modules/accountant/accountant.service.ts` so recurring journals use explicit field mapping, persist `recurring_journal_items`, return hydrated recurring payloads, normalize recurring status updates, and reload newly created/updated journal templates inside the same transaction instead of querying pre-commit through the global DB.
- Frontend routing: updated `lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_detail_panel.dart`, `lib/modules/accountant/manual_journals/presentation/pages/manual_journal_create_screen.dart`, `lib/app/routing/app_router.dart`, and `lib/modules/accountant/recurring_journals/presentation/pages/recurring_journal_create_screen.dart` to pass `sourceManualJournalId` plus `returnTo`, load recurring create from source-id fallback, send cancel back to the caller route, and route successful recurring saves to recurring journal detail instead of using browser-history pop.
- Handoff: refreshed `HANDOFF_MANUAL_JOURNALS_2026-07-22.md` with the 2026-07-23 continuation fixes and the current recurring/template UAT priorities.
- Verification: `npx.cmd tsc -p tsconfig.build.json --noEmit` in `backend/` ✅, `dart analyze E:/zerpai-new/lib/modules/accountant/recurring_journals/presentation/pages/recurring_journal_create_screen.dart` ✅, `dart analyze E:/zerpai-new/lib/app/routing/app_router.dart` ✅, `dart analyze E:/zerpai-new/lib/modules/accountant/manual_journals/presentation/pages/manual_journal_create_screen.dart E:/zerpai-new/lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_detail_panel.dart` ✅.
- Residual risk: browser UAT still required for create recurring, draft recurring, cancel from both manual-journal origins, and template creation from both edit/detail/manual-entry flows to confirm API success and expected post-save destination behavior.
## 49. 2026-07-23 11:29:56 Manual journal direct-detail route reselection fix
- Scope: fixed accountant manual-journal deep-link detail pages staying on the shared skeleton even though the detail API returned 200 data.
- Frontend Files:
  - lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart
    - added route-aware reselection guard in build so the overview reissues selectJournal(initialJournalId) when the provider is recreated after auth/provider churn and loses selectedJournalId.
    - kept loop protection by skipping reselection while loading or after a recorded failed fetch.
- Backend Files:
  - No backend files changed in this batch.
- Root cause confirmed:
  - direct /accountant/manual-journals/:id navigation fired the detail fetch successfully, but a later provider refresh/reset could clear selectedJournalId after the one-shot initState selection call.
  - the detail pane renders ZDocumentDetailSkeleton whenever state.selectedJournal is null, so the page stayed in the skeleton state despite successful list/detail API responses.
- Verification:
  - dart analyze E:/zerpai-new/lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart pending in current run.
  - browser recheck of /60000000000/accountant/manual-journals/421864f0-8277-43bd-8f21-cb2e173e572e pending in current run.
- Residual risk: recurring/template UAT is continuing immediately after this direct-detail route check because those flows depend on the same overview entry point being stable.

Timestamp of Log Update: July 23, 2026 - 11:29 AM (IST)

## 50. 2026-07-23 12:01:02 Recurring journal list schema-drift fix
- Scope: fixed accountant recurring-journal backend failures where recurring list hydration crashed on a live-table/schema mismatch, blocking recurring create/save follow-up UAT with repeated `GET /accountant/recurring-journals` 500s.
- Backend Files:
  - `backend/src/db/schema.ts`
    - removed the stale `entity_id` column mapping from `accountsRecurringJournalItems` to match the live `recurring_journal_items` table shape in `current schema.md`.
  - `backend/src/modules/accountant/accountant.service.ts`
    - stopped writing `entityId` into recurring journal item inserts.
    - removed customer/vendor join dependence from recurring list/detail hydration and resolved recurring `contact_name` from persisted recurring item data instead.
- Root cause confirmed:
  - live DB `recurring_journal_items` does not contain `entity_id`, but backend Drizzle schema still selected and inserted it.
  - exact in-process query failure reproduced as `column recurring_journal_items.entity_id does not exist`, which surfaced in the API as `GET /api/v1/accountant/recurring-journals` 500.
- Verification:
  - `npm.cmd run build` in `backend/` ✅
  - direct API check after patch: `GET http://localhost:3001/api/v1/accountant/recurring-journals` with tenant/auth headers ✅ `200 OK`
- Residual risk:
  - browser UAT after the backend fix still needs completion for recurring save/save-as-draft and template flows; Playwright on the Flutter web page still showed renderer/hit-target instability around lower-page clicks, so the remaining browser pass should be treated as ongoing rather than complete.

Timestamp of Log Update: July 23, 2026 - 12:01 PM (IST)

## 51. 2026-07-23 12:05:00 Dashboard report journal-entry schema drift fix
- Scope: fixed backend report queries still reading the removed `journal_entry_lines.transaction_type` column, which was generating live `42703` errors for dashboard sales trend and top-customer sections.
- Backend Files:
  - `backend/src/db/schema.ts`
    - removed the stale `transaction_type` mapping from `journalEntryLine` so the runtime model matches `current schema.md`.
  - `backend/src/modules/reports/reports.service.ts`
    - switched dashboard sales-trend and top-customer filters from `transaction_type` to `source_type`.
    - changed account-transactions report output to expose `source_type` as the report `type` field instead of selecting the missing `transaction_type` column.
- Root cause confirmed:
  - live `journal_entry_lines` schema contains `source_type` but not `transaction_type`.
  - attachment log errors for `sales trend` and `top customers` were current schema-drift issues, not harmless startup noise.
- Verification:
  - `npm.cmd run build` in `backend/` ✅
  - direct API check: `GET http://localhost:3001/api/v1/reports/dashboard-summary` with auth/tenant headers ✅ `200 OK`
- No SQL required:
  - backend code was wrong; live schema already matched `current schema.md`.
  - startup `Cannot GET /health`, `Cannot GET /`, and `cancelled_quantity already exists, skipping` entries remain non-blocking noise unless a real health endpoint is explicitly needed.

Timestamp of Log Update: July 23, 2026 - 12:05 PM (IST)

## 52. 2026-07-23 12:40:43 Root health endpoint alias
- Scope: added the requested `/health` endpoint path without duplicating health-check logic.
- Backend Files:
  - `backend/src/main.ts`
    - added a direct root-path alias that redirects `/health` to the existing `/api/v1/health` controller route.
- Root cause confirmed:
  - health module/controller already existed and worked under the global prefix.
  - the 404 came from callers hitting `/health` while Nest only exposed `/api/v1/health`.
- Verification:
  - `npm.cmd run build` in `backend/` ✅
  - `GET http://localhost:3001/health` ✅ `302 Found` -> `/api/v1/health`
  - `GET http://localhost:3001/api/v1/health` ✅ `200 OK`
- No extra service or duplicate controller added.

Timestamp of Log Update: July 23, 2026 - 12:40 PM (IST)

## 53. 2026-07-23 12:50:09 Recurring journal item entity-scope recovery
- Scope: restored canonical tenant scoping for 
ecurring_journal_items so recurring child rows follow the same ntity_id ownership rule already used by manual_journal_items, journal_entry_lines, and other entity-owned accountant tables.
- Backend Files:
  - ackend/src/db/schema.ts
    - re-added ntityId to ccountsRecurringJournalItems so Drizzle matches the intended entity-scoped table contract.
  - ackend/src/modules/accountant/accountant.service.ts
    - recurring item inserts now persist ntityId: tenant.entityId instead of relying only on the parent recurring journal row.
  - ackend/drizzle/0028_recurring_journal_items_entity_scope_recovery.sql
    - added an idempotent recovery migration that adds ntity_id if missing, backfills from 
ecurring_journals.entity_id, enforces NOT NULL, restores the foreign key, and creates an index.
- Docs:
  - current schema.md
    - updated public.recurring_journal_items to include ntity_id uuid NOT NULL plus the organisation_branch_master foreign key so schema docs match the tenancy rule.
- Root cause confirmed:
  - current schema.md and live DB had drifted away from the intended tenant-owned recurring-item contract even though earlier migrations and generated Drizzle snapshots already expected 
ecurring_journal_items.entity_id.
  - that drift forced earlier symptom patches and left recurring child visibility dependent on parent rows instead of the canonical child-table tenant column.
- Verification:
  - 
pm.cmd run build in ackend/ ✅
  - migration SQL file prepared for manual execution ✅
- Operator note:
  - user later requested code-only + SQL handoff with no further agent-driven DB writes; follow that rule for next batches.
- Residual risk:
  - authenticated recurring-journal API UAT is still pending because the previously captured bearer token is now expired; browser/local-session verification should be rerun after the user executes the SQL in their chosen environment.

Timestamp of Log Update: July 23, 2026 - 12:50 PM (IST)

## 54. 2026-07-23 12:59:12 Accountant schema re-alignment after current schema refresh
- Scope: re-swept the accountant/report backend paths touched in the recent journal stabilization batches against the newly updated current schema.md and removed the last stale code assumptions that no longer match the canonical DB shape.
- Backend Files:
  - ackend/src/db/schema.ts
    - tightened accountant-owned Drizzle mappings to match the refreshed schema by marking ntity_id as required on journal_entry_lines, manual_journals, manual_journal_items, journal_number_settings, journal_templates, journal_template_items, 
ecurring_journals, and 
ecurring_journal_items.
    - kept the recurring-item ntity_id contract in place so child-row tenancy stays explicit and schema-aligned.
  - ackend/src/modules/accountant/accountant.service.ts
    - replaced the stale 	ransaction_type = 'Opening Balance' reads/writes in opening-balance journal-entry logic with source_type = 'Opening Balance' so Supabase account adjustments now match the updated journal_entry_lines schema.
- Root cause confirmed:
  - the refreshed current schema.md now clearly codifies source_type on journal_entry_lines and ntity_id NOT NULL across the accountant child/header tables.
  - one older account-opening-balance path still targeted the removed 	ransaction_type column even after the earlier reports fix, so it would have remained a hidden sibling failure.
- Verification:
  - 
pm.cmd run build in ackend/ ✅
- Operator boundary:
  - no further agent-driven DB writes were performed after the user requested code-only plus SQL handoff.
- Residual risk:
  - authenticated browser/API UAT still depends on the user’s live session/token and their manual execution flow for any future SQL.

Timestamp of Log Update: July 23, 2026 - 12:59 PM (IST)

## 55. [2026-07-23 13:10:59] Manual journal posting now creates journal_entries headers
- Scope: fixed accountant manual-journal posting so published journals now populate journal_entries, replace their journal_entry_lines idempotently, and persist the manual_journals.ledger_journal_entry_id backlink.
- Backend Files:
  - ackend/src/modules/accountant/accountant.service.ts
    - implemented the previously stubbed postJournalToTransactions() shared posting path.
    - create-manual-journal now correctly posts when normalized status becomes published instead of checking the unreachable pre-normalized posted value.
    - posting now balances-checks line totals, upserts one journal_entries header for the manual journal, deletes prior child lines on re-post, recreates journal_entry_lines with journal_entry_id + tenant scope, and updates manual_journals.ledger_journal_entry_id plus 	otal_amount.
    - added an internal transaction-safe loader so create-and-post inside the same DB transaction can read the just-inserted journal/items before commit.
  - ackend/src/db/schema.ts
    - added Drizzle mappings for journal_entries, journal_entry_lines.journal_entry_id, journal_entry_lines.org_id, journal_entry_lines.line_number, journal_entry_lines.contact_name, and manual_journals.ledger_journal_entry_id so code matches current schema.md.
- Root cause confirmed:
  - postJournalToTransactions() was an empty stub, so publish flows never created journal_entries rows.
  - createManualJournal() normalized posted -> published but still checked journal.status === 'posted', so create-and-post could never enter the posting path.
  - Drizzle also lacked the manual_journals.ledger_journal_entry_id mapping, so even after header creation there was no typed backlink owner in code.
- Verification:
  - 
pm.cmd run build in ackend/ ✅
- SQL required:
  - none for this fix if your live DB already matches current schema.md; the missing behavior was backend code, not a missing table/column.
- Residual risk:
  - older already-published manual journals created before this patch will stay missing from journal_entries until you backfill them deliberately; new publishes after this code change should populate both header and line tables.

Timestamp of Log Update: July 23, 2026 - 1:10 PM (IST)


## 56. [2026-07-23 14:06:22] Accounts and Accountant backend completion foundation

- Scope:
  - Replaced Accountant backend stubs and stale schema assumptions with one
    entity-scoped ledger contract.
  - Preserved the operator boundary: no database writes, seeds, schema pushes,
    or migration execution were performed by Codex.

- Frontend Files:
  - No frontend files changed in this batch.

- Backend Files:
  - \`backend/src/common/account-visibility.util.ts\`
    - Removed cross-entity system-account visibility. Every account read now
      requires exact \`entity_id\` ownership.
  - \`backend/src/db/schema.ts\`
    - Realigned Accounts/Accountant Drizzle fields with \`current schema.md\`;
      removed stale columns and restored required entity/fiscal/ledger fields.
  - \`backend/src/modules/accountant/accountant-account-metadata.ts\`
    - Added one backend-owned account group/type metadata contract.
  - \`backend/src/modules/accountant/accountant.service.ts\`
    - Replaced account raw DTO spreading with explicit create/update maps.
    - Implemented account trees, balances, journal usage, safe parent checks,
      canonical opening-balance headers/lines, and opening-balance adjustment.
    - Implemented paginated transaction search and entity-validated bulk
      account reassignment.
    - Completed manual-journal header mapping, atomic posting, fiscal-year
      validation, status transitions, ledger linkage, and journal numbering.
    - Completed fiscal-year and journal-number setting persistence.
    - Added customer/vendor search and real account metadata.
    - Implemented R2 attachment validation/upload/database persistence/cleanup.
    - Replaced transaction-lock raw DTO writes with entity/module upserts.
    - Fixed recurring global hydration, entity/org context, duplicate checks,
      and generation progress ownership.
    - Removed unused duplicate report stubs; \`ReportsService\` remains owner.
  - \`backend/src/modules/accountant/accountant.controller.ts\`
    - Added opening-balance load route and pagination/contact transaction
      filters; corrected save service contract.
  - \`backend/src/modules/accountant/recurring-journals.cron.service.ts\`
    - Advanced \`last_generated_date\` after generated or already-existing runs
      and rejected incomplete entity context.

- Documentation:
  - \`accounts-accountant module completion audit.md\`
    - Added verified Batch 1 worklog and backend completion evidence.

- Verification:
  - \`npm.cmd run build\` in \`backend/\` passed.
  - TypeScript diagnostics were cleared before the Nest build.

- SQL:
  - No SQL was executed.
  - Constraint/index hardening remains queued for the manual-run SQL handoff.

- Residual work:
  - Flutter opening-balance, bulk-update, metadata, settings, and cache behavior.
  - Cross-module posting header consistency, focused tests, migration SQL, and
    authenticated browser UAT.

Timestamp of Log Update: July 23, 2026 - 2:06 PM (IST)


## 57. [2026-07-23] Accounts and Accountant frontend persistence completion

- Reworked Accountant repository runtime behavior to propagate metadata,
  transaction, balance, and currency failures instead of silently returning
  fabricated or empty business data.
- Removed hardcoded account metadata fallback, system-account hiding,
  fabricated default currency ID 999, and inconsistent Accountant Hive
  cache-key casing.
- Added backend hydration and explicit loading/error states to opening
  balances; both screens now reuse ZTableSkeleton and ZErrorPlaceholder and
  validate one-sided balances before save.
- Added server-paginated transaction search to Bulk Update, including contact
  type/id filters, page size, total count, navigation, shared loading state,
  and current-page refresh after updates.
- Rewired Accountant Settings to load and save fiscal-year dates/name,
  organization base currency, rounding, and tax preferences through existing
  SettingsPreferencesRepository and organization settings ownership.
- Added chart-of-accounts error propagation and canonical source_type/reference
  parsing for account transaction rows.
- Confirmed transaction locking intentionally uses the dedicated
  transaction-locking controller; no route rewrite was required.
- Focused dart analyze passed for all nine touched Dart files.
- Database writes performed by Codex: none. Archived logs were not edited.

## 60. [2026-07-23] Accountant DB-only currency and failure-state hardening

- Removed fabricated/manual INR currency rows from manual-journal create,
  journal-template create, and recurring-journal create.
- All three forms now resolve currencies through the existing
  `currenciesProvider` and organization-backed `defaultCurrencyProvider`.
- Missing, inactive, or stale currency codes now show explicit disabled/validation
  states and block persistence instead of silently becoming INR.
- Organization currency remains unresolved while settings load or fail; no
  loading/error fallback currency is fabricated.
- Manual-journal and recurring-journal API models now reject persisted payloads
  whose currency is missing.
- Removed swallowed fiscal-year/contact/journal-setting failures so Riverpod
  exposes real loading/error states.
- Replaced remaining Accountant Skeletonizer placeholder rows with shared
  `ZListSkeleton` and `ZErrorPlaceholder` controls.
- Removed hardcoded rupee formatting across Accountant journal, recurring,
  opening-balance, and bulk-update surfaces; persisted currency codes drive
  amount labels.
- Removed a fabricated journal creator display name; absent creator data now
  renders as `Not available`.
- Shared ledger posting now resolves missing currency from the persisted
  organization base currency, validates it against active `currencies`, and
  rejects invalid configuration. Expenses, bills, and inventory adjustments no
  longer force INR.
- Manual journals, templates, recurring journals, opening balances, and their
  ledger headers now use the same persisted currency validation path.
- Verification: Accountant/Accounts full Dart analysis passed; ledger and health
  Jest suites passed 5/5; backend Nest build passed.
- Database writes performed by Codex: none. Archived logs were not edited.

## 61. [2026-07-23 18:02:20 +05:30] Accounts/Accountant integrity hardening

- Backend logic:
  - Enforced date locks on new, replaced, voided, manual-journal, and
    opening-balance ledger dates.
  - Fixed inventory approval self-void, recurring branch tenancy, fiscal-year
    overlap, hierarchy cycles, fail-open usage checks, child-safe deletes,
    recurrence activation, and account/contact ownership.
  - Added header-backed transaction currency, exchange-rate, and BCY fields.
  - Prepared migration 0029 with organization currency backfill, rerunnable
    checks, and active fiscal-year overlap exclusion.
- Frontend logic:
  - Removed non-tenant Hive account fallback; tenant providers now invalidate on
    active-entity changes.
  - Removed hardcoded INR, transaction-date/BCY/exchange fabrication,
    rupee-only formatting, fake import/export, and ephemeral attachment success.
  - Restored permitted sub-account parents and enforced template balancing.
- Frontend files:
  - `lib/core/models/org_settings_model.dart`
  - `lib/modules/accountant/**`
  - `lib/modules/accounts/chart_of_accounts/**`
- Backend files:
  - `backend/src/modules/accountant/**`
  - `backend/src/modules/inventory/services/inventory-adjustments.service.ts`
  - `backend/src/modules/purchases/{bills,expenses}/services/**`
  - `backend/src/modules/transaction-locking/transaction-locking.service.ts`
  - `backend/drizzle/0029_accountant_completion_hardening.sql`
- Documentation: `accounts-accountant module completion audit.md`.
- Verification: backend build, focused Dart analysis, and complete
  Accounts/Accountant module analysis passed. Full repository analyzer exceeded
  the 120-second tool limit; no pass claimed.
- Residual blockers: sales/payment/return/credit-note posting, shared
  source+ledger transaction ownership, formal reversals, and dated FX.
- Database writes/migration execution by Codex: none.


## 58. [2026-07-23] Production health endpoint hardening

- Reworked GET /api/v1/health so dependency readiness controls HTTP status:
  healthy returns 200; database failure or configured Redis outage returns 503.
- Public health output now contains only timestamp, aggregate status, and
  database/Redis up-down-disabled checks.
- Removed environment/configuration flags, Supabase URL fragments,
  credential-presence flags, raw dependency errors, and exception messages.
- Added focused tests for healthy, database error, database exception, and
  configured Redis outage behavior.
- Verification: health controller Jest suite passed 4/4; backend Nest build
  passed.
- Database writes performed by Codex: none. Archived logs were not edited.


## 59. [2026-07-23] Canonical cross-module ledger posting

- Added Accountant-owned LedgerPostingService as the single posting path for
  non-manual source documents.
- The service validates organization/entity context, active entity-owned
  accounts, active fiscal-year containment, one-sided positive lines, and
  exact debit/credit balance.
- Header and lines now replace atomically and idempotently by source
  module/type/document; voiding removes report-visible lines while preserving
  a VOIDED journal header.
- Expenses now post only in RECORDED status, void on draft/deleted state, and
  retain vendor/customer contact context.
- Purchase Bills now post/void on every status transition, use persisted items
  during status-only changes, and no longer use a zero org id, arbitrary first
  account, nonexistent transaction_type column, or direct line inserts.
- Inventory Adjustments now derive balanced asset and adjustment-account sides
  from product inventory mappings and the selected adjustment/COGS account;
  one-sided fallback posting was removed.
- Re-approving an already-approved inventory adjustment idempotently repairs
  its ledger linkage; rejection/deletion voids its source journal.
- Verification: ledger and health Jest suites passed 5/5; backend Nest build
  passed; no direct legacy line writers remain in bills, expenses, or
  inventory adjustments.
- Database writes performed by Codex: none. Archived logs were not edited.

## 62. [2026-07-24] Attached Flutter diagnostics repair

- Added required account currency propagation to purchase bill, purchase order,
  sales invoice, and sales order account-tree nodes; updated manual-journal
  model fixture currency.
- Removed unreachable pricelist builders, legacy purchase-return preview,
  unused approval dialog, dead settings fields, and unused billed-total work.
- Replaced attached deprecated color opacity calls and migrated the taxes type
  selector to Flutter `RadioGroup`.
- Verification: `dart analyze` across all 24 files in the attached diagnostic
  export completed with zero errors and zero warnings.
- Residual: 50 non-failing Flutter `Radio.groupValue`/`onChanged` deprecation
  infos remain across legacy settings and purchasing selectors; migrate via
  the existing `ZerpaiRadioGroup<T>` reusable in a separate UI-safe batch.
- Database writes performed by Codex: none.

## 63. [2026-07-24] Migration 0029 zero-org ownership repair

- Fixed migration 0029 to repair zero-org accounts from canonical
  `organisation_branch_master` ownership before repairing legacy journal lines.
- ORG entities resolve through their own `ref_id`; BRANCH entities resolve
  through their parent ORG `ref_id`. Unresolved ownership still fails closed.
- Corrected the legacy header backfill join from nonexistent
  `public.organizations` to canonical `public.organization`.
- Verification: every `public.*` table referenced by migration 0029 exists in
  `current schema.md`; `git diff --check` passed.
- Database writes performed by Codex: none. The failed transaction rolled back;
  rerun the complete migration file manually.
- Manual database verification supplied by the user:
  `unresolved_zero_org_lines = 0` and
  `migration_indexes_created = true`; migration 0029 is confirmed applied.

## 64. [2026-07-24 11:23:32 +05:30] Manual-journal tenant recovery

- Root cause:
  - Auth organization resolution accepted a legacy zero UUID from Supabase
    metadata before checking canonical `users.entity_id` ownership.
  - Manual-journal loading errors were rendered as a false empty state.
- Backend Files:
  - `backend/src/common/auth/auth.service.ts`
    - Canonical entity ownership now resolves organization first.
    - Zero UUID metadata is rejected; user-editable metadata is no longer used
      for organization authorization.
  - `backend/src/common/auth/auth.service.spec.ts`
    - Added focused regression coverage for stale zero metadata.
- Frontend Files:
  - `lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_list_panel.dart`
    - Empty-load failures now display the actual error instead of
      `No manual journals found`.
- Verification:
  - Focused Jest: 1/1 passed.
  - Backend Nest build passed.
  - Focused Dart analysis passed with no issues.
  - Local backend rebuilt/restarted; health reports database and Redis up.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 11:23 AM (IST)

## 65. [2026-07-24 11:28:25 +05:30] Manual-journal currency parsing

- Root cause:
  - Accountant API returns Drizzle journal currency as `currencyCode`.
  - Flutter accepted only `currency_code` and `currency`, so one valid journal
    rejected the complete list as missing currency.
- Frontend Files:
  - `lib/modules/accountant/manual_journals/models/manual_journal_model.dart`
    - Added the existing API camelCase field to currency parsing.
  - `test/modules/accountant/manual_journals/models/manual_journal_model_test.dart`
    - Added regression coverage for `currencyCode`.
- Backend Files:
  - No backend files changed in this batch.
- Verification:
  - Focused Dart analysis passed.
  - Focused Flutter model tests passed 3/3.
  - `git diff --check` passed.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 11:28 AM (IST)

## 66. [2026-07-24 11:44:09 +05:30] Manual-journal UI shell alignment

- Aligned Manual Journals with the existing Purchases Bills workspace:
  - Removed the inset rounded card and restored the shared edge-to-edge canvas.
  - Standardized the list header to 64 px and the split-list rail to 360 px.
  - Kept journal-specific view, period, columns, actions, and routes unchanged.
  - Restructured detail UI into a document header, neutral action strip, draft
    guidance banner, and light document canvas.
- Reused:
  - `ZerpaiLayout` for the module workspace.
  - `ZTooltip` for detail action and close guidance.
  - Existing manual-journal responsive table, skeleton, document ribbon, and
    confirmation-dialog reusables.
- Frontend Files:
  - `lib/modules/accountant/manual_journals/presentation/pages/manual_journals_overview_screen.dart`
  - `lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_list_panel.dart`
  - `lib/modules/accountant/manual_journals/presentation/widgets/manual_journals_detail_panel.dart`
- Backend Files:
  - No backend files changed in this batch.
- Verification:
  - Focused Dart analysis passed with no issues.
  - `git diff --check` passed.
  - No matching widget test exists; authenticated browser UAT remains manual.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 11:44 AM (IST)

## 67. [2026-07-24 11:49:22 +05:30] Journal modal placement

- Manual and recurring journal column-customization dialogs now open at the
  top center with zero outer inset.
- Manual journal dialog surface now uses explicit pure white.
- Verification: focused Dart analysis and `git diff --check` passed.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 11:49 AM (IST)

## 68. [2026-07-24 11:58:53 +05:30] Recurring-journal UI shell alignment

- Applied the established Manual Journals and Purchases Bills workspace shell
  to Recurring Journals without changing recurring-journal business behavior.
- List workspace:
  - Removed the boxed card and enabled the edge-to-edge `ZerpaiLayout` canvas.
  - Added the 64 px title/action toolbar, module New action, search, status
    filter, working column-customization menu, shared loading/error states,
    standard page-size options, and a real 360 px compact split list.
- Detail workspace:
  - Added the document header, neutral action strip, top-right close action,
    light content canvas, and preserved Overview/Child Journal tabs.
  - Preserved edit, generate-child, stop/resume, clone, delete, and deep-link
    behavior.
- Reused `ZerpaiLayout`, `FormDropdown`, `ZTooltip`, `ZTableSkeleton`,
  `ZErrorPlaceholder`, and existing confirmation/toast controls.
- Frontend Files:
  - `lib/modules/accountant/recurring_journals/presentation/pages/recurring_journal_overview_screen.dart`
  - `lib/modules/accountant/recurring_journals/presentation/widgets/recurring_journals_list_panel.dart`
  - `lib/modules/accountant/recurring_journals/presentation/widgets/recurring_journals_detail_panel.dart`
- Verification:
  - Full recurring-journals module Dart analysis passed with no issues.
  - `git diff --check` passed.
  - No matching widget test exists; authenticated browser UAT remains manual.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 11:58 AM (IST)

## 69. [2026-07-24 12:06:27 +05:30] Journal runtime UI repair

- Fixed the 1 px Manual and Recurring Journal detail-header overflow by
  accounting for the bottom-border pixel inside the existing 92 px header.
- Fixed recurring-journal loading by accepting the API's Drizzle
  `currencyCode` field alongside existing currency aliases.
- Added focused recurring-journal parser coverage for the API camelCase shape.
- Verification:
  - Focused Dart analysis passed with no issues.
  - Focused Flutter test passed 1/1.
  - `git diff --check` passed.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 12:06 PM (IST)

## 70. [2026-07-24 12:16:59 +05:30] Recurring detail back-navigation repair

- Root cause: browser history restored the recurring-journal detail URL while
  provider selection remained stale, leaving the detail skeleton mounted.
- Recurring overview now reconciles selected journal state from the restored
  route after loading, matching the existing Manual Journals behavior.
- A completed lookup with no matching route record now shows an explicit
  not-found retry state instead of an indefinite skeleton.
- Verification: focused Dart analysis and `git diff --check` passed.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 12:16 PM (IST)

## 71. [2026-07-24 12:26:13 +05:30] Recurring child-journal amount repair

- Root cause:
  - The recurring child-journal endpoint returned only `manual_journals`
    headers.
  - Flutter correctly derives each journal amount from its loaded
    `manual_journal_items`, so omitted lines produced `INR 0.00`.
- Frontend Files:
  - No frontend files changed in this batch.
- Backend Files:
  - `backend/src/modules/accountant/accountant.service.ts`
    - Extended the canonical entity-scoped manual-journal query with an
      optional recurring-journal filter.
    - Reused that enriched query for recurring child journals so headers,
      journal lines, account data, and contact data use one mapping path.
- Verification:
  - Backend Nest build passed.
  - Built JavaScript contains the recurring-journal filter and enriched query.
  - Restarted backend is listening on port 3001.
  - Health reports database and Redis up.
  - `git diff --check` passed; only the existing LF/CRLF warning remains.
- Database writes performed by Codex: none.
- Residual:
  - Authenticated browser refresh remains required to reload repaired child
    journal payloads.

Timestamp of Log Update: July 24, 2026 - 12:26 PM (IST)

## 72. [2026-07-24 14:56:52 +05:30] Chart of Accounts UI alignment

- Frontend Files:
  - `lib/modules/accounts/chart_of_accounts/presentation/pages/accountant_chart_of_accounts_overview.dart`
    - Reused the Manual Journals edge-to-edge `ZerpaiLayout` workspace.
    - Moved view selection, New, More, and contextual bulk actions into the
      standard 64 px module toolbar.
    - Removed the inset rounded card and aligned the desktop split-list rail to
      360 px while preserving account tree, sorting, filtering, permissions,
      selection, menus, and deep-linked detail behavior.
  - `lib/modules/accounts/chart_of_accounts/presentation/widgets/accountant_chart_of_accounts_detail_panel.dart`
    - Aligned account detail with the journal 92 px document header, bordered
      close control, 48 px neutral action strip, and light content canvas.
    - Reused `ZTooltip`; account-specific balance, trend, transaction, edit,
      status, delete, and report behavior remains unchanged.
- Backend Files:
  - No backend files changed in this batch.
- Reused:
  - `ZerpaiLayout`, `ZTooltip`, existing account table/tree, skeleton,
    confirmation, permission, and routing owners.
- Verification:
  - Focused Dart analysis passed with no issues.
  - `git diff --check` passed; only existing LF/CRLF warnings remain.
  - Chrome connection could list tabs but could not create a grouped local tab;
    authenticated visual smoke remains pending.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 2:56 PM (IST)

## 73. [2026-07-24 15:12:34 +05:30] Accounts table density and footer parity

- Frontend Files:
  - `lib/modules/accounts/chart_of_accounts/presentation/pages/accountant_chart_of_accounts_overview.dart`
    - Matched Manual Journals' 51 px light table-header treatment.
    - Added the matching 48 px footer with real total count, page-size options,
      visible range, and functional previous/next navigation.
    - Kept the single Accounts New action because the module has one valid
      creation flow; no decorative empty split-menu action was introduced.
- Backend Files:
  - No backend files changed in this batch.
- Verification:
  - Focused Dart analysis passed with no issues.
  - `git diff --check` passed; only existing LF/CRLF warnings remain.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 3:12 PM (IST)

## 74. [2026-07-24 15:19:02 +05:30] Accounts split-menu alignment

- Frontend Files:
  - `lib/modules/accounts/chart_of_accounts/presentation/pages/accountant_chart_of_accounts_overview.dart`
    - Kept the main More menu right-aligned beneath its toolbar button.
    - Corrected Sort and Export submenus to open into the detail canvas during
      split view instead of overlapping the list rail and sidebar.
    - Preserved left-opening submenus in full-width list view where right-side
      viewport space is unavailable.
- Backend Files:
  - No backend files changed in this batch.
- Verification:
  - Focused Dart analysis passed with no issues.
  - `git diff --check` passed; only the existing LF/CRLF warning remains.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 3:19 PM (IST)

## 75. [2026-07-24 15:31:11 +05:30] Bulk Update contact loading

- Frontend Files:
  - `lib/modules/accountant/bulk_update/presentation/pages/accountant_bulk_update_screen.dart`
    - Reused `manualJournalContactsProvider` to populate the initial Contact
      dropdown instead of hardcoding an empty item list.
    - Preserved the existing remote contact search for typed filtering.
- Backend Files:
  - No backend files changed; the existing entity-scoped contacts endpoint
    already returns customers and vendors for blank and typed searches.
- Verification:
  - Focused Dart analysis passed with no issues.
  - `git diff --check` passed.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 3:31 PM (IST)

## 76. [2026-07-24 15:37:20 +05:30] Bulk Update date-range validation

- Frontend Files:
  - `lib/modules/accountant/bulk_update/presentation/pages/accountant_bulk_update_screen.dart`
    - Constrained the end-date picker to dates on or after the selected start.
    - Constrained the start-date picker to dates on or before the selected end.
    - Clamped each calendar's initial date into its valid selectable range.
    - Added a Search-time guard so an invalid range cannot reach the API.
- Backend Files:
  - No backend files changed in this batch.
- Reused:
  - Existing shared `ZerpaiDatePicker`; no duplicate range picker was created.
- Verification:
  - Focused Dart analysis passed with no issues.
  - Added a debug assertion for the calculated picker bounds.
  - `git diff --check` passed.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 3:37 PM (IST)

## 77. [2026-07-24 15:48:13 +05:30] Bulk Update required-date crash guard

- Frontend Files:
  - `lib/modules/accountant/bulk_update/presentation/pages/accountant_bulk_update_screen.dart`
    - Removed date-format placeholder text from the controllers so empty dates
      are represented as empty values.
    - Marked Date Range as required.
    - Blocked Search until both start and end dates are selected.
    - Kept the dialog open and skipped the API request when validation fails.
- Backend Files:
  - No backend files changed in this batch.
- Reused:
  - Existing `SharedFieldLayout`, `CustomTextField`, `ZerpaiDatePicker`,
    `ZButton`, and `ZerpaiToast`; no duplicate controls were created.
- Verification:
  - Focused Dart analysis passed with no issues.
  - `git diff --check` passed.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 3:48 PM (IST)

## 78. [2026-07-24 16:01:22 +05:30] Bulk Update results layout crash

- Frontend Files:
  - `lib/modules/accountant/bulk_update/presentation/pages/accountant_bulk_update_screen.dart`
    - Disabled the outer `ZerpaiLayout` body scroll so the page `Stack` receives
      bounded height.
    - The results `Column` can now safely size its `Expanded` table without a
      missing-size RenderFlex hit-test failure.
- Backend Files:
  - No backend files changed in this batch.
- Reused:
  - Existing `ZerpaiLayout.enableBodyScroll`; no layout wrapper was added.
- Verification:
  - Focused Dart analysis passed with no issues.
  - `git diff --check` passed.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 4:01 PM (IST)

## 79. [2026-07-24 16:50:41 +05:30] Transaction lock reason guard

- Frontend Files:
  - `lib/modules/accountant/transaction_locking/presentation/pages/accountant_transaction_locking_screen.dart`
    - Blocked module and lock-all submissions when the required reason is blank.
    - Trimmed submitted reasons, disabled repeated submits while loading, and
      kept dialogs open with user-facing feedback when locking fails.
  - `lib/modules/accountant/transaction_locking/providers/transaction_lock_provider.dart`
    - Added the shared pre-request blank-reason guard before optimistic state or
      API activity.
  - `test/modules/accountant/providers/transaction_lock_provider_test.dart`
    - Added blank-reason coverage and corrected rollback error assertions.
- Backend Files:
  - No backend files changed; its existing required-reason validation remains
    the authoritative API trust-boundary guard.
- Verification:
  - Focused Dart analysis passed with no issues.
  - Transaction-lock provider tests passed: 12.
  - `git diff --check` passed.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 24, 2026 - 4:50 PM (IST)

## 80. [2026-07-25 08:36:28 +05:30] Preserve transaction-lock API details

- Frontend Files:
  - `lib/core/utils/error_handler.dart`
    - Added support for the standard nested `meta.error.message` API envelope.
    - Preserves the backend lock module, through-date, and reason in user-facing
      error messages.
  - `lib/modules/accountant/manual_journals/repositories/manual_journal_repository.dart`
    - Reused `ErrorHandler` instead of replacing structured API errors with
      generic manual-journal fallback text.
  - `test/core/utils/error_handler_test.dart`
    - Added nested lock-envelope coverage and aligned one stale expected message
      with the current production wording.
- Backend Files:
  - No backend files changed; its existing transaction-lock message remains the
    source of truth.
- Verification:
  - Focused Dart analysis passed with no issues.
  - Error-handler tests passed: 4.
  - `git diff --check` passed.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 25, 2026 - 8:36 AM (IST)

## 81. [2026-07-25 08:41:18 +05:30] Unlock modal alignment

- Frontend Files:
  - `lib/modules/accountant/transaction_locking/presentation/pages/accountant_transaction_locking_screen.dart`
    - Replaced the custom centered `AlertDialog` with the shared confirmation
      dialog used by destructive confirmation flows.
    - Unlock confirmation now uses top-center alignment, zero inset padding,
      pure-white surface, and shared button styling.
- Reused:
  - Existing `showZerpaiConfirmationDialog()`; no new modal was created.
- Verification:
  - Focused Dart analysis passed with no issues.
  - `git diff --check` passed.
- Database writes performed by Codex: none.

Timestamp of Log Update: July 25, 2026 - 8:41 AM (IST)

## 82. [2026-07-25 11:25:42 +05:30] Negative-stock lock policy completion

- Backend Files:
  - `backend/src/modules/transaction-locking/transaction-locking.controller.ts`
    - Added tenant-scoped GET/PUT endpoints for the negative-stock lock policy.
  - `backend/src/modules/transaction-locking/transaction-locking.service.ts`
    - Persists Allow/Restrict in the existing entity-scoped `record_locking`
      table.
    - Defaults missing or inactive policy rows to Restrict.
    - Blocks lock creation under Restrict when entity accounting stock from
      `v_accounting_stock` is negative.
    - Allows lock creation without the stock check under Allow.
  - `backend/src/modules/transaction-locking/transaction-locking.service.spec.ts`
    - Covers Restrict rejection and Allow bypass.
- Frontend Files:
  - `lib/modules/accountant/transaction_locking/providers/transaction_lock_provider.dart`
    - Added entity-aware policy loading and validated persistence calls.
  - `lib/modules/accountant/transaction_locking/presentation/pages/accountant_transaction_locking_screen.dart`
    - Loads the persisted mode, displays it in the banner, saves Apply, restores
      persisted state on Cancel, and shows loading/success/error feedback.
    - Removed the unsupported automatic COGS-revaluation claim from Allow copy.
  - `test/modules/accountant/providers/transaction_lock_provider_test.dart`
    - Covers policy loading, saving, and unsupported-mode rejection.
- Verification:
  - Backend Nest build passed.
  - Backend focused Jest tests passed: 2.
  - Focused Dart analysis passed with no issues.
  - Flutter provider tests passed: 14.
  - `git diff --check` passed.
- Database migrations or direct writes performed by Codex: none.
- Runtime note:
  - Authenticated browser persistence/enforcement UAT remains separate because
    exercising Apply would mutate the active entity's configuration.

Timestamp of Log Update: July 25, 2026 - 11:25 AM (IST)
