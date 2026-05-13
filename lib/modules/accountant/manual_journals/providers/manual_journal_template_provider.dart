import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/manual_journal_model.dart';
import '../repositories/manual_journal_repository.dart';
import 'manual_journal_provider.dart';
import '../../../auth/controller/auth_controller.dart';

class ManualJournalTemplateState {
  static const _unset = Object();

  final List<ManualJournalTemplate> templates;
  final bool isLoading;
  final bool isMutating;
  final String? selectedTemplateId;
  final String? error;

  ManualJournalTemplateState({
    this.templates = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.selectedTemplateId,
    this.error,
  });

  ManualJournalTemplate? get selectedTemplate => selectedTemplateId == null
      ? null
      : templates
            .where((template) => template.id == selectedTemplateId)
            .firstOrNull;

  ManualJournalTemplateState copyWith({
    List<ManualJournalTemplate>? templates,
    bool? isLoading,
    bool? isMutating,
    Object? selectedTemplateId = _unset,
    Object? error = _unset,
  }) {
    return ManualJournalTemplateState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      selectedTemplateId: selectedTemplateId == _unset
          ? this.selectedTemplateId
          : selectedTemplateId as String?,
      error: error == _unset ? this.error : error as String?,
    );
  }
}

class ManualJournalTemplateNotifier
    extends StateNotifier<ManualJournalTemplateState> {
  final ManualJournalRepository repository;

  ManualJournalTemplateNotifier(this.repository, {required bool isAuthenticated})
    : super(ManualJournalTemplateState()) {
    if (isAuthenticated) fetchTemplates();
  }

  Future<void> fetchTemplates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final templates = await repository.getJournalTemplates();
      state = state.copyWith(templates: templates, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<ManualJournalTemplate> createTemplate(
    ManualJournalTemplate template,
  ) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      final created = await repository.createJournalTemplate(template);
      await fetchTemplates();
      state = state.copyWith(isMutating: false);
      return created;
    } catch (e) {
      state = state.copyWith(isMutating: false, error: e.toString());
      rethrow;
    }
  }

  Future<ManualJournalTemplate> updateTemplate(
    ManualJournalTemplate template,
  ) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      final updated = await repository.updateJournalTemplate(template);
      await fetchTemplates();
      state = state.copyWith(isMutating: false);
      return updated;
    } catch (e) {
      state = state.copyWith(isMutating: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteTemplate(String id) async {
    state = state.copyWith(isMutating: true, error: null);
    try {
      await repository.deleteJournalTemplate(id);
      await fetchTemplates();
      state = state.copyWith(isMutating: false);
    } catch (e) {
      state = state.copyWith(isMutating: false, error: e.toString());
      rethrow;
    }
  }

  void selectTemplate(String? id) {
    state = state.copyWith(selectedTemplateId: id);
  }
}

final manualJournalTemplateProvider =
    StateNotifierProvider<
      ManualJournalTemplateNotifier,
      ManualJournalTemplateState
    >((ref) {
      final repository = ref.watch(manualJournalRepositoryProvider);
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      return ManualJournalTemplateNotifier(repository, isAuthenticated: isAuthenticated);
    });
