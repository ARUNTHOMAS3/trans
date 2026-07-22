import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ColumnConfig {
  ColumnConfig({
    required this.id,
    required this.label,
    required this.orderIndex,
    this.isVisible = true,
    this.isLocked = false,
    this.isPinned = false,
  });

  final String id;
  final String label;
  bool isVisible;
  int orderIndex;
  final bool isLocked;
  bool isPinned;

  ColumnConfig copy() => ColumnConfig(
    id: id,
    label: label,
    isVisible: isVisible,
    orderIndex: orderIndex,
    isLocked: isLocked,
    isPinned: isPinned,
  );
}

class ColumnCustomizerDialog extends StatefulWidget {
  final List<ColumnConfig> columns;
  final ValueChanged<List<ColumnConfig>> onSave;

  const ColumnCustomizerDialog({
    super.key,
    required this.columns,
    required this.onSave,
  });

  @override
  State<ColumnCustomizerDialog> createState() => _ColumnCustomizerDialogState();
}

class _ColumnCustomizerDialogState extends State<ColumnCustomizerDialog> {
  late List<ColumnConfig> _items;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _items = widget.columns.map((c) => c.copy()).toList();
    _sortItems();
  }

  void _sortItems() {
    _items.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return a.orderIndex.compareTo(b.orderIndex);
    });
  }

  void _togglePin(ColumnConfig col) {
    setState(() {
      col.isPinned = !col.isPinned;
      _sortItems();
      for (int i = 0; i < _items.length; i++) {
        _items[i].orderIndex = i;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = _items.where((c) => c.isVisible).length;
    final totalCount = _items.length;

    final displayedItems = _searchQuery.isEmpty
        ? _items
        : _items
              .where(
                (c) =>
                    c.label.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    final pinnedItems = displayedItems.where((c) => c.isPinned).toList();
    final unpinnedItems = displayedItems.where((c) => !c.isPinned).toList();

    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      surfaceTintColor: AppTheme.backgroundColor,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.sliders,
                  size: 20,
                  color: AppTheme.textPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Customize Columns',
                  style: AppTheme.sectionHeader.copyWith(fontSize: 16),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDisabled,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$visibleCount of $totalCount Selected',
                    style: AppTheme.captionText,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    LucideIcons.x,
                    size: 20,
                    color: AppTheme.errorRed,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTheme.bodyText,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  LucideIcons.search,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: AppTheme.backgroundColor.withValues(alpha: 0),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            const SizedBox(height: 8),

            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: AppTheme.backgroundColor,
                  shadowColor: AppTheme.textPrimary.withValues(alpha: 0.05),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pinned section
                      if (pinnedItems.isNotEmpty) ...[
                        _SectionLabel(
                          label: 'Pinned',
                          count: pinnedItems.length,
                        ),
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          buildDefaultDragHandles: false,
                          itemCount: pinnedItems.length,
                          onReorder: (oldIndex, newIndex) {
                            if (_searchQuery.isNotEmpty) return;
                            setState(() {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final item = pinnedItems.removeAt(oldIndex);
                              pinnedItems.insert(newIndex, item);
                              // Reflect new order back into _items
                              for (int i = 0; i < pinnedItems.length; i++) {
                                final idx = _items.indexOf(pinnedItems[i]);
                                if (idx != -1) _items[idx].orderIndex = i;
                              }
                              _sortItems();
                              for (int i = 0; i < _items.length; i++) {
                                _items[i].orderIndex = i;
                              }
                            });
                          },
                          itemBuilder: (context, index) {
                            final col = pinnedItems[index];
                            return _ColumnItem(
                              key: ValueKey('pinned_${col.id}'),
                              col: col,
                              index: index,
                              onToggleVisible: col.isLocked
                                  ? null
                                  : () => setState(
                                      () => col.isVisible = !col.isVisible,
                                    ),
                              onTogglePin: () => _togglePin(col),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Unpinned section
                      if (pinnedItems.isNotEmpty && unpinnedItems.isNotEmpty)
                        _SectionLabel(
                          label: 'Columns',
                          count: unpinnedItems.length,
                        ),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: unpinnedItems.length,
                        onReorder: (oldIndex, newIndex) {
                          if (_searchQuery.isNotEmpty) return;
                          setState(() {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final item = unpinnedItems.removeAt(oldIndex);
                            unpinnedItems.insert(newIndex, item);
                            for (int i = 0; i < unpinnedItems.length; i++) {
                              final idx = _items.indexOf(unpinnedItems[i]);
                              if (idx != -1)
                                _items[idx].orderIndex = pinnedItems.length + i;
                            }
                            _sortItems();
                            for (int i = 0; i < _items.length; i++) {
                              _items[i].orderIndex = i;
                            }
                          });
                        },
                        itemBuilder: (context, index) {
                          final col = unpinnedItems[index];
                          return _ColumnItem(
                            key: ValueKey('unpinned_${col.id}'),
                            col: col,
                            index: index,
                            onToggleVisible: col.isLocked
                                ? null
                                : () => setState(
                                    () => col.isVisible = !col.isVisible,
                                  ),
                            onTogglePin: () => _togglePin(col),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                ZButton.primary(
                  label: 'Save',
                  onPressed: () => widget.onSave(_items),
                ),
                const SizedBox(width: 12),
                ZButton.secondary(
                  label: 'Cancel',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.bgDisabled,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnItem extends StatefulWidget {
  const _ColumnItem({
    super.key,
    required this.col,
    required this.index,
    required this.onTogglePin,
    this.onToggleVisible,
  });
  final ColumnConfig col;
  final int index;
  final VoidCallback onTogglePin;
  final VoidCallback? onToggleVisible;

  @override
  State<_ColumnItem> createState() => _ColumnItemState();
}

class _ColumnItemState extends State<_ColumnItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final col = widget.col;
    final showPin = col.isPinned || _hovered;

    return Padding(
      key: ValueKey(col.id),
      padding: const EdgeInsets.only(bottom: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Container(
          decoration: BoxDecoration(
            color: col.isPinned
                ? AppTheme.primaryBlue.withValues(alpha: 0.04)
                : AppTheme.bgLight,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: col.isPinned
                  ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                  : AppTheme.borderColor.withValues(alpha: 0.5),
            ),
          ),
          child: InkWell(
            onTap: widget.onToggleVisible,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: const MouseRegion(
                      cursor: SystemMouseCursors.grab,
                      child: Icon(
                        LucideIcons.gripVertical,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (col.isLocked)
                    const Icon(
                      LucideIcons.lock,
                      size: 16,
                      color: AppTheme.textSecondary,
                    )
                  else
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: Checkbox(
                        value: col.isVisible,
                        onChanged: widget.onToggleVisible == null
                            ? null
                            : (v) => widget.onToggleVisible!(),
                        activeColor: AppTheme.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        side: const BorderSide(
                          color: AppTheme.borderColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      col.label,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        color: col.isVisible
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                        fontWeight: col.isVisible
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Pin button
                  if (showPin)
                    GestureDetector(
                      onTap: widget.onTogglePin,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: col.isPinned
                              ? AppTheme.primaryBlue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: col.isPinned
                              ? null
                              : Border.all(
                                  color: AppTheme.borderColor,
                                  width: 1,
                                ),
                        ),
                        child: Icon(
                          LucideIcons.pin,
                          size: 14,
                          color: col.isPinned
                              ? AppTheme.backgroundColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
