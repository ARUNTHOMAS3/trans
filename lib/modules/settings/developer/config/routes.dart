import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/settings/shared/presentation/pages/settings_placeholder_page.dart';

List<GoRoute> buildSettingsDeveloperRoutes() {
  return [
    GoRoute(
      path: 'settings/developer/incoming-webhooks',
      name: AppRoutes.settingsDeveloperIncomingWebhooks,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Incoming Webhooks'),
    ),
    GoRoute(
      path: 'settings/developer/connections',
      name: AppRoutes.settingsDeveloperConnections,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Connections'),
    ),
    GoRoute(
      path: 'settings/developer/api-usage',
      name: AppRoutes.settingsDeveloperApiUsage,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'API Usage'),
    ),
    GoRoute(
      path: 'settings/developer/data-management',
      name: AppRoutes.settingsDeveloperDataManagement,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Data Management'),
    ),
    GoRoute(
      path: 'settings/developer/deluge-components',
      name: AppRoutes.settingsDeveloperDelugeComponents,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Deluge Components Usage'),
    ),
    GoRoute(
      path: 'settings/developer/web-forms',
      name: AppRoutes.settingsDeveloperWebForms,
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Web Forms'),
    ),
  ];
}
