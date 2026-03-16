// FILE: lib/modules/inventory/repositories/transfers_repository.dart
// Repository pattern for Stock Transfers - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/shared/services/hive_service.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/inventory/models/stock_transfer_model.dart';

class TransfersRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;

  TransfersRepository({ApiClient? apiClient, HiveService? hiveService})
    : _apiClient = apiClient ?? ApiClient(),
      _hiveService = hiveService ?? HiveService();

  /// Fetch stock transfers - Online-first with offline fallback
  Future<List<StockTransfer>> getTransfers({
    bool forceRefresh = false,
  }) async {
    try {
      // Online-first: Fetch from API
      final response = await _apiClient.get('/stock-transfers');
      
      final List<StockTransfer> transfers = (response.data as List)
          .map((json) => StockTransfer.fromJson(json))
          .toList();
      
      // Cache to Hive for offline access
      await _hiveService.saveTransfers(transfers);
      
      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('transfers');
      
      return transfers;
    } catch (e) {
      // Offline fallback: Return cached data
      AppLogger.warning(
        'API fetch failed, using cached transfers',
        error: e,
        module: 'transfers',
      );
      
      final cachedTransfers = _hiveService.getTransfers();
      
      if (cachedTransfers.isEmpty) {
        rethrow;
      }
      
      return cachedTransfers;
    }
  }

  /// Get single transfer by ID
  Future<StockTransfer?> getTransfer(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getTransfer(id);
    if (cached != null) {
      return cached;
    }
    
    // Not in cache, fetch from API
    try {
      final response = await _apiClient.get('/stock-transfers/$id');
      final transfer = StockTransfer.fromJson(response.data);
      
      await _hiveService.saveTransfer(transfer);
      return transfer;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch transfer',
        error: e,
        module: 'transfers',
        data: {'transferId': id},
      );
      return null;
    }
  }

  /// Create new stock transfer
  Future<StockTransfer> createTransfer(StockTransfer transferData) async {
    try {
      final response = await _apiClient.post(
        '/stock-transfers',
        data: transferData.toJson(),
      );
      final createdTransfer = StockTransfer.fromJson(response.data);
      
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
        '/stock-transfers/$id',
        data: transferData.toJson(),
      );
      final updatedTransfer = StockTransfer.fromJson(response.data);
      
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
      await _apiClient.delete('/stock-transfers/$id');
      
      // Remove from cache
      await _hiveService.transfersBox.delete(id);
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
      final response = await _apiClient.post(
        '/stock-transfers/$id/initiate',
      );
      final initiatedTransfer = StockTransfer.fromJson(response.data);
      
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

  /// Receive transfer items
  Future<StockTransfer> receiveTransfer(
    String id,
    List<Map<String, dynamic>> receivedItems,
  ) async {
    try {
      final response = await _apiClient.post(
        '/stock-transfers/$id/receive',
        data: {'items': receivedItems},
      );
      final receivedTransfer = StockTransfer.fromJson(response.data);
      
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
        '/stock-transfers/$id/cancel',
        data: {'reason': reason},
      );
      final cancelledTransfer = StockTransfer.fromJson(response.data);
      
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
      final response = await _apiClient.get(
        '/stock-transfers/from/$warehouseId',
      );
      return (response.data as List)
          .map((json) => StockTransfer.fromJson(json))
          .toList();
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
  Future<List<StockTransfer>> getTransfersToWarehouse(String warehouseId) async {
    try {
      final response = await _apiClient.get(
        '/stock-transfers/to/$warehouseId',
      );
      return (response.data as List)
          .map((json) => StockTransfer.fromJson(json))
          .toList();
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
      final response = await _apiClient.get('/stock-transfers/status/$status');
      return (response.data as List)
          .map((json) => StockTransfer.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch transfers by status',
        error: e,
        module: 'transfers',
        data: {'status': status},
      );
      // Fallback: Filter cached items
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
