import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/settings/approvals/approval/presentation/pages/approval_create_page.dart';
import 'package:zerpai_erp/modules/settings/approvals/approval/presentation/pages/approval_report_page.dart';
import 'package:zerpai_erp/modules/settings/inventory/shipments/presentation/pages/shipments_settings_page.dart';
import 'package:zerpai_erp/modules/settings/inventory/stock_counts/presentation/pages/stock_counts_settings_page.dart';
import 'package:zerpai_erp/modules/settings/inventory/transfer_orders/presentation/pages/transfer_orders_settings_page.dart';
import 'package:zerpai_erp/modules/settings/items/presentation/pages/items_custom_field_create_page.dart';
import 'package:zerpai_erp/modules/settings/items/presentation/pages/settings_items_page.dart';
import 'package:zerpai_erp/modules/settings/purchase/expenses/presentation/pages/expenses_settings_page.dart';
import 'package:zerpai_erp/modules/settings/purchase/purchase_orders/presentation/pages/purchase_orders_settings_page.dart';
import 'package:zerpai_erp/modules/settings/purchase/purchase_receives/presentation/pages/purchase_receives_settings_page.dart';
import 'package:zerpai_erp/modules/settings/record_locking/lock_configuration/presentation/pages/lock_configuration_create_page.dart';
import 'package:zerpai_erp/modules/settings/record_locking/lock_configuration/presentation/pages/lock_configuration_report_page.dart';
import 'package:zerpai_erp/modules/settings/sales/credit_notes/presentation/pages/credit_notes_settings_page.dart';
import 'package:zerpai_erp/modules/settings/sales/delivery_challans/presentation/pages/delivery_challans_settings_page.dart';
import 'package:zerpai_erp/modules/settings/sales/invoices/presentation/pages/invoices_settings_page.dart';
import 'package:zerpai_erp/modules/settings/sales/retainer_invoices/presentation/pages/retainer_invoices_settings_page.dart';
import 'package:zerpai_erp/modules/settings/sales/sales_orders/presentation/pages/sales_orders_settings_page.dart';

List<GoRoute> buildSettingsHandoffRoutes() => [
  GoRoute(
    path: 'settings/items',
    name: AppRoutes.settingsItems,
    builder: (context, state) => const SettingsItemsPage(),
  ),
  GoRoute(
    path: 'settings/items/fields/new',
    name: AppRoutes.settingsItemsNewField,
    builder: (context, state) => const SettingsItemsCustomFieldCreatePage(),
  ),
  GoRoute(
    path: 'settings/approval',
    name: AppRoutes.settingsApproval,
    builder: (context, state) => const ApprovalReportPage(),
  ),
  GoRoute(
    path: 'settings/approval/create',
    name: AppRoutes.settingsApprovalCreate,
    builder: (context, state) => const ApprovalCreatePage(),
  ),
  GoRoute(
    path: 'settings/lock-configuration',
    name: AppRoutes.settingsLockConfiguration,
    builder: (context, state) => const LockConfigurationReportPage(),
  ),
  GoRoute(
    path: 'settings/lock-configuration/create',
    name: AppRoutes.settingsLockConfigurationCreate,
    builder: (context, state) => const LockConfigurationCreatePage(),
  ),
  GoRoute(
    path: 'settings/preferences/salesorders',
    name: AppRoutes.settingsSalesOrders,
    builder: (context, state) => const SalesOrdersSettingsPage(),
  ),
  GoRoute(
    path: 'settings/preferences/invoices',
    name: AppRoutes.settingsInvoices,
    builder: (context, state) => const InvoicesSettingsPage(),
  ),
  GoRoute(
    path: 'settings/preferences/creditnotes',
    name: AppRoutes.settingsCreditNotes,
    builder: (context, state) => const CreditNotesSettingsPage(),
  ),
  GoRoute(
    path: 'settings/preferences/deliverychallans',
    name: AppRoutes.settingsDeliveryChallans,
    builder: (context, state) => const DeliveryChallansSettingsPage(),
  ),
  GoRoute(
    path: 'settings/preferences/retainerinvoices',
    name: AppRoutes.settingsRetainerInvoices,
    builder: (context, state) => const RetainerInvoicesSettingsPage(),
  ),
  GoRoute(
    path: 'settings/preferences/expenses',
    name: AppRoutes.settingsExpenses,
    builder: (context, state) => const ExpensesSettingsPage(),
  ),
  GoRoute(
    path: 'settings/preferences/purchaseorders',
    name: AppRoutes.settingsPurchaseOrders,
    builder: (context, state) => const PurchaseOrdersSettingsPage(),
  ),
  GoRoute(
    path: 'settings/preferences/purchasereceives',
    name: AppRoutes.settingsPurchaseReceives,
    builder: (context, state) => const PurchaseReceivesSettingsPage(),
  ),
  GoRoute(
    path: 'settings/preferences/shipments',
    name: AppRoutes.settingsShipments,
    builder: (context, state) => const ShipmentsSettingsPage(),
  ),
  GoRoute(
    path: 'settings/preferences/stockcounts',
    name: AppRoutes.settingsStockCounts,
    builder: (context, state) => const StockCountsSettingsPage(),
  ),
  GoRoute(
    path: 'settings/preferences/transferorders',
    name: AppRoutes.settingsTransferOrders,
    builder: (context, state) => const TransferOrdersSettingsPage(),
  ),
];
