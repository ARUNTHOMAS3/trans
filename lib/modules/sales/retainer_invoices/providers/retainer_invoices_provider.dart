import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/models/retainer_invoices_model.dart';
import 'package:zerpai_erp/modules/sales/retainer_invoices/repositories/retainer_invoices_repository.dart';

class RetainerInvoicesState {
  const RetainerInvoicesState({
    this.invoices = const [],
    this.activeFilter,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
  });

  final List<RetainerInvoice> invoices;
  final RetainerStatus? activeFilter;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  List<RetainerInvoice> get filteredInvoices {
    final normalizedSearch = searchQuery.trim().toLowerCase();
    return invoices.where((invoice) {
      final matchesFilter =
          activeFilter == null || invoice.status == activeFilter;
      final matchesSearch =
          normalizedSearch.isEmpty ||
          invoice.invoiceNo.toLowerCase().contains(normalizedSearch) ||
          invoice.customerName.toLowerCase().contains(normalizedSearch) ||
          (invoice.referenceNo?.toLowerCase().contains(normalizedSearch) ?? false);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  RetainerInvoicesState copyWith({
    List<RetainerInvoice>? invoices,
    Object? activeFilter = _noFilterChange,
    String? searchQuery,
    bool? isLoading,
    Object? errorMessage = _noFilterChange,
  }) {
    return RetainerInvoicesState(
      invoices: invoices ?? this.invoices,
      activeFilter: identical(activeFilter, _noFilterChange)
          ? this.activeFilter
          : activeFilter as RetainerStatus?,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _noFilterChange)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class RetainerInvoicesNotifier extends StateNotifier<RetainerInvoicesState> {
  RetainerInvoicesNotifier(this._repository)
      : super(const RetainerInvoicesState());

  final RetainerInvoicesRepository _repository;

  String nextInvoiceNo() {
    var next = 1;
    for (final invoice in state.invoices) {
      final match = RegExp(r'(\d+)$').firstMatch(invoice.invoiceNo);
      final current = match == null ? 0 : int.tryParse(match.group(1)!) ?? 0;
      if (current >= next) {
        next = current + 1;
      }
    }
    return 'RET-${next.toString().padLeft(5, '0')}';
  }

  void setFilter(RetainerStatus? status) {
    state = state.copyWith(activeFilter: status);
  }

  void setSearchQuery(String value) {
    state = state.copyWith(searchQuery: value);
  }

  Future<void> loadInvoices() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final invoices = await _repository.fetchRetainerInvoices();
      state = state.copyWith(
        invoices: invoices,
        isLoading: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void addInvoice(RetainerInvoice invoice) {
    state = state.copyWith(invoices: [...state.invoices, invoice]);
  }

  void updateInvoice(RetainerInvoice invoice) {
    state = state.copyWith(
      invoices: [
        for (final current in state.invoices)
          if (current.id == invoice.id) invoice else current,
      ],
    );
  }

  void deleteInvoice(String invoiceId) {
    state = state.copyWith(
      invoices: state.invoices.where((invoice) => invoice.id != invoiceId).toList(),
    );
  }

  void markAsSent(String invoiceId) {
    _mutateInvoice(invoiceId, (invoice) => invoice.copyWith(status: RetainerStatus.sent));
  }

  void markAsPaid(String invoiceId) {
    _mutateInvoice(
      invoiceId,
      (invoice) => invoice.copyWith(
        status: RetainerStatus.paid,
        amountUsed: invoice.totalAmount,
      ),
    );
  }

  void voidInvoice(String invoiceId) {
    _mutateInvoice(
      invoiceId,
      (invoice) => invoice.copyWith(status: RetainerStatus.voided),
    );
  }

  void cloneInvoice(String sourceId, String newId, String newInvoiceNo) {
    final original = state.invoices.where((invoice) => invoice.id == sourceId).firstOrNull;
    if (original == null) {
      return;
    }
    addInvoice(
      original.copyWith(
        id: newId,
        invoiceNo: newInvoiceNo,
        date: DateTime.now(),
        status: RetainerStatus.draft,
        amountUsed: 0,
      ),
    );
  }

  void _mutateInvoice(
    String invoiceId,
    RetainerInvoice Function(RetainerInvoice invoice) update,
  ) {
    state = state.copyWith(
      invoices: [
        for (final invoice in state.invoices)
          if (invoice.id == invoiceId) update(invoice) else invoice,
      ],
    );
  }
}

final retainerInvoicesProvider =
    StateNotifierProvider<RetainerInvoicesNotifier, RetainerInvoicesState>(
      (ref) => RetainerInvoicesNotifier(
        ref.read(retainerInvoicesRepositoryProvider),
      ),
    );

final retainerInvoicesRepositoryProvider =
    Provider<RetainerInvoicesRepository>(
      (ref) => RetainerInvoicesRepository(apiClient: ref.read(apiClientProvider)),
    );

const Object _noFilterChange = Object();
