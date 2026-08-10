import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_section.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';

class AccountTypeComparisonPeriod {
  final String label;
  final bool isCurrent;
  final DateTime? startDate;
  final DateTime? endDate;

  const AccountTypeComparisonPeriod({
    required this.label,
    required this.isCurrent,
    this.startDate,
    this.endDate,
  });
}

const String _accountTypeSummaryTitle = 'Account Type Summary';

typedef AccountTypeSummaryParams = ({
  String startDate,
  String endDate,
  String basis,
});

final accountTypeSummaryProvider =
    FutureProvider.family<Map<String, dynamic>, AccountTypeSummaryParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return repo.getAccountTypeSummary(
        params.startDate,
        params.endDate,
        basis: params.basis,
      );
    });

class AccountTypeSummaryPage extends ConsumerStatefulWidget {
  const AccountTypeSummaryPage({super.key});

  @override
  ConsumerState<AccountTypeSummaryPage> createState() =>
      _AccountTypeSummaryPageState();
}

class _AccountTypeSummaryPageState
    extends ConsumerState<AccountTypeSummaryPage> {
  static const List<String> _reportBasisOptions = <String>['Accrual', 'Cash'];

  bool _isInitialized = false;
  bool _hasPendingFilterChanges = false;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;
  String _reportBasis = 'Accrual';
  String _appliedReportBasis = 'Accrual';
  String _compareWith = 'None';
  ReportCompareSelection _compareSelection = const ReportCompareSelection.none();

  void _initializeFromRoute(Map<String, Object?> parsedParams) {
    if (_isInitialized) return;
    _startDate = parsedParams['startDate'] as DateTime;
    _endDate = parsedParams['endDate'] as DateTime;
    _appliedStartDate = _startDate;
    _appliedEndDate = _endDate;
    _reportBasis = (parsedParams['basis'] as String?) ?? 'Accrual';
    _appliedReportBasis = _reportBasis;
    _isInitialized = true;
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleReportBasisChanged(String value) {
    if (_reportBasis == value) return;
    setState(() {
      _reportBasis = value;
      _hasPendingFilterChanges = true;
    });
  }

  void _runReport() {
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _appliedReportBasis = _reportBasis;
      _hasPendingFilterChanges = false;
    });
  }

  void _handleCompareSelectionApplied(ReportCompareSelection selection) {
    setState(() {
      _compareWith = selection.displayValue;
      _compareSelection = selection;
    });
  }

  List<AccountTypeComparisonPeriod> _buildComparisonPeriods() {
    if (!_compareSelection.isActive) {
      return const <AccountTypeComparisonPeriod>[];
    }

    final count = _compareSelection.count.clamp(1, 5);
    final currentPeriod = AccountTypeComparisonPeriod(
      label: _formatComparisonPeriod(_appliedStartDate!, _appliedEndDate!),
      isCurrent: true,
      startDate: _appliedStartDate,
      endDate: _appliedEndDate,
    );

    final previousPeriods = <AccountTypeComparisonPeriod>[];

    if (_compareSelection.compareType == 'Previous Year(s)') {
      for (var offset = count; offset >= 1; offset -= 1) {
        final previousStart = DateTime(
          _appliedStartDate!.year - offset.toInt(),
          _appliedStartDate!.month,
          _appliedStartDate!.day,
        );
        final previousEnd = DateTime(
          _appliedEndDate!.year - offset.toInt(),
          _appliedEndDate!.month,
          _appliedEndDate!.day,
        );
        previousPeriods.add(
          AccountTypeComparisonPeriod(
            label: _formatComparisonPeriod(previousStart, previousEnd),
            isCurrent: false,
            startDate: previousStart,
            endDate: previousEnd,
          ),
        );
      }
    } else {
      final periodDays = _appliedEndDate!.difference(_appliedStartDate!).inDays + 1;
      for (var offset = count; offset >= 1; offset -= 1) {
        final previousEnd = _appliedStartDate!.subtract(
          Duration(days: periodDays * (offset.toInt() - 1) + 1),
        );
        final previousStart = previousEnd.subtract(Duration(days: periodDays - 1));
        previousPeriods.add(
          AccountTypeComparisonPeriod(
            label: _formatComparisonPeriod(previousStart, previousEnd),
            isCurrent: false,
            startDate: previousStart,
            endDate: previousEnd,
          ),
        );
      }
    }

    final periods = <AccountTypeComparisonPeriod>[
      ...previousPeriods,
      currentPeriod,
    ];
    
    if (_compareSelection.arrangeLatestFirst) {
      return periods.reversed.toList(growable: false);
    }
    return periods;
  }

  String _formatComparisonPeriod(DateTime startDate, DateTime endDate) {
    final dateFormat = ReportFormatterCache.date('MMM yyyy');
    if (startDate.month == endDate.month && startDate.year == endDate.year) {
      return dateFormat.format(startDate).toUpperCase();
    }
    return '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}'.toUpperCase();
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
    final queryParams = (
      startDate: ReportUtils.formatApiDate(appliedStartDate),
      endDate: ReportUtils.formatApiDate(appliedEndDate),
      basis: _appliedReportBasis,
    );
    final reportAsync = ref.watch(accountTypeSummaryProvider(queryParams));
    final reportData = reportAsync.valueOrNull;
    final sections = _AccountTypeSection.fromResponse(reportData);

    return ReportViewScaffold(
      categoryLabel: 'Accountant',
      reportTitle: _accountTypeSummaryTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _AccountTypeSummaryHeading(
        basis: _appliedReportBasis,
        dateLabel: dateLabel,
      ),
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: startDate,
          initialEndDate: endDate,
          onChanged: _handleDateRangeChanged,
        ),
        ReportSearchableFilterDropdown(
          label: 'Report Basis',
          value: _reportBasis,
          options: _reportBasisOptions,
          onChanged: _handleReportBasisChanged,
        ),
      ],
      onRunReport: _runReport,
      showInlineRunReportButton: true,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showRefresh: false,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: _accountTypeSummaryTitle,
      ),
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
      settingsTooltip: 'Customize the Account Type Summary report.',
      scheduleTooltip: 'Schedule the Account Type Summary report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportCompareSection(
            selectedValue: _compareWith,
            onSelectionApplied: _handleCompareSelectionApplied,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 3),
        ],
      ),
      isLoading: reportAsync.isLoading,
      errorMessage: reportAsync.hasError
          ? 'Unable to load report: ${reportAsync.error}'
          : null,
      onRetry: () => ref.invalidate(accountTypeSummaryProvider(queryParams)),
      isEmpty: sections.isEmpty,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      currentNavigationCategory: 'Accountant',
      currentNavigationReport: _accountTypeSummaryTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _accountTypeSummaryTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _AccountTypeSummaryTable(
        sections: sections,
        startDate: appliedStartDate,
        endDate: appliedEndDate,
        basis: _appliedReportBasis,
        comparisonPeriods: _buildComparisonPeriods(),
      ),
    );
  }
}

