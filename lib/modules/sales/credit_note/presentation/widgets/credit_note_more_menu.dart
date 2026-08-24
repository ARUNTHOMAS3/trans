import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class CreditNoteMoreMenu extends StatefulWidget {
  const CreditNoteMoreMenu({
    super.key,
    required this.sortColumn,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onImport,
    required this.onExport,
    required this.onPreferences,
    required this.onManageCustomFields,
    required this.onRefreshList,
    required this.onResetColumnWidth,
  });

  final String? sortColumn;
  final bool sortAscending;
  final void Function(String column, bool ascending) onSortChanged;
  final VoidCallback onImport;
  final VoidCallback onExport;
  final VoidCallback onPreferences;
  final VoidCallback onManageCustomFields;
  final VoidCallback onRefreshList;
  final VoidCallback onResetColumnWidth;

  @override
  State<CreditNoteMoreMenu> createState() => _CreditNoteMoreMenuState();
}

class _CreditNoteMoreMenuState extends State<CreditNoteMoreMenu> {
  bool _sortItemHovered = false;
  bool _sortSubmenuHovered = false;
  bool _exportItemHovered = false;
  bool _exportSubmenuHovered = false;
  bool _importHovered = false;
  bool _preferencesHovered = false;
  bool _customFieldsHovered = false;
  bool _refreshHovered = false;
  bool _resetHovered = false;

  bool get _sortSubmenuVisible => _sortItemHovered || _sortSubmenuHovered;
  bool get _exportSubmenuVisible => _exportItemHovered || _exportSubmenuHovered;

  static const _sortOptions = [
    ('date', 'Issued Date'),
    ('creditNoteNumber', 'Credit Note#'),
    ('customerName', 'Customer Name'),
    ('amount', 'Amount'),
  ];

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      );

  Widget _menuItem({
    required String label,
    required IconData icon,
    required bool hovered,
    required bool active,
    bool hasChevron = false,
    VoidCallback? onTap,
  }) {
    final showActive = active || hovered;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: showActive ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 15,
                color: showActive ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: showActive ? Colors.white : AppTheme.textPrimary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              if (hasChevron)
                Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: showActive ? Colors.white : AppTheme.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_sortSubmenuVisible)
            _buildSortSubmenu()
          else if (_exportSubmenuVisible)
            _buildExportSubmenu()
          else
            const SizedBox(width: 184),
          Container(
            width: 200,
            decoration: _cardDecoration,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _sortItemHovered = true),
                  onExit: (_) => setState(() => _sortItemHovered = false),
                  child: _menuItem(
                    label: 'Sort by',
                    icon: LucideIcons.arrowUpDown,
                    hovered: _sortItemHovered,
                    active: _sortSubmenuVisible,
                    hasChevron: true,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _importHovered = true),
                  onExit: (_) => setState(() => _importHovered = false),
                  child: _menuItem(
                    label: 'Import',
                    icon: LucideIcons.download,
                    hovered: _importHovered,
                    active: false,
                    hasChevron: true,
                    onTap: widget.onImport,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _exportItemHovered = true),
                  onExit: (_) => setState(() => _exportItemHovered = false),
                  child: _menuItem(
                    label: 'Export',
                    icon: LucideIcons.upload,
                    hovered: _exportItemHovered,
                    active: _exportSubmenuVisible,
                    hasChevron: true,
                  ),
                ),
                const Divider(height: 9, color: AppTheme.borderLight),
                MouseRegion(
                  onEnter: (_) => setState(() => _preferencesHovered = true),
                  onExit: (_) => setState(() => _preferencesHovered = false),
                  child: _menuItem(
                    label: 'Preferences',
                    icon: LucideIcons.settings,
                    hovered: _preferencesHovered,
                    active: false,
                    onTap: widget.onPreferences,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _customFieldsHovered = true),
                  onExit: (_) => setState(() => _customFieldsHovered = false),
                  child: _menuItem(
                    label: 'Manage Custom Fields',
                    icon: LucideIcons.columns,
                    hovered: _customFieldsHovered,
                    active: false,
                    onTap: widget.onManageCustomFields,
                  ),
                ),
                const Divider(height: 9, color: AppTheme.borderLight),
                MouseRegion(
                  onEnter: (_) => setState(() => _refreshHovered = true),
                  onExit: (_) => setState(() => _refreshHovered = false),
                  child: _menuItem(
                    label: 'Refresh List',
                    icon: LucideIcons.refreshCw,
                    hovered: _refreshHovered,
                    active: false,
                    onTap: widget.onRefreshList,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _resetHovered = true),
                  onExit: (_) => setState(() => _resetHovered = false),
                  child: _menuItem(
                    label: 'Reset Column Width',
                    icon: LucideIcons.rotateCcw,
                    hovered: _resetHovered,
                    active: false,
                    onTap: widget.onResetColumnWidth,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSubmenu() {
    return SizedBox(
      width: 184,
      child: MouseRegion(
        onEnter: (_) => setState(() => _sortSubmenuHovered = true),
        onExit: (_) => setState(() => _sortSubmenuHovered = false),
        child: Container(
          decoration: _cardDecoration,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _sortOptions.map((option) {
              final isSelected = widget.sortColumn == option.$1;
              return _CreditNoteSortOption(
                label: option.$2,
                isSelected: isSelected,
                sortAscending: widget.sortAscending,
                onTap: () => widget.onSortChanged(
                  option.$1,
                  isSelected ? !widget.sortAscending : true,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildExportSubmenu() {
    return Container(
      width: 184,
      margin: const EdgeInsets.only(top: 80),
      child: MouseRegion(
        onEnter: (_) => setState(() => _exportSubmenuHovered = true),
        onExit: (_) => setState(() => _exportSubmenuHovered = false),
        child: Container(
          decoration: _cardDecoration,
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _CreditNoteSubmenuItem(
            label: 'Export current view',
            onTap: widget.onExport,
          ),
        ),
      ),
    );
  }
}

class _CreditNoteSortOption extends StatefulWidget {
  const _CreditNoteSortOption({
    required this.label,
    required this.isSelected,
    required this.sortAscending,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool sortAscending;
  final VoidCallback onTap;

  @override
  State<_CreditNoteSortOption> createState() => _CreditNoteSortOptionState();
}

class _CreditNoteSortOptionState extends State<_CreditNoteSortOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = _hovered
        ? AppTheme.primaryBlue
        : widget.isSelected
        ? AppTheme.bgHover
        : Colors.transparent;
    final foreground = _hovered ? Colors.white : AppTheme.textPrimary;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isSelected
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: foreground,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(
                  widget.sortAscending
                      ? LucideIcons.arrowUp
                      : LucideIcons.arrowDown,
                  size: 14,
                  color: foreground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditNoteSubmenuItem extends StatefulWidget {
  const _CreditNoteSubmenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_CreditNoteSubmenuItem> createState() =>
      _CreditNoteSubmenuItemState();
}

class _CreditNoteSubmenuItemState extends State<_CreditNoteSubmenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: _hovered ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
