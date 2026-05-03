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
      return [];
    }
  }

  @override
  Future<Picklist?> getPicklist(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.picklists}/$id');
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Picklist.fromJson(data);
    } catch (e) {
      AppLogger.error('getPicklist error', error: e, module: 'inventory');
      return null;
    }
  }

  @override
  Future<Picklist> createPicklist(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.picklists,
        data: data,
      );
      final resData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Picklist.fromJson(resData);
    } catch (e) {
      AppLogger.error('createPicklist error', error: e, module: 'inventory');
      throw Exception('Failed to create picklist: $e');
    }
  }

  @override
  Future<Picklist?> updatePicklist(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.picklists}/$id',
        data: data,
      );
      final resData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Picklist.fromJson(resData);
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
  Future<Map<String, dynamic>> getNextNumber() async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.picklists}/next-number',
      );
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return Map<String, dynamic>.from(data);
    } catch (e) {
      AppLogger.error('getNextNumber error', error: e, module: 'inventory');
      return {'next_number': 1, 'prefix': 'PL-', 'formatted': 'PL-00001'};
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
    String? sortBy,
    bool? sortAscending,
  }) async {
    try {
      final queryParameters = {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (customerId != null && customerId.isNotEmpty)
          'customerId': customerId,
        if (productId != null && productId.isNotEmpty) 'productId': productId,
        if (salesOrderId != null && salesOrderId.isNotEmpty)
          'salesOrderId': salesOrderId,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortAscending != null) 'sortOrder': sortAscending ? 'asc' : 'desc',
      };

      // useCache:false — paginated/filtered data must always be fresh so the
      // total count in response.extra['meta'] is never lost to a stale cache hit.
      final response = await _apiClient.get(
        '${ApiEndpoints.picklists}/warehouse/$warehouseId/items',
        queryParameters: queryParameters,
        useCache: false,
      );

      final responseData = response.data;
      List<dynamic> list;

      if (responseData is List) {
        list = responseData;
      } else if (responseData is Map && responseData.containsKey('data')) {
        final d = responseData['data'];
        list = d is List ? d : [];
      } else {
        list = responseData is Map ? [] : []; // Fallback
      }

      // Try to find the total count in various locations (interceptor meta, top level, nested meta)
      int total = list.length;

      // 1. Check response.extra['meta'] (moved there by ApiClient)
      final extraMeta = response.extra['meta'];
      if (extraMeta is Map) {
        final raw = extraMeta['total'] ?? extraMeta['count'];
        if (raw != null) {
          total = raw is int ? raw : int.tryParse(raw.toString()) ?? total;
        }
      }

      // 2. Check the raw response body if it's a Map (sometimes ApiClient doesn't unwrap)
      final rawBody = response.data;
      if (rawBody is Map) {
        final raw =
            rawBody['total'] ??
            rawBody['count'] ??
            (rawBody['meta'] is Map
                ? (rawBody['meta']['total'] ?? rawBody['meta']['count'])
                : null);
        if (raw != null) {
          total = raw is int ? raw : int.tryParse(raw.toString()) ?? total;
        }
      }

      return {
        'items': list
            .whereType<Map>()
            .map(
              (json) =>
                  WarehouseStockData.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList(),
        'total': total,
      };
    } catch (e) {
      AppLogger.error('getWarehouseItems error', error: e, module: 'inventory');
      return {'items': <WarehouseStockData>[], 'total': 0};
    }
  }

  @override
  Future<List<Map<String, String>>> getWarehouseBins({
    required String warehouseId,
    String? search,
    String? productId,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
        if (productId != null && productId.isNotEmpty) 'productId': productId,
      };

      final response = await _apiClient.get(
        '${ApiEndpoints.picklists}/warehouse/$warehouseId/bins',
        queryParameters: queryParameters,
      );

      final responseData = response.data;
      List<dynamic> list;
      if (responseData is List) {
        list = responseData;
      } else if (responseData is Map) {
        final d = responseData['data'];
        list = d is List ? d : [];
      } else {
        list = [];
      }

      return list
          .whereType<Map>()
          .map(
            (bin) => {
              'id': (bin['id'] ?? '').toString(),
              'binCode': (bin['binCode'] ?? bin['bin_code'] ?? '').toString(),
            },
          )
          .where((b) => b['binCode']!.isNotEmpty)
          .toList();
    } catch (e) {
      AppLogger.error('getWarehouseBins error', error: e, module: 'inventory');
      return [];
    }
  }
}
