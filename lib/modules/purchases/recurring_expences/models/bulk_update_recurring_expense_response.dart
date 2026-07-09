class BulkUpdateRecurringExpenseResponse {
  final int requestedCount;
  final int updatedCount;
  final int failedCount;
  final String? requestId;

  const BulkUpdateRecurringExpenseResponse({
    required this.requestedCount,
    required this.updatedCount,
    required this.failedCount,
    this.requestId,
  });

  factory BulkUpdateRecurringExpenseResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return BulkUpdateRecurringExpenseResponse(
      requestedCount: (json['requestedCount'] as num?)?.toInt() ?? 0,
      updatedCount: (json['updatedCount'] as num?)?.toInt() ?? 0,
      failedCount: (json['failedCount'] as num?)?.toInt() ?? 0,
      requestId: json['requestId']?.toString(),
    );
  }
}
