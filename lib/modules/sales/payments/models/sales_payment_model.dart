class SalesPayment {
  final String? id;
  final String customerId;
  final String paymentNumber;
  final DateTime paymentDate;
  final String paymentMode;
  final double amount;
  final double bankCharges;
  final String? reference;
  final String? depositTo;
  final String? notes;
  final String? customerName;

  SalesPayment({
    this.id,
    required this.customerId,
    required this.paymentNumber,
    required this.paymentDate,
    required this.paymentMode,
    required this.amount,
    this.bankCharges = 0,
    this.reference,
    this.depositTo,
    this.notes,
    this.customerName,
  });

  factory SalesPayment.fromJson(Map<String, dynamic> json) {
    return SalesPayment(
      id: json['id'],
      customerId: json['customer_id'],
      paymentNumber: json['payment_number'],
      paymentDate: DateTime.parse(json['payment_date']),
      paymentMode: json['payment_mode'],
      amount: double.parse(json['amount'].toString()),
      bankCharges: double.parse((json['bank_charges'] ?? 0).toString()),
      reference: json['reference'],
      depositTo: json['deposit_to'],
      notes: json['notes'],
      customerName: json['customer'] != null
          ? json['customer']['display_name']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'paymentNumber': paymentNumber,
      'paymentDate': paymentDate.toIso8601String(),
      'paymentMode': paymentMode,
      'amount': amount,
      'bankCharges': bankCharges,
      'reference': reference,
      'depositTo': depositTo,
      'notes': notes,
    };
  }
}
