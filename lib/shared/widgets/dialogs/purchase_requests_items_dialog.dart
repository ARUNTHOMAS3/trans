import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class PurchaseRequestItem {
  final String id;
  final String productName;
  final String productId;
  final String requestNumber;
  final double quantity;
  final double rate;
  final DateTime expectedDate;
  final bool isOnHold;

  const PurchaseRequestItem({
    required this.id,
    required this.productName,
    required this.productId,
    required this.requestNumber,
    required this.quantity,
    required this.rate,
    required this.expectedDate,
    this.isOnHold = false,
  });
}

class PurchaseRequestsItemsDialog extends StatefulWidget {
  final Function(List<PurchaseRequestItem>) onItemsSelected;

  const PurchaseRequestsItemsDialog({
    super.key,
    required this.onItemsSelected,
  });

  @override
  State<PurchaseRequestsItemsDialog> createState() => _PurchaseRequestsItemsDialogState();
}

class _PurchaseRequestsItemsDialogState extends State<PurchaseRequestsItemsDialog> {
  String _searchQuery = '';
  bool _includeOnHold = false;
  String _dateFilterType = 'Expected Date';
  String _timeframe = 'This Month';

  final List<PurchaseRequestItem> _selectedItems = [];
  String? _hoveredItemId;

  // Mock Purchase Requests data
  final List<PurchaseRequestItem> _mockPurchaseRequestItems = [
    PurchaseRequestItem(
      id: 'pr-1',
      productName: 'Acetaminophen 325mg',
      productId: 'prod-1',
      requestNumber: 'PR-2026-001',
      quantity: 100.0,
      rate: 12.50,
      expectedDate: DateTime(2026, 6, 15),
    ),
    PurchaseRequestItem(
      id: 'pr-2',
      productName: 'Ibuprofen 200mg',
      productId: 'prod-2',
      requestNumber: 'PR-2026-002',
      quantity: 250.0,
      rate: 8.20,
      expectedDate: DateTime(2026, 6, 20),
    ),
    PurchaseRequestItem(
      id: 'pr-3',
      productName: 'Amoxicillin 500mg',
      productId: 'prod-3',
      requestNumber: 'PR-2026-003',
      quantity: 50.0,
      rate: 45.00,
      expectedDate: DateTime(2026, 7, 5),
      isOnHold: true,
    ),
    PurchaseRequestItem(
      id: 'pr-4',
      productName: 'Atorvastatin 10mg',
      productId: 'prod-4',
      requestNumber: 'PR-2026-004',
      quantity: 500.0,
      rate: 15.00,
      expectedDate: DateTime(2026, 6, 12),
    ),
    PurchaseRequestItem(
      id: 'pr-5',
      productName: 'Metformin 850mg',
      productId: 'prod-5',
      requestNumber: 'PR-2026-005',
      quantity: 300.0,
      rate: 6.80,
      expectedDate: DateTime(2026, 6, 28),
      isOnHold: true,
    ),
  ];

