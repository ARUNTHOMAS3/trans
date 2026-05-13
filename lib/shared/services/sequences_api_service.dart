import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

final sequencesApiServiceProvider = Provider((ref) => SequencesApiService());

class SequencesApiService {
  final ApiClient _apiClient = ApiClient();

  Future<String> getNextNumber(String module) async {
    try {
      final response = await _apiClient.get('/sequences/$module/next');
      if (response.statusCode == 200) {
        return response.data['nextNumber'] as String;
      }
      throw Exception('Failed to get next number');
    } catch (e) {
      throw Exception('Error fetching next number: $e');
    }
  }

  Future<void> incrementSequence(String module, {String? usedNumber}) async {
    try {
      await _apiClient.post(
        '/sequences/$module/increment',
        data: {'usedNumber': usedNumber},
      );
    } catch (e) {
      // Log error but don't block
      print('Error incrementing sequence: $e');
    }
  }
}
