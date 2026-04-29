import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/modules/inventory/providers/stock_provider.dart';
import '../models/inventory_picklist_model.dart';
import 'inventory_picklist_repository.dart';

class InventoryPicklistRepositoryImpl implements InventoryPicklistRepository {
  final ApiClient _apiClient;

  InventoryPicklistRepositoryImpl(this._apiClient);

  @override
  Future<List<Picklist>> getPicklists({
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
        ApiEndpoints.picklists,
        queryParameters: queryParameters,
      );

      final List<dynamic> list = (response.data is List)
          ? response.data
          : (response.data['data'] ?? []);
      return list.map((json) => Picklist.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('getPicklists error', error: e, module: 'inventory');
      // For now, return empty list instead of throwing to avoid breaking UI 
      // when table doesn't exist yet.
      return [];
    }
  }

  @override
  Future<Picklist?> getPicklist(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.picklists}/$id');
      return Picklist.fromJson(response.data);
    } catch (e) {
      AppLogger.error('getPicklist error', error: e, module: 'inventory');
      return null;
    }
  }

  @override
  Future<Picklist> createPicklist(Picklist picklist) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.picklists,
        data: picklist.toJson(),
      );
      return Picklist.fromJson(response.data);
    } catch (e) {
      AppLogger.error('createPicklist error', error: e, module: 'inventory');
      throw Exception('Failed to create picklist: $e');
    }
  }

  @override
  Future<Picklist?> updatePicklist(String id, Picklist picklist) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.picklists}/$id',
        data: picklist.toJson(),
      );
      return Picklist.fromJson(response.data);
    } catch (e) {
      AppLogger.error('updatePicklist error', error: e, module: 'inventory');
      return null;
    }
  }

  @override
  Future<bool> deletePicklist(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.picklists}/$id');
      return true;
    } catch (e) {
      AppLogger.error('deletePicklist error', error: e, module: 'inventory');
      return false;
    }
  }

  @override
  Future<int> getTotalCount() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.picklists);
      return response.data['meta']?['total'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<Map<String, dynamic>> getWarehouseItems({
    required String warehouseId,
    int page = 1,
    int limit = 100,
    String? search,
    String? customerId,
    String? productId,
    String? salesOrderId,
  }) async {
    try {
      final queryParameters = {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (customerId != null && customerId.isNotEmpty)
          'customerId': customerId,
        if (productId != null && productId.isNotEmpty)
          'productId': productId,
        if (salesOrderId != null && salesOrderId.isNotEmpty)
          'salesOrderId': salesOrderId,
      };

      final response = await _apiClient.get(
        '${ApiEndpoints.picklists}/warehouse/$warehouseId/items',
        queryParameters: queryParameters,
      );

      final responseData = response.data;
      final responseMeta = response.extra['meta'];
      List<dynamic> list;
      if (responseData is List) {
        list = responseData;
      } else if (responseData is Map) {
        final d = responseData['data'];
        list = d is List ? d : [];
      } else {
        list = [];
      }

      // total may come from unwrapped response.extra.meta, top-level response,
      // or nested response meta depending on interceptor path.
      int total = list.length;
      final metaTotalFromExtra =
          responseMeta is Map ? responseMeta['total'] : null;
      if (responseData is Map) {
        final topTotal = responseData['total'];
        final meta = responseData['meta'];
        final metaTotal = meta is Map ? meta['total'] : null;
        final raw =
            metaTotalFromExtra ?? topTotal ?? metaTotal ?? list.length;
        total = raw is int
            ? raw
            : (raw is num
                  ? raw.toInt()
                  : (int.tryParse('$raw') ?? list.length));
      } else {
        final raw = metaTotalFromExtra ?? list.length;
        total = raw is int
            ? raw
            : (raw is num ? raw.toInt() : (int.tryParse('$raw') ?? list.length));
      }

      return {
        'items': list
            .whereType<Map>()
            .map((json) => WarehouseStockData.fromJson(Map<String, dynamic>.from(json)))
            .toList(),
        'total': total,
      };
    } catch (e) {
      AppLogger.error('getWarehouseItems error', error: e, module: 'inventory');
      return {'items': <WarehouseStockData>[], 'total': 0};
    }
  }
}
