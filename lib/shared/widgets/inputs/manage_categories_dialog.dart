import 'package:flutter/material.dart';
import 'package:zerpai_erp/shared/widgets/inputs/category_dropdown.dart'
    show CategoryNode;
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_builders.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

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
        final isAdding = _editingNode == null;
        setState(() {
          _flatList = newList;
          _nodes = CategoryNode.fromFlatList(newList);
          _isSaving = false;
          _resetForm();
        });

        ZerpaiBuilders.showSuccessToast(
          context,
          isAdding
              ? 'Category added successfully'
              : 'Category updated successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = _parseError(e);
        });
      }
    }
  }

  Future<void> _deleteCategory(CategoryNode node) async {
    // Clear any previous error messages
    setState(() => _errorMessage = null);

    // Check for subcategories
    if (node.children.isNotEmpty) {
      setState(() {
        _errorMessage =
            'You have to delete the subcategories first to delete the parent category.';
      });
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
          _errorMessage = null;
        });
        ZerpaiBuilders.showSuccessToast(
          context,
          'Category deleted successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = _parseError(e);
        });
      }
    }
  }

  String _parseError(dynamic e) {
    return ZerpaiBuilders.parseErrorMessage(e, 'category');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(
        top: 0,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 650,
          maxHeight:
              MediaQuery.of(context).size.height *
              0.85, // Max 85% of screen height
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- FIXED TOP PART ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  if (_errorMessage != null)
                    ZerpaiBuilders.buildErrorAlert(
                      context: context,
                      message: _errorMessage!,
                      onClose: () => setState(() => _errorMessage = null),
                      margin: const EdgeInsets.fromLTRB(0, 16, 0, 0),
                    ),
                  if (_showForm) ...[
                    const SizedBox(height: 24),
                    _buildForm(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),

            // --- SCROLLABLE CATEGORY LIST ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!_showForm) const SizedBox(height: 24),
                    _buildTreeHeader(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: _buildTreeList(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // --- FIXED BOTTOM PART ---
            const Divider(height: 1, color: AppTheme.borderColor),
            Padding(padding: const EdgeInsets.all(24), child: _buildFooter()),
          ],
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
            InkWell(
              onTap: _startAdd,
              borderRadius: BorderRadius.circular(4),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                child: const Text(
                  '+ New Category',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, color: AppTheme.textSecondary),
            hoverColor: AppTheme.bgLight,
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
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Name*',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.errorRed,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppTheme.borderMid),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppTheme.borderMid),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: AppTheme.primaryBlueDark, width: 1.5),
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
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          FormDropdown<String>(
            value: _selectedParentId,
            items: options.map((o) => o['id'] as String).toList(),
            allowClear: true,
            onChanged: (id) => setState(() => _selectedParentId = id),
            displayStringForValue: (id) {
              final it = _flatList.firstWhere(
                (i) => i['id'] == id,
                orElse: () => {'name': id},
              );
              return (it['name'] as String);
            },
            itemBuilder: (id, isSelected, isHovered) {
              final opt = options.firstWhere((o) => o['id'] == id);
              final depth = opt['depth'] as int;
              final isRoot = depth == 0;

              // Theme Colors to match category_dropdown.dart
              const Color strongBlue = AppTheme.primaryBlueDark;
              const Color softBlue = AppTheme.infoBg;

              Color bg = Colors.transparent;
              Color textColor = const Color(0xFF1E293B);
              Color bulletColor = AppTheme.textDisabled;

              if (isHovered) {
                bg = strongBlue;
                textColor = Colors.white;
                bulletColor = Colors.white70;
              } else if (isSelected) {
                bg = softBlue;
                textColor = strongBlue;
                bulletColor = strongBlue.withValues(alpha: 0.5);
              }

              return Container(
                padding: EdgeInsets.only(
                  left: (depth * 20.0) + (isRoot ? 12.0 : 8.0),
                  right: 12,
                ),
                height: 40,
                alignment: Alignment.centerLeft,
                color: bg,
                child: Row(
                  children: [
                    if (!isRoot) ...[
                      Text(
                        '• ',
                        style: TextStyle(
                          color: bulletColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        isRoot
                            ? (opt['name'] as String).toUpperCase()
                            : (opt['name'] as String),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isRoot
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: 16,
                        color: isHovered ? Colors.white : strongBlue,
                      ),
                  ],
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
                    color: AppTheme.primaryBlueDark,
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
        color: AppTheme.textSecondary,
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

  Widget _buildTreeLines(int depth, List<bool> parentHasNext, bool isLast) {
    if (depth == 0) return const SizedBox(width: 12);

    return SizedBox(
      width: depth * 24.0,
      child: Row(
        children: [
          ...List.generate(depth - 1, (i) {
            return Container(
              width: 24,
              alignment: Alignment.center,
              child: parentHasNext[i]
                  ? Container(width: 1, color: AppTheme.borderMid)
                  : null,
            );
          }),
          SizedBox(
            width: 24,
            child: Stack(
              children: [
                // Vertical line
                Center(
                  child: Container(
                    width: 1,
                    margin: EdgeInsets.only(bottom: isLast ? 22 : 0),
                    color: AppTheme.borderMid,
                  ),
                ),
                // Horizontal line
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 12,
                    height: 1,
                    color: AppTheme.borderMid,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                  // Tree Lines Component
                  _buildTreeLines(depth, parentHasNext, isLast),

                  // Category Name
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRoot) ...[
                          const Icon(
                            Icons.folder_open_outlined,
                            size: 18,
                            color: AppTheme.primaryBlueDark,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            isRoot ? node.name.toUpperCase() : node.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isRoot
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isHovered
                                  ? AppTheme.primaryBlueDark
                                  : const Color(0xFF475569),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasChildren)
                          Icon(
                            isExpanded
                                ? Icons.arrow_drop_down
                                : Icons.arrow_right,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
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
                          color: AppTheme.primaryBlueDark,
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
                        color: AppTheme.textSecondary,
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
                        color: AppTheme.errorRed,
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
            backgroundColor: AppTheme.bgLight, // Grey from Image 2
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
