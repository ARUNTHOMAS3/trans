import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/core/workflow/approval_queue_engine.dart';
import 'package:zerpai_erp/core/workflow/domain_event_dispatcher.dart';
import 'package:zerpai_erp/core/workflow/domain_event_envelope.dart';
import 'package:zerpai_erp/core/workflow/domain_event_idempotency.dart';
import 'package:zerpai_erp/core/workflow/domain_events.dart';
import 'package:zerpai_erp/core/workflow/transaction_status_transition_guard.dart';
import 'package:zerpai_erp/core/workflow/transition_governance_context.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';

User _admin() {
  final now = DateTime(2026, 1, 1);
  return User(
    id: 'u-admin',
    email: 'admin@example.com',
    fullName: 'Admin',
    role: 'admin',
    orgId: 'org-1',
    orgName: 'Org',
    orgSystemId: '0000000001',
    isActive: true,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('Domain Event Convergence', () {
    setUp(() {
      DomainEventDispatcher.clearHandlers();
    });

    test('emits transition + blocked events on denied transition', () {
      final events = <DomainEventEnvelope>[];
      DomainEventDispatcher.configureIdempotencyStore(
        InMemoryDomainEventIdempotencyStore(),
      );
      DomainEventDispatcher.register(
        'transaction.transitioned',
        events.add,
      );
      DomainEventDispatcher.register('workflow.blocked', events.add);

      final decision = TransactionStatusTransitionGuard.canTransition(
        user: _admin(),
        transactionType: 'sales.invoice',
        fromStatus: 'approved',
        toStatus: 'voided',
        transactionId: 'inv-1',
        reason: '',
      );

      expect(decision.allowed, false);
      expect(
        events.where((e) => e.event is TransactionTransitionedEvent).isNotEmpty,
        true,
      );
      expect(events.where((e) => e.event is WorkflowBlockedEvent).isNotEmpty, true);
    });

    test('emits approval queued event from queue engine', () {
      final events = <DomainEventEnvelope>[];
      DomainEventDispatcher.configureIdempotencyStore(
        InMemoryDomainEventIdempotencyStore(),
      );
      DomainEventDispatcher.register('approval.queued', events.add);
      final item = ApprovalQueueEngine.createPendingItem(
        queueId: 'q1',
        transactionType: 'inventory.adjustment',
        transactionId: 'adj-10',
        status: 'pending_approval',
        pendingSince: DateTime(2026, 1, 1, 0, 0, 0),
        now: DateTime(2026, 1, 5, 0, 0, 0),
      );
      expect(item.isOverdue, true);
      expect(events.where((e) => e.event is ApprovalQueuedEvent).isNotEmpty, true);
    });

    test('emits transition event on allowed transition', () {
      final events = <DomainEventEnvelope>[];
      DomainEventDispatcher.configureIdempotencyStore(
        InMemoryDomainEventIdempotencyStore(),
      );
      DomainEventDispatcher.register(
        'transaction.transitioned',
        events.add,
      );
      final decision = TransactionStatusTransitionGuard.canTransition(
        user: _admin(),
        transactionType: 'inventory.transfer',
        fromStatus: 'draft',
        toStatus: 'initiated',
        transactionId: 'to-1',
        governanceContext: const TransitionGovernanceContext(),
      );
      expect(decision.allowed, true);
      expect(events.where((e) => e.event is TransactionTransitionedEvent).length, 1);
    });
  });
}
