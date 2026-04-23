class AccountTransaction {
  final String id;
  final String accountId;
  final String? accountName;
  final DateTime transactionDate;
  final String? transactionType;
  final String? referenceNumber;
  final String? description;
  final double debit;
  final double credit;
  final double bcyDebit;
  final double bcyCredit;
  final String? currencyCode;
  final double exchangeRate;
  final String? transactionNumber;
  final String? sourceId;
  final String? sourceType;

  AccountTransaction({
    required this.id,
    required this.accountId,
    this.accountName,
    required this.transactionDate,
    this.transactionType,
    this.transactionNumber,
    this.referenceNumber,
    this.description,
    this.debit = 0.0,
    this.credit = 0.0,
    this.bcyDebit = 0.0,
    this.bcyCredit = 0.0,
    this.currencyCode,
    this.exchangeRate = 1.0,
    this.sourceId,
    this.sourceType,
  });

  factory AccountTransaction.fromJson(Map<String, dynamic> json) {
    return AccountTransaction(
      id: json['id'] ?? '',
      accountId: json['account_id'] ?? '',
      accountName: json['account_name'],
      transactionDate: DateTime.parse(
        json['transaction_date'] ?? DateTime.now().toIso8601String(),
      ),
      transactionType: json['transaction_type'],
      transactionNumber: json['transaction_number'],
      referenceNumber: json['reference_number'],
      description: json['description'],
      debit: (json['debit'] ?? 0.0).toDouble(),
      credit: (json['credit'] ?? 0.0).toDouble(),
      bcyDebit: (json['bcy_debit'] ?? json['debit'] ?? 0.0).toDouble(),
      bcyCredit: (json['bcy_credit'] ?? json['credit'] ?? 0.0).toDouble(),
      currencyCode: json['currency_code'],
      exchangeRate: (json['exchange_rate'] ?? 1.0).toDouble(),
      sourceId: json['source_id'],
      sourceType: json['source_type'],
    );
  }

  double get amount => debit > 0 ? debit : credit;
  double get bcyAmount => bcyDebit > 0 ? bcyDebit : bcyCredit;
}
