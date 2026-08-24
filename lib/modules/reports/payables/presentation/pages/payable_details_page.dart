import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/payables/presentation/widgets/payable_details_table.dart';
import 'package:zerpai_erp/modules/reports/presentation/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_entities_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/repositories/reports_repository.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_popup_positioning.dart';

const String _reportTitle = 'Payable Details';

class PayableDetailsRow {
  final String status;
  final DateTime date;
  final String transactionNumber;
  final String vendorName;
  final String transactionType;
  final String itemName;
  final double quantity;
  final double rate;
  final double amount;
  final String currencyCode;
  final String account;
  final String customerName;
  final String warehouseLocationName;
  final String projectName;
  final DateTime? dueDate;
  final DateTime? expectedPaymentDate;

  PayableDetailsRow({
    required this.status,
    required this.date,
    required this.transactionNumber,
    required this.vendorName,
    required this.transactionType,
    required this.itemName,
    required this.quantity,
    required this.rate,
    required this.amount,
    required this.currencyCode,
    required this.account,
    required this.customerName,
    required this.warehouseLocationName,
    required this.projectName,
    this.dueDate,
    this.expectedPaymentDate,
  });
}

typedef PayableDetailsParams = ({
  String startDate,
  String endDate,
  List<String> entities,
  int refreshKey,
});

final payableDetailsRowsProvider =
    FutureProvider.family<List<PayableDetailsRow>, PayableDetailsParams>((
  ref,
  params,
) async {
  final repo = ref.watch(reportsRepositoryProvider);
  final List<Future<List<PayableDetailsRow>>> futures = [];

  DateTime parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString()) ?? DateTime.now();
  }

  DateTime? parseDateTimeNullable(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    return DateTime.tryParse(val.toString());
  }

  double toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  if (params.entities.contains('Bill')) {
    futures.add(repo.getPurchasesByItem(
      startDate: params.startDate,
      endDate: params.endDate,
      limit: 500,
    ).then((res) {
      final List<PayableDetailsRow> list = [];
      final products = res['data'] as List? ?? [];
      for (final p in products) {
        final itemName = p['itemName']?.toString() ?? '-';
        final purchases = p['purchases'] as List? ?? [];
        for (final item in purchases) {
          list.add(PayableDetailsRow(
            status: item['status']?.toString() ?? 'Draft',
            date: parseDateTime(item['billDate']),
            transactionNumber: item['billNumber']?.toString() ?? '',
            vendorName: item['vendorName']?.toString() ?? '',
            transactionType: 'Bill',
            itemName: itemName,
            quantity: toDouble(item['quantity']),
            rate: toDouble(item['rate']),
            amount: toDouble(item['lineTotal']),
            currencyCode: 'INR',
            account: item['paymentTerm']?.toString() ?? '-',
            customerName: '-',
            warehouseLocationName: item['warehouse']?.toString() ?? '-',
            projectName: '-',
            dueDate: parseDateTimeNullable(item['dueDate']),
          ));
        }
      }
      return list;
    }));
  }

  if (params.entities.contains('Vendor Credit') || params.entities.contains('Vendor Credits')) {
    futures.add(repo.getVendorCreditsDetails(
      startDate: params.startDate,
      endDate: params.endDate,
      limit: 500,
    ).then((res) {
      final rows = res['data'] as List? ?? [];
      return rows.map((json) {
        return PayableDetailsRow(
          status: json['status']?.toString() ?? 'Open',
          date: parseDateTime(json['vendorCreditDateRaw'] ?? json['vendorCreditDate']),
          transactionNumber: json['vendorCreditNumber']?.toString() ?? '',
          vendorName: json['vendorName']?.toString() ?? '',
          transactionType: 'Vendor Credit',
          itemName: 'Vendor Credit Item',
          quantity: 1.0,
          rate: toDouble(json['amount']),
          amount: toDouble(json['amount']),
          currencyCode: 'INR',
          account: '-',
          customerName: '-',
          warehouseLocationName: json['warehouse']?.toString() ?? '-',
          projectName: '-',
        );
      }).toList();
    }));
  }

  if (params.entities.contains('Expense')) {
    futures.add(repo.getExpenseDetails(
      startDate: params.startDate,
      endDate: params.endDate,
      limit: 500,
    ).then((res) {
      final rows = res['data'] as List? ?? [];
      return rows.map((json) {
        return PayableDetailsRow(
          status: json['status']?.toString() ?? 'Non-Billable',
          date: parseDateTime(json['date'] ?? json['expenseDate']),
          transactionNumber: json['transactionNumber']?.toString() ?? '',
          vendorName: json['vendorName']?.toString() ?? '',
          transactionType: 'Expense',
          itemName: json['category']?.toString() ?? '-',
          quantity: 1.0,
          rate: toDouble(json['amountValue']),
          amount: toDouble(json['amountWithTaxValue'] ?? json['amountValue']),
          currencyCode: json['currencyCode']?.toString() ?? 'INR',
          account: json['paidThrough']?.toString() ?? '-',
          customerName: json['customerName']?.toString() ?? '-',
          warehouseLocationName: '-',
          projectName: '-',
        );
      }).toList();
    }));
  }

  if (futures.isEmpty) return [];
  final results = await Future.wait(futures);
  final merged = results.expand((x) => x).toList();
  merged.sort((a, b) => b.date.compareTo(a.date));
  return merged;
});

