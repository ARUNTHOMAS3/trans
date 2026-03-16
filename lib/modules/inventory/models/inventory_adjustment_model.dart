class InventoryAdjustment {
  final String id;
  final String productId;
  final String? productCode;
  final String? productName;
  final String? warehouseId;
  final String? warehouseName;
  final DateTime adjustmentDate;
  final String reason; // stocktake, damage, theft, expiry, receipt, issue
  final double quantityBefore;
  final double quantityAdjusted;
  final double quantityAfter;
  final String? referenceNumber;
  final String? notes;
  final String? adjustedBy;
  final String status; // draft, approved, rejected, cancelled
  final DateTime createdAt;
  final DateTime updatedAt;

  InventoryAdjustment({
    required this.id,
    required this.productId,
    this.productCode,
    this.productName,
    this.warehouseId,
    this.warehouseName,
    required this.adjustmentDate,
    required this.reason,
    required this.quantityBefore,
    required this.quantityAdjusted,
    required this.quantityAfter,
    this.referenceNumber,
    this.notes,
    this.adjustedBy,
    this.status = 'draft',
    required this.createdAt,
    required this.updatedAt,
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
      reason: json['reason'],
      quantityBefore: double.parse(json['quantity_before'].toString()),
      quantityAdjusted: double.parse(json['quantity_adjusted'].toString()),
      quantityAfter: double.parse(json['quantity_after'].toString()),
      referenceNumber: json['reference_number'],
      notes: json['notes'],
      adjustedBy: json['adjusted_by'],
      status: json['status'] ?? 'draft',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
      'reason': reason,
      'quantity_before': quantityBefore.toString(),
      'quantity_adjusted': quantityAdjusted.toString(),
      'quantity_after': quantityAfter.toString(),
      'reference_number': referenceNumber,
      'notes': notes,
      'adjusted_by': adjustedBy,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get adjustment type (positive or negative)
  bool get isIncrease => quantityAdjusted > 0;
  bool get isDecrease => quantityAdjusted < 0;
}
