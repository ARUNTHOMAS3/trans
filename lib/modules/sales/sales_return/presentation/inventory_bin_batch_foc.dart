import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/providers/lookup_providers.dart';

class PicklistBatchRowController {
  final TextEditingController binLocationCtrl = TextEditingController();
  final TextEditingController batchRefCtrl = TextEditingController();
  final TextEditingController batchNoCtrl = TextEditingController();
  final TextEditingController unitPackCtrl = TextEditingController();
  final TextEditingController mrpCtrl = TextEditingController();
  final TextEditingController ptrCtrl = TextEditingController();
  final TextEditingController qtyOutCtrl = TextEditingController();
  final TextEditingController focCtrl = TextEditingController();
  final TextEditingController expDateCtrl = TextEditingController();
  final TextEditingController mfgDateCtrl = TextEditingController();
  final TextEditingController mfgBatchCtrl = TextEditingController();
  final GlobalKey expKey = GlobalKey();
  final GlobalKey mfgKey = GlobalKey();
  DateTime? expDate;
  DateTime? mfgDate;

  void dispose() {
    binLocationCtrl.dispose();
    batchRefCtrl.dispose();
    batchNoCtrl.dispose();
    unitPackCtrl.dispose();
    mrpCtrl.dispose();
    ptrCtrl.dispose();
    qtyOutCtrl.dispose();
    focCtrl.dispose();
    expDateCtrl.dispose();
    mfgDateCtrl.dispose();
    mfgBatchCtrl.dispose();
  }
}

class PicklistBatchDialogResult {
  final bool overwriteLineItem;
  final int batchCount;
  final double appliedQuantity;
  final double totalIncludingFoc;
  final List<Map<String, String>>? batchDataList;

  const PicklistBatchDialogResult({
    required this.overwriteLineItem,
    required this.batchCount,
    required this.appliedQuantity,
    required this.totalIncludingFoc,
    this.batchDataList,
  });
}

class PicklistSelectBatchesDialog extends ConsumerStatefulWidget {
  final String itemName;
  final String productId;
  final String warehouseName;
  final String warehouseId;
  final String? branchId;
  final double totalQuantity;
  final List<Map<String, String>>? savedBatchData;
  final bool allowManualBatchEntry;

  const PicklistSelectBatchesDialog({
    super.key,
    required this.itemName,
    required this.productId,
    required this.warehouseName,
    required this.warehouseId,
    this.branchId,
    required this.totalQuantity,
    this.savedBatchData,
    this.allowManualBatchEntry = false,
  });

  @override
  ConsumerState<PicklistSelectBatchesDialog> createState() =>
      _PicklistSelectBatchesDialogState();
}

