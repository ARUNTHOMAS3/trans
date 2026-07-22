import 'package:flutter/foundation.dart';
import 'dart:convert';

import 'approval_queue_engine.dart';
import 'approval_escalation_engine.dart';
import 'domain_event_envelope.dart';
import 'domain_events.dart';
import 'governance_intelligence_model.dart';
import 'governance_insights_model.dart';
import 'governance_dashboard_service.dart';
import 'workflow_observability.dart';

class WorkflowRuntimeStore extends ChangeNotifier {
  WorkflowRuntimeStore._();

  static final WorkflowRuntimeStore instance = WorkflowRuntimeStore._();

  final List<DomainEventEnvelope> _events = <DomainEventEnvelope>[];
  final List<ApprovalQueueItem> _approvalQueue = <ApprovalQueueItem>[];
  int _freezeViolations = 0;
  int _escalatedApprovals = 0;
  final Map<String, int> _escalationLevels = <String, int>{};
  final Set<String> _resolvedIncidents = <String>{};
  final Set<String> _archivedIncidents = <String>{};
  final Map<String, GovernanceIncidentStatus> _incidentStatuses =
      <String, GovernanceIncidentStatus>{};
  final Map<String, GovernanceIncidentAssignment> _incidentAssignments =
      <String, GovernanceIncidentAssignment>{};
  final Map<String, List<String>> _incidentAssignmentHistory =
      <String, List<String>>{};
  final Map<String, List<String>> _incidentNotes = <String, List<String>>{};
  final Map<String, List<GovernanceInvestigationSnapshot>>
  _investigationSnapshots = <String, List<GovernanceInvestigationSnapshot>>{};
  String? _lastInvestigationType;
  String? _lastInvestigationId;
  String _lastInvestigationReplayFilter = '';
  bool _lastInvestigationOnlyCritical = false;
  Set<GovernanceIncidentStatus> _missionStatusPreset = GovernanceIncidentStatus
      .values
      .toSet();
  Set<GovernanceIncidentStatus> _opsStatusPreset = GovernanceIncidentStatus
      .values
      .toSet();
  GovernanceIncidentStatus _logsStatusPreset = GovernanceIncidentStatus.active;

  List<DomainEventEnvelope> get events =>
      List<DomainEventEnvelope>.unmodifiable(_events);

  List<ApprovalQueueItem> get approvalQueue =>
      List<ApprovalQueueItem>.unmodifiable(_approvalQueue);

  int get freezeViolations => _freezeViolations;
  int get escalatedApprovals => _escalatedApprovals;
  String? get lastInvestigationType => _lastInvestigationType;
  String? get lastInvestigationId => _lastInvestigationId;
  String get lastInvestigationReplayFilter => _lastInvestigationReplayFilter;
  bool get lastInvestigationOnlyCritical => _lastInvestigationOnlyCritical;
  Set<GovernanceIncidentStatus> get missionStatusPreset =>
      Set<GovernanceIncidentStatus>.from(_missionStatusPreset);
  Set<GovernanceIncidentStatus> get opsStatusPreset =>
      Set<GovernanceIncidentStatus>.from(_opsStatusPreset);
  GovernanceIncidentStatus get logsStatusPreset => _logsStatusPreset;

  void recordEvent(DomainEventEnvelope envelope) {
    _events.add(envelope);
    if (_events.length > 500) {
      _events.removeRange(0, _events.length - 500);
    }

    final event = envelope.event;
    if (event is ApprovalQueuedEvent) {
      _upsertApprovalQueue(
        ApprovalQueueItem(
          queueId: event.queueId,
          transactionType: event.transactionType,
          transactionId: event.transactionId,
          status: event.status,
          pendingSince: event.pendingSince,
          branchId: event.branchId,
          warehouseId: event.warehouseId,
          sla: event.sla,
          isOverdue: event.isOverdue,
        ),
      );
    }
    if (event is InventoryFreezeViolationEvent) {
      _freezeViolations += 1;
    }
    if (event is ApprovalEscalatedEvent) {
      _escalationLevels[event.queueId] = event.level;
      _escalatedApprovals += 1;
    }
    notifyListeners();
  }

  int escalationLevelFor(String queueId) => _escalationLevels[queueId] ?? 0;

