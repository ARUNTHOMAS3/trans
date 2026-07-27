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
  final double? bcyDebit;
  final double? bcyCredit;
  final String? currencyCode;
  final String? bcyCurrencyCode;
  final double? exchangeRate;
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
    this.bcyDebit,
    this.bcyCredit,
    this.currencyCode,
    this.bcyCurrencyCode,
    this.exchangeRate,
    this.sourceId,
    this.sourceType,
  });

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  factory AccountTransaction.fromJson(Map<String, dynamic> json) {
    final rawDate = json['transaction_date'];
    final transactionDate = rawDate == null
        ? null
        : DateTime.tryParse(rawDate.toString());
    if (transactionDate == null) {
      throw const FormatException('Transaction date is required');
    }
    return AccountTransaction(
      id: json['id'] ?? '',
      accountId: json['account_id'] ?? '',
      accountName:
          json['account_name'] ??
          json['accountName'] ??
          json['account']?['user_account_name'] ??
          json['account']?['userAccountName'] ??
          json['account']?['system_account_name'] ??
          json['account']?['systemAccountName'] ??
          json['account']?['account_name'] ??
          json['account']?['accountName'],
      transactionDate: transactionDate,
      transactionType: json['transaction_type'] ?? json['source_type'],
      transactionNumber: json['transaction_number'] ?? json['reference_number'],
      referenceNumber: json['reference_number'],
      description: json['description'],
      debit: _asDouble(json['debit']),
      credit: _asDouble(json['credit']),
      bcyDebit: _asNullableDouble(json['bcy_debit']),
      bcyCredit: _asNullableDouble(json['bcy_credit']),
      currencyCode: json['currency_code'],
      bcyCurrencyCode: json['bcy_currency_code'],
      exchangeRate: _asNullableDouble(json['exchange_rate']),
      sourceId: json['source_id'],
      sourceType: json['source_type'],
    );
  }

  double get amount => debit > 0 ? debit : credit;
  double? get bcyAmount {
    if (bcyDebit == null || bcyCredit == null) return null;
    return bcyDebit! > 0 ? bcyDebit : bcyCredit;
  }
}
