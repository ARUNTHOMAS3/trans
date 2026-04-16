import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

class WarehouseStockData {
  final String warehouseId;
  final String productId;
  final String productCode;
  final String productName;
  final String? customerId;
  final double stock;
  final double quantityOnHand;
  final String? batchNo;
  final String? expiryDate;
  final String? salesOrderId;
  final String? salesOrderNumber;
  final String? customerName;
  final String? unitTitle;
  final double? quantityOrdered;
  final double? quantityToPick;
  final double? quantityPicked;
  final String? preferredBin;
  final double availableQuantity;

  WarehouseStockData({
    required this.warehouseId,
    required this.productId,
    required this.productCode,
    required this.productName,
    this.customerId,
    required this.stock,
    this.quantityOnHand = 0,
    this.batchNo,
    this.expiryDate,
    this.salesOrderId,
    this.salesOrderNumber,
    this.customerName,
    this.unitTitle,
    this.quantityOrdered,
    this.quantityToPick,
    this.quantityPicked,
    this.preferredBin,
    this.availableQuantity = 0,
  });

  WarehouseStockData copyWith({
    String? warehouseId,
    String? productId,
    String? productCode,
    String? productName,
    String? customerId,
    double? stock,
    double? quantityOnHand,
    String? batchNo,
    String? expiryDate,
    String? salesOrderId,
    String? salesOrderNumber,
    String? customerName,
    String? unitTitle,
    double? quantityOrdered,
    double? quantityToPick,
    double? quantityPicked,
    String? preferredBin,
    double? availableQuantity,
  }) {
    return WarehouseStockData(
      warehouseId: warehouseId ?? this.warehouseId,
      productId: productId ?? this.productId,
      productCode: productCode ?? this.productCode,
      productName: productName ?? this.productName,
      customerId: customerId ?? this.customerId,
      stock: stock ?? this.stock,
      quantityOnHand: quantityOnHand ?? this.quantityOnHand,
      batchNo: batchNo ?? this.batchNo,
      expiryDate: expiryDate ?? this.expiryDate,
      salesOrderId: salesOrderId ?? this.salesOrderId,
      salesOrderNumber: salesOrderNumber ?? this.salesOrderNumber,
      customerName: customerName ?? this.customerName,
      unitTitle: unitTitle ?? this.unitTitle,
      quantityOrdered: quantityOrdered ?? this.quantityOrdered,
      quantityToPick: quantityToPick ?? this.quantityToPick,
      quantityPicked: quantityPicked ?? this.quantityPicked,
      preferredBin: preferredBin ?? this.preferredBin,
      availableQuantity: availableQuantity ?? this.availableQuantity,
    );
  }

  factory WarehouseStockData.fromJson(Map<String, dynamic> json) {
    return WarehouseStockData(
      warehouseId: json['warehouseId'] as String? ?? json['warehouse_id'] as String? ?? '',
      productId: json['productId'] as String? ?? json['product_id'] as String? ?? '',
      productCode: json['productCode'] as String? ?? json['product_code'] as String? ?? json['sku'] as String? ?? '',
      productName: json['productName'] as String? ?? json['product_name'] as String? ?? '',
      customerId: json['customerId'] as String? ?? json['customer_id'] as String?,
      stock: (json['currentStock'] as num? ?? json['stock'] as num? ?? 0).toDouble(),
      quantityOnHand: (json['quantityOnHand'] as num? ?? json['quantity_on_hand'] as num? ?? 0).toDouble(),
      batchNo: json['batchNo'] as String? ?? json['batch_no'] as String?,
      expiryDate: json['expiryDate'] as String? ?? json['expiry_date'] as String?,
      salesOrderId: json['salesOrderId'] as String? ?? json['sales_order_id'] as String?,
      salesOrderNumber: json['salesOrderNumber'] as String? ?? json['sales_order_number'] as String? ?? json['orderNumber'] as String?,
      customerName: json['customerName'] as String? ?? json['customer_name'] as String?,
      unitTitle: json['unitTitle'] as String? ?? json['unit_title'] as String? ?? json['unit'] as String?,
      quantityOrdered: (json['quantityOrdered'] as num? ?? json['quantity_ordered'] as num?)?.toDouble(),
      quantityToPick: (json['quantityToPick'] as num? ?? json['quantity_to_pick'] as num?)?.toDouble(),
      quantityPicked: (json['quantityPicked'] as num? ?? json['quantity_picked'] as num?)?.toDouble(),
      preferredBin: json['preferredBin'] as String? ?? json['preferred_bin'] as String?,
      availableQuantity: (json['availableQuantity'] as num? ?? json['available_quantity'] as num? ?? 0).toDouble(),
    );
  }
}

final productStockInWarehouseProvider = FutureProvider.family<
  WarehouseStockData?,
  ({String productId, String warehouseId})
>((ref, args) async {
  // Returns a default/empty stock data for the given product and warehouse
  return WarehouseStockData(
    warehouseId: args.warehouseId,
    productId: args.productId,
    productCode: '',
    productName: '',
    stock: 0,
    quantityOnHand: 0,
    availableQuantity: 0,
  );
});

final stockByWarehouseProvider =
    FutureProvider.family<List<WarehouseStockData>, String>((ref, warehouseId) async {
  final apiClient = ref.watch(apiClientProvider);
  
  try {
    final response = await apiClient.get('/picklists/warehouse/$warehouseId/items');
    
    if (response.success) {
      late List<dynamic> itemsData;
      if (response.data is List) {
        itemsData = response.data as List<dynamic>;
      } else if (response.data is Map) {
        final dataMap = response.data as Map<String, dynamic>;
        itemsData = dataMap['data'] ?? dataMap['items'] ?? [];
      } else {
        return [];
      }
      
      final result = itemsData
          .map((itemJson) => WarehouseStockData.fromJson(itemJson as Map<String, dynamic>))
          .toList();
      // ignore: avoid_print
      print('[stockByWarehouseProvider] Loaded ${result.length} items for warehouse $warehouseId');
      return result;
    } else {
      return [];
    }
  } catch (e) {
    // ignore: avoid_print
    print('[stockByWarehouseProvider] Error loading items for $warehouseId: $e');
    return [];
  }
});

/// Note: allSalesOrderItemsProvider is now defined in sales_order_controller.dart 
/// to avoid duplication and utilize the real sales order data.
