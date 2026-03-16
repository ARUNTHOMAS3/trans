// // FILE: lib/shared/widgets/inputs/manage_reorder_terms_dialog.dart
// import 'package:flutter/material.dart';

// class ManageReorderTermsDialog extends StatefulWidget {
//   final List<Map<String, dynamic>> items;
//   final String? selectedId;
//   final ValueChanged<dynamic> onSelect;
//   final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)?
//   onSave;
//   final Future<String?> Function(Map<String, dynamic> item)? onDeleteCheck;

//   const ManageReorderTermsDialog({
//     super.key,
//     required this.items,
//     required this.onSelect,
//     this.onSave,
//     this.onDeleteCheck,
//     this.selectedId,
//   });

//   @override
//   State<ManageReorderTermsDialog> createState() =>
//       _ManageReorderTermsDialogState();
// }

// class _ManageReorderTermsDialogState extends State<ManageReorderTermsDialog> {
//   late List<Map<String, dynamic>> _rows;

//   final TextEditingController _nameCtrl = TextEditingController();
//   final TextEditingController _qtyCtrl = TextEditingController();
//   int? _editingIndex;
//   int? _hoverIndex;

//   @override
//   void initState() {
//     super.initState();
//     _rows = widget.items
//         .map((item) => Map<String, dynamic>.from(item))
//         .toList();
//   }

//   void _startEdit(int index) {
//     setState(() {
//       _editingIndex = index;
//       final item = _rows[index];
//       _nameCtrl.text = item['term_name'] ?? item['name'] ?? '';
//       _qtyCtrl.text = item['quantity']?.toString() ?? '0';
//     });
//   }

//   void _cancel() {
//     setState(() {
//       _editingIndex = null;
//       _nameCtrl.clear();
//       _qtyCtrl.clear();
//     });
//   }

//   Future<void> _triggerSync() async {
//     if (widget.onSave != null) {
//       try {
//         await widget.onSave!(_rows);
//       } catch (e) {
//         print('❌ Live Sync Error: $e');
//       }
//     }
//   }

//   Future<void> _saveItem({bool selectAfter = false}) async {
//     final name = _nameCtrl.text.trim();
//     if (name.isEmpty) return;
//     final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;

//     final newItem = {'term_name': name, 'name': name, 'quantity': qty};

//     setState(() {
//       if (_editingIndex == null) {
//         _rows.add(newItem);
//       } else {
//         _rows[_editingIndex!].addAll(newItem);
//       }
//     });

//     final targetIndex = _editingIndex ?? _rows.length - 1;
//     _editingIndex = null;
//     _nameCtrl.clear();
//     _qtyCtrl.clear();

//     if (widget.onSave != null) {
//       try {
//         final updatedRows = await widget.onSave!(_rows);

//         if (context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("Reorder Term saved successfully"),
//               backgroundColor: Colors.green,
//               duration: Duration(seconds: 2),
//             ),
//           );
//         }

//         if (updatedRows.isNotEmpty) {
//           setState(() {
//             _rows = updatedRows;
//           });

//           if (selectAfter) {
//             final matching = updatedRows.firstWhere(
//               (r) => (r['term_name'] ?? r['name']) == name,
//               orElse: () => updatedRows[targetIndex],
//             );
//             _selectAndPop(matching);
//           }
//         } else if (selectAfter) {
//           _selectAndPop(newItem);
//         }
//       } catch (e) {
//         if (selectAfter) _selectAndPop(newItem);
//       }
//     } else if (selectAfter) {
//       _selectAndPop(newItem);
//     }
//   }

//   void _delete(int index) async {
//     final item = _rows[index];

//     if (widget.onDeleteCheck != null) {
//       final error = await widget.onDeleteCheck!(item);
//       if (error != null && mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(error), backgroundColor: Colors.red),
//         );
//         return;
//       }
//     }

//     setState(() {
//       _rows.removeAt(index);
//       if (_editingIndex == index) {
//         _cancel();
//       }
//     });

//     await _triggerSync();
//   }

//   void _selectAndPop(Map<String, dynamic> item) {
//     if (!mounted) return;
//     widget.onSelect(item);
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
//           const Text(
//             'Manage Reorder Terms',
//             style: TextStyle(
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
//           Row(
//             children: [
//               Expanded(
//                 flex: 2,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Term Name*",
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFFE11D48),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       height: 40,
//                       child: TextField(
//                         controller: _nameCtrl,
//                         decoration: const InputDecoration(
//                           isDense: true,
//                           border: OutlineInputBorder(),
//                           filled: true,
//                           fillColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 flex: 1,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Text(
//                       "Qty Added*",
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                         color: Color(0xFF111827),
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       height: 40,
//                       child: TextField(
//                         controller: _qtyCtrl,
//                         keyboardType: TextInputType.number,
//                         decoration: const InputDecoration(
//                           isDense: true,
//                           border: OutlineInputBorder(),
//                           filled: true,
//                           fillColor: Colors.white,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               ElevatedButton(
//                 onPressed: () => _saveItem(selectAfter: true),
//                 style: ElevatedButton.styleFrom(
//                   elevation: 0,
//                   backgroundColor: const Color(0xFF22C55E),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 10,
//                   ),
//                 ),
//                 child: const Text("Save and Select"),
//               ),
//               const SizedBox(width: 10),
//               TextButton(
//                 onPressed: _cancel,
//                 child: const Text(
//                   "Cancel",
//                   style: TextStyle(color: Color(0xFF6B7280)),
//                 ),
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
//       child: Row(
//         children: const [
//           Expanded(
//             child: Text(
//               'TERM NAME',
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 0.4,
//                 color: Color(0xFF6B7280),
//               ),
//             ),
//           ),
//           SizedBox(width: 12),
//           SizedBox(
//             width: 80,
//             child: Text(
//               'QTY',
//               style: TextStyle(
//                 fontSize: 11,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 0.4,
//                 color: Color(0xFF6B7280),
//               ),
//             ),
//           ),
//           SizedBox(width: 80), // For actions
//         ],
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
//         final name = item['term_name'] ?? item['name'] ?? '';
//         final qty = item['quantity']?.toString() ?? '0';
//         final isSelected =
//             item['id'] != null && item['id'] == widget.selectedId;
//         final hovered = _hoverIndex == index;

