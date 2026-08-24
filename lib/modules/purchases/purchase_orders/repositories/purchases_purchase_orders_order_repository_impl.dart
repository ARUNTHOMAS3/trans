// FILE: lib/modules/purchases/purchase_orders/repositories/purchases_purchase_orders_order_repository_impl.dart
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/purchases_purchase_orders_order_model.dart';
import 'purchases_purchase_orders_order_repository.dart';
import '../../../../core/constants/api_endpoints.dart';
import 'package:hive/hive.dart';

class PurchaseOrderRepositoryImpl implements PurchaseOrderRepository {
  final ApiClient _apiClient;

  PurchaseOrderRepositoryImpl(this._apiClient);

  @override
  Future<List<PurchaseOrder>> getPurchaseOrders({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
    String? vendorId,
  }) async {
    try {
      final queryParameters = {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
        if (vendorId != null && vendorId.isNotEmpty) 'vendorId': vendorId,
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
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return PurchaseOrder.fromJson(data);
    } catch (e, stackTrace) {
      print('=== ERROR IN getPurchaseOrder ===');
      print(e);
      print(stackTrace);
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
    } catch (e, stackTrace) {
      print('=== ERROR IN updatePurchaseOrder ===');
      print(e);
      print(stackTrace);
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
      AppLogger.error(
        'getNextPurchaseOrderNumber error',
        error: e,
        module: 'purchases',
      );
      return {'formatted': 'PO-00001'};
    }
  }

  @override
  Future<Map<String, dynamic>> getPurchaseOrderSettings() async {
    try {
      final response = await _apiClient.get('sequences/purchase/settings');
      final data = response.data as Map<String, dynamic>;
      return {
        'isAuto': data['is_active'] ?? data['isActive'] ?? true,
        'prefix': data['prefix'] ?? 'PO-',
        'nextNumber': data['next_number'] ?? data['nextNumber'] ?? 1,
        'padding': data['padding'] ?? 5,
      };
    } catch (e) {
      AppLogger.error(
        'getPurchaseOrderSettings error',
        error: e,
        module: 'purchases',
      );
      return {'isAuto': true, 'prefix': 'PO-', 'nextNumber': 1, 'padding': 5};
    }
  }

  @override
  Future<void> updatePurchaseOrderSettings(
    Map<String, dynamic> settings,
  ) async {
    try {
      final payload = {
        'isActive': settings['isAuto'],
        'prefix': settings['prefix'],
        'nextNumber': settings['nextNumber'],
        'padding': settings['padding'],
      };
      await _apiClient.patch('sequences/purchase/settings', data: payload);
    } catch (e) {
      AppLogger.error(
        'updatePurchaseOrderSettings error',
        error: e,
        module: 'purchases',
      );
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
      AppLogger.debug(
        'GET WAREHOUSES called',
        data: {'orgId': orgId},
        module: 'purchases',
      );
      final queryParameters = <String, dynamic>{
        if (orgId != null && orgId.isNotEmpty) 'org_id': orgId,
      };

      final List<WarehouseModel> allWarehouses = [];

      try {
        final legacyResponse = await _apiClient.get(
          ApiEndpoints.warehouses,
          queryParameters: queryParameters,
        );

        if (legacyResponse.statusCode == 200 && legacyResponse.data != null) {
          final List<dynamic> legacyWarehousesJson = legacyResponse.data is List
              ? legacyResponse.data
              : (legacyResponse.data['data'] as List<dynamic>? ?? []);
          final legacyWarehouses = legacyWarehousesJson
              .map((json) => WarehouseModel.fromJson(json))
              .toList();
          for (var wh in legacyWarehouses) {
            if (!allWarehouses.any((element) => element.id == wh.id)) {
              allWarehouses.add(wh);
            }
          }
        }
      } catch (e) {
        AppLogger.error(
          'Failed to fetch from warehouses endpoint',
          error: e,
          module: 'purchases',
        );
      }

      final box = Hive.box('config');
      final activeEntityId = (box.get('selected_entity_id') as String?)?.trim();

      AppLogger.info(
        'PO WAREHOUSE FILTER: activeEntityId=$activeEntityId, warehouses=[${allWarehouses.map((w) => '${w.name}(entityId=${w.entityId})').join(', ')}]',
        module: 'purchases',
      );

      if (activeEntityId != null && activeEntityId.isNotEmpty) {
        final filtered = allWarehouses.where((w) {
          final match = w.entityId == null || w.entityId!.isEmpty || w.entityId == activeEntityId;
          return match;
        }).toList();
        AppLogger.info(
          'PO WAREHOUSE FILTER RESULT: filtered=[${filtered.map((w) => w.name).join(', ')}]',
          module: 'purchases',
        );
        return filtered;
      }

      return allWarehouses;
    } catch (e, st) {
      AppLogger.error(
        'GET WAREHOUSES error',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      return [];
    }
  }
}
