import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/core/auth/capability_service.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';

User _user({
  String role = 'user',
  Map<String, dynamic>? permissions,
  List<String> accessibleBranchIds = const <String>[],
}) {
  final now = DateTime(2026, 1, 1);
  return User(
    id: 'u1',
    email: 'test@example.com',
    fullName: 'Test User',
    role: role,
    orgId: 'org-1',
    orgName: 'Org',
    orgSystemId: '0000000001',
    isActive: true,
    createdAt: now,
    updatedAt: now,
    permissions: permissions,
    accessibleBranchIds: accessibleBranchIds,
  );
}

void main() {
  group('CapabilityService', () {
    test('canUserAction works for canonical key', () {
      final user = _user(
        permissions: const <String, dynamic>{
          'users_roles': ['view'],
        },
      );
      expect(
        CapabilityService.canUserAction(
          user,
          'settings.users.view',
          action: 'view',
        ),
        true,
      );
    });

    test('canUserAction maps legacy key to canonical key', () {
      final user = _user(
        permissions: const <String, dynamic>{
          'invoices': ['view'],
        },
      );
      expect(
        CapabilityService.canUserAction(user, 'invoices', action: 'view'),
        true,
      );
      expect(
        CapabilityService.canUserAction(user, 'invoices', action: 'create'),
        false,
      );
    });

    test('respects branch restriction', () {
      final user = _user(
        permissions: const <String, dynamic>{
          'invoices': ['view'],
        },
        accessibleBranchIds: const <String>['branch-a'],
      );
      expect(
        CapabilityService.canUserAction(
          user,
          'invoices',
          action: 'view',
          branchId: 'branch-b',
        ),
        false,
      );
    });
  });
}

