// FILE: lib/modules/sales/repositories/customers_repository.dart
// Repository pattern for Customers - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/shared/services/hive_service.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/sales/models/sales_customer_model.dart';

class CustomersRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;

  CustomersRepository({ApiClient? apiClient, HiveService? hiveService})
    : _apiClient = apiClient ?? ApiClient(),
      _hiveService = hiveService ?? HiveService();

  /// Fetch customers - Online-first with offline fallback
  Future<List<SalesCustomer>> getCustomers({bool forceRefresh = false}) async {
    try {
      // Online-first: Fetch from API
      final response = await _apiClient.get('/sales/customers');

      final List<SalesCustomer> customers = (response.data as List)
          .map((json) => SalesCustomer.fromJson(json))
          .toList();

      // Cache to Hive for offline access
      await _hiveService.saveCustomers(customers);

      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('customers');

      return customers;
    } catch (e) {
      // Offline fallback: Return cached data
      AppLogger.warning(
        'API fetch failed, using cached customers',
        error: e,
        module: 'customers',
      );

      final cachedCustomers = _hiveService.getCustomers();

      if (cachedCustomers.isEmpty) {
        rethrow;
      }

      return cachedCustomers;
    }
  }

  /// Get single customer by ID
  Future<SalesCustomer?> getCustomer(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getCustomer(id);
    if (cached != null) {
      return cached;
    }

    // Not in cache, fetch from API
    try {
      final response = await _apiClient.get('/sales/customers/$id');
      final customer = SalesCustomer.fromJson(response.data);

      await _hiveService.saveCustomer(customer);
      return customer;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch customer',
        error: e,
        module: 'customers',
        data: {'customerId': id},
      );
      return null;
    }
  }

  /// Create new customer
  Future<SalesCustomer> createCustomer(SalesCustomer customerData) async {
    try {
      final response = await _apiClient.post(
        '/sales/customers',
        data: customerData.toJson(),
      );
      final createdCustomer = SalesCustomer.fromJson(response.data);

      // Cache locally
      await _hiveService.saveCustomer(createdCustomer);

      return createdCustomer;
    } catch (e) {
      AppLogger.error(
        'Failed to create customer',
        error: e,
        module: 'customers',
      );
      rethrow;
    }
  }

  /// Update existing customer
  Future<SalesCustomer> updateCustomer(
    String id,
    SalesCustomer customerData,
  ) async {
    try {
      final response = await _apiClient.put(
        '/sales/customers/$id',
        data: customerData.toJson(),
      );
      final updatedCustomer = SalesCustomer.fromJson(response.data);

      // Update cache
      await _hiveService.saveCustomer(updatedCustomer);

      return updatedCustomer;
    } catch (e) {
      AppLogger.error(
        'Failed to update customer',
        error: e,
        module: 'customers',
        data: {'customerId': id},
      );
      rethrow;
    }
  }

  /// Delete customer
  Future<void> deleteCustomer(String id) async {
    try {
      await _apiClient.delete('/sales/customers/$id');

      // Remove from cache
      await _hiveService.customersBox.delete(id);
    } catch (e) {
      AppLogger.error(
        'Failed to delete customer',
        error: e,
        module: 'customers',
        data: {'customerId': id},
      );
      rethrow;
    }
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 24)}) {
    final lastSync = _hiveService.getLastSyncTime('customers');
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('customers');
    final stats = _hiveService.getCacheStats();

    return {
      'cached_customers': stats['customers'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }
}
