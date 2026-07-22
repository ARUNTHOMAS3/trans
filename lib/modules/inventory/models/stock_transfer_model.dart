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
  final double? totalQuantity;

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
    this.totalQuantity,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) {
    return StockTransfer(
      id: json['id'],
      transferNumber: json['transfer_no'] ?? json['transfer_number'],
      fromWarehouseId:
          json['source_warehouse_id'] ?? json['from_warehouse_id'] ?? '',
      fromWarehouseName:
          json['source_warehouse_name'] ?? json['from_warehouse_name'] ?? '',
      toWarehouseId:
          json['destination_warehouse_id'] ?? json['to_warehouse_id'] ?? '',
      toWarehouseName:
          json['destination_warehouse_name'] ?? json['to_warehouse_name'] ?? '',
      transferDate: DateTime.parse(json['transfer_date']),
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'])
          : null,
      status: json['status'] ?? 'draft',
      items:
          (json['items'] as List?)
              ?.map((item) => StockTransferItem.fromJson(item))
              .toList() ??
          [],
      reference: json['reference'],
      notes: json['reason'] ?? json['notes'],
      initiatedBy: json['initiated_by'],
      receivedBy: json['received_by'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      totalQuantity: double.tryParse((json['total_qty'] ?? '0').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'transfer_no': transferNumber,
      'source_warehouse_id': fromWarehouseId,
      'destination_warehouse_id': toWarehouseId,
      'transfer_date': transferDate.toIso8601String(),
      'expected_delivery_date': expectedDeliveryDate?.toIso8601String(),
      'status': status,
      'items': items.map((item) => item.toJson()).toList(),
      'reason': notes,
    };
  }
}

class StockTransferItem {
  final String? id;
  final String productId;
  final String? productCode;
  final String? productName;
  final String? hsnSac;
  final double quantity;
  final double transferredQuantity;
  final double receivedQuantity;
  final double? rate;
  final String? uom;
  final String? batchNumber;
  final DateTime? expiryDate;
  final String? notes;
  final List<TransferOrderSourceBatch> sourceBatches;
  final List<TransferOrderDestinationBatch> destinationBatches;

  StockTransferItem({
    this.id,
    required this.productId,
    this.productCode,
    this.productName,
    this.hsnSac,
    required this.quantity,
    this.transferredQuantity = 0.0,
    this.receivedQuantity = 0.0,
    this.rate,
    this.uom,
    this.batchNumber,
    this.expiryDate,
    this.notes,
    this.sourceBatches = const [],
    this.destinationBatches = const [],
  });

  factory StockTransferItem.fromJson(Map<String, dynamic> json) {
    return StockTransferItem(
      id: json['id'],
      productId: json['product_id'],
      productCode: json['product_code'],
      productName: json['product_name'],
      hsnSac: json['hsn_sac']?.toString(),
      quantity:
          double.tryParse(
            (json['qty_requested'] ?? json['quantity'] ?? 0).toString(),
          ) ??
          0.0,
      transferredQuantity:
          double.tryParse(
            (json['qty_transferred'] ?? json['transferred_quantity'] ?? 0)
                .toString(),
          ) ??
          0.0,
      receivedQuantity:
          double.tryParse(
            (json['qty_received'] ?? json['received_quantity'] ?? 0).toString(),
          ) ??
          0.0,
      rate: double.tryParse(
        (json['rate'] ?? json['purchase_rate'] ?? 0).toString(),
      ),
      uom: json['unit'] ?? json['uom'],
      batchNumber: json['batch_number'],
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'])
          : null,
      notes: json['notes'],
      sourceBatches:
          (json['source_batches'] as List?)
              ?.whereType<Map>()
              .map(
                (row) => TransferOrderSourceBatch.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList() ??
          const [],
      destinationBatches:
          (json['destination_batches'] as List?)
              ?.whereType<Map>()
              .map(
                (row) => TransferOrderDestinationBatch.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'qty_requested': quantity,
      'qty_transferred': transferredQuantity,
      'unit': uom,
      'hsn_sac': hsnSac,
      'rate': rate,
      'source_batches': sourceBatches.map((row) => row.toJson()).toList(),
      'destination_batches': destinationBatches
          .map((row) => row.toJson())
          .toList(),
    };
  }

  double get amount => (rate ?? 0) * transferredQuantity;

  /// Check if item is fully transferred
  bool get isFullyTransferred => transferredQuantity >= quantity;

  /// Check if item is fully received
  bool get isFullyReceived => receivedQuantity >= quantity;
}

class TransferOrderSourceBatch {
  final String batchId;
  final String layerId;
  final String warehouseId;
  final String binId;
  final double qty;

  const TransferOrderSourceBatch({
    required this.batchId,
    required this.layerId,
    required this.warehouseId,
    required this.binId,
    required this.qty,
  });

  factory TransferOrderSourceBatch.fromJson(Map<String, dynamic> json) {
    return TransferOrderSourceBatch(
      batchId: (json['batch_id'] ?? '').toString(),
      layerId: (json['layer_id'] ?? '').toString(),
      warehouseId: (json['warehouse_id'] ?? '').toString(),
      binId: (json['bin_id'] ?? '').toString(),
      qty: double.tryParse((json['qty'] ?? 0).toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_id': batchId,
      'layer_id': layerId,
      'warehouse_id': warehouseId,
      'bin_id': binId,
      'qty': qty,
    };
  }
}

class TransferOrderDestinationBatch {
  final String sourceBatchId;
  final String destinationBatchId;
  final String destinationWarehouseId;
  final String destinationBinId;
  final double qty;

  const TransferOrderDestinationBatch({
    required this.sourceBatchId,
    required this.destinationBatchId,
    required this.destinationWarehouseId,
    required this.destinationBinId,
    required this.qty,
  });

  factory TransferOrderDestinationBatch.fromJson(Map<String, dynamic> json) {
    return TransferOrderDestinationBatch(
      sourceBatchId: (json['source_batch_id'] ?? '').toString(),
      destinationBatchId: (json['destination_batch_id'] ?? '').toString(),
      destinationWarehouseId: (json['destination_warehouse_id'] ?? '')
          .toString(),
      destinationBinId: (json['destination_bin_id'] ?? '').toString(),
      qty: double.tryParse((json['qty'] ?? 0).toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source_batch_id': sourceBatchId,
      'destination_batch_id': destinationBatchId,
      'destination_warehouse_id': destinationWarehouseId,
      'destination_bin_id': destinationBinId,
      'qty': qty,
    };
  }
}
