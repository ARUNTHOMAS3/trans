import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/api_client.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../auth/controller/auth_controller.dart';
import '../models/manual_journal_model.dart';
import '../repositories/manual_journal_repository.dart';

dynamic _normalizePayload(dynamic payload) {
  if (payload is String && payload.isNotEmpty) {
    try {
      return jsonDecode(payload);
    } catch (_) {
      return payload;
    }
  }
  return payload;
}

List<Map<String, dynamic>> _extractListPayload(dynamic payload) {
  final normalized = _normalizePayload(payload);
  dynamic data = normalized is Map<String, dynamic>
      ? normalized['data'] ?? normalized['items'] ?? normalized['results']
      : normalized;

  if (data is Map<String, dynamic>) {
    data = data['data'] ?? data['items'] ?? data['results'];
  }

  if (data is! List) return const [];
  return data
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, dynamic> _extractMapPayload(dynamic payload) {
  final normalized = _normalizePayload(payload);
  if (normalized is! Map<String, dynamic>) return {};
  final dynamic data = normalized['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  return normalized;
}

const _defaultOrgId = '00000000-0000-0000-0000-000000000000';

final journalSettingsScopeProvider = Provider<Map<String, dynamic>>((ref) {
  final authUser = ref.watch(authUserProvider);
  final supabaseUserId = Supabase.instance.client.auth.currentUser?.id;

  final userId = (authUser != null && authUser.id.isNotEmpty)
      ? authUser.id
      : (supabaseUserId != null && supabaseUserId.isNotEmpty
            ? supabaseUserId
            : null);

  final orgId = (authUser != null && authUser.orgId.isNotEmpty)
      ? authUser.orgId
      : _defaultOrgId;

  return {'orgId': orgId, 'branchId': null, 'userId': userId};
});

class ManualJournalState {
  static const _unset = Object();

  final List<ManualJournal> journals;
  final bool isLoading;
  final bool isMutating;
  final String? selectedJournalId;
  final String? error;

  final Set<String> failedJournalIds;

  ManualJournalState({
    this.journals = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.selectedJournalId,
    this.error,
    this.failedJournalIds = const {},
  });

  ManualJournal? get selectedJournal => selectedJournalId == null
      ? null
      : (() {
          for (final journal in journals) {
            if (journal.id == selectedJournalId) {
              return journal;
            }
          }
          return null;
        })();

  ManualJournalState copyWith({
    List<ManualJournal>? journals,
    bool? isLoading,
    bool? isMutating,
    Object? selectedJournalId = _unset,
    Object? error = _unset,
    Set<String>? failedJournalIds,
  }) {
    return ManualJournalState(
      journals: journals ?? this.journals,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      selectedJournalId: selectedJournalId == _unset
          ? this.selectedJournalId
          : selectedJournalId as String?,
      error: error == _unset ? this.error : error as String?,
      failedJournalIds: failedJournalIds ?? this.failedJournalIds,
    );
  }
}

class ManualJournalNotifier extends StateNotifier<ManualJournalState> {
  final ManualJournalRepository repository;
  final String? _orgId;

  ManualJournalNotifier(this.repository, {String? orgId})
    : _orgId = orgId,
      super(ManualJournalState()) {
    if (orgId != null && orgId != _defaultOrgId) {
      fetchJournals(orgId: orgId);
    }
  }

  Future<void> fetchJournals({String? orgId}) async {
    final effectiveOrgId = orgId ?? _orgId;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final journals = await repository.getManualJournals(
        orgId: effectiveOrgId,
      );
      if (!mounted) return;
      state = state.copyWith(journals: journals, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getFriendlyMessage(e),
      );
    }
  }

  Future<void> selectJournal(String? id, {bool forceRefresh = false}) async {
    if (id == null) {
      state = state.copyWith(selectedJournalId: null);
      return;
    }

    // Loop Protection: If it already failed and we aren't forcing a refresh, stop
    if (state.failedJournalIds.contains(id) && !forceRefresh) {
      state = state.copyWith(selectedJournalId: id);
      return;
    }

    state = state.copyWith(selectedJournalId: id, isLoading: true, error: null);

    try {
      // Assuming getManualJournal(id) fetches fresh detail if not full in list
      final journal = await repository.getManualJournal(id);
      if (!mounted) return;

      final newFailedSet = Set<String>.from(state.failedJournalIds)..remove(id);

      // Update the journal in the list if found, or just update the state
      final updatedJournals = state.journals
          .map((j) => j.id == id ? journal : j)
          .toList();

      state = state.copyWith(
        journals: updatedJournals,
        isLoading: false,
        failedJournalIds: newFailedSet,
      );
    } catch (e) {
      if (!mounted) return;
      final newFailedSet = Set<String>.from(state.failedJournalIds)..add(id);
      state = state.copyWith(
        isLoading: false,
        error: ErrorHandler.getFriendlyMessage(e),
        failedJournalIds: newFailedSet,
      );
    }
  }

  void clearSelection() {
    state = state.copyWith(selectedJournalId: null);
  }

  Future<ManualJournal> createJournal(ManualJournal journal) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      final created = await repository.createManualJournal(journal);
      await fetchJournals();
      if (!mounted) return created;
      state = state.copyWith(selectedJournalId: created.id, isMutating: false);
      return created;
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isMutating: false,
        error: ErrorHandler.getFriendlyMessage(e),
      );
      rethrow;
    }
  }

  Future<ManualJournal> updateJournal(ManualJournal journal) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      final updated = await repository.updateManualJournal(journal);
      if (!mounted) return updated;
      await fetchJournals();
      if (!mounted) return updated;
      state = state.copyWith(selectedJournalId: updated.id, isMutating: false);
      return updated;
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isMutating: false,
        error: ErrorHandler.getFriendlyMessage(e),
      );
      rethrow;
    }
  }

  Future<ManualJournal> updateStatus(
    String id,
    ManualJournalStatus status,
  ) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      final updated = await repository.updateManualJournalStatus(id, status);
      if (!mounted) return updated;
      await fetchJournals();
      if (!mounted) return updated;
      state = state.copyWith(selectedJournalId: updated.id, isMutating: false);
      return updated;
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isMutating: false,
        error: ErrorHandler.getFriendlyMessage(e),
      );
      rethrow;
    }
  }

  Future<void> deleteJournal(String id) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      await repository.deleteManualJournal(id);
      if (!mounted) return;
      await fetchJournals();
      if (!mounted) return;
      if (state.selectedJournalId == id) {
        state = state.copyWith(selectedJournalId: null);
      }
      state = state.copyWith(isMutating: false);
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isMutating: false,
        error: ErrorHandler.getFriendlyMessage(e),
      );
      rethrow;
    }
  }

  Future<void> publishJournals(List<String> ids) async {
    if (ids.isEmpty) return;
    state = state.copyWith(isMutating: true, error: null);
    try {
      final journalById = <String, ManualJournal>{
        for (final journal in state.journals) journal.id: journal,
      };

      for (final id in ids) {
        final journal = journalById[id];
        if (journal == null) continue;
        if (journal.status == ManualJournalStatus.posted) continue;
        await repository.updateManualJournalStatus(
          id,
          ManualJournalStatus.posted,
        );
      }

      if (!mounted) return;
      await fetchJournals();
      if (!mounted) return;
      state = state.copyWith(isMutating: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isMutating: false,
        error: ErrorHandler.getFriendlyMessage(e),
      );
      rethrow;
    }
  }

  Future<void> deleteJournals(List<String> ids) async {
    if (ids.isEmpty) return;
    state = state.copyWith(isMutating: true, error: null);
    try {
      for (final id in ids) {
        await repository.deleteManualJournal(id);
      }

      if (!mounted) return;
      await fetchJournals();

      if (!mounted) return;
      if (ids.contains(state.selectedJournalId)) {
        state = state.copyWith(selectedJournalId: null);
      }

      state = state.copyWith(isMutating: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isMutating: false,
        error: ErrorHandler.getFriendlyMessage(e),
      );
      rethrow;
    }
  }

  Future<ManualJournal> cloneJournal(String id) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      final created = await repository.cloneManualJournal(id);
      await fetchJournals();
      if (!mounted) return created;
      state = state.copyWith(selectedJournalId: created.id, isMutating: false);
      return created;
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isMutating: false,
        error: ErrorHandler.getFriendlyMessage(e),
      );
      rethrow;
    }
  }

  Future<ManualJournal> reverseJournal(String id) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      final reversed = await repository.reverseManualJournal(id);
      await fetchJournals();
      if (!mounted) return reversed;
      state = state.copyWith(selectedJournalId: reversed.id, isMutating: false);
      return reversed;
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isMutating: false,
        error: ErrorHandler.getFriendlyMessage(e),
      );
      rethrow;
    }
  }

  Future<ManualJournalTemplate> createTemplateFromJournal(String id) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      final template = await repository.createTemplateFromManualJournal(id);
      if (!mounted) return template;
      state = state.copyWith(isMutating: false);
      return template;
    } catch (e) {
      if (!mounted) rethrow;
      state = state.copyWith(
        isMutating: false,
        error: ErrorHandler.getFriendlyMessage(e),
      );
      rethrow;
    }
  }
}

