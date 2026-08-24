import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/business_overview/data/providers/horizontal_balance_sheet_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_action_buttons.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_sticky_header_scroll_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';

class HorizontalBalanceSheetScreen extends StatefulWidget {
  const HorizontalBalanceSheetScreen({super.key});

  @override
  State<HorizontalBalanceSheetScreen> createState() =>
      _HorizontalBalanceSheetScreenState();
}

class _HorizontalBalanceSheetScreenState
    extends State<HorizontalBalanceSheetScreen> {
  static const String _dateLabel = 'As of 14-07-2026';

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  String _reportBasis = 'Accrual';

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

  void _cycleReportBasis() {
    setState(() {
      _reportBasis = _reportBasis == 'Accrual' ? 'Cash' : 'Accrual';
      _hasPendingFilterChanges = true;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() => _hasPendingFilterChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Business Overview',
      reportTitle: 'Horizontal Balance Sheet',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportFilterChip(
          label: 'As of',
          value: 'Today',
          onPressed: _markFiltersDirty,
        ),
        ReportFilterChip(
          label: 'Report Basis',
          value: _reportBasis,
          onPressed: _cycleReportBasis,
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
      settingsTooltip: 'Customize the Horizontal Balance Sheet report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
      currentNavigationReport: 'Horizontal Balance Sheet',
      onReportSelected: (reportName, category) {
        if (reportName == 'Horizontal Balance Sheet') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: _HorizontalBalanceSheetStatement(
        reportBasis: _reportBasis,
      ),
    );
  }
}

// ignore_for_file: unused_element_parameter
class _HorizontalBalanceSheetItem {
  final String label;
  final String amount;
  final int indentLevel;
  final bool isSection;
  final bool isTotal;
  final bool isLink;
  final bool isItalic;
  final bool showCollapseIcon;
  final bool highlighted;

  const _HorizontalBalanceSheetItem({
    required this.label,
    required this.amount,
    this.indentLevel = 0,
    this.isSection = false,
    this.isTotal = false,
    this.isLink = false,
    this.isItalic = false,
    this.showCollapseIcon = false,
    this.highlighted = false,
  });
}

class _HorizontalBalanceSheetStatement extends StatelessWidget {
  final String reportBasis;

  const _HorizontalBalanceSheetStatement({required this.reportBasis});

  // 

  // 

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const statementWidth = 1100.0;
        final statementHeight = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : 480.0;
        final statement = SizedBox(
          width: statementWidth,
          height: statementHeight,
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
                Text(
                  'As of 14-07-2026',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyText.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppTheme.space28),
              ],
            ),
            emptyBody: const SizedBox.shrink(),
            children: [
              _HorizontalBalanceSheetGrid(
                asOfDate: DateTime.now().toIso8601String().split('T')[0], // Mocking current date for now
                basis: reportBasis,
              ),
              SizedBox(height: AppTheme.space48),
              _BaseCurrencyNote(),
              SizedBox(height: AppTheme.space10),
            ],
          ),
        );

        if (constraints.maxWidth < statementWidth) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: statement,
          );
        }

        return Center(child: statement);
      },
    );
  }
}

class _HorizontalBalanceSheetGrid extends ConsumerWidget {
  final String asOfDate;
  final String basis;

  const _HorizontalBalanceSheetGrid({
    required this.asOfDate,
    required this.basis,
  });

