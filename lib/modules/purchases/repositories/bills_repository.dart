// FILE: lib/modules/purchases/repositories/bills_repository.dart
// Repository pattern for Purchase Bills - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/core/services/hive_service.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/purchases/models/purchase_bill_model.dart';

class BillsRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;

  BillsRepository({ApiClient? apiClient, HiveService? hiveService})
    : _apiClient = apiClient ?? ApiClient(),
      _hiveService = hiveService ?? HiveService();

  /// Fetch purchase bills - Online-first with offline fallback
  Future<List<PurchaseBill>> getBills({bool forceRefresh = false}) async {
    try {
      // Online-first: Fetch from API
      final response = await _apiClient.get('/purchase-bills');

      final List<PurchaseBill> bills = (response.data as List)
          .map((json) => PurchaseBill.fromJson(json))
          .toList();

      // Cache to Hive for offline access
      await _hiveService.saveBills(bills);

      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('bills');

      return bills;
    } catch (e) {
      // Offline fallback: Return cached data
      AppLogger.warning(
        'API fetch failed, using cached purchase bills',
        error: e,
        module: 'bills',
      );

      final cachedBills = _hiveService.getBills();

      if (cachedBills.isEmpty) {
        rethrow;
      }

      return cachedBills;
    }
  }

  /// Get single purchase bill by ID
  Future<PurchaseBill?> getBill(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getBill(id);
    if (cached != null) {
      return cached;
    }

    // Not in cache, fetch from API
    try {
      final response = await _apiClient.get('/purchase-bills/$id');
      final bill = PurchaseBill.fromJson(response.data);

      await _hiveService.saveBill(bill);
      return bill;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch purchase bill',
        error: e,
        module: 'bills',
        data: {'billId': id},
      );
      return null;
    }
  }

  /// Create new purchase bill
  Future<PurchaseBill> createBill(PurchaseBill billData) async {
    try {
      final response = await _apiClient.post(
        '/purchase-bills',
        data: billData.toJson(),
      );
      final createdBill = PurchaseBill.fromJson(response.data);

      // Cache locally
      await _hiveService.saveBill(createdBill);

      return createdBill;
    } catch (e) {
      AppLogger.error(
        'Failed to create purchase bill',
        error: e,
        module: 'bills',
      );
      rethrow;
    }
  }

  /// Update existing purchase bill
  Future<PurchaseBill> updateBill(String id, PurchaseBill billData) async {
    try {
      final response = await _apiClient.put(
        '/purchase-bills/$id',
        data: billData.toJson(),
      );
      final updatedBill = PurchaseBill.fromJson(response.data);

      // Update cache
      await _hiveService.saveBill(updatedBill);

      return updatedBill;
    } catch (e) {
      AppLogger.error(
        'Failed to update purchase bill',
        error: e,
        module: 'bills',
        data: {'billId': id},
      );
      rethrow;
    }
  }

  /// Delete purchase bill
  Future<void> deleteBill(String id) async {
    try {
      await _apiClient.delete('/purchase-bills/$id');

      // Remove from cache
      await _hiveService.billsBox.delete(id);
    } catch (e) {
      AppLogger.error(
        'Failed to delete purchase bill',
        error: e,
        module: 'bills',
        data: {'billId': id},
      );
      rethrow;
    }
  }

  /// Get purchase bills by vendor
  Future<List<PurchaseBill>> getBillsByVendor(String vendorId) async {
    try {
      final response = await _apiClient.get('/purchase-bills/vendor/$vendorId');
      return (response.data as List)
          .map((json) => PurchaseBill.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch vendor purchase bills',
        error: e,
        module: 'bills',
        data: {'vendorId': vendorId},
      );
      return [];
    }
  }

  /// Get purchase bills by status
  Future<List<PurchaseBill>> getBillsByStatus(String status) async {
    try {
      final response = await _apiClient.get('/purchase-bills/status/$status');
      return (response.data as List)
          .map((json) => PurchaseBill.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch purchase bills by status',
        error: e,
        module: 'bills',
        data: {'status': status},
      );
      return [];
    }
  }

  /// Get overdue bills
  Future<List<PurchaseBill>> getOverdueBills() async {
    try {
      final response = await _apiClient.get('/purchase-bills/overdue');
      return (response.data as List)
          .map((json) => PurchaseBill.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch overdue bills',
        error: e,
        module: 'bills',
      );
      return [];
    }
  }

  /// Make payment against a bill
  Future<PurchaseBill> makePayment(String billId, double amount) async {
    try {
      final response = await _apiClient.post(
        '/purchase-bills/$billId/payment',
        data: {'amount': amount},
      );
      final updatedBill = PurchaseBill.fromJson(response.data);

      // Update cache
      await _hiveService.saveBill(updatedBill);

      return updatedBill;
    } catch (e) {
      AppLogger.error(
        'Failed to make payment on bill',
        error: e,
        module: 'bills',
        data: {'billId': billId, 'amount': amount},
      );
      rethrow;
    }
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 24)}) {
    final lastSync = _hiveService.getLastSyncTime('bills');
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('bills');
    final stats = _hiveService.getCacheStats();

    return {
      'cached_bills': stats['bills'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }
}
