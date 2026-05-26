import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/purchases/bills/models/purchases_bills_bill_model.dart';
import 'package:zerpai_erp/modules/purchases/bills/repositories/purchases_bills_repository.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class BillsState {
  final List<PurchasesBill> bills;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final int totalPages;
  final String? searchQuery;
  final String? filterStatus;

  BillsState({
    this.bills = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.totalPages = 1,
    this.searchQuery,
    this.filterStatus,
  });

  BillsState copyWith({
    List<PurchasesBill>? bills,
    bool? isLoading,
    String? error,
    int? currentPage,
    int? totalPages,
    String? searchQuery,
    String? filterStatus,
  }) {
    return BillsState(
      bills: bills ?? this.bills,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class BillsNotifier extends StateNotifier<BillsState> {
  final PurchasesBillsRepository _repository;

  BillsNotifier(this._repository) : super(BillsState());

  Future<void> loadBills({int page = 1, String? search, String? status}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final bills = await _repository.getBills(
        page: page,
        search: search,
        status: status,
      );
      state = state.copyWith(
        bills: bills,
        isLoading: false,
        currentPage: page,
        searchQuery: search,
        filterStatus: status,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<PurchasesBill> createBill(PurchasesBill bill) async {
    try {
      final created = await _repository.createBill(bill);
      state = state.copyWith(bills: [...state.bills, created]);
      return created;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteBill(String id) async {
    try {
      await _repository.deleteBill(id);
      state = state.copyWith(
        bills: state.bills.where((b) => b.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final billsProvider = StateNotifierProvider<BillsNotifier, BillsState>((ref) {
  final repository = ref.read(purchasesBillsRepositoryProvider);
  return BillsNotifier(repository);
});
