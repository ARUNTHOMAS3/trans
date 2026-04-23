import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/report/dialogs/items_custom_columns.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/report/item_row.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/report/column_visibility_manager.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

// -----------------------------------------------------------
// HEADER MENU
// -----------------------------------------------------------

enum _HeaderMenuAction { customizeColumns, enableWrap, enableClip }

// -----------------------------------------------------------
// TABLE HEADER
// -----------------------------------------------------------

class ItemsTableHeader extends ConsumerWidget {
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

  final Map<String, double> columnWidths;
  final ValueChanged<Map<String, double>> onWidthsChanged;

  final bool wrapText;
  final ValueChanged<bool> onWrapChange;

  const ItemsTableHeader({
    super.key,
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
    required this.columnWidths,
    required this.onWidthsChanged,
    required this.wrapText,
    required this.onWrapChange,
  });

  void _resize(String key, double dx) {
    final updated = Map<String, double>.from(columnWidths);
    updated[key] = (updated[key]! + dx).clamp(80.0, 600.0);
    onWidthsChanged(updated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Column visibility manager
    final manager = ref.watch(columnVisibilityProvider);
    final visibleKeys = manager.visibleColumns;
    // All column definitions (flattened)
    final allDefs = ColumnVisibilityManager.getAllColumns();
    // Keep only visible columns, preserving order
    final displayedDefs = allDefs
        .where((def) => visibleKeys.contains(def.key))
        .toList();

    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppTheme.textSecondary,
    );

    Widget header(
      String key,
      String label, {
      bool sortable = false,
      bool active = false,
      bool asc = true,
      VoidCallback? onSort,
    }) {
      final width = columnWidths[key] ?? 120.0;
      return _ResizableHeaderCell(
        width: width,
        onResize: (dx) => _resize(key, dx),
        child: InkWell(
          onTap: sortable ? onSort : null,
          child: Padding(
            padding: const EdgeInsets.only(left: 8, right: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: headerStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
                if (sortable && active)
                  Icon(
                    asc ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    size: 14,
                    color: AppTheme.textMuted,
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: _HeaderMenuButton(
              wrapText: wrapText,
              onWrapChange: onWrapChange,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 32,
            child: Checkbox(
              value: allSelected,
              activeColor: AppTheme.primaryBlueDark,
              onChanged: (v) => onToggleAll(v ?? false),
            ),
          ),
          // Dynamically render visible columns
          ...displayedDefs.map((def) {
            bool sortable = false;
            bool active = false;
            bool asc = true;
            VoidCallback? onSort;
            switch (def.key) {
              case 'name':
                sortable = true;
                active = isNameSorted;
                asc = isNameAscending;
                onSort = onToggleNameSort;
                break;
              case 'reorderLevel':
                sortable = true;
                active = isReorderSorted;
                asc = isReorderAscending;
                onSort = onToggleReorderSort;
                break;
              case 'hsn':
                sortable = true;
                active = isHsnSorted;
                asc = isHsnAscending;
                onSort = onToggleHsnSort;
                break;
              case 'sku':
                sortable = true;
                active = isSkuSorted;
                asc = isSkuAscending;
                onSort = onToggleSkuSort;
                break;
              case 'stockOnHand':
                sortable = true;
                active = isStockSorted;
                asc = isStockAscending;
                onSort = onToggleStockSort;
                break;
            }
            return header(
              def.key,
              def.label,
              sortable: sortable,
              active: active,
              asc: asc,
              onSort: onSort,
            );
          }),
        ],
      ),
    );
  }
}

// Provider for column visibility manager
final columnVisibilityProvider =
    ChangeNotifierProvider<ColumnVisibilityManager>(
      (ref) => ColumnVisibilityManager(),
    );

// -----------------------------------------------------------
// HEADER MENU BUTTON
// -----------------------------------------------------------

class _HeaderMenuButton extends StatelessWidget {
  final bool wrapText;
  final ValueChanged<bool> onWrapChange;

  const _HeaderMenuButton({required this.wrapText, required this.onWrapChange});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_HeaderMenuAction>(
      padding: EdgeInsets.zero,
      offset: const Offset(0, 8),
      elevation: 10,
      color: Colors.white,
      constraints: const BoxConstraints(minWidth: 210),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE4FF)),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.tune, size: 15, color: AppTheme.textSecondary),
      ),
      onSelected: (action) {
        final manager = ProviderScope.containerOf(
          context,
        ).read(columnVisibilityProvider);
        switch (action) {
          case _HeaderMenuAction.customizeColumns:
            showDialog(
              context: context,
              builder: (_) => ItemsCustomColumnsDialog(
                selectedColumns: manager.visibleColumns,
                onSave: (newSet) {
                  manager.setVisibleColumns(newSet);
                },
              ),
            );
            break;
          case _HeaderMenuAction.enableWrap:
            onWrapChange(true);
            break;
          case _HeaderMenuAction.enableClip:
            onWrapChange(false);
            break;
        }
      },
      itemBuilder: (context) {
        final entries = <PopupMenuEntry<_HeaderMenuAction>>[
          const PopupMenuItem<_HeaderMenuAction>(
            value: _HeaderMenuAction.customizeColumns,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: _MenuActionTile(
              icon: Icons.tune_rounded,
              label: 'Customize Columns',
              selected: false,
              accent: true,
            ),
          ),
        ];

        if (wrapText) {
          entries.add(
            PopupMenuItem<_HeaderMenuAction>(
              value: _HeaderMenuAction.enableClip,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const _MenuActionTile(
                icon: Icons.horizontal_rule,
                label: 'Clip Text',
                selected: true,
              ),
            ),
          );
        } else {
          entries.add(
            PopupMenuItem<_HeaderMenuAction>(
              value: _HeaderMenuAction.enableWrap,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: const _MenuActionTile(
                icon: Icons.wrap_text,
                label: 'Wrap Text',
                selected: true,
              ),
            ),
          );
        }
        return entries;
      },
    );
  }
}

