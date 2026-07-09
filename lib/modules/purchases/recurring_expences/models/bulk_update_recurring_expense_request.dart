class BulkUpdateRecurringExpenseRequest {
  final List<String> ids;
  final Map<String, dynamic> updateData;

  const BulkUpdateRecurringExpenseRequest({
    required this.ids,
    required this.updateData,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'ids': ids,
    'updateData': updateData,
  };
}
