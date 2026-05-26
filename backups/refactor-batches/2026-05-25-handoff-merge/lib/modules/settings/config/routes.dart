import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/settings/organization/presentation/pages/settings_branch_profile_page.dart';
import 'package:zerpai_erp/modules/settings/organization/presentation/pages/settings_branches_create_page.dart';
import 'package:zerpai_erp/modules/settings/organization/presentation/pages/settings_branches_list_page.dart';
import 'package:zerpai_erp/modules/settings/organization/presentation/pages/settings_organization_branding_page.dart';
import 'package:zerpai_erp/modules/settings/organization/presentation/pages/settings_organization_profile_page.dart';
import 'package:zerpai_erp/modules/settings/presentation/pages/settings_page.dart';
import 'package:zerpai_erp/modules/settings/users_roles/presentation/pages/settings_roles_page.dart';
import 'package:zerpai_erp/modules/settings/organization/presentation/pages/settings_warehouses_create_page.dart';
import 'package:zerpai_erp/modules/settings/organization/presentation/pages/settings_warehouses_list_page.dart';
import 'package:zerpai_erp/modules/settings/organization/presentation/pages/settings_zone_bins_page.dart';
import 'package:zerpai_erp/modules/settings/organization/presentation/pages/settings_zones_create_page.dart';
import 'package:zerpai_erp/modules/settings/organization/presentation/pages/settings_zones_page.dart';
import 'package:zerpai_erp/modules/settings/taxes/config/routes.dart';
import 'package:zerpai_erp/modules/settings/setup/config/routes.dart';
import 'package:zerpai_erp/modules/settings/customization/config/routes.dart';
import 'package:zerpai_erp/modules/settings/automation/config/routes.dart';
import 'package:zerpai_erp/modules/settings/integrations/config/routes.dart';
import 'package:zerpai_erp/modules/settings/developer/config/routes.dart';
import 'package:zerpai_erp/modules/settings/users/presentation/pages/settings_users_user_creation.dart';
import 'package:zerpai_erp/modules/settings/users/presentation/pages/settings_users_user_overview.dart';
import 'package:zerpai_erp/modules/settings/users_roles/presentation/pages/settings_users_roles_role_creation.dart';

typedef ActiveTenantTypeReader = String? Function();
typedef ActiveTenantIdReader = String? Function();

