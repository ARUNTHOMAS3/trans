// FILE: lib/shared/widgets/inputs/manage_list_dialog.dart
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// First-level dialog that shows a list of items with + New button
/// Now supports inline create/edit form instead of nested popover
class ManageListDialog extends StatefulWidget {
  final String title;
  final String singularLabel;
  final String headerLabel;
  final List<dynamic> items;
  final String? selectedId;
  final String labelKey;
  final ValueChanged<dynamic> onSelect;
  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
  onSave;
  final Future<Map<String, dynamic>> Function(String name)? onCreateOne;
  final Future<String?> Function(Map<String, dynamic> item)? onDeleteCheck;

  const ManageListDialog({
    super.key,
    required this.title,
    required this.singularLabel,
    required this.headerLabel,
    required this.items,
    required this.onSelect,
    this.onSave,
    this.onCreateOne,
    this.onDeleteCheck,
    String? selectedId,
    this.labelKey = 'name',
  }) : selectedId = selectedId;

  @override
  State<ManageListDialog> createState() => _ManageListDialogState();
}

class _ManageListDialogState extends State<ManageListDialog> {
  late List<Map<String, dynamic>> _rows;
  int? _hoverIndex;
  String? _errorMessage;


  // Inline form state
  bool _showInlineForm = false;
  final TextEditingController _ctrl = TextEditingController();
  int? _editingIndex;

  @override
  void didUpdateWidget(ManageListDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _updateInternalRows();
    }
  }

  List<Map<String, dynamic>> _processItems(List<dynamic> items) {
    return items.map((item) {
      if (item is String) {
        return {'id': item, widget.labelKey: item, '_isString': true};
      }
      final map = Map<String, dynamic>.from(item as Map);
      // Ensure labelKey is populated
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

  void _updateInternalRows() {
    setState(() {
      _rows = _processItems(widget.items);
    });
  }

  @override
  void initState() {
    super.initState();
    _rows = [];
    _updateInternalRows();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _startEdit(int index) {
    setState(() {
      _showInlineForm = true;
      _editingIndex = index;
      _ctrl.text = _rows[index][widget.labelKey]?.toString() ?? '';
      _errorMessage = null;
    });
  }

  void _cancel() {
    setState(() {
      _showInlineForm = false;
      _editingIndex = null;
      _ctrl.clear();
      _errorMessage = null;
    });
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
            'The ${widget.singularLabel.toLowerCase()} "$text" already exists.';
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
      _showInlineForm = false;
      _editingIndex = null;
      _ctrl.clear();
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

        if (mounted) {
          ZerpaiBuilders.showSavedToast(context, widget.singularLabel);
        }

        if (updatedRows.isNotEmpty) {
          setState(() {
            _rows = _processItems(updatedRows);
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
            final valueToReturn = savedItem ?? itemToSelect ?? _rows.last;
            widget.onSelect(valueToReturn);
            Navigator.pop(context, valueToReturn);
          }
        }
      } catch (e) {
        AppLogger.error('Save error in ManageListDialog', error: e, module: 'purchases');
        setState(() {
          _errorMessage = ZerpaiBuilders.parseErrorMessage(
            e,
            widget.singularLabel,
          );
        });
      }
    } else {
      if (mounted && context.mounted) {
        final valueToReturn = itemToSelect ?? _rows.last;
        widget.onSelect(valueToReturn);
        Navigator.pop(context, valueToReturn);
      }
    }
  }

  void _selectAndClose(Map<String, dynamic> item) {
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
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
            if (_errorMessage != null)
              ZerpaiBuilders.buildErrorAlert(
                context: context,
                message: _errorMessage!,
                onClose: () => setState(() => _errorMessage = null),
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              ),
            if (_showInlineForm)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: _buildInlineForm(),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: _buildNewButton(),
              ),
            _buildListHeader(),
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



  Widget _buildNewButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () {
          setState(() {
            _showInlineForm = true;
            _editingIndex = null;
            _ctrl.clear();
            _errorMessage = null;
          });
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.accentGreen,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          child: Text(
            '+ New ${widget.singularLabel}',
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
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
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppTheme.primaryBlueDark, width: 1.5),
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
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  _editingIndex == null ? "Save and Select" : "Update",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    color: Colors.white,
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
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      color: AppTheme.bgLight,
      child: Text(
        widget.headerLabel.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  double _listHeight() {
    const double rowHeight = 44.0;
    const double maxHeight = 400.0;
    final double height = _rows.length * rowHeight;
    return height.clamp(44.0, maxHeight);
  }

  Widget _buildList() {
    if (_rows.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        child: Text(
          'No ${widget.headerLabel.toLowerCase()} found',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _rows.length,
      itemBuilder: (context, index) {
        final item = _rows[index];
        final label = item[widget.labelKey]?.toString() ?? '';
        final hovered = _hoverIndex == index;

        return MouseRegion(
          onEnter: (_) => setState(() => _hoverIndex = index),
          onExit: (_) => setState(() => _hoverIndex = null),
          child: InkWell(
            onTap: () => _selectAndClose(item),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: hovered ? AppTheme.bgLight : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: index == _rows.length - 1 ? Colors.transparent : AppTheme.borderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppTheme.textBody,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hovered) ...[
                    TextButton.icon(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: AppTheme.primaryBlueDark,
                      ),
                      label: Text(
                        'Edit',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 13,
                          color: AppTheme.primaryBlueDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () => _startEdit(index),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 14,
                        color: AppTheme.errorRed,
                      ),
                      label: Text(
                        'Delete',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 13,
                          color: AppTheme.errorRed,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onPressed: () async {
                        // Handle delete with confirmation
                        if (widget.onDeleteCheck != null &&
                            item['id'] != null) {
                          final blockReason = await widget.onDeleteCheck!(item);
                          if (blockReason != null && blockReason.isNotEmpty) {
                            if (mounted) {
                              setState(() {
                                _errorMessage = blockReason;
                              });
                            }
                            return;
                          }
                        }

                        // Proceed with delete
                        // Keep backup for potential restore
                        final backupRows = List<Map<String, dynamic>>.from(
                          _rows,
                        );

                        // Optimistically remove
                        setState(() {
                          _rows.removeAt(index);
                          _errorMessage = null;
                        });

                        // Save changes
                        if (widget.onSave != null) {
                          try {
                            final updatedRows = await widget.onSave!(_rows);
                            if (mounted) {
                              setState(() {
                                _rows = _processItems(updatedRows);
                              });
                              ZerpaiBuilders.showDeletedToast(
                                context,
                                widget.singularLabel,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                // Restore from backup on error
                                _rows = backupRows;
                                _errorMessage =
                                    ZerpaiBuilders.parseErrorMessage(
                                      e,
                                      widget.singularLabel,
                                    );
                              });
                            }
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
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
