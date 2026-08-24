import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/business_overview/data/providers/profit_and_loss_schedule_iii_provider.dart';
import 'package:intl/intl.dart';



class ProfitAndLossScheduleIIIScreen extends ConsumerStatefulWidget {
  const ProfitAndLossScheduleIIIScreen({super.key});

  @override
  ConsumerState<ProfitAndLossScheduleIIIScreen> createState() =>
      _ProfitAndLossScheduleIIIScreenState();
}

class _ProfitAndLossScheduleIIIScreenState
    extends ConsumerState<ProfitAndLossScheduleIIIScreen> {
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

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

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

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }


  void _cycleReportView() {
    const views = <String>['Simplified View', 'Detailed View'];
    final nextIndex = (views.indexOf(_reportView) + 1) % views.length;
    setState(() {
      _reportView = views[nextIndex];
      _hasPendingFilterChanges = true;
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
  }

  @override
  Widget build(BuildContext context) {
    final providerValue = ref.watch(profitAndLossScheduleIIIProvider((
      startDate: ReportFormatterCache.date('yyyy-MM-dd').format(_appliedStartDate),
      endDate: ReportFormatterCache.date('yyyy-MM-dd').format(_appliedEndDate),
    )));
    
    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: 'Profit and Loss (Schedule III)',
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
      settingsTooltip: 'Customize the Profit and Loss (Schedule III) report.',
      tableHeaderActions: ReportTextActionButton(
        label: 'Select Report View : $_reportView',
        icon: Icons.request_page_outlined,
        onPressed: _cycleReportView,
      ),
      isLoading: providerValue.isLoading,
      currentNavigationCategory: 'Business Overview',
      currentNavigationReport: 'Profit and Loss (Schedule III)',
      onReportSelected: (reportName, category) {
        if (reportName == 'Profit and Loss (Schedule III)') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: providerValue.when(
        data: (data) => _ProfitAndLossScheduleIIIStatement(
          reportBasis: _appliedReportBasis,
          data: data,
          startDate: _appliedStartDate,
          endDate: _appliedEndDate,
        ),
        loading: () => const SizedBox.shrink(),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ScheduleIIIRow {
  final String particulars;
  final String currentAmount;
  final String previousAmount;
  final bool isEmphasized;
  final bool isIndented;

  const _ScheduleIIIRow({
    required this.particulars,
    required this.currentAmount,
    required this.previousAmount,
    this.isEmphasized = false,
    this.isIndented = false,
  });
}

class _ProfitAndLossScheduleIIIStatement extends StatelessWidget {
  final String reportBasis;
  final Map<String, dynamic> data;
  final DateTime startDate;
  final DateTime endDate;

  const _ProfitAndLossScheduleIIIStatement({
    required this.reportBasis,
    required this.data,
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

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    final numValue = (amount is num) ? amount : double.tryParse(amount.toString()) ?? 0.0;
    return NumberFormat('#,##0.00').format(numValue);
  }

  List<_ScheduleIIIRow> get _rows {
    final summary = data['summary'] ?? {};
    
    return [
      _ScheduleIIIRow(
        particulars: 'I. Revenue from operations',
        currentAmount: _formatAmount(summary['totalRevenueFromOperations']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: 'II. Other Income',
        currentAmount: _formatAmount(summary['totalOtherIncome']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: 'III. Total Revenue (I + II)',
        currentAmount: _formatAmount(summary['totalRevenue']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: 'IV. Expenses',
        currentAmount: _formatAmount(summary['totalExpenses']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: '1. Cost of materials consumed',
        currentAmount: _formatAmount(summary['totalCostOfMaterialsConsumed']),
        previousAmount: '0.00',
        isIndented: true,
      ),
      _ScheduleIIIRow(
        particulars: '2. Purchases of stock in trade',
        currentAmount: _formatAmount(summary['totalPurchasesOfStockInTrade']),
        previousAmount: '0.00',
        isIndented: true,
      ),
      _ScheduleIIIRow(
        particulars:
            '3. Changes in Inventories of finished goods work-in-progress and Stock-in-trade',
        currentAmount: _formatAmount(summary['totalChangesInInventories']),
        previousAmount: '0.00',
        isIndented: true,
      ),
      _ScheduleIIIRow(
        particulars: '4. Employee benefits expense',
        currentAmount: _formatAmount(summary['totalEmployeeBenefitsExpense']),
        previousAmount: '0.00',
        isIndented: true,
      ),
      _ScheduleIIIRow(
        particulars: '5. Finance Costs',
        currentAmount: _formatAmount(summary['totalFinanceCosts']),
        previousAmount: '0.00',
        isIndented: true,
      ),
      _ScheduleIIIRow(
        particulars: '6. Depreciation And Amortization Expense',
        currentAmount: _formatAmount(summary['totalDepreciation']),
        previousAmount: '0.00',
        isIndented: true,
      ),
      _ScheduleIIIRow(
        particulars: '7. Other Expenses',
        currentAmount: _formatAmount(summary['totalOtherExpenses']),
        previousAmount: '0.00',
        isIndented: true,
      ),
      _ScheduleIIIRow(
        particulars:
            'V. Profit before exceptional and extraordinary items and tax (III - IV)',
        currentAmount: _formatAmount(summary['profitBeforeExceptionalItemsAndTax']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: 'VI. Exceptional Items',
        currentAmount: _formatAmount(summary['totalExceptionalItems']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: 'VII. Profit before extraordinary items and tax (V-VI)',
        currentAmount: _formatAmount(summary['profitBeforeExtraordinaryItemsAndTax']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: 'VIII. Extraordinary Items',
        currentAmount: _formatAmount(summary['totalExtraordinaryItems']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: 'IX. Profit before tax (VII - VIII)',
        currentAmount: _formatAmount(summary['profitBeforeTax']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: 'X. Tax Expense',
        currentAmount: _formatAmount(summary['totalTaxExpense']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: '1. Current tax',
        currentAmount: _formatAmount(summary['totalCurrentTax']),
        previousAmount: '0.00',
        isIndented: true,
      ),
      _ScheduleIIIRow(
        particulars: '2. Deferred tax',
        currentAmount: _formatAmount(summary['totalDeferredTax']),
        previousAmount: '0.00',
        isIndented: true,
      ),
      _ScheduleIIIRow(
        particulars:
            'XI. Profit (Loss) for the period from continuing operations (IX - X)',
        currentAmount: _formatAmount(summary['profitForThePeriod']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: 'XII. Profit (Loss) from discontinuing operations',
        currentAmount: '0.00',
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: 'XIII. Tax expense of discontinuing operations',
        currentAmount: '0.00',
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars:
            'XIV. Profit (Loss) from Discontinuing operations (after tax) (XII - XIII)',
        currentAmount: '0.00',
        previousAmount: '0.00',
        isEmphasized: true,
      ),
      _ScheduleIIIRow(
        particulars: 'XV. Profit (Loss) for the period (XI + XIV)',
        currentAmount: _formatAmount(summary['profitForThePeriod']),
        previousAmount: '0.00',
        isEmphasized: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const tableWidth = 828.0;
        final statementHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 480.0;
        final statement = SizedBox(
          width: tableWidth,
          height: statementHeight,
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
                const SizedBox(height: AppTheme.space20),
                _ScheduleIIIHeader(
                  currentPeriodLabel: _periodLabels[0],
                  previousPeriodLabel: _periodLabels[1],
                ),
              ],
            ),
            emptyBody: const SizedBox.shrink(),
            children: [
              for (final row in _rows) _ScheduleIIITableRow(row),
              const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderLight,
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
            child: statement,
          );
        }

        return Center(child: statement);
      },
    );
  }
}

class _ScheduleIIIHeader extends StatelessWidget {
  final String currentPeriodLabel;
  final String previousPeriodLabel;

  const _ScheduleIIIHeader({
    required this.currentPeriodLabel,
    required this.previousPeriodLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          const _ScheduleIIICell(width: 498, text: 'PARTICULARS', isHeader: true),
          const _ScheduleIIICell(
            width: 90,
            text: 'NOTE NO.',
            isHeader: true,
            textAlign: TextAlign.right,
          ),
          _ScheduleIIICell(
            width: 120,
            text: currentPeriodLabel,
            isHeader: true,
            textAlign: TextAlign.right,
          ),
          _ScheduleIIICell(
            width: 120,
            text: previousPeriodLabel,
            isHeader: true,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _ScheduleIIITableRow extends StatelessWidget {
  final _ScheduleIIIRow row;

  const _ScheduleIIITableRow(this.row);

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      fontWeight: row.isEmphasized ? FontWeight.w700 : FontWeight.w400,
      color: AppTheme.textPrimary,
    );

    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ScheduleIIICell(
            width: 498,
            text: row.particulars,
            style: textStyle,
            leftPadding: row.isIndented ? 36 : 20,
          ),
          _ScheduleIIICell(
            width: 90,
            text: '',
            style: textStyle,
            textAlign: TextAlign.right,
          ),
          _ScheduleIIICell(
            width: 120,
            text: row.currentAmount,
            style: textStyle,
            textAlign: TextAlign.right,
          ),
          _ScheduleIIICell(
            width: 120,
            text: row.previousAmount,
            style: textStyle,
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _ScheduleIIICell extends StatelessWidget {
  final double width;
  final String text;
  final bool isHeader;
  final TextAlign textAlign;
  final TextStyle? style;
  final double leftPadding;

  const _ScheduleIIICell({
    required this.width,
    required this.text,
    this.isHeader = false,
    this.textAlign = TextAlign.left,
    this.style,
    this.leftPadding = 20,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedStyle =
        style ??
        ReportTableTypography.header.copyWith(fontSize: 11, letterSpacing: 0);

    return SizedBox(
      width: width,
      child: Padding(
        padding: EdgeInsets.only(
          left: leftPadding,
          right: AppTheme.space20,
          top: isHeader ? 0 : AppTheme.space8,
          bottom: isHeader ? 0 : AppTheme.space8,
        ),
        child: Text(
          text,
          textAlign: textAlign,
          softWrap: true,
          style: resolvedStyle,
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
      padding: const EdgeInsets.only(
        left: AppTheme.space20,
        bottom: AppTheme.space20,
      ),
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
