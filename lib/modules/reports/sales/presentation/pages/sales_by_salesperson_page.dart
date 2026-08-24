import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/providers/sales_report_provider.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import '../widgets/sales_by_salesperson_table.dart';
import '../widgets/sales_by_salesperson_transactions_table.dart';
import 'sales_by_customer_customization_page.dart';
import 'sales_by_customer_transactions_page.dart';
import '../widgets/sales_by_customer_table.dart';

class SalesBySalespersonPage extends ConsumerStatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const SalesBySalespersonPage({super.key, this.startDate, this.endDate});

  @override
  ConsumerState<SalesBySalespersonPage> createState() =>
      _SalesBySalespersonPageState();
}

class _SalesBySalespersonPageState
    extends ConsumerState<SalesBySalespersonPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _appliedStartDate;
  late DateTime _appliedEndDate;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  ReportCompareSelection _compareSelection = const ReportCompareSelection.none();
  String _compareWith = 'None';

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate ?? DateTime(2026, 4, 1);
    _endDate = widget.endDate ?? DateTime(2027, 3, 31, 23, 59, 59);
    _appliedStartDate = _startDate;
    _appliedEndDate = _endDate;
  }

  void _markFiltersDirty() {
    _hasPendingFilterChanges = true;
    _isApplyingFilters = false;
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    if (_startDate.isAtSameMomentAs(selection.startDate) &&
        _endDate.isAtSameMomentAs(selection.endDate)) {
      return;
    }
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _markFiltersDirty();
    });
  }


  void _handleCompareSelectionApplied(ReportCompareSelection selection) {
    setState(() {
      _compareSelection = selection;
      _compareWith = selection.displayValue;
      _refreshKey += 1;
    });
  }

  List<SalesByCustomerComparisonPeriod> _buildComparisonPeriods() {
    if (!_compareSelection.isActive) {
      return const <SalesByCustomerComparisonPeriod>[];
    }

    final count = _compareSelection.count.clamp(1, 5);
    final currentPeriod = SalesByCustomerComparisonPeriod(
      label: _formatComparisonPeriod(_appliedStartDate, _appliedEndDate),
      isCurrent: true,
    );
    final previousPeriods = <SalesByCustomerComparisonPeriod>[];

    if (_compareSelection.compareType == 'Previous Year(s)') {
      for (var offset = count; offset >= 1; offset -= 1) {
        previousPeriods.add(
          SalesByCustomerComparisonPeriod(
            label: _formatComparisonPeriod(
              _shiftDateByYears(_appliedStartDate, -offset),
              _shiftDateByYears(_appliedEndDate, -offset),
            ),
            isCurrent: false,
          ),
        );
      }
    } else {
      final periodDays = _appliedEndDate.difference(_appliedStartDate).inDays + 1;
      for (var offset = count; offset >= 1; offset -= 1) {
        final previousEnd = _appliedStartDate.subtract(
          Duration(days: periodDays * (offset - 1) + 1),
        );
        final previousStart = previousEnd.subtract(Duration(days: periodDays - 1));
        previousPeriods.add(
          SalesByCustomerComparisonPeriod(
            label: _formatComparisonPeriod(previousStart, previousEnd),
            isCurrent: false,
          ),
        );
      }
    }

    final periods = <SalesByCustomerComparisonPeriod>[
      ...previousPeriods,
      currentPeriod,
    ];
    if (_compareSelection.arrangeLatestFirst) {
      return periods.reversed.toList(growable: false);
    }
    return periods;
  }

  DateTime _shiftDateByYears(DateTime date, int years) {
    final targetYear = date.year + years;
    final lastDayOfTargetMonth = DateTime(targetYear, date.month + 1, 0).day;
    return DateTime(
      targetYear,
      date.month,
      date.day.clamp(1, lastDayOfTargetMonth),
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  String _formatComparisonPeriod(DateTime startDate, DateTime endDate) {
    final formatter = ReportFormatterCache.date('MMM yyyy');
    return '${formatter.format(startDate).toUpperCase()} - ${formatter.format(endDate).toUpperCase()}';
  }

  void _runReport() {
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<List<Map<String, dynamic>>> reportRowsAsync,
  ) {
    if (!_isApplyingFilters ||
        reportRowsAsync.isLoading ||
        !reportRowsAsync.hasValue) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isApplyingFilters) return;
      setState(() {
        _isApplyingFilters = false;
        _hasPendingFilterChanges = false;
      });
    });
  }

  Future<void> _openSalespersonOverview(Map<String, dynamic> item) async {
    final salespersonName =
        item['salespersonName']?.toString() ?? 'Salesperson';
    final transactions = await ref
        .read(reportsRepositoryProvider)
        .getSalesBySalespersonTransactions(
          salespersonName,
          ReportFormatterCache.date('yyyy-MM-dd').format(_appliedStartDate),
          ReportFormatterCache.date('yyyy-MM-dd').format(_appliedEndDate),
        );
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SalesByCustomerTransactionsPage(
          customerName: salespersonName,
          categoryLabel: 'Sales > Sales by Salesperson',
          reportTitleOverride: 'Sales by Salesperson - $salespersonName',
          currentNavigationReport: 'Sales by Sales Person',
          dateLabel:
              'From ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedStartDate)} To ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedEndDate)}',
          reportContent: SalesBySalespersonTransactionsTable(
            items: transactions,
          ),
          onReportSelected: (reportName, category) {
            openReportFromReportsModule(context, reportName);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\u20B9',
      decimalDigits: 2,
    );
    final reportRowsAsync = ref.watch(
      salesReportRowsProvider(
        SalesReportRequest(
          kind: SalesReportKind.salesperson,
          startDate: _appliedStartDate,
          endDate: _appliedEndDate,
          refreshKey: _refreshKey,
        ),
      ),
    );
    _clearPendingAfterSuccessfulLoad(reportRowsAsync);
    final reportRows =
        reportRowsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final displayDate =
        'From ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedStartDate)} To ${ReportFormatterCache.date('dd-MM-yyyy').format(_appliedEndDate)}';
    final comparisonPeriods = _buildComparisonPeriods();

    return ReportViewScaffold(
      categoryLabel: 'Sales',
      reportTitle: 'Sales by Salesperson',
      dateLabel: displayDate,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          onChanged: _handleDateRangeChanged,
        ),
      ],
      onRunReport: _runReport,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: 'Sales by Salesperson',
      ),
      onReload: _runReport,
      onRefresh: _runReport,
      onSettings: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SalesByCustomerCustomizationPage(),
          ),
        );
      },
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      settingsTooltip: 'Customize the Sales by Salesperson report.',
      scheduleTooltip: 'Schedule the Sales by Salesperson report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportCompareSection(
            selectedValue: _compareWith,
            onSelectionApplied: _handleCompareSelectionApplied,
          ),
          SizedBox(width: AppTheme.space10),
          ReportCustomizeColumnsButton(count: 9),
        ],
      ),
      isLoading: reportRowsAsync.isLoading && !reportRowsAsync.hasValue,
      errorMessage: reportRowsAsync.hasError
          ? reportRowsAsync.error.toString()
          : null,
      onRetry: _runReport,
      isEmpty: reportRows.isEmpty,
      emptyTitle: 'No salesperson sales found',
      emptyMessage:
          'There are no salesperson rows for the selected date range.',
      currentNavigationCategory: 'Sales',
      currentNavigationReport: 'Sales by Sales Person',
      onReportSelected: (reportName, category) {
        if (reportName == 'Sales by Sales Person') {
          return;
        }
        openReportFromReportsModule(context, reportName);
      },
      reportContent: SalesBySalespersonTable(
        items: reportRows,
        currencyFormat: currencyFormat,
        onOpenOverview: _openSalespersonOverview,
        comparisonPeriods: comparisonPeriods,
      ),
    );
  }
}
