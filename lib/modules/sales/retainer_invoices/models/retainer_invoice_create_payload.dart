class RetainerInvoiceCreateItemPayload {
  const RetainerInvoiceCreateItemPayload({
    required this.description,
    required this.amount,
    required this.lineNo,
  });

  final String description;
  final double amount;
  final int lineNo;

  Map<String, dynamic> toJson() => {
    'description': description,
    'amount': amount,
    'lineNo': lineNo,
  };
}

class RetainerInvoiceCreatePayload {
  const RetainerInvoiceCreatePayload({
    required this.customerId,
    required this.retainerInvoiceNumber,
    required this.retainerInvoiceDate,
    required this.subtotal,
    required this.roundOff,
    required this.totalAmount,
    required this.balanceAmount,
    required this.status,
    required this.items,
    this.referenceNumber,
    this.transactionSeriesId,
    this.customerNotes,
    this.termsConditions,
    this.amountReceived = 0,
    this.amountApplied = 0,
  });

  final String customerId;
  final String retainerInvoiceNumber;
  final String retainerInvoiceDate;
  final double subtotal;
  final double roundOff;
  final double totalAmount;
  final double amountReceived;
  final double amountApplied;
  final double balanceAmount;
  final String status;
  final List<RetainerInvoiceCreateItemPayload> items;
  final String? referenceNumber;
  final String? transactionSeriesId;
  final String? customerNotes;
  final String? termsConditions;

  Map<String, dynamic> toJson() => {
    'customerId': customerId,
    'transactionSeriesId': transactionSeriesId,
    'retainerInvoiceNumber': retainerInvoiceNumber,
    'referenceNumber': referenceNumber,
    'retainerInvoiceDate': retainerInvoiceDate,
    'customerNotes': customerNotes,
    'termsConditions': termsConditions,
    'subtotal': subtotal,
    'roundOff': roundOff,
    'totalAmount': totalAmount,
    'amountReceived': amountReceived,
    'amountApplied': amountApplied,
    'balanceAmount': balanceAmount,
    'status': status,
    'items': items.map((item) => item.toJson()).toList(),
  };
}
