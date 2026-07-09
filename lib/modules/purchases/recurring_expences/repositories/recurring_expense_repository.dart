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

abstract class RecurringExpenseRepository {
  Future<RecurringExpenseResponse> getRecurringExpenses(
    RecurringExpenseRequest request,
  );

  Future<RecurringExpenseDetails?> getRecurringExpenseById(String id);

  Future<List<RecurringExpenseAuditHistoryEntry>> getRecurringExpenseHistory(
    String id,
  );

  Future<List<RecurringExpenseRun>> getRecurringExpenseRuns(String id);

  Future<List<Map<String, dynamic>>> getRelatedExpenses(String id);

  Future<List<RecurringExpenseReceipt>> getReceipts(String recurringExpenseId);

  Future<RecurringExpenseReceipt> uploadReceipt({
    required String recurringExpenseId,
    required Object formData,
  });

  Future<bool> deleteReceipt({
    required String recurringExpenseId,
    required String receiptId,
  });

  Future<RecurringExpenseDetails> createRecurringExpense(
    CreateRecurringExpenseRequest request,
  );

  Future<RecurringExpenseDetails?> updateRecurringExpense(
    UpdateRecurringExpenseRequest request,
  );

  Future<bool> deleteRecurringExpense(String id);

  Future<bool> deleteRecurringExpensesBulk(List<String> ids);

  Future<BulkUpdateRecurringExpenseResponse> bulkUpdateRecurringExpenses(
    BulkUpdateRecurringExpenseRequest request,
  );

  Future<bool> stopRecurringExpense(String id);

  Future<bool> startRecurringExpense(String id);

  Future<bool> createExpenseFromRecurring(String id);

  Future<List<ExpenseAccountLookupModel>> getExpenseAccounts({
    String? search,
    int? page,
    int? limit,
  });

  Future<List<VendorLookupModel>> getVendors({
    String? search,
    int? page,
    int? limit,
  });

  Future<List<CustomerLookupModel>> getCustomers({
    String? search,
    int? page,
    int? limit,
  });

  Future<List<CurrencyLookupModel>> getCurrencies();

  Future<List<GstTreatmentLookupModel>> getGstTreatments();

  Future<List<StateLookupModel>> getStates({String countryCode = 'IN'});

  Future<List<RecurringExpenseTaxOption>> getTaxes();
}
