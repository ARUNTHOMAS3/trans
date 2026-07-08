class PaymentRecord {
  /// Backend `payments_received.id` (uuid). Null for mock/seed rows that have
  /// not been persisted; required to route an edit through the update endpoint.
  final String? id;
  final String date;
  final String paymentNo;
  final String reference;
  final String customer;
  final String invoiceNo;
  final String mode;
  final double amount;
  final double unusedAmount;
  final String status;
  final String location;
  final bool isSelected;
  final List<String> attachments;

  /// Backend `payment_type`: `INVOICE_PAYMENT` or `CUSTOMER_ADVANCE`. Null for
  /// local/seed rows; drives which edit page the overview opens.
  final String? paymentType;

  const PaymentRecord({
    this.id,
    required this.date,
    required this.paymentNo,
    required this.reference,
    required this.customer,
    required this.invoiceNo,
    required this.mode,
    required this.amount,
    required this.unusedAmount,
    this.status = 'PAID',
    this.location = 'ZABNIX PRIVATE LIMITED',
    this.isSelected = false,
    this.attachments = const [],
    this.paymentType,
  });

  /// Maps a backend `payments_received` row (snake_case) to a [PaymentRecord].
  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) =>
        v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

    // payment_date arrives as 'YYYY-MM-DD'; display as 'dd-MM-yyyy'.
    String displayDate(dynamic raw) {
      final s = (raw ?? '').toString();
      final parts = s.split('T').first.split('-');
      if (parts.length == 3) return '${parts[2]}-${parts[1]}-${parts[0]}';
      return s;
    }

    final amount = toDouble(json['amount_received']);
    final excess = toDouble(json['excess_amount']);
    final rawStatus = (json['status'] ?? 'draft').toString();

    return PaymentRecord(
      id: json['id']?.toString(),
      date: displayDate(json['payment_date']),
      paymentNo: (json['payment_number'] ?? '').toString(),
      reference: (json['reference_number'] ?? '').toString(),
      customer: (json['customer_name'] ?? '').toString(),
      invoiceNo: '',
      mode: (json['payment_mode'] ?? '').toString(),
      amount: amount,
      unusedAmount: excess,
      status: rawStatus.toUpperCase(),
      location: (json['location_name'] ?? 'ZABNIX PRIVATE LIMITED').toString(),
      paymentType: json['payment_type']?.toString(),
    );
  }

  PaymentRecord copyWith({
    String? id,
    String? date,
    String? paymentNo,
    String? reference,
    String? customer,
    String? invoiceNo,
    String? mode,
    double? amount,
    double? unusedAmount,
    String? status,
    String? location,
    bool? isSelected,
    List<String>? attachments,
    String? paymentType,
  }) {
    return PaymentRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      paymentNo: paymentNo ?? this.paymentNo,
      reference: reference ?? this.reference,
      customer: customer ?? this.customer,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      mode: mode ?? this.mode,
      amount: amount ?? this.amount,
      unusedAmount: unusedAmount ?? this.unusedAmount,
      status: status ?? this.status,
      location: location ?? this.location,
      isSelected: isSelected ?? this.isSelected,
      attachments: attachments ?? this.attachments,
      paymentType: paymentType ?? this.paymentType,
    );
  }
}
