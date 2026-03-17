import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';

class ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepository(this._apiClient);

  Future<Map<String, dynamic>> getProfitAndLoss(
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await _apiClient.get(
        'reports/profit-and-loss',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Profit and Loss report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGeneralLedger(
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await _apiClient.get(
        'reports/general-ledger',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch General Ledger report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTrialBalance(
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await _apiClient.get(
        'reports/trial-balance',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Trial Balance report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAccountTransactions(
    String accountId,
    String startDate,
    String endDate, {
    String? contactId,
    String? contactType,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/account-transactions',
        queryParameters: {
          'accountId': accountId,
          'startDate': startDate,
          'endDate': endDate,
          if (contactId != null) 'contactId': contactId,
          if (contactType != null) 'contactType': contactType,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Account Transactions report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSalesByCustomer(
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await _apiClient.get(
        'reports/sales-by-customer',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Sales by Customer report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInventoryValuation() async {
    try {
      // Inventory valuation might just be as of "today", not strictly start/end
      final response = await _apiClient.get('reports/inventory-valuation');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Inventory Valuation report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(apiClientProvider));
});