class _PicklistSelectBatchesDialogState
    extends ConsumerState<PicklistSelectBatchesDialog> {
  static const double _batchDropdownHeight = 38;
  static const double _batchTextFieldHeight = 38;
  final List<PicklistBatchRowController> _rows = [];
  final Set<int> _hoveredFocRows = <int>{};
  final Set<int> _hoveredBatchRows = <int>{};
  bool _overwriteLineItem = false;
  bool _showMfgDetails = false;
  bool _showFocColumn = false;
  static const String _quantityMismatchMessage =
      "There's a mismatch between the quantity entered in the line item and the total quantity across all batches. Click the checkbox to overwrite the quantity in the line item.";

  @override
  void initState() {
    super.initState();
    if (widget.savedBatchData != null && widget.savedBatchData!.isNotEmpty) {
      for (var batchData in widget.savedBatchData!) {
        final row = PicklistBatchRowController();
        row.binLocationCtrl.text = batchData['binLocation'] ?? '';
        row.batchRefCtrl.text = batchData['batchRef'] ?? '';
        row.batchNoCtrl.text = batchData['batchNo'] ?? '';
        row.unitPackCtrl.text = batchData['unitPack'] ?? '';
        row.mrpCtrl.text = batchData['mrp'] ?? '';
        row.ptrCtrl.text = batchData['prate'] ?? '';
        row.expDateCtrl.text = batchData['expDate'] ?? '';
        if (row.expDateCtrl.text.isNotEmpty) {
          try {
            row.expDate = DateFormat('dd-MM-yyyy').parse(row.expDateCtrl.text);
          } catch (_) {}
        }
        row.mfgDateCtrl.text = batchData['mfgDate'] ?? '';
        if (row.mfgDateCtrl.text.isNotEmpty) {
          try {
            row.mfgDate = DateFormat('dd-MM-yyyy').parse(row.mfgDateCtrl.text);
          } catch (_) {}
        }
        row.mfgBatchCtrl.text = batchData['mfgBatch'] ?? '';
        row.qtyOutCtrl.text =
            batchData['qtyOut'] ?? widget.totalQuantity.toInt().toString();
        row.focCtrl.text = batchData['foc'] ?? '';

        if (row.focCtrl.text.isNotEmpty &&
            (double.tryParse(row.focCtrl.text) ?? 0) > 0) {
          _showFocColumn = true;
        }
        if (row.mfgDateCtrl.text.isNotEmpty ||
            row.mfgBatchCtrl.text.isNotEmpty) {
          _showMfgDetails = true;
        }

        _rows.add(row);
      }
    } else {
      final firstRow = PicklistBatchRowController();
      firstRow.qtyOutCtrl.text = widget.totalQuantity.toInt().toString();
      _rows.add(firstRow);
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  double get _totalQuantityOnlyOut => _rows.fold<double>(
    0,
    (sum, r) => sum + (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0),
  );

  double get _totalAppliedIncludingFoc => _rows.fold<double>(
    0,
    (sum, r) =>
        sum +
        (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0) +
        (double.tryParse(r.focCtrl.text.trim()) ?? 0),
  );

  double get _quantityToBeAdded =>
      (widget.totalQuantity - _totalQuantityOnlyOut).clamp(
        0,
        widget.totalQuantity,
      );

  bool get _hasQuantityMismatch =>
      (_totalQuantityOnlyOut - widget.totalQuantity).abs() > 0.0001;

  int get _batchCount {
    final refs = _rows
        .where((r) => (double.tryParse(r.qtyOutCtrl.text.trim()) ?? 0) > 0)
        .map((r) => r.batchRefCtrl.text.trim())
        .where((ref) => ref.isNotEmpty)
        .toSet();
    return refs.length;
  }

  void _addRow() {
    setState(() {
      _rows.add(PicklistBatchRowController());
    });
  }

  void _removeRow(int index) {
    setState(() {
      if (_rows.length == 1) {
        _rows[index].batchRefCtrl.clear();
        _rows[index].qtyOutCtrl.clear();
      } else {
        _rows[index].dispose();
        _rows.removeAt(index);
      }
    });
  }

  Widget _headerCell(
    String text,
    int flex, {
    TextAlign alignment = TextAlign.center,
  }) {
    final isRequired = text.contains('*');
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          textAlign: alignment,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isRequired ? AppTheme.errorRed : AppTheme.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required int flex,
    required String hint,
    bool isNumber = false,
    bool readOnly = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
          inputFormatters: isNumber
              ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
              : [],
          textAlign: isNumber ? TextAlign.right : TextAlign.left,
          textAlignVertical: TextAlignVertical.center,
          strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
          style: TextStyle(
            fontSize: 13,
            color: readOnly ? AppTheme.textSecondary : AppTheme.textPrimary,
            fontFamily: 'Inter',
          ),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: false,
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            filled: true,
            fillColor: readOnly ? AppTheme.bgLight : AppTheme.backgroundColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            constraints: const BoxConstraints(
              minHeight: _batchTextFieldHeight,
              maxHeight: _batchTextFieldHeight,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: readOnly ? AppTheme.bgDisabled : AppTheme.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: readOnly ? AppTheme.bgDisabled : AppTheme.infoBlue,
                width: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required TextEditingController controller,
    required GlobalKey anchorKey,
    required int flex,
    required DateTime? currentDate,
    required ValueChanged<DateTime?> onDateChanged,
    bool readOnly = false,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: _batchTextFieldHeight,
          child: TextField(
            key: anchorKey,
            controller: controller,
            readOnly: true,
            textAlignVertical: TextAlignVertical.center,
            strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
            style: TextStyle(
              fontSize: 13,
              color: readOnly ? AppTheme.textSecondary : AppTheme.textPrimary,
              fontFamily: 'Inter',
            ),
            decoration: InputDecoration(
              isDense: false,
              hintText: '',
              hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              filled: true,
              fillColor: readOnly ? AppTheme.bgLight : AppTheme.backgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              constraints: const BoxConstraints(
                minHeight: _batchTextFieldHeight,
                maxHeight: _batchTextFieldHeight,
              ),
              suffixIcon: Icon(
                LucideIcons.calendar,
                size: 14,
                color: readOnly ? AppTheme.textMuted : AppTheme.textSecondary,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 32,
                maxWidth: 32,
                minHeight: _batchTextFieldHeight,
                maxHeight: _batchTextFieldHeight,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: readOnly ? AppTheme.bgDisabled : AppTheme.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: readOnly ? AppTheme.bgDisabled : AppTheme.infoBlue,
                  width: 1.4,
                ),
              ),
            ),
            onTap: () async {
              if (readOnly) return;
              final picked = await ZerpaiDatePicker.show(
                context,
                initialDate: currentDate ?? DateTime.now(),
                targetKey: anchorKey,
              );
              if (picked != null) {
                onDateChanged(picked);
                controller.text = DateFormat('dd-MM-yyyy').format(picked);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFocInput(PicklistBatchRowController row, int index) {
    final isHovered = _hoveredFocRows.contains(index);
    return Expanded(
      flex: 15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredFocRows.add(index)),
          onExit: (_) => setState(() => _hoveredFocRows.remove(index)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: _batchTextFieldHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isHovered ? AppTheme.infoBlue : AppTheme.borderLight,
                width: isHovered ? 1.4 : 1,
              ),
            ),
            child: TextField(
              controller: row.focCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              textAlign: TextAlign.right,
              textAlignVertical: TextAlignVertical.center,
              strutStyle: const StrutStyle(forceStrutHeight: true, height: 1.2),
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
              decoration: InputDecoration(
                isDense: false,
                hintText: '0',
                hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                filled: false,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                constraints: const BoxConstraints(
                  minHeight: _batchTextFieldHeight,
                  maxHeight: _batchTextFieldHeight,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 0),
      child: SizedBox(
        width: _showMfgDetails
            ? (_showFocColumn ? 1480 : 1320)
            : (_showFocColumn ? 1320 : 1160),
        height: MediaQuery.of(context).size.height - 16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Select Batches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.infoBlue),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Row(
                children: [
                  const Icon(LucideIcons.home, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Location : ${widget.warehouseName.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'BATCH DETAILS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Text(
                      'Item: ${widget.itemName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontFamily: 'Inter',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Total Quantity : ${widget.totalQuantity.toInt()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('|', style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(width: 8),
                  Text(
                    'Quantity to be added : ${_quantityToBeAdded.toInt()}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: _showMfgDetails,
                      onChanged: (val) =>
                          setState(() => _showMfgDetails = val ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Manufacture Details',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(width: 24),
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: _showFocColumn,
                      onChanged: (val) =>
                          setState(() => _showFocColumn = val ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'FOC',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: _overwriteLineItem,
                      onChanged: (val) => setState(() {
                        _overwriteLineItem = val ?? false;
                      }),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: AppTheme.successGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Overwrite the line item with ${_totalQuantityOnlyOut.toInt()} quantities',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 8),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: const BoxDecoration(
                color: AppTheme.bgLight,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  _headerCell('BIN LOCATION*', 15),
                  _headerCell('BATCH NO*', 15),
                  _headerCell('UNIT PACK*', 15),
                  _headerCell('MRP*', 15),
                  _headerCell('PURCHASE RATE*', 15),
                  _headerCell('EXPIRY DATE*', 15),
                  if (_showMfgDetails) ...[
                    _headerCell('MANUFACTURED DATE', 15),
                    _headerCell('MANUFACTURER BATCH', 15),
                  ],
                  _headerCell('QUANTITY OUT*', 15),
                  if (_showFocColumn) _headerCell('FOC', 15),
                  const SizedBox(width: 24),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.28,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 0,
                ),
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  final row = _rows[index];
                  final isRowHovered = _hoveredBatchRows.contains(index);
                  return Column(
                     children: [
                      MouseRegion(
                        onEnter: (_) =>
                            setState(() => _hoveredBatchRows.add(index)),
                        onExit: (_) =>
                            setState(() => _hoveredBatchRows.remove(index)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 15,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: SizedBox(
                                    height: _batchDropdownHeight,
                                    child: Consumer(
                                      builder: (context, ref, _) {
                                        final binsAsync = ref.watch(
                                          binsLookupProvider(widget.warehouseId),
                                        );
                                        final binCodes = (binsAsync.value ?? [])
                                            .map((b) => (b['bin_code'] ?? '').toString())
                                            .where((c) => c.isNotEmpty)
                                            .toList();
                                        return _BinHoverBox(
                                          isEnabled: row.binLocationCtrl.text.isNotEmpty,
                                          message: row.binLocationCtrl.text,
                                          child: FormDropdown<String>(
                                            height: _batchDropdownHeight,
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: AppTheme.borderLight),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            value: binCodes.contains(
                                                    row.binLocationCtrl.text.trim())
                                                ? row.binLocationCtrl.text.trim()
                                                : null,
                                            items: binCodes,
                                            hint: binsAsync.isLoading
                                                ? 'Loading bins...'
                                                : 'Select Bin',
                                            showSearch: true,
                                            maxVisibleItems: 8,
                                            menuMaxHeight: 400,
                                            menuWidth: 160,
                                            itemEstimatedHeight: 64,
                                            displayStringForValue: (v) => v,
                                            searchStringForValue: (v) => v,
                                            itemBuilder: (item, isSelected, isHovered) =>
                                                Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              color: isHovered
                                                  ? AppTheme.infoBlue
                                                  : (isSelected
                                                      ? const Color(0xFFF3F4F6)
                                                      : Colors.transparent),
                                              child: Text(
                                                item,
                                                softWrap: true,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isHovered
                                                      ? Colors.white
                                                      : const Color(0xFF1F2937),
                                                ),
                                              ),
                                            ),
                                            onChanged: (val) {
                                              setState(() {
                                                row.binLocationCtrl.text = val ?? '';
                                              });
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 15,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: SizedBox(
                                    height: _batchDropdownHeight,
                                    child: Consumer(
                                      builder: (context, ref, _) {
                                        final batchesAsync = ref.watch(
                                          batchLookupProvider(widget.productId),
                                        );
                                        final batches =
                                            batchesAsync.value ?? [];

                                        if (widget.allowManualBatchEntry &&
                                            batches.isEmpty) {
                                          return TextField(
                                            controller: row.batchRefCtrl,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textPrimary,
                                              fontFamily: 'Inter',
                                            ),
                                            textAlignVertical:
                                                TextAlignVertical.center,
                                            decoration: InputDecoration(
                                              hintText: 'Enter Batch#',
                                              hintStyle: const TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 13,
                                              ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 10,
                                              ),
                                              enabledBorder:
                                                  OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.borderLight,
                                                ),
                                              ),
                                              focusedBorder:
                                                  OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.infoBlue,
                                                  width: 1.4,
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              row.batchNoCtrl.text = value;
                                              setState(() {});
                                            },
                                          );
                                        }

                                        return FormDropdown<
                                          Map<String, dynamic>
                                        >(
                                          height: _batchDropdownHeight,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(color: AppTheme.borderLight),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          value:
                                              batches
                                                  .firstWhere(
                                                    (b) =>
                                                        b['batch_no']
                                                            ?.toString()
                                                            .trim() ==
                                                        row.batchRefCtrl.text
                                                            .trim(),
                                                    orElse: () =>
                                                        <String, dynamic>{},
                                                  )
                                                  .isEmpty
                                              ? null
                                              : batches.firstWhere(
                                                  (b) =>
                                                      b['batch_no']
                                                          ?.toString()
                                                          .trim() ==
                                                      row.batchRefCtrl.text
                                                          .trim(),
                                                ),
                                          items: batches,
                                          hint: 'Select Batch',
                                          showSearch: true,
                                          menuMaxHeight: 400,
                                          menuWidth: 138,
                                          itemEstimatedHeight: 100,
                                          itemBuilder:
                                              (item, isSelected, isHovered) {
                                                final batchNo =
                                                    item['batch_no']
                                                        ?.toString() ??
                                                    '-';
                                                final balance =
                                                    item['balance']
                                                        ?.toString() ??
                                                    '0';
                                                final expDate =
                                                    item['expiry_date']
                                                        ?.toString() ??
                                                    '-';
                                                final mrp =
                                                    item['mrp']?.toString() ??
                                                    '0.00';
                                                final ptr =
                                                    item['ptr']?.toString() ??
                                                    '0.00';

                                                final displayText =
                                                    '$batchNo | Bal: $balance | Exp: $expDate | MRP: $mrp | PTR: $ptr';

                                                return Container(
                                                  width: double.infinity,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 8,
                                                      ),
                                                  color: isHovered
                                                      ? AppTheme.infoBlue
                                                      : (isSelected
                                                            ? const Color(
                                                                0xFFF3F4F6,
                                                              )
                                                            : Colors
                                                                  .transparent),
                                                  child: Text(
                                                    displayText,
                                                    softWrap: true,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isHovered
                                                          ? Colors.white
                                                          : const Color(
                                                              0xFF1F2937,
                                                            ),
                                                      fontFamily: 'Inter',
                                                    ),
                                                  ),
                                                );
                                              },
                                          displayStringForValue: (v) =>
                                              v['batch_no']?.toString() ?? '',
                                          searchStringForValue: (v) =>
                                              v['batch_no']?.toString() ?? '',
                                          onChanged: (v) {
                                            setState(() {
                                              if (v != null) {
                                                final batchNo = v['batch_no']
                                                    ?.toString()
                                                    .trim();
                                                row.batchRefCtrl.text =
                                                    batchNo ?? '';
                                                row.batchNoCtrl.text =
                                                    batchNo ?? '';

                                                row.unitPackCtrl.text =
                                                    v['unit_pack']
                                                        ?.toString() ??
                                                    '';
                                                row.expDateCtrl.text =
                                                    v['expiry_date']
                                                        ?.toString() ??
                                                    '';

                                                final prices =
                                                    v['prices'] as List?;
                                                if (prices != null &&
                                                    prices.isNotEmpty) {
                                                  final p = prices[0];
                                                  row.mrpCtrl.text =
                                                      (p['mrp'] as num?)
                                                          ?.toDouble()
                                                          .toStringAsFixed(2) ??
                                                      '0.00';
                                                  row.ptrCtrl.text =
                                                      (p['ptr'] as num?)
                                                          ?.toDouble()
                                                          .toStringAsFixed(2) ??
                                                      '0.00';
                                                }
                                              }
                                            });
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              _buildInput(
                                controller: row.unitPackCtrl,
                                flex: 15,
                                hint: 'Pack',
                                isNumber: true,
                                readOnly: !widget.allowManualBatchEntry,
                              ),
                              _buildInput(
                                controller: row.mrpCtrl,
                                flex: 15,
                                hint: '0',
                                isNumber: true,
                                readOnly: !widget.allowManualBatchEntry,
                              ),
                              _buildInput(
                                controller: row.ptrCtrl,
                                flex: 15,
                                hint: '0',
                                isNumber: true,
                                readOnly: !widget.allowManualBatchEntry,
                              ),
                              _buildDatePicker(
                                controller: row.expDateCtrl,
                                anchorKey: row.expKey,
                                flex: 15,
                                currentDate: row.expDate,
                                onDateChanged: (d) =>
                                    setState(() => row.expDate = d),
                                readOnly: !widget.allowManualBatchEntry,
                              ),
                              if (_showMfgDetails) ...[
                                _buildDatePicker(
                                  controller: row.mfgDateCtrl,
                                  anchorKey: row.mfgKey,
                                  flex: 15,
                                  currentDate: row.mfgDate,
                                  onDateChanged: (d) =>
                                      setState(() => row.mfgDate = d),
                                  readOnly: true,
                                ),
                                _buildInput(
                                  controller: row.mfgBatchCtrl,
                                  flex: 15,
                                  hint: 'Mfg Batch',
                                  readOnly: true,
                                ),
                              ],
                              _buildInput(
                                controller: row.qtyOutCtrl,
                                flex: 15,
                                hint: '0',
                                isNumber: true,
                              ),
                              if (_showFocColumn) _buildFocInput(row, index),
                              SizedBox(
                                width: 24,
                                child: AnimatedOpacity(
                                  opacity: isRowHovered ? 1 : 0,
                                  duration: const Duration(milliseconds: 120),
                                  child: IconButton(
                                    onPressed: () => _removeRow(index),
                                    tooltip: 'Remove row',
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(
                                      LucideIcons.x,
                                      size: 15,
                                      color: AppTheme.errorRed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (index < _rows.length - 1)
                        const Divider(height: 1, color: AppTheme.borderLight),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: _addRow,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.plusCircle,
                          size: 14,
                          color: AppTheme.primaryBlueDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'New Row',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryBlueDark,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Batches added: ${_rows.length}/100',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      for (var i = 0; i < _rows.length; i++) {
                        final row = _rows[i];
                        if (row.binLocationCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please select Bin Location in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.batchRefCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please select Batch Reference in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.batchNoCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please enter Batch No in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.unitPackCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please enter Unit Pack in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.mrpCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please enter MRP in Row ${i + 1}.',
                          );
                          return;
                        }
                        if (row.expDateCtrl.text.isEmpty) {
                          ZerpaiToast.error(
                            context,
                            'Please select Expiry Date in Row ${i + 1}.',
                          );
                          return;
                        }

                        final qtyOut =
                            double.tryParse(row.qtyOutCtrl.text.trim()) ?? 0;
                        final foc =
                            double.tryParse(row.focCtrl.text.trim()) ?? 0;
                        if (qtyOut <= 0 && foc <= 0) {
                          ZerpaiToast.error(
                            context,
                            'Either Quantity Out or FOC must be filled in Row ${i + 1}.',
                          );
                          return;
                        }
                      }

                      final seenPairs = <String>{};
                      for (var i = 0; i < _rows.length; i++) {
                        final row = _rows[i];
                        final bin = row.binLocationCtrl.text.trim();
                        final batch = row.batchNoCtrl.text.trim();
                        if (bin.isNotEmpty && batch.isNotEmpty) {
                          final pair = '$bin|$batch';
                          if (seenPairs.contains(pair)) {
                            ZerpaiToast.error(
                              context,
                              'Same Bin Location and Batch No can\'t be used multiple times.',
                            );
                            return;
                          }
                          seenPairs.add(pair);
                        }
                      }

                      if (_hasQuantityMismatch && !_overwriteLineItem) {
                        ZerpaiToast.error(context, _quantityMismatchMessage);
                        return;
                      }

                      final batchDataList = _rows
                          .map(
                            (row) => {
                              'binLocation': row.binLocationCtrl.text,
                              'batchRef': row.batchRefCtrl.text,
                              'batchNo': row.batchNoCtrl.text,
                              'unitPack': row.unitPackCtrl.text,
                              'mrp': row.mrpCtrl.text,
                              'prate': row.ptrCtrl.text,
                              'expDate': row.expDateCtrl.text,
                              'mfgDate': row.mfgDateCtrl.text,
                              'mfgBatch': row.mfgBatchCtrl.text,
                              'qtyOut': row.qtyOutCtrl.text,
                              'foc': row.focCtrl.text,
                            },
                          )
                          .toList();

                      Navigator.pop(
                        context,
                        PicklistBatchDialogResult(
                          overwriteLineItem: _overwriteLineItem,
                          batchCount: _batchCount > 0
                              ? _batchCount
                              : _rows.length,
                          appliedQuantity: _totalQuantityOnlyOut,
                          totalIncludingFoc: _totalAppliedIncludingFoc,
                          batchDataList: batchDataList,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.borderLight),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
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
    );
  }
}

class _BinHoverBox extends StatefulWidget {
  final String message;
  final Widget child;
  final bool isEnabled;

  const _BinHoverBox({
    required this.message,
    required this.child,
    this.isEnabled = true,
  });

  @override
  State<_BinHoverBox> createState() => _BinHoverBoxState();
}

class _BinHoverBoxState extends State<_BinHoverBox> {
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_entry != null || !widget.isEnabled) return;
    _entry = _createOverlayEntry();
    Overlay.maybeOf(context)?.insert(_entry!);
  }

  void _hideOverlay() {
    _entry?.remove();
    _entry = null;
  }

  OverlayEntry _createOverlayEntry() {
    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            offset: const Offset(0, 4),
            child: Material(
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _showOverlay(),
        onExit: (_) => _hideOverlay(),
        child: widget.child,
      ),
    );
  }
}
