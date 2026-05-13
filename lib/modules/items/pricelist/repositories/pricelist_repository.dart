import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  final Dio _dio;
  final String _baseUrl;
  final _box = Hive.box('price_lists');

  PriceListRepositoryImpl(this._dio, this._baseUrl);

  @override
  Future<List<PriceList>> getPriceLists() async {
    try {
      final response = await _dio.get('$_baseUrl/price-lists');

      // Handle potential pre-unwrapped data from ApiClient interceptor
      final dynamic rawData = response.data;
      List? itemList;

      if (rawData is List) {
        itemList = rawData;
      } else if (rawData is Map && rawData['data'] != null) {
        itemList = rawData['data'] as List;
      }

      if (itemList != null) {
        final List<PriceList> priceLists = itemList
            .map((json) => PriceList.fromJson(json))
            .toList();

        // Cache to Hive
        await _cachePriceLists(priceLists);
        return priceLists;
      }
      return _getCachedPriceLists();
    } on DioException catch (e) {
      // Return cached data if network fails
      final cached = _getCachedPriceLists();
      if (cached.isNotEmpty) return cached;
      throw Exception('Failed to load price lists: ${e.message}');
    }
  }

  @override
  Future<PriceList> getPriceList(String id) async {
    try {
      final response = await _dio.get('$_baseUrl/price-lists/$id');

      final dynamic rawData = response.data;
      Map<String, dynamic>? dataMap;

      if (rawData is Map<String, dynamic>) {
        dataMap = rawData.containsKey('data') && rawData['data'] is Map
            ? Map<String, dynamic>.from(rawData['data'])
            : rawData;
      }

      if (dataMap != null) {
        final priceList = PriceList.fromJson(dataMap);
        await _box.put(id, priceList.toJson());
        return priceList;
      }
      throw Exception('Price list not found');
    } on DioException catch (e) {
      final cached = _box.get(id);
      if (cached != null) {
        return PriceList.fromJson(Map<String, dynamic>.from(cached));
      }
      throw Exception('Failed to load price list: ${e.message}');
    }
  }

  @override
  Future<PriceList> createPriceList(PriceList priceList) async {
    try {
      final payload = priceList.toJson()
        ..remove('item_rates')
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');
      final response = await _dio.post(
        '$_baseUrl/price-lists',
        data: payload,
      );

      final dynamic rawData = response.data;
      Map<String, dynamic>? dataMap;

      if (rawData is Map<String, dynamic>) {
        dataMap = rawData.containsKey('data') && rawData['data'] is Map
            ? Map<String, dynamic>.from(rawData['data'])
            : rawData;
      }

      if (dataMap != null) {
        final created = PriceList.fromJson(dataMap);
        await _box.put(created.id, created.toJson());
        return created;
      }
      throw Exception('Failed to create price list');
    } on DioException catch (e) {
      throw Exception('Failed to create price list: ${e.message}');
    }
  }

  @override
  Future<PriceList> updatePriceList(PriceList priceList) async {
    try {
      final payload = priceList.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');
      final response = await _dio.put(
        '$_baseUrl/price-lists/${priceList.id}',
        data: payload,
      );

      final dynamic rawData = response.data;
      Map<String, dynamic>? dataMap;

      if (rawData is Map<String, dynamic>) {
        dataMap = rawData.containsKey('data') && rawData['data'] is Map
            ? Map<String, dynamic>.from(rawData['data'])
            : rawData;
      }

      if (dataMap != null) {
        final updated = PriceList.fromJson(dataMap);
        await _box.put(updated.id, updated.toJson());
        return updated;
      }
      throw Exception('Failed to update price list');
    } on DioException catch (e) {
      throw Exception('Failed to update price list: ${e.message}');
    }
  }

  @override
  Future<void> deletePriceList(String id) async {
    try {
      await _dio.delete('$_baseUrl/price-lists/$id');
      await _box.delete(id);
    } on DioException catch (e) {
      throw Exception('Failed to delete price list: ${e.message}');
    }
  }

  @override
  Future<void> deactivatePriceList(String id) async {
    try {
      await _dio.patch('$_baseUrl/price-lists/$id/deactivate');
      final cached = _box.get(id);
      if (cached != null) {
        final priceList = PriceList.fromJson(Map<String, dynamic>.from(cached));
        await _box.put(id, priceList.copyWith(status: 'inactive').toJson());
      }
    } on DioException catch (e) {
      throw Exception('Failed to deactivate price list: ${e.message}');
    }
  }

  // Helper methods for caching
  Future<void> _cachePriceLists(List<PriceList> priceLists) async {
    final Map<String, dynamic> cacheMap = {
      for (var pl in priceLists) pl.id: pl.toJson(),
    };
    await _box.clear();
    await _box.putAll(cacheMap);
  }

  List<PriceList> _getCachedPriceLists() {
    return _box.values
        .map((json) => PriceList.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }
}
