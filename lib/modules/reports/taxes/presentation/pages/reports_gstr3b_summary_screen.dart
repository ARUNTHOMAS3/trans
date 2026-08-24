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

const String _gstr3bTitle = 'GSTR-3B Summary';

class Gstr3bSummaryScreen extends ConsumerStatefulWidget {
  const Gstr3bSummaryScreen({super.key});

  @override
  ConsumerState<Gstr3bSummaryScreen> createState() =>
      _Gstr3bSummaryScreenState();
}

class _Gstr3bSummaryScreenState extends ConsumerState<Gstr3bSummaryScreen> {
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
      reportTitle: _gstr3bTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _Gstr3bHeading(dateLabel: dateLabel),
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
      currentNavigationReport: _gstr3bTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _gstr3bTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _Gstr3bReportBody(currencyFormat: currencyFormat),
    );
  }
}

class _Gstr3bHeading extends StatelessWidget {
  final String dateLabel;

  const _Gstr3bHeading({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(_gstr3bTitle, textAlign: TextAlign.center, style: AppTheme.pageTitle),
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

class _Gstr3bReportBody extends StatelessWidget {
  final NumberFormat currencyFormat;

  const _Gstr3bReportBody({required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    final rupee = currencyFormat;
    return SingleChildScrollView(
      primary: false,
      physics: const ClampingScrollPhysics(),
      child: Center(
        child: SizedBox(
          width: 900,
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppTheme.space36,
              bottom: AppTheme.space32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _Gstr3bSectionTitle(
                  title:
                      '3.1 Details of Outward Supplies and inward supplies liable to reverse charge',
                ),
                const SizedBox(height: AppTheme.space10),
                _Gstr3bGridTable(
                  headerColor: AppTheme.selectionInactiveBg,
                  numberColor: AppTheme.selectionActiveBg,
                  flexes: const [45, 10, 10, 9, 10, 6],
                  rows: [
                    const _Gstr3bRow.header([
                      'Nature of Supply',
                      'Taxable\nValue',
                      'Integrated\nTax',
                      'Central\nTax',
                      'State/UT\nTax',
                      'Cess',
                    ]),
                    const _Gstr3bRow.number(['1', '2', '3', '4', '5', '6']),
                    _Gstr3bRow.body([
                      '(a) Outward taxable supplies (other than zero rated, nil rated and\nexempted)',
                      rupee.format(101062),
                      rupee.format(0),
                      rupee.format(9018.22),
                      rupee.format(9018.22),
                      rupee.format(0),
                    ]),
                    _Gstr3bRow.body([
                      '(b) Outward taxable supplies (zero rated)',
                      rupee.format(0),
                      rupee.format(0),
                      '',
                      '',
                      rupee.format(0),
                    ]),
                    _Gstr3bRow.body([
                      '(c) Other outward supplies (Nil rated, exempted)',
                      rupee.format(714),
                      '',
                      '',
                      '',
                      '',
                    ]),
                    _Gstr3bRow.body([
                      '(d) Inward supplies (liable to reverse charge)',
                      rupee.format(0),
                      rupee.format(0),
                      rupee.format(0),
                      rupee.format(0),
                      rupee.format(0),
                    ]),
                    _Gstr3bRow.body([
                      '(e) Non-GST outward supplies',
                      rupee.format(0),
                      '',
                      '',
                      '',
                      '',
                    ]),
                    _Gstr3bRow.body([
                      'Total Value',
                      rupee.format(101776),
                      rupee.format(0),
                      rupee.format(9018.22),
                      rupee.format(9018.22),
                      rupee.format(0),
                    ], isTotal: true),
                  ],
                ),
                const SizedBox(height: AppTheme.space28),
                const _Gstr3bSectionTitle(
                  title:
                      '3.1.1 Details of supplies notified under sub-section (5) of section 9 of the Central Goods and Services Tax Act',
                ),
                const SizedBox(height: AppTheme.space10),
                _Gstr3bGridTable(
                  headerColor: AppTheme.selectionInactiveBg,
                  numberColor: AppTheme.selectionActiveBg,
                  flexes: const [52, 8, 9, 7, 8, 6],
                  rows: [
                    const _Gstr3bRow.header([
                      'Description',
                      'Taxable\nValue',
                      'Integrated\nTax',
                      'Central\nTax',
                      'State/UT\nTax',
                      'Cess',
                    ]),
                    const _Gstr3bRow.number(['1', '2', '3', '4', '5', '6']),
                    const _Gstr3bRow.body([
                      '(i) Taxable supplies on which electronic commerce operator pays tax under\nSub-section (5) of Section 9\n[To be furnished by the electronic commerce operator]',
                      '0',
                      '0',
                      '0',
                      '0',
                      '0',
                    ], muted: true),
                    _Gstr3bRow.body([
                      '(ii) Taxable supplies made by the registered person through electronic\ncommerce operator, on which electronic commerce operator is required to pay\ntax under Sub-section (5) of Section 9\n[To be furnished by the registered person making supplies through electronic\ncommerce operator]',
                      rupee.format(0),
                      '',
                      '',
                      '',
                      '',
                    ], emphasized: true),
                  ],
                ),
                const SizedBox(height: AppTheme.space28),
                const _Gstr3bSectionTitle(
                  title:
                      '3.2 Of the supplies shown in 3.1 (a) above, details of inter-State supplies made to unregistered persons,\ncomposition taxable persons and UIN holders',
                ),
                const SizedBox(height: AppTheme.space10),
                _Gstr3bGridTable(
                  headerColor: AppTheme.selectionInactiveBg,
                  numberColor: AppTheme.selectionActiveBg,
                  flexes: const [25, 22, 20, 22],
                  rows: [
                    _Gstr3bRow.header(['', 'Place of Supply', 'Taxable Value', 'Integrated Tax']),
                    _Gstr3bRow.number(['1', '2', '3', '4']),
                    _Gstr3bRow.section(['Supplies made to Unregistered Persons']),
                    _Gstr3bRow.body(['', '', '', '']),
                    _Gstr3bRow.section(['Supplies made to Composition Taxable Persons']),
                    _Gstr3bRow.body(['', '', '', '']),
                    _Gstr3bRow.section(['Supplies made to UIN holders']),
                    _Gstr3bRow.message('We are not tracking supplies made to UIN holders'),
                  ],
                ),
                const SizedBox(height: AppTheme.space28),
                const _Gstr3bSectionTitle(title: '4. Eligible ITC'),
                const SizedBox(height: AppTheme.space10),
                _Gstr3bGridTable(
                  headerColor: AppTheme.warningBg,
                  numberColor: AppTheme.warningOrange.withValues(alpha: 0.28),
                  flexes: const [50, 12, 10, 11, 7],
                  rows: [
                    const _Gstr3bRow.header([
                      'Details',
                      'Integrated Tax',
                      'Central Tax',
                      'State/UT Tax',
                      'Cess',
                    ]),
                    const _Gstr3bRow.number(['1', '2', '3', '4', '5']),
                    const _Gstr3bRow.section(['(A) ITC Available (whether in full or part)']),
                    _Gstr3bRow.body(['    (1) Import of Goods', rupee.format(0), '', '', rupee.format(0)]),
                    _Gstr3bRow.body(['    (2) Import of Services', rupee.format(0), '', '', rupee.format(0)]),
                    _Gstr3bRow.body([
                      '    (3) Inward supplies liable to reverse charge ( other than 1 & 2 above)',
                      rupee.format(0),
                      rupee.format(0),
                      rupee.format(0),
                      rupee.format(0),
                    ]),
                    _Gstr3bRow.message('- -We do not support in Zoho Books- -'),
                    _Gstr3bRow.body([
                      '    (5) All other ITC',
                      rupee.format(0),
                      rupee.format(0),
                      rupee.format(0),
                      rupee.format(0),
                    ]),
                  ],
                ),
                const SizedBox(height: AppTheme.space28),
                const _Gstr3bSectionTitle(
                  title: '5. Values of exempt, nil-rated and non-GST inward supplies',
                ),
                const SizedBox(height: AppTheme.space10),
                _Gstr3bGridTable(
                  headerColor: AppTheme.warningBg,
                  numberColor: AppTheme.warningOrange.withValues(alpha: 0.28),
                  flexes: const [50, 24, 24],
                  rows: [
                    const _Gstr3bRow.header([
                      'Nature of Supply',
                      'Inter-State Supplies',
                      'Intra-State Supplies',
                    ]),
                    const _Gstr3bRow.number(['1', '2', '3']),
                    _Gstr3bRow.body([
                      'Composition Scheme, Exempted, Nil Rated',
                      rupee.format(0),
                      rupee.format(-203),
                    ]),
                    _Gstr3bRow.body(['Non-GST supply', rupee.format(0), rupee.format(0)]),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Gstr3bSectionTitle extends StatelessWidget {
  final String title;

  const _Gstr3bSectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTheme.sectionHeader.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
        height: 1.35,
      ),
    );
  }
}

class _Gstr3bGridTable extends StatelessWidget {
  final Color headerColor;
  final Color numberColor;
  final List<int> flexes;
  final List<_Gstr3bRow> rows;

  const _Gstr3bGridTable({
    required this.headerColor,
    required this.numberColor,
    required this.flexes,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderMid),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final row in rows) _buildRow(row),
        ],
      ),
    );
  }

  Widget _buildRow(_Gstr3bRow row) {
    if (row.isMessage) {
      return _MergedCell(
        text: row.values.first,
        muted: true,
        color: row.color,
      );
    }
    if (row.isSection) {
      return _MergedCell(text: row.values.first, muted: row.muted, color: row.color);
    }

    final background = row.isHeader
        ? headerColor
        : row.isNumber
            ? numberColor
            : row.color;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < flexes.length; index++)
            Expanded(
              flex: flexes[index],
              child: _Gstr3bCell(
                text: index < row.values.length ? row.values[index] : '',
                color: background,
                isHeader: row.isHeader,
                isTotal: row.isTotal,
                muted: row.muted,
                emphasized: row.emphasized,
                alignRight: index > 0 && !row.isNumber,
                alignCenter: row.isNumber,
              ),
            ),
        ],
      ),
    );
  }
}

