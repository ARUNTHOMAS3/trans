import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/models/purchases_purchase_returns_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/repositories/purchases_purchase_returns_repository.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

class PurchaseReturnsRepositoryImpl implements PurchaseReturnsRepository {
  final ApiClient _apiClient;

  PurchaseReturnsRepositoryImpl(this._apiClient);

  @override
  Future<List<PurchaseReturn>> getPurchaseReturns({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all')
        'status': status,
    };

    final response = await _apiClient.get(
      ApiEndpoints.purchaseReturns,
      queryParameters: params,
    );

    final data = response.data;
    final List<dynamic> list = data is List
        ? data
        : (data['data'] as List<dynamic>? ?? const []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(PurchaseReturn.fromJson)
        .toList();
  }

  @override
  Future<PurchaseReturn?> getPurchaseReturn(String id) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.purchaseReturns}/$id',
    );
    final data = response.data;
    if (data == null) return null;
    return PurchaseReturn.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<PurchaseReturn> createPurchaseReturn(
    PurchaseReturn purchaseReturn,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.purchaseReturns,
      data: purchaseReturn.toJson(),
    );
    return PurchaseReturn.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PurchaseReturn?> updatePurchaseReturn(
    String id,
    PurchaseReturn purchaseReturn,
  ) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.purchaseReturns}/$id',
      data: purchaseReturn.toJson(),
    );
    final data = response.data;
    if (data == null) return null;
    return PurchaseReturn.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<bool> deletePurchaseReturn(String id) async {
    await _apiClient.delete('${ApiEndpoints.purchaseReturns}/$id');
    return true;
  }

  @override
  Future<String> getNextReturnNumber() async {
    final response = await _apiClient.get(
      ApiEndpoints.purchaseReturnNextNumber,
    );
    final data = response.data;
    return (data is Map ? data['number'] : data) as String? ?? '';
  }
}
