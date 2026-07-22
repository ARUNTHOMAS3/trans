import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

class LockConfigurationRecord {
  const LockConfigurationRecord({
    this.id,
    required this.module,
    required this.lockConfigurationName,
    required this.description,
    required this.allowOrRestrictActions,
    required this.allowOrRestrictFields,
    required this.lockRecordsFor,
    required this.status,
  });

  final String? id;
  final String module;
  final String lockConfigurationName;
  final String description;
  final String allowOrRestrictActions;
  final String allowOrRestrictFields;
  final String lockRecordsFor;
  final String status;

  LockConfigurationRecord copyWith({String? status}) => LockConfigurationRecord(
    id: id,
    module: module,
    lockConfigurationName: lockConfigurationName,
    description: description,
    allowOrRestrictActions: allowOrRestrictActions,
    allowOrRestrictFields: allowOrRestrictFields,
    lockRecordsFor: lockRecordsFor,
    status: status ?? this.status,
  );
}

final lockConfigurationProvider =
    StateNotifierProvider<
      LockConfigurationNotifier,
      List<LockConfigurationRecord>
    >((ref) => LockConfigurationNotifier(ref.watch(apiClientProvider)));

class LockConfigurationNotifier
    extends StateNotifier<List<LockConfigurationRecord>> {
  LockConfigurationNotifier(this._apiClient) : super(const []) {
    load();
  }

  final ApiClient _apiClient;

  Future<void> load({bool forceRefresh = false}) async {
    final response = await _apiClient.get(
      'transaction-locking/configurations',
      useCache: !forceRefresh,
    );
    final rows = response.data is List ? response.data as List : const [];
    state = rows
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .toList(growable: false);
  }

  Future<void> addSeries(LockConfigurationRecord record) async {
    final response = await _apiClient.post(
      'transaction-locking/configurations',
      data: _toPayload(record),
    );
    final created = _fromJson(Map<String, dynamic>.from(response.data as Map));
    state = [...state, created];
  }

  Future<void> updateSeries(int index, LockConfigurationRecord record) async {
    if (index < 0 || index >= state.length) return;
    final id = state[index].id;
    if (id == null || id.isEmpty) return;

    final response = await _apiClient.patch(
      'transaction-locking/configurations/$id',
      data: _toPayload(record),
    );
    final updated = _fromJson(Map<String, dynamic>.from(response.data as Map));
    final next = [...state]..[index] = updated;
    state = next;
  }

  Future<void> deleteSeries(int index) async {
    if (index < 0 || index >= state.length) return;
    final id = state[index].id;
    if (id == null || id.isEmpty) return;

    await _apiClient.delete('transaction-locking/configurations/$id');
    state = [...state]..removeAt(index);
  }

  Future<void> toggleStatus(int index) async {
    if (index < 0 || index >= state.length) return;
    final current = state[index];
    final nextStatus = current.status == 'Active' ? 'Inactive' : 'Active';
    await updateSeries(index, current.copyWith(status: nextStatus));
  }

  LockConfigurationRecord _fromJson(Map<String, dynamic> json) {
    return LockConfigurationRecord(
      id: json['id']?.toString(),
      module: json['module']?.toString() ?? '',
      lockConfigurationName: json['lock_configuration_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      allowOrRestrictActions:
          json['allow_or_restrict_actions']?.toString() ?? '',
      allowOrRestrictFields: 'Allowed Fields: All',
      lockRecordsFor: json['lock_records_for']?.toString() ?? '',
      status: json['status'] == false ? 'Inactive' : 'Active',
    );
  }

  Map<String, dynamic> _toPayload(LockConfigurationRecord record) {
    return <String, dynamic>{
      'module': record.module,
      'lock_configuration_name': record.lockConfigurationName,
      'description': record.description,
      'allow_or_restrict_actions': record.allowOrRestrictActions,
      'lock_records_for': record.lockRecordsFor,
      'status': record.status == 'Active',
    };
  }
}
