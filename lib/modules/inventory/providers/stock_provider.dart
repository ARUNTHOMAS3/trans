import 'package:flutter_riverpod/flutter_riverpod.dart';

class WarehouseStockData {
  final String productId;
  final String productName;
  final String productCode;
  final String? unitTitle;
  final double availableQuantity;
  final double quantityOnHand;
  final String? batchNo;
  final String? salesOrderId;
  final String? salesOrderNumber;
  final String? customerId;
  final String? customerName;
  final double? quantityOrdered;
  final double? quantityToPick;
  final double? quantityPicked;

  const WarehouseStockData({
    this.productId = '',
    this.productName = '',
    this.productCode = '',
    this.unitTitle,
    this.availableQuantity = 0,
    this.quantityOnHand = 0,
    this.batchNo,
    this.salesOrderId,
    this.salesOrderNumber,
    this.customerId,
    this.customerName,
    this.quantityOrdered,
    this.quantityToPick,
    this.quantityPicked,
  });

  WarehouseStockData copyWith({
    String? productId,
    String? productName,
    String? productCode,
    String? unitTitle,
    double? availableQuantity,
    double? quantityOnHand,
    String? batchNo,
    String? salesOrderId,
    String? salesOrderNumber,
    String? customerId,
    String? customerName,
    double? quantityOrdered,
    double? quantityToPick,
    double? quantityPicked,
  }) {
    return WarehouseStockData(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unitTitle: unitTitle ?? this.unitTitle,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      batchNo: batchNo ?? this.batchNo,
      salesOrderId: salesOrderId ?? this.salesOrderId,
      salesOrderNumber: salesOrderNumber ?? this.salesOrderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      quantityOrdered: quantityOrdered ?? this.quantityOrdered,
      quantityToPick: quantityToPick ?? this.quantityToPick,
      quantityPicked: quantityPicked ?? this.quantityPicked,
    );
  }

  factory WarehouseStockData.fromJson(Map<String, dynamic> json) {
    return WarehouseStockData(
      productId: json['product_id'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      productCode: json['product_code'] as String? ?? '',
      unitTitle: json['unit_title'] as String?,
      availableQuantity: (json['available_quantity'] as num?)?.toDouble() ?? 0,
      quantityOnHand: (json['quantity_on_hand'] as num?)?.toDouble() ?? 0,
      batchNo: json['batch_no'] as String?,
      salesOrderId: json['sales_order_id'] as String?,
      salesOrderNumber: json['sales_order_number'] as String?,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      quantityOrdered: (json['quantity_ordered'] as num?)?.toDouble(),
      quantityToPick: (json['quantity_to_pick'] as num?)?.toDouble(),
      quantityPicked: (json['quantity_picked'] as num?)?.toDouble(),
    );
  }
}

final productStockInWarehouseProvider = FutureProvider.family<
  WarehouseStockData?,
  ({String productId, String warehouseId})
>((ref, args) async {
  return const WarehouseStockData();
});

final stockByWarehouseProvider =
    FutureProvider.family<List<WarehouseStockData>, String>((ref, warehouseId) async {
  return const [];
});

/// Stub — returns an empty list until SO items are wired to a real provider.
final allSalesOrderItemsProvider =
    FutureProvider<List<WarehouseStockData>>((ref) async => const []);
