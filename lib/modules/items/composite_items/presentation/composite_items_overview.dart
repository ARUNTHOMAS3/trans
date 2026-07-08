// lib/modules/items/composite_items/presentation/overview.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/tables/split_list_detail_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/modules/items/items/presentation/pages/stock_adjustment_page.dart';
import '../models/composite_item.dart';
import '../providers/composite_items_provider.dart';
import 'composite_item_visual_theme.dart';
import 'dialogs/move_to_another_item_dialog.dart';

class CompositeItemsOverview extends ConsumerStatefulWidget {
  final String itemId;
  final bool isAdjustingStock;
  final String initialTab;

  const CompositeItemsOverview({
    super.key,
    required this.itemId,
    this.isAdjustingStock = false,
    this.initialTab = 'Overview',
  });

  @override
  ConsumerState<CompositeItemsOverview> createState() => _CompositeItemsOverviewState();
}

class _CompositeItemsOverviewState extends ConsumerState<CompositeItemsOverview> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  OverlayEntry? _moreMenuOverlayEntry;
  final LayerLink _moreMenuLayerLink = LayerLink();
  bool _isMoreMenuOpen = false;
  _SubMenuType _activeSubMenu = _SubMenuType.none;

  int _currentPage = 1;
  int _rowsPerPage = 25;
  bool _showTotalCount = false;
  bool _hoveringRowsPerPage = false;
  bool _hoveringPrevPage = false;
  bool _hoveringNextPage = false;

  String _selectedTab = 'Overview';
  String _locationsStockType = 'physical';
  String _transactionsFilterBy = 'Sales Orders';
  String _transactionsStatus = 'All';

  // Associated Price Lists State
  final Map<String, List<Map<String, dynamic>>> _salesPriceLists = {};
  final Map<String, List<Map<String, dynamic>>> _purchasePriceLists = {};
  bool _priceListsExpanded = true;
  String _priceListType = 'sales';

  // Filters mapping
  static const List<FavoriteFilterOption> _filterOptions = [
    FavoriteFilterOption(label: 'All Composite Items', value: 'all'),
    FavoriteFilterOption(label: 'Ungrouped Items',     value: 'ungrouped'),
    FavoriteFilterOption(label: 'Active Items',        value: 'active'),
    FavoriteFilterOption(label: 'Low Stock Items',     value: 'low_stock'),
    FavoriteFilterOption(label: 'Inactive Items',      value: 'inactive'),
    FavoriteFilterOption(label: 'Assembly',            value: 'assembly'),
    FavoriteFilterOption(label: 'Kit',                 value: 'kit'),
  ];
  late FavoriteFilterOption _selectedFilter = _filterOptions[0];

  @override
  void initState() {
    super.initState();
    const validTabs = {'Overview', 'Locations', 'Transactions', 'History'};
    _selectedTab = validTabs.contains(widget.initialTab)
        ? widget.initialTab
        : 'Overview';
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _closeMoreMenu();
    super.dispose();
  }

  List<CompositeItem> get _filteredRecords {
    final state = ref.watch(compositeItemsProvider);
    final query = _searchController.text.toLowerCase().trim();
    return state.records.where((item) {
      bool matchesFilter = true;
      switch (_selectedFilter.value) {
        case 'assembly':  matchesFilter = item.itemType == 'Assembly Item'; break;
        case 'kit':       matchesFilter = item.itemType == 'Kit Item'; break;
        case 'active':    matchesFilter = item.isActive; break;
        case 'inactive':  matchesFilter = !item.isActive; break;
        case 'low_stock': matchesFilter = item.stockQuantity < item.reorderLevel; break;
        case 'ungrouped': matchesFilter = !item.isGrouped; break;
        default:          matchesFilter = true; // 'all'
      }
      if (!matchesFilter) return false;

      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
             item.sku.toLowerCase().contains(query) ||
             item.category.toLowerCase().contains(query);
    }).toList();
  }

  void _showMoreMenu() {
    if (_moreMenuOverlayEntry != null) return;
    final overlay = Overlay.of(context);
    _moreMenuOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeMoreMenu,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _moreMenuLayerLink,
              showWhenUnlinked: false,
              followerAnchor: Alignment.topRight,
              targetAnchor: Alignment.bottomRight,
              offset: Offset(_activeSubMenu != _SubMenuType.none ? 204.0 : 0.0, 8.0),
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: _MoreMenuDropdownContent(
                  onClose: _closeMoreMenu,
                  activeSubMenu: _activeSubMenu,
                  onSubMenuChanged: (type) {
                    setState(() => _activeSubMenu = type);
                    _moreMenuOverlayEntry?.markNeedsBuild();
                  },
                  sortField: ref.watch(compositeItemsProvider).sortField,
                  sortAscending: ref.watch(compositeItemsProvider).sortAscending,
                  onSort: (field, asc) {
                    ref.read(compositeItemsProvider.notifier).sort(field, asc);
                  },
                  onRefresh: () async {
                    await ref.read(compositeItemsProvider.notifier).refresh();
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(_moreMenuOverlayEntry!);
    setState(() => _isMoreMenuOpen = true);
  }

  void _closeMoreMenu() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    setState(() {
      _isMoreMenuOpen = false;
      _activeSubMenu = _SubMenuType.none;
    });
  }

  Future<void> _pickUploadFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        if (mounted) {
          ZerpaiToast.success(context, 'Attached ${result.files.length} image(s)');
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error selecting files: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(compositeItemsProvider);
    final notifier = ref.read(compositeItemsProvider.notifier);
    final orgSystemId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

    final filteredRecords = _filteredRecords;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, filteredRecords.length);
    final paginatedRecords = filteredRecords.isNotEmpty
        ? filteredRecords.sublist(startIndex, endIndex)
        : <CompositeItem>[];

    final selectedCount = state.records.where((r) => r.isSelected).length;
    bool allSelected = paginatedRecords.isNotEmpty;
    for (final r in paginatedRecords) {
      if (!r.isSelected) {
        allSelected = false;
        break;
      }
    }

    final selectedRecord = state.records.firstWhere(
      (r) => r.id == widget.itemId,
      orElse: () => state.records.isNotEmpty ? state.records.first : CompositeItem(
        id: widget.itemId,
        name: 'Item Not Found',
        itemType: 'Unknown',
        sku: 'N/A',
        unit: 'pcs',
        category: 'N/A',
        hsnCode: 'N/A',
        taxPreference: 'N/A',
        sellingPrice: 0.00,
        costPrice: 0.00,
      ),
    );

    final isMissing = selectedRecord.name == 'Item Not Found';

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: CompositeItemVisualTheme(
        child: Container(
          color: Colors.white,
          child: SplitListDetailLayout(
          leftWidth: 300,
          leftHeader: selectedCount > 0
              ? _buildLeftBulkActionHeader(selectedCount, allSelected, startIndex, endIndex, ref, context)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  child: Row(
                    children: [
                      // Filter Dropdown
                      Expanded(
                        child: FavoriteFilterDropdown(
                          moduleName: 'composite_items',
                          options: _filterOptions,
                          selectedOption: _selectedFilter,
                          isCompact: true,
                          onChanged: (opt) => setState(() {
                            _selectedFilter = opt;
                            _currentPage = 1;
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add Button
                      ElevatedButton(
                        onPressed: () {
                          context.go('/$orgSystemId/items/composite-items/create');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(36, 36),
                          fixedSize: const Size(36, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                        child: const Icon(LucideIcons.plus, size: 12, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      // More menu
                      CompositedTransformTarget(
                        link: _moreMenuLayerLink,
                        child: IconButton(
                          onPressed: () {
                            if (_isMoreMenuOpen) {
                              _closeMoreMenu();
                            } else {
                              _showMoreMenu();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          icon: Icon(
                            LucideIcons.moreHorizontal,
                            size: 20,
                            color: _isMoreMenuOpen ? const Color(0xFF2563EB) : AppTheme.textSecondary,
                          ),
                          splashRadius: 16,
                        ),
                      ),
                    ],
                  ),
                ),
          leftBody: Column(
            children: [
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: paginatedRecords.length,
                        itemBuilder: (context, index) {
                          final r = paginatedRecords[index];
                          final isSelected = r.id == selectedRecord.id;
                          final absoluteIndex = state.records.indexOf(r);
                          return _CompositeItemListCard(
                            record: r,
                            isSelected: isSelected,
                            onTap: () {
                              context.go('/$orgSystemId/items/composite-items/${r.id}');
                            },
                            onChanged: (val) {
                              notifier.toggleRecordSelect(absoluteIndex, val ?? false);
                            },
                          );
                        },
                      ),
              ),
              _buildLeftFooter(filteredRecords.length),
            ],
          ),
          rightHeader: (isMissing || widget.isAdjustingStock) ? null : _buildRightHeader(selectedRecord),
          rightBody: isMissing
              ? _buildErrorState(context)
              : widget.isAdjustingStock
                  ? StockAdjustmentPage(
                      itemId: selectedRecord.id,
                      isEmbedded: true,
                    )
                  : _buildRightBody(selectedRecord),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftBulkActionHeader(int selectedCount, bool allSelected, int startIndex, int endIndex, WidgetRef ref, BuildContext context) {
    final state = ref.watch(compositeItemsProvider);
    final totalRecords = state.records.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth <= 320;
        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: allSelected,
                  onChanged: (val) {
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(val ?? false, startIndex, endIndex);
                  },
                  activeColor: AppTheme.primaryBlue,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  side: const BorderSide(
                    color: AppTheme.borderColor,
                    width: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Bulk Actions',
                offset: const Offset(0, 32),
                color: const Color(0xFFF9FAFB),
                surfaceTintColor: Colors.white,
                onSelected: (action) {
                  if (action == 'mark_active') {
                    ref.read(compositeItemsProvider.notifier).bulkMarkActive(true);
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    ZerpaiToast.success(context, 'Selected item(s) marked as Active');
                  } else if (action == 'mark_inactive') {
                    ref.read(compositeItemsProvider.notifier).bulkMarkActive(false);
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    ZerpaiToast.success(context, 'Selected item(s) marked as Inactive');
                  } else if (action == 'add_group') {
                    ref.read(compositeItemsProvider.notifier).bulkAddGroup();
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    ZerpaiToast.success(context, 'Selected item(s) added to group');
                  } else if (action == 'mark_returnable') {
                    ref.read(compositeItemsProvider.notifier).bulkMarkReturnable(true);
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    ZerpaiToast.success(context, 'Selected item(s) marked as Returnable');
                  } else if (action == 'enable_bin') {
                    ref.read(compositeItemsProvider.notifier).bulkEnableBinLocation(true);
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    ZerpaiToast.success(context, 'Bin location enabled for selected item(s)');
                  } else if (action == 'disable_bin') {
                    ref.read(compositeItemsProvider.notifier).bulkEnableBinLocation(false);
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    ZerpaiToast.success(context, 'Bin location disabled for selected item(s)');
                  } else if (action == 'delete') {
                    showDialog<bool>(
                      context: context,
                      builder: (context) => const _DeleteConfirmationDialog(),
                    ).then((confirmed) {
                      if (confirmed == true) {
                        ref.read(compositeItemsProvider.notifier).deleteSelected();
                        ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                        ZerpaiToast.deleted(context, 'Composite Item(s)');
                      }
                    });
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    value: 'mark_active',
                    padding: EdgeInsets.zero,
                    height: 36,
                    child: _HoverPopupMenuItem(label: 'Mark as Active'),
                  ),
                   PopupMenuItem<String>(
                    value: 'mark_inactive',
                    padding: EdgeInsets.zero,
                    height: 36,
                    child: _HoverPopupMenuItem(label: 'Mark as Inactive'),
                  ),
                  PopupMenuItem<String>(
                    value: 'mark_returnable',
                    padding: EdgeInsets.zero,
                    height: 36,
                    child: _HoverPopupMenuItem(label: 'Mark as Returnable'),
                  ),
                  PopupMenuItem<String>(
                    value: 'enable_bin',
                    padding: EdgeInsets.zero,
                    height: 36,
                    child: _HoverPopupMenuItem(label: 'Enable Bin location'),
                  ),
                  PopupMenuItem<String>(
                    value: 'disable_bin',
                    padding: EdgeInsets.zero,
                    height: 36,
                    child: _HoverPopupMenuItem(label: 'Disable Bin location'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    padding: EdgeInsets.zero,
                    height: 36,
                    child: _HoverPopupMenuItem(label: 'Delete'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Bulk Actions',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 1,
                height: 16,
                color: const Color(0xFFD1D5DB),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '$selectedCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              if (!isNarrow) ...[
                const SizedBox(width: 4),
                const Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              IconButton(
                onPressed: () {
                  ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                },
                icon: const Icon(Icons.close, size: 16, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRightHeader(CompositeItem r) {
    final orgSystemId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 450;

          final actionsRow = SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit pencil button
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(LucideIcons.edit2, size: 15, color: Color(0xFF4B5563)),
                    onPressed: () {
                      context.go('/$orgSystemId/items/composite-items/${r.id}/edit');
                    },
                  ),
                ),
                const SizedBox(width: 8),
                 // Create Assemblies button
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    onPressed: () {
                      ZerpaiToast.success(context, 'Create Assemblies clicked');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text(
                      'Create Assemblies',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // More dropdown button
                PopupMenuButton<String>(
                  tooltip: 'More Options',
                  offset: const Offset(0, 36),
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  onSelected: (val) {
                    if (val == 'clone') {
                      context.go('/$orgSystemId/items/composite-items/${r.id}/clone');
                    } else if (val == 'adjust') {
                      context.go('/$orgSystemId/items/composite-items/${r.id}/adjust-stock');
                    } else if (val == 'toggle_active') {
                      ref
                          .read(compositeItemsProvider.notifier)
                          .markActive(r.id, !r.isActive);
                      ZerpaiToast.success(
                        context,
                        r.isActive
                            ? 'Marked as inactive'
                            : 'Marked as active',
                      );
                    } else if (val == 'delete') {
                      showDialog<bool>(
                        context: context,
                        builder: (context) => const _DeleteConfirmationDialog(),
                      ).then((confirmed) {
                        if (confirmed == true) {
                          ref.read(compositeItemsProvider.notifier).removeRecord(r.id);
                          ZerpaiToast.deleted(context, 'Composite Item');
                          context.go('/$orgSystemId/items/composite-items');
                        }
                      });
                    } else if (val == 'move') {
                      final allOtherItems = ref.read(compositeItemsProvider).records
                          .where((item) => item.id != r.id)
                          .map((item) => item.name)
                          .toList();
                      if (allOtherItems.isEmpty) {
                        allOtherItems.add('demo composit item 2');
                        allOtherItems.add('demo composit item 3');
                      }
                      showDialog<String>(
                        context: context,
                        builder: (context) => MoveToAnotherItemDialog(
                          existingItemName: r.name,
                          destinationItems: allOtherItems,
                        ),
                      ).then((destination) {
                        if (destination == null) return;
                        final notifier =
                            ref.read(compositeItemsProvider.notifier);
                        notifier.recordHistory(
                          r.id,
                          'The item was moved to $destination.',
                        );
                        notifier.recordHistory(
                          r.id,
                          'Item has been removed from the Item Group - '
                          '$destination',
                        );
                      });
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem<String>(
                      value: 'clone',
                      padding: EdgeInsets.zero,
                      height: 36,
                      child: _HoverPopupMenuItem(
                        label: 'Clone Item',
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'adjust',
                      padding: EdgeInsets.zero,
                      height: 36,
                      child: _HoverPopupMenuItem(
                        label: 'Adjust Stock',
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'toggle_active',
                      padding: EdgeInsets.zero,
                      height: 36,
                      child: _HoverPopupMenuItem(
                        label: r.isActive
                            ? 'Mark as Inactive'
                            : 'Mark as Active',
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      padding: EdgeInsets.zero,
                      height: 36,
                      child: _HoverPopupMenuItem(
                        label: 'Delete',
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'move',
                      padding: EdgeInsets.zero,
                      height: 36,
                      child: _HoverPopupMenuItem(
                        label: 'Move to another item',
                      ),
                    ),
                  ],
                  child: const _HoverMoreButtonChild(),
                ),
                const SizedBox(width: 8),
                // Close button (X)
                IconButton(
                  onPressed: () {
                    context.go('/$orgSystemId/items/composite-items');
                  },
                  icon: const Icon(Icons.close, size: 18),
                  color: const Color(0xFF4B5563),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Title and Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 18, 2),
                child: isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          actionsRow,
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              r.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (!r.isActive) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              color: AppTheme.textMuted,
                              child: const Text(
                                'INACTIVE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 16),
                          Flexible(
                            child: actionsRow,
                          ),
                        ],
                      ),
              ),
              // Row 2: Returnable status
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                child: Row(
                  children: [
                    Icon(
                      r.returnable ? Icons.replay : Icons.info_outline,
                      color: const Color(0xFF6B7280),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      r.returnable ? 'Returnable Item' : 'Non-Returnable Item',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Row 3: Tab navigation
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton('Overview'),
                      _buildTabButton('Locations'),
                      _buildTabButton('Transactions'),
                      _buildTabButton('History'),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabButton(String tabName) {
    final isActive = _selectedTab == tabName;
    return InkWell(
      onTap: () {
        setState(() => _selectedTab = tabName);
        final orgSystemId =
            GoRouterState.of(context).pathParameters['orgSystemId'] ??
            '6000000000';
        context.go(
          '/$orgSystemId/items/composite-items/${widget.itemId}?tab=$tabName',
        );
      },
      child: Container(
        padding: const EdgeInsets.only(right: 28, top: 10, bottom: 9),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          tabName,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppTheme.textPrimary : AppTheme.textBody,
          ),
        ),
      ),
    );
  }

  Widget _buildRightBody(CompositeItem r) {
    switch (_selectedTab) {
      case 'Locations':
        return _buildLocationsTab(r);
      case 'Transactions':
        return _buildTransactionsTab(r);
      case 'History':
        return _buildHistoryTab(r);
      default:
        return _buildOverviewTab(r);
    }
  }

  Widget _buildOverviewTab(CompositeItem r) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useColumn = constraints.maxWidth < 650;

        final leftCol = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Primary Details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Item Name', r.name, valueColor: AppTheme.primaryBlue),
            _buildInfoRow('Item Type', r.itemType),
            _buildInfoRow('Category', r.category),
            _buildInfoRow('Unit', r.unit),
            _buildInfoRow('Created Source', 'User'),
            _buildInfoRow('Tax Preference', r.taxPreference),
            _buildInfoRow('Intra State Tax Rate', 'GST12 (12 %)'),
            _buildInfoRow('Inter State Tax Rate', 'IGST12 (12 %)'),
            _buildInfoRow('Inventory Account', 'Finished Goods'),
            _buildInfoRow('Inventory Valuation Method', 'FIFO (First In First Out)'),

            const SizedBox(height: 28),
            const Text(
              'Purchase Information',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Cost Price', '₹${r.costPrice.toStringAsFixed(2)}'),
            _buildInfoRow('Purchase Account', r.purchaseAccountName.isEmpty ? 'Cost of Goods Sold' : r.purchaseAccountName),

            const SizedBox(height: 28),
            const Text(
              'Sales Information',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Selling Price', '₹${r.sellingPrice.toStringAsFixed(2)}'),
            _buildInfoRow('Sales Account', r.accountName.isEmpty ? 'Sales' : r.accountName),

            const SizedBox(height: 28),
            const Text(
              'Reporting Tags',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'No reporting tag has been associated with this item.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),

            const SizedBox(height: 24),
            _buildAssociatedPriceListsSection(r),

            const SizedBox(height: 24),
            _buildAssociatedItemsSection(r),
          ],
        );

        final rightCol = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image upload card
            DottedBorder(
              color: const Color(0xFFD1D5DB),
              strokeWidth: 1,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(8),
              child: AspectRatio(
                aspectRatio: 1.17,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.image,
                        size: 40,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            'Drag image(s) here or ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                          ),
                          InkWell(
                            onTap: _pickUploadFiles,
                            child: const Text(
                              'Browse images',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'You can add up to 15 images, each not exceeding 5 MB in size and 7000 X 7000 pixels resolution.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Opening stock details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => _DistributionOfOpeningStockDialog(item: r),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 6),
                          const Text(
                            'Opening Stock',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                          const SizedBox(width: 4),
                          ZTooltip(
                            message: 'Initial physical inventory at start.',
                            child: const Icon(LucideIcons.helpCircle, size: 13, color: AppTheme.textSecondary),
                          ),
                          const Spacer(),
                          const Text(
                            ': 0.00',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  const SizedBox(height: 16),
                  // 2x2 grid of stock statistics
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _buildStockStatBox('0', 'Qty', 'To be Shipped'),
                      _buildStockStatBox('0', 'Qty', 'To be Received'),
                      _buildStockStatBox('0', 'Qty', 'To be Invoiced'),
                      _buildStockStatBox('0', 'Qty', 'To be Billed'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );

        final double padLeft = constraints.maxWidth < 500 ? 12.0 : 24.0;
        final double padRight = constraints.maxWidth < 500 ? 12.0 : 48.0;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(padLeft, 24.0, padRight, 28.0),
          child: useColumn
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    leftCol,
                    const SizedBox(height: 28),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 280),
                        child: rightCol,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: leftCol,
                    ),
                    const SizedBox(width: 24),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 250),
                      child: rightCol,
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildItemThumbnail(String itemName) {
    if (itemName == 'BATCH TRACK 3') {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 16,
                height: 2,
                color: const Color(0xFF2563EB),
              ),
              const SizedBox(height: 2),
              const Text(
                'batch track',
                style: TextStyle(fontSize: 4, color: Color(0xFF4B5563), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 1),
              Container(
                width: 10,
                height: 1,
                color: const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 18, color: Color(0xFF9CA3AF)),
      ),
    );
  }

  Widget _buildAssociatedItemsSection(CompositeItem r) {
    if (r.associateItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Associated Items',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              // Table Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'ITEM DETAILS',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                    Text(
                      'QUANTITY',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              // Table Rows
              ...List.generate(r.associateItems.length, (index) {
                final assocStr = r.associateItems[index];
                String name = assocStr;
                String qty = '1';

                if (assocStr.contains(' (x')) {
                  final idx = assocStr.indexOf(' (x');
                  name = assocStr.substring(0, idx);
                  final closeIdx = assocStr.indexOf(')', idx);
                  if (closeIdx != -1) {
                    qty = assocStr.substring(idx + 3, closeIdx);
                  }
                }

                final isLast = index == r.associateItems.length - 1;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: isLast
                        ? const BorderRadius.only(
                            bottomLeft: Radius.circular(5),
                            bottomRight: Radius.circular(5),
                          )
                        : null,
                    border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(
                    children: [
                      _buildItemThumbnail(name),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                      Text(
                        qty,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // Retained for the upcoming direct-create price-list action.
  // ignore: unused_element
  void _showAddPriceListDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final discountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          'Associate ${_priceListType == 'sales' ? 'Sales' : 'Purchase'} Price List',
          style: const TextStyle(color: Color(0xFF1F2937)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Price (₹)'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            if (_priceListType == 'sales')
              TextField(
                controller: discountController,
                decoration: const InputDecoration(labelText: 'Discount (%)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;
              final discount = double.tryParse(discountController.text) ?? 0.0;
              if (name.isNotEmpty) {
                setState(() {
                  final itemId = widget.itemId;
                  if (_priceListType == 'sales') {
                    if (!_salesPriceLists.containsKey(itemId)) {
                      _salesPriceLists[itemId] = [];
                    }
                    _salesPriceLists[itemId]!.add({
                      'name': name,
                      'price': price,
                      'discount': discount,
                    });
                  } else {
                    if (!_purchasePriceLists.containsKey(itemId)) {
                      _purchasePriceLists[itemId] = [];
                    }
                    _purchasePriceLists[itemId]!.add({
                      'name': name,
                      'price': price,
                    });
                  }
                });
                Navigator.pop(ctx);
                ZerpaiToast.success(context, 'Price List associated successfully');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAssociatePriceListDialog() {
    String? selectedPriceList;
    String? selectionError;
    final availablePriceLists = (_priceListType == 'sales'
            ? _salesPriceLists.values
            : _purchasePriceLists.values)
        .expand((lists) => lists)
        .map((priceList) => priceList['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(top: 0, bottom: 24),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Associate Price List',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.pop(),
                        hoverColor: AppTheme.errorBg,
                        icon: const Icon(
                          LucideIcons.x,
                          size: 20,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 140,
                            child: Text(
                              'Select Price List',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 210,
                            child: FormDropdown<String>(
                              value: selectedPriceList,
                              items: availablePriceLists,
                              hint: 'Select a Price List',
                              showSearch: false,
                              height: 38,
                              errorText: selectionError,
                              onChanged: (value) {
                                setDialogState(() {
                                  selectedPriceList = value;
                                  selectionError = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: AppTheme.borderLight),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          SizedBox(
                            height: 32,
                            child: ElevatedButton(
                              onPressed: () {
                              if (selectedPriceList == null) {
                                setDialogState(() {
                                  selectionError = availablePriceLists.isEmpty
                                      ? 'No price lists available'
                                      : 'Select a price list';
                                });
                                return;
                              }
                              context.pop();
                              ZerpaiToast.success(
                                this.context,
                                'Price List associated successfully',
                              );
                            },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 32,
                            child: OutlinedButton(
                              onPressed: () => context.pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                side: const BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textBody,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openCreatePriceListPage() {
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ??
        '6000000000';
    context.push(
      '/$orgSystemId/pricelists/price-lists/create'
      '?transactionType=$_priceListType',
    );
  }

  Widget _buildAssociatedPriceListsSection(CompositeItem r) {
    final itemId = r.id;
    final salesList = _salesPriceLists[itemId] ?? [];
    final purchaseList = _purchasePriceLists[itemId] ?? [];
    final isSales = _priceListType == 'sales';
    final listToDisplay = isSales ? salesList : purchaseList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => setState(() => _priceListsExpanded = !_priceListsExpanded),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Associated Price Lists',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _priceListsExpanded ? Icons.arrow_drop_down : Icons.arrow_right,
                    size: 18,
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
            // Segmented Toggle
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF2563EB)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: () => setState(() => _priceListType = 'sales'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSales ? const Color(0xFF2563EB) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(3),
                          bottomLeft: Radius.circular(3),
                        ),
                      ),
                      child: Text(
                        'Sales',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSales ? Colors.white : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _priceListType = 'purchase'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: !isSales ? const Color(0xFF2563EB) : Colors.white,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(3),
                          bottomRight: Radius.circular(3),
                        ),
                      ),
                      child: Text(
                        'Purchase',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: !isSales ? Colors.white : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_priceListsExpanded) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5),
                    ),
                    border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 5,
                        child: Text(
                          'NAME',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'PRICE',
                          textAlign: isSales ? TextAlign.center : TextAlign.right,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                      ),
                      if (isSales)
                        const Expanded(
                          flex: 3,
                          child: Text(
                            'DISCOUNT',
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),
                // Table Body / Empty State
                if (listToDisplay.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    alignment: Alignment.center,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'The ${_priceListType} price lists associated with this item will be displayed here. ',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        InkWell(
                          onTap: _openCreatePriceListPage,
                          child: const Text(
                            'Create Price List',
                            style: TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(listToDisplay.length, (index) {
                    final item = listToDisplay[index];
                    final isLast = index == listToDisplay.length - 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: isLast
                            ? const BorderRadius.only(
                                bottomLeft: Radius.circular(5),
                                bottomRight: Radius.circular(5),
                              )
                            : null,
                        border: isLast ? null : const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: Text(
                              item['name'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              '₹${item['price'].toStringAsFixed(2)}',
                              textAlign: isSales ? TextAlign.center : TextAlign.right,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          if (isSales)
                            Expanded(
                              flex: 3,
                              child: Text(
                                '${item['discount'].toStringAsFixed(2)}%',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // + Associate Price List Button
          InkWell(
            onTap: _showAssociatePriceListDialog,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(LucideIcons.plus, size: 16, color: Color(0xFF2563EB)),
                SizedBox(width: 6),
                Text(
                  'Associate Price List',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStockStatBox(String qty, String unit, String label) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                qty,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 2),
              Text(
                unit,
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsTab(CompositeItem r) {
    final isPhysical = _locationsStockType == 'physical';

    Widget hdrCell(String text, {int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          alignment: Alignment.center,
          child: Text(
            text.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Actions Row
          Row(
            children: [
              const Text(
                'Stock Locations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 8),
              // Gear settings button
              PopupMenuButton<String>(
                tooltip: 'Location Options',
                offset: const Offset(0, 36),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                onSelected: (val) {
                  if (val == 'add_opening_stock') {
                    final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
                    context.go('/$orgId/items/detail/${r.id}/opening-stock');
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    value: 'add_opening_stock',
                    padding: EdgeInsets.zero,
                    height: 36,
                    child: _HoverPopupMenuItem(label: 'Add Opening Stock'),
                  ),
                ],
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.settings_outlined, size: 16, color: Color(0xFF4B5563)),
                      const Icon(Icons.arrow_drop_down, size: 14, color: Color(0xFF4B5563)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Segmented Toggle
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryBlue),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Accounting Stock button
                    InkWell(
                      onTap: () => setState(() => _locationsStockType = 'accounting'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: !isPhysical ? AppTheme.primaryBlue : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(3),
                            bottomLeft: Radius.circular(3),
                          ),
                        ),
                        child: Text(
                          'Accounting Stock',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: !isPhysical ? Colors.white : AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    // Physical Stock button
                    InkWell(
                      onTap: () => setState(() => _locationsStockType = 'physical'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isPhysical ? AppTheme.primaryBlue : Colors.white,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(3),
                            bottomRight: Radius.circular(3),
                          ),
                        ),
                        child: Text(
                          'Physical Stock',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isPhysical ? Colors.white : AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Grid Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // Table Header Row 1
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: 58,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          border: Border(
                            right: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: const Text(
                          'WAREHOUSE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        height: 58,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9FAFB),
                          border: Border(
                            right: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        child: const Text(
                          'BINS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                        ),
                      ),
                    ),
                    // Physical/Accounting Stock Header section spans 3 sub-columns
                    Expanded(
                      flex: 6,
                      child: Column(
                        children: [
                          Container(
                            height: 28,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9FAFB),
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                            child: Text(
                              isPhysical ? 'PHYSICAL STOCK' : 'ACCOUNTING STOCK',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                            ),
                          ),
                          Row(
                            children: [
                              hdrCell('STOCK ON HAND', flex: 2),
                              Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
                              hdrCell('COMMITTED STOCK', flex: 2),
                              Container(width: 1, height: 30, color: const Color(0xFFE5E7EB)),
                              hdrCell('AVAILABLE FOR SALE', flex: 2),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // Table Rows
                _buildLocationRow(
                  name: 'ZABNIX PRIVATE LIMITED',
                  isPrimary: true,
                  bin: 'N/A',
                  onHand: '0.00',
                  committed: '0.00',
                  available: '0.00',
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _buildLocationRow(
                  name: 'DEMO WAREHOUSE 1 (Warehouse)',
                  isPrimary: false,
                  bin: 'N/A',
                  onHand: '0.00',
                  committed: '0.00',
                  available: '0.00',
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _buildLocationRow(
                  name: 'SAHAKAR TIRUR',
                  isPrimary: false,
                  bin: 'N/A',
                  onHand: '0.00',
                  committed: '0.00',
                  available: '0.00',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required String name,
    required bool isPrimary,
    required String bin,
    required String onHand,
    required String committed,
    required String available,
  }) {
    return Row(
      children: [
        // Location Name cell
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ),
                if (isPrimary) ...[
                  const SizedBox(width: 4),
                  const ZTooltip(
                    message: 'Primary Location',
                    direction: ZTooltipDirection.bottom,
                    child: Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Bins cell
        Expanded(
          flex: 2,
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Text(
              bin,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        ),
        // Stock values cells
        Expanded(
          flex: 6,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.center,
                  child: Text(onHand, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                ),
              ),
              Container(width: 1, height: 42, color: const Color(0xFFE5E7EB)),
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.center,
                  child: Text(committed, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                ),
              ),
              Container(width: 1, height: 42, color: const Color(0xFFE5E7EB)),
              Expanded(
                flex: 2,
                child: Container(
                  alignment: Alignment.center,
                  child: Text(available, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getStatusesForFilter(String filter) {
    switch (filter) {
      case 'Shipments':
        return [
          'All',
          'Shipped',
          'In-Transit',
          'Out For Delivery',
          'Failed Delivery Attempt',
          'Delayed',
          'Ready For Pickup',
          'Customs Clearance',
          'Delivered',
          'Delivered to PO',
          'Delivered from PickUp Point',
        ];
      case 'Packages':
        return [
          'All',
          'Not Shipped',
          'Shipped',
          'Delivered',
        ];
      case 'Delivery Challans':
        return [
          'All',
          'Draft',
          'Open',
          'Delivered',
          'Returned',
        ];
      case 'Credit Notes':
        return [
          'All',
          'Open',
          'Closed',
          'Void',
        ];
      case 'Invoices':
        return [
          'All',
          'Draft',
          'Client Viewed',
          'Partially Paid',
          'Unpaid',
          'Overdue',
          'Paid',
          'Void',
        ];
      case 'Sales Orders':
        return [
          'All',
          'Draft',
          'Confirmed',
          'Partially Shipped',
          'Shipped',
          'Closed',
          'Void',
        ];
      case 'Purchase Orders':
        return [
          'All',
          'Draft',
          'Billed',
          'Partially Billed',
          'Canceled',
          'Issued',
          'Received',
          'Partially Received',
          'Dropshipped',
        ];
      case 'Purchase Receives':
        return [
          'All',
          'Draft',
          'Received',
          'Returned',
        ];
      case 'Bills':
        return [
          'All',
          'Draft',
          'Unpaid',
          'Partially Paid',
          'Paid',
          'Overdue',
          'Void',
        ];
      case 'Vendor Credits':
        return [
          'All',
          'Open',
          'Closed',
          'Void',
        ];
      case 'Transfer Orders':
        return [
          'All',
          'Draft',
          'Pending Approval',
          'Approved',
          'Transit',
          'Received',
          'Rejected',
        ];
      default:
        return ['All'];
    }
  }


  Widget _hdrCell(String label, {required int flex, bool hasSort = false}) {
    return Expanded(
      flex: flex,
      child: hasSort
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.swap_vert, size: 12, color: AppTheme.textSecondary),
              ],
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
            ),
    );
  }

  Widget _txtCell(String val, {required int flex, bool isBold = false, bool isMuted = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        val,
        style: TextStyle(
          fontSize: 13,
          color: isMuted ? AppTheme.textSecondary : AppTheme.textPrimary,
          fontWeight: isBold ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTransactionsTab(CompositeItem r) {
    final filter = _transactionsFilterBy;
    final status = _transactionsStatus;

    bool showMockRow = false;
    List<Widget> headerColumns = [];
    List<Widget> rowCells = [];
    String emptyMessage = 'No $filter recorded yet.';

    switch (filter) {
      case 'Invoices':
        showMockRow = (status == 'All' || status == 'Draft');
        emptyMessage = 'No Invoices matching status "$status" found.';
        headerColumns = [
          _hdrCell('DATE', flex: 3, hasSort: true),
          _hdrCell('INVOICE#', flex: 3),
          _hdrCell('CUSTOMER NAME', flex: 4),
          _hdrCell('QUANTITY SOLD', flex: 3),
          _hdrCell('PRICE', flex: 3),
          _hdrCell('TOTAL', flex: 3),
          _hdrCell('STATUS', flex: 2),
        ];
        rowCells = [
          _txtCell('13-06-2026', flex: 3),
          _txtCell('INV-000088', flex: 3, isBold: true),
          _txtCell('althaf m', flex: 4),
          _txtCell('1.00', flex: 3),
          _txtCell('₹${r.sellingPrice > 0 ? r.sellingPrice.toStringAsFixed(2) : "238.00"}', flex: 3),
          _txtCell('₹${r.sellingPrice > 0 ? r.sellingPrice.toStringAsFixed(2) : "238.00"}', flex: 3),
          _txtCell('Draft', flex: 2, isMuted: true),
        ];
        break;

      default:
        break;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Filter By Dropdown Button
              PopupMenuButton<String>(
                tooltip: 'Filter By',
                offset: const Offset(0, 36),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                onSelected: (val) {
                  setState(() {
                    _transactionsFilterBy = val;
                    final newStatuses = _getStatusesForFilter(val);
                    if (!newStatuses.contains(_transactionsStatus)) {
                      _transactionsStatus = 'All';
                    }
                  });
                },
                itemBuilder: (ctx) => [
                  'Sales Orders',
                  'Invoices',
                  'Delivery Challans',
                  'Credit Notes',
                  'Packages',
                  'Shipments',
                  'Purchase Orders',
                  'Purchase Receives',
                  'Bills',
                  'Vendor Credits',
                  'Transfer Orders'
                ].map((val) => PopupMenuItem<String>(
                  value: val,
                  padding: EdgeInsets.zero,
                  height: 36,
                  child: _HoverPopupMenuItem(label: val),
                )).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Filter By: $_transactionsFilterBy',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Status Dropdown Button
              PopupMenuButton<String>(
                tooltip: 'Status',
                offset: const Offset(0, 36),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                onSelected: (val) => setState(() => _transactionsStatus = val),
                itemBuilder: (ctx) => _getStatusesForFilter(_transactionsFilterBy)
                    .map((val) => PopupMenuItem<String>(
                      value: val,
                      padding: EdgeInsets.zero,
                      height: 36,
                      child: _HoverPopupMenuItem(label: val),
                    )).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Status: $_transactionsStatus',
                        style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_drop_down, size: 14, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (headerColumns.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: headerColumns,
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  if (showMockRow)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      color: Colors.white,
                      child: Row(
                        children: rowCells,
                      ),
                    )
                  else
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      child: Text(
                        emptyMessage,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Center(
                child: Text(
                  'No $_transactionsFilterBy recorded yet.',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(CompositeItem r) {
    final history =
        ref.watch(compositeItemsProvider).historyByItemId[r.id] ?? const [];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 24, 24),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF9FAFB),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: const Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'DATE',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: Text(
                    'DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No history recorded yet.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          else
            for (final entry in history) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        _formatHistoryDate(entry.occurredAt),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 9,
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                          children: [
                            TextSpan(text: entry.details),
                            const TextSpan(
                              text: ' - ',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            TextSpan(
                              text: entry.actor,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
            ],
        ],
      ),
    );
  }

  String _formatHistoryDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$day-$month-${date.year} '
        '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 380;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppTheme.textPrimary,
                    height: 1.25,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              SizedBox(
                width: 185,
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.25,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? AppTheme.textPrimary,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftFooter(int totalCount) {
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, totalCount);

    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Total Count: ',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showTotalCount = !_showTotalCount),
                child: Text(
                  _showTotalCount ? '$totalCount' : 'View',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              PopupMenuButton<int>(
                tooltip: 'Rows per page',
                offset: const Offset(0, -120),
                color: Colors.white,
                surfaceTintColor: Colors.white,
                onSelected: (val) {
                  setState(() {
                    _rowsPerPage = val;
                    _currentPage = 1;
                  });
                },
                itemBuilder: (ctx) => [10, 25, 50, 100].map((val) => PopupMenuItem<int>(
                  value: val,
                  padding: EdgeInsets.zero,
                  height: 36,
                  child: _HoverPopupMenuItem(label: '$val per page'),
                )).toList(),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoveringRowsPerPage = true),
                  onExit: (_) => setState(() => _hoveringRowsPerPage = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                      ),
                      color: _hoveringRowsPerPage ? const Color(0xFFEFF6FF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings,
                          size: 12,
                          color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_rowsPerPage per page',
                          style: TextStyle(
                            fontSize: 11,
                            color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down,
                          size: 12,
                          color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MouseRegion(
                      onEnter: (_) => setState(() => _hoveringPrevPage = true),
                      onExit: (_) => setState(() => _hoveringPrevPage = false),
                      cursor: _currentPage > 1 ? SystemMouseCursors.click : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _hoveringPrevPage && _currentPage > 1 ? const Color(0xFFEFF6FF) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            size: 14,
                            color: _currentPage > 1
                                ? (_hoveringPrevPage ? const Color(0xFF2563EB) : const Color(0xFF374151))
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      totalCount == 0 ? '0 - 0' : '${startIndex + 1} - $endIndex',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
                    ),
                    const SizedBox(width: 6),
                    MouseRegion(
                      onEnter: (_) => setState(() => _hoveringNextPage = true),
                      onExit: (_) => setState(() => _hoveringNextPage = false),
                      cursor: endIndex < totalCount ? SystemMouseCursors.click : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: endIndex < totalCount ? () => setState(() => _currentPage++) : null,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _hoveringNextPage && endIndex < totalCount ? const Color(0xFFEFF6FF) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            size: 14,
                            color: endIndex < totalCount
                                ? (_hoveringNextPage ? const Color(0xFF2563EB) : const Color(0xFF374151))
                                : const Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.alertTriangle, size: 48, color: Colors.orange),
          const SizedBox(height: 16),
          const Text(
            'Composite Item Not Found',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}

class _CompositeItemListCard extends StatefulWidget {
  final CompositeItem record;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<bool?> onChanged;

  const _CompositeItemListCard({
    required this.record,
    required this.isSelected,
    required this.onTap,
    required this.onChanged,
  });

  @override
  State<_CompositeItemListCard> createState() => _CompositeItemListCardState();
}

class _CompositeItemListCardState extends State<_CompositeItemListCard> {
  bool _isHovered = false;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isSelected
        ? const Color(0xFFEFF6FF)
        : (_isHovered ? const Color(0xFFF9FAFB) : Colors.white);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Container(
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 11.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: widget.record.isSelected,
                        onChanged: widget.onChanged,
                        activeColor: AppTheme.primaryBlue,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                        side: const BorderSide(
                          color: AppTheme.borderColor,
                          width: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Icon(
                          _isExpanded ? LucideIcons.folderOpen : LucideIcons.folder,
                          size: 16,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.record.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    if (!widget.record.isActive) ...[
                      const SizedBox(width: 8),
                      const Text(
                        'INACTIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (_isExpanded && widget.record.associateItems.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  ...List.generate(widget.record.associateItems.length, (index) {
                    final item = widget.record.associateItems[index];
                    final isLast = index == widget.record.associateItems.length - 1;
                    return Row(
                      children: [
                        const SizedBox(width: 36),
                        SizedBox(
                          width: 16,
                          height: 32,
                          child: CustomPaint(
                            painter: _TreeLinePainter(isLast: isLast),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B5563),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HoverPopupMenuItem extends StatefulWidget {
  final String label;
  const _HoverPopupMenuItem({required this.label});

  @override
  State<_HoverPopupMenuItem> createState() => _HoverPopupMenuItemState();
}

class _HoverPopupMenuItemState extends State<_HoverPopupMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: _isHovered ? const Color(0xFF2563EB) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.centerLeft,
        width: double.infinity,
        height: 36,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [

            Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: _isHovered ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SubMenuType { none, sortBy, import }

class _MoreMenuDropdownContent extends StatefulWidget {
  final VoidCallback onClose;
  final String sortField;
  final bool sortAscending;
  final void Function(String field, bool ascending) onSort;
  final VoidCallback onRefresh;
  final _SubMenuType activeSubMenu;
  final ValueChanged<_SubMenuType> onSubMenuChanged;

  const _MoreMenuDropdownContent({
    required this.onClose,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onRefresh,
    required this.activeSubMenu,
    required this.onSubMenuChanged,
  });

  @override
  State<_MoreMenuDropdownContent> createState() => _MoreMenuDropdownContentState();
}

class _MoreMenuDropdownContentState extends State<_MoreMenuDropdownContent> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMainMenu(),
        if (widget.activeSubMenu != _SubMenuType.none) ...[
          const SizedBox(width: 4),
          _buildSubMenu(),
        ],
      ],
    );
  }

  Widget _buildMainMenu() {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.sortBy),
            child: _MoreMenuItem(
              icon: LucideIcons.arrowUpDown,
              label: 'Sort by',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.sortBy,
              onTap: () {},
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.import),
            child: _MoreMenuItem(
              icon: LucideIcons.download,
              label: 'Import',
              hasChevron: true,
              isActive: widget.activeSubMenu == _SubMenuType.import,
              onTap: () {},
            ),
          ),
          MouseRegion(
            onEnter: (_) => widget.onSubMenuChanged(_SubMenuType.none),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MoreMenuItem(
                  icon: LucideIcons.upload,
                  label: 'Export Composite Items',
                  onTap: widget.onClose,
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MoreMenuItem(
                  icon: LucideIcons.settings2,
                  label: 'Preferences',
                  onTap: widget.onClose,
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MoreMenuItem(
                  icon: LucideIcons.refreshCw,
                  label: 'Refresh List',
                  onTap: () {
                    widget.onClose();
                    widget.onRefresh();
                  },
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MoreMenuItem(
                  icon: LucideIcons.badgePercent,
                  label: 'Update New GST Rates',
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildSubMenu() {
    switch (widget.activeSubMenu) {
      case _SubMenuType.sortBy:
        return _SubMenuPanel(
          children: [
            _buildSortItem('name', 'Name'),
            _buildSortItem('sku', 'SKU'),
            _buildSortItem('reorderLevel', 'Reorder Level'),
          ],
        );
      case _SubMenuType.import:
        return _SubMenuPanel(
          children: [
            _SubMenuItem(
              label: 'Import Composite Items',
              onTap: widget.onClose,
            ),
            _SubMenuItem(
              label: 'Import Composite Items Images',
              onTap: widget.onClose,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSortItem(String field, String label) {
    final isSelected = widget.sortField == field;
    final icon = isSelected
        ? (widget.sortAscending ? Icons.arrow_upward : Icons.arrow_downward)
        : Icons.arrow_upward;

    return _SubMenuItem(
      label: label,
      rightIcon: icon,
      isSelected: isSelected,
      onTap: () {
        widget.onSort(field, isSelected ? !widget.sortAscending : true);
        widget.onClose();
      },
    );
  }
}

class _SubMenuPanel extends StatelessWidget {
  final List<Widget> children;
  const _SubMenuPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          ...children,
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _SubMenuItem extends StatefulWidget {
  final String label;
  final IconData? rightIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubMenuItem({
    required this.label,
    this.rightIcon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  State<_SubMenuItem> createState() => _SubMenuItemState();
}

class _SubMenuItemState extends State<_SubMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _hovered ? const Color(0xFF2563EB) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: _hovered
                        ? Colors.white
                        : (widget.isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF374151)),
                    fontWeight: widget.isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              if (widget.rightIcon != null && _hovered)
                Icon(
                  widget.rightIcon,
                  size: 14,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool hasChevron;
  final bool isActive;
  final VoidCallback onTap;

  const _MoreMenuItem({
    required this.icon,
    required this.label,
    this.hasChevron = false,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_MoreMenuItem> createState() => _MoreMenuItemState();
}

class _MoreMenuItemState extends State<_MoreMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isHighlighted = _hovered || widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: isHighlighted ? const Color(0xFF2563EB) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: isHighlighted ? Colors.white : const Color(0xFF374151),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isHighlighted ? Colors.white : const Color(0xFF374151),
                  ),
                ),
              ),
              if (widget.hasChevron)
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: isHighlighted ? Colors.white : const Color(0xFF9CA3AF),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverMoreButtonChild extends StatefulWidget {
  const _HoverMoreButtonChild();

  @override
  State<_HoverMoreButtonChild> createState() => _HoverMoreButtonChildState();
}

class _HoverMoreButtonChildState extends State<_HoverMoreButtonChild> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'More',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 14,
              color: _hovered ? const Color(0xFF1F2937) : const Color(0xFF4B5563),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatelessWidget {
  const _DeleteConfirmationDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFEAB308),
                  size: 26,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Are you sure about deleting the selected item(s)?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CB85C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(70, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    minimumSize: const Size(70, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkUpdateDialog extends StatefulWidget {
  final List<String> fields;
  final Function(String field, String value) onUpdate;

  const _BulkUpdateDialog({
    required this.fields,
    required this.onUpdate,
  });

  @override
  State<_BulkUpdateDialog> createState() => _BulkUpdateDialogState();
}

class _BulkUpdateDialogState extends State<_BulkUpdateDialog> {
  String? _selectedField;
  final TextEditingController _valController = TextEditingController();

  @override
  void dispose() {
    _valController.dispose();
    super.dispose();
  }

  Widget _buildRightInput() {
    if (_selectedField == 'Category') {
      final List<String> categories = ['MEDICINES', '• OTHER BRANDS', 'althu', '• deepthi'];
      return FormDropdown<String>(
        value: categories.contains(_valController.text) ? _valController.text : null,
        items: categories,
        placeholder: 'Select Category',
        height: 40,
        onChanged: (val) {
          setState(() {
            _valController.text = val ?? '';
          });
        },
      );
    } else if (_selectedField == 'Reorder Level') {
      return CustomTextField(
        controller: _valController,
        hintText: 'Enter reorder level',
        height: 40,
      );
    } else if (_selectedField == 'Manufacturer') {
      final List<String> manufacturers = ['Intel', 'AMD', 'Logitech', 'Standard Corp'];
      return FormDropdown<String>(
        value: manufacturers.contains(_valController.text) ? _valController.text : null,
        items: manufacturers,
        placeholder: 'Select Manufacturer',
        height: 40,
        onChanged: (val) {
          setState(() {
            _valController.text = val ?? '';
          });
        },
      );
    } else if (_selectedField == 'Brand') {
      final List<String> brands = ['Intel Inside', 'AMD Ryzen', 'Logitech G', 'Generic'];
      return FormDropdown<String>(
        value: brands.contains(_valController.text) ? _valController.text : null,
        items: brands,
        placeholder: 'Select Brand',
        height: 40,
        onChanged: (val) {
          setState(() {
            _valController.text = val ?? '';
          });
        },
      );
    } else if (_selectedField == 'Returnable') {
      final isYes = _valController.text == 'Yes';
      final isNo = _valController.text == 'No';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _valController.text = 'Yes';
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isYes ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                        width: isYes ? 5 : 1,
                      ),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Yes',
                    style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _valController.text = 'No';
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isNo ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                        width: isNo ? 5 : 1,
                      ),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'No',
                    style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else if (_selectedField == 'Tax Preference') {
      final List<String> taxes = ['Taxable', 'Non-Taxable', 'Out of Scope', 'Non-GST Supply'];
      return FormDropdown<String>(
        value: taxes.contains(_valController.text) ? _valController.text : null,
        items: taxes,
        placeholder: 'Select Tax Preference',
        height: 40,
        onChanged: (val) {
          setState(() {
            _valController.text = val ?? '';
          });
        },
      );
    } else {
      return CustomTextField(
        controller: _valController,
        hintText: '',
        enabled: false,
        height: 40,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        width: 560,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bulk Update Items',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.red),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 20,
                ),
              ],
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
            const Text(
              'Choose a field from the dropdown and update with new information.',
              style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: FormDropdown<String>(
                    value: _selectedField,
                    items: widget.fields,
                    placeholder: 'Select a field',
                    onChanged: (val) {
                      setState(() {
                        _selectedField = val;
                        _valController.clear();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRightInput(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: All the selected items will be updated with the new information.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_selectedField == null || _valController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a field and enter a value.'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      return;
                    }
                    widget.onUpdate(
                      _selectedField!,
                      _valController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5CB85C),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(70, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Update',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4B5563),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    minimumSize: const Size(70, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TreeLinePainter extends CustomPainter {
  final bool isLast;
  _TreeLinePainter({required this.isLast});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD1D5DB) // Light gray line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Vertical line:
    // If it's the last item, the vertical line stops at the center Y.
    // Otherwise, it goes all the way from top to bottom.
    canvas.drawLine(
      Offset(centerX, 0),
      Offset(centerX, isLast ? centerY : size.height),
      paint,
    );

    // Horizontal line:
    // Goes from center X to the right edge.
    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(size.width, centerY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DistributionOfOpeningStockDialog extends StatelessWidget {
  final CompositeItem item;
  const _DistributionOfOpeningStockDialog({required this.item});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, left: 24, right: 24, bottom: 24),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 900),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Distribution of Opening Stock',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: AppTheme.errorRed, size: 20),
                  onPressed: () => Navigator.pop(context),
                  hoverColor: AppTheme.errorBg,
                  splashRadius: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Custom Table
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                children: [
                  // Table Header
                  Container(
                    color: const Color(0xFFF9FAFB),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: const Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'ITEM NAME',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'LOCATION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'OPENING STOCK',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'OPENING STOCK VALUE',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  
                  // Table Body Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Name Column
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      // Locations & Stocks Column (with separating lines only starting from Location)
                      Expanded(
                        flex: 10,
                        child: Column(
                          children: [
                            // Location Row 1
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Row(
                                      children: const [
                                        Text(
                                          'ZABNIX PRIVATE LIMITED',
                                          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                                      ],
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 3,
                                    child: Text(
                                      '0.00',
                                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 3,
                                    child: Text(
                                      '₹0.00',
                                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            // Location Row 2
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: const [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'DEMO WAREHOUSE 1 (Warehouse)',
                                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '0.00',
                                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '₹0.00',
                                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            // Location Row 3
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: const [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      'SAHAKAR TIRUR',
                                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '0.00',
                                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '₹0.00',
                                      style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Footer Action
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
