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
      availableQuantity: availableQuantity ?? this.availableQuantity,
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
  final apiClient = ApiClient();
  
  try {
    final response = await apiClient.get('/picklists/warehouse/$warehouseId/items');
    
    if (response.success) {
      // Handle both direct list and wrapped response
      late List<dynamic> itemsData;
      if (response.data is List) {
        itemsData = response.data as List<dynamic>;
      } else if (response.data is Map) {
        final dataMap = response.data as Map<String, dynamic>;
        itemsData = dataMap['data'] ?? dataMap['items'] ?? [];
      } else {
        return [];
      }
      
      return itemsData.map((itemJson) {
        final json = itemJson as Map<String, dynamic>;
        return WarehouseStockData(
          warehouseId: json['warehouseId'] ?? warehouseId,
          productId: json['productId'] ?? '',
          productCode: json['productCode'] ?? json['sku'] ?? '',
          productName: json['productName'] ?? '',
          customerId: json['customerId'],
          stock: (json['currentStock'] ?? 0).toDouble(),
          quantityOnHand: (json['currentStock'] ?? 0).toDouble(),
          batchNo: json['batchNo'],
          expiryDate: json['expiryDate'],
          unitTitle: json['unit'],
          availableQuantity: (json['currentStock'] ?? 0).toDouble(),
          salesOrderId: json['salesOrderId'], 
          salesOrderNumber: json['orderNumber'] ?? '',
          customerName: json['customerName'] ?? 'Walk-in Customer',
          quantityOrdered: (json['quantityOrdered'] ?? 0).toDouble(),
          quantityToPick: (json['quantityToPick'] ?? 0).toDouble(),
          quantityPicked: (json['quantityPicked'] ?? 0).toDouble(),
          preferredBin: json['preferredBin'] ?? 'N/A',
        );
      }).toList();
    } else {
      return [];
    }
  } catch (e) {
    // Return empty list on error instead of crashing
    return [];
  }
});
