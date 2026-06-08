// FILE: lib/modules/items/services/lookups_api_service.dart

import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/modules/items/items/models/unit_model.dart';
import 'package:zerpai_erp/modules/items/items/models/tax_rate_model.dart';
import 'package:zerpai_erp/modules/items/items/models/uqc_model.dart';

class LookupsApiService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getLookupBootstrap() async {
    try {
      final response = await _apiClient.get(
        '/products/lookups/bootstrap',
        useCache: false,
      );
      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(response.data as Map<String, dynamic>);
      }
      return <String, dynamic>{};
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  Future<List<Uqc>> getUqc() async {
    try {
      final response = await _apiClient.get('/products/lookups/uqc');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => Uqc.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ UQC API Error: $e');
      return [];
    }
  }

  // Clear cache for lookups (call after sync operations)
  void clearLookupsCache() {
    _apiClient.clearCache('/products/lookups');
  }

  Future<List<Unit>> getUnits() async {
    try {
      final response = await _apiClient.get('/products/lookups/units');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => Unit.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('❌ Units API Error: $e');
      return [];
    }
  }

  Future<List<Unit>> syncUnits(List<Unit> units) async {
    try {
      final payload = units.map((u) => u.toJson()).toList();
      final response = await _apiClient.post(
        '/products/lookups/units/sync',
        data: payload,
      );

      // Clear cache after successful sync
      _apiClient.clearCache('/products/lookups/units');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => Unit.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> checkUnitUsage(List<String> unitIds) async {
    try {
      final response = await _apiClient.post(
        '/products/lookups/units/check-usage',
        data: {'unitIds': unitIds},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final unitsInUse = List<String>.from(data['unitsInUse'] ?? []);
        return unitsInUse;
      }
      return [];
    } catch (e) {
      debugPrint('❌ checkUnitUsage API Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> checkLookupUsage(
    String lookupKey,
    String id,
  ) async {
    try {
      final response = await _apiClient.post(
        '/products/lookups/$lookupKey/check-usage',
        data: {'id': id},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {'inUse': false};
    } catch (e) {
      debugPrint('ƒ?O checkLookupUsage API Error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories({
    bool useCache = true,
  }) async {
    try {
      final response = await _apiClient.get(
        '/products/lookups/categories',
        useCache: useCache,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      return [];
    } catch (e) {
      debugPrint('❌ Categories API Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncCategories(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('categories', items);

  Future<Map<String, dynamic>> createCategory(String name) async {
    final response = await _apiClient.post(
      '/products/lookups/categories',
      data: {'name': name},
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create category');
  }

  Future<List<TaxRate>> getTaxRates() async {
    try {
      final response = await _apiClient.get('/products/lookups/tax-rates');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        return data.map((json) => TaxRate.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      // Silent in production
      return [];
    }
  }

  Future<List<TaxRate>> getTaxGroups() async {
    try {
      final response = await _apiClient.get('/products/lookups/tax-groups');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        final taxGroups = data
            .map(
              (json) => TaxRate.fromJson({
                ...json,
                'tax_name':
                    json['tax_group_name'], // Map tax_group_name to tax_name
              }),
            )
            .toList();
        return taxGroups;
      }


      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCountries() async {
    try {
      final response = await _apiClient.get('/lookups/countries');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error loading countries: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStates(String countryCode) async {
    try {
      final response = await _apiClient.get('/lookups/states/$countryCode');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error loading states for $countryCode: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getManufacturers() async {
    try {
      final response = await _apiClient.get('/products/lookups/manufacturers');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error loading manufacturers: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getGstTreatments() async {
    try {
      final response = await _apiClient.get('/lookups/gst-treatments');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error loading GST treatments: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncManufacturers(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('manufacturers', items);

  Future<Map<String, dynamic>> createManufacturer(String name) async {
    final response = await _apiClient.post(
      '/products/lookups/manufacturers',
      data: {'name': name},
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create manufacturer');
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      final response = await _apiClient.get('/products/lookups/brands');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      return [];
    } catch (e) {
      // Silent in production
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncBrands(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('brands', items);

  Future<Map<String, dynamic>> createBrand(String name) async {
    final response = await _apiClient.post(
      '/products/lookups/brands',
      data: {'name': name},
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create brand');
  }

  Future<List<Map<String, dynamic>>> searchLookups(
    String type,
    String query,
  ) async {
    try {
      final response = await _apiClient.get(
        '/products/lookups/$type/search',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Lookup Search Error [$type]: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchManufacturers(String query) =>
      searchLookups('manufacturers', query);

  Future<List<Map<String, dynamic>>> searchBrands(String query) =>
      searchLookups('brands', query);

  Future<List<Map<String, dynamic>>> getVendors() async {
    try {
      final response = await _apiClient.get('/products/lookups/vendors');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      return [];
    } catch (e) {
      // Silent in production
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncVendors(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('vendors', items);

  Future<List<Map<String, dynamic>>> getReps() async {
    try {
      final response = await _apiClient.get('/products/lookups/reps');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchReps(String query) =>
      searchLookups('reps', query);

  Future<Map<String, dynamic>> createRep(Map<String, dynamic> payload) async {
    final response = await _apiClient.post(
      '/products/lookups/reps',
      data: payload,
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create rep');
  }

  Future<List<Map<String, dynamic>>> getStorageLocations() async {
    try {
      final response = await _apiClient.get(
        '/products/lookups/storage-locations',
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      return [];
    } catch (e) {
      // Silent in production
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncStorageLocations(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('storage-locations', items);

  Future<Map<String, dynamic>> createStorageLocation(String name) async {
    final response = await _apiClient.post(
      '/products/lookups/storage-locations',
      data: {'name': name},
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create storage location');
  }

  Future<List<Map<String, dynamic>>> getRacks() async {
    try {
      final response = await _apiClient.get('/products/lookups/racks');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      return [];
    } catch (e) {
      // Silent in production
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncRacks(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('racks', items);

  Future<Map<String, dynamic>> createRack(String name) async {
    final response = await _apiClient.post(
      '/products/lookups/racks',
      data: {'name': name},
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create rack');
  }

  Future<List<Map<String, dynamic>>> getReorderTerms() async {
    try {
      final response = await _apiClient.get('/products/lookups/reorder-terms');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      return [];
    } catch (e) {
      // Silent in production
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncReorderTerms(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('reorder-terms', items);

  // Payment Terms
  Future<List<Map<String, dynamic>>> getPaymentTerms() async {
    try {
      final response = await _apiClient.get('/products/lookups/payment-terms');

      if (response.statusCode == 200) {
        final dynamic rawData = response.data;
        if (rawData is List) {
          return List<Map<String, dynamic>>.from(rawData);
        } else if (rawData is Map && rawData.containsKey('data')) {
          // Fallback for cases where it might not be auto-unwrapped
          final dynamic nestedData = rawData['data'];
          if (nestedData is List) {
            return List<Map<String, dynamic>>.from(nestedData);
          }
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncPaymentTerms(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('payment-terms', items);

  Future<List<Map<String, dynamic>>> getSalespersons() async {
    try {
      final response = await _apiClient.get('/products/lookups/salespersons');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Salespersons API Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncSalespersons(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('salespersons', items);

  Future<List<Map<String, dynamic>>> syncContents(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('contents', items);
  Future<Map<String, dynamic>> createContent(String name) async {
    final response = await _apiClient.post(
      '/products/lookups/contents',
      data: {'name': name},
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create content');
  }
  Future<List<Map<String, dynamic>>> syncStrengths(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('strengths', items);
  Future<List<Map<String, dynamic>>> syncBuyingRules(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('buying-rules', items);
  Future<Map<String, dynamic>> createBuyingRule(String name) async {
    final response = await _apiClient.post(
      '/products/lookups/buying-rules',
      data: {'name': name},
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create buying rule');
  }
  Future<List<Map<String, dynamic>>> syncDrugSchedules(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('drug-schedules', items);
  Future<List<Map<String, dynamic>>> syncProductTypes(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('product-types', items);
  Future<Map<String, dynamic>> createProductPackSize({
    required String packName,
    required String unitPack,
  }) async {
    final response = await _apiClient.post(
      '/products/lookups/product-pack-sizes',
      data: {'pack_name': packName, 'unit_pack': unitPack},
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create product pack size');
  }
  Future<Map<String, dynamic>> createDrugSchedule(String name) async {
    final response = await _apiClient.post(
      '/products/lookups/drug-schedules',
      data: {'name': name},
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create drug schedule');
  }

  Future<Map<String, dynamic>> createProductType(String name) async {
    final response = await _apiClient.post(
      '/products/lookups/product-types',
      data: {'name': name},
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create product type');
  }

  Future<List<Map<String, dynamic>>> getAccounts() async {
    try {
      final response = await _apiClient.get('/products/lookups/accountant');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }

      return [];
    } catch (e) {
      // Silent in production
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncAccounts(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('accountant', items);

  Future<List<Map<String, dynamic>>> getContents() async {
    try {
      final response = await _apiClient.get('/products/lookups/contents');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getStrengths() async {
    try {
      final response = await _apiClient.get('/products/lookups/strengths');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createStrength(String name) async {
    final response = await _apiClient.post(
      '/products/lookups/strengths',
      data: {'name': name},
    );
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data is Map) {
      return Map<String, dynamic>.from(response.data as Map);
    }
    throw Exception('Failed to create strength');
  }

  Future<List<Map<String, dynamic>>> getBuyingRules() async {
    try {
      final response = await _apiClient.get('/products/lookups/buying-rules');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDrugSchedules() async {
    try {
      final response = await _apiClient.get('/products/lookups/drug-schedules');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductPackSizes() async {
    try {
      final response = await _apiClient.get('/products/lookups/product-pack-sizes');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductTypes() async {
    try {
      final response = await _apiClient.get('/products/lookups/product-types');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _syncLookup(
    String endpoint,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final cleanedItems = items.map((item) {
        final cleaned = Map<String, dynamic>.from(item);
        if (cleaned['id']?.toString().startsWith('new_') ?? false) {
          cleaned.remove('id');
        }
        return cleaned;
      }).toList();

      final response = await _apiClient.post(
        '/products/lookups/$endpoint/sync',
        data: cleanedItems,
      );
      debugPrint('✅ Successfully synced $endpoint');

      // Clear cache after successful sync
      _apiClient.clearCache('/products/lookups/$endpoint');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTdsRates() async {
    try {
      final response = await _apiClient.get('/products/lookups/tds-rates');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncTdsRates(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('tds-rates', items);

  Future<List<Map<String, dynamic>>> getTdsSections() async {
    try {
      final response = await _apiClient.get('/products/lookups/tds-sections');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getTcsRates() async {
    try {
      final response = await _apiClient.get('/products/lookups/tcs-rates');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncTcsRates(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('tcs-rates', items);

  Future<List<Map<String, dynamic>>> getTcsNatures() async {
    try {
      final response = await _apiClient.get('/products/lookups/tcs-natures');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPriceLists() async {
    try {
      final response = await _apiClient.get('/products/lookups/price-lists');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      debugPrint('❌ Price Lists API Error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getShipmentPreferences() async {
    try {
      final response = await _apiClient.get('shipment-preferences');
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      if (data is Map && data['data'] is List) return (data['data'] as List).cast<Map<String, dynamic>>();
      return [];
    } catch (e) {
      final message = e.toString();
      final endpointMissing =
          message.contains('Cannot GET /api/v1/shipment-preferences') ||
          message.contains('404') ||
          message.contains('Not Found');
      if (endpointMissing) {
        debugPrint(
          'ℹ Shipment preferences endpoint unavailable; continuing with empty list.',
        );
        return [];
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncShipmentPreferences(List<Map<String, dynamic>> items) async {
    try {
      final response = await _apiClient.post('shipment-preferences/sync', data: {'items': items});
      final data = response.data;
      if (data is List) return data.cast<Map<String, dynamic>>();
      return items;
    } catch (e) {
      final message = e.toString();
      final endpointMissing =
          message.contains('Cannot POST /api/v1/shipment-preferences/sync') ||
          message.contains('404') ||
          message.contains('Not Found');
      if (endpointMissing) {
        debugPrint(
          'ℹ Shipment preferences sync endpoint unavailable; using local values.',
        );
        return items;
      }
      return items;
    }
  }

  Future<bool> checkDuplicateNumber(String module, String number) async {
    try {
      final response = await _apiClient.get(
        '/sequences/$module/check-duplicate',
        queryParameters: {'number': number},
      );
      if (response.statusCode == 200) {
        return response.data['exists'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error checking duplicate number: $e');
      return false;
    }
  }

  Future<String?> getNextSequence(String module, {String? branchId}) async {
    try {
      final response = await _apiClient.get(
        '/sequences/$module/next',
        queryParameters: branchId != null ? {'branchId': branchId} : null,
        useCache: false,
      );
      if (response.statusCode == 200) {
        return response.data['nextNumber'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching next sequence for $module: $e');
      return null;
    }
  }

  Future<void> incrementSequence(
    String module, {
    String? usedNumber,
    String? branchId,
  }) async {
    try {
      await _apiClient.post(
        '/sequences/$module/increment',
        data: {
          'usedNumber': usedNumber,
          if (branchId != null) 'branchId': branchId,
        },
      );
    } catch (e) {
      debugPrint('❌ Error incrementing sequence for $module: $e');
    }
  }

  Future<Map<String, dynamic>?> getSequenceSettings(
    String module, {
    String? branchId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/sequences/$module/settings',
        queryParameters: branchId != null ? {'branchId': branchId} : null,
        useCache: false,
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching sequence settings: $e');
      return null;
    }
  }

  Future<void> updateSequenceSettings(
    String module,
    Map<String, dynamic> settings,
  ) async {
    try {
      await _apiClient.patch('/sequences/$module/settings', data: settings);
    } catch (e) {
      debugPrint('❌ Error updating sequence settings: $e');
      rethrow;
    }
  }
}
