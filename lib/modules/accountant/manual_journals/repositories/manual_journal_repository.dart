import 'package:dio/dio.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import '../models/manual_journal_model.dart';

abstract class ManualJournalRepository {
  Future<List<ManualJournal>> getManualJournals({String? orgId});
  Future<ManualJournal> getManualJournal(String id);
  Future<ManualJournal> createManualJournal(ManualJournal journal);
  Future<ManualJournal> updateManualJournal(ManualJournal journal);
  Future<ManualJournal> updateManualJournalStatus(
    String id,
    ManualJournalStatus status,
  );
  Future<void> deleteManualJournal(String id);
  Future<ManualJournal> cloneManualJournal(String id);
  Future<ManualJournal> reverseManualJournal(String id);
  Future<ManualJournalTemplate> createTemplateFromManualJournal(String id);

  // --- Templates ---
  Future<List<ManualJournalTemplate>> getJournalTemplates();
  Future<ManualJournalTemplate> getJournalTemplate(String id);
  Future<ManualJournalTemplate> createJournalTemplate(
    ManualJournalTemplate template,
  );
  Future<ManualJournalTemplate> updateJournalTemplate(
    ManualJournalTemplate template,
  );
  Future<void> deleteJournalTemplate(String id);
}

class ApiManualJournalRepository implements ManualJournalRepository {
  final Dio _dio;

  ApiManualJournalRepository(this._dio);

  dynamic _unwrapData(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload['data'] ??
          payload['items'] ??
          payload['results'] ??
          payload;
    }
    return payload;
  }

  List<Map<String, dynamic>> _asListOfMaps(dynamic payload) {
    final unwrapped = _unwrapData(payload);
    if (unwrapped is! List) return const [];
    return unwrapped
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic> _asMap(dynamic payload) {
    final unwrapped = _unwrapData(payload);
    if (unwrapped is Map<String, dynamic>) return unwrapped;
    if (payload is Map<String, dynamic>) return payload;
    throw Exception('Unexpected API response shape');
  }

  @override
  Future<List<ManualJournal>> getManualJournals({String? orgId}) async {
    final Map<String, dynamic> queryParameters = {};
    if (orgId != null && orgId.isNotEmpty) {
      queryParameters['orgId'] = orgId;
    }

    final response = await _dio.get(
      'accountant/manual-journals',
      queryParameters: queryParameters,
    );
    final journals = _asListOfMaps(response.data);
    return journals.map(ManualJournal.fromJson).toList();
  }

  @override
  Future<ManualJournal> getManualJournal(String id) async {
    final response = await _dio.get('accountant/manual-journals/$id');
    return ManualJournal.fromJson(_asMap(response.data));
  }

  @override
  Future<ManualJournal> createManualJournal(ManualJournal journal) async {
    try {
      final response = await _dio.post(
        'accountant/manual-journals',
        data: journal.toJson(),
      );
      return ManualJournal.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to create journal'),
      );
    }
  }

  @override
  Future<ManualJournal> updateManualJournal(ManualJournal journal) async {
    try {
      final response = await _dio.put(
        'accountant/manual-journals/${journal.id}',
        data: journal.toJson(),
      );
      return ManualJournal.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to update journal'),
      );
    }
  }

  @override
  Future<ManualJournal> updateManualJournalStatus(
    String id,
    ManualJournalStatus status,
  ) async {
    try {
      final response = await _dio.put(
        'accountant/manual-journals/$id/status',
        data: {'status': manualJournalStatusToApi(status)},
      );
      return ManualJournal.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to update journal status'),
      );
    }
  }

  @override
  Future<void> deleteManualJournal(String id) async {
    try {
      await _dio.delete('accountant/manual-journals/$id');
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to delete journal'),
      );
    }
  }

  @override
  Future<ManualJournal> cloneManualJournal(String id) async {
    try {
      final response = await _dio.post('accountant/manual-journals/$id/clone');
      return ManualJournal.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(_extractApiError(e, fallback: 'Failed to clone journal'));
    }
  }

  @override
  Future<ManualJournal> reverseManualJournal(String id) async {
    try {
      final response = await _dio.post(
        'accountant/manual-journals/$id/reverse',
      );
      return ManualJournal.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to reverse journal'),
      );
    }
  }

  @override
  Future<ManualJournalTemplate> createTemplateFromManualJournal(
    String id,
  ) async {
    try {
      final response = await _dio.post(
        'accountant/manual-journals/$id/template',
      );
      return ManualJournalTemplate.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to create template from journal'),
      );
    }
  }

  @override
  Future<List<ManualJournalTemplate>> getJournalTemplates() async {
    final response = await _dio.get('accountant/journal-templates');
    final templates = _asListOfMaps(response.data);
    return templates.map(ManualJournalTemplate.fromJson).toList();
  }

  @override
  Future<ManualJournalTemplate> getJournalTemplate(String id) async {
    final response = await _dio.get('accountant/journal-templates/$id');
    return ManualJournalTemplate.fromJson(_asMap(response.data));
  }

  @override
  Future<ManualJournalTemplate> createJournalTemplate(
    ManualJournalTemplate template,
  ) async {
    try {
      final response = await _dio.post(
        'accountant/journal-templates',
        data: template.toJson(),
      );
      return ManualJournalTemplate.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to create journal template'),
      );
    }
  }

  @override
  Future<ManualJournalTemplate> updateJournalTemplate(
    ManualJournalTemplate template,
  ) async {
    try {
      final response = await _dio.put(
        'accountant/journal-templates/${template.id}',
        data: template.toJson(),
      );
      return ManualJournalTemplate.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to update journal template'),
      );
    }
  }

  @override
  Future<void> deleteJournalTemplate(String id) async {
    try {
      await _dio.delete('accountant/journal-templates/$id');
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to delete journal template'),
      );
    }
  }

  String _extractApiError(DioException e, {required String fallback}) {
    final message = ErrorHandler.getFriendlyMessage(e).trim();
    return message.isEmpty ? fallback : message;
  }
}
