import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/reports/utils/report_formatter_cache.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accountant/providers/currency_provider.dart';
import 'package:zerpai_erp/modules/reports/payables/presentation/widgets/purchase_orders_by_item_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_schedule_dialog.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/utils/report_utils.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_company_header.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_popup_positioning.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

const String _purchaseOrdersByItemTitle = 'Purchase Order by Item';
const String _purchaseOrdersByItemBasis = 'Accrual';

typedef PurchaseOrdersByItemParams = ({
  String startDate,
  String endDate,
  String basis,
  int page,
  int pageSize,
});

final purchaseOrdersByItemProvider =
    FutureProvider.family<Map<String, dynamic>, PurchaseOrdersByItemParams>((
  ref,
  params,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  return repo.getPurchaseOrdersByItem(
    params.startDate,
    params.endDate,
    basis: params.basis,
    page: params.page,
    pageSize: params.pageSize,
  );
});

class PurchaseOrdersByItemPage extends ConsumerStatefulWidget {
  const PurchaseOrdersByItemPage({super.key});

  @override
  ConsumerState<PurchaseOrdersByItemPage> createState() =>
      _PurchaseOrdersByItemPageState();
}

class _PurchaseOrdersByItemPageState
    extends ConsumerState<PurchaseOrdersByItemPage> {
  bool _isInitialized = false;
  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  List<String> _groupByFields = const <String>[];
  bool _showGroupTotals = false;
  int _page = 1;
  final int _pageSize = 200;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _appliedStartDate;
  DateTime? _appliedEndDate;

  static const List<String> _groupByOptions = <String>[
    'Date',
    'P.O#',
    'Vendor Name',
    'Item Name',
  ];

  void _initializeFromRoute(
    Map<String, Object?> parsedParams,
    GoRouterState routerState,
  ) {
    if (_isInitialized) return;
    final query = routerState.uri.queryParameters;
    if (query['startDate'] == null && query['endDate'] == null) {
      final thisYear = ReportDateRangePresets.resolveRange(
        ReportDateRangePresets.thisYear,
      );
      _startDate = thisYear.startDate;
      _endDate = thisYear.endDate;
    } else {
      _startDate = parsedParams['startDate'] as DateTime;
      _endDate = parsedParams['endDate'] as DateTime;
    }
    _appliedStartDate = _startDate;
    _appliedEndDate = _endDate;
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

  void _toggleMoreFilters() {
    setState(() => _isMoreFiltersOpen = !_isMoreFiltersOpen);
  }

  void _closeMoreFilters() {
    if (_isMoreFiltersOpen) {
      setState(() => _isMoreFiltersOpen = false);
    }
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
      _appliedStartDate = _startDate;
      _appliedEndDate = _endDate;
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
    _initializeFromRoute(parsedParams, routerState);

    final startDate = _startDate!;
    final endDate = _endDate!;
    final appliedStartDate = _appliedStartDate!;
    final appliedEndDate = _appliedEndDate!;
    final orgDatePattern = ref.watch(orgDateFormatProvider);
    final dateFormat = ReportFormatterCache.date(orgDatePattern);
    final dateLabel =
        'From ${dateFormat.format(appliedStartDate)} To ${dateFormat.format(appliedEndDate)}';
    final currencyAsync = ref.watch(defaultCurrencyProvider);
    final currencyFormat = NumberFormat.currency(
      symbol: currencyAsync.valueOrNull?.symbol ?? '\u20B9',
      decimalDigits: 2,
    );
    final queryParams = (
      startDate: ReportUtils.formatApiDate(appliedStartDate),
      endDate: ReportUtils.formatApiDate(appliedEndDate),
      basis: _purchaseOrdersByItemBasis,
      page: _page,
      pageSize: _pageSize,
    );
    final reportAsync = ref.watch(purchaseOrdersByItemProvider(queryParams));
    final reportData = reportAsync.valueOrNull;
    final rows = PurchaseOrdersByItemRow.fromResponse(reportData);
    final totals = PurchaseOrdersByItemTotals.fromResponse(reportData);
    final pagination = Map<String, dynamic>.from(
      reportData?['pagination'] as Map? ?? const <String, dynamic>{},
    );
    final totalCount = _intValue(
      pagination['totalRecords'] ?? pagination['total'] ?? reportData?['total'],
      rows.length,
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
      categoryLabel: 'Payables',
      reportTitle: _purchaseOrdersByItemTitle,
      dateLabel: dateLabel,
      companyName: '',
      reportHeading: _PurchaseOrdersByItemHeading(dateLabel: dateLabel),
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: startDate,
          initialEndDate: endDate,
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
        onChanged: _markFiltersDirty,
      ),
      isExpandedFilterPanelOpen: _isMoreFiltersOpen,
      onDismissExpandedFilterPanel: _closeMoreFilters,
      showInlineRunReportButton: !_isMoreFiltersOpen,
      hasPendingFilterChanges: _hasPendingFilterChanges,
      showReload: true,
      showSchedule: true,
      onSchedule: () => ReportScheduleDialog.show(
        context,
        reportName: _purchaseOrdersByItemTitle,
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
      settingsTooltip: 'Customize the Purchase Order by Item report.',
      scheduleTooltip: 'Schedule the Purchase Order by Item report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PurchaseOrdersGroupBySection(
            selectedValues: _groupByFields,
            showGroupTotals: _showGroupTotals,
            options: _groupByOptions,
            onApply: _handleGroupByApplied,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 9),
        ],
      ),
      isLoading: reportAsync.isLoading,
      errorMessage: reportAsync.hasError
          ? 'Unable to load report: ${reportAsync.error}'
          : null,
      onRetry: () => ref.invalidate(purchaseOrdersByItemProvider(queryParams)),
      isEmpty: false,
      emptyTitle: 'No data to display',
      emptyMessage: 'No data to display',
      currentNavigationCategory: 'Payables',
      currentNavigationReport: _purchaseOrdersByItemTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _purchaseOrdersByItemTitle && category == 'Payables') {
          return;
        }
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: PurchaseOrdersByItemTable(
        rows: rows,
        totals: totals,
        currencyFormat: currencyFormat,
        dateFormat: dateFormat,
        totalCount: totalCount,
        page: currentPage,
        pageSize: effectivePageSize,
        onPageChanged: _handlePageChanged,
        groupByFields: _groupByFields,
        showGroupTotals: _showGroupTotals,
      ),
    );
  }
}

