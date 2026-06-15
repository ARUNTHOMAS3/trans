/// A Purchase Receive tracks the receipt of goods against a Purchase Order.
/// Stock levels increase upon goods receipt (PRD §8.3).

class BatchInfo {
  final String batchNo;
  final String unitPack;
  final double mrp;
  final double ptr;
  final double quantity;
  final double foc;
  final String manufactureBatch;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;
  final String? binId;
  final String? binLabel;
  final String? hsnCode;

  BatchInfo({
    this.batchNo = '',
    this.unitPack = '',
    this.mrp = 0,
    this.ptr = 0,
    this.quantity = 0,
    this.foc = 0,
    this.manufactureBatch = '',
    this.manufactureDate,
    this.expiryDate,
    this.binId,
    this.binLabel,
    this.hsnCode,
  });

  BatchInfo copyWith({
    String? batchNo,
    String? unitPack,
    double? mrp,
    double? ptr,
    double? quantity,
    double? foc,
    String? manufactureBatch,
    DateTime? manufactureDate,
    DateTime? expiryDate,
    String? binId,
    String? binLabel,
    String? hsnCode,
  }) {
    return BatchInfo(
      batchNo: batchNo ?? this.batchNo,
      unitPack: unitPack ?? this.unitPack,
      mrp: mrp ?? this.mrp,
      ptr: ptr ?? this.ptr,
      quantity: quantity ?? this.quantity,
      foc: foc ?? this.foc,
      manufactureBatch: manufactureBatch ?? this.manufactureBatch,
      manufactureDate: manufactureDate ?? this.manufactureDate,
      expiryDate: expiryDate ?? this.expiryDate,
      binId: binId ?? this.binId,
      binLabel: binLabel ?? this.binLabel,
      hsnCode: hsnCode ?? this.hsnCode,
    );
  }

  Map<String, dynamic> toJson() => {
    'batch_no': batchNo,
    'unit_pack': unitPack,
    'mrp': mrp,
    'ptr': ptr,
    'quantity': quantity,
    'foc': foc,
    'manufacture_batch': manufactureBatch,
    if (manufactureDate != null) 'manufacture_date': manufactureDate!.toIso8601String(),
    if (expiryDate != null) 'expiry_date': expiryDate!.toIso8601String(),
    if (binId != null) 'bin_id': binId,
    if (binLabel != null) 'bin_label': binLabel,
    if (hsnCode != null) 'hsn_code': hsnCode,
  };

