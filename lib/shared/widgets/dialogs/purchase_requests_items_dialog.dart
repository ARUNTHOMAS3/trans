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
import '../z_button.dart';

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
      for (final pr in (response as List<dynamic>)) {
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

    double totalSelectedAmount = 0.0;
    int selectedCount = 0;
    for (final row in _allRows) {
      if (_selectedKeys.contains(row.sourceKey)) {
        selectedCount++;
        totalSelectedAmount += (row.pendingQty * row.estimatedRate);
      }
    }

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 960,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  LucideIcons.fileText,
                  size: 20,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Insert Items From Purchase Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Inter',
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                  hoverColor: const Color(0xFFF3F4F6),
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Controls Bar: Search + Vendor Filter
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _searchCtrl,
                    hintText: 'Search by PR #, Product Name or Item Code...',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 240,
                  child: FormDropdown<String?>(
                    value: _selectedVendorId,
                    hint: 'All Preferred Vendors',
                    items: [null, ...vendors.map((v) => v.id)],
                    displayStringForValue: (id) {
                      if (id == null || id.isEmpty) return 'All Preferred Vendors';
                      final match = vendors.where((v) => v.id == id).firstOrNull;
                      return match?.displayName ?? id;
                    },
                    onChanged: (val) {
                      setState(() => _selectedVendorId = val);
                    },
                  ),
                ),
                if (_selectedVendorId != null || _searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(LucideIcons.filterX, size: 16),
                    tooltip: 'Clear Filters',
                    onPressed: () {
                      setState(() {
                        _selectedVendorId = null;
                        _searchCtrl.clear();
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Main Table Area
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryBlue,
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.inbox,
                                  size: 36,
                                  color: Color(0xFF9CA3AF),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _allRows.isEmpty
                                      ? 'No approved purchase request items available to order.'
                                      : 'No items match the selected filter.',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              // Table Header
                              Container(
                                color: const Color(0xFFF9FAFB),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 32,
                                      child: Checkbox(
                                        value: allSelected,
                                        activeColor: AppTheme.primaryBlue,
                                        onChanged: (v) =>
                                            _toggleSelectAll(v, filtered),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const SizedBox(
                                      width: 110,
                                      child: Text(
                                        'PR NUMBER',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      flex: 3,
                                      child: Text(
                                        'PRODUCT DETAILS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ),
                                    const Expanded(
                                      flex: 2,
                                      child: Text(
                                        'PREFERRED VENDOR',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 90,
                                      child: Text(
                                        'QTY TO ORDER',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 100,
                                      child: Text(
                                        'EST. RATE',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 110,
                                      child: Text(
                                        'EST. AMOUNT',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4B5563),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(
                                height: 1,
                                color: Color(0xFFE5E7EB),
                              ),

                              // Table ListView Rows
                              Expanded(
                                child: ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(
                                    height: 1,
                                    color: Color(0xFFF3F4F6),
                                  ),
                                  itemBuilder: (context, index) {
                                    final row = filtered[index];
                                    final isSelected = _selectedKeys
                                        .contains(row.sourceKey);
                                    final lineAmount =
                                        row.pendingQty * row.estimatedRate;

                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedKeys.remove(row.sourceKey);
                                          } else {
                                            _selectedKeys.add(row.sourceKey);
                                          }
                                        });
                                      },
                                      hoverColor: const Color(0xFFF9FAFB),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 10,
                                        ),
                                        color: isSelected
                                            ? const Color(0xFFEFF6FF)
                                            : Colors.transparent,
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              width: 32,
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
                                                      _selectedKeys.remove(
                                                          row.sourceKey);
                                                    }
                                                  });
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 110,
                                              child: Text(
                                                row.requestNumber,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.primaryBlue,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    row.productName,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF1F2937),
                                                    ),
                                                  ),
                                                  if (row.itemCode != null &&
                                                      row.itemCode!.isNotEmpty)
                                                    Text(
                                                      'SKU: ${row.itemCode}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF6B7280),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                row.preferredVendorName ?? '-',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF374151),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 90,
                                              child: Text(
                                                row.pendingQty.toStringAsFixed(
                                                    row.pendingQty
                                                                .truncateToDouble() ==
                                                            row.pendingQty
                                                        ? 0
                                                        : 2),
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF1F2937),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 100,
                                              child: Text(
                                                CurrencyFormat.format(
                                                    row.estimatedRate),
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF374151),
                                                ),
                                              ),
                                            ),
                                            SizedBox(
                                              width: 110,
                                              child: Text(
                                                CurrencyFormat.format(
                                                    lineAmount),
                                                textAlign: TextAlign.right,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1F2937),
                                                ),
                                              ),
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
            const SizedBox(height: 16),

            // Footer Summary & Action Buttons
            Row(
              children: [
                Text(
                  selectedCount > 0
                      ? '$selectedCount item(s) selected  •  Total: ${CurrencyFormat.format(totalSelectedAmount)}'
                      : 'Select items to insert into Purchase Order',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selectedCount > 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: selectedCount > 0
                        ? const Color(0xFF1F2937)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const Spacer(),
                ZButton.secondary(
                  onPressed: () => Navigator.of(context).pop(),
                  label: 'Cancel',
                ),
                const SizedBox(width: 12),
                ZButton.primary(
                  onPressed:
                      selectedCount > 0 ? _onConfirmSelection : null,
                  label: 'Insert Items ($selectedCount)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
