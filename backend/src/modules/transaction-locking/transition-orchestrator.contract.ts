export type TransitionLockContext = {
  isFinancialPeriodLocked?: boolean;
  isInventoryFrozen?: boolean;
  isBranchClosed?: boolean;
};

export type TransitionSideEffectMetadata = {
  affectsInventory: boolean;
  affectsAccounting: boolean;
  createsLedgerEntries: boolean;
  requiresStockValidation: boolean;
  requiresLockCheck: boolean;
  approvalThresholdAmount?: number;
  maxPendingDurationMs?: number;
  staleAfterDurationMs?: number;
};

export type TransitionRequest = {
  transactionType: string;
  transactionId: string;
  fromStatus: string;
  toStatus: string;
  actorId: string;
  reason?: string;
  branchId?: string;
  warehouseId?: string;
  amount?: number;
  lockContext?: TransitionLockContext;
  sideEffects?: Partial<TransitionSideEffectMetadata>;
};

export type TransitionDecision = {
  allowed: boolean;
  reason?: string;
  requiredPermission?: string;
};

export type ApprovalQueueRecord = {
  queueId: string;
  transactionType: string;
  transactionId: string;
  status: string;
  pendingSince: string;
  branchId?: string;
  warehouseId?: string;
  requestedBy?: string;
  slaMs?: number;
  isOverdue?: boolean;
};

export type TransitionTelemetryRecord = {
  transactionType: string;
  transactionId: string;
  fromStatus: string;
  toStatus: string;
  allowed: boolean;
  reason: string;
  highRisk?: boolean;
  reversed?: boolean;
  timestamp: string;
  branchId?: string;
  warehouseId?: string;
};

/**
 * Batch L incremental backend centralization path:
 * - keep existing module endpoints
 * - progressively route status mutations through one orchestrator contract
 * - enforce lock/sla/threshold/side-effect policies in one place
 */
