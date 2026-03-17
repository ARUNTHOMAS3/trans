// FILE: lib/modules/sales/repositories/payments_repository.dart
// Repository pattern for Payments - Online-first with offline fallback (PRD Section 12.2)

import 'package:zerpai_erp/core/services/hive_service.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/sales/models/sales_payment_model.dart';

class PaymentsRepository {
  final ApiClient _apiClient;
  final HiveService _hiveService;

  PaymentsRepository({ApiClient? apiClient, HiveService? hiveService})
    : _apiClient = apiClient ?? ApiClient(),
      _hiveService = hiveService ?? HiveService();

  /// Fetch payments - Online-first with offline fallback
  Future<List<SalesPayment>> getPayments({bool forceRefresh = false}) async {
    try {
      // Online-first: Fetch from API
      final response = await _apiClient.get('/payments');

      final List<SalesPayment> payments = (response.data as List)
          .map((json) => SalesPayment.fromJson(json))
          .toList();

      // Cache to Hive for offline access
      await _hiveService.savePayments(payments);

      // Update last sync timestamp
      await _hiveService.updateLastSyncTime('payments');

      return payments;
    } catch (e) {
      // Offline fallback: Return cached data
      AppLogger.warning(
        'API fetch failed, using cached payments',
        error: e,
        module: 'payments',
      );

      final cachedPayments = _hiveService.getPayments();

      if (cachedPayments.isEmpty) {
        rethrow;
      }

      return cachedPayments;
    }
  }

  /// Get single payment by ID
  Future<SalesPayment?> getPayment(String id) async {
    // Check cache first (faster)
    final cached = _hiveService.getPayment(id);
    if (cached != null) {
      return cached;
    }

    // Not in cache, fetch from API
    try {
      final response = await _apiClient.get('/payments/$id');
      final payment = SalesPayment.fromJson(response.data);

      await _hiveService.savePayment(payment);
      return payment;
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch payment',
        error: e,
        module: 'payments',
        data: {'paymentId': id},
      );
      return null;
    }
  }

  /// Create new payment
  Future<SalesPayment> createPayment(SalesPayment paymentData) async {
    try {
      final response = await _apiClient.post(
        '/payments',
        data: paymentData.toJson(),
      );
      final createdPayment = SalesPayment.fromJson(response.data);

      // Cache locally
      await _hiveService.savePayment(createdPayment);

      return createdPayment;
    } catch (e) {
      AppLogger.error('Failed to create payment', error: e, module: 'payments');
      rethrow;
    }
  }

  /// Update existing payment
  Future<SalesPayment> updatePayment(
    String id,
    SalesPayment paymentData,
  ) async {
    try {
      final response = await _apiClient.put(
        '/payments/$id',
        data: paymentData.toJson(),
      );
      final updatedPayment = SalesPayment.fromJson(response.data);

      // Update cache
      await _hiveService.savePayment(updatedPayment);

      return updatedPayment;
    } catch (e) {
      AppLogger.error(
        'Failed to update payment',
        error: e,
        module: 'payments',
        data: {'paymentId': id},
      );
      rethrow;
    }
  }

  /// Delete payment
  Future<void> deletePayment(String id) async {
    try {
      await _apiClient.delete('/payments/$id');

      // Remove from cache
      await _hiveService.paymentsBox.delete(id);
    } catch (e) {
      AppLogger.error(
        'Failed to delete payment',
        error: e,
        module: 'payments',
        data: {'paymentId': id},
      );
      rethrow;
    }
  }

  /// Get payments by customer
  Future<List<SalesPayment>> getPaymentsByCustomer(String customerId) async {
    try {
      final response = await _apiClient.get('/payments/customer/$customerId');
      return (response.data as List)
          .map((json) => SalesPayment.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch customer payments',
        error: e,
        module: 'payments',
        data: {'customerId': customerId},
      );
      return [];
    }
  }

  /// Check if cache is stale
  bool isCacheStale({Duration threshold = const Duration(hours: 24)}) {
    final lastSync = _hiveService.getLastSyncTime('payments');
    if (lastSync == null) return true;

    return DateTime.now().difference(lastSync) > threshold;
  }

  /// Get cache info
  Map<String, dynamic> getCacheInfo() {
    final lastSync = _hiveService.getLastSyncTime('payments');
    final stats = _hiveService.getCacheStats();

    return {
      'cached_payments': stats['payments'] ?? 0,
      'last_sync': lastSync?.toIso8601String(),
      'is_stale': isCacheStale(),
    };
  }
}
