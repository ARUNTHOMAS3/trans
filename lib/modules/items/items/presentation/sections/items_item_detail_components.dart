part of '../items_item_detail.dart';

extension _ItemDetailComponents on _ItemDetailScreenState {
  Widget _buildItemSidebar(ItemsState state) {
    final allFilteredItems = _getFilteredItems(state.items);
    final totalItemsReal = state.totalItemsCount ?? allFilteredItems.length;
    final controller = ref.read(itemsControllerProvider.notifier);

    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        children: [
          // Sidebar Header
          _selectedItemIds.isNotEmpty
              ? _buildBulkActionsHeader(totalItemsReal)
              : _buildDefaultHeader(),
          // Search Bar
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: _SidebarSearchBar(
              onSearch: (q) => controller.performSearch(q),
              onClear: () => controller.loadItems(),
              isSearching: state.isSearching,
            ),
          ),
          // Sidebar List
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 100) {
                  if (!state.hasReachedMax &&
                      !state.isLoadingList &&
                      !state.isSearching) {
                    controller.loadNextPage();
                  }
                }
                return false;
              },
              child: ListView.separated(
                itemCount:
                    allFilteredItems.length + (state.isLoadingList ? 1 : 0),
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTheme.bgDisabled),
                itemBuilder: (context, index) {
                  if (index >= allFilteredItems.length) {
                    // Loading spinner row
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  final item = allFilteredItems[index];
                  final isSelected =
                      (widget.itemId ??
                          state.selectedItemId ??
                          (state.items.isNotEmpty
                              ? state.items.first.id
                              : null)) ==
                      item.id;
                  final isChecked = _selectedItemIds.contains(
                    item.id ?? item.itemCode,
                  );
                  final bool isComposite =
                      item.compositions != null &&
                      item.compositions!.isNotEmpty;
                  final priceText = _formatMoney(item.mrp);

                  return InkWell(
                    onTap: () {
                      if (item.id != null) {
                        final qp = _buildDetailQueryParameters(_tabsForItem(item));
                        final query = qp.isNotEmpty
                            ? '?${qp.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
                            : '';
                        context.go('/items/detail/${item.id!}$query');
                      } else {
                        ref
                            .read(itemsControllerProvider.notifier)
                            .selectItem(item.id);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      color: (isSelected || isChecked)
                          ? const Color(0xFFF5F7FF)
                          : Colors.transparent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: isChecked,
                              onChanged: (value) {
                                updateState(() {
                                  final key = item.id ?? item.itemCode;
                                  if (value == true) {
                                    _selectedItemIds.add(key);
                                  } else {
                                    _selectedItemIds.remove(key);
                                  }
                                });
                              },
                              side: const BorderSide(color: AppTheme.borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.productName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? AppTheme.primaryBlueDark
                                              : AppTheme.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isComposite) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.business_center_outlined,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ],
                                  ],
                                ),
                                if (item.sku != null &&
                                    item.sku!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'SKU: ${item.sku}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.currency_rupee,
                                size: 14,
                                color: AppTheme.textPrimary,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                priceText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
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
          ),
          _buildSidebarFooter(
            totalItems: totalItemsReal,
            loadedItems: allFilteredItems.length,
            hasReachedMax: state.hasReachedMax,
            isSearching: state.isSearching,
            onLoadMore:
                state.hasReachedMax || state.isLoadingList || state.isSearching
                ? null
                : () => controller.loadNextPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ItemsFilterDropdown(
              currentFilter: _currentFilter,
              onFilterChanged: (filter) {
                final selectedId =
                    widget.itemId ??
                    ref.read(itemsControllerProvider).selectedItemId;
                final currentItem = ref
                    .read(itemsControllerProvider)
                    .items
                    .cast<Item?>()
                    .firstWhere(
                      (item) => item?.id == selectedId,
                      orElse: () => null,
                    );
                if (currentItem != null) {
                  _setCurrentFilter(filter, _tabsForItem(currentItem));
                } else {
                  updateState(() => _currentFilter = filter);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            height: 32,
            child: ElevatedButton(
              onPressed: () => context.pushNamed(AppRoutes.itemsCreate),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            key: _moreButtonKey,
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: IconButton(
              onPressed: _toggleMoreMenu,
              icon: const Icon(
                Icons.more_horiz,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionsHeader(int totalItems) {
    final bool allSelected = _selectedItemIds.length == totalItems;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: allSelected,
                onChanged: (value) {
                  updateState(() {
                    if (value == true) {
                      final state = ref.read(itemsControllerProvider);
                      final filtered = _getFilteredItems(state.items);
                      for (var it in filtered) {
                        _selectedItemIds.add(it.id ?? it.itemCode);
                      }
                    } else {
                      _selectedItemIds.clear();
                    }
                  });
                },
                side: const BorderSide(color: AppTheme.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              offset: const Offset(0, 42),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              onSelected: (value) {
                if (value == 'bulk-update') {
                  showBulkUpdateDialog(context, selectedIds: _selectedItemIds);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'bulk-update',
                  padding: EdgeInsets.zero,
                  height: 44,
                  child: Container(
                    width: double.infinity,
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: AppTheme.infoBlue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: const Text(
                      'Bulk Update',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const PopupMenuDivider(height: 1),
                _buildBulkPopupItem('sales-order', 'New Sales Order'),
                _buildBulkPopupItem('purchase-order', 'New Purchase Order'),
                const PopupMenuDivider(height: 1),
                _buildBulkPopupItem('activate', 'Mark as Active'),
                _buildBulkPopupItem('inactive', 'Mark as Inactive'),
                const PopupMenuDivider(height: 1),
                _buildBulkPopupItem('add-to-group', 'Add to group'),
                const PopupMenuDivider(height: 1),
                _buildBulkPopupItem('returnable', 'Mark as Returnable'),
                _buildBulkPopupItem('disable-bin', 'Disable Bin location'),
                _buildBulkPopupItem('delete', 'Delete'),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: AppTheme.primaryBlueDark,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Bulk Actions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: AppTheme.textPrimary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(width: 1, height: 24, color: AppTheme.borderColor),
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF2FF),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${_selectedItemIds.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Selected',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textBody,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => updateState(() => _selectedItemIds.clear()),
              icon: const Icon(Icons.close, size: 20, color: AppTheme.errorRed),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHeader(Item item) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    if (item.isTrackInventory &&
                        (item.stockOnHand ?? 0) < item.reorderPoint &&
                        item.reorderPoint > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorBg,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.errorBgBorder),
                        ),
                        child: const Text(
                          'Low Stock',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.errorRed,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (item.isReturnable) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.sync,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Returnable Item',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSubtle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () {
              if (item.id != null) {
                context.go('/items/edit/${item.id!}', extra: item);
              } else {
                context.pushNamed(AppRoutes.itemsCreate, extra: item);
              }
            },
            tooltip: 'Edit',
          ),
          const SizedBox(width: 8),
          if (item.type != 'service' && item.isTrackInventory) ...[
            ElevatedButton(
              onPressed: () {
                final warehousesAsync = ref.read(
                  itemWarehouseStocksProvider(item.id!),
                );
                final warehouses = warehousesAsync.maybeWhen(
                  data: (rows) => rows,
                  orElse: () => <WarehouseStockRow>[],
                );
                _openOpeningStockDialog(item, warehouses);
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: const Text(
                'Create Assemblies',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 8),
          ],
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            offset: const Offset(0, 40),
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            onSelected: (value) => _handleDetailMoreAction(item, value),
            itemBuilder: (context) => [
              _buildHoverMenuItem(value: 'clone', label: 'Clone Item'),
              _buildHoverMenuItem(
                value: 'toggle-active',
                label: item.isActive ? 'Mark as Inactive' : 'Mark as Active',
              ),
              _buildHoverMenuItem(value: 'delete', label: 'Delete'),
              _buildHoverMenuItem(
                value: 'toggle-lock',
                label: item.isLock ? 'Unlock Item' : 'Lock Item',
              ),
            ],
            child: OutlinedButton(
              onPressed: null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              child: Row(
                children: const [
                  Text(
                    'More',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AppRoutes.itemsReport);
              }
            },
            icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDetailMoreAction(Item item, String action) async {
    switch (action) {
      case 'clone':
        context.pushNamed(AppRoutes.itemsCreate, extra: {'cloneItem': item});
        return;
      case 'toggle-active':
        await _setItemActive(item, !item.isActive);
        return;
      case 'toggle-lock':
        await _setItemLock(item, !item.isLock);
        return;
      case 'delete':
        await _deleteItem(item);
        return;
    }
  }

  Future<void> _setItemActive(Item item, bool isActive) async {
    final id = item.id;
    if (id == null) {
      return;
    }
    final updated = item.copyWith(isActive: isActive);
    await ref.read(itemsControllerProvider.notifier).updateItem(updated);
  }

  Future<void> _setItemLock(Item item, bool isLock) async {
    final id = item.id;
    if (id == null) {
      return;
    }
    final updated = item.copyWith(isLock: isLock);
    await ref.read(itemsControllerProvider.notifier).updateItem(updated);
  }

  Future<void> _deleteItem(Item item) async {
    final id = item.id;
    if (id == null) {
      return;
    }
    await ref.read(itemsControllerProvider.notifier).deleteItem(id);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  PopupMenuEntry<String> _buildBulkPopupItem(String value, String label) {
    return PopupMenuItem<String>(
      value: value,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      height: 40,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.textBody,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSidebarFooter({
    required int totalItems,
    required int loadedItems,
    required bool hasReachedMax,
    required bool isSearching,
    VoidCallback? onLoadMore,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              isSearching
                  ? 'Found $loadedItems result${loadedItems == 1 ? '' : 's'}'
                  : 'Showing $loadedItems of $totalItems',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          if (onLoadMore != null)
            TextButton(
              onPressed: onLoadMore,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Load More'),
            )
          else if (!hasReachedMax && !isSearching)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final IconData? trailingIcon;

  const _MenuRow({required this.icon, required this.label, this.trailingIcon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
        if (trailingIcon != null) ...[
          const SizedBox(width: 6),
          Icon(trailingIcon, size: 18),
        ],
      ],
    );
  }
}

/// Stateful debounced search bar for the items sidebar.
class _SidebarSearchBar extends StatefulWidget {
  final ValueChanged<String> onSearch;
  final VoidCallback onClear;
  final bool isSearching;
  const _SidebarSearchBar({
    required this.onSearch,
    required this.onClear,
    required this.isSearching,
  });

  @override
  State<_SidebarSearchBar> createState() => _SidebarSearchBarState();
}

class _SidebarSearchBarState extends State<_SidebarSearchBar> {
  final TextEditingController _ctrl = TextEditingController();
  bool _hasText = false;
  Timer? _debounce;

  @override
  void dispose() {
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _hasText = value.isNotEmpty);
    _debounce?.cancel();

    if (value.isEmpty) {
      widget.onClear();
      return;
    }

    if (value.length < 2) return;

    // Check if it's a barcode (pure digits, length >= 8) -> immediate search
    final isBarcode = RegExp(r'^\d{8,}$').hasMatch(value);
    if (isBarcode) {
      widget.onSearch(value);
    } else {
      // Regular text -> debounce
      _debounce = Timer(const Duration(milliseconds: 300), () {
        widget.onSearch(value);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: _onChanged,
      onSubmitted: (value) {
        // Trigger immediate search on Enter
        _debounce?.cancel();
        widget.onSearch(value);
        FocusScope.of(context).unfocus();
      },
      textInputAction: TextInputAction.search,
      textAlignVertical: TextAlignVertical.center,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        hintText: 'Search items...',
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
        prefixIcon: widget.isSearching
            ? const Padding(
                padding: EdgeInsets.all(8),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.textSecondary,
                  ),
                ),
              )
            : const Icon(Icons.search, size: 18, color: AppTheme.textMuted),
        suffixIcon: _hasText
            ? IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                onPressed: () {
                  _ctrl.clear();
                  setState(() => _hasText = false);
                  widget.onClear();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.primaryBlueDark),
        ),
      ),
    );
  }
}
