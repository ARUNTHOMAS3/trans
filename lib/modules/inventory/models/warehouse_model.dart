// lib/modules/inventory/models/warehouse_model.dart

class Warehouse {
  final String id;
  final String name;
  final String? code;
  final bool isActive;
  final String? address;

  Warehouse({
    required this.id,
    required this.name,
    this.code,
    this.isActive = true,
    this.address,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: (json['id'] ?? json['warehouse_id'] ?? '').toString(),
      name: (json['name'] ?? 'Unnamed Warehouse').toString(),
      code: json['code']?.toString(),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'is_active': isActive,
      'address': address,
    };
  }

  @override
  String toString() => name;
}
