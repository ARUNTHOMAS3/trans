import 'package:dio/dio.dart';
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
      final response = await _dio.post('accountant/manual-journals/$id/reverse');
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
      final response = await _dio.post('accountant/manual-journals/$id/template');
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
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message']?.toString();
      if (message != null && message.trim().isNotEmpty) {
        return message;
      }
      final error = data['error']?.toString();
      if (error != null && error.trim().isNotEmpty) {
        return error;
      }
    }
    if (e.message != null && e.message!.trim().isNotEmpty) {
      return e.message!.trim();
    }
    return fallback;
  }
}

class MockManualJournalRepository implements ManualJournalRepository {
  final List<ManualJournal> _journals = [
    ManualJournal(
      id: '1',
      journalDate: DateTime.now(),
      journalNumber: 'MJ-00001',
      notes: 'Wages payable for Jan 2026',
      items: [
        ManualJournalItem(
          id: 'i1',
          accountId: 'a1',
          accountName: 'Wages and Salaries',
          debit: 50000,
          credit: 0,
        ),
        ManualJournalItem(
          id: 'i2',
          accountId: 'a2',
          accountName: 'TDS Payable',
          debit: 0,
          credit: 5000,
        ),
        ManualJournalItem(
          id: 'i3',
          accountId: 'a3',
          accountName: 'Salaries Payable',
          debit: 0,
          credit: 45000,
        ),
      ],
      status: ManualJournalStatus.posted,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    ManualJournal(
      id: '2',
      journalDate: DateTime.now().subtract(const Duration(days: 2)),
      journalNumber: 'MJ-00002',
      notes: 'Office supplies purchase',
      items: [
        ManualJournalItem(
          id: 'i4',
          accountId: 'a4',
          accountName: 'Office Supplies',
          debit: 1200,
          credit: 0,
        ),
        ManualJournalItem(
          id: 'i5',
          accountId: 'a5',
          accountName: 'Petty Cash',
          debit: 0,
          credit: 1200,
        ),
      ],
      status: ManualJournalStatus.draft,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
  final List<ManualJournalTemplate> _templates = [];
  int _nextJournalId = 3;
  int _nextTemplateId = 1;
  int _nextItemId = 6;

  String _generateJournalId() => (_nextJournalId++).toString();

  String _generateJournalNumber() =>
      'MJ-${_nextJournalId.toString().padLeft(5, '0')}';

  String _generateTemplateId() => (_nextTemplateId++).toString();

  String _generateItemId() => 'i${_nextItemId++}';

  ManualJournalItem _cloneItem(
    ManualJournalItem item, {
    double? debit,
    double? credit,
  }) {
    return ManualJournalItem(
      id: _generateItemId(),
      accountId: item.accountId,
      accountName: item.accountName,
      description: item.description,
      contactId: item.contactId,
      contactType: item.contactType,
      contactName: item.contactName,
      projectId: item.projectId,
      projectName: item.projectName,
      reportingTags: item.reportingTags,
      debit: debit ?? item.debit,
      credit: credit ?? item.credit,
      sortOrder: item.sortOrder,
    );
  }

  ManualJournal _buildDerivedJournal(
    ManualJournal source, {
    required List<ManualJournalItem> items,
    String? notes,
    String? referenceNumber,
  }) {
    final now = DateTime.now();
    return ManualJournal(
      id: _generateJournalId(),
      orgId: source.orgId,
      outletId: source.outletId,
      userId: source.userId,
      journalDate: now,
      journalNumber: _generateJournalNumber(),
      fiscalYearId: source.fiscalYearId,
      referenceNumber: referenceNumber ?? source.referenceNumber,
      notes: notes,
      currency: source.currency,
      is13thMonthAdjustment: source.is13thMonthAdjustment,
      reportingMethod: source.reportingMethod,
      items: items,
      status: ManualJournalStatus.draft,
      createdAt: now,
      updatedAt: now,
      recurringJournalId: source.recurringJournalId,
    );
  }

  @override
  Future<List<ManualJournal>> getManualJournals({String? orgId}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _journals;
  }

  @override
  Future<ManualJournal> getManualJournal(String id) async {
    return _journals.firstWhere((j) => j.id == id);
  }

  @override
  Future<ManualJournal> createManualJournal(ManualJournal journal) async {
    _journals.add(journal);
    return journal;
  }

  @override
  Future<ManualJournal> updateManualJournal(ManualJournal journal) async {
    final index = _journals.indexWhere((j) => j.id == journal.id);
    if (index != -1) {
      _journals[index] = journal;
    }
    return journal;
  }

  @override
  Future<ManualJournal> updateManualJournalStatus(
    String id,
    ManualJournalStatus status,
  ) async {
    final index = _journals.indexWhere((j) => j.id == id);
    if (index == -1) {
      throw Exception('Journal not found');
    }

    final existing = _journals[index];
    final updated = ManualJournal(
      id: existing.id,
      journalDate: existing.journalDate,
      journalNumber: existing.journalNumber,
      fiscalYearId: existing.fiscalYearId,
      referenceNumber: existing.referenceNumber,
      notes: existing.notes,
      currency: existing.currency,
      is13thMonthAdjustment: existing.is13thMonthAdjustment,
      reportingMethod: existing.reportingMethod,
      items: existing.items,
      status: status,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    _journals[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteManualJournal(String id) async {
    _journals.removeWhere((j) => j.id == id);
  }

  @override
  Future<ManualJournal> cloneManualJournal(String id) async {
    final source = _journals.firstWhere((j) => j.id == id);
    final cloned = _buildDerivedJournal(
      source,
      items: source.items.map((item) => _cloneItem(item)).toList(),
      notes: source.notes,
    );
    _journals.add(cloned);
    return cloned;
  }

  @override
  Future<ManualJournal> reverseManualJournal(String id) async {
    final source = _journals.firstWhere((j) => j.id == id);
    final reversed = _buildDerivedJournal(
      source,
      items: source.items
          .map(
            (item) => _cloneItem(
              item,
              debit: item.credit,
              credit: item.debit,
            ),
          )
          .toList(),
      notes: source.notes == null || source.notes!.trim().isEmpty
          ? 'Reversal of ${source.journalNumber}'
          : 'Reversal of ${source.journalNumber}: ${source.notes}',
      referenceNumber: source.referenceNumber ?? source.journalNumber,
    );
    _journals.add(reversed);
    return reversed;
  }

  @override
  Future<ManualJournalTemplate> createTemplateFromManualJournal(
    String id,
  ) async {
    final source = _journals.firstWhere((j) => j.id == id);
    final now = DateTime.now();
    final template = ManualJournalTemplate(
      id: _generateTemplateId(),
      templateName: '${source.journalNumber} Template',
      referenceNumber: source.referenceNumber,
      notes: source.notes,
      reportingMethod: source.reportingMethod,
      currency: source.currency,
      enterAmount: false,
      isActive: true,
      items: source.items
          .map(
            (item) => ManualJournalTemplateItem(
              id: _generateItemId(),
              accountId: item.accountId,
              accountName: item.accountName,
              description: item.description,
              contactId: item.contactId,
              contactType: item.contactType,
              contactName: item.contactName,
              projectId: item.projectId,
              reportingTags: item.reportingTags,
              type: item.debit > 0 ? 'debit' : item.credit > 0 ? 'credit' : null,
              debit: item.debit,
              credit: item.credit,
              sortOrder: item.sortOrder,
            ),
          )
          .toList(),
      createdAt: now,
      updatedAt: now,
    );
    _templates.add(template);
    return template;
  }

  @override
  Future<List<ManualJournalTemplate>> getJournalTemplates() async {
    return List<ManualJournalTemplate>.from(_templates);
  }

  @override
  Future<ManualJournalTemplate> getJournalTemplate(String id) async {
    return _templates.firstWhere(
      (template) => template.id == id,
      orElse: () => throw Exception('Journal template not found'),
    );
  }

  @override
  Future<ManualJournalTemplate> createJournalTemplate(
    ManualJournalTemplate template,
  ) async {
    final now = DateTime.now();
    final created = ManualJournalTemplate(
      id: template.id.isEmpty ? _generateTemplateId() : template.id,
      templateName: template.templateName,
      referenceNumber: template.referenceNumber,
      notes: template.notes,
      reportingMethod: template.reportingMethod,
      currency: template.currency,
      enterAmount: template.enterAmount,
      isActive: template.isActive,
      items: template.items,
      createdAt: template.createdAt ?? now,
      updatedAt: now,
    );
    _templates.add(created);
    return created;
  }

  @override
  Future<ManualJournalTemplate> updateJournalTemplate(
    ManualJournalTemplate template,
  ) async {
    final index = _templates.indexWhere((t) => t.id == template.id);
    final updated = ManualJournalTemplate(
      id: template.id,
      templateName: template.templateName,
      referenceNumber: template.referenceNumber,
      notes: template.notes,
      reportingMethod: template.reportingMethod,
      currency: template.currency,
      enterAmount: template.enterAmount,
      isActive: template.isActive,
      items: template.items,
      createdAt:
          index != -1 ? _templates[index].createdAt : template.createdAt,
      updatedAt: DateTime.now(),
    );
    if (index == -1) {
      _templates.add(updated);
    } else {
      _templates[index] = updated;
    }
    return updated;
  }

  @override
  Future<void> deleteJournalTemplate(String id) async {
    _templates.removeWhere((template) => template.id == id);
  }
}
