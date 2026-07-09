import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_attachment_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_history_entry_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_journal_entry_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_record.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_request_models.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expenses_list_query.dart';
import 'package:zerpai_erp/modules/purchases/expenses/repositories/expenses_repository.dart';
import 'package:zerpai_erp/modules/purchases/expenses/repositories/expenses_repository_impl.dart';
import 'package:zerpai_erp/modules/purchases/expenses/services/expenses_api_service.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/providers/recurring_expense_provider.dart';

class ExpensesState {
  const ExpensesState({
    this.records = const <ExpenseRecord>[],
    this.sortField = 'date',
    this.sortAscending = false,
    this.selectedFilterValue = 'all',
    this.isLoading = false,
    this.totalRecords = 0,
    this.totalPages = 1,
    this.error,
    this.query = const ExpensesListQuery(),
  });

  final List<ExpenseRecord> records;
  final String sortField;
  final bool sortAscending;
  final String selectedFilterValue;
  final bool isLoading;
  final int totalRecords;
  final int totalPages;
  final String? error;
  final ExpensesListQuery query;

  ExpensesState copyWith({
    List<ExpenseRecord>? records,
    String? sortField,
    bool? sortAscending,
    String? selectedFilterValue,
    bool? isLoading,
    int? totalRecords,
    int? totalPages,
    String? error,
    ExpensesListQuery? query,
  }) {
    return ExpensesState(
      records: records ?? this.records,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      selectedFilterValue: selectedFilterValue ?? this.selectedFilterValue,
      isLoading: isLoading ?? this.isLoading,
      totalRecords: totalRecords ?? this.totalRecords,
      totalPages: totalPages ?? this.totalPages,
      error: error,
      query: query ?? this.query,
    );
  }
}

final expensesApiServiceProvider = Provider<ExpensesApiService>(
  (ref) => ExpensesApiService(ref.read(apiClientProvider)),
);

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepositoryImpl(ref.read(expensesApiServiceProvider)),
);

class ExpensesNotifier extends StateNotifier<ExpensesState> {
  ExpensesNotifier(this._repository) : super(const ExpensesState()) {
    Future<void>.microtask(fetchExpenses);
  }

  final ExpensesRepository _repository;
  int _requestToken = 0;

