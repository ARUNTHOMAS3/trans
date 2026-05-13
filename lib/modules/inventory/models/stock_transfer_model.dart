class StockTransfer {
  final String id;
  final String? transferNumber;
  final String fromWarehouseId;
  final String fromWarehouseName;
  final String toWarehouseId;
  final String toWarehouseName;
  final DateTime transferDate;
  final DateTime? expectedDeliveryDate;
  final String status; // draft, pending, in_transit, received, cancelled
  final List<StockTransferItem> items;
  final String? reference;
  final String? notes;
  final String? initiatedBy;
  final String? receivedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  StockTransfer({
    required this.id,
    this.transferNumber,
    required this.fromWarehouseId,
    required this.fromWarehouseName,
    required this.toWarehouseId,
    required this.toWarehouseName,
    required this.transferDate,
    this.expectedDeliveryDate,
    this.status = 'draft',
    this.items = const [],
    this.reference,
    this.notes,
    this.initiatedBy,
    this.receivedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    return StockTransfer(
      id: json['id'],
      transferNumber: json['transfer_number'],
      fromWarehouseId: json['from_warehouse_id'],
      fromWarehouseName: json['from_warehouse_name'],
      toWarehouseId: json['to_warehouse_id'],
      toWarehouseName: json['to_warehouse_name'],
      transferDate: DateTime.parse(json['transfer_date']),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'])
          : null,
      status: json['status'] ?? 'draft',
      items: (json['items'] as List?)
              ?.map((item) => StockTransferItem.fromJson(item))
              .toList() ??
          [],
      reference: json['reference'],
      notes: json['notes'],
      initiatedBy: json['initiated_by'],
      receivedBy: json['received_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transfer_number': transferNumber,
      'from_warehouse_id': fromWarehouseId,
      'from_warehouse_name': fromWarehouseName,
      'to_warehouse_id': toWarehouseId,
      'to_warehouse_name': toWarehouseName,
      'transfer_date': transferDate.toIso8601String(),
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'reference': reference,
      'notes': notes,
      'initiated_by': initiatedBy,
      'received_by': receivedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class StockTransferItem {
  final String? id;
  final String productId;
  final String? productCode;
  final String? productName;
  final double quantity;
  final double transferredQuantity;
  final double receivedQuantity;
  final String? uom;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? notes;

  StockTransferItem({
    this.id,
    required this.productId,
    this.productCode,
    this.productName,
    required this.quantity,
    this.transferredQuantity = 0.0,
    this.receivedQuantity = 0.0,
    this.uom,
    this.batchNumber,
    this.expiryDate,
    this.notes,
  });

  factory StockTransferItem.fromJson(Map<String, dynamic> json) {
    return StockTransferItem(
      id: json['id'],
      productId: json['product_id'],
      productCode: json['product_code'],
      productName: json['product_name'],
      quantity: double.parse(json['quantity'].toString()),
      transferredQuantity: double.parse((json['transferred_quantity'] ?? 0).toString()),
      receivedQuantity: double.parse((json['received_quantity'] ?? 0).toString()),
      uom: json['uom'],
      batchNumber: json['batch_number'],
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_code': productCode,
      'product_name': productName,
      'quantity': quantity.toString(),
      'transferred_quantity': transferredQuantity.toString(),
      'received_quantity': receivedQuantity.toString(),
      'uom': uom,
      'batch_number': batchNumber,
      'expiry_date': expiryDate?.toIso8601String(),
      'notes': notes,
    };
  }

  /// Check if item is fully transferred
  bool get isFullyTransferred => transferredQuantity >= quantity;

  /// Check if item is fully received
  bool get isFullyReceived => receivedQuantity >= quantity;
}
