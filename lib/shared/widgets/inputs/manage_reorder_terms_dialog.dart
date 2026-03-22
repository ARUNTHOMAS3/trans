// FILE: lib/shared/widgets/inputs/manage_reorder_terms_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';

class ManageReorderTermsDialog extends StatefulWidget {
  final List<dynamic> items;
  final String? selectedId;
  final ValueChanged<dynamic> onSelect;
  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
  onSave;
  final Future<String?> Function(Map<String, dynamic> item)? onDeleteCheck;

  const ManageReorderTermsDialog({
    super.key,
    required this.items,
    required this.onSelect,
    this.onSave,
    this.onDeleteCheck,
    this.selectedId,
  });

  @override
  State<ManageReorderTermsDialog> createState() =>
      _ManageReorderTermsDialogState();
}

class _ManageReorderTermsDialogState extends State<ManageReorderTermsDialog> {
  late List<Map<String, dynamic>> _rows;
  final List<Map<String, dynamic>> _deletedRows = [];
  bool _isSaving = false;
  int? _selectedIndex;
  int? _editingIndex;
  String? _editingField;
  int? _hoveredIndex;
  final Map<String, TextEditingController> _controllers = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rows = widget.items.map((item) {
      if (item is Map<String, dynamic>) {
        final map = Map<String, dynamic>.from(item);
        if (!map.containsKey('term_name') && map.containsKey('name')) {
          map['term_name'] = map['name'];
        }
        return map;
      }
      return <String, dynamic>{};
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(int index, String field) {
    final key = '$index-$field';
    if (!_controllers.containsKey(key)) {
      final value = _rows[index][field]?.toString() ?? '';
      _controllers[key] = TextEditingController(text: value);
    }
    return _controllers[key]!;
  }

  void _addNewRow() {
    setState(() {
      _rows.add({'term_name': '', 'quantity': '', 'is_new': true});
      _editingIndex = _rows.length - 1;
      _editingField = 'term_name';
    });
  }

  Future<void> _saveChanges() async {
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
              'reorder term',
            );
            _isSaving = false;
          });
        }
        return;
      }
    }

    final seenNames = <String>{};
    for (var i = 0; i < _rows.length; i++) {
      final termName = _rows[i]['term_name']?.toString().trim() ?? '';
      final quantityStr = _rows[i]['quantity']?.toString().trim() ?? '';

      if (termName.isEmpty) {
        _showError('Enter a valid term name.');
        return;
      }

      if (seenNames.contains(termName.toLowerCase())) {
        _showError('The reorder term $termName already exists.');
        return;
      }
      seenNames.add(termName.toLowerCase());

      final quantity = int.tryParse(quantityStr);
      if (quantity == null || quantity <= 0) {
        _showError('Quantity must be greater than 0 at row ${i + 1}');
        return;
      }

      _rows[i]['quantity'] = quantity;
    }

    if (widget.onSave != null) {
      try {
        setState(() => _isSaving = true);

        final cleanedRows = _rows.map((row) {
          final cleaned = <String, dynamic>{};

          if (row['id'] != null) cleaned['id'] = row['id'];
          cleaned['term_name'] = row['term_name'];
          cleaned['quantity'] = row['quantity'];
          if (row['description'] != null)
            cleaned['description'] = row['description'];
          if (row['is_active'] != null) cleaned['is_active'] = row['is_active'];
          if (row['created_at'] != null)
            cleaned['created_at'] = row['created_at'];

          return cleaned;
        }).toList();

        final updatedRows = await widget.onSave!(cleanedRows);

        if (mounted) {
          ZerpaiBuilders.showSavedToast(context, 'Reorder terms');
        }

        if (updatedRows.isNotEmpty) {
          setState(() {
            _rows = updatedRows.map((r) {
              final map = Map<String, dynamic>.from(r);
              if (!map.containsKey('term_name') && map.containsKey('name')) {
                map['term_name'] = map['name'];
              }
              return map;
            }).toList();
            _deletedRows.clear();
          });

          if (mounted && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        AppLogger.error(
          'Save error in ManageReorderTermsDialog',
          error: e,
          module: 'items',
        );
        _showError(ZerpaiBuilders.parseErrorMessage(e, 'reorder term'));
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  void _deleteRow(int index) {
    final target = _rows[index];

    if (target['id'] != null) {
      _deletedRows.add(target);
    }

    setState(() {
      _rows.removeAt(index);
      _selectedIndex = null;
      _errorMessage = null;
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
        constraints: const BoxConstraints(maxWidth: 480),
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
            'Manage Reorder Rules',
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTableHeader(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _rows.length,
                itemBuilder: (context, index) => _buildTableRow(index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: const Text(
                'RULE NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          Container(width: 1, height: 36, color: AppTheme.borderColor),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: const Text(
                'ADDITIONAL UNITS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(int index) {
    final item = _rows[index];
    final isSelected = _selectedIndex == index;
    final isHovered = _hoveredIndex == index;
    final isNewRow = item['is_new'] == true;
    final termName = item['term_name']?.toString() ?? '';
    final quantity = item['quantity']?.toString() ?? '';

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredIndex = index;
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredIndex = null;
        });
      },
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          if (item['id'] != null) {
            widget.onSelect(item);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: (isSelected && !isNewRow)
                ? const Color(0xFFF0F9FF)
                : Colors.white,
            border: const Border(
              bottom: BorderSide(color: AppTheme.borderColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildCell(
                  index: index,
                  field: 'term_name',
                  value: termName,
                  isSelected: isSelected,
                ),
              ),
              Container(width: 1, height: 40, color: AppTheme.borderColor),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildCell(
                        index: index,
                        field: 'quantity',
                        value: quantity,
                        isSelected: isSelected,
                        isNumeric: true,
                      ),
                    ),
                    if (isHovered) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _deleteRow(index),
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: AppTheme.errorRed,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Delete',
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell({
    required int index,
    required String field,
    required String value,
    required bool isSelected,
    bool isNumeric = false,
  }) {
    final isEditing = _editingIndex == index && _editingField == field;

    return GestureDetector(
      onTap: () {
        _clearError();
        setState(() {
          _editingIndex = index;
          _editingField = field;
          _selectedIndex = index;
        });
      },
      child: Container(
        height: 40,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isEditing ? Colors.white : Colors.transparent,
          border: isEditing
              ? Border.all(color: AppTheme.primaryBlueDark, width: 1.5)
              : null,
          borderRadius: isEditing ? BorderRadius.zero : null,
        ),
        margin: const EdgeInsets.all(2),
        child: isEditing
            ? TextField(
                controller: _getController(index, field),
                autofocus: true,
                keyboardType: isNumeric
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: isNumeric
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : null,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Extra',
                  hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                onChanged: (newValue) {
                  _rows[index][field] = newValue;
                },
                onSubmitted: (_) {
                  setState(() {
                    _editingIndex = null;
                    _editingField = null;
                  });
                },
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                ),
              ),
      ),
    );
  }

  Widget _buildAddNewLink() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: _addNewRow,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.primaryBlueDark,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.add, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
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
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              side: const BorderSide(color: AppTheme.borderColor),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
