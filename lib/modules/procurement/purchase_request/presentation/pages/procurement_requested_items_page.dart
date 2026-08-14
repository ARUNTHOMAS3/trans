// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_selection_checkbox.dart';
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
    required this.view,
  });

  final String itemName;
  final String expectedDate;
  final double quantity;
  final double remainingQuantity;
  final String requestNumber;

  /// Which saved view this line belongs to, resolved once at load time.
  final _RiView view;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

/// The saved views offered by the title switcher. A requested item is [open]
/// while it still needs ordering, [onHold] when its request has been parked,
/// and [processed] once the line has been fully ordered.
enum _RiView { open, onHold, processed }

String _viewLabel(_RiView v) => switch (v) {
      _RiView.open => 'Open Requested Items',
      _RiView.onHold => 'On Hold Requested Items',
      _RiView.processed => 'Processed Requested Items',
    };

/// Rows are bucketed by the parent request's status and the line's own
/// `line_status`, so a held or finished request never shows up as outstanding.
_RiView _resolveView(String prStatus, String lineStatus, double remaining) {
  if (prStatus == 'ON_HOLD' || prStatus == 'ONHOLD') return _RiView.onHold;
  // A request with a purchase order raised against it is no longer outstanding.
  if (prStatus == 'ORDERED' ||
      prStatus == 'PROCESSED' ||
      lineStatus == 'PROCESSED' ||
      lineStatus == 'ORDERED' ||
      remaining <= 0) {
    return _RiView.processed;
  }
  return _RiView.open;
}

class ProcurementRequestedItemsPage extends ConsumerStatefulWidget {
  const ProcurementRequestedItemsPage({super.key});

  @override
  ConsumerState<ProcurementRequestedItemsPage> createState() =>
      _ProcurementRequestedItemsPageState();
}

