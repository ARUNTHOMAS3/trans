// lib/modules/inventory/models/warehouse_model.dart

class Warehouse {
  final String id;
  final String? branchId;
  final String name;
  final String? code;
  final bool isActive;
  final String? address;
  final bool isDefaultForBranch;
  final String? entityId;

  Warehouse({
    required this.id,
    this.branchId,
    required this.name,
    this.code,
    this.isActive = true,
    this.address,
    this.isDefaultForBranch = true,
    this.entityId,
  });

  factory Warehouse.fromJson(Map<String, dynamic> json) {
    return Warehouse(
      id: (json['id'] ?? json['warehouse_id'] ?? '').toString(),
      branchId:
          (json['branch_id'] ??
                  json['branchId'] ??
                  json['source_branch_id'] ??
                  json['sourceBranchId'])
              ?.toString(),
      name: (json['name'] ?? 'Unnamed Warehouse').toString(),
      code: (json['code'] ?? json['warehouse_code'])?.toString(),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      address: json['address']?.toString(),
      isDefaultForBranch: json['is_default_for_branch'] as bool? ?? true,
      entityId: (json['entity_id'] ?? json['entityId'])?.toString(),
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
      'entity_id': entityId,
    };
  }

  @override
  String toString() => name;
}
