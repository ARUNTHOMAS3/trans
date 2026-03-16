class Purchase {
  final String id;
  final String? purchaseNumber;
  final String vendorId;
  final String? vendorName;
  final DateTime purchaseDate;
  final DateTime? expectedDeliveryDate;
  final String? reference;
  final String? deliveryMethod;
  final String? paymentTerms;
  final String documentType; // order, bill, receipt
  final String status; // draft, pending, approved, received, cancelled
  final double total;
  final String? currency;
  final String? vendorNotes;
  final String? termsAndConditions;
  final List<PurchaseItem> items;
  final double? taxAmount;
  final double? discountAmount;
  final double? shippingCharge;
  final double? adjustment;
  final DateTime createdAt;
  final DateTime updatedAt;

  Purchase({
    required this.id,
    this.purchaseNumber,
    required this.vendorId,
    this.vendorName,
    required this.purchaseDate,
    this.expectedDeliveryDate,
    this.reference,
    this.deliveryMethod,
    this.paymentTerms,
    this.documentType = 'order',
    this.status = 'draft',
    this.total = 0.0,
    this.currency = 'INR',
    this.vendorNotes,
    this.termsAndConditions,
    this.items = const [],
    this.taxAmount,
    this.discountAmount,
    this.shippingCharge,
    this.adjustment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    return Purchase(
      id: json['id'],
      purchaseNumber: json['purchase_number'],
      vendorId: json['vendor_id'],
      vendorName: json['vendor_name'],
      purchaseDate: DateTime.parse(json['purchase_date']),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'])
          : null,
      reference: json['reference'],
      deliveryMethod: json['delivery_method'],
      paymentTerms: json['payment_terms'],
      documentType: json['document_type'] ?? 'order',
      status: json['status'] ?? 'draft',
      total: double.parse(json['total'].toString()),
      currency: json['currency'] ?? 'INR',
      vendorNotes: json['vendor_notes'],
      termsAndConditions: json['terms_and_conditions'],
      items: (json['items'] as List?)
              ?.map((item) => PurchaseItem.fromJson(item))
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
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'purchase_number': purchaseNumber,
      'vendor_id': vendorId,
      'vendor_name': vendorName,
      'purchase_date': purchaseDate.toIso8601String(),
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
      'reference': reference,
      'delivery_method': deliveryMethod,
      'payment_terms': paymentTerms,
      'document_type': documentType,
      'status': status,
      'total': total.toString(),
      'currency': currency,
      'vendor_notes': vendorNotes,
      'terms_and_conditions': termsAndConditions,
      'items': items.map((item) => item.toJson()).toList(),
      'tax_amount': taxAmount?.toString(),
      'discount_amount': discountAmount?.toString(),
      'shipping_charge': shippingCharge?.toString(),
      'adjustment': adjustment?.toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class PurchaseItem {
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

  PurchaseItem({
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

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    return PurchaseItem(
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
