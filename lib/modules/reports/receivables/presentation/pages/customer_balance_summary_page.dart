import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/receivables/presentation/widgets/customer_balance_summary_table.dart';

class CustomerBalanceSummaryPage extends StatefulWidget {
  const CustomerBalanceSummaryPage({super.key});

  @override
  State<CustomerBalanceSummaryPage> createState() =>
      _CustomerBalanceSummaryPageState();
}

class _CustomerBalanceSummaryPageState
    extends State<CustomerBalanceSummaryPage> {
  static const String _reportTitle = 'Customer Balance Summary';
  static const String _dateLabel = 'From 01-07-2026 To 31-07-2026';
  static const String _dateRangeFilterType = 'Date Range';
  static const String _asOfDateFilterType = 'As of Date';
  static const List<String> _filterTypeOptions = <String>[
    _asOfDateFilterType,
    _dateRangeFilterType,
  ];
  static final DateTime _dateRangeStartDate = DateTime(2026, 7, 1);
  static final DateTime _dateRangeEndDate = DateTime(2026, 7, 31, 23, 59, 59);
  static const int _pageSize = 20;

  static const List<CustomerBalanceSummaryRow> _rows = [
    CustomerBalanceSummaryRow(
      customerName: 'althaf m',
      invoicedAmount: '\u20B9419.00',
      amountReceived: '\u20B9210.00',
      closingBalance: '\u20B91,093.00 Dr',
    ),
    CustomerBalanceSummaryRow(
      customerName: 'CUS-1',
      invoicedAmount: '\u20B90.00',
      amountReceived: '\u20B90.00',
      closingBalance: '\u20B91,544.00 Dr',
    ),
    CustomerBalanceSummaryRow(
      customerName: 'SAHAKAR MEDICALS AND SURGICALS ALANALLUR LLP',
      invoicedAmount: '\u20B90.00',
      amountReceived: '\u20B90.00',
      closingBalance: '\u20B91,18,000.00 Dr',
    ),
    CustomerBalanceSummaryRow(
      customerName: 'SAHAKAR MEDICALS AND SURGICALS HYPER STORE LLP',
      invoicedAmount: '\u20B90.00',
      amountReceived: '\u20B90.00',
      closingBalance: '\u20B91,18,000.00 Dr',
    ),
    CustomerBalanceSummaryRow(
      customerName: 'SAHAKAR MEDICALS AND SURGICALS KKL LLP',
      invoicedAmount: '\u20B90.00',
      amountReceived: '\u20B90.00',
      closingBalance: '\u20B91,18,000.00 Dr',
    ),
    CustomerBalanceSummaryRow(
      customerName: 'SAHAKAR MEDICALS AND SURGICALS MAKKARAPARAMBA LLP',
      invoicedAmount: '\u20B90.00',
      amountReceived: '\u20B90.00',
      closingBalance: '\u20B91,18,000.00 Dr',
    ),
    CustomerBalanceSummaryRow(
      customerName: 'SAHAKAR MEDICALS AND SURGICALS THRISSUR LLP',
      invoicedAmount: '\u20B90.00',
      amountReceived: '\u20B90.00',
      closingBalance: '\u20B959,000.00 Cr',
    ),
    CustomerBalanceSummaryRow(
      customerName: 'SAHAKAR MEDICALS AND SURGICALS THRISSUR LLP',
      invoicedAmount: '\u20B90.00',
      amountReceived: '\u20B90.00',
      closingBalance: '\u20B91,18,000.00 Dr',
    ),
    CustomerBalanceSummaryRow(
      customerName: 'SAHAKAR MEDICALS AND SURGICALS TIRUR LLP',
      invoicedAmount: '\u20B90.00',
      amountReceived: '\u20B90.00',
      closingBalance: '\u20B91,18,000.00 Dr',
    ),
    CustomerBalanceSummaryRow(
      customerName: 'STARLEX HEALTH SERVICES & PRODUCTS PVT LTD',
      invoicedAmount: '\u20B90.00',
      amountReceived: '\u20B90.00',
      closingBalance: '\u20B921,14,240.00 Cr',
    ),
    CustomerBalanceSummaryRow(
      customerName: 'Walk-in Customer',
      invoicedAmount: '\u20B9420.00',
      amountReceived: '\u20B9420.00',
      closingBalance: '\u20B90.00',
    ),
  ];

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  String _groupBy = 'None';
  String _selectedFilterType = _dateRangeFilterType;
  bool _isCombinedFilterActive = false;
  int _page = 1;

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

  void _activateCombinedFilter() {
    if (_isCombinedFilterActive) return;
    setState(() => _isCombinedFilterActive = true);
  }

  void _handleFilterTypeChanged(String value) {
    if (_selectedFilterType == value) return;
    setState(() {
      _selectedFilterType = value;
      _isCombinedFilterActive = false;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleDateRangeChanged(ReportDateRangeSelection _) {
    setState(() {
      _isCombinedFilterActive = false;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleGroupByChanged(String value) {
    setState(() {
      _groupBy = value;
      _hasPendingFilterChanges = true;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _isCombinedFilterActive = false;
      _page = 1;
      _hasPendingFilterChanges = false;
    });
  }

  void _handlePageChanged(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Receivables',
      reportTitle: _reportTitle,
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        Listener(
          onPointerDown: (_) => _activateCombinedFilter(),
          child: Container(
            height: AppTheme.buttonHeight,
            decoration: BoxDecoration(
              color: AppTheme.bgLight,
              borderRadius: BorderRadius.circular(AppTheme.space6),
              border: Border.all(
                color: _isCombinedFilterActive
                    ? AppTheme.primaryBlue
                    : AppTheme.borderColor,
                width: _isCombinedFilterActive
                    ? AppTheme.inputActiveBorderWidth
                    : AppTheme.inputBorderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ReportSearchableFilterDropdown(
                  label: 'Filter Type',
                  value: _selectedFilterType,
                  options: _filterTypeOptions,
                  onChanged: _handleFilterTypeChanged,
                  showLabel: false,
                  width: 118,
                  menuWidth: 156,
                  menuMaxHeight: 152,
                  fillColor: AppTheme.bgLight,
                  border: Border.all(color: Colors.transparent),
                  hideBorderDefault: true,
                  showLeftBorder: false,
                  showRightBorder: false,
                  clipActiveBorder: true,
                  activeBorderCoverColor: AppTheme.bgLight,
                ),
                Text(
                  ':',
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ReportDateRangeFilter(
                  key: ValueKey(_selectedFilterType),
                  label: _selectedFilterType,
                  showLabel: false,
                  fillColor: AppTheme.bgLight,
                  showBorder: false,
                  suppressHoverOverlay: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space8,
                  ),
                  initialStartDate: _dateRangeStartDate,
                  initialEndDate: _dateRangeEndDate,
                  onChanged: _handleDateRangeChanged,
                ),
              ],
            ),
          ),
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
      settingsTooltip: 'Customize the Customer Balance Summary report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: const <String>[],
            onChanged: _handleGroupByChanged,
          ),
          const _HeaderActionDivider(),
          const ReportCustomizeColumnsButton(count: 4),
        ],
      ),
      isLoading: false,
      currentNavigationCategory: 'Receivables',
      currentNavigationReport: 'Customer Balance Summary',
      onReportSelected: (reportName, category) {
        if (reportName == 'Customer Balance Summary') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: CustomerBalanceSummaryTable(
        rows: _rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}
class _HeaderActionDivider extends StatelessWidget {
  const _HeaderActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: AppTheme.space20,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
      color: AppTheme.borderLight,
    );
  }
}
