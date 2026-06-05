import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/modules/settings/automation/presentation/pages/settings_workflow_actions_page.dart';
import 'package:zerpai_erp/modules/settings/automation/presentation/pages/settings_workflow_investigation_page.dart';
import 'package:zerpai_erp/modules/settings/automation/presentation/pages/settings_workflow_logs_page.dart';
import 'package:zerpai_erp/modules/settings/automation/presentation/pages/settings_workflow_mission_control_page.dart';
import 'package:zerpai_erp/modules/settings/automation/presentation/pages/settings_workflow_operations_center_page.dart';
import 'package:zerpai_erp/modules/settings/automation/presentation/pages/settings_workflow_rules_page.dart';

List<GoRoute> buildSettingsAutomationRoutes() {
  return [
    GoRoute(
      path: 'settings/workflow-rules',
      builder: (context, state) => const SettingsWorkflowRulesPage(),
    ),
    GoRoute(
      path: 'settings/workflow-actions',
      builder: (context, state) => const SettingsWorkflowActionsPage(),
    ),
    GoRoute(
      path: 'settings/workflow-logs',
      builder: (context, state) => const SettingsWorkflowLogsPage(),
    ),
    GoRoute(
      path: 'settings/workflow-ops-center',
      builder: (context, state) => const SettingsWorkflowOperationsCenterPage(),
    ),
    GoRoute(
      path: 'settings/workflow-investigation',
      builder: (context, state) => SettingsWorkflowInvestigationPage(
        initialTransactionType: state.uri.queryParameters['type'],
        initialTransactionId: state.uri.queryParameters['id'],
      ),
    ),
    GoRoute(
      path: 'settings/workflow-mission-control',
      builder: (context, state) => const SettingsWorkflowMissionControlPage(),
    ),
  ];
}
