import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';

const String _selfInvoiceSummaryTitle = 'Self-invoice Summary';

class SelfInvoiceSummaryScreen extends ConsumerStatefulWidget {
  const SelfInvoiceSummaryScreen({super.key});

  @override
  ConsumerState<SelfInvoiceSummaryScreen> createState() =>
      _SelfInvoiceSummaryScreenState();
}

class _SelfInvoiceSummaryScreenState
    extends ConsumerState<SelfInvoiceSummaryScreen> {
  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  int _page = 1;
  final int _pageSize = 25;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;

  void _initializeFromRoute(Map<String, Object?> parsedParams) {
    if (_isInitialized) return;
    _startDate = parsedParams['startDate'] as DateTime;
    _endDate = parsedParams['endDate'] as DateTime;
    _appliedStartDate = _startDate;
    _appliedEndDate = _endDate;
    _isInitialized = true;
  }

  void _markFiltersDirty() {
    setState(() {
      _page = 1;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
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

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _page = 1;
      _hasPendingFilterChanges = false;
    });
  }

  void _handlePageChanged(int page) {
    if (_page == page) return;
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    final routerState = GoRouterState.of(context);
    final parsedParams = ReportUtils.parseReportParams(context, routerState);
    _initializeFromRoute(parsedParams);

    final startDate = _startDate!;
    final endDate = _endDate!;
    final appliedStartDate = _appliedStartDate!;
    final appliedEndDate = _appliedEndDate!;
    final orgDatePattern = ref.watch(orgDateFormatProvider);
    final dateFormat = ReportFormatterCache.date(orgDatePattern);
    final dateLabel =
        'From ${dateFormat.format(appliedStartDate)} To ${dateFormat.format(appliedEndDate)}';
    const rows = <_SelfInvoiceSummaryRow>[];

    return ReportViewScaffold(
      categoryLabel: 'Taxes',
      reportTitle: _selfInvoiceSummaryTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _SelfInvoiceSummaryHeading(dateLabel: dateLabel),
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: startDate,
          initialEndDate: endDate,
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
      showSettings: false,
      showSchedule: false,
      showReload: true,
      showRefresh: false,
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
      tableHeaderActions: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [ReportCustomizeColumnsButton(count: 8)],
      ),
      isLoading: false,
      errorMessage: null,
      onRetry: _runReport,
      isEmpty: false,
      emptyTitle: 'There are no transactions during the selected date range.',
      emptyMessage: 'There are no transactions during the selected date range.',
      currentNavigationCategory: 'Taxes',
      currentNavigationReport: _selfInvoiceSummaryTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _selfInvoiceSummaryTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _SelfInvoiceSummaryTable(
        rows: rows,
        totalCount: 0,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}

class _SelfInvoiceSummaryHeading extends StatelessWidget {
  final String dateLabel;

  const _SelfInvoiceSummaryHeading({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _selfInvoiceSummaryTitle,
          textAlign: TextAlign.center,
          style: AppTheme.pageTitle,
        ),
        const SizedBox(height: AppTheme.space10),
        Text(
          'A summary of self-invoices that were generated on your purchase where reverse charge was applied',
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppTheme.space10),
        Text(
          dateLabel,
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SelfInvoiceSummaryTable extends StatelessWidget {
  final List<_SelfInvoiceSummaryRow> rows;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _SelfInvoiceSummaryTable({
    required this.rows,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1320
            ? 1320.0
            : constraints.maxWidth;
        final hasBoundedHeight = constraints.maxHeight.isFinite;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            height: hasBoundedHeight ? constraints.maxHeight : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                if (rows.isEmpty)
                  hasBoundedHeight
                      ? const Expanded(child: _SelfInvoiceEmptyBody())
                      : const _SelfInvoiceEmptyBody()
                else ...[
                  for (final row in rows) _SelfInvoiceDataRow(row: row),
                  ReportPaginationFooter(
                    totalCount: totalCount,
                    page: page,
                    pageSize: pageSize,
                    onPageChanged: onPageChanged,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.tableHeaderBg,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: _buildSelfInvoiceRow(
        date: _headerText('DATE'),
        selfInvoiceNumber: _headerText(
          'SELF-INVOICE NUMBER',
          showSortIcon: true,
        ),
        transactionType: _headerText('TRANSACTION TYPE'),
        transactionNumber: _headerText('TRANSACTION#'),
        igstAmount: _headerText('IGST AMOUNT', alignRight: true),
        cgstAmount: _headerText('CGST AMOUNT', alignRight: true),
        sgstAmount: _headerText('SGST AMOUNT', alignRight: true),
        cessAmount: _headerText('CESS AMOUNT', alignRight: true),
      ),
    );
  }
}

class _SelfInvoiceDataRow extends StatelessWidget {
  final _SelfInvoiceSummaryRow row;

  const _SelfInvoiceDataRow({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildSelfInvoiceRow(
        date: _bodyText(row.date),
        selfInvoiceNumber: _bodyText(row.selfInvoiceNumber),
        transactionType: _bodyText(row.transactionType),
        transactionNumber: _bodyText(row.transactionNumber),
        igstAmount: _amountPlaceholder(row.igstAmount),
        cgstAmount: _amountPlaceholder(row.cgstAmount),
        sgstAmount: _amountPlaceholder(row.sgstAmount),
        cessAmount: _amountPlaceholder(row.cessAmount),
      ),
    );
  }
}

class _SelfInvoiceEmptyBody extends StatelessWidget {
  const _SelfInvoiceEmptyBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      alignment: Alignment.center,
      color: AppTheme.backgroundColor,
      child: Text(
        'There are no transactions during the selected date range.',
        style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

Widget _buildSelfInvoiceRow({
  required Widget date,
  required Widget selfInvoiceNumber,
  required Widget transactionType,
  required Widget transactionNumber,
  required Widget igstAmount,
  required Widget cgstAmount,
  required Widget sgstAmount,
  required Widget cessAmount,
}) {
  return Row(
    children: [
      Expanded(flex: 2, child: date),
      Expanded(flex: 3, child: selfInvoiceNumber),
      Expanded(flex: 3, child: transactionType),
      Expanded(flex: 3, child: transactionNumber),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: igstAmount),
      ),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: cgstAmount),
      ),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: sgstAmount),
      ),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.centerRight, child: cessAmount),
      ),
    ],
  );
}

Widget _headerText(
  String label, {
  bool alignRight = false,
  bool showSortIcon = false,
}) {
  final text = Text(label, style: ReportTableTypography.header);
  final child = showSortIcon
      ? Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            text,
            const SizedBox(width: AppTheme.space4),
            const Icon(
              LucideIcons.chevronsUpDown,
              size: 12,
              color: AppTheme.primaryBlue,
            ),
          ],
        )
      : text;

  return Align(
    alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
    child: child,
  );
}

Widget _bodyText(String value) {
  return Text(
    value.isEmpty ? '--' : value,
    overflow: TextOverflow.ellipsis,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w500,
    ),
  );
}

Widget _amountPlaceholder(String value) {
  return Text(
    value,
    textAlign: TextAlign.right,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _SelfInvoiceSummaryRow {
  final String date;
  final String selfInvoiceNumber;
  final String transactionType;
  final String transactionNumber;
  final String igstAmount;
  final String cgstAmount;
  final String sgstAmount;
  final String cessAmount;

  const _SelfInvoiceSummaryRow({
    required this.date,
    required this.selfInvoiceNumber,
    required this.transactionType,
    required this.transactionNumber,
    required this.igstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.cessAmount,
  });
}
