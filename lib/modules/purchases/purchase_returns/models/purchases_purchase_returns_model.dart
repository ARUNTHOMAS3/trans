class PurchaseReturnItem {
  final String? id;
  final String? itemId;
  final String itemName;
  final String? description;
  final String? unit;
  final double orderedQty;
  final double returnQty;
  final double rate;
  final double amount;
  final String? taxRateId;
  final String? taxRateName;
  final double taxAmount;
  final String? warehouseId;
  final String? warehouseName;
  final String? batchNumber;
  final String? reason;

  const PurchaseReturnItem({
    this.id,
    this.itemId,
    this.itemName = '',
    this.description,
    this.unit,
    this.orderedQty = 0,
    this.returnQty = 0,
    this.rate = 0,
    this.amount = 0,
    this.taxRateId,
    this.taxRateName,
    this.taxAmount = 0,
    this.warehouseId,
    this.warehouseName,
    this.batchNumber,
    this.reason,
  });

  PurchaseReturnItem copyWith({
    String? id,
    String? itemId,
    String? itemName,
    String? description,
    String? unit,
    double? orderedQty,
    double? returnQty,
    double? rate,
    double? amount,
    String? taxRateId,
    String? taxRateName,
    double? taxAmount,
    String? warehouseId,
    String? warehouseName,
    String? batchNumber,
    String? reason,
  }) {
    return PurchaseReturnItem(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      orderedQty: orderedQty ?? this.orderedQty,
      returnQty: returnQty ?? this.returnQty,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      taxRateId: taxRateId ?? this.taxRateId,
      taxRateName: taxRateName ?? this.taxRateName,
      taxAmount: taxAmount ?? this.taxAmount,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      batchNumber: batchNumber ?? this.batchNumber,
      reason: reason ?? this.reason,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (itemId != null) 'item_id': itemId,
    'item_name': itemName,
    if (description != null) 'description': description,
    if (unit != null) 'unit': unit,
    'ordered_qty': orderedQty,
    'return_qty': returnQty,
    'rate': rate,
    'amount': amount,
    if (taxRateId != null) 'tax_rate_id': taxRateId,
    if (taxRateName != null) 'tax_rate_name': taxRateName,
    'tax_amount': taxAmount,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (warehouseName != null) 'warehouse_name': warehouseName,
    if (batchNumber != null) 'batch_number': batchNumber,
    if (reason != null) 'reason': reason,
  };

  factory PurchaseReturnItem.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnItem(
      id: json['id'] as String?,
      itemId: json['item_id'] as String?,
      itemName: json['item_name'] as String? ?? '',
      description: json['description'] as String?,
      unit: json['unit'] as String?,
      orderedQty: (json['ordered_qty'] as num?)?.toDouble() ?? 0,
      returnQty: (json['return_qty'] as num?)?.toDouble() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      taxRateId: json['tax_rate_id'] as String?,
      taxRateName: json['tax_rate_name'] as String?,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      warehouseId: json['warehouse_id'] as String?,
      warehouseName: json['warehouse_name'] as String?,
      batchNumber: json['batch_number'] as String?,
      reason: json['reason'] as String?,
    );
  }
}

class PurchaseReturn {
  final String? id;
  final String returnNumber;
  final DateTime? returnDate;
  final String? vendorId;
  final String? vendorName;
  final String? purchaseOrderId;
  final String? purchaseOrderNumber;
  final String? purchaseReceiveId;
  final String? purchaseReceiveNumber;
  final String? billId;
  final String? billNumber;
  final String? warehouseId;
  final String? warehouseName;

  /// draft | confirmed | vendor_received
  final String status;
  final String? notes;
  final double subtotal;
  final double taxAmount;
  final double total;
  final List<PurchaseReturnItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get totalReturnQty => items.fold(0.0, (sum, i) => sum + i.returnQty);

  const PurchaseReturn({
    this.id,
    this.returnNumber = '',
    this.returnDate,
    this.vendorId,
    this.vendorName,
    this.purchaseOrderId,
    this.purchaseOrderNumber,
    this.purchaseReceiveId,
    this.purchaseReceiveNumber,
    this.billId,
    this.billNumber,
    this.warehouseId,
    this.warehouseName,
    this.status = 'draft',
    this.notes,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.total = 0,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  PurchaseReturn copyWith({
    String? id,
    String? returnNumber,
    DateTime? returnDate,
    String? vendorId,
    String? vendorName,
    String? purchaseOrderId,
    String? purchaseOrderNumber,
    String? purchaseReceiveId,
    String? purchaseReceiveNumber,
    String? billId,
    String? billNumber,
    String? warehouseId,
    String? warehouseName,
    String? status,
    String? notes,
    double? subtotal,
    double? taxAmount,
    double? total,
    List<PurchaseReturnItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseReturn(
      id: id ?? this.id,
      returnNumber: returnNumber ?? this.returnNumber,
      returnDate: returnDate ?? this.returnDate,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      purchaseReceiveId: purchaseReceiveId ?? this.purchaseReceiveId,
      purchaseReceiveNumber:
          purchaseReceiveNumber ?? this.purchaseReceiveNumber,
      billId: billId ?? this.billId,
      billNumber: billNumber ?? this.billNumber,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'return_number': returnNumber,
    if (returnDate != null) 'return_date': returnDate!.toIso8601String(),
    if (vendorId != null) 'vendor_id': vendorId,
    if (vendorName != null) 'vendor_name': vendorName,
    if (purchaseOrderId != null) 'purchase_order_id': purchaseOrderId,
    if (purchaseOrderNumber != null)
      'purchase_order_number': purchaseOrderNumber,
    if (purchaseReceiveId != null) 'purchase_receive_id': purchaseReceiveId,
    if (purchaseReceiveNumber != null)
      'purchase_receive_number': purchaseReceiveNumber,
    if (billId != null) 'bill_id': billId,
    if (billNumber != null) 'bill_number': billNumber,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (warehouseName != null) 'warehouse_name': warehouseName,
    'status': status,
    if (notes != null) 'notes': notes,
    'subtotal': subtotal,
    'tax_amount': taxAmount,
    'total': total,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory PurchaseReturn.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>?;
    return PurchaseReturn(
      id: json['id'] as String?,
      returnNumber: json['return_number'] as String? ?? '',
      returnDate: json['return_date'] != null
          ? DateTime.tryParse(json['return_date'] as String)
          : null,
      vendorId: json['vendor_id'] as String?,
      vendorName: json['vendor_name'] as String?,
      purchaseOrderId: json['purchase_order_id'] as String?,
      purchaseOrderNumber: json['purchase_order_number'] as String?,
      purchaseReceiveId: json['purchase_receive_id'] as String?,
      purchaseReceiveNumber: json['purchase_receive_number'] as String?,
      billId: json['bill_id'] as String?,
      billNumber: json['bill_number'] as String?,
      warehouseId: json['warehouse_id'] as String?,
      warehouseName: json['warehouse_name'] as String?,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      items:
          rawItems
              ?.whereType<Map<String, dynamic>>()
              .map(PurchaseReturnItem.fromJson)
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }
}
