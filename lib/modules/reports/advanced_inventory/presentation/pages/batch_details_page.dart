import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/advanced_inventory/presentation/widgets/batch_details_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_popup_positioning.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_searchable_filter_dropdown.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class BatchDetailsReportQuery {
  final int refreshKey;
  final int page;
  final int pageSize;
  final DateTime startDate;
  final DateTime endDate;
  final bool hideEmptyBatches;

  const BatchDetailsReportQuery({
    required this.refreshKey,
    required this.page,
    required this.pageSize,
    required this.startDate,
    required this.endDate,
    required this.hideEmptyBatches,
  });

  @override
  bool operator ==(Object other) {
    return other is BatchDetailsReportQuery &&
        other.refreshKey == refreshKey &&
        other.page == page &&
        other.pageSize == pageSize &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.hideEmptyBatches == hideEmptyBatches;
  }

  @override
  int get hashCode => Object.hash(
        refreshKey,
        page,
        pageSize,
        startDate,
        endDate,
        hideEmptyBatches,
      );
}

class BatchDetailsReportData {
  final List<BatchDetailsRow> rows;
  final BatchDetailsRow totals;
  final int totalCount;

  const BatchDetailsReportData({
    required this.rows,
    required this.totals,
    required this.totalCount,
  });
}

final batchDetailsRowsProvider = FutureProvider.autoDispose
    .family<BatchDetailsReportData, BatchDetailsReportQuery>((ref, query) async {
  final repository = ref.watch(reportsRepositoryProvider);
  final dateFormatter = ReportFormatterCache.date('yyyy-MM-dd');
  final response = await repository.getBatchDetails(
    page: query.page,
    limit: query.pageSize,
    startDate: dateFormatter.format(query.startDate),
    endDate: dateFormatter.format(query.endDate),
    hideEmptyBatches: query.hideEmptyBatches,
  );
  final rows = List<Map<String, dynamic>>.from(response['data'] ?? const [])
      .map(BatchDetailsRow.fromJson)
      .toList(growable: false);
  final meta = Map<String, dynamic>.from(response['meta'] ?? const {});
  final totalsMap = meta['totals'] is Map
      ? Map<String, dynamic>.from(meta['totals'] as Map)
      : null;
  return BatchDetailsReportData(
    rows: rows,
    totals: BatchDetailsRow.totalFromJson(totalsMap),
    totalCount: _intValue(meta['total']) ?? rows.length,
  );
});

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

class BatchDetailsPage extends ConsumerStatefulWidget {
  const BatchDetailsPage({super.key});

  @override
  ConsumerState<BatchDetailsPage> createState() => _BatchDetailsPageState();
}

class _BatchDetailsPageState extends ConsumerState<BatchDetailsPage> {
  static const int _pageSize = 200;
  static const String _dateRangeFilterType = 'Date Range';
  static const String _asOfDateFilterType = 'As of Date';
  static const List<String> _dateFilterOptions = <String>[
    _asOfDateFilterType,
    _dateRangeFilterType,
  ];
  static const List<String> _reportByOptions = <String>['Creation Date'];
  static const List<String> _groupByOptions = <String>[
    'Item Name',
    'SKU',
    'Batch Number',
    'Manufactured Date',
    'Expiry Date',
    'Location Name',
  ];

  DateTime _startDate = DateTime(2026, 7, 1);
  DateTime _endDate = DateTime(2026, 7, 31, 23, 59, 59);
  DateTime _appliedStartDate = DateTime(2026, 7, 1);
  DateTime _appliedEndDate = DateTime(2026, 7, 31, 23, 59, 59);
  bool _hideEmptyBatches = false;
  bool _appliedHideEmptyBatches = false;
  String _selectedDateFilterType = _dateRangeFilterType;
  String _appliedDateFilterType = _dateRangeFilterType;
  String _reportBy = _reportByOptions.first;
  bool _isCombinedDateFilterActive = false;
  bool _isMoreFiltersOpen = false;
  bool _showGroupTotals = false;
  List<String> _groupByFields = const <String>[];
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;

  void _markFiltersDirty() {
    _hasPendingFilterChanges = true;
    _isApplyingFilters = false;
  }

