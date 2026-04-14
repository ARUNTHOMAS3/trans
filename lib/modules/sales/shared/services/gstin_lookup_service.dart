import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/gstin_lookup_model.dart';

class GstinLookupService {
  final ApiClient _apiClient = ApiClient();

  Future<GstinLookupResult> fetchGstin(String gstin) async {
    try {
      final response = await _apiClient.get('/sales/gstin/lookup/$gstin');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return GstinLookupResult.fromJson(data);
      }
    } catch (e) {
      // Endpoint likely doesn't exist yet or service is down.
      // Return empty result instead of crashing the UI.
      // In validated environments, we might want to log this.
    }

    return const GstinLookupResult(
      gstin: '',
      legalName: '',
      tradeName: '',
      status: '',
      taxpayerType: '',
      addresses: [],
    );
  }
}

