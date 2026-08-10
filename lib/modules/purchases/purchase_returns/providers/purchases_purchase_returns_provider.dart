import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/models/purchases_purchase_returns_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/repositories/purchases_purchase_returns_repository.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/repositories/purchases_purchase_returns_repository_impl.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';

// ── Repository provider ──────────────────────────────────────────────────────

final purchaseReturnsRepositoryProvider =
    Provider<PurchaseReturnsRepository>((ref) {
  return PurchaseReturnsRepositoryImpl();
});

// ── State ────────────────────────────────────────────────────────────────────

class PurchaseReturnsState {
  final List<PurchaseReturn> returns;
  final bool isLoading;
  final String? error;
  final int totalCount;
  final String? search;
  final String? status;

  const PurchaseReturnsState({
    this.returns = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
    this.search,
    this.status,
  });

  PurchaseReturnsState copyWith({
    List<PurchaseReturn>? returns,
    bool? isLoading,
    String? error,
    int? totalCount,
    String? search,
    String? status,
  }) {
    return PurchaseReturnsState(
      returns: returns ?? this.returns,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalCount: totalCount ?? this.totalCount,
      search: search ?? this.search,
      status: status ?? this.status,
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class PurchaseReturnsNotifier
    extends StateNotifier<AsyncValue<PurchaseReturnsState>> {
  final PurchaseReturnsRepository _repository;
  final List<PurchaseReturn> _localReturns = [];

  PurchaseReturnsNotifier(this._repository)
      : super(const AsyncValue.loading()) {
    fetchReturns();
  }

  Future<void> fetchReturns({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    final prev = state.valueOrNull ?? const PurchaseReturnsState();
    state = AsyncValue.data(
      prev.copyWith(isLoading: true, error: null, search: search, status: status),
    );

    try {
      final remote = await _repository.getPurchaseReturns(
        page: page,
        limit: limit,
        search: search,
        status: status,
      );
      final merged = _merge(remote, _localReturns);
      state = AsyncValue.data(PurchaseReturnsState(
        returns: merged,
        isLoading: false,
        totalCount: merged.length,
        search: search,
        status: status,
      ));
    } catch (e, st) {
      AppLogger.error('Failed to fetch purchase returns: $e', module: 'purchases', error: e, stackTrace: st);
      final filtered = _applyFilters(_localReturns, search, status);
      state = AsyncValue.data(PurchaseReturnsState(
        returns: filtered,
        isLoading: false,
        error: e.toString(),
        totalCount: filtered.length,
        search: search,
        status: status,
      ));
    }
  }

  Future<PurchaseReturn?> createReturn(PurchaseReturn purchaseReturn) async {
    try {
      final created = await _repository.createPurchaseReturn(purchaseReturn);
      _upsertLocal(created);
      await fetchReturns(
        search: state.valueOrNull?.search,
        status: state.valueOrNull?.status,
      );
      return created;
    } catch (e, st) {
      AppLogger.error('Failed to create purchase return: $e', module: 'purchases', error: e, stackTrace: st);
      return null;
    }
  }

  Future<PurchaseReturn?> updateReturn(
    String id,
    PurchaseReturn purchaseReturn,
  ) async {
    try {
      final updated =
          await _repository.updatePurchaseReturn(id, purchaseReturn);
      if (updated != null) {
        _upsertLocal(updated);
        await fetchReturns(
          search: state.valueOrNull?.search,
          status: state.valueOrNull?.status,
        );
      }
      return updated;
    } catch (e, st) {
      AppLogger.error('Failed to update purchase return: $e', module: 'purchases', error: e, stackTrace: st);
      return null;
    }
  }

  Future<bool> deleteReturn(String id) async {
    try {
      final ok = await _repository.deletePurchaseReturn(id);
      if (ok) {
        _localReturns.removeWhere((r) => r.id == id);
        await fetchReturns(
          search: state.valueOrNull?.search,
          status: state.valueOrNull?.status,
        );
      }
      return ok;
    } catch (e, st) {
      AppLogger.error('Failed to delete purchase return: $e', module: 'purchases', error: e, stackTrace: st);
      return false;
    }
  }

  Future<void> refresh() => fetchReturns(
        search: state.valueOrNull?.search,
        status: state.valueOrNull?.status,
      );

  // ── helpers ─────────────────────────────────────────────────────────────────

  List<PurchaseReturn> _merge(
    List<PurchaseReturn> remote,
    List<PurchaseReturn> local,
  ) {
    final map = <String, PurchaseReturn>{};
    for (final r in remote) {
      map[r.id ?? r.returnNumber] = r;
    }
    for (final r in local) {
      map[r.id ?? r.returnNumber] = r;
    }
    final list = map.values.toList()
      ..sort((a, b) {
        final aDate = a.returnDate ?? a.createdAt ?? DateTime(1970);
        final bDate = b.returnDate ?? b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    return list;
  }

  List<PurchaseReturn> _applyFilters(
    List<PurchaseReturn> source,
    String? search,
    String? status,
  ) {
    var list = List<PurchaseReturn>.from(source);

    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase().trim();
      list = list.where((r) {
        return r.returnNumber.toLowerCase().contains(q) ||
            (r.vendorName ?? '').toLowerCase().contains(q) ||
            (r.purchaseOrderNumber ?? '').toLowerCase().contains(q) ||
            (r.purchaseReceiveNumber ?? '').toLowerCase().contains(q);
      }).toList();
    }

    if (status != null &&
        status.trim().isNotEmpty &&
        status.toLowerCase() != 'all') {
      list = list
          .where((r) => r.status.toLowerCase() == status.toLowerCase())
          .toList();
    }

    return list;
  }

  void _upsertLocal(PurchaseReturn r) {
    final idx = _localReturns
        .indexWhere((e) => e.id == r.id || e.returnNumber == r.returnNumber);
    if (idx >= 0) {
      _localReturns[idx] = r;
    } else {
      _localReturns.insert(0, r);
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final purchaseReturnsProvider = StateNotifierProvider<PurchaseReturnsNotifier,
    AsyncValue<PurchaseReturnsState>>((ref) {
  return PurchaseReturnsNotifier(
    ref.watch(purchaseReturnsRepositoryProvider),
  );
});
