import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/core/workflow/approval_escalation_engine.dart';
import 'package:zerpai_erp/core/workflow/approval_queue_engine.dart';

void main() {
  group('ApprovalEscalationEngine', () {
    test('creates escalation for overdue SLA approvals', () {
      final queue = <ApprovalQueueItem>[
        ApprovalQueueEngine.createPendingItem(
          queueId: 'q-1',
          transactionType: 'inventory.adjustment',
          transactionId: 'adj-1',
          status: 'pending_approval',
          pendingSince: DateTime(2026, 1, 1, 0, 0, 0),
          now: DateTime(2026, 1, 1, 0, 0, 0),
        ),
      ];

      final decisions = ApprovalEscalationEngine.evaluate(
        queue: queue,
        previousEscalations: const <String, int>{},
        now: DateTime(2026, 1, 3, 2, 0, 0),
      );

      expect(decisions.length, 1);
      expect(decisions.first.level, 1);
      expect(decisions.first.queueId, 'q-1');
    });

    test('does not duplicate same escalation level window', () {
      final queue = <ApprovalQueueItem>[
        ApprovalQueueEngine.createPendingItem(
          queueId: 'q-2',
          transactionType: 'inventory.adjustment',
          transactionId: 'adj-2',
          status: 'pending_approval',
          pendingSince: DateTime(2026, 1, 1, 0, 0, 0),
          now: DateTime(2026, 1, 1, 0, 0, 0),
        ),
      ];

      final decisions = ApprovalEscalationEngine.evaluate(
        queue: queue,
        previousEscalations: const <String, int>{'q-2': 1},
        now: DateTime(2026, 1, 3, 2, 0, 0),
      );

      expect(decisions, isEmpty);
    });
  });
}

