// FILE: lib/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart

class PurchaseOrder {
  final String? id;
  final String orgId;
  final String orderNumber;
  final DateTime orderDate;
  final DateTime? expectedDeliveryDate;
  final String? referenceNumber;
  final String vendorId;
  final String? paymentTerms;
  final String? shipmentPreference;
  final Map<String, dynamic>? deliveryAddress;
  final double subTotal;
  final double shippingCharges;
  final double adjustment;
  final String discountType;
  final double discountValue;
  final double totalAmount;
  final String status;
  final String? notes;
  final String? terms;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PurchaseOrder({
    this.id,
    required this.orgId,
    required this.orderNumber,
    required this.orderDate,
    this.expectedDeliveryDate,
    this.referenceNumber,
    required this.vendorId,
    this.paymentTerms,
    this.shipmentPreference,
    this.deliveryAddress,
    this.subTotal = 0.0,
    this.shippingCharges = 0.0,
    this.adjustment = 0.0,
    this.discountType = 'percentage',
    this.discountValue = 0.0,
    this.totalAmount = 0.0,
    this.status = 'draft',
    this.notes,
    this.terms,
    this.createdAt,
    this.updatedAt,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      id: json['id'] as String?,
      orgId: json['org_id'] as String,
      orderNumber: json['order_number'] as String,
      orderDate: DateTime.parse(json['order_date'] as String),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'] as String)
          : null,
      referenceNumber: json['reference_number'] as String?,
      vendorId: json['vendor_id'] as String,
      paymentTerms: json['payment_terms'] as String?,
      shipmentPreference: json['shipment_preference'] as String?,
      deliveryAddress: json['delivery_address'] as Map<String, dynamic>?,
      subTotal: (json['sub_total'] as num?)?.toDouble() ?? 0.0,
      shippingCharges: (json['shipping_charges'] as num?)?.toDouble() ?? 0.0,
      adjustment: (json['adjustment'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discount_type'] as String? ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'org_id': orgId,
      'order_number': orderNumber,
      'order_date': orderDate.toIso8601String(),
      if (expectedDeliveryDate != null)
        'expected_delivery_date': expectedDeliveryDate!.toIso8601String(),
      if (referenceNumber != null) 'reference_number': referenceNumber,
      'vendor_id': vendorId,
      if (paymentTerms != null) 'payment_terms': paymentTerms,
      if (shipmentPreference != null) 'shipment_preference': shipmentPreference,
      if (deliveryAddress != null) 'delivery_address': deliveryAddress,
      'sub_total': subTotal,
      'shipping_charges': shippingCharges,
      'adjustment': adjustment,
      'discount_type': discountType,
      'discount_value': discountValue,
      'total_amount': totalAmount,
      'status': status,
      if (notes != null) 'notes': notes,
      if (terms != null) 'terms': terms,
    };
  }

  PurchaseOrder copyWith({
    String? id,
    String? orgId,
    String? orderNumber,
    DateTime? orderDate,
    DateTime? expectedDeliveryDate,
    String? referenceNumber,
    String? vendorId,
    String? paymentTerms,
    String? shipmentPreference,
    Map<String, dynamic>? deliveryAddress,
    double? subTotal,
    double? shippingCharges,
    double? adjustment,
    String? discountType,
    double? discountValue,
    double? totalAmount,
    String? status,
    String? notes,
    String? terms,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      orgId: orgId ?? this.orgId,
      orderNumber: orderNumber ?? this.orderNumber,
      orderDate: orderDate ?? this.orderDate,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      vendorId: vendorId ?? this.vendorId,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      shipmentPreference: shipmentPreference ?? this.shipmentPreference,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      subTotal: subTotal ?? this.subTotal,
      shippingCharges: shippingCharges ?? this.shippingCharges,
      adjustment: adjustment ?? this.adjustment,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      terms: terms ?? this.terms,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
