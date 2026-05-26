import '../models/inventory_picklist_model.dart';

abstract class InventoryPicklistRepository {
  Future<List<Picklist>> getPicklists({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  });

  Future<Picklist?> getPicklist(String id);

  Future<Picklist> createPicklist(Map<String, dynamic> data);

  Future<Picklist?> updatePicklist(String id, Map<String, dynamic> data);

  Future<bool> deletePicklist(String id);

  Future<int> getTotalCount();

  /// Returns {next_number: int, prefix: String, formatted: String}
  Future<Map<String, dynamic>> getNextNumber();

  Future<Map<String, dynamic>> getWarehouseItems({
    required String warehouseId,
    int page = 1,
    int limit = 100,
    String? search,
    String? customerId,
    String? productId,
    String? salesOrderId,
    String? sortBy,
    bool? sortAscending,
  });

  Future<List<Map<String, String>>> getWarehouseBins({
    required String warehouseId,
    String? search,
    String? productId,
  });
}
