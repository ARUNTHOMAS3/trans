import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/reports/presentation/pages/reports_center_screen.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_customize_columns_button.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_date_range_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_entities_filter.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_filter_bar.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_more_filters_panel.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_popup_positioning.dart';
import 'package:zerpai_erp/modules/reports/presentation/widgets/report_view_scaffold.dart';
import 'package:zerpai_erp/modules/reports/receivables/presentation/widgets/receivable_details_table.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class ReceivableDetailsPage extends StatefulWidget {
  const ReceivableDetailsPage({super.key});

  @override
  State<ReceivableDetailsPage> createState() => _ReceivableDetailsPageState();
}

class _ReceivableDetailsPageState extends State<ReceivableDetailsPage> {
  static const String _reportTitle = 'Receivable Details';
  static const String _dateLabel = 'From 01-07-2026 To 31-07-2026';
  static const int _pageSize = 17;
  static final DateTime _dateRangeStartDate = DateTime(2026, 7, 1);
  static final DateTime _dateRangeEndDate = DateTime(2026, 7, 31, 23, 59, 59);

  static const List<ReceivableDetailsRow> _rows = [
    ReceivableDetailsRow(
      customerName: 'CUS-1',
      date: '11-07-2026',
      transactionNumber: 'INV-000094',
      referenceNumber: '[pok00043',
      status: 'Draft',
      transactionType: 'Invoice',
      itemName: 'BATCH TARCK ITEM',
      quantityOrdered: '5.00',
      itemPriceBcy: '\u20B9199.00',
      totalBcy: '\u20B9995.00',
    ),
    ReceivableDetailsRow(
      customerName: 'CUS-1',
      date: '11-07-2026',
      transactionNumber: 'INV-000095',
      referenceNumber: '[pok00042',
      status: 'Draft',
      transactionType: 'Invoice',
      itemName: 'BATCH TARCK ITEM',
      quantityOrdered: '5.00',
      itemPriceBcy: '\u20B9199.00',
      totalBcy: '\u20B9995.00',
    ),
    ReceivableDetailsRow(
      customerName: 'CUS-1',
      date: '11-07-2026',
      transactionNumber: 'INV-000095',
      referenceNumber: '[pok00042',
      status: 'Draft',
      transactionType: 'Invoice',
      itemName: 'BATCH TARCK ITEM',
      quantityOrdered: '10.00',
      itemPriceBcy: '\u20B9199.00',
      totalBcy: '\u20B91,990.00',
    ),
    ReceivableDetailsRow(
      customerName: 'CUS-1',
      date: '11-07-2026',
      transactionNumber: 'INV-000096',
      referenceNumber: '[pok00040',
      status: 'Draft',
      transactionType: 'Invoice',
      itemName: 'BATCH TARCK ITEM',
      quantityOrdered: '5.00',
      itemPriceBcy: '\u20B9199.00',
      totalBcy: '\u20B9995.00',
    ),
    ReceivableDetailsRow(
      customerName: 'althaf m',
      date: '13-07-2026',
      transactionNumber: 'INV-000099',
      referenceNumber: 'SO-00049',
      status: 'Sent',
      transactionType: 'Invoice',
      itemName: 'BATCH TARCK ITEM',
      quantityOrdered: '1.00',
      itemPriceBcy: '\u20B9199.00',
      totalBcy: '\u20B9199.00',
    ),
    ReceivableDetailsRow(
      customerName: 'CUS-1',
      date: '11-07-2026',
      transactionNumber: 'INV-000094',
      referenceNumber: '[pok00043',
      status: 'Draft',
      transactionType: 'Invoice',
      itemName: 'BATCH TRACK 2',
      quantityOrdered: '5.00',
      itemPriceBcy: '\u20B9115.00',
      totalBcy: '\u20B9575.00',
    ),
    ReceivableDetailsRow(
      customerName: 'CUS-1',
      date: '11-07-2026',
      transactionNumber: 'INV-000095',
      referenceNumber: '[pok00042',
      status: 'Draft',
      transactionType: 'Invoice',
      itemName: 'BATCH TRACK 2',
      quantityOrdered: '5.00',
      itemPriceBcy: '\u20B9115.00',
      totalBcy: '\u20B9575.00',
    ),
    ReceivableDetailsRow(
      customerName: 'CUS-1',
      date: '11-07-2026',
      transactionNumber: 'INV-000096',
      referenceNumber: '[pok00040',
      status: 'Draft',
      transactionType: 'Invoice',
      itemName: 'BATCH TRACK 2',
      quantityOrdered: '10.00',
      itemPriceBcy: '\u20B9115.00',
      totalBcy: '\u20B91,150.00',
    ),
    ReceivableDetailsRow(
      customerName: 'CUS-2',
      date: '11-07-2026',
      transactionNumber: 'INV-000097',
      referenceNumber: '202700054',
      status: 'Draft',
      transactionType: 'Invoice',
      itemName: 'BATCH TRACK 2',
      quantityOrdered: '100.00',
      itemPriceBcy: '\u20B9115.00',
      totalBcy: '\u20B911,500.00',
    ),
    ReceivableDetailsRow(
      customerName: 'CUS-1',
      date: '11-07-2026',
      transactionNumber: 'INV-000096',
      referenceNumber: '[pok00040',
      status: 'Draft',
      transactionType: 'Invoice',
      itemName: 'BATCH TRACK 3',
      quantityOrdered: '15.00',
      itemPriceBcy: '\u20B9123.00',
      totalBcy: '\u20B91,845.00',
    ),
    ReceivableDetailsRow(
      customerName: 'althaf m',
      date: '04-07-2026',
      transactionNumber: 'INV-000092',
      referenceNumber: '',
      status: 'Draft',
      transactionType: 'Invoice',
      itemName: 'demo composit item\n1',
      quantityOrdered: '1.00',
      itemPriceBcy: '\u20B9238.00',
      totalBcy: '\u20B9238.00',
    ),
    ReceivableDetailsRow(
      customerName: 'althaf m',
      date: '12-07-2026',
      transactionNumber: 'INV-000098',
      referenceNumber: '',
      status: 'Sent',
      transactionType: 'Invoice',
      itemName: 'demo composit item\n1',
      quantityOrdered: '1.00',
      itemPriceBcy: '\u20B9238.00',
      totalBcy: '\u20B9238.00',
    ),
    ReceivableDetailsRow(
      customerName: 'althaf m',
      date: '13-07-2026',
      transactionNumber: 'RCN-1',
      referenceNumber: '',
      status: 'Open',
      transactionType: 'Credit Note',
      itemName: 'demo composit item\n1',
      quantityOrdered: '-1.00',
      itemPriceBcy: '\u20B9238.00',
      totalBcy: '\u20B9-238.00',
    ),
    ReceivableDetailsRow(
      customerName: 'Walk-in Customer',
      date: '15-07-2026',
      transactionNumber: 'SI-4',
      referenceNumber: '',
      status: 'Paid',
      transactionType: 'Invoice',
      itemName: 'dolo',
      quantityOrdered: '1.00',
      itemPriceBcy: '\u20B9200.00',
      totalBcy: '\u20B9200.00',
    ),
    ReceivableDetailsRow(
      customerName: 'althaf m',
      date: '15-07-2026',
      transactionNumber: 'SI-5',
      referenceNumber: '',
      status: 'Paid',
      transactionType: 'Invoice',
      itemName: 'dolo',
      quantityOrdered: '1.00',
      itemPriceBcy: '\u20B9200.00',
      totalBcy: '\u20B9200.00',
    ),
    ReceivableDetailsRow(
      customerName: 'Walk-in Customer',
      date: '14-07-2026',
      transactionNumber: 'SI-3',
      referenceNumber: '',
      status: 'Paid',
      transactionType: 'Invoice',
      itemName: 'dolo',
      quantityOrdered: '1.00',
      itemPriceBcy: '\u20B9200.00',
      totalBcy: '\u20B9200.00',
    ),
    ReceivableDetailsRow(
      customerName: 'CUS-1',
      date: '11-07-2026',
      transactionNumber: 'INV-000093',
      referenceNumber: '[pok00044',
      status: 'Draft',
      transactionType: 'Invoice',
      itemName: 'test nonbatch',
      quantityOrdered: '10.00',
      itemPriceBcy: '\u20B9100.00',
      totalBcy: '\u20B91,000.00',
    ),
  ];

