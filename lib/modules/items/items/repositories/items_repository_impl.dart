import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'package:zerpai_erp/modules/items/composite_items/models/composite_item_model.dart';
import 'package:zerpai_erp/modules/items/items/repositories/items_repository.dart';
import 'package:zerpai_erp/modules/items/items/services/products_api_service.dart';
import 'package:zerpai_erp/core/services/hive_service.dart';
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
      // Mock API call
      await Future.delayed(const Duration(milliseconds: 300));
      final serials = [
        SerialData(
          serialNumber: 'SN-001',
          warehouseName: 'Primary Warehouse',
          isAvailable: true,
        ),
        SerialData(
          serialNumber: 'SN-002',
          warehouseName: 'Primary Warehouse',
          isAvailable: false,
        ),
        SerialData(
          serialNumber: 'SN-003',
          warehouseName: 'Secondary Warehouse',
          isAvailable: true,
        ),
      ];

      // Cache to Hive
      await _hiveService.saveItemSerials(itemId, serials);
      return serials;
    } catch (e) {
      AppLogger.warning('Failed to fetch serials from API, using cache');
      return _hiveService.getItemSerials(itemId);
    }
  }

  @override
  Future<List<BatchData>> getItemBatches(String itemId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final batches = [
        BatchData(
          batchReference: 'B-2024-001',
          manufacturerBatch: 'MF-88',
          unitPack: 10,
          manufacturedDate: '01-01-2024',
          expiryDate: '01-01-2026',
          quantityIn: 500,
          quantityAvailable: 320,
        ),
      ];
      await _hiveService.saveItemBatches(itemId, batches);
      return batches;
    } catch (e) {
      return []; // Implement _hiveService.getItemBatches if needed
    }
  }

  @override
  Future<List<TransactionData>> getItemStockTransactions(String itemId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final transactions = [
        TransactionData(
          date: '2024-03-01',
          documentNumber: 'INV-1001',
          customerName: 'General Pharma',
          quantitySold: 10,
          price: 15.0,
          total: 150.0,
          status: 'completed',
          documentType: 'sale',
        ),
      ];
      await _hiveService.saveItemStockTransactions(itemId, transactions);
      return transactions;
    } catch (e) {
      return [];
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
