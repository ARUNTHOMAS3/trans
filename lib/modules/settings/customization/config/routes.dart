import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/settings/customization/pdf_templates/presentation/pages/printing_templates_overview.dart';
import 'package:zerpai_erp/modules/settings/shared/presentation/pages/settings_placeholder_page.dart';

List<GoRoute> buildSettingsCustomizationRoutes() {
  return [
    GoRoute(
      path: 'settings/transaction-number-series',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Transaction Number Series'),
    ),
    GoRoute(
      path: 'settings/pdf-templates',
      name: AppRoutes.settingsPdfTemplates,
      builder: (context, state) => const PrintTemplatesPage(),
    ),
    GoRoute(
      path: 'settings/email-notifications',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Email Notifications'),
    ),
    GoRoute(
      path: 'settings/sms-notifications',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'SMS Notifications'),
    ),
    GoRoute(
      path: 'settings/reporting-tags',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Reporting Tags'),
    ),
    GoRoute(
      path: 'settings/web-tabs',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Web Tabs'),
    ),
  ];
}
