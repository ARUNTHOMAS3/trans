import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/modules/inventory/providers/stock_provider.dart';

const _textPrimary = Color(0xFF1F2937);
const _textSecondary = Color(0xFF6B7280);
const _borderCol = Color(0xFFE5E7EB);
const _focusBorder = Color(0xFF3B82F6);
const _dangerRed = Color(0xFFEF4444);

class ScanItemSidePanel extends StatefulWidget {
  final List<WarehouseStockData> items;
  final Map<String, double> manualPickedQty;
  final Function(WarehouseStockData, double) onUpdate;
  final VoidCallback onClose;

  const ScanItemSidePanel({
    super.key,
    required this.items,
    required this.manualPickedQty,
    required this.onUpdate,
    required this.onClose,
  });

  @override
  State<ScanItemSidePanel> createState() => _ScanItemSidePanelState();
}

class _ScanItemSidePanelState extends State<ScanItemSidePanel> {
  WarehouseStockData? _selectedItem;
  final _scanCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.items.isNotEmpty) {
      _selectItem(widget.items.first);
    }
  }

  void _selectItem(WarehouseStockData item) {
    setState(() {
      _selectedItem = item;
      final rowKey = '${item.productId}_${item.batchNo ?? ''}_${item.salesOrderId ?? ''}';
      final currentQty = widget.manualPickedQty[rowKey] ?? item.quantityPicked ?? 0;
      _qtyCtrl.text = currentQty == 0 ? '' : currentQty.toInt().toString();
    });
  }

  @override
  void dispose() {
    _scanCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 500,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _borderCol)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Scan Item',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(LucideIcons.x, color: _dangerRed, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Select Item Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _borderCol),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select the item you want to pick',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FormDropdown<WarehouseStockData>(
                            value: _selectedItem,
                            items: widget.items,
                            hint: 'Select or Scan the item to pick',
                            displayStringForValue: (item) => item.productName,
                            searchStringForValue: (item) => item.productName,
                            onChanged: (val) {
                              if (val != null) _selectItem(val);
                            },
                            height: 36,
                          ),
                        ),
                        if (_selectedItem != null) ...[
                          const SizedBox(height: 16),
                          const Divider(color: _borderCol, height: 1),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Status', style: TextStyle(fontSize: 12, color: _textSecondary)),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _selectedItem!.status == 'COMPLETED' ? 'Completed' : 'In Progress',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Sales Order#', style: TextStyle(fontSize: 12, color: _textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedItem!.salesOrderNumber != null ? '[${_selectedItem!.salesOrderNumber}]' : '-',
                                      style: const TextStyle(fontSize: 13, color: _textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text('Quantity to pick', style: TextStyle(fontSize: 12, color: _textSecondary)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_selectedItem!.quantityToPick?.toInt() ?? 0} box',
                                      style: const TextStyle(fontSize: 14, color: _textPrimary, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_selectedItem != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Add Quantity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _borderCol),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Item Quantity',
                                      style: TextStyle(fontSize: 13, color: _textPrimary, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(LucideIcons.info, size: 14, color: _textSecondary),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextField(
                                    controller: _scanCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Scan Item',
                                      hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.5), fontSize: 13),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: _focusBorder),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: _focusBorder),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(6),
                                        borderSide: const BorderSide(color: _focusBorder, width: 1.5),
                                      ),
                                    ),
                                    onSubmitted: (val) {
                                      if (val.isNotEmpty) {
                                        final currentQty = double.tryParse(_qtyCtrl.text) ?? 0;
                                        setState(() {
                                          _qtyCtrl.text = (currentQty + 1).toInt().toString();
                                          _scanCtrl.clear();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: _borderCol),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Picked Items',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textPrimary),
                                    ),
                                    Builder(
                                      builder: (context) {
                                        final picked = double.tryParse(_qtyCtrl.text) ?? 0;
                                        final toPick = _selectedItem!.quantityToPick ?? 0;
                                        final yetToPick = (toPick - picked).clamp(0, double.infinity);
                                        return Text(
                                          'Yet to be picked: ${yetToPick.toInt()} box',
                                          style: const TextStyle(fontSize: 13, color: _textPrimary),
                                        );
                                      }
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: _borderCol),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF8FAFC),
                                          border: Border(bottom: BorderSide(color: _borderCol)),
                                        ),
                                        child: const Text(
                                          'QUANTITY PICKED',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textSecondary, letterSpacing: 0.5),
                                        ),
                                      ),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        alignment: Alignment.centerRight,
                                        child: SizedBox(
                                          width: 100,
                                          child: TextField(
                                            controller: _qtyCtrl,
                                            textAlign: TextAlign.right,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              isDense: true,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(4),
                                                borderSide: const BorderSide(color: _borderCol),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(4),
                                                borderSide: const BorderSide(color: _borderCol),
                                              ),
                                            ),
                                            onChanged: (val) => setState(() {}),
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
                ],
              ),
            ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _borderCol)),
            ),
            child: Row(
              children: [
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: _selectedItem == null ? null : () {
                      final newQty = double.tryParse(_qtyCtrl.text) ?? 0;
                      widget.onUpdate(_selectedItem!, newQty);
                      widget.onClose();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF42B883),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Update', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: widget.onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textPrimary,
                      side: const BorderSide(color: _borderCol),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
