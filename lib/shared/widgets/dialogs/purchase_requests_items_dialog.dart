import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_theme.dart';
import '../../../modules/purchases/vendors/providers/vendor_provider.dart';
import '../inputs/custom_text_field.dart';
import '../inputs/dropdown_input.dart';

class PurchaseRequestItemSelection {
  final String productId;
  final String productName;
  final double quantity;
  final double rate;
  final String requestNumber;
  final String sourceKey;
  final String? itemCode;
  final String? hsnCode;
  final String? description;
  final String? preferredVendorId;

  const PurchaseRequestItemSelection({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.rate,
    required this.requestNumber,
    required this.sourceKey,
    this.itemCode,
    this.hsnCode,
    this.description,
    this.preferredVendorId,
  });
}

class PurchaseRequestsItemsDialog extends ConsumerStatefulWidget {
  final String? initialVendorId;
  final Set<String>? excludeSourceKeys;
  final ValueChanged<List<PurchaseRequestItemSelection>> onItemsSelected;

  const PurchaseRequestsItemsDialog({
    super.key,
    this.initialVendorId,
    this.excludeSourceKeys,
    required this.onItemsSelected,
  });

  @override
  ConsumerState<PurchaseRequestsItemsDialog> createState() =>
      _PurchaseRequestsItemsDialogState();
}

class _PrItemRow {
  final String sourceKey;
  final String prId;
  final String requestNumber;
  final String productId;
  final String productName;
  final String? itemCode;
  final String? hsnCode;
  final String? description;
  final double requiredQty;
  final double pendingQty;
  final double estimatedRate;
  final String? preferredVendorId;
  final String? preferredVendorName;

  _PrItemRow({
    required this.sourceKey,
    required this.prId,
    required this.requestNumber,
    required this.productId,
    required this.productName,
    this.itemCode,
    this.hsnCode,
    this.description,
    required this.requiredQty,
    required this.pendingQty,
    required this.estimatedRate,
    this.preferredVendorId,
    this.preferredVendorName,
  });
}

