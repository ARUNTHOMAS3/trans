class TransitionGovernanceContext {
  final bool isFinancialPeriodLocked;
  final bool isInventoryFrozen;
  final bool isBranchClosed;
  final double? transactionAmount;
  final bool approvalOverride;
  final DateTime? pendingSince;
  final DateTime? now;

  const TransitionGovernanceContext({
    this.isFinancialPeriodLocked = false,
    this.isInventoryFrozen = false,
    this.isBranchClosed = false,
    this.transactionAmount,
    this.approvalOverride = false,
    this.pendingSince,
    this.now,
  });
}
