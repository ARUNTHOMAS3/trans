import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zerpai_erp/modules/accountant/models/transaction_lock_model.dart';
import 'package:zerpai_erp/modules/accountant/providers/transaction_lock_provider.dart';

class _MockDio extends Mock implements Dio {}

RequestOptions _ro(String path) => RequestOptions(path: path);

Response<dynamic> _ok(List<dynamic> body) => Response(
      data: body,
      statusCode: 200,
      requestOptions: _ro('transaction-locking'),
    );

void main() {
  late _MockDio dio;
  late TransactionLockNotifier notifier;

  setUp(() {
    dio = _MockDio();
    // Prevent the automatic init() fetch from running inside constructor by
    // default — individual tests stub it as needed.
    when(() => dio.get(any(), queryParameters: any(named: 'queryParameters')))
        .thenAnswer((_) async => _ok([]));
    notifier = TransactionLockNotifier(dio);
  });

  group('fetchLocks', () {
    test('parses API list and populates state keyed by moduleName', () async {
      final lockDate = DateTime(2026, 3, 1);
      final updatedAt = DateTime(2026, 3, 2);

      when(() => dio.get('transaction-locking')).thenAnswer(
        (_) async => _ok([
          {
            'moduleName': 'sales',
            'lockDate': lockDate.toIso8601String(),
            'reason': 'Year-end close',
            'updatedAt': updatedAt.toIso8601String(),
          },
          {
            'moduleName': 'purchases',
            'lockDate': lockDate.toIso8601String(),
            'reason': 'Audit',
            'updatedAt': updatedAt.toIso8601String(),
          },
        ]),
      );

      await notifier.fetchLocks();

      expect(notifier.state.keys, containsAll(['sales', 'purchases']));
      expect(notifier.state['sales']?.reason, 'Year-end close');
      expect(notifier.state['purchases']?.reason, 'Audit');
    });

    test('keeps state empty when API returns empty list', () async {
      when(() => dio.get('transaction-locking'))
          .thenAnswer((_) async => _ok([]));

      await notifier.fetchLocks();

      expect(notifier.state, isEmpty);
    });

    test('leaves state unchanged when API call throws', () async {
      // Pre-populate state to verify it is not cleared on error
      when(() => dio.get('transaction-locking')).thenAnswer(
        (_) async => _ok([
          {
            'moduleName': 'inventory',
            'lockDate': DateTime(2026).toIso8601String(),
            'reason': 'Initial',
            'updatedAt': DateTime(2026).toIso8601String(),
          },
        ]),
      );
      await notifier.fetchLocks();

      // Now make it fail
      when(() => dio.get('transaction-locking'))
          .thenThrow(DioException(requestOptions: _ro('transaction-locking')));
      await notifier.fetchLocks();

      // State should still have the previously fetched lock
      expect(notifier.state.containsKey('inventory'), isTrue);
    });
  });

  group('lockModule', () {
    test('adds lock to state optimistically before API call resolves', () async {
      when(
        () => dio.post('transaction-locking', data: any(named: 'data')),
      ).thenAnswer(
        (_) async =>
            Response(data: null, statusCode: 201, requestOptions: _ro('')),
      );

      final lockDate = DateTime(2026, 4, 1);
      final future = notifier.lockModule(
        moduleName: 'accountant',
        lockDate: lockDate,
        reason: 'Q1 close',
      );

      // State is updated optimistically (synchronously before await)
      expect(notifier.state.containsKey('accountant'), isTrue);
      expect(notifier.state['accountant']?.reason, 'Q1 close');

      await future;

      // State remains after successful API call
      expect(notifier.state.containsKey('accountant'), isTrue);
    });

    test('rolls back optimistic update when API call fails', () async {
      when(
        () => dio.post('transaction-locking', data: any(named: 'data')),
      ).thenThrow(DioException(requestOptions: _ro('transaction-locking')));

      await notifier.lockModule(
        moduleName: 'sales',
        lockDate: DateTime(2026, 4, 1),
        reason: 'Rollback test',
      );

      // Lock must be removed after rollback
      expect(notifier.state.containsKey('sales'), isFalse);
    });
  });

  group('unlockModule', () {
    setUp(() async {
      // Seed a lock so we can unlock it
      when(() => dio.get('transaction-locking')).thenAnswer(
        (_) async => _ok([
          {
            'moduleName': 'inventory',
            'lockDate': DateTime(2026).toIso8601String(),
            'reason': 'Seeded',
            'updatedAt': DateTime(2026).toIso8601String(),
          },
        ]),
      );
      await notifier.fetchLocks();
    });

    test('removes lock from state optimistically', () async {
      when(() => dio.delete('transaction-locking/inventory')).thenAnswer(
        (_) async =>
            Response(data: null, statusCode: 200, requestOptions: _ro('')),
      );

      final future = notifier.unlockModule('inventory');

      // Optimistic removal
      expect(notifier.state.containsKey('inventory'), isFalse);

      await future;

      expect(notifier.state.containsKey('inventory'), isFalse);
    });

    test('restores lock when delete API call fails', () async {
      when(() => dio.delete('transaction-locking/inventory')).thenThrow(
        DioException(requestOptions: _ro('transaction-locking/inventory')),
      );

      await notifier.unlockModule('inventory');

      // Must rollback — lock is restored
      expect(notifier.state.containsKey('inventory'), isTrue);
    });
  });

  group('getLock', () {
    test('returns null for an unknown module', () {
      expect(notifier.getLock('unknown'), isNull);
    });

    test('returns the lock for a known module', () async {
      when(() => dio.get('transaction-locking')).thenAnswer(
        (_) async => _ok([
          {
            'moduleName': 'reports',
            'lockDate': DateTime(2026, 2).toIso8601String(),
            'reason': 'Freeze',
            'updatedAt': DateTime(2026, 2).toIso8601String(),
          },
        ]),
      );

      await notifier.fetchLocks();

      final lock = notifier.getLock('reports');
      expect(lock, isNotNull);
      expect(lock!.reason, 'Freeze');
    });
  });

  group('TransactionLock model', () {
    test('fromJson round-trips through toJson', () {
      final now = DateTime.utc(2026, 3, 19, 10, 30);
      final lock = TransactionLock(
        moduleName: 'accountant',
        lockDate: now,
        reason: 'Test',
        updatedAt: now,
      );

      final restored = TransactionLock.fromJson(lock.toJson());

      expect(restored.moduleName, lock.moduleName);
      expect(restored.lockDate.toIso8601String(), lock.lockDate.toIso8601String());
      expect(restored.reason, lock.reason);
    });

    test('copyWith replaces only specified fields', () {
      final original = TransactionLock(
        moduleName: 'sales',
        lockDate: DateTime(2026),
        reason: 'Original',
        updatedAt: DateTime(2026),
      );

      final updated = original.copyWith(reason: 'Updated');

      expect(updated.moduleName, 'sales');
      expect(updated.reason, 'Updated');
    });
  });
}
