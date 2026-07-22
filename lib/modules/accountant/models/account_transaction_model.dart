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

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

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
      debit: _asDouble(json['debit']),
      credit: _asDouble(json['credit']),
      bcyDebit: _asDouble(
        json['bcy_debit'],
        fallback: _asDouble(json['debit']),
      ),
      bcyCredit: _asDouble(
        json['bcy_credit'],
        fallback: _asDouble(json['credit']),
      ),
      currencyCode: json['currency_code'],
      exchangeRate: _asDouble(json['exchange_rate'], fallback: 1.0),
      sourceId: json['source_id'],
      sourceType: json['source_type'],
    );
  }

  double get amount => debit > 0 ? debit : credit;
  double get bcyAmount => bcyDebit > 0 ? bcyDebit : bcyCredit;
}