  String _formatAmount(num amount) {
    if (amount == 0) return '0.00';
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '',
      decimalDigits: 2,
    ).format(amount);
  }

  List<_HorizontalBalanceSheetItem> _mapSections(List<dynamic> sections) {
    final List<_HorizontalBalanceSheetItem> items = [];
    for (final section in sections) {
      items.add(_HorizontalBalanceSheetItem(
        label: section['label'] ?? '',
        amount: '',
        isSection: true,
      ));
      
      final rows = section['rows'] as List<dynamic>? ?? [];
      for (final row in rows) {
        items.add(_HorizontalBalanceSheetItem(
          label: row['label'] ?? '',
          amount: _formatAmount(row['amount'] ?? 0),
          indentLevel: 1,
        ));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(horizontalBalanceSheetProvider(
      HorizontalBalanceSheetArgs(asOfDate: asOfDate, basis: basis),
    ));

    return asyncData.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(48.0),
          child: ZTableSkeleton(rows: 10, columns: 2),
        ),
      ),
      error: (e, s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(48.0),
          child: Text('Failed to load report: $e'),
        ),
      ),
      data: (data) {
        final liabilitiesAndEquity = data['liabilitiesAndEquity'] ?? {};
        final assets = data['assets'] ?? {};

        final totalLiabilities = liabilitiesAndEquity['total'] ?? 0;
        final totalAssets = assets['total'] ?? 0;

        final liabilitiesRows = _mapSections(liabilitiesAndEquity['sections'] ?? []);
        final assetsRows = _mapSections(assets['sections'] ?? []);

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.backgroundColor,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(AppTheme.space4),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _StatementSide(
                    title: 'Liabilities & Equities',
                    rows: liabilitiesRows,
                    totalLabel: 'TOTAL LIABILITIES & EQUITIES',
                    totalAmount: _formatAmount(totalLiabilities),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: AppTheme.borderLight,
                ),
                Expanded(
                  child: _StatementSide(
                    title: 'Assets',
                    rows: assetsRows,
                    totalLabel: 'TOTAL ASSETS',
                    totalAmount: _formatAmount(totalAssets),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

class _StatementSide extends StatelessWidget {
  final String title;
  final List<_HorizontalBalanceSheetItem> rows;
  final String totalLabel;
  final String totalAmount;

  const _StatementSide({
    required this.title,
    required this.rows,
    required this.totalLabel,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space20,
            AppTheme.space14,
            AppTheme.space20,
            AppTheme.space12,
          ),
          child: Text(
            title,
            style: AppTheme.pageTitle.copyWith(
              fontStyle: FontStyle.italic,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space20,
            AppTheme.space8,
            AppTheme.space20,
            AppTheme.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final row in rows) _StatementRow(row: row),
            ],
          ),
        ),
        const Spacer(),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderLight),
        _StatementTotalRow(label: totalLabel, amount: totalAmount),
      ],
    );
  }
}

class _StatementRow extends StatelessWidget {
  final _HorizontalBalanceSheetItem row;

  const _StatementRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final textColor = row.isLink ? AppTheme.primaryBlue : AppTheme.textPrimary;
    final textStyle = AppTheme.tableCell.copyWith(
      fontSize: 14,
      color: textColor,
      fontStyle: row.isItalic ? FontStyle.italic : FontStyle.normal,
      fontWeight: row.isSection || row.isTotal ? FontWeight.w700 : FontWeight.w400,
    );

    final content = Padding(
      padding: EdgeInsets.only(
        left: row.indentLevel * AppTheme.space14,
        top: row.isSection ? AppTheme.space16 : AppTheme.space8,
        bottom: AppTheme.space8,
      ),
      child: Row(
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
                ] else if (!row.isSection && !row.isTotal) ...[
                  Text('- ', style: textStyle.copyWith(color: AppTheme.textPrimary)),
                ],
                Flexible(
                  child: Text(row.label, style: textStyle),
                ),
              ],
            ),
          ),
          if (row.amount.isNotEmpty)
            Text(
              row.amount,
              textAlign: TextAlign.right,
              style: textStyle.copyWith(
                color: row.isTotal && !row.isLink
                    ? AppTheme.textPrimary
                    : textStyle.color,
              ),
            ),
        ],
      ),
    );

    final decorated = row.isTotal
        ? DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: content,
          )
        : content;

    if (!row.highlighted) return decorated;

    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.bgLight),
      child: decorated,
    );
  }
}

class _StatementTotalRow extends StatelessWidget {
  final String label;
  final String amount;

  const _StatementTotalRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.space20,
        AppTheme.space14,
        AppTheme.space32,
        AppTheme.space14,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTheme.tableCell.copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            amount,
            textAlign: TextAlign.right,
            style: AppTheme.tableCell.copyWith(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
