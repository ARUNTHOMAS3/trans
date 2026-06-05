class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? roleLabel;
  final bool roleIsDefault;
  final String orgId;
  final String orgName;
  final String? phoneNumber;
  final String? department;
  final String? position;
  final String? avatarUrl;
  final bool isActive;
  final bool isVerified;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.roleLabel,
    this.roleIsDefault = false,
    required this.orgId,
    required this.orgName,
    this.phoneNumber,
    this.department,
    this.position,
    this.avatarUrl,
    required this.isActive,
    required this.isVerified,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.tryParse(value.toString());
    }

    DateTime parseDate(dynamic value) {
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.tryParse(value.toString()) ?? DateTime.now();
    }

    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      roleLabel:
          json['roleLabel'] as String? ?? json['role_label'] as String?,
      roleIsDefault:
          json['roleIsDefault'] as bool? ??
          json['role_is_default'] as bool? ??
          false,
      orgId: json['orgId'] as String? ?? '',
      orgName: json['orgName'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? false,
      lastLoginAt: parseNullableDate(json['lastLoginAt'] ?? json['last_login_at']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'roleLabel': roleLabel,
        'roleIsDefault': roleIsDefault,
        'orgId': orgId,
        'orgName': orgName,
        'phoneNumber': phoneNumber,
        'department': department,
        'position': position,
        'avatarUrl': avatarUrl,
        'isActive': isActive,
        'isVerified': isVerified,
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
