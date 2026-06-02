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
  - **Coalesced API Field Parsing**: Updated romJson key mappings to check both snake_case and camelCase parameters (e.g. sub_total/subtotal, grand_total/	otal, discount_total/discount_amount) to prevent API parsing mismatch which led to ?0.00 totals display.
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
  - **Payment Terms Parsing**: Refactored paymentTerms in romJson to dynamically check if json['payment_terms'] is a Map (resolving nested database join values like 	erm_name) or string.
- lib/modules/purchases/bills/presentation/pages/purchases_bills_create.dart:
  - **Tax Dropdown Arrow Retention**: Restored Icons.arrow_drop_down visibility and the standard border in _taxCell when vendor is unregistered, ensuring it visually remains a dropdown box while keeping onTap: null (readonly).

#### Backend Files
- ackend/src/modules/purchases/bills/services/bills.service.ts:
  - **Payment Terms DB Join**: Added payment_terms:payment_terms(term_name) to Supabase queries in createBill, indAll, and indOne methods to return actual payment term values.

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

**Verifications**: Verified compilation successfully with lutter analyze on modified scopes.

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

**Verifications**: Verified compilation successfully with lutter analyze on modified scopes.

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
- **Quantity Column Width Expansion**: Increased aseWidth from 124.0 to 160.0 and ixedContentWidth from 116.0 to 140.0 in _dynamicQtyToReceiveColumnWidth() to give the batch cards more horizontal space and prevent overflow/tight layouts.

Timestamp of Log Update: June 1, 2026 - 6:01 PM (IST)
- **Batch Dialog Overwrite Logic Fix**: Configured the dialog Save onPressed callback to bypass exceeds and mismatch validation errors when _overwriteLineItem is enabled. Wired the checkbox onChanged event to immediately clear any existing mismatch or exceeds error messages. Changed the error banner text to dynamically display the active _dialogErrorMessage instead of the hardcoded _quantityMismatchMessage string.

Timestamp of Log Update: June 1, 2026 - 6:05 PM (IST)
