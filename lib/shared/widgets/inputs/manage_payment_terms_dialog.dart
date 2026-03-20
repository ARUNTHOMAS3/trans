import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class ManagePaymentTermsDialog extends StatefulWidget {
  final List<dynamic> items;
  final String? selectedId;
  final ValueChanged<dynamic> onSelect;
  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
  onSave;
  final Future<String?> Function(Map<String, dynamic> item)? onDeleteCheck;

  const ManagePaymentTermsDialog({
    super.key,
    required this.items,
    required this.onSelect,
    this.onSave,
    this.onDeleteCheck,
    this.selectedId,
  });

  @override
  State<ManagePaymentTermsDialog> createState() =>
      _ManagePaymentTermsDialogState();
}

class _ManagePaymentTermsDialogState extends State<ManagePaymentTermsDialog> {
  late List<Map<String, dynamic>> _rows;
  final List<Map<String, dynamic>> _deletedRows = [];
  bool _isSaving = false;
  int? _editingIndex;
  String? _editingField;
  int? _hoveredIndex;
  final Map<String, TextEditingController> _controllers = {};
  String? _errorMessage;
  late String? _currentDefaultId;

  @override
  void initState() {
    super.initState();
    int counter = 0;
    _rows = widget.items.map((item) {
      if (item is Map<String, dynamic>) {
        final row = Map<String, dynamic>.from(item);
        // Ensure every row has an ID for controller mapping
        row['id'] ??=
            'init_${DateTime.now().millisecondsSinceEpoch}_${counter++}';
        return row;
      }
      return <String, dynamic>{};
    }).toList();
    _currentDefaultId = widget.selectedId;
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(int index, String field) {
    final row = _rows[index];
    final id = row['id']?.toString() ?? 'unknown_$index';
    final key = '$id-$field';
    if (!_controllers.containsKey(key)) {
      final value = row[field]?.toString() ?? '';
      _controllers[key] = TextEditingController.fromValue(
        TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        ),
      );
    }
    return _controllers[key]!;
  }

  void _addNewRow() {
    setState(() {
      _rows.add({
        'id': 'new_${DateTime.now().millisecondsSinceEpoch}',
        'term_name': '',
        'number_of_days': '',
        'is_active': true,
      });
      _editingIndex = _rows.length - 1;
      _editingField = 'term_name';
    });
    _clearError();
  }

