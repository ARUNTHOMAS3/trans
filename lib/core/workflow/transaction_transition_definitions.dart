import 'transaction_statuses.dart';

class TransitionDefinition {
  final String transactionType;
  final String from;
  final String to;
  final String permission;
  final bool requiresReason;
  final bool requiresApproval;
  final bool reversesInventory;
  final bool reversesAccounting;
  final bool affectsInventory;
  final bool affectsAccounting;
  final bool createsLedgerEntries;
  final bool requiresStockValidation;
  final bool requiresLockCheck;
  final double? approvalThresholdAmount;
  final Duration? maxPendingDuration;
  final Duration? staleAfterDuration;
  final bool terminal;

  const TransitionDefinition({
    required this.transactionType,
    required this.from,
    required this.to,
    required this.permission,
    this.requiresReason = false,
    this.requiresApproval = false,
    this.reversesInventory = false,
    this.reversesAccounting = false,
    this.affectsInventory = false,
    this.affectsAccounting = false,
    this.createsLedgerEntries = false,
    this.requiresStockValidation = false,
    this.requiresLockCheck = true,
    this.approvalThresholdAmount,
    this.maxPendingDuration,
    this.staleAfterDuration,
    this.terminal = false,
  });
}

const List<TransitionDefinition> transitionDefinitions = <TransitionDefinition>[
  TransitionDefinition(
    transactionType: 'inventory.adjustment',
    from: TransactionStatuses.draft,
    to: TransactionStatuses.pendingApproval,
    permission: 'inventory.adjustment.edit',
    requiresApproval: true,
    affectsInventory: true,
    affectsAccounting: true,
    requiresStockValidation: true,
    approvalThresholdAmount: 50000,
    maxPendingDuration: Duration(hours: 48),
    staleAfterDuration: Duration(days: 7),
  ),
  TransitionDefinition(
    transactionType: 'inventory.adjustment',
    from: TransactionStatuses.draft,
    to: TransactionStatuses.approved,
    permission: 'inventory.adjustment.edit',
    requiresApproval: true,
    affectsInventory: true,
    affectsAccounting: true,
    requiresStockValidation: true,
    createsLedgerEntries: true,
    approvalThresholdAmount: 50000,
    maxPendingDuration: Duration(hours: 48),
    staleAfterDuration: Duration(days: 7),
  ),
  TransitionDefinition(
    transactionType: 'inventory.adjustment',
    from: TransactionStatuses.pendingApproval,
    to: TransactionStatuses.rejected,
    permission: 'inventory.adjustment.edit',
    requiresReason: true,
    requiresApproval: true,
    affectsInventory: true,
    affectsAccounting: true,
    requiresStockValidation: true,
    terminal: true,
  ),
  TransitionDefinition(
    transactionType: 'inventory.adjustment',
    from: TransactionStatuses.pendingApproval,
    to: TransactionStatuses.cancelled,
    permission: 'inventory.adjustment.edit',
    requiresReason: true,
    affectsInventory: true,
    affectsAccounting: true,
    requiresStockValidation: true,
    terminal: true,
  ),
  TransitionDefinition(
    transactionType: 'inventory.transfer',
    from: TransactionStatuses.draft,
    to: TransactionStatuses.initiated,
    permission: 'inventory.transfer.edit',
    affectsInventory: true,
    requiresStockValidation: true,
    maxPendingDuration: Duration(hours: 48),
    staleAfterDuration: Duration(days: 5),
  ),
  TransitionDefinition(
    transactionType: 'inventory.transfer',
    from: TransactionStatuses.initiated,
    to: TransactionStatuses.received,
    permission: 'inventory.transfer.edit',
    requiresApproval: true,
    reversesInventory: true,
    affectsInventory: true,
    requiresStockValidation: true,
    maxPendingDuration: Duration(hours: 48),
    staleAfterDuration: Duration(days: 5),
  ),
  TransitionDefinition(
    transactionType: 'inventory.transfer',
    from: TransactionStatuses.draft,
    to: TransactionStatuses.cancelled,
    permission: 'inventory.transfer.edit',
    requiresReason: true,
    affectsInventory: true,
    requiresStockValidation: true,
    terminal: true,
  ),
  TransitionDefinition(
    transactionType: 'inventory.transfer',
    from: TransactionStatuses.initiated,
    to: TransactionStatuses.cancelled,
    permission: 'inventory.transfer.edit',
    requiresReason: true,
    affectsInventory: true,
    requiresStockValidation: true,
    terminal: true,
  ),
  TransitionDefinition(
    transactionType: 'sales.return',
    from: TransactionStatuses.draft,
    to: TransactionStatuses.approved,
    permission: 'sales.return.edit',
    requiresApproval: true,
    reversesInventory: true,
    reversesAccounting: true,
    affectsInventory: true,
    affectsAccounting: true,
    createsLedgerEntries: true,
    requiresStockValidation: true,
    approvalThresholdAmount: 25000,
    maxPendingDuration: Duration(hours: 48),
  ),
  TransitionDefinition(
    transactionType: 'sales.return',
    from: TransactionStatuses.draft,
    to: TransactionStatuses.cancelled,
    permission: 'sales.return.edit',
    requiresReason: true,
    affectsInventory: true,
    affectsAccounting: true,
    requiresStockValidation: true,
    terminal: true,
  ),
  TransitionDefinition(
    transactionType: 'purchases.bill',
    from: TransactionStatuses.draft,
    to: TransactionStatuses.confirmed,
    permission: 'purchases.bill.edit',
    requiresApproval: true,
    reversesAccounting: true,
    affectsAccounting: true,
    createsLedgerEntries: true,
    approvalThresholdAmount: 100000,
    maxPendingDuration: Duration(hours: 72),
    staleAfterDuration: Duration(days: 10),
  ),
  TransitionDefinition(
    transactionType: 'purchases.bill',
    from: TransactionStatuses.confirmed,
    to: TransactionStatuses.voided,
    permission: 'purchases.bill.edit',
    requiresReason: true,
    reversesAccounting: true,
    affectsAccounting: true,
    createsLedgerEntries: true,
    terminal: true,
  ),
  TransitionDefinition(
    transactionType: 'sales.invoice',
    from: TransactionStatuses.approved,
    to: TransactionStatuses.voided,
    permission: 'sales.invoice.edit',
    requiresReason: true,
    reversesInventory: true,
    reversesAccounting: true,
    affectsInventory: true,
    affectsAccounting: true,
    createsLedgerEntries: true,
    requiresStockValidation: true,
    terminal: true,
  ),
  TransitionDefinition(
    transactionType: 'sales.invoice',
    from: TransactionStatuses.pendingApproval,
    to: TransactionStatuses.cancelled,
    permission: 'sales.invoice.edit',
    requiresReason: true,
    affectsInventory: true,
    affectsAccounting: true,
    terminal: true,
  ),
];

