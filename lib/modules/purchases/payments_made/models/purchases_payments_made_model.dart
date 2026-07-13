// PATH: lib/modules/purchases/payments_made/models/purchases_payments_made_model.dart

class PaymentMade {
  final String id;
  final String entityId;
  final String vendorId;
  final String? vendorName; // display helper
  final String paymentType;
  final String? transactionSeriesId;
  final String paymentNumber;
  final DateTime paymentDate;
  final double paymentAmount;
  final String? currencyId;
  final double exchangeRate;
  final String paidThroughAccountId;
  final String? depositToAccountId;
  final String? paymentMode;
  final String? referenceNumber;
  final String status;
  final String? notes;
  final double totalAllocated;
  final double totalRefunded;
  final double excessAmount;
  final List<dynamic> billAllocations;
  final Map<String, dynamic>? paymentMadeTax;
  final List<dynamic> paymentMadeAttachments;
  
  // Custom display helpers from mock structure
  final String companyName;
  final List<String> companyAddress;
  final String companyGstin;
  final String companyPhone;
  final String companyEmail;
  final List<String> vendorAddress;
  final String vendorGstin;
  final String placeOfSupply;
  final String amountInWords;

  const PaymentMade({
    required this.id,
    required this.entityId,
    required this.vendorId,
    this.vendorName,
    required this.paymentType,
    this.transactionSeriesId,
    required this.paymentNumber,
    required this.paymentDate,
    required this.paymentAmount,
    this.currencyId,
    this.exchangeRate = 1.0,
    required this.paidThroughAccountId,
    this.depositToAccountId,
    this.paymentMode,
    this.referenceNumber,
    this.status = 'draft',
    this.notes,
    this.totalAllocated = 0.0,
    this.totalRefunded = 0.0,
    this.excessAmount = 0.0,
    this.billAllocations = const [],
    this.paymentMadeTax,
    this.paymentMadeAttachments = const [],
    
    // Default company displays
    this.companyName = 'ZABNIX PRIVATE LIMITED',
    this.companyAddress = const [
      'PERINTHALMANNA',
      'MALAPPURAM Kerala 679322',
      'India',
    ],
    this.companyGstin = '32AACCZ4912F1ZL',
    this.companyPhone = '8086355500',
    this.companyEmail = 'zabnixprivatelimited@gmail.com',
    this.vendorAddress = const [
      '1545, Obeya Brio, Sector 1, 19th Main Road,',
      'HSR Layout',
      'Bengaluru Urban',
      '560102 Karnataka',
      'India',
    ],
    this.vendorGstin = '29AAHCG3435D1ZQ',
    this.placeOfSupply = 'Kerala (32)',
    this.amountInWords = '',
  });

  factory PaymentMade.fromJson(Map<String, dynamic> json) {
    final vendor = json['vendor'] as Map<String, dynamic>? ?? json['vendors'] as Map<String, dynamic>?;
    return PaymentMade(
      id: json['id'] as String? ?? '',
      entityId: json['entity_id'] as String? ?? json['entityId'] as String? ?? '',
      vendorId: json['vendor_id'] as String? ?? json['vendorId'] as String? ?? '',
      vendorName: _firstNonEmptyString([
        vendor?['display_name'],
        vendor?['displayName'],
        vendor?['company_name'],
        vendor?['companyName'],
        vendor?['vendor_name'],
        vendor?['name'],
        json['vendor_name'],
        json['vendorName'],
      ]),
      paymentType: json['payment_type'] as String? ?? json['paymentType'] as String? ?? 'RECORD_PAYMENT',
      transactionSeriesId: json['transaction_series_id'] as String?,
      paymentNumber: json['payment_number'] as String? ?? json['paymentNumber'] as String? ?? '',
      paymentDate: json['payment_date'] != null 
          ? DateTime.parse(json['payment_date'] as String)
          : DateTime.now(),
      paymentAmount: double.tryParse(json['payment_amount']?.toString() ?? json['paymentAmount']?.toString() ?? '0.0') ?? 0.0,
      currencyId: json['currency_id'] as String?,
      exchangeRate: double.tryParse(json['exchange_rate']?.toString() ?? '1.0') ?? 1.0,
      paidThroughAccountId: json['paid_through_account_id'] as String? ?? json['paidThroughAccountId'] as String? ?? '',
      depositToAccountId: json['deposit_to_account_id'] as String? ?? json['depositToAccountId'] as String?,
      paymentMode: json['payment_mode'] as String? ?? json['paymentMode'] as String?,
      referenceNumber: json['reference_number'] as String? ?? json['referenceNumber'] as String?,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      totalAllocated: double.tryParse(json['total_allocated']?.toString() ?? '0.0') ?? 0.0,
      totalRefunded: double.tryParse(json['total_refunded']?.toString() ?? '0.0') ?? 0.0,
      excessAmount: double.tryParse(json['excess_amount']?.toString() ?? '0.0') ?? 0.0,
      paymentMadeAttachments: json['payment_made_attachments'] as List<dynamic>? ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'entity_id': entityId,
      'vendor_id': vendorId,
      'payment_type': paymentType,
      'transaction_series_id': transactionSeriesId,
      'payment_number': paymentNumber,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'payment_amount': paymentAmount,
      'currency_id': currencyId,
      'exchange_rate': exchangeRate,
      'paid_through_account_id': paidThroughAccountId,
      'deposit_to_account_id': depositToAccountId,
      'payment_mode': paymentMode,
      'reference_number': referenceNumber,
      'status': status,
      'notes': notes,
      'total_allocated': totalAllocated,
      'total_refunded': totalRefunded,
      'excess_amount': excessAmount,
      'bill_allocations': billAllocations,
      if (paymentMadeTax != null) 'payment_made_tax': paymentMadeTax,
      'payment_made_attachments': paymentMadeAttachments,
    };
  }
}

String? _firstNonEmptyString(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty) {
      return text;
    }
  }
  return null;
}