class PayableDetailsPage extends ConsumerStatefulWidget {
  const PayableDetailsPage({super.key});

  @override
  ConsumerState<PayableDetailsPage> createState() => _PayableDetailsPageState();
}

class _PayableDetailsPageState extends ConsumerState<PayableDetailsPage> {
  static const int _pageSize = 10;
  static const List<String> _entityOptions = <String>[
    'Bill',
    'Vendor Credit',
    'Expense',
  ];

  static const List<String> _groupByOptions = <String>[
    'Date',
    'Transaction#',
    'Vendor Name',
    'Transaction Type',
    'Item Name',
    'Account',
    'Customer Name',
    'Warehouse Location Name',
    'Project Name',
    'Currency Code',
    'Location',
    'Due Date',
    'Expected Payment Date',
  ];

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  ReportDateRangeSelection? _dateRangeSelection;
  List<String> _selectedEntities = <String>['Bill'];
  List<String> _groupByFields = <String>[];
  bool _showGroupTotals = false;
  bool _groupTotalsOnly = false;
  int _page = 1;
  int _refreshKey = 0;

  ReportDateRangeSelection get _effectiveDateRangeSelection =>
      _dateRangeSelection ??
      ReportDateRangeSelection(
        startDate: DateTime(2025, 4, 1),
        endDate: DateTime(2026, 3, 31, 23, 59, 59),
        label: ReportDateRangePresets.previousYear,
      );

  String get _dateLabel {
    final selection = _effectiveDateRangeSelection;
    final formatter = DateFormat('dd-MM-yyyy');
    return 'From ${formatter.format(selection.startDate)} To ${formatter.format(selection.endDate)}';
  }

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

  void _handleGroupByApplied(
    List<String> fields,
    bool showGroupTotals,
    bool groupTotalsOnly,
  ) {
    setState(() {
      _groupByFields = fields;
      _showGroupTotals = showGroupTotals;
      _groupTotalsOnly = groupTotalsOnly;
      _hasPendingFilterChanges = true;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _page = 1;
      _refreshKey++;
      _hasPendingFilterChanges = false;
    });
  }

