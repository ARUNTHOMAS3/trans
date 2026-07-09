class ExpenseItemModel {
  const ExpenseItemModel({
    required this.id,
    required this.expenseAccountId,
    required this.amount,
    this.lineNo,
    this.notes,
    this.taxId,
    this.taxAmount = 0,
    this.expenseAccountName,
  });

  final String id;
  final int? lineNo;
  final String expenseAccountId;
  final String? expenseAccountName;
  final String? notes;
  final String? taxId;
  final double taxAmount;
  final double amount;

  factory ExpenseItemModel.fromJson(Map<String, dynamic> json) {
    return ExpenseItemModel(
      id: (json['id'] ?? '').toString(),
      lineNo: (json['line_no'] as num?)?.toInt() ??
          int.tryParse((json['line_no'] ?? '').toString()),
      expenseAccountId:
          (json['expense_account_id'] ?? json['expenseAccountId'] ?? '')
              .toString(),
      expenseAccountName:
          (json['expense_account_name'] ?? json['expenseAccountName'])
              ?.toString(),
      notes: json['notes']?.toString(),
      taxId: (json['tax_id'] ?? json['taxId'])?.toString(),
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ??
          double.tryParse((json['tax_amount'] ?? '0').toString()) ??
          0,
      amount: (json['amount'] as num?)?.toDouble() ??
          double.tryParse((json['amount'] ?? '0').toString()) ??
          0,
    );
  }

  Map<String, dynamic> toRequestJson() => <String, dynamic>{
        if (id.isNotEmpty) 'id': id,
        if (lineNo != null) 'line_no': lineNo,
        'expense_account_id': expenseAccountId,
        if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
        if (taxId != null && taxId!.trim().isNotEmpty) 'tax_id': taxId,
        'tax_amount': taxAmount,
        'amount': amount,
      };
}
