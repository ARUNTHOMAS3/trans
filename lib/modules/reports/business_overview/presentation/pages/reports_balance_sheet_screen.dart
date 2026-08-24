import 'package:zerpai_erp/modules/reports/presentation/widgets/report_table_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_compare_section.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/reports/business_overview/data/providers/balance_sheet_provider.dart';

class BalanceSheetScreen extends ConsumerStatefulWidget {
  const BalanceSheetScreen({super.key});

  @override
  ConsumerState<BalanceSheetScreen> createState() => _BalanceSheetScreenState();
}

class _BalanceSheetScreenState extends ConsumerState<BalanceSheetScreen> {
  static final DateTime _defaultDate = DateTime.now(); // Mock anchor date
  static const List<String> _reportBasisOptions = <String>['Accrual', 'Cash'];
  static final _displayDateFormat = ReportFormatterCache.date('dd-MM-yyyy');

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _collapseSubAccounts = false;
  
  String _asOfOption = 'Today';
  DateTime _asOfDate = _defaultDate;
  DateTime _appliedAsOfDate = _defaultDate;
  String _reportBasis = 'Accrual';
  String _appliedReportBasis = 'Accrual';
  
  final GlobalKey _dateFilterKey = GlobalKey();

  String get _dateLabel => 'As of ${_displayDateFormat.format(_appliedAsOfDate)}';

  ReportCompareSelection _compareSelection = const ReportCompareSelection.none();
  ReportCompareSelection _appliedCompareSelection = const ReportCompareSelection.none();

  void _markFiltersDirty() {
    setState(() => _hasPendingFilterChanges = true);
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _toggleCollapseSubAccounts() {
    setState(() {
      _collapseSubAccounts = !_collapseSubAccounts;
    });
  }

  void _handleAsOfOptionChanged(String option) async {
    if (option == 'Custom') {
      final picked = await ZerpaiDatePicker.show(
        context,
        initialDate: _asOfDate,
        targetKey: _dateFilterKey,
      );
      if (picked != null) {
        setState(() {
          _asOfOption = 'Custom';
          _asOfDate = picked;
          _hasPendingFilterChanges = true;
        });
      }
    } else {
      final range = ReportDateRangePresets.resolveRange(option, anchor: _defaultDate);
      setState(() {
        _asOfOption = option;
        _asOfDate = range.endDate;
        _hasPendingFilterChanges = true;
      });
    }
  }

  void _handleReportBasisChanged(String value) {
    if (_reportBasis == value) return;
    setState(() {
      _reportBasis = value;
      _hasPendingFilterChanges = true;
    });
  }

  void _handleCompareSelectionApplied(ReportCompareSelection selection) {
    setState(() {
      _compareSelection = selection;
      _appliedCompareSelection = selection;
    });
  }

  List<String> _buildComparisonPeriods() {
    if (!_appliedCompareSelection.isActive) {
      return const <String>[];
    }
    final periods = <String>[];
    final count = _appliedCompareSelection.count;
    final type = _appliedCompareSelection.compareType;

    for (int i = count; i >= 1; i--) {
      if (type == 'Previous Year(s)') {
        final dt = DateTime(
          _appliedAsOfDate.year - i,
          _appliedAsOfDate.month,
          _appliedAsOfDate.day,
        );
        periods.add(_displayDateFormat.format(dt));
      } else if (type == 'Previous Period(s)') {
        periods.add('Period - $i');
      } else {
        periods.add('Compare $i');
      }
    }
    periods.add(_displayDateFormat.format(_appliedAsOfDate));
    return periods;
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _appliedAsOfDate = _asOfDate;
      _appliedReportBasis = _reportBasis;
      _appliedCompareSelection = _compareSelection;
      _hasPendingFilterChanges = false;
    });
    ref.invalidate(balanceSheetProvider);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: 'Balance Sheet',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportSearchableFilterDropdown(
          key: _dateFilterKey,
          label: 'As of',
          value: _asOfOption == 'Custom' ? _displayDateFormat.format(_asOfDate) : _asOfOption,
          options: ReportDateRangePresets.options,
          menuMaxHeight: 350,
          onChanged: _handleAsOfOptionChanged,
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
      showSchedule: false,
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
      settingsTooltip: 'Customize the Balance Sheet report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CollapseSubAccountsAction(
            value: _collapseSubAccounts,
            onChanged: _toggleCollapseSubAccounts,
          ),
          const SizedBox(width: AppTheme.space10),
          ReportCompareSection(
            selectedValue: _compareSelection.displayValue,
            onSelectionApplied: _handleCompareSelectionApplied,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 2),
          const SizedBox(width: AppTheme.space10),
          ReportIconActionButton(
            icon: Icons.settings_outlined,
            onPressed: () {},
            tooltip: 'Customize report settings',
            chromeless: true,
          ),
        ],
      ),
      isLoading: false,
      currentNavigationCategory: 'Business Overview',
      currentNavigationReport: 'Balance Sheet',
      onReportSelected: (reportName, category) {
        if (reportName == 'Balance Sheet') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: _BalanceSheetBody(
        appliedAsOfDate: _appliedAsOfDate,
        reportBasis: _appliedReportBasis,
        comparisonPeriods: _buildComparisonPeriods(),
        collapseSubAccounts: _collapseSubAccounts,
      ),
    );
  }
}