//         return MouseRegion(
//           onEnter: (_) => setState(() => _hoverIndex = index),
//           onExit: (_) => setState(() => _hoverIndex = null),
//           child: InkWell(
//             onTap: () => _selectAndPop(item),
//             child: Container(
//               height: 44,
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               decoration: BoxDecoration(
//                 color: hovered ? const Color(0xFFF9FAFB) : Colors.white,
//                 border: const Border(
//                   bottom: BorderSide(color: Color(0xFFE5E7EB)),
//                 ),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       name,
//                       style: TextStyle(
//                         fontSize: 13.5,
//                         color: isSelected
//                             ? const Color(0xFF2563EB)
//                             : const Color(0xFF111827),
//                         fontWeight: isSelected
//                             ? FontWeight.w600
//                             : FontWeight.normal,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   SizedBox(
//                     width: 80,
//                     child: Text(
//                       qty,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         color: Color(0xFF4B5563),
//                       ),
//                     ),
//                   ),
//                   if (isSelected)
//                     const Icon(Icons.check, size: 16, color: Color(0xFF2563EB)),
//                   const SizedBox(width: 8),
//                   SizedBox(
//                     width: 72,
//                     child: hovered
//                         ? Row(
//                             mainAxisAlignment: MainAxisAlignment.end,
//                             children: [
//                               IconButton(
//                                 icon: const Icon(
//                                   Icons.edit_outlined,
//                                   size: 16,
//                                   color: Color(0xFF2563EB),
//                                 ),
//                                 onPressed: () => _startEdit(index),
//                                 constraints: const BoxConstraints(),
//                                 padding: const EdgeInsets.all(4),
//                               ),
//                               IconButton(
//                                 icon: const Icon(
//                                   Icons.delete_outline,
//                                   size: 16,
//                                   color: Color(0xFFDC2626),
//                                 ),
//                                 onPressed: () => _delete(index),
//                                 constraints: const BoxConstraints(),
//                                 padding: const EdgeInsets.all(4),
//                               ),
//                             ],
//                           )
//                         : null,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
// FILE: lib/shared/widgets/inputs/manage_reorder_terms_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
      // Don't set _selectedIndex to keep white background
    });
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
              'reorder term',
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

        // Clean data before sending to backend - remove frontend-only fields
        final cleanedRows = _rows.map((row) {
          final cleaned = <String, dynamic>{};

          // Only include database fields
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
          ZerpaiBuilders.showSuccessToast(
            context,
            "Reorder terms have been saved successfully",
          );
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
            _deletedRows.clear(); // Clear deleted items after successful save
          });

          // Close dialog after successful save
          if (mounted && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        debugPrint('❌ Save Error: $e');
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

    // Track deleted item if it has an ID (exists in database)
    if (target['id'] != null) {
      _deletedRows.add(target);
    }

    // Remove from UI immediately
    setState(() {
      _rows.removeAt(index);
      _selectedIndex = null;
      _errorMessage = null; // Clear error if row removed
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
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
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
              style: const TextStyle(
                color: Color(0xFF991B1B),
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _clearError,
            child: const Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
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
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Text(
            'Manage Reorder Terms',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
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

  Widget _buildTable() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1D5DB)),
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
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: const Text(
                'TERM NAME',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFD1D5DB)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: const Text(
                'NUMBER OF UNIT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF6B7280),
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
            border: const Border(bottom: BorderSide(color: Color(0xFFD1D5DB))),
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
              Container(width: 1, height: 40, color: const Color(0xFFD1D5DB)),
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
                          color: Color(0xFFDC2626),
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
              ? Border.all(color: const Color(0xFF2563EB), width: 1.5)
              : null,
          borderRadius: isEditing ? BorderRadius.zero : null,
        ),
        margin: const EdgeInsets.all(
          2,
        ), // Subtle margin so it doesn't touch table borders
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
                style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: 'Extra',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
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
                style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
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
                  color: Color(0xFF2563EB),
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
                  color: Color(0xFF2563EB),
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
              side: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF111827)),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: const Color(0xFF22C55E),
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
