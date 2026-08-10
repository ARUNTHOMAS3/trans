import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/payables/presentation/widgets/vendor_balance_summary_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';

class VendorBalanceSummaryPage extends StatefulWidget {
  const VendorBalanceSummaryPage({super.key});

  @override
  State<VendorBalanceSummaryPage> createState() =>
      _VendorBalanceSummaryPageState();
}

class _VendorBalanceSummaryPageState extends State<VendorBalanceSummaryPage> {
  static const String _reportTitle = 'Vendor Balance Summary';
  static const String _dateLabel = 'From 01-07-2026 To 31-07-2026';
  static const int _pageSize = 20;
  static const String _dateRangeFilterType = 'Date Range';
  static const String _asOfDateFilterType = 'As of Date';
  static const List<String> _filterTypeOptions = <String>[
    _asOfDateFilterType,
    _dateRangeFilterType,
  ];
  static final DateTime _dateRangeStartDate = DateTime(2026, 7, 1);
  static final DateTime _dateRangeEndDate = DateTime(2026, 7, 31, 23, 59, 59);

  static const List<VendorBalanceSummaryRow> _rows = [
    VendorBalanceSummaryRow(
      vendorName: 'FIRST LOGIC META LAB PRIVATE LIMITED',
      billedAmount: '\u20B90.00',
      amountPaid: '\u20B90.00',
      closingBalance: '\u20B911,88,400.00 Dr',
    ),
    VendorBalanceSummaryRow(
      vendorName: 'GYANKAAR TECHNOLOGIES PRIVATE LIMITED',
      billedAmount: '\u20B90.00',
      amountPaid: '\u20B90.00',
      closingBalance: '\u20B98,496.00 Dr',
    ),
    VendorBalanceSummaryRow(
      vendorName: 'm, althaf',
      billedAmount: '\u20B90.00',
      amountPaid: '\u20B90.00',
      closingBalance: '\u20B963,935.00 Cr',
    ),
    VendorBalanceSummaryRow(
      vendorName: 'NUBINIX TECHNOLOGIES',
      billedAmount: '\u20B90.00',
      amountPaid: '\u20B90.00',
      closingBalance: '\u20B91,18,988.10 Dr',
    ),
    VendorBalanceSummaryRow(
      vendorName: 'ZERPAI TESTING',
      billedAmount: '\u20B90.00',
      amountPaid: '\u20B90.00',
      closingBalance: '\u20B98,796.05 Cr',
    ),
  ];

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  String _groupBy = 'None';
  String _selectedFilterType = _dateRangeFilterType;
  bool _isCombinedFilterActive = false;
  int _page = 1;

  void _markFiltersDirty() {
    _hasPendingFilterChanges = true;
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
      _markFiltersDirty();
    });
  }

  void _handleDateRangeChanged(ReportDateRangeSelection _) {
    setState(() {
      _isCombinedFilterActive = false;
      _markFiltersDirty();
    });
  }

  void _handleFilterControlChanged() {
    setState(_markFiltersDirty);
  }

  void _toggleMoreFilters() {
    setState(() {
      _isCombinedFilterActive = false;
      _isMoreFiltersOpen = !_isMoreFiltersOpen;
    });
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
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
      categoryLabel: 'Payables',
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
        onChanged: _handleFilterControlChanged,
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
      settingsTooltip: 'Customize the Vendor Balance Summary report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: const <String>[
              'None',
            ],
            onChanged: _handleGroupByChanged,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 4),
        ],
      ),
      isLoading: false,
      currentNavigationCategory: 'Payables',
      currentNavigationReport: 'Vendor Balance Summary',
      onReportSelected: (reportName, category) {
        if (reportName == 'Vendor Balance Summary') return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: VendorBalanceSummaryTable(
        rows: _rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        groupBy: _groupBy,
      ),
    );
  }
}
