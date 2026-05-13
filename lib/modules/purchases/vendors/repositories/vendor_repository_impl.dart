import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/repositories/vendor_repository.dart';

class VendorRepositoryImpl implements VendorRepository {
  final ApiClient _apiClient;

  VendorRepositoryImpl(this._apiClient);

  @override
  Future<List<Vendor>> getAllVendors({int page = 1, int limit = 100, String? search}) async {
    try {
      final queryParameters = {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _apiClient.get(
        ApiEndpoints.vendors,
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Handle paginated response format
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          final List<dynamic> items = data['data'] as List;
          return items
              .map((json) => Vendor.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        
        // Handle direct array format
        if (data is List) {
          return data
              .map((json) => Vendor.fromJson(json as Map<String, dynamic>))
              .toList();
        }
      }

      throw Exception('Failed to fetch vendors');
    } catch (e) {
      throw Exception('Failed to fetch vendors: $e');
    }
  }

  @override
  Future<Vendor?> getVendorById(String id) async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.vendors}/$id');
      
      if (response.statusCode == 200) {
        return Vendor.fromJson(response.data);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to fetch vendor: $e');
    }
  }

  @override
  Future<Vendor> createVendor(Vendor vendor) async {
    try {
      final data = vendor.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');

      final response = await _apiClient.post(
        ApiEndpoints.vendors,
        data: data,
      );
      
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Vendor.fromJson(response.data);
      }
      
      throw Exception('Failed to create vendor');
    } catch (e) {
      throw Exception('Failed to create vendor: $e');
    }
  }

  @override
  Future<Vendor> updateVendor(String id, Vendor vendor) async {
    try {
      final data = vendor.toJson();
      data.remove('id');
      data.remove('created_at');
      data.removeWhere((key, value) => value == null);

      final response = await _apiClient.put(
        '${ApiEndpoints.vendors}/$id',
        data: data,
      );
      
      if (response.statusCode == 200) {
        return Vendor.fromJson(response.data);
      }
      
      throw Exception('Failed to update vendor');
    } catch (e) {
      throw Exception('Failed to update vendor: $e');
    }
  }

  @override
  Future<void> deleteVendor(String id) async {
    try {
      final response = await _apiClient.delete('${ApiEndpoints.vendors}/$id');
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete vendor');
      }
    } catch (e) {
      throw Exception('Failed to delete vendor: $e');
    }
  }
}

final vendorRepositoryProvider = Provider<VendorRepository>((ref) {
  return VendorRepositoryImpl(ref.read(apiClientProvider));
});