import '../models/sales_return_model.dart';

abstract class SalesReturnRepository {
  Future<List<SalesReturn>> getSalesReturns({
    int page,
    int limit,
    String? search,
    String? status,
  });
  Future<String> getNextRmaNumber({String prefix});
  Future<SalesReturn> createSalesReturn(CreateSalesReturnPayload payload);
  Future<SalesReturnReceive> createReceive(
    String salesReturnId,
    CreateReceivePayload payload,
  );
  Future<List<SalesReturnReceive>> getReceives(String salesReturnId);
  Future<void> deleteReceive(String salesReturnId, String receiveId);
}