class _MergedCell extends StatelessWidget {
  final String text;
  final bool muted;
  final Color? color;

  const _MergedCell({required this.text, this.muted = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 38),
      alignment: text.startsWith('We are') || text.startsWith('- -')
          ? Alignment.center
          : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space14,
        vertical: AppTheme.space8,
      ),
      decoration: BoxDecoration(
        color: color ?? AppTheme.backgroundColor,
        border: const Border(bottom: BorderSide(color: AppTheme.borderMid)),
      ),
      child: Text(
        text,
        textAlign: text.startsWith('We are') || text.startsWith('- -')
            ? TextAlign.center
            : TextAlign.left,
        style: AppTheme.bodyText.copyWith(
          color: muted ? AppTheme.textSecondary : AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
      ),
    );
  }
}

class _Gstr3bCell extends StatelessWidget {
  final String text;
  final Color? color;
  final bool isHeader;
  final bool isTotal;
  final bool muted;
  final bool emphasized;
  final bool alignRight;
  final bool alignCenter;

  const _Gstr3bCell({
    required this.text,
    this.color,
    this.isHeader = false,
    this.isTotal = false,
    this.muted = false,
    this.emphasized = false,
    this.alignRight = false,
    this.alignCenter = false,
  });

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
        textAlign: alignCenter
            ? TextAlign.center
            : alignRight
                ? TextAlign.right
                : TextAlign.left,
        style: AppTheme.bodyText.copyWith(
          color: isHeader || muted ? AppTheme.textSecondary : AppTheme.textPrimary,
          fontWeight: isTotal || emphasized
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

class _Gstr3bRow {
  final List<String> values;
  final bool isHeader;
  final bool isNumber;
  final bool isTotal;
  final bool isSection;
  final bool isMessage;
  final bool muted;
  final bool emphasized;
  final Color? color;

  const _Gstr3bRow.body(
    this.values, {
    this.isTotal = false,
    this.muted = false,
    this.emphasized = false,
  })  : isHeader = false,
        isNumber = false,
        isSection = false,
        isMessage = false,
        color = null;

  const _Gstr3bRow.header(this.values)
      : isHeader = true,
        isNumber = false,
        isTotal = false,
        isSection = false,
        isMessage = false,
        muted = false,
        emphasized = false,
        color = null;

  const _Gstr3bRow.number(this.values)
      : isHeader = false,
        isNumber = true,
        isTotal = false,
        isSection = false,
        isMessage = false,
        muted = false,
        emphasized = false,
        color = null;

  const _Gstr3bRow.section(this.values)
      : isHeader = false,
        isNumber = false,
        isTotal = false,
        isSection = true,
        isMessage = false,
        muted = true,
        emphasized = false,
        color = AppTheme.backgroundColor;

  _Gstr3bRow.message(String message)
      : values = <String>[message],
        isHeader = false,
        isNumber = false,
        isTotal = false,
        isSection = false,
        isMessage = true,
        muted = true,
        emphasized = false,
        color = AppTheme.backgroundColor;
}