  List<DomainEventEnvelope> traceForTransaction({
    required String transactionType,
    required String transactionId,
  }) {
    return _events
        .where((envelope) {
          final event = envelope.event;
          if (event is TransactionTransitionedEvent) {
            return event.transactionType == transactionType &&
                event.transactionId == transactionId;
          }
          if (event is WorkflowBlockedEvent) {
            return event.transactionType == transactionType &&
                event.transactionId == transactionId;
          }
          if (event is InventoryFreezeViolationEvent) {
            return event.transactionType == transactionType &&
                event.transactionId == transactionId;
          }
          if (event is ApprovalEscalatedEvent) {
            return event.transactionType == transactionType &&
                event.transactionId == transactionId;
          }
          if (event is ApprovalQueuedEvent) {
            return event.transactionType == transactionType &&
                event.transactionId == transactionId;
          }
          if (event is GovernanceIncidentStatusChangedEvent) {
            return event.transactionType == transactionType &&
                event.transactionId == transactionId;
          }
          return false;
        })
        .toList(growable: false);
  }

  String? latestBlockedReason({
    required String transactionType,
    required String transactionId,
  }) {
    for (var i = _events.length - 1; i >= 0; i--) {
      final event = _events[i].event;
      if (event is WorkflowBlockedEvent &&
          event.transactionType == transactionType &&
          event.transactionId == transactionId) {
        return event.reason;
      }
    }
    return null;
  }

  WorkflowBlockedEvent? latestBlockedEvent({
    required String transactionType,
    required String transactionId,
  }) {
    for (var i = _events.length - 1; i >= 0; i--) {
      final event = _events[i].event;
      if (event is WorkflowBlockedEvent &&
          event.transactionType == transactionType &&
          event.transactionId == transactionId) {
        return event;
      }
    }
    return null;
  }

  Map<String, int> branchGovernanceHealthScores() {
    final totals = <String, int>{};
    void applyPenalty(String key, int points) {
      totals[key] = (totals[key] ?? 100) - points;
    }

    for (final item in _approvalQueue) {
      final key = item.branchId ?? 'unscoped';
      if (item.isOverdue) applyPenalty(key, 8);
      if (escalationLevelFor(item.queueId) > 0) applyPenalty(key, 5);
    }
    for (final envelope in _events) {
      final event = envelope.event;
      if (event is WorkflowBlockedEvent) {
        applyPenalty(event.branchId ?? 'unscoped', 6);
      } else if (event is InventoryFreezeViolationEvent) {
        applyPenalty(event.branchId ?? 'unscoped', 10);
      } else if (event is TransactionTransitionedEvent &&
          event.toStatus.trim().toLowerCase() == 'reopened') {
        applyPenalty(event.branchId ?? 'unscoped', 3);
      }
    }

    return totals.map((k, v) => MapEntry(k, v.clamp(0, 100)));
  }

  List<BranchGovernanceIntelligence> branchGovernanceIntelligence({
    DateTime? now,
  }) {
    final resolvedNow = now ?? DateTime.now();
    final health = branchGovernanceHealthScores();
    final keys = <String>{};
    keys.addAll(health.keys);
    for (final q in _approvalQueue) {
      keys.add(q.branchId ?? 'unscoped');
    }
    for (final e in _events) {
      if (e.event is WorkflowBlockedEvent) {
        keys.add((e.event as WorkflowBlockedEvent).branchId ?? 'unscoped');
      } else if (e.event is InventoryFreezeViolationEvent) {
        keys.add(
          (e.event as InventoryFreezeViolationEvent).branchId ?? 'unscoped',
        );
      } else if (e.event is TransactionTransitionedEvent) {
        keys.add(
          (e.event as TransactionTransitionedEvent).branchId ?? 'unscoped',
        );
      } else if (e.event is ApprovalEscalatedEvent) {
        keys.add((e.event as ApprovalEscalatedEvent).branchId ?? 'unscoped');
      }
    }

    final list = <BranchGovernanceIntelligence>[];
    for (final key in keys) {
      var pending = 0;
      var overdue = 0;
      var blocked = 0;
      var escalations = 0;
      var freeze = 0;
      var reopens = 0;
      var totalLatencyHours = 0.0;

      for (final q in _approvalQueue) {
        final branchKey = q.branchId ?? 'unscoped';
        if (branchKey != key) continue;
        pending += 1;
        if (q.isOverdue) overdue += 1;
        totalLatencyHours +=
            resolvedNow.difference(q.pendingSince).inMinutes / 60;
      }
      for (final e in _events) {
        final event = e.event;
        if (event is WorkflowBlockedEvent &&
            (event.branchId ?? 'unscoped') == key) {
          blocked += 1;
        } else if (event is ApprovalEscalatedEvent &&
            (event.branchId ?? 'unscoped') == key) {
          escalations += 1;
        } else if (event is InventoryFreezeViolationEvent &&
            (event.branchId ?? 'unscoped') == key) {
          freeze += 1;
        } else if (event is TransactionTransitionedEvent &&
            (event.branchId ?? 'unscoped') == key &&
            event.toStatus.trim().toLowerCase() == 'reopened') {
          reopens += 1;
        }
      }

      final approvalLatencyHours = pending == 0
          ? 0.0
          : totalLatencyHours / pending;
      final breachRatio = pending == 0 ? 0.0 : overdue / pending;
      final escalationDensity = pending == 0 ? 0.0 : escalations / pending;

      list.add(
        BranchGovernanceIntelligence(
          branchId: key,
          governanceHealthScore: health[key] ?? 100,
          pendingApprovals: pending,
          overdueApprovals: overdue,
          blockedTransitions: blocked,
          escalations: escalations,
          freezeViolations: freeze,
          reopens: reopens,
          approvalLatencyHours: approvalLatencyHours,
          slaBreachRatio: breachRatio,
          escalationDensity: escalationDensity,
        ),
      );
    }
    list.sort(
      (a, b) => a.governanceHealthScore.compareTo(b.governanceHealthScore),
    );
    return list;
  }

