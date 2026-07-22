import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ExpenseHistoryEntryModel {
  const ExpenseHistoryEntryModel({
    required this.id,
    required this.actorName,
    required this.createdAt,
    required this.summary,
    required this.action,
    this.fieldChanges = const <String>[],
  });

  final String id;
  final String actorName;
  final String createdAt;
  final String summary;
  final String action;
  final List<String> fieldChanges;

  factory ExpenseHistoryEntryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseHistoryEntryModel(
      id: (json['id'] ?? '').toString(),
      actorName: (json['actor_name'] ?? json['actorName'] ?? 'AUTO').toString(),
      createdAt: (json['created_at'] ?? json['createdAt'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      fieldChanges: (json['field_changes'] as List<dynamic>? ?? const [])
          .map((entry) => entry.toString())
          .toList(growable: false),
    );
  }

  bool get isCreate => action.toUpperCase() == 'CREATE';

  String get displayMessage {
    final base = summary.trim();
    if (fieldChanges.isEmpty) {
      return base;
    }
    if (action.toUpperCase() != 'UPDATE') {
      return base;
    }

    final changes = fieldChanges
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .join('. ');
    if (changes.isEmpty) {
      return base;
    }
    return '$base ${changes.endsWith('.') ? changes : '$changes.'}';
  }

  IconData get icon => isCreate ? LucideIcons.filePlus2 : LucideIcons.fileEdit;
}
