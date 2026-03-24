import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Items Module
import 'package:zerpai_erp/modules/items/items/presentation/items_item_create.dart';
import 'package:zerpai_erp/modules/items/items/presentation/items_item_detail.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/report/items_report_overview.dart';
import 'package:zerpai_erp/modules/items/composite_items/presentation/items_composite_items_composite_creation.dart';
import 'package:zerpai_erp/modules/items/composite_items/presentation/items_composite_items_composite_listview.dart';

import 'package:zerpai_erp/modules/sales/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_customer_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_generic_list.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_order_overview.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_order_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_invoice_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_retainer_invoice_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_delivery_challan_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_payment_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_credit_note_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_eway_bill_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_quotation_create.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_document_detail.dart';
import 'package:zerpai_erp/modules/sales/presentation/sales_customer_overview.dart';

import 'package:zerpai_erp/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_creation.dart';
import 'package:zerpai_erp/modules/inventory/assemblies/presentation/inventory_assemblies_assembly_overview.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/manual_journals_overview_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/manual_journal_create_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/manual_journal_template_create_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/presentation/manual_journal_templates_list_screen.dart';
import 'package:zerpai_erp/modules/accountant/recurring_journals/presentation/recurring_journal_create_screen.dart';
import 'package:zerpai_erp/modules/accountant/recurring_journals/presentation/recurring_journal_overview_screen.dart';
import 'package:zerpai_erp/modules/accountant/manual_journals/models/manual_journal_model.dart';
import 'package:zerpai_erp/modules/accountant/recurring_journals/models/recurring_journal_model.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_chart_of_accounts_overview.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_chart_of_accounts_creation.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_bulk_update_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_account_transactions.dart';
import 'package:zerpai_erp/modules/items/pricelist/presentation/items_pricelist_pricelist_overview.dart';
import 'package:zerpai_erp/modules/items/pricelist/presentation/items_pricelist_pricelist_creation.dart';
import 'package:zerpai_erp/modules/items/pricelist/presentation/items_pricelist_pricelist_edit.dart';
import 'package:zerpai_erp/modules/items/pricelist/models/pricelist_model.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_opening_balances_screen.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_opening_balances_update_screen.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_transaction_locking_screen.dart';
import 'package:zerpai_erp/modules/accountant/presentation/accountant_settings_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_audit_logs_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_sales_sales_daily.dart';
import 'package:zerpai_erp/modules/home/presentation/home_dashboard_overview.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_profit_and_loss_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_general_ledger_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_trial_balance_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_sales_by_customer_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_inventory_valuation_screen.dart';
import 'package:zerpai_erp/core/pages/settings_page.dart';
import 'package:zerpai_erp/core/pages/settings_organization_profile_page.dart';
import 'package:zerpai_erp/core/pages/settings_organization_branding_page.dart';
import 'package:zerpai_erp/core/pages/settings_branches_list_page.dart';
import 'package:zerpai_erp/core/pages/settings_branches_create_page.dart';
import 'package:zerpai_erp/core/pages/settings_warehouses_list_page.dart';
import 'package:zerpai_erp/core/pages/settings_warehouses_create_page.dart';

// Purchasing Module
import 'package:zerpai_erp/modules/purchases/vendors/presentation/purchases_vendors_vendor_list.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/purchases_vendors_vendor_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/presentation/purchases_purchase_receives_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/presentation/purchases_purchase_receives_list.dart';
import 'package:zerpai_erp/modules/purchases/bills/presentation/purchases_bills_list.dart';
import 'package:zerpai_erp/modules/purchases/bills/presentation/purchases_bills_create.dart';

// Shared
import 'package:zerpai_erp/shared/widgets/placeholder_screen.dart';
import 'package:zerpai_erp/core/layout/zerpai_shell.dart';
import 'package:zerpai_erp/core/pages/error_page.dart';
import 'package:zerpai_erp/core/pages/maintenance_page.dart';
import 'package:zerpai_erp/core/pages/not_found_page.dart';
import 'package:zerpai_erp/core/pages/unauthorized_page.dart';
import 'app_routes.dart';
export 'app_routes.dart';

