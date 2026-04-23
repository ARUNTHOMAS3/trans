import '../models/purchases_purchase_receives_model.dart';

abstract class PurchaseReceiveRepository {
  Future<List<PurchaseReceive>> getPurchaseReceives({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  });

  Future<PurchaseReceive?> getPurchaseReceive(String id);

  Future<PurchaseReceive> createPurchaseReceive(
    PurchaseReceive purchaseReceive,
  );

  Future<PurchaseReceive?> updatePurchaseReceive(
    String id,
    PurchaseReceive purchaseReceive,
  );

  Future<bool> deletePurchaseReceive(String id);

  Future<int> getTotalCount();

  Future<Map<String, dynamic>> getNextPurchaseReceiveNumber({String? prefix});
}
