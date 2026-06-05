// FILE: lib/modules/inventory/repositories/adjustments_repository.dart
// Repository pattern for Inventory Adjustments - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/shared/services/hive_service.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_model.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_reason_model.dart';

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
      final response = await _apiClient.get(ApiEndpoints.inventoryAdjustments);
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? (payload['data'] as List<dynamic>? ?? const <dynamic>[])
                : const <dynamic>[]);

      final List<InventoryAdjustment> adjustments = rows
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
    // API-first for detail view so items/batches and latest totals are accurate.
    try {
      final response = await _apiClient.get('/inventory-adjustments/$id');
      final dynamic payload = response.data;
      final Map<String, dynamic> row = payload is Map<String, dynamic>
          ? (payload['data'] is Map<String, dynamic>
                ? payload['data'] as Map<String, dynamic>
                : payload)
          : <String, dynamic>{};
      if (row.isEmpty) return null;
      final adjustment = InventoryAdjustment.fromJson(row);

      await _hiveService.saveAdjustment(adjustment);
      return adjustment;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch adjustment',
        error: e,
        module: 'adjustments',
        data: {'adjustmentId': id},
      );
      return _hiveService.getAdjustment(id);
    }
  }

  /// Get inventory adjustment reasons master list
  Future<List<InventoryAdjustmentReason>> getAdjustmentReasons() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.inventoryAdjustmentReasons,
      );
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? (payload['data'] as List<dynamic>? ?? const <dynamic>[])
                : const <dynamic>[]);

      return rows
          .map(
            (json) => InventoryAdjustmentReason.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch adjustment reasons',
        error: e,
        module: 'adjustments',
      );
      return [];
    }
  }

  Future<InventoryAdjustmentReason> createAdjustmentReason(
    String name, {
    String? code,
    bool isActive = true,
    int? sortOrder,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.inventoryAdjustmentReasons,
      data: {
        'name': name,
        'code': code,
        'is_active': isActive,
        'sort_order': sortOrder,
      },
    );
    final dynamic payload = response.data;
    final Map<String, dynamic> row = payload is Map<String, dynamic>
        ? (payload['data'] is Map<String, dynamic>
              ? payload['data'] as Map<String, dynamic>
              : payload)
        : <String, dynamic>{};
    return InventoryAdjustmentReason.fromJson(row);
  }

  Future<InventoryAdjustmentReason> updateAdjustmentReason(
    String id, {
    String? name,
    String? code,
    bool? isActive,
    int? sortOrder,
  }) async {
    final response = await _apiClient.patch(
      '${ApiEndpoints.inventoryAdjustmentReasons}/$id',
      data: {
        if (name != null) 'name': name,
        if (code != null) 'code': code,
        if (isActive != null) 'is_active': isActive,
        if (sortOrder != null) 'sort_order': sortOrder,
      },
    );
    final dynamic payload = response.data;
    final Map<String, dynamic> row = payload is Map<String, dynamic>
        ? (payload['data'] is Map<String, dynamic>
              ? payload['data'] as Map<String, dynamic>
              : payload)
        : <String, dynamic>{};
    return InventoryAdjustmentReason.fromJson(row);
  }

  Future<void> deleteAdjustmentReason(String id) async {
    await _apiClient.delete('${ApiEndpoints.inventoryAdjustmentReasons}/$id');
  }

  /// Create new inventory adjustment
  Future<InventoryAdjustment> createAdjustment(
    InventoryAdjustment adjustmentData,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.inventoryAdjustments,
        data: adjustmentData.toJson(),
      );
      final dynamic payload = response.data;
      final Map<String, dynamic> row = payload is Map<String, dynamic>
          ? (payload['data'] is Map<String, dynamic>
                ? payload['data'] as Map<String, dynamic>
                : payload)
          : <String, dynamic>{};
      final createdAdjustment = InventoryAdjustment.fromJson(row);

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
        '${ApiEndpoints.inventoryAdjustments}/$id',
        data: adjustmentData.toJson(),
      );
      final dynamic payload = response.data;
      final Map<String, dynamic> row = payload is Map<String, dynamic>
          ? (payload['data'] is Map<String, dynamic>
                ? payload['data'] as Map<String, dynamic>
                : payload)
          : <String, dynamic>{};
      final updatedAdjustment = InventoryAdjustment.fromJson(row);

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
      await _apiClient.delete('${ApiEndpoints.inventoryAdjustments}/$id');

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
        '${ApiEndpoints.inventoryAdjustments}/$id/approve',
      );
      final dynamic payload = response.data;
      final Map<String, dynamic> row = payload is Map<String, dynamic>
          ? (payload['data'] is Map<String, dynamic>
                ? payload['data'] as Map<String, dynamic>
                : payload)
          : <String, dynamic>{};
      final approvedAdjustment = InventoryAdjustment.fromJson(row);

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
        '${ApiEndpoints.inventoryAdjustments}/$id/reject',
        data: {'reason': reason},
      );
      final dynamic payload = response.data;
      final Map<String, dynamic> row = payload is Map<String, dynamic>
          ? (payload['data'] is Map<String, dynamic>
                ? payload['data'] as Map<String, dynamic>
                : payload)
          : <String, dynamic>{};
      final rejectedAdjustment = InventoryAdjustment.fromJson(row);

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
        '${ApiEndpoints.inventoryAdjustments}?product_id=$productId',
      );
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? (payload['data'] as List<dynamic>? ?? const <dynamic>[])
                : const <dynamic>[]);
      return rows.map((json) => InventoryAdjustment.fromJson(json)).toList();
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
        '${ApiEndpoints.inventoryAdjustments}?warehouse_id=$warehouseId',
      );
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? (payload['data'] as List<dynamic>? ?? const <dynamic>[])
                : const <dynamic>[]);
      return rows.map((json) => InventoryAdjustment.fromJson(json)).toList();
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
        '${ApiEndpoints.inventoryAdjustments}?search=$reason',
      );
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? (payload['data'] as List<dynamic>? ?? const <dynamic>[])
                : const <dynamic>[]);
      return rows.map((json) => InventoryAdjustment.fromJson(json)).toList();
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
      final response = await _apiClient.get(
        '${ApiEndpoints.inventoryAdjustments}?status=draft',
      );
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? (payload['data'] as List<dynamic>? ?? const <dynamic>[])
                : const <dynamic>[]);
      return rows.map((json) => InventoryAdjustment.fromJson(json)).toList();
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

  /// Fetch batch suggestions for autocomplete in select-batches dialog
  Future<List<Map<String, dynamic>>> getBatchSuggestions({
    required String productId,
    required String query,
  }) async {
    try {
      final response = await _apiClient.get(
        '/inventory-adjustments/batch-suggestions',
        queryParameters: {'product_id': productId, 'q': query},
      );
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? (payload['data'] as List<dynamic>? ?? const <dynamic>[])
                : const <dynamic>[]);
      return rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      AppLogger.warning('Batch suggestions fetch failed', error: e, module: 'adjustments');
      return [];
    }
  }

  /// Fetch bin options (id + code) for a warehouse
  Future<List<Map<String, String>>> getBinOptions(String warehouseId) async {
    if (warehouseId.trim().isEmpty) return const [];
    try {
      final response = await _apiClient.get(
        '/inventory-adjustments/bin-master',
        queryParameters: {'warehouse_id': warehouseId, 'active': 'true'},
      );
      final dynamic payload = response.data;
      final List<dynamic> rows = payload is List
          ? payload
          : (payload is Map<String, dynamic>
                ? (payload['data'] as List<dynamic>? ?? const <dynamic>[])
                : const <dynamic>[]);
      return rows
          .map((e) {
            final id = (e['id'] ?? '').toString().trim();
            final code = (e['bin_code'] ?? '').toString().trim();
            if (id.isEmpty || code.isEmpty) return null;
            return <String, String>{'id': id, 'bin_code': code};
          })
          .whereType<Map<String, String>>()
          .toList();
    } catch (e) {
      AppLogger.warning('Bin codes fetch failed', error: e, module: 'adjustments');
      return [];
    }
  }

  /// Backward-compatible helper when only codes are needed.
  Future<List<String>> getBinCodes(String warehouseId) async {
    final rows = await getBinOptions(warehouseId);
    return rows.map((e) => e['bin_code']!).toList(growable: false);
  }
}
