import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/core/workflow/approval_queue_engine.dart';
import 'package:zerpai_erp/core/workflow/transition_lock_policy.dart';
import 'package:zerpai_erp/core/workflow/workflow_observability.dart';

void main() {
  group('TransitionLockPolicy', () {
    test('resolves inventory freeze from lock records', () {
      final context = TransitionLockPolicy.buildGovernanceContext(
        transactionType: 'inventory.transfer',
        locks: <TransactionLockRecord>[
          TransactionLockRecord(
            moduleName: 'inventory',
            lockDate: DateTime.utc(2026, 1, 1),
          ),
        ],
      );
      expect(context.isInventoryFrozen, true);
      expect(context.isFinancialPeriodLocked, false);
    });
  });

  group('ApprovalQueueEngine', () {
    test('marks approval item overdue when SLA exceeded', () {
      final item = ApprovalQueueEngine.createPendingItem(
        queueId: 'q1',
        transactionType: 'inventory.adjustment',
        transactionId: 'adj-1',
        status: 'pending_approval',
        pendingSince: DateTime(2026, 1, 1, 0, 0, 0),
        now: DateTime(2026, 1, 3, 12, 0, 0),
      );
      expect(item.isOverdue, true);
    });
  });

  group('WorkflowObservabilityEngine', () {
    test('builds snapshot with stale and blocked metrics', () {
      final pending = <ApprovalQueueItem>[
        ApprovalQueueEngine.createPendingItem(
          queueId: 'q1',
          transactionType: 'inventory.transfer',
          transactionId: 'to-1',
          status: 'initiated',
          pendingSince: DateTime(2026, 1, 1, 0, 0, 0),
          now: DateTime(2026, 1, 4, 0, 0, 0),
        ),
      ];
      final snapshot = WorkflowObservabilityEngine.buildSnapshot(
        approvalQueue: pending,
        telemetry: const <TransitionTelemetryCounter>[
          TransitionTelemetryCounter(blocked: 3, reversed: 1, highRisk: 2),
        ],
        now: DateTime(2026, 1, 10, 0, 0, 0),
      );
      expect(snapshot.pendingApprovals, 1);
      expect(snapshot.overdueApprovals, 1);
      expect(snapshot.staleTransitions, 1);
      expect(snapshot.blockedTransitions, 3);
      expect(snapshot.highRiskTransitions, 3);
    });
  });
}
