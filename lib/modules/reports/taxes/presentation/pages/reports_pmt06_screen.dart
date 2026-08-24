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

const String _pmt06Title = 'PMT-06 (Self Assessment Basis)';

class Pmt06Screen extends ConsumerStatefulWidget {
  const Pmt06Screen({super.key});

  @override
  ConsumerState<Pmt06Screen> createState() => _Pmt06ScreenState();
}

class _Pmt06ScreenState extends ConsumerState<Pmt06Screen> {
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
      reportTitle: _pmt06Title,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _Pmt06Heading(dateLabel: dateLabel),
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
      showExport: false,
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
      currentNavigationReport: _pmt06Title,
      onReportSelected: (reportName, category) {
        if (reportName == _pmt06Title) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _Pmt06ReportBody(currencyFormat: currencyFormat),
    );
  }
}

class _Pmt06Heading extends StatelessWidget {
  final String dateLabel;

  const _Pmt06Heading({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _pmt06Title,
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

class _Pmt06ReportBody extends StatelessWidget {
  final NumberFormat currencyFormat;

  const _Pmt06ReportBody({required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth < 960 ? 960.0 : 960.0;
        return SingleChildScrollView(
          primary: false,
          physics: const ClampingScrollPhysics(),
          child: Center(
            child: SizedBox(
              width: contentWidth,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: AppTheme.space36,
                  bottom: AppTheme.space32,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Pmt06SectionTitle(
                      title:
                          '3.1 Details of Outward Supplies and inward supplies liable to reverse charge',
                    ),
                    const SizedBox(height: AppTheme.space10),
                    _Pmt06TaxTable(
                      firstColumnTitle: 'Nature of Supply',
                      headerColor: AppTheme.selectionInactiveBg,
                      numberRowColor: AppTheme.selectionActiveBg,
                      rows: [
                        _Pmt06TaxRow(
                          label:
                              '(a) Outward taxable supplies\n(other than zero rated, nil rated and exempted)',
                          integratedTax: 0,
                          centralTax: 9018.22,
                          stateTax: 9018.22,
                          cessTax: 0,
                        ),
                        _Pmt06TaxRow(
                          label: '(b) Outward taxable supplies (zero rated)',
                          integratedTax: 0,
                          cessTax: 0,
                        ),
                        _Pmt06TaxRow(
                          label: '(c) Inward supplies (liable to reverse charge)',
                          integratedTax: 0,
                          centralTax: 0,
                          stateTax: 0,
                          cessTax: 0,
                        ),
                        _Pmt06TaxRow(
                          label: 'Total value',
                          integratedTax: 0,
                          centralTax: 9018.22,
                          stateTax: 9018.22,
                          cessTax: 0,
                          isTotal: true,
                        ),
                      ],
                      currencyFormat: currencyFormat,
                    ),
                    const SizedBox(height: AppTheme.space28),
                    const _Pmt06SectionTitle(title: '4. Eligible ITC'),
                    const SizedBox(height: AppTheme.space10),
                    _Pmt06TaxTable(
                      firstColumnTitle: 'Details',
                      headerColor: AppTheme.warningBg,
                      numberRowColor: AppTheme.warningOrange.withValues(alpha: 0.28),
                      rows: [
                        const _Pmt06TaxRow(
                          label: '(A) ITC Available (whether in full or part)',
                          isSection: true,
                        ),
                        _Pmt06TaxRow(
                          label: '    (1) Import of Goods',
                          integratedTax: 0,
                          cessTax: 0,
                        ),
                        _Pmt06TaxRow(
                          label: '    (2) All other ITC',
                          integratedTax: 0,
                          centralTax: 0,
                          stateTax: 0,
                          cessTax: 0,
                        ),
                        _Pmt06TaxRow(
                          label: 'Total value',
                          integratedTax: 0,
                          centralTax: 0,
                          stateTax: 0,
                          cessTax: 0,
                          isTotal: true,
                        ),
                      ],
                      currencyFormat: currencyFormat,
                    ),
                    const SizedBox(height: AppTheme.space28),
                    const _Pmt06SectionTitle(
                      title: 'Total Tax Liability (Total(3.1) - Total(4))',
                    ),
                    const SizedBox(height: AppTheme.space10),
                    _Pmt06TaxTable(
                      firstColumnTitle: 'Details',
                      headerColor: AppTheme.warningBg,
                      numberRowColor: AppTheme.warningOrange.withValues(alpha: 0.28),
                      rows: [
                        _Pmt06TaxRow(
                          label: 'Total Tax Liability',
                          integratedTax: 0,
                          centralTax: 9018.22,
                          stateTax: 9018.22,
                          cessTax: 0,
                          isTotal: true,
                        ),
                      ],
                      currencyFormat: currencyFormat,
                    ),
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

class _Pmt06SectionTitle extends StatelessWidget {
  final String title;

  const _Pmt06SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTheme.sectionHeader.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _Pmt06TaxTable extends StatelessWidget {
  final String firstColumnTitle;
  final Color headerColor;
  final Color numberRowColor;
  final List<_Pmt06TaxRow> rows;
  final NumberFormat currencyFormat;

  const _Pmt06TaxTable({
    required this.firstColumnTitle,
    required this.headerColor,
    required this.numberRowColor,
    required this.rows,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderMid),
        color: AppTheme.backgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Pmt06GridRow(
            color: headerColor,
            cells: [
              _Pmt06Cell(text: firstColumnTitle, isHeader: true),
              const _Pmt06Cell(text: 'Integrated Tax', isHeader: true),
              const _Pmt06Cell(text: 'Central Tax', isHeader: true),
              const _Pmt06Cell(text: 'State/UT Tax', isHeader: true),
              const _Pmt06Cell(text: 'CESS Tax', isHeader: true),
            ],
          ),
          _Pmt06GridRow(
            color: numberRowColor,
            cells: const [
              _Pmt06Cell(text: '1', alignCenter: true),
              _Pmt06Cell(text: '2', alignCenter: true),
              _Pmt06Cell(text: '3', alignCenter: true),
              _Pmt06Cell(text: '4', alignCenter: true),
              _Pmt06Cell(text: '5', alignCenter: true),
            ],
          ),
          for (final row in rows)
            _Pmt06GridRow(
              cells: [
                _Pmt06Cell(text: row.label, isTotal: row.isTotal),
                _Pmt06Cell(
                  text: _formatNullable(row.integratedTax),
                  alignRight: true,
                  isTotal: row.isTotal,
                ),
                _Pmt06Cell(
                  text: _formatNullable(row.centralTax),
                  alignRight: true,
                  isTotal: row.isTotal,
                ),
                _Pmt06Cell(
                  text: _formatNullable(row.stateTax),
                  alignRight: true,
                  isTotal: row.isTotal,
                ),
                _Pmt06Cell(
                  text: _formatNullable(row.cessTax),
                  alignRight: true,
                  isTotal: row.isTotal,
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatNullable(double? value) {
    if (value == null) return '';
    return currencyFormat.format(value);
  }
}

class _Pmt06GridRow extends StatelessWidget {
  final List<_Pmt06Cell> cells;
  final Color? color;

  const _Pmt06GridRow({required this.cells, this.color});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 32, child: cells[0].copyWith(color: color)),
          Expanded(flex: 11, child: cells[1].copyWith(color: color)),
          Expanded(flex: 11, child: cells[2].copyWith(color: color)),
          Expanded(flex: 12, child: cells[3].copyWith(color: color)),
          Expanded(flex: 10, child: cells[4].copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Pmt06Cell extends StatelessWidget {
  final String text;
  final bool isHeader;
  final bool isTotal;
  final bool alignRight;
  final bool alignCenter;
  final Color? color;

  const _Pmt06Cell({
    required this.text,
    this.isHeader = false,
    this.isTotal = false,
    this.alignRight = false,
    this.alignCenter = false,
    this.color,
  });

  _Pmt06Cell copyWith({Color? color}) {
    return _Pmt06Cell(
      text: text,
      isHeader: isHeader,
      isTotal: isTotal,
      alignRight: alignRight,
      alignCenter: alignCenter,
      color: color ?? this.color,
    );
  }

  @override
  Widget build(BuildContext context) {
    final alignment = alignCenter
        ? Alignment.center
        : alignRight
            ? Alignment.centerRight
            : Alignment.centerLeft;
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space14,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: color ?? AppTheme.backgroundColor,
        border: const Border(
          right: BorderSide(color: AppTheme.borderMid),
          bottom: BorderSide(color: AppTheme.borderMid),
        ),
      ),
      child: Text(
        text,
        textAlign: alignRight
            ? TextAlign.right
            : alignCenter
                ? TextAlign.center
                : TextAlign.left,
        style: AppTheme.bodyText.copyWith(
          color: isHeader ? AppTheme.textSecondary : AppTheme.textPrimary,
          fontWeight: isTotal
              ? FontWeight.w700
              : isHeader
                  ? FontWeight.w500
                  : FontWeight.w400,
          height: 1.45,
        ),
      ),
    );
  }
}

class _Pmt06TaxRow {
  final String label;
  final double? integratedTax;
  final double? centralTax;
  final double? stateTax;
  final double? cessTax;
  final bool isTotal;
  final bool isSection;

  const _Pmt06TaxRow({
    required this.label,
    this.integratedTax,
    this.centralTax,
    this.stateTax,
    this.cessTax,
    this.isTotal = false,
    this.isSection = false,
  });
}