  GovernanceTrendSnapshot governanceTrends({DateTime? now}) {
    final end = now ?? DateTime.now();
    final currentStart = end.subtract(const Duration(days: 7));
    final previousStart = currentStart.subtract(const Duration(days: 7));

    int blockedCurrent = 0;
    int blockedPrevious = 0;
    int escalatedCurrent = 0;
    int escalatedPrevious = 0;

    for (final envelope in _events) {
      final t = envelope.event.occurredAt;
      final inCurrent = t.isAfter(currentStart) && !t.isAfter(end);
      final inPrevious = t.isAfter(previousStart) && !t.isAfter(currentStart);
      if (envelope.event is WorkflowBlockedEvent) {
        if (inCurrent) blockedCurrent++;
        if (inPrevious) blockedPrevious++;
      }
      if (envelope.event is ApprovalEscalatedEvent) {
        if (inCurrent) escalatedCurrent++;
        if (inPrevious) escalatedPrevious++;
      }
    }

    int overdueCurrent = 0;
    int overduePrevious = 0;
    for (final item in _approvalQueue) {
      if (item.isOverdue) overdueCurrent++;
      if ((item.sla != null) &&
          item.pendingSince.isBefore(currentStart) &&
          currentStart.difference(item.pendingSince) > item.sla!) {
        overduePrevious++;
      }
    }

    return GovernanceTrendSnapshot(
      currentBlocked: blockedCurrent,
      previousBlocked: blockedPrevious,
      currentEscalations: escalatedCurrent,
      previousEscalations: escalatedPrevious,
      currentOverdueApprovals: overdueCurrent,
      previousOverdueApprovals: overduePrevious,
    );
  }

