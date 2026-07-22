import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/sales/payment_recieved/models/payment_record.dart';

/// API service for the `payments_received` Supabase table (backend route
/// `sales/payments-received`). Tenant headers (entity/org) are injected
/// automatically by [ApiClient]'s request interceptor.
/// A customer that appears in `invoice_master`, used to populate the
/// "Customer Name" dropdown on the payment-create page.
class InvoiceCustomerOption {
  final String id;
  final String name;
  final String code;
  final String? email;
  const InvoiceCustomerOption({
    required this.id,
    required this.name,
    required this.code,
    this.email,
  });
}

class PaymentsReceivedApiService {
  final ApiClient _apiClient = ApiClient();

  /// Fetches the distinct customers that have invoices in `invoice_master`
  /// (backend route `sales/payments-received/invoice-customers`). Names are
  /// resolved server-side from the `customers` table.
  Future<List<InvoiceCustomerOption>> getInvoiceCustomers() async {
    final response = await _apiClient.get(
      '/sales/payments-received/invoice-customers',
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load invoice customers (${response.statusCode})',
      );
    }
    final body = response.data;
    final List<dynamic> rows = body is List
        ? body
        : (body is Map ? (body['data'] as List? ?? []) : []);
    return rows
        .whereType<Map>()
        .map((r) {
          final m = Map<String, dynamic>.from(r);
          return InvoiceCustomerOption(
            id: (m['id'] ?? '').toString(),
            name: (m['name'] ?? '').toString(),
            code: (m['customer_number'] ?? '').toString(),
            email: m['email']?.toString(),
          );
        })
        .where((c) => c.id.isNotEmpty)
        .toList();
  }

  /// Fetches payments received for the active tenant, newest first.
  Future<List<PaymentRecord>> getPayments({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    final response = await _apiClient.get(
      '/sales/payments-received',
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    if (response.statusCode == 200) {
      final body = response.data;
      final List<dynamic> rows = body is List
          ? body
          : (body is Map ? (body['data'] as List? ?? []) : []);
      return rows
          .whereType<Map>()
          .map((r) => PaymentRecord.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    }
    throw Exception('Failed to load payments (${response.statusCode})');
  }

  /// Fetches the customer's unpaid invoices (with computed amount due) for the
  /// "Unpaid Invoices" allocation table. Each map carries the real invoice `id`
  /// (uuid) required to save allocations, plus display fields.
  Future<List<Map<String, String>>> getUnpaidInvoices(String customerId) async {
    final money = NumberFormat('#,##0.00', 'en_IN');
    String displayDate(dynamic raw) {
      final s = (raw ?? '').toString();
      final parts = s.split('T').first.split('-');
      if (parts.length == 3) return '${parts[2]}-${parts[1]}-${parts[0]}';
      return s;
    }

    final response = await _apiClient.get(
      '/sales/payments-received/unpaid-invoices',
      queryParameters: {'customerId': customerId},
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load unpaid invoices (${response.statusCode})',
      );
    }
    final body = response.data;
    final List<dynamic> rows = body is List
        ? body
        : (body is Map ? (body['data'] as List? ?? []) : []);
    return rows.whereType<Map>().map((r) {
      final m = Map<String, dynamic>.from(r);
      return <String, String>{
        'id': (m['id'] ?? '').toString(),
        'number': (m['invoice_number'] ?? '').toString(),
        'date': displayDate(m['invoice_date']),
        'dueDate': displayDate(m['due_date']),
        'location': (m['place_of_supply'] ?? '').toString(),
        'invoiceAmount': money.format(
          double.tryParse((m['invoice_amount'] ?? 0).toString()) ?? 0,
        ),
        'amountDue': money.format(
          double.tryParse((m['amount_due'] ?? 0).toString()) ?? 0,
        ),
      };
    }).toList();
  }

  /// Persists a payment received. Returns the created row (includes the
  /// generated `id`). Throws on failure so callers can surface an error toast.
  Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.post(
      '/sales/payments-received',
      data: payload,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return <String, dynamic>{};
    }
    throw Exception('Failed to create payment (${response.statusCode})');
  }

  /// Updates an existing payment received by its backend `id` (uuid). Returns
  /// the updated row. Throws on failure.
  Future<Map<String, dynamic>> updatePayment(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _apiClient.patch(
      '/sales/payments-received/$id',
      data: payload,
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map && data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return <String, dynamic>{};
    }
    throw Exception('Failed to update payment (${response.statusCode})');
  }
}
