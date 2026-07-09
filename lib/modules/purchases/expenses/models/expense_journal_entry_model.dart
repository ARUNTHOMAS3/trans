class ExpenseJournalEntryModel {
  const ExpenseJournalEntryModel({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.transactionDate,
    required this.transactionType,
    required this.referenceNumber,
    required this.description,
    required this.debit,
    required this.credit,
    required this.sourceId,
    required this.sourceType,
    this.createdAt,
  });

  final String id;
  final String accountId;
  final String accountName;
  final String transactionDate;
  final String transactionType;
  final String referenceNumber;
  final String? description;
  final double debit;
  final double credit;
  final String sourceId;
  final String sourceType;
  final String? createdAt;

  factory ExpenseJournalEntryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseJournalEntryModel(
      id: (json['id'] ?? '').toString(),
      accountId: (json['account_id'] ?? json['accountId'] ?? '').toString(),
      accountName: (json['account_name'] ?? json['accountName'] ?? '')
          .toString(),
      transactionDate:
          (json['transaction_date'] ?? json['transactionDate'] ?? '')
              .toString(),
      transactionType:
          (json['transaction_type'] ?? json['transactionType'] ?? '')
              .toString(),
      referenceNumber:
          (json['reference_number'] ?? json['referenceNumber'] ?? '')
              .toString(),
      description: (json['description'] ?? '')?.toString(),
      debit:
          (json['debit'] as num?)?.toDouble() ??
          double.tryParse((json['debit'] ?? '0').toString()) ??
          0,
      credit:
          (json['credit'] as num?)?.toDouble() ??
          double.tryParse((json['credit'] ?? '0').toString()) ??
          0,
      sourceId: (json['source_id'] ?? json['sourceId'] ?? '').toString(),
      sourceType: (json['source_type'] ?? json['sourceType'] ?? '').toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
