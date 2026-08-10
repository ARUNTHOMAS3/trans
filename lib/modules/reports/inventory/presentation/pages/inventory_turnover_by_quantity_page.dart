import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/inventory/presentation/widgets/inventory_turnover_by_quantity_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_popup_positioning.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class InventoryTurnoverByQuantityReportData {
  final List<InventoryTurnoverByQuantityRow> rows;
  final InventoryTurnoverByQuantityRow totals;

  const InventoryTurnoverByQuantityReportData({
    required this.rows,
    required this.totals,
  });
}

final inventoryTurnoverByQuantityRowsProvider = FutureProvider.autoDispose
    .family<InventoryTurnoverByQuantityReportData, int>((
      ref,
      refreshKey,
    ) async {
      final repository = ref.watch(reportsRepositoryProvider);
      final response = await repository.getInventoryTurnoverByQuantity(
        startDate: '2026-07-01',
        endDate: '2026-07-31',
        limit: 500,
      );
      final rows = List<Map<String, dynamic>>.from(response['data'] ?? const [])
          .map(InventoryTurnoverByQuantityRow.fromJson)
          .where((row) => row.itemName.trim().isNotEmpty)
          .toList(growable: false);
      final meta = response['meta'] is Map
          ? Map<String, dynamic>.from(response['meta'] as Map)
          : const <String, dynamic>{};
      final totals = meta['totals'] is Map
          ? InventoryTurnoverByQuantityRow.fromTotals(
              Map<String, dynamic>.from(meta['totals'] as Map),
            )
          : InventoryTurnoverByQuantityRow.totalFromRows(rows);
      return InventoryTurnoverByQuantityReportData(rows: rows, totals: totals);
    });

class InventoryTurnoverByQuantityPage extends ConsumerStatefulWidget {
  const InventoryTurnoverByQuantityPage({super.key});

  @override
  ConsumerState<InventoryTurnoverByQuantityPage> createState() =>
      _InventoryTurnoverByQuantityPageState();
}

