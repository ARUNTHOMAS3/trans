import 'package:zerpai_erp/modules/sales/recurring_invoices/models/recurring_invoices_model.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

class RecurringInvoicesApiService {
  RecurringInvoicesApiService([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<RecurringInvoice>> getRecurringInvoices() async {
    final response = await _apiClient.get(
      '/sales/recurring-invoices',
      useCache: false,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to load recurring invoices');
    }

    final responseData = response.data;
    final List<dynamic> rows = responseData is List
        ? responseData
        : (responseData is Map<String, dynamic> ? (responseData['data'] ?? []) : []);

    return rows
        .whereType<Map>()
        .map(
          (row) => RecurringInvoice.fromJson(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();
  }

  Future<void> deleteRecurringInvoice(String id) async {
    final response = await _apiClient.delete('/sales/recurring-invoices/$id');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete recurring invoice');
    }
  }
}
