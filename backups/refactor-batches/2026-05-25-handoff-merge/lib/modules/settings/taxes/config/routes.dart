import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/modules/settings/shared/presentation/pages/settings_placeholder_page.dart';

List<GoRoute> buildSettingsTaxesRoutes() {
  return [
    GoRoute(
      path: 'settings/taxes',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Taxes'),
    ),
    GoRoute(
      path: 'settings/direct-taxes',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Direct Taxes'),
    ),
    GoRoute(
      path: 'settings/eway-bills',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'e-Way Bills'),
    ),
    GoRoute(
      path: 'settings/einvoicing',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'e-Invoicing'),
    ),
    GoRoute(
      path: 'settings/msme',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'MSME Settings'),
    ),
  ];
}
