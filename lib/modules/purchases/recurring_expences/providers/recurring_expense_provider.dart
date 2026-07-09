import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';
import '../models/bulk_update_recurring_expense_request.dart';
import '../models/bulk_update_recurring_expense_response.dart';
import '../models/create_recurring_expense_request.dart';
import '../models/recurring_expense_audit_history_model.dart';
import '../models/recurring_expense_details_model.dart';
import '../models/recurring_expense_history_model.dart';
import '../models/recurring_expense_receipt_model.dart';
import '../models/recurring_expense_request_model.dart';
import '../models/recurring_expense_response_model.dart';
import '../models/update_recurring_expense_request.dart';
import '../repositories/recurring_expense_repository.dart';
import '../repositories/recurring_expense_repository_impl.dart';
import '../services/recurring_expense_api_service.dart';
import '../notifiers/recurring_expense_notifier.dart';

final recurringExpenseFormNotifierProvider =
    StateNotifierProvider<RecurringExpenseNotifier, RecurringExpenseFormState>((
      ref,
    ) {
      return RecurringExpenseNotifier();
    });

final recurringExpenseApiServiceProvider = Provider<RecurringExpenseApiService>(
  (Ref ref) => RecurringExpenseApiService(ref.read(apiClientProvider)),
);

final recurringExpenseRepositoryProvider = Provider<RecurringExpenseRepository>(
  (Ref ref) => RecurringExpenseRepositoryImpl(
    ref.read(recurringExpenseApiServiceProvider),
  ),
);

final recurringExpensesProvider = FutureProvider.autoDispose
    .family<RecurringExpenseResponse, RecurringExpenseRequest>((
      Ref ref,
      RecurringExpenseRequest request,
    ) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .getRecurringExpenses(request);
    });

final recurringExpenseDetailsProvider =
    FutureProvider.family<RecurringExpenseDetails?, String>((
      Ref ref,
      String id,
    ) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .getRecurringExpenseById(id);
    });

final recurringExpenseHistoryProvider =
    FutureProvider.family<List<RecurringExpenseAuditHistoryEntry>, String>((
      Ref ref,
      String id,
    ) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .getRecurringExpenseHistory(id);
    });

final recurringExpenseRunsProvider =
    FutureProvider.family<List<RecurringExpenseRun>, String>((
      Ref ref,
      String id,
    ) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .getRecurringExpenseRuns(id);
    });

final recurringExpenseRelatedExpensesProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      Ref ref,
      String id,
    ) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .getRelatedExpenses(id);
    });

final recurringExpenseReceiptsProvider =
    FutureProvider.family<List<RecurringExpenseReceipt>, String>((
      Ref ref,
      String id,
    ) async {
      return ref.read(recurringExpenseRepositoryProvider).getReceipts(id);
    });

final createRecurringExpenseProvider =
    FutureProvider.family<
      RecurringExpenseDetails,
      CreateRecurringExpenseRequest
    >((Ref ref, CreateRecurringExpenseRequest request) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .createRecurringExpense(request);
    });

final updateRecurringExpenseProvider =
    FutureProvider.family<
      RecurringExpenseDetails?,
      UpdateRecurringExpenseRequest
    >((Ref ref, UpdateRecurringExpenseRequest request) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .updateRecurringExpense(request);
    });

final deleteRecurringExpenseProvider = FutureProvider.family<bool, String>((
  Ref ref,
  String id,
) async {
  return ref
      .read(recurringExpenseRepositoryProvider)
      .deleteRecurringExpense(id);
});

final deleteRecurringExpensesBulkProvider =
    FutureProvider.family<bool, List<String>>((
      Ref ref,
      List<String> ids,
    ) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .deleteRecurringExpensesBulk(ids);
    });

final bulkUpdateRecurringExpensesProvider =
    FutureProvider.family<
      BulkUpdateRecurringExpenseResponse,
      BulkUpdateRecurringExpenseRequest
    >((Ref ref, BulkUpdateRecurringExpenseRequest request) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .bulkUpdateRecurringExpenses(request);
    });

final stopRecurringExpenseProvider = FutureProvider.family<bool, String>((
  Ref ref,
  String id,
) async {
  return ref.read(recurringExpenseRepositoryProvider).stopRecurringExpense(id);
});

final startRecurringExpenseProvider = FutureProvider.family<bool, String>((
  Ref ref,
  String id,
) async {
  return ref.read(recurringExpenseRepositoryProvider).startRecurringExpense(id);
});

final createExpenseFromRecurringProvider = FutureProvider.family<bool, String>((
  Ref ref,
  String id,
) async {
  return ref
      .read(recurringExpenseRepositoryProvider)
      .createExpenseFromRecurring(id);
});

final recurringExpenseAccountsSearchQueryProvider = StateProvider<String>(
  (Ref ref) => '',
);

final recurringExpenseVendorsSearchQueryProvider = StateProvider<String>(
  (Ref ref) => '',
);

final recurringExpenseCustomersSearchQueryProvider = StateProvider<String>(
  (Ref ref) => '',
);

final recurringExpenseAccountsSearchProvider =
    FutureProvider.family<List<ExpenseAccountLookupModel>, String>((
      Ref ref,
      String search,
    ) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .getExpenseAccounts(
            search: search.trim().isEmpty ? null : search.trim(),
          );
    });

final recurringExpenseVendorsSearchProvider =
    FutureProvider.family<List<VendorLookupModel>, String>((
      Ref ref,
      String search,
    ) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .getVendors(search: search.trim().isEmpty ? null : search.trim());
    });

final recurringExpenseCustomersSearchProvider =
    FutureProvider.family<List<CustomerLookupModel>, String>((
      Ref ref,
      String search,
    ) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .getCustomers(search: search.trim().isEmpty ? null : search.trim());
    });

final recurringExpenseAccountsProvider =
    FutureProvider<List<ExpenseAccountLookupModel>>((Ref ref) async {
      final search = ref.watch(recurringExpenseAccountsSearchQueryProvider);
      return ref.watch(recurringExpenseAccountsSearchProvider(search).future);
    });

final recurringExpenseVendorsProvider = FutureProvider<List<VendorLookupModel>>(
  (Ref ref) async {
    final search = ref.watch(recurringExpenseVendorsSearchQueryProvider);
    return ref.watch(recurringExpenseVendorsSearchProvider(search).future);
  },
);

final recurringExpenseCustomersProvider =
    FutureProvider<List<CustomerLookupModel>>((Ref ref) async {
      final search = ref.watch(recurringExpenseCustomersSearchQueryProvider);
      return ref.watch(recurringExpenseCustomersSearchProvider(search).future);
    });

final recurringExpenseCurrenciesProvider =
    FutureProvider<List<CurrencyLookupModel>>((Ref ref) async {
      return ref.read(recurringExpenseRepositoryProvider).getCurrencies();
    });

final recurringExpenseGstTreatmentsProvider =
    FutureProvider<List<GstTreatmentLookupModel>>((Ref ref) async {
      return ref.read(recurringExpenseRepositoryProvider).getGstTreatments();
    });

final recurringExpenseStatesProvider =
    FutureProvider.family<List<StateLookupModel>, String>((
      Ref ref,
      String countryCode,
    ) async {
      return ref
          .read(recurringExpenseRepositoryProvider)
          .getStates(countryCode: countryCode);
    });

final recurringExpenseTaxesProvider =
    FutureProvider<List<RecurringExpenseTaxOption>>((Ref ref) async {
      return ref.read(recurringExpenseRepositoryProvider).getTaxes();
    });
