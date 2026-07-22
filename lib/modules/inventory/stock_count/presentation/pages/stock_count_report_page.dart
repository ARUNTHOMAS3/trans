import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import '../../models/stock_count_model.dart';
import '../../providers/stock_count_provider.dart';

class StockCountReportPage extends ConsumerStatefulWidget {
  const StockCountReportPage({super.key});

  @override
  ConsumerState<StockCountReportPage> createState() =>
      _StockCountReportPageState();
}

class _StockCountReportPageState extends ConsumerState<StockCountReportPage> {
  final Set<String> _selectedIds = {};
  static const double _tableLeadingInset = 4;
  static const double _tableSettingsSlotWidth = 30;
  static const double _tableCheckboxSize = 16;
  static const double _tableGapAfterSettings = 4;
  static const double _tableGapAfterCheckbox = 24;

  String _sortByField = 'Stock Count#';
  bool _sortAscending = false;

  final Map<String, double> _columnWidths = {
    'STOCK COUNT#': 180.0,
    'DESCRIPTION': 220.0,
    'LOCATION': 220.0,
    'ASSIGNED TO': 280.0,
    'STATUS': 180.0,
    'COUNT DATE': 180.0,
    'TOTAL ITEMS': 160.0,
    'ACCURACY': 160.0,
  };

  // Settings overlay
  OverlayEntry? _settingsOverlayEntry;
  LayerLink? __settingsLayerLink;
  LayerLink get _settingsLayerLink => __settingsLayerLink ??= LayerLink();
  bool _isSettingsOpen = false;
  bool _clipText = false;

  List<ColumnConfig> _columns = [
    ColumnConfig(
      id: 'STOCK COUNT#',
      label: 'Stock Count#',
      isLocked: true,
      orderIndex: 0,
    ),
    ColumnConfig(id: 'DESCRIPTION', label: 'Description', orderIndex: 1),
    ColumnConfig(id: 'LOCATION', label: 'Location', orderIndex: 2),
    ColumnConfig(id: 'ASSIGNED TO', label: 'Assigned To', orderIndex: 3),
    ColumnConfig(id: 'STATUS', label: 'Status', orderIndex: 4),
    ColumnConfig(id: 'COUNT DATE', label: 'Count Date', orderIndex: 5),
    ColumnConfig(id: 'TOTAL ITEMS', label: 'Total Items', orderIndex: 6),
    ColumnConfig(id: 'ACCURACY', label: 'Accuracy', orderIndex: 7),
  ];

  OverlayEntry? _timeRangeOverlayEntry;
  final LayerLink _timeRangeLayerLink = LayerLink();
  bool _isTimeRangeMenuOpen = false;
  String _selectedTimeRange = 'This Month';

  OverlayEntry? _assignedToOverlayEntry;
  final LayerLink _assignedToLayerLink = LayerLink();
  bool _isAssignedToMenuOpen = false;
  String _tempSearchUserQuery = '';
  String? _tempAssignedToFilter;

  OverlayEntry? _statusOverlayEntry;
  final LayerLink _statusLayerLink = LayerLink();
  bool _isStatusMenuOpen = false;
  String _tempSearchStatusQuery = '';

  OverlayEntry? _locationOverlayEntry;
  final LayerLink _locationLayerLink = LayerLink();
  bool _isLocationMenuOpen = false;
  String _tempSearchLocationQuery = '';
  String? _tempLocationFilter;

  // More option menu (3-dots) overlays
  OverlayEntry? _moreMenuOverlayEntry;
  final LayerLink _moreMenuLayerLink = LayerLink();
  bool _isMoreMenuOpen = false;
  bool _isSortByOpen = false;

  static final RegExp _naturalSortTokenPattern = RegExp(r'(\d+|\D+)');

