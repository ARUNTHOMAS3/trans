import 'package:flutter_riverpod/flutter_riverpod.dart';

class WarehouseStockData {
  final String productId;
  final double availableQuantity;
  final double quantityOnHand;

  const WarehouseStockData({
    this.productId = '',
    this.availableQuantity = 0,
    this.quantityOnHand = 0,
  });
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