List<GoRoute> buildSettingsRoutes({
  required String fallbackRouteSystemId,
  required ActiveTenantTypeReader storedActiveTenantType,
  required ActiveTenantIdReader storedActiveTenantId,
}) {
  return [
    GoRoute(
      path: 'settings',
      name: AppRoutes.settings,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: 'settings/orgprofile',
      name: AppRoutes.settingsOrgProfile,
      redirect: (context, state) {
        final orgSystemId =
            state.pathParameters['orgSystemId'] ?? fallbackRouteSystemId;
        final activeTenantType = storedActiveTenantType();
        final activeTenantId = storedActiveTenantId();
        if (activeTenantType == 'BRANCH' &&
            activeTenantId != null &&
            activeTenantId.isNotEmpty) {
          return '/$orgSystemId/settings/branches/$activeTenantId/profile';
        }
        return null;
      },
      builder: (context, state) => const SettingsOrganizationProfilePage(),
    ),
    GoRoute(
      path: 'settings/orgbranding',
      name: AppRoutes.settingsOrgBranding,
      builder: (context, state) => const SettingsOrganizationBrandingPage(),
    ),
    GoRoute(
      path: 'settings/locations',
      name: AppRoutes.settingsLocations,
      redirect: (context, state) {
        final orgSystemId =
            state.pathParameters['orgSystemId'] ?? fallbackRouteSystemId;
        return '/$orgSystemId/settings/branches';
      },
    ),
    GoRoute(
      path: 'settings/zones',
      name: AppRoutes.settingsZones,
      builder: (context, state) => SettingsZonesPage(
        branchId: state.uri.queryParameters['warehouseId'] == null
            ? state.uri.queryParameters['branchId'] ??
                  state.uri.queryParameters['locationId'] ??
                  state.uri.queryParameters['branchId']
            : null,
        branchName: state.uri.queryParameters['warehouseName'] == null
            ? state.uri.queryParameters['branchName'] ??
                  state.uri.queryParameters['locationName'] ??
                  state.uri.queryParameters['branchName']
            : null,
        warehouseId: state.uri.queryParameters['warehouseId'],
        warehouseName: state.uri.queryParameters['warehouseName'],
      ),
    ),
    GoRoute(
      path: 'settings/zones/new',
      name: AppRoutes.settingsZonesCreate,
      builder: (context, state) => SettingsZonesCreatePage(
        branchId: state.uri.queryParameters['warehouseId'] == null
            ? state.uri.queryParameters['branchId'] ??
                  state.uri.queryParameters['locationId'] ??
                  state.uri.queryParameters['branchId']
            : null,
        branchName: state.uri.queryParameters['warehouseName'] == null
            ? state.uri.queryParameters['branchName'] ??
                  state.uri.queryParameters['locationName'] ??
                  state.uri.queryParameters['branchName']
            : null,
        warehouseId: state.uri.queryParameters['warehouseId'],
        warehouseName: state.uri.queryParameters['warehouseName'],
      ),
    ),
    GoRoute(
      path: 'settings/zones/:zoneId/bins',
      name: AppRoutes.settingsZoneBins,
      builder: (context, state) => SettingsZoneBinsPage(
        zoneId: state.pathParameters['zoneId'] ?? '',
        branchId: state.uri.queryParameters['warehouseId'] == null
            ? state.uri.queryParameters['branchId'] ??
                  state.uri.queryParameters['locationId'] ??
                  state.uri.queryParameters['branchId']
            : null,
        branchName: state.uri.queryParameters['warehouseName'] == null
            ? state.uri.queryParameters['branchName'] ??
                  state.uri.queryParameters['locationName'] ??
                  state.uri.queryParameters['branchName']
            : null,
        warehouseId: state.uri.queryParameters['warehouseId'],
        warehouseName: state.uri.queryParameters['warehouseName'],
        zoneName: state.uri.queryParameters['zoneName'] ?? '',
      ),
    ),
    GoRoute(
      path: 'settings/locations/create',
      name: AppRoutes.settingsLocationsCreate,
      redirect: (context, state) {
        final orgSystemId =
            state.pathParameters['orgSystemId'] ?? fallbackRouteSystemId;
        return '/$orgSystemId/settings/branches/create';
      },
    ),
    GoRoute(
      path: 'settings/locations/:id/edit',
      name: AppRoutes.settingsLocationsEdit,
      redirect: (context, state) {
        final orgSystemId =
            state.pathParameters['orgSystemId'] ?? fallbackRouteSystemId;
        final id = state.pathParameters['id'] ?? '';
        return '/$orgSystemId/settings/branches/$id/edit';
      },
    ),
    GoRoute(
      path: 'settings/branches',
      name: AppRoutes.settingsBranches,
      builder: (context, state) => const SettingsBranchesListPage(),
    ),
    GoRoute(
      path: 'settings/branches/create',
      name: AppRoutes.settingsBranchCreate,
      builder: (context, state) => const SettingsBranchCreatePage(),
    ),
    GoRoute(
      path: 'settings/branches/:id/edit',
      name: AppRoutes.settingsBranchEdit,
      builder: (context, state) =>
          SettingsBranchCreatePage(branchId: state.pathParameters['id']),
    ),
    GoRoute(
      path: 'settings/branches/:id/profile',
      name: AppRoutes.settingsBranchProfile,
      builder: (context, state) =>
          SettingsBranchProfilePage(branchId: state.pathParameters['id'] ?? ''),
    ),
    GoRoute(
      path: 'settings/warehouses',
      name: AppRoutes.settingsWarehouses,
      builder: (context, state) => const SettingsWarehousesListPage(),
    ),
    GoRoute(
      path: 'settings/warehouses/create',
      name: AppRoutes.settingsWarehouseCreate,
      builder: (context, state) => const SettingsWarehouseCreatePage(),
    ),
    GoRoute(
      path: 'settings/warehouses/:id/edit',
      name: AppRoutes.settingsWarehouseEdit,
      builder: (context, state) =>
          SettingsWarehouseCreatePage(warehouseId: state.pathParameters['id']),
    ),
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
    ...buildSettingsTaxesRoutes(),
    ...buildSettingsSetupRoutes(),
    ...buildSettingsCustomizationRoutes(),
    ...buildSettingsAutomationRoutes(),
    ...buildSettingsIntegrationsRoutes(),
    ...buildSettingsDeveloperRoutes(),
  ];
}
