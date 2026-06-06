// FILE: lib/modules/purchases/purchase_orders/presentation/widgets/manage_tds_tcs_rates_dialog.dart
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';

class ManageTdsTcsRatesDialog extends StatefulWidget {
  final String title;
  final bool isTcs;
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> sections; // sections for TDS, natures for TCS
  final String? selectedId;
  final ValueChanged<Map<String, dynamic>> onSelect;
  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)? onSave;
  final Future<String?> Function(Map<String, dynamic> item)? onDeleteCheck;

  const ManageTdsTcsRatesDialog({
    super.key,
    required this.title,
    required this.isTcs,
    required this.items,
    required this.sections,
    required this.onSelect,
    this.onSave,
    this.onDeleteCheck,
    this.selectedId,
  });

  @override
  State<ManageTdsTcsRatesDialog> createState() => _ManageTdsTcsRatesDialogState();
}

class _ManageTdsTcsRatesDialogState extends State<ManageTdsTcsRatesDialog> {
  late List<Map<String, dynamic>> _rows;
  int? _hoverIndex;
  String? _errorMessage;
  bool _showInlineForm = false;
  int? _editingIndex;

  // Form controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _rateCtrl = TextEditingController();
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    _rows = List<Map<String, dynamic>>.from(widget.items);
  }

  @override
  void didUpdateWidget(ManageTdsTcsRatesDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      setState(() {
        _rows = List<Map<String, dynamic>>.from(widget.items);
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  void _startEdit(int index) {
    final item = _rows[index];
    setState(() {
      _showInlineForm = true;
      _editingIndex = index;
      _nameCtrl.text = item['tax_name']?.toString() ?? '';
      _rateCtrl.text = widget.isTcs
          ? (item['rate']?.toString() ?? '')
          : (item['base_rate']?.toString() ?? '');
      _selectedSectionId = widget.isTcs
          ? item['nature_id']?.toString()
          : item['section_id']?.toString();
      _errorMessage = null;
    });
  }

  void _cancel() {
    setState(() {
      _showInlineForm = false;
      _editingIndex = null;
      _nameCtrl.clear();
      _rateCtrl.clear();
      _selectedSectionId = null;
      _errorMessage = null;
    });
  }

  void _saveItem({bool selectAfter = false}) async {
    final name = _nameCtrl.text.trim();
    final rateStr = _rateCtrl.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Tax Name is required.');
      return;
    }
    final rateVal = double.tryParse(rateStr);
    if (rateVal == null) {
      setState(() => _errorMessage = 'Please enter a valid rate.');
      return;
    }
    if (_selectedSectionId == null) {
      setState(() => _errorMessage = widget.isTcs ? 'Please select a nature.' : 'Please select a section.');
      return;
    }

    final isDuplicate = _rows.any((row) {
      final idx = _rows.indexOf(row);
      if (_editingIndex == idx) return false;
      return row['tax_name']?.toString().toLowerCase().trim() == name.toLowerCase();
    });

    if (isDuplicate) {
      setState(() {
        _errorMessage = 'The tax "${name}" already exists.';
      });
      return;
    }

    Map<String, dynamic>? itemToSelect;

    setState(() {
      final itemData = {
        'tax_name': name,
        if (widget.isTcs) 'rate': rateVal else 'base_rate': rateVal,
        if (widget.isTcs) 'nature_id': _selectedSectionId else 'section_id': _selectedSectionId,
        'is_active': true,
      };

      if (_editingIndex == null) {
        final newItem = {
          ...itemData,
          'id': 'new_${DateTime.now().millisecondsSinceEpoch}',
        };
        _rows.add(newItem);
        itemToSelect = newItem;
      } else {
        final existing = _rows[_editingIndex!];
        _rows[_editingIndex!] = {
          ...existing,
          ...itemData,
        };
        itemToSelect = _rows[_editingIndex!];
      }
      _showInlineForm = false;
      _editingIndex = null;
      _nameCtrl.clear();
      _rateCtrl.clear();
      _selectedSectionId = null;
      _errorMessage = null;
    });

    if (selectAfter) {
      await _saveChanges(itemToSelect: itemToSelect);
    }
  }

  Future<void> _saveChanges({Map<String, dynamic>? itemToSelect}) async {
    if (widget.onSave != null) {
      try {
        final updatedRows = await widget.onSave!(_rows);
        if (updatedRows.isNotEmpty) {
          setState(() {
            _rows = List<Map<String, dynamic>>.from(updatedRows);
          });
          Map<String, dynamic>? savedItem;
          if (itemToSelect != null) {
            final labelToFind = itemToSelect['tax_name'];
            savedItem = _rows.firstWhere(
              (row) => row['tax_name'] == labelToFind,
              orElse: () => _rows.last,
            );
          }
          if (mounted) {
            final valueToReturn = savedItem ?? itemToSelect ?? _rows.last;
            widget.onSelect(valueToReturn);
            Navigator.pop(context, valueToReturn);
          }
        }
      } catch (e) {
        AppLogger.error('Save error in ManageTdsTcsRatesDialog', error: e, module: 'purchases');
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } else {
      if (mounted) {
        final valueToReturn = itemToSelect ?? _rows.last;
        widget.onSelect(valueToReturn);
        Navigator.pop(context, valueToReturn);
      }
    }
  }

  void _selectAndClose(Map<String, dynamic> item) {
    widget.onSelect(item);
    Navigator.pop(context, item);
  }

  String _getSectionName(String? id) {
    if (id == null) return '';
    try {
      final match = widget.sections.firstWhere((s) => s['id']?.toString() == id);
      return widget.isTcs
          ? (match['nature_name']?.toString() ?? '')
          : (match['section_name']?.toString() ?? '');
    } catch (_) {
      return '';
    }
  }

  bool _isExpired(Map<String, dynamic> item) {
    if (item['is_active'] == false) return true;
    final toDateStr = item['applicable_to']?.toString();
    if (toDateStr != null && toDateStr.isNotEmpty) {
      try {
        final toDate = DateTime.parse(toDateStr);
        if (toDate.isBefore(DateTime.now())) {
          return true;
        }
      } catch (_) {}
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(left: 24, right: 24, top: 0, bottom: 40),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        color: Colors.white,
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF991B1B), size: 16),
                        onPressed: () => setState(() => _errorMessage = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            if (_showInlineForm)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: _buildInlineForm(),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: _buildActionToolbar(),
              ),
            _buildTableHeaders(),
            const Divider(height: 1, color: AppTheme.borderColor),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: _buildTableRows(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF0088FF)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, size: 18, color: Color(0xFF0088FF)),
              splashRadius: 20,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionToolbar() {
    final typeStr = widget.isTcs ? 'TCS' : 'TDS';
    return Row(
      children: [
        Text(
          '$typeStr taxes',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Spacer(),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _showInlineForm = true;
                    _editingIndex = null;
                    _nameCtrl.clear();
                    _rateCtrl.clear();
                    _selectedSectionId = null;
                    _errorMessage = null;
                  });
                },
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    '+ New $typeStr Tax',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 16,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              PopupMenuButton<String>(
                offset: const Offset(0, 36),
                icon: const Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Colors.white,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                style: const ButtonStyle(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onSelected: (val) {
                  if (val == 'new') {
                    setState(() {
                      _showInlineForm = true;
                      _editingIndex = null;
                      _nameCtrl.clear();
                      _rateCtrl.clear();
                      _selectedSectionId = null;
                      _errorMessage = null;
                    });
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    value: 'new',
                    height: 32,
                    child: Text(
                      'New $typeStr Tax Rate',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            ZerpaiToast.info(context, '$typeStr group creation is managed automatically.');
          },
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          child: Text(
            '+ New $typeStr Group',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineForm() {
    final sectionStr = widget.isTcs ? 'Nature' : 'Section';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Tax Name*",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _nameCtrl,
                      height: 32,
                      hintText: 'Enter tax name',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Rate (%)*",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _rateCtrl,
                      height: 32,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hintText: '0.00',
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$sectionStr*",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.errorRed,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FormDropdown<String>(
                      height: 32,
                      value: _selectedSectionId,
                      items: widget.sections.map((s) => s['id']?.toString() ?? '').toList(),
                      displayStringForValue: (id) => _getSectionName(id),
                      hint: 'Select $sectionStr',
                      onChanged: (id) {
                        setState(() {
                          _selectedSectionId = id;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _saveItem(selectAfter: true),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: Text(
                  _editingIndex == null ? "Save and Select" : "Update",
                  style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: _cancel,
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaders() {
    final sectionHeader = widget.isTcs ? 'NATURE' : 'SECTION';
    return Container(
      color: const Color(0xFFF9FAFB),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'TAX NAME',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.5),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'RATE (%)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              sectionHeader,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.5),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              'STATUS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 60), // spacer for actions
        ],
      ),
    );
  }

  Widget _buildTableRows() {
    if (_rows.isEmpty) {
      final typeStr = widget.isTcs ? 'TCS' : 'TDS';
      return Container(
        height: 120,
        alignment: Alignment.center,
        child: Text(
          'No $typeStr rates found.',
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final item = _rows[index];
        final taxName = item['tax_name']?.toString() ?? '';
        final rateVal = widget.isTcs ? item['rate'] : item['base_rate'];
        final ratePercent = rateVal?.toString() ?? '0';
        final sectionName = widget.isTcs
            ? _getSectionName(item['nature_id']?.toString())
            : _getSectionName(item['section_id']?.toString());

        final expired = _isExpired(item);
        final hovered = _hoverIndex == index;
        final isSelected = item['id'] == widget.selectedId;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoverIndex = index),
          onExit: (_) => setState(() => _hoverIndex = null),
          child: InkWell(
            onTap: () => _selectAndClose(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEFF6FF)
                    : (hovered ? const Color(0xFFF9FAFB) : Colors.white),
                border: const Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      taxName,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textBody, fontWeight: FontWeight.normal),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      ratePercent,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      sectionName,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      expired ? 'Expired' : 'Active',
                      style: TextStyle(
                        fontSize: 13,
                        color: expired ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hovered) ...[
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF0088FF)),
                            onPressed: () => _startEdit(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 16,
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 14, color: AppTheme.errorRed),
                            onPressed: () async {
                              if (widget.onDeleteCheck != null && item['id'] != null) {
                                final check = await widget.onDeleteCheck!(item);
                                if (check != null && check.isNotEmpty) {
                                  setState(() => _errorMessage = check);
                                  return;
                                }
                              }

                              final backup = List<Map<String, dynamic>>.from(_rows);
                              setState(() {
                                _rows.removeAt(index);
                                _errorMessage = null;
                              });

                              if (widget.onSave != null) {
                                try {
                                  final saved = await widget.onSave!(_rows);
                                  setState(() {
                                    _rows = List<Map<String, dynamic>>.from(saved);
                                  });
                                  if (mounted) {
                                    ZerpaiToast.success(context, 'Tax rate deleted successfully.');
                                  }
                                } catch (e) {
                                  setState(() {
                                    _rows = backup;
                                    _errorMessage = e.toString();
                                  });
                                }
                              }
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 16,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