  List<String> _assignedToOptions(List<StockCount> counts) {
    final values =
        counts
            .map((count) => count.assignedTo.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  List<String> _locationOptions(List<StockCount> counts) {
    final values =
        counts
            .map((count) => (count.location ?? '').trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  bool _isBatchTrackedItem(Map<String, dynamic> item) =>
      item['track_batches'] as bool? ?? false;

  bool _isItemMatched(Map<String, dynamic> item) {
    final countedQty = item['countedQty'] as num?;
    if (countedQty == null) {
      return false;
    }

    if (_isBatchTrackedItem(item)) {
      return !(item['hasInvalidBatch'] as bool? ?? false);
    }

    final systemQty = item['systemQty'] as num? ?? 0;
    return systemQty.toDouble() == countedQty.toDouble();
  }

  int _compareNaturalValues(String left, String right) {
    final leftParts = _naturalSortTokenPattern
        .allMatches(left)
        .map((match) => match.group(0) ?? '')
        .toList();
    final rightParts = _naturalSortTokenPattern
        .allMatches(right)
        .map((match) => match.group(0) ?? '')
        .toList();
    final maxParts = leftParts.length < rightParts.length
        ? leftParts.length
        : rightParts.length;

    for (var index = 0; index < maxParts; index++) {
      final leftPart = leftParts[index];
      final rightPart = rightParts[index];
      final leftNumber = int.tryParse(leftPart);
      final rightNumber = int.tryParse(rightPart);

      int comparison;
      if (leftNumber != null && rightNumber != null) {
        comparison = leftNumber.compareTo(rightNumber);
      } else {
        comparison = leftPart.toLowerCase().compareTo(rightPart.toLowerCase());
      }

      if (comparison != 0) return comparison;
    }

    return leftParts.length.compareTo(rightParts.length);
  }

  void _toggleStockCountHeaderSort() {
    setState(() {
      if (_sortByField == 'Stock Count#') {
        _sortAscending = !_sortAscending;
      } else {
        _sortByField = 'Stock Count#';
        _sortAscending = true;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stockCountsProvider.notifier).fetchCounts();
    });
  }

  bool _isInSelectedTimeRange(DateTime date) {
    final now = DateTime.now();
    final current = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);

    DateTime start;
    DateTime end;

    switch (_selectedTimeRange) {
      case 'This Week':
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
      case 'Previous Week':
        end = today.subtract(Duration(days: today.weekday - 1));
        start = end.subtract(const Duration(days: 7));
        break;
      case 'This Quarter':
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        start = DateTime(now.year, quarterStartMonth, 1);
        end = DateTime(now.year, quarterStartMonth + 3, 1);
        break;
      case 'Previous Quarter':
        final quarterStartMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        end = DateTime(now.year, quarterStartMonth, 1);
        start = DateTime(end.year, end.month - 3, 1);
        break;
      case 'This Year':
        start = DateTime(now.year, 1, 1);
        end = DateTime(now.year + 1, 1, 1);
        break;
      case 'Previous Year':
        start = DateTime(now.year - 1, 1, 1);
        end = DateTime(now.year, 1, 1);
        break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1);
        break;
      case 'Previous Month':
        start = DateTime(now.year, now.month - 1, 1);
        end = DateTime(now.year, now.month, 1);
        break;
      default:
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 7));
    }

    return !current.isBefore(start) && current.isBefore(end);
  }

  @override
  void deactivate() {
    _closeTimeRangeOverlay();
    _closeAssignedToOverlay();
    _closeStatusOverlay();
    _closeLocationOverlay();
    _closeSettingsOverlay();
    _closeMoreMenuOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _closeTimeRangeOverlay();
    _closeAssignedToOverlay();
    _closeStatusOverlay();
    _closeLocationOverlay();
    _closeSettingsOverlay();
    _closeMoreMenuOverlay();
    super.dispose();
  }

  void _clearSelection() {
    if (_selectedIds.isEmpty) return;
    setState(() {
      _selectedIds.clear();
    });
  }

  void _toggleVisibleSelection(List<StockCount> counts, bool shouldSelectAll) {
    setState(() {
      if (shouldSelectAll) {
        _selectedIds.addAll(counts.map((count) => count.id));
      } else {
        _selectedIds.removeAll(counts.map((count) => count.id));
      }
    });
  }

