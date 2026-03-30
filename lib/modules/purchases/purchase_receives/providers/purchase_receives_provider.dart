import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import '../data/purchase_receive_repository.dart';
import '../data/purchase_receive_repository_impl.dart';
import '../models/purchases_purchase_receives_model.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';

// Repository Provider
final purchaseReceiveRepositoryProvider = Provider<PurchaseReceiveRepository>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return PurchaseReceiveRepositoryImpl(apiClient);
});

// State classes for the AsyncNotifier
class PurchaseReceivesState {
  final List<PurchaseReceive> receives;
  final bool isLoading;
  final String? error;
  final int totalCount;

  PurchaseReceivesState({
    this.receives = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
  });

  PurchaseReceivesState copyWith({
    List<PurchaseReceive>? receives,
    bool? isLoading,
    String? error,
    int? totalCount,
  }) {
    return PurchaseReceivesState(
      receives: receives ?? this.receives,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

// AsyncNotifier Provider for a list of receives
class PurchaseReceivesNotifier
    extends StateNotifier<AsyncValue<PurchaseReceivesState>> {
  final PurchaseReceiveRepository _repository;

  PurchaseReceivesNotifier(this._repository)
    : super(const AsyncValue.loading()) {
    fetchReceives();
  }

  Future<void> fetchReceives({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    state = const AsyncValue.loading();
    try {
      // NOTE: Temporarily returning empty data for UI-only mode as requested (missing DB tables)
      // final receives = await _repository.getPurchaseReceives(
      //   page: page,
      //   limit: limit,
      //   search: search,
      //   status: status,
      // );
      // final total = await _repository.getTotalCount();

      state = AsyncValue.data(
        PurchaseReceivesState(receives: const [], totalCount: 0),
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch purchase receives (UI-only mode)',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      state = AsyncValue.data(
        PurchaseReceivesState(),
      ); // Fallback to empty state
    }
  }

  Future<bool> createReceive(PurchaseReceive receive) async {
    try {
      await _repository.createPurchaseReceive(receive);
      await fetchReceives(); // Refresh list after create
      return true;
    } catch (e, st) {
      AppLogger.error(
        'Failed to create purchase receive',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      return false;
    }
  }

  Future<bool> updateReceive(String id, PurchaseReceive receive) async {
    try {
      final updated = await _repository.updatePurchaseReceive(id, receive);
      if (updated != null) {
        await fetchReceives(); // Refresh list after update
        return true;
      }
      return false;
    } catch (e, st) {
      AppLogger.error(
        'Failed to update purchase receive',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      return false;
    }
  }

  Future<bool> deleteReceive(String id) async {
    try {
      final success = await _repository.deletePurchaseReceive(id);
      if (success) {
        await fetchReceives(); // Refresh list after delete
      }
      return success;
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete purchase receive',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      return false;
    }
  }
}

final purchaseReceivesProvider =
    StateNotifierProvider<
      PurchaseReceivesNotifier,
      AsyncValue<PurchaseReceivesState>
    >((ref) {
      final repository = ref.watch(purchaseReceiveRepositoryProvider);
      return PurchaseReceivesNotifier(repository);
    });
