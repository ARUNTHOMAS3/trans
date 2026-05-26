import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

import '../models/pricelist_model.dart';

abstract class PriceListRepository {
  Future<List<PriceList>> getPriceLists();
  Future<PriceList> getPriceList(String id);
  Future<PriceList> createPriceList(PriceList priceList);
  Future<PriceList> updatePriceList(PriceList priceList);
  Future<void> deletePriceList(String id);
  Future<void> deactivatePriceList(String id);
}

class PriceListRepositoryImpl implements PriceListRepository {
  PriceListRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  PriceList _asPriceList(dynamic data) {
    final map = data is Map && data.containsKey('data') ? data['data'] : data;
    return PriceList.fromJson(_asMap(map));
  }

  @override
  Future<List<PriceList>> getPriceLists() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.priceLists,
        queryParameters: {'scope': 'SELF'},
        useCache: false,
      );
      final rawList = response.data is List
          ? response.data as List
          : (response.data is Map && response.data['data'] is List
                ? response.data['data'] as List
                : <dynamic>[]);
      return rawList
          .whereType<Map>()
          .where((json) {
            final scope = (json['price_scope'] ?? json['priceScope'] ?? '')
                .toString()
                .trim()
                .toUpperCase();
            return scope == 'SELF';
          })
          .map((json) => PriceList.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      AppLogger.error('getPriceLists error', error: e, module: 'price_lists');
      return [];
    }
  }

  @override
  Future<PriceList> getPriceList(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.priceLists}/$id');
      return _asPriceList(response.data);
    } catch (e) {
      AppLogger.error('getPriceList error', error: e, module: 'price_lists');
      throw Exception('Price list not found');
    }
  }

  @override
  Future<PriceList> createPriceList(PriceList priceList) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.priceLists,
        data: priceList.toJson(),
      );
      return _asPriceList(response.data);
    } catch (e) {
      AppLogger.error('createPriceList error', error: e, module: 'price_lists');
      throw Exception('Failed to create price list: $e');
    }
  }

  @override
  Future<PriceList> updatePriceList(PriceList priceList) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.priceLists}/${priceList.id}',
        data: priceList.toJson(),
      );
      return _asPriceList(response.data);
    } catch (e) {
      AppLogger.error('updatePriceList error', error: e, module: 'price_lists');
      throw Exception('Failed to update price list: $e');
    }
  }

  @override
  Future<void> deletePriceList(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.priceLists}/$id');
    } catch (e) {
      AppLogger.error('deletePriceList error', error: e, module: 'price_lists');
      throw Exception('Failed to delete price list: $e');
    }
  }

  @override
  Future<void> deactivatePriceList(String id) async {
    try {
      await _apiClient.patch('${ApiEndpoints.priceLists}/$id/deactivate');
    } catch (e) {
      AppLogger.error(
        'deactivatePriceList error',
        error: e,
        module: 'price_lists',
      );
      throw Exception('Failed to deactivate price list: $e');
    }
  }
}
