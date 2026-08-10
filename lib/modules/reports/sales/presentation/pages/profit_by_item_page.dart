import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/providers/sales_report_provider.dart';

import '../widgets/profit_by_item_table.dart';
import 'sales_by_customer_customization_page.dart';

class ProfitByItemPage extends ConsumerStatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;

  const ProfitByItemPage({super.key, this.startDate, this.endDate});

  @override
  ConsumerState<ProfitByItemPage> createState() => _ProfitByItemPageState();
}

class _ProfitByItemPageState extends ConsumerState<ProfitByItemPage> {
  static const List<String> _reportByOptions = <String>[
    'Invoices',
    'Invoices & Credit Notes',
  ];

  late DateTime _startDate;
  late DateTime _endDate;
  late DateTime _appliedStartDate;
  late DateTime _appliedEndDate;
  bool _isMoreFiltersOpen = false;
  String _selectedReportBy = 'Invoices';
  String _appliedReportBy = 'Invoices';
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
      _appliedReportBy = _selectedReportBy;
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

  void _handleReportByChanged(String value) {
    if (_selectedReportBy == value) return;
    setState(() {
      _selectedReportBy = value;
      _markFiltersDirty();
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
          kind: SalesReportKind.profitByItem,
          startDate: _appliedStartDate,
          endDate: _appliedEndDate,
          reportBy: _appliedReportBy,
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
      reportTitle: 'Profit By Item',
      dateLabel: displayDate,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          initialStartDate: _startDate,
          initialEndDate: _endDate,
          onChanged: _handleDateRangeChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Report By',
          value: _selectedReportBy,
          options: _reportByOptions,
          onChanged: _handleReportByChanged,
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
          ReportScheduleDialog.show(context, reportName: 'Profit By Item'),
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
      settingsTooltip: 'Customize the Profit By Item report.',
      scheduleTooltip: 'Schedule the Profit By Item report.',
      tableHeaderActions: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [ReportCustomizeColumnsButton(count: 7)],
      ),
      isLoading: reportRowsAsync.isLoading && !reportRowsAsync.hasValue,
      errorMessage: reportRowsAsync.hasError
          ? reportRowsAsync.error.toString()
          : null,
      onRetry: _runReport,
      isEmpty: reportRows.isEmpty,
      emptyTitle: 'No profit rows found',
      emptyMessage:
          'There are no item profit rows for the selected date range.',
      currentNavigationCategory: 'Sales',
      currentNavigationReport: 'Profit By Item',
      reportContent: ProfitByItemTable(
        items: reportRows,
        currencyFormat: currencyFormat,
      ),
    );
  }
}
