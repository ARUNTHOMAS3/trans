enum RecurringStatus {
  draft,
  active,
  stopped,
  expired;

  String get label {
    switch (this) {
      case RecurringStatus.draft:
        return 'Draft';
      case RecurringStatus.active:
        return 'Active';
      case RecurringStatus.stopped:
        return 'Stopped';
      case RecurringStatus.expired:
        return 'Expired';
    }
  }

  static RecurringStatus fromLabel(String label) {
    switch (label.toLowerCase().trim()) {
      case 'active':
        return RecurringStatus.active;
      case 'stopped':
        return RecurringStatus.stopped;
      case 'expired':
        return RecurringStatus.expired;
      case 'draft':
      default:
        return RecurringStatus.draft;
    }
  }
}

class RecurringInvoice {
  final String id;
  final String profileName;
  final String customerName;
  final String billingFrequency;
  final double amount;
  final RecurringStatus status;
  final DateTime? nextInvoiceDate;

  const RecurringInvoice({
    required this.id,
    required this.profileName,
    required this.customerName,
    required this.billingFrequency,
    required this.amount,
    required this.status,
    this.nextInvoiceDate,
  });

  RecurringInvoice copyWith({
    String? id,
    String? profileName,
    String? customerName,
    String? billingFrequency,
    double? amount,
    RecurringStatus? status,
    DateTime? nextInvoiceDate,
  }) {
    return RecurringInvoice(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      customerName: customerName ?? this.customerName,
      billingFrequency: billingFrequency ?? this.billingFrequency,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      nextInvoiceDate: nextInvoiceDate ?? this.nextInvoiceDate,
    );
  }
}