// TODO(auth): Replace with real org system_id from auth/bootstrap once enabled
const String _kDevOrgSystemId = '0000000000';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/$_kDevOrgSystemId/home',
  debugLogDiagnostics: false,
  redirect: (context, state) {
    final path = state.uri.path;
    const skipPrefixes = ['/not-found', '/unauthorized', '/error', '/maintenance'];
    if (skipPrefixes.any((p) => path == p || path.startsWith('$p/'))) return null;
    if (RegExp(r'^/\d{10,20}(/|$)').hasMatch(path)) return null;
    final query = state.uri.query.isNotEmpty ? '?${state.uri.query}' : '';
    return '/$_kDevOrgSystemId${path == '/' ? '/home' : path}$query';
  },
  errorBuilder: (context, state) =>
      ZerpaiShell(child: ErrorPage(errorMessage: state.error?.toString())),
  routes: [
    // Full-screen error routes (outside shell — no sidebar, no org prefix)
    GoRoute(
      path: '/not-found',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return NotFoundPage(
          requestedRoute: extra?['requestedRoute'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/unauthorized',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return UnauthorizedPage(
          requiredPermission: extra?['requiredPermission'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/maintenance',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return MaintenancePage(
          message: extra?['message'] as String?,
          estimatedCompletion: extra?['estimatedCompletion'] as DateTime?,
        );
      },
    ),
    GoRoute(
      path: '/error',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ErrorPage(
          errorMessage: extra?['errorMessage'] as String?,
          errorCode: extra?['errorCode'] as String?,
          error: extra?['error'],
          stackTrace: extra?['stackTrace'] as StackTrace?,
        );
      },
    ),

    // All app routes under /:orgSystemId
    GoRoute(
      path: '/:orgSystemId',
      redirect: (context, state) {
        // Redirect bare /:orgSystemId (no sub-path) to home
        final orgId = state.pathParameters['orgSystemId']!;
        if (state.uri.path == '/$orgId') return '/$orgId/home';
        return null;
      },
      routes: [
        ShellRoute(
          builder: (context, state, child) => ZerpaiShell(child: child),
          routes: [
            // Home
            GoRoute(
              path: 'home',
              builder: (context, state) => const HomeDashboardScreen(),
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) => const SettingsPage(),
            ),
            GoRoute(
              path: 'settings/orgprofile',
              builder: (context, state) => const SettingsOrganizationProfilePage(),
            ),
            GoRoute(
              path: 'settings/orgbranding',
              builder: (context, state) =>
                  const SettingsOrganizationBrandingPage(),
            ),
            GoRoute(
              path: 'settings/branches',
              builder: (context, state) => const SettingsBranchesListPage(),
            ),
            GoRoute(
              path: 'settings/branches/create',
              builder: (context, state) => const SettingsBranchCreatePage(),
            ),
            GoRoute(
              path: 'settings/branches/:id/edit',
              builder: (context, state) => SettingsBranchCreatePage(
                branchId: state.pathParameters['id'],
              ),
            ),
            GoRoute(
              path: 'settings/warehouses',
              builder: (context, state) => const SettingsWarehousesListPage(),
            ),
            GoRoute(
              path: 'settings/warehouses/create',
              builder: (context, state) => const SettingsWarehouseCreatePage(),
            ),
            GoRoute(
              path: 'settings/warehouses/:id/edit',
              builder: (context, state) => SettingsWarehouseCreatePage(
                warehouseId: state.pathParameters['id'],
              ),
            ),

            // Items
            GoRoute(
              path: 'items/report',
              name: AppRoutes.itemsReport,
              builder: (context, state) => ItemsReportScreen(
                initialFilter: state.uri.queryParameters['filter'],
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),
            GoRoute(
              path: 'items/create',
              name: AppRoutes.itemsCreate,
              builder: (context, state) {
                final extra = state.extra;
                if (extra is Item) {
                  return ItemCreateScreen(
                    item: extra,
                    initialTab: state.uri.queryParameters['tab'],
                  );
                }
                if (extra is Map && extra['cloneItem'] is Item) {
                  return ItemCreateScreen(
                    item: extra['cloneItem'] as Item,
                    isClone: true,
                    initialTab: state.uri.queryParameters['tab'],
                  );
                }
                return ItemCreateScreen(
                  initialTab: state.uri.queryParameters['tab'],
                );
              },
            ),
            GoRoute(
              path: 'items/edit/:id',
              name: AppRoutes.itemsEdit,
              builder: (context, state) {
                final id = state.pathParameters['id'];
                final extra = state.extra;
                if (extra is Item) {
                  return ItemCreateScreen(
                    itemId: id,
                    item: extra,
                    initialTab: state.uri.queryParameters['tab'],
                  );
                }
                return ItemCreateScreen(
                  itemId: id,
                  initialTab: state.uri.queryParameters['tab'],
                );
              },
            ),
            GoRoute(
              path: 'items/detail/:id',
              name: AppRoutes.itemsDetail,
              builder: (context, state) {
                final id = state.pathParameters['id'];
                return ItemDetailScreen(
                  itemId: id,
                  initialQueryParameters: state.uri.queryParameters,
                );
              },
              routes: [
                GoRoute(
                  path: 'opening-stock',
                  name: AppRoutes.itemsOpeningStock,
                  builder: (context, state) => ItemsOpeningStockScreen(
                    itemId: state.pathParameters['id']!,
                    initialQueryParameters: state.uri.queryParameters,
                  ),
                ),
              ],
            ),
            // compositeItemsCreate must come BEFORE compositeItems to avoid ':id' matching 'create'
            GoRoute(
              path: 'items/composite-items/create',
              builder: (context, state) => const CompositeCreateScreen(),
            ),
            GoRoute(
              path: 'items/composite-items',
              builder: (context, state) => CompositeItemsListScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => CompositeItemsListScreen(
                    initialItemId: state.pathParameters['id'],
                    initialSearchQuery: state.uri.queryParameters['q'],
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/customers',
              builder: (context, state) => SalesGenericListScreen(
                title: 'Customers',
                createRoute: AppRoutes.salesCustomersCreate,
                detailRoute: AppRoutes.salesCustomersDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesCustomersProvider,
                columns: [
                  'name',
                  'company_name',
                  'email',
                  'phone',
                  'gst_treatment',
                  'receivables_bcy',
                ],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const SalesCustomerCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) =>
                      SalesCustomerOverviewScreen(id: state.pathParameters['id']!),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/quotations',
              builder: (context, state) => SalesGenericListScreen(
                title: 'Quotations',
                createRoute: AppRoutes.salesQuotationsCreate,
                detailRoute: AppRoutes.salesQuotationsDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesQuotesProvider,
                columns: [
                  'quotation_number',
                  'customer',
                  'date',
                  'amount',
                  'status',
                ],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const SalesQuoteCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'quotation',
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/retainer-invoices',
              builder: (context, state) => SalesGenericListScreen(
                title: 'Retainer Invoices',
                createRoute: AppRoutes.salesRetainerInvoicesCreate,
                detailRoute: AppRoutes.salesRetainerInvoicesDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesRetainerInvoicesProvider,
                columns: ['invoice_number', 'customer', 'date', 'amount', 'status'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) =>
                      const SalesRetainerInvoiceCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'retainer_invoice',
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/orders',
              builder: (context, state) => SalesOrderOverviewScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const SalesOrderCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'sales_order',
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/invoices',
              builder: (context, state) => SalesGenericListScreen(
                title: 'Invoices',
                createRoute: AppRoutes.salesInvoicesCreate,
                detailRoute: AppRoutes.salesInvoicesDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesInvoicesProvider,
                columns: [
                  'invoice_number',
                  'customer',
                  'date',
                  'amount',
                  'balance',
                  'status',
                ],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const SalesInvoiceCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'invoice',
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/delivery-challans',
              builder: (context, state) => SalesGenericListScreen(
                title: 'Delivery Challans',
                createRoute: AppRoutes.salesDeliveryChallansCreate,
                detailRoute: AppRoutes.salesDeliveryChallansDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesChallansProvider,
                columns: const ['challan_number', 'customer', 'date', 'status'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const SalesChallanCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'delivery_challan',
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/payments-received',
              builder: (context, state) => SalesGenericListScreen(
                title: 'Payments Received',
                createRoute: AppRoutes.salesPaymentsReceivedCreate,
                detailRoute: AppRoutes.salesPaymentsReceivedDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesPaymentsProvider,
                columns: const [
                  'payment_number',
                  'customer',
                  'date',
                  'amount',
                  'mode',
                ],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const SalesPaymentCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'payment_received',
                  ),
                ),
              ],
            ),

            // Sales - Returns
            GoRoute(
              path: 'sales/returns',
              builder: (context, state) => SalesGenericListScreen(
                title: 'Sales Returns',
                createRoute: AppRoutes.salesReturns,
                detailRoute: AppRoutes.salesReturnsDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                columns: const [
                  'return_number',
                  'customer',
                  'date',
                  'amount',
                  'status',
                ],
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'sales_return',
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/credit-notes',
              builder: (context, state) => SalesGenericListScreen(
                title: 'Credit Notes',
                createRoute: AppRoutes.salesCreditNotesCreate,
                detailRoute: AppRoutes.salesCreditNotesDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesCreditNotesProvider,
                columns: const [
                  'credit_note_number',
                  'customer',
                  'date',
                  'amount',
                  'status',
                ],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const SalesCreditNoteCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'credit_note',
                  ),
                ),
              ],
            ),

            GoRoute(
              path: 'sales/e-way-bills',
              builder: (context, state) => SalesGenericListScreen(
                title: 'e-Way Bills',
                createRoute: AppRoutes.salesEWayBillsCreate,
                detailRoute: AppRoutes.salesEWayBillsDetail,
                initialSearchQuery: state.uri.queryParameters['q'],
                provider: salesEWayBillsProvider,
                columns: const ['bill_number', 'customer', 'date', 'status'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const SalesEWayBillCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => SalesDocumentDetailScreen(
                    id: state.pathParameters['id']!,
                    documentType: 'eway_bill',
                  ),
                ),
              ],
            ),

            // Assemblies
            GoRoute(
              path: 'inventory/assemblies',
              builder: (context, state) => const AssemblyListScreen(),
            ),
            GoRoute(
              path: 'inventory/assemblies/create',
              builder: (context, state) => const AssemblyCreateScreen(),
            ),

            // Price Lists
            GoRoute(
              path: 'items/price-lists',
              builder: (context, state) => PriceListOverviewScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),
            GoRoute(
              path: 'items/price-lists/create',
              builder: (context, state) {
                final extra = state.extra;
                if (extra is PriceList) {
                  return PriceListCreateScreen(template: extra);
                }
                return const PriceListCreateScreen();
              },
            ),
            GoRoute(
              path: 'items/price-lists/edit/:id',
              builder: (context, state) {
                final id = state.pathParameters['id'];
                final extra = state.extra as PriceList?;
                return PriceListEditScreen(priceList: extra, priceListId: id);
              },
            ),

            // Placeholders (Inventory)
            GoRoute(
              path: 'inventory/adjustments',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Inventory Adjustments'),
            ),
            GoRoute(
              path: 'inventory/adjustments/create',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Adjustment'),
            ),
            GoRoute(
              path: 'inventory/picklists',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Picklists'),
            ),
            GoRoute(
              path: 'inventory/picklists/create',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Picklist'),
            ),
            GoRoute(
              path: 'inventory/packages',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Packages'),
            ),
            GoRoute(
              path: 'inventory/packages/create',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Package'),
            ),
            GoRoute(
              path: 'inventory/shipments',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Shipments'),
            ),
            GoRoute(
              path: 'inventory/shipments/create',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Shipment'),
            ),
            GoRoute(
              path: 'inventory/transfer-orders',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Transfer Orders'),
            ),
            GoRoute(
              path: 'inventory/transfer-orders/create',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Transfer Order'),
            ),

            // Missing Module Placeholders
            GoRoute(
              path: 'items/item-groups',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Item Groups'),
            ),
            GoRoute(
              path: 'items/item-groups/create',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Item Group'),
            ),
            GoRoute(
              path: 'items/mapping',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Item Mapping'),
            ),
            GoRoute(
              path: 'items/mapping/create',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'New Item Mapping'),
            ),

            // Purchases Module
            GoRoute(
              path: 'purchases',
              redirect: (context, state) => AppRoutes.purchasesVendors,
            ),
            GoRoute(
              path: 'purchases/vendors',
              builder: (context, state) => PurchasesVendorsVendorListScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),
            GoRoute(
              path: 'purchases/vendors/create',
              builder: (context, state) =>
                  const PurchasesVendorsVendorCreateScreen(),
            ),
            GoRoute(
              path: 'purchases/purchase-orders',
              builder: (context, state) => PurchaseOrderOverviewScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),
            GoRoute(
              path: 'purchases/purchase-receives',
              builder: (context, state) =>
                  const PurchasesPurchaseReceivesListScreen(),
            ),
            GoRoute(
              path: 'purchases/expenses',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Expenses'),
            ),
            GoRoute(
              path: 'purchases/bills',
              builder: (context, state) => const PurchasesBillsListScreen(),
            ),
            GoRoute(
              path: 'purchases/bills/create',
              builder: (context, state) => const PurchasesBillCreateScreen(),
            ),
            GoRoute(
              path: 'purchases/payments-made',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Payments Made'),
            ),
            GoRoute(
              path: 'purchases/vendor-credits',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Vendor Credits'),
            ),
            GoRoute(
              path: 'purchases/purchase-orders/create',
              builder: (context, state) => const PurchaseOrderCreateScreen(),
            ),
            GoRoute(
              path: 'purchases/purchase-receives/create',
              builder: (context, state) =>
                  const PurchasesPurchaseReceivesCreateScreen(),
            ),
            GoRoute(
              path: 'documents',
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Documents'),
            ),
            GoRoute(
              path: 'audit-logs',
              builder: (context, state) => AuditLogsScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),

            // Reports
            GoRoute(
              path: 'reports',
              builder: (context, state) => ReportsCenterScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
            ),
            GoRoute(
              path: 'reports/daily-sales',
              builder: (context, state) => const ReportDailySalesScreen(),
            ),

            GoRoute(
              path: 'accountant/manual-journals',
              builder: (context, state) => ManualJournalOverviewScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) {
                    final extra = state.extra;
                    ManualJournal? initialJournal;
                    ManualJournalTemplate? template;
                    bool showTemplates = false;

                    if (extra is ManualJournal) {
                      initialJournal = extra;
                    } else if (extra is ManualJournalTemplate) {
                      template = extra;
                    } else if (extra is Map<String, dynamic>) {
                      initialJournal = extra['initialJournal'] as ManualJournal?;
                      template = extra['template'] as ManualJournalTemplate?;
                      showTemplates = extra['showTemplates'] as bool? ?? false;
                    }

                    return ManualJournalCreateScreen(
                      initialJournal: initialJournal,
                      template: template,
                      showTemplates: showTemplates,
                    );
                  },
                ),
                GoRoute(
                  path: 'templates',
                  builder: (context, state) =>
                      const ManualJournalTemplatesListScreen(),
                ),
                GoRoute(
                  path: 'journal-template-creation',
                  builder: (context, state) => const JournalTemplateCreateScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => ManualJournalOverviewScreen(
                    initialJournalId: state.pathParameters['id'],
                    initialSearchQuery: state.uri.queryParameters['q'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'accounts/chart-of-accounts',
              builder: (context, state) => ChartOfAccountsPage(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const ChartOfAccountsCreationPage(),
                    opaque: false,
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                  ),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => ChartOfAccountsPage(
                    initialAccountId: state.pathParameters['id'],
                    initialSearchQuery: state.uri.queryParameters['q'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'accountant/recurring-journals',
              builder: (context, state) => RecurringJournalOverviewScreen(
                initialSearchQuery: state.uri.queryParameters['q'],
              ),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) {
                    final extra = state.extra;
                    if (extra is RecurringJournal) {
                      return RecurringJournalCreateScreen(initialJournal: extra);
                    }
                    if (extra is ManualJournal) {
                      return RecurringJournalCreateScreen(
                        initialManualJournal: extra,
                      );
                    }
                    if (extra is Map<String, dynamic>) {
                      return RecurringJournalCreateScreen(
                        initialJournal:
                            extra['initialJournal'] as RecurringJournal?,
                        initialManualJournal:
                            extra['initialManualJournal'] as ManualJournal?,
                      );
                    }
                    return const RecurringJournalCreateScreen();
                  },
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => RecurringJournalOverviewScreen(
                    initialJournalId: state.pathParameters['id'],
                    initialSearchQuery: state.uri.queryParameters['q'],
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'accountant/bulk-update',
              builder: (context, state) => const AccountantBulkUpdateScreen(),
            ),
            GoRoute(
              path: 'accountant/transaction-locking',
              builder: (context, state) =>
                  const AccountantTransactionLockingScreen(),
            ),

            GoRoute(
              path: 'accountant/opening-balances',
              builder: (context, state) => const OpeningBalancesScreen(),
            ),
            GoRoute(
              path: 'accountant/opening-balances/update',
              builder: (context, state) => const OpeningBalancesUpdateScreen(),
            ),
            GoRoute(
              path: 'accountant/settings',
              builder: (context, state) => const AccountantSettingsScreen(),
            ),
            GoRoute(
              path: 'accountant/transactions-report',
              name: AppRoutes.accountantTransactionsReport,
              builder: (context, state) {
                final String accountId =
                    state.uri.queryParameters['accountId'] ?? '';
                final String accountName =
                    state.uri.queryParameters['accountName'] ?? '';
                return AccountTransactionsReportPage(
                  accountId: accountId.isNotEmpty ? accountId : null,
                  accountName: accountName.isNotEmpty ? accountName : null,
                );
              },
            ),
            GoRoute(
              path: 'reports/profit-and-loss',
              name: AppRoutes.profitAndLoss,
              builder: (context, state) => const ProfitAndLossScreen(),
            ),
            GoRoute(
              path: 'reports/general-ledger',
              name: AppRoutes.generalLedger,
              builder: (context, state) => const GeneralLedgerScreen(),
            ),
            GoRoute(
              path: 'reports/trial-balance',
              name: AppRoutes.trialBalance,
              builder: (context, state) => const TrialBalanceScreen(),
            ),
            GoRoute(
              path: 'reports/sales-by-customer',
              name: AppRoutes.salesByCustomer,
              builder: (context, state) => const SalesByCustomerScreen(),
            ),
            GoRoute(
              path: 'reports/inventory-valuation',
              name: AppRoutes.inventoryValuation,
              builder: (context, state) => const InventoryValuationScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