class _CollapseSubAccountsAction extends StatelessWidget {
  final bool value;
  final VoidCallback onChanged;

  const _CollapseSubAccountsAction({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(AppTheme.space4),
      hoverColor: AppTheme.bgHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.space4,
          vertical: AppTheme.space6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: value,
              onChanged: (_) => onChanged(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: AppTheme.space4),
            Text(
              'Collapse Sub-Accounts',
              style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceSheetRowData {
  final String account;
  final String? accountId;
  final String total;
  final int indentLevel;
  final bool isSection;
  final bool isTotal;
  final bool isLink;
  

  final bool showCollapseIcon = false;

  const _BalanceSheetRowData({
    required this.account,
    this.accountId,
    required this.total,
    this.indentLevel = 0,
    this.isSection = false,
    this.isTotal = false,
    this.isLink = false,
    });
}

class _BalanceSheetBody extends ConsumerWidget {
  final DateTime appliedAsOfDate;
  final String reportBasis;
  final List<String> comparisonPeriods;
  final bool collapseSubAccounts;

  const _BalanceSheetBody({
    required this.appliedAsOfDate,
    required this.reportBasis,
    required this.comparisonPeriods,
    required this.collapseSubAccounts,
  });

  

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = BalanceSheetRequest(
      startDate: DateTime(2026, 4, 1),
      endDate: appliedAsOfDate,
      basis: reportBasis,
    );

    final asyncData = ref.watch(balanceSheetProvider(request));

    return asyncData.when(
      loading: () => const Padding(padding: EdgeInsets.all(AppTheme.space16), child: SingleChildScrollView(physics: NeverScrollableScrollPhysics(), child: ZTableSkeleton(rows: 5, columns: 3))),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (data) {
        final List<_BalanceSheetRowData> dynamicRows = [];

        void processAccounts(List<dynamic> accounts, int indentLevel) {
          for (final acc in accounts) {
            final accMap = acc as Map<String, dynamic>;
            dynamicRows.add(_BalanceSheetRowData(
              account: accMap['accountName'] as String? ?? '',
              accountId: accMap['accountId'] as String?,
              total: (double.tryParse(accMap['totalAmount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
              indentLevel: indentLevel,
              isLink: true,
            ));
            final children = accMap['children'] as List<dynamic>? ?? [];
            if (children.isNotEmpty && !collapseSubAccounts) {
              processAccounts(children, indentLevel + 1);
              dynamicRows.add(_BalanceSheetRowData(
                account: 'Total for ${accMap['accountName']}',
                total: (double.tryParse(accMap['totalAmount']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                indentLevel: indentLevel,
                isTotal: true,
              ));
            }
          }
        }

        void processSubCategories(Map<String, dynamic> subCategories, int indentLevel) {
          final sortedKeys = subCategories.keys.toList()..sort();
          for (final subCat in sortedKeys) {
            final subCatData = subCategories[subCat] as Map<String, dynamic>;
            final accountGroups = subCatData['accountGroups'] as Map<String, dynamic>? ?? {};
            if (accountGroups.isEmpty) continue;

            dynamicRows.add(_BalanceSheetRowData(account: subCat, total: '', indentLevel: indentLevel, isSection: true));
            
            final sortedGroups = accountGroups.keys.toList()..sort();
            for (final group in sortedGroups) {
              final groupData = accountGroups[group] as Map<String, dynamic>;
              final accountTypes = groupData['accountTypes'] as Map<String, dynamic>? ?? {};
              if (accountTypes.isEmpty) continue;

              dynamicRows.add(_BalanceSheetRowData(account: group, total: '', indentLevel: indentLevel + 1, isSection: true));

              final sortedTypes = accountTypes.keys.toList()..sort();
              for (final type in sortedTypes) {
                final typeData = accountTypes[type] as Map<String, dynamic>;
                final accounts = typeData['accounts'] as List<dynamic>? ?? [];
                
                // Usually Zoho doesn't show Account Type explicitly unless needed, but let's show it if it's different
                if (type != group) {
                  // We skip showing the account type as a header to match Zoho layout closely, 
                  // or show it if needed. Zoho groups by type internally. We will just render accounts under the group.
                }

                processAccounts(accounts, indentLevel + 2);
              }
              
              dynamicRows.add(_BalanceSheetRowData(
                account: 'Total for $group',
                total: (double.tryParse(groupData['total']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
                indentLevel: indentLevel + 1,
                isTotal: true,
              ));
            }

            dynamicRows.add(_BalanceSheetRowData(
              account: 'Total for $subCat',
              total: (double.tryParse(subCatData['total']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
              indentLevel: indentLevel,
              isTotal: true,
            ));
          }
        }

        final assetsData = data['assets'] as Map<String, dynamic>? ?? {};
        if (assetsData.isNotEmpty) {
          dynamicRows.add(const _BalanceSheetRowData(account: 'Assets', total: '', isSection: true));
          processSubCategories(assetsData['subCategories'] as Map<String, dynamic>? ?? {}, 1);
          dynamicRows.add(_BalanceSheetRowData(
            account: 'Total for Assets',
            total: (double.tryParse(assetsData['total']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
            isTotal: true,
          ));
        }

        final liabilitiesData = data['liabilitiesAndEquities'] as Map<String, dynamic>? ?? {};
        if (liabilitiesData.isNotEmpty) {
          dynamicRows.add(const _BalanceSheetRowData(account: 'Liabilities & Equities', total: '', isSection: true));
          processSubCategories(liabilitiesData['subCategories'] as Map<String, dynamic>? ?? {}, 1);
          dynamicRows.add(_BalanceSheetRowData(
            account: 'Total for Liabilities and Equities',
            total: (double.tryParse(liabilitiesData['total']?.toString() ?? '0') ?? 0.0).toStringAsFixed(2),
            isTotal: true,
          ));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final int extraCols = comparisonPeriods.isEmpty ? 0 : comparisonPeriods.length - 1;
            final double minWidth = 825.0 + (extraCols * 170.0);
            final tableWidth = constraints.maxWidth < minWidth ? constraints.maxWidth : minWidth;
            
            final tableHeight = constraints.hasBoundedHeight
                ? constraints.maxHeight
                : 480.0;
            final table = SizedBox(
              width: tableWidth,
              height: tableHeight,
              child: ReportStickyHeaderScrollTable(
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Basis : $reportBasis',
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    _BalanceSheetTableHeader(comparisonPeriods: comparisonPeriods),
                  ],
                ),
                emptyBody: const SizedBox.shrink(),
                children: [
                  for (final row in dynamicRows) 
                    _BalanceSheetTableRow(
                      row: row,
                      comparisonPeriods: comparisonPeriods,
                      appliedAsOfDate: appliedAsOfDate,
                    ),
                  const SizedBox(height: AppTheme.space24),
                  const _BaseCurrencyNote(),
                  const SizedBox(height: AppTheme.space10),
                ],
              ),
            );

            if (constraints.maxWidth < tableWidth) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: table,
              );
            }

            return Center(child: table);
          },
        );
      },
    );
  }
}

class _BalanceSheetTableHeader extends StatelessWidget {
  final List<String> comparisonPeriods;
  const _BalanceSheetTableHeader({required this.comparisonPeriods});

  @override
  Widget build(BuildContext context) {
    final bool hasComparison = comparisonPeriods.isNotEmpty;
    return Container(
      height: hasComparison ? 68 : 34,
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(
          top: BorderSide(color: AppTheme.borderLight),
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: hasComparison
          ? Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Expanded(child: SizedBox()),
                      for (final period in comparisonPeriods)
                        SizedBox(
                          width: 170,
                          child: Center(
                            child: Text(
                              period,
                              style: ReportTableTypography.header,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                          child: Text('ACCOUNT', style: ReportTableTypography.header),
                        ),
                      ),
                      for (final _ in comparisonPeriods)
                        SizedBox(
                          width: 170,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                            child: Text(
                              'TOTAL',
                              textAlign: TextAlign.right,
                              style: ReportTableTypography.header,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                    child: Text('ACCOUNT', style: ReportTableTypography.header),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20),
                    child: Text(
                      'TOTAL',
                      textAlign: TextAlign.right,
                      style: ReportTableTypography.header,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BalanceSheetTableRow extends StatelessWidget {
  final _BalanceSheetRowData row;
  final List<String> comparisonPeriods;
  final DateTime appliedAsOfDate;

  const _BalanceSheetTableRow({
    required this.row,
    required this.comparisonPeriods,
    required this.appliedAsOfDate,
  });

  @override
  Widget build(BuildContext context) {
    final isLinkedTotal = row.isTotal && row.isLink;
    final labelStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: row.isLink ? AppTheme.primaryBlue : AppTheme.textPrimary,
      fontWeight: row.isSection || row.isTotal
          ? FontWeight.w700
          : FontWeight.w400,
      decoration: isLinkedTotal
          ? TextDecoration.underline
          : TextDecoration.none,
      decorationColor: AppTheme.primaryBlue,
    );
    final amountStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: row.isLink ? AppTheme.primaryBlue : AppTheme.textPrimary,
      fontWeight: row.isSection ? FontWeight.w700 : FontWeight.w400,
      decoration: isLinkedTotal
          ? TextDecoration.underline
          : TextDecoration.none,
      decorationColor: AppTheme.primaryBlue,
    );

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: AppTheme.space20 + (row.indentLevel * AppTheme.space16),
          right: AppTheme.space20,
          top: row.isSection ? AppTheme.space14 : AppTheme.space10,
          bottom: AppTheme.space10,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (row.showCollapseIcon) ...[
                    const Icon(
                      Icons.remove_circle,
                      size: AppTheme.space12,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: AppTheme.space2),
                  ],
                  Flexible(
                      child: (row.isLink && row.accountId != null)
                          ? ZerpaiLinkText(
                              text: row.account,
                              style: labelStyle,
                              onTap: () {
                                final apiDateFormat = ReportFormatterCache.date('yyyy-MM-dd');
                                context.push(Uri(
                                  path: AppRoutes.accountantTransactionsReport,
                                  queryParameters: {
                                    'accountId': row.accountId,
                                    'accountName': row.account,
                                    'startDate': '2026-04-01',
                                    'endDate': apiDateFormat.format(appliedAsOfDate),
                                  },
                                ).toString());
                              },
                            )
                          : Text(
                              row.account,
                              style: labelStyle,
                            ),
                    ),
                ],
              ),
            ),
            if (comparisonPeriods.isEmpty)
              SizedBox(
                width: 170,
                child: Text(
                  row.total,
                  textAlign: TextAlign.right,
                  style: amountStyle,
                ),
              )
            else
              for (final _ in comparisonPeriods)
                SizedBox(
                  width: 170,
                  child: Text(
                    row.total,
                    textAlign: TextAlign.right,
                    style: amountStyle,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _BaseCurrencyNote extends StatelessWidget {
  const _BaseCurrencyNote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppTheme.space20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '**Amount is displayed in your base currency',
            style: AppTheme.captionText.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppTheme.space4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space4,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.successTextDark,
              borderRadius: BorderRadius.circular(1),
            ),
            child: Text(
              'INR',
              style: AppTheme.captionText.copyWith(
                color: AppTheme.backgroundColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
