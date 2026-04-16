import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'package:zerpai_erp/modules/items/composite_items/models/composite_item_model.dart';
import 'package:zerpai_erp/modules/items/items/repositories/items_repository.dart';
import 'package:zerpai_erp/modules/items/items/services/products_api_service.dart';
import 'package:zerpai_erp/shared/services/hive_service.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/errors/app_exceptions.dart';

/// Production implementation of ItemRepository with offline support
///
/// Architecture: Online-first with offline fallback
/// - Tries API first
/// - Caches successful responses to Hive
/// - Falls back to Hive if API fails
class ItemsRepositoryImpl implements ItemRepository {
  final ProductsApiService _apiService;
  final HiveService _hiveService;

  ItemsRepositoryImpl({
    ProductsApiService? apiService,
    HiveService? hiveService,
  }) : _apiService = apiService ?? ProductsApiService(),
       _hiveService = hiveService ?? HiveService();

  @override
  Future<List<Item>> getItems({int? limit, int? offset}) async {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.info('Fetching items from API', module: 'items_repository');

      // Try API first (online-first approach)
      final items = await _apiService.getProducts(limit: limit, offset: offset);

      stopwatch.stop();
      AppLogger.performance('getItems (API)', stopwatch.elapsed);

      // Cache to Hive for offline access
      try {
        if (offset == null || offset == 0) {
          await _hiveService.productsBox.clear();
        }

        final batchMap = <String, Item>{};
        for (var product in items) {
          if (product.id != null) {
            batchMap[product.id!] = product;
          }
        }
        if (batchMap.isNotEmpty) {
          await _hiveService.productsBox.putAll(batchMap);
        }

        await _hiveService.updateLastSyncTime('items');

        AppLogger.debug(
          'Cached ${items.length} items to offline storage',
          module: 'items_repository',
        );
      } catch (cacheError) {
        // Log cache error but don't fail the request
        AppLogger.warning(
          'Failed to cache items',
          data: {'error': cacheError.toString()},
          module: 'items_repository',
        );
      }

      return items;
    } on NetworkException catch (e) {
      // Network error - try offline fallback
      AppLogger.warning(
        'Network error, falling back to offline cache',
        data: {'error': e.toString()},
        module: 'items_repository',
      );
      return _getItemsFromCache();
    } on ApiException catch (e) {
      // API error - try offline fallback
      AppLogger.warning(
        'API error, falling back to offline cache',
        data: {'error': e.toString(), 'statusCode': e.statusCode},
        module: 'items_repository',
      );
      return _getItemsFromCache();
    } catch (e, st) {
      // Unexpected error - try offline fallback
      AppLogger.error(
        'Unexpected error fetching items, falling back to offline cache',
        error: e,
        stackTrace: st,
        module: 'items_repository',
      );
      return _getItemsFromCache();
    }
  }

  /// Get items from offline cache
  List<Item> _getItemsFromCache() {
    try {
      final items = _hiveService.getProducts();

      final lastSync = _hiveService.getLastSyncTime('items');
      AppLogger.info(
        'Retrieved ${items.length} items from offline cache',
        data: {
          'count': items.length,
          'lastSync': lastSync?.toIso8601String() ?? 'never',
        },
        module: 'items_repository',
      );

      return items;
    } catch (e, st) {
      AppLogger.error(
        'Failed to retrieve items from cache',
        error: e,
        stackTrace: st,
        module: 'items_repository',
      );
      // Return empty list rather than throwing
      return [];
    }
  }

  @override
  Future<int> getItemsCount() async {
    try {
      AppLogger.info(
        'Fetching items count from API',
        module: 'items_repository',
      );
      return await _apiService.getProductsCount();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch item count from API, returning cache count',
        error: e,
        module: 'items_repository',
      );
      return _hiveService.productsBox.length;
    }
  }

  @override
  Future<Map<String, dynamic>> getProductsCursor({
    int? limit,
    String? cursor,
  }) async {
    try {
      AppLogger.info(
        'Fetching cursor items from API',
        data: {'limit': limit, 'cursor': cursor},
        module: 'items_repository',
      );
      return await _apiService.getProductsCursor(limit: limit, cursor: cursor);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch cursor items',
        error: e,
        module: 'items_repository',
      );
      // Rethrow so ItemsController can show a proper error state
      rethrow;
    }
  }

  @override
  Future<List<Item>> searchProducts(String query, {int limit = 30}) async {
    try {
      AppLogger.info(
        'Searching products from API',
        data: {'query': query},
        module: 'items_repository',
      );
      return await _apiService.searchProducts(query, limit: limit);
    } catch (e) {
      AppLogger.warning(
        'Search failed, falling back to empty',
        error: e,
        module: 'items_repository',
      );
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBulkStock({
    required String outletId,
    required List<String> productIds,
  }) async {
    try {
      return await _apiService.getBulkStock(
        outletId: outletId,
        productIds: productIds,
      );
    } catch (e) {
      AppLogger.warning(
        'Bulk stock fetch failed',
        error: e,
        module: 'items_repository',
      );
      return [];
    }
  }

  @override
  Future<Item?> getItemById(String id) async {
    try {
      AppLogger.debug(
        'Fetching item by ID from API',
        data: {'id': id},
        module: 'items_repository',
      );

      // Try API first
      final item = await _apiService.getProductById(id);

      // Cache to Hive
      try {
        await _hiveService.saveProduct(item);
      } catch (cacheError) {
        AppLogger.warning(
          'Failed to cache item',
          data: {'id': id, 'error': cacheError.toString()},
          module: 'items_repository',
        );
      }

      return item;
    } catch (e) {
      // Try offline fallback
      AppLogger.warning(
        'Error fetching item from API, trying cache',
        data: {'id': id, 'error': e.toString()},
        module: 'items_repository',
      );

      try {
        final cachedData = _hiveService.getProduct(id);
        if (cachedData != null) {
          return cachedData;
        }
      } catch (cacheError) {
        AppLogger.error(
          'Failed to retrieve item from cache',
          error: cacheError,
          module: 'items_repository',
        );
      }

      // Re-throw the original error if fallback fails
      AppLogger.error(
        'Failed to fetch item from API or cache for ID: $id',
        error: e,
        data: {'id': id},
        module: 'items_repository',
      );
      if (kDebugMode) {
        print('❌ [getItemById] FATAL ERROR for $id: $e');
      }
      return null;
    }
  }

  @override
  Future<Item> createItem(Item item) async {
    try {
      AppLogger.info(
        'Creating item via API',
        data: {'name': item.productName},
        module: 'items_repository',
      );

      return await _apiService.createProduct(item);
    } catch (e, st) {
      AppLogger.error(
        'Failed to create item',
        error: e,
        stackTrace: st,
        module: 'items_repository',
      );
      rethrow;
    }
  }

  @override
  Future<Item> updateItem(Item item) async {
    final String? id = item.id;
    if (id == null) {
      throw Exception('Item ID is required for update');
    }

    try {
      AppLogger.info(
        'Updating item via API',
        data: {'id': id, 'name': item.productName},
        module: 'items_repository',
      );

      return await _apiService.updateProduct(id, item);
    } catch (e, st) {
      AppLogger.error(
        'Failed to update item',
        error: e,
        stackTrace: st,
        data: {'id': id},
        module: 'items_repository',
      );
      rethrow;
    }
  }

  @override
  Future<int> updateItemsBulk(
    Set<String> ids,
    Map<String, dynamic> changes,
  ) async {
    if (ids.isEmpty) return 0;

    try {
      AppLogger.info(
        'Bulk updating items via API',
        data: {'count': ids.length},
        module: 'items_repository',
      );

      final List<String> idList = ids.toList();
      return await _apiService.updateProductsBulk(idList, changes);
    } catch (e, st) {
      AppLogger.error(
        'Failed to bulk update items',
        error: e,
        stackTrace: st,
        data: {'count': ids.length},
        module: 'items_repository',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateOpeningStock(
    String itemId,
    double openingStock,
    double openingStockValue,
  ) async {
    try {
      await _apiService.updateOpeningStock(
        itemId,
        openingStock,
        openingStockValue,
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to update opening stock',
        error: e,
        stackTrace: st,
        data: {
          'itemId': itemId,
          'qty': openingStock,
          'value': openingStockValue,
        },
        module: 'items_repository',
      );
      rethrow;
    }
  }

  @override
  Future<List<WarehouseStockRow>> getItemWarehouseStocks(String itemId) async {
    try {
      return await _apiService.getProductWarehouseStocks(itemId);
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch warehouse stocks from API',
        error: e,
        module: 'items_repository',
      );
      return [];
    }
  }

  @override
  Future<List<WarehouseStockRow>> updateItemWarehouseStocks(
    String itemId,
    List<WarehouseStockRow> rows,
  ) async {
    try {
      return await _apiService.updateProductWarehouseStocks(itemId, rows);
    } catch (e) {
      AppLogger.error(
        'Failed to update warehouse stocks',
        error: e,
        module: 'items_repository',
      );
      rethrow;
    }
  }

  @override
  Future<List<WarehouseStockRow>> adjustItemWarehousePhysicalStock(
    String itemId, {
    required String warehouseId,
    required double countedStock,
    required String reason,
    String? notes,
  }) async {
    try {
      return await _apiService.adjustProductWarehousePhysicalStock(
        itemId,
        warehouseId: warehouseId,
        countedStock: countedStock,
        reason: reason,
        notes: notes,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to adjust warehouse physical stock',
        error: e,
        module: 'items_repository',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    try {
      AppLogger.info(
        'Deleting item via API',
        data: {'id': id},
        module: 'items_repository',
      );

      await _apiService.deleteProduct(id);

      // Remove from cache
      try {
        await _hiveService.deleteProduct(id);
      } catch (cacheError) {
        AppLogger.warning(
          'Failed to delete cached item',
          data: {'id': id, 'error': cacheError.toString()},
          module: 'items_repository',
        );
      }
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete item',
        error: e,
        stackTrace: st,
        data: {'id': id},
        module: 'items_repository',
      );
      rethrow;
    }
  }

  @override
  Future<bool> createCompositeItem(Map<String, dynamic> payload) async {
    try {
      AppLogger.info(
        'Creating composite item via API',
        module: 'items_repository',
      );
      await _apiService.createCompositeProduct(payload);
      return true;
    } catch (e, st) {
      AppLogger.error(
        'Failed to create composite item',
        error: e,
        stackTrace: st,
        module: 'items_repository',
      );
      rethrow;
    }
  }

  @override
  Future<List<CompositeItem>> getCompositeItems() async {
    try {
      AppLogger.info(
        'Fetching composite items from API',
        module: 'items_repository',
      );
      return await _apiService.getCompositeProducts();
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch composite items',
        error: e,
        stackTrace: st,
        module: 'items_repository',
      );
      return [];
    }
  }

  @override
  Future<int> updateCompositeItemsBulk(
    Set<String> ids,
    Map<String, dynamic> changes,
  ) async {
    if (ids.isEmpty) return 0;

    try {
      AppLogger.info(
        'Bulk updating composite items via API',
        data: {'count': ids.length},
        module: 'items_repository',
      );

      final List<String> idList = ids.toList();
      return await _apiService.updateCompositeProductsBulk(idList, changes);
    } catch (e, st) {
      AppLogger.error(
        'Failed to bulk update composite items',
        error: e,
        stackTrace: st,
        data: {'count': ids.length},
        module: 'items_repository',
      );
      rethrow;
    }
  }

  @override
  Future<int> deleteCompositeItemsBulk(Set<String> ids) async {
    if (ids.isEmpty) return 0;

    try {
      AppLogger.info(
        'Bulk deleting composite items via API',
        data: {'count': ids.length},
        module: 'items_repository',
      );

      final List<String> idList = ids.toList();
      final deletedCount = await _apiService.deleteCompositeProductsBulk(
        idList,
      );

      // Clean up cache
      for (final id in idList) {
        try {
          await _hiveService.deleteProduct(id);
        } catch (_) {}
      }

      return deletedCount;
    } catch (e, st) {
      AppLogger.error(
        'Failed to bulk delete composite items',
        error: e,
        stackTrace: st,
        data: {'count': ids.length},
        module: 'items_repository',
      );
      rethrow;
    }
  }

  /// Force refresh from API (bypass cache)
  Future<List<Item>> forceRefresh() async {
    AppLogger.info(
      'Force refreshing items from API',
      module: 'items_repository',
    );
    return getItems();
  }

  /// Check if offline data is available
  bool hasOfflineData() {
    return _hiveService.productsBox.isNotEmpty;
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('items');
    final itemCount = _hiveService.productsBox.length;

    return {
      'itemCount': itemCount,
      'lastSync': lastSync?.toIso8601String(),
      'hasData': itemCount > 0,
    };
  }

  @override
  Future<List<SerialData>> getItemSerials(String itemId) async {
    try {
      return _hiveService.getItemSerials(itemId);
    } catch (e) {
      AppLogger.warning('Failed to read cached serials', error: e);
      return _hiveService.getItemSerials(itemId);
    }
  }

  @override
  Future<List<BatchData>> getItemBatches(String itemId) async {
    try {
      final rawBatches = await _apiService.getProductBatches(itemId);
      final batches = rawBatches.map((batch) {
        String formatDate(dynamic raw) {
          if (raw == null || raw.toString().trim().isEmpty) return '';
          final parsed = DateTime.tryParse(raw.toString());
          if (parsed == null) return raw.toString();
          final day = parsed.day.toString().padLeft(2, '0');
          final month = parsed.month.toString().padLeft(2, '0');
          final year = parsed.year.toString();
          return '$day-$month-$year';
        }

        return BatchData(
          batchReference: (batch['batch_no'] ?? batch['batch'] ?? '').toString(),
          manufacturerBatch: (batch['manufacture_batch_number'] ?? '')
              .toString(),
          unitPack: int.tryParse((batch['unit_pack'] ?? '0').toString()) ?? 0,
          manufacturedDate: formatDate(batch['manufacture_exp']),
          expiryDate: formatDate(batch['expiry_date'] ?? batch['exp']),
          quantityIn: 0,
          quantityAvailable: 0,
          mrp: double.tryParse((batch['mrp'] ?? '0').toString()) ?? 0.0,
          ptr: double.tryParse((batch['ptr'] ?? '0').toString()) ?? 0.0,
        );
      }).toList();

      await _hiveService.saveItemBatches(itemId, batches);
      return batches;
    } catch (e) {
      AppLogger.warning('Failed to fetch item batches from API', error: e);
      return [];
    }
  }

  @override
  Future<List<TransactionData>> getItemStockTransactions(String itemId) async {
    try {
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<ItemHistoryEntry>> getItemHistory(String itemId) async {
    try {
      return await _apiService.getProductHistory(itemId);
    } catch (e) {
      AppLogger.error(
        'Failed to fetch item history from API',
        error: e,
        module: 'items_repository',
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getQuickStats(String itemId) async {
    try {
      return await _apiService.getProductQuickStats(itemId);
    } catch (e) {
      AppLogger.warning('Failed to fetch quick stats from API', error: e);
      return {'current_stock': 0, 'last_purchase_price': 0.0};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAssociatedPriceLists(
    String productId,
  ) async {
    try {
      return await _apiService.getAssociatedPriceLists(productId);
    } catch (e) {
      AppLogger.warning('Failed to fetch associated price lists', error: e);
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAllPriceLists() async {
    try {
      return await _apiService.getAllPriceLists();
    } catch (e) {
      AppLogger.warning('Failed to fetch all price lists', error: e);
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> associatePriceList({
    required String productId,
    required String priceListId,
    double? customRate,
    double? discountPercentage,
  }) async {
    try {
      return await _apiService.associatePriceList(
        productId: productId,
        priceListId: priceListId,
        customRate: customRate,
        discountPercentage: discountPercentage,
      );
    } catch (e) {
      AppLogger.error('Failed to associate price list', error: e);
      rethrow;
    }
  }
}
