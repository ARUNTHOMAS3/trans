import 'package:flutter/material.dart';
import 'package:zerpai_erp/modules/reports/automation/presentation/widgets/scheduled_workflow_report_page.dart';

class WorkflowExecutionLogsPage extends StatelessWidget {
  const WorkflowExecutionLogsPage({super.key});

  static const List<ScheduledWorkflowColumnConfig> _columns = [
    ScheduledWorkflowColumnConfig(label: 'TIME', flex: 14),
    ScheduledWorkflowColumnConfig(label: 'WORKFLOW', flex: 16),
    ScheduledWorkflowColumnConfig(label: 'RECORD NAME', flex: 16),
    ScheduledWorkflowColumnConfig(label: 'TRIGGERED BY', flex: 15),
    ScheduledWorkflowColumnConfig(label: 'EVENT TYPE', flex: 15),
    ScheduledWorkflowColumnConfig(label: 'WORKFLOW TRIGGERED', flex: 15),
    ScheduledWorkflowColumnConfig(label: 'EXECUTION STATUS', flex: 15),
  ];

  @override
  Widget build(BuildContext context) {
    return const ScheduledWorkflowReportPage(
      reportTitle: 'Workflow Execution Logs',
      customizeColumnCount: 7,
      columns: _columns,
      initialGroupBy: 'Execution Date',
      showTopDateLabel: false,
      showReloadAction: false,
      showEntityClearIndicator: true,
    );
  }
}
