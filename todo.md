# ZERPAI ERP - Technical TODO List

## 🔍 Search & Navigation

- [ ] **Navbar Global Search**: Enhance the central search in `ZerpaiNavbar` to support full-module searching and redirects.
- [ ] **Advanced Filtering**: Implement the backend logic for the local Search Popup in the Chart of Accounts (Account Name/Code matching).
- [ ] **Persistent State**: Ensure the 'Account View' filter and search results remain active when navigating back to the CoA page.

## 🏗️ Missing Modules (Placeholders needed)

The following modules are listed in the Search Switcher but lack routes or implementations:

- [ ] **Banking**: Create routes and placeholder screens for Banking transactions and statements.
- [ ] **Expenses**: Implement Expense tracking module.
- [ ] **Bills**: Add vendor bill management under Purchases.
- [ ] **Payments Made**: Implement payment tracking for vendor bills.
- [ ] **Vendor Credits**: Add support for purchase returns and vendor credits.
- [ ] **Projects**: (CRM/Service) Implement project management and tracking.
- [ ] **Timesheet**: Add time tracking functionality.
- [ ] **Tasks**: Implement task management within modules.

## 📈 Charts & Data

- [ ] **Account Transactions Graph**: Wire up the "Closing Balance" and "Recent Transactions" data to visual sparklines or bar charts in the `ChartOfAccountsDetailPanel`.
- [ ] **Dashboard Widgets**: Connect dashboard placeholders to real-time aggregations from the backend.

## 🧹 Code Quality & Cleanup

- [ ] **Standardize Search UI**: Ensure all search bars across the app use the new consistent styling found in the Chart of Accounts.
- [ ] **Unify Generic Lists**: Migrate other list views to use `SalesGenericListScreen` where appropriate to reduce code duplication.

## 🧰 Tech Debt / Architecture

- [ ] **Routing Cleanup**: Remove or consolidate legacy `lib/core/router/` vs `lib/core/routing/` (app currently uses `lib/core/routing/`).
- [ ] **Multi-Tenancy Headers**: Add `X-Org-Id` and `X-Outlet-Id` to API requests in `ApiClient`/Dio layer.
- [ ] **Backend Tenant Enforcement**: Re-enable `TenantMiddleware` once auth is wired, and ensure endpoints derive org/outlet from token or headers.
- [ ] **Supabase Migration Docs**: Align root `README.md` migration instructions with `supabase/migrations/README.md` (schema file mismatch).

## 🧩 Collected TODO/FIXME/HACK/XXX (grouped by module)

**Frontend / Sales**

- [ ] `lib/modules/sales/presentation/sections/sales_generic_list_ui.dart:226` Implement Export Current View.
- [ ] `lib/modules/sales/presentation/sections/sales_generic_list_ui.dart:246` Open Preferences.
- [ ] `lib/modules/sales/presentation/sections/sales_generic_list_ui.dart:258` Refresh List.
- [ ] `lib/modules/sales/presentation/sections/sales_generic_list_ui.dart:308` Implement bulk update.
- [ ] `lib/modules/sales/presentation/sections/sales_generic_list_ui.dart:311` Implement mark as active.
- [ ] `lib/modules/sales/presentation/sections/sales_generic_list_ui.dart:314` Implement mark as inactive.
- [ ] `lib/modules/sales/presentation/sections/sales_generic_list_ui.dart:317` Implement merge.
- [ ] `lib/modules/sales/presentation/sections/sales_generic_list_ui.dart:323` Implement associate templates.
- [ ] `lib/modules/sales/presentation/sections/sales_generic_list_ui.dart:374` Implement request GST.
- [ ] `lib/modules/sales/presentation/sections/sales_generic_list_ui.dart:385` Implement delete.
- [ ] `lib/modules/sales/presentation/sections/sales_generic_list_filter.dart:83` Implement custom view creation.
- [ ] `lib/modules/sales/presentation/sections/sales_customer_overview_actions.dart:114` Handle action.
- [ ] `lib/modules/sales/presentation/sections/sales_customer_overview_actions.dart:256` Implement delete.
- [x] `lib/modules/sales/presentation/sections/sales_customer_dialogs.dart` Replace deprecated `groupValue` and `onChanged` with `RadioGroup`. *(fixed via RadioScope migration)*
- [x] `lib/modules/sales/presentation/sections/sales_customer_overview_tab.dart` Replace deprecated `groupValue` and `onChanged` with `RadioGroup`. *(fixed via RadioScope migration)*

**Frontend / Purchases**

