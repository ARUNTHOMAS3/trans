class AppRoutes {
  AppRoutes._();

  static const String authLogin = '/login';
  static const String authForgotPassword = '/forgot-password';
  static const String authResetPassword = '/reset-password';

  static const String home = '/home';
  static const String settings = '/settings';
  static const String settingsOrgProfile = '/settings/orgprofile';
  static const String settingsOrgProfileEdit = '/settings/orgprofile/edit';
  static const String settingsOrgBranding = '/settings/orgbranding';
  static const String settingsLocations = '/settings/locations';
  static const String settingsLocationsCreate = '/settings/locations/create';
  static const String settingsLocationsEdit = '/settings/locations/:id/edit';
  static const String settingsZones = '/settings/zones';
  static const String settingsZonesCreate = '/settings/zones/new';
  static const String settingsZoneBins = '/settings/zones/:zoneId/bins';

  // Branches (business locations)
  static const String settingsBranches = '/settings/branches';
  static const String settingsBranchCreate = '/settings/branches/create';
  static const String settingsBranchEdit = '/settings/branches/:id/edit';
  static const String settingsBranchProfile = '/settings/branches/:id/profile';

  // Warehouses
  static const String settingsWarehouses = '/settings/warehouses';
  static const String settingsWarehouseCreate = '/settings/warehouses/create';
  static const String settingsWarehouseEdit = '/settings/warehouses/:id/edit';

  // Users & Roles
  static const String settingsUsers = '/settings/users';
  static const String settingsUserInvite = '/settings/users/new';
  static const String settingsUserDetail = '/settings/users/:id';
  static const String settingsUserEdit = '/settings/users/:id/edit';
  static const String settingsRoles = '/settings/roles';
  static const String settingsRoleCreate = '/settings/roles/new';
  static const String settingsRoleDetail = '/settings/roles/:id';
  static const String settingsRoleEdit = '/settings/roles/:id/edit';
  // Taxes & Compliance
  static const String settingsTaxes = '/settings/taxes';
  static const String settingsDirectTaxes = '/settings/direct-taxes';
  static const String settingsEwayBills = '/settings/eway-bills';
  static const String settingsEinvoicing = '/settings/einvoicing';
  static const String settingsMsme = '/settings/msme';
  // Setup & Configurations
  static const String settingsGeneral = '/settings/general';
  static const String settingsCurrencies = '/settings/currencies';
  static const String settingsReminders = '/settings/reminders';
  static const String settingsCustomerPortal = '/settings/customer-portal';
  // Customization
  static const String settingsTransactionNumberSeries =
      '/settings/transaction-number-series';
  static const String settingsPdfTemplates = '/settings/pdf-templates';
  static const String settingsEmailNotifications =
      '/settings/email-notifications';
  static const String settingsSmsNotifications = '/settings/sms-notifications';
  static const String settingsReportingTags = '/settings/reporting-tags';
  static const String settingsWebTabs = '/settings/web-tabs';
  // Automation
  static const String settingsWorkflowRules = '/settings/workflow-rules';
  static const String settingsWorkflowActions = '/settings/workflow-actions';
  static const String settingsWorkflowLogs = '/settings/workflow-logs';
  // Integrations & Marketplace
  static const String settingsIntegrationsZoho = '/settings/integrations/zoho';
  static const String settingsIntegrationsWhatsapp =
      '/settings/integrations/whatsapp';
  static const String settingsIntegrationsSms = '/settings/integrations/sms';
  static const String settingsIntegrationsShipping =
      '/settings/integrations/shipping';
  static const String settingsIntegrationsPos = '/settings/integrations/pos';
  static const String settingsIntegrationsEcommerce =
      '/settings/integrations/ecommerce';
  static const String settingsIntegrationsAccounting =
      '/settings/integrations/accounting';
  static const String settingsIntegrationsSalesMarketing =
      '/settings/integrations/sales-marketing';
  static const String settingsIntegrationsEdi = '/settings/integrations/edi';
  static const String settingsIntegrationsOtherApps =
      '/settings/integrations/other-apps';
  static const String settingsIntegrationsMarketplace =
      '/settings/integrations/marketplace';
  // Developer Data
  static const String settingsDeveloperIncomingWebhooks =
      '/settings/developer/incoming-webhooks';
  static const String settingsDeveloperConnections =
      '/settings/developer/connections';
  static const String settingsDeveloperApiUsage =
      '/settings/developer/api-usage';
  static const String settingsDeveloperDataManagement =
      '/settings/developer/data-management';
  static const String settingsDeveloperDelugeComponents =
      '/settings/developer/deluge-components';
  static const String settingsDeveloperWebForms =
      '/settings/developer/web-forms';

  // Items
  static const String itemsReport = '/items/report';
  static const String itemsCreate = '/items/create';
  static const String itemsDetail = '/items/detail/:id';
  // Full path used when pushing by name; relative 'opening-stock' is the child path in the router.
  static const String itemsOpeningStock = '/items/detail/:id/opening-stock';
  static const String itemsEdit = '/items/edit/:id';

  // Composite Items
  static const String compositeItems = '/items/composite-items';
  static const String compositeItemsCreate = '/items/composite-items/create';
  static const String compositeItemsDetail = '/items/composite-items/:id';

  // Sales — Customers
  static const String salesCustomers = '/sales/customers';
  static const String salesCustomersCreate = '/sales/customers/create';
  static const String salesCustomersDetail = '/sales/customers/:id';
  static const String salesCustomersEdit = '/sales/customers/:id/edit';

  // Sales — Quotations
  static const String salesQuotations = '/sales/quotations';
  static const String salesQuotationsCreate = '/sales/quotations/create';
  static const String salesQuotationsDetail = '/sales/quotations/:id';

  // Sales — Retainer Invoices
  static const String salesRetainerInvoices = '/sales/retainer-invoices';
  static const String salesRetainerInvoicesCreate =
      '/sales/retainer-invoices/create';
  static const String salesRetainerInvoicesDetail =
      '/sales/retainer-invoices/:id';

  // Sales — Orders
  static const String salesOrders = '/sales/orders';
  static const String salesOrdersCreate = '/sales/orders/create';
  static const String salesOrdersEdit = '/sales/orders/:id/edit';
  static const String salesOrdersDetail = '/sales/orders/:id';
  static const String salesOrdersEmail = '/sales/orders/:id/email';

  // Sales — Invoices
  static const String salesInvoices = '/sales/invoices';
  static const String salesInvoicesCreate = '/sales/invoices/create';
  static const String salesInvoicesEdit = '/sales/invoices/:id/edit';
  static const String salesInvoicesDetail = '/sales/invoices/:id';

  // Sales — Delivery Challans
  static const String salesDeliveryChallans = '/sales/delivery-challans';
  static const String salesDeliveryChallansCreate =
      '/sales/delivery-challans/create';
  static const String salesDeliveryChallansDetail =
      '/sales/delivery-challans/:id';

  // Sales — Payments Received
  static const String salesPaymentsReceived = '/sales/payments-received';
  static const String salesPaymentsReceivedCreate =
      '/sales/payments-received/create';
  static const String salesCustomerAdvanceCreate =
      '/sales/payments-received/customer-advance';
  static const String salesPaymentsReceivedDetail =
      '/sales/payments-received/:id';

  // Sales — Returns
  static const String salesReturns = '/sales/returns';
  static const String salesReturnsOverview = salesReturns;
  static const String salesReturnsCreate = '/sales/returns/create';
  static const String salesReturnsDetail = '/sales/returns/:id';

  // Sales — Credit Notes
  static const String salesCreditNotes = '/sales/credit-notes';
  static const String salesCreditNotesCreate = '/sales/credit-notes/create';
  static const String salesCreditNotesEdit = '/sales/credit-notes/edit/:id';
  static const String salesCreditNotesDetail = '/sales/credit-notes/:id';
  // Compatibility aliases used by imported modules
  static const String creditNotes = salesCreditNotes;
  static const String creditNotesCreate = salesCreditNotesCreate;
  static const String creditNotesEdit = salesCreditNotesEdit;

  // Sales — e-Way Bills
  static const String salesEWayBills = '/sales/e-way-bills';
  static const String salesEWayBillsCreate = '/sales/e-way-bills/create';
  static const String salesEWayBillsDetail = '/sales/e-way-bills/:id';

  // Sales — Payment Links
  static const String salesPaymentLinks = '/sales/payment-links';
  static const String salesPaymentLinksCreate = '/sales/payment-links/create';
  static const String salesPaymentLinksDetail = '/sales/payment-links/:id';

  // Sales — Recurring Invoices
  static const String salesRecurringInvoices = '/sales/recurring-invoices';
  static const String salesRecurringInvoicesCreate =
      '/sales/recurring-invoices/create';
  static const String salesRecurringInvoicesDetail =
      '/sales/recurring-invoices/:id';

  // Inventory / Assemblies
  static const String assemblies = '/inventory/assemblies';
  static const String assembliesCreate = '/inventory/assemblies/create';

  // Price Lists
  static const String priceLists = '/pricelists/price-lists';
  static const String priceListsCreate = '/pricelists/price-lists/create';
  static const String priceListsEdit = '/pricelists/price-lists/edit/:id';
  static const String branchPriceLists = '/pricelists/branch-price-lists';
  static const String branchPriceListsCreate =
      '/pricelists/branch-price-lists/create';
  static const String branchPriceListsEdit =
      '/pricelists/branch-price-lists/edit/:id';

  // Inventory placeholders
  static const String inventoryAdjustments = '/inventory/adjustments';
  static const String inventoryAdjustmentsCreate =
      '/inventory/adjustments/create';
  static const String inventoryAdjustmentsEdit =
      '/inventory/adjustments/edit/:id';
  static const String picklists = '/inventory/picklists';
  static const String picklistsDetail = '/inventory/picklists/:id';
  static const String picklistsCreate = '/inventory/picklists/create';
  static const String picklistsEdit = '/inventory/picklists/edit/:id';
  static const String packages = '/inventory/packages';
  static const String packagesCreate = '/inventory/packages/create';
  static const String packagesEdit = '/inventory/packages/edit/:id';
  static const String packagesDetail = '/inventory/packages/:id';
  static const String shipments = '/inventory/shipments';
  static const String shipmentsCreate = '/inventory/shipments/create';
  static const String shipmentsEdit = '/inventory/shipments/edit/:id';
  static const String transferOrders = '/inventory/transfer-orders';
  static const String transferOrdersCreate =
      '/inventory/transfer-orders/create';
  static const String transferOrdersEdit =
      '/inventory/transfer-orders/edit/:id';
  static const String transferOrdersDetail = '/inventory/transfer-orders/:id';
  static const String moveOrders = '/inventory/move-orders';
  static const String moveOrdersCreate = '/inventory/move-orders/create';
  static const String moveOrdersDetail = '/inventory/move-orders/:id';

  // Items utility routes
  static const String itemGroups = '/items/item-groups';
  static const String itemGroupsCreate = '/items/item-groups/create';
  static const String itemMapping = '/items/mapping';
  static const String itemMappingCreate = '/items/mapping/create';

  // Item Trade Setup
  static const String itemTradeSetup = '/items/trade-setup';
  static const String itemTradeSetupCreate = '/items/trade-setup/create';
  static const String itemTradeSetupDetail = '/items/trade-setup/:id';

  // Other top-level modules
  static const String purchases = '/purchases';
  static const String documents = '/documents';
  static const String auditLogs = '/audit-logs';


  // Purchases - Vendors
  static const String vendors = '/purchases/vendors';
  static const String vendorsCreate = '/purchases/vendors/create';
  static const String vendorsDetail = '/purchases/vendors/:id';
  static const String vendorsEdit = '/purchases/vendors/:id/edit';
  static const String vendorsEmail = '/purchases/vendors/:id/email';
  static const String purchasesVendors = '/purchases/vendors'; // Legacy
  static const String purchasesVendorsCreate =
      '/purchases/vendors/create'; // Legacy

  // Purchases - Expenses
  static const String expenses = '/purchases/expenses';
  static const String expensesCreate = '/purchases/expenses/create';
  static const String expensesReceiptsInbox = '/purchases/expenses/receipts-inbox';

  // Purchases - Recurring Expenses
  static const String recurringExpenses = '/purchases/recurring-expenses';
  static const String recurringExpensesCreate =
      '/purchases/recurring-expenses/create';
  static const String recurringExpensesCustomView =
      '/purchases/recurring-expenses/custom-view';

  // Purchases - Purchase Orders
  static const String purchaseOrders = '/purchases/purchase-orders';
  static const String purchaseOrdersCreate =
      '/purchases/purchase-orders/create';
  static const String purchaseOrdersEdit =
      '/purchases/purchase-orders/:id/edit';
  static const String purchaseOrdersDetail = '/purchases/purchase-orders/:id';
  static const String purchaseOrdersEmail =
      '/purchases/purchase-orders/:id/email';
  static const String purchaseReceives = '/purchases/purchase-receives';
  static const String purchaseReceivesCreate =
      '/purchases/purchase-receives/create';
  static const String purchaseReceivesEdit =
      '/purchases/purchase-receives/edit/:id';
  static const String purchaseReturns = '/purchases/purchase-returns';
  static const String purchaseReturnsCreate =
      '/purchases/purchase-returns/create';
  static const String purchaseReturnsDetail =
      '/purchases/purchase-returns/:id';
  static const String purchasesPurchaseOrders =
      '/purchases/purchase-orders'; // Legacy
  static const String purchasesPurchaseOrdersCreate =
      '/purchases/purchase-orders/create'; // Legacy

  // Purchases - Bills
  static const String bills = '/purchases/bills';
  static const String billsCreate = '/purchases/bills/create';
  static const String billsDetail = '/purchases/bills/:id';
  static const String billsEdit = '/purchases/bills/:id/edit';

  // Purchases - Recurring Bills
  static const String recurringBills = '/purchases/recurring-bills';
  static const String recurringBillsCreate =
      '/purchases/recurring-bills/create';

  // Purchases - Payments Made
  static const String paymentsMade = '/purchases/payments-made';
  static const String paymentsMadeCreate = '/purchases/payments-made/create';
  static const String paymentsMadeReport = '/purchases/payments-made/report';

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
  static const String accountsChartOfAccountsEdit =
      '/accounts/chart-of-accounts/edit/:id';
  static const String accountsOpeningBalances = '/accounts/opening-balances';
  static const String accountsOpeningBalancesUpdate =
      '/accounts/opening-balances/update';

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

  // Procurement
  static const String procurementPurchaseRequests = '/procurement/purchase-requests';
  static const String procurementPurchaseRequestsCreate = '/procurement/purchase-requests/create';
  static const String procurementPurchaseRequestOverview = '/procurement/purchase-requests/:id';
  static const String procurementRequestedItems = '/procurement/purchase-requests/requested-items';
  static const String procurementApprovals = '/procurement/approvals';
  static const String procurementApprovalsOverview = '/procurement/approvals/overview';
}


