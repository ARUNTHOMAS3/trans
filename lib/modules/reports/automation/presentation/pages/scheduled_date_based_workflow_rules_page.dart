import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/reports/automation/presentation/widgets/scheduled_workflow_report_page.dart';

class ScheduledDateBasedWorkflowRulesPage extends StatelessWidget {
  const ScheduledDateBasedWorkflowRulesPage({super.key});

  static const List<ScheduledWorkflowColumnConfig> _columns = [
    ScheduledWorkflowColumnConfig(
      label: 'EXECUTION DATE',
      flex: 24,
      isSorted: true,
    ),
    ScheduledWorkflowColumnConfig(label: 'TIME', flex: 23),
    ScheduledWorkflowColumnConfig(label: 'WORKFLOW', flex: 25),
    ScheduledWorkflowColumnConfig(label: 'RECORD NAME', flex: 28),
  ];

  @override
  Widget build(BuildContext context) {
    return const ScheduledWorkflowReportPage(
      reportTitle: 'Scheduled Date Based Workflow Rules',
      customizeColumnCount: 4,
      columns: _columns,
    );
  }
}
