import 'package:intl/intl.dart';

double _toDouble(dynamic v) =>
    v == null ? 0.0 : double.tryParse(v.toString()) ?? 0.0;

class CreditNoteItemModel {
  final String id;
  final String? productId;
  final String? productName;
  final String? itemCode;
  final double quantity;
  final double rate;
  final double lineTotal;
  final String? description;

  const CreditNoteItemModel({
    required this.id,
    this.productId,
    this.productName,
    this.itemCode,
    required this.quantity,
    required this.rate,
    required this.lineTotal,
    this.description,
  });

  factory CreditNoteItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return CreditNoteItemModel(
      id: json['id'] as String,
      productId: product?['id'] as String?,
      productName: product?['product_name'] as String?,
      itemCode: product?['item_code'] as String?,
      quantity: _toDouble(json['quantity']),
      rate: _toDouble(json['rate']),
      lineTotal: _toDouble(json['line_total']),
      description: json['description'] as String?,
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
    required this.items,
  });

  factory CreditNoteModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    final rawItems = json['items'] as List<dynamic>? ?? [];

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
      status: (json['status'] as String? ?? 'DRAFT').toUpperCase(),
      grandTotal: _toDouble(json['grand_total']),
      subTotal: _toDouble(json['subtotal']),
      taxTotal: _toDouble(json['tax_total']),
      sourceType: json['source_type'] as String?,
      sourceId: json['source_id'] as String?,
      customerId: customer?['id'] as String?,
      customerName: customer?['display_name'] as String?,
      customerNumber: customer?['customer_number'] as String?,
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
