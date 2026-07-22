import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

class InventoryBatchBinDialogBinOption {
  const InventoryBatchBinDialogBinOption({
    required this.id,
    required this.code,
    required this.stock,
  });

  final String id;
  final String code;
  final double stock;
}

class InventoryBatchBinDialogBatchOption {
  const InventoryBatchBinDialogBatchOption({
    required this.id,
    required this.reference,
    required this.manufacturerBatchNo,
    required this.mfgDate,
    required this.expiryDate,
    required this.availableQty,
    required this.connectedBinIds,
  });

  final String id;
  final String reference;
  final String manufacturerBatchNo;
  final String mfgDate;
  final String expiryDate;
  final double availableQty;
  final Set<String> connectedBinIds;
}

class InventoryBatchBinDialogLine {
  const InventoryBatchBinDialogLine({
    required this.binId,
    required this.binCode,
    required this.qty,
    this.batchId = '',
    this.batchRef = '',
    this.manufacturerBatchNo = '',
    this.mfgDate = '',
    this.expiryDate = '',
    this.availableQty = 0,
  });

  final String binId;
  final String binCode;
  final double qty;
  final String batchId;
  final String batchRef;
  final String manufacturerBatchNo;
  final String mfgDate;
  final String expiryDate;
  final double availableQty;
}

class InventoryBatchBinSelectionDialog extends StatefulWidget {
  const InventoryBatchBinSelectionDialog({
    super.key,
    required this.title,
    required this.locationName,
    required this.itemName,
    required this.totalQuantity,
    required this.options,
    required this.batchOptions,
    required this.initialLines,
    required this.isSource,
    required this.requiresBatch,
    this.locationContextLabel = 'Location',
    this.quantityUnitLabel = 'pcs',
  });

  final String title;
  final String locationName;
  final String itemName;
  final double totalQuantity;
  final List<InventoryBatchBinDialogBinOption> options;
  final List<InventoryBatchBinDialogBatchOption> batchOptions;
  final List<InventoryBatchBinDialogLine> initialLines;
  final bool isSource;
  final bool requiresBatch;
  final String locationContextLabel;
  final String quantityUnitLabel;

  @override
  State<InventoryBatchBinSelectionDialog> createState() =>
      _InventoryBatchBinSelectionDialogState();
}

