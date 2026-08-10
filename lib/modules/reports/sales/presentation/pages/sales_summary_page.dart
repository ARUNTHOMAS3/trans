import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/providers/sales_report_provider.dart';

import '../widgets/sales_summary_table.dart';
import 'sales_by_customer_customization_page.dart';

class SalesSummaryPage extends ConsumerStatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const SalesSummaryPage({super.key, this.startDate, this.endDate});

  @override
  ConsumerState<SalesSummaryPage> createState() => _SalesSummaryPageState();
}

class _SalesSummaryPageState extends ConsumerState<SalesSummaryPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _appliedStartDate;
  late DateTime _appliedEndDate;
  bool _isMoreFiltersOpen = false;
  String _selectedGroupBy = 'None';
  String _appliedGroupBy = 'None';
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;

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

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      symbol: '\u20B9',
      decimalDigits: 2,
    );
    final reportRowsAsync = ref.watch(
      salesReportRowsProvider(
        SalesReportRequest(
          kind: SalesReportKind.summary,
          startDate: _appliedStartDate,
          endDate: _appliedEndDate,
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

    return ReportViewScaffold(
      categoryLabel: 'Sales',
      reportTitle: 'Sales Summary',
      dateLabel: displayDate,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          onChanged: _handleDateRangeChanged,
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
        onChanged: _handleFilterControlChanged,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () =>
          ReportScheduleDialog.show(context, reportName: 'Sales Summary'),
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
      settingsTooltip: 'Customize the Sales Summary report.',
      scheduleTooltip: 'Schedule the Sales Summary report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _selectedGroupBy,
            options: const <String>['Location'],
            onChanged: _handleGroupByChanged,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 5),
        ],
      ),
      isLoading: reportRowsAsync.isLoading && !reportRowsAsync.hasValue,
      errorMessage: reportRowsAsync.hasError
          ? reportRowsAsync.error.toString()
          : null,
      onRetry: _runReport,
      isEmpty: reportRows.isEmpty,
      emptyTitle: 'No sales summary rows found',
      emptyMessage:
          'There are no sales summary rows for the selected date range.',
      currentNavigationCategory: 'Sales',
      currentNavigationReport: 'Sales Summary',
      reportContent: SalesSummaryTable(
        items: reportRows,
        currencyFormat: currencyFormat,
        groupBy: _appliedGroupBy,
      ),
    );
  }
}
