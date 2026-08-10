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

const String _gstr1Title = 'Summary of Outward Supplies (GSTR-1)';
const String _gstr1NavigationTitle = 'Summary of Outward Supplies';

class Gstr1OutwardSuppliesSummaryScreen extends ConsumerStatefulWidget {
  const Gstr1OutwardSuppliesSummaryScreen({super.key});

  @override
  ConsumerState<Gstr1OutwardSuppliesSummaryScreen> createState() =>
      _Gstr1OutwardSuppliesSummaryScreenState();
}

class _Gstr1OutwardSuppliesSummaryScreenState
    extends ConsumerState<Gstr1OutwardSuppliesSummaryScreen> {
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
      reportTitle: _gstr1Title,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _Gstr1Heading(dateLabel: dateLabel),
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
      currentNavigationReport: _gstr1NavigationTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _gstr1NavigationTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _Gstr1ReportContent(currencyFormat: currencyFormat),
    );
  }
}

class _Gstr1Heading extends StatelessWidget {
  final String dateLabel;

  const _Gstr1Heading({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _gstr1Title,
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

class _Gstr1ReportContent extends StatelessWidget {
  final NumberFormat currencyFormat;

  const _Gstr1ReportContent({required this.currencyFormat});

  static const List<_Gstr1Row> _rows = <_Gstr1Row>[
    _Gstr1Row(
      description:
          'Taxable outward supplies made to\nregistered persons (including UIN-\nholders)',
      igstAmount: 0,
      cgstAmount: 10,
      sgstAmount: 10,
      taxableAmount: 400,
      invoiceTotal: 420,
    ),
    _Gstr1Row(
      description:
          'Taxable outward inter-State supplies\nto un-registered persons where the\ninvoice value is more than \u20B91 lakh',
      igstAmount: 0,
      taxableAmount: 0,
      invoiceTotal: 0,
    ),
    _Gstr1Row(
      description: 'Zero rated supplies and Deemed\nExports',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      taxableAmount: 0,
      invoiceTotal: 0,
    ),
    _Gstr1Row(
      description: 'Nil rated, exempted and non-GST\noutward supplies',
      taxableAmount: 0,
      invoiceTotal: 0,
    ),
    _Gstr1Row(
      description: 'Details of Credit/Debit Notes and\nRefund Voucher',
      igstAmount: 0,
      cgstAmount: 5,
      sgstAmount: 5,
      taxableAmount: 200,
      invoiceTotal: 210,
    ),
    _Gstr1Row(
      description:
          'Details of Credit/Debit Notes and\nRefund Voucher (Unregistered)',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      taxableAmount: 0,
      invoiceTotal: 0,
    ),
    _Gstr1Row(
      description: 'Consolidated Statement of Advances\nReceived',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      invoiceTotal: 0,
    ),
    _Gstr1Row(
      description:
          'Tax already paid (on advance receipt)\non invoices issued in the current period',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      invoiceTotal: 0,
    ),
    _Gstr1Row(
      description: 'HSN-wise summary of the B2B\nSupplies',
      igstAmount: 0,
      cgstAmount: 5,
      sgstAmount: 5,
      taxableAmount: 200,
      invoiceTotal: 210,
    ),
    _Gstr1Row(
      description: 'HSN-wise summary of the B2C\nSupplies',
      igstAmount: 0,
      cgstAmount: 9025,
      sgstAmount: 9025,
      taxableAmount: 101000,
      invoiceTotal: 119050,
    ),
    _Gstr1Row(
      description: 'Supplies made through E-Commerce\nOperators',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      taxableAmount: 0,
      invoiceTotal: 0,
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
            width: constraints.maxWidth < 1040 ? 1040 : constraints.maxWidth,
            height: viewportHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                primary: false,
                physics: const ClampingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const _Gstr1InfoBanner(),
                    const SizedBox(height: AppTheme.space28),
                    SizedBox(
                      width: 900,
                      child: _Gstr1SummaryTable(
                        rows: _rows,
                        currencyFormat: currencyFormat,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Gstr1InfoBanner extends StatelessWidget {
  const _Gstr1InfoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.infoBg,
        border: Border(bottom: BorderSide(color: AppTheme.infoBgBorder)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(LucideIcons.info, size: 16, color: AppTheme.infoBlue),
          const SizedBox(width: AppTheme.space8),
          Expanded(
            child: Text(
              'As per GST regulations, all HSN or SAC codes in a transaction must be valid. Review and update your codes to stay compliant and avoid issues during GST filing. To validate the HSN/SAC codes, kindly navigate to\nthe HSN-wise summary section of this report.',
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Gstr1SummaryTable extends StatelessWidget {
  final List<_Gstr1Row> rows;
  final NumberFormat currencyFormat;

  const _Gstr1SummaryTable({
    required this.rows,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          for (final row in rows)
            _Gstr1DataRow(row: row, currencyFormat: currencyFormat),
        ],
      ),
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
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildGstr1Row(
        description: _headerText('DESCRIPTION'),
        igst: _headerText('IGST AMOUNT', alignRight: true),
        cgst: _headerText('CGST AMOUNT', alignRight: true),
        sgst: _headerText('SGST AMOUNT', alignRight: true),
        taxable: _headerText('TAXABLE AMOUNT', alignRight: true),
        total: _headerText('INVOICE TOTAL', alignRight: true),
      ),
    );
  }
}

class _Gstr1DataRow extends StatelessWidget {
  final _Gstr1Row row;
  final NumberFormat currencyFormat;

  const _Gstr1DataRow({required this.row, required this.currencyFormat});

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
      child: _buildGstr1Row(
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
        taxable: _amountText(row.taxableAmount, currencyFormat),
        total: _invoiceTotalText(row.invoiceTotal, currencyFormat),
      ),
    );
  }
}

Widget _buildGstr1Row({
  required Widget description,
  required Widget igst,
  required Widget cgst,
  required Widget sgst,
  required Widget taxable,
  required Widget total,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 36, child: description),
      Expanded(flex: 15, child: Align(alignment: Alignment.topRight, child: igst)),
      Expanded(flex: 15, child: Align(alignment: Alignment.topRight, child: cgst)),
      Expanded(flex: 15, child: Align(alignment: Alignment.topRight, child: sgst)),
      Expanded(flex: 16, child: Align(alignment: Alignment.topRight, child: taxable)),
      Expanded(flex: 15, child: Align(alignment: Alignment.topRight, child: total)),
    ],
  );
}

Widget _headerText(String label, {bool alignRight = false}) {
  return Align(
    alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
    child: Text(label, style: ReportTableTypography.header),
  );
}

Widget _amountText(double? value, NumberFormat currencyFormat) {
  if (value == null) return const SizedBox.shrink();
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

class _Gstr1Row {
  final String description;
  final double? igstAmount;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? taxableAmount;
  final double invoiceTotal;

  const _Gstr1Row({
    required this.description,
    this.igstAmount,
    this.cgstAmount,
    this.sgstAmount,
    this.taxableAmount,
    required this.invoiceTotal,
  });
}
