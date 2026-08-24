import 'package:intl/intl.dart';

double _toDouble(dynamic v) =>
    v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

class CreditNoteItemModel {
  final String id;
  final String? accountId;
  final String? productId;
  final String? productName;
  final String? itemCode;
  final double quantity;
  final double rate;
  final double lineTotal;
  final String? description;
  final String discountType; // 'PERCENTAGE' | 'FIXED'
  final double discountValue;
  final double taxPercentage;

  final String? hsnSacCode;

  const CreditNoteItemModel({
    required this.id,
    this.accountId,
    this.productId,
    this.productName,
    this.itemCode,
    required this.quantity,
    required this.rate,
    required this.lineTotal,
    this.description,
    this.discountType = 'PERCENTAGE',
    this.discountValue = 0,
    this.taxPercentage = 0,
    this.hsnSacCode,
  });

  factory CreditNoteItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return CreditNoteItemModel(
      id: json['id'] as String? ?? '',
      accountId: json['account_id'] as String?,
      productId: (product?['id'] ?? json['product_id']) as String?,
      productName: (product?['product_name'] ?? json['product_name']) as String?,
      itemCode: (product?['item_code'] ?? json['item_code']) as String?,
      quantity: _toDouble(json['quantity']),
      rate: _toDouble(json['rate']),
      lineTotal: _toDouble(json['line_total']),
      description: json['description'] as String?,
      discountType:
          (json['discount_type'] as String?)?.toUpperCase() == 'FIXED'
          ? 'FIXED'
          : 'PERCENTAGE',
      discountValue: _toDouble(json['discount_value']),
      taxPercentage: _toDouble(json['tax_percentage']),
      hsnSacCode: (product?['hsn_sac_code'] ?? json['hsn_sac_code']) as String?,
    );
  }

  String get formattedQty {
    if (quantity == quantity.roundToDouble()) return quantity.toStringAsFixed(0);
    return quantity.toStringAsFixed(2);
  }

  String get formattedRate => NumberFormat('#,##0.00').format(rate);
  String get formattedLineTotal => NumberFormat('#,##0.00').format(lineTotal);
}

class CreditNoteModel {
  final String id;
  final String creditNoteNumber;
  final String? referenceNumber;
  final DateTime? creditNoteDate;
  final String status;
  final double grandTotal;
  final double subTotal;
  final double taxTotal;
  final String? sourceType;
  final String? sourceId;
  final String? customerId;
  final String? customerName;
  final String? customerNumber;
  final String? customerEmail;
  final String? customerPhone;
  final String? billingAddressStreet;
  final String? billingAddressPlace;
  final String? billingAddressCity;
  final String? billingAddressState;
  final String? billingAddressZip;
  final String? billingAddressCountry;
  final String? placeOfSupply;
  final String? gstin;
  final String? customerNotes;
  final String? termsConditions;
  final String? salespersonId;
  final String? salespersonName;
  final String? invoiceNumber;
  final List<CreditNoteItemModel> items;

  const CreditNoteModel({
    required this.id,
    required this.creditNoteNumber,
    this.referenceNumber,
    this.creditNoteDate,
    required this.status,
    required this.grandTotal,
    this.subTotal = 0,
    this.taxTotal = 0,
    this.sourceType,
    this.sourceId,
    this.customerId,
    this.customerName,
    this.customerNumber,
    this.customerEmail,
    this.customerPhone,
    this.billingAddressStreet,
    this.billingAddressPlace,
    this.billingAddressCity,
    this.billingAddressState,
    this.billingAddressZip,
    this.billingAddressCountry,
    this.placeOfSupply,
    this.gstin,
    this.customerNotes,
    this.termsConditions,
    this.salespersonId,
    this.salespersonName,
    this.invoiceNumber,
    required this.items,
  });

  factory CreditNoteModel.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson.containsKey('data') && rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;
    final customer = json['customer'] as Map<String, dynamic>?;
    final rawItems = json['items'] as List<dynamic>? ?? [];
    // Legacy approved notes remain editable/open in the Credit Note workflow.
    final status = (json['status'] as String? ?? 'DRAFT').toUpperCase();

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return CreditNoteModel(
      id: json['id'] as String,
      creditNoteNumber: json['credit_note_number'] as String? ?? '',
      referenceNumber: json['reference_number'] as String?,
      creditNoteDate: parseDate(json['credit_note_date']),
      status: status == 'APPROVED' ? 'OPEN' : status,
      grandTotal: _toDouble(json['grand_total']),
      subTotal: _toDouble(json['subtotal']),
      taxTotal: _toDouble(json['tax_total']),
      sourceType: json['source_type'] as String?,
      sourceId: json['source_id'] as String?,
      customerId: customer?['id'] as String?,
      customerName: customer?['display_name'] as String?,
      customerNumber: customer?['customer_number'] as String?,
      customerEmail: customer?['email'] as String?,
      customerPhone: customer?['phone'] as String?,
      billingAddressStreet: customer?['billing_address_street'] as String?,
      billingAddressPlace: customer?['billing_address_place'] as String?,
      billingAddressCity: customer?['billing_address_city'] as String?,
      billingAddressState: customer?['billing_address_state'] as String?,
      billingAddressZip: customer?['billing_address_zip'] as String?,
      billingAddressCountry: customer?['billing_address_country'] as String?,
      placeOfSupply: customer?['place_of_supply'] as String?,
      gstin: customer?['gstin'] as String?,
      customerNotes: json['customer_notes'] as String?,
      termsConditions: json['terms_conditions'] as String?,
      salespersonId: json['salesperson_id'] as String?,
      salespersonName: json['salesperson_name'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      items: rawItems
          .map((e) => CreditNoteItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedDate => creditNoteDate != null
      ? DateFormat('dd-MM-yyyy').format(creditNoteDate!)
      : '-';

  String get formattedAmount => NumberFormat('#,##0.00').format(grandTotal);

  double get computedSubTotal =>
      items.fold(0.0, (sum, i) => sum + i.lineTotal);

  double get computedTaxTotal => grandTotal - computedSubTotal;
}
