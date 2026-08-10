bool isUuid(String? str) {
  if (str == null || str.trim().isEmpty) return false;
  return RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(str.trim());
}

class PurchaseReturnItemBatch {
  final String? id;
  final String? purchaseReturnItemId;
  final String batchId;
  final String layerId;
  final String warehouseId;
  final String? binId;
  final double quantityOut;
  final double focQty;
  final double damageQty;
  final String? unitPack;
  final double? mrp;
  final double? purchaseRate;
  final DateTime? expiryDate;
  final DateTime? manufactureDate;
  final String? manufactureBatchNo;
  final String? remarks;
  final DateTime? createdAt;

  const PurchaseReturnItemBatch({
    this.id,
    this.purchaseReturnItemId,
    required this.batchId,
    required this.layerId,
    required this.warehouseId,
    this.binId,
    required this.quantityOut,
    this.focQty = 0,
    this.damageQty = 0,
    this.unitPack,
    this.mrp,
    this.purchaseRate,
    this.expiryDate,
    this.manufactureDate,
    this.manufactureBatchNo,
    this.remarks,
    this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        if (isUuid(id)) 'id': id,
        if (isUuid(purchaseReturnItemId))
          'purchase_return_item_id': purchaseReturnItemId,
        if (isUuid(batchId)) 'batch_id': batchId,
        if (isUuid(layerId)) 'layer_id': layerId,
        if (isUuid(warehouseId)) 'warehouse_id': warehouseId,
        if (isUuid(binId)) 'bin_id': binId,
        'quantity_out': quantityOut,
        'foc_qty': focQty,
        'damage_qty': damageQty,
        if (unitPack != null) 'unit_pack': unitPack,
        if (mrp != null) 'mrp': mrp,
        if (purchaseRate != null) 'purchase_rate': purchaseRate,
        if (expiryDate != null)
          'expiry_date': expiryDate!.toIso8601String().split('T').first,
        if (manufactureDate != null)
          'manufacture_date':
              manufactureDate!.toIso8601String().split('T').first,
        if (manufactureBatchNo != null)
          'manufacture_batch_no': manufactureBatchNo,
        if (remarks != null) 'remarks': remarks,
      };

  factory PurchaseReturnItemBatch.fromJson(Map<String, dynamic> json) {
    return PurchaseReturnItemBatch(
      id: json['id'] as String?,
      purchaseReturnItemId: json['purchase_return_item_id'] as String?,
      batchId: json['batch_id'] as String? ?? '',
      layerId: json['layer_id'] as String? ?? '',
      warehouseId: json['warehouse_id'] as String? ?? '',
      binId: json['bin_id'] as String?,
      quantityOut: (json['quantity_out'] as num?)?.toDouble() ?? 0,
      focQty: (json['foc_qty'] as num?)?.toDouble() ?? 0,
      damageQty: (json['damage_qty'] as num?)?.toDouble() ?? 0,
      unitPack: json['unit_pack'] as String?,
      mrp: (json['mrp'] as num?)?.toDouble(),
      purchaseRate: (json['purchase_rate'] as num?)?.toDouble(),
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
      manufactureDate: json['manufacture_date'] != null
          ? DateTime.tryParse(json['manufacture_date'] as String)
          : null,
      manufactureBatchNo: json['manufacture_batch_no'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class PurchaseReturnItem {
  final String? id;
  final String? purchaseReturnId;
  final String? itemId; // Maps to product_id in DB
  final String? billItemId;
  final String? accountId;
  final String itemName;
  final String? description;
  final String? unit;
  final double orderedQty; // UI alias for billed_qty
  final double returnQty; // UI alias for quantity_to_return_qty
  final double billedQty;
  final double returnedQty;
  final double quantityToReturnQty;
  final double creditedQty;
  final double pendingCreditQty;
  final double rate;
  final double discountPercent;
  final double discountAmount;
  final double amount; // UI alias for line_total
  final double lineTotal;
  final String? taxRateId; // Maps to tax_id in DB
  final String? taxRateName;
  final double taxAmount;
  final String? warehouseId;
  final String? warehouseName;
  final String? batchNumber;
  final String? reason;
  final String? remarks;
  final List<PurchaseReturnItemBatch> batches;

  const PurchaseReturnItem({
    this.id,
    this.purchaseReturnId,
    this.itemId,
    this.billItemId,
    this.accountId,
    this.itemName = '',
    this.description,
    this.unit,
    this.orderedQty = 0,
    this.returnQty = 0,
    this.billedQty = 0,
    this.returnedQty = 0,
    this.quantityToReturnQty = 0,
    this.creditedQty = 0,
    this.pendingCreditQty = 0,
    this.rate = 0,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.amount = 0,
    this.lineTotal = 0,
    this.taxRateId,
    this.taxRateName,
    this.taxAmount = 0,
    this.warehouseId,
    this.warehouseName,
    this.batchNumber,
    this.reason,
    this.remarks,
    this.batches = const [],
  });

  PurchaseReturnItem copyWith({
    String? id,
    String? purchaseReturnId,
    String? itemId,
    String? billItemId,
    String? accountId,
    String? itemName,
    String? description,
    String? unit,
    double? orderedQty,
    double? returnQty,
    double? billedQty,
    double? returnedQty,
    double? quantityToReturnQty,
    double? creditedQty,
    double? pendingCreditQty,
    double? rate,
    double? discountPercent,
    double? discountAmount,
    double? amount,
    double? lineTotal,
    String? taxRateId,
    String? taxRateName,
    double? taxAmount,
    String? warehouseId,
    String? warehouseName,
    String? batchNumber,
    String? reason,
    String? remarks,
    List<PurchaseReturnItemBatch>? batches,
  }) {
    return PurchaseReturnItem(
      id: id ?? this.id,
      purchaseReturnId: purchaseReturnId ?? this.purchaseReturnId,
      itemId: itemId ?? this.itemId,
      billItemId: billItemId ?? this.billItemId,
      accountId: accountId ?? this.accountId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      orderedQty: orderedQty ?? this.orderedQty,
      returnQty: returnQty ?? this.returnQty,
      billedQty: billedQty ?? this.billedQty,
      returnedQty: returnedQty ?? this.returnedQty,
      quantityToReturnQty: quantityToReturnQty ?? this.quantityToReturnQty,
      creditedQty: creditedQty ?? this.creditedQty,
      pendingCreditQty: pendingCreditQty ?? this.pendingCreditQty,
      rate: rate ?? this.rate,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      amount: amount ?? this.amount,
      lineTotal: lineTotal ?? this.lineTotal,
      taxRateId: taxRateId ?? this.taxRateId,
      taxRateName: taxRateName ?? this.taxRateName,
      taxAmount: taxAmount ?? this.taxAmount,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      batchNumber: batchNumber ?? this.batchNumber,
      reason: reason ?? this.reason,
      remarks: remarks ?? this.remarks,
      batches: batches ?? this.batches,
    );
  }

  Map<String, dynamic> toJson() {
    final effectiveBilledQty = billedQty > 0 ? billedQty : orderedQty;
    final effectiveReturnQty =
        quantityToReturnQty > 0 ? quantityToReturnQty : returnQty;
    final effectiveLineTotal = lineTotal > 0 ? lineTotal : amount;

    return {
      if (isUuid(id)) 'id': id,
      if (isUuid(purchaseReturnId)) 'purchase_return_id': purchaseReturnId,
      if (isUuid(itemId)) 'product_id': itemId,
      if (isUuid(billItemId)) 'bill_item_id': billItemId,
      if (isUuid(accountId)) 'account_id': accountId,
      'billed_qty': effectiveBilledQty,
      'returned_qty': returnedQty,
      'quantity_to_return_qty': effectiveReturnQty,
      'credited_qty': creditedQty,
      'pending_credit_qty': pendingCreditQty,
      'rate': rate,
      'discount_percent': discountPercent,
      'discount_amount': discountAmount,
      if (isUuid(taxRateId)) 'tax_id': taxRateId,
      'tax_amount': taxAmount,
      'line_total': effectiveLineTotal,
      if (remarks != null || description != null)
        'remarks': remarks ?? description,
    };
  }

  factory PurchaseReturnItem.fromJson(Map<String, dynamic> json) {
    final bQty = (json['billed_qty'] as num?)?.toDouble() ??
        (json['ordered_qty'] as num?)?.toDouble() ??
        0;
    final qToReturn = (json['quantity_to_return_qty'] as num?)?.toDouble() ??
        (json['return_qty'] as num?)?.toDouble() ??
        0;
    final lTotal = (json['line_total'] as num?)?.toDouble() ??
        (json['amount'] as num?)?.toDouble() ??
        0;

    final rawBatches =
        json['purchase_return_item_batches'] as List<dynamic>? ??
            json['batches'] as List<dynamic>?;

    final parsedItemName = (json['item_name'] as String?)?.isNotEmpty == true
        ? json['item_name'] as String
        : ((json['product_name'] as String?)?.isNotEmpty == true
            ? json['product_name'] as String
            : ((json['products'] is Map)
                ? ((json['products']['product_name'] ?? json['products']['name'] ?? json['products']['item_name']) as String?)
                : null) ?? '');

    final parsedDesc = (json['description'] as String?)?.isNotEmpty == true
        ? json['description'] as String
        : ((json['remarks'] as String?)?.isNotEmpty == true
            ? json['remarks'] as String
            : ((json['products'] is Map)
                ? ((json['products']['description'] ?? json['products']['remarks']) as String?)
                : null));

    return PurchaseReturnItem(
      id: json['id'] as String?,
      purchaseReturnId: json['purchase_return_id'] as String?,
      itemId: (json['product_id'] ?? json['item_id']) as String?,
      billItemId: json['bill_item_id'] as String?,
      accountId: json['account_id'] as String?,
      itemName: parsedItemName,
      description: parsedDesc,
      unit: json['unit'] as String?,
      orderedQty: bQty,
      returnQty: qToReturn,
      billedQty: bQty,
      returnedQty: (json['returned_qty'] as num?)?.toDouble() ?? 0,
      quantityToReturnQty: qToReturn,
      creditedQty: (json['credited_qty'] as num?)?.toDouble() ?? 0,
      pendingCreditQty: (json['pending_credit_qty'] as num?)?.toDouble() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      discountPercent: (json['discount_percent'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      amount: lTotal,
      lineTotal: lTotal,
      taxRateId: (json['tax_id'] ?? json['tax_rate_id']) as String?,
      taxRateName: json['tax_rate_name'] as String?,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      warehouseId: json['warehouse_id'] as String?,
      warehouseName: json['warehouse_name'] as String?,
      batchNumber: json['batch_number'] as String?,
      reason: json['reason'] as String?,
      remarks: json['remarks'] as String?,
      batches: rawBatches
              ?.whereType<Map<String, dynamic>>()
              .map(PurchaseReturnItemBatch.fromJson)
              .toList() ??
          [],
    );
  }
}

extension PurchaseReturnItemCopyWith on PurchaseReturnItem {
  PurchaseReturnItem copyWith({
    String? id,
    String? purchaseReturnId,
    String? itemId,
    String? billItemId,
    String? accountId,
    String? itemName,
    String? description,
    String? unit,
    double? orderedQty,
    double? returnQty,
    double? billedQty,
    double? returnedQty,
    double? quantityToReturnQty,
    double? creditedQty,
    double? pendingCreditQty,
    double? rate,
    double? discountPercent,
    double? discountAmount,
    double? amount,
    double? lineTotal,
    String? taxRateId,
    String? taxRateName,
    double? taxAmount,
    String? warehouseId,
    String? warehouseName,
    String? batchNumber,
    String? reason,
    String? remarks,
    List<PurchaseReturnItemBatch>? batches,
  }) {
    return PurchaseReturnItem(
      id: id ?? this.id,
      purchaseReturnId: purchaseReturnId ?? this.purchaseReturnId,
      itemId: itemId ?? this.itemId,
      billItemId: billItemId ?? this.billItemId,
      accountId: accountId ?? this.accountId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      unit: unit ?? this.unit,
      orderedQty: orderedQty ?? this.orderedQty,
      returnQty: returnQty ?? this.returnQty,
      billedQty: billedQty ?? this.billedQty,
      returnedQty: returnedQty ?? this.returnedQty,
      quantityToReturnQty: quantityToReturnQty ?? this.quantityToReturnQty,
      creditedQty: creditedQty ?? this.creditedQty,
      pendingCreditQty: pendingCreditQty ?? this.pendingCreditQty,
      rate: rate ?? this.rate,
      discountPercent: discountPercent ?? this.discountPercent,
      discountAmount: discountAmount ?? this.discountAmount,
      amount: amount ?? this.amount,
      lineTotal: lineTotal ?? this.lineTotal,
      taxRateId: taxRateId ?? this.taxRateId,
      taxRateName: taxRateName ?? this.taxRateName,
      taxAmount: taxAmount ?? this.taxAmount,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      batchNumber: batchNumber ?? this.batchNumber,
      reason: reason ?? this.reason,
      remarks: remarks ?? this.remarks,
      batches: batches ?? this.batches,
    );
  }
}

extension PurchaseReturnCopyWith on PurchaseReturn {
  PurchaseReturn copyWith({
    String? id,
    String? entityId,
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
    String? referenceNumber,
    String? reason,
    String? subject,
    String? status,
    String? creditStatus,
    String? notes,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? adjustmentAmount,
    double? total,
    String? createdBy,
    String? approvedBy,
    DateTime? approvedAt,
    List<PurchaseReturnItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseReturn(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      returnNumber: returnNumber ?? this.returnNumber,
      returnDate: returnDate ?? this.returnDate,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      purchaseReceiveId: purchaseReceiveId ?? this.purchaseReceiveId,
      purchaseReceiveNumber: purchaseReceiveNumber ?? this.purchaseReceiveNumber,
      billId: billId ?? this.billId,
      billNumber: billNumber ?? this.billNumber,
      warehouseId: warehouseId ?? this.warehouseId,
      warehouseName: warehouseName ?? this.warehouseName,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      reason: reason ?? this.reason,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      creditStatus: creditStatus ?? this.creditStatus,
      notes: notes ?? this.notes,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      adjustmentAmount: adjustmentAmount ?? this.adjustmentAmount,
      total: total ?? this.total,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PurchaseReturn {
  final String? id;
  final String? entityId;
  final String returnNumber; // Maps to purchase_return_number
  final DateTime? returnDate; // Maps to purchase_return_date
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
  final String? referenceNumber;
  final String? reason;
  final String? subject;
  final String status; // 'draft', 'confirmed', 'vendor_received', etc.
  final String creditStatus; // 'pending', etc.
  final String? notes;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double adjustmentAmount;
  final double total; // Maps to total_amount
  final String? createdBy;
  final String? approvedBy;
  final DateTime? approvedAt;
  final List<PurchaseReturnItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get totalReturnQty =>
      items.fold(0.0, (sum, i) => sum + i.returnQty);

  const PurchaseReturn({
    this.id,
    this.entityId,
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
    this.referenceNumber,
    this.reason,
    this.subject,
    this.status = 'draft',
    this.creditStatus = 'pending',
    this.notes,
    this.subtotal = 0,
    this.discountAmount = 0,
    this.taxAmount = 0,
    this.adjustmentAmount = 0,
    this.total = 0,
    this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.items = const [],
    this.createdAt,
    this.updatedAt,
  });

  PurchaseReturn copyWith({
    String? id,
    String? entityId,
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
    String? referenceNumber,
    String? reason,
    String? subject,
    String? status,
    String? creditStatus,
    String? notes,
    double? subtotal,
    double? discountAmount,
    double? taxAmount,
    double? adjustmentAmount,
    double? total,
    String? createdBy,
    String? approvedBy,
    DateTime? approvedAt,
    List<PurchaseReturnItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PurchaseReturn(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
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
      referenceNumber: referenceNumber ?? this.referenceNumber,
      reason: reason ?? this.reason,
      subject: subject ?? this.subject,
      status: status ?? this.status,
      creditStatus: creditStatus ?? this.creditStatus,
      notes: notes ?? this.notes,
      subtotal: subtotal ?? this.subtotal,
      discountAmount: discountAmount ?? this.discountAmount,
      taxAmount: taxAmount ?? this.taxAmount,
      adjustmentAmount: adjustmentAmount ?? this.adjustmentAmount,
      total: total ?? this.total,
      createdBy: createdBy ?? this.createdBy,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        if (isUuid(id)) 'id': id,
        if (isUuid(entityId)) 'entity_id': entityId,
        if (isUuid(vendorId)) 'vendor_id': vendorId,
        if (isUuid(warehouseId)) 'warehouse_id': warehouseId,
        'purchase_return_number': returnNumber,
        'purchase_return_date': (returnDate ?? DateTime.now())
            .toIso8601String()
            .split('T')
            .first,
        if (isUuid(billId)) 'bill_id': billId,
        if (referenceNumber != null) 'reference_number': referenceNumber,
        if (reason != null) 'reason': reason,
        if (subject != null) 'subject': subject,
        if (notes != null) 'notes': notes,
        'subtotal': subtotal,
        'discount_amount': discountAmount,
        'tax_amount': taxAmount,
        'adjustment_amount': adjustmentAmount,
        'total_amount': total,
        'credit_status': creditStatus,
        'status': status,
        if (isUuid(createdBy)) 'created_by': createdBy,
        if (isUuid(approvedBy)) 'approved_by': approvedBy,
        if (approvedAt != null) 'approved_at': approvedAt!.toIso8601String(),
      };

  factory PurchaseReturn.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['purchase_return_items'] ?? json['items']) as List<dynamic>?;
    final parsedVendorName = (json['vendor_name'] as String?)?.isNotEmpty == true
        ? json['vendor_name'] as String
        : ((json['vendors'] is Map)
            ? ((json['vendors']['display_name'] ?? json['vendors']['company_name'] ?? json['vendors']['name']) as String?)
            : null);

    return PurchaseReturn(
      id: json['id'] as String?,
      entityId: json['entity_id'] as String?,
      returnNumber: (json['purchase_return_number'] ?? json['return_number']) as String? ?? '',
      returnDate: json['purchase_return_date'] != null
          ? DateTime.tryParse(json['purchase_return_date'] as String)
          : (json['return_date'] != null
              ? DateTime.tryParse(json['return_date'] as String)
              : null),
      vendorId: json['vendor_id'] as String?,
      vendorName: parsedVendorName,
      purchaseOrderId: json['purchase_order_id'] as String?,
      purchaseOrderNumber: json['purchase_order_number'] as String?,
      purchaseReceiveId: json['purchase_receive_id'] as String?,
      purchaseReceiveNumber: json['purchase_receive_number'] as String?,
      billId: json['bill_id'] as String?,
      billNumber: json['bill_number'] as String?,
      warehouseId: json['warehouse_id'] as String?,
      warehouseName: json['warehouse_name'] as String?,
      referenceNumber: json['reference_number'] as String?,
      reason: json['reason'] as String?,
      subject: json['subject'] as String?,
      status: json['status'] as String? ?? 'draft',
      creditStatus: json['credit_status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0,
      adjustmentAmount: (json['adjustment_amount'] as num?)?.toDouble() ?? 0,
      total: (json['total_amount'] ?? json['total'] as num?)?.toDouble() ?? 0,
      createdBy: json['created_by'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'] as String)
          : null,
      items: rawItems
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
