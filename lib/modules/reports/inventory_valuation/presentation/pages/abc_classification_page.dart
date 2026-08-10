import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/inventory_valuation/presentation/widgets/abc_classification_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_tooltip.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

final abcClassificationRowsProvider = FutureProvider.autoDispose
    .family<List<AbcClassificationRow>, int>((ref, refreshKey) async {
      final repository = ref.watch(reportsRepositoryProvider);
      final Map<String, dynamic> response;
      try {
        response = await repository.getInventoryValuation();
      } catch (_) {
        return const <AbcClassificationRow>[];
      }
      final rawRows = List<Map<String, dynamic>>.from(
        response['data'] ?? const [],
      );
      final sourceRows = rawRows
          .map(_AbcSourceRow.fromJson)
          .where((row) => row.itemName.trim().isNotEmpty)
          .toList(growable: false)
        ..sort((a, b) => b.value.compareTo(a.value));

      final totalValue = sourceRows.fold<double>(0, (sum, row) => sum + row.value);
      double cumulativeValue = 0;
      return sourceRows.map((row) {
        cumulativeValue += row.value;
        final share = totalValue == 0 ? 0.0 : (row.value / totalValue) * 100;
        final cumulativeShare = totalValue == 0
            ? 100.0
            : (cumulativeValue / totalValue) * 100;
        return AbcClassificationRow(
          itemName: row.itemName,
          cumulativeValue: row.value,
          cumulativeShare: share,
          currentClass: _classForShare(cumulativeShare),
        );
      }).toList(growable: false);
    });

String _classForShare(double cumulativeShare) {
  if (cumulativeShare <= 50) return 'A';
  if (cumulativeShare <= 80) return 'B';
  return 'C';
}

class _AbcSourceRow {
  final String itemName;
  final double value;

  const _AbcSourceRow({required this.itemName, required this.value});

  factory _AbcSourceRow.fromJson(Map<String, dynamic> item) {
    return _AbcSourceRow(
      itemName: item['itemName']?.toString() ?? '-',
      value: _numberValue(item, 'assetValue'),
    );
  }

  static double _numberValue(Map<String, dynamic> item, String key) {
    final value = item[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class AbcClassificationPage extends ConsumerStatefulWidget {
  const AbcClassificationPage({super.key});

  @override
  ConsumerState<AbcClassificationPage> createState() =>
      _AbcClassificationPageState();
}

class _AbcClassificationPageState extends ConsumerState<AbcClassificationPage> {
  static const int _pageSize = 24;
  static const String _dateLabel = 'From 01-07-2026 To 31-07-2026';
  static final DateTime _initialStartDate = DateTime(2026, 7, 1);
  static final DateTime _initialEndDate = DateTime(2026, 7, 31, 23, 59, 59);
  static const List<String> _classifyBasedOnOptions = <String>[
    'Usage Value',
    'Quantity',
  ];

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;
  String _selectedClassifyBasedOn = 'Usage Value';

  void _markFiltersDirty() {
    _hasPendingFilterChanges = true;
    _isApplyingFilters = false;
  }

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
  }

  void _handleFilterControlChanged() {
    setState(_markFiltersDirty);
  }

  void _handleClassifyBasedOnChanged(String value) {
    if (_selectedClassifyBasedOn == value) return;
    setState(() {
      _selectedClassifyBasedOn = value;
      _markFiltersDirty();
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _page = 1;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<List<AbcClassificationRow>> rowsAsync,
  ) {
    if (!_isApplyingFilters || rowsAsync.isLoading || !rowsAsync.hasValue) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isApplyingFilters) return;
      setState(() {
        _isApplyingFilters = false;
        _hasPendingFilterChanges = false;
      });
    });
  }

  void _handlePageChanged(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    final rowsAsync = ref.watch(abcClassificationRowsProvider(_refreshKey));
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final rows = rowsAsync.valueOrNull ?? const <AbcClassificationRow>[];

    return ReportViewScaffold(
      categoryLabel: 'Inventory Valuation',
      reportTitle: 'ABC Classification',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _initialStartDate,
          initialEndDate: _initialEndDate,
          onChanged: (_) => _handleFilterControlChanged(),
        ),
        ReportSearchableFilterDropdown(
          label: 'Classify Based on',
          value: _selectedClassifyBasedOn,
          options: _classifyBasedOnOptions,
          onChanged: _handleClassifyBasedOnChanged,
          width: 306,
          menuWidth: 156,
          menuMaxHeight: 196,
          labelSuffix: const _FilterInfoIcon(
            message: 'Classify inventory items by the selected value basis.',
          ),
        ),
        const _ClassPercentageFilter(),
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
        onChanged: _handleFilterControlChanged,
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
      settingsTooltip: 'Customize the ABC Classification report.',
      tableHeaderActions: const ReportCustomizeColumnsButton(count: 4),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No ABC classification rows found',
      emptyMessage:
          'There are no ABC classification rows for the selected criteria.',
      currentNavigationCategory: 'Inventory Valuation',
      currentNavigationReport: 'ABC classification',
      onReportSelected: (reportName, category) {
        if (reportName == 'ABC classification') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: AbcClassificationTable(
        rows: rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}

class _ClassPercentageFilter extends StatelessWidget {
  const _ClassPercentageFilter();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.buttonHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.space8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text('Class Percentage', style: _filterLabelStyle),
          SizedBox(width: AppTheme.space4),
          _FilterInfoIcon(
            message: 'Class percentage split used to assign A, B, and C classes.',
          ),
          Text(' : ', style: _filterLabelStyle),
          _ClassPercentagePill(label: 'A', value: '50'),
          SizedBox(width: AppTheme.space6),
          _ClassPercentagePill(label: 'B', value: '30'),
          SizedBox(width: AppTheme.space6),
          _ClassPercentagePill(label: 'C', value: '20'),
        ],
      ),
    );
  }
}

const TextStyle _filterLabelStyle = TextStyle(
  color: AppTheme.textPrimary,
  fontSize: 13,
  fontWeight: FontWeight.w500,
);

class _ClassPercentagePill extends StatelessWidget {
  final String label;
  final String value;

  const _ClassPercentagePill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(AppTheme.space6),
      ),
      alignment: Alignment.center,
      child: Text(
        '$label : $value',
        style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
      ),
    );
  }
}

class _FilterInfoIcon extends StatelessWidget {
  final String message;

  const _FilterInfoIcon({required this.message});

  @override
  Widget build(BuildContext context) {
    return ReportTooltip(
      message: message,
      child: const Icon(
        Icons.info_outline,
        size: AppTheme.space14,
        color: AppTheme.textMuted,
      ),
    );
  }
}
