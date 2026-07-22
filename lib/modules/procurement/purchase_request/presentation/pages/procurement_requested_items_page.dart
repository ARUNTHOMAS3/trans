// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class _RequestedItem {
  const _RequestedItem({
    required this.itemName,
    required this.expectedDate,
    required this.quantity,
    required this.remainingQuantity,
    required this.requestNumber,
  });

  final String itemName;
  final String expectedDate;
  final int quantity;
  final int remainingQuantity;
  final String requestNumber;
}

// ---------------------------------------------------------------------------
// Hardcoded data
// ---------------------------------------------------------------------------

const List<_RequestedItem> _kItems = [
  _RequestedItem(
    itemName: 'BATCH TARCK ITEM',
    expectedDate: '19-05-2026',
    quantity: 50,
    remainingQuantity: 50,
    requestNumber: 'PR-00001',
  ),
  _RequestedItem(
    itemName: 'BIN2',
    expectedDate: '19-05-2026',
    quantity: 2,
    remainingQuantity: 2,
    requestNumber: 'PR-00001',
  ),
  _RequestedItem(
    itemName: 'BATCH TARCK ITEM',
    expectedDate: '16-05-2026',
    quantity: 10,
    remainingQuantity: 10,
    requestNumber: 'PR-00002',
  ),
  _RequestedItem(
    itemName: 'BATCH TARCK ITEM',
    expectedDate: '16-05-2026',
    quantity: 10,
    remainingQuantity: 10,
    requestNumber: 'PR-00003',
  ),
  _RequestedItem(
    itemName: 'BATCH TRACK 2',
    expectedDate: '16-05-2026',
    quantity: 1,
    remainingQuantity: 1,
    requestNumber: 'PR-00003',
  ),
  _RequestedItem(
    itemName: 'BIN2',
    expectedDate: '16-05-2026',
    quantity: 1,
    remainingQuantity: 1,
    requestNumber: 'PR-00003',
  ),
  _RequestedItem(
    itemName: 'ITEM-3',
    expectedDate: '16-05-2026',
    quantity: 1,
    remainingQuantity: 1,
    requestNumber: 'PR-00003',
  ),
];

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

enum _RiTabFilter { open, onHold, processed }

class ProcurementRequestedItemsPage extends ConsumerStatefulWidget {
  const ProcurementRequestedItemsPage({super.key});

  @override
  ConsumerState<ProcurementRequestedItemsPage> createState() =>
      _ProcurementRequestedItemsPageState();
}

