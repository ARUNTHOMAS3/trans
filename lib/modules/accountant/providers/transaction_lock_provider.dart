import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/transaction_lock_model.dart';
import '../../../core/services/api_client.dart';
import '../../../core/logging/app_logger.dart';
import '../../auth/controller/auth_controller.dart';

final transactionLockProvider =
    StateNotifierProvider<
      TransactionLockNotifier,
      Map<String, TransactionLock>
    >((ref) {
      final dio = ref.watch(dioProvider);
      final isAuthenticated = ref.watch(isAuthenticatedProvider);
      final notifier = TransactionLockNotifier(dio);
      if (isAuthenticated) notifier.init();
      return notifier;
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
      AppLogger.error('Error fetching transaction locks', error: e, module: 'transaction_lock');
    }
  }

  Future<void> lockModule({
    required String moduleName,
    required DateTime lockDate,
    required String reason,
  }) async {
    // Optimistic update
    final lock = TransactionLock(
      moduleName: moduleName,
      lockDate: lockDate,
      reason: reason,
      updatedAt: DateTime.now(),
    );

    final previousState = state;
    state = {...state, moduleName: lock};

    try {
      await _dio.post('transaction-locking', data: lock.toJson());
    } catch (e) {
      AppLogger.error('Error locking module', error: e, module: 'transaction_lock');
      state = previousState; // Rollback
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
      AppLogger.error('Error unlocking module', error: e, module: 'transaction_lock');
      state = previousState; // Rollback
    }
  }

  TransactionLock? getLock(String moduleName) => state[moduleName];
}