class _InventoryTurnoverByQuantityPageState
    extends ConsumerState<InventoryTurnoverByQuantityPage> {
  static const int _pageSize = 20;
  static const String _dateLabel = 'From 01-07-2026 To 31-07-2026';
  static final DateTime _dateRangeStartDate = DateTime(2026, 7, 1);
  static final DateTime _dateRangeEndDate = DateTime(2026, 7, 31, 23, 59, 59);

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  bool _isApplyingFilters = false;
  int _refreshKey = 0;
  int _page = 1;
  String _selectedGroupBy = 'None';

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

  void _handleGroupByChanged(String value) {
    if (_selectedGroupBy == value) return;
    setState(() {
      _selectedGroupBy = value;
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
    AsyncValue<InventoryTurnoverByQuantityReportData> rowsAsync,
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
      inventoryTurnoverByQuantityRowsProvider(_refreshKey),
    );
    _clearPendingAfterSuccessfulLoad(rowsAsync);
    final reportData = rowsAsync.valueOrNull;
    final rows = reportData?.rows ?? const <InventoryTurnoverByQuantityRow>[];
    final totals =
        reportData?.totals ??
        InventoryTurnoverByQuantityRow.totalFromRows(rows);

    return ReportViewScaffold(
      categoryLabel: 'Inventory Valuation',
      reportTitle: 'Inventory Turnover By Quantity',
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
        reportName: 'Inventory Turnover By Quantity',
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
      settingsTooltip: 'Customize the Inventory Turnover By Quantity report.',
      scheduleTooltip: 'Schedule the Inventory Turnover By Quantity report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _InventoryTurnoverGroupBySection(
            selectedValue: _selectedGroupBy,
            onChanged: _handleGroupByChanged,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 7),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      isEmpty: rows.isEmpty,
      emptyTitle: 'No inventory turnover rows found',
      emptyMessage:
          'There are no inventory turnover rows for the selected criteria.',
      currentNavigationCategory: 'Inventory',
      currentNavigationReport: 'Inventory Turnover By Quantity',
      onReportSelected: (reportName, category) {
        if (reportName == 'Inventory Turnover By Quantity') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: InventoryTurnoverByQuantityTable(
        rows: rows,
        totals: totals,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
      ),
    );
  }
}

class _InventoryTurnoverGroupBySection extends StatefulWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const _InventoryTurnoverGroupBySection({
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  State<_InventoryTurnoverGroupBySection> createState() =>
      _InventoryTurnoverGroupBySectionState();
}

class _InventoryTurnoverGroupBySectionState
    extends State<_InventoryTurnoverGroupBySection> {
  static const double _popupWidth = 320;
  static const double _dropdownWidth = 280;
  static const double _popupGap = AppTheme.space6;
  static const double _screenPadding = AppTheme.space12;

  final LayerLink _layerLink = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  String _draftValue = 'None';

  @override
  void initState() {
    super.initState();
    _draftValue = widget.selectedValue;
  }

  @override
  void didUpdateWidget(covariant _InventoryTurnoverGroupBySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isOpen && widget.selectedValue != _draftValue) {
      _draftValue = widget.selectedValue;
    }
  }

  @override
  void dispose() {
    _removeOverlay(updateState: false);
    super.dispose();
  }

  void _toggleOverlay() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _draftValue = widget.selectedValue;
    _overlayEntry = OverlayEntry(builder: (_) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay({bool updateState = true}) {
    final entry = _overlayEntry;
    _overlayEntry = null;
    if (entry != null) {
      if (entry.mounted) entry.remove();
      entry.dispose();
    }
    if (updateState && mounted && _isOpen) {
      setState(() => _isOpen = false);
    }
  }

  void _apply() {
    widget.onChanged(_draftValue);
    _removeOverlay();
  }

  void _cancel() {
    _draftValue = widget.selectedValue;
    _removeOverlay();
  }

  Widget _buildOverlay() {
    final anchorContext = _anchorKey.currentContext;
    final anchorRenderObject = anchorContext?.findRenderObject();
    if (anchorRenderObject is! RenderBox || !anchorRenderObject.hasSize) {
      return const SizedBox.shrink();
    }

    final placement = resolveReportPopupPlacement(
      context: context,
      anchorBox: anchorRenderObject,
      popupWidth: _popupWidth,
      popupHeight: 230,
      screenPadding: _screenPadding,
      popupGap: _popupGap,
    );
    final anchorCenterX = anchorRenderObject.size.width / 2;
    final arrowLeft = (anchorCenterX - placement.offset.dx - 5)
        .clamp(AppTheme.space16, _popupWidth - AppTheme.space24)
        .toDouble();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _cancel,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: placement.targetAnchor,
          followerAnchor: placement.followerAnchor,
          offset: placement.offset,
          showWhenUnlinked: false,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -5,
                  left: arrowLeft,
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
                value: _draftValue,
                items: const <String>[],
                hint: 'None',
                placeholder: 'Search',
                onChanged: (value) {
                  setState(() => _draftValue = value ?? 'None');
                  _overlayEntry?.markNeedsBuild();
                },
                showSearch: true,
                showSearchIcon: true,
                displayStringForValue: (value) => value,
                menuWidth: _dropdownWidth,
                menuMaxHeight: 120,
                fillColor: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.space6),
                border: Border.all(color: AppTheme.borderColor),
                showCustomValueAction: false,
                forceDownward: true,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space8,
              AppTheme.space16,
              0,
            ),
            child: Divider(height: 1, color: AppTheme.borderLight),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.space16),
            child: Row(
              children: [
                _InventoryTurnoverGroupByActionButton(
                  label: 'Apply',
                  isPrimary: true,
                  onPressed: _apply,
                ),
                const SizedBox(width: AppTheme.space8),
                _InventoryTurnoverGroupByActionButton(
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
        key: _anchorKey,
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
                widget.selectedValue == 'None' ? 'None' : 'Applied',
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

class _InventoryTurnoverGroupByActionButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _InventoryTurnoverGroupByActionButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
          backgroundColor:
              isPrimary ? AppTheme.successGreen : AppTheme.bgDisabled,
          foregroundColor:
              isPrimary ? AppTheme.backgroundColor : AppTheme.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.space4),
            side: BorderSide(
              color: isPrimary ? AppTheme.successGreen : AppTheme.borderLight,
            ),
          ),
          textStyle: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