  List<PolicyFrictionMetric> topPolicyFriction({int limit = 5}) {
    final counts = <String, int>{};
    for (final envelope in _events) {
      final e = envelope.event;
      if (e is! WorkflowBlockedEvent) continue;
      final rule = (e.ruleCode ?? 'unknown').trim();
      final permission = (e.permissionUsed ?? 'unknown').trim();
      final key = '$rule|$permission';
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final list = counts.entries
        .map((entry) {
          final parts = entry.key.split('|');
          return PolicyFrictionMetric(
            ruleCode: parts.isNotEmpty ? parts[0] : 'unknown',
            permissionKey: parts.length > 1 ? parts[1] : 'unknown',
            count: entry.value,
          );
        })
        .toList(growable: false);
    list.sort((a, b) => b.count.compareTo(a.count));
    if (list.length <= limit) return list;
    return list.sublist(0, limit);
  }

  GovernanceExecutiveSummary executiveSummary() {
    final intel = branchGovernanceIntelligence();
    final unhealthy = intel.where((x) => x.governanceHealthScore < 70).length;
    final critical = intel.where((x) => x.governanceHealthScore < 50).length;
    var blocked = 0;
    var escalations = 0;
    for (final envelope in _events) {
      if (envelope.event is WorkflowBlockedEvent) blocked++;
      if (envelope.event is ApprovalEscalatedEvent) escalations++;
    }
    return GovernanceExecutiveSummary(
      totalBranches: intel.length,
      unhealthyBranches: unhealthy,
      criticalBranches: critical,
      totalEscalations: escalations,
      totalBlocked: blocked,
    );
  }

  List<GovernanceHeatmapCell> branchGovernanceHeatmap() {
    final intel = branchGovernanceIntelligence();
    final cells = <GovernanceHeatmapCell>[];
    String sev(num v, num w, num c) {
      if (v >= c) return 'critical';
      if (v >= w) return 'warning';
      return 'ok';
    }

    for (final x in intel) {
      cells.add(
        GovernanceHeatmapCell(
          branchId: x.branchId,
          metric: 'Esc Density',
          value: x.escalationDensity,
          severity: sev(x.escalationDensity, 0.30, 0.60),
        ),
      );
      cells.add(
        GovernanceHeatmapCell(
          branchId: x.branchId,
          metric: 'SLA Breach',
          value: x.slaBreachRatio,
          severity: sev(x.slaBreachRatio, 0.25, 0.50),
        ),
      );
      cells.add(
        GovernanceHeatmapCell(
          branchId: x.branchId,
          metric: 'Latency(h)',
          value: x.approvalLatencyHours,
          severity: sev(x.approvalLatencyHours, 24, 48),
        ),
      );
    }
    return cells;
  }

  List<GovernanceForecastSignal> governanceForecastSignals({DateTime? now}) {
    final t = governanceTrends(now: now);
    GovernanceForecastSignal build(String metric, int current, int previous) {
      final direction = current > previous
          ? 'worsening'
          : (current < previous ? 'improving' : 'stable');
      return GovernanceForecastSignal(
        metric: metric,
        currentDelta: current,
        previousDelta: previous,
        direction: direction,
      );
    }

    return <GovernanceForecastSignal>[
      build('Blocked', t.currentBlocked, t.previousBlocked),
      build('Escalations', t.currentEscalations, t.previousEscalations),
      build(
        'Overdue Approvals',
        t.currentOverdueApprovals,
        t.previousOverdueApprovals,
      ),
    ];
  }

  GovernanceIncidentSummary incidentSummary({
    required String transactionType,
    required String transactionId,
  }) {
    final trace = traceForTransaction(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    var blocked = 0;
    var escalated = 0;
    for (final e in trace) {
      if (e.event is WorkflowBlockedEvent) blocked++;
      if (e.event is ApprovalEscalatedEvent) escalated++;
    }
    final latest = latestBlockedEvent(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final status = incidentStatusFor(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    return GovernanceIncidentSummary(
      transactionType: transactionType,
      transactionId: transactionId,
      totalEvents: trace.length,
      blockedCount: blocked,
      escalationCount: escalated,
      status: status,
      latestReason: latest?.reason,
      latestRuleCode: latest?.ruleCode,
      latestPermission: latest?.permissionUsed,
    );
  }

  List<BranchGovernanceRanking> branchGovernanceRanking() {
    final intel = branchGovernanceIntelligence();
    final ranking = intel
        .map((x) {
          final band = x.governanceHealthScore < 50
              ? 'critical'
              : (x.governanceHealthScore < 70 ? 'warning' : 'healthy');
          return BranchGovernanceRanking(
            branchId: x.branchId,
            score: x.governanceHealthScore,
            riskBand: band,
            slaBreachRatio: x.slaBreachRatio,
            escalationDensity: x.escalationDensity,
          );
        })
        .toList(growable: false);
    ranking.sort((a, b) => a.score.compareTo(b.score));
    return ranking;
  }

  List<PolicyFrictionMetric> incidentRcaTopBlockers({
    required String transactionType,
    required String transactionId,
    int limit = 3,
  }) {
    final trace = traceForTransaction(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final counts = <String, int>{};
    for (final e in trace) {
      final event = e.event;
      if (event is! WorkflowBlockedEvent) continue;
      final rule = event.ruleCode ?? 'unknown';
      final perm = event.permissionUsed ?? 'unknown';
      final key = '$rule|$perm';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final list = counts.entries
        .map((x) {
          final p = x.key.split('|');
          return PolicyFrictionMetric(
            ruleCode: p.first,
            permissionKey: p.length > 1 ? p[1] : 'unknown',
            count: x.value,
          );
        })
        .toList(growable: false);
    list.sort((a, b) => b.count.compareTo(a.count));
    if (list.length <= limit) return list;
    return list.sublist(0, limit);
  }

  GovernanceOperationsCenterSnapshot operationsCenterSnapshot() {
    final ranking = branchGovernanceRanking();
    final intel = branchGovernanceIntelligence();
    final escalationHotspots = ranking
        .where((r) => r.escalationDensity >= 0.30)
        .length;
    final slaHotspots = ranking.where((r) => r.slaBreachRatio >= 0.25).length;
    final unstable = ranking.where((r) => r.score < 70).length;
    final blockedHotspots = intel
        .where((x) => x.blockedTransitions >= 3)
        .length;

    return GovernanceOperationsCenterSnapshot(
      escalationHotspots: escalationHotspots,
      slaBreachHotspots: slaHotspots,
      blockedHotspots: blockedHotspots,
      unstableBranches: unstable,
    );
  }

  GovernanceEvidencePack incidentEvidencePack({
    required String transactionType,
    required String transactionId,
  }) {
    final summary = incidentSummary(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final blockers = incidentRcaTopBlockers(
      transactionType: transactionType,
      transactionId: transactionId,
      limit: 5,
    );
    return GovernanceEvidencePack(
      transactionType: transactionType,
      transactionId: transactionId,
      totalEvents: summary.totalEvents,
      latestRuleCode: summary.latestRuleCode,
      latestPermission: summary.latestPermission,
      latestReason: summary.latestReason,
      topBlockers: blockers
          .map((b) => '${b.ruleCode}|${b.permissionKey}|${b.count}')
          .toList(growable: false),
    );
  }

  List<GovernanceReplayStep> incidentReplayTimeline({
    required String transactionType,
    required String transactionId,
  }) {
    final trace = traceForTransaction(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final replay = <GovernanceReplayStep>[];
    for (final envelope in trace) {
      final event = envelope.event;
      replay.add(
        GovernanceReplayStep(
          at: event.occurredAt,
          eventType: event.eventType,
          detail: _eventDetail(event),
        ),
      );
    }
    replay.sort((a, b) => a.at.compareTo(b.at));
    return replay;
  }

  String incidentEvidenceExportJson({
    required String transactionType,
    required String transactionId,
  }) {
    final summary = incidentSummary(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final pack = incidentEvidencePack(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final replay = incidentReplayTimeline(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final payload = <String, dynamic>{
      'transaction_type': summary.transactionType,
      'transaction_id': summary.transactionId,
      'total_events': summary.totalEvents,
      'blocked_count': summary.blockedCount,
      'escalation_count': summary.escalationCount,
      'status': summary.status.label,
      'latest_reason': summary.latestReason,
      'latest_rule_code': summary.latestRuleCode,
      'latest_permission': summary.latestPermission,
      'top_blockers': pack.topBlockers,
      'replay': replay
          .map(
            (r) => <String, dynamic>{
              'at': r.at.toIso8601String(),
              'event_type': r.eventType,
              'detail': r.detail,
            },
          )
          .toList(growable: false),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String incidentHandoffBundleJson({
    required String transactionType,
    required String transactionId,
  }) {
    final summary = incidentSummary(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final assignment = incidentAssignment(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final notes = incidentNotes(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final assignmentHistory = incidentAssignmentHistory(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final snapshots = investigationSnapshots(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    final payload = <String, dynamic>{
      'transaction_type': transactionType,
      'transaction_id': transactionId,
      'status': summary.status.label,
      'assignment': <String, dynamic>{
        'assigned_operator': assignment?.assignedOperator,
        'branch_lead': assignment?.branchLead,
        'escalation_owner': assignment?.escalationOwner,
        'investigation_assignee': assignment?.investigationAssignee,
        'watchers': assignment?.watcherList ?? const <String>[],
      },
      'assignment_history': assignmentHistory,
      'notes': notes,
      'snapshots': snapshots
          .map(
            (s) => <String, dynamic>{
              'label': s.label,
              'replay_filter': s.replayFilter,
              'only_critical': s.onlyCritical,
              'created_at': s.createdAt.toIso8601String(),
            },
          )
          .toList(growable: false),
      'evidence': jsonDecode(
        incidentEvidenceExportJson(
          transactionType: transactionType,
          transactionId: transactionId,
        ),
      ),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _eventDetail(DomainEvent event) {
    if (event is TransactionTransitionedEvent) {
      return '${event.fromStatus} -> ${event.toStatus}';
    }
    if (event is WorkflowBlockedEvent) {
      return 'blocked:${event.ruleCode ?? '-'}:${event.reason}';
    }
    if (event is ApprovalQueuedEvent) {
      return 'queue:${event.queueId}:sla=${event.sla?.inHours ?? '-'}h';
    }
    if (event is ApprovalEscalatedEvent) {
      return 'escalated:L${event.level}:overdue=${event.overdueHours ?? '-'}h';
    }
    if (event is InventoryFreezeViolationEvent) {
      return 'freeze_violation:${event.reason}';
    }
    if (event is GovernanceIncidentStatusChangedEvent) {
      return 'incident_status:${event.fromStatus}->${event.toStatus}:${event.reason}';
    }
    return event.eventType;
  }

  List<GovernanceIncidentSummary> incidentAlerts({
    int limit = 10,
    Set<GovernanceIncidentStatus>? statuses,
  }) {
    final seen = <String>{};
    final alerts = <GovernanceIncidentSummary>[];
    for (var i = _events.length - 1; i >= 0; i--) {
      final event = _events[i].event;
      if (event is! WorkflowBlockedEvent) continue;
      final key = '${event.transactionType}|${event.transactionId}';
      if (_resolvedIncidents.contains(key)) continue;
      if (_archivedIncidents.contains(key)) continue;
      if (seen.contains(key)) continue;
      seen.add(key);
      final summary = incidentSummary(
        transactionType: event.transactionType,
        transactionId: event.transactionId,
      );
      if (statuses != null && !statuses.contains(summary.status)) continue;
      if (summary.blockedCount > 0 || summary.escalationCount > 0) {
        alerts.add(summary);
      }
      if (alerts.length >= limit) break;
    }
    return alerts;
  }

  void setLastInvestigationContext({
    required String transactionType,
    required String transactionId,
  }) {
    _lastInvestigationType = transactionType.trim();
    _lastInvestigationId = transactionId.trim();
    notifyListeners();
  }

  void setLastInvestigationViewState({
    required String replayFilter,
    required bool onlyCritical,
  }) {
    _lastInvestigationReplayFilter = replayFilter.trim();
    _lastInvestigationOnlyCritical = onlyCritical;
    notifyListeners();
  }

  void saveMissionStatusPreset(Set<GovernanceIncidentStatus> statuses) {
    if (statuses.isEmpty) return;
    _missionStatusPreset = Set<GovernanceIncidentStatus>.from(statuses);
    notifyListeners();
  }

  void saveOpsStatusPreset(Set<GovernanceIncidentStatus> statuses) {
    if (statuses.isEmpty) return;
    _opsStatusPreset = Set<GovernanceIncidentStatus>.from(statuses);
    notifyListeners();
  }

  void saveLogsStatusPreset(GovernanceIncidentStatus status) {
    _logsStatusPreset = status;
    notifyListeners();
  }

  bool isIncidentResolved({
    required String transactionType,
    required String transactionId,
  }) {
    return _resolvedIncidents.contains('$transactionType|$transactionId');
  }

  void resolveIncident({
    required String transactionType,
    required String transactionId,
  }) {
    setIncidentStatus(
      transactionType: transactionType,
      transactionId: transactionId,
      toStatus: GovernanceIncidentStatus.resolved,
      reason: 'Operator marked resolved',
      notify: false,
    );
    _resolvedIncidents.add('$transactionType|$transactionId');
    notifyListeners();
  }

  bool isIncidentArchived({
    required String transactionType,
    required String transactionId,
  }) {
    return _archivedIncidents.contains('$transactionType|$transactionId');
  }

  void archiveIncident({
    required String transactionType,
    required String transactionId,
  }) {
    setIncidentStatus(
      transactionType: transactionType,
      transactionId: transactionId,
      toStatus: GovernanceIncidentStatus.archived,
      reason: 'Operator archived resolved incident',
      notify: false,
    );
    _archivedIncidents.add('$transactionType|$transactionId');
    notifyListeners();
  }

  GovernanceIncidentStatus incidentStatusFor({
    required String transactionType,
    required String transactionId,
  }) {
    final key = '$transactionType|$transactionId';
    final existing = _incidentStatuses[key];
    if (existing != null) return existing;
    if (_archivedIncidents.contains(key))
      return GovernanceIncidentStatus.archived;
    if (_resolvedIncidents.contains(key))
      return GovernanceIncidentStatus.resolved;
    final hasEscalation = _events.any((envelope) {
      final event = envelope.event;
      return event is ApprovalEscalatedEvent &&
          event.transactionType == transactionType &&
          event.transactionId == transactionId;
    });
    if (hasEscalation) return GovernanceIncidentStatus.escalated;
    return GovernanceIncidentStatus.active;
  }

  void startInvestigating({
    required String transactionType,
    required String transactionId,
  }) {
    setIncidentStatus(
      transactionType: transactionType,
      transactionId: transactionId,
      toStatus: GovernanceIncidentStatus.investigating,
      reason: 'Operator opened investigation workspace',
    );
  }

  void markIncidentEscalated({
    required String transactionType,
    required String transactionId,
  }) {
    setIncidentStatus(
      transactionType: transactionType,
      transactionId: transactionId,
      toStatus: GovernanceIncidentStatus.escalated,
      reason: 'Escalation pressure detected or assigned',
    );
  }

  void setIncidentStatus({
    required String transactionType,
    required String transactionId,
    required GovernanceIncidentStatus toStatus,
    required String reason,
    bool notify = true,
  }) {
    final key = '$transactionType|$transactionId';
    final previous = incidentStatusFor(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    if (previous == toStatus) return;
    _incidentStatuses[key] = toStatus;
    _events.add(
      DomainEventEnvelope(
        eventId:
            'incident-status-$key-${DateTime.now().microsecondsSinceEpoch}',
        correlationId: 'incident-status-$key',
        event: GovernanceIncidentStatusChangedEvent(
          occurredAt: DateTime.now(),
          transactionType: transactionType,
          transactionId: transactionId,
          fromStatus: previous.label,
          toStatus: toStatus.label,
          reason: reason,
        ),
      ),
    );
    if (_events.length > 500) {
      _events.removeRange(0, _events.length - 500);
    }
    if (notify) notifyListeners();
  }

  Map<GovernanceIncidentStatus, int> incidentStatusPipelineCounts() {
    final counts = <GovernanceIncidentStatus, int>{
      GovernanceIncidentStatus.active: 0,
      GovernanceIncidentStatus.investigating: 0,
      GovernanceIncidentStatus.escalated: 0,
      GovernanceIncidentStatus.resolved: 0,
      GovernanceIncidentStatus.archived: 0,
    };
    final seen = <String>{};
    for (var i = _events.length - 1; i >= 0; i--) {
      final event = _events[i].event;
      if (event is! WorkflowBlockedEvent) continue;
      final key = '${event.transactionType}|${event.transactionId}';
      if (seen.contains(key)) continue;
      seen.add(key);
      final status = incidentStatusFor(
        transactionType: event.transactionType,
        transactionId: event.transactionId,
      );
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  GovernanceIncidentAssignment? incidentAssignment({
    required String transactionType,
    required String transactionId,
  }) {
    return _incidentAssignments['$transactionType|$transactionId'];
  }

  void setIncidentAssignment({
    required String transactionType,
    required String transactionId,
    String? assignedOperator,
    String? branchLead,
    String? escalationOwner,
    String? investigationAssignee,
    List<String>? watcherList,
    String? transferReason,
  }) {
    final key = '$transactionType|$transactionId';
    final previous = _incidentAssignments[key];
    final nextAssignee = investigationAssignee?.trim().isEmpty == true
        ? null
        : investigationAssignee?.trim();
    final normalizedWatchers = _normalizeWatchers(watcherList);
    _incidentAssignments[key] = GovernanceIncidentAssignment(
      assignedOperator: assignedOperator?.trim().isEmpty == true
          ? null
          : assignedOperator?.trim(),
      branchLead: branchLead?.trim().isEmpty == true
          ? null
          : branchLead?.trim(),
      escalationOwner: escalationOwner?.trim().isEmpty == true
          ? null
          : escalationOwner?.trim(),
      investigationAssignee: nextAssignee,
      watcherList: normalizedWatchers,
      updatedAt: DateTime.now(),
    );
    if (previous?.investigationAssignee != nextAssignee) {
      final history = _incidentAssignmentHistory.putIfAbsent(
        key,
        () => <String>[],
      );
      history.add(
        '${DateTime.now().toIso8601String()} | '
        '${previous?.investigationAssignee ?? '-'} -> ${nextAssignee ?? '-'}'
        '${transferReason?.trim().isNotEmpty == true ? ' | ${transferReason!.trim()}' : ''}',
      );
      if (history.length > 25) {
        history.removeRange(0, history.length - 25);
      }
    }
    notifyListeners();
  }

  List<String> incidentAssignmentHistory({
    required String transactionType,
    required String transactionId,
  }) {
    return List<String>.unmodifiable(
      _incidentAssignmentHistory['$transactionType|$transactionId'] ??
          const <String>[],
    );
  }

  List<String> incidentNotes({
    required String transactionType,
    required String transactionId,
  }) {
    return List<String>.unmodifiable(
      _incidentNotes['$transactionType|$transactionId'] ?? const <String>[],
    );
  }

  void addIncidentNote({
    required String transactionType,
    required String transactionId,
    required String note,
  }) {
    final normalized = note.trim();
    if (normalized.isEmpty) return;
    final key = '$transactionType|$transactionId';
    final notes = _incidentNotes.putIfAbsent(key, () => <String>[]);
    notes.add('${DateTime.now().toIso8601String()} | $normalized');
    if (notes.length > 25) {
      notes.removeRange(0, notes.length - 25);
    }
    notifyListeners();
  }

  List<GovernanceInvestigationSnapshot> investigationSnapshots({
    required String transactionType,
    required String transactionId,
  }) {
    final key = '$transactionType|$transactionId';
    final snapshots = _investigationSnapshots[key] ?? const [];
    return List<GovernanceInvestigationSnapshot>.unmodifiable(snapshots);
  }

  void saveInvestigationSnapshot({
    required String transactionType,
    required String transactionId,
    required String label,
  }) {
    final key = '$transactionType|$transactionId';
    final snapshots = _investigationSnapshots.putIfAbsent(
      key,
      () => <GovernanceInvestigationSnapshot>[],
    );
    snapshots.add(
      GovernanceInvestigationSnapshot(
        transactionType: transactionType,
        transactionId: transactionId,
        label: label.trim().isEmpty ? 'Snapshot' : label.trim(),
        replayFilter: _lastInvestigationReplayFilter,
        onlyCritical: _lastInvestigationOnlyCritical,
        createdAt: DateTime.now(),
      ),
    );
    if (snapshots.length > 10) {
      snapshots.removeRange(0, snapshots.length - 10);
    }
    notifyListeners();
  }

  bool applyInvestigationSnapshot({
    required String transactionType,
    required String transactionId,
    required DateTime createdAt,
  }) {
    final snapshots = investigationSnapshots(
      transactionType: transactionType,
      transactionId: transactionId,
    );
    GovernanceInvestigationSnapshot? target;
    for (final snapshot in snapshots) {
      if (snapshot.createdAt == createdAt) {
        target = snapshot;
        break;
      }
    }
    if (target == null) {
      return false;
    }
    _lastInvestigationType = transactionType.trim();
    _lastInvestigationId = transactionId.trim();
    _lastInvestigationReplayFilter = target.replayFilter.trim();
    _lastInvestigationOnlyCritical = target.onlyCritical;
    notifyListeners();
    return true;
  }

  List<String> _normalizeWatchers(List<String>? watcherList) {
    if (watcherList == null) {
      return const <String>[];
    }
    final out = <String>[];
    final seen = <String>{};
    for (final raw in watcherList) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(value);
    }
    return out;
  }

  void restoreIncidentToActive({
    required String transactionType,
    required String transactionId,
  }) {
    final key = '$transactionType|$transactionId';
    _resolvedIncidents.remove(key);
    _archivedIncidents.remove(key);
    setIncidentStatus(
      transactionType: transactionType,
      transactionId: transactionId,
      toStatus: GovernanceIncidentStatus.active,
      reason: 'Incident restored to active lifecycle',
      notify: false,
    );
    notifyListeners();
  }

  int evaluateApprovalEscalations({DateTime? now}) {
    final decisions = ApprovalEscalationEngine.evaluate(
      queue: _approvalQueue,
      previousEscalations: _escalationLevels,
      now: now,
    );
    for (final decision in decisions) {
      ApprovalEscalationEngine.emit(decision);
    }
    return decisions.length;
  }

  void _upsertApprovalQueue(ApprovalQueueItem item) {
    final index = _approvalQueue.indexWhere((q) => q.queueId == item.queueId);
    if (index == -1) {
      _approvalQueue.add(item);
    } else {
      _approvalQueue[index] = item;
    }
  }

  GovernanceDashboardSnapshot dashboardSnapshot({DateTime? now}) {
    final telemetry = _deriveTelemetry();
    return GovernanceDashboardService.build(
      approvalQueue: _approvalQueue,
      telemetry: <TransitionTelemetryCounter>[telemetry],
      freezeViolations: _freezeViolations,
      reopenSignals: _countReopens(),
      escalatedApprovals: _escalatedApprovals,
      now: now,
    );
  }

  TransitionTelemetryCounter _deriveTelemetry() {
    var blocked = 0;
    var reversed = 0;
    var highRisk = 0;

    for (final envelope in _events) {
      final event = envelope.event;
      if (event is WorkflowBlockedEvent) {
        blocked += 1;
      }
      if (event is TransactionTransitionedEvent) {
        final to = event.toStatus.trim().toLowerCase();
        final from = event.fromStatus.trim().toLowerCase();
        if (to == 'voided' || to == 'cancelled' || to == 'reopened') {
          reversed += 1;
        }
        if (to == 'approved' || to == 'confirmed' || from == 'approved') {
          highRisk += 1;
        }
      }
    }

    return TransitionTelemetryCounter(
      blocked: blocked,
      reversed: reversed,
      highRisk: highRisk,
    );
  }

  int _countReopens() {
    var reopenSignals = 0;
    for (final envelope in _events) {
      final event = envelope.event;
      if (event is TransactionTransitionedEvent &&
          event.toStatus.trim().toLowerCase() == 'reopened') {
        reopenSignals += 1;
      }
    }
    return reopenSignals;
  }
}
