import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';

class BulkItemsDialog extends ConsumerStatefulWidget {
  final List<Item> products;
  final Function(Map<Item, int>) onItemsSelected;

  const BulkItemsDialog({
    Key? key,
    required this.products,
    required this.onItemsSelected,
  }) : super(key: key);

  @override
  ConsumerState<BulkItemsDialog> createState() => _BulkItemsDialogState();
}

class _BulkItemsDialogState extends ConsumerState<BulkItemsDialog> {
  String _searchQuery = '';
  Set<String> _selectedCategoryIds = {};

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;
  List<Item> _selectedItems = [];
  Map<String, int> _itemQuantities = {};

  List<Item> get _filteredProducts {
    List<Item> results = widget.products;

    if (_selectedCategoryIds.isNotEmpty) {
      results = results
          .where((p) => _selectedCategoryIds.contains(p.categoryId))
          .toList();
    }

    if (_searchQuery.isEmpty) return results;
    return results.where((p) {
      return p.productName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.sku?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }


  void _toggleCategoryFilterMenu() {
    if (_isMenuOpen) {
      _closeCategoryFilterMenu();
    } else {
      _openCategoryFilterMenu();
    }
  }

  void _openCategoryFilterMenu() {
    final categories = ref.read(itemsControllerProvider).categories;
    final overlay = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _closeCategoryFilterMenu,
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: Colors.transparent)),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 36),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: Container(
                  width: 280,
                  padding: const EdgeInsets.all(12),
                  child: _CategoryFilterMenu(
                    categories: categories,
                    initialSelected: _selectedCategoryIds,
                    onApply: (selected) {
                      setState(() {
                        _selectedCategoryIds = selected;
                      });
                      _closeCategoryFilterMenu();
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() => _isMenuOpen = true);
  }

  void _closeCategoryFilterMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _isMenuOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalQty = _itemQuantities.values.fold(0, (sum, q) => sum + q);
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(
        top: 40,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        width: 800,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Items in Bulk',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.red, size: 20),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Pane
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      LucideIcons.filter,
                                      size: 20,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    const SizedBox(width: 12),
                                    CompositedTransformTarget(
                                      link: _layerLink,
                                      child: GestureDetector(
                                        onTap: _toggleCategoryFilterMenu,
                                        child: CustomPaint(
                                          painter: DashedBorderPainter(
                                            color: const Color(0xFF3B82F6),
                                            borderRadius: 4,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Text(
                                                  'Category',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                                if (_selectedCategoryIds.isNotEmpty)
                                                  Text(
                                                    ' (${_selectedCategoryIds.length})',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      color: Color(0xFF3B82F6),
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  _isMenuOpen
                                                      ? Icons.keyboard_arrow_up
                                                      : Icons.keyboard_arrow_down,
                                                  size: 16,
                                                  color: const Color(0xFF3B82F6),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF3B82F6).withAlpha(
                                        128,
                                      ),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: TextField(
                                    onChanged: (val) =>
                                        setState(() => _searchQuery = val),
                                    style: const TextStyle(fontSize: 13),
                                    decoration: const InputDecoration(
                                      hintText:
                                          'Type to search or scan the barcode of the item',
                                      hintStyle: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: _filteredProducts.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = _filteredProducts[index];
                                final isSelected = _selectedItems.any(
                                  (i) => i.id == item.id,
                                );
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedItems.removeWhere(
                                          (i) => i.id == item.id,
                                        );
                                        _itemQuantities.remove(item.id!);
                                      } else {
                                        _selectedItems.add(item);
                                        _itemQuantities[item.id!] = 1;
                                      }
                                    });
                                  },
                                  child: Container(
                                    color: isSelected
                                        ? const Color(0xFFEFF6FF)
                                        : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.productName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: isSelected
                                                      ? const Color(0xFF2563EB)
                                                      : const Color(0xFF111827),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Rate: ₹${item.sellingPrice?.toStringAsFixed(2) ?? "0.00"}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF10B981),
                                            size: 20,
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
                  // Right Pane
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Selected Items',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFD1D5DB),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_selectedItems.length}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Total Quantity: $totalQty',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _selectedItems.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Click the item names from the left pane to\nselect them',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _selectedItems.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final item = _selectedItems[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.productName,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF111827),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(
                                                color: const Color(0xFFD1D5DB),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      int current =
                                                          _itemQuantities[item
                                                              .id!] ??
                                                          1;
                                                      if (current > 1) {
                                                        _itemQuantities[item
                                                                .id!] =
                                                            current - 1;
                                                      } else {
                                                        _selectedItems
                                                            .removeWhere(
                                                              (i) =>
                                                                  i.id ==
                                                                  item.id,
                                                            );
                                                        _itemQuantities.remove(
                                                          item.id!,
                                                        );
                                                      }
                                                    });
                                                  },
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: Icon(
                                                      LucideIcons.minus,
                                                      size: 14,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ),
                                                Container(
                                                  width: 32,
                                                  alignment: Alignment.center,
                                                  decoration:
                                                      const BoxDecoration(
                                                        border: Border(
                                                          left: BorderSide(
                                                            color: Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                          right: BorderSide(
                                                            color: Color(
                                                              0xFFD1D5DB,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                  child: Text(
                                                    '${_itemQuantities[item.id!] ?? 1}',
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF374151),
                                                    ),
                                                  ),
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _itemQuantities[item
                                                              .id!] =
                                                          (_itemQuantities[item
                                                                  .id!] ??
                                                              1) +
                                                          1;
                                                    });
                                                  },
                                                  child: const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                        ),
                                                    child: Icon(
                                                      LucideIcons.plus,
                                                      size: 14,
                                                      color: Color(0xFF6B7280),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        // Bottom Actions
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                          ),
                          child: Row(
                            children: [
                              ElevatedButton(
                                onPressed: _selectedItems.isEmpty
                                    ? null
                                    : () {
                                        Map<Item, int> selectedWithQty = {};
                                        for (var item in _selectedItems) {
                                          selectedWithQty[item] =
                                              _itemQuantities[item.id!] ?? 1;
                                        }
                                        widget.onItemsSelected(selectedWithQty);
                                        Navigator.of(context).pop();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF10B981,
                                  ), // Green Color
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Add Items',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  foregroundColor: const Color(0xFF374151),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFilterMenu extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Set<String> initialSelected;
  final ValueChanged<Set<String>> onApply;

  const _CategoryFilterMenu({
    required this.categories,
    required this.initialSelected,
    required this.onApply,
  });

  @override
  State<_CategoryFilterMenu> createState() => _CategoryFilterMenuState();
}

class _CategoryFilterMenuState extends State<_CategoryFilterMenu> {
  late Set<String> _tempSelected;
  String _menuSearch = '';

  @override
  void initState() {
    super.initState();
    _tempSelected = Set.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.categories.where((c) {
      final name = c['name']?.toString().toLowerCase() ?? '';
      return name.contains(_menuSearch.toLowerCase());
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Menu Search
        Container(
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF3B82F6).withAlpha(128)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _menuSearch = val),
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'Search',
              prefixIcon: Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(bottom: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Category List
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: SingleChildScrollView(
            child: Column(
              children: filtered.map((cat) {
                final id = cat['id'].toString();
                final isSelected = _tempSelected.contains(id);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _tempSelected.remove(id);
                      } else {
                        _tempSelected.add(id);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _tempSelected.add(id);
                                } else {
                                  _tempSelected.remove(id);
                                }
                              });
                            },
                            activeColor: const Color(0xFF3B82F6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat['name']?.toString().toUpperCase() ?? '',
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
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Apply Button
        ElevatedButton(
          onPressed: () => widget.onApply(_tempSelected),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: const Text(
            'Apply',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashWidth;
  final double borderRadius;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1.0,
    this.gap = 3.0,
    this.dashWidth = 3.0,
    this.borderRadius = 4.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final Path dashedPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashedPath.addPath(
          metric.extractPath(distance, distance + dashWidth),
          Offset.zero,
        );
        distance += dashWidth + gap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
