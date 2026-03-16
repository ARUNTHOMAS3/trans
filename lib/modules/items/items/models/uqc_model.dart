class Uqc {
  final String id;
  final String uqcCode;
  final String description;
  final bool isActive;

  Uqc({
    required this.id,
    required this.uqcCode,
    required this.description,
    this.isActive = true,
  });

  factory Uqc.fromJson(Map<String, dynamic> json) {
    return Uqc(
      id: json['id']?.toString() ?? '',
      uqcCode: json['uqc_code'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'uqc_code': uqcCode,
      'description': description,
      'is_active': isActive,
    };
  }

  String get displayName => '$uqcCode ($description)';
}
