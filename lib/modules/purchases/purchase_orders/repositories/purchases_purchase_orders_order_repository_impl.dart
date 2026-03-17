import 'package:zerpai_erp/core/services/api_client.dart';
import '../models/purchases_purchase_orders_order_model.dart';
import 'purchases_purchase_orders_order_repository.dart';
import '../../../../core/constants/api_endpoints.dart';

class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  final ApiClient _apiClient;

  PurchaseOrderRepositoryImpl(this._apiClient);

  @override
  Future<List<PurchaseOrder>> getPurchaseOrders({
    int page = 1,
    int limit = 100,
    String? search,
  }) async {
    try {
      final queryParameters = {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _apiClient.get(
        ApiEndpoints.purchaseOrders,
        queryParameters: queryParameters,
      );

      final List<dynamic> data = response.data;
      return data.map((json) => PurchaseOrder.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch purchase orders: $e');
    }
  }

  @override
  Future<PurchaseOrder?> getPurchaseOrder(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.purchaseOrders}/$id',
      );
      return PurchaseOrder.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder purchaseOrder) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.purchaseOrders,
        data: purchaseOrder.toJson(),
      );
      return PurchaseOrder.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create purchase order: $e');
    }
  }

  @override
  Future<PurchaseOrder?> updatePurchaseOrder(
    String id,
    PurchaseOrder purchaseOrder,
  ) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.purchaseOrders}/$id',
        data: purchaseOrder.toJson(),
      );
      return PurchaseOrder.fromJson(response.data);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> deletePurchaseOrder(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.purchaseOrders}/$id');
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getTotalCount() async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.purchaseOrders}/statistics/overview',
      );
      return response.data['total'] as int;
    } catch (e) {
      return 0;
    }
  }
}
