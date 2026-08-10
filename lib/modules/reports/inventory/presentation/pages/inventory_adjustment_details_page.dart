import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/inventory/presentation/widgets/inventory_adjustment_details_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_popup_positioning.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';

class InventoryAdjustmentDetailsReportData {
  final List<InventoryAdjustmentDetailsRow> rows;
  final InventoryAdjustmentDetailsRow totals;

  const InventoryAdjustmentDetailsReportData({
    required this.rows,
    required this.totals,
  });
}

final inventoryAdjustmentDetailsRowsProvider = FutureProvider.autoDispose
    .family<InventoryAdjustmentDetailsReportData, int>((ref, refreshKey) async {
      final repository = ref.watch(reportsRepositoryProvider);
      final response = await repository.getInventoryAdjustmentDetails(
        startDate: '2026-07-01',
        endDate: '2026-07-31',
        limit: 500,
      );
      final rows = List<Map<String, dynamic>>.from(response['data'] ?? const [])
          .map(InventoryAdjustmentDetailsRow.fromJson)
          .where((row) => row.date.trim().isNotEmpty)
          .toList(growable: false);
      final meta = response['meta'] is Map
          ? Map<String, dynamic>.from(response['meta'] as Map)
          : const <String, dynamic>{};
      final totals = meta['totals'] is Map
          ? InventoryAdjustmentDetailsRow.fromTotals(
              Map<String, dynamic>.from(meta['totals'] as Map),
            )
          : InventoryAdjustmentDetailsRow.totalFromRows(rows);
      return InventoryAdjustmentDetailsReportData(rows: rows, totals: totals);
    });

class InventoryAdjustmentDetailsPage extends ConsumerStatefulWidget {
  const InventoryAdjustmentDetailsPage({super.key});

  @override
  ConsumerState<InventoryAdjustmentDetailsPage> createState() =>
      _InventoryAdjustmentDetailsPageState();
}

class _InventoryAdjustmentDetailsPageState
    extends ConsumerState<InventoryAdjustmentDetailsPage> {
  static const int _pageSize = 20;
  static const List<String> _groupByOptions = <String>[
    'Reference Number',
    'Date',
    'Inventory Adjustment Reason',
    'Adjustment Type',
  ];
  static const String _dateLabel = 'From 01-07-2026 To 31-07-2026';
  static final DateTime _dateRangeStartDate = DateTime(2026, 7, 1);
  static final DateTime _dateRangeEndDate = DateTime(2026, 7, 31, 23, 59, 59);

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;
  List<String> _groupByFields = const <String>[];
  bool _showGroupTotals = false;

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

  void _handleDateRangeChanged(ReportDateRangeSelection _) {
    _handleFilterControlChanged();
  }

  void _handleGroupByApplied(List<String> fields, bool showGroupTotals) {
    setState(() {
      _page = 1;
      _groupByFields = List<String>.unmodifiable(fields);
      _showGroupTotals = showGroupTotals;
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
    AsyncValue<InventoryAdjustmentDetailsReportData> rowsAsync,
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
    final rowsAsync = ref.watch(
      inventoryAdjustmentDetailsRowsProvider(_refreshKey),
    );
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final reportData = rowsAsync.valueOrNull;
    final rows = reportData?.rows ?? const <InventoryAdjustmentDetailsRow>[];
    final totals =
        reportData?.totals ?? InventoryAdjustmentDetailsRow.totalFromRows(rows);

    return ReportViewScaffold(
      categoryLabel: 'Inventory',
      reportTitle: 'Inventory Adjustment Details',
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _dateRangeStartDate,
          initialEndDate: _dateRangeEndDate,
          onChanged: _handleDateRangeChanged,
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
        onChanged: _handleFilterControlChanged,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: 'Inventory Adjustment Details',
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
      settingsTooltip: 'Customize the Inventory Adjustment Details report.',
      scheduleTooltip: 'Schedule the Inventory Adjustment Details report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InventoryAdjustmentDetailsGroupBySection(
            selectedValues: _groupByFields,
            showGroupTotals: _showGroupTotals,
            options: _groupByOptions,
            onApply: _handleGroupByApplied,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 8),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No inventory adjustment details found',
      emptyMessage:
          'There are no inventory adjustment detail rows for the selected criteria.',
      currentNavigationCategory: 'Inventory',
      currentNavigationReport: 'Inventory Adjustment Details',
      onReportSelected: (reportName, category) {
        if (reportName == 'Inventory Adjustment Details') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: InventoryAdjustmentDetailsTable(
        rows: rows,
        totals: totals,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        groupByFields: _groupByFields,
        showGroupTotals: _showGroupTotals,
      ),
    );
  }
}

class _InventoryAdjustmentDetailsGroupBySection extends StatefulWidget {
  final List<String> selectedValues;
  final bool showGroupTotals;
  final List<String> options;
  final void Function(List<String> fields, bool showGroupTotals) onApply;

  const _InventoryAdjustmentDetailsGroupBySection({
    required this.selectedValues,
    required this.showGroupTotals,
    required this.options,
    required this.onApply,
  });

  @override
  State<_InventoryAdjustmentDetailsGroupBySection> createState() =>
      _InventoryAdjustmentDetailsGroupBySectionState();
}

class _InventoryAdjustmentDetailsGroupBySectionState
    extends State<_InventoryAdjustmentDetailsGroupBySection> {
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
  void didUpdateWidget(covariant _InventoryAdjustmentDetailsGroupBySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isOpen) _syncDraftFromWidget();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _syncDraftFromWidget() {
    _draftValues = widget.selectedValues
        .where(widget.options.contains)
        .toList(growable: false);
    _draftShowTotals = widget.showGroupTotals;
  }

  void _toggleOverlay() => _isOpen ? _cancel() : _openOverlay();

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

  void _markOverlayNeedsBuild() => _overlayEntry?.markNeedsBuild();

  void _cancel() {
    _syncDraftFromWidget();
    _removeOverlay();
    if (mounted) setState(() {});
  }

  void _apply() {
    widget.onApply(List<String>.unmodifiable(_draftValues), _draftShowTotals);
    _removeOverlay();
    if (mounted) setState(() {});
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
                itemBuilder: (item, isSelected, isHovered) {
                  return Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color: isHovered
                            ? Colors.white
                            : (isSelected
                                ? const Color(0xFF111827)
                                : AppTheme.textPrimary),
                        fontWeight:
                            isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  );
                },
                listBuilder: (items, itemBuilder) {
                  final adjustmentItems = items
                      .where((item) => const <String>[
                            'Reference Number',
                            'Date',
                            'Inventory Adjustment Reason',
                            'Adjustment Type',
                          ].contains(item))
                      .toList(growable: false);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (adjustmentItems.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          child: Text(
                            'Inventory Adjustment',
                            style: AppTheme.metaHelper.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        ...adjustmentItems.map(itemBuilder),
                      ],
                    ],
                  );
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