const Map<String, Set<String>> moduleStatusOwnership = <String, Set<String>>{
  'inventory.adjustment': <String>{
    TransactionStatuses.draft,
    TransactionStatuses.pendingApproval,
    TransactionStatuses.approved,
    TransactionStatuses.rejected,
    TransactionStatuses.cancelled,
  },
  'inventory.transfer': <String>{
    TransactionStatuses.draft,
    TransactionStatuses.initiated,
    TransactionStatuses.received,
    TransactionStatuses.cancelled,
  },
  'sales.invoice': <String>{
    TransactionStatuses.draft,
    TransactionStatuses.pendingApproval,
    TransactionStatuses.approved,
    TransactionStatuses.voided,
    TransactionStatuses.cancelled,
  },
  'sales.return': <String>{
    TransactionStatuses.draft,
    TransactionStatuses.pendingApproval,
    TransactionStatuses.approved,
    TransactionStatuses.cancelled,
  },
  'purchases.bill': <String>{
    TransactionStatuses.draft,
    TransactionStatuses.pendingApproval,
    TransactionStatuses.confirmed,
    TransactionStatuses.voided,
    TransactionStatuses.cancelled,
  },
};

TransitionDefinition? findTransitionDefinition({
  required String transactionType,
  required String from,
  required String to,
}) {
  for (final definition in transitionDefinitions) {
    if (definition.transactionType == transactionType &&
        definition.from == from &&
        definition.to == to) {
      return definition;
    }
  }
  return null;
}

bool isTransitionSlaBreached({
  required TransitionDefinition definition,
  required DateTime pendingSince,
  DateTime? now,
}) {
  final limit = definition.maxPendingDuration ?? definition.staleAfterDuration;
  if (limit == null) return false;
  final resolvedNow = now ?? DateTime.now();
  return resolvedNow.difference(pendingSince) > limit;
}
