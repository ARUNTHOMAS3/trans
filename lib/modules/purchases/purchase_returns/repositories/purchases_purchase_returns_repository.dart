import '../models/purchases_purchase_returns_model.dart';

abstract class PurchaseReturnsRepository {
  Future<List<PurchaseReturn>> getPurchaseReturns({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  });

  Future<PurchaseReturn?> getPurchaseReturn(String id);

  Future<PurchaseReturn> createPurchaseReturn(PurchaseReturn purchaseReturn);

  Future<PurchaseReturn?> updatePurchaseReturn(
    String id,
    PurchaseReturn purchaseReturn,
  );

  Future<bool> deletePurchaseReturn(String id);

  Future<String> getNextReturnNumber();
}
