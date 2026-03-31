// FILE: lib/core/constants/api_endpoints.dart

class ApiEndpoints {
  // Paths are relative to the Dio baseURL (which already includes /api/v1/).
  // Do NOT add a leading slash — Dio resolves relative paths against baseURL.

  // Sales endpoints
  static const String customers = 'customers';
  static const String salesOrders = 'sales-orders';
  static const String invoices = 'invoices';

  // Purchases endpoints
  static const String vendors = 'vendors';
  static const String purchaseOrders = 'purchase-orders';
  static const String purchaseOrderNextNumber = 'purchase-orders/next-number';
  static const String purchaseOrderSettings = 'purchase-orders/settings';
  static const String purchaseReceives = 'purchase-receives';
  static const String warehouses = 'warehouses';
  static const String bills = 'bills';

  // Items endpoints
  static const String products = 'products';
  static const String priceLists = 'price-lists';

  // Inventory endpoints
  static const String inventory = 'inventory';
  static const String assemblies = 'assemblies';
  static const String stockMovements = 'stock-movements';
  static const String picklists = 'picklists';

  // Accounts endpoints
  static const String chartOfAccounts = 'accountant';
  static const String journalEntries = 'accountant/manual-journals';

  // Reports endpoints
  static const String reports = 'reports';
  static const String salesReports = 'reports/sales';
  static const String inventoryReports = 'reports/inventory';
  static const String gstReports = 'reports/gst';

  // Authentication endpoints
  static const String auth = 'auth';
  static const String login = 'auth/login';
  static const String logout = 'auth/logout';
  static const String refreshToken = 'auth/refresh';

  // Lookups
  static const String units = 'units';
  static const String categories = 'categories';
  static const String taxRates = 'tax-rates';
  static const String accounts = 'accountant';
}
