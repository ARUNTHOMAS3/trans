import 'recurring_expense_enums.dart';

class RecurringExpenseRun {
  final String id;
  final String recurringExpenseId;
  final String? expenseId;
  final String? runDate;
  final double generatedAmount;
  final RunStatus status;
  final String? remarks;
  final String? message;
  final String? performedBy;
  final String? createdAt;

  const RecurringExpenseRun({
    required this.id,
    required this.recurringExpenseId,
    this.expenseId,
    this.runDate,
    required this.generatedAmount,
    required this.status,
    this.remarks,
    this.message,
    this.performedBy,
    this.createdAt,
  });

  factory RecurringExpenseRun.fromJson(Map<String, dynamic> json) {
    String? readFirst(List<String> keys) {
      for (final key in keys) {
        final value = json[key]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
      return null;
    }

    return RecurringExpenseRun(
      id: (json['id'] ?? '').toString(),
      recurringExpenseId: (json['recurring_expense_id'] ?? '').toString(),
      expenseId: json['expense_id']?.toString(),
      runDate: json['run_date']?.toString(),
      generatedAmount:
          (json['generated_amount'] as num?)?.toDouble() ??
          double.tryParse((json['generated_amount'] ?? '0').toString()) ??
          0,
      status: RunStatusX.fromValue(json['status']?.toString()),
      remarks: json['remarks']?.toString(),
      message: readFirst(<String>[
        'message',
        'description',
        'content',
        'action',
      ]),
      performedBy: readFirst(<String>[
        'performed_by',
        'performed_by_name',
        'created_by_name',
        'updated_by_name',
        'user_name',
        'username',
        'created_by',
        'updated_by',
      ]),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'recurring_expense_id': recurringExpenseId,
      if (expenseId != null) 'expense_id': expenseId,
      if (runDate != null) 'run_date': runDate,
      'generated_amount': generatedAmount,
      'status': status.value,
      if (remarks != null) 'remarks': remarks,
      if (message != null) 'message': message,
      if (performedBy != null) 'performed_by': performedBy,
      if (createdAt != null) 'created_at': createdAt,
    };
  }

  RecurringExpenseRun copyWith({
    String? id,
    String? recurringExpenseId,
    String? expenseId,
    String? runDate,
    double? generatedAmount,
    RunStatus? status,
    String? remarks,
    String? message,
    String? performedBy,
    String? createdAt,
  }) {
    return RecurringExpenseRun(
      id: id ?? this.id,
      recurringExpenseId: recurringExpenseId ?? this.recurringExpenseId,
      expenseId: expenseId ?? this.expenseId,
      runDate: runDate ?? this.runDate,
      generatedAmount: generatedAmount ?? this.generatedAmount,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      message: message ?? this.message,
      performedBy: performedBy ?? this.performedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get timestamp => runDate ?? createdAt ?? '';
  String get title {
    final explicitMessage = message?.trim();
    if (explicitMessage != null && explicitMessage.isNotEmpty) {
      return explicitMessage;
    }
    final note = remarks?.trim();
    if (note != null && note.isNotEmpty) {
      return note;
    }
    if (expenseId != null && expenseId!.isNotEmpty) {
      return 'Expense ${status.value}';
    }
    return status.value;
  }

  String get author {
    final actor = performedBy?.trim();
    if (actor != null && actor.isNotEmpty) {
      if (RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      ).hasMatch(actor)) {
        return 'AUTO';
      }
      return actor;
    }
    return 'AUTO';
  }

  String? get action => remarks;
}
