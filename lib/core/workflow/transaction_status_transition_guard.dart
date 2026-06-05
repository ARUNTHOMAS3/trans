import 'package:zerpai_erp/core/auth/capability_service.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';

import 'transaction_status_audit_event.dart';
import 'transition_telemetry.dart';
import 'transition_governance_context.dart';
import 'transaction_status_normalizer.dart';
import 'transaction_status_transition_matrix.dart';
import 'transaction_transition_definitions.dart';
import 'domain_event_dispatcher.dart';
import 'domain_events.dart';

class TransitionDecision {
  final bool allowed;
  final String reason;
  final String fromStatus;
  final String toStatus;
  final String requiredPermission;
  final String ruleCode;
  final Map<String, dynamic> explainability;

  const TransitionDecision({
    required this.allowed,
    required this.reason,
    required this.fromStatus,
    required this.toStatus,
    required this.requiredPermission,
    this.ruleCode = 'allowed',
    this.explainability = const <String, dynamic>{},
  });
}

class TransactionStatusTransitionGuard {
  const TransactionStatusTransitionGuard._();

  static TransitionDecision canTransition({
    required User? user,
    required String transactionType,
    required String fromStatus,
    required String toStatus,
    String? branchId,
    String? warehouseId,
    String? transactionId,
    String? requiredPermission,
    String? reason,
    bool enforcePermission = true,
    TransitionGovernanceContext governanceContext =
        const TransitionGovernanceContext(),
  }) {
    final from = normalizeTransactionStatus(fromStatus);
    final to = normalizeTransactionStatus(toStatus);
    final canonicalType = transactionType.trim().toLowerCase();
    final permissionKey =
        requiredPermission ?? '$canonicalType.status.transition';
    final definition = findTransitionDefinition(
      transactionType: canonicalType,
      from: from,
      to: to,
    );
    final effectivePermissionKey = definition?.permission ?? permissionKey;
    if (definition?.requiresReason == true &&
        (reason == null || reason.trim().isEmpty)) {
      final denied = TransitionDecision(
        allowed: false,
        reason: 'Reason is required for this transition.',
        fromStatus: from,
        toStatus: to,
        requiredPermission: effectivePermissionKey,
        ruleCode: 'reason_required',
      );
      _emitTelemetry(
        transactionId: transactionId,
        canonicalType: canonicalType,
        from: from,
        to: to,
        decision: denied,
        definition: definition,
        branchId: branchId,
        warehouseId: warehouseId,
        user: user,
      );
      return denied;
    }

    if (definition?.requiresLockCheck == true) {
      if (governanceContext.isBranchClosed) {
        final denied = TransitionDecision(
          allowed: false,
          reason: 'Branch is closed. Transition blocked.',
          fromStatus: from,
          toStatus: to,
          requiredPermission: effectivePermissionKey,
          ruleCode: 'branch_closed_lock',
        );
        _emitTelemetry(
          transactionId: transactionId,
          canonicalType: canonicalType,
          from: from,
          to: to,
          decision: denied,
          definition: definition,
          branchId: branchId,
          warehouseId: warehouseId,
          user: user,
        );
        return denied;
      }
      if ((definition?.affectsAccounting ?? false) &&
          governanceContext.isFinancialPeriodLocked) {
        final denied = TransitionDecision(
          allowed: false,
          reason: 'Financial period is locked. Transition blocked.',
          fromStatus: from,
          toStatus: to,
          requiredPermission: effectivePermissionKey,
          ruleCode: 'financial_lock',
        );
        _emitTelemetry(
          transactionId: transactionId,
          canonicalType: canonicalType,
          from: from,
          to: to,
          decision: denied,
          definition: definition,
          branchId: branchId,
          warehouseId: warehouseId,
          user: user,
        );
        return denied;
      }
      if ((definition?.affectsInventory ?? false) &&
          governanceContext.isInventoryFrozen) {
        final denied = TransitionDecision(
          allowed: false,
          reason: 'Inventory is frozen. Transition blocked.',
          fromStatus: from,
          toStatus: to,
          requiredPermission: effectivePermissionKey,
          ruleCode: 'inventory_freeze_lock',
        );
        _emitTelemetry(
          transactionId: transactionId,
          canonicalType: canonicalType,
          from: from,
          to: to,
          decision: denied,
          definition: definition,
          branchId: branchId,
          warehouseId: warehouseId,
          user: user,
        );
        return denied;
      }
    }

    final threshold = definition?.approvalThresholdAmount;
    if (threshold != null &&
        governanceContext.transactionAmount != null &&
        governanceContext.transactionAmount! > threshold &&
        !governanceContext.approvalOverride &&
        (to == 'approved' || to == 'confirmed')) {
      final denied = TransitionDecision(
        allowed: false,
        reason:
            'Approval threshold exceeded. Additional approval is required.',
        fromStatus: from,
        toStatus: to,
        requiredPermission: effectivePermissionKey,
        ruleCode: 'approval_threshold',
      );
      _emitTelemetry(
        transactionId: transactionId,
        canonicalType: canonicalType,
        from: from,
        to: to,
        decision: denied,
        definition: definition,
        branchId: branchId,
        warehouseId: warehouseId,
        user: user,
      );
      return denied;
    }

    if (from == to) {
      final noOp = TransitionDecision(
        allowed: true,
        reason: 'No-op transition.',
        fromStatus: from,
        toStatus: to,
        requiredPermission: effectivePermissionKey,
        ruleCode: 'noop',
      );
      _emitTelemetry(
        transactionId: transactionId,
        canonicalType: canonicalType,
        from: from,
        to: to,
        decision: noOp,
        definition: definition,
        branchId: branchId,
        warehouseId: warehouseId,
        user: user,
      );
      return noOp;
    }

    final allowedTargets = transactionStatusTransitions[from];
    if (allowedTargets == null || !allowedTargets.contains(to)) {
      final denied = TransitionDecision(
        allowed: false,
        reason: 'Transition is not allowed by workflow matrix.',
        fromStatus: from,
        toStatus: to,
        requiredPermission: effectivePermissionKey,
        ruleCode: 'matrix_denied',
      );
      _emitTelemetry(
        transactionId: transactionId,
        canonicalType: canonicalType,
        from: from,
        to: to,
        decision: denied,
        definition: definition,
        branchId: branchId,
        warehouseId: warehouseId,
        user: user,
      );
      return denied;
    }

    final hasPermission = !enforcePermission ||
        CapabilityService.canUser(
          user,
          effectivePermissionKey,
          branchId: branchId,
          warehouseId: warehouseId,
        );

    if (!hasPermission) {
      final denied = TransitionDecision(
        allowed: false,
        reason: 'User lacks transition permission.',
        fromStatus: from,
        toStatus: to,
        requiredPermission: effectivePermissionKey,
        ruleCode: 'permission_denied',
      );
      _emitTelemetry(
        transactionId: transactionId,
        canonicalType: canonicalType,
        from: from,
        to: to,
        decision: denied,
        definition: definition,
        branchId: branchId,
        warehouseId: warehouseId,
        user: user,
      );
      return denied;
    }

    final allowed = TransitionDecision(
      allowed: true,
      reason: 'Allowed by transition matrix and capability check.',
      fromStatus: from,
      toStatus: to,
      requiredPermission: effectivePermissionKey,
      ruleCode: 'allowed',
    );
    _emitTelemetry(
      transactionId: transactionId,
      canonicalType: canonicalType,
      from: from,
      to: to,
      decision: allowed,
      definition: definition,
      branchId: branchId,
      warehouseId: warehouseId,
      user: user,
    );
    return allowed;
  }

