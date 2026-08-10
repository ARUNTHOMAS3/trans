import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/payments_received/presentation/widgets/time_to_get_paid_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';

class TimeToGetPaidPage extends StatefulWidget {
  const TimeToGetPaidPage({super.key});

  @override
  State<TimeToGetPaidPage> createState() => _TimeToGetPaidPageState();
}

class _TimeToGetPaidPageState extends State<TimeToGetPaidPage> {
  static const String _reportTitle = 'Time to Get Paid';
  static const String _contentSubtitle = 'As of  15-07-2026';
  static const int _pageSize = 10;

  static const List<TimeToGetPaidRow> _rows = [
    TimeToGetPaidRow(
      customerName: 'althaf m',
      zeroToFifteenDays: '100%',
      sixteenToThirtyDays: '0%',
      thirtyOneToFortyFiveDays: '0%',
      aboveFortyFiveDays: '0%',
    ),
    TimeToGetPaidRow(
      customerName: 'STARLEX HEALTH SERVICES &\nPRODUCTS PVT LTD',
      zeroToFifteenDays: '8.8235%',
      sixteenToThirtyDays: '7.3529%',
      thirtyOneToFortyFiveDays: '0%',
      aboveFortyFiveDays: '83.8235%',
    ),
    TimeToGetPaidRow(
      customerName: 'Walk-in Customer',
      zeroToFifteenDays: '100%',
      sixteenToThirtyDays: '0%',
      thirtyOneToFortyFiveDays: '0%',
      aboveFortyFiveDays: '0%',
    ),
  ];

  String _groupBy = 'None';
  int _page = 1;

  void _handleGroupByChanged(String value) {
    if (_groupBy == value) return;
    setState(() => _groupBy = value);
  }

  void _handlePageChanged(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Payments Received',
      reportTitle: _reportTitle,
      dateLabel: '',
      contentSubtitle: _contentSubtitle,
      companyName: '',
      filters: const [],
      showFilterBar: false,
      noticeBanner: _ApplyFilterBar(onPressed: () {}),
      showReload: true,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: _reportTitle,
      ),
      onReload: () {},
      onRefresh: () {},
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the Time to Get Paid report.',
      scheduleTooltip: 'Schedule the Time to Get Paid report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: const <String>[
              'None',
              'Currency',
            ],
            onChanged: _handleGroupByChanged,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 5),
        ],
      ),
      isLoading: false,
      currentNavigationCategory: 'Payments Received',
      currentNavigationReport: 'Time to Get Paid',
      onReportSelected: (reportName, category) {
        if (reportName == 'Time to Get Paid') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: TimeToGetPaidTable(
        rows: _rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        groupBy: _groupBy,
      ),
    );
  }
}

class _ApplyFilterBar extends StatelessWidget {
  final VoidCallback onPressed;

  const _ApplyFilterBar({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space24,
        AppTheme.space12,
        AppTheme.space24,
        AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.space4),
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
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