class _MenuActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool accent;

  const _MenuActionTile({
    required this.icon,
    required this.label,
    this.selected = false,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    const blue = AppTheme.primaryBlueDark;
    const dark = AppTheme.textPrimary;
    final textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: selected
          ? Colors.white
          : accent
          ? blue
          : dark,
    );

    final bg = selected ? blue : Colors.transparent;
    final icColor = selected
        ? Colors.white
        : accent
        ? blue
        : AppTheme.textSecondary;

    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: icColor),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: textStyle)),
          if (selected) const Icon(Icons.check, size: 16, color: Colors.white),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------
// TABLE BODY
// -----------------------------------------------------------

class ItemsTable extends ConsumerWidget {
  final List<ItemRow> items;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final Map<String, double> columnWidths;
  final bool wrapText;
  final ValueChanged<ItemRow>? onItemTap;

  const ItemsTable({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.columnWidths,
    required this.wrapText,
    this.onItemTap,
  });

  void _toggle(String id, bool v) {
    final s = Set<String>.from(selectedIds);
    v ? s.add(id) : s.remove(id);
    onSelectionChanged(s);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Column visibility manager
    final manager = ref.watch(columnVisibilityProvider);
    final visibleKeys = manager.visibleColumns;
    // All column definitions
    final allDefs = ColumnVisibilityManager.getAllColumns();
    // Keep only visible columns, preserving order
    final displayedDefs = allDefs
        .where((def) => visibleKeys.contains(def.key))
        .toList();

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppTheme.borderColor),
      itemBuilder: (context, i) {
        final it = items[i];
        final sel = selectedIds.contains(it.selectionId);

        return _ItemTableRow(
          key: ValueKey(it.selectionId),
          item: it,
          isSelected: sel,
          onSelectionChanged: (v) => _toggle(it.selectionId, v),
          displayedDefs: displayedDefs,
          columnWidths: columnWidths,
          wrapText: wrapText,
          onItemTap: onItemTap,
        );
      },
    );
  }
}

