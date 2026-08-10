import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';

const String _journalReportTitle = 'Journal Report';

typedef JournalReportParams = ({
  String startDate,
  String endDate,
  String basis,
  int page,
  int pageSize,
});

final journalReportProvider =
    FutureProvider.family<Map<String, dynamic>, JournalReportParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return repo.getJournalReport(
        params.startDate,
        params.endDate,
        basis: params.basis,
        page: params.page,
        pageSize: params.pageSize,
      );
    });

class JournalReportScreen extends ConsumerStatefulWidget {
  const JournalReportScreen({super.key});

  @override
  ConsumerState<JournalReportScreen> createState() => _JournalReportScreenState();
}

class _JournalReportScreenState extends ConsumerState<JournalReportScreen> {
  static const List<String> _reportBasisOptions = <String>['Accrual', 'Cash'];

  bool _isInitialized = false;
  bool _hasPendingFilterChanges = false;
  bool _showAssociatedTags = false;
  int _page = 1;
  int _pageSize = 25;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;
  String _reportBasis = 'Accrual';
  String _appliedReportBasis = 'Accrual';

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
      _page = 1;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleReportBasisChanged(String value) {
    if (_reportBasis == value) return;
    setState(() {
      _reportBasis = value;
      _page = 1;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleAssociatedTagsChanged(bool? value) {
    setState(() {
      _showAssociatedTags = value ?? false;
      _page = 1;
      _hasPendingFilterChanges = true;
    });
  }

  void _runReport() {
    setState(() {
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
      _appliedReportBasis = _reportBasis;
      _page = 1;
      _hasPendingFilterChanges = false;
    });
  }

  void _handlePageChanged(int page) {
    if (_page == page) return;
    setState(() => _page = page);
  }

  int _intValue(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
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
      page: _page,
      pageSize: _pageSize,
    );
    final reportAsync = ref.watch(journalReportProvider(queryParams));
    final reportData = reportAsync.valueOrNull;
    final sections = _JournalSection.fromResponse(reportData);
    final pagination = Map<String, dynamic>.from(
      reportData?['pagination'] as Map? ?? const <String, dynamic>{},
    );
    final totalCount = _intValue(
      pagination['totalRecords'] ?? pagination['total'] ?? reportData?['total'],
      sections.length,
    );
    final currentPage = _intValue(
      pagination['page'] ?? reportData?['page'],
      _page,
    );
    final effectivePageSize = _intValue(
      pagination['pageSize'] ?? reportData?['pageSize'],
      _pageSize,
    );
    final currencyCode = ref.watch(defaultCurrencyProvider).valueOrNull?.code ?? 'INR';

    return ReportViewScaffold(
      categoryLabel: 'Accountant',
      reportTitle: _journalReportTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _JournalReportHeading(
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
        _AssociatedTagsFilter(
          value: _showAssociatedTags,
          onChanged: _handleAssociatedTagsChanged,
        ),
      ],
      onRunReport: _runReport,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showRefresh: false,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: _journalReportTitle,
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
      settingsTooltip: 'Customize the Journal Report.',
      scheduleTooltip: 'Schedule the Journal Report.',
      isLoading: reportAsync.isLoading,
      errorMessage: reportAsync.hasError
          ? 'Unable to load report: ${reportAsync.error}'
          : null,
      onRetry: () => ref.invalidate(journalReportProvider(queryParams)),
      isEmpty: sections.isEmpty,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      currentNavigationCategory: 'Accountant',
      currentNavigationReport: _journalReportTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _journalReportTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _JournalReportTable(
        sections: sections,
        dateFormat: dateFormat,
        currencyCode: currencyCode,
        totalCount: totalCount,
        page: currentPage,
        pageSize: effectivePageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}

class _AssociatedTagsFilter extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _AssociatedTagsFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.space36,
      padding: const EdgeInsets.only(
        left: AppTheme.space8,
        right: AppTheme.space14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.space6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: AppTheme.space20,
            height: AppTheme.space20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: AppTheme.borderColor),
            ),
          ),
          const SizedBox(width: AppTheme.space8),
          Text(
            'Show Associated tags',
            style: AppTheme.bodyText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalReportHeading extends StatelessWidget {
  final String basis;
  final String dateLabel;

  const _JournalReportHeading({required this.basis, required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _journalReportTitle,
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
        const SizedBox(height: AppTheme.space16),
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

class _JournalReportTable extends StatelessWidget {
  final List<_JournalSection> sections;
  final DateFormat dateFormat;
  final String currencyCode;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _JournalReportTable({
    required this.sections,
    required this.dateFormat,
    required this.currencyCode,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1180 ? 1180.0 : constraints.maxWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (sections.isEmpty)
                  const _JournalReportEmptyBody()
                else
                  for (final section in sections) _JournalSectionBlock(
                    section: section,
                    dateFormat: dateFormat,
                  ),
                _BaseCurrencyNote(currencyCode: currencyCode),
                ReportPaginationFooter(
                  totalCount: totalCount,
                  page: page,
                  pageSize: pageSize,
                  onPageChanged: onPageChanged,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _JournalSectionBlock extends StatelessWidget {
  final _JournalSection section;
  final DateFormat dateFormat;

  const _JournalSectionBlock({required this.section, required this.dateFormat});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _JournalGroupHeader(title: section.title(dateFormat)),
        for (final line in section.lines) _JournalLineRow(line: line),
        _JournalTotalRow(debit: section.totalDebit, credit: section.totalCredit),
        const SizedBox(height: AppTheme.space14),
      ],
    );
  }
}

class _JournalGroupHeader extends StatelessWidget {
  final String title;

  const _JournalGroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
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
      child: _buildJournalRow(
        left: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: ReportTableTypography.header.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        debit: Text('DEBIT', style: ReportTableTypography.header),
        credit: Text('CREDIT', style: ReportTableTypography.header),
      ),
    );
  }
}

class _JournalLineRow extends StatelessWidget {
  final _JournalLine line;

  const _JournalLineRow({required this.line});

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
      child: _buildJournalRow(
        left: Text(
          line.accountName,
          overflow: TextOverflow.ellipsis,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        debit: Text(_formatAmount(line.debit), style: _amountStyle(AppTheme.textPrimary)),
        credit: Text(_formatAmount(line.credit), style: _amountStyle(AppTheme.textPrimary)),
      ),
    );
  }
}

class _JournalTotalRow extends StatelessWidget {
  final double debit;
  final double credit;

  const _JournalTotalRow({required this.debit, required this.credit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space12,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildJournalRow(
        left: const SizedBox.shrink(),
        debit: Text(_formatAmount(debit), style: _amountStyle(AppTheme.primaryBlue)),
        credit: Text(_formatAmount(credit), style: _amountStyle(AppTheme.primaryBlue)),
      ),
    );
  }
}

class _BaseCurrencyNote extends StatelessWidget {
  final String currencyCode;

  const _BaseCurrencyNote({required this.currencyCode});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space2,
        AppTheme.space20,
        AppTheme.space16,
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space4,
              vertical: AppTheme.space2,
            ),
            color: Colors.green.shade700,
            child: Text(
              currencyCode,
              style: AppTheme.captionText.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JournalReportEmptyBody extends StatelessWidget {
  const _JournalReportEmptyBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Text(
        'No data to display',
        style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }
}

Widget _buildJournalRow({
  required Widget left,
  required Widget debit,
  required Widget credit,
}) {
  return Row(
    children: [
      Expanded(flex: 7, child: left),
      Container(width: 1, height: AppTheme.space24, color: AppTheme.borderLight),
      SizedBox(
        width: 220,
        child: Align(alignment: Alignment.centerRight, child: debit),
      ),
      SizedBox(
        width: 220,
        child: Align(alignment: Alignment.centerRight, child: credit),
      ),
    ],
  );
}

TextStyle _amountStyle(Color color) {
  return AppTheme.bodyText.copyWith(color: color, fontWeight: FontWeight.w500);
}

String _formatAmount(double value) {
  return ReportFormatterCache.number('#,##0.00').format(value);
}

String _formatSourceType(String rawType) {
  final normalized = rawType.trim().replaceAll(RegExp(r'[_-]+'), ' ');
  if (normalized.isEmpty) return 'JOURNAL';
  return normalized.toUpperCase();
}

class _JournalSection {
  final DateTime? date;
  final String sourceType;
  final String transactionNumber;
  final String description;
  final double totalDebit;
  final double totalCredit;
  final List<_JournalLine> lines;

  const _JournalSection({
    required this.date,
    required this.sourceType,
    required this.transactionNumber,
    required this.description,
    required this.totalDebit,
    required this.totalCredit,
    required this.lines,
  });

  String title(DateFormat dateFormat) {
    final formattedDate = date == null ? '--' : dateFormat.format(date!);
    final sourceLabel = _formatSourceType(sourceType);
    final number = transactionNumber.trim();
    return number.isEmpty
        ? '$formattedDate - $sourceLabel'
        : '$formattedDate - $sourceLabel $number';
  }

  static List<_JournalSection> fromResponse(Map<String, dynamic>? response) {
    final rawSections = response?['sections'];
    if (rawSections is! List) return const <_JournalSection>[];
    return rawSections
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw))
        .map((raw) {
          final lines = raw['lines'] is List
              ? (raw['lines'] as List)
                  .whereType<Map>()
                  .map((line) => _JournalLine.fromJson(Map<String, dynamic>.from(line)))
                  .toList(growable: false)
              : const <_JournalLine>[];
          return _JournalSection(
            date: DateTime.tryParse(raw['date']?.toString() ?? ''),
            sourceType: raw['sourceType']?.toString() ?? 'Journal',
            transactionNumber: raw['transactionNumber']?.toString() ?? '',
            description: raw['description']?.toString() ?? '',
            totalDebit: _doubleValue(raw['totalDebit']),
            totalCredit: _doubleValue(raw['totalCredit']),
            lines: lines,
          );
        })
        .toList(growable: false);
  }
}

class _JournalLine {
  final String accountName;
  final double debit;
  final double credit;

  const _JournalLine({
    required this.accountName,
    required this.debit,
    required this.credit,
  });

  factory _JournalLine.fromJson(Map<String, dynamic> json) {
    return _JournalLine(
      accountName: json['accountName']?.toString() ?? '--',
      debit: _doubleValue(json['debit']),
      credit: _doubleValue(json['credit']),
    );
  }
}

double _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
