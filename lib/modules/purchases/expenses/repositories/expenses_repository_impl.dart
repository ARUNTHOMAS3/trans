import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_attachment_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_employee_option.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_history_entry_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_journal_entry_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_record.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_request_models.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expenses_list_query.dart';
import 'package:zerpai_erp/modules/purchases/expenses/repositories/expenses_repository.dart';
import 'package:zerpai_erp/modules/purchases/expenses/services/expenses_api_service.dart';

class ExpensesRepositoryImpl implements ExpensesRepository {
  ExpensesRepositoryImpl(this._apiService);

  final ExpensesApiService _apiService;

  @override
  Future<ExpensesListResponse> getExpenses(ExpensesListQuery query) async {
    return _apiService.getExpenses(query);
  }

  @override
  Future<List<ExpenseEmployeeOption>> getEmployees() {
    return _apiService.getEmployees();
  }

  @override
  Future<ExpenseRecord?> getExpenseById(String id) {
    return _apiService.getExpenseById(id);
  }

  @override
  Future<List<ExpenseHistoryEntryModel>> getExpenseHistory(String id) {
    return _apiService.getExpenseHistory(id);
  }

  @override
  Future<List<ExpenseJournalEntryModel>> getExpenseJournal(String id) {
    return _apiService.getExpenseJournal(id);
  }

  @override
  Future<List<ExpenseAttachmentModel>> getExpenseAttachments(String id) {
    return _apiService.getExpenseAttachments(id);
  }

  @override
  Future<ExpenseRecord> createExpense(UpsertExpenseRequest request) {
    return _apiService.createExpense(request);
  }

  @override
  Future<ExpenseRecord?> updateExpense(UpdateExpenseRequest request) {
    return _apiService.updateExpense(request);
  }

  @override
  Future<bool> deleteExpense(String id) {
    return _apiService.deleteExpense(id);
  }

  @override
  Future<List<ExpenseAttachmentModel>> uploadReceiptFiles({
    required String expenseId,
    required List<PlatformFile> files,
  }) {
    return _apiService.uploadReceiptFiles(expenseId: expenseId, files: files);
  }

  @override
  Future<bool> deleteAttachment({
    required String expenseId,
    required String attachmentId,
  }) {
    return _apiService.deleteAttachment(
      expenseId: expenseId,
      attachmentId: attachmentId,
    );
  }
}
