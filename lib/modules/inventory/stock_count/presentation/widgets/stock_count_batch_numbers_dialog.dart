import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StockCountBatchNumbersDialog extends StatefulWidget {
  final String itemName;
  final String locationName;
  final String? productId;
  final String? warehouseId;
  final List<Map<String, dynamic>> countedBatches;

  const StockCountBatchNumbersDialog({
    super.key,
    required this.itemName,
    required this.locationName,
    required this.countedBatches,
    this.productId,
    this.warehouseId,
  });

  @override
  State<StockCountBatchNumbersDialog> createState() =>
      _StockCountBatchNumbersDialogState();
}

enum _BatchDialogFilter { all, missing, newlyAdded }

class _BatchDialogRow {
  final String batchReference;
  final double systemQty;
  final double countedQty;
  final bool isMissing;
  final bool isNewlyAdded;

  const _BatchDialogRow({
    required this.batchReference,
    required this.systemQty,
    required this.countedQty,
    this.isMissing = false,
    this.isNewlyAdded = false,
  });
}

class _StockCountBatchNumbersDialogState
    extends State<StockCountBatchNumbersDialog> {
  static const String _triangleAlertSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#F7525A" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3"/>
  <path d="M12 9v4"/>
  <path d="M12 17h.01"/>
</svg>
''';

  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  bool _isLoading = true;
  String _searchQuery = '';
  _BatchDialogFilter _activeFilter = _BatchDialogFilter.all;
  List<_BatchDialogRow> _rows = [];

  Widget _warningTriangleIcon(double size) => SvgPicture.string(
        _triangleAlertSvg,
        width: size,
        height: size,
      );

  int get _missingCount => _rows.where((row) => row.isMissing).length;
  int get _newlyAddedCount => _rows.where((row) => row.isNewlyAdded).length;
  bool get _hasBatchMembershipMismatch =>
      _missingCount > 0 || _newlyAddedCount > 0;
  double get _countedTotal =>
      _rows.fold(0.0, (sum, row) => sum + row.countedQty);

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRows() async {
    final countedMap = <String, double>{};
    final countedLabelMap = <String, String>{};

    for (final batch in widget.countedBatches) {
      final rawName = (batch['batchNo'] ?? '').toString().trim();
      if (rawName.isEmpty) continue;
      final key = rawName.toLowerCase();
      final qty = (batch['qty'] as num?)?.toDouble() ?? 0.0;
      countedMap[key] = (countedMap[key] ?? 0.0) + qty;
      countedLabelMap[key] = rawName;
    }

    final dbRows = <Map<String, dynamic>>[];
    if (widget.productId != null && widget.productId!.trim().isNotEmpty) {
      try {
        final supabase = Supabase.instance.client;
        var query = supabase
            .from('v_batch_wise_stock')
            .select('batch_id, batch_no, available_stock, stock_on_hand')
            .eq('product_id', widget.productId!);

        final normalizedWarehouseId = widget.warehouseId?.trim();
        if (normalizedWarehouseId != null && normalizedWarehouseId.isNotEmpty) {
          query = query.eq('warehouse_id', normalizedWarehouseId);
        }

        final response = await query;

        for (final row in response as List) {
          final map = Map<String, dynamic>.from(row as Map);
          final batchNo = (map['batch_no'] ?? '').toString().trim();
          final systemQty = double.tryParse(map['stock_on_hand']?.toString() ?? '') ?? 
                            double.tryParse(map['available_stock']?.toString() ?? '') ?? 
                            0.0;
          dbRows.add({
            'batchNo': batchNo,
            'systemQty': systemQty,
          });
        }
      } catch (_) {}
    }

    final mergedRows = <_BatchDialogRow>[];
    for (final row in dbRows) {
      final batchNo = (row['batchNo'] ?? '').toString().trim();
      if (batchNo.isEmpty) continue;
      final key = batchNo.toLowerCase();
      final systemQty = (row['systemQty'] as num?)?.toDouble() ?? 0.0;
      final countedQty = countedMap.remove(key) ?? 0.0;

      mergedRows.add(
        _BatchDialogRow(
          batchReference: batchNo,
          systemQty: systemQty,
          countedQty: countedQty,
          isMissing: countedQty == 0 && systemQty > 0,
        ),
      );
    }

    countedMap.forEach((key, qty) {
      if (qty <= 0) return;
      mergedRows.add(
        _BatchDialogRow(
          batchReference: countedLabelMap[key] ?? key,
          systemQty: 0,
          countedQty: qty,
          isNewlyAdded: true,
        ),
      );
    });

    if (mounted) {
      setState(() {
        _rows = mergedRows;
        _isLoading = false;
      });
    }
  }

  String _formatQty(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  List<_BatchDialogRow> _filteredRows() {
    Iterable<_BatchDialogRow> rows = _rows;
    switch (_activeFilter) {
      case _BatchDialogFilter.missing:
        rows = rows.where((row) => row.isMissing);
        break;
      case _BatchDialogFilter.newlyAdded:
        rows = rows.where((row) => row.isNewlyAdded);
        break;
      case _BatchDialogFilter.all:
        break;
    }

    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      rows = rows.where(
        (row) => row.batchReference.toLowerCase().contains(query),
      );
    }
    return rows.toList();
  }

  Widget _buildTab({
    required _BatchDialogFilter filter,
    required String label,
    IconData? icon,
    Color? iconColor,
    Widget? leading,
  }) {
    final isActive = _activeFilter == filter;
    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        margin: const EdgeInsets.only(right: 28),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF4A83F6) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: 4),
            ] else if (icon != null) ...[
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF1F2937)
                    : const Color(0xFF52617A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      width: 245,
      height: 40,
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9CA3AF),
          ),
          prefixIcon: const Icon(
            LucideIcons.search,
            size: 18,
            color: Color(0xFF98A2B3),
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                  child: const Icon(
                    LucideIcons.x,
                    size: 16,
                    color: Color(0xFF98A2B3),
                  ),
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFBFD1FF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFBFD1FF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF4A83F6)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialogHeight = _hasBatchMembershipMismatch ? 676.78 : 410.53;
    final displayedRows = _hasBatchMembershipMismatch
        ? _filteredRows()
        : _rows
            .where((row) {
              final query = _searchQuery.trim().toLowerCase();
              if (query.isEmpty) return true;
              return row.batchReference.toLowerCase().contains(query);
            })
            .toList();
    final rowAreaHeight = _hasBatchMembershipMismatch
        ? math.min(220.0, math.max(56.0, displayedRows.length * 38.0))
        : math.min(150.0, math.max(56.0, displayedRows.length * 38.0));

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, left: 0, right: 0, bottom: 0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: SizedBox(
        width: 600,
        height: dialogHeight,
        child: ConstrainedBox(
          constraints: BoxConstraints.tightFor(
            width: 600,
            height: dialogHeight,
          ),
          child: _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 120),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 18, 18),
                      child: Row(
                        children: [
                          const Text(
                            'Batch Numbers',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: const Icon(
                              LucideIcons.x,
                              size: 20,
                              color: Color(0xFFFF3B30),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFE9EDF5)),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(38, 18, 40, 16),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.building2,
                            size: 14,
                            color: Color(0xFF8A94A6),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Location :',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.locationName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 38),
                      child: Divider(height: 1, color: Color(0xFFE9EDF5)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(38, 18, 38, 18),
                      child: Text(
                        widget.itemName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_hasBatchMembershipMismatch)
                              Container(
                                color: const Color(0xFFF9FAFB),
                                padding:
                                    const EdgeInsets.fromLTRB(22, 18, 22, 18),
                                child: Container(
                                  padding:
                                      const EdgeInsets.fromLTRB(18, 16, 18, 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF2E2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 2,
                                            ),
                                            child: _warningTriangleIcon(17),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              '${_missingCount + _newlyAddedCount} batches are not matching with the items that you\'ve added while stock counting.',
                                              style: const TextStyle(
                                                fontSize: 15,
                                                height: 1.45,
                                                color: Color(0xFF374151),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      if (_missingCount > 0)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 28),
                                          child: Row(
                                            children: [
                                              _warningTriangleIcon(14),
                                              const SizedBox(width: 8),
                                              Text(
                                                '$_missingCount Batches are missing',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xFF374151),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (_newlyAddedCount > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 28,
                                            top: 8,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                LucideIcons.info,
                                                size: 14,
                                                color: Color(0xFFFF9F2E),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '$_newlyAddedCount Batches are newly added',
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  color: Color(0xFF374151),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                22,
                                _hasBatchMembershipMismatch ? 28 : 18,
                                22,
                                10,
                              ),
                              child: Row(
                                children: [
                                  const Text(
                                    'Batch Numbers',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  if (!_showSearch)
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          _showSearch = true;
                                        });
                                      },
                                      child: const Icon(
                                        LucideIcons.search,
                                        size: 18,
                                        color: Color(0xFF4A83F6),
                                      ),
                                    ),
                                  if (_showSearch) ...[
                                    const SizedBox(width: 10),
                                    _buildSearchField(),
                                  ],
                                  const Spacer(),
                                  Text(
                                    'Counted : ${_formatQty(_countedTotal)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF374151),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_hasBatchMembershipMismatch)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(28, 0, 22, 0),
                                child: Row(
                                  children: [
                                    _buildTab(
                                      filter: _BatchDialogFilter.all,
                                      label: 'All (${_rows.length})',
                                    ),
                                    _buildTab(
                                      filter: _BatchDialogFilter.missing,
                                      label: 'Missing ($_missingCount)',
                                      leading: _warningTriangleIcon(15),
                                    ),
                                    _buildTab(
                                      filter: _BatchDialogFilter.newlyAdded,
                                      label: 'Newly Added ($_newlyAddedCount)',
                                      icon: LucideIcons.info,
                                      iconColor: const Color(0xFFFF9F2E),
                                    ),
                                  ],
                                ),
                              ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                22,
                                _hasBatchMembershipMismatch ? 0 : 6,
                                22,
                                0,
                              ),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE9EDF5)),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      color: const Color(0xFFF8FAFD),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      child: const Row(
                                        children: [
                                          Expanded(
                                            flex: 5,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                              ),
                                              child: Text(
                                                'BATCH REFERENCE#',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF7583A0),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                              ),
                                              child: Text(
                                                'SYSTEM QUANTITY',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF7583A0),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 10,
                                              ),
                                              child: Text(
                                                'COUNTED QTY',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xFF7583A0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(maxHeight: rowAreaHeight),
                                      child: displayedRows.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 28,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'No batches found',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : SingleChildScrollView(
                                              child: Column(
                                                children: displayedRows.map((row) {
                                          final rowColor = row.isMissing
                                              ? const Color(0xFFFFF1F1)
                                              : row.isNewlyAdded
                                              ? const Color(0xFFFFF4E7)
                                              : Colors.white;
                                          final leadingIcon = row.isMissing
                                              ? _warningTriangleIcon(14)
                                              : row.isNewlyAdded
                                              ? const Icon(
                                                  LucideIcons.info,
                                                  size: 14,
                                                  color: Color(0xFFFF9F2E),
                                                )
                                              : null;

                                          return Container(
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: rowColor,
                                              border: Border(
                                                top: BorderSide(
                                                  color: rowColor == Colors.white
                                                      ? const Color(0xFFE9EDF5)
                                                      : Colors.transparent,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  flex: 5,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        if (leadingIcon != null)
                                                          ...[
                                                            leadingIcon,
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                          ],
                                                        Flexible(
                                                          child: Text(
                                                            row.batchReference,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 15,
                                                              color: Color(
                                                                0xFF374151,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                    child: Text(
                                                      _formatQty(row.systemQty),
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        color: Color(
                                                          0xFF374151,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  flex: 3,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          _formatQty(
                                                            row.countedQty,
                                                          ),
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            color: !_hasBatchMembershipMismatch &&
                                                                    row.countedQty !=
                                                                        row.systemQty
                                                                ? const Color(
                                                                    0xFFEF4444,
                                                                  )
                                                                : const Color(
                                                                    0xFF374151,
                                                                  ),
                                                          ),
                                                        ),
                                                        if (!_hasBatchMembershipMismatch &&
                                                            row.countedQty !=
                                                                row.systemQty) ...[
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Icon(
                                                            row.countedQty >
                                                                    row.systemQty
                                                                ? LucideIcons
                                                                      .arrowUp
                                                                : LucideIcons
                                                                      .arrowDown,
                                                            size: 15,
                                                            color: const Color(
                                                              0xFFEF4444,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!_hasBatchMembershipMismatch)
                              const SizedBox(height: 10)
                            else
                              const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF111827),
                            backgroundColor: const Color(0xFFF7F7F7),
                            side: const BorderSide(color: Color(0xFFD8DDE6)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
