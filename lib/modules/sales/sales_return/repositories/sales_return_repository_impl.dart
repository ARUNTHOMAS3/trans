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
          if (status != null &&
              status.isNotEmpty &&
              status.toLowerCase() != 'all')
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
      return [];
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
  Future<SalesReturn> createSalesReturn(
    CreateSalesReturnPayload payload,
  ) async {
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
  Future<SalesReturnReceive> createReceive(
    String salesReturnId,
    CreateReceivePayload payload,
  ) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.salesReturnReceives(salesReturnId),
        data: payload.toJson(),
      );
      return SalesReturnReceive.fromJson(response.data as Map<String, dynamic>);
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
      final List<dynamic> list = data is List
          ? data
          : (data['data'] as List<dynamic>? ?? const []);
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
}
