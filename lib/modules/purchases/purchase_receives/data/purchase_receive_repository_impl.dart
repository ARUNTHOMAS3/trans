import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import '../models/purchases_purchase_receives_model.dart';
import 'purchase_receive_repository.dart';

class PurchaseReceiveRepositoryImpl implements PurchaseReceiveRepository {
  final ApiClient _apiClient;

  PurchaseReceiveRepositoryImpl(this._apiClient);

  @override
  Future<List<PurchaseReceive>> getPurchaseReceives({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    try {
      final queryParameters = {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
      };

      final response = await _apiClient.get(
        ApiEndpoints.purchaseReceives,
        queryParameters: queryParameters,
      );

      final List<dynamic> list = (response.data is List)
          ? response.data
          : (response.data['data'] ?? []);
      return list.map((json) => PurchaseReceive.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('getPurchaseReceives error', error: e, module: 'purchases');
      throw Exception('Failed to fetch purchase receives: $e');
    }
  }

  @override
  Future<PurchaseReceive?> getPurchaseReceive(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.purchaseReceives}/$id');
      return PurchaseReceive.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getPurchaseReceive error', error: e, module: 'purchases');
      return null;
    }
  }

  @override
  Future<PurchaseReceive> createPurchaseReceive(PurchaseReceive purchaseReceive) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.purchaseReceives,
        data: purchaseReceive.toJson(),
      );
      return PurchaseReceive.fromJson(response.data);
    } catch (e) {
      AppLogger.error('createPurchaseReceive error', error: e, module: 'purchases');
      throw Exception('Failed to create purchase receive: $e');
    }
  }

  @override
  Future<PurchaseReceive?> updatePurchaseReceive(
    String id,
    PurchaseReceive purchaseReceive,
  ) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.purchaseReceives}/$id',
        data: purchaseReceive.toJson(),
      );
      return PurchaseReceive.fromJson(response.data);
    } catch (e) {
      AppLogger.error('updatePurchaseReceive error', error: e, module: 'purchases');
      return null;
    }
  }

  @override
  Future<bool> deletePurchaseReceive(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.purchaseReceives}/$id');
      return true;
    } catch (e) {
      AppLogger.error('deletePurchaseReceive error', error: e, module: 'purchases');
      return false;
    }
  }

  @override
  Future<int> getTotalCount() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.purchaseReceives);
      return response.data['meta']?['total'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }
}
