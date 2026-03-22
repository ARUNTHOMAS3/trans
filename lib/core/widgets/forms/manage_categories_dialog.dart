import 'package:flutter/material.dart';
import 'package:zerpai_erp/core/widgets/forms/category_dropdown.dart'
    show CategoryNode;
import 'package:zerpai_erp/core/widgets/forms/dropdown_input.dart';

/// Dialog used when clicking "Manage Categories" from the Category dropdown.
/// zerpai-like folder tree with hover actions and dynamic height.
class ManageCategoriesDialog extends StatefulWidget {
  final List<CategoryNode> nodes;
  final List<Map<String, dynamic>> flatList; // For saving back to backend
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryApplied;

  /// Callback to save changes (add/edit/delete).
  /// Should return the full updated flat list from backend.
  final Future<List<Map<String, dynamic>>> Function(List<Map<String, dynamic>>)
  onSave;

  const ManageCategoriesDialog({
    super.key,
    required this.nodes,
    required this.flatList,
    required this.selectedCategory,
    required this.onCategoryApplied,
    required this.onSave,
  });

  @override
  State<ManageCategoriesDialog> createState() => _ManageCategoriesDialogState();
}

class _ManageCategoriesDialogState extends State<ManageCategoriesDialog> {
  late Set<String> _expandedIds;
  String? _hoveredId;
  bool _showForm = false;
  CategoryNode? _editingNode;
  final TextEditingController _nameCtrl = TextEditingController();
  String? _selectedParentId;
  bool _isSaving = false;
  String? _errorMessage;
  late List<CategoryNode> _nodes;
  late List<Map<String, dynamic>> _flatList;

