import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/accountant/transaction_locking/models/transaction_lock_model.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';

final transactionLockProvider =
    StateNotifierProvider<
      TransactionLockNotifier,
      Map<String, TransactionLock>
    >((ref) {
      ref.watch(authUserProvider.select((user) => user?.activeEntityId));
      final dio = ref.watch(dioProvider);
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      final notifier = TransactionLockNotifier(dio);
      if (isAuthenticated) notifier.init();
      return notifier;
    });

final negativeStockModeProvider = FutureProvider.autoDispose<String>((ref) {
  ref.watch(authUserProvider.select((user) => user?.activeEntityId));
  return ref.watch(transactionLockProvider.notifier).fetchNegativeStockMode();
});

class TransactionLockNotifier
    extends StateNotifier<Map<String, TransactionLock>> {
  final Dio _dio;

  TransactionLockNotifier(this._dio) : super({});

  Future<void> init() async {
    await fetchLocks();
  }

  Future<void> fetchLocks() async {
    try {
      final response = await _dio.get('transaction-locking');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final Map<String, TransactionLock> locks = {};
        for (var item in data) {
          final lock = TransactionLock.fromJson(item);
          locks[lock.moduleName] = lock;
        }
        state = locks;
      }
    } catch (e) {
      AppLogger.error(
        'Error fetching transaction locks',
        error: e,
        module: 'transaction_lock',
      );
    }
  }

  Future<String> fetchNegativeStockMode() async {
    final response = await _dio.get(
      'transaction-locking/negative-stock-policy',
    );
    final mode = response.data is Map
        ? (response.data as Map)['mode']?.toString()
        : null;
    return mode == 'allow' ? 'allow' : 'restrict';
  }

  Future<void> saveNegativeStockMode(String mode) async {
    if (mode != 'allow' && mode != 'restrict') {
      throw ArgumentError('Negative stock mode must be allow or restrict');
    }
    await _dio.put(
      'transaction-locking/negative-stock-policy',
      data: {'mode': mode},
    );
  }

  Future<void> lockModule({
    required String moduleName,
    required DateTime lockDate,
    required String reason,
  }) async {
    final normalizedReason = reason.trim();
    if (normalizedReason.isEmpty) {
      throw ArgumentError('A lock reason is required');
    }

    // Optimistic update
    final lock = TransactionLock(
      moduleName: moduleName,
      lockDate: lockDate,
      reason: normalizedReason,
      updatedAt: DateTime.now(),
    );

    final previousState = state;
    state = {...state, moduleName: lock};

    try {
      await _dio.post('transaction-locking', data: lock.toJson());
    } catch (e) {
      AppLogger.error(
        'Error locking module',
        error: e,
        module: 'transaction_lock',
      );
      state = previousState; // Rollback
      rethrow;
    }
  }

  Future<void> unlockModule(String moduleName) async {
    final previousState = state;
    final newState = Map<String, TransactionLock>.from(state);
    newState.remove(moduleName);
    state = newState;

    try {
      await _dio.delete('transaction-locking/$moduleName');
    } catch (e) {
      AppLogger.error(
        'Error unlocking module',
        error: e,
        module: 'transaction_lock',
      );
      state = previousState; // Rollback
      rethrow;
    }
  }

  TransactionLock? getLock(String moduleName) => state[moduleName];
}
