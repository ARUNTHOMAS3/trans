// lib/modules/inventory/repositories/warehouse_repository.dart

import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class WarehouseRepository {
  Future<List<Warehouse>> getWarehouses({
    bool forceRefresh = false,
    String? orgId,
    String? outletId,
  });
}

class WarehouseRepositoryImpl implements WarehouseRepository {
  final ApiClient _apiClient;

  WarehouseRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Warehouse>> getWarehouses({
    bool forceRefresh = false,
    String? orgId,
    String? outletId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (orgId != null && orgId.trim().isNotEmpty) {
      final trimmed = orgId.trim();
      queryParams['orgId'] = trimmed;
      queryParams['org_id'] = trimmed;
    }
    if (outletId != null && outletId.trim().isNotEmpty) {
      final trimmed = outletId.trim();
      queryParams['outletId'] = trimmed;
      queryParams['outlet_id'] = trimmed;
      queryParams['branchId'] = trimmed;
      queryParams['branch_id'] = trimmed;
    }

    Future<List<Warehouse>> fetchFrom(
      String path, {
      Map<String, dynamic>? paramsOverride,
    }) async {
      final response = await _apiClient.get(
        path,
        queryParameters: paramsOverride ?? (queryParams.isNotEmpty ? queryParams : null),
        useCache: !forceRefresh,
      );
      if (response.statusCode != 200) return const <Warehouse>[];
      final rows = _extractRows(response.data);
      return rows
          .map(Warehouse.fromJson)
          .where((w) => w.id.isNotEmpty && w.name.trim().isNotEmpty)
          .toList(growable: false);
    }

    Future<List<Warehouse>> fetchDirectFromSupabase() async {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('warehouses')
          .select('id, name, warehouse_code, is_active')
          .order('name');
      final rows = _extractRows(response);
      return rows
          .map(Warehouse.fromJson)
          .where((w) => w.id.isNotEmpty && w.name.trim().isNotEmpty)
          .toList(growable: false);
    }

    try {
      // Primary source used by inventory create flows.
      final fromLookups = await fetchFrom('/products/lookups/warehouses');
      if (fromLookups.isNotEmpty) {
        return fromLookups;
      }

      // Fallback for environments where lookup endpoint is empty/scoped.
      final fromSettings = await fetchFrom('/warehouses-settings');
      if (fromSettings.isNotEmpty) {
        return fromSettings;
      }

      // Extra fallback for strict endpoints that only accept snake_case org_id.
      if (orgId != null && orgId.trim().isNotEmpty) {
        final fromSettingsOrgOnly = await fetchFrom(
          '/warehouses-settings',
          paramsOverride: <String, dynamic>{'org_id': orgId.trim()},
        );
        if (fromSettingsOrgOnly.isNotEmpty) {
          return fromSettingsOrgOnly;
        }
      }

      final fromSupabase = await fetchDirectFromSupabase();
      if (fromSupabase.isNotEmpty) {
        return fromSupabase;
      }

      return const <Warehouse>[];
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch warehouses from API, checking for fallback',
        error: e,
        module: 'inventory',
      );

      try {
        final fromSupabase = await fetchDirectFromSupabase();
        if (fromSupabase.isNotEmpty) {
          return fromSupabase;
        }
      } catch (supabaseError) {
        AppLogger.warning(
          'Supabase warehouses fallback failed',
          error: supabaseError,
          module: 'inventory',
        );
      }

      return const <Warehouse>[];
    }
  }

  List<Map<String, dynamic>> _extractRows(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList(growable: false);
    }

    if (payload is Map<String, dynamic>) {
      final candidates = <dynamic>[
        payload['data'],
        payload['items'],
        payload['rows'],
      ];
      for (final candidate in candidates) {
        if (candidate is List) {
          return candidate
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList(growable: false);
        }
      }
    }

    return const <Map<String, dynamic>>[];
  }
}
