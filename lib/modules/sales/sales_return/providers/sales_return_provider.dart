import 'package:dio/dio.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
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

  /// Message from the last failed create/update, so the form can tell the user
  /// what actually went wrong instead of a generic "please try again".
  String? lastError;

  Future<SalesReturn?> createSalesReturn(CreateSalesReturnPayload payload) async {
    state = const AsyncValue.loading();
    lastError = null;
    try {
      final result = await _repository.createSalesReturn(payload);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      lastError = _describeError(e);
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

  /// Pulls the server's message out of a Dio failure so validation errors
  /// (a bad UUID, a duplicate RMA#) reach the user instead of being flattened
  /// into a generic retry prompt.
  String _describeError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        final message = data['message'];
        return message is List ? message.join(', ') : '$message';
      }
      final status = e.response?.statusCode;
      if (status != null) return 'Server returned $status.';
      return e.message ?? 'Network error.';
    }
    return '$e';
  }

  Future<SalesReturn?> updateSalesReturn(
    String id,
    CreateSalesReturnPayload payload,
  ) async {
    state = const AsyncValue.loading();
    lastError = null;
    try {
      final result = await _repository.updateSalesReturn(id, payload);
      state = AsyncValue.data(result);
      return result;
    } catch (e, st) {
      lastError = _describeError(e);
      AppLogger.error(
        'Failed to update sales return',
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
    FutureProvider.autoDispose.family<List<SalesReturn>, String?>((ref, status) async {
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

final salesReturnHistoryProvider =
    FutureProvider.family<List<SalesReturnHistoryEntry>, String>(
  (ref, salesReturnId) async {
    final repo = ref.watch(salesReturnRepositoryProvider);
    return repo.getHistory(salesReturnId);
  },
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
    return (salesReturnId, receiveId) => repo.deleteReceive(salesReturnId, receiveId);
  },
);

/// Invoiced / already-returned quantities for a customer, keyed by product id.
/// Watched by the create form so the INVOICED and RETURNED columns fill in as
/// soon as a customer is picked.
final customerItemHistoryProvider = FutureProvider.family<
    Map<String, CustomerItemHistory>,
    ({String customerId, String? excludeReturnId})>(
  (ref, args) async {
    if (args.customerId.isEmpty) return const {};
    final repo = ref.watch(salesReturnRepositoryProvider);
    return repo.getCustomerItemHistory(
      args.customerId,
      excludeReturnId: args.excludeReturnId,
    );
  },
);

/// Workflow transition, e.g. approving a draft from the overview page.
final updateSalesReturnStatusProvider =
    Provider<Future<SalesReturn> Function(String, String)>(
  (ref) {
    final repo = ref.read(salesReturnRepositoryProvider);
    return (id, status) => repo.updateSalesReturnStatus(id, status);
  },
);

final deleteSalesReturnProvider = Provider<Future<void> Function(String)>(
  (ref) {
    final repo = ref.read(salesReturnRepositoryProvider);
    return (id) => repo.deleteSalesReturn(id);
  },
);

final salesReturnsWarehousesProvider = FutureProvider<List<Warehouse>>((ref) async {
  final repository = ref.watch(salesReturnRepositoryProvider);
  return repository.getWarehouses();
});
