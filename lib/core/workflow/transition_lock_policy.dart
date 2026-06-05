import 'transition_governance_context.dart';
import 'transaction_transition_definitions.dart';
import 'domain_event_dispatcher.dart';
import 'domain_events.dart';

class TransactionLockRecord {
  final String moduleName;
  final DateTime lockDate;
  final String? reason;

  const TransactionLockRecord({
    required this.moduleName,
    required this.lockDate,
    this.reason,
  });
}

class TransitionLockPolicy {
  const TransitionLockPolicy._();

  static bool _hasModuleLock(
    Iterable<TransactionLockRecord> locks,
    String moduleName,
  ) {
    for (final lock in locks) {
      if (lock.moduleName.trim().toLowerCase() == moduleName) return true;
    }
    return false;
  }

  static TransitionGovernanceContext buildGovernanceContext({
    required String transactionType,
    Iterable<TransactionLockRecord> locks = const <TransactionLockRecord>[],
    bool isBranchClosed = false,
    bool inventoryFreezeOverride = false,
    bool financialLockOverride = false,
    double? transactionAmount,
    bool approvalOverride = false,
    DateTime? pendingSince,
    DateTime? now,
  }) {
    final definition = transitionDefinitions
        .where((d) => d.transactionType == transactionType)
        .cast<TransitionDefinition?>()
        .firstWhere((d) => d != null, orElse: () => null);
    final affectsInventory = definition?.affectsInventory ?? false;
    final affectsAccounting = definition?.affectsAccounting ?? false;

    final inventoryLocked =
        affectsInventory &&
        !inventoryFreezeOverride &&
        (_hasModuleLock(locks, 'inventory') ||
            _hasModuleLock(locks, transactionType));
    final financialLocked =
        affectsAccounting &&
        !financialLockOverride &&
        (_hasModuleLock(locks, 'accounting') ||
            _hasModuleLock(locks, 'financial_period') ||
            _hasModuleLock(locks, transactionType));

    if (inventoryLocked) {
      DomainEventDispatcher.dispatch(
        InventoryFreezeViolationEvent(
          occurredAt: DateTime.now(),
          transactionType: transactionType,
          transactionId: 'context-evaluation',
          reason: 'Inventory lock active for transition context.',
        ),
      );
    }

    return TransitionGovernanceContext(
      isBranchClosed: isBranchClosed,
      isInventoryFrozen: inventoryLocked,
      isFinancialPeriodLocked: financialLocked,
      transactionAmount: transactionAmount,
      approvalOverride: approvalOverride,
      pendingSince: pendingSince,
      now: now,
    );
  }
}
