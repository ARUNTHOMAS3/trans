// lib/modules/items/composite_items/presentation/report.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import '../models/composite_item.dart';
import '../providers/composite_items_provider.dart';
import 'composite_item_visual_theme.dart';

class _ColumnDef {
  final String id;
  final String label;
  double width;
  bool visible;
  final bool isLocked;
  _ColumnDef({
    required this.id,
    required this.label,
    required this.width,
    required this.visible,
    this.isLocked = false,
  });
}

class CompositeItemsReportPage extends ConsumerStatefulWidget {
  const CompositeItemsReportPage({super.key});

  @override
  ConsumerState<CompositeItemsReportPage> createState() =>
      _CompositeItemsReportPageState();
}

class _CompositeItemsReportPageState
    extends ConsumerState<CompositeItemsReportPage> {
  // â”€â”€â”€ Filter options â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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

  // â”€â”€â”€ Sort state (mirrors provider) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  String get _sortField => ref.watch(compositeItemsProvider).sortField;
  bool get _sortAscending => ref.watch(compositeItemsProvider).sortAscending;

  // â”€â”€â”€ More-menu overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final LayerLink _moreMenuLayerLink = LayerLink();
  bool _isMoreMenuOpen = false;
  OverlayEntry? _moreMenuOverlayEntry;
  _SubMenuType _activeSubMenu = _SubMenuType.none;

  // â”€â”€â”€ Columns-picker overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final LayerLink _colsLayerLink = LayerLink();
  bool _isColsOpen = false;
  OverlayEntry? _colsOverlay;

  // â”€â”€â”€ UI state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _isLoading = false;
  bool _allSelected = false;
  bool _showTotalCount = false;
  int _currentPage = 1;
  int _rowsPerPage = 25;
  int? _hoveredRowIndex;
  int? _hoveredHeaderIndex;
  bool _hoveringHeaderRow = false;
  bool _hoveringRowsPerPage = false;
  bool _hoveringPrevPage = false;
  bool _hoveringNextPage = false;
  bool _clipText = true;
  bool _showResizedBanner = false;
  final Set<String> _expandedRecordIds = {};

  // â”€â”€â”€ Column definitions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  final List<_ColumnDef> _columns = [
    // ── Visible by default ────────────────────────────────────────────────────
    _ColumnDef(id: 'name',                label: 'Name',                 width: 220, visible: true,  isLocked: true),
    _ColumnDef(id: 'itemType',            label: 'Composition Type',     width: 160, visible: true),
    _ColumnDef(id: 'sku',                 label: 'SKU',                  width: 140, visible: true),
    _ColumnDef(id: 'reorderLevel',        label: 'Reorder Level',        width: 120, visible: true),
    _ColumnDef(id: 'category',            label: 'Category',             width: 160, visible: true),
    _ColumnDef(id: 'manufacturer',        label: 'Manufacturer',         width: 160, visible: true),
    _ColumnDef(id: 'brand',               label: 'Brand',                width: 140, visible: true),
    _ColumnDef(id: 'unit',                label: 'Unit',                 width: 100, visible: false),
    _ColumnDef(id: 'hsnCode',             label: 'HSN Code',             width: 120, visible: false),
    // ── Hidden by default ─────────────────────────────────────────────────────
    _ColumnDef(id: 'accountName',         label: 'Account Name',         width: 160, visible: false),
    _ColumnDef(id: 'description',         label: 'Description',          width: 200, visible: false),
    _ColumnDef(id: 'dimensions',          label: 'Dimensions',           width: 140, visible: false),
    _ColumnDef(id: 'mpn',                 label: 'MPN',                  width: 120, visible: false),
    _ColumnDef(id: 'purchaseAccountName', label: 'Purchase Account Name',width: 190, visible: false),
    _ColumnDef(id: 'purchaseDescription', label: 'Purchase Description', width: 200, visible: false),
    _ColumnDef(id: 'purchaseRate',        label: 'Purchase Rate',        width: 130, visible: false),
    _ColumnDef(id: 'rate',                label: 'Rate',                 width: 110, visible: false),
    _ColumnDef(id: 'type',                label: 'Type',                 width: 110, visible: false),
    _ColumnDef(id: 'upc',                 label: 'UPC',                  width: 120, visible: false),
    _ColumnDef(id: 'usageUnit',           label: 'Usage Unit',           width: 120, visible: false),
    _ColumnDef(id: 'weight',              label: 'Weight',               width: 110, visible: false),
  ];

  // â”€â”€â”€ Data helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  List<CompositeItem> get _allRecords => ref.watch(compositeItemsProvider).records;

  List<CompositeItem> get _filteredRecords {
    return _allRecords.where((item) {
      switch (_selectedFilter.value) {
        case 'assembly':  return item.itemType == 'Assembly Item';
        case 'kit':       return item.itemType == 'Kit Item';
        case 'active':    return item.isActive;
        case 'inactive':  return !item.isActive;
        case 'low_stock': return item.stockQuantity < item.reorderLevel;
        case 'ungrouped': return !item.isGrouped;
        default:          return true; // 'all'
      }
    }).toList();
  }

  int get _selectedCount => _allRecords.where((r) => r.isSelected).length;

  void _updateAllSelectedState() {
    final records = _filteredRecords;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, records.length);
    if (startIndex >= endIndex) { _allSelected = false; return; }
    _allSelected = records.sublist(startIndex, endIndex).every((r) => r.isSelected);
  }

  String _cellValue(_ColumnDef col, CompositeItem r) {
    switch (col.id) {
      case 'name':                return r.name;
      case 'itemType':            return r.itemType.replaceAll(' Item', '');
      case 'sku':                 return r.sku;
      case 'reorderLevel':        return r.reorderLevel > 0 ? '${r.reorderLevel}' : '';
      case 'category':            return r.category.toUpperCase();
      case 'manufacturer':        return r.manufacturer;
      case 'brand':               return r.brand;
      case 'unit':                return r.unit;
      case 'hsnCode':             return r.hsnCode;
      case 'accountName':         return r.accountName;
      case 'description':         return r.description;
      case 'dimensions':          return r.dimensions;
      case 'mpn':                 return r.mpn;
      case 'purchaseAccountName': return r.purchaseAccountName;
      case 'purchaseDescription': return r.purchaseDescription;
      case 'purchaseRate':        return r.purchaseRate > 0 ? r.purchaseRate.toStringAsFixed(2) : '';
      case 'rate':                return r.sellingPrice > 0 ? r.sellingPrice.toStringAsFixed(2) : '';
      case 'type':                return r.itemType.replaceAll(' Item', '');
      case 'upc':                 return r.upc;
      case 'usageUnit':           return r.usageUnit;
      case 'weight':              return r.weight > 0 ? '${r.weight} kg' : '';
      default:                    return '';
    }
  }

  // â”€â”€â”€ Refresh â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _refreshData() async {
    setState(() { _isLoading = true; _allSelected = false; });
    await ref.read(compositeItemsProvider.notifier).refresh();
    if (mounted) setState(() => _isLoading = false);
  }

  // â”€â”€â”€ More menu overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _showMoreMenu() {
    if (_moreMenuOverlayEntry != null) return;
    final overlay = Overlay.of(context);
    _moreMenuOverlayEntry = OverlayEntry(builder: (context) {
      return Stack(children: [
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
          offset: const Offset(0, 8),
          child: Material(
            elevation: 0,
            color: Colors.transparent,
            child: _MoreMenuDropdownContent(
              activeSubMenu: _activeSubMenu,
              onSubMenuChanged: (type) {
                setState(() => _activeSubMenu = type);
                _moreMenuOverlayEntry?.markNeedsBuild();
              },
              sortField: _sortField,
              sortAscending: _sortAscending,
              onSort: (field, asc) {
                ref.read(compositeItemsProvider.notifier).sort(field, asc);
              },
              onClose: _closeMoreMenu,
              onRefresh: _refreshData,
            ),
          ),
        ),
      ]);
    });
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

  // â”€â”€â”€ Columns overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _openColsOverlay() {
    if (_colsOverlay != null) return;
    final overlay = Overlay.of(context);
    _colsOverlay = OverlayEntry(builder: (ctx) {
      return Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _closeColsOverlay,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _colsLayerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 26),
          child: Material(
            elevation: 8,
            color: Colors.transparent,
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ColsMenuItem(
                    icon: LucideIcons.sliders,
                    label: 'Customize Columns',
                    onTap: () {
                      _closeColsOverlay();
                      _showCustomizeColumnsDialog();
                    },
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  _ColsMenuToggleItem(
                    icon: LucideIcons.alignLeft,
                    label: _clipText ? 'Clip Text' : 'Wrap Text',
                    onChanged: (v) {
                      _closeColsOverlay();
                      setState(() => _clipText = !_clipText);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ]);
    });
    overlay.insert(_colsOverlay!);
    setState(() => _isColsOpen = true);
  }

  void _closeColsOverlay() {
    _colsOverlay?.remove();
    _colsOverlay = null;
    setState(() => _isColsOpen = false);
  }

  void _showCustomizeColumnsDialog() {
    final configs = _columns.asMap().entries.map((e) => ColumnConfig(
      id: e.value.id,
      label: e.value.label,
      isVisible: e.value.visible,
      orderIndex: e.key,
      isLocked: e.value.isLocked,
    )).toList();

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => ColumnCustomizerDialog(
        columns: configs,
        onSave: (updated) {
          Navigator.of(ctx).pop();
          setState(() {
            for (final col in _columns) {
              final match = updated.firstWhere(
                (u) => u.id == col.id,
                orElse: () => ColumnConfig(
                  id: col.id, label: col.label,
                  isVisible: col.visible, isLocked: col.isLocked,
                ),
              );
              col.visible = match.isVisible;
            }
            _columns.sort((a, b) {
              final ai = updated.indexWhere((u) => u.id == a.id);
              final bi = updated.indexWhere((u) => u.id == b.id);
              if (ai == -1 && bi == -1) return 0;
              if (ai == -1) return 1;
              if (bi == -1) return -1;
              return ai.compareTo(bi);
            });
          });
          ZerpaiToast.success(context, 'Custom View has been updated.');
        },
      ),
    );
  }

  // â”€â”€â”€ Column resize â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _onColResize(int colIndex, double delta) {
    setState(() {
      _columns[colIndex].width = (_columns[colIndex].width + delta).clamp(60.0, 600.0);
      _showResizedBanner = true;
    });
  }

  // â”€â”€â”€ Sort icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  bool _isSortable(String id) => const {'name', 'itemType', 'sku', 'category', 'reorderLevel'}.contains(id);

  Widget _buildSortIcon(String id) {
    final isSorted = _sortField == id;
    final isAsc = _sortAscending;
    const active = Color(0xFF2563EB);
    const inactive = Color(0xFF9CA3AF);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: () => ref.read(compositeItemsProvider.notifier).sort(id, true),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Icon(Icons.arrow_upward_rounded, size: 14,
            color: isSorted && isAsc ? active : inactive),
        ),
      ),
      const SizedBox(width: 2),
      GestureDetector(
        onTap: () => ref.read(compositeItemsProvider.notifier).sort(id, false),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Icon(Icons.arrow_downward_rounded, size: 14,
            color: isSorted && !isAsc ? active : inactive),
        ),
      ),
    ]);
  }

  // â”€â”€â”€ Header cell â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildHeader(_ColumnDef col, int globalIdx, int visibleIdx, double scaledWidth) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredHeaderIndex = visibleIdx),
      onExit: (_) => setState(() => _hoveredHeaderIndex = null),
      child: SizedBox(
        width: scaledWidth,
        height: 38,
        child: Stack(children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 6, right: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Flexible(
                    child: Text(
                      col.label.toUpperCase(),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: .3,
                      ),
                    ),
                  ),
                  if (_isSortable(col.id)) ...[
                    const SizedBox(width: 4),
                    _buildSortIcon(col.id),
                  ],
                ]),
              ),
            ),
          ),
          // Resize handle
          Positioned(
            right: 0, top: 0, bottom: 0,
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                onHorizontalDragUpdate: (d) => _onColResize(globalIdx, d.delta.dx),
                child: Container(
                  width: 8,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 2, height: 16,
                      decoration: BoxDecoration(
                        color: (_hoveringHeaderRow && _hoveredHeaderIndex == visibleIdx)
                            ? const Color(0xFFCBD5E1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // â”€â”€â”€ Select all / single â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _toggleSelectAll(bool? val) {
    if (val == null) return;
    final records = _filteredRecords;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, records.length);
    setState(() {
      _allSelected = val;
      ref.read(compositeItemsProvider.notifier).toggleSelectAll(val, startIndex, endIndex);
    });
  }

  void _toggleRecordSelect(int absoluteIndex, bool? val) {
    if (val == null) return;
    setState(() {
      ref.read(compositeItemsProvider.notifier).toggleRecordSelect(absoluteIndex, val);
      _updateAllSelectedState();
    });
  }

  // â”€â”€â”€ dispose â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  void dispose() {
    _moreMenuOverlayEntry?.remove();
    _moreMenuOverlayEntry = null;
    _colsOverlay?.remove();
    _colsOverlay = null;
    super.dispose();
  }

  // â”€â”€â”€ build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, records.length);
    final paginatedRecords = records.isEmpty ? <CompositeItem>[] : records.sublist(startIndex, endIndex);

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      child: CompositeItemVisualTheme(
        child: Container(
          color: Colors.white,
          child: Column(
          children: [
            // â”€â”€ Resized-columns banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_showResizedBanner)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFEFF6FF),
                child: Row(children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You have resized the columns. Would you like to save the changes?',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => setState(() => _showResizedBanner = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22A95E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Save', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 6),
                  OutlinedButton(
                    onPressed: () => setState(() => _showResizedBanner = false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 30),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                  ),
                ]),
              ),

            // â”€â”€ Bulk ribbon OR normal top bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_selectedCount > 0)
              _BulkActionRibbon(
                selectedCount: _selectedCount,
                onActionSelected: (action) {
                  final totalRecords = _allRecords.length;
                  if (action == 'mark_active') {
                    ref.read(compositeItemsProvider.notifier).bulkMarkActive(true);
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    setState(() {
                      _allSelected = false;
                      _updateAllSelectedState();
                    });
                    ZerpaiToast.success(context, 'Selected item(s) marked as Active');
                  } else if (action == 'mark_inactive') {
                    ref.read(compositeItemsProvider.notifier).bulkMarkActive(false);
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    setState(() {
                      _allSelected = false;
                      _updateAllSelectedState();
                    });
                    ZerpaiToast.success(context, 'Selected item(s) marked as Inactive');
                  } else if (action == 'add_group') {
                    ref.read(compositeItemsProvider.notifier).bulkAddGroup();
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    setState(() {
                      _allSelected = false;
                      _updateAllSelectedState();
                    });
                    ZerpaiToast.success(context, 'Selected item(s) added to group');
                  } else if (action == 'mark_returnable') {
                    ref.read(compositeItemsProvider.notifier).bulkMarkReturnable(true);
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    setState(() {
                      _allSelected = false;
                      _updateAllSelectedState();
                    });
                    ZerpaiToast.success(context, 'Selected item(s) marked as Returnable');
                  } else if (action == 'enable_bin') {
                    ref.read(compositeItemsProvider.notifier).bulkEnableBinLocation(true);
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    setState(() {
                      _allSelected = false;
                      _updateAllSelectedState();
                    });
                    ZerpaiToast.success(context, 'Bin location enabled for selected item(s)');
                  } else if (action == 'disable_bin') {
                    ref.read(compositeItemsProvider.notifier).bulkEnableBinLocation(false);
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, totalRecords);
                    setState(() {
                      _allSelected = false;
                      _updateAllSelectedState();
                    });
                    ZerpaiToast.success(context, 'Bin location disabled for selected item(s)');
                  } else if (action == 'delete') {
                    showDialog<bool>(
                      context: context,
                      builder: (context) => const _DeleteConfirmationDialog(),
                    ).then((confirmed) {
                      if (confirmed == true) {
                        setState(() {
                          ref.read(compositeItemsProvider.notifier).deleteSelected();
                          _allSelected = false;
                          _currentPage = 1;
                          _updateAllSelectedState();
                        });
                        ZerpaiToast.deleted(context, 'Composite Item(s)');
                      }
                    });
                  }
                },
                onDelete: () {
                  showDialog<bool>(
                    context: context,
                    builder: (context) => const _DeleteConfirmationDialog(),
                  ).then((confirmed) {
                    if (confirmed == true) {
                      setState(() {
                        ref.read(compositeItemsProvider.notifier).deleteSelected();
                        _allSelected = false;
                        _currentPage = 1;
                        _updateAllSelectedState();
                      });
                      ZerpaiToast.deleted(context, 'Composite Item(s)');
                    }
                  });
                },
                onDismiss: () => setState(() {
                  _allSelected = false;
                  ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, _allRecords.length);
                }),
              )
            else
              // Normal top bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(children: [
                  // Filter dropdown title
                  FavoriteFilterDropdown(
                    moduleName: 'composite_items',
                    options: _filterOptions,
                    selectedOption: _selectedFilter,
                    onChanged: (opt) => setState(() => _selectedFilter = opt),
                  ),
                  const Spacer(),
                  // + New button
                  ElevatedButton(
                    onPressed: () {
                      final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
                      context.go('/$orgId/items/composite-items/create');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'New',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  // More menu (â‹¯)
                  CompositedTransformTarget(
                    link: _moreMenuLayerLink,
                    child: IconButton(
                      onPressed: () => _isMoreMenuOpen ? _closeMoreMenu() : _showMoreMenu(),
                      icon: Icon(
                        LucideIcons.moreHorizontal,
                        size: 20,
                        color: _isMoreMenuOpen ? const Color(0xFF2563EB) : AppTheme.textSecondary,
                      ),
                      splashRadius: 20,
                    ),
                  ),
                ]),
              ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // â”€â”€ Table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Expanded(
              child: LayoutBuilder(builder: (ctx, constraints) {
                final screenW = constraints.maxWidth;
                final visibleCols = _columns.where((c) => c.visible).toList();
                const double prefixW = 8 + 14 + 8 + 36 + 8.0; // sliders + checkbox area
                const double suffixW = 0.0;                   // no right search icon area
                final colsTotalW = visibleCols.fold(0.0, (s, c) => s + c.width);
                final minTableW = colsTotalW + prefixW + suffixW;
                final bool shouldStretch = screenW > minTableW;
                final double scale = shouldStretch ? (screenW - prefixW - suffixW) / colsTotalW : 1.0;
                final double tableW = shouldStretch ? screenW : minTableW;

                Widget tableContent = SizedBox(
                  width: tableW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // â”€â”€ Header row â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      MouseRegion(
                        onEnter: (_) => setState(() => _hoveringHeaderRow = true),
                        onExit: (_) => setState(() {
                          _hoveringHeaderRow = false;
                          _hoveredHeaderIndex = null;
                        }),
                        child: Container(
                          height: 38,
                          color: const Color(0xFFF9FAFB),
                          child: Row(children: [
                            const SizedBox(width: 8),
                            // Columns picker icon
                            CompositedTransformTarget(
                              link: _colsLayerLink,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _isColsOpen ? _closeColsOverlay() : _openColsOverlay(),
                                  child: const Icon(LucideIcons.sliders, size: 14, color: Color(0xFF2563EB)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Select-all checkbox
                            SizedBox(
                              width: 36,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: Checkbox(
                                value: _allSelected,
                                onChanged: _toggleSelectAll,
                                activeColor: AppTheme.primaryBlue,
                                visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    side: const BorderSide(color: AppTheme.borderColor, width: 1.4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Column headers
                            ...List.generate(visibleCols.length, (vi) {
                              final col = visibleCols[vi];
                              final globalIdx = _columns.indexOf(col);
                              return _buildHeader(col, globalIdx, vi, col.width * scale);
                            }),
                          ]),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),

                      // â”€â”€ Rows â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                      if (paginatedRecords.isEmpty)
                        SizedBox(
                          height: 300,
                          child: Center(
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(LucideIcons.box, size: 48, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text('No Composite Items found',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              const SizedBox(height: 8),
                              const Text(
                                'Create a new composite item or adjust your filter.',
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ]),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paginatedRecords.length,
                          itemBuilder: (context, index) {
                            final record = paginatedRecords[index];
                            final absoluteIndex = startIndex + index;
                            final isHovered = _hoveredRowIndex == index;
                            final isExpanded = _expandedRecordIds.contains(record.id);

                            String formatAssociateItem(String item) {
                              final regExp = RegExp(r'\s*\(x(\d+)\)');
                              final match = regExp.firstMatch(item);
                              if (match != null) {
                                final qty = match.group(1);
                                final nameWithoutQty = item.replaceAll(regExp, '');
                                return '${nameWithoutQty.toUpperCase()} ( $qty pcs )';
                              }
                              return '${item.toUpperCase()} ( 1 pcs )';
                            }

                            return MouseRegion(
                              onEnter: (_) => setState(() => _hoveredRowIndex = index),
                              onExit: (_) => setState(() => _hoveredRowIndex = null),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.transparent,
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      height: _clipText ? 38 : null,
                                      constraints: _clipText ? null : const BoxConstraints(minHeight: 38),
                                      padding: EdgeInsets.symmetric(vertical: _clipText ? 0 : 5),
                                      decoration: BoxDecoration(
                                        color: record.isSelected
                                            ? const Color(0xFFF8FAFF)
                                            : (isHovered ? const Color(0xFFF0F4FF) : Colors.white),
                                        border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                                      ),
                                      child: Row(children: [
                                        const SizedBox(width: 8),
                                        const SizedBox(width: 14),
                                        const SizedBox(width: 8),
                                        // Checkbox
                                        SizedBox(
                                          width: 36,
                                          child: Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: Checkbox(
                                            value: record.isSelected,
                                            onChanged: (v) => _toggleRecordSelect(absoluteIndex, v),
                                            activeColor: AppTheme.primaryBlue,
                                            visualDensity: VisualDensity.compact,
                                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                side: const BorderSide(color: AppTheme.borderColor, width: 1.4),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Row cells
                                        Expanded(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '6000000000';
                                              context.go('/$orgId/items/composite-items/${record.id}');
                                            },
                                            child: Row(children: [
                                              ...visibleCols.map((col) {
                                                final val = _cellValue(col, record);
                                                final isName = col.id == 'name';
                                                return SizedBox(
                                                  width: col.width * scale,
                                                  child: Padding(
                                                    padding: const EdgeInsets.only(left: 6, right: 8),
                                                    child: isName
                                                        ? Row(
                                                            children: [
                                                              GestureDetector(
                                                                onTap: () {
                                                                  setState(() {
                                                                    if (_expandedRecordIds.contains(record.id)) {
                                                                      _expandedRecordIds.remove(record.id);
                                                                    } else {
                                                                      _expandedRecordIds.add(record.id);
                                                                    }
                                                                  });
                                                                },
                                                                child: MouseRegion(
                                                                  cursor: SystemMouseCursors.click,
                                                                  child: Icon(
                                                                    _expandedRecordIds.contains(record.id)
                                                                        ? LucideIcons.folderOpen
                                                                        : LucideIcons.folder,
                                                                    size: 16,
                                                                    color: const Color(0xFF9CA3AF),
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 12),
                                                              Expanded(
                                                                child: Text(
                                                                  val,
                                                                  overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.visible,
                                                                  maxLines: _clipText ? 1 : null,
                                                                  softWrap: !_clipText,
                                                                  style: TextStyle(
                                                                    fontSize: 13,
                                                                    color: AppTheme.primaryBlue,
                                                                    fontWeight: FontWeight.w500,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          )
                                                        : Text(
                                                            val,
                                                            overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.visible,
                                                            maxLines: _clipText ? 1 : null,
                                                            softWrap: !_clipText,
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: AppTheme.textPrimary,
                                                              fontWeight: FontWeight.normal,
                                                            ),
                                                          ),
                                                  ),
                                                );
                                              }),
                                            ]),
                                          ),
                                        ),
                                      ]),
                                    ),
                                    if (isExpanded && record.associateItems.isNotEmpty) ...[
                                      ...List.generate(record.associateItems.length, (assocIdx) {
                                        final item = record.associateItems[assocIdx];
                                        final isLast = assocIdx == record.associateItems.length - 1;
                                        return Container(
                                          height: 36,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                                          ),
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 80),
                                              SizedBox(
                                                width: 16,
                                                height: 36,
                                                child: CustomPaint(
                                                  painter: _TreeLinePainter(isLast: isLast),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  formatAssociateItem(item),
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4B5563),
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );

                return Stack(children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: shouldStretch
                        ? tableContent
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: tableContent,
                          ),
                  ),
                  if (_isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.65),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                          ),
                        ),
                      ),
                    ),
                ]);
              }),
            ),

            // â”€â”€ Pagination footer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            Container(
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text('Total Count: ', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                GestureDetector(
                  onTap: () => setState(() => _showTotalCount = !_showTotalCount),
                  child: Text(
                    _showTotalCount ? '${records.length}' : 'View',
                    style: const TextStyle(
                      fontSize: 13, color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const Spacer(),
                // Rows per page picker
                PopupMenuButton<int>(
                  tooltip: 'Rows per page',
                  offset: const Offset(0, -120),
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  onSelected: (val) => setState(() {
                    _rowsPerPage = val;
                    _currentPage = 1;
                    _allSelected = false;
                    ref.read(compositeItemsProvider.notifier).toggleSelectAll(false, 0, _allRecords.length);
                  }),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB)),
                        color: _hoveringRowsPerPage ? const Color(0xFFEFF6FF) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.access_time, size: 13,
                            color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Text('$_rowsPerPage per page',
                            style: TextStyle(fontSize: 12,
                                color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF374151))),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, size: 14,
                            color: _hoveringRowsPerPage ? const Color(0xFF2563EB) : const Color(0xFF6B7280)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Prev / page info / Next
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    MouseRegion(
                      onEnter: (_) => setState(() => _hoveringPrevPage = true),
                      onExit: (_) => setState(() => _hoveringPrevPage = false),
                      cursor: _currentPage > 1 ? SystemMouseCursors.click : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: _currentPage > 1
                            ? () => setState(() { _currentPage--; _updateAllSelectedState(); })
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _hoveringPrevPage && _currentPage > 1 ? const Color(0xFFEFF6FF) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chevron_left, size: 16,
                              color: _currentPage > 1
                                  ? (_hoveringPrevPage ? const Color(0xFF2563EB) : const Color(0xFF374151))
                                  : const Color(0xFFD1D5DB)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      records.isEmpty ? '0 - 0' : '${startIndex + 1} - $endIndex',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      onEnter: (_) => setState(() => _hoveringNextPage = true),
                      onExit: (_) => setState(() => _hoveringNextPage = false),
                      cursor: endIndex < records.length ? SystemMouseCursors.click : SystemMouseCursors.basic,
                      child: GestureDetector(
                        onTap: endIndex < records.length
                            ? () => setState(() { _currentPage++; _updateAllSelectedState(); })
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: _hoveringNextPage && endIndex < records.length ? const Color(0xFFEFF6FF) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chevron_right, size: 16,
                              color: endIndex < records.length
                                  ? (_hoveringNextPage ? const Color(0xFF2563EB) : const Color(0xFF374151))
                                  : const Color(0xFFD1D5DB)),
                        ),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Helper widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BulkActionRibbon extends StatelessWidget {
  final int selectedCount;
  final ValueChanged<String> onActionSelected;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  const _BulkActionRibbon({
    required this.selectedCount,
    required this.onActionSelected,
    required this.onDelete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          // ── Bulk Actions Dropdown ────────────────────
          PopupMenuButton<String>(
            tooltip: 'Bulk Actions',
            offset: const Offset(0, 36),
            color: Colors.white,
            surfaceTintColor: Colors.white,
            onSelected: onActionSelected,
            itemBuilder: (ctx) => [
              PopupMenuItem<String>(
                value: 'mark_active',
                padding: EdgeInsets.zero,
                height: 36,
                child: const _HoverPopupMenuItem(label: 'Mark as Active'),
              ),
              PopupMenuItem<String>(
                value: 'mark_inactive',
                padding: EdgeInsets.zero,
                height: 36,
                child: const _HoverPopupMenuItem(label: 'Mark as Inactive'),
              ),
              PopupMenuItem<String>(
                value: 'mark_returnable',
                padding: EdgeInsets.zero,
                height: 36,
                child: const _HoverPopupMenuItem(label: 'Mark as Returnable'),
              ),
              PopupMenuItem<String>(
                value: 'enable_bin',
                padding: EdgeInsets.zero,
                height: 36,
                child: const _HoverPopupMenuItem(label: 'Enable Bin location'),
              ),
              PopupMenuItem<String>(
                value: 'disable_bin',
                padding: EdgeInsets.zero,
                height: 36,
                child: const _HoverPopupMenuItem(label: 'Disable Bin location'),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                padding: EdgeInsets.zero,
                height: 36,
                child: const _HoverPopupMenuItem(label: 'Delete'),
              ),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD1D5DB)),
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bulk Actions',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down, size: 14, color: Color(0xFF6B7280)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          // ── Icon group: PDF, Print, Email ────────────
          _RibbonIconButton(icon: LucideIcons.fileText, tooltip: 'PDF', onTap: () {}),
          _RibbonIconButton(icon: LucideIcons.printer, tooltip: 'Print', onTap: () {}),
          _RibbonIconButton(icon: LucideIcons.mail, tooltip: 'Email', onTap: () {}),
          const SizedBox(width: 4),
          // Divider
          Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 12),
          // ── Delete ───────────────────────────────────
          _RibbonTextButton(label: 'Delete', onTap: onDelete, isDestructive: true),
          const SizedBox(width: 16),
          // Divider
          Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
          const SizedBox(width: 16),
          // ── Selected count badge ──────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Selected',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // ── Esc × dismiss ────────────────────────────
          GestureDetector(
            onTap: onDismiss,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Esc',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Icon(Icons.close, size: 14, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RibbonTextButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _RibbonTextButton({
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_RibbonTextButton> createState() => _RibbonTextButtonState();
}

class _RibbonTextButtonState extends State<_RibbonTextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFFF3F4F6)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFD1D5DB)),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: widget.isDestructive
                  ? Colors.black
                  : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}

class _RibbonIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _RibbonIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_RibbonIconButton> createState() => _RibbonIconButtonState();
}

class _RibbonIconButtonState extends State<_RibbonIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFF3F4F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Tooltip(
            message: widget.tooltip,
            child: Icon(
              widget.icon,
              size: 16,
              color: _hovered ? const Color(0xFF374151) : const Color(0xFF6B7280),
            ),
          ),
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.warning_rounded,
                      color: Color(0xFFEAB308),
                      size: 26,
                    ),
                    Positioned(
                      top: -3,
                      right: -3,
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFFEAB308),
                        size: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Are you sure about deleting the selected Composite Item(s)?',
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
      final List<String> categories = [
        'Assemblies',
        'Kits',
        'Safety',
      ];
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
    } else if (_selectedField == 'Tax Preference') {
      final List<String> taxes = [
        'Taxable',
        'Tax Exempt',
        'Out of Scope',
      ];
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
    } else if (_selectedField == 'Reorder Level') {
      return CustomTextField(
        controller: _valController,
        hintText: 'Enter reorder level',
        keyboardType: TextInputType.number,
        height: 40,
      );
    } else if (_selectedField == 'Manufacturer') {
      return CustomTextField(
        controller: _valController,
        hintText: 'Enter manufacturer',
        height: 40,
      );
    } else if (_selectedField == 'Brand') {
      return CustomTextField(
        controller: _valController,
        hintText: 'Enter brand',
        height: 40,
      );
    } else if (_selectedField == 'Returnable') {
      final isReturnableChecked = _valController.text == 'YES';
      final isNotReturnableChecked = _valController.text == 'NO';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _valController.text = 'YES';
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
                        color: isReturnableChecked ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                        width: isReturnableChecked ? 5 : 1,
                      ),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Check this option',
                    style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                  ),
                ],
              ),
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _valController.text = 'NO';
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
                        color: isNotReturnableChecked ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                        width: isNotReturnableChecked ? 5 : 1,
                      ),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Uncheck this option',
                    style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                  ),
                ],
              ),
            ),
          ),
        ],
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
                    'Bulk Update Composite Items',
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
              'Note: All the selected composite items will be updated with the new information and you cannot undo this action.',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_selectedField == null ||
                        _valController.text.trim().isEmpty) {
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

class _MoreMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MoreMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  State<_MoreMenuItem> createState() => _MoreMenuItemState();
}

