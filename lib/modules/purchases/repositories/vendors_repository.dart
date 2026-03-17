// FILE: lib/modules/purchases/repositories/vendors_repository.dart
// Repository pattern for Vendors - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/core/services/hive_service.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/purchases/models/vendor_model.dart';

class VendorsRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;

  VendorsRepository({ApiClient? apiClient, HiveService? hiveService})
    : _apiClient = apiClient ?? ApiClient(),
      _hiveService = hiveService ?? HiveService();

  /// Fetch vendors - Online-first with offline fallback
  Future<List<Vendor>> getVendors({bool forceRefresh = false}) async {
    try {
      // Online-first: Fetch from API
      final response = await _apiClient.get('/vendors');

      final List<Vendor> vendors = (response.data as List)
          .map((json) => Vendor.fromJson(json))
          .toList();

      // Cache to Hive for offline access
      await _hiveService.saveVendors(vendors);

      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('vendors');

      return vendors;
    } catch (e) {
      // Offline fallback: Return cached data
      AppLogger.warning(
        'API fetch failed, using cached vendors',
        error: e,
        module: 'vendors',
      );

      final cachedVendors = _hiveService.getVendors();

      if (cachedVendors.isEmpty) {
        rethrow;
      }

      return cachedVendors;
    }
  }

  /// Get single vendor by ID
  Future<Vendor?> getVendor(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getVendor(id);
    if (cached != null) {
      return cached;
    }

    // Not in cache, fetch from API
    try {
      final response = await _apiClient.get('/vendors/$id');
      final vendor = Vendor.fromJson(response.data);

      await _hiveService.saveVendor(vendor);
      return vendor;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch vendor',
        error: e,
        module: 'vendors',
        data: {'vendorId': id},
      );
      return null;
    }
  }

  /// Create new vendor
  Future<Vendor> createVendor(Vendor vendorData) async {
    try {
      final response = await _apiClient.post(
        '/vendors',
        data: vendorData.toJson(),
      );
      final createdVendor = Vendor.fromJson(response.data);

      // Cache locally
      await _hiveService.saveVendor(createdVendor);

      return createdVendor;
    } catch (e) {
      AppLogger.error('Failed to create vendor', error: e, module: 'vendors');
      rethrow;
    }
  }

  /// Update existing vendor
  Future<Vendor> updateVendor(String id, Vendor vendorData) async {
    try {
      final response = await _apiClient.put(
        '/vendors/$id',
        data: vendorData.toJson(),
      );
      final updatedVendor = Vendor.fromJson(response.data);

      // Update cache
      await _hiveService.saveVendor(updatedVendor);

      return updatedVendor;
    } catch (e) {
      AppLogger.error(
        'Failed to update vendor',
        error: e,
        module: 'vendors',
        data: {'vendorId': id},
      );
      rethrow;
    }
  }

  /// Delete vendor
  Future<void> deleteVendor(String id) async {
    try {
      await _apiClient.delete('/vendors/$id');

      // Remove from cache
      await _hiveService.vendorsBox.delete(id);
    } catch (e) {
      AppLogger.error(
        'Failed to delete vendor',
        error: e,
        module: 'vendors',
        data: {'vendorId': id},
      );
      rethrow;
    }
  }

  /// Search vendors by name or company
  Future<List<Vendor>> searchVendors(String query) async {
    try {
      final response = await _apiClient.get('/vendors/search?q=$query');
      return (response.data as List)
          .map((json) => Vendor.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to search vendors',
        error: e,
        module: 'vendors',
        data: {'query': query},
      );
      return [];
    }
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 24)}) {
    final lastSync = _hiveService.getLastSyncTime('vendors');
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('vendors');
    final stats = _hiveService.getCacheStats();

    return {
      'cached_vendors': stats['vendors'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }
}
