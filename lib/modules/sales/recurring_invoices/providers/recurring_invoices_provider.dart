import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

import '../data/services/recurring_invoices_api_service.dart';
import '../models/recurring_invoices_model.dart';

class RecurringInvoicesState {
  final List<RecurringInvoice> invoices;
  final bool isLoading;
  final RecurringStatus? activeFilter;
  final String searchQuery;
  final String? errorMessage;

  const RecurringInvoicesState({
    required this.invoices,
    this.isLoading = false,
    this.activeFilter,
    this.searchQuery = '',
    this.errorMessage,
  });

  List<RecurringInvoice> get filteredInvoices {
    var list = invoices;

    if (activeFilter != null) {
      list = list.where((inv) => inv.status == activeFilter).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((inv) {
        return inv.profileName.toLowerCase().contains(q) ||
            inv.customerName.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  RecurringInvoicesState copyWith({
    List<RecurringInvoice>? invoices,
    bool? isLoading,
    RecurringStatus? activeFilter,
    bool clearFilter = false,
    String? searchQuery,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RecurringInvoicesState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class RecurringInvoicesNotifier extends StateNotifier<RecurringInvoicesState> {
  RecurringInvoicesNotifier(this._apiService)
      : super(const RecurringInvoicesState(invoices: [], isLoading: true)) {
    loadInvoices();
  }

  final RecurringInvoicesApiService _apiService;

  Future<void> loadInvoices() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final invoices = await _apiService.getRecurringInvoices();
      state = state.copyWith(
        invoices: invoices,
        isLoading: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  void addInvoice(RecurringInvoice invoice) {
    state = state.copyWith(invoices: [invoice, ...state.invoices]);
  }

  void updateInvoice(RecurringInvoice updated) {
    state = state.copyWith(
      invoices: state.invoices
          .map((invoice) => invoice.id == updated.id ? updated : invoice)
          .toList(),
    );
  }

  void deleteInvoice(String id) {
    state = state.copyWith(
      invoices: state.invoices.where((invoice) => invoice.id != id).toList(),
    );
  }

  Future<void> deleteInvoicePermanently(String id) async {
    await _apiService.deleteRecurringInvoice(id);
    deleteInvoice(id);
  }

  void setFilter(RecurringStatus? filter) {
    if (filter == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: filter);
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final recurringInvoicesProvider =
    StateNotifierProvider<RecurringInvoicesNotifier, RecurringInvoicesState>((ref) {
  return RecurringInvoicesNotifier(
    RecurringInvoicesApiService(ref.read(apiClientProvider)),
  );
});
