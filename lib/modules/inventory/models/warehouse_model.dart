// lib/modules/inventory/models/warehouse_model.dart

class Warehouse {
  final String id;
  final String? branchId;
  final String name;
  final String? code;
  final bool isActive;
  final String? address;
  final bool isDefaultForBranch;

  Warehouse({
    required this.id,
    this.branchId,
    required this.name,
    this.code,
    this.isActive = true,
    this.address,
    this.isDefaultForBranch = true,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: (json['id'] ?? json['warehouse_id'] ?? '').toString(),
      branchId: (json['branch_id'] ?? json['branchId'])?.toString(),
      name: (json['name'] ?? 'Unnamed Warehouse').toString(),
      code: json['code']?.toString(),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      address: json['address']?.toString(),
      isDefaultForBranch: json['is_default_for_branch'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branch_id': branchId,
      'name': name,
      'code': code,
      'is_active': isActive,
      'address': address,
      'is_default_for_branch': isDefaultForBranch,
    };
  }

  @override
  String toString() => name;
}
