// lib/modules/inventory/models/warehouse_model.dart

class Warehouse {
  final String id;
  final String? outletId;
  final String name;
  final String? code;
  final bool isActive;
  final String? address;

  Warehouse({
    required this.id,
    this.outletId,
    required this.name,
    this.code,
    this.isActive = true,
    this.address,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: (json['id'] ?? json['warehouse_id'] ?? '').toString(),
      outletId: (json['outlet_id'] ?? json['outletId'])?.toString(),
      name: (json['name'] ?? 'Unnamed Warehouse').toString(),
      code: json['code']?.toString(),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'outlet_id': outletId,
      'name': name,
      'code': code,
      'is_active': isActive,
      'address': address,
    };
  }

  @override
  String toString() => name;
}
