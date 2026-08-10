import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_selection_section.dart';

class BalanceSheetScheduleIIIScreen extends StatefulWidget {
  const BalanceSheetScheduleIIIScreen({super.key});

  @override
  State<BalanceSheetScheduleIIIScreen> createState() =>
      _BalanceSheetScheduleIIIScreenState();
}

class _BalanceSheetScheduleIIIScreenState
    extends State<BalanceSheetScheduleIIIScreen> {
  static const String _dateLabel = 'As of 31-07-2026';

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  String _reportBasis = 'Accrual';
  String _reportView = 'Simplified View';

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _cycleReportBasis() {
    setState(() {
      _reportBasis = _reportBasis == 'Accrual' ? 'Cash' : 'Accrual';
      _hasPendingFilterChanges = true;
    });
  }

  void _handleReportViewChanged(String view) {
    setState(() {
      _reportView = view;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: 'Balance Sheet (Schedule III)',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'As of',
          value: 'This Month',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'Report Basis',
          value: _reportBasis,
          onPressed: _cycleReportBasis,
        ),
        ReportFilterChip(
          label: 'More Filters',
          value: '',
          leadingIcon: LucideIcons.plusCircle,
          showChevron: false,
          showLabelColon: false,
          onPressed: _toggleMoreFilters,
        ),
      ],
      onRunReport: _runReport,
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: false,
      onReload: _runReport,
      onRefresh: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the Balance Sheet (Schedule III) report.',
      tableHeaderActions: ReportViewSelectionSection(
        selectedValue: _reportView,
        onChanged: (val) => _handleReportViewChanged(val),
      ),
      isLoading: false,
      currentNavigationCategory: 'Business Overview',
      currentNavigationReport: 'Balance Sheet (Schedule III)',
      onReportSelected: (reportName, category) {
        if (reportName == 'Balance Sheet (Schedule III)') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: _BalanceSheetScheduleIIIStatement(
        reportBasis: _reportBasis,
        reportView: _reportView,
      ),
    );
  }
}

class _ScheduleIIIBalanceRow {
  final String particulars;
  final String currentAmount;
  final String previousAmount;
  final int indentLevel;
  final bool isSection;
  final bool isEmphasized;
  final bool isGrandTotal;
  final bool isLink;

  const _ScheduleIIIBalanceRow({
    required this.particulars,
    required this.currentAmount,
    required this.previousAmount,
    this.indentLevel = 0,
    this.isSection = false,
    this.isEmphasized = false,
    this.isGrandTotal = false,
    this.isLink = false,
  });
}

class _BalanceSheetScheduleIIIStatement extends StatelessWidget {
  final String reportBasis;
  final String reportView;

  const _BalanceSheetScheduleIIIStatement({
    required this.reportBasis,
    required this.reportView,
  });

  static const List<_ScheduleIIIBalanceRow> _rows = [
    _ScheduleIIIBalanceRow(
      particulars: 'EQUITY AND LIABILITIES',
      currentAmount: '',
      previousAmount: '',
      isSection: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: "1. Shareholders' funds",
      currentAmount: '',
      previousAmount: '',
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'a. Share Capital',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'b. Reserves and Surplus',
      currentAmount: '2,35,164.72',
      previousAmount: '2,33,877.32',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'c. Money received against share warrants',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: '2. Share application money pending allotment',
      currentAmount: '0.00',
      previousAmount: '0.00',
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: '3. Non-current liabilities',
      currentAmount: '',
      previousAmount: '',
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'a. Long Term Borrowings',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'b. Deferred Tax Liabilities (Net)',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'c. Other long term liabilities',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'd. Long Term Provisions',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: '4. Current Liabilities',
      currentAmount: '',
      previousAmount: '',
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'a. Short-term borrowings',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'b. Trade Payables',
      currentAmount: '74,831.05',
      previousAmount: '74,831.05',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'c. Other Current Liabilities',
      currentAmount: '29,32,179.14',
      previousAmount: '29,31,937.74',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'd. Short Term Provisions',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'TOTAL EQUITY AND LIABILITIES',
      currentAmount: '32,42,174.91',
      previousAmount: '32,40,646.11',
      isGrandTotal: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'ASSETS',
      currentAmount: '',
      previousAmount: '',
      isSection: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: '1. Non-current assets',
      currentAmount: '',
      previousAmount: '',
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'a. Fixed Assets',
      currentAmount: '',
      previousAmount: '',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'i. Tangible Assets',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 2,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'ii. InTangible Assets',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 2,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'iii. Capital Work-in-progress',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 2,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'iv. InTangible assets under development',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 2,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'b. Non-current investments',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'c. Deferred Tax Assets (Net)',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'd. Long term loans and advances',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'e. Other non-current assets',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: '2. Current Assets',
      currentAmount: '',
      previousAmount: '',
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'a. Current Investments',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'b. Inventories',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'c. Trade Receivables',
      currentAmount: '7,10,737.00',
      previousAmount: '7,10,528.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'd. Cash and cash equivalents',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'e. Short term loans and advances',
      currentAmount: '0.00',
      previousAmount: '0.00',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'f. Other current assets',
      currentAmount: '25,31,437.91',
      previousAmount: '25,30,118.11',
      indentLevel: 1,
      isEmphasized: true,
    ),
    _ScheduleIIIBalanceRow(
      particulars: 'TOTAL ASSETS',
      currentAmount: '32,42,174.91',
      previousAmount: '32,40,646.11',
      isGrandTotal: true,
    ),
  ];

