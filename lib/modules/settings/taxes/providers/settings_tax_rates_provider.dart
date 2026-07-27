import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/settings/taxes/models/settings_tax_rate_model.dart';

enum SettingsTaxFilter { all, active, inactive, expired, tax, taxGroup }

class SettingsTaxRatesState {
  const SettingsTaxRatesState({
    this.rates = const <SettingsTaxRate>[],
    this.filter = SettingsTaxFilter.all,
    this.selectedIds = const <String>{},
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final List<SettingsTaxRate> rates;
  final SettingsTaxFilter filter;
  final Set<String> selectedIds;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  List<SettingsTaxRate> get visibleRates {
    switch (filter) {
      case SettingsTaxFilter.active:
        return rates.where((tax) => tax.isActive).toList(growable: false);
      case SettingsTaxFilter.inactive:
      case SettingsTaxFilter.expired:
        return rates.where((tax) => !tax.isActive).toList(growable: false);
      case SettingsTaxFilter.tax:
        return rates.where((tax) => !tax.isTaxGroup).toList(growable: false);
      case SettingsTaxFilter.taxGroup:
        return rates.where((tax) => tax.isTaxGroup).toList(growable: false);
      case SettingsTaxFilter.all:
        return rates;
    }
  }

  SettingsTaxRatesState copyWith({
    List<SettingsTaxRate>? rates,
    SettingsTaxFilter? filter,
    Set<String>? selectedIds,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) => SettingsTaxRatesState(
    rates: rates ?? this.rates,
    filter: filter ?? this.filter,
    selectedIds: selectedIds ?? this.selectedIds,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

final settingsTaxRatesProvider =
    StateNotifierProvider<SettingsTaxRatesNotifier, SettingsTaxRatesState>(
      (ref) => SettingsTaxRatesNotifier(ref.watch(apiClientProvider))..load(),
    );

class SettingsTaxRatesNotifier extends StateNotifier<SettingsTaxRatesState> {
  SettingsTaxRatesNotifier(this._apiClient)
    : super(const SettingsTaxRatesState());

  final ApiClient _apiClient;

  Future<void> load({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final responses = await Future.wait([
        _apiClient.get('settings-taxes/rates', useCache: false),
        _apiClient.get('settings-taxes/groups', useCache: false),
      ]);
      final rates = responses[0].data is List
          ? responses[0].data as List
          : const [];
      final groups = responses[1].data is List
          ? responses[1].data as List
          : const [];
      state = state.copyWith(
        rates: [
          ...rates.whereType<Map>().map(
            (row) => _fromRate(Map<String, dynamic>.from(row)),
          ),
          ...groups.whereType<Map>().map(
            (row) => _fromGroup(Map<String, dynamic>.from(row)),
          ),
        ],
        selectedIds: <String>{},
        isLoading: false,
        isSaving: false,
        clearError: true,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isSaving: false,
        errorMessage: 'Unable to load tax rates',
      );
    }
  }

  void setFilter(SettingsTaxFilter filter) =>
      state = state.copyWith(filter: filter, selectedIds: <String>{});

  void toggleSelection(String id, bool selected) {
    final next = {...state.selectedIds};
    selected ? next.add(id) : next.remove(id);
    state = state.copyWith(selectedIds: next);
  }

  void toggleSelectAll(bool selected) {
    state = state.copyWith(
      selectedIds: selected
          ? state.visibleRates.map((tax) => tax.id).toSet()
          : <String>{},
    );
  }

  Future<bool> createTax({
    required String name,
    required String type,
    required double rate,
    List<String>? taxIds,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final isGroup = type.toLowerCase() == 'group';
      await _apiClient.post(
        isGroup ? 'settings-taxes/groups' : 'settings-taxes/rates',
        data: isGroup
            ? {
                'tax_group_name': name,
                'tax_rate': rate,
                'tax_ids': taxIds ?? const <String>[],
                'is_active': true,
              }
            : {
                'tax_name': name,
                'tax_type': type,
                'tax_rate': rate,
                'is_active': true,
              },
      );
      await load(forceRefresh: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Unable to create tax',
      );
      return false;
    }
  }

  Future<bool> updateTax({
    required String id,
    required String name,
    required String type,
    required double rate,
    List<String>? taxIds,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final isGroup = type.toLowerCase() == 'group';
      await _apiClient.patch(
        'settings-taxes/${isGroup ? 'groups' : 'rates'}/$id',
        data: isGroup
            ? {
                'tax_group_name': name,
                'tax_rate': rate,
                'tax_ids': taxIds ?? const <String>[],
              }
            : {'tax_name': name, 'tax_type': type, 'tax_rate': rate},
      );
      await load(forceRefresh: true);
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Unable to update tax',
      );
      return false;
    }
  }

  Future<bool> deleteTax(String id, {bool isTaxGroup = false}) async {
    try {
      await _apiClient.delete(
        'settings-taxes/${isTaxGroup ? 'groups' : 'rates'}/$id',
      );
      await load(forceRefresh: true);
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Unable to delete tax');
      return false;
    }
  }

  Future<bool> toggleTaxStatus({
    required String id,
    required bool isActive,
    bool isTaxGroup = false,
  }) async {
    try {
      await _apiClient.patch(
        'settings-taxes/${isTaxGroup ? 'groups' : 'rates'}/$id',
        data: {'is_active': isActive},
      );
      await load(forceRefresh: true);
      return true;
    } catch (_) {
      state = state.copyWith(errorMessage: 'Unable to update tax status');
      return false;
    }
  }

  SettingsTaxRate _fromRate(Map<String, dynamic> row) => SettingsTaxRate(
    id: row['id']?.toString() ?? '',
    name: row['tax_name']?.toString() ?? '',
    type: row['tax_type']?.toString() ?? '',
    rate: double.tryParse(row['tax_rate']?.toString() ?? '') ?? 0,
    isActive: row['is_active'] as bool? ?? true,
  );

  SettingsTaxRate _fromGroup(Map<String, dynamic> row) => SettingsTaxRate(
    id: row['id']?.toString() ?? '',
    name: row['tax_group_name']?.toString() ?? '',
    type: 'Group',
    rate: double.tryParse(row['tax_rate']?.toString() ?? '') ?? 0,
    isActive: row['is_active'] as bool? ?? true,
    isTaxGroup: true,
  );
}
