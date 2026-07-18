import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import '../../models/stock_count_model.dart';
import '../../providers/stock_count_provider.dart';

class RecurringStockCountReportPage extends ConsumerStatefulWidget {
  const RecurringStockCountReportPage({super.key});

  @override
  ConsumerState<RecurringStockCountReportPage> createState() =>
      _RecurringStockCountReportPageState();
}

class _RecurringStockCountReportPageState
    extends ConsumerState<RecurringStockCountReportPage> {
  String? _assignedToFilter = 'All';
  String? _statusFilter = 'All';
  String? _scheduleTypeFilter = 'All';
  String? _locationFilter = 'All';
  String _sortByField = 'Stock Count Name';
  bool _sortAscending = true;
  OverlayEntry? _assignedToOverlayEntry;
  final LayerLink _assignedToLayerLink = LayerLink();
  bool _isAssignedToMenuOpen = false;
  String _tempSearchUserQuery = '';
  String? _tempAssignedToFilter;

  OverlayEntry? _statusOverlayEntry;
  final LayerLink _statusLayerLink = LayerLink();
  bool _isStatusMenuOpen = false;
  String _tempSearchStatusQuery = '';

  OverlayEntry? _scheduleTypeOverlayEntry;
  final LayerLink _scheduleTypeLayerLink = LayerLink();
  bool _isScheduleTypeMenuOpen = false;
  String _tempSearchScheduleTypeQuery = '';

  OverlayEntry? _locationOverlayEntry;
  final LayerLink _locationLayerLink = LayerLink();
  bool _isLocationMenuOpen = false;
  String _tempSearchLocationQuery = '';
  String? _tempLocationFilter;

  final Map<String, double> _columnWidths = {
    'STOCK COUNT NAME': 220.0,
    'STOCK COUNT #': 160.0,
    'ASSIGNED TO': 280.0,
    'STATUS': 180.0,
    'SCHEDULE TYPE': 180.0,
    'LOCATION': 220.0,
    'START DATE': 160.0,
    'EXPIRES AFTER': 160.0,
    'COUNT GENERATION TIME': 220.0,
    'NEXT COUNT DATE': 180.0,
    'TOTAL ITEMS': 140.0,
    'ACCURACY': 140.0,
  };
  OverlayEntry? _settingsOverlayEntry;
  LayerLink? __settingsLayerLink;
  LayerLink get _settingsLayerLink => __settingsLayerLink ??= LayerLink();
  bool _isSettingsOpen = false;
  bool _clipText = false;
  List<ColumnConfig> _columns = [
    ColumnConfig(
      id: 'STOCK COUNT NAME',
      label: 'Stock Count Name',
      isLocked: true,
      orderIndex: 0,
    ),
    ColumnConfig(id: 'STOCK COUNT #', label: 'Stock Count #', orderIndex: 1),
    ColumnConfig(id: 'ASSIGNED TO', label: 'Assigned To', orderIndex: 2),
    ColumnConfig(id: 'STATUS', label: 'Status', orderIndex: 3),
    ColumnConfig(id: 'SCHEDULE TYPE', label: 'Schedule Type', orderIndex: 4),
    ColumnConfig(id: 'LOCATION', label: 'Location', orderIndex: 5),
    ColumnConfig(id: 'START DATE', label: 'Start Date', orderIndex: 6),
    ColumnConfig(id: 'EXPIRES AFTER', label: 'Expires After', orderIndex: 7),
    ColumnConfig(
      id: 'COUNT GENERATION TIME',
      label: 'Count Generation Time',
      orderIndex: 8,
    ),
    ColumnConfig(
      id: 'NEXT COUNT DATE',
      label: 'Next Count Date',
      orderIndex: 9,
    ),
    ColumnConfig(id: 'TOTAL ITEMS', label: 'Total Items', orderIndex: 10),
    ColumnConfig(id: 'ACCURACY', label: 'Accuracy', orderIndex: 11),
  ];
  OverlayEntry? _moreMenuOverlayEntry;
  final LayerLink _moreMenuLayerLink = LayerLink();
  bool _isMoreMenuOpen = false;
  bool _isSortByOpen = false;

  List<String> _assignedToOptions(List<StockCount> counts) {
    final values = counts
        .map((count) => count.assignedTo.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  List<String> _locationOptions(List<StockCount> counts) {
    final values = counts
        .map((count) => (count.location ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  List<String> _scheduleTypeOptions(List<StockCount> counts) {
    final values = counts
        .map((count) => (count.scheduleType ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...values];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stockCountsProvider.notifier).fetchCounts();
    });
  }

  @override
  void deactivate() {
    _closeAssignedToOverlay();
    _closeStatusOverlay();
    _closeScheduleTypeOverlay();
    _closeLocationOverlay();
    _closeSettingsOverlay();
    _closeMoreMenuOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _closeAssignedToOverlay();
    _closeStatusOverlay();
    _closeScheduleTypeOverlay();
    _closeLocationOverlay();
    _closeSettingsOverlay();
    _closeMoreMenuOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orgId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    final dateF = DateFormat('dd-MM-yyyy');
    final recurringCounts =
        ref
            .watch(stockCountsProvider)
            .counts
            .where((count) => count.isRecurring)
            .where((count) {
              if (_assignedToFilter != null &&
                  _assignedToFilter != 'All' &&
                  count.assignedTo != _assignedToFilter) {
                return false;
              }
              if (_statusFilter != null && _statusFilter != 'All') {
                final statusVal = StockCountStatus.fromLabel(_statusFilter!);
                if (count.status != statusVal) return false;
              }
              if (_scheduleTypeFilter != null &&
                  _scheduleTypeFilter != 'All' &&
                  count.scheduleType != _scheduleTypeFilter) {
                return false;
              }
              if (_locationFilter != null &&
                  _locationFilter != 'All' &&
                  _locationFilter != 'None' &&
                  _locationFilter!.trim().isNotEmpty) {
                final locs = _locationFilter!
                    .split(',')
                    .where((x) => x.isNotEmpty)
                    .toList();
                if (locs.isNotEmpty && !locs.contains(count.location ?? '')) {
                  return false;
                }
              }
              return true;
            })
            .toList()
          ..sort((a, b) {
            int cmp = 0;
            switch (_sortByField) {
              case 'Assigned To':
                cmp = a.assignedTo.toLowerCase().compareTo(
                  b.assignedTo.toLowerCase(),
                );
                break;
              case 'Status':
                final aStatus = a.isActive ? 'active' : 'inactive';
                final bStatus = b.isActive ? 'active' : 'inactive';
                cmp = aStatus.compareTo(bStatus);
                break;
              case 'Schedule Type':
                cmp = (a.frequency ?? 'Custom').toLowerCase().compareTo(
                  (b.frequency ?? 'Custom').toLowerCase(),
                );
                break;
              case 'Next Count Date':
                cmp = (a.nextCountDate ?? DateTime(1900)).compareTo(
                  b.nextCountDate ?? DateTime(1900),
                );
                break;
              case 'Total Items':
                cmp = a.totalItems.compareTo(b.totalItems);
                break;
              case 'Stock Count Name':
              default:
                final aName = a.recurringName?.trim().isNotEmpty == true
                    ? a.recurringName!
                    : a.stockCountNum;
                final bName = b.recurringName?.trim().isNotEmpty == true
                    ? b.recurringName!
                    : b.stockCountNum;
                cmp = aName.toLowerCase().compareTo(bName.toLowerCase());
                break;
            }
            return _sortAscending ? cmp : -cmp;
          });

    final recurringSourceCounts = ref
        .watch(stockCountsProvider)
        .counts
        .where((count) => count.isRecurring)
        .toList();
    final assignedToOptions = _assignedToOptions(recurringSourceCounts);
    final locationOptions = _locationOptions(recurringSourceCounts);
    final scheduleTypeOptions = _scheduleTypeOptions(recurringSourceCounts);

    return ZerpaiLayout(
      pageTitle: '',
      useTopPadding: false,
      useHorizontalPadding: false,
      enableBodyScroll: false,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 20),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () =>
                          context.go('/$orgId${AppRoutes.stockCounts}'),
                      icon: const Icon(LucideIcons.chevronLeft, size: 18),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Stock Counts',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Recurring Stock Counts',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => context.go(
                      '/$orgId${AppRoutes.stockCountsCreate}?recurring=true',
                    ),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22A95E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(LucideIcons.plus, size: 14, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'New',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CompositedTransformTarget(
                    link: _moreMenuLayerLink,
                    child: InkWell(
                      onTap: _toggleMoreMenuOverlay,
                      hoverColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.moreHorizontal,
                          size: 18,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB)),
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    'VIEW BY:  ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  CompositedTransformTarget(
                    link: _assignedToLayerLink,
                    child: InkWell(
                      onTap: () => _toggleAssignedToOverlay(assignedToOptions),
                      hoverColor: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Assigned To: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            _assignedToFilter ?? 'All',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isAssignedToMenuOpen
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 12,
                            color: const Color(0xFF111827),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  CompositedTransformTarget(
                    link: _statusLayerLink,
                    child: InkWell(
                      onTap: _toggleStatusOverlay,
                      hoverColor: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            _statusFilter ?? 'All',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isStatusMenuOpen
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 12,
                            color: const Color(0xFF111827),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  CompositedTransformTarget(
                    link: _scheduleTypeLayerLink,
                    child: InkWell(
                      onTap: () =>
                          _toggleScheduleTypeOverlay(scheduleTypeOptions),
                      hoverColor: Colors.transparent,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Schedule Type: ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          Text(
                            _scheduleTypeFilter ?? 'All',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isScheduleTypeMenuOpen
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 12,
                            color: const Color(0xFF111827),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  CompositedTransformTarget(
                    link: _locationLayerLink,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () => _toggleLocationOverlay(locationOptions),
                          hoverColor: Colors.transparent,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Location: ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              Builder(builder: (context) {
                                final locFilter = _locationFilter;
                                String displayText;
                                if (locFilter == null ||
                                    locFilter == 'None' ||
                                    locFilter.isEmpty) {
                                  displayText = 'None';
                                } else {
                                  final selected = locFilter
                                      .split(',')
                                      .where((x) => x.isNotEmpty)
                                      .toList();
                                  displayText = selected.length ==
                                          locationOptions
                                              .where((value) => value != 'All')
                                              .length &&
                                          locationOptions.length > 1
                                      ? 'All'
                                      : locFilter;
                                }
                                return Text(
                                  displayText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                        if (_locationFilter != null &&
                            _locationFilter != 'None' &&
                            _locationFilter != 'All') ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _locationFilter = 'None';
                              });
                            },
                            child: const Icon(
                              LucideIcons.x,
                              size: 14,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _toggleLocationOverlay(locationOptions),
                          hoverColor: Colors.transparent,
                          child: Icon(
                            _isLocationMenuOpen
                                ? LucideIcons.chevronUp
                                : LucideIcons.chevronDown,
                            size: 12,
                            color: const Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final activeCols =
                            _columns.where((c) => c.isVisible).toList()..sort(
                              (a, b) => a.orderIndex.compareTo(b.orderIndex),
                            );
                        final totalColsWidth =
                            activeCols.fold<double>(
                              0,
                              (sum, col) =>
                                  sum + (_columnWidths[col.id] ?? 120.0),
                            ) +
                            64.0;
                        final tableWidth = constraints.maxWidth > totalColsWidth
                            ? constraints.maxWidth
                            : totalColsWidth;

                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            height: constraints.maxHeight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Container(
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF9FAFB),
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      CompositedTransformTarget(
                                        link: _settingsLayerLink,
                                        child: InkWell(
                                          onTap: _toggleSettingsOverlay,
                                          hoverColor: Colors.transparent,
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 4,
                                            ),
                                            child: Icon(
                                              LucideIcons.settings2,
                                              size: 18,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      ...activeCols.map(
                                        (col) => _buildTableHeaderCell(
                                          col.label.toUpperCase(),
                                          _columnWidths[col.id] ?? 120.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: ListView.separated(
                                    padding: EdgeInsets.zero,
                                    itemCount: recurringCounts.length,
                                    separatorBuilder: (_, __) => const Divider(
                                      height: 1,
                                      color: Color(0xFFE5E7EB),
                                    ),
                                    itemBuilder: (context, index) {
                                      final count = recurringCounts[index];
                                      final name =
                                          count.recurringName
                                                  ?.trim()
                                                  .isNotEmpty ==
                                              true
                                          ? count.recurringName!
                                          : count.stockCountNum;
                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () => context.go(
                                            '/$orgId${AppRoutes.stockCountsDetail.replaceFirst(':id', count.id)}',
                                          ),
                                          hoverColor: const Color(0xFFF9FAFB),
                                          child: SizedBox(
                                            height: 48,
                                            child: Row(
                                              children: [
                                                const SizedBox(width: 56),
                                                ...activeCols.map((col) {
                                                  final colWidth =
                                                      _columnWidths[col.id] ??
                                                      120.0;
                                                  switch (col.id) {
                                                    case 'STOCK COUNT NAME':
                                                      return _buildTableCell(
                                                        Text(
                                                          name,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                  0xFF567FE1,
                                                                ),
                                                              ),
                                                          maxLines: _clipText
                                                              ? 1
                                                              : null,
                                                          overflow: _clipText
                                                              ? TextOverflow
                                                                    .ellipsis
                                                              : TextOverflow
                                                                    .clip,
                                                        ),
                                                        colWidth,
                                                      );
                                                    case 'STOCK COUNT #':
                                                      return _buildTableCell(
                                                        Text(
                                                          count.stockCountNum,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF111827,
                                                                ),
                                                              ),
                                                          maxLines: _clipText
                                                              ? 1
                                                              : null,
                                                          overflow: _clipText
                                                              ? TextOverflow
                                                                    .ellipsis
                                                              : TextOverflow
                                                                    .clip,
                                                        ),
                                                        colWidth,
                                                      );
                                                    case 'ASSIGNED TO':
                                                      return _buildTableCell(
                                                        Row(
                                                          children: [
                                                            Container(
                                                              width: 24,
                                                              height: 24,
                                                              decoration: BoxDecoration(
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                  color: const Color(
                                                                    0xFFD1D5DB,
                                                                  ),
                                                                ),
                                                                color:
                                                                    const Color(
                                                                      0xFFF3F4F6,
                                                                    ),
                                                              ),
                                                              child: const Icon(
                                                                LucideIcons
                                                                    .user,
                                                                size: 12,
                                                                color: Color(
                                                                  0xFF9CA3AF,
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              width: 8,
                                                            ),
                                                            Expanded(
                                                              child: Text(
                                                                count
                                                                    .assignedTo,
                                                                style: const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Color(
                                                                    0xFF111827,
                                                                  ),
                                                                ),
                                                                maxLines:
                                                                    _clipText
                                                                    ? 1
                                                                    : null,
                                                                overflow:
                                                                    _clipText
                                                                    ? TextOverflow
                                                                          .ellipsis
                                                                    : TextOverflow
                                                                          .clip,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        colWidth,
                                                      );
                                                    case 'LOCATION':
                                                      return _buildTableCell(
                                                        Text(
                                                          count.location
                                                                      ?.trim()
                                                                      .isNotEmpty ==
                                                                  true
                                                              ? count.location!
                                                              : '-',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF111827,
                                                                ),
                                                              ),
                                                          maxLines: _clipText
                                                              ? 1
                                                              : null,
                                                          overflow: _clipText
                                                              ? TextOverflow
                                                                    .ellipsis
                                                              : TextOverflow
                                                                    .clip,
                                                        ),
                                                        colWidth,
                                                      );
                                                    case 'START DATE':
                                                      return _buildTableCell(
                                                        Text(
                                                          dateF.format(
                                                            count.scheduleStartDate ??
                                                                count.countDate,
                                                          ),
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF111827,
                                                                ),
                                                              ),
                                                        ),
                                                        colWidth,
                                                      );
                                                    case 'EXPIRES AFTER':
                                                      return _buildTableCell(
                                                        Text(
                                                          count.scheduleExpiry
                                                                      ?.trim()
                                                                      .isNotEmpty ==
                                                                  true
                                                              ? count
                                                                    .scheduleExpiry!
                                                              : '-',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF111827,
                                                                ),
                                                              ),
                                                          maxLines: _clipText
                                                              ? 1
                                                              : null,
                                                          overflow: _clipText
                                                              ? TextOverflow
                                                                    .ellipsis
                                                              : TextOverflow
                                                                    .clip,
                                                        ),
                                                        colWidth,
                                                      );
                                                    case 'COUNT GENERATION TIME':
                                                      return _buildTableCell(
                                                        Text(
                                                          count.countGenerationTime
                                                                      ?.trim()
                                                                      .isNotEmpty ==
                                                                  true
                                                              ? count
                                                                    .countGenerationTime!
                                                              : '-',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF111827,
                                                                ),
                                                              ),
                                                          maxLines: _clipText
                                                              ? 1
                                                              : null,
                                                          overflow: _clipText
                                                              ? TextOverflow
                                                                    .ellipsis
                                                              : TextOverflow
                                                                    .clip,
                                                        ),
                                                        colWidth,
                                                      );
                                                    case 'STATUS':
                                                      return _buildTableCell(
                                                        Text(
                                                          count.isActive
                                                              ? 'ACTIVE'
                                                              : 'INACTIVE',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color:
                                                                count.isActive
                                                                ? const Color(
                                                                    0xFF22A95E,
                                                                  )
                                                                : const Color(
                                                                    0xFF6B7280,
                                                                  ),
                                                          ),
                                                        ),
                                                        colWidth,
                                                      );
                                                    case 'ACCURACY':
                                                      return _buildTableCell(
                                                        Text(
                                                          count.accuracy != null
                                                              ? '${count.accuracy!.toStringAsFixed(1)}%'
                                                              : '-',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF111827,
                                                                ),
                                                              ),
                                                        ),
                                                        colWidth,
                                                      );
                                                    case 'SCHEDULE TYPE':
                                                      return _buildTableCell(
                                                        Text(
                                                          count.frequency ??
                                                              'Custom',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF111827,
                                                                ),
                                                              ),
                                                          maxLines: _clipText
                                                              ? 1
                                                              : null,
                                                          overflow: _clipText
                                                              ? TextOverflow
                                                                    .ellipsis
                                                              : TextOverflow
                                                                    .clip,
                                                        ),
                                                        colWidth,
                                                      );
                                                    case 'NEXT COUNT DATE':
                                                      return _buildTableCell(
                                                        Text(
                                                          count.nextCountDate !=
                                                                  null
                                                              ? dateF.format(
                                                                  count
                                                                      .nextCountDate!,
                                                                )
                                                              : '-',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                color: Color(
                                                                  0xFF111827,
                                                                ),
                                                              ),
                                                        ),
                                                        colWidth,
                                                      );
                                                    case 'TOTAL ITEMS':
                                                      return _buildTableCell(
                                                        Align(
                                                          alignment: Alignment
                                                              .centerRight,
                                                          child: Text(
                                                            '${count.totalItems}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 13,
                                                                  color: Color(
                                                                    0xFF111827,
                                                                  ),
                                                                ),
                                                          ),
                                                        ),
                                                        colWidth,
                                                      );
                                                    default:
                                                      return _buildTableCell(
                                                        const SizedBox.shrink(),
                                                        colWidth,
                                                      );
                                                  }
                                                }),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAssignedToOverlay(List<String> options) {
    if (_isAssignedToMenuOpen) {
      _closeAssignedToOverlay();
    } else {
      _showAssignedToOverlay(options);
    }
  }

  void _showAssignedToOverlay(List<String> options) {
    if (_assignedToOverlayEntry != null) return;
    _tempAssignedToFilter = _assignedToFilter == 'All'
        ? null
        : _assignedToFilter;
    _tempSearchUserQuery = '';

    _assignedToOverlayEntry = OverlayEntry(
      builder: (context) => _buildCheckboxFilterOverlay(
        link: _assignedToLayerLink,
        getSearchQuery: () => _tempSearchUserQuery,
        onSearchChanged: (val, setStateOverlay) {
          setStateOverlay(() => _tempSearchUserQuery = val);
        },
        options: options.where((option) => option != 'All').toList(),
        getSelectedValue: () => _tempAssignedToFilter,
        allLabel: 'All',
        onClearSelection: (setStateOverlay) {
          setStateOverlay(() => _tempAssignedToFilter = null);
        },
        onOptionToggle: (value, setStateOverlay) {
          setStateOverlay(() {
            _tempAssignedToFilter = _tempAssignedToFilter == value
                ? null
                : value;
          });
        },
        onApply: () {
          setState(() {
            _assignedToFilter = _tempAssignedToFilter ?? 'All';
          });
          _closeAssignedToOverlay();
        },
        onClose: _closeAssignedToOverlay,
      ),
    );

    setState(() => _isAssignedToMenuOpen = true);
    Overlay.of(context).insert(_assignedToOverlayEntry!);
  }

  void _closeAssignedToOverlay() {
    if (_assignedToOverlayEntry != null) {
      _assignedToOverlayEntry!.remove();
      _assignedToOverlayEntry = null;
      if (mounted) setState(() => _isAssignedToMenuOpen = false);
    }
  }

  void _toggleStatusOverlay() {
    if (_isStatusMenuOpen) {
      _closeStatusOverlay();
    } else {
      _showStatusOverlay();
    }
  }

  void _showStatusOverlay() {
    if (_statusOverlayEntry != null) return;
    _tempSearchStatusQuery = '';

    final statusOptions = [
      'All',
      'Yet To Start',
      'Counting In Progress',
      'Pending Approval',
      'Completed',
      'Cancelled',
      'Expired',
    ];
    _statusOverlayEntry = OverlayEntry(
      builder: (context) => _buildSingleSelectFilterOverlay(
        link: _statusLayerLink,
        getSearchQuery: () => _tempSearchStatusQuery,
        onSearchChanged: (val, setStateOverlay) {
          setStateOverlay(() => _tempSearchStatusQuery = val);
        },
        options: statusOptions,
        getSelectedValue: () => _statusFilter ?? 'All',
        onSelected: (value) {
          setState(() => _statusFilter = value);
          _closeStatusOverlay();
        },
        onClose: _closeStatusOverlay,
      ),
    );

    setState(() => _isStatusMenuOpen = true);
    Overlay.of(context).insert(_statusOverlayEntry!);
  }

  void _closeStatusOverlay() {
    if (_statusOverlayEntry != null) {
      _statusOverlayEntry!.remove();
      _statusOverlayEntry = null;
      if (mounted) setState(() => _isStatusMenuOpen = false);
    }
  }

  void _toggleScheduleTypeOverlay(List<String> options) {
    if (_isScheduleTypeMenuOpen) {
      _closeScheduleTypeOverlay();
    } else {
      _showScheduleTypeOverlay(options);
    }
  }

  void _showScheduleTypeOverlay(List<String> options) {
    if (_scheduleTypeOverlayEntry != null) return;
    _tempSearchScheduleTypeQuery = '';

    _scheduleTypeOverlayEntry = OverlayEntry(
      builder: (context) => _buildSingleSelectFilterOverlay(
        link: _scheduleTypeLayerLink,
        getSearchQuery: () => _tempSearchScheduleTypeQuery,
        onSearchChanged: (val, setStateOverlay) {
          setStateOverlay(() => _tempSearchScheduleTypeQuery = val);
        },
        options: options,
        getSelectedValue: () => _scheduleTypeFilter ?? 'All',
        onSelected: (value) {
          setState(() => _scheduleTypeFilter = value);
          _closeScheduleTypeOverlay();
        },
        onClose: _closeScheduleTypeOverlay,
      ),
    );
    setState(() => _isScheduleTypeMenuOpen = true);
    Overlay.of(context).insert(_scheduleTypeOverlayEntry!);
  }

  void _closeScheduleTypeOverlay() {
    if (_scheduleTypeOverlayEntry != null) {
      _scheduleTypeOverlayEntry!.remove();
      _scheduleTypeOverlayEntry = null;
      if (mounted) setState(() => _isScheduleTypeMenuOpen = false);
    }
  }

  void _toggleLocationOverlay(List<String> options) {
    if (_isLocationMenuOpen) {
      _closeLocationOverlay();
    } else {
      _showLocationOverlay(options);
    }
  }

  void _showLocationOverlay(List<String> options) {
    if (_locationOverlayEntry != null) return;
    _tempLocationFilter =
        (_locationFilter == 'All' || _locationFilter == 'None')
            ? null
            : _locationFilter;
    _tempSearchLocationQuery = '';
    final locations = options.where((value) => value != 'All').toList();

    _locationOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeLocationOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _locationLayerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (context, setStateOverlay) {
                    final filteredLocs = options
                        .where((value) => value != 'All')
                        .where(
                          (l) => l.toLowerCase().contains(
                            _tempSearchLocationQuery.toLowerCase(),
                          ),
                        )
                        .toList();

                    return Container(
                      width: 260,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search Input Box
                          Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFF93C5FD),
                              ),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 8),
                                const Icon(
                                  LucideIcons.search,
                                  size: 14,
                                  color: Color(0xFF9CA3AF),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    style: const TextStyle(fontSize: 13),
                                    decoration: const InputDecoration(
                                      hintText: 'Search',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      border: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    onChanged: (val) {
                                      setStateOverlay(() {
                                        _tempSearchLocationQuery = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // "All" option row
                          (() {
                            bool isAllHovered = false;
                            return StatefulBuilder(
                              builder: (context, setStateAllHover) {
                              final isAllChecked =
                                  (_tempLocationFilter != null &&
                                  _tempLocationFilter != 'None' &&
                                  _tempLocationFilter!.trim().isNotEmpty &&
                                  _tempLocationFilter!
                                          .split(',')
                                          .where((x) => x.isNotEmpty)
                                          .length ==
                                      locations.length);
                                return InkWell(
                                    onTap: () {
                                      setStateOverlay(() {
                                        final selectedList =
                                            (_tempLocationFilter == null ||
                                                _tempLocationFilter == 'None' ||
                                                _tempLocationFilter!
                                                    .trim()
                                                    .isEmpty)
                                            ? <String>[]
                                            : _tempLocationFilter!
                                                  .split(',')
                                                  .where(
                                                    (x) => x.isNotEmpty,
                                                  )
                                                  .toList();
                                        if (selectedList.length ==
                                            locations.length) {
                                          _tempLocationFilter = null;
                                        } else {
                                          _tempLocationFilter = locations.join(
                                            ',',
                                          );
                                        }
                                      });
                                    },
                                    onHover: (val) {
                                      setStateAllHover(() {
                                        isAllHovered = val;
                                      });
                                    },
                                    hoverColor: Colors.transparent,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isAllHovered
                                            ? const Color(0xFF2563EB)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: Checkbox(
                                              value: isAllChecked,
                                              activeColor: isAllHovered
                                                  ? Colors.white
                                                  : const Color(0xFF2563EB),
                                              checkColor: isAllHovered
                                                  ? const Color(0xFF2563EB)
                                                  : Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              side: BorderSide(
                                                color: isAllHovered
                                                    ? Colors.white
                                                    : const Color(0xFFCCCCCC),
                                                width: 1.5,
                                              ),
                                              onChanged: (val) {
                                                setStateOverlay(() {
                                                  if (val == true) {
                                                    _tempLocationFilter =
                                                        locations.join(',');
                                                  } else {
                                                    _tempLocationFilter = null;
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'All',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isAllHovered
                                                    ? Colors.white
                                                    : const Color(0xFF4B5563),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                );
                              },
                            );
                          })(),
                          // List of locations
                          ...filteredLocs.map((loc) {
                            final selectedList =
                                (_tempLocationFilter == null ||
                                    _tempLocationFilter == 'None' ||
                                    _tempLocationFilter!.trim().isEmpty)
                                ? <String>[]
                                : _tempLocationFilter!
                                      .split(',')
                                      .where((x) => x.isNotEmpty)
                                      .toList();
                            final isLocChecked = selectedList.contains(loc);
                            bool isLocHovered = false;
                            return StatefulBuilder(
                              builder: (context, setStateItem) {
                                return InkWell(
                                  onTap: () {
                                    setStateOverlay(() {
                                      if (isLocChecked) {
                                        selectedList.remove(loc);
                                      } else {
                                        selectedList.add(loc);
                                      }
                                      if (selectedList.isEmpty) {
                                        _tempLocationFilter = null;
                                      } else {
                                        _tempLocationFilter = selectedList.join(
                                          ',',
                                        );
                                      }
                                    });
                                  },
                                  onHover: (val) {
                                    setStateItem(() {
                                      isLocHovered = val;
                                    });
                                  },
                                  hoverColor: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isLocHovered
                                          ? const Color(0xFF2563EB)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: Checkbox(
                                            value: isLocChecked,
                                            activeColor: isLocHovered
                                                ? Colors.white
                                                : const Color(0xFF2563EB),
                                            checkColor: isLocHovered
                                                ? const Color(0xFF2563EB)
                                                : Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            side: BorderSide(
                                              color: isLocHovered
                                                  ? Colors.white
                                                  : const Color(0xFFCCCCCC),
                                              width: 1.5,
                                            ),
                                            onChanged: (val) {
                                              setStateOverlay(() {
                                                if (val == true) {
                                                  if (!selectedList.contains(
                                                    loc,
                                                  )) {
                                                    selectedList.add(loc);
                                                  }
                                                } else {
                                                  selectedList.remove(loc);
                                                }
                                                if (selectedList.isEmpty) {
                                                  _tempLocationFilter = null;
                                                } else {
                                                  _tempLocationFilter =
                                                      selectedList.join(',');
                                                }
                                              });
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            loc,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isLocHovered
                                                  ? Colors.white
                                                  : const Color(0xFF4B5563),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                          const SizedBox(height: 12),
                          // Apply Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF22A95E),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _locationFilter =
                                      _tempLocationFilter ?? 'None';
                                });
                                _closeLocationOverlay();
                              },
                              child: const Text(
                                'Apply',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );

    setState(() => _isLocationMenuOpen = true);
    Overlay.of(context).insert(_locationOverlayEntry!);
  }

  void _closeLocationOverlay() {
    if (_locationOverlayEntry != null) {
      _locationOverlayEntry!.remove();
      _locationOverlayEntry = null;
      if (mounted) setState(() => _isLocationMenuOpen = false);
    }
  }

  Widget _buildSingleSelectFilterOverlay({
    required LayerLink link,
    required String Function() getSearchQuery,
    required void Function(String, StateSetter) onSearchChanged,
    required List<String> options,
    required String Function() getSelectedValue,
    required ValueChanged<String> onSelected,
    required VoidCallback onClose,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setStateOverlay) {
                final filteredOptions = options
                    .where(
                      (option) => option.toLowerCase().contains(
                        getSearchQuery().toLowerCase(),
                      ),
                    )
                    .toList();

                return Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterSearchField(
                        onChanged: (val) =>
                            onSearchChanged(val, setStateOverlay),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: filteredOptions.map((option) {
                            final isSelected = getSelectedValue() == option;
                            bool isHovered = false;
                            return StatefulBuilder(
                              builder: (context, setStateItem) {
                                return InkWell(
                                  onTap: () => onSelected(option),
                                  onHover: (val) {
                                    setStateItem(() => isHovered = val);
                                  },
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isHovered
                                          ? const Color(0xFF3B82F6)
                                          : (isSelected
                                                ? const Color(0xFFF3F4F6)
                                                : Colors.transparent),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            option,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isHovered
                                                  ? Colors.white
                                                  : (isSelected
                                                        ? const Color(
                                                            0xFF1F2937,
                                                          )
                                                        : const Color(
                                                            0xFF4B5563,
                                                          )),
                                            ),
                                          ),
                                        ),
                                        if (isSelected && !isHovered)
                                          const Icon(
                                            LucideIcons.check,
                                            size: 14,
                                            color: Color(0xFF2563EB),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxFilterOverlay({
    required LayerLink link,
    required String Function() getSearchQuery,
    required void Function(String, StateSetter) onSearchChanged,
    required List<String> options,
    required String? Function() getSelectedValue,
    required String allLabel,
    required void Function(StateSetter) onClearSelection,
    required void Function(String, StateSetter) onOptionToggle,
    required VoidCallback onApply,
    required VoidCallback onClose,
  }) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: onClose,
            child: Container(color: Colors.transparent),
          ),
        ),
        CompositedTransformFollower(
          link: link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 4),
          child: Material(
            color: Colors.transparent,
            child: StatefulBuilder(
              builder: (context, setStateOverlay) {
                final filteredOptions = options
                    .where(
                      (option) => option.toLowerCase().contains(
                        getSearchQuery().toLowerCase(),
                      ),
                    )
                    .toList();

                return Container(
                  width: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterSearchField(
                        onChanged: (val) =>
                            onSearchChanged(val, setStateOverlay),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => onClearSelection(setStateOverlay),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                height: 16,
                                width: 16,
                                child: Checkbox(
                                  value: getSelectedValue() == null,
                                  activeColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: const BorderSide(
                                    color: Color(0xFFCCCCCC),
                                    width: 1.5,
                                  ),
                                  onChanged: (_) =>
                                      onClearSelection(setStateOverlay),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  allLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF4B5563),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ...filteredOptions.map((option) {
                        final isChecked = getSelectedValue() == option;
                        bool isHovered = false;
                        return StatefulBuilder(
                          builder: (context, setStateItem) {
                            return InkWell(
                              onTap: () =>
                                  onOptionToggle(option, setStateOverlay),
                              onHover: (val) {
                                setStateItem(() => isHovered = val);
                              },
                              hoverColor: Colors.transparent,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isHovered
                                      ? const Color(0xFF2563EB)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: Checkbox(
                                        value: isChecked,
                                        activeColor: isHovered
                                            ? Colors.white
                                            : const Color(0xFF2563EB),
                                        checkColor: isHovered
                                            ? const Color(0xFF2563EB)
                                            : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        side: BorderSide(
                                          color: isHovered
                                              ? Colors.white
                                              : const Color(0xFFCCCCCC),
                                          width: 1.5,
                                        ),
                                        onChanged: (_) => onOptionToggle(
                                          option,
                                          setStateOverlay,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isHovered
                                              ? Colors.white
                                              : const Color(0xFF4B5563),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22A95E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onPressed: onApply,
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSearchField({required ValueChanged<String> onChanged}) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF93C5FD)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          const Icon(LucideIcons.search, size: 14, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String label, double width) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.only(right: 16),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8A94A6),
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell(Widget child, double width) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.only(right: 16),
        alignment: Alignment.centerLeft,
        child: child,
      ),
    );
  }

  void _toggleSettingsOverlay() {
    if (_isSettingsOpen) {
      _closeSettingsOverlay();
    } else {
      _showSettingsOverlay();
    }
  }

  void _showSettingsOverlay() {
    if (_settingsOverlayEntry != null) return;
    _settingsOverlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeSettingsOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _settingsLayerLink,
            targetAnchor: Alignment.bottomLeft,
            followerAnchor: Alignment.topLeft,
            offset: const Offset(0, 8),
            child: Material(
              color: Colors.transparent,
              child: _TableSettingsMenu(
                onClose: _closeSettingsOverlay,
                onCustomizeColumns: _showCustomizeColumnsDialog,
                clipText: _clipText,
                onClipTextToggled: () {
                  setState(() {
                    _clipText = !_clipText;
                  });
                  _settingsOverlayEntry?.markNeedsBuild();
                },
              ),
            ),
          ),
        ],
      ),
    );
    if (mounted) setState(() => _isSettingsOpen = true);
    Overlay.of(context).insert(_settingsOverlayEntry!);
  }

  void _closeSettingsOverlay() {
    if (_settingsOverlayEntry != null) {
      _settingsOverlayEntry!.remove();
      _settingsOverlayEntry = null;
      if (mounted) setState(() => _isSettingsOpen = false);
    }
  }

  void _showCustomizeColumnsDialog() {
    _closeSettingsOverlay();
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => ColumnCustomizerDialog(
        columns: _columns
            .map((c) => ColumnConfig.fromJson(c.toJson()))
            .toList(),
        onSave: (newColumns) {
          Navigator.pop(ctx, newColumns);
        },
      ),
    ).then((dynamic result) {
      if (result != null && result is List<ColumnConfig> && mounted) {
        setState(() => _columns = result);
      }
    });
  }

  void _toggleMoreMenuOverlay() {
    if (_isMoreMenuOpen) {
      _closeMoreMenuOverlay();
    } else {
      _showMoreMenuOverlay();
    }
  }

  void _closeMoreMenuOverlay() {
    if (_moreMenuOverlayEntry != null) {
      _moreMenuOverlayEntry!.remove();
      _moreMenuOverlayEntry = null;
      if (mounted) {
        setState(() {
          _isMoreMenuOpen = false;
          _isSortByOpen = false;
        });
      }
    }
  }

  void _showMoreMenuOverlay() {
    if (_moreMenuOverlayEntry != null) return;
    _moreMenuOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMoreMenuOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _moreMenuLayerLink,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (context, setStateOverlay) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isSortByOpen) ...[
                          Container(
                            width: 180,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildSortSubMenuItem(
                                  field: 'Stock Count Name',
                                  isFirst: true,
                                  setStateOverlay: setStateOverlay,
                                ),
                                _buildSortSubMenuItem(
                                  field: 'Next Count Date',
                                  isLast: true,
                                  setStateOverlay: setStateOverlay,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Container(
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              MouseRegion(
                                onEnter: (_) {
                                  if (!_isSortByOpen) {
                                    setStateOverlay(() {
                                      _isSortByOpen = true;
                                    });
                                  }
                                },
                                child: InkWell(
                                  onTap: () {
                                    setStateOverlay(() {
                                      _isSortByOpen = !_isSortByOpen;
                                    });
                                  },
                                  hoverColor: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isSortByOpen
                                          ? const Color(0xFF2563EB)
                                          : Colors.transparent,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          LucideIcons.arrowUpDown,
                                          size: 14,
                                          color: _isSortByOpen
                                              ? Colors.white
                                              : const Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sort by',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _isSortByOpen
                                                ? Colors.white
                                                : const Color(0xFF374151),
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          LucideIcons.chevronRight,
                                          size: 14,
                                          color: _isSortByOpen
                                              ? Colors.white
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              _buildMoreMenuItem(
                                icon: LucideIcons.refreshCw,
                                label: 'Refresh List',
                                isLast: true,
                                onTap: () {
                                  _closeMoreMenuOverlay();
                                  ref
                                      .read(stockCountsProvider.notifier)
                                      .fetchCounts();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
    if (mounted) setState(() => _isMoreMenuOpen = true);
    Overlay.of(context).insert(_moreMenuOverlayEntry!);
  }

  Widget _buildMoreMenuItem({
    required IconData icon,
    required String label,
    bool isLast = false,
    required VoidCallback onTap,
  }) {
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setStateItem) {
        return MouseRegion(
          onEnter: (_) => setStateItem(() => isHovered = true),
          onExit: (_) => setStateItem(() => isHovered = false),
          child: InkWell(
            onTap: onTap,
            hoverColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isHovered ? const Color(0xFF2563EB) : Colors.transparent,
                borderRadius: isLast
                    ? const BorderRadius.vertical(bottom: Radius.circular(6))
                    : BorderRadius.zero,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isHovered ? Colors.white : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isHovered ? Colors.white : const Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortSubMenuItem({
    required String field,
    bool isFirst = false,
    bool isLast = false,
    required StateSetter setStateOverlay,
  }) {
    final isSelected = _sortByField == field;
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setStateItem) {
        final Color bg;
        if (isHovered) {
          bg = const Color(0xFF2563EB);
        } else if (isSelected) {
          bg = const Color(0xFFF3F4F6);
        } else {
          bg = Colors.transparent;
        }

        final Color textColor;
        if (isHovered) {
          textColor = Colors.white;
        } else if (isSelected) {
          textColor = const Color(0xFF1F2937);
        } else {
          textColor = const Color(0xFF374151);
        }

        return MouseRegion(
          onEnter: (_) => setStateItem(() => isHovered = true),
          onExit: (_) => setStateItem(() => isHovered = false),
          child: InkWell(
            onTap: () {
              setState(() {
                if (_sortByField == field) {
                  _sortAscending = !_sortAscending;
                } else {
                  _sortByField = field;
                  _sortAscending = true;
                }
              });
              _closeMoreMenuOverlay();
            },
            hoverColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.only(
                  topLeft: isFirst ? const Radius.circular(6) : Radius.zero,
                  topRight: isFirst ? const Radius.circular(6) : Radius.zero,
                  bottomLeft: isLast ? const Radius.circular(6) : Radius.zero,
                  bottomRight: isLast ? const Radius.circular(6) : Radius.zero,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      field,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      _sortAscending
                          ? LucideIcons.arrowUp
                          : LucideIcons.arrowDown,
                      size: 14,
                      color: isHovered ? Colors.white : const Color(0xFF2563EB),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TableSettingsMenu extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onCustomizeColumns;
  final bool clipText;
  final VoidCallback onClipTextToggled;

  const _TableSettingsMenu({
    required this.onClose,
    required this.onCustomizeColumns,
    required this.clipText,
    required this.onClipTextToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TableSettingsMenuItem(
            label: 'Customize Columns',
            icon: LucideIcons.columns,
            onTap: onCustomizeColumns,
          ),
          _TableSettingsMenuItem(
            label: clipText ? 'Wrap Text' : 'Clip Text',
            icon: clipText ? LucideIcons.wrapText : LucideIcons.list,
            onTap: onClipTextToggled,
          ),
        ],
      ),
    );
  }
}

class _TableSettingsMenuItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _TableSettingsMenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_TableSettingsMenuItem> createState() => _TableSettingsMenuItemState();
}

class _TableSettingsMenuItemState extends State<_TableSettingsMenuItem> {
  bool _isHovered = false;

  void _setHovered(bool v) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isHovered = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = _isHovered ? Colors.white : const Color(0xFF1F2937);
    final Color iconColor = _isHovered ? Colors.white : AppTheme.primaryBlue;
    final Color bg = _isHovered ? AppTheme.primaryBlue : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: InkWell(
        onTap: widget.onTap,
        hoverColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          color: bg,
          child: Row(
            children: [
              Icon(widget.icon, size: 15, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
