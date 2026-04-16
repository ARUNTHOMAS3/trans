import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';

class WarehouseHoverPopover extends ConsumerStatefulWidget {
  final Widget child;
  final String warehouseName;
  final String selectedView;
  final ValueChanged<String> onViewChanged;
  final ValueChanged<String> onWarehouseChanged;

  const WarehouseHoverPopover({
    super.key,
    required this.child,
    required this.warehouseName,
    required this.selectedView,
    required this.onViewChanged,
    required this.onWarehouseChanged,
  });

  @override
  ConsumerState<WarehouseHoverPopover> createState() => _WarehouseHoverPopoverState();
}

class _WarehouseHoverPopoverState extends ConsumerState<WarehouseHoverPopover> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
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
              targetAnchor: Alignment.topCenter,
              followerAnchor: Alignment.bottomCenter,
              offset: const Offset(0, -6),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        onViewChanged: widget.onViewChanged,
                        onWarehouseChanged: (name) {
                          widget.onWarehouseChanged(name);
                          _closeOverlay();
                        },
                        onClose: _closeOverlay,
                      ),
                    ),
                    CustomPaint(
                      size: const Size(14, 7),
                      painter: _PopoverArrowPainter(
                        color: Colors.white,
                        borderColor: const Color(0xFFE5E7EB),
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
  final ValueChanged<String> onViewChanged;
  final ValueChanged<String> onWarehouseChanged;
  
  const _WarehousePopoverContent({
    required this.onClose, 
    required this.warehouseName,
    required this.selectedView,
    required this.onViewChanged,
    required this.onWarehouseChanged,
  });

  @override
  ConsumerState<_WarehousePopoverContent> createState() => _WarehousePopoverContentState();
}

class _WarehousePopoverContentState extends ConsumerState<_WarehousePopoverContent> {
  late String _localSelectedView;
  String selectedStockType = 'Accounting';
  bool isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _localSelectedView = widget.selectedView;
  }

  void _toggleStockType(String type) {
    setState(() {
      selectedStockType = type;
      isDropdownOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String footer1, footer2, footer3;
    if (selectedStockType == 'Accounting') {
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
                        GestureDetector(
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
                                    color: selectedStockType == 'Accounting' ? const Color(0xFF3B82F6) : Colors.white,
                                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(3), bottomLeft: Radius.circular(3)),
                                  ),
                                  child: Text('Accounting Stock', style: TextStyle(
                                    fontSize: 12, 
                                    fontFamily: 'Inter', 
                                    color: selectedStockType == 'Accounting' ? Colors.white : const Color(0xFF3B82F6)
                                  )),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _toggleStockType('Physical'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: selectedStockType == 'Physical' ? const Color(0xFF3B82F6) : Colors.white,
                                    borderRadius: const BorderRadius.only(topRight: Radius.circular(3), bottomRight: Radius.circular(3)),
                                  ),
                                  child: Text('Physical Stock', style: TextStyle(
                                    fontSize: 12, 
                                    fontFamily: 'Inter', 
                                    color: selectedStockType == 'Physical' ? Colors.white : const Color(0xFF3B82F6)
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Row(children: [const Text('Location Name', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')), const SizedBox(width: 4), const Icon(LucideIcons.search, size: 12, color: Color(0xFF9CA3AF))])),
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: [
                          Text('$selectedStockType Stock', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Expanded(child: Text('Stock on Hand', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter'))),
                              Expanded(child: Text('Committed Stock', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter'))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2, 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Available for Sale', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontFamily: 'Inter')),
                          const SizedBox(height: 4),
                          const Icon(LucideIcons.eye, size: 14, color: Color(0xFF9CA3AF)),
                        ],
                      )
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              
              // DYNAMIC DB ROWS
              ref.watch(warehousesProvider).when(
                data: (warehouses) {
                  // Sort: selected warehouse first
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
                      
                      // Stock values reset to 0.00 (awaiting real stock integration per warehouse)
                      String wHand = '0.00';
                      String wComm = '0.00';
                      String wAvail = '0.00';

                      return InkWell(
                        onTap: () => widget.onWarehouseChanged(name),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(flex: 3, child: Row(children: [
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
                                  ])),
                                  Expanded(flex: 2, child: Text(wHand, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal, fontFamily: 'Inter'))),
                                  Expanded(flex: 2, child: Text(wComm, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontFamily: 'Inter', color: Color(0xFF6B7280)))),
                                  Expanded(flex: 2, child: Text(wAvail, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter'))),
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
          Positioned(
            top: 42,
            left: 204,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 160,
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
  _PopoverArrowPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

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
    canvas.drawLine(const Offset(1, 0), Offset(size.width - 1, 0), mergePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
