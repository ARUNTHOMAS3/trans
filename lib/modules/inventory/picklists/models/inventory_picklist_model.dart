/// Model classes for Inventory Picklist documents.
///
/// A Picklist tracks the process of picking items from inventory for orders.
class Picklist {
  final String? id;
  final String picklistNumber;
  final DateTime? date;
  final String status; // 'Yet to Start' | 'In Progress' | 'On Hold' | 'Completed'
  final String? assignee;
  final String? location;
  final String? notes;

  Picklist({
    this.id,
    this.picklistNumber = '',
    this.date,
    this.status = 'Yet to Start',
    this.assignee,
    this.location,
    this.notes,
  });

  Picklist copyWith({
    String? id,
    String? picklistNumber,
    DateTime? date,
    String? status,
    String? assignee,
    String? location,
    String? notes,
  }) {
    return Picklist(
      id: id ?? this.id,
      picklistNumber: picklistNumber ?? this.picklistNumber,
      date: date ?? this.date,
      status: status ?? this.status,
      assignee: assignee ?? this.assignee,
      location: location ?? this.location,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'picklist_number': picklistNumber,
        'date': date?.toIso8601String(),
        'status': status,
        'assignee': assignee,
        'location': location,
        'notes': notes,
      };

  factory Picklist.fromJson(Map<String, dynamic> json) {
    return Picklist(
      id: json['id'] as String?,
      picklistNumber: json['picklist_number'] as String? ?? '',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : null,
      status: json['status'] as String? ?? 'Yet to Start',
      assignee: json['assignee'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
