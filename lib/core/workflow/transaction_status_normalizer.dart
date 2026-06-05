import 'transaction_statuses.dart';

const Map<String, String> _statusAliases = <String, String>{
  'draft': TransactionStatuses.draft,
  'pending': TransactionStatuses.pendingApproval,
  'pending approval': TransactionStatuses.pendingApproval,
  'pending_approval': TransactionStatuses.pendingApproval,
  'submitted': TransactionStatuses.pendingApproval,
  'approve': TransactionStatuses.approved,
  'approved': TransactionStatuses.approved,
  'adjusted': TransactionStatuses.approved,
  'reject': TransactionStatuses.rejected,
  'rejected': TransactionStatuses.rejected,
  'cancel': TransactionStatuses.cancelled,
  'cancelled': TransactionStatuses.cancelled,
  'canceled': TransactionStatuses.cancelled,
  'void': TransactionStatuses.voided,
  'voided': TransactionStatuses.voided,
  'reopen': TransactionStatuses.reopened,
  'reopened': TransactionStatuses.reopened,
  'complete': TransactionStatuses.completed,
  'completed': TransactionStatuses.completed,
  'initiated': TransactionStatuses.initiated,
  'received': TransactionStatuses.received,
  'confirm': TransactionStatuses.confirmed,
  'confirmed': TransactionStatuses.confirmed,
  'close': TransactionStatuses.closed,
  'closed': TransactionStatuses.closed,
};

String normalizeTransactionStatus(dynamic value) {
  if (value == null) return TransactionStatuses.draft;
  final raw = value.toString().trim();
  if (raw.isEmpty) return TransactionStatuses.draft;
  final normalizedKey = raw.toLowerCase().replaceAll('_', ' ').trim();
  return _statusAliases[normalizedKey] ?? normalizedKey.replaceAll(' ', '_');
}

String transactionStatusLabel(String status) {
  final normalized = normalizeTransactionStatus(status);
  switch (normalized) {
    case TransactionStatuses.pendingApproval:
      return 'Pending Approval';
    case TransactionStatuses.approved:
      return 'Approved';
    case TransactionStatuses.rejected:
      return 'Rejected';
    case TransactionStatuses.cancelled:
      return 'Cancelled';
    case TransactionStatuses.voided:
      return 'Voided';
    case TransactionStatuses.reopened:
      return 'Reopened';
    case TransactionStatuses.completed:
      return 'Completed';
    case TransactionStatuses.initiated:
      return 'Initiated';
    case TransactionStatuses.received:
      return 'Received';
    case TransactionStatuses.confirmed:
      return 'Confirmed';
    case TransactionStatuses.closed:
      return 'Closed';
    case TransactionStatuses.draft:
    default:
      return 'Draft';
  }
}
