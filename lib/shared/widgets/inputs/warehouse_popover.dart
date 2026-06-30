import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/items/items/presentation/sections/items_stock_providers.dart';

class WarehouseHoverPopover extends ConsumerStatefulWidget {
  final Widget child;
  final String warehouseName;
  final String selectedView;
  final String? selectedStockType;
  final ValueChanged<String>? onViewChanged;
  final ValueChanged<String>? onStockTypeChanged;
  final ValueChanged<String> onWarehouseChanged;
  final String? productId;

  const WarehouseHoverPopover({
    super.key,
    required this.child,
    required this.warehouseName,
    required this.selectedView,
    this.selectedStockType,
    this.onViewChanged,
    this.onStockTypeChanged,
    required this.onWarehouseChanged,
    this.productId,
  });

  @override
  ConsumerState<WarehouseHoverPopover> createState() => _WarehouseHoverPopoverState();
}

class _WarehouseHoverPopoverState extends ConsumerState<WarehouseHoverPopover> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);
    
    // Determine if there is enough space below dynamically (popover needs ~350px height)
    final double screenHeight = MediaQuery.of(context).size.height;
    final double spaceBelow = screenHeight - position.dy - renderBox.size.height;
    final double spaceAbove = position.dy;
    
    final bool showBelow = spaceBelow >= 350 || spaceBelow > spaceAbove;
    
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: showBelow ? Alignment.bottomCenter : Alignment.topCenter,
              followerAnchor: showBelow ? Alignment.topCenter : Alignment.bottomCenter,
              offset: Offset(0, showBelow ? 6 : -6),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBelow)
                      CustomPaint(
                        size: const Size(14, 7),
                        painter: _PopoverArrowPainter(
                          color: Colors.white,
                          borderColor: const Color(0xFFE5E7EB),
                          isUp: true,
                        ),
                      ),
                    Container(
                      width: 620,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: const [
                           BoxShadow(
                             color: Color(0x1A000000), 
                             blurRadius: 10, 
                             offset: Offset(0, 4)
                           ),
                        ],
                      ),
                      child: _WarehousePopoverContent(
                        warehouseName: widget.warehouseName,
                        selectedView: widget.selectedView,
                        selectedStockType: widget.selectedStockType ?? 'Physical',
                        onViewChanged: (v) {
                          if (widget.onViewChanged != null) {
                            widget.onViewChanged!(v);
                          }
                        },
                        onStockTypeChanged: (t) {
                          if (widget.onStockTypeChanged != null) {
                            widget.onStockTypeChanged!(t);
                          }
                        },
                        productId: widget.productId,
                        onWarehouseChanged: (name) {
                          widget.onWarehouseChanged(name);
                          _closeOverlay();
                        },
                        onClose: _closeOverlay,
                      ),
                    ),
                    if (!showBelow)
                      CustomPaint(
                        size: const Size(14, 7),
                        painter: _PopoverArrowPainter(
                          color: Colors.white,
                          borderColor: const Color(0xFFE5E7EB),
                          isUp: false,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void deactivate() {
    _closeOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _showOverlay,
        child: widget.child,
      ),
    );
  }
}

class _WarehousePopoverContent extends ConsumerStatefulWidget {
  final VoidCallback onClose;
  final String warehouseName;
  final String selectedView;
  final String selectedStockType;
  final ValueChanged<String> onViewChanged;
  final ValueChanged<String> onStockTypeChanged;
  final ValueChanged<String> onWarehouseChanged;
  final String? productId;
  
  const _WarehousePopoverContent({
    required this.onClose, 
    required this.warehouseName,
    required this.selectedView,
    required this.selectedStockType,
    required this.onViewChanged,
    required this.onStockTypeChanged,
    required this.onWarehouseChanged,
    this.productId,
  });

  @override
  ConsumerState<_WarehousePopoverContent> createState() => _WarehousePopoverContentState();
}