class _ProcurementRequestedItemsPageState
    extends ConsumerState<ProcurementRequestedItemsPage> {
  _RiTabFilter _activeTab = _RiTabFilter.open;
  final Set<int> _selected = {};
  _RiSortField _sortField = _RiSortField.itemName;
  _RiSortDir _sortDir = _RiSortDir.ascending;

  List<_RequestedItem> get _filtered {
    final base = List<_RequestedItem>.from(_kItems);
    base.sort((a, b) {
      final cmp = switch (_sortField) {
        _RiSortField.itemName => a.itemName.compareTo(b.itemName),
        _RiSortField.expectedDate => a.expectedDate.compareTo(b.expectedDate),
        _RiSortField.remainingQty => a.remainingQuantity.compareTo(
          b.remainingQuantity,
        ),
        _RiSortField.requestNo => a.requestNumber.compareTo(b.requestNumber),
      };
      return _sortDir == _RiSortDir.ascending ? cmp : -cmp;
    });
    return base;
  }

  void _onSort(_RiSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortDir = _sortDir == _RiSortDir.ascending
            ? _RiSortDir.descending
            : _RiSortDir.ascending;
      } else {
        _sortField = field;
        _sortDir = _RiSortDir.ascending;
      }
    });
  }

  void _onRefresh() {
    setState(() {
      _activeTab = _RiTabFilter.open;
      _sortField = _RiSortField.itemName;
      _sortDir = _RiSortDir.ascending;
      _selected.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      titleWidget: _BreadcrumbTitle(
        onBack: () => context.go(AppRoutes.procurementPurchaseRequests),
      ),
      useHorizontalPadding: false,
      titlePadding: const EdgeInsets.only(left: 16),
      actions: [
        _MoreButton(
          activeSortField: _sortField,
          onSortChanged: _onSort,
          onRefresh: _onRefresh,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tabs or selection bar — no outer wrapper; _RiTab internal padding (16px)
          // aligns "Open" with the checkbox at 16px from the left edge
          if (_selected.isNotEmpty)
            _RiSelectionBar(
              count: _selected.length,
              onClear: () => setState(() => _selected.clear()),
            )
          else
            _RiTabBar(
              active: _activeTab,
              onChanged: (t) => setState(() {
                _activeTab = t;
                _selected.clear();
              }),
            ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
          // Table fills full width so the grey header background is edge-to-edge
          _ItemsTable(
            rows: _filtered,
            selected: _selected,
            sortField: _sortField,
            sortDir: _sortDir,
            onSortChanged: _onSort,
            onToggleRow: (i) => setState(() {
              if (_selected.contains(i)) {
                _selected.remove(i);
              } else {
                _selected.add(i);
              }
            }),
            onToggleAll: () => setState(() {
              if (_selected.length == _filtered.length) {
                _selected.clear();
              } else {
                _selected
                  ..clear()
                  ..addAll(List.generate(_filtered.length, (i) => i));
              }
            }),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Breadcrumb title (renders inside ZerpaiLayout titleWidget)
// ---------------------------------------------------------------------------

class _BreadcrumbTitle extends StatelessWidget {
  const _BreadcrumbTitle({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: const Text(
            'Purchase Requests',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            LucideIcons.chevronRight,
            size: 20,
            color: AppTheme.successGreen,
          ),
        ),
        const Text(
          'Requested Items',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.successGreen,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Selection bar (shown when rows are checked)
// ---------------------------------------------------------------------------

class _RiSelectionBar extends StatefulWidget {
  const _RiSelectionBar({required this.count, required this.onClear});
  final int count;
  final VoidCallback onClear;

  @override
  State<_RiSelectionBar> createState() => _RiSelectionBarState();
}

class _RiSelectionBarState extends State<_RiSelectionBar> {
  final _createLink = LayerLink();
  final _createKey = GlobalKey();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _toggle(BuildContext context) {
    if (_overlay != null) {
      _overlay!.remove();
      _overlay = null;
      setState(() {});
      return;
    }

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _overlay?.remove();
                _overlay = null;
                if (mounted) setState(() {});
              },
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _createLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 38),
            child: Align(
              alignment: Alignment.topLeft,
              child: _RiCreateDropdown(
                onSelect: (_) {
                  _overlay?.remove();
                  _overlay = null;
                  if (mounted) setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            '${widget.count} item${widget.count == 1 ? '' : 's'} selected',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          CompositedTransformTarget(
            link: _createLink,
            child: ElevatedButton(
              key: _createKey,
              onPressed: () => _toggle(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Create'),
                  SizedBox(width: 4),
                  Icon(LucideIcons.chevronDown, size: 14),
                ],
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: widget.onClear,
            borderRadius: BorderRadius.circular(6),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }
}

class _RiCreateDropdown extends StatefulWidget {
  const _RiCreateDropdown({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  State<_RiCreateDropdown> createState() => _RiCreateDropdownState();
}

class _RiCreateDropdownState extends State<_RiCreateDropdown> {
  String? _hovered;

  static const _kItems = ['Purchase Order', 'Request for Quote'];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _kItems.map((item) {
            final isHovered = _hovered == item;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = item),
              onExit: (_) => setState(() => _hovered = null),
              child: GestureDetector(
                onTap: () => widget.onSelect(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: double.infinity,
                  color: isHovered ? AppTheme.primaryBlue : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: isHovered ? Colors.white : AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab bar
// ---------------------------------------------------------------------------

class _RiTabBar extends StatefulWidget {
  const _RiTabBar({required this.active, required this.onChanged});

  final _RiTabFilter active;
  final ValueChanged<_RiTabFilter> onChanged;

  @override
  State<_RiTabBar> createState() => _RiTabBarState();
}

class _RiTabBarState extends State<_RiTabBar> {
  final _dotsLink = LayerLink();
  final _dotsKey = GlobalKey();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _toggle(BuildContext context) {
    if (_overlay != null) {
      _overlay!.remove();
      _overlay = null;
      setState(() {});
      return;
    }

    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _overlay?.remove();
                _overlay = null;
                if (mounted) setState(() {});
              },
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _dotsLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 36),
            child: Align(
              alignment: Alignment.topLeft,
              child: _RiTabDropdown(
                active: widget.active,
                onSelect: (f) {
                  _overlay?.remove();
                  _overlay = null;
                  if (mounted) setState(() {});
                  widget.onChanged(f);
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RiTab(
          label: 'Open',
          isActive: widget.active == _RiTabFilter.open,
          onTap: () => widget.onChanged(_RiTabFilter.open),
        ),
        _RiTab(
          label: 'On Hold',
          isActive: widget.active == _RiTabFilter.onHold,
          onTap: () => widget.onChanged(_RiTabFilter.onHold),
        ),
        _RiTab(
          label: 'Processed',
          isActive: widget.active == _RiTabFilter.processed,
          onTap: () => widget.onChanged(_RiTabFilter.processed),
        ),
        const SizedBox(width: 8),
        CompositedTransformTarget(
          link: _dotsLink,
          child: GestureDetector(
            key: _dotsKey,
            onTap: () => _toggle(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _overlay != null
                    ? AppTheme.primaryBlue.withValues(alpha: 0.1)
                    : AppTheme.bgDisabled,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '...',
                style: TextStyle(
                  fontSize: 13,
                  color: _overlay != null
                      ? AppTheme.primaryBlue
                      : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tab filter dropdown ────────────────────────────────────────────────────

class _RiTabDropdown extends StatefulWidget {
  const _RiTabDropdown({required this.active, required this.onSelect});

  final _RiTabFilter active;
  final ValueChanged<_RiTabFilter> onSelect;

  @override
  State<_RiTabDropdown> createState() => _RiTabDropdownState();
}

class _RiTabDropdownState extends State<_RiTabDropdown> {
  _RiTabFilter? _hovered;

  static const _kItems = [
    (_RiTabFilter.open, 'Open'),
    (_RiTabFilter.onHold, 'On Hold'),
    (_RiTabFilter.processed, 'Processed'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text(
                'DEFAULT',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ..._kItems.map((entry) {
              final (filter, label) = entry;
              final isActive = filter == widget.active;
              final isHovered = _hovered == filter;

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hovered = filter),
                onExit: (_) => setState(() => _hovered = null),
                child: GestureDetector(
                  onTap: () => widget.onSelect(filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    color: isHovered
                        ? AppTheme.primaryBlue
                        : isActive
                        ? const Color(0xFFF0F4FF)
                        : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: isHovered
                              ? Colors.white
                              : isActive
                              ? AppTheme.primaryBlue
                              : AppTheme.textPrimary,
                          fontWeight: isActive || isHovered
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RiTab extends StatelessWidget {
  const _RiTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.successGreen : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? AppTheme.successGreen : AppTheme.textBody,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Table
// ---------------------------------------------------------------------------

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({
    required this.rows,
    required this.selected,
    required this.sortField,
    required this.sortDir,
    required this.onSortChanged,
    required this.onToggleRow,
    required this.onToggleAll,
  });

  final List<_RequestedItem> rows;
  final Set<int> selected;
  final _RiSortField sortField;
  final _RiSortDir sortDir;
  final ValueChanged<_RiSortField> onSortChanged;
  final ValueChanged<int> onToggleRow;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final allSelected = rows.isNotEmpty && selected.length == rows.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableHeader(
          allSelected: allSelected,
          onToggleAll: onToggleAll,
          sortField: sortField,
          sortDir: sortDir,
          onSortChanged: onSortChanged,
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        ...List.generate(rows.length, (i) {
          return Column(
            children: [
              _TableRow(
                item: rows[i],
                isSelected: selected.contains(i),
                onToggle: () => onToggleRow(i),
              ),
              if (i < rows.length - 1)
                const Divider(height: 1, color: AppTheme.borderColor),
            ],
          );
        }),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.allSelected,
    required this.onToggleAll,
    required this.sortField,
    required this.sortDir,
    required this.onSortChanged,
  });

  final bool allSelected;
  final VoidCallback onToggleAll;
  final _RiSortField sortField;
  final _RiSortDir sortDir;
  final ValueChanged<_RiSortField> onSortChanged;

  static const TextStyle _style = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppTheme.textMuted,
    letterSpacing: 0.5,
  );

  Widget _col(String label, _RiSortField field) {
    final isActive = sortField == field;
    final icon = isActive
        ? (sortDir == _RiSortDir.ascending
              ? LucideIcons.arrowUp
              : LucideIcons.arrowDown)
        : LucideIcons.chevronsUpDown;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onSortChanged(field),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: _style.copyWith(
                color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              icon,
              size: 11,
              color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: allSelected,
              onChanged: (_) => onToggleAll(),
              activeColor: AppTheme.primaryBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: _col('ITEM NAME', _RiSortField.itemName)),
          Expanded(
            flex: 2,
            child: _col('EXPECTED DATE', _RiSortField.expectedDate),
          ),
          const Expanded(flex: 2, child: Text('QUANTITY', style: _style)),
          Expanded(
            flex: 2,
            child: _col('REMAINING QUANTITY', _RiSortField.remainingQty),
          ),
          Expanded(flex: 2, child: _col('REQUEST#', _RiSortField.requestNo)),
        ],
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.item,
    required this.isSelected,
    required this.onToggle,
  });

  final _RequestedItem item;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isSelected
        ? AppTheme.primaryBlue.withValues(alpha: 0.06)
        : _hovered
        ? AppTheme.bgHover
        : Colors.white;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              child: Checkbox(
                value: widget.isSelected,
                onChanged: (_) => widget.onToggle(),
                activeColor: AppTheme.primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 4,
              child: Text(
                widget.item.itemName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textBody,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget.item.expectedDate,
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${widget.item.quantity}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '${widget.item.remainingQuantity}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                widget.item.requestNumber,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// More (···) button — top right
// ---------------------------------------------------------------------------

class _MoreButton extends StatefulWidget {
  const _MoreButton({
    required this.activeSortField,
    required this.onSortChanged,
    required this.onRefresh,
  });

  final _RiSortField activeSortField;
  final ValueChanged<_RiSortField> onSortChanged;
  final VoidCallback onRefresh;

  @override
  State<_MoreButton> createState() => _MoreButtonState();
}

class _MoreButtonState extends State<_MoreButton> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  void _toggle(BuildContext context) {
    if (_overlay != null) {
      _close();
      return;
    }
    _overlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 4),
            child: Align(
              alignment: Alignment.topRight,
              child: _MoreDropdownPanel(
                activeSortField: widget.activeSortField,
                onSortChanged: (field) {
                  widget.onSortChanged(field);
                  _close();
                },
                onRefresh: () {
                  widget.onRefresh();
                  _close();
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _overlay != null;
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: () => _toggle(context),
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isOpen
                  ? AppTheme.infoBlue.withValues(alpha: 0.08)
                  : Colors.white,
              border: Border.all(
                color: isOpen ? AppTheme.infoBlue : AppTheme.borderColor,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              LucideIcons.moreHorizontal,
              size: 16,
              color: isOpen ? AppTheme.infoBlue : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dropdown panel for the ··· overlay
// ---------------------------------------------------------------------------

class _MoreDropdownPanel extends StatelessWidget {
  const _MoreDropdownPanel({
    required this.activeSortField,
    required this.onSortChanged,
    required this.onRefresh,
  });

  final _RiSortField activeSortField;
  final ValueChanged<_RiSortField> onSortChanged;
  final VoidCallback onRefresh;

  static const _kSortItems = [
    (_RiSortField.itemName, 'Item Name'),
    (_RiSortField.expectedDate, 'Expected Date'),
    (_RiSortField.remainingQty, 'Remaining Quantity'),
    (_RiSortField.requestNo, 'Request#'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                'SORT BY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            ..._kSortItems.map((entry) {
              final (field, label) = entry;
              return _RiSortMenuItem(
                label: label,
                isActive: activeSortField == field,
                onTap: () => onSortChanged(field),
              );
            }),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1, color: AppTheme.borderColor),
            ),
            _RiActionMenuItem(
              icon: LucideIcons.refreshCw,
              label: 'Refresh List',
              onTap: onRefresh,
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sort / action enums
// ---------------------------------------------------------------------------

enum _RiSortField { itemName, expectedDate, remainingQty, requestNo }

enum _RiSortDir { ascending, descending }

// ---------------------------------------------------------------------------
// Sort menu item (blue highlight when active/hovered)
// ---------------------------------------------------------------------------

class _RiSortMenuItem extends StatefulWidget {
  const _RiSortMenuItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  State<_RiSortMenuItem> createState() => _RiSortMenuItemState();
}

class _RiSortMenuItemState extends State<_RiSortMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          color: _hovered
              ? AppTheme.infoBlue
              : widget.isActive
              ? AppTheme.bgHover
              : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color: _hovered ? Colors.white : AppTheme.textBody,
              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action menu item (icon + label)
// ---------------------------------------------------------------------------

class _RiActionMenuItem extends StatefulWidget {
  const _RiActionMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_RiActionMenuItem> createState() => _RiActionMenuItemState();
}

class _RiActionMenuItemState extends State<_RiActionMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          color: _hovered ? AppTheme.infoBlue : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: _hovered ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: _hovered ? Colors.white : AppTheme.textBody,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
