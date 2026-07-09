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
import '../services/recurring_expense_api_service.dart';
import 'recurring_expense_repository.dart';

class RecurringExpenseRepositoryImpl implements RecurringExpenseRepository {
  final RecurringExpenseApiService _apiService;

  RecurringExpenseRepositoryImpl(this._apiService);

  @override
  Future<RecurringExpenseResponse> getRecurringExpenses(
    RecurringExpenseRequest request,
  ) => _apiService.getRecurringExpenses(request);

  @override
  Future<RecurringExpenseDetails?> getRecurringExpenseById(String id) =>
      _apiService.getRecurringExpenseById(id);

  @override
  Future<List<RecurringExpenseAuditHistoryEntry>> getRecurringExpenseHistory(
    String id,
  ) => _apiService.getRecurringExpenseHistory(id);

  @override
  Future<List<RecurringExpenseRun>> getRecurringExpenseRuns(String id) =>
      _apiService.getRecurringExpenseRuns(id);

  @override
  Future<List<Map<String, dynamic>>> getRelatedExpenses(String id) =>
      _apiService.getRelatedExpenses(id);

  @override
  Future<List<RecurringExpenseReceipt>> getReceipts(
    String recurringExpenseId,
  ) => _apiService.getReceipts(recurringExpenseId);

  @override
  Future<RecurringExpenseReceipt> uploadReceipt({
    required String recurringExpenseId,
    required Object formData,
  }) => _apiService.uploadReceipt(
    recurringExpenseId: recurringExpenseId,
    formData: formData,
  );

  @override
  Future<bool> deleteReceipt({
    required String recurringExpenseId,
    required String receiptId,
  }) => _apiService.deleteReceipt(
    recurringExpenseId: recurringExpenseId,
    receiptId: receiptId,
  );

  @override
  Future<RecurringExpenseDetails> createRecurringExpense(
    CreateRecurringExpenseRequest request,
  ) => _apiService.createRecurringExpense(request);

  @override
  Future<RecurringExpenseDetails?> updateRecurringExpense(
    UpdateRecurringExpenseRequest request,
  ) => _apiService.updateRecurringExpense(request);

  @override
  Future<bool> deleteRecurringExpense(String id) =>
      _apiService.deleteRecurringExpense(id);

  @override
  Future<bool> deleteRecurringExpensesBulk(List<String> ids) =>
      _apiService.deleteRecurringExpensesBulk(ids);

  @override
  Future<BulkUpdateRecurringExpenseResponse> bulkUpdateRecurringExpenses(
    BulkUpdateRecurringExpenseRequest request,
  ) => _apiService.bulkUpdateRecurringExpenses(request);

  @override
  Future<bool> stopRecurringExpense(String id) =>
      _apiService.stopRecurringExpense(id);

  @override
  Future<bool> startRecurringExpense(String id) =>
      _apiService.startRecurringExpense(id);

  @override
  Future<bool> createExpenseFromRecurring(String id) =>
      _apiService.createExpenseFromRecurring(id);

  @override
  Future<List<ExpenseAccountLookupModel>> getExpenseAccounts({
    String? search,
    int? page,
    int? limit,
  }) =>
      _apiService.getExpenseAccounts(search: search, page: page, limit: limit);

  @override
  Future<List<VendorLookupModel>> getVendors({
    String? search,
    int? page,
    int? limit,
  }) => _apiService.getVendors(search: search, page: page, limit: limit);

  @override
  Future<List<CustomerLookupModel>> getCustomers({
    String? search,
    int? page,
    int? limit,
  }) => _apiService.getCustomers(search: search, page: page, limit: limit);

  @override
  Future<List<CurrencyLookupModel>> getCurrencies() =>
      _apiService.getCurrencies();

  @override
  Future<List<GstTreatmentLookupModel>> getGstTreatments() =>
      _apiService.getGstTreatments();

  @override
  Future<List<StateLookupModel>> getStates({String countryCode = 'IN'}) =>
      _apiService.getStates(countryCode: countryCode);

  @override
  Future<List<RecurringExpenseTaxOption>> getTaxes() => _apiService.getTaxes();
}
