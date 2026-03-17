// FILE: lib/modules/purchases/purchase_orders/providers/purchases_purchase_orders_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/purchases_purchase_orders_order_model.dart';
import '../repositories/purchases_purchase_orders_order_repository_impl.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

final purchaseOrderRepositoryProvider = Provider<PurchaseOrderRepositoryImpl>(
  (ref) => PurchaseOrderRepositoryImpl(ref.read(apiClientProvider)),
);

final purchaseOrdersProvider =
    FutureProvider.family<List<PurchaseOrder>, PurchaseOrderFilter>((
      ref,
      filter,
    ) async {
      final repository = ref.read(purchaseOrderRepositoryProvider);
      return repository.getPurchaseOrders(
        page: filter.page,
        limit: filter.limit,
        search: filter.search,
      );
    });

final purchaseOrderProvider = FutureProvider.family<PurchaseOrder?, String>((
  ref,
  id,
) async {
  final repository = ref.read(purchaseOrderRepositoryProvider);
  return repository.getPurchaseOrder(id);
});

final createPurchaseOrderProvider =
    FutureProvider.family<PurchaseOrder, PurchaseOrder>((
      ref,
      purchaseOrder,
    ) async {
      final repository = ref.read(purchaseOrderRepositoryProvider);
      return repository.createPurchaseOrder(purchaseOrder);
    });

final updatePurchaseOrderProvider =
    FutureProvider.family<PurchaseOrder?, PurchaseOrderUpdateRequest>((
      ref,
      request,
    ) async {
      final repository = ref.read(purchaseOrderRepositoryProvider);
      return repository.updatePurchaseOrder(request.id, request.purchaseOrder);
    });

final deletePurchaseOrderProvider = FutureProvider.family<bool, String>((
  ref,
  id,
) async {
  final repository = ref.read(purchaseOrderRepositoryProvider);
  return repository.deletePurchaseOrder(id);
});

// Models for provider parameters
class PurchaseOrderFilter {
  final int page;
  final int limit;
  final String? search;

  PurchaseOrderFilter({this.page = 1, this.limit = 100, this.search});
}

class PurchaseOrderUpdateRequest {
  final String id;
  final PurchaseOrder purchaseOrder;

  PurchaseOrderUpdateRequest(this.id, this.purchaseOrder);
}
