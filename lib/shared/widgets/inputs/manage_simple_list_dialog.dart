import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';

class ManageSimpleListDialog extends StatefulWidget {
  final String title;
  final String singularLabel;
  final String headerLabel;
  final List<dynamic> items; // Can be List<String> or List<Map<String, dynamic>>
  final String? selectedId;
  final String labelKey;
  final ValueChanged<dynamic> onSelect;
  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
  onSave;
  final ValueChanged<List<String>>? onListChanged; // Deprecated but kept for compat
  final Future<String?> Function(Map<String, dynamic> item)? onDeleteCheck;

  const ManageSimpleListDialog({
    super.key,
    required this.title,
    required this.singularLabel,
    required this.headerLabel,
    required this.items,
    required this.onSelect,
    this.onSave,
    this.onListChanged,
    this.onDeleteCheck,
    String? selectedId,
    String? selectedValue, // Compat
    this.labelKey = 'name',
  }) : selectedId = selectedId ?? selectedValue;

  @override
  State<ManageSimpleListDialog> createState() => _ManageSimpleListDialogState();
}

class _ManageSimpleListDialogState extends State<ManageSimpleListDialog> {
  late List<Map<String, dynamic>> _rows;
  String _filterText = '';

  final TextEditingController _ctrl = TextEditingController();
  int? _editingIndex;
  int? _hoverIndex;
  final List<Map<String, dynamic>> _deletedRows = [];
  String? _errorMessage;

  List<Map<String, dynamic>> _processItems(List<dynamic> items) {
    return items.map((item) {
      if (item is String) {
        return {'id': item, widget.labelKey: item, '_isString': true};
      }
      final map = Map<String, dynamic>.from(item as Map);
      if (!map.containsKey(widget.labelKey) ||
          (map[widget.labelKey] == null ||
              map[widget.labelKey].toString().isEmpty)) {
        map[widget.labelKey] =
            map['name'] ??
            map['unit_name'] ??
            map['rack_code'] ??
            map['location_name'] ??
            map['shedule_name'] ??
            map['buying_rule'] ??
            map['item_rule'] ??
            map['rule_name'] ??
            map['term_name'] ??
            map['system_account_name'] ??
            map['vendor_name'] ??
            map['brand_name'] ??
            map['manufacturer_name'] ??
            map['content_name'] ??
            map['item_content'] ??
            map['strength_name'] ??
            map['item_strength'] ??
            map['id'];
      }
      return map;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      if (_editingIndex == null) {
        setState(() {
          _filterText = _ctrl.text.toLowerCase();
        });
      }
    });

    _rows = _processItems(widget.items);

    if (widget.selectedId != null) {
      final index = _rows.indexWhere((r) => r['id'] == widget.selectedId);
      if (index != -1) {
        _editingIndex = index;
        _ctrl.text = _rows[index][widget.labelKey]?.toString() ?? '';
      }
    }
  }

  void _startEdit(int index) {
    setState(() {
      _editingIndex = index;
      _filterText = '';
      _ctrl.text = _rows[index][widget.labelKey]?.toString() ?? '';
    });
  }

  void _cancel() {
    setState(() {
      _editingIndex = null;
      _filterText = '';
      _ctrl.clear();
    });
  }

  Future<void> _saveChanges({Map<String, dynamic>? itemToSelect}) async {
    if (widget.onDeleteCheck != null && _deletedRows.isNotEmpty) {
      for (var deletedItem in _deletedRows) {
        if (deletedItem['id'] != null) {
          final blockReason = await widget.onDeleteCheck!(deletedItem);
          if (blockReason != null && blockReason.isNotEmpty) {
            if (mounted) {
              setState(() {
                _errorMessage = blockReason;
              });
            }
            return;
          }
        }
      }
    }

    if (widget.onSave != null) {
      try {
        final updatedRows = await widget.onSave!(_rows);

        if (mounted) {
          ZerpaiBuilders.showSavedToast(context, widget.singularLabel);
        }

        if (updatedRows.isNotEmpty) {
          setState(() {
            _rows = _processItems(updatedRows);
            _deletedRows.clear();
          });

          Map<String, dynamic>? savedItem;
          if (itemToSelect != null) {
            final labelToFind = itemToSelect[widget.labelKey];
            savedItem = _rows.firstWhere(
              (row) => row[widget.labelKey] == labelToFind,
              orElse: () => _rows.last,
            );
          }

          if (mounted && context.mounted) {
            Navigator.pop(context, {
              'savedItem': savedItem,
              'updatedRows': _rows,
            });
          }
        }
      } catch (e) {
        AppLogger.error('Save error in ManageSimpleListDialog', error: e, module: 'items');
        setState(() {
          _errorMessage = ZerpaiBuilders.parseErrorMessage(
            e,
            widget.singularLabel,
          );
        });
      }
    } else {
      Navigator.pop(context);
    }
  }

