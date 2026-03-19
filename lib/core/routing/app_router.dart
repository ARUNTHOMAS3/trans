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

// Purchasing Module
import 'package:zerpai_erp/modules/purchases/vendors/presentation/purchases_vendors_vendor_list.dart';
import 'package:zerpai_erp/modules/purchases/vendors/presentation/purchases_vendors_vendor_create.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart';

// Shared
import 'package:zerpai_erp/shared/widgets/placeholder_screen.dart';
import 'package:zerpai_erp/core/layout/zerpai_shell.dart';
import 'package:zerpai_erp/core/pages/error_page.dart';
import 'package:zerpai_erp/core/pages/maintenance_page.dart';
import 'package:zerpai_erp/core/pages/not_found_page.dart';
import 'package:zerpai_erp/core/pages/unauthorized_page.dart';
import 'app_routes.dart';
export 'app_routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  errorBuilder: (context, state) =>
      ZerpaiShell(child: ErrorPage(errorMessage: state.error?.toString())),
  routes: [
    // Full-screen error routes (outside shell — no sidebar)
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
    ShellRoute(
      builder: (context, state, child) => ZerpaiShell(child: child),
      routes: [
        // Home
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeDashboardScreen(),
        ),

        // Items
        GoRoute(
          path: AppRoutes.itemsReport,
          name: AppRoutes.itemsReport,
          builder: (context, state) => ItemsReportScreen(
            initialFilter: state.uri.queryParameters['filter'],
          ),
        ),
        GoRoute(
          path: AppRoutes.itemsCreate,
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
          path: AppRoutes.itemsEdit,
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
          path: AppRoutes.itemsDetail,
          name: AppRoutes.itemsDetail,
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return ItemDetailScreen(
              itemId: id,
              initialQueryParameters: state.uri.queryParameters,
            );
          },
        ),
        GoRoute(
          path: AppRoutes.itemsOpeningStock,
          name: AppRoutes.itemsOpeningStock,
          builder: (context, state) => ItemsOpeningStockScreen(
            itemId: state.pathParameters['id']!,
            initialQueryParameters: state.uri.queryParameters,
          ),
        ),
        GoRoute(
          path: AppRoutes.compositeItems,
          builder: (context, state) => const CompositeItemsListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => CompositeItemsListScreen(
                initialItemId: state.pathParameters['id'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.compositeItemsCreate,
          builder: (context, state) => const CompositeCreateScreen(),
        ),

        GoRoute(
          path: AppRoutes.salesCustomers,
          builder: (context, state) => SalesGenericListScreen(
            title: 'Customers',
            createRoute: AppRoutes.salesCustomersCreate,
            detailRoute: AppRoutes.salesCustomersDetail,
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
          path: AppRoutes.salesQuotations,
          builder: (context, state) => SalesGenericListScreen(
            title: 'Quotations',
            createRoute: AppRoutes.salesQuotationsCreate,
            detailRoute: AppRoutes.salesQuotationsDetail,
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
          path: AppRoutes.salesRetainerInvoices,
          builder: (context, state) => SalesGenericListScreen(
            title: 'Retainer Invoices',
            createRoute: AppRoutes.salesRetainerInvoicesCreate,
            detailRoute: AppRoutes.salesRetainerInvoicesDetail,
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
          path: AppRoutes.salesOrders,
          builder: (context, state) => const SalesOrderOverviewScreen(),
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
          path: AppRoutes.salesInvoices,
          builder: (context, state) => SalesGenericListScreen(
            title: 'Invoices',
            createRoute: AppRoutes.salesInvoicesCreate,
            detailRoute: AppRoutes.salesInvoicesDetail,
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
          path: AppRoutes.salesDeliveryChallans,
          builder: (context, state) => SalesGenericListScreen(
            title: 'Delivery Challans',
            createRoute: AppRoutes.salesDeliveryChallansCreate,
            detailRoute: AppRoutes.salesDeliveryChallansDetail,
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
          path: AppRoutes.salesPaymentsReceived,
          builder: (context, state) => SalesGenericListScreen(
            title: 'Payments Received',
            createRoute: AppRoutes.salesPaymentsReceivedCreate,
            detailRoute: AppRoutes.salesPaymentsReceivedDetail,
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
          path: AppRoutes.salesReturns,
          builder: (context, state) => SalesGenericListScreen(
            title: 'Sales Returns',
            createRoute: AppRoutes.salesReturns,
            detailRoute: AppRoutes.salesReturnsDetail,
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
          path: AppRoutes.salesCreditNotes,
          builder: (context, state) => SalesGenericListScreen(
            title: 'Credit Notes',
            createRoute: AppRoutes.salesCreditNotesCreate,
            detailRoute: AppRoutes.salesCreditNotesDetail,
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
          path: AppRoutes.salesEWayBills,
          builder: (context, state) => SalesGenericListScreen(
            title: 'e-Way Bills',
            createRoute: AppRoutes.salesEWayBillsCreate,
            detailRoute: AppRoutes.salesEWayBillsDetail,
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
          path: AppRoutes.assemblies,
          builder: (context, state) => const AssemblyListScreen(),
        ),
        GoRoute(
          path: AppRoutes.assembliesCreate,
          builder: (context, state) => const AssemblyCreateScreen(),
        ),

        // Price Lists
        GoRoute(
          path: AppRoutes.priceLists,
          builder: (context, state) => const PriceListOverviewScreen(),
        ),
        GoRoute(
          path: AppRoutes.priceListsCreate,
          builder: (context, state) {
            final extra = state.extra;
            if (extra is PriceList) {
              return PriceListCreateScreen(template: extra);
            }
            return const PriceListCreateScreen();
          },
        ),
        GoRoute(
          path: AppRoutes.priceListsEdit,
          builder: (context, state) {
            final id = state.pathParameters['id'];
            final extra = state.extra as PriceList?;
            return PriceListEditScreen(priceList: extra, priceListId: id);
          },
        ),

        // Placeholders (Inventory)
        GoRoute(
          path: AppRoutes.inventoryAdjustments,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Inventory Adjustments'),
        ),
        GoRoute(
          path: AppRoutes.inventoryAdjustmentsCreate,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'New Adjustment'),
        ),
        GoRoute(
          path: AppRoutes.picklists,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Picklists'),
        ),
        GoRoute(
          path: AppRoutes.picklistsCreate,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'New Picklist'),
        ),
        GoRoute(
          path: AppRoutes.packages,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Packages'),
        ),
        GoRoute(
          path: AppRoutes.packagesCreate,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'New Package'),
        ),
        GoRoute(
          path: AppRoutes.shipments,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Shipments'),
        ),
        GoRoute(
          path: AppRoutes.shipmentsCreate,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'New Shipment'),
        ),
        GoRoute(
          path: AppRoutes.transferOrders,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Transfer Orders'),
        ),
        GoRoute(
          path: AppRoutes.transferOrdersCreate,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'New Transfer Order'),
        ),

        // Missing Module Placeholders
        GoRoute(
          path: AppRoutes.itemGroups,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Item Groups'),
        ),
        GoRoute(
          path: AppRoutes.itemGroupsCreate,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'New Item Group'),
        ),
        GoRoute(
          path: AppRoutes.itemMapping,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Item Mapping'),
        ),
        GoRoute(
          path: AppRoutes.itemMappingCreate,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'New Item Mapping'),
        ),
        // Purchases Module
        GoRoute(
          path: AppRoutes.purchases,
          redirect: (context, state) => AppRoutes.purchasesVendors,
        ),
        GoRoute(
          path: AppRoutes.purchasesVendors,
          builder: (context, state) => const PurchasesVendorsVendorListScreen(),
        ),
        GoRoute(
          path: AppRoutes.purchasesVendorsCreate,
          builder: (context, state) =>
              const PurchasesVendorsVendorCreateScreen(),
        ),
        GoRoute(
          path: AppRoutes.purchasesPurchaseOrders,
          builder: (context, state) => const PurchaseOrderOverviewScreen(),
        ),
        GoRoute(
          path: AppRoutes.expenses,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Expenses'),
        ),
        GoRoute(
          path: AppRoutes.bills,
          builder: (context, state) => const PlaceholderScreen(title: 'Bills'),
        ),
        GoRoute(
          path: AppRoutes.paymentsMade,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Payments Made'),
        ),
        GoRoute(
          path: AppRoutes.vendorCredits,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Vendor Credits'),
        ),
        GoRoute(
          path: AppRoutes.purchasesPurchaseOrdersCreate,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'New Purchase Order'),
        ),
        GoRoute(
          path: AppRoutes.documents,
          builder: (context, state) =>
              const PlaceholderScreen(title: 'Documents'),
        ),
        GoRoute(
          path: AppRoutes.auditLogs,
          builder: (context, state) => const AuditLogsScreen(),
        ),

        // Reports
        GoRoute(
          path: AppRoutes.reports,
          builder: (context, state) => const ReportsCenterScreen(),
        ),
        GoRoute(
          path: AppRoutes.reportDailySales,
          builder: (context, state) => const ReportDailySalesScreen(),
        ),

        GoRoute(
          path: AppRoutes.accountantManualJournals,
          builder: (context, state) => const ManualJournalOverviewScreen(),
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
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.accountsChartOfAccounts,
          builder: (context, state) => const ChartOfAccountsPage(),
          routes: [
            GoRoute(
              path: 'create', // Use relative path for child
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
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.accountantRecurringJournals,
          builder: (context, state) => const RecurringJournalOverviewScreen(),
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
              ),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.accountantBulkUpdate,
          builder: (context, state) => const AccountantBulkUpdateScreen(),
        ),
        GoRoute(
          path: AppRoutes.accountantTransactionLocking,
          builder: (context, state) =>
              const AccountantTransactionLockingScreen(),
        ),

        GoRoute(
          path: AppRoutes.accountantOpeningBalances,
          builder: (context, state) => const OpeningBalancesScreen(),
        ),
        GoRoute(
          path: AppRoutes.accountantOpeningBalancesUpdate,
          builder: (context, state) => const OpeningBalancesUpdateScreen(),
        ),
        GoRoute(
          path: AppRoutes.accountantSettings,
          builder: (context, state) => const AccountantSettingsScreen(),
        ),
        GoRoute(
          path: AppRoutes.accountantTransactionsReport,
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
          path: AppRoutes.profitAndLoss,
          name: AppRoutes.profitAndLoss,
          builder: (context, state) => const ProfitAndLossScreen(),
        ),
        GoRoute(
          path: AppRoutes.generalLedger,
          name: AppRoutes.generalLedger,
          builder: (context, state) => const GeneralLedgerScreen(),
        ),
        GoRoute(
          path: AppRoutes.trialBalance,
          name: AppRoutes.trialBalance,
          builder: (context, state) => const TrialBalanceScreen(),
        ),
        GoRoute(
          path: AppRoutes.salesByCustomer,
          name: AppRoutes.salesByCustomer,
          builder: (context, state) => const SalesByCustomerScreen(),
        ),
        GoRoute(
          path: AppRoutes.inventoryValuation,
          name: AppRoutes.inventoryValuation,
          builder: (context, state) => const InventoryValuationScreen(),
        ),
      ],
    ),
  ],
);