  @override
  void initState() {
    super.initState();
    _nodes = widget.nodes;
    _flatList = List<Map<String, dynamic>>.from(widget.flatList);
    _expandedIds = _nodes.map((n) => n.id).toSet();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _showForm = false;
      _editingNode = null;
      _nameCtrl.clear();
      _selectedParentId = null;
      _errorMessage = null;
    });
  }

  void _startAdd() {
    setState(() {
      _showForm = true;
      _editingNode = null;
      _nameCtrl.clear();
      _selectedParentId = null;
    });
  }

  void _startEdit(CategoryNode node) {
    setState(() {
      _showForm = true;
      _editingNode = node;
      _nameCtrl.text = node.name;
      _selectedParentId = node.parentId;
    });
  }

  Future<void> _saveCategory() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final List<Map<String, dynamic>> updatedFlatList = List.from(_flatList);
      if (_editingNode == null) {
        updatedFlatList.add({
          'id': null,
          'name': name,
          'parent_id': _selectedParentId,
          'is_active': true,
        });
      } else {
        final index = updatedFlatList.indexWhere(
          (item) => item['id'] == _editingNode!.id,
        );
        if (index != -1) {
          updatedFlatList[index] = {
            ...updatedFlatList[index],
            'name': name,
            'parent_id': _selectedParentId,
          };
        }
      }
      final newList = await widget.onSave(updatedFlatList);
      if (mounted) {
        setState(() {
          _flatList = newList;
          _nodes = CategoryNode.fromFlatList(newList);
          _isSaving = false;
          _resetForm();
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isSaving = false;
          _errorMessage = e.toString();
        });
    }
  }

  Future<void> _deleteCategory(CategoryNode node) async {
    if (node.children.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete a category that has sub-categories'),
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final List<Map<String, dynamic>> updatedFlatList = _flatList
          .where((item) => item['id'] != node.id)
          .toList();
      final newList = await widget.onSave(updatedFlatList);
      if (mounted) {
        setState(() {
          _flatList = newList;
          _nodes = CategoryNode.fromFlatList(newList);
          _isSaving = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(
        top: 0,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 650),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const Divider(height: 32),
              if (_showForm) ...[_buildForm(), const SizedBox(height: 32)],
              _buildTreeHeader(),
              const SizedBox(height: 16),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              _buildTreeList(),
              const Divider(height: 48),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Text(
            'Manage Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          if (!_showForm)
            ElevatedButton.icon(
              onPressed: _startAdd,
              icon: const Icon(Icons.add, size: 18),
              label: const Text(
                'Add New Category',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: Color(0xFF64748B)),
            hoverColor: const Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final List<Map<String, dynamic>> options = _flattenTreeForSelection(
      _nodes,
      0,
    );
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Light grey fill from Image 3
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Name*',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFEF4444),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
              fillColor: Colors.white,
              filled: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Parent Category',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FormDropdown<String>(
            value: _selectedParentId,
            items: options.map((o) => o['id'] as String).toList(),
            allowClear: true,
            hint: 'None (Root Category)',
            onChanged: (id) => setState(() => _selectedParentId = id),
            displayStringForValue: (id) {
              final it = _flatList.firstWhere(
                (i) => i['id'] == id,
                orElse: () => {'name': id},
              );
              return (it['name'] as String).toUpperCase();
            },
            itemBuilder: (id, isSelected, isHovered) {
              final opt = options.firstWhere((o) => o['id'] == id);
              final depth = opt['depth'] as int;
              return Container(
                padding: EdgeInsets.only(left: (depth * 16.0) + 12),
                height: 40,
                alignment: Alignment.centerLeft,
                color: isHovered ? const Color(0xFFF1F5F9) : Colors.transparent,
                child: Text(
                  (opt['name'] as String).toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: depth == 0 ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF1E293B),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton(
                onPressed: _isSaving ? null : _saveCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF10B981,
                  ), // Green from Image 3
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  minimumSize: const Size(100, 40),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _editingNode == null ? 'Save' : 'Update',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: _resetForm,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _flattenTreeForSelection(
    List<CategoryNode> nodes,
    int depth,
  ) {
    final List<Map<String, dynamic>> flat = [];
    for (final node in nodes) {
      if (_editingNode?.id == node.id) continue;
      flat.add({'id': node.id, 'name': node.name, 'depth': depth});
      flat.addAll(_flattenTreeForSelection(node.children, depth + 1));
    }
    return flat;
  }

  Widget _buildTreeHeader() {
    return const Text(
      'CATEGORIES',
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildTreeList() {
    return Column(
      children: _nodes
          .asMap()
          .entries
          .map((e) => _buildNode(e.value, 0, [], e.key == _nodes.length - 1))
          .toList(),
    );
  }

  Widget _buildNode(
    CategoryNode node,
    int depth,
    List<bool> parentHasNext,
    bool isLast,
  ) {
    final bool isExpanded = _expandedIds.contains(node.id);
    final bool isHovered = _hoveredId == node.id;
    final bool hasChildren = node.children.isNotEmpty;
    final bool isRoot = depth == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredId = node.id),
          onExit: (_) => setState(() => _hoveredId = null),
          child: InkWell(
            onHover: (hovering) {
              if (hovering)
                setState(() => _hoveredId = node.id);
              else
                setState(() => _hoveredId = null);
            },
            onTap: () {
              if (hasChildren) {
                setState(() {
                  if (isExpanded)
                    _expandedIds.remove(node.id);
                  else
                    _expandedIds.add(node.id);
                });
              }
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isHovered ? const Color(0xFFF8FAFC) : Colors.transparent,
              ),
              child: Row(
                children: [
                  // Tree Lines Structure
                  SizedBox(
                    width: (depth * 32.0) + 16,
                    child: Stack(
                      children: [
                        // Vertical lines for previous levels
                        for (int i = 0; i < depth; i++)
                          if (parentHasNext[i])
                            Positioned(
                              left: (i * 32.0) + 7,
                              top: 0,
                              bottom: 0,
                              child: Container(
                                width: 1,
                                color: const Color(0xFFCBD5E1),
                              ),
                            ),
                        // Current level T/L line
                        if (depth > 0) ...[
                          Positioned(
                            left: ((depth - 1) * 32.0) + 7,
                            top: 0,
                            bottom: isLast ? 22 : 0,
                            child: Container(
                              width: 1,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                          Positioned(
                            left: ((depth - 1) * 32.0) + 7,
                            top: 22,
                            child: Container(
                              width: 16,
                              height: 1,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Folder Icon (Only for roots)
                  if (isRoot) ...[
                    Icon(
                      isExpanded ? Icons.folder_open : Icons.folder,
                      size: 18,
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Text and Expansion Arrow
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          isRoot ? node.name.toUpperCase() : node.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isRoot
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isHovered
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF475569),
                          ),
                        ),
                        if (hasChildren) ...[
                          const SizedBox(width: 4),
                          Icon(
                            isExpanded
                                ? Icons.arrow_drop_down
                                : Icons.arrow_right,
                            size: 22,
                            color: const Color(
                              0xFF334155,
                            ), // Darker for better visibility
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Hover Actions
                  if (isHovered) ...[
                    InkWell(
                      onTap: () {
                        widget.onCategoryApplied(node.id);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Apply this Category',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => _startEdit(node),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _deleteCategory(node),
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
        if (isExpanded && hasChildren)
          ...node.children.asMap().entries.map((e) {
            final childIsLast = e.key == node.children.length - 1;
            return _buildNode(e.value, depth + 1, [
              ...parentHasNext,
              !isLast,
            ], childIsLast);
          }),
      ],
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9), // Grey from Image 2
            foregroundColor: const Color(0xFF334155),
            elevation: 0,
            minimumSize: const Size(100, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
