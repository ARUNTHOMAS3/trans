// FILE: lib/modules/sales/eway_bills/repositories/eway_bills_repository.dart
// Repository pattern for E-way Bills - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/shared/services/hive_service.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/sales/eway_bills/models/sales_eway_bill_model.dart';

class EwayBillsRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;

  EwayBillsRepository({ApiClient? apiClient, HiveService? hiveService})
    : _apiClient = apiClient ?? ApiClient(),
      _hiveService = hiveService ?? HiveService();

  /// Fetch E-way bills - Online-first with offline fallback
  Future<List<SalesEWayBill>> getEwayBills({bool forceRefresh = false}) async {
    try {
      // Online-first: Fetch from API
      final response = await _apiClient.get('/eway-bills');

      final List<SalesEWayBill> ewayBills = (response.data as List)
          .map((json) => SalesEWayBill.fromJson(json))
          .toList();

      // Cache to Hive for offline access
      await _hiveService.saveEwayBills(ewayBills);

      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('eway_bills');

      return ewayBills;
    } catch (e) {
      // Offline fallback: Return cached data
      AppLogger.warning(
        'API fetch failed, using cached E-way bills',
        error: e,
        module: 'eway_bills',
      );

      final cachedEwayBills = _hiveService.getEwayBills();

      if (cachedEwayBills.isEmpty) {
        rethrow;
      }

      return cachedEwayBills;
    }
  }

  /// Get single E-way bill by ID
  Future<SalesEWayBill?> getEwayBill(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getEwayBill(id);
    if (cached != null) {
      return cached;
    }

    // Not in cache, fetch from API
    try {
      final response = await _apiClient.get('/eway-bills/$id');
      final ewayBill = SalesEWayBill.fromJson(response.data);

      await _hiveService.saveEwayBill(ewayBill);
      return ewayBill;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch E-way bill',
        error: e,
        module: 'eway_bills',
        data: {'ewayBillId': id},
      );
      return null;
    }
  }

  /// Create new E-way bill
  Future<SalesEWayBill> createEwayBill(SalesEWayBill ewayBillData) async {
    try {
      final response = await _apiClient.post(
        '/eway-bills',
        data: ewayBillData.toJson(),
      );
      final createdEwayBill = SalesEWayBill.fromJson(response.data);

      // Cache locally
      await _hiveService.saveEwayBill(createdEwayBill);

      return createdEwayBill;
    } catch (e) {
      AppLogger.error(
        'Failed to create E-way bill',
        error: e,
        module: 'eway_bills',
      );
      rethrow;
    }
  }

  /// Update existing E-way bill
  Future<SalesEWayBill> updateEwayBill(
    String id,
    SalesEWayBill ewayBillData,
  ) async {
    try {
      final response = await _apiClient.put(
        '/eway-bills/$id',
        data: ewayBillData.toJson(),
      );
      final updatedEwayBill = SalesEWayBill.fromJson(response.data);

      // Update cache
      await _hiveService.saveEwayBill(updatedEwayBill);

      return updatedEwayBill;
    } catch (e) {
      AppLogger.error(
        'Failed to update E-way bill',
        error: e,
        module: 'eway_bills',
        data: {'ewayBillId': id},
      );
      rethrow;
    }
  }

  /// Delete E-way bill
  Future<void> deleteEwayBill(String id) async {
    try {
      await _apiClient.delete('/eway-bills/$id');

      // Remove from cache
      await _hiveService.ewayBillsBox.delete(id);
    } catch (e) {
      AppLogger.error(
        'Failed to delete E-way bill',
        error: e,
        module: 'eway_bills',
        data: {'ewayBillId': id},
      );
      rethrow;
    }
  }

  /// Get E-way bills by sales order
  Future<List<SalesEWayBill>> getEwayBillsBySalesOrder(
    String salesOrderId,
  ) async {
    try {
      final response = await _apiClient.get(
        '/eway-bills/sales-order/$salesOrderId',
      );
      return (response.data as List)
          .map((json) => SalesEWayBill.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch E-way bills for sales order',
        error: e,
        module: 'eway_bills',
        data: {'salesOrderId': salesOrderId},
      );
      return [];
    }
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 24)}) {
    final lastSync = _hiveService.getLastSyncTime('eway_bills');
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('eway_bills');
    final stats = _hiveService.getCacheStats();

    return {
      'cached_eway_bills': stats['eway_bills'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }
}
