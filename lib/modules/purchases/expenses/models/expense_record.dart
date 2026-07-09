import 'expense_attachment_model.dart';
import 'expense_item_model.dart';
import 'expense_mileage_model.dart';

class ExpenseRecord {
  const ExpenseRecord({
    required this.id,
    required this.date,
    required this.expenseAccount,
    required this.reference,
    required this.amount,
    this.expenseNumber = '',
    this.invoiceNumber = '',
    this.expenseMode = 'RECORD_EXPENSE',
    this.expenseAccountId = '',
    this.paidThroughAccountId = '',
    this.paidThrough = 'Petty Cash',
    this.currencyCode = 'INR',
    this.expenseType = 'SERVICES',
    this.hsnSacCode = '',
    this.vendorId = '',
    this.vendorName = '',
    this.customerId = '',
    this.customerName = '',
    this.markupBy = '',
    this.gstTreatment = '',
    this.sourceOfSupply = '',
    this.destinationOfSupply = '',
    this.reverseCharge = false,
    this.taxId = '',
    this.taxAmount = 0,
    this.amountTaxMode = 'EXCLUSIVE',
    this.status = 'NON-BILLABLE',
    this.isSelected = false,
    this.isItemized = false,
    this.isBillable = false,
    this.notes = '',
    this.gst = '',
    this.subtotal = 0,
    this.totalAmount = 0,
    this.recurringExpenseId = '',
    this.attachments = const <ExpenseAttachmentModel>[],
    this.items = const <ExpenseItemModel>[],
    this.mileage,
    this.attachmentCount = 0,
    this.hasAttachments = false,
  });

  final String id;
  final String date;
  final String expenseAccount;
  final String reference;
  final String expenseNumber;
  final String invoiceNumber;
  final String expenseMode;
  final String expenseAccountId;
  final String paidThroughAccountId;
  final String paidThrough;
  final String currencyCode;
  final String expenseType;
  final String hsnSacCode;
  final String vendorId;
  final String vendorName;
  final String customerId;
  final String customerName;
  final String markupBy;
  final String gstTreatment;
  final String sourceOfSupply;
  final String destinationOfSupply;
  final bool reverseCharge;
  final String taxId;
  final double taxAmount;
  final String amountTaxMode;
  final String status;
  final double amount;
  final bool isSelected;
  final bool isItemized;
  final bool isBillable;
  final String notes;
  final String gst;
  final double subtotal;
  final double totalAmount;
  final String recurringExpenseId;
  final List<ExpenseAttachmentModel> attachments;
  final List<ExpenseItemModel> items;
  final ExpenseMileageModel? mileage;
  final int attachmentCount;
  final bool hasAttachments;

  factory ExpenseRecord.empty() => const ExpenseRecord(
    id: '',
    date: '',
    expenseAccount: '',
    reference: '',
    amount: 0,
  );

  factory ExpenseRecord.fromJson(Map<String, dynamic> json) {
    final invoiceNumber =
        (json['invoice_number'] ?? json['invoiceNumber'] ?? '').toString();
    final expenseNumber =
        (json['expense_number'] ?? json['expenseNumber'] ?? '').toString();
    final reference = invoiceNumber.isNotEmpty ? invoiceNumber : expenseNumber;

    final attachments = _mapList(
      json['attachments'],
      ExpenseAttachmentModel.fromJson,
    );
    final items = _mapList(json['items'], ExpenseItemModel.fromJson);
    final mileageJson = json['mileage'];

    return ExpenseRecord(
      id: (json['id'] ?? '').toString(),
      date: (json['expense_date'] ?? json['expenseDate'] ?? '').toString(),
      expenseAccount:
          (json['expense_account_name'] ?? json['expenseAccountName'] ?? '')
              .toString(),
      reference: reference,
      expenseNumber: expenseNumber,
      invoiceNumber: invoiceNumber,
      expenseMode:
          (json['expense_mode'] ?? json['expenseMode'] ?? 'RECORD_EXPENSE')
              .toString(),
      expenseAccountId:
          (json['expense_account_id'] ?? json['expenseAccountId'] ?? '')
              .toString(),
      paidThroughAccountId:
          (json['paid_through_account_id'] ??
                  json['paidThroughAccountId'] ??
                  '')
              .toString(),
      paidThrough:
          (json['paid_through_account_name'] ?? json['paidThrough'] ?? '')
              .toString(),
      currencyCode: (json['currency_code'] ?? json['currencyCode'] ?? 'INR')
          .toString(),
      expenseType: (json['expense_type'] ?? json['expenseType'] ?? 'SERVICES')
          .toString(),
      hsnSacCode: (json['hsn_sac_code'] ?? json['hsnSacCode'] ?? '').toString(),
      vendorId: (json['vendor_id'] ?? json['vendorId'] ?? '').toString(),
      vendorName: (json['vendor_name'] ?? json['vendorName'] ?? '').toString(),
      customerId: (json['customer_id'] ?? json['customerId'] ?? '').toString(),
      customerName: (json['customer_name'] ?? json['customerName'] ?? '')
          .toString(),
      markupBy:
          (json['markup_by'] ?? json['markupBy'] ?? json['mark_up_by'] ?? '')
              .toString(),
      gstTreatment: (json['gst_treatment'] ?? json['gstTreatment'] ?? '')
          .toString(),
      sourceOfSupply: (json['source_of_supply'] ?? json['sourceOfSupply'] ?? '')
          .toString(),
      destinationOfSupply:
          (json['destination_of_supply'] ?? json['destinationOfSupply'] ?? '')
              .toString(),
      reverseCharge:
          json['reverse_charge'] as bool? ??
          json['reverseCharge'] as bool? ??
          false,
      taxId: (json['tax_id'] ?? json['taxId'] ?? '').toString(),
      taxAmount:
          (json['tax_amount'] as num?)?.toDouble() ??
          double.tryParse((json['tax_amount'] ?? '0').toString()) ??
          0,
      amountTaxMode:
          (json['amount_tax_mode'] ?? json['amountTaxMode'] ?? 'EXCLUSIVE')
              .toString(),
      status: (json['status'] ?? '').toString(),
      amount:
          (json['amount'] as num?)?.toDouble() ??
          double.tryParse((json['amount'] ?? '0').toString()) ??
          0,
      isItemized:
          json['is_itemized'] as bool? ?? json['isItemized'] as bool? ?? false,
      isBillable:
          json['is_billable'] as bool? ?? json['isBillable'] as bool? ?? false,
      notes: (json['notes'] ?? '').toString(),
      gst: (json['gst'] ?? '').toString(),
      subtotal:
          (json['subtotal'] as num?)?.toDouble() ??
          double.tryParse((json['subtotal'] ?? '0').toString()) ??
          0,
      totalAmount:
          (json['total_amount'] as num?)?.toDouble() ??
          double.tryParse((json['total_amount'] ?? '0').toString()) ??
          0,
      recurringExpenseId:
          (json['recurring_expense_id'] ?? json['recurringExpenseId'] ?? '')
              .toString(),
      attachments: attachments,
      items: items,
      mileage: mileageJson is Map<String, dynamic>
          ? ExpenseMileageModel.fromJson(mileageJson)
          : null,
      attachmentCount:
          (json['attachment_count'] as num?)?.toInt() ??
          int.tryParse((json['attachment_count'] ?? '0').toString()) ??
          attachments.length,
      hasAttachments:
          json['has_attachments'] as bool? ??
          json['hasAttachments'] as bool? ??
          attachments.isNotEmpty,
    );
  }