class _ProcurementRequestedItemsPageState
    extends ConsumerState<ProcurementRequestedItemsPage> {
  _RiView _activeView = _RiView.open;
  final Set<int> _selected = {};
  _RiSortField _sortField = _RiSortField.itemName;
  _RiSortDir _sortDir = _RiSortDir.ascending;

  List<_RequestedItem> _allRows = [];
  bool _isLoading = true;
  int _page = 0;
  static const _kPageSize = 100;

  @override
  void initState() {
    super.initState();
    _loadRequestedItems();
  }

  Future<void> _loadRequestedItems() async {
    try {
      final res = await Supabase.instance.client
          .from('purchase_requests')
          .select('request_number, status, expected_date, '
              'purchase_request_items('
              'required_qty, pending_qty, line_status, '
              'products(product_name)'
              ')')
          .order('request_number');

      if (!mounted) return;

      final rows = <_RequestedItem>[];
      for (final pr in (res as List<dynamic>)) {
        final prMap = pr as Map<String, dynamic>;
        final prStatus = (prMap['status'] as String? ?? '').toUpperCase();
        // A rejected request is a dead end — its lines are not outstanding
        // work and belong in none of the three views.
        if (prStatus == 'REJECTED') continue;

        final requestNumber = prMap['request_number'] as String? ?? '';
        final expected = _fmtDate(prMap['expected_date'] as String?);
        final items =
            (prMap['purchase_request_items'] as List<dynamic>?) ?? const [];

        for (final row in items) {
          final m = row as Map<String, dynamic>;
          final required = (m['required_qty'] as num?)?.toDouble() ?? 0;
          final pending = (m['pending_qty'] as num?)?.toDouble() ?? 0;
          final lineStatus = (m['line_status'] as String? ?? '').toUpperCase();
          final product = m['products'] as Map<String, dynamic>?;

          rows.add(
            _RequestedItem(
              itemName: product?['product_name'] as String? ?? 'Unnamed item',
              expectedDate: expected,
              quantity: required,
              remainingQuantity: pending,
              requestNumber: requestNumber,
              view: _resolveView(prStatus, lineStatus, pending),
            ),
          );
        }
      }

      setState(() {
        _allRows = rows;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load requested items',
          error: e, module: 'RequestedItems');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_RequestedItem> get _filtered {
    final base = _allRows.where((r) => r.view == _activeView).toList();
    base.sort((a, b) {
      final cmp = switch (_sortField) {
        _RiSortField.itemName     => a.itemName.compareTo(b.itemName),
        _RiSortField.expectedDate => a.expectedDate.compareTo(b.expectedDate),
        _RiSortField.remainingQty =>
          a.remainingQuantity.compareTo(b.remainingQuantity),
        _RiSortField.requestNo => a.requestNumber.compareTo(b.requestNumber),
      };
      return _sortDir == _RiSortDir.ascending ? cmp : -cmp;
    });
    return base;
  }

  /// The slice of [_filtered] currently on screen.
  List<_RequestedItem> get _pageRows {
    final all = _filtered;
    final start = (_page * _kPageSize).clamp(0, all.length);
    final end = (start + _kPageSize).clamp(0, all.length);
    return all.sublist(start, end);
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
      _selected.clear();
    });
  }

  void _onRefresh() {
    setState(() {
      _activeView = _RiView.open;
      _sortField = _RiSortField.itemName;
      _sortDir = _RiSortDir.ascending;
      _selected.clear();
      _page = 0;
      _isLoading = true;
    });
    _loadRequestedItems();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _pageRows;
    final total = _filtered.length;
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';

    return ZerpaiLayout(
      pageTitle: '',
      titleWidget: _ViewSwitcherTitle(
        activeView: _activeView,
        onBack: () => context.goNamed(
          AppRoutes.procurementPurchaseRequests,
          pathParameters: {'orgSystemId': orgSystemId},
        ),
        onViewChanged: (v) => setState(() {
          _activeView = v;
          _selected.clear();
          _page = 0;
        }),
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
          if (_selected.isNotEmpty)
            _RiSelectionBar(
              count: _selected.length,
              onClear: () => setState(() => _selected.clear()),
            ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Center(
                child: Text(
                  'No ${_viewLabel(_activeView).toLowerCase()} found.',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            // Table fills full width so the grey header background is
            // edge-to-edge
            _ItemsTable(
              rows: rows,
              orgSystemId: orgSystemId,
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
                if (_selected.length == rows.length) {
                  _selected.clear();
                } else {
                  _selected
                    ..clear()
                    ..addAll(List.generate(rows.length, (i) => i));
                }
              }),
            ),
          const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
          if (!_isLoading && total > 0)
            _RiFooter(
              total: total,
              page: _page,
              pageSize: _kPageSize,
              onPageChanged: (p) => setState(() {
                _page = p;
                _selected.clear();
              }),
            ),
        ],
      ),
    );
  }
}

/// Quantities carry a decimal scale in the DB but read as whole units.
String _fmtQty(double q) =>
    q == q.roundToDouble() ? q.toStringAsFixed(0) : q.toStringAsFixed(2);

/// `expected_date` arrives as YYYY-MM-DD; the grid shows DD-MM-YYYY.
String _fmtDate(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  final parts = raw.split('-');
  if (parts.length != 3) return raw;
  return '${parts[2]}-${parts[1]}-${parts[0]}';
}

// ---------------------------------------------------------------------------
// Breadcrumb title (renders inside ZerpaiLayout titleWidget)
// ---------------------------------------------------------------------------

/// Back chevron + "Purchase Requests" breadcrumb above the active view name,
/// which itself opens the saved-view switcher.
class _ViewSwitcherTitle extends StatefulWidget {
  const _ViewSwitcherTitle({
    required this.activeView,
    required this.onBack,
    required this.onViewChanged,
  });

  final _RiView activeView;
  final VoidCallback onBack;
  final ValueChanged<_RiView> onViewChanged;

  @override
  State<_ViewSwitcherTitle> createState() => _ViewSwitcherTitleState();
}

class _ViewSwitcherTitleState extends State<_ViewSwitcherTitle> {
  final _link = LayerLink();
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
            offset: const Offset(0, 40),
            child: Align(
              alignment: Alignment.topLeft,
              child: _RiViewDropdown(
                active: widget.activeView,
                onSelect: (v) {
                  _close();
                  widget.onViewChanged(v);
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BackChevron(onTap: widget.onBack),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: widget.onBack,
              child: const MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  'Purchase Requests',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 2),
            CompositedTransformTarget(
              link: _link,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _toggle(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _viewLabel(widget.activeView),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        isOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 20,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BackChevron extends StatefulWidget {
  const _BackChevron({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_BackChevron> createState() => _BackChevronState();
}

class _BackChevronState extends State<_BackChevron> {
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
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.bgHover : Colors.white,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            LucideIcons.chevronLeft,
            size: 16,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Saved-view menu hanging off the page title.
class _RiViewDropdown extends StatefulWidget {
  const _RiViewDropdown({required this.active, required this.onSelect});

  final _RiView active;
  final ValueChanged<_RiView> onSelect;

  @override
  State<_RiViewDropdown> createState() => _RiViewDropdownState();
}

class _RiViewDropdownState extends State<_RiViewDropdown> {
  _RiView? _hovered;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 260,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderColor),
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
          children: _RiView.values.map((view) {
            final isActive = view == widget.active;
            final isHovered = _hovered == view;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = view),
              onExit: (_) => setState(() => _hovered = null),
              child: GestureDetector(
                onTap: () => widget.onSelect(view),
                child: Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? AppTheme.primaryBlue
                        : isActive
                            ? AppTheme.infoBg
                            : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isActive && !isHovered
                          ? AppTheme.primaryBlue
                          : Colors.transparent,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 11),
                  child: Text(
                    _viewLabel(view),
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
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer — total count + pagination
// ---------------------------------------------------------------------------

class _RiFooter extends StatelessWidget {
  const _RiFooter({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.onPageChanged,
  });

  final int total;
  final int page;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final start = page * pageSize + 1;
    final end = ((page + 1) * pageSize).clamp(0, total);
    final hasPrev = page > 0;
    final hasNext = end < total;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(
            'Total Count: $total',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const Spacer(),
          Text(
            '$start - $end',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          _PageArrow(
            icon: LucideIcons.chevronLeft,
            enabled: hasPrev,
            onTap: () => onPageChanged(page - 1),
          ),
          const SizedBox(width: 4),
          _PageArrow(
            icon: LucideIcons.chevronRight,
            enabled: hasNext,
            onTap: () => onPageChanged(page + 1),
          ),
        ],
      ),
    );
  }
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: enabled ? AppTheme.textSecondary : AppTheme.textMuted,
          ),
        ),
      ),
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
  final _createKey  = GlobalKey();
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
                    horizontal: 14, vertical: 8),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
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
              child: Icon(LucideIcons.x,
                  size: 18, color: AppTheme.errorRed),
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
              onExit:  (_) => setState(() => _hovered = null),
              child: GestureDetector(
                onTap: () => widget.onSelect(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isHovered ? AppTheme.primaryBlue : Colors.white,
                    borderRadius: AppTheme.hoverRadius,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: isHovered
                          ? Colors.white
                          : AppTheme.textPrimary,
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
// Table
// ---------------------------------------------------------------------------

class _ItemsTable extends StatelessWidget {
  const _ItemsTable({
    required this.rows,
    required this.orgSystemId,
    required this.selected,
    required this.sortField,
    required this.sortDir,
    required this.onSortChanged,
    required this.onToggleRow,
    required this.onToggleAll,
  });

  final List<_RequestedItem> rows;
  final String orgSystemId;
  final Set<int> selected;
  final _RiSortField sortField;
  final _RiSortDir sortDir;
  final ValueChanged<_RiSortField> onSortChanged;
  final ValueChanged<int> onToggleRow;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final allSelected = rows.isNotEmpty && selected.length == rows.length;
    // Partial selection drives the header's indeterminate dash.
    final someSelected = selected.isNotEmpty && !allSelected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TableHeader(
          allSelected: allSelected,
          someSelected: someSelected,
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
                orgSystemId: orgSystemId,
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
    required this.someSelected,
    required this.onToggleAll,
    required this.sortField,
    required this.sortDir,
    required this.onSortChanged,
  });

  final bool allSelected;
  final bool someSelected;
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
            child: ZSelectionCheckbox(
              value: someSelected ? null : allSelected,
              onChanged: (_) => onToggleAll(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(flex: 4, child: _col('ITEM NAME', _RiSortField.itemName)),
          Expanded(
              flex: 2,
              child: _col('EXPECTED DATE', _RiSortField.expectedDate)),
          const Expanded(
            flex: 2,
            child: Text('QUANTITY', style: _style),
          ),
          Expanded(
              flex: 2,
              child: _col('REMAINING QUANTITY', _RiSortField.remainingQty)),
          Expanded(
              flex: 3,
              child: _col('PURCHASE REQUEST NUMBER', _RiSortField.requestNo)),
        ],
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.item,
    required this.orgSystemId,
    required this.isSelected,
    required this.onToggle,
  });

  final _RequestedItem item;
  final String orgSystemId;
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
              child: ZSelectionCheckbox(
                value: widget.isSelected,
                onChanged: (_) => widget.onToggle(),
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
                _fmtQty(widget.item.quantity),
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _fmtQty(widget.item.remainingQuantity),
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            Expanded(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.goNamed(
                      AppRoutes.procurementPurchaseRequestOverview,
                      pathParameters: {
                        'orgSystemId': widget.orgSystemId,
                        'id': widget.item.requestNumber,
                      },
                    ),
                    child: Text(
                      widget.item.requestNumber,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
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
    (_RiSortField.itemName,     'Item Name'),
    (_RiSortField.expectedDate, 'Expected Date'),
    (_RiSortField.remainingQty, 'Remaining Quantity'),
    (_RiSortField.requestNo,    'Request#'),
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
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.infoBlue
                : widget.isActive
                    ? AppTheme.bgHover
                    : Colors.white,
            borderRadius: AppTheme.hoverRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color: _hovered ? Colors.white : AppTheme.textBody,
              fontWeight:
                  widget.isActive ? FontWeight.w600 : FontWeight.w400,
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
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.infoBlue : Colors.white,
            borderRadius: AppTheme.hoverRadius,
          ),
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
