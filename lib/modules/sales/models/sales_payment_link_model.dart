class SalesPaymentLink {
  final String? id;
  final String customerId;
  final double amount;
  final String linkNumber;
  final DateTime? expiryDate;
  final String? paymentReason;
  final String status;
  final Map<String, dynamic>? customer;

  SalesPaymentLink({
    this.id,
    required this.customerId,
    required this.amount,
    required this.linkNumber,
    this.expiryDate,
    this.paymentReason,
    this.status = 'active',
    this.customer,
  });

  factory SalesPaymentLink.fromJson(Map<String, dynamic> json) {
    return SalesPaymentLink(
      id: json['id'],
      customerId: json['customer_id'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      linkNumber: json['link_number'],
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      paymentReason: json['payment_reason'],
      status: json['status'] ?? 'active',
      customer: json['customer'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'customerId': customerId,
      'amount': amount,
      'linkNumber': linkNumber,
      if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      'paymentReason': paymentReason,
      'status': status,
    };
  }
}
