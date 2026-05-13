import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';

import 'package:skeletonizer/skeletonizer.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_state.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/modules/auth/services/permission_service.dart';
import 'package:zerpai_erp/modules/auth/widgets/permission_wrapper.dart';

import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'dialogs/bulk_update_dialog.dart';
import 'dialogs/export_items_dialog.dart';
import 'dialogs/import_items_dialog.dart';
import 'items_filter_dropdown.dart';
import 'items_filters.dart';
import 'item_row.dart';
import 'itemsgrid_view.dart';
import 'itemslist_view.dart';

part 'sections/items_report_body_menu.dart';
part 'sections/items_report_body_actions.dart';
part 'sections/items_report_body_table.dart';
part 'sections/items_report_body_components.dart';

enum _ItemsMoreAction {
  importItems,
  importItemImages,
  exportItems,
  exportCurrentItem,
  preferences,
  refreshList,
  resetColumnWidth,
}

enum _ItemsSortField {
  name,
  reorderLevel,
  sku,
  stockOnHand,
  hsnSacRate,
  createdTime,
  lastModifiedTime,
}

enum _ItemsViewMode { list, grid }

enum _SelectionOverflowAction { disableBin, delete }

class ItemsReportBody extends ConsumerStatefulWidget {
  final List<ItemRow> items;
  final ItemsFilter filter;
  final ValueChanged<ItemsFilter> onFilterChanged;
  final ValueChanged<ItemRow> onItemTap;
  final bool isLoading;
  final Future<int> Function(Set<String> ids, bool isActive)? onBulkSetActive;
  final Future<int> Function(Set<String> ids, bool isLock)? onBulkSetLock;
  final Future<int> Function(Set<String> ids)? onBulkDelete;
  final FocusNode? searchFocusNode;
  final String? initialSearchQuery;

  const ItemsReportBody({
    super.key,
    required this.items,
    required this.filter,
    required this.onFilterChanged,
    required this.onItemTap,
    this.isLoading = false,
    this.onBulkSetActive,
    this.onBulkSetLock,
    this.onBulkDelete,
    this.searchFocusNode,
    this.initialSearchQuery,
  });

  @override
  ConsumerState<ItemsReportBody> createState() => _ItemsReportBodyState();
}

class _ItemsReportBodyState extends ConsumerState<ItemsReportBody> {
  void updateState(void Function() fn) => setState(fn);

  final GlobalKey _moreButtonKey = GlobalKey();
  final double _moreMenuWidth = 260.0;
  final double _importMenuWidth = 200.0;
  final double _exportMenuWidth = 200.0;
  final double _sortMenuWidth = 220.0;

  OverlayEntry? _moreMenuEntry;
  OverlayEntry? _importMenuEntry;
  OverlayEntry? _exportMenuEntry;
  OverlayEntry? _sortMenuEntry;

  bool _isHoveringSortRow = false;
  bool _isHoveringSortMenu = false;
  bool _isHoveringImportRow = false;
  bool _isHoveringImportMenu = false;
  bool _isHoveringExportRow = false;
  bool _isHoveringExportMenu = false;

  Offset? _moreMenuTopLeft;
  _ItemsSortField _currentSortField = _ItemsSortField.name;
  bool _isAscending = true;

  int _currentPage = 1;
  final GlobalKey _paginationKey = GlobalKey();
  OverlayEntry? _paginationMenuEntry;

