// FILE: lib/modules/inventory/repositories/adjustments_repository.dart
// Repository pattern for Inventory Adjustments - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/shared/services/hive_service.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_model.dart';

class AdjustmentsRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;

  AdjustmentsRepository({ApiClient? apiClient, HiveService? hiveService})
    : _apiClient = apiClient ?? ApiClient(),
      _hiveService = hiveService ?? HiveService();

  /// Fetch inventory adjustments - Online-first with offline fallback
  Future<List<InventoryAdjustment>> getAdjustments({
    bool forceRefresh = false,
  }) async {
    try {
      // Online-first: Fetch from API
      final response = await _apiClient.get('/inventory-adjustments');

      final List<InventoryAdjustment> adjustments = (response.data as List)
          .map((json) => InventoryAdjustment.fromJson(json))
          .toList();

      // Cache to Hive for offline access
      await _hiveService.saveAdjustments(adjustments);

      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('adjustments');

      return adjustments;
    } catch (e) {
      // Offline fallback: Return cached data
      AppLogger.warning(
        'API fetch failed, using cached adjustments',
        error: e,
        module: 'adjustments',
      );

      final cachedAdjustments = _hiveService.getAdjustments();

      if (cachedAdjustments.isEmpty) {
        rethrow;
      }

      return cachedAdjustments;
    }
  }

  /// Get single adjustment by ID
  Future<InventoryAdjustment?> getAdjustment(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getAdjustment(id);
    if (cached != null) {
      return cached;
    }

    // Not in cache, fetch from API
    try {
      final response = await _apiClient.get('/inventory-adjustments/$id');
      final adjustment = InventoryAdjustment.fromJson(response.data);

      await _hiveService.saveAdjustment(adjustment);
      return adjustment;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch adjustment',
        error: e,
        module: 'adjustments',
        data: {'adjustmentId': id},
      );
      return null;
    }
  }

  /// Create new inventory adjustment
  Future<InventoryAdjustment> createAdjustment(
    InventoryAdjustment adjustmentData,
  ) async {
    try {
      final response = await _apiClient.post(
        '/inventory-adjustments',
        data: adjustmentData.toJson(),
      );
      final createdAdjustment = InventoryAdjustment.fromJson(response.data);

      // Cache locally
      await _hiveService.saveAdjustment(createdAdjustment);

      return createdAdjustment;
    } catch (e) {
      AppLogger.error(
        'Failed to create adjustment',
        error: e,
        module: 'adjustments',
      );
      rethrow;
    }
  }

  /// Update existing adjustment
  Future<InventoryAdjustment> updateAdjustment(
    String id,
    InventoryAdjustment adjustmentData,
  ) async {
    try {
      final response = await _apiClient.put(
        '/inventory-adjustments/$id',
        data: adjustmentData.toJson(),
      );
      final updatedAdjustment = InventoryAdjustment.fromJson(response.data);

      // Update cache
      await _hiveService.saveAdjustment(updatedAdjustment);

      return updatedAdjustment;
    } catch (e) {
      AppLogger.error(
        'Failed to update adjustment',
        error: e,
        module: 'adjustments',
        data: {'adjustmentId': id},
      );
      rethrow;
    }
  }

  /// Delete adjustment
  Future<void> deleteAdjustment(String id) async {
    try {
      await _apiClient.delete('/inventory-adjustments/$id');

      // Remove from cache
      await _hiveService.adjustmentsBox.delete(id);
    } catch (e) {
      AppLogger.error(
        'Failed to delete adjustment',
        error: e,
        module: 'adjustments',
        data: {'adjustmentId': id},
      );
      rethrow;
    }
  }

  /// Approve adjustment
  Future<InventoryAdjustment> approveAdjustment(String id) async {
    try {
      final response = await _apiClient.post(
        '/inventory-adjustments/$id/approve',
      );
      final approvedAdjustment = InventoryAdjustment.fromJson(response.data);

      // Update cache
      await _hiveService.saveAdjustment(approvedAdjustment);

      return approvedAdjustment;
    } catch (e) {
      AppLogger.error(
        'Failed to approve adjustment',
        error: e,
        module: 'adjustments',
        data: {'adjustmentId': id},
      );
      rethrow;
    }
  }

  /// Reject adjustment
  Future<InventoryAdjustment> rejectAdjustment(String id, String reason) async {
    try {
      final response = await _apiClient.post(
        '/inventory-adjustments/$id/reject',
        data: {'reason': reason},
      );
      final rejectedAdjustment = InventoryAdjustment.fromJson(response.data);

      // Update cache
      await _hiveService.saveAdjustment(rejectedAdjustment);

      return rejectedAdjustment;
    } catch (e) {
      AppLogger.error(
        'Failed to reject adjustment',
        error: e,
        module: 'adjustments',
        data: {'adjustmentId': id},
      );
      rethrow;
    }
  }

  /// Get adjustments by product
  Future<List<InventoryAdjustment>> getAdjustmentsByProduct(
    String productId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/inventory-adjustments/product/$productId',
      );
      return (response.data as List)
          .map((json) => InventoryAdjustment.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch adjustments by product',
        error: e,
        module: 'adjustments',
        data: {'productId': productId},
      );
      return [];
    }
  }

  /// Get adjustments by warehouse
  Future<List<InventoryAdjustment>> getAdjustmentsByWarehouse(
    String warehouseId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/inventory-adjustments/warehouse/$warehouseId',
      );
      return (response.data as List)
          .map((json) => InventoryAdjustment.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch adjustments by warehouse',
        error: e,
        module: 'adjustments',
        data: {'warehouseId': warehouseId},
      );
      return [];
    }
  }

  /// Get adjustments by reason
  Future<List<InventoryAdjustment>> getAdjustmentsByReason(
    String reason,
  ) async {
    try {
      final response = await _apiClient.get(
        '/inventory-adjustments/reason/$reason',
      );
      return (response.data as List)
          .map((json) => InventoryAdjustment.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch adjustments by reason',
        error: e,
        module: 'adjustments',
        data: {'reason': reason},
      );
      return [];
    }
  }

  /// Get pending adjustments (awaiting approval)
  Future<List<InventoryAdjustment>> getPendingAdjustments() async {
    try {
      final response = await _apiClient.get('/inventory-adjustments/pending');
      return (response.data as List)
          .map((json) => InventoryAdjustment.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch pending adjustments',
        error: e,
        module: 'adjustments',
      );
      // Fallback: Filter cached items
      final allAdjustments = _hiveService.getAdjustments();
      return allAdjustments.where((adj) => adj.status == 'draft').toList();
    }
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 24)}) {
    final lastSync = _hiveService.getLastSyncTime('adjustments');
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('adjustments');
    final stats = _hiveService.getCacheStats();

    return {
      'cached_adjustments': stats['adjustments'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }
}