class _MoreMenuItemState extends State<_MoreMenuItem> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: _hovered ? const Color(0xFF2563EB) : Colors.transparent,
          child: Row(children: [
            Icon(widget.icon, size: 14, color: _hovered ? Colors.white : const Color(0xFF374151)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _hovered ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ColsMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ColsMenuItem({required this.icon, required this.label, required this.onTap});

  @override
  State<_ColsMenuItem> createState() => _ColsMenuItemState();
}

class _ColsMenuItemState extends State<_ColsMenuItem> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: _hovered ? const Color(0xFF2563EB) : Colors.transparent,
          child: Row(children: [
            Icon(widget.icon, size: 14, color: _hovered ? Colors.white : const Color(0xFF374151)),
            const SizedBox(width: 10),
            Text(widget.label,
                style: TextStyle(fontSize: 13, color: _hovered ? Colors.white : const Color(0xFF374151))),
          ]),
        ),
      ),
    );
  }
}

class _ColsMenuToggleItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final ValueChanged<bool> onChanged;
  const _ColsMenuToggleItem({required this.icon, required this.label, required this.onChanged});

  @override
  State<_ColsMenuToggleItem> createState() => _ColsMenuToggleItemState();
}

class _ColsMenuToggleItemState extends State<_ColsMenuToggleItem> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => widget.onChanged(true),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          color: _hovered ? const Color(0xFF2563EB) : Colors.transparent,
          child: Row(children: [
            Icon(widget.icon, size: 14, color: _hovered ? Colors.white : const Color(0xFF374151)),
            const SizedBox(width: 10),
            Text(widget.label,
                style: TextStyle(fontSize: 13, color: _hovered ? Colors.white : const Color(0xFF374151))),
          ]),
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
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        color: _hovered ? const Color(0xFF2563EB) : Colors.transparent,
        alignment: Alignment.centerLeft,
        child: Text(
          widget.label,
          style: TextStyle(fontSize: 13, color: _hovered ? Colors.white : const Color(0xFF374151)),
        ),
      ),
    );
  }
}

