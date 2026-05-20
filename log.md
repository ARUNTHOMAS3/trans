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

