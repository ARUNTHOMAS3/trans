import 'package:flutter_riverpod/flutter_riverpod.dart';
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

final settingsTaxRatesProvider = StateNotifierProvider<SettingsTaxRatesNotifier,
    SettingsTaxRatesState>((ref) => SettingsTaxRatesNotifier()..load());

class SettingsTaxRatesNotifier extends StateNotifier<SettingsTaxRatesState> {
  SettingsTaxRatesNotifier() : super(const SettingsTaxRatesState());

  Future<void> load({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;
    state = state.copyWith(isLoading: true, clearError: true);
    // Handoff has no backend contract yet. Keep the UI deterministic and
    // explicit rather than inventing a database response.
    state = state.copyWith(isLoading: false);
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
    state = state.copyWith(isSaving: true);
    final id = 'tax_${DateTime.now().microsecondsSinceEpoch}';
    final next = [
      ...state.rates,
      SettingsTaxRate(
        id: id,
        name: name,
        type: type,
        rate: rate,
        isActive: true,
        isTaxGroup: type.toLowerCase() == 'group',
      ),
    ];
    state = state.copyWith(rates: next, isSaving: false);
    return true;
  }

  Future<bool> updateTax({
    required String id,
    required String name,
    required String type,
    required double rate,
    List<String>? taxIds,
  }) async {
    state = state.copyWith(isSaving: true);
    final next = state.rates
        .map((tax) => tax.id == id
            ? tax.copyWith(
                name: name,
                type: type,
                rate: rate,
                isTaxGroup: type.toLowerCase() == 'group',
              )
            : tax)
        .toList(growable: false);
    state = state.copyWith(rates: next, isSaving: false);
    return true;
  }

  Future<bool> deleteTax(String id, {bool isTaxGroup = false}) async {
    state = state.copyWith(
      rates: state.rates.where((tax) => tax.id != id).toList(growable: false),
      selectedIds: {...state.selectedIds}..remove(id),
    );
    return true;
  }

  Future<bool> toggleTaxStatus({
    required String id,
    required bool isActive,
    bool isTaxGroup = false,
  }) async {
    state = state.copyWith(
      rates: state.rates
          .map((tax) => tax.id == id ? tax.copyWith(isActive: isActive) : tax)
          .toList(growable: false),
    );
    return true;
  }
}
