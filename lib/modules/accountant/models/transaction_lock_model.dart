class TransactionLock {
  final String moduleName;
  final DateTime lockDate;
  final String reason;
  final DateTime updatedAt;

  const TransactionLock({
    required this.moduleName,
    required this.lockDate,
    required this.reason,
    required this.updatedAt,
  });

  TransactionLock copyWith({
    String? moduleName,
    DateTime? lockDate,
    String? reason,
    DateTime? updatedAt,
  }) {
    return TransactionLock(
      moduleName: moduleName ?? this.moduleName,
      lockDate: lockDate ?? this.lockDate,
      reason: reason ?? this.reason,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'moduleName': moduleName,
      'lockDate': lockDate.toIso8601String(),
      'reason': reason,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TransactionLock.fromJson(Map<String, dynamic> json) {
    return TransactionLock(
      moduleName: json['moduleName'] as String,
      lockDate: DateTime.parse(json['lockDate'] as String),
      reason: json['reason'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
