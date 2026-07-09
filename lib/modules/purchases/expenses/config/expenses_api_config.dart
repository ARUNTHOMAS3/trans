class ExpensesApiConfig {
  ExpensesApiConfig._();

  static const String basePath = 'expenses';

  static const String employees = '$basePath/employees';
  static String detail(String id) => '$basePath/$id';
  static String history(String id) => '$basePath/$id/history';
  static String journal(String id) => '$basePath/$id/journal';
  static String attachments(String id) => '$basePath/$id/attachments';
  static String attachmentById(String id, String attachmentId) =>
      '$basePath/$id/attachments/$attachmentId';
  static String mileage(String id) => '$basePath/$id/mileage';

  static const String taxRates = 'products/lookups/tax-rates';
  static const String taxGroups = 'products/lookups/tax-groups';
  static const String uploadLookup = '/lookups/uploads';
}