class _AccountTypeSummaryHeading extends StatelessWidget {
  final String basis;
  final String dateLabel;

  const _AccountTypeSummaryHeading({
    required this.basis,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _accountTypeSummaryTitle,
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
        const SizedBox(height: AppTheme.space20),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: 'Basis : ',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              TextSpan(text: basis),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccountTypeSummaryTable extends StatelessWidget {
  final List<_AccountTypeSection> sections;
  final DateTime startDate;
  final DateTime endDate;
  final String basis;
  final List<AccountTypeComparisonPeriod> comparisonPeriods;

  const _AccountTypeSummaryTable({
    required this.sections,
    required this.startDate,
    required this.endDate,
    required this.basis,
    this.comparisonPeriods = const [],
  });

  bool get _isComparisonMode => comparisonPeriods.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget tableContent = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _isComparisonMode ? _buildComparisonHeader() : _buildHeader(),
            Expanded(
              child: sections.isEmpty
                  ? const Center(child: Text('No data to display'))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final section in sections) ...[
                            _AccountTypeSummaryDataRow(
                              label: section.accountTypeLabel,
                              accountType: section.accountType,
                              accountTypeLabel: section.accountTypeLabel,
                              debit: null,
                              credit: null,
                              isSection: true,
                              startDate: startDate,
                              endDate: endDate,
                              basis: basis,
                              comparisonPeriods: comparisonPeriods,
                            ),
                            for (final row in section.rows)
                              _AccountTypeSummaryDataRow(
                                label: row.accountTypeLabel,
                                accountType: row.accountType,
                                accountTypeLabel: row.accountTypeLabel,
                                debit: row.debit,
                                credit: row.credit,
                                isSection: false,
                                startDate: startDate,
                                endDate: endDate,
                                basis: basis,
                                comparisonPeriods: comparisonPeriods,
                              ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        );

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: constraints.maxWidth < 826.0 ? constraints.maxWidth : 826.0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: tableContent),
                const SizedBox(height: AppTheme.space6),
                _buildBaseCurrencyNote(),
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
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text('ACCOUNT TYPE', style: ReportTableTypography.header),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'DEBIT',
              textAlign: TextAlign.right,
              style: ReportTableTypography.header,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'CREDIT',
              textAlign: TextAlign.right,
              style: ReportTableTypography.header,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          ...comparisonPeriods.map((period) => Expanded(
                flex: 4,
                child: _comparisonPeriodHeader(period.label),
              )),
        ],
      ),
    );
  }

  Widget _comparisonPeriodHeader(String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.space10),
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppTheme.tableHeaderBg,
            border: Border(
              bottom: BorderSide(color: AppTheme.borderLight),
              right: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: Text(label, style: ReportTableTypography.header),
        ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space10),
                alignment: Alignment.centerRight,
                decoration: const BoxDecoration(
                  color: AppTheme.tableHeaderBg,
                  border: Border(
                    right: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: AppTheme.space20),
                  child: Text('DEBIT', style: ReportTableTypography.header),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.space10),
                alignment: Alignment.centerRight,
                decoration: const BoxDecoration(
                  color: AppTheme.tableHeaderBg,
                  border: Border(
                    right: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: AppTheme.space20),
                  child: Text('CREDIT', style: ReportTableTypography.header),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBaseCurrencyNote() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space16,
        AppTheme.space2,
        AppTheme.space16,
        AppTheme.space12,
      ),
      child: Row(
        children: [
          Text(
            '**Amount is displayed in your base currency ',
            style: AppTheme.captionText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(1),
            ),
            child: Text(
              'INR',
              style: AppTheme.captionText.copyWith(
                color: AppTheme.backgroundColor,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTypeSummaryDataRow extends StatefulWidget {
  final String label;
  final String accountType;
  final String accountTypeLabel;
  final double? debit;
  final double? credit;
  final bool isSection;
  final DateTime startDate;
  final DateTime endDate;
  final String basis;
  final List<AccountTypeComparisonPeriod> comparisonPeriods;

  const _AccountTypeSummaryDataRow({
    required this.label,
    required this.accountType,
    required this.accountTypeLabel,
    required this.debit,
    required this.credit,
    required this.isSection,
    required this.startDate,
    required this.endDate,
    required this.basis,
    this.comparisonPeriods = const [],
  });

  @override
  State<_AccountTypeSummaryDataRow> createState() =>
      _AccountTypeSummaryDataRowState();
}

class _AccountTypeSummaryDataRowState
    extends State<_AccountTypeSummaryDataRow> {
  static final NumberFormat _numberFormat = ReportFormatterCache.number('#,##0.00');
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  void _openDetails() {
    final uri = Uri.parse(AppRoutes.accountantTransactionsReport).replace(
      queryParameters: {
        'accountType': widget.accountType,
        'accountTypeLabel': widget.accountTypeLabel,
        'startDate': ReportUtils.formatApiDate(widget.startDate),
        'endDate': ReportUtils.formatApiDate(widget.endDate),
        'basis': widget.basis,
      },
    );
    context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    final bool isComparisonMode = widget.comparisonPeriods.isNotEmpty;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openDetails,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isComparisonMode ? 0 : AppTheme.space20,
            vertical: isComparisonMode ? 0 : AppTheme.space10,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
            border: const Border(
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: isComparisonMode
              ? Row(
                  children: [
                    ...widget.comparisonPeriods.map((period) {
                      final deb = period.isCurrent ? widget.debit : (widget.debit == null ? null : 0.0);
                      final cred = period.isCurrent ? widget.credit : (widget.credit == null ? null : 0.0);
                      return Expanded(
                        flex: 4,
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space20,
                                  vertical: AppTheme.space10,
                                ),
                                alignment: Alignment.centerRight,
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: AppTheme.borderLight))
                                ),
                                child: _amountText(deb),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.space20,
                                  vertical: AppTheme.space10,
                                ),
                                alignment: Alignment.centerRight,
                                decoration: const BoxDecoration(
                                  border: Border(right: BorderSide(color: AppTheme.borderLight))
                                ),
                                child: _amountText(cred),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        widget.label,
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: widget.isSection
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(flex: 2, child: _amountText(widget.debit)),
                    Expanded(flex: 2, child: _amountText(widget.credit)),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _amountText(double? value) {
    if (value == null) {
      return const SizedBox.shrink();
    }
    return Text(
      _numberFormat.format(value),
      textAlign: TextAlign.right,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w500,
        decoration: _isHovered ? TextDecoration.underline : TextDecoration.none,
        decorationColor: AppTheme.primaryBlue,
      ),
    );
  }
}

class _AccountTypeSection {
  final String accountType;
  final String accountTypeLabel;
  final List<_AccountTypeRow> rows;

  const _AccountTypeSection({
    required this.accountType,
    required this.accountTypeLabel,
    required this.rows,
  });

  static List<_AccountTypeSection> fromResponse(Map<String, dynamic>? data) {
    final rawSections = List<Map<String, dynamic>>.from(
      data?['sections'] ?? const <Map<String, dynamic>>[],
    );
    return rawSections
        .map(
          (section) => _AccountTypeSection(
            accountType: section['accountType']?.toString() ?? '',
            accountTypeLabel:
                section['accountTypeLabel']?.toString() ?? 'Uncategorized',
            rows:
                List<Map<String, dynamic>>.from(
                      section['rows'] ?? const <Map<String, dynamic>>[],
                    )
                    .map(
                      (row) => _AccountTypeRow(
                        accountType: row['accountType']?.toString() ?? '',
                        accountTypeLabel:
                            row['accountTypeLabel']?.toString() ??
                            'Uncategorized',
                        debit: _numberValue(row['debit']),
                        credit: _numberValue(row['credit']),
                      ),
                    )
                    .toList(growable: false),
          ),
        )
        .toList(growable: false);
  }

  static double _numberValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _AccountTypeRow {
  final String accountType;
  final String accountTypeLabel;
  final double debit;
  final double credit;

  const _AccountTypeRow({
    required this.accountType,
    required this.accountTypeLabel,
    required this.debit,
    required this.credit,
  });
}
