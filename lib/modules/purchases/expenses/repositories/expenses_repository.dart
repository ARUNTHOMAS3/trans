import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_attachment_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_employee_option.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_history_entry_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_journal_entry_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_record.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_request_models.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expenses_list_query.dart';
import 'package:zerpai_erp/modules/purchases/expenses/services/expenses_api_service.dart';

abstract class ExpensesRepository {
  Future<ExpensesListResponse> getExpenses(ExpensesListQuery query);
  Future<List<ExpenseEmployeeOption>> getEmployees();
  Future<ExpenseRecord?> getExpenseById(String id);
  Future<List<ExpenseHistoryEntryModel>> getExpenseHistory(String id);
  Future<List<ExpenseJournalEntryModel>> getExpenseJournal(String id);
  Future<List<ExpenseAttachmentModel>> getExpenseAttachments(String id);
  Future<ExpenseRecord> createExpense(UpsertExpenseRequest request);
  Future<ExpenseRecord?> updateExpense(UpdateExpenseRequest request);
  Future<bool> deleteExpense(String id);
  Future<List<ExpenseAttachmentModel>> uploadReceiptFiles({
    required String expenseId,
    required List<PlatformFile> files,
  });
  Future<bool> deleteAttachment({
    required String expenseId,
    required String attachmentId,
  });
}
