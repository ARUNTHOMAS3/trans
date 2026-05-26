import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_model.dart';
import 'package:zerpai_erp/modules/inventory/repositories/adjustments_repository.dart';

class InventoryAdjustmentsFilters {
  final String search;
  final String status;
  final String adjustmentType;

  const InventoryAdjustmentsFilters({
    this.search = '',
    this.status = 'all',
    this.adjustmentType = 'all',
  });

  InventoryAdjustmentsFilters copyWith({
    String? search,
    String? status,
    String? adjustmentType,
  }) {
    return InventoryAdjustmentsFilters(
      search: search ?? this.search,
      status: status ?? this.status,
      adjustmentType: adjustmentType ?? this.adjustmentType,
    );
  }
}

final adjustmentsRepositoryProvider = Provider<AdjustmentsRepository>((ref) {
  return AdjustmentsRepository();
});

final inventoryAdjustmentsFiltersProvider =
    StateProvider<InventoryAdjustmentsFilters>(
      (ref) => const InventoryAdjustmentsFilters(),
    );

final inventoryAdjustmentsListProvider =
    FutureProvider<List<InventoryAdjustment>>((ref) async {
      final repo = ref.watch(adjustmentsRepositoryProvider);
      final filters = ref.watch(inventoryAdjustmentsFiltersProvider);
      final rows = await repo.getAdjustments(forceRefresh: true);

      return rows.where((row) {
        final matchesSearch = filters.search.trim().isEmpty
            ? true
            : (row.productName ?? '').toLowerCase().contains(
                    filters.search.toLowerCase(),
                  ) ||
                  (row.referenceNumber ?? '').toLowerCase().contains(
                    filters.search.toLowerCase(),
                  ) ||
                  row.reason.toLowerCase().contains(
                    filters.search.toLowerCase(),
                  );

        final matchesStatus = filters.status == 'all'
            ? true
            : row.status.toLowerCase() == filters.status.toLowerCase();

        final matchesType = filters.adjustmentType == 'all'
            ? true
            : row.adjustmentType.toLowerCase() ==
                filters.adjustmentType.toLowerCase();

        return matchesSearch && matchesStatus && matchesType;
      }).toList();
    });

final inventoryAdjustmentDetailProvider =
    FutureProvider.family<InventoryAdjustment?, String>((ref, id) async {
      final repo = ref.watch(adjustmentsRepositoryProvider);
      return repo.getAdjustment(id);
    });

class InventoryAdjustmentsActions {
  final Ref _ref;
  InventoryAdjustmentsActions(this._ref);

  Future<InventoryAdjustment> create(InventoryAdjustment adjustment) async {
    final repo = _ref.read(adjustmentsRepositoryProvider);
    final created = await repo.createAdjustment(adjustment);
    _ref.invalidate(inventoryAdjustmentsListProvider);
    return created;
  }

  Future<InventoryAdjustment> approve(String id) async {
    final repo = _ref.read(adjustmentsRepositoryProvider);
    final approved = await repo.approveAdjustment(id);
    _ref.invalidate(inventoryAdjustmentsListProvider);
    return approved;
  }

  Future<InventoryAdjustment> reject(String id, String reason) async {
    final repo = _ref.read(adjustmentsRepositoryProvider);
    final rejected = await repo.rejectAdjustment(id, reason);
    _ref.invalidate(inventoryAdjustmentsListProvider);
    return rejected;
  }

  Future<void> delete(String id) async {
    final repo = _ref.read(adjustmentsRepositoryProvider);
    await repo.deleteAdjustment(id);
    _ref.invalidate(inventoryAdjustmentsListProvider);
  }
}

final inventoryAdjustmentsActionsProvider =
    Provider<InventoryAdjustmentsActions>((ref) {
      return InventoryAdjustmentsActions(ref);
    });
