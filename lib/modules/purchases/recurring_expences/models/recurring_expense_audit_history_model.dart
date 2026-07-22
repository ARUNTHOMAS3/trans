class RecurringExpenseAuditHistoryEntry {
  final String id;
  final String action;
  final String actorName;
  final String? createdAt;
  final String summary;
  final List<String> fieldChanges;

  const RecurringExpenseAuditHistoryEntry({
    required this.id,
    required this.action,
    required this.actorName,
    this.createdAt,
    required this.summary,
    this.fieldChanges = const <String>[],
  });

  factory RecurringExpenseAuditHistoryEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawFieldChanges = json['field_changes'];
    final fieldChanges = rawFieldChanges is List
        ? rawFieldChanges
              .map((value) => value?.toString().trim() ?? '')
              .where((value) => value.isNotEmpty)
              .toList()
        : const <String>[];

    return RecurringExpenseAuditHistoryEntry(
      id: (json['id'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      actorName: (json['actor_name'] ?? json['performed_by_name'] ?? '-')
          .toString(),
      createdAt: json['created_at']?.toString(),
      summary: (json['summary'] ?? '').toString(),
      fieldChanges: fieldChanges,
    );
  }
}