  void _saveItem({bool selectAfter = false}) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final isDuplicate = _rows.any((row) {
      final index = _rows.indexOf(row);
      if (_editingIndex == index) return false;
      final label = row[widget.labelKey]?.toString().toLowerCase().trim() ?? '';
      return label == text.toLowerCase();
    });

    if (isDuplicate) {
      setState(() {
        _errorMessage =
            'The ${widget.singularLabel.toLowerCase()} $text already exists.';
      });
      return;
    }

    Map<String, dynamic>? itemToSelect;

    setState(() {
      if (_editingIndex == null) {
        final newItem = {widget.labelKey: text, 'id': null};
        _rows.add(newItem);
        itemToSelect = newItem;
      } else {
        _rows[_editingIndex!][widget.labelKey] = text;
        itemToSelect = _rows[_editingIndex!];
      }
      _editingIndex = null;
      _filterText = '';
      _ctrl.clear();
      _errorMessage = null;
    });

    _notifyChanges();

    if (selectAfter) {
      await _saveChanges(itemToSelect: itemToSelect);
    }
  }

  Future<void> _delete(int index) async {
    final target = _rows[index];

    if (widget.onDeleteCheck != null && target['id'] != null) {
      final blockReason = await widget.onDeleteCheck!(target);
      if (blockReason != null && blockReason.isNotEmpty) {
        setState(() {
          _errorMessage = blockReason;
        });
        return;
      }
    }

    setState(() {
      if (target['id'] != null) {
        _deletedRows.add(target);
      }
      _rows.removeAt(index);
      if (_editingIndex == index) {
        _cancel();
      }
      _errorMessage = null;
    });

    _notifyChanges();

    if (mounted) {
      ZerpaiBuilders.showDeletedToast(context, widget.singularLabel);
    }
  }

  void _notifyChanges() {
    if (widget.onListChanged != null) {
      widget.onListChanged!(
        _rows.map((r) => r[widget.labelKey].toString()).toList(),
      );
    }
  }

  void _selectAndPop(Map<String, dynamic> item) {
    if (!mounted) return;
    if (item['_isString'] == true) {
      widget.onSelect(item[widget.labelKey]);
    } else {
      widget.onSelect(item);
    }
    if (context.mounted) {
      Navigator.pop(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (_errorMessage != null) _buildPremiumErrorAlert(),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInlineForm(),
                  const SizedBox(height: 12),
                  _buildListHeader(),
                ],
              ),
            ),
            SizedBox(height: _listHeight(), child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
      child: Row(
        children: [
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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

  Widget _buildPremiumErrorAlert() {
    return ZerpaiBuilders.buildErrorAlert(
      context: context,
      message: _errorMessage!,
      onClose: () => setState(() => _errorMessage = null),
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
    );
  }

  Widget _buildInlineForm() {
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
          Text(
            "${widget.singularLabel} Name*",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.errorRed,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.zero,
                  borderSide: BorderSide(color: AppTheme.primaryBlueDark, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _saveItem(selectAfter: true),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: AppTheme.successGreen,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: Text(
                  _editingIndex == null ? "Save and Select" : "Update",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: _cancel,
                child: Text(
                  "Cancel",
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: AppTheme.bgDisabled,
      child: Text(
        widget.headerLabel.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  double _listHeight() {
    const double rowHeight = 44.0;
    const double maxHeight = 400.0;

    final filteredCount = _filterText.isEmpty
        ? _rows.length
        : _rows.where((item) {
            final label = item[widget.labelKey]?.toString().toLowerCase() ?? '';
            return label.contains(_filterText);
          }).length;

    final double height = filteredCount * rowHeight;
    return height.clamp(44.0, maxHeight);
  }

  Widget _buildList() {
    final filteredRows = _filterText.isEmpty
        ? _rows
        : _rows.where((item) {
            final label = item[widget.labelKey]?.toString().toLowerCase() ?? '';
            return label.contains(_filterText);
          }).toList();

    if (filteredRows.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          _filterText.isEmpty
              ? 'No items found'
              : 'No items match "$_filterText"',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredRows.length,
      itemBuilder: (context, filteredIndex) {
        final item = filteredRows[filteredIndex];
        final originalIndex = _rows.indexOf(item);
        final label = item[widget.labelKey]?.toString() ?? '';
        final hovered = _hoverIndex == originalIndex;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoverIndex = originalIndex),
          onExit: (_) => setState(() => _hoverIndex = null),
          child: InkWell(
            onTap: () => _selectAndPop(item),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: hovered ? AppTheme.bgLight : Colors.white,
                border: const Border(
                  bottom: BorderSide(color: AppTheme.borderColor),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hovered) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppTheme.primaryBlueDark,
                      ),
                      onPressed: () => _startEdit(originalIndex),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: AppTheme.errorRed,
                      ),
                      onPressed: () => _delete(originalIndex),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
