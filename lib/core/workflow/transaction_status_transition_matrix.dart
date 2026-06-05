import 'transaction_statuses.dart';

const Map<String, Set<String>> transactionStatusTransitions =
    <String, Set<String>>{
      TransactionStatuses.draft: <String>{
        TransactionStatuses.pendingApproval,
        TransactionStatuses.approved,
        TransactionStatuses.confirmed,
        TransactionStatuses.initiated,
        TransactionStatuses.cancelled,
      },
      TransactionStatuses.pendingApproval: <String>{
        TransactionStatuses.approved,
        TransactionStatuses.rejected,
        TransactionStatuses.cancelled,
      },
      TransactionStatuses.approved: <String>{
        TransactionStatuses.voided,
        TransactionStatuses.reopened,
        TransactionStatuses.completed,
        TransactionStatuses.closed,
      },
      TransactionStatuses.rejected: <String>{
        TransactionStatuses.reopened,
        TransactionStatuses.cancelled,
      },
      TransactionStatuses.reopened: <String>{
        TransactionStatuses.pendingApproval,
        TransactionStatuses.approved,
        TransactionStatuses.cancelled,
      },
      TransactionStatuses.initiated: <String>{
        TransactionStatuses.received,
        TransactionStatuses.cancelled,
      },
      TransactionStatuses.received: <String>{
        TransactionStatuses.completed,
        TransactionStatuses.closed,
      },
      TransactionStatuses.confirmed: <String>{
        TransactionStatuses.completed,
        TransactionStatuses.closed,
        TransactionStatuses.cancelled,
        TransactionStatuses.voided,
      },
    };
