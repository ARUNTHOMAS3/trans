/// Lightweight user model used across the auth module.
class User {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String orgId;
  final String orgName;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? phoneNumber;
  final String? department;
  final String? position;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.orgId,
    required this.orgName,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.phoneNumber,
    this.department,
    this.position,
    this.avatarUrl,
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
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      orgId: json['orgId'] as String? ?? '',
      orgName: json['orgName'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
      phoneNumber: json['phoneNumber'] as String?,
      department: json['department'] as String?,
      position: json['position'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'fullName': fullName,
        'role': role,
        'orgId': orgId,
        'orgName': orgName,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'phoneNumber': phoneNumber,
        'department': department,
        'position': position,
        'avatarUrl': avatarUrl,
      };
}