  void _handlePageChanged(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    final dateRangeSelection = _effectiveDateRangeSelection;
    final params = (
      startDate: DateFormat('yyyy-MM-dd').format(dateRangeSelection.startDate),
      endDate: DateFormat('yyyy-MM-dd').format(dateRangeSelection.endDate),
      entities: _selectedEntities,
      refreshKey: _refreshKey,
    );

    final rowsAsync = ref.watch(payableDetailsRowsProvider(params));
    final rows = rowsAsync.valueOrNull ?? const <PayableDetailsRow>[];

    return ReportViewScaffold(
      categoryLabel: 'Payables',
      reportTitle: _reportTitle,
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          initialStartDate: dateRangeSelection.startDate,
          initialEndDate: dateRangeSelection.endDate,
          onChanged: (selection) {
            setState(() {
              _dateRangeSelection = selection;
              _hasPendingFilterChanges = true;
            });
          },
        ),
        ReportEntitiesFilter(
          options: _entityOptions,
          initialSelection: _selectedEntities,
          onChanged: (selection) {
            setState(() {
              _selectedEntities = selection;
              _hasPendingFilterChanges = true;
            });
          },
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
      settingsTooltip: 'Customize the Payable Details report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PayableDetailsGroupBySection(
            selectedValues: _groupByFields,
            showGroupTotals: _showGroupTotals,
            groupTotalsOnly: _groupTotalsOnly,
            options: _groupByOptions,
            onApply: _handleGroupByApplied,
          ),
          const SizedBox(width: AppTheme.space10),
          const ReportCustomizeColumnsButton(count: 9),
        ],
      ),
      isLoading: rowsAsync.isLoading && !rowsAsync.hasValue,
      errorMessage: rowsAsync.hasError ? rowsAsync.error.toString() : null,
      onRetry: _runReport,
      currentNavigationCategory: 'Payables',
      currentNavigationReport: _reportTitle,
      onReportSelected: (reportName, category) {
        if (reportName == _reportTitle && category == 'Payables') {
          return;
        }
        openReportFromReportsModule(context, reportName, category: category);
      },
      reportContent: PayableDetailsTable(
        rows: rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        groupByFields: _groupByFields,
        showGroupTotals: _showGroupTotals,
        groupTotalsOnly: _groupTotalsOnly,
      ),
    );
  }
}

class _PayableDetailsGroupBySection extends StatefulWidget {
  final List<String> selectedValues;
  final bool showGroupTotals;
  final bool groupTotalsOnly;
  final List<String> options;
  final void Function(
    List<String> fields,
    bool showGroupTotals,
    bool groupTotalsOnly,
  ) onApply;

  const _PayableDetailsGroupBySection({
    required this.selectedValues,
    required this.showGroupTotals,
    required this.groupTotalsOnly,
    required this.options,
    required this.onApply,
  });

  @override
  State<_PayableDetailsGroupBySection> createState() =>
      _PayableDetailsGroupBySectionState();
}

class _PayableDetailsGroupBySectionState
    extends State<_PayableDetailsGroupBySection> {
  static const double _popupWidth = 302;
  static const double _popupHeight = 290;
  static const double _dropdownWidth = 270;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _draftValues = const <String>[];
  bool _draftShowTotals = false;
  bool _draftTotalsOnly = false;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _syncDraftFromWidget();
  }

  @override
  void didUpdateWidget(covariant _PayableDetailsGroupBySection oldWidget) {
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
    _draftTotalsOnly = widget.groupTotalsOnly;
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
    widget.onApply(
      List<String>.unmodifiable(_draftValues),
      _draftShowTotals,
      _draftTotalsOnly,
    );
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
                  final reportsItems = items
                      .where((item) => const [
                            'Date',
                            'Transaction#',
                            'Vendor Name',
                            'Transaction Type',
                            'Item Name',
                            'Account',
                            'Customer Name',
                            'Warehouse Location Name',
                            'Project Name',
                            'Currency Code'
                          ].contains(item))
                      .toList(growable: false);
                  final locationsItems = items
                      .where((item) => const [
                            'Location'
                          ].contains(item))
                      .toList(growable: false);
                  final billItems = items
                      .where((item) => const [
                            'Due Date',
                            'Expected Payment Date'
                          ].contains(item))
                      .toList(growable: false);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reportsItems.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          child: Text(
                            'Reports',
                            style: AppTheme.metaHelper.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        ...reportsItems.map(itemBuilder),
                      ],
                      if (locationsItems.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          child: Text(
                            'Locations',
                            style: AppTheme.metaHelper.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        ...locationsItems.map(itemBuilder),
                      ],
                      if (billItems.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          child: Text(
                            'Bill',
                            style: AppTheme.metaHelper.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        ...billItems.map(itemBuilder),
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
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space4),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.space4),
              onTap: () {
                setState(() => _draftTotalsOnly = !_draftTotalsOnly);
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
                        value: _draftTotalsOnly,
                        onChanged: (value) {
                          setState(() => _draftTotalsOnly = value ?? false);
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
                        'Display only the total value of each group\nwithout showing individual transactions',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12, vertical: AppTheme.space4),
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
