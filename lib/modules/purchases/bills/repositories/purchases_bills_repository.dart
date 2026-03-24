import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/modules/purchases/bills/models/purchases_bills_bill_model.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

abstract class PurchasesBillsRepository {
  Future<List<PurchasesBill>> getBills({
    int page = 1,
    String? search,
    String? status,
  });
  Future<PurchasesBill> createBill(PurchasesBill bill);
  Future<PurchasesBill> updateBill(String id, PurchasesBill bill);
  Future<void> deleteBill(String id);
}

class PurchasesBillsRepositoryImpl implements PurchasesBillsRepository {
  final ApiClient _apiClient;
  PurchasesBillsRepositoryImpl(this._apiClient);

  @override
  Future<List<PurchasesBill>> getBills({
    int page = 1,
    String? search,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;

      final response = await _apiClient.get(
        ApiEndpoints.bills,
        queryParameters: queryParams,
      );
      final data = response.data;
      final List list = data is List
          ? data
          : (data['data'] ?? data['bills'] ?? []);
      return list.map((e) => PurchasesBill.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<PurchasesBill> createBill(PurchasesBill bill) async {
    final response = await _apiClient.post(
      ApiEndpoints.bills,
      data: bill.toJson(),
    );
    return PurchasesBill.fromJson(response.data);
  }

  @override
  Future<PurchasesBill> updateBill(String id, PurchasesBill bill) async {
    final response = await _apiClient.put(
      '${ApiEndpoints.bills}/$id',
      data: bill.toJson(),
    );
    return PurchasesBill.fromJson(response.data);
  }

  @override
  Future<void> deleteBill(String id) async {
    await _apiClient.delete('${ApiEndpoints.bills}/$id');
  }
}

final purchasesBillsRepositoryProvider = Provider<PurchasesBillsRepository>((
  ref,
) {
  return PurchasesBillsRepositoryImpl(ref.read(apiClientProvider));
});