  bool _isMoreFiltersOpen = false;
  bool _hasPendingFilterChanges = false;
  late final List<String> _entityOptions = _rows
      .map((row) => row.transactionType)
      .where((type) => type.trim().isNotEmpty)
      .toSet()
      .toList(growable: false);
  late List<String> _selectedEntities = List<String>.from(_entityOptions);
  List<String> _groupByFields = const <String>[];
  bool _showOnlyGroupTotals = false;
  bool _showGroupTotals = false;
  int _page = 1;

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

  void _handleEntitiesChanged(List<String> values) {
    setState(() {
      _selectedEntities = List<String>.from(values);
      _hasPendingFilterChanges = true;
    });
  }

  void _handleGroupByApplied(
    List<String> fields,
    bool showOnlyGroupTotals,
    bool showGroupTotals,
  ) {
    setState(() {
      _groupByFields = List<String>.unmodifiable(fields);
      _showOnlyGroupTotals = showOnlyGroupTotals;
      _showGroupTotals = showGroupTotals;
      _hasPendingFilterChanges = true;
    });
  }

  void _runReport() {
    _closeMoreFilters();
    setState(() {
      _page = 1;
      _hasPendingFilterChanges = false;
    });
  }

  void _handlePageChanged(int page) {
    setState(() => _page = page);
  }

