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
  final String location;
  final DateTime? lastInvoiceDate;
  final DateTime? endDate;
  final String salespersonName;

  const RecurringInvoice({
    required this.id,
    required this.profileName,
    required this.customerName,
    required this.billingFrequency,
    required this.amount,
    required this.status,
    this.nextInvoiceDate,
    this.location = '',
    this.lastInvoiceDate,
    this.endDate,
    this.salespersonName = '',
  });

  factory RecurringInvoice.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return RecurringInvoice(
      id: (json['id'] ?? '').toString(),
      profileName: (json['profileName'] ?? json['profile_name'] ?? '').toString(),
      customerName:
          (json['customerName'] ?? json['customer_name'] ?? '').toString(),
      billingFrequency:
          (json['billingFrequency'] ?? json['billing_frequency'] ?? '')
              .toString(),
      amount: (json['amount'] as num?)?.toDouble() ??
          (json['total'] as num?)?.toDouble() ??
          (json['sub_total'] as num?)?.toDouble() ??
          0,
      status: RecurringStatus.fromLabel(
        (json['status'] ?? 'Draft').toString(),
      ),
      nextInvoiceDate: parseDate(
        json['nextInvoiceDate'] ?? json['next_invoice_date'],
      ),
      location: (json['location'] ?? '').toString(),
      lastInvoiceDate: parseDate(
        json['lastInvoiceDate'] ??
            json['last_invoice_date'] ??
            json['last_generated_date'] ??
            json['updated_at'],
      ),
      endDate: parseDate(json['endDate'] ?? json['end_date']),
      salespersonName:
          (json['salespersonName'] ?? json['salesperson_name'] ?? '')
              .toString(),
    );
  }

  RecurringInvoice copyWith({
    String? id,
    String? profileName,
    String? customerName,
    String? billingFrequency,
    double? amount,
    RecurringStatus? status,
    DateTime? nextInvoiceDate,
    String? location,
    DateTime? lastInvoiceDate,
    DateTime? endDate,
    String? salespersonName,
  }) {
    return RecurringInvoice(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      customerName: customerName ?? this.customerName,
      billingFrequency: billingFrequency ?? this.billingFrequency,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      nextInvoiceDate: nextInvoiceDate ?? this.nextInvoiceDate,
      location: location ?? this.location,
      lastInvoiceDate: lastInvoiceDate ?? this.lastInvoiceDate,
      endDate: endDate ?? this.endDate,
      salespersonName: salespersonName ?? this.salespersonName,
    );
  }
}
