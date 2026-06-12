import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
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
      final receives = await _repository.getPurchaseReceives(
        page: page,
        limit: limit,
        search: search,
        status: status,
      );
      final total = await _repository.getTotalCount();
      state = AsyncValue.data(
        PurchaseReceivesState(receives: receives, totalCount: total),
      );
    } catch (e, st) {
      AppLogger.error(
        'Failed to fetch purchase receives',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> createReceive(PurchaseReceive receive) async {
    try {
      await _repository.createPurchaseReceive(receive);
      await fetchReceives(); // Refresh list after create
      return null;
    } catch (e, st) {
      AppLogger.error(
        'Failed to create purchase receive',
        error: e,
        stackTrace: st,
        module: 'purchases',
      );
      
      String? errorMessage;
      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData is Map) {
          final message = responseData['message'];
          if (message is String && message.trim().isNotEmpty) {
            errorMessage = message.trim();
          } else if (message is Map) {
            final field = message['field'];
            final constraints = message['constraints'];
            if (constraints is Map) {
              errorMessage = '${field ?? ""}: ${constraints.values.join(", ")}';
            } else {
              errorMessage = 'Validation error on "$field"';
            }
          } else if (message is List) {
            final list = message.map((item) {
              if (item is Map) {
                final field = item['field'];
                final constraints = item['constraints'];
                if (constraints is Map) {
                  return '${field ?? ""}: ${constraints.values.join(", ")}';
                }
                return 'Validation error on "$field"';
              }
              return item.toString();
            }).join('; ');
            if (list.isNotEmpty) errorMessage = list;
          }
          
          if (errorMessage == null) {
            final meta = responseData['meta'];
            if (meta is Map) {
              final metaError = meta['error'];
              if (metaError is Map) {
                final metaMessage = metaError['message'];
                if (metaMessage is String && metaMessage.trim().isNotEmpty) {
                  errorMessage = metaMessage.trim();
                }
              }
            }
          }
        }
        if (errorMessage == null) {
          final payload = e.error;
          if (payload is Map) {
            final msg = payload['message'];
            if (msg is String && msg.trim().isNotEmpty) errorMessage = msg.trim();
          }
        }
        errorMessage ??= e.message?.trim();
      }
      
      errorMessage ??= e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring('Exception: '.length);
      }
      return errorMessage;
    }
  }

  Future<bool> updateReceive(String id, PurchaseReceive receive) async {
    try {
      final updated = await _repository.updatePurchaseReceive(id, receive);
      if (updated != null) {
        final currentState = state.valueOrNull;
        if (currentState != null) {
          final updatedList = currentState.receives.map((r) => r.id == id ? updated : r).toList();
          state = AsyncValue.data(currentState.copyWith(receives: updatedList));
        }
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

final purchaseReceiveByIdProvider = FutureProvider.family<PurchaseReceive?, String>((ref, id) async {
  final repository = ref.watch(purchaseReceiveRepositoryProvider);
  return repository.getPurchaseReceive(id);
});
