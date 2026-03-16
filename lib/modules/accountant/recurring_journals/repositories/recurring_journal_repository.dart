import 'package:dio/dio.dart';
import '../models/recurring_journal_model.dart';
import '../../manual_journals/models/manual_journal_model.dart';

abstract class RecurringJournalRepository {
  Future<List<RecurringJournal>> getRecurringJournals();
  Future<RecurringJournal> getRecurringJournal(String id);
  Future<RecurringJournal> createRecurringJournal(RecurringJournal journal);
  Future<RecurringJournal> updateRecurringJournal(RecurringJournal journal);
  Future<RecurringJournal> updateRecurringJournalStatus(
    String id,
    RecurringJournalStatus status,
  );
  Future<void> deleteRecurringJournal(String id);
  Future<List<ManualJournal>> getChildJournals(String id);
  Future<void> generateChildJournal(String id);
  Future<RecurringJournal> cloneRecurringJournal(String id);
}

class ApiRecurringJournalRepository implements RecurringJournalRepository {
  final Dio _dio;

  ApiRecurringJournalRepository(this._dio);

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
  Future<List<RecurringJournal>> getRecurringJournals() async {
    final response = await _dio.get('accountant/recurring-journals');
    final data = _asListOfMaps(response.data);
    return data.map(RecurringJournal.fromJson).toList();
  }

  @override
  Future<RecurringJournal> getRecurringJournal(String id) async {
    final response = await _dio.get('accountant/recurring-journals/$id');
    return RecurringJournal.fromJson(_asMap(response.data));
  }

  @override
  Future<RecurringJournal> createRecurringJournal(
    RecurringJournal journal,
  ) async {
    try {
      final response = await _dio.post(
        'accountant/recurring-journals',
        data: journal.toJson(),
      );
      return RecurringJournal.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to create recurring journal'),
      );
    }
  }

  @override
  Future<RecurringJournal> updateRecurringJournal(
    RecurringJournal journal,
  ) async {
    try {
      final response = await _dio.put(
        'accountant/recurring-journals/${journal.id}',
        data: journal.toJson(),
      );
      return RecurringJournal.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to update recurring journal'),
      );
    }
  }

  @override
  Future<RecurringJournal> updateRecurringJournalStatus(
    String id,
    RecurringJournalStatus status,
  ) async {
    try {
      final response = await _dio.put(
        'accountant/recurring-journals/$id/status',
        data: {'status': status.name},
      );
      return RecurringJournal.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(_extractApiError(e, fallback: 'Failed to update status'));
    }
  }

  @override
  Future<void> deleteRecurringJournal(String id) async {
    try {
      await _dio.delete('accountant/recurring-journals/$id');
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to delete recurring journal'),
      );
    }
  }

  @override
  Future<List<ManualJournal>> getChildJournals(String id) async {
    try {
      final response = await _dio.get(
        'accountant/recurring-journals/$id/child-journals',
      );
      final data = _asListOfMaps(response.data);
      return data.map(ManualJournal.fromJson).toList();
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to fetch child journals'),
      );
    }
  }

  @override
  Future<void> generateChildJournal(String id) async {
    try {
      await _dio.post('accountant/recurring-journals/$id/generate');
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to generate child journal'),
      );
    }
  }

  @override
  Future<RecurringJournal> cloneRecurringJournal(String id) async {
    try {
      final response = await _dio.post('accountant/recurring-journals/$id/clone');
      return RecurringJournal.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        _extractApiError(e, fallback: 'Failed to clone recurring journal'),
      );
    }
  }

  String _extractApiError(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) return message;
      final error = data['error']?.toString();
      if (error != null && error.trim().isNotEmpty) return error;
    }
    return e.message ?? fallback;
  }
}
