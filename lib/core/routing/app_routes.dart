class AppRoutes {
  AppRoutes._();

  static const String home = '/';

  // Items
  static const String itemsReport = '/items/report';
  static const String itemsCreate = '/items/create';
  static const String itemsDetail = '/items/detail/:id';
  static const String itemsEdit = '/items/edit/:id';

  // Composite Items
  static const String compositeItems = '/items/composite-items';
  static const String compositeItemsCreate = '/items/composite-items/create';
  static const String compositeItemsDetail = '/items/composite-items/:id';

  // Sales
  static const String salesCustomers = '/sales/customers';
  static const String salesCustomersDetail = '/sales/customers/:id';
  static const String salesCustomersCreate = '/sales/customers/create';
  static const String salesQuotations = '/sales/quotations';
  static const String salesQuotationsDetail = '/sales/quotations/:id';
  static const String salesQuotationsCreate = '/sales/quotations/create';
  static const String salesRetainerInvoices = '/sales/retainer-invoices';
  static const String salesRetainerInvoicesDetail =
      '/sales/retainer-invoices/:id';
  static const String salesRetainerInvoicesCreate =
      '/sales/retainer-invoices/create';
  static const String salesOrders = '/sales/orders';
  static const String salesOrdersDetail = '/sales/orders/:id';
  static const String salesOrdersCreate = '/sales/orders/create';
  static const String salesInvoices = '/sales/invoices';
  static const String salesInvoicesDetail = '/sales/invoices/:id';
  static const String salesInvoicesCreate = '/sales/invoices/create';
  static const String salesDeliveryChallans = '/sales/delivery-challans';
  static const String salesDeliveryChallansDetail =
      '/sales/delivery-challans/:id';
  static const String salesDeliveryChallansCreate =
      '/sales/delivery-challans/create';
  static const String salesPaymentsReceived = '/sales/payments-received';
  static const String salesPaymentsReceivedDetail =
      '/sales/payments-received/:id';
  static const String salesPaymentsReceivedCreate =
      '/sales/payments-received/create';
  static const String salesReturns = '/sales/returns';
  static const String salesReturnsDetail = '/sales/returns/:id';
  static const String salesCreditNotes = '/sales/credit-notes';
  static const String salesCreditNotesDetail = '/sales/credit-notes/:id';
  static const String salesCreditNotesCreate = '/sales/credit-notes/create';
  static const String salesEWayBills = '/sales/e-way-bills';
  static const String salesEWayBillsDetail = '/sales/e-way-bills/:id';
  static const String salesEWayBillsCreate = '/sales/e-way-bills/create';

  // Inventory / Assemblies
  static const String assemblies = '/inventory/assemblies';
  static const String assembliesCreate = '/inventory/assemblies/create';

  // Price Lists
  static const String priceLists = '/items/price-lists';
  static const String priceListsCreate = '/items/price-lists/create';
  static const String priceListsEdit = '/items/price-lists/edit/:id';

  // Inventory placeholders
  static const String inventoryAdjustments = '/inventory/adjustments';
  static const String inventoryAdjustmentsCreate =
      '/inventory/adjustments/create';
  static const String picklists = '/inventory/picklists';
  static const String picklistsCreate = '/inventory/picklists/create';
  static const String packages = '/inventory/packages';
  static const String packagesCreate = '/inventory/packages/create';
  static const String shipments = '/inventory/shipments';
  static const String shipmentsCreate = '/inventory/shipments/create';
  static const String transferOrders = '/inventory/transfer-orders';
  static const String transferOrdersCreate =
      '/inventory/transfer-orders/create';

  // Items utility routes
  static const String itemGroups = '/items/item-groups';
  static const String itemGroupsCreate = '/items/item-groups/create';
  static const String itemMapping = '/items/mapping';
  static const String itemMappingCreate = '/items/mapping/create';

  // Other top-level modules
  static const String purchases = '/purchases';
  static const String documents = '/documents';
  static const String auditLogs = '/audit-logs';

  // Purchases - Vendors
  static const String vendors = '/purchases/vendors';
  static const String vendorsCreate = '/purchases/vendors/create';
  static const String purchasesVendors = '/purchases/vendors'; // Legacy
  static const String purchasesVendorsCreate =
      '/purchases/vendors/create'; // Legacy

  // Purchases - Expenses
  static const String expenses = '/purchases/expenses';
  static const String expensesCreate = '/purchases/expenses/create';

  // Purchases - Recurring Expenses
  static const String recurringExpenses = '/purchases/recurring-expenses';
  static const String recurringExpensesCreate =
      '/purchases/recurring-expenses/create';

  // Purchases - Purchase Orders
  static const String purchaseOrders = '/purchases/purchase-orders';
  static const String purchaseOrdersCreate =
      '/purchases/purchase-orders/create';
  static const String purchasesPurchaseOrders =
      '/purchases/purchase-orders'; // Legacy
  static const String purchasesPurchaseOrdersCreate =
      '/purchases/purchase-orders/create'; // Legacy

  // Purchases - Bills
  static const String bills = '/purchases/bills';
  static const String billsCreate = '/purchases/bills/create';

  // Purchases - Recurring Bills
  static const String recurringBills = '/purchases/recurring-bills';
  static const String recurringBillsCreate =
      '/purchases/recurring-bills/create';

  // Purchases - Payments Made
  static const String paymentsMade = '/purchases/payments-made';
  static const String paymentsMadeCreate = '/purchases/payments-made/create';

  // Purchases - Vendor Credits
  static const String vendorCredits = '/purchases/vendor-credits';
  static const String vendorCreditsCreate = '/purchases/vendor-credits/create';

  // Reports
  static const String reports = '/reports';
  static const String reportDailySales = '/reports/daily-sales';
  static const String profitAndLoss = '/reports/profit-and-loss';
  static const String generalLedger = '/reports/general-ledger';
  static const String trialBalance = '/reports/trial-balance';
  static const String accountTransactions = '/reports/account-transactions';
  static const String salesByCustomer = '/reports/sales-by-customer';
  static const String inventoryValuation = '/reports/inventory-valuation';

  // Accounts
  static const String accountsChartOfAccounts = '/accounts/chart-of-accounts';
  static const String accountsChartOfAccountsDetail =
      '/accounts/chart-of-accounts/:id';
  static const String accountsChartOfAccountsCreate =
      '/accounts/chart-of-accounts/create';

  // Accountant
  static const String accountantManualJournals = '/accountant/manual-journals';
  static const String accountantManualJournalsDetail =
      '/accountant/manual-journals/:id';
  static const String accountantManualJournalsCreate =
      '/accountant/manual-journals/create';
  static const String accountantJournalTemplates =
      '/accountant/manual-journals/templates';
  static const String accountantJournalTemplateCreation =
      '/accountant/manual-journals/journal-template-creation';
  static const String accountantRecurringJournals =
      '/accountant/recurring-journals';
  static const String accountantRecurringJournalsDetail =
      '/accountant/recurring-journals/:id';
  static const String accountantRecurringJournalsCreate =
      '/accountant/recurring-journals/create';
  static const String accountantBulkUpdate = '/accountant/bulk-update';
  static const String accountantTransactionLocking =
      '/accountant/transaction-locking';
  static const String accountantOpeningBalances =
      '/accountant/opening-balances';
  static const String accountantOpeningBalancesUpdate =
      '/accountant/opening-balances/update';
  static const String accountantSettings = '/accountant/settings';
  static const String accountantTransactionsReport =
      '/accountant/transactions-report';
}