  List<_ScheduleIIIBalanceRow> _buildRows() {
    if (reportView == 'Simplified View') return _rows;

    final List<_ScheduleIIIBalanceRow> rows = [];
    for (final row in _rows) {
      rows.add(row);
      if (row.particulars == 'b. Reserves and Surplus') {
        rows.add(
          const _ScheduleIIIBalanceRow(
            particulars: 'Current Year Earnings',
            currentAmount: '3,34,992.38',
            previousAmount: '3,34,712.38',
            indentLevel: 2,
            isLink: true,
          ),
        );
        rows.add(
          const _ScheduleIIIBalanceRow(
            particulars: 'Retained Earnings',
            currentAmount: '12,042.38',
            previousAmount: '12,042.38',
            indentLevel: 2,
            isLink: true,
          ),
        );
      }
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const tableWidth = 825.0;
        final tableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 480.0;
        final table = SizedBox(
          width: tableWidth,
          height: tableHeight,
          child: ReportStickyHeaderScrollTable(
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Basis : $reportBasis',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.space24),
                const _ScheduleIIITableHeader(),
              ],
            ),
            emptyBody: const SizedBox.shrink(),
            children: [
              for (final row in _buildRows()) _ScheduleIIITableRow(row),
              const SizedBox(height: AppTheme.space24),
              const _BaseCurrencyNote(),
              const SizedBox(height: AppTheme.space10),
            ],
          ),
        );

        if (constraints.maxWidth < tableWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: table,
          );
        }

        return Center(child: table);
      },
    );
  }
}

class _ScheduleIIITableHeader extends StatelessWidget {
  const _ScheduleIIITableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
              child: Text('PARTICULARS', style: ReportTableTypography.header),
            ),
          ),
          SizedBox(
            width: 110,
            child: Text(
              'NOTE NO.',
              textAlign: TextAlign.center,
              style: ReportTableTypography.header,
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              '31-07-2026',
              textAlign: TextAlign.right,
              style: ReportTableTypography.header,
            ),
          ),
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.only(right: AppTheme.space20),
              child: Text(
                '30-06-2026',
                textAlign: TextAlign.right,
                style: ReportTableTypography.header,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleIIITableRow extends StatelessWidget {
  final _ScheduleIIIBalanceRow row;

  const _ScheduleIIITableRow(this.row);

  @override
  Widget build(BuildContext context) {
    final bool isLink = row.isLink;

    final textStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: isLink ? AppTheme.primaryBlue : AppTheme.textPrimary,
      fontWeight: row.isSection || row.isEmphasized || row.isGrandTotal
          ? FontWeight.w700
          : FontWeight.w400,
    );
    final hasAmounts =
        row.currentAmount.isNotEmpty || row.previousAmount.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: row.isGrandTotal
            ? const Border(bottom: BorderSide(color: AppTheme.borderLight))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.space20 + (row.indentLevel * AppTheme.space16),
          right: AppTheme.space20,
          top: row.isSection ? AppTheme.space14 : AppTheme.space10,
          bottom: row.isGrandTotal ? AppTheme.space14 : AppTheme.space10,
        ),
        child: Row(
          children: [
            Expanded(child: Text(row.particulars, style: textStyle)),
            const SizedBox(width: 110),
            SizedBox(
              width: 120,
              child: Text(
                row.currentAmount,
                textAlign: TextAlign.right,
                style: textStyle.copyWith(
                  fontWeight: hasAmounts || row.isGrandTotal
                      ? FontWeight.w700
                      : textStyle.fontWeight,
                ),
              ),
            ),
            SizedBox(
              width: 120,
              child: Text(
                row.previousAmount,
                textAlign: TextAlign.right,
                style: textStyle.copyWith(
                  fontWeight: hasAmounts || row.isGrandTotal
                      ? FontWeight.w700
                      : textStyle.fontWeight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BaseCurrencyNote extends StatelessWidget {
  const _BaseCurrencyNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.space20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '**Amount is displayed in your base currency',
            style: AppTheme.captionText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppTheme.space4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space4,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.successTextDark,
              borderRadius: BorderRadius.circular(1),
            ),
            child: Text(
              'INR',
              style: AppTheme.captionText.copyWith(
                color: AppTheme.backgroundColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
