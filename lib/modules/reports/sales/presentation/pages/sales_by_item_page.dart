import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_entities_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/providers/sales_report_provider.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import '../widgets/sales_by_customer_table.dart';
import '../widgets/sales_by_item_table.dart';
import '../widgets/sales_by_item_transactions_table.dart';
import 'sales_by_customer_transactions_page.dart';
import 'sales_by_item_customization_page.dart';

class SalesByItemPage extends ConsumerStatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const SalesByItemPage({super.key, this.startDate, this.endDate});

  @override
  ConsumerState<SalesByItemPage> createState() => _SalesByItemPageState();
}

class _SalesByItemPageState extends ConsumerState<SalesByItemPage> {
  static const List<String> _entityOptions = <String>[
    'Invoice',
    'Credit Note',
  ];

  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _appliedStartDate;
  late DateTime _appliedEndDate;
  List<String> _selectedEntities = _entityOptions;
  List<String> _appliedEntities = _entityOptions;
  bool _isMoreFiltersOpen = false;
  String _selectedGroupBy = 'None';
  String _appliedGroupBy = 'None';
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
    if (_sameDateTime(_startDate, selection.startDate) &&
        _sameDateTime(_endDate, selection.endDate)) {
      return;
    }
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _markFiltersDirty();
    });
  }

  void _handleEntitiesChanged(List<String> entities) {
    if (_sameStringList(_selectedEntities, entities)) return;
    setState(() {
      _selectedEntities = List<String>.from(entities);
      _markFiltersDirty();
    });
  }

  void _handleGroupByChanged(String value) {
    if (_selectedGroupBy == value) return;
    setState(() {
      _selectedGroupBy = value;
      _appliedGroupBy = value;
      _refreshKey += 1;
    });
  }

  void _handleFilterControlChanged() {
    setState(_markFiltersDirty);
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

  bool _sameDateTime(DateTime left, DateTime right) {
    return left.isAtSameMomentAs(right);
  }

  bool _sameStringList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index += 1) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  void _toggleMoreFilters() {
    setState(() {
      _isMoreFiltersOpen = !_isMoreFiltersOpen;
    });
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() {
        _isMoreFiltersOpen = false;
      });
    }
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _appliedEntities = List<String>.from(_selectedEntities);
      _appliedGroupBy = _selectedGroupBy;
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

  Future<void> _openItemOverview(Map<String, dynamic> item) async {
    final itemName = item['itemName']?.toString() ?? 'Item';
    final itemId = item['itemId']?.toString();
    final currencyFormat = NumberFormat.currency(
      symbol: '\u20B9',
      decimalDigits: 2,
    );
    final quantityFormat = ReportFormatterCache.number('0.00');
    final transactions = itemId == null || itemId.isEmpty
        ? const <Map<String, dynamic>>[]
        : await ref
              .read(reportsRepositoryProvider)
              .getSalesByItemTransactions(
                itemId,
                ReportFormatterCache.date('yyyy-MM-dd').format(_appliedStartDate),
                ReportFormatterCache.date('yyyy-MM-dd').format(_appliedEndDate),
              );
    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SalesByCustomerTransactionsPage(
          customerName: itemName,
          categoryLabel: 'Sales > Sales by Item',
          reportTitleOverride: 'Sales by Item - $itemName',
          currentNavigationReport: 'Sales by Item',
          dateLabel:
              'From ' +
              ReportFormatterCache.date('dd-MM-yyyy').format(_appliedStartDate) +
              ' To ' +
              ReportFormatterCache.date('dd-MM-yyyy').format(_appliedEndDate),
          reportContent: SalesByItemTransactionsTable(
            items: transactions,
            currencyFormat: currencyFormat,
            quantityFormat: quantityFormat,
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
    final quantityFormat = ReportFormatterCache.number('0.00');
    final reportRowsAsync = ref.watch(
      salesReportRowsProvider(
        SalesReportRequest(
          kind: SalesReportKind.item,
          startDate: _appliedStartDate,
          endDate: _appliedEndDate,
          entities: _appliedEntities,
          groupBy: _appliedGroupBy,
          refreshKey: _refreshKey,
        ),
      ),
    );
    _clearPendingAfterSuccessfulLoad(reportRowsAsync);
    final reportRows =
        reportRowsAsync.valueOrNull ?? const <Map<String, dynamic>>[];
    final displayDate =
        'From ' +
        ReportFormatterCache.date('dd-MM-yyyy').format(_appliedStartDate) +
        ' To ' +
        ReportFormatterCache.date('dd-MM-yyyy').format(_appliedEndDate);
    final comparisonPeriods = _buildComparisonPeriods();

    return ReportViewScaffold(
      categoryLabel: 'Sales',
      reportTitle: 'Sales by Item',
      dateLabel: displayDate,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          onChanged: _handleDateRangeChanged,
        ),
        ReportEntitiesFilter(
          options: _entityOptions,
          initialSelection: _selectedEntities,
          onChanged: _handleEntitiesChanged,
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
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      expandedFilterPanel: ReportMoreFiltersPanel(
        onRunReport: _runReport,
        onCancel: _closeMoreFilters,
        onChanged: _handleFilterControlChanged,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: 'Sales by Item'),
      onReload: _runReport,
      onRefresh: _runReport,
      onSettings: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SalesByItemCustomizationPage(),
          ),
        );
      },
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      settingsTooltip: 'Customize the Sales by Item report.',
      scheduleTooltip: 'Schedule the Sales by Item report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _selectedGroupBy,
            options: const <String>[
              'Customer Name',
              'Salesperson',
              'Place Of Supply',
              'Group Name',
            ],
            onChanged: _handleGroupByChanged,
          ),
          const SizedBox(width: AppTheme.space10),
          ReportCompareSection(
            selectedValue: _compareWith,
            onSelectionApplied: _handleCompareSelectionApplied,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 4),
        ],
      ),
      isLoading: reportRowsAsync.isLoading && !reportRowsAsync.hasValue,
      errorMessage: reportRowsAsync.hasError
          ? reportRowsAsync.error.toString()
          : null,
      onRetry: _runReport,
      isEmpty: reportRows.isEmpty,
      emptyTitle: 'No item sales found',
      emptyMessage: 'There are no item sales rows for the selected date range.',
      currentNavigationCategory: 'Sales',
      currentNavigationReport: 'Sales by Item',
      onReportSelected: (reportName, category) {
        if (reportName == 'Sales by Item') {
          return;
        }
        openReportFromReportsModule(context, reportName);
      },
      reportContent: SalesByItemTable(
        items: reportRows,
        currencyFormat: currencyFormat,
        quantityFormat: quantityFormat,
        onOpenDetails: _openItemOverview,
        comparisonPeriods: comparisonPeriods,
      ),
    );
  }
}
