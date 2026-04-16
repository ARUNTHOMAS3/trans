class HsnSacCode {
  final String code;
  final String description;
  final double? gstRate;

  HsnSacCode({required this.code, required this.description, this.gstRate});

  factory HsnSacCode.fromJson(Map<String, dynamic> json) {
    return HsnSacCode(
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      gstRate: json['gstRate'] != null
          ? (json['gstRate'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'code': code, 'description': description, 'gstRate': gstRate};
  }

  String get displayText => '$code - $description';
}