  List<PurchaseRequestItem> get _filteredPrItems {
    var items = _mockPurchaseRequestItems;

    // Filter by On Hold
    if (!_includeOnHold) {
      items = items.where((item) => !item.isOnHold).toList();
    }

    // Filter by Date Timeframe (mock filter logic)
    final now = DateTime.now();
    items = items.where((item) {
      if (_timeframe == 'This Month') {
        return item.expectedDate.month == now.month && item.expectedDate.year == now.year;
      } else if (_timeframe == 'Today') {
        return item.expectedDate.day == now.day &&
            item.expectedDate.month == now.month &&
            item.expectedDate.year == now.year;
      }
      return true;
    }).toList();

    // Filter by Search Query
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((item) {
        return item.productName.toLowerCase().contains(query) ||
            item.requestNumber.toLowerCase().contains(query);
      }).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPrItems;

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(
        top: 0,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: Container(
        width: 800,
        height: 600,
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Items From Purchase Requests',
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

            // Filters Section (Expected Date / Timeframe / Include On Hold)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  // Expected Date Dropdown Trigger
                  _buildDropdownTrigger(
                    value: _dateFilterType,
                    onTap: () {
                      _showDateFilterMenu();
                    },
                  ),
                  const SizedBox(width: 8),
                  // Timeframe Dropdown Trigger
                  _buildDropdownTrigger(
                    value: _timeframe,
                    onTap: () {
                      _showTimeframeMenu();
                    },
                  ),
                  const SizedBox(width: 24),
                  // Include on hold checkbox
                  InkWell(
                    onTap: () => setState(() => _includeOnHold = !_includeOnHold),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: Checkbox(
                            value: _includeOnHold,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (v) => setState(() => _includeOnHold = v ?? false),
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Include on hold items',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Panes Section
            Expanded(
              child: Row(
                children: [
                  // Left Pane (Search + PR List)
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      child: Column(
                        children: [
                          // Search Box
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5), width: 1.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: TextField(
                                onChanged: (v) => setState(() => _searchQuery = v),
                                style: const TextStyle(fontSize: 13),
                                decoration: const InputDecoration(
                                  hintText: 'Type to search purchase requests items',
                                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ),

                          // Items List
                          Expanded(
                            child: filtered.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 32),
                                      child: Text(
                                        'No results found. Try a different keyword.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: filtered.length,
                                    itemBuilder: (context, index) {
                                      final item = filtered[index];
                                      final isSelected = _selectedItems.any((i) => i.id == item.id);
                                      final isHovered = _hoveredItemId == item.id;

                                      return InkWell(
                                        onHover: (h) => setState(() => _hoveredItemId = h ? item.id : null),
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              _selectedItems.removeWhere((i) => i.id == item.id);
                                            } else {
                                              _selectedItems.add(item);
                                            }
                                          });
                                        },
                                        child: Container(
                                          color: isSelected
                                              ? const Color(0xFFEFF6FF)
                                              : isHovered
                                                  ? const Color(0xFFF3F4F6)
                                                  : Colors.transparent,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.productName,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                        color: (isSelected || isHovered)
                                                            ? const Color(0xFF3B82F6)
                                                            : const Color(0xFF111827),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          'PR: ${item.requestNumber}',
                                                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Text(
                                                          'Qty: ${item.quantity.toStringAsFixed(0)}',
                                                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                                        ),
                                                        const SizedBox(width: 12),
                                                        Text(
                                                          'Rate: ₹${item.rate.toStringAsFixed(2)}',
                                                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (isSelected) ...[
                                                const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
                                              ] else if (isHovered) ...[
                                                const Icon(Icons.check_circle, color: Color(0xFFD1D5DB), size: 22),
                                              ],
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

                  // Right Pane (Selected list summary + Actions)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title / Counter
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
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
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFD1D5DB)),
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
                        ),

                        // List of selected
                        Expanded(
                          child: _selectedItems.isEmpty
                              ? const Center(
                                  child: Text(
                                    'Click the item names from the left\npane to select them',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: _selectedItems.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final item = _selectedItems[index];

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.productName,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                      color: Color(0xFF111827),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Qty: ${item.quantity.toStringAsFixed(0)} • Rate: ₹${item.rate.toStringAsFixed(2)}',
                                                    style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                              onPressed: () {
                                                setState(() {
                                                  _selectedItems.removeWhere((i) => i.id == item.id);
                                                });
                                              },
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                ),
                        ),

                        // Actions Footer inside right pane
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ZButton.primary(
                                label: 'Add Items',
                                onPressed: _selectedItems.isEmpty
                                    ? null
                                    : () {
                                        widget.onItemsSelected(_selectedItems);
                                        Navigator.of(context).pop();
                                      },
                              ),
                              const SizedBox(width: 12),
                              ZButton.secondary(
                                label: 'Cancel',
                                onPressed: () => Navigator.of(context).pop(),
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

  Widget _buildDropdownTrigger({
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF6B7280)),
          ],
        ),
      ),
    );
  }

  void _showDateFilterMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomLeft(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      items: const [
        PopupMenuItem<String>(value: 'Expected Date', child: Text('Expected Date')),
        PopupMenuItem<String>(value: 'Created Date', child: Text('Created Date')),
      ],
    ).then((val) {
      if (val != null) {
        setState(() => _dateFilterType = val);
      }
    });
  }

  void _showTimeframeMenu() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomLeft(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      items: const [
        PopupMenuItem<String>(value: 'This Month', child: Text('This Month')),
        PopupMenuItem<String>(value: 'Today', child: Text('Today')),
        PopupMenuItem<String>(value: 'This Week', child: Text('This Week')),
        PopupMenuItem<String>(value: 'This Quarter', child: Text('This Quarter')),
        PopupMenuItem<String>(value: 'This Year', child: Text('This Year')),
      ],
    ).then((val) {
      if (val != null) {
        setState(() => _timeframe = val);
      }
    });
  }
}
