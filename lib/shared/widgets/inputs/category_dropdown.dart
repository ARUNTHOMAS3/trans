import 'package:flutter/material.dart';
import 'dart:async';
import 'package:zerpai_erp/core/theme/app_theme.dart';

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
    this.displayString,
    this.onSearch,
  });

  final String? displayString;

  @override
  Widget build(BuildContext context) {
    return _BaseCategoryDropdown(
      nodes: nodes,
      value: value,
      displayString: displayString,
      onChanged: onChanged,
      onSearch: onSearch,
      showManageAction: false,
      onManageCategoriesTap: null,
    );
  }

  final Future<List<CategoryNode>> Function(String query)? onSearch;
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
    this.displayString,
    this.onSearch,
  });

  final String? displayString;

  @override
  Widget build(BuildContext context) {
    return _BaseCategoryDropdown(
      nodes: nodes,
      value: value,
      displayString: displayString,
      onChanged: onChanged,
      onSearch: onSearch,
      showManageAction: true,
      onManageCategoriesTap: onManageCategoriesTap,
    );
  }

  final Future<List<CategoryNode>> Function(String query)? onSearch;
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
    this.displayString,
    this.onManageCategoriesTap,
    this.onSearch,
  });

  final String? displayString;

  final Future<List<CategoryNode>> Function(String query)? onSearch;

  @override
  State<_BaseCategoryDropdown> createState() => _BaseCategoryDropdownState();
}

class _BaseCategoryDropdownState extends State<_BaseCategoryDropdown> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _isOpen = false;
  bool _openAbove = false;
  double _resolvedOverlayHeight = _overlayMaxHeight;

  static const double _fieldHeight = 52;
  static const double _overlayMaxHeight = 450;
  static const double _overlayMinHeight = 180;

  bool get _hasValue => widget.value != null && widget.value!.trim().isNotEmpty;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _toggle() {
    _isOpen ? _close() : _open();
  }

  void _open() {
    final overlay = Overlay.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 320;
    final fieldSize = box?.size ?? const Size(320, _fieldHeight);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final targetBox = context.findRenderObject() as RenderBox?;

    if (overlayBox != null && targetBox != null) {
      final targetGlobal = targetBox.localToGlobal(
        Offset.zero,
        ancestor: overlayBox,
      );
      final availableBelow =
          overlayBox.size.height - (targetGlobal.dy + fieldSize.height) - 8;
      final availableAbove = targetGlobal.dy - 8;

      final shouldOpenAbove =
          availableBelow < _overlayMinHeight && availableAbove > availableBelow;
      _openAbove = shouldOpenAbove;

      final usableHeight = shouldOpenAbove ? availableAbove : availableBelow;
      _resolvedOverlayHeight = usableHeight
          .clamp(_overlayMinHeight, _overlayMaxHeight)
          .toDouble();
    } else {
      _openAbove = false;
      _resolvedOverlayHeight = _overlayMaxHeight;
    }

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
                offset: _openAbove
                    ? Offset(0, -(_resolvedOverlayHeight - 1))
                    : Offset(0, fieldSize.height - 1),
                showWhenUnlinked: false,
                child: SizedBox(
                  width: width,
                child: Material(
                    elevation: 6,
                    color: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    clipBehavior: Clip.antiAlias,
                    child: _CategoryDropdownPanel(
                      nodes: widget.nodes,
                      initialValue: widget.value,
                      onSearch: widget.onSearch,
                      maxHeight: _resolvedOverlayHeight,
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

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: SizedBox(
        height: _fieldHeight,
        child: InkWell(
          onTap: _toggle,
          borderRadius: BorderRadius.circular(4),
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          child: InputDecorator(
            isFocused: _isOpen,
            isEmpty: !_hasValue,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hoverColor: Colors.white,
              focusColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: AppTheme.primaryBlueDark),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _hasValue
                        ? (_findNameInTree(widget.nodes, widget.value!) !=
                                  widget.value
                              ? _findNameInTree(widget.nodes, widget.value!)
                              : (widget.displayString ?? widget.value!))
                        : 'Select a category',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: _hasValue
                          ? AppTheme.textPrimary
                          : AppTheme.textMuted,
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
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppTheme.textSecondary,
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
  final Future<List<CategoryNode>> Function(String query)? onSearch;
  final double maxHeight;

  final bool showManageAction;
  final VoidCallback? onManageCategoriesTap;

  const _CategoryDropdownPanel({
    required this.nodes,
    required this.initialValue,
    required this.onSelect,
    required this.maxHeight,
    required this.showManageAction,
    this.onManageCategoriesTap,
    this.onSearch,
  });

  @override
  State<_CategoryDropdownPanel> createState() => _CategoryDropdownPanelState();
}

class _CategoryDropdownPanelState extends State<_CategoryDropdownPanel> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  String? _hoverKey;
  bool _isSearching = false;
  List<CategoryNode> _remoteNodes = [];
  Timer? _debounce;

  /// Which nodes are expanded. Initialize all roots expanded by default.

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
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (widget.onSearch == null || query.isEmpty) {
      setState(() {
        _remoteNodes = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      try {
        final results = await widget.onSearch!(query);
        if (mounted) {
          setState(() {
            _remoteNodes = results;
            _isSearching = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isSearching = false);
      }
    });
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
    final List<CategoryNode> baseNodes =
        query.isNotEmpty && _remoteNodes.isNotEmpty
        ? _remoteNodes
        : widget.nodes;
    final filteredNodes = _filterNodes(baseNodes, query);

    return Container(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
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
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(
                  color: AppTheme.textDisabled,
                  fontSize: 13,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 20,
                  color: AppTheme.textDisabled,
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
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.infoBlue),
                ),
              ),
            ),
          ),
          if (_isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.infoBlue),
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
            const Divider(height: 1, color: AppTheme.bgLight),
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
                      color: AppTheme.infoBlue,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Manage Categories',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryBlueDark,
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
    const Color strongBlue = AppTheme.primaryBlueDark;
    const Color softBlue = AppTheme.infoBg;

    Color bg = Colors.transparent;
    Color textColor = const Color(0xFF475569);
    Color bulletColor = AppTheme.textDisabled;
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
