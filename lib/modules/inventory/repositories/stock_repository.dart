// FILE: lib/modules/inventory/repositories/stock_repository.dart
// Repository pattern for Stock Management - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/shared/services/hive_service.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_model.dart';

class StockRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;

  StockRepository({ApiClient? apiClient, HiveService? hiveService})
    : _apiClient = apiClient ?? ApiClient(),
      _hiveService = hiveService ?? HiveService();

  /// Fetch stock items - Online-first with offline fallback
  Future<List<Stock>> getStockItems({
    bool forceRefresh = false,
  }) async {
    try {
      // Online-first: Fetch from API
      final response = await _apiClient.get('/stock');
      
      final List<Stock> stockItems = (response.data as List)
          .map((json) => Stock.fromJson(json))
          .toList();
      
      // Cache to Hive for offline access
      await _hiveService.saveStockItems(stockItems);
      
      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('stock');
      
      return stockItems;
    } catch (e) {
      // Offline fallback: Return cached data
      AppLogger.warning(
        'API fetch failed, using cached stock items',
        error: e,
        module: 'stock',
      );
      
      final cachedStock = _hiveService.getStockItems();
      
      if (cachedStock.isEmpty) {
        rethrow;
      }
      
      return cachedStock;
    }
  }

  /// Get single stock item by ID
  Future<Stock?> getStockItem(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getStockItem(id);
    if (cached != null) {
      return cached;
    }
    
    // Not in cache, fetch from API
    try {
      final response = await _apiClient.get('/stock/$id');
      final stockItem = Stock.fromJson(response.data);
      
      await _hiveService.saveStockItem(stockItem);
      return stockItem;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch stock item',
        error: e,
        module: 'stock',
        data: {'stockId': id},
      );
      return null;
    }
  }

  /// Get stock by product ID
  Future<Stock?> getStockByProduct(String productId) async {
    try {
      final response = await _apiClient.get('/stock/product/$productId');
      return Stock.fromJson(response.data);
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch stock by product',
        error: e,
        module: 'stock',
        data: {'productId': productId},
      );
      return null;
    }
  }

  /// Get stock by warehouse
  Future<List<Stock>> getStockByWarehouse(String warehouseId) async {
    try {
      final response = await _apiClient.get('/stock/warehouse/$warehouseId');
      return (response.data as List)
          .map((json) => Stock.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch stock by warehouse',
        error: e,
        module: 'stock',
        data: {'warehouseId': warehouseId},
      );
      return [];
    }
  }

  /// Get low stock items (below reorder level)
  Future<List<Stock>> getLowStockItems() async {
    try {
      final response = await _apiClient.get('/stock/low-stock');
      return (response.data as List)
          .map((json) => Stock.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch low stock items',
        error: e,
        module: 'stock',
      );
      // Fallback: Filter cached items
      final allStock = _hiveService.getStockItems();
      return allStock.where((item) => item.isBelowReorderLevel).toList();
    }
  }

  /// Get out of stock items
  Future<List<Stock>> getOutOfStockItems() async {
    try {
      final response = await _apiClient.get('/stock/out-of-stock');
      return (response.data as List)
          .map((json) => Stock.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch out of stock items',
        error: e,
        module: 'stock',
      );
      // Fallback: Filter cached items
      final allStock = _hiveService.getStockItems();
      return allStock.where((item) => item.isOutOfStock).toList();
    }
  }

  /// Update stock quantity (used by transactions)
  Future<Stock> updateStockQuantity(
    String productId,
    double quantityChange,
    String warehouseId,
  ) async {
    try {
      final response = await _apiClient.post(
        '/stock/update-quantity',
        data: {
          'product_id': productId,
          'quantity_change': quantityChange.toString(),
          'warehouse_id': warehouseId,
        },
      );
      final updatedStock = Stock.fromJson(response.data);
      
      // Update cache
      await _hiveService.saveStockItem(updatedStock);
      
      return updatedStock;
    } catch (e) {
      AppLogger.error(
        'Failed to update stock quantity',
        error: e,
        module: 'stock',
        data: {
          'productId': productId,
          'quantityChange': quantityChange,
          'warehouseId': warehouseId,
        },
      );
      rethrow;
    }
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 1)}) {
    final lastSync = _hiveService.getLastSyncTime('stock');
    if (lastSync == null) return true;
    
    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('stock');
    final stats = _hiveService.getCacheStats();
    
    return {
      'cached_items': stats['stock'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }
}