  static List<T> _mapList<T>(
    dynamic value,
    T Function(Map<String, dynamic>) mapper,
  ) {
    if (value is! List) {
      return <T>[];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, nestedValue) => MapEntry(key.toString(), nestedValue),
          ),
        )
        .map(mapper)
        .toList(growable: false);
  }

  ExpenseRecord copyWith({
    String? id,
    String? date,
    String? expenseAccount,
    String? reference,
    String? expenseNumber,
    String? invoiceNumber,
    String? expenseMode,
    String? expenseAccountId,
    String? paidThroughAccountId,
    String? paidThrough,
    String? currencyCode,
    String? expenseType,
    String? hsnSacCode,
    String? vendorId,
    String? vendorName,
    String? customerId,
    String? customerName,
    String? markupBy,
    String? gstTreatment,
    String? sourceOfSupply,
    String? destinationOfSupply,
    bool? reverseCharge,
    String? taxId,
    double? taxAmount,
    String? amountTaxMode,
    String? status,
    double? amount,
    bool? isSelected,
    bool? isItemized,
    bool? isBillable,
    String? notes,
    String? gst,
    double? subtotal,
    double? totalAmount,
    String? recurringExpenseId,
    List<ExpenseAttachmentModel>? attachments,
    List<ExpenseItemModel>? items,
    ExpenseMileageModel? mileage,
    int? attachmentCount,
    bool? hasAttachments,
  }) {
    return ExpenseRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      expenseAccount: expenseAccount ?? this.expenseAccount,
      reference: reference ?? this.reference,
      expenseNumber: expenseNumber ?? this.expenseNumber,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      expenseMode: expenseMode ?? this.expenseMode,
      expenseAccountId: expenseAccountId ?? this.expenseAccountId,
      paidThroughAccountId: paidThroughAccountId ?? this.paidThroughAccountId,
      paidThrough: paidThrough ?? this.paidThrough,
      currencyCode: currencyCode ?? this.currencyCode,
      expenseType: expenseType ?? this.expenseType,
      hsnSacCode: hsnSacCode ?? this.hsnSacCode,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      markupBy: markupBy ?? this.markupBy,
      gstTreatment: gstTreatment ?? this.gstTreatment,
      sourceOfSupply: sourceOfSupply ?? this.sourceOfSupply,
      destinationOfSupply: destinationOfSupply ?? this.destinationOfSupply,
      reverseCharge: reverseCharge ?? this.reverseCharge,
      taxId: taxId ?? this.taxId,
      taxAmount: taxAmount ?? this.taxAmount,
      amountTaxMode: amountTaxMode ?? this.amountTaxMode,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      isSelected: isSelected ?? this.isSelected,
      isItemized: isItemized ?? this.isItemized,
      isBillable: isBillable ?? this.isBillable,
      notes: notes ?? this.notes,
      gst: gst ?? this.gst,
      subtotal: subtotal ?? this.subtotal,
      totalAmount: totalAmount ?? this.totalAmount,
      recurringExpenseId: recurringExpenseId ?? this.recurringExpenseId,
      attachments: attachments ?? this.attachments,
      items: items ?? this.items,
      mileage: mileage ?? this.mileage,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      hasAttachments: hasAttachments ?? this.hasAttachments,
    );
  }
}
