import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
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

  /// Replaces an existing return's header and its full line set.
  Future<SalesReturn> updateSalesReturn(
    String id,
    CreateSalesReturnPayload payload,
  );
  /// Moves a return along its workflow, e.g. approving a draft. Returns the
  /// saved record so callers can reflect the new status without a refetch.
  Future<SalesReturn> updateSalesReturnStatus(String id, String status);

  /// Invoiced and already-returned quantities per product for one customer,
  /// keyed by `products.id`.
  ///
  /// [excludeReturnId] drops one return from the already-returned total — the
  /// document being edited must not count itself.
  Future<Map<String, CustomerItemHistory>> getCustomerItemHistory(
    String customerId, {
    String? excludeReturnId,
  });

  Future<SalesReturnReceive> createReceive(
      String salesReturnId, CreateReceivePayload payload);
  Future<List<SalesReturnReceive>> getReceives(String salesReturnId);

  /// Persisted activity for a sales return and its explicitly linked credit notes.
  Future<List<SalesReturnHistoryEntry>> getHistory(String salesReturnId);
  Future<void> deleteReceive(String salesReturnId, String receiveId);

  /// Deletes the return along with its line items and any receives. The server
  /// owns the cascade; this is a single call.
  Future<void> deleteSalesReturn(String id);

  /// Fetches warehouses specifically for the sales returns module.
  Future<List<Warehouse>> getWarehouses();
}
