// FILE: lib/shared/widgets/inputs/manage_list_dialog.dart
import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/inputs/manage_simple_list_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

/// First-level dialog that shows a list of items with + New button
/// Clicking + New or Edit opens the ManageSimpleListDialog
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
  final Future<String?> Function(Map<String, dynamic> item)? onDeleteCheck;

  const ManageListDialog({
    super.key,
    required this.title,
    required this.singularLabel,
    required this.headerLabel,
    required this.items,
    required this.onSelect,
    this.onSave,
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
    _rows = []; // Initialize to empty first
    _updateInternalRows(); // Reuse logic
  }

  Future<void> _openFormDialog({Map<String, dynamic>? editItem}) async {
    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => ManageSimpleListDialog(
        title: widget.title,
        singularLabel: widget.singularLabel,
        headerLabel: widget.headerLabel,
        items: _rows,
        selectedId: editItem?['id'],
        onSelect: (value) {
          // This will be called when user clicks an item in the nested dialog
          if (value is Map) {
            widget.onSelect(value['id'] ?? value);
          } else if (value is String) {
            widget.onSelect(value);
          }
        },
        onSave: widget.onSave,
        onDeleteCheck: widget.onDeleteCheck,
        labelKey: widget.labelKey,
      ),
    );

    // After nested dialog closes, refresh the list and select the item
    if (result != null && mounted) {
      // Extract saved item and updated rows from result
      Map<String, dynamic>? savedItem;
      List<Map<String, dynamic>>? updatedRows;

      // Check if this is the new format with savedItem and updatedRows
      if (result.containsKey('savedItem') &&
          result.containsKey('updatedRows')) {
        savedItem = result['savedItem'] as Map<String, dynamic>?;
        updatedRows = (result['updatedRows'] as List?)
            ?.cast<Map<String, dynamic>>();
      } else {
        // Old format - just the saved item
        savedItem = result;
      }

      // Update the list if we have updated rows
      if (updatedRows != null && updatedRows.isNotEmpty) {
        setState(() {
          _rows = _processItems(updatedRows!);
        });
      }

      // Call onSelect to populate the field - extract ID from Map
      if (savedItem != null) {
        widget.onSelect(savedItem['id'] ?? savedItem);
      } else if (result is String) {
        widget.onSelect(result);
      }

      // Close this dialog too and pass the saved item back
      Navigator.pop(context, savedItem ?? result);
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
        onTap: () => _openFormDialog(),
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
                border: const Border(
                  bottom: BorderSide(color: AppTheme.borderColor, width: 0.5),
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
                      onPressed: () => _openFormDialog(editItem: item),
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
