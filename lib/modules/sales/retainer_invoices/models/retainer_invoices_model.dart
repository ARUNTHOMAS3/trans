enum RetainerStatus { draft, sent, paid, partiallyPaid, voided, closed }

RetainerStatus retainerStatusFromApi(String? value) {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'draft':
      return RetainerStatus.draft;
    case 'sent':
      return RetainerStatus.sent;
    case 'paid':
      return RetainerStatus.paid;
    case 'partially_paid':
    case 'partially paid':
      return RetainerStatus.partiallyPaid;
    case 'void':
    case 'voided':
      return RetainerStatus.voided;
    case 'closed':
      return RetainerStatus.closed;
    default:
      return RetainerStatus.draft;
  }
}

extension RetainerStatusLabel on RetainerStatus {
  String get label {
    switch (this) {
      case RetainerStatus.draft:
        return 'Draft';
      case RetainerStatus.sent:
        return 'Sent';
      case RetainerStatus.paid:
        return 'Paid';
      case RetainerStatus.partiallyPaid:
        return 'Partially Paid';
      case RetainerStatus.voided:
        return 'Void';
      case RetainerStatus.closed:
        return 'Closed';
    }
  }

  String get apiValue {
    switch (this) {
      case RetainerStatus.draft:
        return 'draft';
      case RetainerStatus.sent:
        return 'sent';
      case RetainerStatus.paid:
        return 'paid';
      case RetainerStatus.partiallyPaid:
        return 'partially_paid';
      case RetainerStatus.voided:
        return 'voided';
      case RetainerStatus.closed:
        return 'closed';
    }
  }
}

class RetainerInvoice {
  const RetainerInvoice({
    required this.id,
    required this.invoiceNo,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.taxLabel,
    required this.taxRate,
    required this.amountUsed,
    required this.status,
    this.referenceNo,
    this.customerEmail,
    this.location,
    this.notes = '',
    this.termsAndConditions = '',
  });

  factory RetainerInvoice.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'];
    final customerMap = customer is Map ? Map<String, dynamic>.from(customer) : null;
    final totalAmount = (json['total_amount'] as num?)?.toDouble() ?? 0;
    final amountApplied = (json['amount_applied'] as num?)?.toDouble() ?? 0;
    final amountReceived = (json['amount_received'] as num?)?.toDouble() ?? 0;

    return RetainerInvoice(
      id: json['id']?.toString() ?? '',
      invoiceNo: json['retainer_invoice_number']?.toString() ?? '',
      date: DateTime.tryParse(json['retainer_invoice_date']?.toString() ?? '') ??
          DateTime.now(),
      customerId: json['customer_id']?.toString() ?? '',
      customerName:
          customerMap?['display_name']?.toString() ??
          json['customer_name']?.toString() ??
          '',
      totalAmount: totalAmount,
      taxLabel: 'None',
      taxRate: 0,
      amountUsed: amountApplied > 0 ? amountApplied : amountReceived,
      status: retainerStatusFromApi(json['status']?.toString()),
      referenceNo: json['reference_number']?.toString(),
      customerEmail: customerMap?['email']?.toString(),
      location: json['location']?.toString(),
      notes: json['customer_notes']?.toString() ?? '',
      termsAndConditions: json['terms_conditions']?.toString() ?? '',
    );
  }

  factory RetainerInvoice.create({
    required String id,
    required String invoiceNo,
    required DateTime date,
    required String customerId,
    required String customerName,
    required double amount,
    required String taxLabel,
    required double taxRate,
    required double amountUsed,
    required RetainerStatus status,
    String? referenceNo,
    String? customerEmail,
    String? location,
    String notes = '',
    String termsAndConditions = '',
  }) {
    return RetainerInvoice(
      id: id,
      invoiceNo: invoiceNo,
      date: date,
      customerId: customerId,
      customerName: customerName,
      totalAmount: amount,
      taxLabel: taxLabel,
      taxRate: taxRate,
      amountUsed: amountUsed,
      status: status,
      referenceNo: referenceNo,
      customerEmail: customerEmail,
      location: location,
      notes: notes,
      termsAndConditions: termsAndConditions,
    );
  }

  final String id;
  final String invoiceNo;
  final DateTime date;
  final String customerId;
  final String customerName;
  final double totalAmount;
  final String taxLabel;
  final double taxRate;
  final double amountUsed;
  final RetainerStatus status;
  final String? referenceNo;
  final String? customerEmail;
  final String? location;
  final String notes;
  final String termsAndConditions;

  double get amount => totalAmount;
  double get amountRemaining => (totalAmount - amountUsed).clamp(0.0, double.infinity);

  RetainerInvoice copyWith({
    String? id,
    String? invoiceNo,
    DateTime? date,
    String? customerId,
    String? customerName,
    double? totalAmount,
    String? taxLabel,
    double? taxRate,
    double? amountUsed,
    RetainerStatus? status,
    Object? referenceNo = _sentinel,
    Object? customerEmail = _sentinel,
    Object? location = _sentinel,
    String? notes,
    String? termsAndConditions,
  }) {
    return RetainerInvoice(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      date: date ?? this.date,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      taxLabel: taxLabel ?? this.taxLabel,
      taxRate: taxRate ?? this.taxRate,
      amountUsed: amountUsed ?? this.amountUsed,
      status: status ?? this.status,
      referenceNo: identical(referenceNo, _sentinel)
          ? this.referenceNo
          : referenceNo as String?,
      customerEmail: identical(customerEmail, _sentinel)
          ? this.customerEmail
          : customerEmail as String?,
      location: identical(location, _sentinel) ? this.location : location as String?,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
    );
  }
}

const Object _sentinel = Object();
