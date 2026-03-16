import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'item_row.dart';
import 'items_table.dart';
import 'column_visibility_manager.dart';

class ItemsListView extends ConsumerStatefulWidget {
  final List<ItemRow> items;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final ValueChanged<ItemRow>? onItemTap;
  final bool allSelected;
  final ValueChanged<bool> onToggleAll;

  final bool isNameSorted;
  final bool isNameAscending;
  final VoidCallback onToggleNameSort;

  final bool isReorderSorted;
  final bool isReorderAscending;
  final VoidCallback onToggleReorderSort;

  final bool isHsnSorted;
  final bool isHsnAscending;
  final VoidCallback onToggleHsnSort;

  final bool isSkuSorted;
  final bool isSkuAscending;
  final VoidCallback onToggleSkuSort;

  final bool isStockSorted;
  final bool isStockAscending;
  final VoidCallback onToggleStockSort;

  final int resetWidthsTrigger;

  const ItemsListView({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onSelectionChanged,
    this.onItemTap,
    required this.allSelected,
    required this.onToggleAll,
    required this.isNameSorted,
    required this.isNameAscending,
    required this.onToggleNameSort,
    required this.isReorderSorted,
    required this.isReorderAscending,
    required this.onToggleReorderSort,
    required this.isHsnSorted,
    required this.isHsnAscending,
    required this.onToggleHsnSort,
    required this.isSkuSorted,
    required this.isSkuAscending,
    required this.onToggleSkuSort,
    required this.isStockSorted,
    required this.isStockAscending,
    required this.onToggleStockSort,
    this.resetWidthsTrigger = 0,
  });

  @override
  ConsumerState<ItemsListView> createState() => _ItemsListViewState();
}

class _ItemsListViewState extends ConsumerState<ItemsListView> {
  final ScrollController _horizontalController = ScrollController();

  /// 🔑 single source of truth
  late Map<String, double> _widths;

  @override
  void initState() {
    super.initState();
    final allCols = ColumnVisibilityManager.getAllColumns();
    _widths = {for (var col in allCols) col.key: 150.0};
    // Overrides
    if (_widths.containsKey('name')) _widths['name'] = 260.0;
    if (_widths.containsKey('description')) _widths['description'] = 260.0;
  }

  /// 🔑 text wrap state
  bool _wrapText = false;

  @override
  void didUpdateWidget(ItemsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.resetWidthsTrigger != oldWidget.resetWidthsTrigger) {
      final allCols = ColumnVisibilityManager.getAllColumns();
      setState(() {
        _widths = {for (var col in allCols) col.key: 150.0};
        if (_widths.containsKey('name')) _widths['name'] = 260.0;
        if (_widths.containsKey('description')) _widths['description'] = 260.0;
      });
    }
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleKeys = ref.watch(columnVisibilityProvider).visibleColumns;
    final double leadingWidth = 32 + 4 + 32;
    final double columnsWidth = visibleKeys
        .map((key) => _widths[key] ?? 150.0)
        .fold<double>(0, (sum, w) => sum + w);
    final double baseTableWidth = leadingWidth + columnsWidth + 32;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double tableWidth = baseTableWidth > constraints.maxWidth
            ? baseTableWidth
            : constraints.maxWidth;

        return Container(
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                height: constraints.maxHeight, // PROVIDE DEFINITIVE HEIGHT
                child: Column(
                  children: [
                    ItemsTableHeader(
                      allSelected: widget.allSelected,
                      onToggleAll: widget.onToggleAll,

                      isNameSorted: widget.isNameSorted,
                      isNameAscending: widget.isNameAscending,
                      onToggleNameSort: widget.onToggleNameSort,

                      isReorderSorted: widget.isReorderSorted,
                      isReorderAscending: widget.isReorderAscending,
                      onToggleReorderSort: widget.onToggleReorderSort,

                      isHsnSorted: widget.isHsnSorted,
                      isHsnAscending: widget.isHsnAscending,
                      onToggleHsnSort: widget.onToggleHsnSort,

                      isSkuSorted: widget.isSkuSorted,
                      isSkuAscending: widget.isSkuAscending,
                      onToggleSkuSort: widget.onToggleSkuSort,

                      isStockSorted: widget.isStockSorted,
                      isStockAscending: widget.isStockAscending,
                      onToggleStockSort: widget.onToggleStockSort,

                      columnWidths: _widths,
                      onWidthsChanged: (w) => setState(() => _widths = w),

                      wrapText: _wrapText,
                      onWrapChange: (v) => setState(() => _wrapText = v),
                    ),

                    const Divider(height: 1, color: Color(0xFFE5E7EB)),

                    Expanded(
                      child: ItemsTable(
                        items: widget.items,
                        selectedIds: widget.selectedIds,
                        onSelectionChanged: widget.onSelectionChanged,
                        columnWidths: _widths,
                        wrapText: _wrapText,
                        onItemTap: widget.onItemTap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