class _PurchaseOrdersByItemHeading extends StatelessWidget {
  final String dateLabel;

  const _PurchaseOrdersByItemHeading({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const ReportCompanyHeader(companyName: ''),
        const SizedBox(height: AppTheme.space12),
        Text(
          _purchaseOrdersByItemTitle,
          textAlign: TextAlign.center,
          style: AppTheme.pageTitle.copyWith(fontSize: 20),
        ),
        const SizedBox(height: AppTheme.space10),
        Text(
          dateLabel,
          textAlign: TextAlign.center,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PurchaseOrdersGroupBySection extends StatefulWidget {
  final List<String> selectedValues;
  final bool showGroupTotals;
  final List<String> options;
  final void Function(List<String> fields, bool showGroupTotals) onApply;

  const _PurchaseOrdersGroupBySection({
    required this.selectedValues,
    required this.showGroupTotals,
    required this.options,
    required this.onApply,
  });

  @override
  State<_PurchaseOrdersGroupBySection> createState() =>
      _PurchaseOrdersGroupBySectionState();
}

class _PurchaseOrdersGroupBySectionState
    extends State<_PurchaseOrdersGroupBySection> {
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
  void didUpdateWidget(covariant _PurchaseOrdersGroupBySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isOpen) _syncDraftFromWidget();
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                        child: Text(
                          'Purchase Order',
                          style: AppTheme.metaHelper.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      ...items.map(itemBuilder),
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
