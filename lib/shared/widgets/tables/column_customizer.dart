import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../models/column_config.dart';
import '../z_button.dart';

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
    _items = widget.columns.map((c) => ColumnConfig(
      id: c.id,
      label: c.label,
      isVisible: c.isVisible,
      orderIndex: c.orderIndex,
      isLocked: c.isLocked,
    )).toList();
    _items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      
      // Update orderIndex for all items
      for (int i = 0; i < _items.length; i++) {
        _items[i].orderIndex = i;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleCount = _items.where((c) => c.isVisible).length;
    final totalCount = _items.length;

    // We filter items but we MUST keep the original indices for ReorderableListView if we want to support search + reorder
    // However, ReorderableListView doesn't play well with filtered lists easily if we want to preserve global order.
    // For now, let's just filter the display. If search is active, we might disable reordering or handle it carefully.
    final displayedItems = _items
        .where((c) => c.label.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
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
            // Header Section
            Row(
              children: [
                const Icon(LucideIcons.sliders, size: 20, color: AppTheme.textPrimary),
                const SizedBox(width: 12),
                Text('Customize Columns', style: AppTheme.sectionHeader.copyWith(fontSize: 16)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.bgDisabled,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$visibleCount of $totalCount Selected',
                    style: AppTheme.metaHelper,
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x, size: 20, color: AppTheme.errorRed),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Boxed Search Bar (Transparent)
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTheme.bodyText,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon: const Icon(LucideIcons.search, size: 16, color: AppTheme.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
            const SizedBox(height: 16),

            // List Section with Boxed Items
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  canvasColor: Colors.white,
                  shadowColor: Colors.black.withValues(alpha: 0.05),
                ),
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  buildDefaultDragHandles: false,
                  itemCount: displayedItems.length,
                  onReorder: _onReorder,
                  itemBuilder: (context, index) {
                    final col = displayedItems[index];
                    return _buildListItem(col, index);
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Footer Section
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

  Widget _buildListItem(ColumnConfig col, int index) {
    return Padding(
      key: ValueKey(col.id),
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: col.isLocked ? null : () => setState(() => col.isVisible = !col.isVisible),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Icon(LucideIcons.gripVertical, size: 14, color: AppTheme.textMuted),
                  ),
                ),
                const SizedBox(width: 12),
                if (col.isLocked)
                  const Icon(LucideIcons.lock, size: 16, color: AppTheme.textSecondary)
                else
                  SizedBox(
                    height: 18,
                    width: 18,
                    child: Checkbox(
                      value: col.isVisible,
                      onChanged: (v) => setState(() => col.isVisible = v ?? false),
                      activeColor: AppTheme.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      side: const BorderSide(color: AppTheme.borderColor, width: 1.5),
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    col.label,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: col.isVisible ? AppTheme.textPrimary : AppTheme.textSecondary,
                      fontWeight: col.isVisible ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
