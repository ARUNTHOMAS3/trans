import 'approval_queue_engine.dart';
import 'workflow_observability.dart';

class GovernanceDashboardSnapshot {
  final int pendingApprovals;
  final int overdueApprovals;
  final int staleTransitions;
  final int blockedTransitions;
  final int highRiskTransitions;
  final int freezeViolations;
  final int reopenSignals;
  final int escalatedApprovals;

  const GovernanceDashboardSnapshot({
    required this.pendingApprovals,
    required this.overdueApprovals,
    required this.staleTransitions,
    required this.blockedTransitions,
    required this.highRiskTransitions,
    required this.freezeViolations,
    required this.reopenSignals,
    required this.escalatedApprovals,
  });
}

class GovernanceDashboardService {
  const GovernanceDashboardService._();

  static GovernanceDashboardSnapshot build({
    required List<ApprovalQueueItem> approvalQueue,
    required List<TransitionTelemetryCounter> telemetry,
    int freezeViolations = 0,
    int reopenSignals = 0,
    int escalatedApprovals = 0,
    DateTime? now,
  }) {
    final snapshot = WorkflowObservabilityEngine.buildSnapshot(
      approvalQueue: approvalQueue,
      telemetry: telemetry,
      now: now,
    );
    return GovernanceDashboardSnapshot(
      pendingApprovals: snapshot.pendingApprovals,
      overdueApprovals: snapshot.overdueApprovals,
      staleTransitions: snapshot.staleTransitions,
      blockedTransitions: snapshot.blockedTransitions,
      highRiskTransitions: snapshot.highRiskTransitions,
      freezeViolations: freezeViolations,
      reopenSignals: reopenSignals,
      escalatedApprovals: escalatedApprovals,
    );
  }
}