  static void _emitTelemetry({
    required String? transactionId,
    required String canonicalType,
    required String from,
    required String to,
    required TransitionDecision decision,
    required TransitionDefinition? definition,
    required String? branchId,
    required String? warehouseId,
    required User? user,
  }) {
    final id = transactionId?.trim() ?? '';
    if (id.isEmpty) return;
    final highRisk =
        (definition?.affectsAccounting ?? false) ||
        (definition?.affectsInventory ?? false);
    final reversed =
        (definition?.reversesAccounting ?? false) ||
        (definition?.reversesInventory ?? false);
    TransitionTelemetryEmitter.emit(
      TransitionTelemetryEvent(
        transactionType: canonicalType,
        transactionId: id,
        fromStatus: from,
        toStatus: to,
        allowed: decision.allowed,
        reason: decision.reason,
        highRisk: highRisk,
        reversed: reversed,
        timestamp: DateTime.now(),
        branchId: branchId,
        warehouseId: warehouseId,
      ),
    );
    DomainEventDispatcher.dispatch(
      TransactionTransitionedEvent(
        occurredAt: DateTime.now(),
        transactionType: canonicalType,
        transactionId: id,
        fromStatus: from,
        toStatus: to,
        allowed: decision.allowed,
        reason: decision.reason,
        branchId: branchId,
        warehouseId: warehouseId,
        actorId: user?.id,
        actorName: user?.fullName,
        permissionUsed: decision.requiredPermission,
        explainability: <String, dynamic>{
          'rule_code': decision.ruleCode,
          'decision_reason': decision.reason,
          'required_permission': decision.requiredPermission,
        },
      ),
    );
    if (!decision.allowed) {
      DomainEventDispatcher.dispatch(
        WorkflowBlockedEvent(
          occurredAt: DateTime.now(),
          transactionType: canonicalType,
          transactionId: id,
          fromStatus: from,
          toStatus: to,
          reason: decision.reason,
          branchId: branchId,
          warehouseId: warehouseId,
          actorId: user?.id,
          actorName: user?.fullName,
          permissionUsed: decision.requiredPermission,
          ruleCode: decision.ruleCode,
          explainability: <String, dynamic>{
            'rule_code': decision.ruleCode,
            'decision_reason': decision.reason,
            'required_permission': decision.requiredPermission,
            'from': from,
            'to': to,
          },
        ),
      );
    }
  }

  static TransactionStatusAuditEvent buildAuditEvent({
    required String transactionType,
    required String transactionId,
    required String beforeStatus,
    required String afterStatus,
    required User actor,
    required String reason,
    required String permissionUsed,
    String? branchId,
    String? warehouseId,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    return TransactionStatusAuditEvent(
      transactionType: transactionType,
      transactionId: transactionId,
      beforeStatus: normalizeTransactionStatus(beforeStatus),
      afterStatus: normalizeTransactionStatus(afterStatus),
      actorId: actor.id,
      actorName: actor.fullName,
      reason: reason,
      permissionUsed: permissionUsed,
      timestamp: DateTime.now(),
      branchId: branchId,
      warehouseId: warehouseId,
      metadata: metadata,
    );
  }
}
