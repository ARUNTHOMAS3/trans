import 'package:flutter_test/flutter_test.dart';
import 'package:zerpai_erp/core/auth/permission_resolver.dart';
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
  group('PermissionResolver', () {
    test('returns all registry keys for admin', () {
      final input = PermissionResolutionInput(
        user: _user(role: 'admin', permissions: const <String, dynamic>{}),
      );
      final resolved = PermissionResolver.resolve(input);
      expect(resolved.isNotEmpty, true);
      expect(
        resolved.contains('settings.roles.view'),
        true,
      );
    });

    test('expands list permissions using legacy key mapping', () {
      final input = PermissionResolutionInput(
        user: _user(
          permissions: const <String, dynamic>{
            'users_roles': ['view'],
          },
        ),
      );
      final resolved = PermissionResolver.resolve(input);
      expect(resolved.contains('settings.users.view'), true);
      expect(resolved.contains('settings.roles.view'), true);
    });

    test('supports full_access flag', () {
      final input = PermissionResolutionInput(
        user: _user(
          permissions: const <String, dynamic>{'full_access': true},
        ),
      );
      final resolved = PermissionResolver.resolve(input);
      expect(resolved.contains('sales.invoice.view'), true);
      expect(resolved.contains('settings.roles.edit'), true);
    });

    test('applies branch guard when branch not accessible', () {
      final input = PermissionResolutionInput(
        user: _user(
          permissions: const <String, dynamic>{
            'users_roles': ['view'],
          },
          accessibleBranchIds: const <String>['branch-a'],
        ),
        branchId: 'branch-b',
      );
      final resolved = PermissionResolver.resolve(input);
      expect(resolved, isEmpty);
    });

    test('supports grant and deny overrides', () {
      final input = PermissionResolutionInput(
        user: _user(
          permissions: const <String, dynamic>{
            'users_roles': ['view'],
          },
        ),
        grantOverrides: const <String>{'settings.roles.manage'},
        denyOverrides: const <String>{'settings.users.view'},
      );
      final resolved = PermissionResolver.resolve(input);
      expect(resolved.contains('settings.roles.manage'), true);
      expect(resolved.contains('settings.users.view'), false);
    });

    test('invalidateCache does not break future resolves', () {
      final input = PermissionResolutionInput(
        user: _user(
          permissions: const <String, dynamic>{
            'users_roles': ['view'],
          },
        ),
      );
      final first = PermissionResolver.resolve(input);
      PermissionResolver.invalidateCache();
      final second = PermissionResolver.resolve(input);
      expect(second, equals(first));
    });
  });
}
