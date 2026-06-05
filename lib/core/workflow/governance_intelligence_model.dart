class BranchGovernanceIntelligence {
  final String branchId;
  final int governanceHealthScore;
  final int pendingApprovals;
  final int overdueApprovals;
  final int blockedTransitions;
  final int escalations;
  final int freezeViolations;
  final int reopens;
  final double approvalLatencyHours;
  final double slaBreachRatio;
  final double escalationDensity;

  const BranchGovernanceIntelligence({
    required this.branchId,
    required this.governanceHealthScore,
    required this.pendingApprovals,
    required this.overdueApprovals,
    required this.blockedTransitions,
    required this.escalations,
    required this.freezeViolations,
    required this.reopens,
    required this.approvalLatencyHours,
    required this.slaBreachRatio,
    required this.escalationDensity,
  });
}

