// FILE: lib/modules/purchases/purchase_orders/repositories/purchases_purchase_orders_order_repository_impl.dart
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
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
        ApiEndpoints.purchaseOrders,
        queryParameters: queryParameters,
      );

      final List<dynamic> list = (response.data is List)
          ? response.data
          : (response.data['data'] ?? []);
      return list.map((json) => PurchaseOrder.fromJson(json)).toList();
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
      final response = await _apiClient.get(ApiEndpoints.purchaseOrders);
      return response.data['meta']?['total'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<Map<String, dynamic>> getNextPurchaseOrderNumber() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.purchaseOrderNextNumber,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('getNextPurchaseOrderNumber error', error: e, module: 'purchases');
      return {'formatted': 'PO-00001'};
    }
  }

  @override
  Future<Map<String, dynamic>> getPurchaseOrderSettings() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.purchaseOrderSettings);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('getPurchaseOrderSettings error', error: e, module: 'purchases');
      return {'isAuto': true, 'prefix': 'PO-', 'nextNumber': 1, 'padding': 5};
    }
  }

  @override
  Future<void> updatePurchaseOrderSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      await _apiClient.post(ApiEndpoints.purchaseOrderSettings, data: settings);
    } catch (e) {
      AppLogger.error('updatePurchaseOrderSettings error', error: e, module: 'purchases');
      throw Exception('Failed to update settings: $e');
    }
  }

  Future<WarehouseModel?> createWarehouse(WarehouseModel warehouse) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.warehouses,
        data: warehouse.toJson(),
      );
      if (response.data != null) {
        return WarehouseModel.fromJson(response.data['data'] ?? response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<List<WarehouseModel>> getWarehouses({String? orgId}) async {
    try {
      AppLogger.debug('GET WAREHOUSES called', data: {'orgId': orgId}, module: 'purchases');
      final queryParameters = {
        if (orgId != null && orgId.isNotEmpty) 'org_id': orgId,
      };
      final response = await _apiClient.get(
        ApiEndpoints.warehouses,
        queryParameters: queryParameters,
      );

      // The response.data should already be the list because ApiClient standardizes it
      final dynamic rawData = response.data;
      final List<dynamic> list;

      if (rawData is List) {
        list = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        list = rawData['data'] as List;
      } else {
        list = [];
      }

      final mapped = list
          .map((e) => WarehouseModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return mapped;
    } catch (e, st) {
      AppLogger.error('GET WAREHOUSES error', error: e, stackTrace: st, module: 'purchases');
      return [];
    }
  }
}