  void _activateCombinedDateFilter() {
    if (_isCombinedDateFilterActive) return;
    setState(() => _isCombinedDateFilterActive = true);
  }

  void _deactivateCombinedDateFilter() {
    if (!_isCombinedDateFilterActive) return;
    setState(() => _isCombinedDateFilterActive = false);
  }

  void _handleDateFilterTypeChanged(String value) {
    if (_selectedDateFilterType == value) return;
    setState(() {
      _selectedDateFilterType = value;
      _isCombinedDateFilterActive = false;
      _markFiltersDirty();
    });
  }

  void _handleDateRangeChanged(ReportDateRangeSelection selection) {
    setState(() {
      _startDate = selection.startDate;
      _endDate = selection.endDate;
      _isCombinedDateFilterActive = false;
      _markFiltersDirty();
    });
  }

  void _toggleHideEmptyBatches(bool value) {
    setState(() {
      _hideEmptyBatches = value;
      _markFiltersDirty();
    });
  }

  void _handleReportByChanged(String value) {
    setState(() {
      _reportBy = value;
      _markFiltersDirty();
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
      _page = 1;
      _appliedDateFilterType = _selectedDateFilterType;
      if (_selectedDateFilterType == _asOfDateFilterType) {
        _appliedStartDate = DateTime(_endDate.year, _endDate.month, _endDate.day);
        _appliedEndDate = DateTime(
          _endDate.year,
          _endDate.month,
          _endDate.day,
          23,
          59,
          59,
        );
      } else {
        _appliedStartDate = _startDate;
        _appliedEndDate = _endDate;
      }
      _appliedHideEmptyBatches = _hideEmptyBatches;
      _isApplyingFilters = _hasPendingFilterChanges;
      _refreshKey += 1;
    });
  }

