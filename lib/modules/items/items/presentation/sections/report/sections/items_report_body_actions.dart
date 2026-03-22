part of '../items_report_body.dart';

extension _ItemsReportBodyActions on _ItemsReportBodyState {
  // -----------------------------------------------------------
  // HANDLERS
  // -----------------------------------------------------------

  void _showBulkUpdateDialog() {
    showBulkUpdateDialog(context, selectedIds: _selectedIds);
  }

  Future<void> _handleMoreAction(
    BuildContext context,
    _ItemsMoreAction action,
  ) async {
    String msg;
    switch (action) {
      case _ItemsMoreAction.importItems:
        final result = await showImportItemsDialog(context);
        if (!context.mounted) return;
        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import option: $result'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      case _ItemsMoreAction.exportItems:
        await showExportItemsDialog(context);
        return;
      case _ItemsMoreAction.importItemImages:
        msg = 'TODO: Import Items Images';
        break;
      case _ItemsMoreAction.exportCurrentItem:
        msg = 'TODO: Export Current Item';
        break;
      case _ItemsMoreAction.preferences:
        msg = 'TODO: Open Preferences';
        break;
      case _ItemsMoreAction.refreshList:
        msg = 'Refreshing list...';
        // In a real app, you'd trigger a reload from the controller
        break;
      case _ItemsMoreAction.resetColumnWidth:
        msg = 'Column widths reset.';
        updateState(() => _resetWidthsCounter++);
        break;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleSortField(
    BuildContext context,
    _ItemsSortField field,
    bool ascending,
  ) {
    // This is currently just a snackbar in the original code
    final dirText = ascending ? 'ascending' : 'descending';
    final label = _sortFieldLabel(field);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sorted by $label ($dirText)'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleTransactionAction(BuildContext context, String type) {
    String msg;
    switch (type) {
      case 'sales':
        msg = 'Sales Order selected';
        break;
      case 'purchase':
        msg = 'Purchase Order selected';
        break;
      default:
        msg = 'Transaction selected';
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleSelectionOverflow(
    BuildContext context,
    _SelectionOverflowAction action,
  ) {
    String msg;
    switch (action) {
      case _SelectionOverflowAction.disableBin:
        msg = 'Disable Bin location';
        break;
      case _SelectionOverflowAction.delete:
        msg = 'Delete selected';
        break;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleMarkAsActive(BuildContext context) async {
    await _applyBulkActive(context, true);
  }

  Future<void> _handleMarkAsInActive(BuildContext context) async {
    await _applyBulkActive(context, false);
  }

  void _handleMarkAsReturnable(BuildContext context) {
    final int count = _selectedIds.length;
    final String msg = count > 0
        ? '$count item(s) marked as Returnable'
        : 'No items selected';

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handlePushToEcommerce(BuildContext context) {
    final int count = _selectedIds.length;
    final String msg = count > 0
        ? '$count item(s) pushed to Ecommerce'
        : 'No items selected';

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleLockItem(BuildContext context, bool lock) async {
    final int count = _selectedIds.length;
    if (count == 0) {
      _showActionSnack(context, 'No items selected');
      return;
    }
    final updated = await widget.onBulkSetLock?.call(_selectedIds, lock) ?? 0;
    if (!context.mounted) return;
    final label = lock ? 'locked' : 'unlocked';
    _showActionSnack(context, '$updated item(s) $label successfully');
  }

  Future<void> _applyBulkActive(BuildContext context, bool active) async {
    final int count = _selectedIds.length;
    if (count == 0) {
      _showActionSnack(context, 'No items selected');
      return;
    }
    final updated =
        await widget.onBulkSetActive?.call(_selectedIds, active) ?? 0;
    if (!context.mounted) return;
    final label = active ? 'active' : 'inactive';
    _showActionSnack(context, '$updated item(s) marked as $label successfully');
  }

  void _showActionSnack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // -----------------------------------------------------------
  // UI BUILDERS
  // -----------------------------------------------------------

  Widget _buildToolbar(List<ItemRow> sortedItems) {
    return Column(
      children: [
        if (!_hasSelection) _buildNormalToolbar(),
        if (_hasSelection) _buildSelectionToolbar(sortedItems),
        if (!_hasSelection) const SizedBox(height: 16),
        if (_hasSelection) const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildNormalToolbar() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 260,
                  child: ItemsFilterDropdown(
                    currentFilter: widget.filter,
                    onFilterChanged: widget.onFilterChanged,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SEARCH BOX
                    Container(
                      width: 240,
                      height: 36,
                      margin: const EdgeInsets.only(right: 12),
                      child: TextField(
                        focusNode: widget.searchFocusNode,
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        onSubmitted: (value) {
                          // Trigger immediate search on Enter
                          _debounceTimer?.cancel();
                          ref
                              .read(itemsControllerProvider.notifier)
                              .performSearch(value);
                          FocusScope.of(context).unfocus();
                        },
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'Search items...',
                          hintStyle: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 18,
                            color: AppTheme.textMuted,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    _searchController.clear();
                                    updateState(() {
                                      _searchQuery = '';
                                      _currentPage = 1;
                                    });
                                  },
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                )
                              : null,
                          filled: true,
                          fillColor: AppTheme.bgLight,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: AppTheme.borderColor,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: AppTheme.borderColor,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: AppTheme.primaryBlueDark,
                            ),
                          ),
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.view_list_outlined,
                        color: _viewMode == _ItemsViewMode.list
                            ? AppTheme.primaryBlueDark
                            : AppTheme.textSubtle,
                      ),
                      tooltip: 'List view',
                      onPressed: () {
                        updateState(() {
                          _viewMode = _ItemsViewMode.list;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.grid_view_outlined,
                        color: _viewMode == _ItemsViewMode.grid
                            ? AppTheme.primaryBlueDark
                            : AppTheme.textSubtle,
                      ),
                      tooltip: 'Grid view',
                      onPressed: () {
                        updateState(() {
                          _viewMode = _ItemsViewMode.grid;
                          _selectedIds.clear();
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'New Item (/)',
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        icon: const Icon(
                          Icons.add,
                          size: 18,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'New Item',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        onPressed: () {
                          context.pushNamed(AppRoutes.itemsCreate);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Material(
                        key: _moreButtonKey,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: AppTheme.borderColor),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(6),
                          hoverColor: AppTheme.bgDisabled,
                          onTap: _toggleMoreMenu,
                          child: const SizedBox(
                            height: 36,
                            width: 36,
                            child: Icon(
                              Icons.more_vert,
                              size: 20,
                              color: AppTheme.textSubtle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionToolbar(List<ItemRow> sortedItems) {
    final selectedRows = sortedItems
        .where((row) => _selectedIds.contains(row.selectionId))
        .toList();
    final bool allActive =
        selectedRows.isNotEmpty && selectedRows.every((row) => row.isActive);
    final bool allInactive =
        selectedRows.isNotEmpty && selectedRows.every((row) => !row.isActive);
    final bool allLocked =
        selectedRows.isNotEmpty && selectedRows.every((row) => row.isLock);
    final bool allUnlocked =
        selectedRows.isNotEmpty && selectedRows.every((row) => !row.isLock);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Text(
              '${_selectedIds.length} Selected',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 12),
            _SelectionChip(label: 'Bulk Update', onTap: _showBulkUpdateDialog),
            _TransactionChip(
              onSelected: (type) => _handleTransactionAction(context, type),
            ),
            if (allInactive && !allActive)
              _SelectionChip(
                label: 'Mark as Active',
                onTap: () => _handleMarkAsActive(context),
              )
            else if (allActive && !allInactive)
              _SelectionChip(
                label: 'Mark as Inactive',
                onTap: () => _handleMarkAsInActive(context),
              )
            else ...[
              _SelectionChip(
                label: 'Mark as Active',
                onTap: () => _handleMarkAsActive(context),
              ),
              _SelectionChip(
                label: 'Mark as Inactive',
                onTap: () => _handleMarkAsInActive(context),
              ),
            ],
            _SelectionChip(
              label: 'Mark as Returnable',
              onTap: () => _handleMarkAsReturnable(context),
            ),
            _SelectionChip(
              label: 'Push to Ecommerce',
              onTap: () => _handlePushToEcommerce(context),
            ),
            if (allUnlocked && !allLocked)
              _SelectionChip(
                label: 'Lock Item',
                onTap: () => _handleLockItem(context, true),
              )
            else if (allLocked && !allUnlocked)
              _SelectionChip(
                label: 'Unlock Item',
                onTap: () => _handleLockItem(context, false),
              )
            else ...[
              _SelectionChip(
                label: 'Lock Item',
                onTap: () => _handleLockItem(context, true),
              ),
              _SelectionChip(
                label: 'Unlock Item',
                onTap: () => _handleLockItem(context, false),
              ),
            ],
            _SelectionOverflowChip(
              onSelected: (action) => _handleSelectionOverflow(context, action),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () => _onSelectionChanged(<String>{}),
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }
}
