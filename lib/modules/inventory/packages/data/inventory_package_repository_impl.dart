import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import '../models/inventory_package_model.dart';
import 'inventory_package_repository.dart';

class InventoryPackageRepositoryImpl implements InventoryPackageRepository {
  final ApiClient _apiClient;

  InventoryPackageRepositoryImpl(this._apiClient);

  @override
  Future<List<InventoryPackage>> getPackages({
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
        ApiEndpoints.inventoryPackages,
        queryParameters: queryParameters,
      );

      final List<dynamic> list = (response.data is List)
          ? response.data
          : (response.data['data'] ?? []);
      return list.map((json) => InventoryPackage.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('getPackages error', error: e, module: 'inventory');
      return [];
    }
  }

  @override
  Future<InventoryPackage?> getPackage(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.inventoryPackages}/$id');
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return InventoryPackage.fromJson(data);
    } catch (e) {
      AppLogger.error('getPackage error', error: e, module: 'inventory');
      return null;
    }
  }

  @override
  Future<InventoryPackage> createPackage(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.inventoryPackages,
        data: data,
      );
      final resData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return InventoryPackage.fromJson(resData);
    } catch (e) {
      AppLogger.error('createPackage error', error: e, module: 'inventory');
      throw Exception('Failed to create package: $e');
    }
  }

  @override
  Future<InventoryPackage?> updatePackage(String id, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.inventoryPackages}/$id',
        data: data,
      );
      final resData = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return InventoryPackage.fromJson(resData);
    } catch (e) {
      AppLogger.error('updatePackage error', error: e, module: 'inventory');
      return null;
    }
  }

  @override
  Future<bool> deletePackage(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.inventoryPackages}/$id');
      return true;
    } catch (e) {
      AppLogger.error('deletePackage error', error: e, module: 'inventory');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> getNextNumber() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.inventoryPackagesNextNumber);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error('getNextNumber error', error: e, module: 'inventory');
      return {'next_number': 1, 'prefix': 'PKG-', 'formatted': 'PKG-00001'};
    }
  }

  @override
  Future<void> updateNextNumberSettings({
    required String prefix,
    required int nextNumber,
    bool isAuto = true,
  }) async {
    try {
      await _apiClient.patch(
        '${ApiEndpoints.sequences}/inventory_packages/settings',
        data: {
          'prefix': prefix,
          'nextNumber': nextNumber,
        },
      );
    } catch (e) {
      AppLogger.error('updateNextNumberSettings error', error: e, module: 'inventory');
      throw Exception('Failed to update package numbering settings: $e');
    }
  }
}