  factory BatchInfo.fromJson(Map<String, dynamic> json) {
    return BatchInfo(
      batchNo: json['batch_no'] as String? ?? '',
      unitPack: json['unit_pack'] as String? ?? '',
      mrp: (json['mrp'] as num?)?.toDouble() ?? 0,
      ptr: (json['ptr'] as num?)?.toDouble() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      foc: (json['foc'] as num?)?.toDouble() ?? (json['foc_qty'] as num?)?.toDouble() ?? 0,
      manufactureBatch: json['manufacture_batch'] as String? ?? '',
      manufactureDate: json['manufacture_date'] != null
          ? DateTime.parse(json['manufacture_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      binId: json['bin_id'] as String?,
      binLabel: json['bin_label'] as String?,
      hsnCode: json['hsn_code'] as String?,
    );
  }
}

class PurchaseReceiveItem {
  final String? itemId;
  final String itemName;
  final String? description;
  final double ordered;
  final double received;
  final double inTransit;
  final double cancelled;
  double quantityToReceive;
  List<BatchInfo> batches;
  final String? purchaseOrderId;
  final String? purchaseOrderNumber;
  final String? binId;
  final String? binLabel;
  final bool billed;

  PurchaseReceiveItem({
    this.itemId,
    this.itemName = '',
    this.description,
    this.ordered = 0,
    this.received = 0,
    this.inTransit = 0,
    this.cancelled = 0,
    this.quantityToReceive = 0,
    List<BatchInfo>? batches,
    this.purchaseOrderId,
    this.purchaseOrderNumber,
    this.binId,
    this.binLabel,
    this.billed = false,
  }) : batches = batches ?? [];

  PurchaseReceiveItem copyWith({
    String? itemId,
    String? itemName,
    String? description,
    double? ordered,
    double? received,
    double? inTransit,
    double? cancelled,
    double? quantityToReceive,
    List<BatchInfo>? batches,
    String? purchaseOrderId,
    String? purchaseOrderNumber,
    String? binId,
    String? binLabel,
    bool? billed,
  }) {
    return PurchaseReceiveItem(
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      ordered: ordered ?? this.ordered,
      received: received ?? this.received,
      inTransit: inTransit ?? this.inTransit,
      cancelled: cancelled ?? this.cancelled,
      quantityToReceive: quantityToReceive ?? this.quantityToReceive,
      batches: batches ?? this.batches,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      binId: binId ?? this.binId,
      binLabel: binLabel ?? this.binLabel,
      billed: billed ?? this.billed,
    );
  }

  Map<String, dynamic> toJson() => {
    'item_id': itemId,
    'item_name': itemName,
    'description': description,
    'ordered': ordered,
    'received': received,
    'in_transit': inTransit,
    'cancelled': cancelled,
    'quantity_to_receive': quantityToReceive,
    'batches': batches.map((b) => b.toJson()).toList(),
    if (binId != null) 'bin_id': binId,
    if (binLabel != null) 'bin_label': binLabel,
    'billed': billed,
  };

  factory PurchaseReceiveItem.fromJson(Map<String, dynamic> json) {
    return PurchaseReceiveItem(
      itemId: json['item_id'] as String?,
      itemName: json['item_name'] as String? ?? '',
      description: json['description'] as String?,
      ordered: (json['ordered'] as num?)?.toDouble() ?? 0,
      received: (json['received'] as num?)?.toDouble() ?? 0,
      inTransit: (json['in_transit'] as num?)?.toDouble() ?? 0,
      cancelled: (json['cancelled'] as num?)?.toDouble() ?? 0,
      quantityToReceive: (json['quantity_to_receive'] as num?)?.toDouble() ?? 0,
      batches:
          (json['batches'] as List<dynamic>?)
              ?.map((e) => BatchInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      purchaseOrderId: json['purchase_order_id'] as String?,
      purchaseOrderNumber: json['purchase_order_number'] as String?,
      binId: json['bin_id'] as String?,
      binLabel: json['bin_label'] as String?,
      billed: json['billed'] as bool? ?? false,
    );
  }
}

class PurchaseReceive {
  final String? id;
  final String purchaseReceiveNumber;
  final DateTime? receivedDate;
  final String? vendorId;
  final String? vendorName;
  final String? purchaseOrderId;
  final String? purchaseOrderNumber;
  final String? warehouseId;
  final String? transactionBinId;
  final String? transactionBinLabel;
  final String status; // 'draft' | 'received'
  final String? notes;
  final List<PurchaseReceiveItem> items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool billed;
  final double quantity;
  final String? billNo;
  final DateTime? billDate;
  final double invoiceTotal;

  double get totalQuantity =>
      items.fold(0, (sum, item) => sum + item.quantityToReceive);

  PurchaseReceive({
    this.id,
    this.purchaseReceiveNumber = '',
    this.receivedDate,
    this.vendorId,
    this.vendorName,
    this.purchaseOrderId,
    this.purchaseOrderNumber,
    this.warehouseId,
    this.transactionBinId,
    this.transactionBinLabel,
    this.status = 'draft',
    this.notes,
    List<PurchaseReceiveItem>? items,
    this.createdAt,
    this.updatedAt,
    this.billed = false,
    this.quantity = 0,
    this.billNo,
    this.billDate,
    this.invoiceTotal = 0,
  }) : items = items ?? [];

  PurchaseReceive copyWith({
    String? id,
    String? purchaseReceiveNumber,
    DateTime? receivedDate,
    String? vendorId,
    String? vendorName,
    String? purchaseOrderId,
    String? purchaseOrderNumber,
    String? warehouseId,
    String? transactionBinId,
    String? transactionBinLabel,
    String? status,
    String? notes,
    List<PurchaseReceiveItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? billed,
    double? quantity,
    String? billNo,
    DateTime? billDate,
    double? invoiceTotal,
  }) {
    return PurchaseReceive(
      id: id ?? this.id,
      purchaseReceiveNumber:
          purchaseReceiveNumber ?? this.purchaseReceiveNumber,
      receivedDate: receivedDate ?? this.receivedDate,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      purchaseOrderId: purchaseOrderId ?? this.purchaseOrderId,
      purchaseOrderNumber: purchaseOrderNumber ?? this.purchaseOrderNumber,
      warehouseId: warehouseId ?? this.warehouseId,
      transactionBinId: transactionBinId ?? this.transactionBinId,
      transactionBinLabel: transactionBinLabel ?? this.transactionBinLabel,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      billed: billed ?? this.billed,
      quantity: quantity ?? this.quantity,
      billNo: billNo ?? this.billNo,
      billDate: billDate ?? this.billDate,
      invoiceTotal: invoiceTotal ?? this.invoiceTotal,
    );
  }

  Map<String, dynamic> toJson() => {
    // Keep payload strictly DTO-safe for backend whitelist validation.
    'purchase_receive_number': purchaseReceiveNumber,
    if (receivedDate != null) 'received_date': receivedDate!.toIso8601String(),
    if (vendorName != null && vendorName!.isNotEmpty) 'vendor_name': vendorName,
    if (purchaseOrderId != null && purchaseOrderId!.isNotEmpty)
      'purchase_order_id': purchaseOrderId,
    if (purchaseOrderNumber != null && purchaseOrderNumber!.isNotEmpty)
      'purchase_order_number': purchaseOrderNumber,
    if (warehouseId != null && warehouseId!.isNotEmpty)
      'warehouse_id': warehouseId,
    if (transactionBinId != null && transactionBinId!.isNotEmpty)
      'transaction_bin_id': transactionBinId,
    if (transactionBinLabel != null && transactionBinLabel!.isNotEmpty)
      'transaction_bin_label': transactionBinLabel,
    'status': status,
    if (notes != null) 'notes': notes,
    if (items.isNotEmpty) 'items': items.map((i) => i.toJson()).toList(),
    if (billNo != null) 'bill_no': billNo,
    if (billDate != null) 'bill_date': billDate!.toIso8601String(),
    'invoice_total': invoiceTotal,
    'billed': billed,
  };

  factory PurchaseReceive.fromJson(Map<String, dynamic> json) {
    return PurchaseReceive(
      id: json['id'] as String?,
      purchaseReceiveNumber: json['purchase_receive_number'] as String? ?? '',
      receivedDate: json['received_date'] != null
          ? DateTime.tryParse(json['received_date'] as String)
          : null,
      vendorId: json['vendor_id'] as String?,
      vendorName: json['vendor_name'] as String?,
      purchaseOrderId: json['purchase_order_id'] as String?,
      purchaseOrderNumber: json['purchase_order_number'] as String?,
      warehouseId: json['warehouse_id'] as String?,
      transactionBinId: json['transaction_bin_id'] as String?,
      transactionBinLabel: json['transaction_bin_label'] as String?,
      status: json['status'] as String? ?? 'draft',
      notes: json['notes'] as String?,
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (e) => PurchaseReceiveItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          (json['purchases_purchase_receive_items'] as List<dynamic>?)
              ?.map(
                (e) => PurchaseReceiveItem.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      billed: json['billed'] as bool? ?? false,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      billNo: json['bill_no'] as String?,
      billDate: json['bill_date'] != null
          ? DateTime.tryParse(json['bill_date'] as String)
          : null,
      invoiceTotal: (json['invoice_total'] as num?)?.toDouble() ?? 0,
    );
  }
}
