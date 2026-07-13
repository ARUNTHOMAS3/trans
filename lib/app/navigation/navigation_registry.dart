import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/navigation/app_module.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';

class NavigationRegistry {
  NavigationRegistry._();

  static const List<AppModule> modules = [
    AppModule(
      id: 'items',
      label: 'Items',
      icon: LucideIcons.shoppingBag,
      items: [
        AppNavItem(
          label: 'Items',
          listRoute: AppRoutes.itemsReport,
          createRoute: AppRoutes.itemsCreate,
          permissionKey: 'item',
        ),
        AppNavItem(
          label: 'Composite Items',
          listRoute: AppRoutes.compositeItems,
          createRoute: AppRoutes.compositeItemsCreate,
          permissionKey: 'composite_items',
        ),
        AppNavItem(
          label: 'Item Groups',
          listRoute: AppRoutes.itemGroups,
          createRoute: AppRoutes.itemGroupsCreate,
          permissionKey: 'item_groups',
        ),
        AppNavItem(
          label: 'Item Mapping',
          listRoute: AppRoutes.itemMapping,
          createRoute: AppRoutes.itemMappingCreate,
          permissionKey: 'item_mapping',
        ),
      ],
    ),
    AppModule(
      id: 'price_lists',
      label: 'Price Lists',
      icon: LucideIcons.tags,
      items: [
        AppNavItem(
          label: 'Price List',
          listRoute: AppRoutes.priceLists,
          createRoute: AppRoutes.priceListsCreate,
          permissionKey: 'price_list',
        ),
        AppNavItem(
          label: 'Branch Price List',
          listRoute: AppRoutes.branchPriceLists,
          createRoute: AppRoutes.branchPriceListsCreate,
          permissionKey: 'branch_price_lists',
        ),
      ],
    ),
    AppModule(
      id: 'inventory',
      label: 'Inventory',
      icon: LucideIcons.package,
      items: [
        AppNavItem(
          label: 'Assemblies',
          listRoute: AppRoutes.assemblies,
          createRoute: AppRoutes.assembliesCreate,
          permissionKey: 'assemblies',
        ),
        AppNavItem(
          label: 'Inventory Adjustments',
          listRoute: AppRoutes.inventoryAdjustments,
          createRoute: AppRoutes.inventoryAdjustmentsCreate,
          permissionKey: 'inventory_adjustments',
        ),
        AppNavItem(
          label: 'Picklists',
          listRoute: AppRoutes.picklists,
          createRoute: AppRoutes.picklistsCreate,
          permissionKey: 'picklists',
        ),
        AppNavItem(
          label: 'Packages',
          listRoute: AppRoutes.packages,
          createRoute: AppRoutes.packagesCreate,
          permissionKey: 'packages',
        ),
        AppNavItem(
          label: 'Shipments',
          listRoute: AppRoutes.shipments,
          createRoute: AppRoutes.shipmentsCreate,
          permissionKey: 'shipments',
        ),
        AppNavItem(
          label: 'Transfer Orders',
          listRoute: AppRoutes.transferOrders,
          createRoute: AppRoutes.transferOrdersCreate,
          permissionKey: 'transfer_orders',
        ),
        AppNavItem(
          label: 'Move Orders',
          listRoute: AppRoutes.moveOrders,
          createRoute: AppRoutes.moveOrdersCreate,
          permissionKey: 'move_orders',
        ),
      ],
    ),
    AppModule(
      id: 'sales',
      label: 'Sales',
      icon: LucideIcons.shoppingCart,
      items: [
        AppNavItem(
          label: 'Customers',
          listRoute: AppRoutes.salesCustomers,
          createRoute: AppRoutes.salesCustomersCreate,
          permissionKey: 'customers',
        ),
        AppNavItem(
          label: 'Quotations',
          listRoute: AppRoutes.salesQuotations,
          createRoute: AppRoutes.salesQuotationsCreate,
          permissionKey: 'quotations',
        ),
        AppNavItem(
          label: 'Retainer Invoices',
          listRoute: AppRoutes.salesRetainerInvoices,
          createRoute: AppRoutes.salesRetainerInvoicesCreate,
          permissionKey: 'retainer_invoices',
        ),
        AppNavItem(
          label: 'Sales Orders',
          listRoute: AppRoutes.salesOrders,
          createRoute: AppRoutes.salesOrdersCreate,
          permissionKey: 'sales_orders',
        ),
        AppNavItem(
          label: 'Invoices',
          listRoute: AppRoutes.salesInvoices,
          createRoute: AppRoutes.salesInvoicesCreate,
          permissionKey: 'invoices',
        ),
        AppNavItem(
          label: 'Delivery Challans',
          listRoute: AppRoutes.salesDeliveryChallans,
          createRoute: AppRoutes.salesDeliveryChallansCreate,
          permissionKey: 'delivery_challans',
        ),
        AppNavItem(
          label: 'Payments Received',
          listRoute: AppRoutes.salesPaymentsReceived,
          createRoute: AppRoutes.salesPaymentsReceivedCreate,
          permissionKey: 'customer_payments',
        ),
        AppNavItem(
          label: 'Sales Returns',
          listRoute: AppRoutes.salesReturns,
          createRoute: AppRoutes.salesReturnsCreate,
          permissionKey: 'sales_returns',
        ),
        AppNavItem(
          label: 'Credit Notes',
          listRoute: AppRoutes.salesCreditNotes,
          createRoute: AppRoutes.salesCreditNotesCreate,
          permissionKey: 'credit_notes',
        ),
        AppNavItem(
          label: 'e-Way Bills',
          listRoute: AppRoutes.salesEWayBills,
          createRoute: AppRoutes.salesEWayBillsCreate,
          permissionKey: 'ewaybill_perms',
        ),
        AppNavItem(
          label: 'Payment Links',
          listRoute: AppRoutes.salesPaymentLinks,
          createRoute: AppRoutes.salesPaymentLinksCreate,
          permissionKey: 'payment_links',
        ),
        AppNavItem(
          label: 'Recurring Invoices',
          listRoute: AppRoutes.salesRecurringInvoices,
          createRoute: AppRoutes.salesRecurringInvoicesCreate,
          permissionKey: 'recurring_invoices',
        ),
      ],
    ),
    AppModule(
      id: 'procurement',
      label: 'Procurement',
      icon: LucideIcons.clipboardList,
      items: [
        AppNavItem(
          label: 'Purchase Requests',
          listRoute: AppRoutes.procurementPurchaseRequests,
          createRoute: AppRoutes.procurementPurchaseRequestsCreate,
        ),
        AppNavItem(
          label: 'Approvals',
          listRoute: AppRoutes.procurementApprovals,
          createRoute: AppRoutes.procurementApprovals,
          showAdd: false,
        ),
      ],
    ),
    AppModule(
      id: 'purchases',
      label: 'Purchases',
      icon: LucideIcons.truck,
      items: [
        AppNavItem(
          label: 'Vendors',
          listRoute: AppRoutes.vendors,
          createRoute: AppRoutes.vendorsCreate,
          permissionKey: 'vendors',
        ),
        AppNavItem(
          label: 'Expenses',
          listRoute: AppRoutes.expenses,
          createRoute: AppRoutes.expensesCreate,
          permissionKey: 'expenses',
        ),
        AppNavItem(
          label: 'Recurring Expenses',
          listRoute: AppRoutes.recurringExpenses,
          createRoute: AppRoutes.recurringExpensesCreate,
          permissionKey: 'recurring_expenses',
        ),
        AppNavItem(
          label: 'Purchase Orders',
          listRoute: AppRoutes.purchaseOrders,
          createRoute: AppRoutes.purchaseOrdersCreate,
          permissionKey: 'purchase_orders',
        ),
        AppNavItem(
          label: 'Purchase Receives',
          listRoute: AppRoutes.purchaseReceives,
          createRoute: AppRoutes.purchaseReceivesCreate,
          permissionKey: 'purchase_receives',
        ),
        AppNavItem(
          label: 'Purchase Returns',
          listRoute: AppRoutes.purchaseReturns,
          createRoute: AppRoutes.purchaseReturnsCreate,
          permissionKey: 'purchase_returns',
        ),
        AppNavItem(
          label: 'Bills',
          listRoute: AppRoutes.bills,
          createRoute: AppRoutes.billsCreate,
          permissionKey: 'bills',
        ),
        AppNavItem(
          label: 'Recurring Bills',
          listRoute: AppRoutes.recurringBills,
          createRoute: AppRoutes.recurringBillsCreate,
          permissionKey: 'recurring_bills',
        ),
        AppNavItem(
          label: 'Payments Made',
          listRoute: AppRoutes.paymentsMadeReport,
          createRoute: AppRoutes.paymentsMadeCreate,
          permissionKey: 'vendor_payments',
        ),
        AppNavItem(
          label: 'Vendor Credits',
          listRoute: AppRoutes.vendorCredits,
          createRoute: AppRoutes.vendorCreditsCreate,
          permissionKey: 'vendor_credits',
        ),
      ],
    ),
    AppModule(
      id: 'accountant',
      label: 'Accountant',
      icon: LucideIcons.landmark,
      items: [
        AppNavItem(
          label: 'Manual Journals',
          listRoute: AppRoutes.accountantManualJournals,
          createRoute: AppRoutes.accountantManualJournalsCreate,
          permissionKey: 'manual_journals',
        ),
        AppNavItem(
          label: 'Recurring Journals',
          listRoute: AppRoutes.accountantRecurringJournals,
          createRoute: AppRoutes.accountantRecurringJournalsCreate,
          permissionKey: 'recurring_journals',
        ),
        AppNavItem(
          label: 'Bulk Update',
          listRoute: AppRoutes.accountantBulkUpdate,
          createRoute: AppRoutes.accountantBulkUpdate,
          permissionKey: 'bulk_update',
          showAdd: false,
        ),
        AppNavItem(
          label: 'Transaction Locking',
          listRoute: AppRoutes.accountantTransactionLocking,
          createRoute: AppRoutes.accountantTransactionLocking,
          permissionKey: 'transaction_locking',
          showAdd: false,
        ),
        AppNavItem(
          label: 'Opening Balances',
          listRoute: AppRoutes.accountantOpeningBalances,
          createRoute: AppRoutes.accountantOpeningBalancesUpdate,
          permissionKey: 'opening_balances',
        ),
      ],
    ),
    AppModule(
      id: 'accounts',
      label: 'Accounts',
      icon: LucideIcons.wallet,
      items: [
        AppNavItem(
          label: 'Chart of Accounts',
          listRoute: AppRoutes.accountsChartOfAccounts,
          createRoute: AppRoutes.accountsChartOfAccountsCreate,
          permissionKey: 'chart_of_accounts',
          showAdd: false,
        ),
      ],
    ),
  ];
}
