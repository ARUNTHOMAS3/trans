/// Status lifecycle for a Retainer Invoice.
enum RetainerStatus {
  draft,
  sent,
  paid,
  partiallyPaid,
  closed,
  voided;

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
      case RetainerStatus.closed:
        return 'Closed';
      case RetainerStatus.voided:
        return 'Void';
    }
  }

  static RetainerStatus fromLabel(String label) {
    switch (label.toLowerCase().trim()) {
      case 'sent':
        return RetainerStatus.sent;
      case 'paid':
        return RetainerStatus.paid;
      case 'partially paid':
        return RetainerStatus.partiallyPaid;
      case 'closed':
        return RetainerStatus.closed;
      case 'void':
      case 'voided':
        return RetainerStatus.voided;
      case 'draft':
      default:
        return RetainerStatus.draft;
    }
  }
}

/// Records which sales invoice has consumed part of this retainer.
class RetainerPaymentApplication {
  final String salesInvoiceNo;
  final double amountApplied;
  final DateTime appliedOn;

  const RetainerPaymentApplication({
    required this.salesInvoiceNo,
    required this.amountApplied,
    required this.appliedOn,
  });

  RetainerPaymentApplication copyWith({
    String? salesInvoiceNo,
    double? amountApplied,
    DateTime? appliedOn,
  }) {
    return RetainerPaymentApplication(
      salesInvoiceNo: salesInvoiceNo ?? this.salesInvoiceNo,
      amountApplied: amountApplied ?? this.amountApplied,
      appliedOn: appliedOn ?? this.appliedOn,
    );
  }
}

/// Full ERP-grade Retainer Invoice model.
class RetainerInvoice {
  final String id;
  final String invoiceNo;
  final DateTime date;
  final DateTime? expiryDate;

  // Customer
  final String customerId;
  final String customerName;
  final String? customerEmail;

  // Financial
  final double amount; // Sub-amount (before tax)
  final String taxLabel; // e.g. "GST 18%"
  final double taxRate; // 0.0 – 1.0
  final double taxAmount; // amount * taxRate
  final double totalAmount; // amount + taxAmount

  // Usage tracking
  final double amountUsed;
  double get amountRemaining => totalAmount - amountUsed;

  // Payment
  final String? paymentMode;
  final String? referenceNo;
  final String? location;

  // Status
  final RetainerStatus status;

  // Content
  final String notes;
  final String termsAndConditions;
  final List<String> attachmentPaths;

  // Applied invoices
  final List<RetainerPaymentApplication> applications;

  const RetainerInvoice({
    required this.id,
    required this.invoiceNo,
    required this.date,
    this.expiryDate,
    required this.customerId,
    required this.customerName,
    this.customerEmail,
    required this.amount,
    this.taxLabel = 'None',
    this.taxRate = 0.0,
    required this.taxAmount,
    required this.totalAmount,
    this.amountUsed = 0.0,
    this.paymentMode,
    this.referenceNo,
    this.location,
    required this.status,
    this.notes = '',
    this.termsAndConditions = '',
    this.attachmentPaths = const [],
    this.applications = const [],
  });

  /// Convenience factory — computes tax and total automatically.
  factory RetainerInvoice.create({
    required String id,
    required String invoiceNo,
    required DateTime date,
    DateTime? expiryDate,
    required String customerId,
    required String customerName,
    String? customerEmail,
    required double amount,
    String taxLabel = 'None',
    double taxRate = 0.0,
    double amountUsed = 0.0,
    String? paymentMode,
    String? referenceNo,
    String? location,
    required RetainerStatus status,
    String notes = '',
    String termsAndConditions = '',
    List<String> attachmentPaths = const [],
    List<RetainerPaymentApplication> applications = const [],
  }) {
    final taxAmount = amount * taxRate;
    return RetainerInvoice(
      id: id,
      invoiceNo: invoiceNo,
      date: date,
      expiryDate: expiryDate,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      amount: amount,
      taxLabel: taxLabel,
      taxRate: taxRate,
      taxAmount: taxAmount,
      totalAmount: amount + taxAmount,
      amountUsed: amountUsed,
      paymentMode: paymentMode,
      referenceNo: referenceNo,
      location: location,
      status: status,
      notes: notes,
      termsAndConditions: termsAndConditions,
      attachmentPaths: attachmentPaths,
      applications: applications,
    );
  }

  RetainerInvoice copyWith({
    String? id,
    String? invoiceNo,
    DateTime? date,
    DateTime? expiryDate,
    String? customerId,
    String? customerName,
    String? customerEmail,
    double? amount,
    String? taxLabel,
    double? taxRate,
    double? taxAmount,
    double? totalAmount,
    double? amountUsed,
    String? paymentMode,
    String? referenceNo,
    String? location,
    RetainerStatus? status,
    String? notes,
    String? termsAndConditions,
    List<String>? attachmentPaths,
    List<RetainerPaymentApplication>? applications,
  }) {
    return RetainerInvoice(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      date: date ?? this.date,
      expiryDate: expiryDate ?? this.expiryDate,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      amount: amount ?? this.amount,
      taxLabel: taxLabel ?? this.taxLabel,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      amountUsed: amountUsed ?? this.amountUsed,
      paymentMode: paymentMode ?? this.paymentMode,
      referenceNo: referenceNo ?? this.referenceNo,
      location: location ?? this.location,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      applications: applications ?? this.applications,
    );
  }
}
