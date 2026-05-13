import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/shared/constants/currency_constants.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';

class LookupService {
  final ApiClient _api;

  LookupService(this._api);

  Future<List<Map<String, dynamic>>> getCurrencies({String? query}) async {
    try {
      final response = await _api.get(
        '/lookups/currencies',
        queryParameters: query != null ? {'q': query} : null,
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      AppLogger.error('Error fetching currencies', error: e);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getCountries({String? query}) async {
    try {
      final response = await _api.get(
        '/lookups/countries',
        queryParameters: query != null ? {'q': query} : null,
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      AppLogger.error('Error fetching countries', error: e);
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getStates(
    String countryCode, {
    String? query,
  }) async {
    try {
      final response = await _api.get(
        '/lookups/states/$countryCode',
        queryParameters: query != null ? {'q': query} : null,
      );
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      AppLogger.error('Error fetching states', error: e);
    }
    return [];
  }

  Future<Map<String, dynamic>?> saveState(
    String name,
    String countryCode,
  ) async {
    try {
      final response = await _api.post(
        '/lookups/states',
        data: {'name': name, 'country_code': countryCode},
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
    } catch (e) {
      AppLogger.error('Error saving state', error: e);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getStorageLocations() async {
    try {
      final response = await _api.get('/lookups/storage-locations');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
    } catch (e) {
      AppLogger.error('Error fetching storage locations', error: e);
    }
    return [];
  }
}

final lookupServiceProvider = Provider<LookupService>((ref) {
  final api = ref.watch(apiClientProvider);
  return LookupService(api);
});

final currenciesProvider = FutureProvider.family<List<CurrencyOption>, String?>(
  (ref, query) async {
    final service = ref.watch(lookupServiceProvider);
    final data = await service.getCurrencies(query: query);

    return data
        .map(
          (json) => CurrencyOption(
            id: (json['id'] ?? '').toString(),
            code: json['code'],
            name: json['name'],
            symbol: json['symbol'] ?? '',
            decimals: json['decimals'] ?? 2,
            format: json['format'] ?? '1,234,567.89',
            label: '${json['code']} - ${json['name']}',
          ),
        )
        .toList();
  },
);

final countriesProvider =
    FutureProvider.family<List<Map<String, String>>, String?>((
      ref,
      query,
    ) async {
      final service = ref.watch(lookupServiceProvider);
      final data = await service.getCountries(query: query);

      return data
          .map(
            (json) => {
              'id': (json['id'] ?? '') as String,
              'name': json['name'] as String,
              'fullLabel': json['full_label'] as String,
              'phoneCode': json['phone_code'] as String,
              'shortCode': (json['short_code'] ?? '') as String,
            },
          )
          .toList();
    });

final statesProvider = FutureProvider.family<List<Map<String, String>>, String>((
  ref,
  countryCode,
) async {
  if (countryCode.isEmpty || countryCode == 'Select') return [];
  final service = ref.watch(lookupServiceProvider);
  final data = await service.getStates(countryCode);

  return data
      .map(
        (json) => {
          'id': (json['id'] ?? '') as String,
          'name': (json['name'] ?? '') as String,
          'code': (json['code'] ?? '') as String,
        },
      )
      .toList();
});

final storageLocationsProvider =
    FutureProvider<List<Map<String, String>>>((ref) async {
  final service = ref.watch(lookupServiceProvider);
  final data = await service.getStorageLocations();

  return data
      .map(
        (json) => {
          'id': (json['id'] ?? '') as String,
          'name': (json['locationName'] ?? json['name'] ?? '') as String,
          'description': (json['description'] ?? '') as String,
        },
      )
      .toList();
});
