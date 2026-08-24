import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';

const String _gstr2Title = 'Summary of Inward Supplies (GSTR-2)';
const String _gstr2NavigationTitle = 'Summary of Inward Supplies';

class Gstr2InwardSuppliesSummaryScreen extends ConsumerStatefulWidget {
  const Gstr2InwardSuppliesSummaryScreen({super.key});

  @override
  ConsumerState<Gstr2InwardSuppliesSummaryScreen> createState() =>
      _Gstr2InwardSuppliesSummaryScreenState();
}

class _Gstr2InwardSuppliesSummaryScreenState
    extends ConsumerState<Gstr2InwardSuppliesSummaryScreen> {
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
      reportTitle: _gstr2Title,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _Gstr2Heading(dateLabel: dateLabel),
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
      currentNavigationReport: _gstr2NavigationTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _gstr2NavigationTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _Gstr2ReportContent(currencyFormat: currencyFormat),
    );
  }
}

class _Gstr2Heading extends StatelessWidget {
  final String dateLabel;

  const _Gstr2Heading({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _gstr2Title,
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

class _Gstr2ReportContent extends StatelessWidget {
  final NumberFormat currencyFormat;

  const _Gstr2ReportContent({required this.currencyFormat});

  static const List<_Gstr2Row> _rows = <_Gstr2Row>[
    _Gstr2Row(
      description: 'Purchases Received From Registered\ntaxpayers',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      billTotal: 0,
    ),
    _Gstr2Row(
      description: 'Purchases Received From\nUnregistered taxpayers',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      billTotal: 0,
    ),
    _Gstr2Row(
      description: 'Details of Credit/Debit Notes/Refund\nVoucher',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      billTotal: 0,
    ),
    _Gstr2Row(
      description:
          'Details of Credit/Debit Notes/Refund\nVoucher for Unregistered Vendor',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      billTotal: 950,
    ),
    _Gstr2Row(
      description: 'Goods /Capital goods received from\nOverseas',
      igstAmount: 0,
      billTotal: 0,
    ),
    _Gstr2Row(
      description: 'Services received from Overseas',
      igstAmount: 0,
      billTotal: 0,
    ),
    _Gstr2Row(
      description:
          'Supplies received from compounding\ndealer & other exempt/nil/non GST\nsupplies',
      billTotal: -203,
    ),
    _Gstr2Row(
      description: 'HSN-wise summary of inward supplies',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      billTotal: -303,
    ),
    _Gstr2Row(description: 'TDS Credit received'),
    _Gstr2Row(description: 'ISD credit received'),
    _Gstr2Row(
      description:
          'Inwards Supplies on which tax is to be\npaid on reverse charge',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
    ),
    _Gstr2Row(
      description: 'Advances paid on account of receipt of\nsupply',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      billTotal: 0,
    ),
    _Gstr2Row(
      description: 'Advance adjusted on account of\nreceipt of supply',
      igstAmount: 0,
      cgstAmount: 0,
      sgstAmount: 0,
      billTotal: 0,
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
                    const _Gstr2InfoBanner(),
                    const SizedBox(height: AppTheme.space28),
                    SizedBox(
                      width: 900,
                      child: _Gstr2SummaryTable(
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

class _Gstr2InfoBanner extends StatelessWidget {
  const _Gstr2InfoBanner();

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
class _Gstr2SummaryTable extends StatelessWidget {
  final List<_Gstr2Row> rows;
  final NumberFormat currencyFormat;

  const _Gstr2SummaryTable({
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
            _Gstr2DataRow(row: row, currencyFormat: currencyFormat),
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
      child: _buildGstr2Row(
        description: _headerText('DESCRIPTION'),
        igst: _headerText('IGST AMOUNT', alignRight: true),
        cgst: _headerText('CGST AMOUNT', alignRight: true),
        sgst: _headerText('SGST AMOUNT', alignRight: true),
        total: _headerText('BILL TOTAL', alignRight: true),
      ),
    );
  }
}

class _Gstr2DataRow extends StatelessWidget {
  final _Gstr2Row row;
  final NumberFormat currencyFormat;

  const _Gstr2DataRow({required this.row, required this.currencyFormat});

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
      child: _buildGstr2Row(
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
        total: _billTotalText(row.billTotal, currencyFormat),
      ),
    );
  }
}

Widget _buildGstr2Row({
  required Widget description,
  required Widget igst,
  required Widget cgst,
  required Widget sgst,
  required Widget total,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 42, child: description),
      Expanded(flex: 18, child: Align(alignment: Alignment.topRight, child: igst)),
      Expanded(flex: 18, child: Align(alignment: Alignment.topRight, child: cgst)),
      Expanded(flex: 18, child: Align(alignment: Alignment.topRight, child: sgst)),
      Expanded(flex: 16, child: Align(alignment: Alignment.topRight, child: total)),
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

Widget _billTotalText(double? value, NumberFormat currencyFormat) {
  if (value == null) return const SizedBox.shrink();
  return Text(
    currencyFormat.format(value),
    textAlign: TextAlign.right,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.primaryBlue,
      fontWeight: FontWeight.w500,
    ),
  );
}

class _Gstr2Row {
  final String description;
  final double? igstAmount;
  final double? cgstAmount;
  final double? sgstAmount;
  final double? billTotal;

  const _Gstr2Row({
    required this.description,
    this.igstAmount,
    this.cgstAmount,
    this.sgstAmount,
    this.billTotal,
  });
}
