import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/modules/reports/payables/presentation/widgets/vendor_credits_details_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';

class VendorCreditsDetailsPage extends ConsumerStatefulWidget {
  const VendorCreditsDetailsPage({super.key});

  @override
  ConsumerState<VendorCreditsDetailsPage> createState() =>
      _VendorCreditsDetailsPageState();
}

typedef VendorCreditsDetailsParams = ({
  String startDate,
  String endDate,
  int page,
  int pageSize,
});

final vendorCreditsDetailsProvider = FutureProvider.family<
    Map<String, dynamic>, VendorCreditsDetailsParams>((ref, params) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getVendorCreditsDetails(
    startDate: params.startDate,
    endDate: params.endDate,
    page: params.page,
    limit: params.pageSize,
  );
});

class _VendorCreditsDetailsPageState
    extends ConsumerState<VendorCreditsDetailsPage> {
  static const String _reportTitle = 'Vendor Credits Details';
  static const int _pageSize = 10;

  ReportDateRangeSelection? _dateRangeSelection;
  late DateTime _appliedStartDate;
  late DateTime _appliedEndDate;
  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  String _groupBy = 'None';
  int _page = 1;

  ReportDateRangeSelection get _effectiveDateRangeSelection =>
      _dateRangeSelection ??
      ReportDateRangeSelection(
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31, 23, 59, 59),
        label: ReportDateRangePresets.thisMonth,
      );

  void _initializeAppliedFilters() {
    if (_isInitialized) return;
    final initialSelection = _effectiveDateRangeSelection;
    _appliedStartDate = initialSelection.startDate;
    _appliedEndDate = initialSelection.endDate;
    _isInitialized = true;
  }

  void _markFiltersDirty() {
    setState(() {
      _page = 1;
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

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _dateRangeSelection = selection;
      _page = 1;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleGroupByChanged(String value) {
    if (_groupBy == value) return;
    setState(() {
      _groupBy = value;
      _hasPendingFilterChanges = true;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    final selectedRange = _effectiveDateRangeSelection;
    setState(() {
      _appliedStartDate = selectedRange.startDate;
      _appliedEndDate = selectedRange.endDate;
      _page = 1;
      _hasPendingFilterChanges = false;
    });
  }

  void _handlePageChanged(int page) {
    if (_page == page) return;
    setState(() => _page = page);
  }

  int _intValue(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  @override
  Widget build(BuildContext context) {
    _initializeAppliedFilters();
    final dateRangeSelection = _effectiveDateRangeSelection;
    final orgDatePattern = ref.watch(orgDateFormatProvider);
    final dateFormat = ReportFormatterCache.date(orgDatePattern);
    final dateLabel =
        'From ${dateFormat.format(_appliedStartDate)} To ${dateFormat.format(_appliedEndDate)}';
    final currencyAsync = ref.watch(defaultCurrencyProvider);
    final currencyFormat = NumberFormat.currency(
      symbol: currencyAsync.valueOrNull?.symbol ?? '\u20B9',
      decimalDigits: 2,
    );
    final queryParams = (
      startDate: ReportUtils.formatApiDate(_appliedStartDate),
      endDate: ReportUtils.formatApiDate(_appliedEndDate),
      page: _page,
      pageSize: _pageSize,
    );
    final reportAsync = ref.watch(vendorCreditsDetailsProvider(queryParams));
    final reportData = reportAsync.valueOrNull;
    final rows = VendorCreditsDetailsRow.fromResponse(reportData);
    final totals = VendorCreditsDetailsTotals.fromResponse(reportData);
    final meta = Map<String, dynamic>.from(
      reportData?['meta'] as Map? ?? const <String, dynamic>{},
    );
    final totalCount = _intValue(
      meta['total'] ?? reportData?['total'],
      rows.length,
    );
    final currentPage = _intValue(meta['page'] ?? reportData?['page'], _page);
    final effectivePageSize = _intValue(
      meta['limit'] ?? meta['pageSize'] ?? reportData?['pageSize'],
      _pageSize,
    );

    return ReportViewScaffold(
      categoryLabel: 'Payables',
      reportTitle: _reportTitle,
      dateLabel: dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          initialStartDate: dateRangeSelection.startDate,
          initialEndDate: dateRangeSelection.endDate,
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
      settingsTooltip: 'Customize the Vendor Credits Details report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: const <String>[
              'None',
              'Vendor Credit Date',
              'Vendor Name',
              'Currency',
            ],
            onChanged: _handleGroupByChanged,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 6),
        ],
      ),
      isLoading: reportAsync.isLoading,
      errorMessage: reportAsync.hasError
          ? 'Unable to load report: ${reportAsync.error}'
          : null,
      onRetry: () => ref.invalidate(vendorCreditsDetailsProvider(queryParams)),
      currentNavigationCategory: 'Payables',
      currentNavigationReport: _reportTitle,
      onReportSelected: (reportName, category) {
        if (reportName == 'Vendor Credit Details' ||
            reportName == 'Vendor Credits Details') {
          return;
        }
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: VendorCreditsDetailsTable(
        rows: rows,
        totals: totals,
        currencyFormat: currencyFormat,
        dateFormat: dateFormat,
        totalCount: totalCount,
        page: currentPage,
        pageSize: effectivePageSize,
        onPageChanged: _handlePageChanged,
        groupBy: _groupBy,
      ),
    );
  }
}
