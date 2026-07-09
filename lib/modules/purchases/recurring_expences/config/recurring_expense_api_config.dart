class RecurringExpenseApiConfig {
  static const String basePath = 'recurring-expenses';
  static const String lookupsBasePath = 'products/lookups';
  static const String accounts = 'accountant';
  static const String customers = 'customers';
  static const String vendors = 'vendors';
  static const String currencies = 'lookups/currencies';
  static const String gstTreatments = 'lookups/gst-treatments';
  static String states(String countryCode) => 'lookups/states/$countryCode';

  static String byId(String id) => '$basePath/$id';
  static const String bulkDelete = '$basePath/bulk';
  static const String bulkUpdate = '$basePath/bulk-update';
  static String runs(String id) => '$basePath/$id/runs';
  static String history(String id) => '$basePath/$id/history';
  static String receipts(String id) => '$basePath/$id/receipts';
  static String receiptById(String recurringExpenseId, String receiptId) =>
      '$basePath/$recurringExpenseId/receipts/$receiptId';
  static String stop(String id) => '$basePath/$id/stop';
  static String start(String id) => '$basePath/$id/start';
  static String createExpense(String id) => '$basePath/$id/create-expense';
  static String relatedExpenses(String id) => '$basePath/$id/expenses';

  static const String taxRates = '$lookupsBasePath/tax-rates';
  static const String taxGroups = '$lookupsBasePath/tax-groups';
  static const String paymentTerms = '$lookupsBasePath/payment-terms';
  static const String priceLists = 'price-lists';
}
