import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class SettingsSearchItem {
  final String group;
  final String label;
  final String? subtitle;
  final List<String> keywords;
  final VoidCallback onSelected;

  const SettingsSearchItem({
    required this.group,
    required this.label,
    required this.onSelected,
    this.subtitle,
    this.keywords = const <String>[],
  });

  bool matches(String query) {
    if (query.isEmpty) {
      return false;
    }
    final q = query.toLowerCase();
    return label.toLowerCase().contains(q) ||
        group.toLowerCase().contains(q) ||
        (subtitle?.toLowerCase().contains(q) ?? false) ||
        keywords.any((keyword) => keyword.toLowerCase().contains(q));
  }
}

class SettingsSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final List<SettingsSearchItem> items;
  final String hintText;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<String>? onNoMatch;

  const SettingsSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.items,
    this.hintText = 'Search settings ( / )',
    this.onQueryChanged,
    this.onNoMatch,
  });

  @override
  State<SettingsSearchField> createState() => _SettingsSearchFieldState();
}

class _SettingsSearchFieldState extends State<SettingsSearchField> {
  final MenuController _menuController = MenuController();

  List<SettingsSearchItem> get _filteredItems {
    final query = widget.controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      return const <SettingsSearchItem>[];
    }
    return widget.items.where((item) => item.matches(query)).toList();
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleSearchStateChanged);
    widget.focusNode.addListener(_handleSearchStateChanged);
  }

  @override
  void didUpdateWidget(covariant SettingsSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleSearchStateChanged);
      widget.controller.addListener(_handleSearchStateChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_handleSearchStateChanged);
      widget.focusNode.addListener(_handleSearchStateChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleSearchStateChanged);
    widget.focusNode.removeListener(_handleSearchStateChanged);
    super.dispose();
  }

  void _handleSearchStateChanged() {
    if (!mounted) {
      return;
    }

    widget.onQueryChanged?.call(widget.controller.text);

    final shouldOpen =
        widget.focusNode.hasFocus &&
        widget.controller.text.trim().isNotEmpty &&
        _filteredItems.isNotEmpty;

    if (shouldOpen && !_menuController.isOpen) {
      _menuController.open();
    } else if (!shouldOpen && _menuController.isOpen) {
      _menuController.close();
    }

    setState(() {});
  }

  void _clearSearch() {
    widget.controller.clear();
    widget.focusNode.requestFocus();
    _menuController.close();
  }

  void _selectItem(SettingsSearchItem item) {
    widget.controller.clear();
    _menuController.close();
    widget.focusNode.unfocus();
    item.onSelected();
  }

  void _submitSearch(String rawQuery) {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return;
    }

    final matches = _filteredItems;
    if (matches.isEmpty) {
      widget.onNoMatch?.call(query);
      return;
    }

    _selectItem(matches.first);
  }

  List<_SettingsSearchGroup> _buildGroups() {
    final Map<String, List<SettingsSearchItem>> grouped =
        <String, List<SettingsSearchItem>>{};
    for (final item in _filteredItems) {
      grouped.putIfAbsent(item.group, () => <SettingsSearchItem>[]).add(item);
    }

    return grouped.entries
        .map(
          (entry) => _SettingsSearchGroup(
            title: entry.key,
            items: entry.value,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final groups = _buildGroups();
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 420.0;
        final measuredWidth = availableWidth.clamp(280.0, 420.0);

        return MenuAnchor(
          controller: _menuController,
          crossAxisUnconstrained: true,
          alignmentOffset: const Offset(0, 8),
          style: MenuStyle(
            backgroundColor: WidgetStateProperty.all(Colors.white),
            surfaceTintColor: WidgetStateProperty.all(Colors.white),
            elevation: WidgetStateProperty.all(8),
            padding: WidgetStateProperty.all(EdgeInsets.zero),
            side: WidgetStateProperty.all(
              const BorderSide(color: AppTheme.borderLight),
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          menuChildren: [
            if (groups.isNotEmpty)
              SizedBox(
                width: measuredWidth,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 420,
                    maxHeight: 320,
                  ),
                  child: Material(
                    color: Colors.white,
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final group in groups) ...[
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  group.title.toUpperCase(),
                                  style: AppTheme.captionText.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              for (final item in group.items)
                                _SettingsSearchResultTile(
                                  item: item,
                                  query: widget.controller.text.trim(),
                                  onTap: () => _selectItem(item),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
          builder: (context, controller, child) {
            return TextField(
              controller: widget.controller,
              focusNode: widget.focusNode,
              onSubmitted: _submitSearch,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: AppTheme.bodyText.copyWith(
                  color: AppTheme.textMuted,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 18,
                  color: AppTheme.primaryBlue,
                ),
                suffixIcon: widget.controller.text.trim().isEmpty
                    ? null
                    : IconButton(
                        onPressed: _clearSearch,
                        splashRadius: 18,
                        icon: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: AppTheme.errorRed,
                        ),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space16,
                  vertical: AppTheme.space12,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppTheme.primaryBlue,
                    width: 1.2,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SettingsSearchGroup {
  final String title;
  final List<SettingsSearchItem> items;

  const _SettingsSearchGroup({
    required this.title,
    required this.items,
  });
}

class _SettingsSearchResultTile extends StatelessWidget {
  final SettingsSearchItem item;
  final String query;
  final VoidCallback onTap;

  const _SettingsSearchResultTile({
    required this.item,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HighlightedText(
                text: item.label,
                query: query,
                style: AppTheme.bodyText.copyWith(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (item.subtitle != null && item.subtitle!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _HighlightedText(
                    text: item.subtitle!,
                    query: query,
                    style: AppTheme.captionText.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return Text(text, style: style);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = trimmedQuery.toLowerCase();
    final start = lowerText.indexOf(lowerQuery);
    if (start < 0) {
      return Text(text, style: style);
    }

    final end = start + trimmedQuery.length;
    return RichText(
      text: TextSpan(
        style: style,
        children: [
          if (start > 0) TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: style.copyWith(
              color: const Color(0xFFB86A00),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (end < text.length) TextSpan(text: text.substring(end)),
        ],
      ),
    );
  }
}
