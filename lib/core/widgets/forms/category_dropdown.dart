import 'package:flutter/material.dart';

/// =======================================================
/// CATEGORY DATA MODEL
/// =======================================================
class CategoryNode {
  final String id;
  final String name;
  final String? parentId;
  final List<CategoryNode> children;
  final bool isActive;

  const CategoryNode({
    required this.id,
    required this.name,
    this.parentId,
    this.children = const [],
    this.isActive = true,
  });

  CategoryNode copyWith({
    String? id,
    String? name,
    String? parentId,
    List<CategoryNode>? children,
    bool? isActive,
  }) {
    return CategoryNode(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      children: children ?? this.children,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Builds a recursive tree from a flat list of maps (from backend)
  static List<CategoryNode> fromFlatList(List<Map<String, dynamic>> flatList) {
    final Map<String, CategoryNode> nodes = {};
    final List<CategoryNode> roots = [];

    // Create all nodes first
    for (final item in flatList) {
      final id = item['id']?.toString() ?? '';
      nodes[id] = CategoryNode(
        id: id,
        name: item['name']?.toString() ?? '',
        parentId: item['parent_id']?.toString(),
        isActive: item['is_active'] ?? true,
        children: [],
      );
    }

    // Build hierarchy
    for (final item in flatList) {
      final id = item['id']?.toString() ?? '';
      final parentId = item['parent_id']?.toString();
      final node = nodes[id]!;

      if (parentId == null || !nodes.containsKey(parentId)) {
        roots.add(node);
      } else {
        // Need to use a mutable way to add children or rebuild
      }
    }

    // Since CategoryNode is immutable, we need a different approach to build the tree efficiently
    return _buildTree(flatList, null);
  }

  static List<CategoryNode> _buildTree(
    List<Map<String, dynamic>> flatList,
    String? parentId,
  ) {
    return flatList
        .where((item) => item['parent_id']?.toString() == parentId)
        .map((item) {
          final id = item['id'].toString();
          return CategoryNode(
            id: id,
            name: item['name']?.toString() ?? '',
            parentId: parentId,
            isActive: item['is_active'] ?? true,
            children: _buildTree(flatList, id),
          );
        })
        .toList();
  }
}

/// =======================================================
/// 1) CategoryPicker
///    👉 Use in BULK UPDATE (NO manage footer)
/// =======================================================
class CategoryPicker extends StatelessWidget {
  final List<CategoryNode> nodes;
  final String? value;
  final ValueChanged<String?> onChanged;

  const CategoryPicker({
    super.key,
    required this.nodes,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseCategoryDropdown(
      nodes: nodes,
      value: value,
      onChanged: onChanged,
      showManageAction: false,
      onManageCategoriesTap: null,
    );
  }
}

/// =======================================================
/// 2) CategoryDropdown
///    👉 Use in Item Create / Edit (WITH manage footer)
/// =======================================================
class CategoryDropdown extends StatelessWidget {
  final List<CategoryNode> nodes;
  final String? value;
  final ValueChanged<String?> onChanged;
  final VoidCallback? onManageCategoriesTap;

  const CategoryDropdown({
    super.key,
    required this.nodes,
    required this.value,
    required this.onChanged,
    this.onManageCategoriesTap,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseCategoryDropdown(
      nodes: nodes,
      value: value,
      onChanged: onChanged,
      showManageAction: true,
      onManageCategoriesTap: onManageCategoriesTap,
    );
  }
}

/// =======================================================
/// INTERNAL BASE DROPDOWN (DO NOT USE DIRECTLY)
/// =======================================================
class _BaseCategoryDropdown extends StatefulWidget {
  final List<CategoryNode> nodes;
  final String? value;
  final ValueChanged<String?> onChanged;

  final bool showManageAction;
  final VoidCallback? onManageCategoriesTap;

  const _BaseCategoryDropdown({
    required this.nodes,
    required this.value,
    required this.onChanged,
    required this.showManageAction,
    this.onManageCategoriesTap,
  });

  @override
  State<_BaseCategoryDropdown> createState() => _BaseCategoryDropdownState();
}

class _BaseCategoryDropdownState extends State<_BaseCategoryDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;

  static const double _fieldHeight = 52;
  static const double _overlayMaxHeight = 360;

  bool get _hasValue => widget.value != null && widget.value!.trim().isNotEmpty;

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  void _toggle() {
    _isOpen ? _close() : _open();
  }

  void _open() {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 320;
    final fieldSize = box?.size ?? const Size(320, _fieldHeight);

    _overlay = OverlayEntry(
      builder: (_) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _close,
          child: Stack(
            children: [
              Positioned.fill(child: const SizedBox.expand()),
              CompositedTransformFollower(
                link: _layerLink,
                offset: _calculateOverlayOffset(fieldSize),
                showWhenUnlinked: false,
                child: SizedBox(
                  width: width,
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(4),
                    clipBehavior: Clip.antiAlias,
                    child: _CategoryDropdownPanel(
                      nodes: widget.nodes,
                      initialValue: widget.value,
                      showManageAction:
                          widget.showManageAction &&
                          widget.onManageCategoriesTap != null,
                      onSelect: (val) {
                        widget.onChanged(val);
                        _close();
                      },
                      onManageCategoriesTap: () {
                        _close();
                        widget.onManageCategoriesTap?.call();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_overlay!);
    setState(() => _isOpen = true);
  }

  Offset _calculateOverlayOffset(Size fieldSize) {
    if (!mounted) return Offset(0, fieldSize.height - 1);

    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final targetBox = context.findRenderObject() as RenderBox?;

    if (overlayBox == null || targetBox == null) {
      return Offset(0, fieldSize.height - 1);
    }

    final targetGlobal = targetBox.localToGlobal(
      Offset.zero,
      ancestor: overlayBox,
    );

    final double spaceBelow =
        overlayBox.size.height - (targetGlobal.dy + fieldSize.height);
    final double spaceAbove = targetGlobal.dy;
    final bool showAbove =
        spaceBelow < _overlayMaxHeight && spaceAbove > spaceBelow;

    return Offset(
      0,
      showAbove ? -(_overlayMaxHeight - 1) : fieldSize.height - 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        height: _fieldHeight,
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            isFocused: _isOpen,
            isEmpty: !_hasValue,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFF2563EB)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _hasValue
                        ? _findNameInTree(widget.nodes, widget.value!)
                        : 'Select a category',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: _hasValue
                          ? const Color(0xFF111827)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                if (_hasValue)
                  GestureDetector(
                    onTap: () => widget.onChanged(null),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _findNameInTree(List<CategoryNode> nodes, String id) {
    for (final node in nodes) {
      if (node.id == id) return node.name;
      final childName = _findNameInTree(node.children, id);
      if (childName != id) return childName;
    }
    return id; // Fallback
  }
}

/// =======================================================
/// DROPDOWN PANEL
/// =======================================================
class _CategoryDropdownPanel extends StatefulWidget {
  final List<CategoryNode> nodes;
  final String? initialValue;
  final ValueChanged<String> onSelect;

  final bool showManageAction;
  final VoidCallback? onManageCategoriesTap;

  const _CategoryDropdownPanel({
    required this.nodes,
    required this.initialValue,
    required this.onSelect,
    required this.showManageAction,
    this.onManageCategoriesTap,
  });

  @override
  State<_CategoryDropdownPanel> createState() => _CategoryDropdownPanelState();
}

class _CategoryDropdownPanelState extends State<_CategoryDropdownPanel> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String? _hoverKey;

  @override
  void initState() {
    super.initState();
    _searchCtrl.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  /// Recursively filters the tree. A node is kept if its name matches or children match.
  List<CategoryNode> _filterNodes(List<CategoryNode> nodes, String query) {
    if (query.isEmpty) return nodes;
    return nodes
        .map((node) {
          final matches = node.name.toLowerCase().contains(query);
          final filteredChildren = _filterNodes(node.children, query);
          if (matches || filteredChildren.isNotEmpty) {
            return node.copyWith(children: filteredChildren);
          }
          return null;
        })
        .whereType<CategoryNode>()
        .toList();
  }

  void _scrollToSelected() {
    if (widget.initialValue == null) return;
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase().trim();
    final filteredNodes = _filterNodes(widget.nodes, query);

    return Container(
      constraints: const BoxConstraints(maxHeight: 450),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 🔎 Search Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6)),
                ),
              ),
            ),
          ),

          // 🌳 Tree List
          Expanded(
            child: filteredNodes.isEmpty
                ? Center(
                    child: Text(
                      'No categories found',
                      style: TextStyle(color: Colors.grey[400], fontSize: 13),
                    ),
                  )
                : ListView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    children: _buildRecursiveTree(filteredNodes, 0, [], true),
                  ),
          ),

          // ⚙️ Manage Action Footer
          if (widget.showManageAction) ...[
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            InkWell(
              onTap: widget.onManageCategoriesTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.settings_outlined,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Manage Categories',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildRecursiveTree(
    List<CategoryNode> nodes,
    int depth,
    List<bool> parentHasNext,
    bool isRootLevel,
  ) {
    final List<Widget> widgets = [];
    for (int i = 0; i < nodes.length; i++) {
      final node = nodes[i];
      final isLast = i == nodes.length - 1;
      final hasChildren = node.children.isNotEmpty;

      widgets.add(_buildNodeRow(node, depth, parentHasNext, isLast));

      // We show children in the dropdown list for the searchable hierarchy
      if (hasChildren) {
        widgets.addAll(
          _buildRecursiveTree(node.children, depth + 1, [
            ...parentHasNext,
            !isLast,
          ], false),
        );
      }
    }
    return widgets;
  }

  Widget _buildNodeRow(
    CategoryNode node,
    int depth,
    List<bool> parentHasNext,
    bool isLast,
  ) {
    final bool isRoot = depth == 0;
    final bool selected = widget.initialValue == node.id;
    final bool hovered = _hoverKey == node.id;

    // Theme: Blue on hover, Light blue on select
    const Color strongBlue = Color(0xFF2563EB);
    const Color softBlue = Color(0xFFEFF6FF);

    Color bg = Colors.transparent;
    Color textColor = const Color(0xFF475569);
    Color bulletColor = const Color(0xFF94A3B8);
    Color checkColor = strongBlue;

    // Priority: Hover state wins for the background
    if (hovered) {
      bg = strongBlue;
      textColor = Colors.white;
      bulletColor = Colors.white70;
      checkColor = Colors.white;
    } else if (selected) {
      bg = softBlue;
      textColor = strongBlue;
      bulletColor = strongBlue.withValues(alpha: 0.5);
      checkColor = strongBlue;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverKey = node.id),
      onExit: (_) => setState(() => _hoverKey = null),
      child: InkWell(
        onTap: () => widget.onSelect(node.id),
        hoverColor: Colors.transparent,
        child: Container(
          height: 38,
          padding: EdgeInsets.only(
            left: (depth * 24.0) + (isRoot ? 12.0 : 8.0),
            right: 12,
          ),
          decoration: BoxDecoration(color: bg),
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
                  isRoot ? node.name.toUpperCase() : node.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isRoot ? FontWeight.w600 : FontWeight.w400,
                    color: textColor,
                    letterSpacing: isRoot ? 0.3 : 0,
                  ),
                ),
              ),
              if (selected) Icon(Icons.check, size: 16, color: checkColor),
            ],
          ),
        ),
      ),
    );
  }
}
