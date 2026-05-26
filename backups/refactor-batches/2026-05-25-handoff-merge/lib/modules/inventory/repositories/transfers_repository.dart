// FILE: lib/modules/inventory/repositories/transfers_repository.dart
// Repository pattern for Stock Transfers - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/shared/services/hive_service.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_transfer_model.dart';

class TransfersRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;
  static const String _basePath = '/transfer-orders';
  static const String _legacyBasePath = '/stock-transfers';

  TransfersRepository({ApiClient? apiClient, HiveService? hiveService})
    : _apiClient = apiClient ?? ApiClient(),
      _hiveService = hiveService ?? HiveService();

  List<dynamic> _extractListPayload(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final data = payload['data'];
      if (data is List) return data;
    }
    return const <dynamic>[];
  }

  Map<String, dynamic>? _extractMapPayload(dynamic payload) {
    if (payload is Map) {
      final data = payload['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return Map<String, dynamic>.from(payload);
    }
    return null;
  }

  /// Fetch all transfers with optional forced refresh.
  /// Implements online-first fetching with local Hive fallback.
  Future<List<StockTransfer>> getTransfers({bool forceRefresh = false}) async {
    final stopwatch = Stopwatch()..start();
    AppLogger.debug(
      '🔄 TransfersRepository.getTransfers started',
      module: 'transfers_repo',
    );

    try {
      // 1. Fetch from primary API
      AppLogger.debug('📡 Fetching from $_basePath', module: 'transfers_repo');
      final response = await _apiClient.get(_basePath, useCache: !forceRefresh);

      final rows = _extractListPayload(response.data);
      AppLogger.debug(
        '📦 Received ${rows.length} transfers',
        module: 'transfers_repo',
      );

      // 2. Parse JSON
      final List<StockTransfer> transfers = rows
          .map((json) => StockTransfer.fromJson(json))
          .toList();

      // 3. Cache to Hive (Optimized with putAll)
      stopwatch.stop();
      AppLogger.performance('getTransfers (API + Parse)', stopwatch.elapsed);

      _saveToCache(transfers);

      return transfers;
    } catch (e) {
      AppLogger.warning(
        '⚠️ Primary API failed, trying legacy or cache',
        error: e,
        module: 'transfers_repo',
      );

      // Try legacy path ONLY if it was a 404 or specific error,
      // but here we just try it as a secondary check.
      try {
        final legacyResponse = await _apiClient.get(
          _legacyBasePath,
          useCache: !forceRefresh,
        );
        final rows = _extractListPayload(legacyResponse.data);
        final transfers = rows
            .map((json) => StockTransfer.fromJson(json))
            .toList();
        _saveToCache(transfers);
        return transfers;
      } catch (legacyErr) {
        AppLogger.error(
          '❌ Legacy path also failed',
          error: legacyErr,
          module: 'transfers_repo',
        );

        // 4. Final fallback: Hive cache
        await _hiveService.ensureTransfersBox();
        final cached = _hiveService.getTransfers();

        if (cached.isEmpty) {
          AppLogger.error(
            '💀 No cached data available',
            module: 'transfers_repo',
          );
          rethrow;
        }

        AppLogger.info(
          '💾 Using ${cached.length} cached transfers',
          module: 'transfers_repo',
        );
        return cached;
      }
    }
  }

  void _saveToCache(List<StockTransfer> transfers) {
    // Non-blocking save
    _hiveService.saveTransfers(transfers).catchError((e) {
      AppLogger.error('Failed to save transfers to Hive', error: e);
    });
  }

  /// Fetch a single transfer detail.
  /// Prefer API for freshness; use cache only as fallback.
  Future<StockTransfer?> getTransfer(String id) async {
    AppLogger.debug(
      '🔍 TransfersRepository.getTransfer($id)',
      module: 'transfers_repo',
    );

    StockTransfer? cachedTransfer;
    // Try to read cache fast, but do not return it immediately.
    try {
      await _hiveService.ensureTransfersBox().timeout(
        const Duration(seconds: 2),
        onTimeout: () => null,
      );
      cachedTransfer = _hiveService.getTransfer(id);
      if (cachedTransfer != null) {
        AppLogger.debug(
          '⚡ Cache available (Detail), proceeding with API refresh',
          module: 'transfers_repo',
        );
      }
    } catch (e) {
      AppLogger.error(
        '⚠️ Hive cache check failed, proceeding with API only',
        error: e,
        module: 'transfers_repo',
      );
    }

    // 2. API Fetch
    try {
      final stopwatch = Stopwatch()..start();
      AppLogger.debug(
        '📡 Fetching transfer detail from $_basePath/$id',
        module: 'transfers_repo',
      );

      final response = await _apiClient
          .get('$_basePath/$id')
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw Exception('API request timed out (15s)'),
          );

      stopwatch.stop();
      AppLogger.performance('getTransfer Detail API', stopwatch.elapsed);

      final payload = _extractMapPayload(response.data);
      if (payload == null) {
        throw Exception(
          'ERR_EMPTY_PAYLOAD: Failed to extract transfer detail payload',
        );
      }

      final transfer = StockTransfer.fromJson(payload);

      // Update cache
      _hiveService.saveTransfer(transfer).catchError((e) {
        AppLogger.error(
          '❌ Failed to update transfer cache',
          error: e,
          module: 'transfers_repo',
        );
        return null;
      });

      return transfer;
    } catch (e) {
      AppLogger.error(
        '❌ getTransfer failed',
        error: e,
        module: 'transfers_repo',
        data: {'id': id},
      );
      if (cachedTransfer != null) {
        AppLogger.warning(
          '⚠️ API detail failed, returning cached transfer detail',
          module: 'transfers_repo',
          error: e,
          data: {'id': id},
        );
        return cachedTransfer;
      }
      rethrow;
    }
  }

  /// Create new stock transfer
  Future<StockTransfer> createTransfer(StockTransfer transferData) async {
    try {
      final response = await _apiClient.post(
        _basePath,
        data: transferData.toJson(),
      );
      final payload = _extractMapPayload(response.data);
      if (payload == null) {
        throw Exception('Invalid transfer create response');
      }
      final createdTransfer = StockTransfer.fromJson(payload);

      // Cache locally
      await _hiveService.saveTransfer(createdTransfer);

      return createdTransfer;
    } catch (e) {
      AppLogger.error(
        'Failed to create transfer',
        error: e,
        module: 'transfers',
      );
      rethrow;
    }
  }

  /// Update existing transfer
  Future<StockTransfer> updateTransfer(
    String id,
    StockTransfer transferData,
  ) async {
    try {
      final response = await _apiClient.put(
        '$_basePath/$id',
        data: transferData.toJson(),
      );
      final payload = _extractMapPayload(response.data);
      if (payload == null) {
        throw Exception('Invalid transfer update response');
      }
      final updatedTransfer = StockTransfer.fromJson(payload);

      // Update cache
      await _hiveService.saveTransfer(updatedTransfer);

      return updatedTransfer;
    } catch (e) {
      AppLogger.error(
        'Failed to update transfer',
        error: e,
        module: 'transfers',
        data: {'transferId': id},
      );
      rethrow;
    }
  }

  /// Delete transfer
  Future<void> deleteTransfer(String id) async {
    try {
      await _apiClient.delete('$_basePath/$id');

      // Remove from cache
      await _hiveService.deleteTransfer(id);
    } catch (e) {
      AppLogger.error(
        'Failed to delete transfer',
        error: e,
        module: 'transfers',
        data: {'transferId': id},
      );
      rethrow;
    }
  }

  /// Initiate transfer (change status to pending)
  Future<StockTransfer> initiateTransfer(String id) async {
    try {
      final response = await _apiClient.post('$_basePath/$id/initiate');
      final payload = _extractMapPayload(response.data);
      if (payload == null) {
        throw Exception('Invalid transfer initiate response');
      }
      final initiatedTransfer = StockTransfer.fromJson(payload);

      // Update cache
      await _hiveService.saveTransfer(initiatedTransfer);

      return initiatedTransfer;
    } catch (e) {
      AppLogger.error(
        'Failed to initiate transfer',
        error: e,
        module: 'transfers',
        data: {'transferId': id},
      );
      rethrow;
    }
  }

  /// Approve a transfer after initiation to complete the RECEIVE workflow.
  Future<StockTransfer> approveTransfer(String id) async {
    try {
      final response = await _apiClient.post('$_basePath/$id/approve');
      final payload = _extractMapPayload(response.data);
      if (payload == null) {
        throw Exception('Invalid transfer approve response');
      }
      final approvedTransfer = StockTransfer.fromJson(payload);

      await _hiveService.saveTransfer(approvedTransfer);

      return approvedTransfer;
    } catch (e) {
      AppLogger.error(
        'Failed to approve transfer',
        error: e,
        module: 'transfers',
        data: {'transferId': id},
      );
      rethrow;
    }
  }

  /// Receive transfer items
  Future<StockTransfer> receiveTransfer(
    String id,
    List<Map<String, dynamic>> receivedItems,
  ) async {
    try {
      final response = await _apiClient.post(
        '$_basePath/$id/receive',
        data: {'items': receivedItems},
      );
      final payload = _extractMapPayload(response.data);
      if (payload == null) {
        throw Exception('Invalid transfer receive response');
      }
      final receivedTransfer = StockTransfer.fromJson(payload);

      // Update cache
      await _hiveService.saveTransfer(receivedTransfer);

      return receivedTransfer;
    } catch (e) {
      AppLogger.error(
        'Failed to receive transfer',
        error: e,
        module: 'transfers',
        data: {'transferId': id},
      );
      rethrow;
    }
  }

  /// Cancel transfer
  Future<StockTransfer> cancelTransfer(String id, String reason) async {
    try {
      final response = await _apiClient.post(
        '$_basePath/$id/cancel',
        data: {'reason': reason},
      );
      final payload = _extractMapPayload(response.data);
      if (payload == null) {
        throw Exception('Invalid transfer cancel response');
      }
      final cancelledTransfer = StockTransfer.fromJson(payload);

      // Update cache
      await _hiveService.saveTransfer(cancelledTransfer);

      return cancelledTransfer;
    } catch (e) {
      AppLogger.error(
        'Failed to cancel transfer',
        error: e,
        module: 'transfers',
        data: {'transferId': id},
      );
      rethrow;
    }
  }

  /// Get transfers by from warehouse
  Future<List<StockTransfer>> getTransfersFromWarehouse(
    String warehouseId,
  ) async {
    try {
      final response = await _apiClient.get('$_basePath/from/$warehouseId');
      final rows = _extractListPayload(response.data);
      return rows.map((json) => StockTransfer.fromJson(json)).toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch outgoing transfers',
        error: e,
        module: 'transfers',
        data: {'warehouseId': warehouseId},
      );
      return [];
    }
  }

  /// Get transfers by to warehouse
  Future<List<StockTransfer>> getTransfersToWarehouse(
    String warehouseId,
  ) async {
    try {
      final response = await _apiClient.get('$_basePath/to/$warehouseId');
      final rows = _extractListPayload(response.data);
      return rows.map((json) => StockTransfer.fromJson(json)).toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch incoming transfers',
        error: e,
        module: 'transfers',
        data: {'warehouseId': warehouseId},
      );
      return [];
    }
  }

  /// Get transfers by status
  Future<List<StockTransfer>> getTransfersByStatus(String status) async {
    try {
      final response = await _apiClient.get('$_basePath/status/$status');
      final rows = _extractListPayload(response.data);
      return rows.map((json) => StockTransfer.fromJson(json)).toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch transfers by status',
        error: e,
        module: 'transfers',
        data: {'status': status},
      );
      // Fallback: Filter cached items
      await _hiveService.ensureTransfersBox();
      final allTransfers = _hiveService.getTransfers();
      return allTransfers.where((t) => t.status == status).toList();
    }
  }

  /// Get pending transfers (awaiting initiation)
  Future<List<StockTransfer>> getPendingTransfers() async {
    return getTransfersByStatus('draft');
  }

  /// Get in-transit transfers
  Future<List<StockTransfer>> getInTransitTransfers() async {
    return getTransfersByStatus('in_transit');
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 24)}) {
    final lastSync = _hiveService.getLastSyncTime('transfers');
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('transfers');
    final stats = _hiveService.getCacheStats();

    return {
      'cached_transfers': stats['transfers'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }
}
