// FILE: lib/modules/purchases/purchase_orders/providers/purchases_purchase_orders_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import '../models/purchases_purchase_orders_order_model.dart';
import '../repositories/purchases_purchase_orders_order_repository_impl.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import '../../../auth/controller/auth_controller.dart';

const String _kDevOrgId = '00000000-0000-0000-0000-000000000002';

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
        status: filter.status,
        vendorId: filter.vendorId,
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

final warehousesProvider = FutureProvider<List<WarehouseModel>>((ref) async {
  final user = ref.watch(authUserProvider);
  final orgId =
      (user?.orgId.isNotEmpty == true) ? user!.orgId : _kDevOrgId;
  AppLogger.debug('Loading warehouses', data: {'orgId': orgId}, module: 'purchases');

  final repository = ref.read(purchaseOrderRepositoryProvider);
  try {
    final list = await repository.getWarehouses(orgId: orgId);
    return list;
  } catch (e, st) {
    AppLogger.error('Failed to load warehouses', error: e, stackTrace: st, module: 'purchases');
    return [];
  }
});

final poNextNumberProvider = FutureProvider<String>((ref) async {
  final repository = ref.read(purchaseOrderRepositoryProvider);
  final result = await repository.getNextPurchaseOrderNumber();
  return result['formatted'] as String? ?? 'PO-00001';
});

final poSettingsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.read(purchaseOrderRepositoryProvider);
  return repository.getPurchaseOrderSettings();
});

// Models for provider parameters
class PurchaseOrderFilter {
  final int page;
  final int limit;
  final String? vendorId;
  final String? search;
  final String? status;

  PurchaseOrderFilter({
    this.page = 1,
    this.limit = 100,
    this.vendorId,
    this.search,
    this.status,
  });
}

class PurchaseOrderUpdateRequest {
  final String id;
  final PurchaseOrder purchaseOrder;

  PurchaseOrderUpdateRequest(this.id, this.purchaseOrder);
}