final manualJournalRepositoryProvider = Provider<ManualJournalRepository>((
  ref,
) {
  final dio = ref.watch(dioProvider);
  return ApiManualJournalRepository(dio);
});

final manualJournalProvider =
    StateNotifierProvider<ManualJournalNotifier, ManualJournalState>((ref) {
      final repository = ref.watch(manualJournalRepositoryProvider);
      final scope = ref.watch(journalSettingsScopeProvider);
      final orgId = scope['orgId']?.toString();
      return ManualJournalNotifier(repository, orgId: orgId);
    });

final fiscalYearsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('accountant/fiscal-years');
    final years = _extractListPayload(response.data);
    years.sort((a, b) {
      final aDate = (a['start_date'] ?? '').toString();
      final bDate = (b['start_date'] ?? '').toString();
      return aDate.compareTo(bDate);
    });
    return years;
  } catch (_) {
    return [];
  }
});

final manualJournalContactsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
      final dio = ref.watch(dioProvider);
      try {
        final response = await dio.get('accountant/contacts');
        final raw = _extractListPayload(response.data);
        final dedupe = <String>{};

        return raw
            .map((item) {
              final id = (item['id'] ?? '').toString().trim();
              final displayName =
                  (item['displayName'] ?? item['display_name'] ?? '')
                      .toString()
                      .trim();
              final rawType =
                  (item['contact_type'] ??
                          item['type'] ??
                          (item['vendor_type'] != null ? 'vendor' : 'customer'))
                      .toString()
                      .trim()
                      .toLowerCase();
              final type = rawType == 'vendor' ? 'vendor' : 'customer';

              return <String, dynamic>{
                ...item,
                'id': id,
                'displayName': displayName,
                'type': type,
                'contact_type': type,
              };
            })
            .where((item) {
              final id = (item['id'] ?? '').toString();
              final displayName = (item['displayName'] ?? '').toString();
              final contactType = (item['contact_type'] ?? 'customer')
                  .toString()
                  .toLowerCase();
              final key = '$contactType:$id';
              if (id.isEmpty || displayName.isEmpty) return false;
              if (dedupe.contains(key)) return false;
              dedupe.add(key);
              return true;
            })
            .toList();
      } catch (_) {
        return [];
      }
    });

final searchContactsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      query,
    ) async {
      final dio = ref.watch(dioProvider);
      try {
        final response = await dio.get(
          'accountant/contacts/search',
          queryParameters: {'q': query},
        );
        final raw = _extractListPayload(response.data);
        return raw.map((item) {
          final id = (item['id'] ?? '').toString().trim();
          final displayName =
              (item['displayName'] ?? item['display_name'] ?? '')
                  .toString()
                  .trim();
          final type = (item['contact_type'] ?? item['type'] ?? 'customer')
              .toString()
              .trim()
              .toLowerCase();
          return <String, dynamic>{
            ...item,
            'id': id,
            'displayName': displayName,
            'type': type,
            'contact_type': type,
          };
        }).toList();
      } catch (_) {
        return [];
      }
    });

final journalSettingsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final scope = ref.watch(journalSettingsScopeProvider);
  final query = <String, dynamic>{'orgId': scope['orgId']};
  if (scope['branchId'] != null) {
    query['branchId'] = scope['branchId'];
  }
  if (scope['userId'] != null) {
    query['userId'] = scope['userId'];
  }

  try {
    final response = await dio.get(
      'accountant/journal-number-settings',
      queryParameters: query,
    );
    return _extractMapPayload(response.data);
  } catch (e) {
    try {
      final response = await dio.get(
        'accountant/journal-settings',
        queryParameters: query,
      );
      return _extractMapPayload(response.data);
    } catch (_) {
      return {'auto_generate': true, 'prefix': 'MJ', 'next_number': 1};
    }
  }
});
