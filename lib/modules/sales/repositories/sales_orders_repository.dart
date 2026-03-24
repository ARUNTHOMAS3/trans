// FILE: lib/modules/sales/repositories/sales_orders_repository.dart
// Repository pattern for Sales Orders - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/shared/services/hive_service.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/sales/models/sales_order_model.dart';

class SalesOrdersRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;

  SalesOrdersRepository({ApiClient? apiClient, HiveService? hiveService})
    : _apiClient = apiClient ?? ApiClient(),
      _hiveService = hiveService ?? HiveService();

  /// Fetch sales orders - Online-first with offline fallback
  Future<List<SalesOrder>> getSalesOrders({bool forceRefresh = false}) async {
    try {
      // Online-first: Fetch from API
      final response = await _apiClient.get('/sales-orders');

      final List<SalesOrder> orders = (response.data as List)
          .map((json) => SalesOrder.fromJson(json))
          .toList();

      // Cache to Hive for offline access
      await _hiveService.saveSalesOrders(orders);

      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('sales_orders');

      return orders;
    } catch (e) {
      // Offline fallback: Return cached data
      AppLogger.warning(
        'API fetch failed, using cached sales orders',
        error: e,
        module: 'sales_orders',
      );

      final cachedOrders = _hiveService.getSalesOrders();

      if (cachedOrders.isEmpty) {
        rethrow;
      }

      return cachedOrders;
    }
  }

  /// Get single sales order by ID
  Future<SalesOrder?> getSalesOrder(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getSalesOrder(id);
    if (cached != null) {
      return cached;
    }

    // Not in cache, fetch from API
    try {
      final response = await _apiClient.get('/sales-orders/$id');
      final order = SalesOrder.fromJson(response.data);

      await _hiveService.saveSalesOrder(order);
      return order;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch sales order',
        error: e,
        module: 'sales_orders',
        data: {'orderId': id},
      );
      return null;
    }
  }

  /// Create new sales order
  Future<SalesOrder> createSalesOrder(SalesOrder orderData) async {
    try {
      final response = await _apiClient.post(
        '/sales-orders',
        data: orderData.toJson(),
      );
      final createdOrder = SalesOrder.fromJson(response.data);

      // Cache locally
      await _hiveService.saveSalesOrder(createdOrder);

      return createdOrder;
    } catch (e) {
      AppLogger.error(
        'Failed to create sales order',
        error: e,
        module: 'sales_orders',
      );
      rethrow;
    }
  }

  /// Update existing sales order
  Future<SalesOrder> updateSalesOrder(String id, SalesOrder orderData) async {
    try {
      final response = await _apiClient.put(
        '/sales-orders/$id',
        data: orderData.toJson(),
      );
      final updatedOrder = SalesOrder.fromJson(response.data);

      // Update cache
      await _hiveService.saveSalesOrder(updatedOrder);

      return updatedOrder;
    } catch (e) {
      AppLogger.error(
        'Failed to update sales order',
        error: e,
        module: 'sales_orders',
        data: {'orderId': id},
      );
      rethrow;
    }
  }

  /// Delete sales order
  Future<void> deleteSalesOrder(String id) async {
    try {
      await _apiClient.delete('/sales-orders/$id');

      // Remove from cache
      await _hiveService.salesOrdersBox.delete(id);
    } catch (e) {
      AppLogger.error(
        'Failed to delete sales order',
        error: e,
        module: 'sales_orders',
        data: {'orderId': id},
      );
      rethrow;
    }
  }

  /// Get sales orders by customer
  Future<List<SalesOrder>> getSalesOrdersByCustomer(String customerId) async {
    try {
      final response = await _apiClient.get(
        '/sales-orders/customer/$customerId',
      );
      return (response.data as List)
          .map((json) => SalesOrder.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch customer sales orders',
        error: e,
        module: 'sales_orders',
        data: {'customerId': customerId},
      );
      return [];
    }
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 24)}) {
    final lastSync = _hiveService.getLastSyncTime('sales_orders');
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('sales_orders');
    final stats = _hiveService.getCacheStats();

    return {
      'cached_orders': stats['sales_orders'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }
}