// ─── More-menu sub-menu type ──────────────────────────────────────────────────
enum _SubMenuType { none, sortBy, import }

// ─── More-menu dropdown content (main panel + optional sub-panel side-by-side)
class _MoreMenuDropdownContent extends StatefulWidget {
  final _SubMenuType activeSubMenu;
  final ValueChanged<_SubMenuType> onSubMenuChanged;
  final String sortField;
  final bool sortAscending;
  final void Function(String field, bool ascending) onSort;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  const _MoreMenuDropdownContent({
    required this.activeSubMenu,
    required this.onSubMenuChanged,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.onClose,
    required this.onRefresh,
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
        if (widget.activeSubMenu != _SubMenuType.none) ...[
          _buildSubMenu(),
          const SizedBox(width: 4),
        ],
        _buildMainMenu(),
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
            child: _MoreMenuItemNew(
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
            child: _MoreMenuItemNew(
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
                _MoreMenuItemNew(
                  icon: LucideIcons.upload,
                  label: 'Export Composite Items',
                  onTap: widget.onClose,
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MoreMenuItemNew(
                  icon: LucideIcons.settings2,
                  label: 'Preferences',
                  onTap: widget.onClose,
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MoreMenuItemNew(
                  icon: LucideIcons.refreshCw,
                  label: 'Refresh List',
                  onTap: () { widget.onClose(); widget.onRefresh(); },
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),
                _MoreMenuItemNew(
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
        return _SubMenuPanel(children: [
          _buildSortItem('name',         'Name'),
          _buildSortItem('sku',          'SKU'),
          _buildSortItem('reorderLevel', 'Reorder Level'),
        ]);
      case _SubMenuType.import:
        return _SubMenuPanel(children: [
          _SubMenuItem(label: 'Import Composite Items',        onTap: widget.onClose),
          _SubMenuItem(label: 'Import Composite Items Images', onTap: widget.onClose),
        ]);
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

// ─── Sub-menu panel container ─────────────────────────────────────────────────
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

// ─── Sub-menu row item ────────────────────────────────────────────────────────
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: _hovered ? const Color(0xFF2563EB) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
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
              Icon(widget.rightIcon, size: 14,
                  color: Colors.white),
          ]),
        ),
      ),
    );
  }
}

// ─── Main menu row item ───────────────────────────────────────────────────────
class _MoreMenuItemNew extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool hasChevron;
  final bool isActive;
  final VoidCallback onTap;

  const _MoreMenuItemNew({
    required this.icon,
    required this.label,
    this.hasChevron = false,
    this.isActive = false,
    required this.onTap,
  });

  @override
  State<_MoreMenuItemNew> createState() => _MoreMenuItemNewState();
}

class _MoreMenuItemNewState extends State<_MoreMenuItemNew> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final highlighted = _hovered || widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          color: highlighted ? const Color(0xFF2563EB) : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            Icon(widget.icon, size: 14,
                color: highlighted ? Colors.white : const Color(0xFF374151)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: highlighted ? Colors.white : const Color(0xFF374151),
                ),
              ),
            ),
            if (widget.hasChevron)
              Icon(Icons.chevron_right, size: 14,
                  color: highlighted ? Colors.white : const Color(0xFF9CA3AF)),
          ]),
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