- [ ] `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart:70` Implement search with debouncing.
- [ ] `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart:77` Show filter dialog.
- [ ] `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart:116` Fetch vendor name.
- [ ] `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart:136` Navigate to order detail.
- [ ] `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart:142` Navigate to edit order.
- [ ] `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart:148` Delete order.
- [ ] `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart:223` Navigate to create order.
- [ ] `lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart:258` Retry loading.
- [ ] `lib/modules/purchases/vendors/presentation/purchases_vendors_vendor_create.dart:202` Remove unused field `_isAddingBank`.
- [ ] `lib/modules/purchases/vendors/presentation/purchases_vendors_vendor_list.dart:361` Remove unused declaration `_AlignmentContainer`.
- [ ] `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_helpers.dart:71` Remove unused declarations (`addContactRow`, `removeContactRow`).
- [ ] `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_builders.dart:212` Replace deprecated `withOpacity` with `.withValues()`.
- [ ] `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_license_section.dart:386` Replace deprecated `withOpacity` with `.withValues()`.
- [ ] `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_other_details_section.dart:529` Replace deprecated `withOpacity` with `.withValues()`.
- [ ] `lib/modules/purchases/vendors/presentation/sections/purchases_vendors_remarks_section.dart:49` Replace deprecated `withOpacity` with `.withValues()`.

**Frontend / Items**

