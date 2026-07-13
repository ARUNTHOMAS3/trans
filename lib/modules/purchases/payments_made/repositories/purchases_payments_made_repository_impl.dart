// PATH: lib/modules/purchases/payments_made/repositories/purchases_payments_made_repository_impl.dart

import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/purchases_payments_made_model.dart';
import 'purchases_payments_made_repository.dart';
import '../../../../core/constants/api_endpoints.dart';

class PaymentsMadeRepositoryImpl implements PaymentsMadeRepository {
  final ApiClient _apiClient;

  PaymentsMadeRepositoryImpl(this._apiClient);

  @override
  Future<List<PaymentMade>> getPaymentsMade({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
    String? vendorId,
  }) async {
    try {
      final queryParameters = {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null) 'status': status,
        if (vendorId != null && vendorId.isNotEmpty) 'vendorId': vendorId,
      };

      final response = await _apiClient.get(
        ApiEndpoints.paymentsMade,
        queryParameters: queryParameters,
      );

      final List<dynamic> list = (response.data is List)
          ? response.data
          : (response.data['data'] ?? []);
      return list.map((json) => PaymentMade.fromJson(json)).toList();
    } catch (e) {
      AppLogger.error('Failed to fetch payments made', error: e, module: 'purchases');
      throw Exception('Failed to fetch payments made: $e');
    }
  }

  @override
  Future<PaymentMade?> getPaymentMade(String id) async {
    try {
      final response = await _apiClient.get(
        '${ApiEndpoints.paymentsMade}/$id',
      );
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return PaymentMade.fromJson(data);
    } catch (e) {
      AppLogger.error('Failed to get payment made detail', error: e, module: 'purchases');
      return null;
    }
  }

  @override
  Future<PaymentMade> createPaymentMade(PaymentMade paymentMade) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.paymentsMade,
        data: paymentMade.toJson(),
      );
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return PaymentMade.fromJson(data);
    } catch (e) {
      AppLogger.error('Failed to create payment made', error: e, module: 'purchases');
      throw Exception('Failed to create payment made: $e');
    }
  }

  @override
  Future<PaymentMade?> updatePaymentMade(String id, PaymentMade paymentMade) async {
    try {
      final response = await _apiClient.put(
        '${ApiEndpoints.paymentsMade}/$id',
        data: paymentMade.toJson(),
      );
      final data = response.data is Map && response.data.containsKey('data')
          ? response.data['data']
          : response.data;
      return PaymentMade.fromJson(data);
    } catch (e) {
      AppLogger.error('Failed to update payment made', error: e, module: 'purchases');
      throw Exception('Failed to update payment made: $e');
    }
  }

  @override
  Future<bool> deletePaymentMade(String id) async {
    try {
      await _apiClient.delete('${ApiEndpoints.paymentsMade}/$id');
      return true;
    } catch (e) {
      AppLogger.error('Failed to delete payment made', error: e, module: 'purchases');
      return false;
    }
  }

  @override
  Future<int> getTotalCount() async {
    try {
      final response = await _apiClient.get('${ApiEndpoints.paymentsMade}/count');
      return response.data['count'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<Map<String, dynamic>> getPaymentMadeSettings() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.paymentsMadeSettings);
      return response.data is Map ? response.data as Map<String, dynamic> : {};
    } catch (e) {
      return {};
    }
  }

  @override
  Future<void> updatePaymentMadeSettings(Map<String, dynamic> settings) async {
    try {
      await _apiClient.put(ApiEndpoints.paymentsMadeSettings, data: settings);
    } catch (e) {
      AppLogger.error('Failed to update settings', error: e, module: 'purchases');
    }
  }

  @override
  Future<Map<String, dynamic>> getNextPaymentMadeNumber() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.paymentsMadeNextNumber);
      return response.data is Map ? response.data as Map<String, dynamic> : {};
    } catch (e) {
      return {'formatted': 'PM-00001'};
    }
  }
}
