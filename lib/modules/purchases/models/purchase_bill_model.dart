class PurchaseBill {
  final String id;
  final String? billNumber;
  final String vendorId;
  final String? vendorName;
  final DateTime billDate;
  final DateTime? dueDate;
  final String? reference;
  final String? paymentTerms;
  final String status; // draft, submitted, paid, overdue, cancelled
  final double totalAmount;
  final double? paidAmount;
  final double? balanceAmount;
  final String? currency;
  final List<PurchaseBillItem> items;
  final double? taxAmount;
  final double? discountAmount;
  final double? shippingCharge;
  final double? adjustment;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  PurchaseBill({
    required this.id,
    this.billNumber,
    required this.vendorId,
    this.vendorName,
    required this.billDate,
    this.dueDate,
    this.reference,
    this.paymentTerms,
    this.status = 'draft',
    required this.totalAmount,
    this.paidAmount,
    this.balanceAmount,
    this.currency = 'INR',
    this.items = const [],
    this.taxAmount,
    this.discountAmount,
    this.shippingCharge,
    this.adjustment,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PurchaseBill.fromJson(Map<String, dynamic> json) {
    return PurchaseBill(
      id: json['id'],
      billNumber: json['bill_number'],
      vendorId: json['vendor_id'],
      vendorName: json['vendor_name'],
      billDate: DateTime.parse(json['bill_date']),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      reference: json['reference'],
      paymentTerms: json['payment_terms'],
      status: json['status'] ?? 'draft',
      totalAmount: double.parse(json['total_amount'].toString()),
      paidAmount: json['paid_amount'] != null
          ? double.parse(json['paid_amount'].toString())
          : null,
      balanceAmount: json['balance_amount'] != null
          ? double.parse(json['balance_amount'].toString())
          : null,
      currency: json['currency'] ?? 'INR',
      items: (json['items'] as List?)
              ?.map((item) => PurchaseBillItem.fromJson(item))
              .toList() ??
          [],
      taxAmount: json['tax_amount'] != null
          ? double.parse(json['tax_amount'].toString())
          : null,
      discountAmount: json['discount_amount'] != null
          ? double.parse(json['discount_amount'].toString())
          : null,
      shippingCharge: json['shipping_charge'] != null
          ? double.parse(json['shipping_charge'].toString())
          : null,
      adjustment: json['adjustment'] != null
          ? double.parse(json['adjustment'].toString())
          : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bill_number': billNumber,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'bill_date': billDate.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'reference': reference,
      'payment_terms': paymentTerms,
      'status': status,
      'total_amount': totalAmount.toString(),
      'paid_amount': paidAmount?.toString(),
      'balance_amount': balanceAmount?.toString(),
      'currency': currency,
      'items': items.map((item) => item.toJson()).toList(),
      'tax_amount': taxAmount?.toString(),
      'discount_amount': discountAmount?.toString(),
      'shipping_charge': shippingCharge?.toString(),
      'adjustment': adjustment?.toString(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class PurchaseBillItem {
  final String? id;
  final String productId;
  final String? productName;
  final String? productCode;
  final double quantity;
  final double rate;
  final double amount;
  final String? unit;
  final double? discountPercentage;
  final double? discountAmount;
  final double? taxPercentage;
  final double? taxAmount;
  final String? hsnSac;
  final String? description;

  PurchaseBillItem({
    this.id,
    required this.productId,
    this.productName,
    this.productCode,
    required this.quantity,
    required this.rate,
    required this.amount,
    this.unit,
    this.discountPercentage,
    this.discountAmount,
    this.taxPercentage,
    this.taxAmount,
    this.hsnSac,
    this.description,
  });

  factory PurchaseBillItem.fromJson(Map<String, dynamic> json) {
    return PurchaseBillItem(
      id: json['id'],
      productId: json['product_id'],
      productName: json['product_name'],
      productCode: json['product_code'],
      quantity: double.parse(json['quantity'].toString()),
      rate: double.parse(json['rate'].toString()),
      amount: double.parse(json['amount'].toString()),
      unit: json['unit'],
      discountPercentage: json['discount_percentage'] != null
          ? double.parse(json['discount_percentage'].toString())
          : null,
      discountAmount: json['discount_amount'] != null
          ? double.parse(json['discount_amount'].toString())
          : null,
      taxPercentage: json['tax_percentage'] != null
          ? double.parse(json['tax_percentage'].toString())
          : null,
      taxAmount: json['tax_amount'] != null
          ? double.parse(json['tax_amount'].toString())
          : null,
      hsnSac: json['hsn_sac'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_code': productCode,
      'quantity': quantity.toString(),
      'rate': rate.toString(),
      'amount': amount.toString(),
      'unit': unit,
      'discount_percentage': discountPercentage?.toString(),
      'discount_amount': discountAmount?.toString(),
      'tax_percentage': taxPercentage?.toString(),
      'tax_amount': taxAmount?.toString(),
      'hsn_sac': hsnSac,
      'description': description,
    };
  }
}
