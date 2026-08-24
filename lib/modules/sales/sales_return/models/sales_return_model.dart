class CreateReceiveBatchPayload {
  final String batchId;
  final String? layerId;
  final String warehouseId;
  final String binId;
  final double quantity;
  final double focQuantity;
  final double? purchaseRate;
  final double? mrp;
  final String? expiryDate;
  final String? mfgDate;
  final String? mfgBatchNo;

  CreateReceiveBatchPayload({
    required this.batchId,
    this.layerId,
    required this.warehouseId,
    required this.binId,
    required this.quantity,
    this.focQuantity = 0,
    this.purchaseRate,
    this.mrp,
    this.expiryDate,
    this.mfgDate,
    this.mfgBatchNo,
  });

  Map<String, dynamic> toJson() => {
    'batch_id': batchId,
    if (layerId != null && layerId!.isNotEmpty) 'layer_id': layerId,
    'warehouse_id': warehouseId,
    'bin_id': binId,
    'quantity': quantity,
    'foc_quantity': focQuantity,
    if (purchaseRate != null) 'purchase_rate': purchaseRate,
    if (mrp != null) 'mrp': mrp,
    if (expiryDate != null && expiryDate!.isNotEmpty) 'expiry_date': expiryDate,
    if (mfgDate != null && mfgDate!.isNotEmpty) 'manufacture_date': mfgDate,
    if (mfgBatchNo != null && mfgBatchNo!.isNotEmpty)
      'manufacture_batch_no': mfgBatchNo,
  };
}

class CreateReceiveItemPayload {
  final String productId;
  final String? salesReturnItemId;
  final double receivingQty;
  final double returnQty;
  final double alreadyReceivedQty;
  final String? remarks;
  final List<CreateReceiveBatchPayload> batches;

  CreateReceiveItemPayload({
    required this.productId,
    this.salesReturnItemId,
    required this.receivingQty,
    this.returnQty = 0,
    this.alreadyReceivedQty = 0,
    this.remarks,
    this.batches = const [],
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    if (salesReturnItemId != null) 'sales_return_item_id': salesReturnItemId,
    'receiving_qty': receivingQty,
    'return_qty': returnQty,
    'already_received_qty': alreadyReceivedQty,
    if (remarks != null) 'remarks': remarks,
    'batches': batches.map((b) => b.toJson()).toList(),
  };
}

class CreateReceivePayload {
  final String receiveDate;
  final String? warehouseId;
  final String? notes;
  final List<CreateReceiveItemPayload> items;

