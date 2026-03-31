// lib/modules/inventory/repositories/warehouse_repository.dart

import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';

abstract class WarehouseRepository {
  Future<List<Warehouse>> getWarehouses({bool forceRefresh = false});
}

class WarehouseRepositoryImpl implements WarehouseRepository {
  final ApiClient _apiClient;

  WarehouseRepositoryImpl({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<Warehouse>> getWarehouses({bool forceRefresh = false}) async {
    try {
      final response = await _apiClient.get(
        '/products/lookups/warehouses',
        useCache: !forceRefresh,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => Warehouse.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      AppLogger.warning(
        'Failed to fetch warehouses from API, checking for fallback',
        error: e,
        module: 'inventory',
      );

      // In debug mode, provide mock data if the backend is down
      if (kDebugMode) {
        return [
          Warehouse(
            id: 'war-001',
            name: 'ZABNINX PRIMARY WAREHOUSE',
            code: 'WH-001',
            address: 'Main St, Digital City',
          ),
          Warehouse(
            id: 'war-002',
            name: 'SECONDARY STORAGE',
            code: 'WH-002',
            address: 'Industrial Area',
          ),
          Warehouse(
            id: 'war-003',
            name: 'LOCAL OUTLET WAREHOUSE',
            code: 'WH-003',
          ),
        ];
      }
      return [];
    }
  }
}
