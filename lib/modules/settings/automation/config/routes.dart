import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/modules/settings/shared/presentation/pages/settings_placeholder_page.dart';

List<GoRoute> buildSettingsAutomationRoutes() {
  return [
    GoRoute(
      path: 'settings/workflow-rules',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Workflow Rules'),
    ),
    GoRoute(
      path: 'settings/workflow-actions',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Workflow Actions'),
    ),
    GoRoute(
      path: 'settings/workflow-logs',
      builder: (context, state) =>
          const SettingsPlaceholderPage(title: 'Workflow Logs'),
    ),
  ];
}
