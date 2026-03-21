// FILE: lib/modules/items/services/lookups_api_service.dart

import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
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
      debugPrint('❌ Lookup bootstrap API Error: $e');
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
      debugPrint('🔍 Units API Response Status: ${response.statusCode}');
      debugPrint('🔍 Units API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List;
        debugPrint('🔍 Units parsed count: ${data.length}');
        final units = data.map((json) => Unit.fromJson(json)).toList();
        debugPrint('🔍 Units models created: ${units.length}');
        return units;
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
      debugPrint('🔄 Syncing units with ${units.length} items');
      final response = await _apiClient.post(
        '/products/lookups/units/sync',
        data: payload,
      );
      debugPrint('✅ Successfully synced units');

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

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _apiClient.get('/products/lookups/categories');
      debugPrint('🔍 Categories API Response Status: ${response.statusCode}');
      debugPrint('🔍 Categories API Response Data: ${response.data}');

      if (response.statusCode == 200) {
        final categories = List<Map<String, dynamic>>.from(response.data);
        debugPrint('🔍 Categories parsed count: ${categories.length}');
        return categories;
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
        debugPrint('🔍 Tax Groups API Data: ${response.data}');
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
        debugPrint('🔍 Parsed Tax Groups count: ${taxGroups.length}');
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
      // Silent in production
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> syncManufacturers(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('manufacturers', items);

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
      debugPrint('📡 Fetching payment terms from API...');
      final response = await _apiClient.get('/products/lookups/payment-terms');
      debugPrint('📡 Payment terms response status: ${response.statusCode}');

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
        debugPrint(
          '⚠️ Unexpected response format for payment terms: ${rawData.runtimeType}',
        );
      }
      return [];
    } catch (e) {
      debugPrint('❌ API Error fetching payment terms: $e');
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
  Future<List<Map<String, dynamic>>> syncStrengths(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('strengths', items);
  Future<List<Map<String, dynamic>>> syncBuyingRules(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('buying-rules', items);
  Future<List<Map<String, dynamic>>> syncDrugSchedules(
    List<Map<String, dynamic>> items,
  ) => _syncLookup('drug-schedules', items);

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

  Future<List<Map<String, dynamic>>> _syncLookup(
    String endpoint,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      debugPrint('🔄 Syncing $endpoint with ${items.length} items');
      debugPrint('📦 Payload: $items');
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

  Future<String?> getNextSequence(String module, {String? outletId}) async {
    try {
      final response = await _apiClient.get(
        '/sequences/$module/next',
        queryParameters: outletId != null ? {'outletId': outletId} : null,
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
    String? outletId,
  }) async {
    try {
      await _apiClient.post(
        '/sequences/$module/increment',
        data: {
          'usedNumber': usedNumber,
          if (outletId != null) 'outletId': outletId,
        },
      );
    } catch (e) {
      debugPrint('❌ Error incrementing sequence for $module: $e');
    }
  }

  Future<Map<String, dynamic>?> getSequenceSettings(
    String module, {
    String? outletId,
  }) async {
    try {
      final response = await _apiClient.get(
        '/sequences/$module/settings',
        queryParameters: outletId != null ? {'outletId': outletId} : null,
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
