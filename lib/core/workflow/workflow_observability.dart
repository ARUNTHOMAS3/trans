import 'approval_queue_engine.dart';
import 'transaction_transition_definitions.dart';

class WorkflowObservabilitySnapshot {
  final int pendingApprovals;
  final int overdueApprovals;
  final int staleTransitions;
  final int blockedTransitions;
  final int highRiskTransitions;

  const WorkflowObservabilitySnapshot({
    required this.pendingApprovals,
    required this.overdueApprovals,
    required this.staleTransitions,
    required this.blockedTransitions,
    required this.highRiskTransitions,
  });
}

class TransitionTelemetryCounter {
  final int blocked;
  final int reversed;
  final int highRisk;

  const TransitionTelemetryCounter({
    this.blocked = 0,
    this.reversed = 0,
    this.highRisk = 0,
  });
}

class WorkflowObservabilityEngine {
  const WorkflowObservabilityEngine._();

  static WorkflowObservabilitySnapshot buildSnapshot({
    required List<ApprovalQueueItem> approvalQueue,
    required List<TransitionTelemetryCounter> telemetry,
    DateTime? now,
  }) {
    final resolvedNow = now ?? DateTime.now();
    var stale = 0;
    var overdue = 0;
    for (final item in approvalQueue) {
      if (item.isOverdue) overdue++;
      final definition = transitionDefinitions
          .where((d) => d.transactionType == item.transactionType)
          .cast<TransitionDefinition?>()
          .firstWhere((d) => d != null, orElse: () => null);
      final staleAfter = definition?.staleAfterDuration;
      if (staleAfter != null &&
          resolvedNow.difference(item.pendingSince) > staleAfter) {
        stale++;
      }
    }

    var blocked = 0;
    var reversed = 0;
    var highRisk = 0;
    for (final t in telemetry) {
      blocked += t.blocked;
      reversed += t.reversed;
      highRisk += t.highRisk;
    }

    return WorkflowObservabilitySnapshot(
      pendingApprovals: approvalQueue.length,
      overdueApprovals: overdue,
      staleTransitions: stale,
      blockedTransitions: blocked,
      highRiskTransitions: highRisk + reversed,
    );
  }
}
