import '../../manual_journals/models/manual_journal_model.dart';

enum RecurringJournalStatus { active, inactive, draft }

class RecurringJournal {
  final String id;
  final String profileName;
  final String repeatEvery; // e.g., 'week', 'month'
  final int interval; // e.g., repeat every 2 weeks
  final DateTime startDate;
  final DateTime? endDate;
  final bool neverExpires;
  final String? referenceNumber;
  final String? notes;
  final String currency;
  final String reportingMethod;
  final List<ManualJournalItem> items;
  final RecurringJournalStatus status;
  final DateTime? lastGeneratedDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurringJournal({
    required this.id,
    required this.profileName,
    required this.repeatEvery,
    this.interval = 1,
    required this.startDate,
    this.endDate,
    this.neverExpires = true,
    this.referenceNumber,
    this.notes,
    this.currency = 'INR',
    this.reportingMethod = 'accrual_and_cash',
    required this.items,
    this.status = RecurringJournalStatus.active,
    this.lastGeneratedDate,
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalDebit => items.fold(0.0, (sum, item) => sum + item.debit);
  double get totalCredit => items.fold(0.0, (sum, item) => sum + item.credit);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_name': profileName,
      'repeat_every': repeatEvery,
      'interval': interval,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'never_expires': neverExpires,
      'reference_number': referenceNumber,
      'notes': notes,
      'currency': currency,
      'reporting_method': reportingMethod,
      'items': items.map((x) => x.toJson()).toList(),
      'status': status.name,
      'last_generated_date': lastGeneratedDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RecurringJournal.fromJson(Map<String, dynamic> json) {
    return RecurringJournal(
      id: json['id'] as String? ?? '',
      profileName:
          (json['profileName'] ?? json['profile_name']) as String? ?? '',
      repeatEvery:
          (json['repeatEvery'] ?? json['repeat_every']) as String? ?? 'week',
      interval: (json['interval'] as num?)?.toInt() ?? 1,
      startDate:
          DateTime.tryParse(
            (json['startDate'] ?? json['start_date'] ?? '').toString(),
          ) ??
          DateTime.now(),
      endDate: (json['endDate'] ?? json['end_date']) != null
          ? DateTime.tryParse((json['endDate'] ?? json['end_date']).toString())
          : null,
      neverExpires:
          (json['neverExpires'] ?? json['never_expires']) as bool? ?? true,
      referenceNumber:
          (json['referenceNumber'] ?? json['reference_number']) as String?,
      notes: json['notes'] as String?,
      currency: (json['currency'] ?? json['currency_code']) as String? ?? 'INR',
      reportingMethod:
          (json['reportingMethod'] ?? json['reporting_method']) as String? ??
          'accrual_and_cash',
      items:
          (json['items'] as List?)
              ?.map(
                (x) => ManualJournalItem.fromJson(Map<String, dynamic>.from(x)),
              )
              .toList() ??
          [],
      status: RecurringJournalStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'active'),
        orElse: () => RecurringJournalStatus.active,
      ),
      lastGeneratedDate:
          (json['lastGeneratedDate'] ?? json['last_generated_date']) != null
          ? DateTime.tryParse(
              (json['lastGeneratedDate'] ?? json['last_generated_date'])
                  .toString(),
            )
          : null,
      createdAt:
          DateTime.tryParse(
            (json['createdAt'] ?? json['created_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(
            (json['updatedAt'] ?? json['updated_at'] ?? '').toString(),
          ) ??
          DateTime.now(),
    );
  }

  RecurringJournal copyWith({
    String? id,
    String? profileName,
    String? repeatEvery,
    int? interval,
    DateTime? startDate,
    DateTime? endDate,
    bool? neverExpires,
    String? referenceNumber,
    String? notes,
    String? currency,
    String? reportingMethod,
    List<ManualJournalItem>? items,
    RecurringJournalStatus? status,
    DateTime? lastGeneratedDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringJournal(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      repeatEvery: repeatEvery ?? this.repeatEvery,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      neverExpires: neverExpires ?? this.neverExpires,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      notes: notes ?? this.notes,
      currency: currency ?? this.currency,
      reportingMethod: reportingMethod ?? this.reportingMethod,
      items: items ?? this.items,
      status: status ?? this.status,
      lastGeneratedDate: lastGeneratedDate ?? this.lastGeneratedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RecurringJournalCustomView {
  final String id;
  final String name;
  final RecurringJournalStatus? status;
  final double? minAmount;
  final double? maxAmount;
  final String? profileNameContains;

  const RecurringJournalCustomView({
    required this.id,
    required this.name,
    this.status,
    this.minAmount,
    this.maxAmount,
    this.profileNameContains,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status?.name,
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'profileNameContains': profileNameContains,
    };
  }

  factory RecurringJournalCustomView.fromJson(Map<String, dynamic> json) {
    return RecurringJournalCustomView(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] != null
          ? RecurringJournalStatus.values.firstWhere(
              (e) => e.name == json['status'],
              orElse: () => RecurringJournalStatus.active,
            )
          : null,
      minAmount: (json['minAmount'] as num?)?.toDouble(),
      maxAmount: (json['maxAmount'] as num?)?.toDouble(),
      profileNameContains: json['profileNameContains'] as String?,
    );
  }
}
