// FILE: lib/modules/items/models/unit_model.dart

class Unit {
  final String id;
  final String unitName;
  final String? uqcId;
  final String? unitSymbol;
  final String? unitType; // count, weight, volume, length
  final bool isActive;

  Unit({
    required this.id,
    required this.unitName,
    this.uqcId,
    this.unitSymbol,
    this.unitType,
    this.isActive = true,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id']?.toString() ?? '',
      unitName: json['unit_name'] ?? '',
      uqcId: json['uqc_id']?.toString(),
      unitSymbol: json['unit_symbol'] ?? json['unique_quantity_code'],
      unitType: json['unit_type'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'unit_name': unitName,
      if (uqcId != null) 'uqc_id': uqcId,
      if (unitSymbol != null) 'unit_symbol': unitSymbol,
      if (unitType != null) 'unit_type': unitType,
      'is_active': isActive,
    };
  }
}
