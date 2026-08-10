import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/reports/automation/presentation/widgets/scheduled_workflow_report_page.dart';

class ScheduledTimeBasedWorkflowActionsPage extends StatelessWidget {
  const ScheduledTimeBasedWorkflowActionsPage({super.key});

  static const List<ScheduledWorkflowColumnConfig> _columns = [
    ScheduledWorkflowColumnConfig(
      label: 'EXECUTION DATE',
      flex: 17,
      isSorted: true,
    ),
    ScheduledWorkflowColumnConfig(label: 'TIME', flex: 16),
    ScheduledWorkflowColumnConfig(label: 'ACTION TYPE', flex: 17),
    ScheduledWorkflowColumnConfig(label: 'ACTION NAME', flex: 17),
    ScheduledWorkflowColumnConfig(label: 'WORKFLOW', flex: 16),
    ScheduledWorkflowColumnConfig(label: 'RECORD NAME', flex: 17),
  ];

  @override
  Widget build(BuildContext context) {
    return const ScheduledWorkflowReportPage(
      reportTitle: 'Scheduled Time Based Workflow Actions',
      customizeColumnCount: 6,
      columns: _columns,
    );
  }
}
