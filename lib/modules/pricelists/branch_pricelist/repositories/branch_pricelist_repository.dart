import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

import '../models/branch_pricelist_model.dart';

abstract class BranchPriceListRepository {
  Future<List<BranchPriceList>> getBranchPriceLists();
  Future<BranchPriceList> getBranchPriceList(String id);
  Future<BranchPriceList> createBranchPriceList(
    BranchPriceList priceList, {
    List<String> branchEntityIds,
  });
  Future<BranchPriceList> updateBranchPriceList(
    BranchPriceList priceList, {
    List<String> branchEntityIds,
  });
  Future<void> deleteBranchPriceList(String id);
  Future<void> deactivateBranchPriceList(String id);
}

class BranchPriceListRepositoryImpl implements BranchPriceListRepository {
  BranchPriceListRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  Map<String, dynamic>? _tryParseJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is Map<String, dynamic>) return decoded;
          if (decoded is Map) return Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
    }
    return null;
  }

  String _extractApiError(Object error, {required String fallback}) {
    if (error is Exception) {
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      final parsed = _tryParseJsonMap(message);
      if (parsed != null) {
        final innerMessage = parsed['message']?.toString().trim();
        if (innerMessage != null && innerMessage.isNotEmpty)
          return innerMessage;
      }
      if (message.isNotEmpty) return message;
    }

    if (error is DioException) {
      final responseData = _tryParseJsonMap(error.response?.data);
      if (responseData != null) {
        final message = responseData['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
        final meta = responseData['meta'];
        if (meta is Map) {
          final metaMap = Map<String, dynamic>.from(meta);
          final metaError = metaMap['error'];
          if (metaError is Map) {
            final metaErrorMap = Map<String, dynamic>.from(metaError);
            final metaMessage = metaErrorMap['message']?.toString().trim();
            if (metaMessage != null && metaMessage.isNotEmpty) {
              return metaMessage;
            }
          }
        }
      }

      final responseMessage = error.response?.message?.trim();
      if (responseMessage != null && responseMessage.isNotEmpty) {
        return responseMessage;
      }

      final dioMessage = error.message?.trim();
      if (dioMessage != null && dioMessage.isNotEmpty) {
        return dioMessage;
      }
    }

    return fallback;
  }

  BranchPriceList _asPriceList(dynamic data) {
    final map = data is Map && data.containsKey('data') ? data['data'] : data;
    return BranchPriceList.fromJson(_asMap(map));
  }

  Map<String, dynamic> _buildPayload(
    BranchPriceList priceList, {
    List<String> branchEntityIds = const [],
  }) {
    final payload = priceList.toJson();
    payload['price_scope'] = 'BRANCH';
    if (branchEntityIds.isNotEmpty) {
      payload['branch_entity_ids'] = branchEntityIds;
    }
    return payload;
  }

  @override
  Future<List<BranchPriceList>> getBranchPriceLists() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.priceLists,
        queryParameters: {'scope': 'BRANCH'},
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
            return scope == 'BRANCH';
          })
          .map(
            (json) => BranchPriceList.fromJson(Map<String, dynamic>.from(json)),
          )
          .toList();
    } catch (e) {
      AppLogger.error(
        'getBranchPriceLists error',
        error: e,
        module: 'branch_price_lists',
      );
      return [];
    }
  }

  @override
  Future<BranchPriceList> getBranchPriceList(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.priceLists}/$id');
      return _asPriceList(response.data);
    } catch (e) {
      AppLogger.error(
        'getBranchPriceList error',
        error: e,
        module: 'branch_price_lists',
      );
      throw Exception('Branch price list not found');
    }
  }

  @override
  Future<BranchPriceList> createBranchPriceList(
    BranchPriceList priceList, {
    List<String> branchEntityIds = const [],
  }) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.priceLists,
        data: _buildPayload(priceList, branchEntityIds: branchEntityIds),
      );
      return _asPriceList(response.data);
    } catch (e) {
      AppLogger.error(
        'createBranchPriceList error',
        error: e,
        module: 'branch_price_lists',
      );
      throw Exception(
        _extractApiError(e, fallback: 'Unable to save branch price list'),
      );
    }
  }

  @override
  Future<BranchPriceList> updateBranchPriceList(
    BranchPriceList priceList, {
    List<String> branchEntityIds = const [],
  }) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.priceLists}/${priceList.id}',
        data: _buildPayload(priceList, branchEntityIds: branchEntityIds),
      );
      return _asPriceList(response.data);
    } catch (e) {
      AppLogger.error(
        'updateBranchPriceList error',
        error: e,
        module: 'branch_price_lists',
      );
      throw Exception(
        _extractApiError(e, fallback: 'Unable to save branch price list'),
      );
    }
  }

  @override
  Future<void> deleteBranchPriceList(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.priceLists}/$id');
    } catch (e) {
      AppLogger.error(
        'deleteBranchPriceList error',
        error: e,
        module: 'branch_price_lists',
      );
      throw Exception(
        _extractApiError(e, fallback: 'Unable to delete branch price list'),
      );
    }
  }

  @override
  Future<void> deactivateBranchPriceList(String id) async {
    try {
      await _apiClient.patch('${ApiEndpoints.priceLists}/$id/deactivate');
    } catch (e) {
      AppLogger.error(
        'deactivateBranchPriceList error',
        error: e,
        module: 'branch_price_lists',
      );
      throw Exception(
        _extractApiError(e, fallback: 'Unable to deactivate branch price list'),
      );
    }
  }
}
