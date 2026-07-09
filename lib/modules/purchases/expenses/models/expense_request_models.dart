import 'expense_attachment_model.dart';
import 'expense_item_model.dart';
import 'expense_mileage_model.dart';

class UpsertExpenseRequest {
  const UpsertExpenseRequest({
    required this.expenseDate,
    required this.expenseMode,
    required this.expenseAccountId,
    required this.paidThroughAccountId,
    required this.amount,
    required this.expenseType,
    this.status,
    this.expenseNumber,
    this.isItemized = false,
    this.currencyCode,
    this.hsnSacCode,
    this.vendorId,
    this.customerId,
    this.markUpBy,
    this.gstTreatment,
    this.sourceOfSupply,
    this.destinationOfSupply,
    this.reverseCharge = false,
    this.taxId,
    this.amountTaxMode,
    this.invoiceNumber,
    this.notes,
    this.isBillable = false,
    this.subtotal,
    this.taxAmount,
    this.totalAmount,
    this.recurringExpenseId,
    this.items = const <ExpenseItemModel>[],
    this.mileage,
    this.attachments = const <ExpenseAttachmentModel>[],
  });

  final String? expenseNumber;
  final String expenseDate;
  final String expenseMode;
  final String? status;
  final bool isItemized;
  final String? expenseAccountId;
  final String paidThroughAccountId;
  final double amount;
  final String? currencyCode;
  final String expenseType;
  final String? hsnSacCode;
  final String? vendorId;
  final String? customerId;
  final double? markUpBy;
  final String? gstTreatment;
  final String? sourceOfSupply;
  final String? destinationOfSupply;
  final bool reverseCharge;
  final String? taxId;
  final String? amountTaxMode;
  final String? invoiceNumber;
  final String? notes;
  final bool isBillable;
  final double? subtotal;
  final double? taxAmount;
  final double? totalAmount;
  final String? recurringExpenseId;
  final List<ExpenseItemModel> items;
  final ExpenseMileageModel? mileage;
  final List<ExpenseAttachmentModel> attachments;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (expenseNumber != null && expenseNumber!.trim().isNotEmpty)
      'expense_number': expenseNumber,
    'expense_date': expenseDate,
    'expense_mode': expenseMode,
    if (status != null && status!.trim().isNotEmpty) 'status': status,
    'is_itemized': isItemized,
    if (expenseAccountId != null && expenseAccountId!.trim().isNotEmpty)
      'expense_account_id': expenseAccountId,
    'paid_through_account_id': paidThroughAccountId,
    'amount': amount,
    if (currencyCode != null && currencyCode!.trim().isNotEmpty)
      'currency_code': currencyCode,
    'expense_type': expenseType,
    if (hsnSacCode != null && hsnSacCode!.trim().isNotEmpty)
      'hsn_sac_code': hsnSacCode,
    if (vendorId != null && vendorId!.trim().isNotEmpty) 'vendor_id': vendorId,
    if (customerId != null && customerId!.trim().isNotEmpty)
      'customer_id': customerId,
    'mark_up_by': markUpBy,
    if (gstTreatment != null && gstTreatment!.trim().isNotEmpty)
      'gst_treatment': gstTreatment,
    if (sourceOfSupply != null && sourceOfSupply!.trim().isNotEmpty)
      'source_of_supply': sourceOfSupply,
    if (destinationOfSupply != null && destinationOfSupply!.trim().isNotEmpty)
      'destination_of_supply': destinationOfSupply,
    'reverse_charge': reverseCharge,
    if (taxId != null && taxId!.trim().isNotEmpty) 'tax_id': taxId,
    if (amountTaxMode != null && amountTaxMode!.trim().isNotEmpty)
      'amount_tax_mode': amountTaxMode,
    if (invoiceNumber != null) 'invoice_number': invoiceNumber,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
    'is_billable': isBillable,
    if (subtotal != null) 'subtotal': subtotal,
    if (taxAmount != null) 'tax_amount': taxAmount,
    if (totalAmount != null) 'total_amount': totalAmount,
    if (recurringExpenseId != null && recurringExpenseId!.trim().isNotEmpty)
      'recurring_expense_id': recurringExpenseId,
    if (items.isNotEmpty)
      'items': items.map((item) => item.toRequestJson()).toList(),
    if (mileage != null) 'mileage': mileage!.toRequestJson(),
    if (attachments.isNotEmpty)
      'attachments': attachments
          .map((item) => item.toAttachmentRequestJson())
          .toList(),
  };
}

class UpdateExpenseRequest {
  const UpdateExpenseRequest({required this.id, required this.expense});

  final String id;
  final UpsertExpenseRequest expense;
}
