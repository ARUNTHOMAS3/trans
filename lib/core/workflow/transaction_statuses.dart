class TransactionStatuses {
  const TransactionStatuses._();

  static const draft = 'draft';
  static const pendingApproval = 'pending_approval';
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';
  static const voided = 'voided';
  static const reopened = 'reopened';
  static const completed = 'completed';
  static const initiated = 'initiated';
  static const received = 'received';
  static const confirmed = 'confirmed';
  static const closed = 'closed';

  static const Set<String> values = <String>{
    draft,
    pendingApproval,
    approved,
    rejected,
    cancelled,
    voided,
    reopened,
    completed,
    initiated,
    received,
    confirmed,
    closed,
  };
}

class TransactionStatusCategory {
  final bool isTerminal;
  final bool requiresApproval;
  final bool affectsInventory;
  final bool affectsAccounting;

  const TransactionStatusCategory({
    required this.isTerminal,
    required this.requiresApproval,
    required this.affectsInventory,
    required this.affectsAccounting,
  });
}

const Map<String, TransactionStatusCategory> transactionStatusCategories =
    <String, TransactionStatusCategory>{
      TransactionStatuses.draft: TransactionStatusCategory(
        isTerminal: false,
        requiresApproval: false,
        affectsInventory: false,
        affectsAccounting: false,
      ),
      TransactionStatuses.pendingApproval: TransactionStatusCategory(
        isTerminal: false,
        requiresApproval: true,
        affectsInventory: false,
        affectsAccounting: false,
      ),
      TransactionStatuses.approved: TransactionStatusCategory(
        isTerminal: false,
        requiresApproval: true,
        affectsInventory: true,
        affectsAccounting: true,
      ),
      TransactionStatuses.rejected: TransactionStatusCategory(
        isTerminal: true,
        requiresApproval: true,
        affectsInventory: false,
        affectsAccounting: false,
      ),
      TransactionStatuses.cancelled: TransactionStatusCategory(
        isTerminal: true,
        requiresApproval: false,
        affectsInventory: false,
        affectsAccounting: false,
      ),
      TransactionStatuses.voided: TransactionStatusCategory(
        isTerminal: true,
        requiresApproval: true,
        affectsInventory: true,
        affectsAccounting: true,
      ),
      TransactionStatuses.reopened: TransactionStatusCategory(
        isTerminal: false,
        requiresApproval: true,
        affectsInventory: false,
        affectsAccounting: false,
      ),
      TransactionStatuses.completed: TransactionStatusCategory(
        isTerminal: true,
        requiresApproval: false,
        affectsInventory: true,
        affectsAccounting: true,
      ),
      TransactionStatuses.initiated: TransactionStatusCategory(
        isTerminal: false,
        requiresApproval: false,
        affectsInventory: true,
        affectsAccounting: false,
      ),
      TransactionStatuses.received: TransactionStatusCategory(
        isTerminal: false,
        requiresApproval: false,
        affectsInventory: true,
        affectsAccounting: true,
      ),
      TransactionStatuses.confirmed: TransactionStatusCategory(
        isTerminal: false,
        requiresApproval: false,
        affectsInventory: true,
        affectsAccounting: true,
      ),
      TransactionStatuses.closed: TransactionStatusCategory(
        isTerminal: true,
        requiresApproval: false,
        affectsInventory: true,
        affectsAccounting: true,
      ),
    };
