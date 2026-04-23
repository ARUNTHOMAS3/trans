import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_client.dart';
import '../../../../shared/services/hive_service.dart';
import '../models/recurring_journal_model.dart';
import '../../manual_journals/models/manual_journal_model.dart';
import '../repositories/recurring_journal_repository.dart';
import '../../../auth/controller/auth_controller.dart';

class RecurringJournalState {
  static const _unset = Object();

  final List<RecurringJournal> journals;
  final List<RecurringJournalCustomView> customViews;
  final bool isLoading;
  final bool isMutating;
  final String? selectedJournalId;
  final String? error;

  RecurringJournalState({
    this.journals = const [],
    this.customViews = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.selectedJournalId,
    this.error,
  });

  RecurringJournal? get selectedJournal => selectedJournalId == null
      ? null
      : journals.cast<RecurringJournal?>().firstWhere(
          (j) => j?.id == selectedJournalId,
          orElse: () => null,
        );

  RecurringJournalState copyWith({
    List<RecurringJournal>? journals,
    List<RecurringJournalCustomView>? customViews,
    bool? isLoading,
    bool? isMutating,
    Object? selectedJournalId = _unset,
    Object? error = _unset,
  }) {
    return RecurringJournalState(
      journals: journals ?? this.journals,
      customViews: customViews ?? this.customViews,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      selectedJournalId: selectedJournalId == _unset
          ? this.selectedJournalId
          : selectedJournalId as String?,
      error: error == _unset ? this.error : error as String?,
    );
  }
}

class RecurringJournalNotifier extends StateNotifier<RecurringJournalState> {
  final RecurringJournalRepository repository;

  RecurringJournalNotifier(this.repository, {required bool isAuthenticated})
      : super(RecurringJournalState()) {
    _loadCustomViews();
    if (isAuthenticated) fetchJournals();
  }

  void _loadCustomViews() {
    final hive = HiveService();
    final List? saved = hive.getConfig('recurring_journal_custom_views');
    if (saved != null) {
      final views = saved
          .map(
            (e) => RecurringJournalCustomView.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
      state = state.copyWith(customViews: views);
    }
  }

  Future<void> _saveCustomViews() async {
    final hive = HiveService();
    final json = state.customViews.map((v) => v.toJson()).toList();
    await hive.saveConfig('recurring_journal_custom_views', json);
  }

  Future<void> fetchJournals() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final journals = await repository.getRecurringJournals();
      state = state.copyWith(journals: journals, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectJournal(String? id) {
    state = state.copyWith(selectedJournalId: id);
  }

  Future<RecurringJournal> createJournal(RecurringJournal journal) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      final created = await repository.createRecurringJournal(journal);
      await fetchJournals();
      state = state.copyWith(selectedJournalId: created.id, isMutating: false);
      return created;
    } catch (e) {
      state = state.copyWith(isMutating: false, error: e.toString());
      rethrow;
    }
  }

  Future<RecurringJournal> updateJournal(RecurringJournal journal) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      final updated = await repository.updateRecurringJournal(journal);
      await fetchJournals();
      state = state.copyWith(selectedJournalId: updated.id, isMutating: false);
      return updated;
    } catch (e) {
      state = state.copyWith(isMutating: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteJournal(String id) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      await repository.deleteRecurringJournal(id);
      await fetchJournals();
      if (state.selectedJournalId == id) {
        state = state.copyWith(selectedJournalId: null);
      }
      state = state.copyWith(isMutating: false);
    } catch (e) {
      state = state.copyWith(isMutating: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> generateChildJournal(String id) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      await repository.generateChildJournal(id);
      // Invalidate the child journals provider to trigger a refresh
      // Note: In Riverpod 2.x, we use ref.invalidate but here we don't have access to ref in the notifier easily
      // unless we pass it. But we can just return and let the caller handle it or
      // if this was an autoDispose provider it would work differently.
      // Actually, we can use the repository to fetch again if needed, or
      // better yet, just let the UI call invalidate if it has access to ref.
      state = state.copyWith(isMutating: false);
    } catch (e) {
      state = state.copyWith(isMutating: false, error: e.toString());
      rethrow;
    }
  }

  Future<RecurringJournal> cloneJournal(String id) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      final created = await repository.cloneRecurringJournal(id);
      await fetchJournals();
      state = state.copyWith(selectedJournalId: created.id, isMutating: false);
      return created;
    } catch (e) {
      state = state.copyWith(isMutating: false, error: e.toString());
      rethrow;
    }
  }

  void addCustomView(RecurringJournalCustomView view) {
    state = state.copyWith(customViews: [...state.customViews, view]);
    _saveCustomViews();
  }
}

final recurringJournalRepositoryProvider = Provider<RecurringJournalRepository>(
  (ref) {
    final dio = ref.watch(dioProvider);
    return ApiRecurringJournalRepository(dio);
  },
);

final recurringJournalProvider =
    StateNotifierProvider<RecurringJournalNotifier, RecurringJournalState>((
      ref,
    ) {
      final repository = ref.watch(recurringJournalRepositoryProvider);
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      return RecurringJournalNotifier(repository, isAuthenticated: isAuthenticated);
    });

final recurringJournalChildJournalsProvider =
    FutureProvider.family<List<ManualJournal>, String>((ref, id) async {
      final repository = ref.watch(recurringJournalRepositoryProvider);
      return repository.getChildJournals(id);
    });
