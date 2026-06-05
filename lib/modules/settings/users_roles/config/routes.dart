// PATH: lib/modules/settings/users_roles/config/routes.dart
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/settings/users_roles/presentation/pages/settings_roles_page.dart';
import 'package:zerpai_erp/modules/settings/users_roles/presentation/pages/settings_users_roles_role_creation.dart';

List<GoRoute> buildSettingsUsersRolesRoutes() {
  return [
    GoRoute(
      path: 'settings/roles',
      name: AppRoutes.settingsRoles,
      builder: (context, state) => const SettingsRolesPage(),
      routes: [
        GoRoute(
          path: 'new',
          name: AppRoutes.settingsRoleCreate,
          builder: (context, state) => const SettingsUsersRolesRoleCreation(),
        ),
        GoRoute(
          path: ':id',
          name: AppRoutes.settingsRoleDetail,
          builder: (context, state) => SettingsUsersRolesRoleCreation(
            roleId: state.pathParameters['id'],
          ),
        ),
        GoRoute(
          path: ':id/edit',
          name: AppRoutes.settingsRoleEdit,
          builder: (context, state) => SettingsUsersRolesRoleCreation(
            roleId: state.pathParameters['id'],
          ),
        ),
      ],
    ),
  ];
}

