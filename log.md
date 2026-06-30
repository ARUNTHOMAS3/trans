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

Timestamp of Log Update: June 29, 2026 - 3:00 PM (IST)
