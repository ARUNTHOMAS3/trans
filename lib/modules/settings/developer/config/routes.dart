import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/modules/settings/shared/presentation/pages/settings_placeholder_page.dart';

List<GoRoute> buildSettingsDeveloperRoutes() {
  return [
    GoRoute(
      path: 'settings/developer/incoming-webhooks',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Incoming Webhooks'),
    ),
    GoRoute(
      path: 'settings/developer/connections',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Connections'),
    ),
    GoRoute(
      path: 'settings/developer/api-usage',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'API Usage'),
    ),
    GoRoute(
      path: 'settings/developer/data-management',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Data Management'),
    ),
    GoRoute(
      path: 'settings/developer/deluge-components',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Deluge Components Usage'),
    ),
    GoRoute(
      path: 'settings/developer/web-forms',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Web Forms'),
    ),
  ];
}
