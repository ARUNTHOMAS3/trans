import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';

import 'dart:math' as math;

class CnAccountDropdown extends StatefulWidget {
  final List<AccountNode> roots;
  final String? value;
  final ValueChanged<String?> onChanged;
  final double height;
  final String hint;
  final double? overlayWidth;
  final Widget Function(BuildContext context, VoidCallback toggleDropdown, String label)? customTriggerBuilder;

  const CnAccountDropdown({
    super.key,
    required this.roots,
    this.value,
    required this.onChanged,
    this.height = 32,
    this.hint = 'Select Account',
    this.overlayWidth,
    this.customTriggerBuilder,
  });

  @override
  State<CnAccountDropdown> createState() => _CnAccountDropdownState();
}

class _CnAccountDropdownState extends State<CnAccountDropdown> {
  final LayerLink _layerLink = LayerLink();
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  bool _isHovered = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _closeDropdown();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_isOpen) return;
    _searchController.clear();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeDropdown() {
    if (!_isOpen) return;
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isOpen = false);
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;
    var offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeDropdown,
                child: Container(),
              ),
            ),
            Positioned(
              left: offset.dx,
              top: offset.dy + size.height,
              width: widget.overlayWidth ?? math.max(size.width, 300.0),
                child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height + 4),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 300),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: CustomTextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            hintText: 'Search accounts...',
                            prefixIcon: LucideIcons.search,
                            height: 32,
                            onChanged: (v) {
                              _overlayEntry?.markNeedsBuild();
                            },
                          ),
                        ),
                        const Divider(height: 1),
                        Flexible(
                          child: _DropdownList(
                            roots: widget.roots,
                            searchQuery: _searchController.text.trim().toLowerCase(),
                            selectedValue: widget.value,
                            onSelect: (id) {
                              widget.onChanged(id);
                              _closeDropdown();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayString = widget.hint;
    if (widget.value != null) {
      AccountNode? findNode(List<AccountNode> nodes, String id) {
        for (final node in nodes) {
          if (node.id == id) return node;
          final found = findNode(node.children, id);
          if (found != null) return found;
        }
        return null;
      }
      final selectedNode = findNode(widget.roots, widget.value!);
      if (selectedNode != null) {
        displayString = selectedNode.name;
      }
    }

    return CompositedTransformTarget(
      link: _layerLink,
      child: widget.customTriggerBuilder != null
          ? widget.customTriggerBuilder!(context, _toggleDropdown, displayString)
          : MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: InkWell(
                onTap: _toggleDropdown,
                hoverColor: Colors.transparent,
                child: Container(
            height: widget.height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: _isOpen || _isHovered
                  ? const Border(
                      top: BorderSide(color: Color(0xFF3B82F6), width: 1),
                      bottom: BorderSide(color: Color(0xFF3B82F6), width: 1),
                    )
                  : const Border(
                      top: BorderSide(color: Colors.transparent, width: 1),
                      bottom: BorderSide(color: Colors.transparent, width: 1),
                    ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayString,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.value != null ? AppTheme.textPrimary : AppTheme.textMuted,
                    ),
                  ),
                ),
                Icon(
                  _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: _isOpen ? AppTheme.primaryBlueDark : AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownList extends StatefulWidget {
  final List<AccountNode> roots;
  final String searchQuery;
  final String? selectedValue;
  final ValueChanged<String> onSelect;

  const _DropdownList({
    required this.roots,
    required this.searchQuery,
    this.selectedValue,
    required this.onSelect,
  });

  @override
  State<_DropdownList> createState() => _DropdownListState();
}

class _DropdownListState extends State<_DropdownList> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    // Flatten hierarchy
    final List<Map<String, dynamic>> items = [];

    void processNodes(List<AccountNode> nodes, int depth) {
      if (depth == 0) {
        final groups = nodes.map((e) => e.accountGroup).toSet().toList()..sort();
        for (final group in groups) {
          final groupNodes = nodes.where((e) => e.accountGroup == group).toList();
          
          bool groupHasMatch = false;
          final List<Map<String, dynamic>> groupItems = [];
          
          final types = groupNodes.map((e) => e.accountType).toSet().toList()..sort();
          for (final type in types) {
            final typeNodes = groupNodes.where((e) => e.accountType == type).toList();
            
            bool typeHasMatch = false;
            final List<Map<String, dynamic>> typeItems = [];
            
            for (final node in typeNodes) {
              final match = widget.searchQuery.isEmpty ||
                  node.name.toLowerCase().contains(widget.searchQuery) ||
                  (node.code?.toLowerCase().contains(widget.searchQuery) ?? false);
              
              if (match) {
                typeItems.add({'node': node, 'depth': 2});
                typeHasMatch = true;
                groupHasMatch = true;
              }
            }
            
            if (typeHasMatch || widget.searchQuery.isEmpty) {
               groupItems.add({'header': type, 'isGroup': false});
               groupItems.addAll(typeItems);
            }
          }
          
          if (groupHasMatch || widget.searchQuery.isEmpty) {
             items.add({'header': group, 'isGroup': true});
             items.addAll(groupItems);
          }
        }
      }
    }
    
    processNodes(widget.roots, 0);

    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No accounts found',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final hovered = _hoveredIndex == index;

        if (item.containsKey('header')) {
          final isGroup = item['isGroup'] as bool;
          final double paddingLeft = isGroup ? 12 : 24;
          return Container(
            height: 36,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              border: !isGroup
                  ? const Border(
                      top: BorderSide(
                        color: AppTheme.bgDisabled,
                        width: 1,
                      ),
                    )
                  : null,
            ),
            padding: EdgeInsets.symmetric(horizontal: paddingLeft),
            alignment: Alignment.centerLeft,
            child: Text(
              item['header'].toString(),
              style: TextStyle(
                fontSize: isGroup ? 13 : 12,
                fontWeight: FontWeight.bold,
                color: isGroup ? AppTheme.textBody : AppTheme.textSubtle,
              ),
            ),
          );
        } else if (item.containsKey('node')) {
          final node = item['node'] as AccountNode;
          final isSelected = node.id == widget.selectedValue;

          Color bg = AppTheme.transparent;
          Color text = AppTheme.textPrimary;
          

          if (hovered) {
            bg = const Color(0xFF3B82F6);
            text = AppTheme.backgroundColor;
          } else if (isSelected) {
            bg = const Color(0xFFF3F4F6);
            text = AppTheme.textPrimary;
          }

          final double paddingLeft = 36.0;

          return MouseRegion(
            onEnter: (_) => setState(() => _hoveredIndex = index),
            onExit: (_) => setState(() => _hoveredIndex = null),
            child: InkWell(
              onTap: () => widget.onSelect(node.id),
              hoverColor: AppTheme.transparent,
              splashColor: AppTheme.transparent,
              highlightColor: AppTheme.transparent,
              child: Container(
                color: bg,
                height: 36,
                padding: EdgeInsets.only(left: paddingLeft, right: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        node.name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: text,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    if (node.code != null && node.code!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        node.code!,
                        style: TextStyle(
                          fontSize: 12,
                          color: hovered ? AppTheme.backgroundColor.withAlpha(200) : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
