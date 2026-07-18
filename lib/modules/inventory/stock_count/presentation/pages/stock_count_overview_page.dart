import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/inventory/adjustments/providers/inventory_adjustments_provider.dart';
import 'package:zerpai_erp/modules/inventory/models/inventory_adjustment_reason_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import '../../models/stock_count_model.dart';
import '../widgets/stock_count_batch_numbers_dialog.dart';
import '../../providers/stock_count_provider.dart';

class StockCountOverviewPage extends ConsumerStatefulWidget {
  final String countId;
  const StockCountOverviewPage({super.key, required this.countId});

  @override
  ConsumerState<StockCountOverviewPage> createState() =>
      _StockCountOverviewPageState();
}

class _StockCountOverviewPageState
    extends ConsumerState<StockCountOverviewPage> {
  static const String _triangleAlertSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#F7525A" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/>
  <path d="M12 9v4"/>
  <path d="M12 17h.01"/>
</svg>
''';

  final List<String> _mockItems = [
    'BATCH TARCK ITEM',
    'BATCH TRACK 2',
    'BATCH TRACK 3',
    'BIN TRACK ITEMS',
    'BIN2',
    'demo composit Item 1',
    'ITEM-1',
    'ITEM-10',
    'ITEM-11',
    'ITEM-12',
    'ITEM-13',
    'ITEM-14',
    'ITEM-15',
    'ITEM-16',
  ];

  /// Stores 'Approve' or 'Reject' decision per item name
  final Map<String, String> _itemDecisions = {};

  /// Stores the selected adjustment reason per item name (dropdown)
  final Map<String, String> _adjustmentReasons = {};
  final List<InventoryAdjustmentReason> _reasonOptions =
      <InventoryAdjustmentReason>[];

  /// Checked rows in approving mode
  final Set<String> _selectedItems = {};

  bool _isApprovingMode = false;
  bool _isAdjustmentsExpanded = false;
  int _selectedTab = 0; // 0: All Items, 1: Rejected Items
  int _recurringSelectedTab = 0;
  String _recurringSortByField = 'Stock Count Name';
  bool _recurringSortAscending = true;
  String _recurringOverviewStatusFilter = 'All';
  OverlayEntry? _recurringMoreMenuOverlayEntry;
  OverlayEntry? _recurringOverviewStatusOverlayEntry;
  final LayerLink _recurringMoreMenuLayerLink = LayerLink();
  final LayerLink _recurringOverviewStatusLayerLink = LayerLink();
  bool _isRecurringMoreMenuOpen = false;
  bool _isRecurringSortByOpen = false;
  bool _isRecurringOverviewStatusMenuOpen = false;
  bool _isSubmittingApproval = false;
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _commentController = TextEditingController();

  final List<Map<String, dynamic>> _comments = [
    {
      'author': 'Zoho Inventory',
      'date': '19-06-2026 10:53 AM',
      'message':
          'Stock count approval could not be completed. Some inventory adjustments could not be processed.',
      'isHistory': false,
    },
    {
      'author': 'Zoho Inventory',
      'date': '19-06-2026 10:53 AM',
      'message':
          'Inventory Adjustment creation failed due to: Invalid reason specified for this adjustment..',
      'isHistory': false,
    },
    {
      'author': 'zabnixprivatelimited',
      'date': '19-06-2026 10:52 AM',
      'message': 'Stock counting approval is in progress.',
      'isHistory': false,
    },
    {
      'author': 'Zoho Inventory',
      'date': '18-06-2026 11:30 AM',
      'message': 'Stock count count initiated.',
      'isHistory': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAdjustmentReasons();
  }

  @override
  void deactivate() {
    _closeRecurringMoreMenuOverlay();
    _closeRecurringOverviewStatusOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _closeRecurringMoreMenuOverlay();
    _closeRecurringOverviewStatusOverlay();
    _commentController.dispose();
    super.dispose();
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

  bool _isItemUnmatched(Map<String, dynamic> item) {
    final countedQty = item['countedQty'] as num?;
    if (countedQty == null) {
      return false;
    }
    return !_isItemMatched(item);
  }

  bool _matchesRecurringOverviewStatusFilter(StockCount count) {
    switch (_recurringOverviewStatusFilter) {
      case 'Yet To Start':
        return count.status == StockCountStatus.yetToStart;
      case 'Counting In Progress':
        return count.status == StockCountStatus.inProgress;
      case 'Pending Approval':
        return count.status == StockCountStatus.pendingApproval;
      case 'Completed':
        return count.status == StockCountStatus.completed;
      case 'Cancelled':
        return count.status == StockCountStatus.cancelled;
      case 'Expired':
        return count.status == StockCountStatus.expired;
      case 'All':
      default:
        return true;
    }
  }

  String _buildAccuracyDisplay(
    StockCountStatus status,
    List<Map<String, dynamic>> items,
    double? fallbackAccuracy,
  ) {
    if (status == StockCountStatus.yetToStart) {
      return '-';
    }

    double totalAccuracy = 0;
    int contributingItems = 0;

    for (final item in items) {
      final countedQty = (item['countedQty'] as num?)?.toDouble();
      if (countedQty == null) {
        continue;
      }

      final systemQty = (item['systemQty'] as num? ?? 0).toDouble();
      final itemAccuracy = systemQty <= 0
          ? (countedQty <= 0 ? 100.0 : 0.0)
          : (countedQty / systemQty) * 100;

      totalAccuracy += itemAccuracy.clamp(0.0, 9999.0);
      contributingItems++;
    }

    if (contributingItems > 0) {
      return '${(totalAccuracy / contributingItems).toStringAsFixed(2)}%';
    }

    if (fallbackAccuracy != null) {
      return '${fallbackAccuracy.toStringAsFixed(2)}%';
    }

    return '-';
  }

  int _countRecurringOverviewCountedItems(StockCount count) {
    return count.items.where((item) => item['countedQty'] != null).length;
  }

  Color _recurringOverviewStatusColor(StockCountStatus status) {
    switch (status) {
      case StockCountStatus.inProgress:
        return const Color(0xFF3B82F6);
      case StockCountStatus.completed:
        return const Color(0xFF16A34A);
      case StockCountStatus.pendingApproval:
      case StockCountStatus.approvalInProgress:
        return const Color(0xFFF59E0B);
      case StockCountStatus.expired:
      case StockCountStatus.cancelled:
        return const Color(0xFFF7525A);
      case StockCountStatus.yetToStart:
        return const Color(0xFF9CA3AF);
    }
  }

  String _recurringOverviewStatusText(StockCountStatus status) {
    switch (status) {
      case StockCountStatus.inProgress:
        return 'COUNTING IN PROGRESS';
      case StockCountStatus.pendingApproval:
        return 'PENDING APPROVAL';
      case StockCountStatus.approvalInProgress:
        return 'APPROVAL IN PROGRESS';
      case StockCountStatus.completed:
        return 'COMPLETED';
      case StockCountStatus.cancelled:
        return 'CANCELLED';
      case StockCountStatus.expired:
        return 'EXPIRED';
      case StockCountStatus.yetToStart:
        return 'YET TO START';
    }
  }

  Widget _warningTriangleIcon(double size) => SvgPicture.string(
        _triangleAlertSvg,
        width: size,
        height: size,
      );

  Future<void> _showBatchNumbersDialog(
    BuildContext context, {
    required StockCount count,
    required Map<String, dynamic> item,
  }) async {
    final countedBatches = (item['batches'] as List? ?? const [])
        .whereType<Map>()
        .map((batch) => Map<String, dynamic>.from(batch))
        .toList();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StockCountBatchNumbersDialog(
        itemName: (item['name'] as String?) ?? 'Item',
        locationName: count.location ?? '-',
        productId: item['product_id']?.toString(),
        warehouseId: count.warehouseId,
        countedBatches: countedBatches,
      ),
    );
  }

  String _extractApprovalErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) return 'Stock count approval failed.';
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length).trim();
    }
    return raw;
  }

  Future<void> _loadAdjustmentReasons() async {
    try {
      final repo = ref.read(adjustmentsRepositoryProvider);
      final reasons = await repo.getAdjustmentReasons();
      if (!mounted) {
        return;
      }
      final activeReasons = reasons.where((reason) => reason.isActive).toList();
      setState(() {
        _reasonOptions
          ..clear()
          ..addAll(activeReasons);
        if (_reasonOptions.isNotEmpty) {
          final validReasonNames =
              _reasonOptions.map((reason) => reason.name).toSet();
          _adjustmentReasons.removeWhere(
            (_, reasonName) => !validReasonNames.contains(reasonName),
          );
        }
      });
    } catch (_) {
      // Keep fallback default reason flow when reason master load fails.
    }
  }

  Future<void> _submitStockCountApproval(
    BuildContext dialogContext,
    StockCount count,
    String orgId,
  ) async {
    if (_isSubmittingApproval) return;

    setState(() {
      _isSubmittingApproval = true;
    });

    try {
      final payload = <String, dynamic>{
        'warehouse_id': count.warehouseId,
        'description': count.description,
        'items': count.items.map((item) {
          final itemName = (item['name'] as String?) ?? '';
          final batches = (item['batches'] as List?) ?? const [];
          return <String, dynamic>{
            'product_id': item['product_id'],
            'name': itemName,
            'system_qty': (item['systemQty'] as num?)?.toDouble() ?? 0.0,
            'counted_qty': (item['countedQty'] as num?)?.toDouble(),
            'rate': double.tryParse(item['rate']?.toString() ?? '') ?? 0.0,
            'decision': _itemDecisions[itemName] ?? 'Approve',
            'adjustment_reason':
                _adjustmentReasons[itemName] ?? 'Stocktaking results',
            'batches': batches
                .whereType<Map>()
                .map((batch) => Map<String, dynamic>.from(batch))
                .toList(),
          };
        }).toList(),
      };

      await _apiClient.post(
        '/inventory-adjustments/stock-counts/${count.id}/approve',
        data: payload,
      );

      await ref.read(stockCountsProvider.notifier).updateCount(
        count.copyWith(
          status: StockCountStatus.completed,
        ),
      );

      if (!mounted) return;

      Navigator.of(dialogContext).pop();
      setState(() {
        _isApprovingMode = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock count approved successfully'),
        ),
      );
      context.go('/$orgId/inventory/stock-counts');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_extractApprovalErrorMessage(error)),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingApproval = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
    final countsState = ref.watch(stockCountsProvider);
    final count = countsState.counts.firstWhere(
      (c) => c.id == widget.countId || c.stockCountNum == widget.countId,
      orElse: () => StockCount(
        id: widget.countId,
        stockCountNum: widget.countId.startsWith('D') ? widget.countId : 'D46',
        assignedTo: 'zabnixprivatelimited',
        status: StockCountStatus.yetToStart,
        countDate: DateTime.now(),
        totalItems: 6,
      ),
    );

    final df = DateFormat('dd-MM-yyyy');
    final items = count.items.isNotEmpty
        ? count.items
        : _mockItems
              .map(
                (name) => {
                  'name': name,
                  'systemQty': 0,
                  'countedQty': null,
                  'batches': <Map<String, dynamic>>[],
                },
              )
              .toList();

    // Matched / Unmatched counts
    int matchedCount = 0;
    int unmatchedCount = 0;
    for (var item in items) {
      if (_isItemMatched(item)) {
        matchedCount++;
      } else if (_isItemUnmatched(item)) {
        unmatchedCount++;
      }
    }

    final matchedStr = count.status == StockCountStatus.yetToStart
        ? '-'
        : '$matchedCount';
    final unmatchedStr = count.status == StockCountStatus.yetToStart
        ? '-'
        : '$unmatchedCount';
    final accuracyDisplay = _buildAccuracyDisplay(
      count.status,
      items.cast<Map<String, dynamic>>(),
      count.accuracy,
    );

    if (count.isRecurring) {
      return _buildRecurringOverview(context, orgId, countsState, count);
    }

    Color badgeBg;
    Color badgeText;
    switch (count.status) {
      case StockCountStatus.expired:
        badgeBg = const Color(0xFFD9534F);
        badgeText = Colors.white;
        break;
      case StockCountStatus.yetToStart:
        badgeBg = const Color(0xFFE5E7EB);
        badgeText = const Color(0xFF4B5563);
        break;
      case StockCountStatus.inProgress:
        badgeBg = const Color(0xFF3B82F6);
        badgeText = Colors.white;
        break;
      case StockCountStatus.completed:
        badgeBg = const Color(0xFFE6F4EA);
        badgeText = const Color(0xFF107C41);
        break;
      case StockCountStatus.pendingApproval:
        badgeBg = const Color(0xFFF97316);
        badgeText = Colors.white;
        break;
      default:
        badgeBg = const Color(0xFFE5E7EB);
        badgeText = const Color(0xFF4B5563);
    }

    return ZerpaiLayout(
      pageTitle: '',
      useTopPadding: false,
      useHorizontalPadding: false,
      enableBodyScroll: true,
      endDrawer: _buildCommentsSidebar(context),
      footer: _isApprovingMode
          ? _buildApprovingFooter(context, orgId, count)
          : null,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  count.stockCountNum,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBg,
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Text(
                                    count.status.label.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: badgeText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Actions row
                      Builder(
                        builder: (context) {
                          return TextButton.icon(
                            onPressed: () {
                              Scaffold.of(context).openEndDrawer();
                            },
                            icon: const Icon(
                              LucideIcons.messageSquare,
                              size: 14,
                              color: Color(0xFF4B5563),
                            ),
                            label: const Text(
                              'Comments & History',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4B5563),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          );
                        },
                      ),
                      if (count.status != StockCountStatus.expired &&
                          !_isApprovingMode &&
                          count.status != StockCountStatus.completed) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 32,
                          color: const Color(0xFFD1D5DB),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (count.status ==
                                StockCountStatus.pendingApproval) {
                              setState(() {
                                _isApprovingMode = true;
                              });
                            } else {
                              context.go(
                                '/$orgId${AppRoutes.stockCountsPerform.replaceAll(':id', count.id)}',
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22A95E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Text(
                            count.status == StockCountStatus.pendingApproval
                                ? 'Start Approving'
                                : (count.status == StockCountStatus.inProgress
                                      ? 'Resume Counting'
                                      : 'Start Counting'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (count.status == StockCountStatus.yetToStart) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              context.go(
                                '/$orgId${AppRoutes.stockCountsCreate}?id=${count.id}',
                              );
                            },
                            icon: const Icon(
                              LucideIcons.edit2,
                              size: 14,
                              color: Color(0xFF1F2937),
                            ),
                            label: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5F5F5),
                              foregroundColor: const Color(0xFF1F2937),
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                      ] else ...[
                        const SizedBox(width: 8),
                      ],
                      PopupMenuButton<String>(
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: const Icon(
                            LucideIcons.moreVertical,
                            size: 16,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        padding: EdgeInsets.zero,
                        onSelected: (val) {
                          if (val == 'clone') {
                            final newCount = count.copyWith(
                              id: 'D${DateTime.now().millisecondsSinceEpoch}',
                              stockCountNum:
                                  'D${countsState.counts.length + 50}',
                              status: StockCountStatus.yetToStart,
                            );
                            ref
                                .read(stockCountsProvider.notifier)
                                .addCount(newCount);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Cloned to count ${newCount.stockCountNum}',
                                ),
                              ),
                            );
                          } else if (val == 'delete') {
                            ref
                                .read(stockCountsProvider.notifier)
                                .deleteCount(count.id);
                            context.go('/$orgId${AppRoutes.stockCounts}');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Stock count deleted.'),
                              ),
                            );
                          } else if (val == 'cancel') {
                            ref
                                .read(stockCountsProvider.notifier)
                                .updateCount(
                                  count.copyWith(
                                    status: StockCountStatus.cancelled,
                                  ),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Stock count cancelled.'),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          _buildHoverableMenuItem(
                            value: 'clone',
                            icon: LucideIcons.copy,
                            label: 'Clone',
                          ),
                          _buildHoverableMenuItem(
                            value: 'delete',
                            icon: LucideIcons.trash2,
                            label: 'Delete',
                          ),
                          _buildHoverableMenuItem(
                            value: 'cancel',
                            icon: LucideIcons.rotateCcw,
                            label: 'Cancel',
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      // Close / X button
                      IconButton(
                        onPressed: () =>
                            context.go('/$orgId${AppRoutes.stockCounts}'),
                        icon: const Icon(
                          LucideIcons.x,
                          size: 20,
                          color: Color(0xFF4B5563),
                        ),
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        splashColor: Colors.transparent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
              child: Row(
                children: [
                  const Text(
                    'Assigned To: ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    count.assignedTo,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 28),
                  Container(
                    width: 1,
                    height: 20,
                    color: const Color(0xFFD1D5DB),
                  ),
                  const SizedBox(width: 28),
                  const Icon(
                    LucideIcons.calendar,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Scheduled On: ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  Text(
                    df.format(count.countDate),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 28),
                  Container(
                    width: 1,
                    height: 20,
                    color: const Color(0xFFD1D5DB),
                  ),
                  const SizedBox(width: 28),
                  const Icon(
                    LucideIcons.mapPin,
                    size: 16,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Location: ',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  ),
                  const Text(
                    'ZABNIX PRIVATE LIMITED',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Adjustments Card
                  if (count.status == StockCountStatus.completed) ...[
                    _buildAdjustmentsCard(context),
                  ],

                  // What's Next Banner
                  if (count.status == StockCountStatus.yetToStart) ...[
                    Row(
                      children: [
                        Container(
                          width: 620,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.sparkles,
                                size: 14,
                                color: Color(0xFF8B5CF6),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "WHAT'S NEXT? ",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  "The stock count hasn't started yet. Items yet to count: ${items.length}",
                                  maxLines: 1,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  context.go(
                                    '/$orgId${AppRoutes.stockCountsPerform.replaceAll(':id', count.id)}',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22A95E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'Start Counting',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ] else if (count.status == StockCountStatus.pendingApproval &&
                      !_isApprovingMode) ...[
                    Row(
                      children: [
                        Container(
                          width: 720,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.sparkles,
                                size: 14,
                                color: Color(0xFF8B5CF6),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "WHAT'S NEXT? ",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const Expanded(
                                child: Text(
                                  "The count has been submitted for approval. Review and approve it to update your inventory.",
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isApprovingMode = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22A95E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  'Start Approving',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Overview Cards Section
                  const Text(
                    'OVERVIEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 620,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildOverviewMetric(
                                  title: 'Accuracy',
                                  value: accuracyDisplay,
                                  icon: LucideIcons.arrowUpDown,
                                  iconColor: const Color(0xFF2563EB),
                                  iconBg: const Color(0xFFEFF6FF),
                                  showInfo: true,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 44,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                color: const Color(0xFFE5E7EB),
                              ),
                              Expanded(
                                child: _buildOverviewMetric(
                                  title: 'Matched',
                                  value: matchedStr,
                                  icon: LucideIcons.checkCircle,
                                  iconColor: const Color(0xFF10B981),
                                  iconBg: const Color(0xFFECFDF5),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 44,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                color: const Color(0xFFE5E7EB),
                              ),
                              Expanded(
                                child: _buildOverviewMetric(
                                  title: 'Unmatched',
                                  value: unmatchedStr,
                                  icon: LucideIcons.xCircle,
                                  iconColor: const Color(0xFFEF4444),
                                  iconBg: const Color(0xFFFEF2F2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (count.status == StockCountStatus.completed) ...[
                          const SizedBox(width: 16),
                          _buildTopAdjustmentReasonBox(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Items table section (Tabs)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: count.status == StockCountStatus.completed
                  ? Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) {
                              final rejectedItemsCount = items.where((item) {
                                final itemName =
                                    (item['name'] as String?) ?? '';
                                final decision =
                                    _itemDecisions[itemName] ?? 'Approve';
                                return decision == 'Reject';
                              }).length;
                              final isSelected = _selectedTab == 1;
                              return InkWell(
                                onTap: () => setState(() => _selectedTab = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  margin: const EdgeInsets.only(right: 24),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: isSelected
                                            ? const Color(0xFF2563EB)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Rejected Items ($rejectedItemsCount)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          InkWell(
                            onTap: () => setState(() => _selectedTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: _selectedTab == 0
                                        ? const Color(0xFF2563EB)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Text(
                                'All Items (${items.length})',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedTab == 0
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: _selectedTab == 0
                                      ? const Color(0xFF2563EB)
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Text(
                      'ITEMS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
            const SizedBox(height: 12),

            // Bulk action ribbon — only visible when rows are checked
            if (_isApprovingMode && _selectedItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    // Bulk Approve
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          for (final name in _selectedItems) {
                            _itemDecisions[name] = 'Approve';
                          }
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Bulk Approve',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bulk Reject
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          for (final name in _selectedItems) {
                            _itemDecisions[name] = 'Reject';
                          }
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Bulk Reject',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_selectedItems.length} Item(s) Selected',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: EdgeInsets.zero,
              child: Container(
                constraints: const BoxConstraints(minHeight: 220),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 1.0,
                      child: IgnorePointer(
                        ignoring:
                            count.status == StockCountStatus.expired ||
                            count.status == StockCountStatus.yetToStart,
                        child: Table(
                          columnWidths:
                              (_isApprovingMode ||
                                  count.status == StockCountStatus.completed)
                              ? {
                                  if (_isApprovingMode)
                                    0: const FixedColumnWidth(48), // checkbox
                                  (_isApprovingMode ? 1 : 0):
                                      const FlexColumnWidth(2.5), // ITEMS
                                  (_isApprovingMode ? 2 : 1):
                                      const FlexColumnWidth(1.5), // STATUS
                                  (_isApprovingMode ? 3 : 2):
                                      const FlexColumnWidth(1.3), // SYSTEM QTY
                                  (_isApprovingMode ? 4 : 3):
                                      const FlexColumnWidth(1.3), // COUNTED QTY
                                  (_isApprovingMode ? 5 : 4):
                                      const FlexColumnWidth(1.3), // DIFFERENCE
                                  (_isApprovingMode ? 6 : 5):
                                      const FlexColumnWidth(1.8), // BATCHES
                                  (_isApprovingMode
                                      ? 7
                                      : 6): const FlexColumnWidth(
                                    2.8,
                                  ), // APPROVAL STATUS
                                  (_isApprovingMode
                                      ? 8
                                      : 7): const FlexColumnWidth(
                                    2.5,
                                  ), // ADJUSTMENT REASON
                                }
                              : const {
                                  0: FlexColumnWidth(3),
                                  1: FlexColumnWidth(1.8),
                                  2: FlexColumnWidth(1.8),
                                  3: FlexColumnWidth(1.5),
                                  4: FlexColumnWidth(1.5),
                                  5: FlexColumnWidth(1.8),
                                },
                          border: const TableBorder(
                            horizontalInside: BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            verticalInside: BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1,
                            ),
                            bottom: BorderSide(
                              color: Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                          children: [
                            TableRow(
                              decoration: const BoxDecoration(
                                color: Color(0xFFF9FAFB),
                              ),
                              children: [
                                // Checkbox header (approving mode only)
                                if (_isApprovingMode)
                                  TableCell(
                                    verticalAlignment:
                                        TableCellVerticalAlignment.middle,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      child: Builder(
                                        builder: (ctx) {
                                          final allNames = items
                                              .map(
                                                (i) =>
                                                    (i['name'] as String?) ??
                                                    '',
                                              )
                                              .toList();
                                          final allSelected =
                                              allNames.isNotEmpty &&
                                              allNames.every(
                                                _selectedItems.contains,
                                              );
                                          return Checkbox(
                                            value: allSelected,
                                            tristate: false,
                                            activeColor: const Color(
                                              0xFF2563EB,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFD1D5DB),
                                              width: 1.5,
                                            ),
                                            onChanged: (v) {
                                              setState(() {
                                                if (v == true) {
                                                  _selectedItems.addAll(
                                                    allNames,
                                                  );
                                                } else {
                                                  _selectedItems.removeAll(
                                                    allNames,
                                                  );
                                                }
                                              });
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                _buildTableHeaderCell('ITEMS'),
                                _wrapHeaderWithExpiredOpacity(
                                  _buildTableHeaderCell('STATUS'),
                                  count.status,
                                ),
                                _wrapHeaderWithExpiredOpacity(
                                  _buildTableHeaderCell(
                                    'SYSTEM QUANTITY',
                                    showInfo: true,
                                  ),
                                  count.status,
                                ),
                                _wrapHeaderWithExpiredOpacity(
                                  _buildTableHeaderCell('COUNTED QUANTITY'),
                                  count.status,
                                ),
                                _wrapHeaderWithExpiredOpacity(
                                  _buildTableHeaderCell('DIFFERENCE'),
                                  count.status,
                                ),
                                _wrapHeaderWithExpiredOpacity(
                                  _buildTableHeaderCell(
                                    'COUNTED SERIALS/BATCHES',
                                  ),
                                  count.status,
                                ),
                                if (_isApprovingMode ||
                                    count.status ==
                                        StockCountStatus.completed) ...[
                                  _buildTableHeaderCell('APPROVAL STATUS'),
                                  if (_isApprovingMode)
                                    _buildAdjustmentReasonHeaderCell(
                                      items
                                          .where((i) {
                                            final sq =
                                                (i['systemQty'] as num? ?? 0)
                                                    .toInt();
                                            final cq = (i['countedQty'] as num?)
                                                ?.toInt();
                                            return cq != null && (cq - sq) != 0;
                                          })
                                          .map(
                                            (i) => (i['name'] as String?) ?? '',
                                          )
                                          .toList(),
                                    )
                                  else
                                    _buildTableHeaderCell('ADJUSTMENT REASON'),
                                ],
                              ],
                            ),
                            ...items
                                .where((item) {
                                  if (count.status ==
                                          StockCountStatus.completed &&
                                      _selectedTab == 1) {
                                    final name =
                                        (item['name'] as String?) ?? '';
                                    final decision =
                                        _itemDecisions[name] ?? 'Approve';
                                    return decision == 'Reject';
                                  }
                                  return true;
                                })
                                .map((item) {
                                  final String itemName =
                                      (item['name'] as String?) ?? '';
                                  final systemQty =
                                      (item['systemQty'] as num? ?? 0).toInt();
                                  final countedQty =
                                      (item['countedQty'] as num?)?.toInt();
                                  final diff = countedQty != null
                                      ? (countedQty - systemQty)
                                      : null;

                                  String statusLabel = 'Uncounted';
                                  Color statusColor = const Color(0xFF9CA3AF);
                                  Color statusBg = const Color(0xFFF3F4F6);
                                  if (countedQty != null) {
                                    if (_isItemMatched(item)) {
                                      statusLabel = 'Matched';
                                      statusColor = const Color(0xFF10B981);
                                      statusBg = const Color(0xFFECFDF5);
                                    } else {
                                      statusLabel = 'Unmatched';
                                      statusColor = const Color(0xFFEF4444);
                                      statusBg = const Color(0xFFFEF2F2);
                                    }
                                  }

                                  String diffText = '-';
                                  Color diffColor = const Color(0xFF1F2937);
                                  if (diff != null) {
                                    if (diff > 0) {
                                      diffText = '+${diff.toStringAsFixed(0)}';
                                      diffColor = const Color(0xFF10B981);
                                    } else if (diff < 0) {
                                      diffText = diff.toStringAsFixed(0);
                                      diffColor = const Color(0xFFEF4444);
                                    } else {
                                      diffText = '0';
                                      diffColor = const Color(0xFF6B7280);
                                    }
                                  }

                                  return TableRow(
                                    children: [
                                      // Per-row checkbox (approving mode only)
                                      if (_isApprovingMode)
                                        TableCell(
                                          verticalAlignment:
                                              TableCellVerticalAlignment.middle,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                            ),
                                            child: Checkbox(
                                              value: _selectedItems.contains(
                                                itemName,
                                              ),
                                              activeColor: const Color(
                                                0xFF2563EB,
                                              ),
                                              side: const BorderSide(
                                                color: Color(0xFFD1D5DB),
                                                width: 1.5,
                                              ),
                                              onChanged: (v) {
                                                setState(() {
                                                  if (v == true) {
                                                    _selectedItems.add(
                                                      itemName,
                                                    );
                                                  } else {
                                                    _selectedItems.remove(
                                                      itemName,
                                                    );
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            context.go(
                                              '/$orgId${AppRoutes.itemsDetail.replaceAll(':id', '1')}',
                                            );
                                          },
                                          hoverColor: const Color(0xFFF9FAFB),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 12,
                                              bottom: 12,
                                              left: 16,
                                            ),
                                            child: Text(
                                              itemName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF2563EB),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      _buildTableCellWidget(
                                        (count.status ==
                                                    StockCountStatus.expired ||
                                                count.status ==
                                                    StockCountStatus.yetToStart)
                                            ? const SizedBox.shrink()
                                            : Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: statusBg,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  statusLabel,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: statusColor,
                                                  ),
                                                ),
                                              ),
                                        alignment: Alignment.centerLeft,
                                      ),
                                      _buildTableCellWidget(
                                        (count.status ==
                                                    StockCountStatus.expired ||
                                                count.status ==
                                                    StockCountStatus.yetToStart)
                                            ? const SizedBox.shrink()
                                            : Text(
                                                '$systemQty',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF374151),
                                                ),
                                              ),
                                      ),
                                      _buildTableCellWidget(
                                        (count.status ==
                                                    StockCountStatus.expired ||
                                                count.status ==
                                                    StockCountStatus.yetToStart)
                                            ? const SizedBox.shrink()
                                            : Text(
                                                countedQty != null
                                                    ? '$countedQty'
                                                    : '-',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF374151),
                                                ),
                                              ),
                                      ),
                                      _buildTableCellWidget(
                                        (count.status ==
                                                    StockCountStatus.expired ||
                                                count.status ==
                                                    StockCountStatus.yetToStart)
                                            ? const SizedBox.shrink()
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    diffText,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: diffColor,
                                                    ),
                                                  ),
                                                  if (diff != null &&
                                                      diff != 0) ...[
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      diff > 0
                                                          ? LucideIcons.arrowUp
                                                          : LucideIcons
                                                                .arrowDown,
                                                      size: 14,
                                                      color: diffColor,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                        bgColor:
                                            (count.status ==
                                                    StockCountStatus.expired ||
                                                count.status ==
                                                    StockCountStatus.yetToStart)
                                            ? Colors.transparent
                                            : (diff != null
                                                  ? (diff > 0
                                                        ? const Color(
                                                            0xFFECFDF5,
                                                          )
                                                        : (diff < 0
                                                              ? const Color(
                                                                  0xFFFEF2F2,
                                                                )
                                                              : Colors
                                                                    .transparent))
                                                  : Colors.transparent),
                                      ),
                                      _buildTableCellWidget(
                                        (count.status ==
                                                    StockCountStatus.expired ||
                                                count.status ==
                                                    StockCountStatus.yetToStart)
                                            ? const SizedBox.shrink()
                                            : Builder(
                                                builder: (context) {
                                                  final trackBatches =
                                                      item['track_batches']
                                                          as bool? ??
                                                      false;
                                                  final batches =
                                                      (item['batches'] as List? ??
                                                              const [])
                                                          .whereType<Map>()
                                                          .toList();
                                                  if (!trackBatches) {
                                                    return const Text(
                                                      '-',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Color(
                                                          0xFF9CA3AF,
                                                        ),
                                                      ),
                                                    );
                                                  }

                                                  return InkWell(
                                                    onTap: () =>
                                                        _showBatchNumbersDialog(
                                                          context,
                                                          count: count,
                                                          item: item,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          '${batches.length} Batches',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Color(
                                                                  0xFF2563EB,
                                                                ),
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        _warningTriangleIcon(
                                                          13,
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              ),
                                        alignment: Alignment.centerLeft,
                                      ),
                                      if (_isApprovingMode) ...[
                                        // Col 5 — Approve / Reject buttons
                                        _buildTableCellWidget(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _buildDecisionButton(
                                                label: 'Approve',
                                                icon: LucideIcons.checkCircle,
                                                isSelected:
                                                    _itemDecisions[itemName] ==
                                                    'Approve',
                                                activeColor: const Color(
                                                  0xFF2563EB,
                                                ),
                                                activeBg: Colors.white,
                                                onTap: () {
                                                  setState(() {
                                                    _itemDecisions[itemName] =
                                                        'Approve';
                                                  });
                                                },
                                              ),
                                              const SizedBox(width: 6),
                                              _buildDecisionButton(
                                                label: 'Reject',
                                                icon: LucideIcons.xCircle,
                                                isSelected:
                                                    _itemDecisions[itemName] ==
                                                    'Reject',
                                                activeColor: const Color(
                                                  0xFF2563EB,
                                                ),
                                                activeBg: Colors.white,
                                                onTap: () {
                                                  setState(() {
                                                    _itemDecisions[itemName] =
                                                        'Reject';
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          alignment: Alignment.centerLeft,
                                        ),
                                        // Col 6 — Adjustment reason dropdown
                                        _buildTableCellWidget(
                                          diff == 0
                                              ? const Text(
                                                  'Not Applicable',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF9CA3AF),
                                                  ),
                                                )
                                              : _buildReasonDropdown(itemName),
                                          alignment: Alignment.centerLeft,
                                        ),
                                      ] else if (count.status ==
                                          StockCountStatus.completed) ...[
                                        // Col 5 — Static Approval Status
                                        _buildTableCellWidget(
                                          Builder(
                                            builder: (context) {
                                              final decision =
                                                  _itemDecisions[itemName] ??
                                                  'Approve';
                                              final isApproved =
                                                  decision == 'Approve';
                                              return Text(
                                                isApproved
                                                    ? 'Approved'
                                                    : 'Rejected',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isApproved
                                                      ? const Color(0xFF10B981)
                                                      : const Color(0xFFEF4444),
                                                ),
                                              );
                                            },
                                          ),
                                          alignment: Alignment.centerLeft,
                                        ),
                                        // Col 6 — Static Adjustment Reason
                                        _buildTableCellWidget(
                                          Text(
                                            diff == 0
                                                ? 'Not Applicable'
                                                : (_adjustmentReasons[itemName] ??
                                                      'Stocktaking results'),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: diff == 0
                                                  ? const Color(0xFF9CA3AF)
                                                  : const Color(0xFF1F2937),
                                            ),
                                          ),
                                          alignment: Alignment.centerLeft,
                                        ),
                                      ],
                                    ],
                                  );
                                })
                                .toList(),
                          ],
                        ),
                      ),
                    ),
                    if (count.status == StockCountStatus.expired)
                      Positioned.fill(
                        child: Row(
                          children: [
                            const Spacer(flex: 30),
                            Expanded(
                              flex: 66,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 20,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF2F2),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.alertTriangle,
                                          color: Color(0xFFEF4444),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      RichText(
                                        textAlign: TextAlign.center,
                                        text: const TextSpan(
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF374151),
                                            height: 1.4,
                                          ),
                                          children: [
                                            TextSpan(text: 'The stock count '),
                                            TextSpan(
                                              text: 'has expired',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  '. You cannot do any\nactions to this count.',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (count.status == StockCountStatus.yetToStart)
                      Positioned.fill(
                        child: Row(
                          children: [
                            const Spacer(flex: 30),
                            Expanded(
                              flex: 66,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 20,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF7ED),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          LucideIcons.timer,
                                          color: Color(0xFFEA580C),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF374151),
                                            height: 1.4,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text:
                                                  'This stock count is assigned to ',
                                            ),
                                            TextSpan(
                                              text: count.assignedTo,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const TextSpan(
                                              text:
                                                  '. Only the assigned user can\nstart it. ',
                                            ),
                                            const TextSpan(
                                              text: 'Note: ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const TextSpan(
                                              text:
                                                  'Stock counts can now be performed on the web or mobile app.',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringOverview(
    BuildContext context,
    String orgId,
    StockCountsState countsState,
    StockCount selectedCount,
  ) {
    final recurringCounts =
        countsState.counts.where((count) => count.isRecurring).toList()
          ..sort((a, b) {
            int cmp = 0;
            switch (_recurringSortByField) {
              case 'Next Count Date':
                cmp = (a.nextCountDate ?? DateTime(1900)).compareTo(
                  b.nextCountDate ?? DateTime(1900),
                );
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
            return _recurringSortAscending ? cmp : -cmp;
          });
    final df = DateFormat('dd-MM-yyyy');
    final recurringName = selectedCount.recurringName?.trim().isNotEmpty == true
        ? selectedCount.recurringName!
        : selectedCount.stockCountNum;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          Container(
            width: 420,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: IconButton(
                          onPressed: () =>
                              context.go('/$orgId${AppRoutes.stockCounts}'),
                          icon: const Icon(LucideIcons.chevronLeft, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stock Counts',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            Text(
                              recurringName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
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
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22A95E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.plus,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      CompositedTransformTarget(
                        link: _recurringMoreMenuLayerLink,
                        child: InkWell(
                          onTap: _toggleRecurringMoreMenuOverlay,
                          hoverColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
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
                Expanded(
                  child: ListView.separated(
                    itemCount: recurringCounts.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Color(0xFFE5E7EB)),
                    itemBuilder: (context, index) {
                      final count = recurringCounts[index];
                      final isSelected = count.id == selectedCount.id;
                      final name =
                          count.recurringName?.trim().isNotEmpty == true
                          ? count.recurringName!
                          : count.stockCountNum;
                      bool isHovered = false;
                      return StatefulBuilder(
                        builder: (context, setStateItem) {
                          return MouseRegion(
                            onEnter: (_) =>
                                setStateItem(() => isHovered = true),
                            onExit: (_) =>
                                setStateItem(() => isHovered = false),
                            child: InkWell(
                              onTap: () => context.go(
                                '/$orgId${AppRoutes.stockCountsDetail.replaceFirst(':id', count.id)}',
                              ),
                              hoverColor: Colors.transparent,
                              child: Container(
                                color: isSelected
                                    ? const Color(0xFFF3F4FF)
                                    : isHovered
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.white,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  14,
                                  16,
                                  14,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF111827),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          count.frequency ?? 'Custom',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF4F46E5),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      count.assignedTo,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    if (count.nextCountDate != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Next Counting on ${df.format(count.nextCountDate!)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Text(
                                      count.isActive ? 'ACTIVE' : 'INACTIVE',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: count.isActive
                                            ? const Color(0xFF22A95E)
                                            : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Row(
                    children: [
                      Text(
                        recurringName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          context.go(
                            '/$orgId${AppRoutes.stockCountsCreate}?id=${selectedCount.id}',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22A95E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.edit2, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      PopupMenuButton<String>(
                        color: Colors.white,
                        surfaceTintColor: Colors.transparent,
                        elevation: 6,
                        offset: const Offset(0, 40),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        onSelected: (value) {
                          if (value == 'clone') {
                            final newCount = selectedCount.copyWith(
                              id: 'D${DateTime.now().millisecondsSinceEpoch}',
                              stockCountNum:
                                  'D${countsState.counts.length + 50}',
                              status: StockCountStatus.yetToStart,
                            );
                            ref
                                .read(stockCountsProvider.notifier)
                                .addCount(newCount);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Cloned to count ${newCount.stockCountNum}',
                                ),
                              ),
                            );
                          } else if (value == 'inactive') {
                            ref
                                .read(stockCountsProvider.notifier)
                                .updateCount(
                                  selectedCount.copyWith(isActive: false),
                                );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Recurring stock count marked inactive.',
                                ),
                              ),
                            );
                          } else if (value == 'delete') {
                            ref
                                .read(stockCountsProvider.notifier)
                                .deleteCount(selectedCount.id);
                            context.go(
                              '/$orgId${AppRoutes.recurringStockCounts}',
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recurring stock count deleted.'),
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          _buildRecurringOverviewMenuItem(
                            value: 'clone',
                            label: 'Clone',
                          ),
                          _buildRecurringOverviewMenuItem(
                            value: 'inactive',
                            label: 'Mark as Inactive',
                          ),
                          _buildRecurringOverviewMenuItem(
                            value: 'delete',
                            label: 'Delete',
                          ),
                        ],
                        child: SizedBox(
                          width: 78,
                          height: 38,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                              ),
                            ),
                            child: const Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'More',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(LucideIcons.chevronDown, size: 13),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => context.go(
                          '/$orgId${AppRoutes.recurringStockCounts}',
                        ),
                        icon: const Icon(
                          LucideIcons.x,
                          size: 22,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildRecurringTab('Overview', 0),
                      _buildRecurringTab('Item Details', 1),
                      _buildRecurringTab('Recent Activities', 2),
                    ],
                  ),
                ),
                Expanded(
                  child: _recurringSelectedTab == 0
                      ? _buildRecurringOverviewTab(selectedCount, df, orgId)
                      : _recurringSelectedTab == 1
                      ? _buildRecurringItemDetailsTab(selectedCount)
                      : _buildRecurringActivitiesTab(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringTab(String label, int index) {
    final isActive = _recurringSelectedTab == index;
    return InkWell(
      onTap: () => setState(() => _recurringSelectedTab = index),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 14),
        margin: const EdgeInsets.only(right: 36),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF2563EB) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? const Color(0xFF111827) : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringOverviewTab(
    StockCount count,
    DateFormat df,
    String orgId,
  ) {
    final recurringKey = count.recurringName?.trim().isNotEmpty == true
        ? count.recurringName!.trim()
        : count.stockCountNum.trim();
    final generatedCounts = ref
        .watch(stockCountsProvider)
        .counts
        .where(
          (generatedCount) =>
              !generatedCount.isRecurring &&
              (generatedCount.recurringName?.trim() ?? '') == recurringKey,
        )
        .where(_matchesRecurringOverviewStatusFilter)
        .toList()
      ..sort((a, b) => b.countDate.compareTo(a.countDate));

    final nextCountLabel = count.nextCountDate != null
        ? df.format(count.nextCountDate!)
        : '-';
    final recurringPeriod = _describeRecurringPeriod(count);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 360,
          color: const Color(0xFFFBFBFB),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ASSIGNED TO',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.user,
                        color: Color(0xFFD1D5DB),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        count.assignedTo,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Text(
                  'DETAILS',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                _buildRecurringDetailRow(
                  'Profile Status:',
                  count.isActive ? 'Active' : 'Inactive',
                  valueBackground: count.isActive
                      ? const Color(0xFFE8F7EF)
                      : const Color(0xFFF3F4F6),
                  valueColor: count.isActive
                      ? const Color(0xFF22A95E)
                      : const Color(0xFF6B7280),
                ),
                _buildRecurringDetailRow('Location:', count.location ?? '-'),
                _buildRecurringDetailRow(
                  'Schedule Type:',
                  count.scheduleType ?? '-',
                ),
                _buildRecurringDetailRow(
                  'Schedule Start Date:',
                  count.scheduleStartDate != null
                      ? df.format(count.scheduleStartDate!)
                      : '-',
                ),
                _buildRecurringDetailRow(
                  'Schedule Expiry:',
                  count.scheduleExpiry ?? '-',
                ),
                _buildRecurringDetailRow(
                  'Count Generation\nTime:',
                  count.countGenerationTime ?? '-',
                ),
                const SizedBox(height: 28),
                const Text(
                  'DESCRIPTION',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                const SizedBox(height: 16),
                Text(
                  (count.description?.trim().isNotEmpty ?? false)
                      ? count.description!
                      : 'No Description found',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(color: Color(0xFFFBFAFE)),
                child: Row(
                  children: [
                    _buildRecurringMetric('Total Items', '${count.totalItems}'),
                    _buildRecurringMetric('Next Count Date', nextCountLabel),
                    _buildRecurringMetric(
                      'Recurring Period',
                      recurringPeriod,
                      showBorder: false,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CompositedTransformTarget(
                            link: _recurringOverviewStatusLayerLink,
                            child: InkWell(
                              onTap: _toggleRecurringOverviewStatusOverlay,
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                  vertical: 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _recurringOverviewStatusFilter,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Icon(
                                      _isRecurringOverviewStatusMenuOpen
                                          ? LucideIcons.chevronUp
                                          : LucideIcons.chevronDown,
                                      size: 16,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9F9FB),
                          border: Border(
                            top: BorderSide(color: Color(0xFFEBEAF2)),
                            bottom: BorderSide(color: Color(0xFFEBEAF2)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: generatedCounts.isEmpty
                            ? const Center(
                                child: Text(
                                  'There are no Stock Counts.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: generatedCounts.length,
                                separatorBuilder: (_, __) => const Divider(
                                  height: 1,
                                  color: Color(0xFFE5E7EB),
                                ),
                                itemBuilder: (context, index) {
                                  final generatedCount = generatedCounts[index];
                                  final countedItems =
                                      _countRecurringOverviewCountedItems(
                                        generatedCount,
                                      );
                                  final statusText = _recurringOverviewStatusText(
                                    generatedCount.status,
                                  );
                                  final statusColor =
                                      _recurringOverviewStatusColor(
                                        generatedCount.status,
                                      );
                                  return InkWell(
                                    onTap: () => context.go(
                                      '/$orgId${AppRoutes.stockCountsDetail.replaceAll(':id', generatedCount.id)}',
                                    ),
                                    hoverColor: const Color(0xFFF9FAFB),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 12,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  generatedCount.stockCountNum,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                df.format(
                                                  generatedCount.countDate,
                                                ),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      LucideIcons.clipboardList,
                                                      size: 13,
                                                      color: Color(
                                                        0xFF9CA3AF,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    RichText(
                                                      text: TextSpan(
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: Color(
                                                            0xFF6B7280,
                                                          ),
                                                        ),
                                                        children: [
                                                          const TextSpan(
                                                            text:
                                                                'Items Counted : ',
                                                          ),
                                                          TextSpan(
                                                            text:
                                                                '$countedItems',
                                                            style:
                                                                const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color(
                                                                    0xFF111827,
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                statusText,
                                                textAlign: TextAlign.right,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ],
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
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecurringItemDetailsTab(StockCount count) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF9F9FB),
            border: Border(bottom: BorderSide(color: Color(0xFFEBEAF2))),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFEBEAF2))),
                  ),
                  child: const Text(
                    'ITEM DETAILS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFEBEAF2))),
                  ),
                  child: const Text(
                    'SKU',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: count.items.length,
            itemBuilder: (context, index) {
              final item = count.items[index];
              final unit = (item['unit'] ?? 'pcs').toString();
              final sku = (item['sku'] ?? '').toString();
              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFEBEAF2))),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Color(0xFFEBEAF2)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.image,
                                  size: 18,
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${item['name'] ?? '-'}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF111827),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      unit,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                          decoration: const BoxDecoration(
                            border: Border(
                              right: BorderSide(color: Color(0xFFEBEAF2)),
                            ),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            sku.isEmpty ? '-' : sku,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111827),
                            ),
                          ),
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
    );
  }

  Widget _buildRecurringActivitiesTab() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(88, 36, 88, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text(
                  '19-06-2026',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                SizedBox(height: 8),
                Text(
                  '04:45 PM',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 34),
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
              Container(width: 1, height: 110, color: const Color(0xFF3B82F6)),
            ],
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Recurring stock count created.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF111827),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'by zabnixprivatelimited',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringDetailRow(
    String label,
    String value, {
    Color? valueBackground,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          Expanded(
            child: valueBackground != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      color: valueBackground,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: valueColor ?? const Color(0xFF111827),
                        ),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringMetric(
    String label,
    String value, {
    bool showBorder = true,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          border: showBorder
              ? const Border(right: BorderSide(color: Color(0xFFE5E7EB)))
              : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF111827),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _describeRecurringPeriod(StockCount count) {
    final frequency = count.frequency ?? '';
    final normalized = frequency.toLowerCase();
    if (normalized.contains('day')) return 'Runs everyday.';
    if (normalized.contains('week')) return 'Runs every week.';
    if (normalized.contains('month')) return 'Runs every month.';
    if (normalized.contains('year')) return 'Runs every year.';
    return frequency.isEmpty ? '-' : 'Runs $frequency.';
  }

  void _toggleRecurringOverviewStatusOverlay() {
    if (_isRecurringOverviewStatusMenuOpen) {
      _closeRecurringOverviewStatusOverlay();
    } else {
      _showRecurringOverviewStatusOverlay();
    }
  }

  void _showRecurringOverviewStatusOverlay() {
    if (_recurringOverviewStatusOverlayEntry != null) return;

    const statusOptions = <String>[
      'All',
      'Yet To Start',
      'Counting In Progress',
      'Pending Approval',
      'Completed',
      'Cancelled',
      'Expired',
    ];

    _recurringOverviewStatusOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeRecurringOverviewStatusOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _recurringOverviewStatusLayerLink,
              targetAnchor: Alignment.bottomLeft,
              followerAnchor: Alignment.topLeft,
              offset: const Offset(0, 6),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    children: statusOptions.map((option) {
                      return _buildRecurringOverviewStatusItem(option);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    setState(() => _isRecurringOverviewStatusMenuOpen = true);
    Overlay.of(context).insert(_recurringOverviewStatusOverlayEntry!);
  }

  void _closeRecurringOverviewStatusOverlay() {
    if (_recurringOverviewStatusOverlayEntry != null) {
      _recurringOverviewStatusOverlayEntry!.remove();
      _recurringOverviewStatusOverlayEntry = null;
      if (mounted) {
        setState(() => _isRecurringOverviewStatusMenuOpen = false);
      }
    }
  }

  Widget _buildRecurringOverviewStatusItem(String label) {
    final isSelected = _recurringOverviewStatusFilter == label;
    bool isHovered = false;

    return StatefulBuilder(
      builder: (context, setStateItem) {
        return InkWell(
          onTap: () {
            setState(() => _recurringOverviewStatusFilter = label);
            _closeRecurringOverviewStatusOverlay();
          },
          onHover: (value) {
            setStateItem(() => isHovered = value);
          },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: isHovered
                  ? const Color(0xFF4285F4)
                  : (isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isHovered
                    ? Colors.white
                    : (isSelected
                          ? const Color(0xFF374151)
                          : const Color(0xFF4B5563)),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleRecurringMoreMenuOverlay() {
    if (_isRecurringMoreMenuOpen) {
      _closeRecurringMoreMenuOverlay();
    } else {
      _showRecurringMoreMenuOverlay();
    }
  }

  void _closeRecurringMoreMenuOverlay() {
    if (_recurringMoreMenuOverlayEntry != null) {
      _recurringMoreMenuOverlayEntry!.remove();
      _recurringMoreMenuOverlayEntry = null;
      if (mounted) {
        setState(() {
          _isRecurringMoreMenuOpen = false;
          _isRecurringSortByOpen = false;
        });
      }
    }
  }

  void _refreshRecurringOverviewList() {
    setState(() {
      _recurringSortByField = 'Stock Count Name';
      _recurringSortAscending = true;
    });
    _closeRecurringMoreMenuOverlay();
  }

  void _showRecurringMoreMenuOverlay() {
    if (_recurringMoreMenuOverlayEntry != null) return;
    _recurringMoreMenuOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeRecurringMoreMenuOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _recurringMoreMenuLayerLink,
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
                        if (_isRecurringSortByOpen) ...[
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
                                _buildRecurringSortSubMenuItem(
                                  field: 'Stock Count Name',
                                  isFirst: true,
                                  setStateOverlay: setStateOverlay,
                                ),
                                _buildRecurringSortSubMenuItem(
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
                                  if (!_isRecurringSortByOpen) {
                                    setStateOverlay(() {
                                      _isRecurringSortByOpen = true;
                                    });
                                  }
                                },
                                child: InkWell(
                                  onTap: () {
                                    setStateOverlay(() {
                                      _isRecurringSortByOpen =
                                          !_isRecurringSortByOpen;
                                    });
                                  },
                                  hoverColor: Colors.transparent,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _isRecurringSortByOpen
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
                                          color: _isRecurringSortByOpen
                                              ? Colors.white
                                              : const Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Sort by',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: _isRecurringSortByOpen
                                                ? Colors.white
                                                : const Color(0xFF374151),
                                          ),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          LucideIcons.chevronRight,
                                          size: 14,
                                          color: _isRecurringSortByOpen
                                              ? Colors.white
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              _buildRecurringMoreMenuItem(
                                icon: LucideIcons.refreshCw,
                                label: 'Refresh List',
                                isLast: true,
                                onTap: _refreshRecurringOverviewList,
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
    if (mounted) setState(() => _isRecurringMoreMenuOpen = true);
    Overlay.of(context).insert(_recurringMoreMenuOverlayEntry!);
  }

  Widget _buildRecurringMoreMenuItem({
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

  Widget _buildRecurringSortSubMenuItem({
    required String field,
    bool isFirst = false,
    bool isLast = false,
    required StateSetter setStateOverlay,
  }) {
    final isSelected = _recurringSortByField == field;
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
                if (_recurringSortByField == field) {
                  _recurringSortAscending = !_recurringSortAscending;
                } else {
                  _recurringSortByField = field;
                  _recurringSortAscending = true;
                }
              });
              _closeRecurringMoreMenuOverlay();
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
                      _recurringSortAscending
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

  Widget _buildAdjustmentReasonHeaderCell(List<String> unmatchedItemNames) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'ADJUSTMENT REASON',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: () {
              // Find first reason already chosen by user
              final firstReason = _adjustmentReasons.values.firstWhere(
                (r) => r.isNotEmpty,
                orElse: () => '',
              );
              if (firstReason.isNotEmpty) {
                setState(() {
                  // Apply to ALL unmatched items, not just already-keyed ones
                  for (final name in unmatchedItemNames) {
                    _adjustmentReasons[name] = firstReason;
                  }
                });
              }
            },
            child: const Text(
              'COPY TO ALL',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wrapHeaderWithExpiredOpacity(Widget child, StockCountStatus status) {
    if (status == StockCountStatus.expired ||
        status == StockCountStatus.yetToStart) {
      return Opacity(opacity: 0.3, child: child);
    }
    return child;
  }

  PopupMenuItem<String> _buildHoverableMenuItem({
    required String value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: _HoverablePopupMenuItemContent(icon: icon, label: label),
    );
  }

  PopupMenuItem<String> _buildRecurringOverviewMenuItem({
    required String value,
    required String label,
  }) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: _RecurringOverviewPopupMenuItemContent(label: label),
    );
  }

  Widget _buildTableHeaderCell(String label, {bool showInfo = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          if (showInfo) ...[
            const SizedBox(width: 4),
            ZTooltip(
              message:
                  'System Quantity is the physical stock in Zoho Inventory that is available in hand when the stock count is initiated.',
              child: const Icon(
                LucideIcons.helpCircle,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTableCellWidget(
    Widget child, {
    Alignment alignment = Alignment.centerRight,
    Color? bgColor,
  }) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.fill,
      child: Container(
        color: bgColor,
        alignment: alignment,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: child,
      ),
    );
  }

  Widget _buildOverviewMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    bool showInfo = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Center(child: Icon(icon, size: 16, color: iconColor)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showInfo) ...[
                  const SizedBox(width: 4),
                  ZTooltip(
                    message:
                        'Accuracy shows how accurate your stock count is. It is calculated on the average of the line item accuracy. Line item level accuracy = (counted physical stock / system physical stock)*100',
                    child: const Icon(
                      LucideIcons.helpCircle,
                      size: 14,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopAdjustmentReasonBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Adjustment Reason',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B7280),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              border: Border.all(color: const Color(0xFFFFEDD5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(LucideIcons.fileText, size: 13, color: Color(0xFF1F2937)),
                SizedBox(width: 6),
                Text(
                  '2 Stocktaking results',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustmentsCard(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 720,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _isAdjustmentsExpanded = !_isAdjustmentsExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Inventory Adjustments',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '1',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      _isAdjustmentsExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: const Color(0xFF6B7280),
                    ),
                  ],
                ),
              ),
            ),
            if (_isAdjustmentsExpanded) ...[
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FlexColumnWidth(1.5),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Reason',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Divider
                    TableRow(
                      children: [
                        Container(height: 1, color: const Color(0xFFF3F4F6)),
                        Container(height: 1, color: const Color(0xFFF3F4F6)),
                        Container(height: 1, color: const Color(0xFFF3F4F6)),
                      ],
                    ),
                    // Data Row
                    TableRow(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Text(
                            DateFormat('dd-MM-yyyy').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: Text(
                            _adjustmentReasons.values.firstWhere(
                              (r) => r.isNotEmpty,
                              orElse: () => 'Stocktaking results',
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12, bottom: 8),
                          child: const Text(
                            'ADJUSTED',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 92,
      height: 30,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: 13,
          color: isSelected ? activeColor : const Color(0xFF6B7280),
        ),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isSelected ? activeColor : const Color(0xFF374151),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? activeBg : Colors.white,
          side: BorderSide(
            color: isSelected ? activeColor : const Color(0xFFD1D5DB),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildReasonDropdown(String itemName) {
    final currentReason = _adjustmentReasons[itemName];
    final items = _reasonOptions.isEmpty
        ? const ['Stocktaking results']
        : _reasonOptions.map((reason) => reason.name).toList();
    return SizedBox(
      width: 170,
      height: 36,
      child: FormDropdown<String>(
        value: items.contains(currentReason) ? currentReason : null,
        hint: 'Select a reason',
        items: items,
        showSearch: false,
        onChanged: (v) {
          setState(() {
            if (v != null) {
              _adjustmentReasons[itemName] = v;
            } else {
              _adjustmentReasons.remove(itemName);
            }
          });
        },
        padding: const EdgeInsets.symmetric(horizontal: 8),
        textStyle: const TextStyle(fontSize: 13),
        itemBuilder: (item, isSelected, isHovered) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isHovered
                  ? const Color(0xFF2563EB)
                  : (isSelected ? const Color(0xFFEFF6FF) : Colors.transparent),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                color: isHovered
                    ? Colors.white
                    : (isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF374151)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildApprovingFooter(
    BuildContext context,
    String orgId,
    StockCount count,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: () {
              final approvedCount = _itemDecisions.values
                  .where((v) => v == 'Approve')
                  .length;
              final rejectedCount = _itemDecisions.values
                  .where((v) => v == 'Reject')
                  .length;
              showDialog(
                context: context,
                builder: (context) {
                  return Dialog(
                    alignment: Alignment.topCenter,
                    insetPadding: const EdgeInsets.only(
                      top: 0,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    child: Container(
                      width: 480,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 32,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Approval Summary',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(
                                  LucideIcons.x,
                                  color: Color(0xFFEF4444),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 16),
                          const Text(
                            'You have approved/rejected the following items.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (approvedCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEFFBFA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.check,
                                      color: Color(0xFF10B981),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Approved($approvedCount)',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'An Inventory Adjustment will be posted for the approved items with difference.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (rejectedCount > 0) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE5E7EB),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFEF2F2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.x,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Rejected($rejectedCount)',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'A new stock count is suggested for these items as they have been rejected. No inventory adjustment will be created for these items, hence, the stock will not be affected.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: _isSubmittingApproval
                                    ? null
                                    : () => _submitStockCountApproval(
                                          context,
                                          count,
                                          orgId,
                                        ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  _isSubmittingApproval ? 'Saving...' : 'Save',
                                ),
                              ),
                              const SizedBox(width: 12),
                              OutlinedButton(
                                onPressed: _isSubmittingApproval
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF374151),
                                  side: const BorderSide(
                                    color: Color(0xFFD1D5DB),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22A95E),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Proceed To Approve'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {
              setState(() {
                _isApprovingMode = false;
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton(
    String text, {
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
  }) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFF374151),
            fontWeight: fontWeight,
            fontStyle: fontStyle,
            decoration: decoration,
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsSidebar(BuildContext context) {
    return Drawer(
      width: 450,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: StatefulBuilder(
          builder: (context, setSidebarState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Comments & History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          LucideIcons.x,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // Comment Editor Box
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Formatting bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: Row(
                          children: [
                            _buildToolbarButton(
                              'B',
                              fontWeight: FontWeight.bold,
                            ),
                            const SizedBox(width: 8),
                            _buildToolbarButton(
                              'I',
                              fontStyle: FontStyle.italic,
                            ),
                            const SizedBox(width: 8),
                            _buildToolbarButton(
                              'U',
                              decoration: TextDecoration.underline,
                            ),
                          ],
                        ),
                      ),
                      // Text Area
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextField(
                          controller: _commentController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Type your comment here...',
                            hintStyle: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(fontSize: 13),
                          onChanged: (val) {
                            setSidebarState(() {});
                          },
                        ),
                      ),
                      // Add Comment Button
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 12),
                        child: ElevatedButton(
                          onPressed: _commentController.text.trim().isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    _comments.insert(0, {
                                      'author': 'zabnixprivatelimited',
                                      'date': DateFormat(
                                        'dd-MM-yyyy hh:mm a',
                                      ).format(DateTime.now()),
                                      'message': _commentController.text.trim(),
                                      'isHistory': false,
                                    });
                                  });
                                  _commentController.clear();
                                  setSidebarState(() {});
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF3F4F6),
                            disabledBackgroundColor: const Color(0xFFF9FAFB),
                            foregroundColor: const Color(0xFF4B5563),
                            disabledForegroundColor: const Color(0xFF9CA3AF),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: const Text(
                            'Add Comment',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ALL COMMENTS Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'ALL COMMENTS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${_comments.length}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // Comments List
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: _comments.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      final isHistory = comment['isHistory'] == true;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isHistory
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFCCCCCC),
                                width: 1.5,
                              ),
                              color: Colors.white,
                            ),
                            child: Icon(
                              isHistory
                                  ? LucideIcons.fileText
                                  : LucideIcons.user,
                              size: 14,
                              color: isHistory
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment['author'] as String,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '•',
                                      style: TextStyle(
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      comment['date'] as String,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: const Color(0xFFF1F5F9),
                                    ),
                                  ),
                                  child: Text(
                                    comment['message'] as String,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF374151),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HoverablePopupMenuItemContent extends StatefulWidget {
  final IconData icon;
  final String label;
  const _HoverablePopupMenuItemContent({
    required this.icon,
    required this.label,
  });

  @override
  State<_HoverablePopupMenuItemContent> createState() =>
      _HoverablePopupMenuItemContentState();
}

class _HoverablePopupMenuItemContentState
    extends State<_HoverablePopupMenuItemContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: _isHovered ? const Color(0xFF2563EB) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              widget.icon,
              size: 14,
              color: _isHovered ? Colors.white : const Color(0xFF2563EB),
            ),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                color: _isHovered ? Colors.white : const Color(0xFF374151),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringOverviewPopupMenuItemContent extends StatefulWidget {
  final String label;

  const _RecurringOverviewPopupMenuItemContent({required this.label});

  @override
  State<_RecurringOverviewPopupMenuItemContent> createState() =>
      _RecurringOverviewPopupMenuItemContentState();
}

class _RecurringOverviewPopupMenuItemContentState
    extends State<_RecurringOverviewPopupMenuItemContent> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF4F8DF7) : Colors.transparent,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: _isHovered ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}
