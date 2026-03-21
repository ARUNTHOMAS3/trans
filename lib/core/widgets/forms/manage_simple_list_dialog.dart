// // FILE: lib/core/widgets/forms/manage_simple_list_dialog.dart
// import 'package:flutter/material.dart';

// class ManageSimpleListDialog extends StatefulWidget {
//   final String title;
//   final String singularLabel;
//   final String headerLabel;
//   final List<dynamic> items; // Can be List<String> or List<Map<String, dynamic>>
//   final String? selectedId;
//   final String labelKey;
//   final ValueChanged<dynamic> onSelect;
//   final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)? onSave;
//   final ValueChanged<List<String>>? onListChanged; // Deprecated but kept for compat

//   const ManageSimpleListDialog({
//     super.key,
//     required this.title,
//     required this.singularLabel,
//     required this.headerLabel,
//     required this.items,
//     required this.onSelect,
//     this.onSave,
//     this.onListChanged,
//     String? selectedId,
//     String? selectedValue, // Compat
//     this.labelKey = 'name',
//   }) : selectedId = selectedId ?? selectedValue;

//   @override
//   State<ManageSimpleListDialog> createState() => _ManageSimpleListDialogState();
// }

// class _ManageSimpleListDialogState extends State<ManageSimpleListDialog> {
//   late List<Map<String, dynamic>> _rows;

//   final TextEditingController _ctrl = TextEditingController();
//   int? _editingIndex;
//   int? _hoverIndex;

//   @override
//   void initState() {
//     super.initState();
//     _rows = widget.items.map((item) {
//       if (item is String) {
//         return {'id': item, widget.labelKey: item, '_isString': true};
//       }
//       final map = Map<String, dynamic>.from(item as Map);
//       // Ensure labelKey is populated so dropdowns show text instead of IDs
//       if (!map.containsKey(widget.labelKey) || (map[widget.labelKey] == null || map[widget.labelKey].toString().isEmpty)) {
//         map[widget.labelKey] = map['name'] ?? map['unit_name'] ?? map['rack_code'] ?? map['location_name'] ?? map['shedule_name'] ?? map['buying_rule'];
//       }
//       return map;
//     }).toList();
//   }

//   void _startEdit(int index) {
//     setState(() {
//       _editingIndex = index;
//       _ctrl.text = _rows[index][widget.labelKey]?.toString() ?? '';
//     });
//   }

//   void _cancel() {
//     setState(() {
//       _editingIndex = null;
//       _ctrl.clear();
//     });
//   }

//   Future<void> _triggerSync() async {
//     if (widget.onSave != null) {
//       try {
//         await widget.onSave!(_rows);
//       } catch (e) {
//         print('❌ Live Sync Error: $e');
//         // We catch here to prevent the UI from breaking,
//         // but the controller already sets state.error
//       }
//     }
//   }

//   Future<void> _saveItem({bool selectAfter = false}) async {
//     final text = _ctrl.text.trim();
//     if (text.isEmpty) return;

//     final newItem = {widget.labelKey: text};

//     // Optimistic Update
//     setState(() {
//       if (_editingIndex == null) {
//         _rows.add(newItem);
//       } else {
//         _rows[_editingIndex!][widget.labelKey] = text;
//       }
//     });

//     final targetIndex = _editingIndex ?? _rows.length - 1;
//     _editingIndex = null;
//     _ctrl.clear();
//     _notifyChanges();

//     if (widget.onSave != null) {
//       try {
//         final updatedRows = await widget.onSave!(_rows);

//         if (context.mounted) {
//            ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("${widget.singularLabel} saved successfully"),
//               backgroundColor: Colors.green,
//               duration: const Duration(seconds: 2),
//             ),
//           );
//         }

//         if (updatedRows.isNotEmpty) {
//           // Update local rows with the ones from server (containing new IDs)
//           setState(() {
//             _rows = updatedRows;
//           });

//           if (selectAfter) {
//             // Find the item with matching name/label to get its ID
//             final matching = updatedRows.firstWhere(
//               (r) => r[widget.labelKey] == text,
//               orElse: () => updatedRows[targetIndex],
//             );
//             _selectAndPop(matching);
//           }
//         } else if (selectAfter) {
//            _selectAndPop(newItem);
//         }
//       } catch (e) {
//         if (selectAfter) _selectAndPop(newItem);
//       }
//     } else if (selectAfter) {
//       _selectAndPop(newItem);
//     }
//   }

//   void _delete(int index) async {
//     final removed = _rows[index];
//     setState(() {
//       _rows.removeAt(index);
//       if (_editingIndex == index) {
//         _cancel();
//       }
//     });

//     _notifyChanges();
//     await _triggerSync();
//   }

