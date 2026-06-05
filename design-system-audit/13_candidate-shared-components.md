# 🚀 Candidate Shared Components

This document identifies UI patterns and components currently embedded within module-specific code that should be promoted to `lib/shared/widgets`. Extracting these will reduce code duplication, improve maintainability, and ensure visual consistency.

## 1. Core UI Primitives

### ZStatusBadge
- **Description**: A color-coded chip with a low-opacity background and semi-bold text.
- **Duplicate Implementations**: 
  - `lib/modules/sales/presentation/sales_order_list.dart` (`_buildStatusBadge`)
  - `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_list.dart` (`_buildStatusBadge`)
- **Suggested Abstraction**: `ZStatusBadge(status: "Draft", color: AppTheme.warningOrange)`
- **Standardization Priority**: **HIGH**
- **Estimated Impact**: Reduces ~50 lines per list screen and centralizes status color logic.

### ZSearchBar
- **Description**: A rounded container with a search icon, clean input, and optional filter/settings triggers.
- **Duplicate Implementations**: 
  - Found in almost every "Overview" screen (Sales, Purchases, Items).
- **Suggested Abstraction**: `ZSearchBar(hint: "Search...", onFilterTap: () => ...)`
- **Standardization Priority**: **HIGH**
- **Estimated Impact**: Ensures uniform search behavior and styling across the ERP.

## 2. Layout Patterns

### ZMasterDetailLayout
- **Description**: An adaptive split-view layout (typically 30/70) that transitions from a full list to a Master-Detail view on selection.
- **Duplicate Implementations**: 
  - `sales_order_list.dart`
  - `purchases_purchase_orders_list.dart`
  - `inventory_adjustments_page.dart`
- **Suggested Abstraction**: A reusable shell that handles the animation and state for the split view.
- **Standardization Priority**: **MEDIUM**
- **Estimated Impact**: Significantly simplifies the creation of new ERP modules.

### ZTransactionTotalsSection
- **Description**: The bottom-right totals summary (Subtotal, Tax, Adjustment, Round Off, Total).
- **Duplicate Implementations**: 
  - `sales_order_create.dart`
  - `purchases_purchase_orders_create.dart`
  - `sales_invoice_create.dart`
- **Suggested Abstraction**: `ZTransactionTotalsSection(subtotal: 100, taxes: [...], adjustment: 5)`
- **Standardization Priority**: **HIGH**
- **Estimated Impact**: Prevents calculation bugs and ensures "Zoho-style" alignment in all financial documents.

## 3. Specialized Widgets

### ZAddressDisplay
- **Description**: A formatted block for billing/shipping addresses with distinct icons for location/phone.
- **Duplicate Implementations**: 
  - `sales_order_create.dart` (`_buildCustomerAddressSection`)
  - `sales_customer_overview.dart`
- **Existing Shared Base**: `lib/shared/widgets/sections/address_section.dart` (Currently underutilized or inconsistent with module implementations).
- **Suggested Abstraction**: Standardize on `ZAddressDisplay` and deprecate local module variants.
- **Standardization Priority**: **MEDIUM**
- **Estimated Impact**: Centralizes address formatting logic which varies by locale/entity type.

### ZItemTableRow
- **Description**: A complex row widget for line items in transaction forms, supporting quantity, rate, discount, and tax popovers.
- **Duplicate Implementations**: 
  - `sales_order_create.dart` (`SalesOrderItemRow`)
  - `purchases_purchase_orders_create.dart`
- **Suggested Abstraction**: `ZTransactionItemRow` with configurable columns for Sales vs. Purchase context.
- **Standardization Priority**: **CRITICAL**
- **Estimated Impact**: Resolves the single largest source of code bloat in "Create" screens (which currently reach 10,000+ lines).

## 4. Interaction Patterns

### ZQuickCreateDropdown
- **Description**: A dropdown input with a "+ New [Entity]" button at the bottom of the list.
- **Duplicate Implementations**: 
  - Customer selection in Sales.
  - Vendor selection in Purchases.
  - Item selection in line items.
- **Suggested Abstraction**: Enhance `FormDropdown` to support a `footerAction` natively.
- **Standardization Priority**: **MEDIUM**
- **Estimated Impact**: Standardizes the "Quick Add" workflow which is core to ERP efficiency.

### ZCurrencyPill
- **Description**: A small badge showing the active currency for a transaction.
- **Duplicate Implementations**: 
  - `sales_order_create.dart`
  - `purchases_purchase_orders_create.dart`
- **Suggested Abstraction**: `ZCurrencyPill(currency: "INR")`
- **Standardization Priority**: **LOW**
- **Estimated Impact**: Consistent visual cue for multi-currency transactions.

## Summary Checklist for Developers
1. [ ] Check if `ZStatusBadge` covers your status needs before building a custom `Container`.
2. [ ] Use `ZSearchBar` for all module listing pages.
3. [ ] Propose any repeated "Section Card" from your module to this list if it appears in 2+ modules.
