import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/branch_pricelist_model.dart';

abstract class BranchPriceListRepository {
  Future<List<BranchPriceList>> getBranchPriceLists();
  Future<BranchPriceList> getBranchPriceList(String id);
  Future<BranchPriceList> createBranchPriceList(BranchPriceList priceList);
  Future<BranchPriceList> updateBranchPriceList(BranchPriceList priceList);
  Future<void> deleteBranchPriceList(String id);
  Future<void> deactivateBranchPriceList(String id);
}

class BranchPriceListRepositoryImpl implements BranchPriceListRepository {
  BranchPriceListRepositoryImpl({ApiClient? apiClient})
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

  BranchPriceList _mapBranchPriceList(Map<String, dynamic> row) {
    return BranchPriceList.fromJson({
      ...row,
      'transaction_type': _asString(row['transaction_type'], 'sales').toLowerCase(),
      'seasonal_enabled': row['seasonal_enabled'] ?? row['is_seasonal'] ?? false,
      'start_date': row['start_date'] ?? row['valid_from'],
      'end_date': row['end_date'] ?? row['valid_to'],
      'associated_branches': row['associated_branches'] ?? row['branch_entity_ids'] ?? const [],
      'created_at': row['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': row['updated_at'] ?? DateTime.now().toIso8601String(),
    });
  }

  Map<String, dynamic> _toCreatePayload(BranchPriceList priceList) {
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
      'discount_enabled': priceList.isDiscountEnabled,
      'is_seasonal': priceList.isSeasonalEnabled,
      'valid_from': priceList.startDate?.toIso8601String(),
      'valid_to': priceList.endDate?.toIso8601String(),
      'price_scope': 'BRANCH',
      'branch_entity_ids': priceList.associatedBranches ?? const [],
      'item_rates': priceList.itemRates?.map((e) => e.toJson()).toList() ?? const [],
    };
  }

  @override
  Future<List<BranchPriceList>> getBranchPriceLists() async {
    final response = await _apiClient.get('/price-lists', useCache: false);
    final rows = _extractRows(response.data);
    return rows
        .where(
          (row) =>
              _asString(row['price_scope'], 'SELF').toUpperCase() == 'BRANCH',
        )
        .map(_mapBranchPriceList)
        .toList();
  }

  @override
  Future<BranchPriceList> getBranchPriceList(String id) async {
    final response = await _apiClient.get('/price-lists/$id', useCache: false);
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Branch price list not found');
    }
    if (_asString(payload['price_scope'], 'SELF').toUpperCase() != 'BRANCH') {
      throw Exception('Branch price list not found');
    }
    return _mapBranchPriceList(payload);
  }

  @override
  Future<BranchPriceList> createBranchPriceList(BranchPriceList priceList) async {
    final response = await _apiClient.post(
      '/price-lists',
      data: _toCreatePayload(priceList),
    );
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Failed to create branch price list');
    }
    return _mapBranchPriceList(payload);
  }

  @override
  Future<BranchPriceList> updateBranchPriceList(BranchPriceList priceList) async {
    final response = await _apiClient.put(
      '/price-lists/${priceList.id}',
      data: _toCreatePayload(priceList),
    );
    final payload = response.data;
    if (payload is! Map<String, dynamic>) {
      throw Exception('Failed to update branch price list');
    }
    return _mapBranchPriceList(payload);
  }

  @override
  Future<void> deleteBranchPriceList(String id) async {
    await _apiClient.delete('/price-lists/$id');
  }

  @override
  Future<void> deactivateBranchPriceList(String id) async {
    await _apiClient.patch('/price-lists/$id/deactivate');
  }
}







