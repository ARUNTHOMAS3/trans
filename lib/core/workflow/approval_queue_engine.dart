import 'transaction_transition_definitions.dart';
import 'domain_event_dispatcher.dart';
import 'domain_events.dart';

class ApprovalQueueItem {
  final String queueId;
  final String transactionType;
  final String transactionId;
  final String status;
  final String? branchId;
  final String? warehouseId;
  final String? requestedBy;
  final DateTime pendingSince;
  final Duration? sla;
  final bool isOverdue;

  const ApprovalQueueItem({
    required this.queueId,
    required this.transactionType,
    required this.transactionId,
    required this.status,
    required this.pendingSince,
    this.branchId,
    this.warehouseId,
    this.requestedBy,
    this.sla,
    this.isOverdue = false,
  });
}

class ApprovalQueueEngine {
  const ApprovalQueueEngine._();

  static Duration? _resolveSla(String transactionType) {
    for (final definition in transitionDefinitions) {
      if (definition.transactionType == transactionType &&
          definition.requiresApproval) {
        return definition.maxPendingDuration;
      }
    }
    return null;
  }

  static ApprovalQueueItem createPendingItem({
    required String queueId,
    required String transactionType,
    required String transactionId,
    required String status,
    required DateTime pendingSince,
    DateTime? now,
    String? branchId,
    String? warehouseId,
    String? requestedBy,
  }) {
    final sla = _resolveSla(transactionType);
    final resolvedNow = now ?? DateTime.now();
    final overdue = sla != null && resolvedNow.difference(pendingSince) > sla;
    final item = ApprovalQueueItem(
      queueId: queueId,
      transactionType: transactionType,
      transactionId: transactionId,
      status: status,
      pendingSince: pendingSince,
      branchId: branchId,
      warehouseId: warehouseId,
      requestedBy: requestedBy,
      sla: sla,
      isOverdue: overdue,
    );
    DomainEventDispatcher.dispatch(
      ApprovalQueuedEvent(
        occurredAt: resolvedNow,
        queueId: item.queueId,
        transactionType: item.transactionType,
        transactionId: item.transactionId,
        status: item.status,
        pendingSince: item.pendingSince,
        isOverdue: item.isOverdue,
        sla: item.sla,
        branchId: item.branchId,
        warehouseId: item.warehouseId,
      ),
    );
    return item;
  }
}
