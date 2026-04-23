/// Lightweight user model used across the auth module.
class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String orgId;
  final String? orgEntityId;
  final String orgName;
  final String orgSystemId;
  final String routeSystemId;
  final String? roleLabel;
  final bool roleIsDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? phoneNumber;
  final String? department;
  final String? position;
  final String? avatarUrl;
  final List<String> accessibleBranchIds;
  final String? defaultBusinessBranchId;
  final String? defaultWarehouseBranchId;
  final Map<String, dynamic>? permissions;
  final String? activeTenantId;
  final String? activeTenantType;
  final String? activeEntityId;
  final String? activeTenantRouteSystemId;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.orgId,
    this.orgEntityId,
    required this.orgName,
    required this.orgSystemId,
    this.routeSystemId = '',
    this.roleLabel,
    this.roleIsDefault = false,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.department,
    this.position,
    this.avatarUrl,
    this.accessibleBranchIds = const [],
    this.defaultBusinessBranchId,
    this.defaultWarehouseBranchId,
    this.permissions,
    this.activeTenantId,
    this.activeTenantType,
    this.activeEntityId,
    this.activeTenantRouteSystemId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
    }

    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['full_name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      orgId: json['orgId'] as String? ?? json['org_id'] as String? ?? '',
      orgEntityId: json['orgEntityId'] as String? ?? json['org_entity_id'] as String?,
      orgName: json['orgName'] as String? ?? json['org_name'] as String? ?? '',
      orgSystemId: json['orgSystemId'] as String? ?? json['org_system_id'] as String? ?? '',
      routeSystemId:
          json['routeSystemId'] as String? ??
          json['route_system_id'] as String? ??
          json['orgSystemId'] as String? ??
          '',
      roleLabel: json['roleLabel'] as String? ?? json['role_label'] as String?,
      roleIsDefault:
          json['roleIsDefault'] as bool? ??
          json['role_is_default'] as bool? ??
          false,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      phoneNumber: json['phoneNumber'] as String? ?? json['phone_number'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
      accessibleBranchIds:
          (json['accessibleBranchIds'] as List<dynamic>? ?? 
           json['accessible_branch_ids'] as List<dynamic>? ?? 
           const [])
              .map((value) => value.toString())
              .toList(),
      defaultBusinessBranchId: 
          json['defaultBusinessBranchId'] as String? ?? 
          json['default_business_branch_id'] as String?,
      defaultWarehouseBranchId: 
          json['defaultWarehouseBranchId'] as String? ?? 
          json['default_warehouse_branch_id'] as String?,
      permissions: json['permissions'] is Map
          ? Map<String, dynamic>.from(json['permissions'] as Map)
          : null,
      activeTenantId:
          json['activeTenantId'] as String? ??
          json['active_tenant_id'] as String?,
      activeTenantType:
          json['activeTenantType'] as String? ??
          json['active_tenant_type'] as String?,
      activeEntityId:
          json['activeEntityId'] as String? ??
          json['active_entity_id'] as String?,
      activeTenantRouteSystemId:
          json['activeTenantRouteSystemId'] as String? ??
          json['active_tenant_route_system_id'] as String?,
    );
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? orgId,
    String? orgEntityId,
    String? orgName,
    String? orgSystemId,
    String? routeSystemId,
    String? roleLabel,
    bool? roleIsDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phoneNumber,
    String? department,
    String? position,
    String? avatarUrl,
    List<String>? accessibleBranchIds,
    String? defaultBusinessBranchId,
    String? defaultWarehouseBranchId,
    Map<String, dynamic>? permissions,
    String? activeTenantId,
    String? activeTenantType,
    String? activeEntityId,
    String? activeTenantRouteSystemId,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      orgId: orgId ?? this.orgId,
      orgEntityId: orgEntityId ?? this.orgEntityId,
      orgName: orgName ?? this.orgName,
      orgSystemId: orgSystemId ?? this.orgSystemId,
      routeSystemId: routeSystemId ?? this.routeSystemId,
      roleLabel: roleLabel ?? this.roleLabel,
      roleIsDefault: roleIsDefault ?? this.roleIsDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      department: department ?? this.department,
      position: position ?? this.position,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      accessibleBranchIds: accessibleBranchIds ?? this.accessibleBranchIds,
      defaultBusinessBranchId:
          defaultBusinessBranchId ?? this.defaultBusinessBranchId,
      defaultWarehouseBranchId:
          defaultWarehouseBranchId ?? this.defaultWarehouseBranchId,
      permissions: permissions ?? this.permissions,
      activeTenantId: activeTenantId ?? this.activeTenantId,
      activeTenantType: activeTenantType ?? this.activeTenantType,
      activeEntityId: activeEntityId ?? this.activeEntityId,
      activeTenantRouteSystemId:
          activeTenantRouteSystemId ?? this.activeTenantRouteSystemId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'role': role,
    'orgId': orgId,
    'orgEntityId': orgEntityId,
    'orgName': orgName,
    'orgSystemId': orgSystemId,
    'routeSystemId': routeSystemId,
    'roleLabel': roleLabel,
    'roleIsDefault': roleIsDefault,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'phoneNumber': phoneNumber,
    'department': department,
    'position': position,
    'avatarUrl': avatarUrl,
    'accessibleBranchIds': accessibleBranchIds,
    'defaultBusinessBranchId': defaultBusinessBranchId,
    'defaultWarehouseBranchId': defaultWarehouseBranchId,
    'permissions': permissions,
    'activeTenantId': activeTenantId,
    'activeTenantType': activeTenantType,
    'activeEntityId': activeEntityId,
    'activeTenantRouteSystemId': activeTenantRouteSystemId,
  };
}