//   void _notifyChanges() {
//     if (widget.onListChanged != null) {
//       widget.onListChanged!(
//         _rows.map((r) => r[widget.labelKey].toString()).toList(),
//       );
//     }
//   }

//   void _selectAndPop(Map<String, dynamic> item) {
//     if (!mounted) return;
//     if (item['_isString'] == true) {
//       widget.onSelect(item[widget.labelKey]);
//     } else {
//       widget.onSelect(item);
//     }
//     if (context.mounted) {
//       Navigator.pop(context, item);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       alignment: Alignment.topCenter,
//       insetPadding: const EdgeInsets.fromLTRB(0, 60, 0, 24),
//       child: ConstrainedBox(
//         constraints: const BoxConstraints(maxWidth: 620),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildHeader(),
//             const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
//             Padding(
//               padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildInlineForm(),
//                   const SizedBox(height: 12),
//                   _buildListHeader(),
//                 ],
//               ),
//             ),
//             SizedBox(height: _listHeight(), child: _buildList()),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
//       child: Row(
//         children: [
//           Text(
//             widget.title,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFF111827),
//             ),
//           ),
//           const Spacer(),
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: const Icon(Icons.close, size: 18, color: Color(0xFFE11D48)),
//             splashRadius: 20,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInlineForm() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF8FAFC),
//         borderRadius: BorderRadius.circular(6),
//         border: Border.all(color: const Color(0xFFE5E7EB)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "${widget.singularLabel} Name*",
//             style: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w600,
//               color: Color(0xFFE11D48),
//             ),
//           ),
//           const SizedBox(height: 8),
//           SizedBox(
//             width: double.infinity,
//             height: 40,
//             child: TextField(
//               controller: _ctrl,
//               decoration: const InputDecoration(
//                 isDense: true,
//                 border: OutlineInputBorder(),
//                 filled: true,
//                 fillColor: Colors.white,
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               ElevatedButton(
//                 onPressed: () => _saveItem(selectAfter: true),
//                 style: ElevatedButton.styleFrom(
//                   elevation: 0,
//                   backgroundColor: const Color(0xFF22C55E),
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                 ),
//                 child: const Text("Save and Select"),
//               ),
//               const SizedBox(width: 10),
//               TextButton(
//                 onPressed: _cancel,
//                 child: const Text("Cancel", style: TextStyle(color: Color(0xFF6B7280))),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildListHeader() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//       color: const Color(0xFFF3F4F6),
//       child: Text(
//         widget.headerLabel.toUpperCase(),
//         style: const TextStyle(
//           fontSize: 11,
//           fontWeight: FontWeight.w700,
//           letterSpacing: 0.4,
//           color: Color(0xFF6B7280),
//         ),
//       ),
//     );
//   }

//   double _listHeight() {
//     const double rowHeight = 44.0;
//     const double maxHeight = 400.0;
//     final double height = _rows.length * rowHeight;
//     return height.clamp(44.0, maxHeight);
//   }

//   Widget _buildList() {
//     return ListView.builder(
//       itemCount: _rows.length,
//       itemBuilder: (context, index) {
//         final item = _rows[index];
//         final label = item[widget.labelKey]?.toString() ?? '';
//         final isSelected = item['id'] != null && item['id'] == widget.selectedId;
//         final hovered = _hoverIndex == index;

//         return MouseRegion(
//           onEnter: (_) => setState(() => _hoverIndex = index),
//           onExit: (_) => setState(() => _hoverIndex = null),
//           child: InkWell(
//             onTap: () => _selectAndPop(item),
//             child: Container(
//               height: 44,
//               padding: const EdgeInsets.symmetric(horizontal: 24),
//               decoration: BoxDecoration(
//                 color: hovered ? const Color(0xFFF9FAFB) : Colors.white,
//                 border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       label,
//                       style: TextStyle(
//                         fontSize: 13.5,
//                         color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF111827),
//                         fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                       ),
//                     ),
//                   ),
//                   if (isSelected)
//                     const Icon(Icons.check, size: 16, color: Color(0xFF2563EB)),
//                   if (hovered) ...[
//                     IconButton(
//                       icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF2563EB)),
//                       onPressed: () => _startEdit(index),
//                       constraints: const BoxConstraints(),
//                       padding: const EdgeInsets.all(8),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFDC2626)),
//                       onPressed: () => _delete(index),
//                       constraints: const BoxConstraints(),
//                       padding: const EdgeInsets.all(8),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
// FILE: lib/core/widgets/forms/manage_simple_list_dialog.dart
import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/widgets/forms/zerpai_builders.dart';

