import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'package:zerpai_erp/modules/items/composite_items/models/composite_item_model.dart';
import 'package:zerpai_erp/modules/items/items/repositories/items_repository.dart';
import 'package:zerpai_erp/modules/items/items/services/products_api_service.dart';

class SupabaseItemRepository implements ItemRepository {
  final ProductsApiService _apiService = ProductsApiService();

  @override
  Future<List<Item>> getItems({int? limit, int? offset}) async {
    return await _apiService.getProducts(limit: limit, offset: offset);
  }

  @override
  Future<int> getItemsCount() async {
    return await _apiService.getProductsCount();
  }

  @override
  Future<Map<String, dynamic>> getProductsCursor({
    int? limit,
    String? cursor,
  }) async {
    return await _apiService.getProductsCursor(limit: limit, cursor: cursor);
  }

  @override
  Future<List<Item>> searchProducts(String query, {int limit = 30}) async {
    return await _apiService.searchProducts(query, limit: limit);
  }

  @override
  Future<List<Map<String, dynamic>>> getBulkStock({
    required String outletId,
    required List<String> productIds,
  }) async {
    return await _apiService.getBulkStock(
      outletId: outletId,
      productIds: productIds,
    );
  }

  @override
  Future<Item?> getItemById(String id) async {
    try {
      return await _apiService.getProductById(id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Item> createItem(Item item) async {
    return await _apiService.createProduct(item);
  }

  @override
  Future<Item> updateItem(Item item) async {
    if (item.id == null) {
      throw Exception('Cannot update item without ID');
    }
    return await _apiService.updateProduct(item.id!, item);
  }

  @override
  Future<int> updateItemsBulk(
    Set<String> ids,
    Map<String, dynamic> changes,
  ) async {
    return await _apiService.updateProductsBulk(ids.toList(), changes);
  }

  @override
  Future<void> updateOpeningStock(
    String itemId,
    double openingStock,
    double openingStockValue,
  ) async {
    final currentItem = await getItemById(itemId);
    if (currentItem == null) return;

    final updatedItem = currentItem.copyWith(
      openingStock: openingStock,
      openingStockValue: openingStockValue,
    );

    await updateItem(updatedItem);
  }

  @override
  Future<List<WarehouseStockRow>> getItemWarehouseStocks(String itemId) async {
    return await _apiService.getProductWarehouseStocks(itemId);
  }

  @override
  Future<List<WarehouseStockRow>> updateItemWarehouseStocks(
    String itemId,
    List<WarehouseStockRow> rows,
  ) async {
    return await _apiService.updateProductWarehouseStocks(itemId, rows);
  }

  @override
  Future<List<WarehouseStockRow>> adjustItemWarehousePhysicalStock(
    String itemId, {
    required String warehouseId,
    required double countedStock,
    required String reason,
    String? notes,
  }) async {
    return await _apiService.adjustProductWarehousePhysicalStock(
      itemId,
      warehouseId: warehouseId,
      countedStock: countedStock,
      reason: reason,
      notes: notes,
    );
  }

  @override
  Future<void> deleteItem(String id) async {
    await _apiService.deleteProduct(id);
  }

  @override
  Future<bool> createCompositeItem(Map<String, dynamic> payload) async {
    try {
      await _apiService.createCompositeProduct(payload);
      return true;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<CompositeItem>> getCompositeItems() async {
    return await _apiService.getCompositeProducts();
  }

  @override
  Future<int> deleteCompositeItemsBulk(Set<String> ids) async {
    return await _apiService.deleteCompositeProductsBulk(ids.toList());
  }

  @override
  Future<int> updateCompositeItemsBulk(
    Set<String> ids,
    Map<String, dynamic> changes,
  ) async {
    return await _apiService.updateCompositeProductsBulk(ids.toList(), changes);
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
    try {
      return await _apiService.getProductQuickStats(itemId);
    } catch (e) {
      return {'current_stock': 0, 'last_purchase_price': 0.0};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAssociatedPriceLists(
    String productId,
  ) async {
    return await _apiService.getAssociatedPriceLists(productId);
  }

  @override
  Future<List<Map<String, dynamic>>> getAllPriceLists() async {
    return await _apiService.getAllPriceLists();
  }

  @override
  Future<Map<String, dynamic>?> associatePriceList({
    required String productId,
    required String priceListId,
    double? customRate,
    double? discountPercentage,
  }) async {
    return await _apiService.associatePriceList(
      productId: productId,
      priceListId: priceListId,
      customRate: customRate,
      discountPercentage: discountPercentage,
    );
  }
}
