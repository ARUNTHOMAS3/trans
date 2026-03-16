// FILE: lib/modules/purchases/purchase_orders/repositories/purchases_purchase_orders_order_repository.dart

import '../models/purchases_purchase_orders_order_model.dart';

abstract class PurchaseOrderRepository {
  Future<List<PurchaseOrder>> getPurchaseOrders({
    int page = 1,
    int limit = 100,
    String? search,
  });

  Future<PurchaseOrder?> getPurchaseOrder(String id);

  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder purchaseOrder);

  Future<PurchaseOrder?> updatePurchaseOrder(
    String id,
    PurchaseOrder purchaseOrder,
  );

  Future<bool> deletePurchaseOrder(String id);

  Future<int> getTotalCount();
}
