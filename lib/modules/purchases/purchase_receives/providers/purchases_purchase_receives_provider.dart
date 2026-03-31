import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

import '../models/purchases_purchase_receives_model.dart';
import '../repositories/purchases_purchase_receives_repository.dart';
import '../repositories/purchases_purchase_receives_repository_impl.dart';

final purchaseReceivesRepositoryProvider = Provider<PurchaseReceivesRepository>(
  (ref) => PurchaseReceivesRepositoryImpl(ref.read(apiClientProvider)),
);

enum PurchaseReceiveSaveMode { remote, localFallback, failed }

class PurchaseReceivesState {
  final List<PurchaseReceive> receives;
  final bool isLoading;
  final String? error;
  final int totalCount;
  final String? search;
  final String? status;

  const PurchaseReceivesState({
    this.receives = const [],
    this.isLoading = false,
    this.error,
    this.totalCount = 0,
    this.search,
    this.status,
  });

  PurchaseReceivesState copyWith({
    List<PurchaseReceive>? receives,
    bool? isLoading,
    String? error,
    int? totalCount,
    String? search,
    String? status,
  }) {
    return PurchaseReceivesState(
      receives: receives ?? this.receives,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      totalCount: totalCount ?? this.totalCount,
      search: search ?? this.search,
      status: status ?? this.status,
    );
  }
}

class PurchaseReceivesNotifier
    extends StateNotifier<AsyncValue<PurchaseReceivesState>> {
  final PurchaseReceivesRepository _repository;
  final List<PurchaseReceive> _localReceives = <PurchaseReceive>[];

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
    final previous = state.valueOrNull ?? const PurchaseReceivesState();
    state = AsyncValue.data(
      previous.copyWith(
        isLoading: true,
        error: null,
        search: search,
        status: status,
      ),
    );

    try {
      final remote = await _repository.getPurchaseReceives(
        page: page,
        limit: limit,
        search: search,
        status: status,
      );
      final merged = _mergeReceives(remote, _localReceives);
      state = AsyncValue.data(
        PurchaseReceivesState(
          receives: merged,
          isLoading: false,
          totalCount: merged.length,
          search: search,
          status: status,
        ),
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch purchase receives from API, using local state only',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      final localFiltered = _applyFilters(_localReceives, search, status);
      state = AsyncValue.data(
        PurchaseReceivesState(
          receives: localFiltered,
          isLoading: false,
          error: e.toString(),
          totalCount: localFiltered.length,
          search: search,
          status: status,
        ),
      );
    }
  }

  Future<PurchaseReceiveSaveMode> createReceive(PurchaseReceive receive) async {
    final now = DateTime.now();
    final normalized = receive.copyWith(
      id:
          receive.id ??
          'local-pr-${now.microsecondsSinceEpoch}',
      createdAt: receive.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final created = await _repository.createPurchaseReceive(normalized);
      _upsertLocal(created);
      await fetchReceives(search: state.valueOrNull?.search, status: state.valueOrNull?.status);
      return PurchaseReceiveSaveMode.remote;
    } catch (e, st) {
      AppLogger.error(
        'Remote save failed for purchase receive, keeping local-only copy',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      _upsertLocal(normalized);
      final filtered = _applyFilters(
        _localReceives,
        state.valueOrNull?.search,
        state.valueOrNull?.status,
      );
      state = AsyncValue.data(
        PurchaseReceivesState(
          receives: filtered,
          isLoading: false,
          error: 'Saved locally only. Purchase Receive API is unavailable.',
          totalCount: filtered.length,
          search: state.valueOrNull?.search,
          status: state.valueOrNull?.status,
        ),
      );
      return PurchaseReceiveSaveMode.localFallback;
    }
  }

  Future<void> refresh() async {
    await fetchReceives(
      search: state.valueOrNull?.search,
      status: state.valueOrNull?.status,
    );
  }

  List<PurchaseReceive> _mergeReceives(
    List<PurchaseReceive> remote,
    List<PurchaseReceive> local,
  ) {
    final map = <String, PurchaseReceive>{};
    for (final receive in remote) {
      final key =
          receive.id ??
          receive.purchaseReceiveNumber;
      map[key] = receive;
    }
    for (final receive in local) {
      final key =
          receive.id ??
          receive.purchaseReceiveNumber;
      map[key] = receive;
    }
    final list = map.values.toList()
      ..sort((a, b) {
        final aDate = a.receivedDate ?? a.createdAt ?? DateTime(1970);
        final bDate = b.receivedDate ?? b.createdAt ?? DateTime(1970);
        return bDate.compareTo(aDate);
      });
    return list;
  }

  List<PurchaseReceive> _applyFilters(
    List<PurchaseReceive> source,
    String? search,
    String? status,
  ) {
    var list = List<PurchaseReceive>.from(source);

    if (search != null && search.trim().isNotEmpty) {
      final q = search.toLowerCase().trim();
      list = list.where((receive) {
        return receive.purchaseReceiveNumber.toLowerCase().contains(q) ||
            (receive.purchaseOrderNumber ?? '').toLowerCase().contains(q) ||
            (receive.vendorName ?? '').toLowerCase().contains(q);
      }).toList();
    }

    if (status != null &&
        status.trim().isNotEmpty &&
        status.toLowerCase() != 'all') {
      list = list.where((receive) {
        final normalized = receive.status.toLowerCase();
        switch (status.toLowerCase()) {
          case 'received':
            return normalized == 'received';
          case 'billed':
            return receive.billed;
          case 'partially billed':
            return receive.billed == false && normalized == 'received';
          case 'in transit':
            return normalized == 'in transit';
          default:
            return normalized == status.toLowerCase();
        }
      }).toList();
    }

    return list;
  }

  void _upsertLocal(PurchaseReceive receive) {
    final index = _localReceives.indexWhere(
      (item) =>
          item.id == receive.id ||
          item.purchaseReceiveNumber == receive.purchaseReceiveNumber,
    );
    if (index >= 0) {
      _localReceives[index] = receive;
    } else {
      _localReceives.insert(0, receive);
    }
  }
}

final purchaseReceivesProvider = StateNotifierProvider<
  PurchaseReceivesNotifier,
  AsyncValue<PurchaseReceivesState>
>((ref) {
  final repository = ref.watch(purchaseReceivesRepositoryProvider);
  return PurchaseReceivesNotifier(repository);
});