class ManageSimpleListDialog extends StatefulWidget {
  final String title;
  final String singularLabel;
  final String headerLabel;
  final List<dynamic>
  items; // Can be List<String> or List<Map<String, dynamic>>
  final String? selectedId;
  final String labelKey;
  final ValueChanged<dynamic> onSelect;
  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
  onSave;
  final ValueChanged<List<String>>?
  onListChanged; // Deprecated but kept for compat
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

  @override
  void initState() {
    super.initState();
    // Add listener to filter list as user types (only when not editing)
    _ctrl.addListener(() {
      if (_editingIndex == null) {
        setState(() {
          _filterText = _ctrl.text.toLowerCase();
        });
      }
    });
    _rows = widget.items.map((item) {
      if (item is String) {
        return {'id': item, widget.labelKey: item, '_isString': true};
      }
      final map = Map<String, dynamic>.from(item as Map);
      // Ensure labelKey is populated so dropdowns show text instead of IDs
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
            map['account_name'] ??
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

    // ✅ If selectedId provided, start editing that item automatically
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
      _filterText = ''; // Clear filter when editing
      _ctrl.text = _rows[index][widget.labelKey]?.toString() ?? '';
    });
  }

  void _cancel() {
    setState(() {
      _editingIndex = null;
      _filterText = ''; // Clear filter when canceling
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
          ZerpaiBuilders.showSuccessToast(
            context,
            "${widget.singularLabel} has been saved successfully",
          );
        }

        if (updatedRows.isNotEmpty) {
          setState(() {
            _rows = updatedRows.map((r) {
              final map = Map<String, dynamic>.from(r);
              // Ensure labelKey is populated
              if (!map.containsKey(widget.labelKey) ||
                  map[widget.labelKey] == null) {
                map[widget.labelKey] = map['name'] ?? map['id'];
              }
              return map;
            }).toList();
            _deletedRows.clear();
          });

          // Find the saved item in the updated rows
          Map<String, dynamic>? savedItem;
          if (itemToSelect != null) {
            final labelToFind = itemToSelect[widget.labelKey];
            savedItem = _rows.firstWhere(
              (row) => row[widget.labelKey] == labelToFind,
              orElse: () => _rows.last, // Fallback to last item
            );
          }

          if (mounted && context.mounted) {
            // Return both the saved item and updated rows
            Navigator.pop(context, {
              'savedItem': savedItem,
              'updatedRows': _rows,
            });
          }
        }
      } catch (e) {
        debugPrint('❌ Save Error: $e');
        setState(() => _errorMessage = 'Failed to save: $e');
      }
    } else {
      Navigator.pop(context);
    }
  }

  void _saveItem({bool selectAfter = false}) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    // Duplicate check
    final isDuplicate = _rows.any((row) {
      final index = _rows.indexOf(row);
      if (_editingIndex == index) return false; // Skip itself if editing

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
        // Adding new item
        final newItem = {widget.labelKey: text, 'id': null};
        _rows.add(newItem);
        itemToSelect = newItem;
      } else {
        // Editing existing item
        _rows[_editingIndex!][widget.labelKey] = text;
        itemToSelect = _rows[_editingIndex!];
      }
      _editingIndex = null;
      _filterText = ''; // Clear filter to show the new item
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

    // Check if item can be deleted
    if (widget.onDeleteCheck != null && target['id'] != null) {
      final blockReason = await widget.onDeleteCheck!(target);
      if (blockReason != null && blockReason.isNotEmpty) {
        // Show error message
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

    // Show success message
    if (mounted) {
      ZerpaiBuilders.showSuccessToast(
        context,
        '${widget.singularLabel} has been deleted successfully',
      );
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
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
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
              color: const Color(0xFF111827),
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFFE11D48)),
            splashRadius: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumErrorAlert() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFEE2E2)),
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
              color: const Color(0xFFEF4444),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineForm() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "${widget.singularLabel} Name*",
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFE11D48),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
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
                  backgroundColor: const Color(0xFF22C55E),
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
                    color: const Color(0xFF6B7280),
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
      color: const Color(0xFFF3F4F6),
      child: Text(
        widget.headerLabel.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  double _listHeight() {
    const double rowHeight = 44.0;
    const double maxHeight = 400.0;

    // Calculate based on filtered rows
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
    // Filter rows based on search text
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
            color: const Color(0xFF9CA3AF),
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredRows.length,
      itemBuilder: (context, filteredIndex) {
        final item = filteredRows[filteredIndex];
        // Find the original index in _rows for edit/delete operations
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
                color: hovered ? const Color(0xFFF9FAFB) : Colors.white,
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13.5,
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  if (hovered) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      onPressed: () => _startEdit(originalIndex),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 16,
                        color: Color(0xFFDC2626),
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
