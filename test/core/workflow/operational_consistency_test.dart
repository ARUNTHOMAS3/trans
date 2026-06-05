import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/core/workflow/approval_queue_engine.dart';
import 'package:zerpai_erp/core/workflow/domain_event_dispatcher.dart';
import 'package:zerpai_erp/core/workflow/domain_event_envelope.dart';
import 'package:zerpai_erp/core/workflow/domain_event_idempotency.dart';
import 'package:zerpai_erp/core/workflow/domain_events.dart';
import 'package:zerpai_erp/core/workflow/governance_dashboard_service.dart';
import 'package:zerpai_erp/core/workflow/governance_insights_model.dart';
import 'package:zerpai_erp/core/workflow/workflow_runtime_store.dart';
import 'package:zerpai_erp/core/workflow/workflow_observability.dart';

void main() {
  group('Operational Consistency', () {
    test('dashboard aggregation builds expected governance snapshot', () {
      final queue = <ApprovalQueueItem>[
        ApprovalQueueEngine.createPendingItem(
          queueId: 'q1',
          transactionType: 'inventory.adjustment',
          transactionId: 'adj-1',
          status: 'pending_approval',
          pendingSince: DateTime(2026, 1, 1, 0, 0, 0),
          now: DateTime(2026, 1, 4, 0, 0, 0),
        ),
      ];
      final snapshot = GovernanceDashboardService.build(
        approvalQueue: queue,
        telemetry: const <TransitionTelemetryCounter>[
          TransitionTelemetryCounter(blocked: 2, reversed: 1, highRisk: 3),
        ],
        freezeViolations: 2,
        reopenSignals: 1,
        now: DateTime(2026, 1, 10, 0, 0, 0),
      );
      expect(snapshot.pendingApprovals, 1);
      expect(snapshot.blockedTransitions, 2);
      expect(snapshot.freezeViolations, 2);
      expect(snapshot.reopenSignals, 1);
      expect(snapshot.escalatedApprovals, 0);
    });

    test('dispatcher idempotency suppresses duplicate event delivery', () {
      DomainEventDispatcher.clearHandlers();
      DomainEventDispatcher.configureIdempotencyStore(
        InMemoryDomainEventIdempotencyStore(),
      );
      final received = <DomainEventEnvelope>[];
      DomainEventDispatcher.register('workflow.blocked', received.add);

      final event = WorkflowBlockedEvent(
        occurredAt: DateTime(2026, 1, 1, 0, 0, 0),
        transactionType: 'sales.invoice',
        transactionId: 'inv-1',
        fromStatus: 'approved',
        toStatus: 'voided',
        reason: 'Reason missing',
      );

      DomainEventDispatcher.dispatch(
        event,
        eventId: 'evt-1',
        correlationId: 'corr-1',
      );
      DomainEventDispatcher.dispatch(
        event,
        eventId: 'evt-1',
        correlationId: 'corr-1',
      );

      expect(received.length, 1);
    });

    test('runtime store exposes trace and blocked reason explainability', () {
      final store = WorkflowRuntimeStore.instance;
      store.recordEvent(
        DomainEventEnvelope(
          eventId: 'evt-a',
          correlationId: 'corr-a',
          event: TransactionTransitionedEvent(
            occurredAt: DateTime(2026, 1, 1),
            transactionType: 'sales.invoice',
            transactionId: 'inv-9',
            fromStatus: 'draft',
            toStatus: 'pending_approval',
            allowed: true,
            reason: 'ok',
          ),
        ),
      );
      store.recordEvent(
        DomainEventEnvelope(
          eventId: 'evt-b',
          correlationId: 'corr-a',
          event: WorkflowBlockedEvent(
            occurredAt: DateTime(2026, 1, 2),
            transactionType: 'sales.invoice',
            transactionId: 'inv-9',
            fromStatus: 'pending_approval',
            toStatus: 'approved',
            reason: 'Missing approver permission',
          ),
        ),
      );
      final trace = store.traceForTransaction(
        transactionType: 'sales.invoice',
        transactionId: 'inv-9',
      );
      final reason = store.latestBlockedReason(
        transactionType: 'sales.invoice',
        transactionId: 'inv-9',
      );
      final blocked = store.latestBlockedEvent(
        transactionType: 'sales.invoice',
        transactionId: 'inv-9',
      );
      expect(trace.length >= 2, true);
      expect(reason, 'Missing approver permission');
      expect(blocked?.reason, 'Missing approver permission');
    });

    test('runtime store computes branch governance intelligence', () {
      final store = WorkflowRuntimeStore.instance;
      store.recordEvent(
        DomainEventEnvelope(
          eventId: 'evt-c',
          correlationId: 'corr-z',
          event: ApprovalQueuedEvent(
            occurredAt: DateTime(2026, 1, 3),
            queueId: 'q-branch-1',
            transactionType: 'inventory.adjustment',
            transactionId: 'adj-88',
            status: 'pending_approval',
            pendingSince: DateTime(2026, 1, 1),
            isOverdue: true,
            sla: const Duration(hours: 24),
            branchId: 'b1',
          ),
        ),
      );
      final intel = store.branchGovernanceIntelligence(
        now: DateTime(2026, 1, 4),
      );
      final b1 = intel.where((e) => e.branchId == 'b1').first;
      expect(b1.pendingApprovals >= 1, true);
      expect(b1.overdueApprovals >= 1, true);
      expect(b1.slaBreachRatio > 0, true);
    });

    test('runtime store computes trends and policy friction', () {
      final store = WorkflowRuntimeStore.instance;
      store.recordEvent(
        DomainEventEnvelope(
          eventId: 'evt-fr-1',
          correlationId: 'corr-fr',
          event: WorkflowBlockedEvent(
            occurredAt: DateTime.now().subtract(const Duration(days: 1)),
            transactionType: 'sales.invoice',
            transactionId: 'inv-fr-1',
            fromStatus: 'pending_approval',
            toStatus: 'approved',
            reason: 'Missing permission',
            ruleCode: 'permission_denied',
            permissionUsed: 'sales.invoice.approve',
          ),
        ),
      );
      final trends = store.governanceTrends(now: DateTime.now());
      final friction = store.topPolicyFriction();
      final executive = store.executiveSummary();
      expect(trends.currentBlocked >= 1, true);
      expect(friction.isNotEmpty, true);
      expect(executive.totalBlocked >= 1, true);
    });

    test('runtime store computes heatmap, forecast and incident summary', () {
      final store = WorkflowRuntimeStore.instance;
      final heatmap = store.branchGovernanceHeatmap();
      final forecast = store.governanceForecastSignals(now: DateTime.now());
      final incident = store.incidentSummary(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      final ranking = store.branchGovernanceRanking();
      final rca = store.incidentRcaTopBlockers(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      final ops = store.operationsCenterSnapshot();
      final pack = store.incidentEvidencePack(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      final alerts = store.incidentAlerts();
      final escalatedOnlyAlerts = store.incidentAlerts(
        statuses: <GovernanceIncidentStatus>{GovernanceIncidentStatus.escalated},
      );
      final replay = store.incidentReplayTimeline(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      final json = store.incidentEvidenceExportJson(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      final handoffBundle = store.incidentHandoffBundleJson(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      final replaySteps = store.incidentReplayTimeline(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      store.setIncidentAssignment(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
        assignedOperator: 'op-a',
        branchLead: 'lead-b',
        escalationOwner: 'esc-c',
        investigationAssignee: 'agent-d',
        watcherList: const <String>['watch-a', 'watch-b'],
      );
      store.setIncidentAssignment(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
        assignedOperator: 'op-a',
        branchLead: 'lead-b',
        escalationOwner: 'esc-c',
        investigationAssignee: 'agent-e',
        watcherList: const <String>['watch-a', 'watch-c'],
        transferReason: 'handoff to escalation specialist',
      );
      store.addIncidentNote(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
        note: 'handoff to evening shift',
      );
      store.saveInvestigationSnapshot(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
        label: 'night-shift',
      );
      expect(heatmap.isNotEmpty, true);
      expect(forecast.length, 3);
      expect(incident.transactionId, 'inv-fr-1');
      expect(
        incident.status == GovernanceIncidentStatus.active ||
            incident.status == GovernanceIncidentStatus.escalated,
        true,
      );
      expect(ranking.isNotEmpty, true);
      expect(rca.isNotEmpty, true);
      expect(ops.unstableBranches >= 0, true);
      expect(pack.totalEvents >= 1, true);
      expect(alerts.isNotEmpty, true);
      expect(escalatedOnlyAlerts.length >= 0, true);
      expect(replay.isNotEmpty, true);
      expect(replaySteps.first.eventType.isNotEmpty, true);
      expect(json.contains('"transaction_id": "inv-fr-1"'), true);
      expect(handoffBundle.contains('"assignment"'), true);
      expect(
        store
            .incidentAssignment(
              transactionType: 'sales.invoice',
              transactionId: 'inv-fr-1',
            )
            ?.investigationAssignee,
        'agent-e',
      );
      expect(
        store
            .incidentAssignment(
              transactionType: 'sales.invoice',
              transactionId: 'inv-fr-1',
            )
            ?.watcherList,
        contains('watch-c'),
      );
      expect(
        store.incidentAssignmentHistory(
          transactionType: 'sales.invoice',
          transactionId: 'inv-fr-1',
        ),
        isNotEmpty,
      );
      expect(
        store.incidentNotes(
          transactionType: 'sales.invoice',
          transactionId: 'inv-fr-1',
        ),
        isNotEmpty,
      );
      expect(
        store.investigationSnapshots(
          transactionType: 'sales.invoice',
          transactionId: 'inv-fr-1',
        ),
        isNotEmpty,
      );
      final snapshot = store
          .investigationSnapshots(
            transactionType: 'sales.invoice',
            transactionId: 'inv-fr-1',
          )
          .last;
      store.applyInvestigationSnapshot(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
        createdAt: snapshot.createdAt,
      );
      expect(store.lastInvestigationType, 'sales.invoice');
      expect(store.lastInvestigationId, 'inv-fr-1');

      store.resolveIncident(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      final resolvedSummary = store.incidentSummary(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      expect(resolvedSummary.status, GovernanceIncidentStatus.resolved);
      store.archiveIncident(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      final archivedSummary = store.incidentSummary(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      expect(archivedSummary.status, GovernanceIncidentStatus.archived);
      store.setLastInvestigationViewState(
        replayFilter: 'blocked',
        onlyCritical: true,
      );
      final pipelineCounts = store.incidentStatusPipelineCounts();
      final alertsAfterResolve = store.incidentAlerts();
      final stillPresent = alertsAfterResolve.any(
        (a) =>
            a.transactionType == 'sales.invoice' &&
            a.transactionId == 'inv-fr-1',
      );
      expect(stillPresent, false);
      expect(
        store.isIncidentArchived(
          transactionType: 'sales.invoice',
          transactionId: 'inv-fr-1',
        ),
        true,
      );
      expect(store.lastInvestigationReplayFilter, 'blocked');
      expect(store.lastInvestigationOnlyCritical, true);
      store.saveMissionStatusPreset(
        <GovernanceIncidentStatus>{GovernanceIncidentStatus.active},
      );
      store.saveOpsStatusPreset(
        <GovernanceIncidentStatus>{GovernanceIncidentStatus.escalated},
      );
      store.saveLogsStatusPreset(GovernanceIncidentStatus.resolved);
      expect(store.missionStatusPreset.length, 1);
      expect(store.opsStatusPreset.length, 1);
      expect(store.logsStatusPreset, GovernanceIncidentStatus.resolved);
      expect(
        (pipelineCounts[GovernanceIncidentStatus.archived] ?? 0) >= 1,
        true,
      );
      store.restoreIncidentToActive(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      final reopened = store.incidentSummary(
        transactionType: 'sales.invoice',
        transactionId: 'inv-fr-1',
      );
      expect(reopened.status, GovernanceIncidentStatus.active);
      final anyStatusEvent = store.events.any(
        (e) =>
            e.event is GovernanceIncidentStatusChangedEvent &&
            (e.event as GovernanceIncidentStatusChangedEvent).transactionType ==
                'sales.invoice' &&
            (e.event as GovernanceIncidentStatusChangedEvent).transactionId ==
                'inv-fr-1',
      );
      expect(anyStatusEvent, true);
    });
  });
}