  void _deleteSelectedCounts(
    BuildContext context,
    List<StockCount> visibleSelectedCounts,
  ) {
    if (visibleSelectedCounts.isEmpty) return;

    final notifier = ref.read(stockCountsProvider.notifier);
    for (final count in visibleSelectedCounts) {
      notifier.deleteCount(count.id);
    }

    _clearSelection();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${visibleSelectedCounts.length} stock '
          'count${visibleSelectedCounts.length == 1 ? '' : 's'} deleted.',
        ),
      ),
    );
  }

  Widget _buildSelectionBar(
    BuildContext context,
    List<StockCount> visibleSelectedCounts,
  ) {
    final selectedCount = visibleSelectedCounts.length;
    if (selectedCount == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            TextButton(
              onPressed: () =>
                  _deleteSelectedCounts(context, visibleSelectedCounts),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: const Text('Delete'),
            ),
            Container(
              width: 1,
              height: 22,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: AppTheme.borderColor,
            ),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$selectedCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Selected',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: _clearSelection,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'Esc',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            ),
            InkWell(
              onTap: _clearSelection,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(LucideIcons.x, size: 16, color: Color(0xFFEF4444)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(stockCountsProvider);
    final allManualCounts = state.counts
        .where((count) => !count.isRecurring)
        .toList();
    final recurringCountTotal = state.counts
        .where((count) => count.isRecurring)
        .length;
    final counts = List<StockCount>.from(
      state.filteredCounts.where((count) => !count.isRecurring),
    );

    // Sort counts
    counts.sort((a, b) {
      int cmp = 0;
      switch (_sortByField) {
        case 'Stock Count#':
          cmp = _compareNaturalValues(a.stockCountNum, b.stockCountNum);
          break;
        case 'Assigned To':
          cmp = a.assignedTo.compareTo(b.assignedTo);
          break;
        case 'Status':
          cmp = a.status.label.compareTo(b.status.label);
          break;
        case 'Count Date':
          cmp = a.countDate.compareTo(b.countDate);
          break;
        case 'Total Items':
          cmp = a.totalItems.compareTo(b.totalItems);
          break;
        default:
          cmp = _compareNaturalValues(a.stockCountNum, b.stockCountNum);
      }
      return _sortAscending ? cmp : -cmp;
    });

    final visibleCountIds = counts.map((count) => count.id).toSet();
    final hiddenSelectedIds = _selectedIds.difference(visibleCountIds);
    if (hiddenSelectedIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedIds.removeAll(hiddenSelectedIds);
        });
      });
    }
    final visibleSelectedCounts = counts
        .where((count) => _selectedIds.contains(count.id))
        .toList();
    final allVisibleSelected =
        counts.isNotEmpty && visibleSelectedCounts.length == counts.length;

    final orgId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    final dateF = DateFormat('dd-MM-yyyy');
    final locationOptions = _locationOptions(allManualCounts);
    final timeRangeCounts = allManualCounts
        .where((count) => _isInSelectedTimeRange(count.countDate))
        .toList();
    final pendingCount = allManualCounts
        .where(
          (count) =>
              count.status == StockCountStatus.yetToStart ||
              count.status == StockCountStatus.inProgress,
        )
        .length;
    final pendingApprovalCount = allManualCounts
        .where((count) => count.status == StockCountStatus.pendingApproval)
        .length;
    var matchedCount = 0;
    var unmatchedCount = 0;
    for (final count in timeRangeCounts) {
      for (final item in count.items) {
        final itemMap = Map<String, dynamic>.from(item);
        final countedQty = itemMap['countedQty'] as num?;
        if (countedQty == null) continue;
        if (_isItemMatched(itemMap)) {
          matchedCount++;
        } else {
          unmatchedCount++;
        }
      }
    }

    return ZerpaiLayout(
      pageTitle: '',
      useTopPadding: false,
      useHorizontalPadding: false,
      enableBodyScroll: false,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  const Text(
                    'Stock Counts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const Spacer(),
                  // View Recurring Counts (2) Link Button
                  InkWell(
                    onTap: () =>
                        context.go('/$orgId${AppRoutes.recurringStockCounts}'),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.repeat,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'View Recurring Counts ($recurringCountTotal)',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Stack(
                    children: [
                      InkWell(
                        onTap: () =>
                            context.go('/$orgId${AppRoutes.stockCountsCreate}'),
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
                            children: [
                              const Icon(
                                LucideIcons.plus,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'New',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 1,
                                height: 14,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                LucideIcons.chevronDown,
                                size: 14,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        bottom: 0,
                        child: PopupMenuButton<String>(
                          offset: const Offset(0, 45),
                          color: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          elevation: 2,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                            side: const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          onSelected: (value) {
                            if (value == 'new_recurring') {
                              context.go(
                                '/$orgId${AppRoutes.stockCountsCreate}?recurring=true',
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'new_recurring',
                              padding: const EdgeInsets.all(4),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'New Recurring',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          child: const SizedBox(
                            width: 34,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Dropdown/Option Menu (3-dots)
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

            // ── Summary Cards ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TOTAL PENDING
                  Expanded(
                    flex: 12,
                    child: _buildSummaryCard(
                      titleWidget: const Text(
                        'TOTAL PENDING',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                          letterSpacing: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildSummaryMetricBox(
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFDF5E9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        LucideIcons.timer,
                                        size: 13,
                                        color: Color(0xFFD97706),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$pendingCount Pending',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  ZTooltip(
                                    message:
                                        'Counts not yet started or currently in progress.',
                                    child: const Icon(
                                      LucideIcons.helpCircle,
                                      size: 14,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryMetricBox(
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF0F3),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        LucideIcons.checkCircle2,
                                        size: 13,
                                        color: Color(0xFFF43F5E),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$pendingApprovalCount Pending Approval',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // This Month + TOP ADJUSTMENT REASON (joined)
                  // This Month
                  Expanded(
                    flex: 12,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAF9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CompositedTransformTarget(
                            link: _timeRangeLayerLink,
                            child: InkWell(
                              onTap: _toggleTimeRangeOverlay,
                              hoverColor: Colors.transparent,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedTimeRange.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    LucideIcons.chevronDown,
                                    size: 10,
                                    color: Color(0xFF111827),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryMetricBox(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.checkCircle2,
                                        size: 16,
                                        color: Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$matchedCount Matched',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryMetricBox(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.xCircle,
                                        size: 16,
                                        color: Color(0xFFEF4444),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$unmatchedCount Unmatched',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // TOP ADJUSTMENT REASON section
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                LucideIcons.layoutGrid,
                                size: 12,
                                color: Color(0xFF2563EB),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'TOP ADJUSTMENT REASON',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4B5563),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildSummaryMetricBox(
                            alignment: Alignment.center,
                            child: Text(
                              timeRangeCounts.isEmpty
                                  ? 'No data'
                                  : 'Unavailable',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── View By Bar ─────────────────────────────────────────────
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
                      onTap: _toggleAssignedToOverlay,
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
                            state.assignedToFilter ?? 'None',
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
                            state.activeFilter?.label ?? 'All',
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
                    link: _locationLayerLink,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: _toggleLocationOverlay,
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
                              Builder(
                                builder: (context) {
                                  final locFilter = state.locationFilter;
                                  String displayText;
                                  if (locFilter == null || locFilter.isEmpty) {
                                    displayText = 'None';
                                  } else {
                                    final selected = locFilter
                                        .split(',')
                                        .where((x) => x.isNotEmpty)
                                        .toList();
                                    displayText =
                                        selected.length ==
                                                locationOptions.length &&
                                            locationOptions.isNotEmpty
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
                                },
                              ),
                            ],
                          ),
                        ),
                        if (state.locationFilter != null &&
                            state.locationFilter != 'None' &&
                            state.locationFilter!.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(stockCountsProvider.notifier)
                                  .setLocationFilter(null);
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
                          onTap: _toggleLocationOverlay,
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

            // ── Table ───────────────────────────────────────────────────
            _buildSelectionBar(context, visibleSelectedCounts),
            Expanded(
              child: counts.isEmpty
                  ? const Center(child: Text('No stock counts found'))
                  : Builder(
                      builder: (context) {
                        final activeCols =
                            _columns.where((c) => c.isVisible).toList()..sort(
                              (a, b) => a.orderIndex.compareTo(b.orderIndex),
                            );

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final totalColsWidth =
                                activeCols.fold<double>(
                                  0,
                                  (sum, col) =>
                                      sum + (_columnWidths[col.id] ?? 120.0),
                                ) +
                                78.0;
                            final tableWidth =
                                constraints.maxWidth > totalColsWidth
                                ? constraints.maxWidth
                                : totalColsWidth;

                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: tableWidth,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Table Header
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
                                          const SizedBox(
                                            width: _tableLeadingInset,
                                          ),
                                          SizedBox(
                                            width: _tableSettingsSlotWidth,
                                            child: Center(
                                              child: CompositedTransformTarget(
                                                link: _settingsLayerLink,
                                                child: InkWell(
                                                  onTap: _toggleSettingsOverlay,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  splashColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
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
                                            ),
                                          ),
                                          const SizedBox(
                                            width: _tableGapAfterSettings,
                                          ),
                                          // Multi-select Checkbox
                                          SizedBox(
                                            height: _tableCheckboxSize,
                                            width: _tableCheckboxSize,
                                            child: Checkbox(
                                              value: allVisibleSelected,
                                              activeColor: const Color(
                                                0xFF2563EB,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              side: const BorderSide(
                                                color: Color(0xFFCCCCCC),
                                                width: 1.5,
                                              ),
                                              onChanged: (val) =>
                                                  _toggleVisibleSelection(
                                                    counts,
                                                    val == true,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: _tableGapAfterCheckbox,
                                          ),
                                          ...activeCols.map(
                                            (col) => _buildTableHeaderCell(
                                              col,
                                              _columnWidths[col.id] ?? 120.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Table Rows
                                    Expanded(
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        itemCount: counts.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                              height: 1,
                                              color: Color(0xFFE5E7EB),
                                            ),
                                        itemBuilder: (context, index) {
                                          final count = counts[index];
                                          final isSelected = _selectedIds
                                              .contains(count.id);

                                          return Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                final detailPath = AppRoutes
                                                    .stockCountsDetail
                                                    .replaceAll(
                                                      ':id',
                                                      count.id,
                                                    );
                                                context.go(
                                                  '/$orgId$detailPath',
                                                );
                                              },
                                              hoverColor: const Color(
                                                0xFFF9FAFB,
                                              ),
                                              child: Container(
                                                height: 48,
                                                child: Row(
                                                  children: [
                                                    const SizedBox(
                                                      width: _tableLeadingInset,
                                                    ),
                                                    const SizedBox(
                                                      width:
                                                          _tableSettingsSlotWidth,
                                                    ),
                                                    const SizedBox(
                                                      width:
                                                          _tableGapAfterSettings,
                                                    ),
                                                    SizedBox(
                                                      height:
                                                          _tableCheckboxSize,
                                                      width: _tableCheckboxSize,
                                                      child: Checkbox(
                                                        value: isSelected,
                                                        activeColor:
                                                            const Color(
                                                              0xFF2563EB,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                        ),
                                                        side: const BorderSide(
                                                          color: Color(
                                                            0xFFCCCCCC,
                                                          ),
                                                          width: 1.5,
                                                        ),
                                                        onChanged: (val) {
                                                          setState(() {
                                                            if (val == true) {
                                                              _selectedIds.add(
                                                                count.id,
                                                              );
                                                            } else {
                                                              _selectedIds
                                                                  .remove(
                                                                    count.id,
                                                                  );
                                                            }
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width:
                                                          _tableGapAfterCheckbox,
                                                    ),
                                                    ...activeCols.map((col) {
                                                      final colWidth =
                                                          _columnWidths[col
                                                              .id] ??
                                                          120.0;
                                                      switch (col.id) {
                                                        case 'STOCK COUNT#':
                                                          return _buildTableCell(
                                                            Text(
                                                              count
                                                                  .stockCountNum,
                                                              style: const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
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
                                                            colWidth,
                                                          );
                                                        case 'DESCRIPTION':
                                                          return _buildTableCell(
                                                            Text(
                                                              count.description
                                                                          ?.trim()
                                                                          .isNotEmpty ==
                                                                      true
                                                                  ? count
                                                                        .description!
                                                                  : '-',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Color(
                                                                      0xFF1F2937,
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
                                                            colWidth,
                                                          );
                                                        case 'LOCATION':
                                                          return _buildTableCell(
                                                            Text(
                                                              count.location
                                                                          ?.trim()
                                                                          .isNotEmpty ==
                                                                      true
                                                                  ? count
                                                                        .location!
                                                                  : '-',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Color(
                                                                      0xFF1F2937,
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
                                                                    color: const Color(
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
                                                                      fontSize:
                                                                          13,
                                                                      color: Color(
                                                                        0xFF1F2937,
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
                                                        case 'STATUS':
                                                          Color statusColor;
                                                          switch (count
                                                              .status) {
                                                            case StockCountStatus
                                                                .expired:
                                                              statusColor =
                                                                  const Color(
                                                                    0xFFEF4444,
                                                                  );
                                                              break;
                                                            case StockCountStatus
                                                                .yetToStart:
                                                              statusColor =
                                                                  const Color(
                                                                    0xFFACB6C8,
                                                                  );
                                                              break;
                                                            case StockCountStatus
                                                                .inProgress:
                                                              statusColor =
                                                                  const Color(
                                                                    0xFF2563EB,
                                                                  );
                                                              break;
                                                            case StockCountStatus
                                                                .completed:
                                                              statusColor =
                                                                  const Color(
                                                                    0xFF10B981,
                                                                  );
                                                              break;
                                                            case StockCountStatus
                                                                .pendingApproval:
                                                              statusColor =
                                                                  const Color(
                                                                    0xFFF59E0B,
                                                                  );
                                                              break;
                                                            default:
                                                              statusColor =
                                                                  const Color(
                                                                    0xFF4B5563,
                                                                  );
                                                          }
                                                          return _buildTableCell(
                                                            Text(
                                                              count.status.label
                                                                  .toUpperCase(),
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    statusColor,
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
                                                            colWidth,
                                                          );
                                                        case 'COUNT DATE':
                                                          return _buildTableCell(
                                                            Text(
                                                              dateF.format(
                                                                count.countDate,
                                                              ),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Color(
                                                                      0xFF1F2937,
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
                                                            colWidth,
                                                          );
                                                        case 'TOTAL ITEMS':
                                                          return _buildTableCell(
                                                            Text(
                                                              count.totalItems
                                                                  .toString(),
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Color(
                                                                      0xFF1F2937,
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
                                                            colWidth,
                                                          );
                                                        case 'ACCURACY':
                                                          return _buildTableCell(
                                                            Text(
                                                              count.accuracy
                                                                      ?.toString() ??
                                                                  '',
                                                              style:
                                                                  const TextStyle(
                                                                    fontSize:
                                                                        13,
                                                                    color: Color(
                                                                      0xFF1F2937,
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
                                                            colWidth,
                                                          );
                                                        default:
                                                          return _buildTableCell(
                                                            const Text(''),
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
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required Widget titleWidget,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [titleWidget, const SizedBox(height: 12), child],
      ),
    );
  }

  Widget _buildSummaryMetricBox({
    required Widget child,
    Alignment alignment = Alignment.centerLeft,
  }) {
    return Container(
      height: 50,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: child,
    );
  }

  void _toggleTimeRangeOverlay() {
    if (_isTimeRangeMenuOpen) {
      _closeTimeRangeOverlay();
    } else {
      _showTimeRangeOverlay();
    }
  }

  void _showTimeRangeOverlay() {
    if (_timeRangeOverlayEntry != null) return;
    _timeRangeOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeTimeRangeOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _timeRangeLayerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 180,
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
                      _buildTimeRangeItem('This Week'),
                      _buildTimeRangeItem('Previous Week'),
                      _buildTimeRangeItem('This Month'),
                      _buildTimeRangeItem('Previous Month'),
                      _buildTimeRangeItem('This Quarter'),
                      _buildTimeRangeItem('Previous Quarter'),
                      _buildTimeRangeItem('This Year'),
                      _buildTimeRangeItem('Previous Year'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    setState(() => _isTimeRangeMenuOpen = true);
    Overlay.of(context).insert(_timeRangeOverlayEntry!);
  }

  void _closeTimeRangeOverlay() {
    if (_timeRangeOverlayEntry != null) {
      _timeRangeOverlayEntry!.remove();
      _timeRangeOverlayEntry = null;
      if (mounted) setState(() => _isTimeRangeMenuOpen = false);
    }
  }

  Widget _buildTimeRangeItem(String range) {
    final isSelected = _selectedTimeRange == range;
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setStateItem) {
        return InkWell(
          onTap: () {
            setState(() {
              _selectedTimeRange = range;
            });
            _closeTimeRangeOverlay();
          },
          onHover: (val) {
            setStateItem(() {
              isHovered = val;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3B82F6)
                  : (isHovered ? const Color(0xFF3B82F6) : Colors.transparent),
              borderRadius: range == 'This Week'
                  ? const BorderRadius.vertical(top: Radius.circular(8))
                  : (range == 'Previous Year'
                        ? const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          )
                        : BorderRadius.zero),
            ),
            child: Text(
              range,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected || isHovered
                    ? Colors.white
                    : const Color(0xFF4B5563),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleAssignedToOverlay() {
    if (_isAssignedToMenuOpen) {
      _closeAssignedToOverlay();
    } else {
      _showAssignedToOverlay();
    }
  }

  void _showAssignedToOverlay() {
    if (_assignedToOverlayEntry != null) return;
    final state = ref.read(stockCountsProvider);
    _tempAssignedToFilter = state.assignedToFilter;
    _tempSearchUserQuery = '';

    _assignedToOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeAssignedToOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _assignedToLayerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (context, setStateOverlay) {
                    final users = _assignedToOptions(
                      ref
                          .read(stockCountsProvider)
                          .counts
                          .where((count) => !count.isRecurring)
                          .toList(),
                    );
                    final filteredUsers = users
                        .where(
                          (u) => u.toLowerCase().contains(
                            _tempSearchUserQuery.toLowerCase(),
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
                                      hoverColor: Colors.transparent,
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
                                        _tempSearchUserQuery = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // List of users
                          ...filteredUsers.map((user) {
                            final isUserChecked = _tempAssignedToFilter == user;
                            return InkWell(
                              onTap: () {
                                setStateOverlay(() {
                                  if (isUserChecked) {
                                    _tempAssignedToFilter = null;
                                  } else {
                                    _tempAssignedToFilter = user;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: Checkbox(
                                        value: isUserChecked,
                                        activeColor: const Color(0xFF2563EB),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFFCCCCCC),
                                          width: 1.5,
                                        ),
                                        onChanged: (val) {
                                          setStateOverlay(() {
                                            if (val == true) {
                                              _tempAssignedToFilter = user;
                                            } else {
                                              _tempAssignedToFilter = null;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        user,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
                                ref
                                    .read(stockCountsProvider.notifier)
                                    .setAssignedToFilter(_tempAssignedToFilter);
                                _closeAssignedToOverlay();
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

    _statusOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeStatusOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _statusLayerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 4),
              child: Material(
                color: Colors.transparent,
                child: StatefulBuilder(
                  builder: (context, setStateOverlay) {
                    final statusOptions = [
                      _StatusOption('All', null),
                      _StatusOption(
                        'Yet To Start',
                        StockCountStatus.yetToStart,
                      ),
                      _StatusOption(
                        'Counting In Progress',
                        StockCountStatus.inProgress,
                      ),
                      _StatusOption(
                        'Pending Approval',
                        StockCountStatus.pendingApproval,
                      ),
                      _StatusOption('Completed', StockCountStatus.completed),
                      _StatusOption('Cancelled', StockCountStatus.cancelled),
                      _StatusOption('Expired', StockCountStatus.expired),
                    ];

                    final filteredOptions = statusOptions
                        .where(
                          (opt) => opt.label.toLowerCase().contains(
                            _tempSearchStatusQuery.toLowerCase(),
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
                                      hoverColor: Colors.transparent,
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
                                        _tempSearchStatusQuery = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 200,
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: filteredOptions.map((opt) {
                                return _buildStatusItem(
                                  opt.label,
                                  opt.statusVal,
                                  setStateOverlay,
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
      },
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

  Widget _buildStatusItem(
    String label,
    StockCountStatus? statusVal,
    StateSetter setStateOverlay,
  ) {
    final state = ref.watch(stockCountsProvider);
    final isSelected = state.activeFilter == statusVal;
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setStateItem) {
        return InkWell(
          onTap: () {
            ref.read(stockCountsProvider.notifier).setFilter(statusVal);
            _closeStatusOverlay();
          },
          onHover: (val) {
            setStateItem(() {
              isHovered = val;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isHovered
                  ? const Color(0xFF3B82F6)
                  : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isHovered
                          ? Colors.white
                          : (isSelected
                                ? const Color(0xFF1F2937)
                                : const Color(0xFF4B5563)),
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
  }

  void _toggleLocationOverlay() {
    if (_isLocationMenuOpen) {
      _closeLocationOverlay();
    } else {
      _showLocationOverlay();
    }
  }

  void _showLocationOverlay() {
    if (_locationOverlayEntry != null) return;
    final state = ref.read(stockCountsProvider);
    _tempLocationFilter = state.locationFilter;
    _tempSearchLocationQuery = '';

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
                    final locations = _locationOptions(
                      ref
                          .read(stockCountsProvider)
                          .counts
                          .where((count) => !count.isRecurring)
                          .toList(),
                    );
                    final filteredLocs = locations
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
                                                .where((x) => x.isNotEmpty)
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
                                ref
                                    .read(stockCountsProvider.notifier)
                                    .setLocationFilter(_tempLocationFilter);
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

  Widget _buildTableHeaderCell(ColumnConfig column, double width) {
    final label = column.label.toUpperCase();
    final isStockCountColumn = column.id == 'STOCK COUNT#';
    final isActiveSort = _sortByField == 'Stock Count#';

    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.only(right: 16),
        alignment: Alignment.centerLeft,
        child: isStockCountColumn
            ? InkWell(
                onTap: _toggleStockCountHeaderSort,
                hoverColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8A94A6),
                      ),
                    ),
                    const SizedBox(width: 1),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.chevronUp,
                          size: 10,
                          color: isActiveSort && _sortAscending
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF9CA3AF),
                        ),
                        Transform.translate(
                          offset: const Offset(0, -2),
                          child: Icon(
                            LucideIcons.chevronDown,
                            size: 10,
                            color: isActiveSort && !_sortAscending
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Text(
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
                        // Sub Menu (positioned to the left of the main menu)
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
                                  field: 'Stock Count#',
                                  isFirst: true,
                                  setStateOverlay: setStateOverlay,
                                ),
                                _buildSortSubMenuItem(
                                  field: 'Count Date',
                                  isLast: true,
                                  setStateOverlay: setStateOverlay,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        // Main Menu
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
                              // Sort by item
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
                              // Refresh List item
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

class _StatusOption {
  final String label;
  final StockCountStatus? statusVal;
  _StatusOption(this.label, this.statusVal);
}

class _HoverPopupItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _HoverPopupItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    // ignore: unused_element_parameter
    this.trailing,
    // ignore: unused_element_parameter
    this.onTap,
  });

  @override
  State<_HoverPopupItem> createState() => _HoverPopupItemState();
}

class _HoverPopupItemState extends State<_HoverPopupItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF2563EB) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 14,
              color: _isHovered ? Colors.white : widget.iconColor,
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _isHovered ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
