class TransactionStatusAuditEvent {
  final String transactionType;
  final String transactionId;
  final String beforeStatus;
  final String afterStatus;
  final String actorId;
  final String actorName;
  final String reason;
  final String permissionUsed;
  final DateTime timestamp;
  final String? branchId;
  final String? warehouseId;
  final Map<String, dynamic> metadata;

  const TransactionStatusAuditEvent({
    required this.transactionType,
    required this.transactionId,
    required this.beforeStatus,
    required this.afterStatus,
    required this.actorId,
    required this.actorName,
    required this.reason,
    required this.permissionUsed,
    required this.timestamp,
    this.branchId,
    this.warehouseId,
    this.metadata = const <String, dynamic>{},
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'transaction_type': transactionType,
      'transaction_id': transactionId,
      'before_status': beforeStatus,
      'after_status': afterStatus,
      'actor_id': actorId,
      'actor_name': actorName,
      'reason': reason,
      'permission_used': permissionUsed,
      'timestamp': timestamp.toIso8601String(),
      'branch_id': branchId,
      'warehouse_id': warehouseId,
      'metadata': metadata,
    };
  }
}
