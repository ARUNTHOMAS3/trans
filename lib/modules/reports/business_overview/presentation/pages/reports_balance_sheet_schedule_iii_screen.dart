import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_selection_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/business_overview/data/providers/balance_sheet_schedule_iii_provider.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';

class BalanceSheetScheduleIIIScreen extends ConsumerStatefulWidget {
  const BalanceSheetScheduleIIIScreen({super.key});

  @override
  ConsumerState<BalanceSheetScheduleIIIScreen> createState() =>
      _BalanceSheetScheduleIIIScreenState();
}

class _BalanceSheetScheduleIIIScreenState
    extends ConsumerState<BalanceSheetScheduleIIIScreen> {
  static final DateTime _defaultDate = DateTime.now();
  static const List<String> _reportBasisOptions = <String>['Accrual', 'Cash'];
  static final _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  DateTime _startDate = _defaultDate;
  DateTime _endDate = _defaultDate;
  DateTime _appliedStartDate = _defaultDate;
  DateTime _appliedEndDate = _defaultDate;
  String _reportBasis = 'Accrual';
  String _appliedReportBasis = 'Accrual';
  String _reportView = 'Simplified View';

  String get _dateLabel =>
      'From ${_displayDateFormat.format(_appliedStartDate)} To ${_displayDateFormat.format(_appliedEndDate)}';

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleReportBasisChanged(String value) {
    if (_reportBasis == value) return;
    setState(() {
      _reportBasis = value;
      _hasPendingFilterChanges = true;
    });
  }

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

  void _handleReportViewChanged(String view) {
    setState(() {
      _reportView = view;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _appliedReportBasis = _reportBasis;
      _hasPendingFilterChanges = false;
    });
    ref.invalidate(balanceSheetScheduleIIIProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: 'Balance Sheet (Schedule III)',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          onChanged: _handleDateRangeChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Report Basis',
          value: _reportBasis,
          options: _reportBasisOptions,
          onChanged: _handleReportBasisChanged,
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
        reportBasis: _appliedReportBasis,
        reportView: _reportView,
        startDate: _appliedStartDate,
        endDate: _appliedEndDate,
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
  final bool isGrandTotal;

  const _ScheduleIIIBalanceRow({
    required this.particulars,
    required this.currentAmount,
    required this.previousAmount,
    this.indentLevel = 0,
    this.isSection = false,
    this.isGrandTotal = false,
  });
}

class _BalanceSheetScheduleIIIStatement extends ConsumerWidget {
  final String reportBasis;
  final String reportView;
  final DateTime startDate;
  final DateTime endDate;

  const _BalanceSheetScheduleIIIStatement({
    required this.reportBasis,
    required this.reportView,
    required this.startDate,
    required this.endDate,
  });

  List<String> get _periodLabels {
    if (startDate.isAtSameMomentAs(endDate)) {
      final format = ReportFormatterCache.date('dd-MM-yyyy');
      return [
        format.format(startDate),
        format.format(startDate.subtract(const Duration(days: 1))),
      ];
    } else {
      final format = ReportFormatterCache.date('MMM dd');
      final duration = endDate.difference(startDate).inDays + 1;
      final prevStart = startDate.subtract(Duration(days: duration));
      final prevEnd = endDate.subtract(Duration(days: duration));

      return [
        '${format.format(startDate).toUpperCase()} - ${format.format(endDate).toUpperCase()}',
        '${format.format(prevStart).toUpperCase()} - ${format.format(prevEnd).toUpperCase()}',
      ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = BalanceSheetScheduleIIIRequest(
      startDate: startDate,
      endDate: endDate,
      basis: reportBasis,
    );

    final asyncData = ref.watch(balanceSheetScheduleIIIProvider(request));

    return asyncData.when(
      loading: () => const Padding(padding: EdgeInsets.all(AppTheme.space16), child: SingleChildScrollView(physics: NeverScrollableScrollPhysics(), child: ZTableSkeleton(rows: 5, columns: 3))),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) {
        final assets = (data['assets'] as List<dynamic>?) ?? [];
        final liabilitiesAndEquity = (data['equitiesAndLiabilities'] as List<dynamic>?) ?? [];

        final List<_ScheduleIIIBalanceRow> dynamicRows = [];

        // EQUITIES AND LIABILITIES
        dynamicRows.add(const _ScheduleIIIBalanceRow(particulars: 'I. EQUITIES AND LIABILITIES', currentAmount: '', previousAmount: '', isSection: true));
        double totalEquitiesAndLiabilities = 0;
        for (final item in liabilitiesAndEquity) {
          final balance = double.tryParse(item['balance'].toString()) ?? 0.0;
          totalEquitiesAndLiabilities += balance;
          dynamicRows.add(_ScheduleIIIBalanceRow(
            particulars: item['accountName'] as String,
            currentAmount: balance.toStringAsFixed(2),
            previousAmount: '0.00',
            indentLevel: 1,
          ));
        }
        dynamicRows.add(_ScheduleIIIBalanceRow(particulars: 'Total', currentAmount: totalEquitiesAndLiabilities.toStringAsFixed(2), previousAmount: '0.00', isGrandTotal: true));

        // ASSETS
        dynamicRows.add(const _ScheduleIIIBalanceRow(particulars: 'II. ASSETS', currentAmount: '', previousAmount: '', isSection: true));
        double totalAssets = 0;
        for (final item in assets) {
          final balance = double.tryParse(item['balance'].toString()) ?? 0.0;
          totalAssets += balance;
          dynamicRows.add(_ScheduleIIIBalanceRow(
            particulars: item['accountName'] as String,
            currentAmount: balance.toStringAsFixed(2),
            previousAmount: '0.00',
            indentLevel: 1,
          ));
        }
        dynamicRows.add(_ScheduleIIIBalanceRow(particulars: 'Total', currentAmount: totalAssets.toStringAsFixed(2), previousAmount: '0.00', isGrandTotal: true));

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
                    _ScheduleIIITableHeader(
                      currentPeriodLabel: _periodLabels[0],
                      previousPeriodLabel: _periodLabels[1],
                    ),
                  ],
                ),
                emptyBody: const SizedBox.shrink(),
                children: [
                  for (final row in dynamicRows) _ScheduleIIITableRow(row),
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
      },
    );
  }
}

class _ScheduleIIITableHeader extends StatelessWidget {
  final String currentPeriodLabel;
  final String previousPeriodLabel;

  const _ScheduleIIITableHeader({
    required this.currentPeriodLabel,
    required this.previousPeriodLabel,
  });

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
              currentPeriodLabel,
              textAlign: TextAlign.right,
              style: ReportTableTypography.header,
            ),
          ),
          SizedBox(
            width: 120,
            child: Padding(
              padding: const EdgeInsets.only(right: AppTheme.space20),
              child: Text(
                previousPeriodLabel,
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
    final textStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: AppTheme.textPrimary,
      fontWeight: row.isSection || row.isGrandTotal
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
