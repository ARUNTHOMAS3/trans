// FILE: lib/modules/purchases/repositories/purchase_orders_repository.dart
// Repository pattern for Purchase Orders - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/shared/services/hive_service.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/purchases/models/purchase_model.dart';

class PurchaseOrdersRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;

  PurchaseOrdersRepository({ApiClient? apiClient, HiveService? hiveService})
    : _apiClient = apiClient ?? ApiClient(),
      _hiveService = hiveService ?? HiveService();

  /// Fetch purchase orders - Online-first with offline fallback
  Future<List<Purchase>> getPurchaseOrders({
    bool forceRefresh = false,
  }) async {
    try {
      // Online-first: Fetch from API
      final response = await _apiClient.get('/purchase-orders');
      
      final List<Purchase> orders = (response.data as List)
          .map((json) => Purchase.fromJson(json))
          .toList();
      
      // Cache to Hive for offline access
      await _hiveService.savePurchaseOrders(orders);
      
      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('purchase_orders');
      
      return orders;
    } catch (e) {
      // Offline fallback: Return cached data
      AppLogger.warning(
        'API fetch failed, using cached purchase orders',
        error: e,
        module: 'purchase_orders',
      );
      
      final cachedOrders = _hiveService.getPurchaseOrders();
      
      if (cachedOrders.isEmpty) {
        rethrow;
      }
      
      return cachedOrders;
    }
  }

  /// Get single purchase order by ID
  Future<Purchase?> getPurchaseOrder(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getPurchaseOrder(id);
    if (cached != null) {
      return cached;
    }
    
    // Not in cache, fetch from API
    try {
      final response = await _apiClient.get('/purchase-orders/$id');
      final order = Purchase.fromJson(response.data);
      
      await _hiveService.savePurchaseOrder(order);
      return order;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch purchase order',
        error: e,
        module: 'purchase_orders',
        data: {'orderId': id},
      );
      return null;
    }
  }

  /// Create new purchase order
  Future<Purchase> createPurchaseOrder(Purchase orderData) async {
    try {
      final response = await _apiClient.post(
        '/purchase-orders',
        data: orderData.toJson(),
      );
      final createdOrder = Purchase.fromJson(response.data);
      
      // Cache locally
      await _hiveService.savePurchaseOrder(createdOrder);
      
      return createdOrder;
    } catch (e) {
      AppLogger.error(
        'Failed to create purchase order',
        error: e,
        module: 'purchase_orders',
      );
      rethrow;
    }
  }

  /// Update existing purchase order
  Future<Purchase> updatePurchaseOrder(String id, Purchase orderData) async {
    try {
      final response = await _apiClient.put(
        '/purchase-orders/$id',
        data: orderData.toJson(),
      );
      final updatedOrder = Purchase.fromJson(response.data);
      
      // Update cache
      await _hiveService.savePurchaseOrder(updatedOrder);
      
      return updatedOrder;
    } catch (e) {
      AppLogger.error(
        'Failed to update purchase order',
        error: e,
        module: 'purchase_orders',
        data: {'orderId': id},
      );
      rethrow;
    }
  }

  /// Delete purchase order
  Future<void> deletePurchaseOrder(String id) async {
    try {
      await _apiClient.delete('/purchase-orders/$id');
      
      // Remove from cache
      await _hiveService.purchaseOrdersBox.delete(id);
    } catch (e) {
      AppLogger.error(
        'Failed to delete purchase order',
        error: e,
        module: 'purchase_orders',
        data: {'orderId': id},
      );
      rethrow;
    }
  }

  /// Get purchase orders by vendor
  Future<List<Purchase>> getPurchaseOrdersByVendor(String vendorId) async {
    try {
      final response = await _apiClient.get('/purchase-orders/vendor/$vendorId');
      return (response.data as List)
          .map((json) => Purchase.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch vendor purchase orders',
        error: e,
        module: 'purchase_orders',
        data: {'vendorId': vendorId},
      );
      return [];
    }
  }

  /// Get purchase orders by status
  Future<List<Purchase>> getPurchaseOrdersByStatus(String status) async {
    try {
      final response = await _apiClient.get('/purchase-orders/status/$status');
      return (response.data as List)
          .map((json) => Purchase.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch purchase orders by status',
        error: e,
        module: 'purchase_orders',
        data: {'status': status},
      );
      return [];
    }
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 24)}) {
    final lastSync = _hiveService.getLastSyncTime('purchase_orders');
    if (lastSync == null) return true;
    
    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('purchase_orders');
    final stats = _hiveService.getCacheStats();
    
    return {
      'cached_orders': stats['purchase_orders'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }
}
