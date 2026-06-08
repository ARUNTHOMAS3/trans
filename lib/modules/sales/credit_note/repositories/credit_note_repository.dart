import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/sales/credit_note/models/credit_note_model.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

abstract class CreditNoteRepository {
  Future<List<CreditNoteModel>> getCreditNotes({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  });

  Future<String?> createCreditNote(Map<String, dynamic> payload);
}

class CreditNoteRepositoryImpl implements CreditNoteRepository {
  CreditNoteRepositoryImpl(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<List<CreditNoteModel>> getCreditNotes({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.creditNotes,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null &&
            status.isNotEmpty &&
            status.toLowerCase() != 'all')
          'status': status,
      },
    );
    final data = response.data;
    final List<dynamic> list = data is List
        ? data
        : (data['data'] as List<dynamic>? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(CreditNoteModel.fromJson)
        .toList();
  }

  @override
  Future<String?> createCreditNote(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.creditNotes,
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      return body['id'] as String?;
    } catch (e, st) {
      AppLogger.error(
        'Failed to create credit note',
        error: e,
        stackTrace: st,
        module: 'credit_note',
      );
      rethrow;
    }
  }
}
