import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

import '../models/purchases_purchase_receives_model.dart';
import 'purchases_purchase_receives_repository.dart';

class PurchaseReceivesRepositoryImpl implements PurchaseReceivesRepository {
  final ApiClient _apiClient;

  PurchaseReceivesRepositoryImpl(this._apiClient);

  @override
  Future<List<PurchaseReceive>> getPurchaseReceives({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    final queryParameters = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all')
        'status': status,
    };

    final response = await _apiClient.get(
      ApiEndpoints.purchaseReceives,
      queryParameters: queryParameters,
    );

    final data = response.data;
    final List<dynamic> list = data is List
        ? data
        : (data['data'] as List<dynamic>? ?? const []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(PurchaseReceive.fromJson)
        .toList();
  }

  @override
  Future<PurchaseReceive?> getPurchaseReceive(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.purchaseReceives}/$id',
      );
      return PurchaseReceive.fromJson(response.data as Map<String, dynamic>);
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch purchase receive',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      return null;
    }
  }

  @override
  Future<PurchaseReceive> createPurchaseReceive(PurchaseReceive receive) async {
    final response = await _apiClient.post(
      ApiEndpoints.purchaseReceives,
      data: receive.toJson(),
    );
    return PurchaseReceive.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PurchaseReceive?> updatePurchaseReceive(
    String id,
    PurchaseReceive receive,
  ) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.purchaseReceives}/$id',
        data: receive.toJson(),
      );
      return PurchaseReceive.fromJson(response.data as Map<String, dynamic>);
    } catch (e, st) {
      AppLogger.error(
        'Failed to update purchase receive',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      return null;
    }
  }

  @override
  Future<bool> deletePurchaseReceive(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.purchaseReceives}/$id');
      return true;
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete purchase receive',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      return false;
    }
  }

  @override
  Future<int> getTotalCount() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.purchaseReceives);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return (data['meta']?['total'] as int?) ?? 0;
      }
      if (data is List) {
        return data.length;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}
