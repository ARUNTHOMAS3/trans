import 'approval_queue_engine.dart';
import 'domain_event_dispatcher.dart';
import 'domain_events.dart';

class ApprovalEscalationDecision {
  final String queueId;
  final String transactionType;
  final String transactionId;
  final int level;
  final String reason;
  final DateTime escalatedAt;
  final Duration? sla;
  final int overdueHours;
  final String? branchId;
  final String? warehouseId;

  const ApprovalEscalationDecision({
    required this.queueId,
    required this.transactionType,
    required this.transactionId,
    required this.level,
    required this.reason,
    required this.escalatedAt,
    required this.overdueHours,
    this.sla,
    this.branchId,
    this.warehouseId,
  });
}

class ApprovalEscalationEngine {
  const ApprovalEscalationEngine._();

  static List<ApprovalEscalationDecision> evaluate({
    required List<ApprovalQueueItem> queue,
    required Map<String, int> previousEscalations,
    DateTime? now,
  }) {
    final resolvedNow = now ?? DateTime.now();
    final decisions = <ApprovalEscalationDecision>[];

    for (final item in queue) {
      final sla = item.sla;
      if (sla == null) continue;
      final pending = resolvedNow.difference(item.pendingSince);
      if (pending <= sla) continue;

      final currentLevel = previousEscalations[item.queueId] ?? 0;
      final nextBoundary = sla * (currentLevel + 1);
      if (pending < nextBoundary) continue;

      decisions.add(
        ApprovalEscalationDecision(
          queueId: item.queueId,
          transactionType: item.transactionType,
          transactionId: item.transactionId,
          level: currentLevel + 1,
          reason:
              'Approval overdue by ${pending.inHours}h (SLA ${sla.inHours}h)',
          escalatedAt: resolvedNow,
          overdueHours: pending.inHours,
          sla: sla,
          branchId: item.branchId,
          warehouseId: item.warehouseId,
        ),
      );
    }

    return decisions;
  }

  static void emit(ApprovalEscalationDecision decision) {
    DomainEventDispatcher.dispatch(
      ApprovalEscalatedEvent(
        occurredAt: decision.escalatedAt,
        queueId: decision.queueId,
        transactionType: decision.transactionType,
        transactionId: decision.transactionId,
        level: decision.level,
        reason: decision.reason,
        sla: decision.sla,
        overdueHours: decision.overdueHours,
        branchId: decision.branchId,
        warehouseId: decision.warehouseId,
      ),
      correlationId: 'approval-escalation:${decision.queueId}',
    );
  }
}
