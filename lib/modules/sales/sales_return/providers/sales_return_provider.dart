import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

import '../models/sales_return_model.dart';
import '../repositories/sales_return_repository.dart';
import '../repositories/sales_return_repository_impl.dart';

final salesReturnRepositoryProvider = Provider<SalesReturnRepository>(
  (ref) => SalesReturnRepositoryImpl(ref.read(apiClientProvider)),
);

class SalesReturnNotifier extends StateNotifier<AsyncValue<SalesReturn?>> {
  final SalesReturnRepository _repository;

  SalesReturnNotifier(this._repository) : super(const AsyncValue.data(null));

  Future<SalesReturn?> createSalesReturn(CreateSalesReturnPayload payload) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createSalesReturn(payload);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      AppLogger.error(
        'Failed to create sales return',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  void reset() => state = const AsyncValue.data(null);
}

final salesReturnProvider =
    StateNotifierProvider<SalesReturnNotifier, AsyncValue<SalesReturn?>>(
  (ref) => SalesReturnNotifier(ref.watch(salesReturnRepositoryProvider)),
);

final salesReturnsListProvider =
    FutureProvider.family<List<SalesReturn>, String?>((ref, status) async {
  final repo = ref.watch(salesReturnRepositoryProvider);
  return repo.getSalesReturns(status: status);
});

class SalesReturnReceiveStatusNotifier
    extends StateNotifier<Map<String, String>> {
  SalesReturnReceiveStatusNotifier() : super({});

  void markReceived(String rmaNumber) {
    state = {...state, rmaNumber: 'Received'};
  }

  void removeReceiveStatus(String rmaNumber) {
    final updated = Map<String, String>.from(state);
    updated.remove(rmaNumber);
    state = updated;
  }
}

final salesReturnReceiveStatusProvider = StateNotifierProvider<
    SalesReturnReceiveStatusNotifier, Map<String, String>>(
  (ref) => SalesReturnReceiveStatusNotifier(),
);

final salesReturnReceivesProvider =
    FutureProvider.family<List<SalesReturnReceive>, String>(
  (ref, salesReturnId) async {
    final repo = ref.watch(salesReturnRepositoryProvider);
    return repo.getReceives(salesReturnId);
  },
);

final createSalesReturnReceiveProvider =
    Provider<Future<SalesReturnReceive> Function(String, CreateReceivePayload)>(
  (ref) {
    final repo = ref.read(salesReturnRepositoryProvider);
    return (salesReturnId, payload) => repo.createReceive(salesReturnId, payload);
  },
);

final deleteSalesReturnReceiveProvider =
    Provider<Future<void> Function(String, String)>(
  (ref) {
    final repo = ref.read(salesReturnRepositoryProvider);
    return (salesReturnId, receiveId) =>
        repo.deleteReceive(salesReturnId, receiveId);
  },
);
