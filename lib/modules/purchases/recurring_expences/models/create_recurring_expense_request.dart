import 'recurring_expense_enums.dart';

class CreateRecurringExpenseRequest {
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
  final bool autoCreate;
  final bool includeCustomerIdField;

  const CreateRecurringExpenseRequest({
    required this.profileName,
    this.entityId,
    required this.repeatEvery,
    required this.repeatType,
    required this.startDate,
    this.endDate,
    required this.neverExpires,
    this.nextRunDate,
    this.lastRunDate,
    this.status = RecurringExpenseStatus.active,
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
    required this.notes,
    this.customerId,
    this.isBillable = false,
    this.autoCreate = true,
    this.includeCustomerIdField = false,
  });

  Map<String, dynamic> toJson() {
    final serializedStartDate = _requireIsoDateString(
      startDate,
      fieldName: 'start_date',
    );
    final serializedEndDate = endDate == null
        ? null
        : _requireIsoDateString(endDate!, fieldName: 'end_date');
    final serializedNextRunDate = nextRunDate == null
        ? null
        : _requireIsoDateString(nextRunDate!, fieldName: 'next_run_date');
    final serializedLastRunDate = lastRunDate == null
        ? null
        : _requireIsoDateString(lastRunDate!, fieldName: 'last_run_date');

    return <String, dynamic>{
      'profile_name': profileName,
      if (entityId != null) 'entity_id': entityId,
      'repeat_every': repeatEvery,
      'repeat_type': repeatType.value,
      'start_date': serializedStartDate,
      if (serializedEndDate != null) 'end_date': serializedEndDate,
      'never_expires': neverExpires,
      if (serializedNextRunDate != null) 'next_run_date': serializedNextRunDate,
      if (serializedLastRunDate != null) 'last_run_date': serializedLastRunDate,
      'status': status.value,
      if (expenseAccountId != null) 'expense_account_id': expenseAccountId,
      'amount': amount,
      'currency_code': currencyCode,
      if (paidThroughAccountId != null)
        'paid_through_account_id': paidThroughAccountId,
      'expense_type': expenseType.value,
      if (hsnSacCode != null && hsnSacCode!.isNotEmpty)
        'hsn_sac_code': hsnSacCode,
      if (vendorId != null) 'vendor_id': vendorId,
      if (gstTreatment != null) 'gst_treatment': gstTreatment,
      if (sourceOfSupply != null) 'source_of_supply': sourceOfSupply,
      if (destinationOfSupply != null)
        'destination_of_supply': destinationOfSupply,
      'reverse_charge': reverseCharge,
      if (taxId != null) 'tax_id': taxId,
      'amount_tax_mode': amountTaxMode.value,
      if (invoiceNumber != null && invoiceNumber!.isNotEmpty)
        'invoice_number': invoiceNumber,
      'notes': notes,
      if (includeCustomerIdField || customerId != null)
        'customer_id': customerId,
      'is_billable': isBillable,
      'auto_create': autoCreate,
    };
  }

  static final RegExp _isoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  String _requireIsoDateString(String value, {required String fieldName}) {
    if (!_isoDatePattern.hasMatch(value)) {
      throw FormatException(
        '$fieldName must be a valid ISO 8601 date string (yyyy-MM-dd).',
      );
    }

    final parsed = DateTime.tryParse(value);
    if (parsed == null) {
      throw FormatException(
        '$fieldName must be a valid ISO 8601 date string (yyyy-MM-dd).',
      );
    }

    final normalized = DateTime(parsed.year, parsed.month, parsed.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  CreateRecurringExpenseRequest copyWith({
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
    bool? autoCreate,
    bool? includeCustomerIdField,
  }) {
    return CreateRecurringExpenseRequest(
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
      autoCreate: autoCreate ?? this.autoCreate,
      includeCustomerIdField:
          includeCustomerIdField ?? this.includeCustomerIdField,
    );
  }
}
