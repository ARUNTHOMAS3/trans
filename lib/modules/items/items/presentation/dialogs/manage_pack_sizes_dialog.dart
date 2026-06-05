import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/models/unit_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ManagePackSizesDialog extends StatefulWidget {
  const ManagePackSizesDialog({
    super.key,
    required this.units,
    required this.lookupLabelForUnitId,
    this.initialPackSize,
  });

  final List<Unit> units;
  final String Function(String unitId) lookupLabelForUnitId;
  final String? initialPackSize;

  @override
  State<ManagePackSizesDialog> createState() => _ManagePackSizesDialogState();
}

class _ManagePackSizesDialogState extends State<ManagePackSizesDialog> {
  final ScrollController _scrollController = ScrollController();
  final List<_PackSizeRow> _rows = [];
  int _selectedRowIndex = 0;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final parsed = _parsePackSize(widget.initialPackSize);
    _rows.add(
      _PackSizeRow(
        unitId: parsed?.unitId,
        unitPack: parsed?.unitPack ?? '',
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeUnits = widget.units.where((unit) => unit.isActive).toList();

    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, left: 24, right: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 12),
              child: Row(
                children: [
                  const Text(
                    'Manage Pack Sizes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    splashRadius: 18,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            if (_errorText != null)
              Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorBgBorder),
                ),
                child: Text(
                  _errorText!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.errorTextDark,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Row(
                children: const [
                  Expanded(
                    child: Text(
                      'Pack Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Unit Pack',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  final row = _rows[index];
                  final isSelected = index == _selectedRowIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedRowIndex = index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.infoBg.withValues(alpha: 0.4)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryBlueDark
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: FormDropdown<String>(
                                value: row.unitId,
                                items: activeUnits.map((unit) => unit.id).toList(),
                                hint: 'Select pack name',
                                onChanged: (value) {
                                  setState(() {
                                    row.unitId = value;
                                    _selectedRowIndex = index;
                                    _errorText = null;
                                  });
                                },
                                displayStringForValue:
                                    widget.lookupLabelForUnitId,
                                searchStringForValue: (value) => widget
                                    .lookupLabelForUnitId(value)
                                    .toLowerCase(),
                                itemBuilder: (value, selected, hovered) {
                                  final label =
                                      widget.lookupLabelForUnitId(value);
                                  return Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    alignment: Alignment.centerLeft,
                                    decoration: BoxDecoration(
                                      color: hovered
                                          ? AppTheme.primaryBlueDark
                                          : selected
                                          ? AppTheme.infoBg
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: hovered
                                                  ? Colors.white
                                                  : selected
                                                  ? AppTheme.primaryBlueDark
                                                  : AppTheme.textPrimary,
                                              fontWeight: selected
                                                  ? FontWeight.w500
                                                  : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                        if (selected)
                                          Icon(
                                            Icons.check,
                                            size: 16,
                                            color: hovered
                                                ? Colors.white
                                                : AppTheme.primaryBlueDark,
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: row.unitPackCtrl,
                                hintText: 'Enter unit pack',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: (_) {
                                  if (_selectedRowIndex != index ||
                                      _errorText != null) {
                                    setState(() {
                                      _selectedRowIndex = index;
                                      _errorText = null;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 40,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  size: 16,
                                  color: AppTheme.errorRed,
                                ),
                                splashRadius: 16,
                                onPressed: _rows.length == 1
                                    ? null
                                    : () => _removeRow(index),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: _addRow,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: AppTheme.primaryBlueDark,
                    ),
                    label: const Text(
                      'Add New',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlueDark,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ZButton.primary(
                    label: 'Save and Select',
                    onPressed: _saveAndSelect,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addRow() {
    final newRow = _PackSizeRow(unitPack: '');
    setState(() {
      _rows.add(newRow);
      _selectedRowIndex = _rows.length - 1;
      _errorText = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      newRow.unitPackFocusNode.requestFocus();
    });
  }

  void _removeRow(int index) {
    final row = _rows.removeAt(index);
    row.dispose();
    setState(() {
      if (_selectedRowIndex >= _rows.length) {
        _selectedRowIndex = _rows.length - 1;
      } else if (_selectedRowIndex > index) {
        _selectedRowIndex -= 1;
      } else if (_selectedRowIndex == index) {
        _selectedRowIndex = index == 0 ? 0 : index - 1;
      }
      _errorText = null;
    });
  }

  void _saveAndSelect() {
    if (_rows.isEmpty) {
      setState(() => _errorText = 'Please add a pack size first.');
      return;
    }

    final row = _rows[_selectedRowIndex];
    final unitId = row.unitId;
    final unitPack = row.unitPackCtrl.text.trim();

    if (unitId == null || unitId.isEmpty) {
      setState(() => _errorText = 'Please select a pack name.');
      return;
    }
    if (unitPack.isEmpty) {
      setState(() => _errorText = 'Please enter a unit pack value.');
      return;
    }

    final packName = widget.lookupLabelForUnitId(unitId).trim();
    Navigator.of(context).pop('$packName ($unitPack)');
  }

  _ParsedPackSize? _parsePackSize(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final match = RegExp(r'^(.*)\s+\((.*)\)$').firstMatch(value.trim());
    if (match == null) return null;

    final packName = match.group(1)?.trim();
    final unitPack = match.group(2)?.trim();
    if (packName == null || packName.isEmpty || unitPack == null) {
      return null;
    }

    for (final unit in widget.units) {
      final label = widget.lookupLabelForUnitId(unit.id).trim();
      if (label.toLowerCase() == packName.toLowerCase()) {
        return _ParsedPackSize(unit.id, unitPack);
      }
    }
    return null;
  }
}

class _PackSizeRow {
  _PackSizeRow({this.unitId, required String unitPack})
    : unitPackCtrl = TextEditingController(text: unitPack),
      unitPackFocusNode = FocusNode();

  String? unitId;
  final TextEditingController unitPackCtrl;
  final FocusNode unitPackFocusNode;

  void dispose() {
    unitPackCtrl.dispose();
    unitPackFocusNode.dispose();
  }
}

class _ParsedPackSize {
  const _ParsedPackSize(this.unitId, this.unitPack);

  final String unitId;
  final String unitPack;
}
