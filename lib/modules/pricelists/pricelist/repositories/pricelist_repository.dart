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

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    if (payload is List) {
      return payload.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (payload is Map<String, dynamic> && payload['data'] is List) {
      final data = payload['data'] as List;
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return const <Map<String, dynamic>>[];
  }

  String _asString(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  PriceList _mapPriceList(Map<String, dynamic> row) {
    return PriceList.fromJson({
      ...row,
      'transaction_type': _asString(row['transaction_type'], 'sales').toLowerCase(),
      'created_at': row['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': row['updated_at'] ?? DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic> _toCreatePayload(PriceList priceList) {
    return {
      'name': priceList.name,
      'description': priceList.description,
      'currency': priceList.currency,
      'pricing_scheme': priceList.pricingScheme,
      'price_list_type': priceList.priceListType,
      'details': priceList.details,
      'round_off_preference': priceList.roundOffPreference,
      'status': priceList.status,
      'transaction_type': priceList.transactionType.toLowerCase(),
      'price_scope': 'SELF',
      'discount_enabled': priceList.isDiscountEnabled,
      'item_rates': priceList.itemRates?.map((e) => e.toJson()).toList() ?? const [],
    };
  }

  @override
  Future<List<PriceList>> getPriceLists() async {
    final response = await _apiClient.get('/price-lists', useCache: false);
    final rows = _extractRows(response.data);
    return rows
        .where(
          (row) =>
              _asString(row['price_scope'], 'SELF').toUpperCase() == 'SELF',
        )
        .map(_mapPriceList)
        .toList();
  }

  @override
  Future<PriceList> getPriceList(String id) async {
    final response = await _apiClient.get('/price-lists/$id', useCache: false);
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Price list not found');
    }
    if (_asString(payload['price_scope'], 'SELF').toUpperCase() != 'SELF') {
      throw Exception('Price list not found');
    }
    return _mapPriceList(payload);
  }

  @override
  Future<PriceList> createPriceList(PriceList priceList) async {
    final response = await _apiClient.post(
      '/price-lists',
      data: _toCreatePayload(priceList),
    );
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Failed to create price list');
    }
    return _mapPriceList(payload);
  }

  @override
  Future<PriceList> updatePriceList(PriceList priceList) async {
    final response = await _apiClient.put(
      '/price-lists/${priceList.id}',
      data: _toCreatePayload(priceList),
    );
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Failed to update price list');
    }
    return _mapPriceList(payload);
  }

  @override
  Future<void> deletePriceList(String id) async {
    await _apiClient.delete('/price-lists/$id');
  }

  @override
  Future<void> deactivatePriceList(String id) async {
    await _apiClient.patch('/price-lists/$id/deactivate');
  }
}
