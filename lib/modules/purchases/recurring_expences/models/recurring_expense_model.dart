import 'recurring_expense_enums.dart';

class RecurringExpense {
  final String id;
  final String profileName;
  final String? entityId;
  final int repeatEvery;
  final RecurringRepeatType repeatType;
  final String startDate;
  final String? endDate;
  final bool neverExpires;
  final String? nextRunDate;
  final String? lastRunDate;
  final RecurringExpenseStatus status;
  final String? expenseAccountId;
  final double amount;
  final String currencyCode;
  final String? paidThroughAccountId;
  final ExpenseType expenseType;
  final String? hsnSacCode;
  final String? vendorId;
  final String? gstTreatment;
  final String? sourceOfSupply;
  final String? destinationOfSupply;
  final bool reverseCharge;
  final String? taxId;
  final AmountTaxMode amountTaxMode;
  final String? invoiceNumber;
  final String notes;
  final String? customerId;
  final bool isBillable;
  final String? expenseAccountName;
  final String? paidThroughAccountName;
  final String? vendorNameRaw;
  final String? customerNameRaw;
  final bool autoCreate;
  final String? createdBy;
  final String? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  const RecurringExpense({
    required this.id,
    required this.profileName,
    this.entityId,
    required this.repeatEvery,
    required this.repeatType,
    required this.startDate,
    this.endDate,
    required this.neverExpires,
    this.nextRunDate,
    this.lastRunDate,
    required this.status,
    this.expenseAccountId,
    required this.amount,
    required this.currencyCode,
    this.paidThroughAccountId,
    required this.expenseType,
    this.hsnSacCode,
    this.vendorId,
    this.gstTreatment,
    this.sourceOfSupply,
    this.destinationOfSupply,
    required this.reverseCharge,
    this.taxId,
    required this.amountTaxMode,
    this.invoiceNumber,
    this.notes = '',
    this.customerId,
    this.isBillable = false,
    this.expenseAccountName,
    this.paidThroughAccountName,
    this.vendorNameRaw,
    this.customerNameRaw,
    required this.autoCreate,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  factory RecurringExpense.fromJson(Map<String, dynamic> json) {
    return RecurringExpense(
      id: (json['id'] ?? '').toString(),
      profileName: (json['profile_name'] ?? '').toString(),
      entityId: json['entity_id']?.toString(),
      repeatEvery:
          (json['repeat_every'] as num?)?.toInt() ??
          int.tryParse((json['repeat_every'] ?? '1').toString()) ??
          1,
      repeatType: RecurringRepeatTypeX.fromValue(
        json['repeat_type']?.toString(),
      ),
      startDate: (json['start_date'] ?? '').toString(),
      endDate: json['end_date']?.toString(),
      neverExpires: json['never_expires'] as bool? ?? false,
      nextRunDate: json['next_run_date']?.toString(),
      lastRunDate: json['last_run_date']?.toString(),
      status: RecurringExpenseStatusX.fromValue(json['status']?.toString()),
      expenseAccountId: json['expense_account_id']?.toString(),
      amount:
          (json['amount'] as num?)?.toDouble() ??
          double.tryParse((json['amount'] ?? '0').toString()) ??
          0,
      currencyCode: (json['currency_code'] ?? 'INR').toString(),
      paidThroughAccountId: json['paid_through_account_id']?.toString(),
      expenseType: ExpenseTypeX.fromValue(json['expense_type']?.toString()),
      hsnSacCode: json['hsn_sac_code']?.toString(),
      vendorId: json['vendor_id']?.toString(),
      gstTreatment: json['gst_treatment']?.toString(),
      sourceOfSupply: json['source_of_supply']?.toString(),
      destinationOfSupply: json['destination_of_supply']?.toString(),
      reverseCharge: json['reverse_charge'] as bool? ?? false,
      taxId: json['tax_id']?.toString(),
      amountTaxMode: AmountTaxModeX.fromValue(
        json['amount_tax_mode']?.toString(),
      ),
      invoiceNumber: json['invoice_number']?.toString(),
      notes: (json['notes'] ?? '').toString(),
      customerId: json['customer_id']?.toString(),
      isBillable: json['is_billable'] as bool? ?? false,
      expenseAccountName:
          json['expense_account_name']?.toString() ??
          json['expense_account']?.toString(),
      paidThroughAccountName:
          json['paid_through_account_name']?.toString() ??
          json['paid_through']?.toString(),
      vendorNameRaw:
          json['vendor_name']?.toString() ??
          json['vendor']?['display_name']?.toString() ??
          json['vendor']?['company_name']?.toString(),
      customerNameRaw:
          json['customer_name']?.toString() ??
          json['customer']?['display_name']?.toString() ??
          json['customer']?['company_name']?.toString(),
      autoCreate: json['auto_create'] as bool? ?? true,
      createdBy: json['created_by']?.toString(),
      updatedBy: json['updated_by']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'profile_name': profileName,
      if (entityId != null) 'entity_id': entityId,
      'repeat_every': repeatEvery,
      'repeat_type': repeatType.value,
      'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      'never_expires': neverExpires,
      if (nextRunDate != null) 'next_run_date': nextRunDate,
      if (lastRunDate != null) 'last_run_date': lastRunDate,
      'status': status.value,
      if (expenseAccountId != null) 'expense_account_id': expenseAccountId,
      'amount': amount,
      'currency_code': currencyCode,
      if (paidThroughAccountId != null)
        'paid_through_account_id': paidThroughAccountId,
      'expense_type': expenseType.value,
      if (hsnSacCode != null) 'hsn_sac_code': hsnSacCode,
      if (vendorId != null) 'vendor_id': vendorId,
      if (gstTreatment != null) 'gst_treatment': gstTreatment,
      if (sourceOfSupply != null) 'source_of_supply': sourceOfSupply,
      if (destinationOfSupply != null)
        'destination_of_supply': destinationOfSupply,
      'reverse_charge': reverseCharge,
      if (taxId != null) 'tax_id': taxId,
      'amount_tax_mode': amountTaxMode.value,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      'notes': notes,
      if (customerId != null) 'customer_id': customerId,
      'is_billable': isBillable,
      if (expenseAccountName != null)
        'expense_account_name': expenseAccountName,
      if (paidThroughAccountName != null)
        'paid_through_account_name': paidThroughAccountName,
      if (vendorNameRaw != null) 'vendor_name': vendorNameRaw,
      if (customerNameRaw != null) 'customer_name': customerNameRaw,
      'auto_create': autoCreate,
      if (createdBy != null) 'created_by': createdBy,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    };
  }

  RecurringExpense copyWith({
    String? id,
    String? profileName,
    String? entityId,
    int? repeatEvery,
    RecurringRepeatType? repeatType,
    String? startDate,
    String? endDate,
    bool? neverExpires,
    String? nextRunDate,
    String? lastRunDate,
    RecurringExpenseStatus? status,
    String? expenseAccountId,
    double? amount,
    String? currencyCode,
    String? paidThroughAccountId,
    ExpenseType? expenseType,
    String? hsnSacCode,
    String? vendorId,
    String? gstTreatment,
    String? sourceOfSupply,
    String? destinationOfSupply,
    bool? reverseCharge,
    String? taxId,
    AmountTaxMode? amountTaxMode,
    String? invoiceNumber,
    String? notes,
    String? customerId,
    bool? isBillable,
    String? expenseAccountName,
    String? paidThroughAccountName,
    String? vendorNameRaw,
    String? customerNameRaw,
    bool? autoCreate,
    String? createdBy,
    String? updatedBy,
    String? createdAt,
    String? updatedAt,
  }) {
    return RecurringExpense(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      entityId: entityId ?? this.entityId,
      repeatEvery: repeatEvery ?? this.repeatEvery,
      repeatType: repeatType ?? this.repeatType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      neverExpires: neverExpires ?? this.neverExpires,
      nextRunDate: nextRunDate ?? this.nextRunDate,
      lastRunDate: lastRunDate ?? this.lastRunDate,
      status: status ?? this.status,
      expenseAccountId: expenseAccountId ?? this.expenseAccountId,
      amount: amount ?? this.amount,
      currencyCode: currencyCode ?? this.currencyCode,
      paidThroughAccountId: paidThroughAccountId ?? this.paidThroughAccountId,
      expenseType: expenseType ?? this.expenseType,
      hsnSacCode: hsnSacCode ?? this.hsnSacCode,
      vendorId: vendorId ?? this.vendorId,
      gstTreatment: gstTreatment ?? this.gstTreatment,
      sourceOfSupply: sourceOfSupply ?? this.sourceOfSupply,
      destinationOfSupply: destinationOfSupply ?? this.destinationOfSupply,
      reverseCharge: reverseCharge ?? this.reverseCharge,
      taxId: taxId ?? this.taxId,
      amountTaxMode: amountTaxMode ?? this.amountTaxMode,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      notes: notes ?? this.notes,
      customerId: customerId ?? this.customerId,
      isBillable: isBillable ?? this.isBillable,
      expenseAccountName: expenseAccountName ?? this.expenseAccountName,
      paidThroughAccountName:
          paidThroughAccountName ?? this.paidThroughAccountName,
      vendorNameRaw: vendorNameRaw ?? this.vendorNameRaw,
      customerNameRaw: customerNameRaw ?? this.customerNameRaw,
      autoCreate: autoCreate ?? this.autoCreate,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get name => profileName;
  String get expenseAccount => expenseAccountName ?? expenseAccountId ?? '';
  String get vendorName => vendorNameRaw ?? vendorId ?? '';
  String get customerName => customerNameRaw ?? customerId ?? '';
  String get frequency => repeatEvery == 1
      ? repeatType.displayLabel
      : '$repeatEvery ${repeatType.customUnitLabel}';
  String get lastExpenseDate => lastRunDate ?? '';
  String get nextExpenseDate => nextRunDate ?? '';
  String get paidThrough =>
      paidThroughAccountName ?? paidThroughAccountId ?? '';
  String? get paidThroughId => paidThroughAccountId;
  String get amountIs => amountTaxMode.displayLabel;
  String get statusText => status.displayLabel;
}