class _PurchaseRequestsItemsDialogState
    extends ConsumerState<PurchaseRequestsItemsDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  final CurrencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  bool _isLoading = true;
  List<_PrItemRow> _allRows = [];
  final Set<String> _selectedKeys = {};
  String? _selectedVendorId;

  @override
  void initState() {
    super.initState();
    _selectedVendorId = widget.initialVendorId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorProvider.notifier).loadVendors();
      _loadPrItems();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPrItems() async {
    setState(() => _isLoading = true);
    try {
      final vendors = ref.read(vendorProvider).vendors;
      final vendorMap = {for (final v in vendors) v.id: v.displayName};

      final response = await Supabase.instance.client
          .from('purchase_requests')
          .select('id, request_number, status, expected_date, '
              'purchase_request_items('
              'id, product_id, required_qty, pending_qty, estimated_rate, '
              'description, preferred_vendor_id, '
              'products(id, product_name, item_code, hsn_sac_code)'
              ')')
          .inFilter('status', [
            'APPROVED',
            'YET_TO_BE_ORDERED',
            'PARTIALLY_ORDERED'
          ])
          .order('request_number', ascending: false);

      final List<_PrItemRow> rows = [];
      for (final pr in (response as List)) {
        final prMap = pr as Map<String, dynamic>;
          final prId = prMap['id']?.toString() ?? '';
          final reqNum = prMap['request_number']?.toString() ?? '';
          final itemsList =
              prMap['purchase_request_items'] as List<dynamic>? ?? [];

          for (int i = 0; i < itemsList.length; i++) {
            final itemMap = itemsList[i] as Map<String, dynamic>;
            final productId = itemMap['product_id']?.toString() ?? '';
            if (productId.isEmpty) continue;

            final required =
                (itemMap['required_qty'] as num?)?.toDouble() ?? 0.0;
            final pending =
                (itemMap['pending_qty'] as num?)?.toDouble() ?? 0.0;
            final qty = pending > 0 ? pending : required;
            if (qty <= 0) continue;

            final rate = (itemMap['estimated_rate'] as num?)?.toDouble() ?? 0.0;
            final product = itemMap['products'] as Map<String, dynamic>?;
            final productName =
                product?['product_name']?.toString() ?? 'Unnamed Product';
            final itemCode = product?['item_code']?.toString();
            final hsnCode = product?['hsn_sac_code']?.toString();
            final description = itemMap['description']?.toString();
            final prefVendorId = itemMap['preferred_vendor_id']?.toString();
            final itemId = itemMap['id']?.toString() ?? i.toString();

            final sourceKey = '${prId}_${productId}_$itemId';
            if (widget.excludeSourceKeys != null &&
                widget.excludeSourceKeys!.contains(sourceKey)) {
              continue;
            }

            final vendorName =
                prefVendorId != null ? vendorMap[prefVendorId] : null;

            rows.add(_PrItemRow(
              sourceKey: sourceKey,
              prId: prId,
              requestNumber: reqNum,
              productId: productId,
              productName: productName,
              itemCode: itemCode,
              hsnCode: hsnCode,
              description: description,
              requiredQty: required,
              pendingQty: qty,
              estimatedRate: rate,
              preferredVendorId: prefVendorId,
              preferredVendorName: vendorName,
            ));
          }
        }

      if (mounted) {
        setState(() {
          _allRows = rows;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      AppLogger.error('Error fetching purchase request items in dialog',
          error: e, stackTrace: st, module: 'PurchaseRequestsItemsDialog');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<_PrItemRow> get _filteredRows {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _allRows.where((row) {
      if (_selectedVendorId != null &&
          _selectedVendorId!.isNotEmpty &&
          row.preferredVendorId != _selectedVendorId) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesReq = row.requestNumber.toLowerCase().contains(query);
        final matchesProduct = row.productName.toLowerCase().contains(query);
        final matchesCode =
            (row.itemCode ?? '').toLowerCase().contains(query);
        if (!matchesReq && !matchesProduct && !matchesCode) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _toggleSelectAll(bool? value, List<_PrItemRow> filtered) {
    setState(() {
      if (value == true) {
        for (final row in filtered) {
          _selectedKeys.add(row.sourceKey);
        }
      } else {
        for (final row in filtered) {
          _selectedKeys.remove(row.sourceKey);
        }
      }
    });
  }

  void _onConfirmSelection() {
    final selectedRows =
        _allRows.where((r) => _selectedKeys.contains(r.sourceKey)).toList();

    final result = selectedRows
        .map((r) => PurchaseRequestItemSelection(
              productId: r.productId,
              productName: r.productName,
              quantity: r.pendingQty,
              rate: r.estimatedRate,
              requestNumber: r.requestNumber,
              sourceKey: r.sourceKey,
              itemCode: r.itemCode,
              hsnCode: r.hsnCode,
              description: r.description,
              preferredVendorId: r.preferredVendorId,
            ))
        .toList();

    widget.onItemsSelected(result);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(vendorProvider).vendors;
    final filtered = _filteredRows;
    final allSelected = filtered.isNotEmpty &&
        filtered.every((r) => _selectedKeys.contains(r.sourceKey));

    final selectedRows =
        _allRows.where((r) => _selectedKeys.contains(r.sourceKey)).toList();

    double totalSelectedAmount = 0.0;
    for (final row in selectedRows) {
      totalSelectedAmount += (row.pendingQty * row.estimatedRate);
    }

    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 920,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Title + Red Close Button
            Row(
              children: [
                const Text(
                  'Add Items From Purchase Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20, color: Colors.red),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  hoverColor: const Color(0xFFFEE2E2),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Filter Bar: Vendor Dropdown (Left) & Total Count (Right)
            Row(
              children: [
                const Text(
                  'Vendor',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 220,
                  height: 34,
                  child: FormDropdown<String?>(
                    value: _selectedVendorId,
                    hint: 'All vendors',
                    items: [null, ...vendors.map((v) => v.id)],
                    displayStringForValue: (id) {
                      if (id == null || id.isEmpty) return 'All vendors';
                      final match = vendors.where((v) => v.id == id).firstOrNull;
                      return match?.displayName ?? id;
                    },
                    onChanged: (val) {
                      setState(() => _selectedVendorId = val);
                    },
                  ),
                ),
                const Spacer(),
                Text(
                  '${_allRows.length} item(s) yet to be ordered',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Two-Pane Split Layout
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    // LEFT PANE: Search + Select All + Items Card List (~54%)
                    Expanded(
                      flex: 54,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search Input
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: CustomTextField(
                              controller: _searchCtrl,
                              hintText:
                                  'Type to search purchase requests items',
                              onChanged: (_) => setState(() {}),
                            ),
                          ),

                          // Select All Bar
                          Container(
                            color: const Color(0xFFF9FAFB),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: allSelected,
                                    activeColor: AppTheme.primaryBlue,
                                    onChanged: (v) =>
                                        _toggleSelectAll(v, filtered),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Select all ${filtered.length}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),

                          // Items List
                          Expanded(
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primaryBlue,
                                    ),
                                  )
                                : filtered.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'No items found.',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) =>
                                            const Divider(
                                          height: 1,
                                          color: Color(0xFFF3F4F6),
                                        ),
                                        itemBuilder: (context, index) {
                                          final row = filtered[index];
                                          final isSelected = _selectedKeys
                                              .contains(row.sourceKey);
                                          final qtyStr = row.pendingQty
                                                      .truncateToDouble() ==
                                                  row.pendingQty
                                              ? row.pendingQty
                                                  .toInt()
                                                  .toString()
                                              : row.pendingQty.toStringAsFixed(2);

                                          return InkWell(
                                            onTap: () {
                                              setState(() {
                                                if (isSelected) {
                                                  _selectedKeys
                                                      .remove(row.sourceKey);
                                                } else {
                                                  _selectedKeys
                                                      .add(row.sourceKey);
                                                }
                                              });
                                            },
                                            hoverColor: const Color(0xFFF9FAFB),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 10,
                                              ),
                                              color: isSelected
                                                  ? const Color(0xFFEFF6FF)
                                                  : Colors.transparent,
                                              child: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: Checkbox(
                                                      value: isSelected,
                                                      activeColor:
                                                          AppTheme.primaryBlue,
                                                      onChanged: (v) {
                                                        setState(() {
                                                          if (v == true) {
                                                            _selectedKeys.add(
                                                                row.sourceKey);
                                                          } else {
                                                            _selectedKeys
                                                                .remove(
                                                                    row.sourceKey);
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          row.productName,
                                                          style: const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Color(0xFF1F2937),
                                                            fontFamily: 'Inter',
                                                          ),
                                                        ),
                                                        const SizedBox(height: 2),
                                                        Text(
                                                          '${row.requestNumber} · ${row.preferredVendorName ?? "No vendor"}',
                                                          style: const TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                Color(0xFF6B7280),
                                                            fontFamily: 'Inter',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        'Qty $qtyStr',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFF1F2937),
                                                          fontFamily: 'Inter',
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        CurrencyFormat.format(
                                                            row.estimatedRate),
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          color:
                                                              Color(0xFF6B7280),
                                                          fontFamily: 'Inter',
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
                        ],
                      ),
                    ),

                    const VerticalDivider(width: 1, color: Color(0xFFE5E7EB)),

                    // RIGHT PANE: Selected Items Panel (~46%)
                    Expanded(
                      flex: 46,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pane Header
                          Container(
                            color: const Color(0xFFF9FAFB),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  'Selected Items',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5E7EB),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${selectedRows.length}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),

                          // Pane Content (Empty or List)
                          Expanded(
                            child: selectedRows.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(24),
                                      child: Text(
                                        'Click the item names from the left pane to select them',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF9CA3AF),
                                          fontFamily: 'Inter',
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(12),
                                    itemCount: selectedRows.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final row = selectedRows[index];
                                      final qtyStr = row.pendingQty
                                                  .truncateToDouble() ==
                                              row.pendingQty
                                          ? row.pendingQty.toInt().toString()
                                          : row.pendingQty.toStringAsFixed(2);
                                      final lineTotal =
                                          row.pendingQty * row.estimatedRate;

                                      return Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    row.productName,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF1F2937),
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${row.requestNumber}  •  Qty $qtyStr @ ${CurrencyFormat.format(row.estimatedRate)}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Color(0xFF6B7280),
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              CurrencyFormat.format(lineTotal),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1F2937),
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  _selectedKeys
                                                      .remove(row.sourceKey);
                                                });
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(4),
                                                child: Icon(
                                                  LucideIcons.x,
                                                  size: 14,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          // Right Pane Bottom Summary
                          if (selectedRows.isNotEmpty) ...[
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              color: const Color(0xFFF9FAFB),
                              child: Row(
                                children: [
                                  const Text(
                                    'Total Selected Amount:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6B7280),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    CurrencyFormat.format(
                                        totalSelectedAmount),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dialog Footer Actions
            Row(
              children: [
                ElevatedButton(
                  onPressed: selectedRows.isNotEmpty
                      ? _onConfirmSelection
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Add items',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF374151),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: 'Inter',
                    ),
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