class _WarehousePopoverContentState extends ConsumerState<_WarehousePopoverContent> {
  late String _localSelectedView;
  late String _localSelectedStockType;
  bool isDropdownOpen = false;
  final LayerLink _dropdownLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _localSelectedView = widget.selectedView;
    _localSelectedStockType = widget.selectedStockType;
  }

  @override
  void didUpdateWidget(covariant _WarehousePopoverContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedView != widget.selectedView) {
      _localSelectedView = widget.selectedView;
    }
    if (oldWidget.selectedStockType != widget.selectedStockType) {
      _localSelectedStockType = widget.selectedStockType;
    }
  }

  void _toggleStockType(String type) {
    setState(() {
      _localSelectedStockType = type;
      widget.onStockTypeChanged(type);
      isDropdownOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String footer1, footer2, footer3;
    if (_localSelectedStockType == 'Accounting') {
      footer1 = 'Stock on Hand : This is calculated based on Bills and Invoices.';
      footer2 = 'Committed Stock : Stock that is committed to sales order(s) but not yet invoiced';
      footer3 = 'Available for Sale : Stock on Hand - Committed Stock';
    } else {
      footer1 = 'Stock on Hand : Based on Receives and Shipments';
      footer2 = 'Committed Stock : Committed but not shipped';
      footer3 = 'Available for Sale : Stock on Hand - Committed Stock';
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () {
            if (isDropdownOpen) setState(() => isDropdownOpen = false);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(child: Text('Warehouse Locations', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis)),
                    Row(
                      children: [
                        const Text('View: ', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')),
                        CompositedTransformTarget(
                          link: _dropdownLink,
                          child: GestureDetector(
                            onTap: () => setState(() => isDropdownOpen = !isDropdownOpen),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                borderRadius: BorderRadius.circular(4),
                                color: Colors.white,
                              ),
                              child: Row(
                                children: [
                                  Text(_localSelectedView, style: const TextStyle(fontSize: 12, fontFamily: 'Inter', color: Color(0xFF374151))),
                                  const SizedBox(width: 4),
                                  const Icon(LucideIcons.chevronDown, size: 14, color: Color(0xFF6B7280)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF3B82F6)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _toggleStockType('Accounting'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _localSelectedStockType == 'Accounting' ? const Color(0xFF3B82F6) : Colors.white,
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), bottomLeft: Radius.circular(3)),
                                  ),
                                  child: Text('Accounting Stock', style: TextStyle(
                                    fontSize: 12, 
                                    fontFamily: 'Inter', 
                                    color: _localSelectedStockType == 'Accounting' ? Colors.white : const Color(0xFF3B82F6)
                                  )),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _toggleStockType('Physical'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _localSelectedStockType == 'Physical' ? const Color(0xFF3B82F6) : Colors.white,
                                    borderRadius: const BorderRadius.only(topRight: Radius.circular(3), bottomRight: Radius.circular(3)),
                                  ),
                                  child: Text('Physical Stock', style: TextStyle(
                                    fontSize: 12, 
                                    fontFamily: 'Inter', 
                                    color: _localSelectedStockType == 'Physical' ? Colors.white : const Color(0xFF3B82F6)
                                  )),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: widget.onClose,
                          child: const Icon(LucideIcons.x, size: 20, color: Color(0xFFDC2626)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              Container( // TABLE HEADER
                color: const Color(0xFFF9FAFB),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Text('Warehouse Name', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')),
                              const SizedBox(width: 4),
                              const Icon(LucideIcons.search, size: 12, color: Color(0xFF9CA3AF)),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, color: const Color(0xFFE5E7EB)),
                      Expanded(
                        flex: 4,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              Text('$_localSelectedStockType Stock', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')),
                              const SizedBox(height: 8),
                              const Divider(height: 1, color: Color(0xFFE5E7EB)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('Stock on Hand', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')),
                                        if (_localSelectedView == 'Stock on Hand') ...[
                                          const SizedBox(height: 4),
                                          const Icon(LucideIcons.eye, size: 14, color: Color(0xFF9CA3AF)),
                                        ] else ...[
                                          const SizedBox(height: 18),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Text('Committed Stock', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')),
                                        if (_localSelectedView == 'Committed Stock') ...[
                                          const SizedBox(height: 4),
                                          const Icon(LucideIcons.eye, size: 14, color: Color(0xFF9CA3AF)),
                                        ] else ...[
                                          const SizedBox(height: 18),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, color: const Color(0xFFE5E7EB)),
                      Expanded(
                        flex: 2, 
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8, right: 16, top: 8, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Available for Sale', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')),
                              if (_localSelectedView == 'Available for Sale') ...[
                                const SizedBox(height: 4),
                                const Icon(LucideIcons.eye, size: 14, color: Color(0xFF9CA3AF)),
                              ] else ...[
                                const SizedBox(height: 18),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              
              // DYNAMIC DB ROWS
              (widget.productId == null || widget.productId!.isEmpty)
                  ? ref.watch(warehousesProvider).when(
                      data: (warehouses) {
                        final sorted = [...warehouses];
                        sorted.sort((a, b) {
                          final aSelected = a.name == widget.warehouseName;
                          final bSelected = b.name == widget.warehouseName;
                          if (aSelected && !bSelected) return -1;
                          if (!aSelected && bSelected) return 1;
                          return 0;
                        });
                        return Column(
                          children: sorted.map((w) {
                            final name = w.name;
                            final isSelected = widget.warehouseName == name;
                            
                            String wHand, wComm, wAvail;
                            if (_localSelectedStockType == 'Accounting') {
                              wHand = '0.00';
                              wComm = '0.00';
                              wAvail = '0.00';
                            } else {
                              wHand = '0.00';
                              wComm = '0.00';
                              wAvail = '0.00';
                            }

                            return InkWell(
                              onTap: () => widget.onWarehouseChanged(name),
                              child: Column(
                                children: [
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 16, height: 16,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB), 
                                                      width: isSelected ? 2 : 1.5
                                                    ),
                                                  ),
                                                  padding: isSelected ? const EdgeInsets.all(3) : null,
                                                  child: isSelected ? Container(
                                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3B82F6)),
                                                  ) : null,
                                                ),
                                                const SizedBox(width: 10), 
                                                Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: Color(0xFF374151)), overflow: TextOverflow.ellipsis))
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                            child: Center(
                                              child: Text(wHand, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, fontFamily: 'Inter')),
                                            ),
                                          ),
                                        ),
                                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                            child: Center(
                                              child: Text(wComm, style: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: Color(0xFF6B7280))),
                                            ),
                                          ),
                                        ),
                                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(wAvail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error loading warehouses: $e', style: const TextStyle(fontSize: 12, color: Colors.grey)))),
                    )
                  : ref.watch(itemWarehouseStocksProvider(widget.productId!)).when(
                      data: (stocks) {
                        final sorted = [...stocks];
                        sorted.sort((a, b) {
                          final aSelected = a.name == widget.warehouseName;
                          final bSelected = b.name == widget.warehouseName;
                          if (aSelected && !bSelected) return -1;
                          if (!aSelected && bSelected) return 1;
                          return 0;
                        });
                        return Column(
                          children: sorted.map((w) {
                            final name = w.name;
                            final isSelected = widget.warehouseName == name;

                            final numbers = _localSelectedStockType == 'Accounting' ? w.accounting : w.physical;
                            final wHand = '${numbers.onHand.toInt()}.00';
                            final wComm = '${numbers.committed.toInt()}.00';
                            final wAvail = '${numbers.available.toInt()}.00';

                            return InkWell(
                              onTap: () => widget.onWarehouseChanged(name),
                              child: Column(
                                children: [
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 16, height: 16,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB), 
                                                      width: isSelected ? 2 : 1.5
                                                    ),
                                                  ),
                                                  padding: isSelected ? const EdgeInsets.all(3) : null,
                                                  child: isSelected ? Container(
                                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF3B82F6)),
                                                  ) : null,
                                                ),
                                                const SizedBox(width: 10), 
                                                Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: Color(0xFF374151)), overflow: TextOverflow.ellipsis))
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                            child: Center(
                                              child: Text(wHand, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, fontFamily: 'Inter')),
                                            ),
                                          ),
                                        ),
                                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                            child: Center(
                                              child: Text(wComm, style: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: Color(0xFF6B7280))),
                                            ),
                                          ),
                                        ),
                                        Container(width: 1, color: const Color(0xFFE5E7EB)),
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.only(left: 8, right: 16, top: 12, bottom: 12),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(wAvail, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2))),
                      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('Error loading warehouse stocks: $e', style: const TextStyle(fontSize: 12, color: Colors.grey)))),
                    ),
              
              // FOOTER
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(footer1, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text(footer2, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text(footer3, style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563), fontFamily: 'Inter')),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        if (isDropdownOpen)
          CompositedTransformFollower(
            link: _dropdownLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 32),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 130,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDropdownItem('Stock on Hand'),
                    _buildDropdownItem('Available for Sale'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDropdownItem(String text) {
    return _CommonDropdownItem(
      text: text, 
      isSelected: _localSelectedView == text, 
      onTap: () {
        setState(() {
          _localSelectedView = text;
          widget.onViewChanged(text);
          isDropdownOpen = false;
        });
      },
    );
  }
}

class _CommonDropdownItem extends StatefulWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _CommonDropdownItem({
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_CommonDropdownItem> createState() => _CommonDropdownItemState();
}

class _CommonDropdownItemState extends State<_CommonDropdownItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: _isHovered 
              ? const Color(0xFF3B82F6) 
              : (widget.isSelected ? const Color(0xFFF3F4F6) : Colors.transparent),
          child: Text(
            widget.text,
            style: TextStyle(
              fontSize: 12,
              color: _isHovered ? Colors.white : const Color(0xFF374151),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

class _PopoverArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool isUp;
  _PopoverArrowPainter({
    required this.color,
    required this.borderColor,
    required this.isUp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    if (isUp) {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width / 2, 0);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width / 2, size.height);
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
    
    final mergePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    if (isUp) {
      canvas.drawLine(Offset(1, size.height), Offset(size.width - 1, size.height), mergePaint);
    } else {
      canvas.drawLine(const Offset(1, 0), Offset(size.width - 1, 0), mergePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PopoverArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.isUp != isUp;
  }
}
