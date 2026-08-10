import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/activity/presentation/widgets/system_mails_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';

class SystemMailsReportScreen extends StatelessWidget {
  const SystemMailsReportScreen({super.key});

  static const List<SystemMailReportRow> _rows = [
    SystemMailReportRow(
      date: '25-07-2026',
      subject: 'New auto-generated invoice for the recurring profile: althaf',
      mailType: 'Draft Notification',
    ),
    SystemMailReportRow(
      date: '18-07-2026',
      subject: 'New auto-generated invoice for the recurring profile: althaf',
      mailType: 'Draft Notification',
    ),
    SystemMailReportRow(
      date: '12-07-2026',
      subject: 'New auto-generated invoice for the recurring profile: althaf',
      mailType: 'Draft Notification',
    ),
    SystemMailReportRow(
      date: '04-07-2026',
      subject: 'New auto-generated invoice for the recurring profile: althaf',
      mailType: 'Draft Notification',
    ),
    SystemMailReportRow(
      date: '27-06-2026',
      subject: 'New auto-generated invoice for the recurring profile: althaf',
      mailType: 'Draft Notification',
    ),
    SystemMailReportRow(
      date: '22-06-2026',
      subject: 'Purchase Request (PR-00009) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '20-06-2026',
      subject: 'New auto-generated invoice for the recurring profile: althaf',
      mailType: 'Draft Notification',
    ),
    SystemMailReportRow(
      date: '08-06-2026',
      subject: 'Purchase Request (PR-00004) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '06-06-2026',
      subject: 'Purchase Request (PR-00004) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '06-06-2026',
      subject: 'Purchase Request (PR-00004) has been rejected',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '25-05-2026',
      subject: 'Purchase Request (PR-00006) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '23-05-2026',
      subject: 'Purchase Request (PR-00005) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '23-05-2026',
      subject: 'Purchase Request (PR-00004) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '16-05-2026',
      subject: 'Purchase Request (PR-00003) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '16-05-2026',
      subject: 'Purchase Request (PR-00002) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '16-05-2026',
      subject: 'Purchase Request (PR-00001) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '16-05-2026',
      subject: 'Purchase Request (PR-00001) has been rejected',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '16-05-2026',
      subject: 'Purchase Request (PR-00001) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '09-05-2026',
      subject: 'Purchase Request (PR-00008) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '09-05-2026',
      subject: 'Purchase Request (PR-00008) has been rejected',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '02-05-2026',
      subject: 'Purchase Request (PR-00007) has been approved',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '25-04-2026',
      subject: 'New auto-generated invoice for the recurring profile: althaf',
      mailType: 'Draft Notification',
    ),
    SystemMailReportRow(
      date: '18-04-2026',
      subject: 'Purchase Request (PR-00003) has been rejected',
      mailType: 'Approval Notification',
    ),
    SystemMailReportRow(
      date: '11-04-2026',
      subject: 'New auto-generated invoice for the recurring profile: althaf',
      mailType: 'Draft Notification',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Activity',
      reportTitle: 'System Mails',
      dateLabel: '',
      companyName: 'ZABNIX PRIVATE LIMITED',
      filters: const [],
      showFilterBar: false,
      noticeBanner: const _ApplyFilterBar(),
      tableHeaderActions: const ReportCustomizeColumnsButton(count: 3),
      showSchedule: true,
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      currentNavigationCategory: 'Activity',
      currentNavigationReport: 'System Mails',
      onReportSelected: (reportName, category) {
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: SystemMailsTable(rows: _rows),
    );
  }
}

class _ApplyFilterBar extends StatelessWidget {
  const _ApplyFilterBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.filter,
            size: AppTheme.space16,
            color: AppTheme.primaryBlue,
          ),
          const SizedBox(width: AppTheme.space6),
          Text(
            'Apply Filter',
            style: AppTheme.bodyText.copyWith(color: AppTheme.primaryBlue),
          ),
        ],
      ),
    );
  }
}
