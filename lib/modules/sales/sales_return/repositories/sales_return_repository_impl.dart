import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

import '../models/sales_return_model.dart';
import 'sales_return_repository.dart';

class SalesReturnRepositoryImpl implements SalesReturnRepository {
  final ApiClient _apiClient;

  SalesReturnRepositoryImpl(this._apiClient);

  @override
  Future<List<SalesReturn>> getSalesReturns({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.salesReturns,
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty && status.toLowerCase() != 'all')
            'status': status,
        },
      );
      final data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data['data'] as List<dynamic>? ?? const []);
      return list
          .whereType<Map<String, dynamic>>()
          .map(SalesReturn.fromJson)
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch sales returns',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      // Rethrow rather than returning an empty list. Swallowing the error made
      // an auth/network failure render as "no returns", which is
      // indistinguishable from an empty table — the report's own error state
      // could never fire.
      rethrow;
    }
  }

  @override
  Future<String> getNextRmaNumber({String prefix = 'RMA-'}) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.salesReturnsNextNumber,
        queryParameters: {'prefix': prefix},
      );
      final data = response.data as Map<String, dynamic>;
      return data['formatted'] as String? ?? '${prefix}00001';
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch next RMA number',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      return '${prefix}00001';
    }
  }

  @override
  Future<SalesReturn> createSalesReturn(CreateSalesReturnPayload payload) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.salesReturns,
        data: payload.toJson(),
      );
      return SalesReturn.fromJson(response.data as Map<String, dynamic>);
    } catch (e, st) {
      AppLogger.error(
        'Failed to create sales return',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      rethrow;
    }
  }

  @override
  Future<SalesReturn> updateSalesReturn(
    String id,
    CreateSalesReturnPayload payload,
  ) async {
    try {
      // PUT replaces the header and the full line set server-side.
      final response = await _apiClient.put(
        '${ApiEndpoints.salesReturns}/$id',
        data: payload.toJson(),
      );
      final data = response.data;
      final json = data is Map<String, dynamic>
          ? (data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : data)
          : <String, dynamic>{};
      return SalesReturn.fromJson(json);
    } catch (e, st) {
      AppLogger.error(
        'Failed to update sales return',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      rethrow;
    }
  }

  @override
  Future<SalesReturn> updateSalesReturnStatus(String id, String status) async {
    try {
      final response = await _apiClient.patch(
        ApiEndpoints.salesReturnStatus(id),
        data: {'status': status},
      );
      final data = response.data;
      final json = data is Map<String, dynamic>
          ? (data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : data)
          : <String, dynamic>{};
      return SalesReturn.fromJson(json);
    } catch (e, st) {
      AppLogger.error(
        'Failed to update sales return status',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, CustomerItemHistory>> getCustomerItemHistory(
    String customerId, {
    String? excludeReturnId,
  }) async {
    if (customerId.isEmpty) return const {};
    try {
      final response = await _apiClient.get(
        ApiEndpoints.salesReturnsCustomerHistory,
        queryParameters: {
          'customerId': customerId,
          if (excludeReturnId != null && excludeReturnId.isNotEmpty)
            'excludeReturnId': excludeReturnId,
        },
      );
      final data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data['data'] as List<dynamic>? ?? const []);
      final entries = list
          .whereType<Map<String, dynamic>>()
          .map(CustomerItemHistory.fromJson)
          .where((e) => e.productId.isNotEmpty);
      return {for (final entry in entries) entry.productId: entry};
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch customer item history',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      // The form stays usable with zeroes rather than blocking item entry.
      return const {};
    }
  }

  @override
  Future<SalesReturnReceive> createReceive(
      String salesReturnId, CreateReceivePayload payload) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.salesReturnReceives(salesReturnId),
        data: payload.toJson(),
      );
      return SalesReturnReceive.fromJson(
          response.data as Map<String, dynamic>);
    } catch (e, st) {
      AppLogger.error(
        'Failed to create sales return receive',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      rethrow;
    }
  }

  @override
  Future<List<SalesReturnReceive>> getReceives(String salesReturnId) async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.salesReturnReceives(salesReturnId),
      );
      final data = response.data;
      final List<dynamic> list =
          data is List ? data : (data['data'] as List<dynamic>? ?? const []);
      return list
          .whereType<Map<String, dynamic>>()
          .map(SalesReturnReceive.fromJson)
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch sales return receives',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      return [];
    }
  }

  @override
  Future<List<SalesReturnHistoryEntry>> getHistory(String salesReturnId) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.salesReturns}/$salesReturnId/history',
      );
      final data = response.data;
      final List<dynamic> list = data is List
          ? data
          : (data['data'] as List<dynamic>? ?? const []);
      return list
          .whereType<Map<String, dynamic>>()
          .map(SalesReturnHistoryEntry.fromJson)
          .where((entry) => entry.id.isNotEmpty && entry.timestamp.isNotEmpty)
          .toList();
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch sales return history',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteReceive(String salesReturnId, String receiveId) async {
    try {
      await _apiClient.delete(
        ApiEndpoints.salesReturnReceive(salesReturnId, receiveId),
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete sales return receive',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteSalesReturn(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.salesReturnById(id));
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete sales return',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      rethrow;
    }
  }

  @override
  Future<List<Warehouse>> getWarehouses() async {
    try {
      final response = await _apiClient.get(
        '/sales-returns/lookups/warehouses',
        useCache: false,
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> rows = [];
        if (data is Map && data.containsKey('data')) {
          rows = data['data'] as List<dynamic>;
        } else if (data is List) {
          rows = data;
        }
        return rows
            .map((row) => Warehouse.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.warning('Failed to load warehouses for sales return', error: e);
      return [];
    }
  }
}
