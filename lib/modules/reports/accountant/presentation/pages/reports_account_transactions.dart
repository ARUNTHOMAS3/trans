import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
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
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_group_by_section.dart';

typedef AccountTransactionsParams = ({
  String accountId,
  String startDate,
  String endDate,
  String basis,
  String? contactId,
  String? contactType,
  String? accountType,
  int page,
  int pageSize,
});

final accountTransactionsProvider =
    FutureProvider.family<Map<String, dynamic>, AccountTransactionsParams>((
      ref,
      params,
    ) async {
      final repo = ref.watch(reportsRepositoryProvider);
      return repo.getAccountTransactions(
        params.accountId,
        params.startDate,
        params.endDate,
        contactId: params.contactId,
        contactType: params.contactType,
        basis: params.basis,
        accountType: params.accountType,
        page: params.page,
        pageSize: params.pageSize,
      );
    });

class AccountTransactionsReportPage extends ConsumerStatefulWidget {
  final String? accountId;
  final String? accountName;

  const AccountTransactionsReportPage({
    super.key,
    this.accountId,
    this.accountName,
  });

  @override
  ConsumerState<AccountTransactionsReportPage> createState() =>
      _AccountTransactionsReportPageState();
}

class _AccountTransactionsReportPageState
    extends ConsumerState<AccountTransactionsReportPage> {
  static const String _reportTitle = 'Account Transactions';
  static const List<String> _reportBasisOptions = <String>['Accrual', 'Cash'];

  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  int _page = 1;
  final int _pageSize = 25;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;
  String _reportBasis = 'Accrual';
  String _appliedReportBasis = 'Accrual';
  String _groupBy = 'None';

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

  void _handleGroupByChanged(String value) {
    if (_groupBy == value) return;
    setState(() {
      _groupBy = value;
    });
  }

  int _intValue(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _formatTransactionType(String? rawType) {
    final value = (rawType ?? '').trim();
    if (value.isEmpty) return '--';
    final normalized = value.replaceAll(RegExp(r'[_-]+'), ' ');
    return normalized
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
    final accountType = routerState.uri.queryParameters['accountType'];
    final accountTypeLabel = routerState.uri.queryParameters['accountTypeLabel']
        ?.trim();
    final effectiveReportTitle =
        accountType != null && accountType.trim().isNotEmpty
        ? 'Account Type Details - ${accountTypeLabel == null || accountTypeLabel.isEmpty ? accountType : accountTypeLabel}'
        : _reportTitle;

    final queryParams = (
      accountId: widget.accountId ?? '',
      startDate: ReportUtils.formatApiDate(appliedStartDate),
      endDate: ReportUtils.formatApiDate(appliedEndDate),
      basis: _appliedReportBasis,
      contactId: routerState.uri.queryParameters['contactId'],
      contactType: routerState.uri.queryParameters['contactType'],
      accountType: accountType,
      page: _page,
      pageSize: _pageSize,
    );

    final reportAsync = ref.watch(accountTransactionsProvider(queryParams));
    final reportData = reportAsync.valueOrNull;
    final pagination = Map<String, dynamic>.from(
      reportData?['pagination'] as Map? ?? const <String, dynamic>{},
    );
    final transactions = List<Map<String, dynamic>>.from(
      reportData?['transactions'] ?? const <Map<String, dynamic>>[],
    );
    final totalCount = _intValue(
      pagination['totalRecords'] ?? pagination['total'] ?? reportData?['total'],
      transactions.length,
    );
    final currentPage = _intValue(
      pagination['page'] ?? reportData?['page'],
      _page,
    );
    final effectivePageSize = _intValue(
      pagination['pageSize'] ?? reportData?['pageSize'],
      _pageSize,
    );
    final totalPages = _intValue(
      pagination['totalPages'] ?? reportData?['totalPages'],
      1,
    );

    final openingBalance = double.tryParse(reportData?['openingBalance']?.toString() ?? '') ?? 0.0;
    final periodDebits = double.tryParse(reportData?['periodDebits']?.toString() ?? '') ?? 0.0;
    final periodCredits = double.tryParse(reportData?['periodCredits']?.toString() ?? '') ?? 0.0;
    final closingBalance = double.tryParse(reportData?['closingBalance']?.toString() ?? '') ?? 0.0;

    if (widget.accountId != null && widget.accountId!.isNotEmpty) {
      if (currentPage == 1 && (transactions.isNotEmpty || openingBalance != 0)) {
        transactions.insert(0, {
          'date': 'As On ${dateFormat.format(appliedStartDate)}',
          'accountName': 'Opening Balance',
          'debit': openingBalance > 0 ? openingBalance : 0.0,
          'credit': openingBalance < 0 ? openingBalance.abs() : 0.0,
          'runningBalance': openingBalance,
          'details': '',
          'type': '',
          'transactionNumber': '',
          'reference': '',
          'isOpeningBalance': true,
        });
      }

      if (currentPage == totalPages && (transactions.isNotEmpty || closingBalance != 0)) {
        transactions.add({
          'date': '',
          'accountName': 'Total Debits and Credits (${dateFormat.format(appliedStartDate)} - ${dateFormat.format(appliedEndDate)})',
          'debit': periodDebits,
          'credit': periodCredits,
          'runningBalance': 0.0,
          'details': '',
          'type': '',
          'transactionNumber': '',
          'reference': '',
          'isSummaryRow': true,
        });
        transactions.add({
          'date': 'As On ${dateFormat.format(appliedEndDate)}',
          'accountName': 'Closing Balance',
          'debit': closingBalance > 0 ? closingBalance : 0.0,
          'credit': closingBalance < 0 ? closingBalance.abs() : 0.0,
          'runningBalance': 0.0,
          'details': '',
          'type': '',
          'transactionNumber': '',
          'reference': '',
          'isSummaryRow': true,
        });
      }
    }
    final errorMessage = reportAsync.hasError
        ? 'Unable to load report: ${reportAsync.error}'
        : null;
    return ReportViewScaffold(
      categoryLabel: 'Accountant',
      reportTitle: effectiveReportTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _AccountTransactionsHeading(
        title: effectiveReportTitle,
        basis: _appliedReportBasis,
        dateLabel: dateLabel,
        accountName: widget.accountName,
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
        reportName: _reportTitle,
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
      settingsTooltip: 'Customize the Account Transactions report.',
      scheduleTooltip: 'Schedule the Account Transactions report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReportGroupBySection(
            selectedValue: _groupBy,
            options: const <String>[
              'None',
              'Date',
              'Account',
              'Transaction Type',
              'Contact',
              'Transaction',
              'Location',
              'Account Type',
              'Account Group',
              'Account Code',
            ],
            onChanged: _handleGroupByChanged,
            showClearAction: true,
          ),
          const SizedBox(width: AppTheme.space12),
          Container(
            width: 1,
            height: 16,
            color: AppTheme.borderColor,
          ),
          const SizedBox(width: AppTheme.space12),
          const ReportCustomizeColumnsButton(count: 9),
        ],
      ),
      isLoading: reportAsync.isLoading,
      errorMessage: errorMessage,
      onRetry: () => ref.invalidate(accountTransactionsProvider(queryParams)),
      isEmpty: transactions.isEmpty,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      currentNavigationCategory: 'Accountant',
      currentNavigationReport: effectiveReportTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _reportTitle) return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: AccountTransactionsTable(
        transactions: transactions,
        accountName: widget.accountName,
        dateFormat: dateFormat,
        transactionTypeFormatter: _formatTransactionType,
        totalCount: totalCount,
        page: currentPage,
        pageSize: effectivePageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}

class _AccountTransactionsHeading extends StatelessWidget {
  final String title;
  final String basis;
  final String dateLabel;
  final String? accountName;

  const _AccountTransactionsHeading({
    required this.title,
    required this.basis,
    required this.dateLabel,
    this.accountName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(title, textAlign: TextAlign.center, style: AppTheme.pageTitle),
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
        if (accountName != null && accountName!.isNotEmpty) ...[
          const SizedBox(height: AppTheme.space10),
          Text(
            accountName!,
            textAlign: TextAlign.center,
            style: AppTheme.pageTitle.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
          ),
        ],
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

class AccountTransactionsTable extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final String? accountName;
  final DateFormat dateFormat;
  final String Function(String?) transactionTypeFormatter;
  final int totalCount;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;
  const AccountTransactionsTable({
    super.key,
    required this.transactions,
    required this.accountName,
    required this.dateFormat,
    required this.transactionTypeFormatter,
    required this.totalCount,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  @override
  State<AccountTransactionsTable> createState() => _AccountTransactionsTableState();
}

class _AccountTransactionsTableState extends State<AccountTransactionsTable> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth < 1380
            ? 1380.0
            : constraints.maxWidth;

        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  Expanded(
                    child: widget.transactions.isEmpty
                        ? const _AccountTransactionsEmptyBody()
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: widget.transactions
                                  .map(
                                    (item) => _AccountTransactionsDataRow(
                                      item: item,
                                      accountName: widget.accountName,
                                      dateFormat: widget.dateFormat,
                                      transactionTypeFormatter:
                                          widget.transactionTypeFormatter,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                  ),
                  ReportPaginationFooter(
                    totalCount: widget.totalCount,
                    page: widget.page,
                    pageSize: widget.pageSize,
                    onPageChanged: widget.onPageChanged,
                  ),
              ],
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
          top: BorderSide(color: AppTheme.borderColor),
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: _buildTableRow(
        date: Row(
          children: [
            Text('DATE', style: ReportTableTypography.header),
            const SizedBox(width: AppTheme.space4),
            const Icon(
              Icons.unfold_more,
              size: AppTheme.space14,
              color: AppTheme.primaryBlue,
            ),
          ],
        ),
        account: _headerText('ACCOUNT'),
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

class _AccountTransactionsDataRow extends StatefulWidget {
  final Map<String, dynamic> item;
  final String? accountName;
  final DateFormat dateFormat;
  final String Function(String?) transactionTypeFormatter;

  const _AccountTransactionsDataRow({
    required this.item,
    required this.accountName,
    required this.dateFormat,
    required this.transactionTypeFormatter,
  });

  @override
  State<_AccountTransactionsDataRow> createState() =>
      _AccountTransactionsDataRowState();
}

class _AccountTransactionsDataRowState
    extends State<_AccountTransactionsDataRow> {
  static final NumberFormat _numberFormat = ReportFormatterCache.number('#,##0.00');

  bool _isHovered = false;

  void _setHovered(bool value) {
    if (!mounted || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final debit = _numberValue(item, 'debit');
    final credit = _numberValue(item, 'credit');
    final runningBalance = _numberValue(item, 'runningBalance');
    final amountValue = runningBalance.abs();
    final amountSuffix = runningBalance >= 0 ? 'Dr' : 'Cr';
    final isSummaryRow = item['isSummaryRow'] == true;
    final isOpeningBalance = item['isOpeningBalance'] == true;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space20,
          vertical: AppTheme.space10,
        ),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.bgHover : AppTheme.backgroundColor,
          border: const Border(bottom: BorderSide(color: AppTheme.borderLight)),
        ),
        child: _buildTableRow(
          date: _bodyText(_formatDate(_textValue(item, 'date'))),
          account: _bodyText(
            _firstTextValue(item, const [
                  'accountName',
                  'account_name',
                  'account',
                ]) ??
                widget.accountName ??
                '--',
          ),
          details: _bodyText(_textValue(item, 'details')),
          type: _bodyText(
            widget.transactionTypeFormatter(
              _firstTextValue(item, const [
                'type',
                'transactionType',
                'transaction_type',
              ]),
            ),
          ),
          transactionNumber: _bodyText(
            _firstTextValue(item, const [
                  'transactionNumber',
                  'transaction_number',
                  'sourceNumber',
                ]) ??
                '',
          ),
          referenceNumber: _bodyText(
            _firstTextValue(item, const [
                  'reference',
                  'referenceNumber',
                  'reference_number',
                ]) ??
                '',
          ),
          debit: (isSummaryRow || isOpeningBalance) ? _bodyText(debit > 0 ? _numberFormat.format(debit) : '', align: TextAlign.right) : _linkText(debit > 0 ? _numberFormat.format(debit) : ''),
          credit: (isSummaryRow || isOpeningBalance) ? _bodyText(credit > 0 ? _numberFormat.format(credit) : '', align: TextAlign.right) : _linkText(credit > 0 ? _numberFormat.format(credit) : ''),
          amount: (isSummaryRow || isOpeningBalance) ? _bodyText(amountValue > 0 ? '${_numberFormat.format(amountValue)} $amountSuffix' : '', align: TextAlign.right) : _linkText('${_numberFormat.format(amountValue)} $amountSuffix'),
        ),
      ),
    );
  }

  String _formatDate(String rawValue) {
    if (rawValue.isEmpty || rawValue == '--') return rawValue;
    final parsed = DateTime.tryParse(rawValue);
    return parsed == null ? rawValue : widget.dateFormat.format(parsed);
  }

  static double _numberValue(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _textValue(Map<String, dynamic> item, String key) {
    final value = item[key]?.toString().trim() ?? '';
    return value.isEmpty ? '--' : value;
  }

  static String? _firstTextValue(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  Widget _bodyText(String text, {TextAlign align = TextAlign.left}) {
    return Text(
      text,
      textAlign: align,
      style: AppTheme.bodyText.copyWith(
        color: AppTheme.textPrimary,
        fontWeight: FontWeight.w500,
      ),
    );
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

class _AccountTransactionsEmptyBody extends StatelessWidget {
  const _AccountTransactionsEmptyBody();

  @override
  Widget build(BuildContext context) {
    return Center(
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

Widget _buildTableRow({
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
      Expanded(flex: 2, child: date),
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
  final content = Row(
    mainAxisAlignment: alignRight
        ? MainAxisAlignment.end
        : MainAxisAlignment.start,
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

  return content;
}
