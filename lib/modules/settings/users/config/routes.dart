// PATH: lib/modules/settings/users/config/routes.dart
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/settings/users/presentation/pages/settings_users_user_creation.dart';
import 'package:zerpai_erp/modules/settings/users/presentation/pages/settings_users_user_overview.dart';

List<GoRoute> buildSettingsUsersRoutes() {
  return [
    GoRoute(
      path: 'settings/users',
      name: AppRoutes.settingsUsers,
      builder: (context, state) => const SettingsUsersUserOverview(),
      routes: [
        GoRoute(
          path: 'new',
          name: AppRoutes.settingsUserInvite,
          builder: (context, state) => const SettingsUsersUserCreation(),
        ),
        GoRoute(
          path: ':id',
          name: AppRoutes.settingsUserDetail,
          builder: (context, state) => SettingsUsersUserOverview(
            selectedUserId: state.pathParameters['id'],
          ),
        ),
        GoRoute(
          path: ':id/edit',
          name: AppRoutes.settingsUserEdit,
          builder: (context, state) =>
              SettingsUsersUserCreation(userId: state.pathParameters['id']),
        ),
      ],
    ),
  ];
}
