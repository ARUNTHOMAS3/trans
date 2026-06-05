class InventoryAdjustment {
  final String id;
  final String productId;
  final String? productCode;
  final String? productName;
  final String? warehouseId;
  final String? warehouseName;
  final DateTime adjustmentDate;
  final String adjustmentType; // 'quantity' | 'value'
  final String reason;
  final double quantityBefore;
  final double quantityAdjusted;
  final double quantityAfter;
  final double costPrice;
  final double adjustmentValue;
  final String? accountId;
  final String? referenceNumber;
  final String? notes;
  final String? adjustedBy;
  final String? adjustedByName;
  final String? adjustedByEmail;
  final String? accountName;
  final String? approvedBy;
  final String? approvedByName;
  final String? approvedByEmail;
  final DateTime? approvedAt;
  final String status; // draft | submitted | approved | rejected | cancelled
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<InventoryAdjustmentItem> items;
  final List<InventoryAdjustmentAccountEntry> accountEntries;

  InventoryAdjustment({
    required this.id,
    required this.productId,
    this.productCode,
    this.productName,
    this.warehouseId,
    this.warehouseName,
    required this.adjustmentDate,
    this.adjustmentType = 'quantity',
    required this.reason,
    required this.quantityBefore,
    required this.quantityAdjusted,
    required this.quantityAfter,
    this.costPrice = 0.0,
    this.adjustmentValue = 0.0,
    this.accountId,
    this.referenceNumber,
    this.notes,
    this.adjustedBy,
    this.adjustedByName,
    this.adjustedByEmail,
    this.accountName,
    this.approvedBy,
    this.approvedByName,
    this.approvedByEmail,
    this.approvedAt,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
    this.items = const <InventoryAdjustmentItem>[],
    this.accountEntries = const <InventoryAdjustmentAccountEntry>[],
  });

  factory InventoryAdjustment.fromJson(Map<String, dynamic> json) {
    return InventoryAdjustment(
      id: json['id'],
      productId: json['product_id'],
      productCode: json['product_code'],
      productName: json['product_name'],
      warehouseId: json['warehouse_id'],
      warehouseName: json['warehouse_name'],
      adjustmentDate: DateTime.parse(json['adjustment_date']),
      adjustmentType: json['adjustment_type'] ?? 'quantity',
      reason: json['reason'],
      quantityBefore: double.parse(json['quantity_before'].toString()),
      quantityAdjusted: double.parse(json['quantity_adjusted'].toString()),
      quantityAfter: double.parse(json['quantity_after'].toString()),
      costPrice: double.parse((json['cost_price'] ?? 0).toString()),
      adjustmentValue: double.parse((json['adjustment_value'] ?? 0).toString()),
      accountId: json['account_id'],
      referenceNumber: json['reference_number'],
      notes: json['notes'],
      adjustedBy: json['adjusted_by'],
      adjustedByName: json['adjusted_by_name'],
      adjustedByEmail: json['adjusted_by_email'],
      accountName: json['account_name'],
      approvedBy: json['approved_by'],
      approvedByName: json['approved_by_name'],
      approvedByEmail: json['approved_by_email'],
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'].toString())
          : null,
      status: json['status'] ?? 'draft',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
          .map(
            (row) => InventoryAdjustmentItem.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(),
      accountEntries:
          (json['account_entries'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (row) => InventoryAdjustmentAccountEntry.fromJson(
                  Map<String, dynamic>.from(row as Map),
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_code': productCode,
      'product_name': productName,
      'warehouse_id': warehouseId,
      'warehouse_name': warehouseName,
      'adjustment_date': adjustmentDate.toIso8601String(),
      'adjustment_type': adjustmentType,
      'reason': reason,
      'quantity_before': quantityBefore.toString(),
      'quantity_adjusted': quantityAdjusted.toString(),
      'quantity_after': quantityAfter.toString(),
      'cost_price': costPrice.toString(),
      'adjustment_value': adjustmentValue.toString(),
      'account_id': accountId,
      'reference_number': referenceNumber,
      'notes': notes,
      'adjusted_by': adjustedBy,
      'adjusted_by_name': adjustedByName,
      'adjusted_by_email': adjustedByEmail,
      'account_name': accountName,
      'approved_by': approvedBy,
      'approved_by_name': approvedByName,
      'approved_by_email': approvedByEmail,
      'approved_at': approvedAt?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'items': items.map((row) => row.toJson()).toList(),
      'account_entries': accountEntries.map((row) => row.toJson()).toList(),
    };
  }

  bool get isIncrease => quantityAdjusted > 0;
  bool get isDecrease => quantityAdjusted < 0;
}

class InventoryAdjustmentItem {
  final String id;
  final String productId;
  final String? productName;
  final double quantityAdjusted;
  final double costPrice;
  final String? batchId;
  final String? batchReference;
  final List<InventoryAdjustmentBatchAllocation> batchAllocations;

  const InventoryAdjustmentItem({
    required this.id,
    required this.productId,
    this.productName,
    required this.quantityAdjusted,
    required this.costPrice,
    this.batchId,
    this.batchReference,
    this.batchAllocations = const <InventoryAdjustmentBatchAllocation>[],
  });

  factory InventoryAdjustmentItem.fromJson(Map<String, dynamic> json) {
    return InventoryAdjustmentItem(
      id: (json['id'] ?? '').toString(),
      productId: (json['product_id'] ?? '').toString(),
      productName: json['product_name']?.toString(),
      quantityAdjusted: double.parse(
        (json['quantity_adjusted'] ?? 0).toString(),
      ),
      costPrice: double.parse((json['cost_price'] ?? 0).toString()),
      batchId: json['batch_id']?.toString(),
      batchReference: json['batch_reference']?.toString(),
      batchAllocations:
          (json['batch_allocations'] as List<dynamic>? ?? const <dynamic>[])
              .map(
                (row) => InventoryAdjustmentBatchAllocation.fromJson(
                  Map<String, dynamic>.from(row as Map),
                ),
              )
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity_adjusted': quantityAdjusted,
      'cost_price': costPrice,
      'batch_id': batchId,
      'batch_reference': batchReference,
      'batch_allocations': batchAllocations.map((row) => row.toJson()).toList(),
    };
  }
}

class InventoryAdjustmentAccountEntry {
  final String accountId;
  final String? accountName;
  final double debit;
  final double credit;
  final String? description;

  const InventoryAdjustmentAccountEntry({
    required this.accountId,
    this.accountName,
    this.debit = 0,
    this.credit = 0,
    this.description,
  });

  factory InventoryAdjustmentAccountEntry.fromJson(Map<String, dynamic> json) {
    return InventoryAdjustmentAccountEntry(
      accountId: (json['account_id'] ?? '').toString(),
      accountName: json['account_name']?.toString(),
      debit: double.tryParse((json['debit'] ?? 0).toString()) ?? 0,
      credit: double.tryParse((json['credit'] ?? 0).toString()) ?? 0,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'account_id': accountId,
      'account_name': accountName,
      'debit': debit,
      'credit': credit,
      'description': description,
    };
  }
}

class InventoryAdjustmentBatchAllocation {
  final String? batchId;
  final String? batchNo;
  final String? batchReference;
  final String? manufacturerBatchNumber;
  final double quantityIn;
  final double quantityOut;
  final String? binId;
  final String? binCode;
  final String? unitPack;
  final double? mrp;
  final DateTime? expiryDate;
  final DateTime? mfdDate;

  const InventoryAdjustmentBatchAllocation({
    this.batchId,
    this.batchNo,
    this.batchReference,
    this.manufacturerBatchNumber,
    this.quantityIn = 0,
    this.quantityOut = 0,
    this.binId,
    this.binCode,
    this.unitPack,
    this.mrp,
    this.expiryDate,
    this.mfdDate,
  });

  factory InventoryAdjustmentBatchAllocation.fromJson(
    Map<String, dynamic> json,
  ) {
    return InventoryAdjustmentBatchAllocation(
      batchId: json['batch_id']?.toString(),
      batchNo: json['batch_no']?.toString(),
      batchReference: json['batch_reference']?.toString(),
      manufacturerBatchNumber: json['manufacture_batch_number']?.toString(),
      quantityIn: double.parse((json['quantity_in'] ?? 0).toString()),
      quantityOut: double.parse((json['quantity_out'] ?? 0).toString()),
      binId: json['bin_id']?.toString(),
      binCode: json['bin_code']?.toString(),
      unitPack: json['unit_pack']?.toString(),
      mrp: json['mrp'] != null ? double.tryParse(json['mrp'].toString()) : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString())
          : null,
      mfdDate: json['mfd_date'] != null
          ? DateTime.tryParse(json['mfd_date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batch_id': batchId,
      'batch_no': batchNo,
      'batch_reference': batchReference,
      'manufacture_batch_number': manufacturerBatchNumber,
      'quantity_in': quantityIn,
      'quantity_out': quantityOut,
      'bin_id': binId,
      'bin_code': binCode,
      'unit_pack': unitPack,
      'mrp': mrp,
      'expiry_date': expiryDate?.toIso8601String(),
      'mfd_date': mfdDate?.toIso8601String(),
    };
  }
}
