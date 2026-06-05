import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import '../models/purchases_purchase_returns_model.dart';
import 'purchases_purchase_returns_repository.dart';

class PurchaseReturnsRepositoryImpl implements PurchaseReturnsRepository {
  final ApiClient _apiClient;

  PurchaseReturnsRepositoryImpl(this._apiClient);

  @override
  Future<List<PurchaseReturn>> getPurchaseReturns({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all')
        'status': status,
    };

    final response = await _apiClient.get(
      ApiEndpoints.purchaseReturns,
      queryParameters: params,
    );

    final data = response.data;
    final List<dynamic> list = data is List
        ? data
        : (data['data'] as List<dynamic>? ?? const []);

    return list
        .whereType<Map<String, dynamic>>()
        .map(PurchaseReturn.fromJson)
        .toList();
  }

  @override
  Future<PurchaseReturn?> getPurchaseReturn(String id) async {
    final response =
        await _apiClient.get('${ApiEndpoints.purchaseReturns}/$id');
    final data = response.data;
    if (data == null) return null;
    return PurchaseReturn.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<PurchaseReturn> createPurchaseReturn(
      PurchaseReturn purchaseReturn) async {
    final payload = _toSchemaPayload(purchaseReturn);
    final response = await _apiClient.post(
      ApiEndpoints.purchaseReturns,
      data: payload,
    );
    return PurchaseReturn.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<PurchaseReturn?> updatePurchaseReturn(
    String id,
    PurchaseReturn purchaseReturn,
  ) async {
    final payload = _toSchemaPayload(purchaseReturn);
    final response = await _apiClient.put(
      '${ApiEndpoints.purchaseReturns}/$id',
      data: payload,
    );
    final data = response.data;
    if (data == null) return null;
    return PurchaseReturn.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<bool> deletePurchaseReturn(String id) async {
    await _apiClient.delete('${ApiEndpoints.purchaseReturns}/$id');
    return true;
  }

  @override
  Future<String> getNextReturnNumber() async {
    final response =
        await _apiClient.get(ApiEndpoints.purchaseReturnNextNumber);
    final data = response.data;
    return (data is Map ? data['number'] : data) as String? ?? '';
  }

  Map<String, dynamic> _toSchemaPayload(PurchaseReturn purchaseReturn) {
    final items = purchaseReturn.items
        .map(
          (item) => <String, dynamic>{
            if (item.itemId != null) 'product_id': item.itemId,
            if (item.id != null) 'id': item.id,
            'invoiced_qty': item.orderedQty,
            'already_returned_qty': 0,
            'return_qty': item.returnQty,
            'credited_qty': 0,
            'pending_credit_qty': item.returnQty,
            'rate': item.rate,
            'discount_percent': 0,
            'discount_amount': 0,
            if (item.taxRateId != null) 'tax_id': item.taxRateId,
            'tax_amount': item.taxAmount,
            'line_total': item.amount,
            if (item.reason != null) 'remarks': item.reason,
          },
        )
        .toList();

    return <String, dynamic>{
      if (purchaseReturn.id != null) 'id': purchaseReturn.id,
      if (purchaseReturn.vendorId != null) 'vendor_id': purchaseReturn.vendorId,
      if (purchaseReturn.warehouseId != null)
        'warehouse_id': purchaseReturn.warehouseId,
      if (purchaseReturn.returnNumber.isNotEmpty)
        'purchase_return_number': purchaseReturn.returnNumber,
      if (purchaseReturn.returnDate != null)
        'purchase_return_date': purchaseReturn.returnDate!.toIso8601String(),
      if (purchaseReturn.billId != null) 'bill_id': purchaseReturn.billId,
      if (purchaseReturn.purchaseOrderNumber != null)
        'reference_number': purchaseReturn.purchaseOrderNumber,
      if (purchaseReturn.notes != null) 'notes': purchaseReturn.notes,
      'subtotal': purchaseReturn.subtotal,
      'discount_amount': 0,
      'tax_amount': purchaseReturn.taxAmount,
      'adjustment_amount': 0,
      'total_amount': purchaseReturn.total,
      'credit_status': purchaseReturn.status,
      'status': purchaseReturn.status,
      'items': items,
    };
  }
}