  Future<void> _saveChanges() async {
    // First, check if any deleted terms are in use
    if (widget.onDeleteCheck != null && _deletedRows.isNotEmpty) {
      final List<Map<String, dynamic>> toRestore = [];
      String? firstError;

      for (var deletedItem in _deletedRows) {
        if (deletedItem['id'] != null) {
          final blockReason = await widget.onDeleteCheck!(deletedItem);
          if (blockReason != null && blockReason.isNotEmpty) {
            toRestore.add(deletedItem);
            firstError ??= blockReason;
          }
        }
      }

      if (toRestore.isNotEmpty) {
        if (mounted) {
          setState(() {
            for (var item in toRestore) {
              _rows.add(item);
              _deletedRows.remove(item);
            }
            _errorMessage = ZerpaiBuilders.parseErrorMessage(
              firstError,
              'payment term',
            );
            _isSaving = false;
          });
        }
        return; // Stop save process
      }
    }

    // Validate all rows
    final seenNames = <String>{};
    for (var i = 0; i < _rows.length; i++) {
      final termName = _rows[i]['term_name']?.toString().trim() ?? '';
      final daysStr = _rows[i]['number_of_days']?.toString().trim() ?? '';

      if (termName.isEmpty) {
        _showError('Enter a valid term name.');
        return;
      }

      if (seenNames.contains(termName.toLowerCase())) {
        _showError('The payment term $termName already exists.');
        return;
      }
      seenNames.add(termName.toLowerCase());

      final days = int.tryParse(daysStr);
      if (days == null) {
        _showError('Number of days must be a valid number at row ${i + 1}');
        return;
      }

      _rows[i]['number_of_days'] = days;
    }

    if (widget.onSave != null) {
      try {
        setState(() => _isSaving = true);

        // Clean data before sending to backend
        final cleanedRows = _rows.map((row) {
          final cleaned = <String, dynamic>{};

          if (row['id'] != null && !row['id'].toString().startsWith('new_')) {
            cleaned['id'] = row['id'];
          }
          cleaned['term_name'] = row['term_name'];
          cleaned['number_of_days'] = row['number_of_days'];
          if (row['description'] != null) {
            cleaned['description'] = row['description'];
          }
          if (row['is_active'] != null) cleaned['is_active'] = row['is_active'];
          if (row['created_at'] != null) {
            cleaned['created_at'] = row['created_at'];
          }

          return cleaned;
        }).toList();

        final updatedRows = await widget.onSave!(cleanedRows);

        if (mounted) {
          ZerpaiBuilders.showSavedToast(context, 'Payment terms');
        }

        if (updatedRows.isNotEmpty) {
          setState(() {
            _rows = updatedRows.map((r) {
              return Map<String, dynamic>.from(r);
            }).toList();
            _deletedRows.clear();
          });

          // Close dialog after successful save
          if (mounted && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        debugPrint('❌ Save Error: $e');
        _showError(ZerpaiBuilders.parseErrorMessage(e, 'payment term'));
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  Future<void> _deleteRow(int index) async {
    final target = _rows[index];
    final id = target['id']?.toString();

    // Perform immediate usage check if it's an existing item
    if (widget.onDeleteCheck != null &&
        id != null &&
        !id.startsWith('new_') &&
        !id.startsWith('init_')) {
      try {
        final blockReason = await widget.onDeleteCheck!(target);
        if (blockReason != null && blockReason.isNotEmpty) {
          _showError(blockReason);
          return;
        }
      } catch (e) {
        debugPrint('❌ Delete check error: $e');
      }
    }

    // Clean up controllers
    if (id != null) {
      _controllers.remove('$id-term_name')?.dispose();
      _controllers.remove('$id-number_of_days')?.dispose();
    }

    // Track for restoration or summary
    _deletedRows.add(target);

    // Remove from UI
    setState(() {
      _rows.removeAt(index);
      _errorMessage = null;
      _editingIndex = null;
      _editingField = null;
    });
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.only(
        top: 0,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_errorMessage != null) _buildPremiumErrorAlert(),
            _buildTable(),
            _buildAddNewLink(),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumErrorAlert() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.errorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.errorBgBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.errorRed,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppTheme.errorTextDark,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearError,
            child: const Icon(Icons.close, color: AppTheme.errorRed, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          const Text(
            'Configure Payment Terms',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18, color: AppTheme.errorRed),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTableHeader(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _rows.length,
              itemBuilder: (context, index) => _buildTableRow(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: AppTheme.bgLight,
              border: Border(
                top: BorderSide(color: AppTheme.borderColor),
                left: BorderSide(color: AppTheme.borderColor),
                right: BorderSide(color: AppTheme.borderColor),
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'TERM NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Vertical Line
                Container(width: 1, height: 20, color: AppTheme.borderColor),
                const Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Text(
                      'NUMBER OF DAYS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Actions space outside table border
        const SizedBox(width: 200),
      ],
    );
  }

  Widget _buildTableRow(int index) {
    final row = _rows[index];
    final isHovered = _hoveredIndex == index;
    final rowId = row['id']?.toString();
    final isDefault = rowId != null && rowId == _currentDefaultId;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: Row(
        key: ValueKey(rowId),
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  left: BorderSide(color: AppTheme.borderColor),
                  right: BorderSide(color: AppTheme.borderColor),
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildEditableCell(index, 'term_name'),
                  ),
                  // Vertical Line
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.borderColor,
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildEditableCell(
                      index,
                      'number_of_days',
                      isNumeric: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  if (isDefault && isHovered)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen, // Green-500
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Default',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  else if (isHovered && rowId != null)
                    TextButton(
                      onPressed: () {
                        setState(() => _currentDefaultId = rowId);
                        widget.onSelect(row);
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Mark as Default',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryBlueDark,
                        ),
                      ),
                    ),
                  if (isHovered) ...[
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () => _deleteRow(index),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.errorRed,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
  }

  Widget _buildEditableCell(int index, String field, {bool isNumeric = false}) {
    final controller = _getController(index, field);
    final isEditing = _editingIndex == index && _editingField == field;

    return GestureDetector(
      onTap: () {
        setState(() {
          _editingIndex = index;
          _editingField = field;
        });
      },
      child: isEditing
          ? TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              keyboardType: isNumeric
                  ? TextInputType.number
                  : TextInputType.text,
              inputFormatters: isNumeric
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                hintText: field == 'term_name' ? 'Net' : '0',
                hintStyle: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: AppTheme.infoBlue,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (value) {
                _rows[index][field] = value;
                _clearError();
              },
              onSubmitted: (_) {
                setState(() {
                  _editingIndex = null;
                  _editingField = null;
                });
              },
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                controller.text,
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
              ),
            ),
    );
  }

  Widget _buildAddNewLink() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: _addNewRow,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_circle, size: 16, color: AppTheme.primaryBlueDark),
            SizedBox(width: 8),
            Text(
              'Add New',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.primaryBlueDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const SizedBox(width: 8), // Match image padding
          ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen, // Green-500
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: const BorderSide(color: AppTheme.borderColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              foregroundColor: AppTheme.textBody,
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
