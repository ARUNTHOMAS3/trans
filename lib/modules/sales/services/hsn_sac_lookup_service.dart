import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/hsn_sac_model.dart';

class HsnSacLookupService {
  final ApiClient _apiClient;

  HsnSacLookupService(this._apiClient);

  Future<List<HsnSacCode>> searchHsn(String query) async {
    return searchHsnSac(query, 'HSN');
  }

  Future<List<HsnSacCode>> searchSac(String query) async {
    return searchHsnSac(query, 'SAC');
  }

  Future<List<HsnSacCode>> searchHsnSac(String query, String type) async {
    final response = await _apiClient.get(
      '/sales/search',
      queryParameters: {'query': query, 'type': type},
    );

    final data = response.data;
    if (data is List) {
      return data.map((item) => HsnSacCode.fromJson(item)).toList();
    }
    return [];
  }
}
