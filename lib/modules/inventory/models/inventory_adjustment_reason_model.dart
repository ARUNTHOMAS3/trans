class InventoryAdjustmentReason {
  final String id;
  final String? entityId;
  final String name;
  final String? code;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const InventoryAdjustmentReason({
    required this.id,
    this.entityId,
    required this.name,
    this.code,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory InventoryAdjustmentReason.fromJson(Map<String, dynamic> json) {
    return InventoryAdjustmentReason(
      id: (json['id'] ?? '').toString(),
      entityId: json['entity_id']?.toString(),
      name: (json['name'] ?? '').toString(),
      code: json['code']?.toString(),
      isActive: json['is_active'] == true || json['isActive'] == true,
      sortOrder: int.tryParse((json['sort_order'] ?? 0).toString()) ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'entity_id': entityId,
      'name': name,
      'code': code,
      'is_active': isActive,
      'sort_order': sortOrder,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  bool get isGlobal => (entityId ?? '').trim().isEmpty;
}
