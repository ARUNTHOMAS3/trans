abstract class DomainEvent {
  final DateTime occurredAt;
  final String eventType;

  const DomainEvent({required this.occurredAt, required this.eventType});
}

class TransactionTransitionedEvent extends DomainEvent {
  final String transactionType;
  final String transactionId;
  final String fromStatus;
  final String toStatus;
  final bool allowed;
  final String reason;
  final String? branchId;
  final String? warehouseId;
  final String? actorId;
  final String? actorName;
  final String? permissionUsed;
  final Map<String, dynamic> explainability;

  const TransactionTransitionedEvent({
    required super.occurredAt,
    required this.transactionType,
    required this.transactionId,
    required this.fromStatus,
    required this.toStatus,
    required this.allowed,
    required this.reason,
    this.branchId,
    this.warehouseId,
    this.actorId,
    this.actorName,
    this.permissionUsed,
    this.explainability = const <String, dynamic>{},
  }) : super(eventType: 'transaction.transitioned');
}

class ApprovalQueuedEvent extends DomainEvent {
  final String queueId;
  final String transactionType;
  final String transactionId;
  final String status;
  final DateTime pendingSince;
  final bool isOverdue;
  final Duration? sla;
  final String? branchId;
  final String? warehouseId;

  const ApprovalQueuedEvent({
    required super.occurredAt,
    required this.queueId,
    required this.transactionType,
    required this.transactionId,
    required this.status,
    required this.pendingSince,
    required this.isOverdue,
    this.sla,
    this.branchId,
    this.warehouseId,
  }) : super(eventType: 'approval.queued');
}

class WorkflowBlockedEvent extends DomainEvent {
  final String transactionType;
  final String transactionId;
  final String fromStatus;
  final String toStatus;
  final String reason;
  final String? branchId;
  final String? warehouseId;
  final String? actorId;
  final String? actorName;
  final String? permissionUsed;
  final String? ruleCode;
  final Map<String, dynamic> explainability;

  const WorkflowBlockedEvent({
    required super.occurredAt,
    required this.transactionType,
    required this.transactionId,
    required this.fromStatus,
    required this.toStatus,
    required this.reason,
    this.branchId,
    this.warehouseId,
    this.actorId,
    this.actorName,
    this.permissionUsed,
    this.ruleCode,
    this.explainability = const <String, dynamic>{},
  }) : super(eventType: 'workflow.blocked');
}

class InventoryFreezeViolationEvent extends DomainEvent {
  final String transactionType;
  final String transactionId;
  final String reason;
  final String? branchId;
  final String? warehouseId;

  const InventoryFreezeViolationEvent({
    required super.occurredAt,
    required this.transactionType,
    required this.transactionId,
    required this.reason,
    this.branchId,
    this.warehouseId,
  }) : super(eventType: 'inventory.freeze_violation');
}

class ApprovalEscalatedEvent extends DomainEvent {
  final String queueId;
  final String transactionType;
  final String transactionId;
  final int level;
  final String reason;
  final Duration? sla;
  final int? overdueHours;
  final String? branchId;
  final String? warehouseId;

  const ApprovalEscalatedEvent({
    required super.occurredAt,
    required this.queueId,
    required this.transactionType,
    required this.transactionId,
    required this.level,
    required this.reason,
    this.sla,
    this.overdueHours,
    this.branchId,
    this.warehouseId,
  }) : super(eventType: 'approval.escalated');
}

class GovernanceIncidentStatusChangedEvent extends DomainEvent {
  final String transactionType;
  final String transactionId;
  final String fromStatus;
  final String toStatus;
  final String reason;

  const GovernanceIncidentStatusChangedEvent({
    required super.occurredAt,
    required this.transactionType,
    required this.transactionId,
    required this.fromStatus,
    required this.toStatus,
    required this.reason,
  }) : super(eventType: 'governance.incident_status_changed');
}
