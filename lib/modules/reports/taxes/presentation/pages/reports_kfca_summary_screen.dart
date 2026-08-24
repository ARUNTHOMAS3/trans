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
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';

const String _kfcaSummaryTitle = 'KFC-A Summary';

class KfcaSummaryScreen extends ConsumerStatefulWidget {
  const KfcaSummaryScreen({super.key});

  @override
  ConsumerState<KfcaSummaryScreen> createState() => _KfcaSummaryScreenState();
}

class _KfcaSummaryScreenState extends ConsumerState<KfcaSummaryScreen> {
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
      reportTitle: _kfcaSummaryTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _KfcaSummaryHeading(dateLabel: dateLabel),
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
      currentNavigationReport: _kfcaSummaryTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _kfcaSummaryTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _KfcaSummaryTable(currencyFormat: currencyFormat),
    );
  }
}

class _KfcaSummaryHeading extends StatelessWidget {
  final String dateLabel;

  const _KfcaSummaryHeading({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _kfcaSummaryTitle,
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

class _KfcaSummaryTable extends StatelessWidget {
  final NumberFormat currencyFormat;

  const _KfcaSummaryTable({required this.currencyFormat});

  static const List<_KfcaSummaryRow> _rows = <_KfcaSummaryRow>[
    _KfcaSummaryRow(
      serialNumber: '1',
      category: 'Taxable supply at the rate of 1.5% SGST',
      registeredSupply: 0,
      unregisteredSupply: 0,
      total: 0,
      rate: '0.25',
      kfcPayable: 0,
    ),
    _KfcaSummaryRow(
      serialNumber: '2',
      category: 'Taxable supply at the rate of 6% SGST',
      registeredSupply: 0,
      unregisteredSupply: 0,
      total: 0,
      rate: '1',
      kfcPayable: 0,
    ),
    _KfcaSummaryRow(
      serialNumber: '3',
      category: 'Taxable supply at the rate of 9% SGST',
      registeredSupply: 0,
      unregisteredSupply: 0,
      total: 0,
      rate: '1',
      kfcPayable: 0,
    ),
    _KfcaSummaryRow(
      serialNumber: '4',
      category: 'Taxable supply at the rate of 14% SGST',
      registeredSupply: 0,
      unregisteredSupply: 0,
      total: 0,
      rate: '1',
      kfcPayable: 0,
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
            width: constraints.maxWidth < 1260 ? 1260 : constraints.maxWidth,
            height: viewportHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: AppTheme.space32),
                child: SizedBox(
                  width: 1200,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _KfcaHeaderRow(),
                      for (final row in _rows)
                        _KfcaDataRow(row: row, currencyFormat: currencyFormat),
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
}

class _KfcaHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headerCell('S.No', width: 52, height: 124, alignment: Alignment.center),
        _headerCell(
          'Category of Supply',
          width: 264,
          height: 124,
          alignment: Alignment.centerLeft,
        ),
        SizedBox(
          width: 580,
          height: 124,
          child: Column(
            children: [
              _headerCell(
                'Value of Intra-State Supply',
                width: 580,
                height: 42,
                alignment: Alignment.center,
              ),
              Row(
                children: [
                  _headerCell(
                    'To taxable person having GST registration\nin the State, not in furtherance of\nbusiness',
                    width: 288,
                    height: 82,
                    alignment: Alignment.centerRight,
                  ),
                  _headerCell(
                    'To unregistered\npersons',
                    width: 172,
                    height: 82,
                    alignment: Alignment.centerRight,
                  ),
                  _headerCell(
                    'Total',
                    width: 120,
                    height: 82,
                    alignment: Alignment.centerRight,
                  ),
                ],
              ),
            ],
          ),
        ),
        _headerCell(
          'Rate of KFC on value of\nsupply',
          width: 206,
          height: 124,
          alignment: Alignment.centerRight,
        ),
        _headerCell(
          'KFC\npayable',
          width: 98,
          height: 124,
          alignment: Alignment.centerRight,
        ),
      ],
    );
  }
}

class _KfcaDataRow extends StatelessWidget {
  final _KfcaSummaryRow row;
  final NumberFormat currencyFormat;

  const _KfcaDataRow({required this.row, required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _bodyCell(row.serialNumber, width: 52, alignment: Alignment.center),
        _bodyCell(row.category, width: 264),
        _amountCell(row.registeredSupply, currencyFormat, width: 288),
        _amountCell(row.unregisteredSupply, currencyFormat, width: 172),
        _amountCell(
          row.total,
          currencyFormat,
          width: 120,
          color: AppTheme.primaryBlue,
        ),
        _bodyCell(row.rate, width: 206, alignment: Alignment.centerRight),
        _amountCell(row.kfcPayable, currencyFormat, width: 98),
      ],
    );
  }
}

Widget _headerCell(
  String text, {
  required double width,
  required double height,
  Alignment alignment = Alignment.centerLeft,
}) {
  return Container(
    width: width,
    height: height,
    padding: const EdgeInsets.symmetric(
      horizontal: AppTheme.space10,
      vertical: AppTheme.space8,
    ),
    alignment: alignment,
    decoration: BoxDecoration(
      color: AppTheme.backgroundColor,
      border: Border.all(color: AppTheme.borderLight),
    ),
    child: Text(
      text,
      textAlign: alignment == Alignment.centerRight
          ? TextAlign.right
          : TextAlign.left,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
        height: 1.45,
      ),
    ),
  );
}

Widget _bodyCell(
  String text, {
  required double width,
  Alignment alignment = Alignment.centerLeft,
}) {
  return Container(
    width: width,
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
    alignment: alignment,
    decoration: BoxDecoration(
      color: AppTheme.backgroundColor,
      border: Border.all(color: AppTheme.borderLight),
    ),
    child: Text(
      text,
      overflow: TextOverflow.ellipsis,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

Widget _amountCell(
  double value,
  NumberFormat currencyFormat, {
  required double width,
  Color color = AppTheme.textPrimary,
}) {
  return Container(
    width: width,
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
    alignment: Alignment.centerRight,
    decoration: BoxDecoration(
      color: AppTheme.backgroundColor,
      border: Border.all(color: AppTheme.borderLight),
    ),
    child: Text(
      currencyFormat.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.bodyText.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _KfcaSummaryRow {
  final String serialNumber;
  final String category;
  final double registeredSupply;
  final double unregisteredSupply;
  final double total;
  final String rate;
  final double kfcPayable;

  const _KfcaSummaryRow({
    required this.serialNumber,
    required this.category,
    required this.registeredSupply,
    required this.unregisteredSupply,
    required this.total,
    required this.rate,
    required this.kfcPayable,
  });
}
