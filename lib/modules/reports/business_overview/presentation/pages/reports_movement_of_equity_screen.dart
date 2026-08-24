import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_section.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';

class MovementOfEquityScreen extends StatefulWidget {
  const MovementOfEquityScreen({super.key});

  @override
  State<MovementOfEquityScreen> createState() => _MovementOfEquityScreenState();
}

class _MovementOfEquityScreenState extends State<MovementOfEquityScreen> {
  static const String _dateLabel = 'From 01-07-2026 To 31-07-2026';

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  String _reportBasis = 'Accrual';

  static final DateTime _defaultDate = DateTime.now(); // Mock anchor date
  final DateTime _appliedEndDate = _defaultDate;
  static final _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');

  ReportCompareSelection _compareSelection = const ReportCompareSelection.none();
  ReportCompareSelection _appliedCompareSelection = const ReportCompareSelection.none();

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

  void _handleCompareSelectionApplied(ReportCompareSelection selection) {
    setState(() {
      _compareSelection = selection;
      _appliedCompareSelection = selection;
    });
  }

  List<String> _buildComparisonPeriods() {
    if (!_appliedCompareSelection.isActive) {
      return const <String>[];
    }
    final periods = <String>[];
    final count = _appliedCompareSelection.count;
    final type = _appliedCompareSelection.compareType;

    for (int i = count; i >= 1; i--) {
      if (type == 'Previous Year(s)') {
        final dt = DateTime(
          _appliedEndDate.year - i,
          _appliedEndDate.month,
          _appliedEndDate.day,
        );
        periods.add(_displayDateFormat.format(dt));
      } else if (type == 'Previous Period(s)') {
        periods.add('Period - $i');
      } else {
        periods.add('Compare $i');
      }
    }
    periods.add(_displayDateFormat.format(_appliedEndDate));
    return periods;
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: 'Movement of Equity',
      dateLabel: _dateLabel,
      contentSubtitle: 'Basis : $_reportBasis\n\n$_dateLabel',
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'Date Range',
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
      settingsTooltip: 'Customize the Movement of Equity report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportCompareSection(
            selectedValue: _compareSelection.displayValue,
            onSelectionApplied: _handleCompareSelectionApplied,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 2),
          const SizedBox(width: AppTheme.space10),
          ReportIconActionButton(
            icon: Icons.settings_outlined,
            onPressed: () {},
            tooltip: 'Customize report settings',
            chromeless: true,
          ),
        ],
      ),
      isLoading: false,
      currentNavigationCategory: 'Business Overview',
      currentNavigationReport: 'Movement of Equity',
      onReportSelected: (reportName, category) {
        if (reportName == 'Movement of Equity') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: _MovementOfEquityBody(
        comparisonPeriods: _buildComparisonPeriods(),
      ),
    );
  }
}

class _EquityMovementRow {
  final String account;
  final String total;
  final int indentLevel;
  final bool isSection;
  final bool isTotal;
  final bool isLink;

  const _EquityMovementRow({
    required this.account,
    required this.total,
    this.indentLevel = 0,
    this.isSection = false,
    this.isTotal = false,
    this.isLink = false,
  });
}

class _MovementOfEquityBody extends StatelessWidget {
  final List<String> comparisonPeriods;

  const _MovementOfEquityBody({required this.comparisonPeriods});

  static const List<_EquityMovementRow> _rows = [
    _EquityMovementRow(account: 'Opening Balance', total: '2,33,877.32'),
    _EquityMovementRow(
      account: 'Changes in Equity',
      total: '',
      isSection: true,
    ),
    _EquityMovementRow(
      account: 'Current Year Earnings',
      total: '1,287.40',
      indentLevel: 1,
      isLink: true,
    ),
    _EquityMovementRow(
      account: 'Net Changes in Equity',
      total: '1,287.40',
      isTotal: true,
    ),
    _EquityMovementRow(
      account: 'Closing Balance',
      total: '2,35,164.72',
      isTotal: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int extraCols = comparisonPeriods.isEmpty ? 0 : comparisonPeriods.length - 1;
        final double minWidth = 835.0 + (extraCols * 170.0);
        final tableWidth = constraints.maxWidth < minWidth ? constraints.maxWidth : minWidth;

        final tableHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 360.0;
        final table = SizedBox(
          width: tableWidth,
          height: tableHeight,
          child: ReportStickyHeaderScrollTable(
            header: _MovementTableHeader(comparisonPeriods: comparisonPeriods),
            emptyBody: const SizedBox.shrink(),
            children: [
              for (final row in _rows) 
                _MovementTableRow(
                  row: row,
                  comparisonPeriods: comparisonPeriods,
                ),
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

class _MovementTableHeader extends StatelessWidget {
  final List<String> comparisonPeriods;
  const _MovementTableHeader({required this.comparisonPeriods});

  @override
  Widget build(BuildContext context) {
    final bool hasComparison = comparisonPeriods.isNotEmpty;
    return Container(
      height: hasComparison ? 68 : 34,
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: hasComparison
          ? Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      for (final period in comparisonPeriods)
                        SizedBox(
                          width: 170,
                          child: Center(
                            child: Text(
                              period,
                              style: ReportTableTypography.header,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                          child: Row(
                            children: [
                              Text('ACCOUNT', style: ReportTableTypography.header),
                              const SizedBox(width: AppTheme.space4),
                              const Icon(
                                Icons.unfold_more,
                                size: AppTheme.space12,
                                color: AppTheme.primaryBlue,
                              ),
                            ],
                          ),
                        ),
                      ),
                      for (final _ in comparisonPeriods)
                        SizedBox(
                          width: 170,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                            child: Text(
                              'TOTAL',
                              textAlign: TextAlign.right,
                              style: ReportTableTypography.header,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                    child: Row(
                      children: [
                        Text('ACCOUNT', style: ReportTableTypography.header),
                        const SizedBox(width: AppTheme.space4),
                        const Icon(
                          Icons.unfold_more,
                          size: AppTheme.space12,
                          color: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                    child: Text(
                      'TOTAL',
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

class _MovementTableRow extends StatelessWidget {
  final _EquityMovementRow row;
  final List<String> comparisonPeriods;

  const _MovementTableRow({
    required this.row,
    required this.comparisonPeriods,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: row.isLink ? AppTheme.primaryBlue : AppTheme.textPrimary,
      fontWeight: row.isSection || row.isTotal
          ? FontWeight.w700
          : FontWeight.w400,
    );
    final amountStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: row.isLink ? AppTheme.primaryBlue : AppTheme.textPrimary,
      fontWeight: FontWeight.w400,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.space20 + (row.indentLevel * AppTheme.space16),
          right: AppTheme.space20,
          top: row.isSection ? AppTheme.space14 : AppTheme.space10,
          bottom: AppTheme.space10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(child: Text(row.account, style: labelStyle)),
                ],
              ),
            ),
            if (comparisonPeriods.isEmpty)
              SizedBox(
                width: 170,
                child: Text(
                  row.total,
                  textAlign: TextAlign.right,
                  style: amountStyle,
                ),
              )
            else
              for (final _ in comparisonPeriods)
                SizedBox(
                  width: 170,
                  child: Text(
                    row.total,
                    textAlign: TextAlign.right,
                    style: amountStyle,
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