class _ItemTableRow extends ConsumerStatefulWidget {
  final ItemRow item;
  final bool isSelected;
  final ValueChanged<bool> onSelectionChanged;
  final List<ColumnDefinition> displayedDefs;
  final Map<String, double> columnWidths;
  final bool wrapText;
  final ValueChanged<ItemRow>? onItemTap;

  const _ItemTableRow({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onSelectionChanged,
    required this.displayedDefs,
    required this.columnWidths,
    required this.wrapText,
    this.onItemTap,
  });

  @override
  ConsumerState<_ItemTableRow> createState() => _ItemTableRowState();
}

class _ItemTableRowState extends ConsumerState<_ItemTableRow> {
  bool _isHovered = false;
  bool _isOverlayHovered = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _hoverTimer;
  Timer? _hideTimer;
  Future<Map<String, dynamic>>? _quickStatsFuture;

  void _showOverlay() {
    _hideTimer?.cancel();
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted ||
          (!_isHovered && !_isOverlayHovered) ||
          _overlayEntry != null) {
        return;
      }

      final id = widget.item.id;
      if (id == null) return;
      _quickStatsFuture ??= ref
          .read(itemsControllerProvider.notifier)
          .fetchQuickStats(id);

      _overlayEntry = OverlayEntry(
        builder: (context) => UnconstrainedBox(
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(60, -45),
            child: MouseRegion(
              onEnter: (_) {
                _hideTimer?.cancel();
                if (!_isOverlayHovered && mounted) {
                  setState(() => _isOverlayHovered = true);
                }
              },
              onExit: (_) {
                if (_isOverlayHovered && mounted) {
                  setState(() => _isOverlayHovered = false);
                }
                _scheduleHideOverlay();
              },
              child: FutureBuilder<Map<String, dynamic>>(
                future: _quickStatsFuture,
                builder: (context, snapshot) {
                  return _QuickStatsOverlay(
                    stats:
                        snapshot.data ??
                        {'current_stock': 0, 'last_purchase_price': 0.0},
                    isLoading:
                        snapshot.connectionState == ConnectionState.waiting,
                  );
                },
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  void _hideOverlay() {
    _hoverTimer?.cancel();
    _hideTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _scheduleHideOverlay() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 120), () {
      if (!mounted || _isHovered || _isOverlayHovered) return;
      _hideOverlay();
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  Widget _cell(double w, String text, {Color color = AppTheme.textPrimary}) {
    return SizedBox(
      width: w,
      child: Text(
        text,
        maxLines: widget.wrapText ? null : 1,
        overflow: widget.wrapText
            ? TextOverflow.visible
            : TextOverflow.ellipsis,
        softWrap: widget.wrapText,
        style: TextStyle(fontSize: 13, color: color),
      ),
    );
  }

  String _getCellData(ItemRow item, String key) {
    if (key == 'name') return item.name;
    switch (key) {
      case 'billingName':
        return item.billingName ?? '';
      case 'itemCode':
        return item.itemCode ?? '';
      case 'typeDisplay':
        return item.typeDisplay ?? '';
      case 'taxPreference':
        return item.taxPreference ?? '';
      case 'hsn':
        return item.hsn ?? '';
      case 'sku':
        return item.sku ?? '';
      case 'ean':
        return item.ean ?? '';
      case 'brand':
        return item.brand ?? '';
      case 'category':
        return item.category ?? '';
      case 'sellingPrice':
        return item.sellingPrice ?? '';
      case 'mrp':
        return item.mrp ?? '';
      case 'ptr':
        return item.ptr ?? '';
      case 'salesAccount':
        return item.salesAccount ?? '';
      case 'description':
        return item.salesDescription ?? item.description ?? '';
      case 'costPrice':
        return item.costPrice ?? '';
      case 'purchaseAccount':
        return item.purchaseAccount ?? '';
      case 'preferredVendor':
        return item.preferredVendor ?? '';
      case 'purchaseDescription':
        return item.purchaseDescription ?? '';
      case 'length':
        return item.length ?? '';
      case 'width':
        return item.width ?? '';
      case 'height':
        return item.height ?? '';
      case 'weight':
        return item.weight ?? '';
      case 'manufacturer':
        return item.manufacturer ?? '';
      case 'mpn':
        return item.mpn ?? '';
      case 'upc':
        return item.upc ?? '';
      case 'isbn':
        return item.isbn ?? '';
      case 'stockOnHand':
        return item.stockOnHand ?? '';
      case 'reorderLevel':
        return item.reorderLevel ?? '';
      case 'inventoryValuationMethod':
        return item.inventoryValuationMethod ?? '';
      case 'storageLocation':
        return item.storageLocation ?? '';
      case 'reorderTerm':
        return item.reorderTerm ?? '';
      case 'buyingRule':
        return item.buyingRule ?? '';
      case 'scheduleOfDrug':
        return item.scheduleOfDrug ?? '';
      case 'accountName':
        return item.accountName;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _showOverlay();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _scheduleHideOverlay();
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onItemTap?.call(widget.item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: widget.isSelected
                  ? const Color(0xFFF2F4FF)
                  : _isHovered
                  ? AppTheme.bgLight
                  : Colors.transparent,
              child: Row(
                crossAxisAlignment: widget.wrapText
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 32),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 32,
                    child: Checkbox(
                      value: widget.isSelected,
                      activeColor: AppTheme.primaryBlueDark,
                      onChanged: (v) => widget.onSelectionChanged(v ?? false),
                    ),
                  ),
                  ...widget.displayedDefs.map((def) {
                    final val = _getCellData(widget.item, def.key);
                    final width = widget.columnWidths[def.key] ?? 120.0;
                    return _cell(
                      width,
                      val,
                      color: def.key == 'name'
                          ? AppTheme.primaryBlueDark
                          : AppTheme.textPrimary,
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// QUICK STATS OVERLAY
// -----------------------------------------------------------

class _QuickStatsOverlay extends StatelessWidget {
  final Map<String, dynamic> stats;
  final bool isLoading;

  const _QuickStatsOverlay({required this.stats, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        width: 170,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading) ...[
              const Text(
                'Loading Quick Stats...',
                style: TextStyle(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: AppTheme.bgDisabled,
                valueColor: AlwaysStoppedAnimation(AppTheme.primaryBlueDark),
              ),
            ] else ...[
              _buildStat(
                'Current Stock',
                '${stats['current_stock'] ?? 0}',
                Icons.inventory_2_outlined,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppTheme.bgDisabled),
              ),
              _buildStat(
                'Last Purchase',
                '₹${stats['last_purchase_price'] ?? 0.0}',
                Icons.shopping_cart_outlined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.1,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------
// RESIZABLE HEADER CELL
// -----------------------------------------------------------

class _ResizableHeaderCell extends StatefulWidget {
  final double width;
  final Widget child;
  final ValueChanged<double> onResize;

  const _ResizableHeaderCell({
    required this.width,
    required this.child,
    required this.onResize,
  });

  @override
  State<_ResizableHeaderCell> createState() => _ResizableHeaderCellState();
}

class _ResizableHeaderCellState extends State<_ResizableHeaderCell> {
  bool _hover = false;
  static const double _resizeSensitivity = 8.0;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Stack(
        children: [
          SizedBox(width: widget.width, height: 42, child: widget.child),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (d) =>
                  widget.onResize(d.delta.dx * _resizeSensitivity),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _hover ? 1.0 : 0.0,
                child: Container(width: 4, color: AppTheme.borderColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