class _InventoryBatchBinSelectionDialogState
    extends State<InventoryBatchBinSelectionDialog> {
  static const double _batchColumnWidth = 180;
  static const double _binColumnWidth = 180;
  static const double _qtyColumnWidth = 110;

  late List<InventoryBatchBinDialogLine> _lines;
  late List<TextEditingController> _qtyControllers;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _lines = widget.initialLines.isEmpty
        ? <InventoryBatchBinDialogLine>[
            const InventoryBatchBinDialogLine(
              binId: '',
              binCode: '',
              qty: 0,
              batchId: '',
              batchRef: '',
            ),
          ]
        : widget.initialLines
              .map(
                (line) => InventoryBatchBinDialogLine(
                  binId: line.binId,
                  binCode: line.binCode,
                  qty: line.qty,
                  batchId: line.batchId,
                  batchRef: line.batchRef,
                  manufacturerBatchNo: line.manufacturerBatchNo,
                  mfgDate: line.mfgDate,
                  expiryDate: line.expiryDate,
                  availableQty: line.availableQty,
                ),
              )
              .toList(growable: true);
    _qtyControllers = _lines
        .map(
          (line) =>
              TextEditingController(text: line.qty == 0 ? '' : _fmt(line.qty)),
        )
        .toList(growable: true);
  }

  @override
  void dispose() {
    for (final controller in _qtyControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  double get _selectedQty =>
      _lines.fold<double>(0, (sum, line) => sum + line.qty);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      backgroundColor: AppTheme.backgroundColor,
      surfaceTintColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          width: 620,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      widget.title,
                      style: AppTheme.sectionHeader.copyWith(fontSize: 16),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        LucideIcons.x,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: Text(
                  '${widget.isSource ? 'Source' : 'Destination'} ${widget.locationContextLabel} : ${widget.locationName}',
                  style: AppTheme.metaHelper.copyWith(fontSize: 13),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.itemName,
                        style: AppTheme.sectionHeader.copyWith(fontSize: 14),
                      ),
                    ),
                    Text(
                      'Total Quantity : ${_fmt(widget.totalQuantity)} ${widget.quantityUnitLabel}   ${widget.isSource ? 'Quantity to be selected' : 'Quantity to be added'} : ${_fmt(widget.totalQuantity - _selectedQty)} ${widget.quantityUnitLabel}',
                      style: AppTheme.bodyText.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (_inlineError != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.errorBg,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppTheme.errorRed.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      _inlineError!,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.errorRedDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 36,
                        color: AppTheme.tableHeaderBg,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: _batchColumnWidth,
                              child: Text(
                                widget.isSource
                                    ? (widget.requiresBatch
                                          ? 'BATCH REFERENCE#*'
                                          : 'BATCH REFERENCE#')
                                    : 'BATCH (FROM SOURCE)',
                                style: AppTheme.tableHeader.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: _binColumnWidth,
                              child: Text(
                                widget.isSource
                                    ? 'SOURCE BINS*'
                                    : 'DESTINATION BINS*',
                                style: AppTheme.tableHeader.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: _qtyColumnWidth,
                              child: Text(
                                widget.isSource
                                    ? 'QUANTITY OUT*'
                                    : 'QUANTITY IN*',
                                textAlign: TextAlign.right,
                                style: AppTheme.tableHeader.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 42),
                          ],
                        ),
                      ),
                      for (int i = 0; i < _lines.length; i++) _binLineEditor(i),
                      Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.all(8),
                        child: InkWell(
                          onTap: () => setState(() {
                            if (widget.isSource) {
                              _lines.add(
                                const InventoryBatchBinDialogLine(
                                  binId: '',
                                  binCode: '',
                                  qty: 0,
                                ),
                              );
                              _qtyControllers.add(TextEditingController());
                              return;
                            }
                            final seed = _lines.isEmpty ? null : _lines.last;
                            _lines.add(
                              InventoryBatchBinDialogLine(
                                binId: '',
                                binCode: '',
                                qty: 0,
                                batchId: seed?.batchId ?? '',
                                batchRef: seed?.batchRef ?? '',
                                manufacturerBatchNo:
                                    seed?.manufacturerBatchNo ?? '',
                                mfgDate: seed?.mfgDate ?? '',
                                expiryDate: seed?.expiryDate ?? '',
                                availableQty: seed?.availableQty ?? 0,
                              ),
                            );
                            _qtyControllers.add(TextEditingController());
                          }),
                          child: Text(
                            '+ New Row',
                            style: AppTheme.metaHelper.copyWith(
                              color: AppTheme.primaryBlue,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Row(
                  children: [
                    if (widget.isSource)
                      InkWell(
                        onTap: () => setState(() {
                          _lines.add(
                            const InventoryBatchBinDialogLine(
                              binId: '',
                              binCode: '',
                              qty: 0,
                              batchId: '',
                              batchRef: '',
                            ),
                          );
                          _qtyControllers.add(TextEditingController());
                        }),
                        child: Text(
                          '+Select another batch',
                          style: AppTheme.metaHelper.copyWith(
                            color: AppTheme.primaryBlue,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    if (widget.isSource) const Spacer(),
                    Text(
                      'Batches added: ${_lines.length}/100',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderColor)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 38,
                      child: ElevatedButton(
                        onPressed: _onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _binLineEditor(int index) {
    const double modalRowControlHeight = 40;
    final line = _lines[index];
    final requireBatchForLine = widget.requiresBatch && widget.isSource;
    final isBatchPending = requireBatchForLine && line.batchRef.trim().isEmpty;
    final qtyController = _qtyControllers[index];
    final batchOption = widget.batchOptions
        .where((b) => b.id == line.batchId || b.reference == line.batchRef)
        .firstOrNull;
    final allBatches = widget.batchOptions;
    final selectedElsewhereBatches = _lines
        .asMap()
        .entries
        .where((entry) => entry.key != index)
        .map(
          (entry) => entry.value.batchId.isEmpty
              ? entry.value.batchRef
              : entry.value.batchId,
        )
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    final availableBatches = allBatches
        .where((option) {
          final key = option.id.isEmpty ? option.reference : option.id;
          return !selectedElsewhereBatches.contains(key) ||
              (line.batchId == option.id || line.batchRef == option.reference);
        })
        .toList(growable: false);
    final currentOption = widget.options
        .where((option) => option.id == line.binId)
        .firstOrNull;
    final selectedElsewhere = _lines
        .asMap()
        .entries
        .where((entry) => entry.key != index)
        .map((entry) => entry.value.binId)
        .where((id) => id.trim().isNotEmpty)
        .toSet();
    final availableOptions = widget.options
        .where(
          (option) =>
              !selectedElsewhere.contains(option.id) || option.id == line.binId,
        )
        .toList(growable: false);
    final constrainedByBatch =
        widget.isSource &&
        batchOption != null &&
        batchOption.connectedBinIds.isNotEmpty;
    final batchScopedOptions = constrainedByBatch
        ? availableOptions
              .where(
                (option) =>
                    batchOption.connectedBinIds.contains(option.id) ||
                    option.id == line.binId,
              )
              .toList(growable: false)
        : availableOptions;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _batchColumnWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isSource)
                  FormDropdown<InventoryBatchBinDialogBatchOption>(
                    value: batchOption,
                    items: availableBatches,
                    height: modalRowControlHeight,
                    hint: 'Select Batch',
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _lines[index] = InventoryBatchBinDialogLine(
                          binId: _lines[index].binId,
                          binCode: _lines[index].binCode,
                          qty: _lines[index].qty,
                          batchId: value.id,
                          batchRef: value.reference,
                          manufacturerBatchNo: value.manufacturerBatchNo,
                          mfgDate: value.mfgDate,
                          expiryDate: value.expiryDate,
                          availableQty: value.availableQty,
                        );
                      });
                    },
                    displayStringForValue: (value) => value.reference,
                    searchStringForValue: (value) =>
                        '${value.reference} ${value.manufacturerBatchNo} ${value.expiryDate}',
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 36,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderColor),
                      color: AppTheme.backgroundColor,
                    ),
                    child: Text(
                      line.batchRef.isEmpty ? 'Select Batch' : line.batchRef,
                      style: AppTheme.bodyText.copyWith(fontSize: 13),
                    ),
                  ),
                if (line.manufacturerBatchNo.trim().isNotEmpty ||
                    line.expiryDate.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Manufacturer Batch#: ${line.manufacturerBatchNo}${line.expiryDate.trim().isNotEmpty ? '   Expiry Date: ${line.expiryDate}' : ''}',
                      style: AppTheme.metaHelper.copyWith(fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: _binColumnWidth,
            child: FormDropdown<InventoryBatchBinDialogBinOption>(
              value: currentOption,
              items: batchScopedOptions,
              height: modalRowControlHeight,
              enabled: !isBatchPending,
              hint: 'Select bin',
              itemEstimatedHeight: 52,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _lines[index] = InventoryBatchBinDialogLine(
                    binId: value.id,
                    binCode: value.code,
                    qty: _lines[index].qty,
                    batchId: _lines[index].batchId,
                    batchRef: _lines[index].batchRef,
                    manufacturerBatchNo: _lines[index].manufacturerBatchNo,
                    mfgDate: _lines[index].mfgDate,
                    expiryDate: _lines[index].expiryDate,
                    availableQty: _lines[index].availableQty,
                  );
                });
              },
              displayStringForValue: (value) => value.code,
              searchStringForValue: (value) =>
                  '${value.code} ${_fmt(value.stock)}',
              itemBuilder: (item, isSelected, isHovered) {
                final isActive = isHovered || isSelected;
                final primaryColor = isActive
                    ? Colors.white
                    : AppTheme.textPrimary;
                final secondaryColor = isActive
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppTheme.textSecondary;
                return Container(
                  width: double.infinity,
                  color: isActive ? AppTheme.infoBlue : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.code,
                        style: AppTheme.bodyText.copyWith(
                          fontSize: 13,
                          color: primaryColor,
                        ),
                      ),
                      Text(
                        'Stock in bin: ${_fmt(item.stock)} ${widget.quantityUnitLabel}',
                        style: AppTheme.metaHelper.copyWith(
                          fontSize: 11,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: _qtyColumnWidth,
            child: CustomTextField(
              controller: qtyController,
              height: modalRowControlHeight,
              hintText: '0',
              enabled: !isBatchPending,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              onChanged: (value) {
                final qty = double.tryParse(value.trim()) ?? 0;
                _lines[index] = InventoryBatchBinDialogLine(
                  binId: _lines[index].binId,
                  binCode: _lines[index].binCode,
                  qty: qty,
                  batchId: _lines[index].batchId,
                  batchRef: _lines[index].batchRef,
                  manufacturerBatchNo: _lines[index].manufacturerBatchNo,
                  mfgDate: _lines[index].mfgDate,
                  expiryDate: _lines[index].expiryDate,
                  availableQty: _lines[index].availableQty,
                );
              },
              onSubmitted: (value) {
                final normalized = _normalizeQtyInput(value);
                if (qtyController.text != normalized) {
                  qtyController.text = normalized;
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 24,
            child: Padding(
              padding: const EdgeInsets.only(top: 13),
              child: InkWell(
                onTap: _lines.length == 1
                    ? null
                    : () => setState(() {
                        _lines.removeAt(index);
                        _qtyControllers.removeAt(index).dispose();
                      }),
                child: Icon(
                  LucideIcons.xCircle,
                  size: 14,
                  color: _lines.length == 1
                      ? AppTheme.textMuted
                      : AppTheme.errorRed,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  void _onSave() {
    final requireBatchForLine = widget.requiresBatch && widget.isSource;

    // Collect per-row problems for context-aware error messages.
    final rowErrors = <String>[];
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final rowNum = i + 1;
      final missing = <String>[];
      if (requireBatchForLine && line.batchRef.trim().isEmpty) {
        missing.add('batch');
      }
      if (line.binId.trim().isEmpty) {
        missing.add(widget.isSource ? 'source bin' : 'destination bin');
      }
      if (line.qty <= 0) missing.add('quantity');
      if (widget.isSource &&
          line.batchId.trim().isNotEmpty &&
          line.binId.trim().isNotEmpty) {
        final batch = widget.batchOptions
            .where(
              (option) =>
                  option.id == line.batchId ||
                  option.reference == line.batchRef,
            )
            .firstOrNull;
        if (batch != null &&
            batch.connectedBinIds.isNotEmpty &&
            !batch.connectedBinIds.contains(line.binId)) {
          missing.add('valid source bin for selected batch');
        }
      }
      if (missing.isNotEmpty) {
        rowErrors.add('Row $rowNum: enter ${missing.join(', ')}.');
      }
    }

    if (rowErrors.isNotEmpty) {
      setState(() {
        _inlineError = rowErrors.length == 1
            ? rowErrors.first
            : '${rowErrors.length} rows are incomplete — ${rowErrors.join(' ')}';
      });
      return;
    }

    final valid = _lines.toList(growable: false);
    final total = valid.fold<double>(0, (sum, line) => sum + line.qty);
    if ((total - widget.totalQuantity).abs() > 0.0001) {
      setState(() {
        _inlineError =
            'Quantity mismatch — entered ${_fmt(total)} but expected ${_fmt(widget.totalQuantity)}.';
      });
      return;
    }
    Navigator.of(context).pop(valid);
  }

  static String _fmt(num value) {
    final fixed = value.toStringAsFixed(2);
    return fixed
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  static String _normalizeQtyInput(String raw) {
    final parsed = double.tryParse(raw.trim());
    if (parsed == null || parsed <= 0) return '';
    return _fmt(parsed);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
