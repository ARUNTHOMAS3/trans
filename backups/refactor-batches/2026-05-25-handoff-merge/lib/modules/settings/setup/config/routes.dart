import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/modules/settings/shared/presentation/pages/settings_placeholder_page.dart';

List<GoRoute> buildSettingsSetupRoutes() {
  return [
    GoRoute(
      path: 'settings/general',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'General'),
    ),
    GoRoute(
      path: 'settings/currencies',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Currencies'),
    ),
    GoRoute(
      path: 'settings/reminders',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Reminders'),
    ),
    GoRoute(
      path: 'settings/customer-portal',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Customer Portal'),
    ),
  ];
}
