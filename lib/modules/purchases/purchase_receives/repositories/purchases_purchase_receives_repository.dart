import '../models/purchases_purchase_receives_model.dart';

abstract class PurchaseReceivesRepository {
  Future<List<PurchaseReceive>> getPurchaseReceives({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  });

  Future<PurchaseReceive?> getPurchaseReceive(String id);

  Future<PurchaseReceive> createPurchaseReceive(PurchaseReceive receive);

  Future<PurchaseReceive?> updatePurchaseReceive(
    String id,
    PurchaseReceive receive,
  );

  Future<bool> deletePurchaseReceive(String id);

  Future<int> getTotalCount();
}
