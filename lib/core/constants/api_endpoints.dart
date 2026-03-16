// FILE: lib/core/constants/api_endpoints.dart

class ApiEndpoints {
  // Base URL is configured in environment
  static const String baseUrl = '/api/v1';
  
  // Sales endpoints
  static const String customers = '$baseUrl/customers';
  static const String salesOrders = '$baseUrl/sales-orders';
  static const String invoices = '$baseUrl/invoices';
  
  // Purchases endpoints
  static const String vendors = '$baseUrl/vendors';
  static const String purchaseOrders = '$baseUrl/purchase-orders';
  static const String bills = '$baseUrl/bills';
  
  // Items endpoints
  static const String products = '$baseUrl/products';
  static const String priceLists = '$baseUrl/price-lists';
  
  // Inventory endpoints
  static const String inventory = '$baseUrl/inventory';
  static const String assemblies = '$baseUrl/assemblies';
  static const String stockMovements = '$baseUrl/stock-movements';
  
  // Accounts endpoints
  static const String chartOfAccounts = '$baseUrl/accountant';
  static const String journalEntries = '$baseUrl/accountant/manual-journals';
  
  // Reports endpoints
  static const String reports = '$baseUrl/reports';
  static const String salesReports = '$baseUrl/reports/sales';
  static const String inventoryReports = '$baseUrl/reports/inventory';
  static const String gstReports = '$baseUrl/reports/gst';
  
  // Authentication endpoints
  static const String auth = '$baseUrl/auth';
  static const String login = '$auth/login';
  static const String logout = '$auth/logout';
  static const String refreshToken = '$auth/refresh';
  
  // Lookups
  static const String units = '$baseUrl/units';
  static const String categories = '$baseUrl/categories';
  static const String taxRates = '$baseUrl/tax-rates';
  static const String accounts = '$baseUrl/accountant';
}