  CreateReceivePayload({
    required this.receiveDate,
    this.warehouseId,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'receive_date': receiveDate,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

class SalesReturnReceive {
  final String id;
  final String salesReturnId;
  final String receiveNumber;
  final String receiveDate;
  final String? notes;
  final String createdAt;
  final List<SalesReturnReceiveItem> items;

  SalesReturnReceive({
    required this.id,
    required this.salesReturnId,
    required this.receiveNumber,
    required this.receiveDate,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  factory SalesReturnReceive.fromJson(Map<String, dynamic> json) =>
      SalesReturnReceive(
        id: json['id'] as String,
        salesReturnId: json['sales_return_id'] as String,
        receiveNumber: json['receive_number'] as String,
        receiveDate: json['receive_date'] as String,
        notes: json['notes'] as String?,
        createdAt: json['created_at'] as String,
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => SalesReturnReceiveItem.fromJson(e))
                .toList() ??
            const [],
      );
}

class SalesReturnReceiveItem {
  final String id;
  final String productId;
  final double receivingQty;
  final List<SalesReturnReceiveBatch> batches;

  SalesReturnReceiveItem({
    required this.id,
    required this.productId,
    required this.receivingQty,
    this.batches = const [],
  });

  factory SalesReturnReceiveItem.fromJson(Map<String, dynamic> json) =>
      SalesReturnReceiveItem(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        receivingQty: _toDouble(json['receiving_qty']),
        batches: (json['batches'] as List<dynamic>?)
                ?.map((e) => SalesReturnReceiveBatch.fromJson(e))
                .toList() ??
            const [],
      );

  static double _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

class SalesReturnReceiveBatch {
  final String id;
  final String batchId;
  final String batchNumber;
  final double quantity;

  SalesReturnReceiveBatch({
    required this.id,
    required this.batchId,
    required this.batchNumber,
    required this.quantity,
  });

  factory SalesReturnReceiveBatch.fromJson(Map<String, dynamic> json) =>
      SalesReturnReceiveBatch(
        id: json['id'] as String? ?? '',
        batchId: json['batch_id'] as String? ?? '',
        batchNumber: json['batch']?['batch_no'] as String? ?? json['batch_id'] as String? ?? '',
        quantity: _toDouble(json['quantity']),
      );

  static double _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

class SalesReturnItemData {
  final String id;
  final String productId;
  final double returnQty;
  final double receivableQty;
  final double creditOnlyQty;
  final double invoicedQty;
  final double alreadyReturnedQty;
  final double receivedQty;
  final String? remarks;

  SalesReturnItemData({
    required this.id,
    required this.productId,
    required this.returnQty,
    required this.receivableQty,
    required this.creditOnlyQty,
    required this.invoicedQty,
    required this.alreadyReturnedQty,
    required this.receivedQty,
    this.remarks,
  });

  factory SalesReturnItemData.fromJson(Map<String, dynamic> json) =>
      SalesReturnItemData(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        returnQty: (json['return_qty'] as num?)?.toDouble() ?? 0,
        receivableQty: (json['receivable_qty'] as num?)?.toDouble() ?? 0,
        creditOnlyQty: (json['credit_only_qty'] as num?)?.toDouble() ?? 0,
        invoicedQty: (json['invoiced_qty'] as num?)?.toDouble() ?? 0,
        alreadyReturnedQty:
            (json['already_returned_qty'] as num?)?.toDouble() ?? 0,
        receivedQty: (json['received_qty'] as num?)?.toDouble() ?? 0,
        remarks: json['remarks'] as String?,
      );
}

class SalesReturnItem {
  final String? id;
  final String productId;
  final String? salesInvoiceItemId;
  final double invoicedQty;
  final double alreadyReturnedQty;
  final double returnQty;
  final double receivableQty;
  final double creditOnlyQty;
  final String? remarks;

  SalesReturnItem({
    this.id,
    required this.productId,
    this.salesInvoiceItemId,
    this.invoicedQty = 0,
    this.alreadyReturnedQty = 0,
    required this.returnQty,
    double? receivableQty,
    this.creditOnlyQty = 0,
    this.remarks,
  }) : receivableQty = receivableQty ?? returnQty;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    if (salesInvoiceItemId != null) 'sales_invoice_item_id': salesInvoiceItemId,
    'invoiced_qty': invoicedQty,
    'already_returned_qty': alreadyReturnedQty,
    'return_qty': returnQty,
    'receivable_qty': receivableQty,
    'credit_only_qty': creditOnlyQty,
    if (remarks != null) 'remarks': remarks,
  };
}

class CreateSalesReturnPayload {
  final String customerId;
  final String rmaNumber;
  final String returnDate;
  final String? warehouseId;
  final String? reason;
  final String? referenceNumber;
  final bool? containsCreditOnlyGoods;
  final String status;
  final String? notes;
  final List<SalesReturnItem> items;

  CreateSalesReturnPayload({
    required this.customerId,
    required this.rmaNumber,
    required this.returnDate,
    this.warehouseId,
    this.reason,
    this.referenceNumber,
    this.containsCreditOnlyGoods,
    this.status = 'draft',
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'customer_id': customerId,
    'rma_number': rmaNumber,
    'return_date': returnDate,
    if (warehouseId != null) 'warehouse_id': warehouseId,
    if (reason != null) 'reason': reason,
    if (referenceNumber != null) 'reference_number': referenceNumber,
    if (containsCreditOnlyGoods != null)
      'contains_credit_only_goods': containsCreditOnlyGoods,
    'status': status,
    if (notes != null) 'notes': notes,
    'items': items.map((i) => i.toJson()).toList(),
  };
}

class SalesReturn {
  final String id;
  final String entityId;
  final String customerId;
  final String? customerName;
  final String rmaNumber;
  final String returnDate;
  final String status;
  final String? warehouseId;
  final String? reason;
  final String? referenceNumber;
  final bool containsCreditOnlyGoods;
  final String? notes;
  final String createdAt;
  final List<SalesReturnItemData> items;

  SalesReturn({
    required this.id,
    required this.entityId,
    required this.customerId,
    this.customerName,
    required this.rmaNumber,
    required this.returnDate,
    required this.status,
    this.warehouseId,
    this.reason,
    this.referenceNumber,
    this.containsCreditOnlyGoods = false,
    this.notes,
    required this.createdAt,
    this.items = const [],
  });

  factory SalesReturn.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return SalesReturn(
      id: json['id'] as String,
      entityId: json['entity_id'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer'] != null
          ? json['customer']['display_name'] as String?
          : null,
      rmaNumber: json['rma_number'] as String,
      returnDate: json['return_date'] as String,
      status: json['status'] as String? ?? 'draft',
      warehouseId: json['warehouse_id'] as String?,
      reason: json['reason'] as String?,
      referenceNumber: json['reference_number'] as String?,
      containsCreditOnlyGoods:
          json['contains_credit_only_goods'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(SalesReturnItemData.fromJson)
          .toList(),
    );
  }
}

class SalesReturnHistoryEntry {
  const SalesReturnHistoryEntry({
    required this.id,
    required this.kind,
    required this.timestamp,
    required this.message,
  });

  final String id;
  final String kind;
  final String timestamp;
  final String message;

  factory SalesReturnHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SalesReturnHistoryEntry(
      id: json['id']?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'sales_return',
      timestamp: json['timestamp']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}

/// How much of one product has been invoiced to a customer, and how much of it
/// they have already sent back. Backs the INVOICED / RETURNED columns on the
/// sales return form.
class CustomerItemHistory {
  final String productId;
  final double invoicedQty;
  final double returnedQty;

  const CustomerItemHistory({
    required this.productId,
    required this.invoicedQty,
    required this.returnedQty,
  });

  /// Quantity still open to return. Never negative — an over-return would
  /// otherwise read as a negative allowance.
  double get returnableQty {
    final remaining = invoicedQty - returnedQty;
    return remaining < 0 ? 0 : remaining;
  }

  static double _toDouble(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  factory CustomerItemHistory.fromJson(Map<String, dynamic> json) =>
      CustomerItemHistory(
        productId: json['product_id']?.toString() ?? '',
        invoicedQty: _toDouble(json['invoiced_qty']),
        returnedQty: _toDouble(json['returned_qty']),
      );
}
