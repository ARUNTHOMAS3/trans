import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/workflow/workflow_runtime_store.dart';

import 'domain_event_dispatcher.dart';
import 'domain_event_envelope.dart';
import 'domain_events.dart';
import 'notification_policy.dart';

class DomainEventHandlers {
  DomainEventHandlers._();
  static bool _registered = false;

  static void registerDefaults() {
    if (_registered) return;
    DomainEventDispatcher.register(
      'transaction.transitioned',
      _auditAndTelemetryHook,
    );
    DomainEventDispatcher.register('approval.queued', _approvalQueueHook);
    DomainEventDispatcher.register('approval.escalated', _approvalEscalatedHook);
    DomainEventDispatcher.register(
      'workflow.blocked',
      _workflowBlockedNotificationHook,
    );
    DomainEventDispatcher.register(
      'inventory.freeze_violation',
      _inventoryFreezeViolationHook,
    );
    _registered = true;
  }

  static void _auditAndTelemetryHook(DomainEventEnvelope envelope) {
    WorkflowRuntimeStore.instance.recordEvent(envelope);
    _runIsolated('transaction.transitioned', () {
      final e = envelope.event as TransactionTransitionedEvent;
      AppLogger.info(
        'Domain event: transaction transitioned',
        module: 'workflow_domain_events',
        data: <String, dynamic>{
          'event_id': envelope.eventId,
          'correlation_id': envelope.correlationId,
          'event_type': e.eventType,
          'transaction_type': e.transactionType,
          'transaction_id': e.transactionId,
          'from_status': e.fromStatus,
          'to_status': e.toStatus,
          'allowed': e.allowed,
          'reason': e.reason,
          'branch_id': e.branchId,
          'warehouse_id': e.warehouseId,
          'actor_id': e.actorId,
          'actor_name': e.actorName,
          'permission_used': e.permissionUsed,
          'rule_code': e.explainability['rule_code'],
        },
      );
    });
  }

  static void _approvalQueueHook(DomainEventEnvelope envelope) {
    WorkflowRuntimeStore.instance.recordEvent(envelope);
    _runIsolated('approval.queued', () {
      final e = envelope.event as ApprovalQueuedEvent;
      AppLogger.info(
        'Domain event: approval queued',
        module: 'workflow_domain_events',
        data: <String, dynamic>{
          'event_id': envelope.eventId,
          'correlation_id': envelope.correlationId,
          'event_type': e.eventType,
          'queue_id': e.queueId,
          'transaction_type': e.transactionType,
          'transaction_id': e.transactionId,
          'status': e.status,
          'pending_since': e.pendingSince.toIso8601String(),
          'is_overdue': e.isOverdue,
          'sla_ms': e.sla?.inMilliseconds,
        },
      );
      _dispatchNotificationPolicy(e.eventType, envelope);
    });
  }

  static void _workflowBlockedNotificationHook(DomainEventEnvelope envelope) {
    WorkflowRuntimeStore.instance.recordEvent(envelope);
    _runIsolated('workflow.blocked', () {
      final e = envelope.event as WorkflowBlockedEvent;
      AppLogger.warning(
        'Domain event: workflow blocked',
        module: 'workflow_domain_events',
        data: <String, dynamic>{
          'event_id': envelope.eventId,
          'correlation_id': envelope.correlationId,
          'event_type': e.eventType,
          'transaction_type': e.transactionType,
          'transaction_id': e.transactionId,
          'from_status': e.fromStatus,
          'to_status': e.toStatus,
          'reason': e.reason,
        },
      );
      _dispatchNotificationPolicy(e.eventType, envelope);
    });
  }

  static void _approvalEscalatedHook(DomainEventEnvelope envelope) {
    WorkflowRuntimeStore.instance.recordEvent(envelope);
    _runIsolated('approval.escalated', () {
      final e = envelope.event as ApprovalEscalatedEvent;
      AppLogger.warning(
        'Domain event: approval escalated',
        module: 'workflow_domain_events',
        data: <String, dynamic>{
          'event_id': envelope.eventId,
          'correlation_id': envelope.correlationId,
          'event_type': e.eventType,
          'queue_id': e.queueId,
          'transaction_type': e.transactionType,
          'transaction_id': e.transactionId,
          'level': e.level,
          'reason': e.reason,
          'sla_ms': e.sla?.inMilliseconds,
          'overdue_hours': e.overdueHours,
          'branch_id': e.branchId,
          'warehouse_id': e.warehouseId,
        },
      );
      _dispatchNotificationPolicy(e.eventType, envelope);
    });
  }

  static void _inventoryFreezeViolationHook(DomainEventEnvelope envelope) {
    WorkflowRuntimeStore.instance.recordEvent(envelope);
    _runIsolated('inventory.freeze_violation', () {
      final e = envelope.event as InventoryFreezeViolationEvent;
      AppLogger.warning(
        'Domain event: inventory freeze violation',
        module: 'workflow_domain_events',
        data: <String, dynamic>{
          'event_id': envelope.eventId,
          'correlation_id': envelope.correlationId,
          'event_type': e.eventType,
          'transaction_type': e.transactionType,
          'transaction_id': e.transactionId,
          'reason': e.reason,
        },
      );
      _dispatchNotificationPolicy(e.eventType, envelope);
    });
  }

  static void _dispatchNotificationPolicy(
    String eventType,
    DomainEventEnvelope envelope,
  ) {
    final policy = resolveWorkflowNotificationPolicy(eventType);
    if (policy == null) return;
    AppLogger.info(
      'Notification policy evaluated',
      module: 'workflow_notification_policy',
      data: <String, dynamic>{
        'event_id': envelope.eventId,
        'correlation_id': envelope.correlationId,
        'event_type': eventType,
        'action_count': policy.actions.length,
        'actions': policy.actions
            .map((a) => '${a.channel}:${a.templateKey}:${a.severity}')
            .toList(growable: false),
      },
    );
  }

  static void _runIsolated(String scope, void Function() action) {
    try {
      action();
    } catch (error, st) {
      AppLogger.error(
        'Domain event handler failed',
        module: 'workflow_domain_events',
        error: error,
        stackTrace: st,
        data: <String, dynamic>{'scope': scope},
      );
    }
  }
}
