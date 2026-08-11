import 'package:dio/dio.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/models/retainer_invoice_create_payload.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/models/retainer_invoices_model.dart';

class RetainerInvoicesRepository {
  RetainerInvoicesRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<RetainerInvoice>> fetchRetainerInvoices({
    String? search,
    String? status,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final response = await _apiClient.get(
        'sales/retainer-invoices',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        },
        useCache: false,
      );
      final items = _asList(response.data);
      return items.map(RetainerInvoice.fromJson).toList();
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to load retainer invoices'),
      );
    }
  }

  Future<Map<String, dynamic>> createRetainerInvoice(
    RetainerInvoiceCreatePayload payload,
  ) async {
    try {
      final response = await _apiClient.post(
        'sales/retainer-invoices',
        data: payload.toJson(),
      );
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to save retainer invoice'),
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
      return payload;
    }
    throw Exception('Unexpected API response shape');
  }

  List<Map<String, dynamic>> _asList(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is List) {
        return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }
    if (payload is List) {
      return payload.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    throw Exception('Unexpected API response shape');
  }

  String _extractApiError(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
      final nestedData = data['data'];
      if (nestedData is Map<String, dynamic>) {
        final nestedMessage = nestedData['message']?.toString();
        if (nestedMessage != null && nestedMessage.trim().isNotEmpty) {
          return nestedMessage;
        }
      }
    }
    return fallback;
  }
}
