import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';

const String _iffTitle = 'Invoice Furnishing Facility(IFF)';
const String _iffNavigationTitle = 'Invoice Furnishing Facility (IFF)';

class InvoiceFurnishingFacilityScreen extends ConsumerStatefulWidget {
  const InvoiceFurnishingFacilityScreen({super.key});

  @override
  ConsumerState<InvoiceFurnishingFacilityScreen> createState() =>
      _InvoiceFurnishingFacilityScreenState();
}

class _InvoiceFurnishingFacilityScreenState
    extends ConsumerState<InvoiceFurnishingFacilityScreen> {
  static const List<String> _gstinOptions = <String>[
    '32AACCZ4912F1Z5',
    '32AACCZ4912F1Z6',
    '32AACCZ4912F1Z7',
  ];

  bool _isInitialized = false;
  bool _hasPendingFilterChanges = false;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;
  String _selectedGstin = _gstinOptions.first;

  void _initializeFromRoute(Map<String, Object?> parsedParams) {
    if (_isInitialized) return;
    _startDate = parsedParams['startDate'] as DateTime;
    _endDate = parsedParams['endDate'] as DateTime;
    _appliedStartDate = _startDate;
    _appliedEndDate = _endDate;
    _isInitialized = true;
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleGstinChanged(String value) {
    if (_selectedGstin == value) return;
    setState(() {
      _selectedGstin = value;
      _hasPendingFilterChanges = true;
    });
  }

  void _runReport() {
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _hasPendingFilterChanges = false;
    });
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
    final currencyAsync = ref.watch(defaultCurrencyProvider);
    final currencyFormat = NumberFormat.currency(
      symbol: currencyAsync.valueOrNull?.symbol ?? '\u20B9',
      decimalDigits: 2,
    );

    return ReportViewScaffold(
      categoryLabel: 'Taxes',
      reportTitle: _iffTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _IffHeading(dateLabel: dateLabel),
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: startDate,
          initialEndDate: endDate,
          onChanged: _handleDateRangeChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'GSTIN',
          value: _selectedGstin,
          options: _gstinOptions,
          width: 216,
          onChanged: _handleGstinChanged,
        ),
      ],
      onRunReport: _runReport,
      showInlineRunReportButton: true,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showSettings: false,
      showSchedule: false,
      showReload: false,
      showRefresh: true,
      leadingToolbarActions: [
        ReportIconActionButton(
          icon: LucideIcons.share2,
          onPressed: () {},
          tooltip: 'Share report',
        ),
      ],
      onRefresh: _runReport,
      onReload: _runReport,
      onExport: () {},
      onDownload: () {},
      onPrint: () {},
      onClose: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      isLoading: false,
      errorMessage: null,
      onRetry: _runReport,
      isEmpty: false,
      emptyTitle: 'There are no transactions during the selected date range.',
      emptyMessage: 'There are no transactions during the selected date range.',
      currentNavigationCategory: 'Taxes',
      currentNavigationReport: _iffNavigationTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _iffNavigationTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _IffTable(currencyFormat: currencyFormat),
    );
  }
}

class _IffHeading extends StatelessWidget {
  final String dateLabel;

  const _IffHeading({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _iffTitle,
          textAlign: TextAlign.center,
          style: AppTheme.pageTitle,
        ),
        const SizedBox(height: AppTheme.space10),
        Text(
          dateLabel,
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _IffTable extends StatelessWidget {
  final NumberFormat currencyFormat;

  const _IffTable({required this.currencyFormat});

  static const List<_IffRow> _rows = <_IffRow>[
    _IffRow(
      description:
          'Taxable outward supplies made to\nregistered persons (including UIN-\nholders)',
      igstAmount: 0,
      cgstAmount: 10,
      sgstAmount: 10,
      invoiceTotal: 420,
    ),
    _IffRow(
      description: 'Details of Credit/Debit Notes and\nRefund Voucher',
      igstAmount: 0,
      cgstAmount: 5,
      sgstAmount: 5,
      invoiceTotal: 210,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : null;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: constraints.maxWidth < 920 ? 920 : constraints.maxWidth,
            height: viewportHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: AppTheme.space32),
                child: SizedBox(
                  width: 900,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      for (final row in _rows)
                        _IffDataRow(row: row, currencyFormat: currencyFormat),
                    ],
                  ),
                ),
              ),
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
      child: _buildIffRow(
        description: _headerText('DESCRIPTION'),
        igst: _headerText('IGST AMOUNT', alignRight: true),
        cgst: _headerText('CGST AMOUNT', alignRight: true),
        sgst: _headerText('SGST AMOUNT', alignRight: true),
        total: _headerText('INVOICE TOTAL', alignRight: true),
      ),
    );
  }
}

class _IffDataRow extends StatelessWidget {
  final _IffRow row;
  final NumberFormat currencyFormat;

  const _IffDataRow({required this.row, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildIffRow(
        description: Text(
          row.description,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
        igst: _amountText(row.igstAmount, currencyFormat),
        cgst: _amountText(row.cgstAmount, currencyFormat),
        sgst: _amountText(row.sgstAmount, currencyFormat),
        total: _invoiceTotalText(row.invoiceTotal, currencyFormat),
      ),
    );
  }
}

Widget _buildIffRow({
  required Widget description,
  required Widget igst,
  required Widget cgst,
  required Widget sgst,
  required Widget total,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 4, child: description),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.topRight, child: igst),
      ),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.topRight, child: cgst),
      ),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.topRight, child: sgst),
      ),
      Expanded(
        flex: 2,
        child: Align(alignment: Alignment.topRight, child: total),
      ),
    ],
  );
}

Widget _headerText(String label, {bool alignRight = false}) {
  return Align(
    alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
    child: Text(label, style: ReportTableTypography.header),
  );
}

Widget _amountText(double value, NumberFormat currencyFormat) {
  return Text(
    currencyFormat.format(value),
    textAlign: TextAlign.right,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w500,
    ),
  );
}

Widget _invoiceTotalText(double value, NumberFormat currencyFormat) {
  return Text(
    currencyFormat.format(value),
    textAlign: TextAlign.right,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _IffRow {
  final String description;
  final double igstAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double invoiceTotal;

  const _IffRow({
    required this.description,
    required this.igstAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.invoiceTotal,
  });
}
