import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_pagination_footer.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_tooltip.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';

const String _detailedGeneralLedgerTitle = 'Detailed General Ledger';

typedef DetailedGeneralLedgerParams = ({
  String startDate,
  String endDate,
  String basis,
  int page,
  int pageSize,
});

final detailedGeneralLedgerProvider = FutureProvider.family<
    Map<String, dynamic>, DetailedGeneralLedgerParams>((ref, params) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getDetailedGeneralLedger(
    params.startDate,
    params.endDate,
    basis: params.basis,
    page: params.page,
    pageSize: params.pageSize,
  );
});

class DetailedGeneralLedgerScreen extends ConsumerStatefulWidget {
  const DetailedGeneralLedgerScreen({super.key});

  @override
  ConsumerState<DetailedGeneralLedgerScreen> createState() =>
      _DetailedGeneralLedgerScreenState();
}

class _DetailedGeneralLedgerScreenState
    extends ConsumerState<DetailedGeneralLedgerScreen> {
  static const List<String> _reportBasisOptions = <String>['Accrual', 'Cash'];

  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
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

  String _formatTransactionType(String? rawType) {
    final value = (rawType ?? '').trim();
    if (value.isEmpty) return '--';
    return value
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
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
    final reportAsync = ref.watch(detailedGeneralLedgerProvider(queryParams));
    final reportData = reportAsync.valueOrNull;
    final sections = _DetailedGeneralLedgerSection.fromResponse(reportData);
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

    return ReportViewScaffold(
      categoryLabel: 'Accountant',
      reportTitle: _detailedGeneralLedgerTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _DetailedGeneralLedgerHeading(
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
      showReload: true,
      showRefresh: false,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: _detailedGeneralLedgerTitle,
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
      settingsTooltip: 'Customize the Detailed General Ledger report.',
      scheduleTooltip: 'Schedule the Detailed General Ledger report.',
      tableHeaderActions: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [ReportCustomizeColumnsButton(count: 9)],
      ),
      isLoading: reportAsync.isLoading,
      errorMessage: reportAsync.hasError
          ? 'Unable to load report: ${reportAsync.error}'
          : null,
      onRetry: () => ref.invalidate(detailedGeneralLedgerProvider(queryParams)),
      isEmpty: sections.isEmpty,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      currentNavigationCategory: 'Accountant',
      currentNavigationReport: _detailedGeneralLedgerTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _detailedGeneralLedgerTitle) return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: _DetailedGeneralLedgerTable(
        sections: sections,
        dateFormat: dateFormat,
        startDate: appliedStartDate,
        endDate: appliedEndDate,
        transactionTypeFormatter: _formatTransactionType,
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

class _DetailedGeneralLedgerHeading extends StatelessWidget {
  final String basis;
  final String dateLabel;

  const _DetailedGeneralLedgerHeading({
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
          _detailedGeneralLedgerTitle,
          textAlign: TextAlign.center,
          style: AppTheme.pageTitle,
        ),
        const SizedBox(height: AppTheme.space6),
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

class _DetailedGeneralLedgerTable extends StatelessWidget {
  final List<_DetailedGeneralLedgerSection> sections;
  final DateFormat dateFormat;
  final DateTime startDate;
  final DateTime endDate;
  final String Function(String?) transactionTypeFormatter;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const _DetailedGeneralLedgerTable({
    required this.sections,
    required this.dateFormat,
    required this.startDate,
    required this.endDate,
    required this.transactionTypeFormatter,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1530
            ? 1530.0
            : constraints.maxWidth;
        final tableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 520.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            height: tableHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(
                  child: sections.isEmpty
                      ? const _DetailedGeneralLedgerEmptyBody()
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final section in sections) ...[
                                _DetailedGeneralLedgerSectionHeader(
                                  label: section.accountName,
                                ),
                                _DetailedGeneralLedgerBalanceRow(
                                  dateLabel:
                                      'As On ${dateFormat.format(startDate)}',
                                  label: 'Opening Balance',
                                  balance: section.openingBalance,
                                  naturalSide: section.naturalSide,
                                ),
                                for (final transaction in section.transactions)
                                  _DetailedGeneralLedgerDataRow(
                                    transaction: transaction,
                                    dateFormat: dateFormat,
                                    transactionTypeFormatter:
                                        transactionTypeFormatter,
                                  ),
                                _DetailedGeneralLedgerBalanceRow(
                                  dateLabel:
                                      'As On ${dateFormat.format(endDate)}',
                                  label: 'Closing Balance',
                                  balance: section.closingBalance,
                                  naturalSide: section.naturalSide,
                                ),
                              ],
                              ReportPaginationFooter(
                                totalCount: totalCount,
                                page: page,
                                pageSize: pageSize,
                                onPageChanged: onPageChanged,
                              ),
                            ],
                          ),
                        ),
                ),
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
      child: _buildDetailedGeneralLedgerRow(
        leading: const SizedBox.shrink(),
        date: _headerText('DATE'),
        account: Row(
          children: [
            Text('ACCOUNT', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        details: _headerText('TRANSACTION DETAILS'),
        type: _headerText('TRANSACTION TYPE'),
        transactionNumber: _headerText('TRANSACTION#'),
        referenceNumber: _headerText('REFERENCE#'),
        debit: _headerText(
          'DEBIT',
          alignRight: true,
          helpMessage:
              'The positive difference between the debit and credit value in an account.',
        ),
        credit: _headerText(
          'CREDIT',
          alignRight: true,
          helpMessage:
              'The negative difference between the debit and credit value in an account.',
        ),
        amount: _headerText(
          'AMOUNT',
          alignRight: true,
          helpMessage: 'Total value of the account.',
        ),
      ),
    );
  }
}

class _DetailedGeneralLedgerSectionHeader extends StatelessWidget {
  final String label;

  const _DetailedGeneralLedgerSectionHeader({required this.label});

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
      child: _buildDetailedGeneralLedgerRow(
        leading: Text(
          label,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        date: const SizedBox.shrink(),
        account: const SizedBox.shrink(),
        details: const SizedBox.shrink(),
        type: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        referenceNumber: const SizedBox.shrink(),
        debit: const SizedBox.shrink(),
        credit: const SizedBox.shrink(),
        amount: const SizedBox.shrink(),
      ),
    );
  }
}

class _DetailedGeneralLedgerBalanceRow extends StatelessWidget {
  final String dateLabel;
  final String label;
  final double balance;
  final _AccountNaturalSide naturalSide;

  const _DetailedGeneralLedgerBalanceRow({
    required this.dateLabel,
    required this.label,
    required this.balance,
    required this.naturalSide,
  });

  @override
  Widget build(BuildContext context) {
    final absoluteBalance = balance.abs();
    final isDebit = naturalSide == _AccountNaturalSide.debit
        ? balance >= 0
        : balance < 0;
    final debitText = isDebit ? _numberFormat.format(absoluteBalance) : '';
    final creditText = isDebit ? '' : _numberFormat.format(absoluteBalance);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space20,
        vertical: AppTheme.space10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: _buildDetailedGeneralLedgerRow(
        leading: const SizedBox.shrink(),
        date: _bodyText(dateLabel),
        account: _bodyText(label),
        details: const SizedBox.shrink(),
        type: const SizedBox.shrink(),
        transactionNumber: const SizedBox.shrink(),
        referenceNumber: const SizedBox.shrink(),
        debit: _balanceText(debitText),
        credit: _balanceText(creditText),
        amount: const SizedBox.shrink(),
      ),
    );
  }

  Widget _balanceText(String text) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DetailedGeneralLedgerDataRow extends StatefulWidget {
  final _DetailedGeneralLedgerTransaction transaction;
  final DateFormat dateFormat;
  final String Function(String?) transactionTypeFormatter;

  const _DetailedGeneralLedgerDataRow({
    required this.transaction,
    required this.dateFormat,
    required this.transactionTypeFormatter,
  });

  @override
  State<_DetailedGeneralLedgerDataRow> createState() =>
      _DetailedGeneralLedgerDataRowState();
}

class _DetailedGeneralLedgerDataRowState
    extends State<_DetailedGeneralLedgerDataRow> {
  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final amountValue = transaction.debit > 0
        ? transaction.debit
        : transaction.credit > 0
            ? transaction.credit
            : 0;
    final amountSuffix = transaction.debit > 0
        ? 'Dr'
        : transaction.credit > 0
            ? 'Cr'
            : '';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space20,
            vertical: AppTheme.space10,
          ),
          decoration: BoxDecoration(
            color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
            border: const Border(
              bottom: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          child: _buildDetailedGeneralLedgerRow(
            leading: const SizedBox.shrink(),
            date: _bodyText(_formatDate(transaction.date)),
            account: _bodyText(transaction.accountName),
            details: _bodyText(transaction.details),
            type: _bodyText(
              widget.transactionTypeFormatter(transaction.transactionType),
            ),
            transactionNumber: _bodyText(transaction.transactionNumber),
            referenceNumber: _bodyText(transaction.reference),
            debit: _linkText(
              transaction.debit > 0
                  ? _numberFormat.format(transaction.debit)
                  : '',
            ),
            credit: _linkText(
              transaction.credit > 0
                  ? _numberFormat.format(transaction.credit)
                  : '',
            ),
            amount: _linkText(
              amountValue > 0
                  ? '${_numberFormat.format(amountValue)} $amountSuffix'
                  : '',
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String rawValue) {
    final parsed = DateTime.tryParse(rawValue);
    return parsed == null ? rawValue : widget.dateFormat.format(parsed);
  }

  Widget _linkText(String text) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.primaryBlue,
        fontWeight: FontWeight.w600,
        decoration: _isHovered ? TextDecoration.underline : null,
        decorationColor: AppTheme.primaryBlue,
      ),
    );
  }
}

class _DetailedGeneralLedgerEmptyBody extends StatelessWidget {
  const _DetailedGeneralLedgerEmptyBody();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Text(
        'No data to display',
        style: AppTheme.bodyText.copyWith(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

final NumberFormat _numberFormat = ReportFormatterCache.number('#,##0.00');

Widget _buildDetailedGeneralLedgerRow({
  required Widget leading,
  required Widget date,
  required Widget account,
  required Widget details,
  required Widget type,
  required Widget transactionNumber,
  required Widget referenceNumber,
  required Widget debit,
  required Widget credit,
  required Widget amount,
}) {
  return Row(
    children: [
      Expanded(flex: 3, child: leading),
      Expanded(flex: 3, child: date),
      Expanded(flex: 3, child: account),
      Expanded(flex: 3, child: details),
      Expanded(flex: 3, child: type),
      Expanded(flex: 3, child: transactionNumber),
      Expanded(flex: 3, child: referenceNumber),
      Expanded(flex: 3, child: debit),
      Expanded(flex: 3, child: credit),
      Expanded(flex: 3, child: amount),
    ],
  );
}

Widget _headerText(
  String text, {
  bool alignRight = false,
  String? helpMessage,
}) {
  return Row(
    mainAxisAlignment:
        alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
    children: [
      Flexible(
        child: Text(
          text,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: ReportTableTypography.header,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      if (helpMessage != null) ...[
        const SizedBox(width: AppTheme.space4),
        ReportTooltip(
          message: helpMessage,
          child: const SizedBox(
            width: AppTheme.space20,
            height: AppTheme.space20,
            child: Icon(
              Icons.help_outline,
              size: AppTheme.space14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    ],
  );
}

Widget _bodyText(String text) {
  return Text(
    text,
    style: AppTheme.bodyText.copyWith(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w500,
    ),
  );
}

enum _AccountNaturalSide { debit, credit }

class _DetailedGeneralLedgerSection {
  final String accountName;
  final String accountGroup;
  final String accountType;
  final double openingBalance;
  final double closingBalance;
  final List<_DetailedGeneralLedgerTransaction> transactions;

  const _DetailedGeneralLedgerSection({
    required this.accountName,
    required this.accountGroup,
    required this.accountType,
    required this.openingBalance,
    required this.closingBalance,
    required this.transactions,
  });

  _AccountNaturalSide get naturalSide {
    final group = accountGroup.toLowerCase();
    final type = accountType.toLowerCase();
    if (group.contains('liabil') ||
        group.contains('income') ||
        group.contains('equity') ||
        type.contains('payable') ||
        type.contains('income') ||
        type.contains('equity')) {
      return _AccountNaturalSide.credit;
    }
    return _AccountNaturalSide.debit;
  }

  static List<_DetailedGeneralLedgerSection> fromResponse(
    Map<String, dynamic>? data,
  ) {
    final rawSections = List<Map<String, dynamic>>.from(
      data?['sections'] ?? const <Map<String, dynamic>>[],
    );
    return rawSections
        .map(
          (section) => _DetailedGeneralLedgerSection(
            accountName: _textValue(section['accountName']),
            accountGroup: _textValue(section['accountGroup']),
            accountType: _textValue(section['accountType']),
            openingBalance: _numberValue(section['openingBalance']),
            closingBalance: _numberValue(section['closingBalance']),
            transactions: List<Map<String, dynamic>>.from(
              section['transactions'] ?? const <Map<String, dynamic>>[],
            ).map(_DetailedGeneralLedgerTransaction.fromJson).toList(
                  growable: false,
                ),
          ),
        )
        .toList(growable: false);
  }

  static String _textValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? 'Uncategorized' : text;
  }

  static double _numberValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _DetailedGeneralLedgerTransaction {
  final String date;
  final String accountName;
  final String details;
  final String transactionType;
  final String transactionNumber;
  final String reference;
  final double debit;
  final double credit;

  const _DetailedGeneralLedgerTransaction({
    required this.date,
    required this.accountName,
    required this.details,
    required this.transactionType,
    required this.transactionNumber,
    required this.reference,
    required this.debit,
    required this.credit,
  });

  factory _DetailedGeneralLedgerTransaction.fromJson(
    Map<String, dynamic> json,
  ) {
    return _DetailedGeneralLedgerTransaction(
      date: _textValue(json['date']),
      accountName: _textValue(json['accountName']),
      details: _textValue(json['details']),
      transactionType: _textValue(json['type']),
      transactionNumber: _textValue(json['transactionNumber']),
      reference: _textValue(json['reference']),
      debit: _numberValue(json['debit']),
      credit: _numberValue(json['credit']),
    );
  }

  static String _textValue(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? '--' : text;
  }

  static double _numberValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