  @override
  Widget build(BuildContext context) {
    return ReportViewScaffold(
      categoryLabel: 'Receivables',
      reportTitle: _reportTitle,
      dateLabel: _dateLabel,
      companyName: '',
      filters: [
        ReportDateRangeFilter(
          label: 'Date Range',
          initialStartDate: _dateRangeStartDate,
          initialEndDate: _dateRangeEndDate,
          onChanged: (_) => _markFiltersDirty(),
        ),
        ReportEntitiesFilter(
          options: _entityOptions,
          initialSelection: _selectedEntities,
          onChanged: _handleEntitiesChanged,
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
      settingsTooltip: 'Customize the Receivable Details report.',
      tableHeaderActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ReceivableDetailsGroupBySection(
            selectedValues: _groupByFields,
            showOnlyGroupTotals: _showOnlyGroupTotals,
            showGroupTotals: _showGroupTotals,
            onApply: _handleGroupByApplied,
          ),
          const _HeaderActionDivider(),
          const ReportCustomizeColumnsButton(count: 10),
        ],
      ),
      isLoading: false,
      currentNavigationCategory: 'Receivables',
      currentNavigationReport: 'Receivable Details',
      onReportSelected: (reportName, category) {
        if (reportName == 'Receivable Details') return;
        openReportFromReportsModule(context, reportName);
      },
      reportContent: ReceivableDetailsTable(
        rows: _rows,
        page: _page,
        pageSize: _pageSize,
        onPageChanged: _handlePageChanged,
        groupByFields: _groupByFields,
        showOnlyGroupTotals: _showOnlyGroupTotals,
        showGroupTotals: _showGroupTotals,
      ),
    );
  }
}

class _ReceivableDetailsGroupBySection extends StatefulWidget {
  static const List<String> _options = <String>[
    'Customer Name',
    'Warehouse Location Name',
    'Date',
    'Transaction#',
    'Transaction Type',
    'Item Name',
    'Account',
    'Salesperson',
    'Currency',
    'Created By',
  ];

  final List<String> selectedValues;
  final bool showOnlyGroupTotals;
  final bool showGroupTotals;
  final void Function(List<String>, bool, bool) onApply;

  const _ReceivableDetailsGroupBySection({
    required this.selectedValues,
    required this.showOnlyGroupTotals,
    required this.showGroupTotals,
    required this.onApply,
  });

  @override
  State<_ReceivableDetailsGroupBySection> createState() =>
      _ReceivableDetailsGroupBySectionState();
}

class _ReceivableDetailsGroupBySectionState
    extends State<_ReceivableDetailsGroupBySection> {
  static const double _popupWidth = 302;
  static const double _popupHeight = 300;
  static const double _dropdownWidth = 270;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _draftValues = const <String>[];
  bool _draftShowOnlyGroupTotals = false;
  bool _draftShowGroupTotals = false;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _syncDraftFromWidget();
  }

  @override
  void didUpdateWidget(covariant _ReceivableDetailsGroupBySection oldWidget) {
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
    _draftShowOnlyGroupTotals = widget.showOnlyGroupTotals;
    _draftShowGroupTotals = widget.showGroupTotals;
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
      _draftShowOnlyGroupTotals,
      _draftShowGroupTotals,
    );
    _removeOverlay();
    if (mounted) setState(() {});
  }

  void _setShowOnlyGroupTotals(bool value) {
    setState(() {
      _draftShowOnlyGroupTotals = value;
      if (value) _draftShowGroupTotals = false;
    });
    _markOverlayNeedsBuild();
  }

  void _setShowGroupTotals(bool value) {
    setState(() {
      _draftShowGroupTotals = value;
      if (value) _draftShowOnlyGroupTotals = false;
    });
    _markOverlayNeedsBuild();
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
                items: _ReceivableDetailsGroupBySection._options,
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
                        color: isHovered ? Colors.white : AppTheme.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  );
                },
                listBuilder: (items, itemBuilder) {
                  final reportItems = items.toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (reportItems.isNotEmpty) ...[
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
                        ...reportItems.map(itemBuilder),
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
          _buildDisplayModeCheckbox(
            value: _draftShowOnlyGroupTotals,
            isDisabled: _draftShowGroupTotals,
            onChanged: _setShowOnlyGroupTotals,
            label:
                'Display only the total value of each\ngroup without showing individual\ntransactions',
          ),
          const SizedBox(height: AppTheme.space8),
          _buildDisplayModeCheckbox(
            value: _draftShowGroupTotals,
            isDisabled: _draftShowOnlyGroupTotals,
            onChanged: _setShowGroupTotals,
            label: 'Display the total as a separate row\nbelow each group',
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.space16,
              AppTheme.space12,
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

  Widget _buildDisplayModeCheckbox({
    required bool value,
    required bool isDisabled,
    required ValueChanged<bool> onChanged,
    required String label,
  }) {
    final effectiveColor = isDisabled ? AppTheme.textMuted : AppTheme.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.space12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.space4),
        onTap: isDisabled ? null : () => onChanged(!value),
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
                  value: value,
                  onChanged: isDisabled
                      ? null
                      : (nextValue) => onChanged(nextValue ?? false),
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
                  label,
                  style: AppTheme.bodyText.copyWith(
                    color: effectiveColor,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
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
                style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
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

class _HeaderActionDivider extends StatelessWidget {
  const _HeaderActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: AppTheme.space20,
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.space10),
      color: AppTheme.borderLight,
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