- [ ] `lib/modules/items/pricelist/models/pricelist_model.dart:18` Add support for multi-currency conversion in calculations.
- [ ] `lib/modules/items/pricelist/models/pricelist_model.dart:19` Implement item-group based pricing rules.
- [ ] `lib/modules/items/pricelist/models/pricelist_model.dart:20` Add tax-inclusive/exclusive calculation flags.
- [ ] Import Items Images (`lib/modules/items/items/presentation/sections/report/sections/items_report_body_actions.dart:35`, `lib/modules/items/items/presentation/sections/items_item_detail_actions.dart:19`).
- [ ] Export Current Item (`lib/modules/items/items/presentation/sections/report/sections/items_report_body_actions.dart:38`, `lib/modules/items/items/presentation/sections/items_item_detail_actions.dart:25`).
- [ ] Open Preferences (`lib/modules/items/items/presentation/sections/report/sections/items_report_body_actions.dart:41`, `lib/modules/items/items/presentation/sections/items_item_detail_actions.dart:28`).
- [ ] Reset Column Width (`lib/modules/items/items/presentation/sections/report/sections/items_report_body_actions.dart:48`, `lib/modules/items/items/presentation/sections/items_item_detail_actions.dart:35`).
- [ ] Get real stock from inventory module (`lib/modules/items/items/presentation/sections/report/items_report_screen.dart:138`, `lib/modules/items/items/presentation/sections/report/items_report_overview.dart:138`).
- [ ] `lib/modules/items/composite_items/presentation/items_composite_items_composite_listview.dart:720` Add compositeItemsDetail route to app_routes.dart.
- [ ] `lib/modules/items/composite_items/presentation/items_composite_items_composite_creation.dart:1693` Remove unused declaration `buildUnderlinedLabel`.
- [ ] `lib/modules/items/composite_items/presentation/items_composite_items_composite_creation.dart:2354` Replace deprecated `groupValue` and `onChanged` with `RadioGroup`.
- [ ] `lib/modules/items/items/presentation/items_item_create.dart:514` Remove unused local variable `name`.
- [ ] `lib/modules/items/items/presentation/sections/items_item_create_inventory.dart:5` Remove unused local variable `controller`.
- [ ] `lib/modules/items/items/presentation/sections/items_item_create_inventory.dart:450` Replace deprecated `groupValue` and `onChanged` with `RadioGroup`.
- [ ] `lib/modules/items/items/presentation/sections/items_item_create_tabs.dart:266` Remove unused local variable `controller`.
- [ ] `lib/modules/items/items/presentation/sections/report/dialogs/bulk_update_dialog.dart:108` Remove unused local variable `categoryIds`.
- [ ] `lib/modules/items/items/presentation/sections/report/items_report_overview.dart:258` Remove dead code (left operand can't be null).

**Frontend / Accountant**

- [ ] `lib/modules/accountant/presentation/accountant_bulk_update_screen.dart:798` Opening Balances (P0) - Priority Implementation.
- [ ] `lib/modules/accountant/presentation/accountant_bulk_update_screen.dart:799` Advanced Reporting - Relocate to Reports module.

**Frontend / Accounts (Manual Journals)**

- [ ] `lib/modules/accounts/manual_journals/presentation/manual_journal_create_screen.dart:123` Implement templates (Choose Template functionality).
- [ ] `lib/modules/accounts/manual_journals/presentation/manual_journal_create_screen.dart:289` Replace deprecated `value` with `initialValue` in DropdownButtonFormField (Fiscal Year).
- [ ] `lib/modules/accounts/manual_journals/presentation/manual_journal_create_screen.dart:313` Replace deprecated `value` with `initialValue` in DropdownButtonFormField (Currency).
- [ ] `lib/modules/accounts/manual_journals/presentation/manual_journal_create_screen.dart:351` Replace deprecated `groupValue` with RadioGroup ancestor for Reporting Method radio buttons.
- [ ] `lib/modules/accounts/manual_journals/presentation/manual_journal_create_screen.dart:353` Replace deprecated `onChanged` with RadioGroup handler for Reporting Method radio buttons.
- [ ] `lib/modules/accounts/recurring_journals/presentation/widgets/recurring_journal_import_export_dialogs.dart:215` Replace deprecated `groupValue` and `onChanged` with `RadioGroup`.
- [x] **Opening Balance Adjustment**: Implement backend logic to automatically create a Journal Entry (Dr: New Account, Cr: Opening Balance Adjustments) when an opening balance is set during account creation/edit.
- [x] **Account Mutation Security**: Implement "Point of No Return" locking. Account Type should be immutable if transactions exist. System accounts (is_system=true) should have Name and Type locked regardless.
- [x] **Hierarchy Safety**: Prevent Tax/GST accounts from being used as Parent Accounts in the dropdown.

**Backend / Currencies**

- [ ] `backend/src/currencies/currencies.controller.ts:2` Fix module resolution error - Cannot find module './currencies.service'. Verify file exists and TypeScript compilation is working.

**Docs / Repowiki**

- [ ] `repowiki/en/content/Backend Development/Database Layer & ORM.md:287` Production auth bypass noted; TODO to enable JWT verification and org/outlet extraction.
- [ ] `repowiki/en/content/Backend Development/Authentication & Security.md:95` Tenant middleware described; TODO to enable JWT verification and org/outlet extraction in production.
- [ ] `repowiki/en/content/Backend Development/Authentication & Security.md:126` Document development bypass and production TODO markers.
- [ ] `repowiki/en/content/Backend Development/Authentication & Security.md:131` Production code TODOs for JWT parsing and role extraction.
- [ ] `repowiki/en/content/Backend Development/Authentication & Security.md:308` Tenant middleware TODOs for JWT verification and role extraction.

## 🔮 Future Enhancements (Post-MVP)

- [ ] **Item Composition API**: Integrate item composition logic with backend API (`lib/modules/items/items/models/item_composition_model.dart:22`).
- [ ] **Filter Favourites Persistence**: Add ability to save and persist favourite filters in report views (`lib/modules/items/items/presentation/sections/report/items_filter_dropdown.dart:31`).
- [ ] **Dynamic Filter Labels**: Extend and localize labels for report filters (`lib/modules/items/items/presentation/sections/report/items_filters.dart:45`).
- [ ] **State Synchronization**: Enhance `GlobalSyncManager` to handle multi-tab synchronization or offline-first conflicts.

## 🛠️ Global Lint & Maintenance

- [ ] `lib/shared/widgets/inputs/category_dropdown.dart:387` Remove unused field `_expandedIds`.
- [ ] `lib/shared/widgets/inputs/category_dropdown.dart:589` Replace deprecated `withOpacity` with `.withValues()`.
- [ ] `lib/shared/widgets/inputs/dropdown_input.dart:97` Remove unused field `_isSearching`.
- [ ] `lib/shared/widgets/inputs/dropdown_input.dart:100` Remove unused field `_keyboardIndex`.
- [ ] `lib/shared/widgets/inputs/dropdown_input.dart:2` Remove unnecessary import of `package:flutter/gestures.dart`.
- [ ] `lib/shared/widgets/inputs/dropdown_input.dart:3` Remove unnecessary import of `package:flutter/services.dart`.
- [x] `lib/core/widgets/forms/zerpai_radio_group.dart` Replace deprecated `groupValue` and `onChanged` with `RadioGroup`. *(fixed — migrated to RadioScope + Flutter RadioGroup)*
- [ ] `lib/shared/widgets/inputs/manage_categories_dialog.dart:405` Replace deprecated `withOpacity` with `.withValues()`.
- [ ] `lib/shared/widgets/inputs/manage_payment_terms_dialog.dart:301` Replace deprecated `withOpacity` with `.withValues()`.
- [ ] `lib/shared/widgets/inputs/manage_reorder_terms_dialog.dart:721` Replace deprecated `withOpacity` with `.withValues()`.
- [x] `lib/shared/widgets/inputs/zerpai_radio_group.dart` Replace deprecated `groupValue` and `onChanged` with `RadioGroup`. *(fixed — migrated to RadioScope + Flutter RadioGroup)*
- [ ] `lib/shared/widgets/reports/zerpai_report_shell.dart:286` Show correct label instead of generic 'This Month'.
