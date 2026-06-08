import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ManagePackSizesDialog extends StatefulWidget {
  const ManagePackSizesDialog({
    super.key,
    required this.packSizes,
    required this.onCreatePackSize,
    this.initialPackSize,
  });

  final List<Map<String, dynamic>> packSizes;
  final Future<Map<String, dynamic>> Function(String packName, String unitPack)
  onCreatePackSize;
  final String? initialPackSize;

  @override
  State<ManagePackSizesDialog> createState() => _ManagePackSizesDialogState();
}

class _ManagePackSizesDialogState extends State<ManagePackSizesDialog> {
  final ScrollController _scrollController = ScrollController();
  final List<_PackSizeRow> _rows = [];
  int _selectedRowIndex = 0;
  String? _errorText;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final parsed = _parsePackSize(widget.initialPackSize);
    final existingRows = widget.packSizes
        .map(
          (pack) => _PackSizeRow(
            packName: (pack['pack_name'] ?? '').toString().trim(),
            unitPack: (pack['unit_pack'] ?? '').toString().trim(),
          ),
        )
        .where((row) => (row.packName?.isNotEmpty ?? false))
        .toList();
    if (existingRows.isEmpty) {
      _rows.add(
        _PackSizeRow(
          packName: parsed?.packName,
          unitPack: parsed?.unitPack ?? '',
        ),
      );
      return;
    }
    _rows.addAll(existingRows);
    if (parsed != null) {
      final initialIndex = _rows.indexWhere(
        (row) =>
            (row.packName ?? '').trim().toLowerCase() ==
                parsed.packName.trim().toLowerCase() &&
            row.unitPackCtrl.text.trim() == parsed.unitPack.trim(),
      );
      if (initialIndex >= 0) {
        _selectedRowIndex = initialIndex;
      }
    }
  }

  String _displayLabel(String? packName, String? unitPack) {
    final normalizedPackName = packName?.trim() ?? '';
    final normalizedUnitPack = unitPack?.trim() ?? '';
    if (normalizedPackName.isEmpty) return normalizedUnitPack;
    if (normalizedUnitPack.isEmpty) return normalizedPackName;
    return '$normalizedPackName - $normalizedUnitPack';
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedRowIndex = index),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: row.packNameCtrl,
                                hintText: 'Enter pack name',
                                onChanged: (value) {
                                  row.packName = value.trim();
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
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ZButton.primary(
                    label: _isSaving ? 'Saving...' : 'Save and Select',
                    onPressed: _isSaving ? null : _saveAndSelect,
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

  Future<void> _saveAndSelect() async {
    if (_rows.isEmpty) {
      setState(() => _errorText = 'Please add a pack size first.');
      return;
    }

    final row = _rows[_selectedRowIndex];
    final packName = row.packNameCtrl.text.trim();
    final unitPack = row.unitPackCtrl.text.trim();

    if (packName.isEmpty) {
      setState(() => _errorText = 'Please enter a pack name.');
      return;
    }
    if (unitPack.isEmpty) {
      setState(() => _errorText = 'Please enter a unit pack value.');
      return;
    }

    final existing = widget.packSizes.firstWhere(
      (pack) =>
          (pack['pack_name'] ?? '').toString().trim().toLowerCase() ==
              packName.toLowerCase() &&
          (pack['unit_pack'] ?? '').toString().trim() == unitPack,
      orElse: () => const <String, dynamic>{},
    );
    if (existing.isNotEmpty) {
      Navigator.of(context).pop(existing);
      return;
    }

    final duplicateRowCount = _rows.where((candidate) {
      final candidatePackName = candidate.packNameCtrl.text.trim().toLowerCase();
      final candidateUnitPack = candidate.unitPackCtrl.text.trim();
      return candidatePackName == packName.toLowerCase() &&
          candidateUnitPack == unitPack;
    }).length;
    if (duplicateRowCount > 1) {
      setState(() {
        _errorText =
            'Pack name and unit pack combination must be unique in this list.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    try {
      final created = await widget.onCreatePackSize(packName, unitPack);
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  _ParsedPackSize? _parsePackSize(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final input = value.trim();
    final directMatch = widget.packSizes.firstWhere(
      (pack) =>
          _displayLabel(
            (pack['pack_name'] ?? '').toString().trim(),
            (pack['unit_pack'] ?? '').toString().trim(),
          ).toLowerCase() ==
          input.toLowerCase(),
      orElse: () => const <String, dynamic>{},
    );
    if (directMatch.isNotEmpty) {
      return _ParsedPackSize(
        (directMatch['pack_name'] ?? '').toString().trim(),
        (directMatch['unit_pack'] ?? '').toString().trim(),
      );
    }

    final packName = input;
    final existing = widget.packSizes.firstWhere(
      (pack) =>
          (pack['pack_name'] ?? '').toString().trim().toLowerCase() ==
          packName.toLowerCase(),
      orElse: () => const <String, dynamic>{},
    );
    if (existing.isEmpty) return _ParsedPackSize(packName, '');
    return _ParsedPackSize(
      (existing['pack_name'] ?? '').toString().trim(),
      (existing['unit_pack'] ?? '').toString().trim(),
    );
  }
}

class _PackSizeRow {
  _PackSizeRow({this.packName, required String unitPack})
    : packNameCtrl = TextEditingController(text: packName ?? ''),
      unitPackCtrl = TextEditingController(text: unitPack),
      unitPackFocusNode = FocusNode();

  String? packName;
  final TextEditingController packNameCtrl;
  final TextEditingController unitPackCtrl;
  final FocusNode unitPackFocusNode;

  void dispose() {
    packNameCtrl.dispose();
    unitPackCtrl.dispose();
    unitPackFocusNode.dispose();
  }
}

class _ParsedPackSize {
  const _ParsedPackSize(this.packName, this.unitPack);

  final String packName;
  final String unitPack;
}
