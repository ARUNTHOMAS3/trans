enum GovernanceIncidentStatus {
  active,
  investigating,
  escalated,
  resolved,
  archived,
}

extension GovernanceIncidentStatusLabel on GovernanceIncidentStatus {
  String get label {
    switch (this) {
      case GovernanceIncidentStatus.active:
        return 'Active';
      case GovernanceIncidentStatus.investigating:
        return 'Investigating';
      case GovernanceIncidentStatus.escalated:
        return 'Escalated';
      case GovernanceIncidentStatus.resolved:
        return 'Resolved';
      case GovernanceIncidentStatus.archived:
        return 'Archived';
    }
  }
}

class GovernanceTrendSnapshot {
  final int currentBlocked;
  final int previousBlocked;
  final int currentEscalations;
  final int previousEscalations;
  final int currentOverdueApprovals;
  final int previousOverdueApprovals;

  const GovernanceTrendSnapshot({
    required this.currentBlocked,
    required this.previousBlocked,
    required this.currentEscalations,
    required this.previousEscalations,
    required this.currentOverdueApprovals,
    required this.previousOverdueApprovals,
  });
}

class PolicyFrictionMetric {
  final String ruleCode;
  final String permissionKey;
  final int count;

  const PolicyFrictionMetric({
    required this.ruleCode,
    required this.permissionKey,
    required this.count,
  });
}

class GovernanceExecutiveSummary {
  final int totalBranches;
  final int unhealthyBranches;
  final int criticalBranches;
  final int totalEscalations;
  final int totalBlocked;

  const GovernanceExecutiveSummary({
    required this.totalBranches,
    required this.unhealthyBranches,
    required this.criticalBranches,
    required this.totalEscalations,
    required this.totalBlocked,
  });
}

class GovernanceHeatmapCell {
  final String branchId;
  final String metric;
  final double value;
  final String severity;

  const GovernanceHeatmapCell({
    required this.branchId,
    required this.metric,
    required this.value,
    required this.severity,
  });
}

class GovernanceForecastSignal {
  final String metric;
  final int currentDelta;
  final int previousDelta;
  final String direction;

  const GovernanceForecastSignal({
    required this.metric,
    required this.currentDelta,
    required this.previousDelta,
    required this.direction,
  });
}

class GovernanceIncidentSummary {
  final String transactionType;
  final String transactionId;
  final int totalEvents;
  final int blockedCount;
  final int escalationCount;
  final String? latestReason;
  final String? latestRuleCode;
  final String? latestPermission;
  final GovernanceIncidentStatus status;

  const GovernanceIncidentSummary({
    required this.transactionType,
    required this.transactionId,
    required this.totalEvents,
    required this.blockedCount,
    required this.escalationCount,
    required this.status,
    this.latestReason,
    this.latestRuleCode,
    this.latestPermission,
  });
}

class BranchGovernanceRanking {
  final String branchId;
  final int score;
  final String riskBand;
  final double slaBreachRatio;
  final double escalationDensity;

  const BranchGovernanceRanking({
    required this.branchId,
    required this.score,
    required this.riskBand,
    required this.slaBreachRatio,
    required this.escalationDensity,
  });
}

class GovernanceOperationsCenterSnapshot {
  final int escalationHotspots;
  final int slaBreachHotspots;
  final int blockedHotspots;
  final int unstableBranches;

  const GovernanceOperationsCenterSnapshot({
    required this.escalationHotspots,
    required this.slaBreachHotspots,
    required this.blockedHotspots,
    required this.unstableBranches,
  });
}

class GovernanceEvidencePack {
  final String transactionType;
  final String transactionId;
  final int totalEvents;
  final String? latestRuleCode;
  final String? latestPermission;
  final String? latestReason;
  final List<String> topBlockers;

  const GovernanceEvidencePack({
    required this.transactionType,
    required this.transactionId,
    required this.totalEvents,
    this.latestRuleCode,
    this.latestPermission,
    this.latestReason,
    this.topBlockers = const <String>[],
  });
}

class GovernanceReplayStep {
  final DateTime at;
  final String eventType;
  final String detail;

  const GovernanceReplayStep({
    required this.at,
    required this.eventType,
    required this.detail,
  });
}

class GovernanceIncidentAssignment {
  final String? assignedOperator;
  final String? branchLead;
  final String? escalationOwner;
  final String? investigationAssignee;
  final List<String> watcherList;
  final DateTime updatedAt;

  const GovernanceIncidentAssignment({
    this.assignedOperator,
    this.branchLead,
    this.escalationOwner,
    this.investigationAssignee,
    this.watcherList = const <String>[],
    required this.updatedAt,
  });
}

class GovernanceInvestigationSnapshot {
  final String transactionType;
  final String transactionId;
  final String label;
  final String replayFilter;
  final bool onlyCritical;
  final DateTime createdAt;

  const GovernanceInvestigationSnapshot({
    required this.transactionType,
    required this.transactionId,
    required this.label,
    required this.replayFilter,
    required this.onlyCritical,
    required this.createdAt,
  });
}