  _ItemsViewMode _viewMode = _ItemsViewMode.list;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedIds = {};
  int _resetWidthsCounter = 0;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final initialQuery = widget.initialSearchQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
      _searchQuery = initialQuery;
    }
  }

  @override
  void didUpdateWidget(covariant ItemsReportBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pruneSelectionAgainstCurrentItems();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    updateState(() {
      _searchQuery = value;
      _currentPage = 1;
    });

    // Allow empty values to pass through to the debouncer so search can be reset

    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      // Use the unified performSearch which handles server-side search correctly
      // and triggers the skeleton list (which we now keep focus through).
      await ref.read(itemsControllerProvider.notifier).performSearch(value);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  bool get _hasSelection => _selectedIds.isNotEmpty;

  void _pruneSelectionAgainstCurrentItems() {
    if (widget.isLoading || _selectedIds.isEmpty) return;
    final validIds = widget.items.map((row) => row.selectionId).toSet();
    final pruned = _selectedIds.where(validIds.contains).toSet();
    if (pruned.length != _selectedIds.length) {
      _selectedIds = pruned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int itemsPerPage = ref.watch(itemsPerPageProvider);
    final List<ItemRow> sortedItems = _sortedItems();
    final int totalLoadedItems = sortedItems.length;
    final int totalItemsReal =
        ref.watch(itemsControllerProvider).totalItemsCount ?? totalLoadedItems;

    // Ensure current page is valid after filter/perPage changes
    final maxPages = (totalItemsReal / itemsPerPage)
        .ceil()
        .clamp(1, double.infinity)
        .toInt();
    if (_currentPage > maxPages) _currentPage = maxPages;

    final startIndex = (_currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, totalItemsReal);

    final pagedItems = sortedItems.sublist(
      startIndex.clamp(0, totalLoadedItems),
      endIndex.clamp(0, totalLoadedItems),
    );

    final rangeStart = totalItemsReal == 0 ? 0 : startIndex + 1;
    final rangeEnd = endIndex;
    final bool isSinglePage = totalItemsReal <= itemsPerPage;

    final itemsToDisplay = widget.isLoading ? ItemRow.dummyList(10) : pagedItems;

    return Column(
      children: [
        _buildToolbar(sortedItems),
        if (ref.watch(itemsControllerProvider).isSearching)
          const LinearProgressIndicator(
            minHeight: 2,
            backgroundColor: Colors.transparent,
          ),
        Expanded(
          child: Skeletonizer(
            enabled: widget.isLoading,
            ignoreContainers: true,
            child: _viewMode == _ItemsViewMode.list
                ? ItemsListView(
                    items: itemsToDisplay,
                    allSelected: _allSelected(itemsToDisplay),
                    onToggleAll: (v) => _toggleAll(itemsToDisplay, v),
                    selectedIds: widget.isLoading ? {} : _selectedIds,
                    onSelectionChanged: _onSelectionChanged,
                    isNameSorted: !widget.isLoading &&
                        _currentSortField == _ItemsSortField.name,
                    isNameAscending: _isAscending,
                  onToggleNameSort: () {
                    setState(() {
                      if (_currentSortField == _ItemsSortField.name) {
                        _isAscending = !_isAscending;
                      } else {
                        _currentSortField = _ItemsSortField.name;
                        _isAscending = true;
                      }
                    });
                  },
                  isReorderSorted:
                      _currentSortField == _ItemsSortField.reorderLevel,
                  isReorderAscending: _isAscending,
                  onToggleReorderSort: () {
                    setState(() {
                      if (_currentSortField == _ItemsSortField.reorderLevel) {
                        _isAscending = !_isAscending;
                      } else {
                        _currentSortField = _ItemsSortField.reorderLevel;
                        _isAscending = true;
                      }
                    });
                  },
                  isHsnSorted: _currentSortField == _ItemsSortField.hsnSacRate,
                  isHsnAscending: _isAscending,
                  onToggleHsnSort: () {
                    setState(() {
                      if (_currentSortField == _ItemsSortField.hsnSacRate) {
                        _isAscending = !_isAscending;
                      } else {
                        _currentSortField = _ItemsSortField.hsnSacRate;
                        _isAscending = true;
                      }
                    });
                  },
                  isSkuSorted: _currentSortField == _ItemsSortField.sku,
                  isSkuAscending: _isAscending,
                  onToggleSkuSort: () {
                    setState(() {
                      if (_currentSortField == _ItemsSortField.sku) {
                        _isAscending = !_isAscending;
                      } else {
                        _currentSortField = _ItemsSortField.sku;
                        _isAscending = true;
                      }
                    });
                  },
                  isStockSorted:
                      _currentSortField == _ItemsSortField.stockOnHand,
                  isStockAscending: _isAscending,
                  onToggleStockSort: () {
                    setState(() {
                      if (_currentSortField == _ItemsSortField.stockOnHand) {
                        _isAscending = !_isAscending;
                      } else {
                        _currentSortField = _ItemsSortField.stockOnHand;
                        _isAscending = true;
                      }
                    });
                  },
                  resetWidthsTrigger: _resetWidthsCounter,
                  onItemTap: widget.onItemTap,
                )
              : ItemsGridView(
                  items: itemsToDisplay,
                  selectedIds: widget.isLoading ? {} : _selectedIds,
                  onSelectionChanged: _onSelectionChanged,
                  onItemTap: widget.onItemTap,
                ),
          ),
        ),
        _buildTableFooter(
          totalItems: totalItemsReal,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          isSinglePage: isSinglePage,
          onPrevPage: _currentPage > 1
              ? () => setState(() => _currentPage--)
              : null,
          onNextPage: _currentPage < maxPages
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );
  }

  void _onSelectionChanged(Set<String> newSelection) {
    setState(() {
      _selectedIds.clear();
      _selectedIds.addAll(newSelection);
    });
  }
}
