import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/core/workflow/transaction_status_normalizer.dart';
import 'package:zerpai_erp/core/workflow/transaction_status_transition_guard.dart';
import 'package:zerpai_erp/core/workflow/transaction_transition_definitions.dart';
import 'package:zerpai_erp/core/workflow/transition_governance_context.dart';
import 'package:zerpai_erp/core/workflow/transaction_statuses.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';

User _user({
  String role = 'user',
  Map<String, dynamic>? permissions,
}) {
  final now = DateTime(2026, 1, 1);
  return User(
    id: 'u1',
    email: 'test@example.com',
    fullName: 'Test User',
    role: role,
    orgId: 'org-1',
    orgName: 'Org',
    orgSystemId: '0000000001',
    isActive: true,
    createdAt: now,
    updatedAt: now,
    permissions: permissions,
  );
}

void main() {
  group('normalizeTransactionStatus', () {
    test('normalizes mixed legacy values', () {
      expect(normalizeTransactionStatus('Draft'), TransactionStatuses.draft);
      expect(
        normalizeTransactionStatus('pending'),
        TransactionStatuses.pendingApproval,
      );
      expect(
        normalizeTransactionStatus('Approved'),
        TransactionStatuses.approved,
      );
      expect(
        normalizeTransactionStatus('canceled'),
        TransactionStatuses.cancelled,
      );
    });
  });

  group('TransactionStatusTransitionGuard', () {
    test('allows no-op transition', () {
      final decision = TransactionStatusTransitionGuard.canTransition(
        user: _user(),
        transactionType: 'sales.invoice',
        fromStatus: 'draft',
        toStatus: 'draft',
      );
      expect(decision.allowed, true);
    });

    test('denies non-matrix transition', () {
      final decision = TransactionStatusTransitionGuard.canTransition(
        user: _user(role: 'admin', permissions: const <String, dynamic>{}),
        transactionType: 'sales.invoice',
        fromStatus: 'draft',
        toStatus: 'voided',
      );
      expect(decision.allowed, false);
    });

    test('allows matrix transition for admin', () {
      final decision = TransactionStatusTransitionGuard.canTransition(
        user: _user(role: 'admin', permissions: const <String, dynamic>{}),
        transactionType: 'sales.invoice',
        fromStatus: 'draft',
        toStatus: 'pending_approval',
      );
      expect(decision.allowed, true);
    });

    test('requires reason for definition-marked transition', () {
      final denied = TransactionStatusTransitionGuard.canTransition(
        user: _user(role: 'admin', permissions: const <String, dynamic>{}),
        transactionType: 'sales.invoice',
        fromStatus: 'approved',
        toStatus: 'voided',
        reason: '',
      );
      expect(denied.allowed, false);

      final allowed = TransactionStatusTransitionGuard.canTransition(
        user: _user(role: 'admin', permissions: const <String, dynamic>{}),
        transactionType: 'sales.invoice',
        fromStatus: 'approved',
        toStatus: 'voided',
        reason: 'Incorrect tax application',
      );
      expect(allowed.allowed, true);
    });

    test('supports transfer draft -> initiated transition', () {
      final decision = TransactionStatusTransitionGuard.canTransition(
        user: _user(role: 'admin', permissions: const <String, dynamic>{}),
        transactionType: 'inventory.transfer',
        fromStatus: 'draft',
        toStatus: 'initiated',
      );
      expect(decision.allowed, true);
    });

    test('blocks accounting-affecting transitions on period lock', () {
      final decision = TransactionStatusTransitionGuard.canTransition(
        user: _user(role: 'admin', permissions: const <String, dynamic>{}),
        transactionType: 'purchases.bill',
        fromStatus: 'draft',
        toStatus: 'confirmed',
        governanceContext: const TransitionGovernanceContext(
          isFinancialPeriodLocked: true,
        ),
      );
      expect(decision.allowed, false);
    });

    test('blocks approved/confirmed transition on threshold without override', () {
      final decision = TransactionStatusTransitionGuard.canTransition(
        user: _user(role: 'admin', permissions: const <String, dynamic>{}),
        transactionType: 'inventory.adjustment',
        fromStatus: 'draft',
        toStatus: 'approved',
        governanceContext: const TransitionGovernanceContext(
          transactionAmount: 100000,
          approvalOverride: false,
        ),
      );
      expect(decision.allowed, false);
    });

    test('builds audit event with canonical statuses', () {
      final actor = _user();
      final event = TransactionStatusTransitionGuard.buildAuditEvent(
        transactionType: 'inventory.adjustment',
        transactionId: 'adj-1',
        beforeStatus: 'Draft',
        afterStatus: 'Approved',
        actor: actor,
        reason: 'Approved by manager',
        permissionUsed: 'inventory.adjustment.approve',
      );

      expect(event.beforeStatus, TransactionStatuses.draft);
      expect(event.afterStatus, TransactionStatuses.approved);
      expect(event.actorId, actor.id);
    });

    test('evaluates transition SLA metadata', () {
      final definition = findTransitionDefinition(
        transactionType: 'inventory.transfer',
        from: TransactionStatuses.draft,
        to: TransactionStatuses.initiated,
      );
      expect(definition, isNotNull);
      final breached = isTransitionSlaBreached(
        definition: definition!,
        pendingSince: DateTime(2026, 1, 1, 0, 0, 0),
        now: DateTime(2026, 1, 4, 0, 0, 1),
      );
      expect(breached, true);
    });
  });
}
