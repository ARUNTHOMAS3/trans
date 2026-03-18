import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'package:zerpai_erp/modules/items/composite_items/models/composite_item_model.dart';

abstract class ItemRepository {
  Future<List<Item>> getItems({int? limit, int? offset});
  Future<Map<String, dynamic>> getProductsCursor({int? limit, String? cursor});
  Future<List<Item>> searchProducts(String query, {int limit = 30});
  Future<List<Map<String, dynamic>>> getBulkStock({
    required String outletId,
    required List<String> productIds,
  });
  Future<int> getItemsCount();
  Future<Item?> getItemById(String id);
  Future<Item> createItem(Item item);
  Future<Item> updateItem(Item item);
  Future<int> updateItemsBulk(Set<String> ids, Map<String, dynamic> changes);
  Future<void> updateOpeningStock(
    String itemId,
    double openingStock,
    double openingStockValue,
  );
  Future<void> deleteItem(String id);
  Future<bool> createCompositeItem(Map<String, dynamic> payload);
  Future<List<CompositeItem>> getCompositeItems();
  Future<int> updateCompositeItemsBulk(
    Set<String> ids,
    Map<String, dynamic> data,
  );
  Future<int> deleteCompositeItemsBulk(Set<String> ids);

  // Stock-related data
  Future<List<SerialData>> getItemSerials(String itemId);
  Future<List<BatchData>> getItemBatches(String itemId);
  Future<List<TransactionData>> getItemStockTransactions(String itemId);
  Future<Map<String, dynamic>> getQuickStats(String itemId);
  Future<List<Map<String, dynamic>>> getAssociatedPriceLists(String productId);
  Future<List<Map<String, dynamic>>> getAllPriceLists();
  Future<Map<String, dynamic>?> associatePriceList({
    required String productId,
    required String priceListId,
    double? customRate,
    double? discountPercentage,
  });
}

// Lightweight in-memory repository kept only for local test scaffolding.
class InMemoryItemRepository implements ItemRepository {
  final List<Item> _items = [];
  int _nextId = 1;

  @override
  Future<List<Item>> getItems({int? limit, int? offset}) async {
    List<Item> result = List.from(_items);
    if (offset != null) {
      result = result.skip(offset).toList();
    }
    if (limit != null) {
      result = result.take(limit).toList();
    }
    return result;
  }

  @override
  Future<int> getItemsCount() async {
    return _items.length;
  }

  @override
  Future<Map<String, dynamic>> getProductsCursor({
    int? limit,
    String? cursor,
  }) async {
    return {'items': <Item>[], 'next_cursor': null};
  }

  @override
  Future<List<Item>> searchProducts(String query, {int limit = 30}) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getBulkStock({
    required String outletId,
    required List<String> productIds,
  }) async {
    return [];
  }

  @override
  Future<Item?> getItemById(String id) async {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Item> createItem(Item item) async {
    final newItem = item.copyWith(id: _nextId.toString());
    _nextId++;
    _items.add(newItem);
    return newItem;
  }

  @override
  Future<Item> updateItem(Item item) async {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      throw StateError('Item with id ${item.id} not found');
    }
    _items[index] = item;
    return item;
  }

  @override
  Future<int> updateItemsBulk(
    Set<String> ids,
    Map<String, dynamic> changes,
  ) async {
    int updated = 0;
    for (final item in _items) {
      if (item.id != null && ids.contains(item.id)) {
        updated += 1;
      }
    }
    return updated;
  }

  @override
  Future<void> updateOpeningStock(
    String itemId,
    double openingStock,
    double openingStockValue,
  ) async {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        openingStock: openingStock,
        openingStockValue: openingStockValue,
      );
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.removeWhere((i) => i.id == id);
  }

  @override
  Future<bool> createCompositeItem(Map<String, dynamic> payload) async {
    return true;
  }

  @override
  Future<List<CompositeItem>> getCompositeItems() async {
    return [];
  }

  @override
  Future<int> updateCompositeItemsBulk(
    Set<String> ids,
    Map<String, dynamic> data,
  ) async {
    return ids.length;
  }

  @override
  Future<int> deleteCompositeItemsBulk(Set<String> ids) async {
    return ids.length;
  }

  @override
  Future<List<SerialData>> getItemSerials(String itemId) async {
    return [];
  }

  @override
  Future<List<BatchData>> getItemBatches(String itemId) async {
    return [];
  }

  @override
  Future<List<TransactionData>> getItemStockTransactions(String itemId) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> getQuickStats(String itemId) async {
    return {'current_stock': 0, 'last_purchase_price': 0};
  }

  @override
  Future<List<Map<String, dynamic>>> getAssociatedPriceLists(
    String productId,
  ) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getAllPriceLists() async {
    return [];
  }

  @override
  Future<Map<String, dynamic>?> associatePriceList({
    required String productId,
    required String priceListId,
    double? customRate,
    double? discountPercentage,
  }) async {
    return null;
  }
}