  Future<void> fetchExpenses([ExpensesListQuery? query]) async {
    final effectiveQuery = query ?? state.query;
    final int requestToken = ++_requestToken;
    state = state.copyWith(
      isLoading: true,
      error: null,
      query: effectiveQuery,
      sortField: effectiveQuery.sortBy,
      sortAscending: effectiveQuery.sortAscending,
      selectedFilterValue: effectiveQuery.favoriteFilter ?? 'all',
    );
    try {
      final response = await _repository.getExpenses(effectiveQuery);
      if (requestToken != _requestToken) {
        return;
      }
      final normalizedPage = _normalizePage(
        requestedPage: effectiveQuery.page,
        totalPages: response.totalPages,
      );
      if (normalizedPage != effectiveQuery.page) {
        await fetchExpenses(effectiveQuery.copyWith(page: normalizedPage));
        return;
      }

      state = state.copyWith(
        records: response.items,
        totalRecords: response.total,
        totalPages: response.totalPages,
        isLoading: false,
        error: null,
      );
    } catch (error) {
      if (requestToken != _requestToken) {
        return;
      }
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }

  Future<void> refresh() => fetchExpenses();

  void toggleRecordSelect(int index, bool? selected) {
    if (index < 0 || index >= state.records.length) return;
    final updated = List<ExpenseRecord>.from(state.records);
    updated[index] = updated[index].copyWith(isSelected: selected ?? false);
    state = state.copyWith(records: updated);
  }

  void toggleSelectAll(bool allSelected, int startIndex, int endIndex) {
    final updated = List<ExpenseRecord>.from(state.records);
    for (int i = startIndex; i < endIndex && i < updated.length; i += 1) {
      updated[i] = updated[i].copyWith(isSelected: allSelected);
    }
    state = state.copyWith(records: updated);
  }

  void clearSelection() {
    state = state.copyWith(
      records: state.records
          .map((record) => record.copyWith(isSelected: false))
          .toList(growable: false),
    );
  }

  void updateFilter(String filterValue) {
    final normalizedFilter = filterValue == 'all' ? null : filterValue;
    unawaited(
      fetchExpenses(
        state.query.copyWith(page: 1, favoriteFilter: normalizedFilter),
      ),
    );
  }

  void bulkUpdate(String field, String value) {
    final updated = state.records
        .map((record) {
          if (!record.isSelected) return record;
          switch (field) {
            case 'Expense Account':
              return record.copyWith(expenseAccount: value);
            case 'Paid Through':
              return record.copyWith(paidThrough: value);
            case 'Date':
              return record.copyWith(date: value);
            case 'Billable':
              return record.copyWith(status: value);
            case 'Reference#':
              return record.copyWith(reference: value);
            case 'Notes':
              return record.copyWith(notes: value);
            case 'Customer Name':
              return record.copyWith(customerName: value);
            default:
              return record;
          }
        })
        .toList(growable: false);
    state = state.copyWith(records: updated);
  }

  Future<void> deleteSelected() async {
    final selectedIds = state.records
        .where((record) => record.isSelected && record.id.isNotEmpty)
        .map((record) => record.id)
        .toList(growable: false);
    if (selectedIds.isEmpty) {
      return;
    }
    for (final id in selectedIds) {
      await _repository.deleteExpense(id);
    }
    await fetchExpenses();
  }

  Future<void> deleteExpenseById(String id) async {
    await _repository.deleteExpense(id);
    await fetchExpenses();
  }

  void addOrReplaceRecord(ExpenseRecord record) {
    final updated = List<ExpenseRecord>.from(state.records);
    final existingIndex = updated.indexWhere((item) => item.id == record.id);
    if (existingIndex == -1) {
      updated.insert(0, record);
    } else {
      updated[existingIndex] = record;
    }
    state = state.copyWith(records: updated);
  }

  Future<void> sort(String field, bool ascending) {
    return fetchExpenses(
      state.query.copyWith(page: 1, sortBy: field, sortAscending: ascending),
    );
  }

  Future<void> setPage(int page) {
    return fetchExpenses(state.query.copyWith(page: page));
  }

  Future<void> setPageSize(int pageSize) {
    return fetchExpenses(state.query.copyWith(page: 1, limit: pageSize));
  }

  int _normalizePage({required int requestedPage, required int totalPages}) {
    if (totalPages < 1) {
      return 1;
    }
    if (requestedPage < 1) {
      return 1;
    }
    if (requestedPage > totalPages) {
      return totalPages;
    }
    return requestedPage;
  }
}

final expensesProvider = StateNotifierProvider<ExpensesNotifier, ExpensesState>(
  (ref) {
    return ExpensesNotifier(ref.read(expensesRepositoryProvider));
  },
);

final expenseDetailsProvider = FutureProvider.family<ExpenseRecord?, String>((
  ref,
  id,
) async {
  return ref.read(expensesRepositoryProvider).getExpenseById(id);
});

final expenseHistoryProvider =
    FutureProvider.family<List<ExpenseHistoryEntryModel>, String>((ref, id) {
      return ref.read(expensesRepositoryProvider).getExpenseHistory(id);
    });

final expenseJournalProvider =
    FutureProvider.family<List<ExpenseJournalEntryModel>, String>((ref, id) {
      return ref.read(expensesRepositoryProvider).getExpenseJournal(id);
    });

final expenseAttachmentsProvider =
    FutureProvider.family<List<ExpenseAttachmentModel>, String>((ref, id) {
      return ref.read(expensesRepositoryProvider).getExpenseAttachments(id);
    });

final createExpenseProvider =
    FutureProvider.family<ExpenseRecord, UpsertExpenseRequest>((ref, request) {
      return ref.read(expensesRepositoryProvider).createExpense(request);
    });

final updateExpenseProvider =
    FutureProvider.family<ExpenseRecord?, UpdateExpenseRequest>((ref, request) {
      return ref.read(expensesRepositoryProvider).updateExpense(request);
    });

final expensesExpenseAccountsProvider =
    FutureProvider<List<ExpenseAccountLookupModel>>((ref) async {
      return ref.watch(recurringExpenseAccountsSearchProvider('').future);
    });

final expensesVendorsProvider = FutureProvider<List<VendorLookupModel>>((
  ref,
) async {
  return ref.watch(recurringExpenseVendorsProvider.future);
});

final expensesCustomersProvider = FutureProvider<List<CustomerLookupModel>>((
  ref,
) async {
  return ref.watch(recurringExpenseCustomersProvider.future);
});

final expensesCurrenciesProvider = FutureProvider<List<CurrencyLookupModel>>((
  ref,
) async {
  return ref.watch(recurringExpenseCurrenciesProvider.future);
});

final expensesGstTreatmentsProvider =
    FutureProvider<List<GstTreatmentLookupModel>>((ref) async {
      return ref.watch(recurringExpenseGstTreatmentsProvider.future);
    });

final expensesStatesProvider =
    FutureProvider.family<List<StateLookupModel>, String>((ref, countryCode) {
      return ref.watch(recurringExpenseStatesProvider(countryCode).future);
    });

final expensesTaxesProvider = FutureProvider<List<RecurringExpenseTaxOption>>((
  ref,
) async {
  return ref.read(expensesApiServiceProvider).getTaxRates();
});