  void _clearPendingAfterSuccessfulLoad(
    AsyncValue<BatchDetailsReportData> rowsAsync,
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

  void _handleGroupByApplied(List<String> fields, bool showGroupTotals) {
    setState(() {
      _page = 1;
      _groupByFields = List<String>.unmodifiable(fields);
      _showGroupTotals = showGroupTotals;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = BatchDetailsReportQuery(
      refreshKey: _refreshKey,
      page: _page,
      pageSize: _pageSize,
      startDate: _appliedStartDate,
      endDate: _appliedEndDate,
      hideEmptyBatches: _appliedHideEmptyBatches,
    );
    final rowsAsync = ref.watch(batchDetailsRowsProvider(query));
    _clearPendingAfterSuccessfulLoad(rowsAsync);

    final reportData = rowsAsync.valueOrNull;
    final rows = reportData?.rows ?? const <BatchDetailsRow>[];
    final totals = reportData?.totals ?? BatchDetailsRow.emptyTotal;
    final totalCount = reportData?.totalCount ?? rows.length;
    final headerDateFormatter = ReportFormatterCache.date('dd-MM-yyyy');
    final dateLabel = _appliedDateFilterType == _asOfDateFilterType
        ? 'As of ${headerDateFormatter.format(_appliedEndDate)}'
        : 'From ${headerDateFormatter.format(_appliedStartDate)} To ${headerDateFormatter.format(_appliedEndDate)}';

    return ReportViewScaffold(
      categoryLabel: 'Advanced Inventory',
      reportTitle: 'Batch Details Report',
      dateLabel: dateLabel,
      companyName: '',
      filters: [
        TapRegion(
          onTapOutside: (_) => _deactivateCombinedDateFilter(),
          child: Listener(
            onPointerDown: (_) => _activateCombinedDateFilter(),
            child: Container(
              height: AppTheme.buttonHeight,
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(AppTheme.space6),
                border: Border.all(
                  color: _isCombinedDateFilterActive
                      ? AppTheme.primaryBlue
                      : AppTheme.borderColor,
                  width: _isCombinedDateFilterActive
                      ? AppTheme.inputActiveBorderWidth
                      : AppTheme.inputBorderWidth,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReportSearchableFilterDropdown(
                    label: 'Filter Type',
                    value: _selectedDateFilterType,
                    options: _dateFilterOptions,
                    onChanged: _handleDateFilterTypeChanged,
                    showLabel: false,
                    width: 118,
                    menuWidth: 156,
                    menuMaxHeight: 152,
                    fillColor: AppTheme.bgLight,
                    border: Border.all(color: Colors.transparent),
                    hideBorderDefault: true,
                    showLeftBorder: false,
                    showRightBorder: false,
                    clipActiveBorder: true,
                    activeBorderCoverColor: AppTheme.bgLight,
                  ),
                  Text(
                    ':',
                    style: AppTheme.bodyText.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ReportDateRangeFilter(
                    key: ValueKey(_selectedDateFilterType),
                    label: _selectedDateFilterType,
                    showLabel: false,
                    fillColor: AppTheme.bgLight,
                    showBorder: false,
                    suppressHoverOverlay: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space8,
                    ),
                    initialStartDate: _startDate,
                    initialEndDate: _endDate,
                    onChanged: _handleDateRangeChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
        ReportSearchableFilterDropdown(
          label: 'Report By',
          value: _reportBy,
          options: _reportByOptions,
          onChanged: _handleReportByChanged,
          width: 238,
          menuWidth: 238,
        ),
        _BatchEmptyFilterChip(
          value: _hideEmptyBatches,
          onChanged: _toggleHideEmptyBatches,
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
        onChanged: () => setState(_markFiltersDirty),
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: 'Batch Details Report',
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
      settingsTooltip: 'Customize the Batch Details report.',
      scheduleTooltip: 'Schedule the Batch Details report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BatchDetailsGroupBySection(
            selectedValues: _groupByFields,
            showGroupTotals: _showGroupTotals,
            options: _groupByOptions,
            onApply: _handleGroupByApplied,
          ),
          const SizedBox(width: AppTheme.space16),
          const ReportCustomizeColumnsButton(count: 9),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No batches found',
      emptyMessage: 'There are no batches for the selected criteria.',
      currentNavigationCategory: 'Advanced Inventory',
      currentNavigationReport: 'Batch Details',
      onReportSelected: (reportName, category) {
        if (reportName == 'Batch Details') return;
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: BatchDetailsTable(
        rows: rows,
        totals: totals,
        page: _page,
        pageSize: _pageSize,
        totalCount: totalCount,
        onPageChanged: _handlePageChanged,
        groupByFields: _groupByFields,
        showGroupTotals: _showGroupTotals,
      ),
    );
  }
}

class _BatchDetailsGroupBySection extends StatefulWidget {
  final List<String> selectedValues;
  final bool showGroupTotals;
  final List<String> options;
  final void Function(List<String> fields, bool showGroupTotals) onApply;

  const _BatchDetailsGroupBySection({
    required this.selectedValues,
    required this.showGroupTotals,
    required this.options,
    required this.onApply,
  });

  @override
  State<_BatchDetailsGroupBySection> createState() =>
      _BatchDetailsGroupBySectionState();
}

class _BatchDetailsGroupBySectionState
    extends State<_BatchDetailsGroupBySection> {
  static const double _popupWidth = 302;
  static const double _popupHeight = 228;
  static const double _dropdownWidth = 270;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _draftValues = const <String>[];
  bool _draftShowTotals = false;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _syncDraftFromWidget();
  }

  @override
  void didUpdateWidget(covariant _BatchDetailsGroupBySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isOpen) {
      _syncDraftFromWidget();
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _syncDraftFromWidget() {
    _draftValues = List<String>.from(widget.selectedValues);
    _draftShowTotals = widget.showGroupTotals;
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _cancel();
    } else {
      _openOverlay();
    }
  }

  void _openOverlay() {
    _syncDraftFromWidget();
    _overlayEntry = OverlayEntry(builder: _buildOverlay);
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOpen = false;
  }

  void _markOverlayNeedsBuild() {
    _overlayEntry?.markNeedsBuild();
  }

  void _cancel() {
    _syncDraftFromWidget();
    _removeOverlay();
    if (mounted) {
      setState(() {});
    }
  }

  void _apply() {
    widget.onApply(List<String>.unmodifiable(_draftValues), _draftShowTotals);
    _removeOverlay();
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final placement = renderBox == null
        ? const ReportPopupPlacement(
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: Offset(0, AppTheme.space4),
          )
        : resolveReportPopupPlacement(
            context: context,
            anchorBox: renderBox,
            popupWidth: _popupWidth,
            popupHeight: _popupHeight,
            popupGap: AppTheme.space8,
          );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _cancel,
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          targetAnchor: placement.targetAnchor,
          followerAnchor: placement.followerAnchor,
          offset: placement.offset,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -5,
                  left: _popupWidth / 2 - 5,
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                    ),
                  ),
                ),
                _buildPopupContent(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPopupContent() {
    return Container(
      width: _popupWidth,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(AppTheme.space6),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.space16,
              vertical: AppTheme.space12,
            ),
            child: Text(
              'Group By',
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space16,
              AppTheme.space10,
            ),
            child: SizedBox(
              width: _dropdownWidth,
              child: FormDropdown<String>(
                value: null,
                items: widget.options,
                hint: 'None',
                placeholder: 'Search',
                onChanged: (_) {},
                showSearch: true,
                showSearchIcon: true,
                multiSelect: true,
                selectedValues: _draftValues,
                onSelectedValuesChanged: (values) {
                  setState(() => _draftValues = List<String>.from(values));
                  _markOverlayNeedsBuild();
                },
                displayStringForValue: (value) => value,
                menuWidth: _dropdownWidth,
                menuMaxHeight: 270,
                fillColor: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.space6),
                border: Border.all(color: AppTheme.borderColor),
                hideSelectedItemsInMultiSelect: true,
                showCustomValueAction: false,
                forceDownward: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.space4),
              onTap: () {
                setState(() => _draftShowTotals = !_draftShowTotals);
                _markOverlayNeedsBuild();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space4,
                  vertical: AppTheme.space4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: AppTheme.space18,
                      height: AppTheme.space18,
                      child: Checkbox(
                        value: _draftShowTotals,
                        onChanged: (value) {
                          setState(() => _draftShowTotals = value ?? false);
                          _markOverlayNeedsBuild();
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        activeColor: AppTheme.primaryBlue,
                        checkColor: AppTheme.backgroundColor,
                        side: const BorderSide(color: AppTheme.borderColor),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Expanded(
                      child: Text(
                        'Display the total as a separate row\nbelow each group',
                        style: AppTheme.bodyText.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space10,
              AppTheme.space16,
              0,
            ),
            child: Divider(height: 1, color: AppTheme.borderLight),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                _GroupByActionButton(
                  label: 'Apply',
                  isPrimary: true,
                  onPressed: _apply,
                ),
                const SizedBox(width: AppTheme.space8),
                _GroupByActionButton(
                  label: 'Cancel',
                  isPrimary: false,
                  onPressed: _cancel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.space4),
        onTap: _toggleOverlay,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space4,
            vertical: AppTheme.space6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.archive,
                size: AppTheme.space16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: AppTheme.space4),
              Text(
                'Group By : ',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                widget.selectedValues.isEmpty ? 'None' : 'Applied',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppTheme.space4),
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: AppTheme.space18,
                color: AppTheme.textPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupByActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _GroupByActionButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor:
              isPrimary ? AppTheme.successGreen : AppTheme.bgDisabled,
          foregroundColor:
              isPrimary ? AppTheme.backgroundColor : AppTheme.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.space4),
            side: BorderSide(
              color: isPrimary ? AppTheme.successGreen : AppTheme.borderColor,
            ),
          ),
        ),
        child: Text(
          label,
          style: AppTheme.metaHelper.copyWith(
            color: isPrimary ? AppTheme.backgroundColor : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _BatchEmptyFilterChip extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BatchEmptyFilterChip({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.bgLight,
      borderRadius: BorderRadius.circular(AppTheme.space8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.space8),
        onTap: () => onChanged(!value),
        child: Container(
          height: AppTheme.inputHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(AppTheme.space8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: AppTheme.space16,
                height: AppTheme.space16,
                child: Checkbox(
                  value: value,
                  onChanged: (selected) => onChanged(selected ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: AppTheme.primaryBlue,
                  checkColor: AppTheme.backgroundColor,
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              Text(
                'Do not show empty batches.',
                style: AppTheme.bodyText.copyWith(color: AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
