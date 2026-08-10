import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_empty_state.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';

class SalesChannelIntegrationsSyncSummaryTable extends StatelessWidget {
  const SalesChannelIntegrationsSyncSummaryTable({super.key});

  @override
  Widget build(BuildContext context) {
    return ReportStickyHeaderScrollTable(
      header: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space20,
          vertical: AppTheme.space10,
        ),
        decoration: const BoxDecoration(
          color: AppTheme.tableHeaderBg,
          border: Border(
            top: BorderSide(color: AppTheme.borderColor),
            bottom: BorderSide(color: AppTheme.borderColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 13,
              child: Text('SYNC DATE', style: ReportTableTypography.header),
            ),
            Expanded(
              flex: 14,
              child: Text('INTEGRATION', style: ReportTableTypography.header),
            ),
            Expanded(
              flex: 14,
              child: Text('STORE', style: ReportTableTypography.header),
            ),
            Expanded(
              flex: 16,
              child: Text('SYNC TYPE', style: ReportTableTypography.header),
            ),
            Expanded(
              flex: 16,
              child: Text(
                'SUCCESSFUL SYNCS',
                textAlign: TextAlign.right,
                style: ReportTableTypography.header,
              ),
            ),
            Expanded(
              flex: 13,
              child: Text(
                'FAILED SYNCS',
                textAlign: TextAlign.right,
                style: ReportTableTypography.header,
              ),
            ),
            Expanded(
              flex: 14,
              child: Text(
                'TOTAL ATTEMPTS',
                textAlign: TextAlign.right,
                style: ReportTableTypography.header,
              ),
            ),
          ],
        ),
      ),
      emptyBody: const ReportTableEmptyBody(),
      isEmpty: true,
      children: const [],
    );
  }
}
