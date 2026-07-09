import 'create_recurring_expense_request.dart';

class UpdateRecurringExpenseRequest {
  final String id;
  final CreateRecurringExpenseRequest recurringExpense;

  const UpdateRecurringExpenseRequest({
    required this.id,
    required this.recurringExpense,
  });

  Map<String, dynamic> toJson() => recurringExpense.toJson();

  UpdateRecurringExpenseRequest copyWith({
    String? id,
    CreateRecurringExpenseRequest? recurringExpense,
  }) {
    return UpdateRecurringExpenseRequest(
      id: id ?? this.id,
      recurringExpense: recurringExpense ?? this.recurringExpense,
    );
  }
}
