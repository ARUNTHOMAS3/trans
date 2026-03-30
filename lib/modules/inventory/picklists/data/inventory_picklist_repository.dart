import '../models/inventory_picklist_model.dart';

abstract class InventoryPicklistRepository {
  Future<List<Picklist>> getPicklists({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  });

  Future<Picklist?> getPicklist(String id);

  Future<Picklist> createPicklist(Picklist picklist);

  Future<Picklist?> updatePicklist(String id, Picklist picklist);

  Future<bool> deletePicklist(String id);

  Future<int> getTotalCount();
}
