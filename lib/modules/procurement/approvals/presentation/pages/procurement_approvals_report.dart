// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/procurement/approvals/providers/approvals_refresh_provider.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

// ---------------------------------------------------------------------------
// Enums + Model
// ---------------------------------------------------------------------------

enum _ApprovalStatus { approved, pending, rejected }

enum _RequestType { all, purchaseRequest, purchaseOrder, bill }

enum _ApprovalStatusFilter { all, pending, approved, rejected }

class _Approval {
  _Approval({
    required this.submitter,
    required this.submittedOn,
    required this.requestType,
    required this.referenceNumber,
    required this.amount,
    required this.status,
  });

  final String submitter;
  final String submittedOn;
  final _RequestType requestType;
  final String referenceNumber;
  final double amount;
  final _ApprovalStatus status;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ProcurementApprovalsReportPage extends ConsumerStatefulWidget {
  const ProcurementApprovalsReportPage({super.key});

  @override
  ConsumerState<ProcurementApprovalsReportPage> createState() =>
      _ProcurementApprovalsReportPageState();
}

class _ProcurementApprovalsReportPageState
    extends ConsumerState<ProcurementApprovalsReportPage> {
  _ApprovalStatusFilter _statusFilter = _ApprovalStatusFilter.all;
  _RequestType _requestType = _RequestType.all;
  List<_Approval> _allRows = [];
  bool _isLoading = true;
  final Set<int> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('purchase_request_approval')
          .select('status, created_at, '
              'purchase_requests!inner('
              'request_number, '
              'users!assignee_id(full_name), '
              'purchase_request_items(estimated_amount)'
              ')')
          .order('created_at', ascending: false);

      final rows = (res as List<dynamic>).map((row) {
        final m = row as Map<String, dynamic>;
        final pr = m['purchase_requests'] as Map<String, dynamic>;
        final assigneeName =
            (pr['users'] as Map<String, dynamic>?)?['full_name'] as String? ?? '—';
        final items = (pr['purchase_request_items'] as List<dynamic>?) ?? [];
        final total = items.fold<double>(
          0,
          (s, i) => s + ((i as Map<String, dynamic>)['estimated_amount'] as num? ?? 0).toDouble(),
        );
        final statusStr = m['status'] as String? ?? 'PENDING';
        final approvalStatus = switch (statusStr) {
          'APPROVED' => _ApprovalStatus.approved,
          'REJECTED' => _ApprovalStatus.rejected,
          _ => _ApprovalStatus.pending,
        };
        final createdAt = DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now();
        final submittedOn =
            '${createdAt.day.toString().padLeft(2, '0')}-'
            '${createdAt.month.toString().padLeft(2, '0')}-'
            '${createdAt.year}';
        return _Approval(
          submitter: assigneeName,
          submittedOn: submittedOn,
          requestType: _RequestType.purchaseRequest,
          referenceNumber: pr['request_number'] as String? ?? '—',
          amount: total,
          status: approvalStatus,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _allRows = rows;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load approvals', error: e, module: 'ApprovalsReport');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<_Approval> get _filtered {
    final byType = _requestType == _RequestType.all
        ? _allRows
        : _allRows.where((a) => a.requestType == _requestType).toList();
    return switch (_statusFilter) {
      _ApprovalStatusFilter.all => byType,
      _ApprovalStatusFilter.pending =>
        byType.where((a) => a.status == _ApprovalStatus.pending).toList(),
      _ApprovalStatusFilter.approved =>
        byType.where((a) => a.status == _ApprovalStatus.approved).toList(),
      _ApprovalStatusFilter.rejected =>
        byType.where((a) => a.status == _ApprovalStatus.rejected).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Re-read after a decision is recorded on the overview, which sits above
    // this page in the route stack and leaves this State alive on the way back.
    ref.listen<int>(approvalsListRefreshProvider, (_, __) {
      _load();
    });

    return ZerpaiLayout(
      pageTitle: 'All Approvals',
      useHorizontalPadding: false,
      titlePadding: const EdgeInsets.only(left: 16),
      titleWidget: _ScopeTitleButton(
        statusFilter: _statusFilter,
        onChanged: (f) => setState(() {
          _statusFilter = f;
          _selected.clear();
        }),
      ),
      child: _isLoading
          ? const TableSkeleton(rows: 10, columns: 6)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RequestTypeFilter(
                  selected: _requestType,
                  onChanged: (t) => setState(() {
                    _requestType = t;
                    _selected.clear();
                  }),
                ),
                const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
                _ApprovalsTable(
                  rows: _filtered,
                  selected: _selected,
                  onToggle: (i) => setState(() {
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
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scope title button ("All Approvals ▼")
// ---------------------------------------------------------------------------

class _ScopeTitleButton extends StatefulWidget {
  const _ScopeTitleButton(
      {required this.statusFilter, required this.onChanged});

  final _ApprovalStatusFilter statusFilter;
  final ValueChanged<_ApprovalStatusFilter> onChanged;

  @override
  State<_ScopeTitleButton> createState() => _ScopeTitleButtonState();
}

class _ScopeTitleButtonState extends State<_ScopeTitleButton> {
  final _layerLink = LayerLink();
  final _buttonKey = GlobalKey();
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

    final box = _buttonKey.currentContext!.findRenderObject()! as RenderBox;
    final size = box.size;

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
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: _ScopeDropdownPanel(
                selected: widget.statusFilter,
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
    final label = switch (widget.statusFilter) {
      _ApprovalStatusFilter.all => 'All Approvals',
      _ApprovalStatusFilter.pending => 'Pending Approvals',
      _ApprovalStatusFilter.approved => 'Approved Approvals',
      _ApprovalStatusFilter.rejected => 'Rejected Approvals',
    };
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: _buttonKey,
          onTap: () => _toggle(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                _overlay != null
                    ? LucideIcons.chevronUp
                    : LucideIcons.chevronDown,
                size: 18,
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Scope dropdown panel ──────────────────────────────────────────────────────

class _ScopeDropdownPanel extends StatelessWidget {
  const _ScopeDropdownPanel({required this.selected, required this.onSelect});

  final _ApprovalStatusFilter selected;
  final ValueChanged<_ApprovalStatusFilter> onSelect;

  static const _options = [
    (_ApprovalStatusFilter.all, 'All'),
    (_ApprovalStatusFilter.pending, 'Pending'),
    (_ApprovalStatusFilter.approved, 'Approved'),
    (_ApprovalStatusFilter.rejected, 'Rejected'),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _options.map((opt) {
              final (filter, label) = opt;
              return _ScopeOption(
                label: label,
                isSelected: selected == filter,
                onTap: () => onSelect(filter),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ScopeOption extends StatefulWidget {
  const _ScopeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ScopeOption> createState() => _ScopeOptionState();
}

class _ScopeOptionState extends State<_ScopeOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: double.infinity,
          decoration: BoxDecoration(
            color: (!widget.isSelected && _hovered)
                ? AppTheme.infoBlue
                : Colors.transparent,
            borderRadius: AppTheme.hoverRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: widget.isSelected
              ? Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: AppTheme.primaryBlue, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  child: Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                )
              : Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color:
                        _hovered ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request type filter ("Select Request Type ∧")
// ---------------------------------------------------------------------------

class _RequestTypeFilter extends StatefulWidget {
  const _RequestTypeFilter({required this.selected, required this.onChanged});

  final _RequestType selected;
  final ValueChanged<_RequestType> onChanged;

  @override
  State<_RequestTypeFilter> createState() => _RequestTypeFilterState();
}

class _RequestTypeFilterState extends State<_RequestTypeFilter> {
  final _layerLink = LayerLink();
  final _rowKey = GlobalKey();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  String _label(_RequestType t) => switch (t) {
        _RequestType.all => 'Select Request Type',
        _RequestType.purchaseRequest => 'Purchase Request',
        _RequestType.purchaseOrder => 'Purchase Order',
        _RequestType.bill => 'Bill',
      };

  void _toggle(BuildContext context) {
    if (_overlay != null) {
      _overlay!.remove();
      _overlay = null;
      setState(() {});
      return;
    }

    final box = _rowKey.currentContext!.findRenderObject()! as RenderBox;
    final size = box.size;

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
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height),
            child: Align(
              alignment: Alignment.topLeft,
              child: _RequestTypeDropdown(
                selected: widget.selected,
                onSelect: (t) {
                  _overlay?.remove();
                  _overlay = null;
                  if (mounted) setState(() {});
                  widget.onChanged(t);
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
    final isExpanded = _overlay != null;
    final hasSelection = widget.selected != _RequestType.all;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          key: _rowKey,
          onTap: () => _toggle(context),
          child: Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _label(widget.selected),
                  style: TextStyle(
                    fontSize: 13,
                    color: hasSelection
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontWeight: hasSelection
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 14,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Request type dropdown panel ───────────────────────────────────────────────

class _RequestTypeDropdown extends StatefulWidget {
  const _RequestTypeDropdown({required this.selected, required this.onSelect});

  final _RequestType selected;
  final ValueChanged<_RequestType> onSelect;

  @override
  State<_RequestTypeDropdown> createState() => _RequestTypeDropdownState();
}

class _RequestTypeDropdownState extends State<_RequestTypeDropdown> {
  final _searchController = TextEditingController();
  String _search = '';
  _RequestType? _hovered;

  static const _options = [
    (_RequestType.purchaseRequest, 'Purchase Request'),
    (_RequestType.purchaseOrder, 'Purchase Order'),
    (_RequestType.bill, 'Bill'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _options
        .where(
            (o) => o.$2.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(LucideIcons.search,
                        size: 14, color: AppTheme.textSecondary),
                  ),
                  prefixIconConstraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 9),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryBlue, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryBlue, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(
                        color: AppTheme.primaryBlue, width: 2),
                  ),
                ),
              ),
            ),
            ...filtered.map((opt) {
              final (type, label) = opt;
              final isSelected = widget.selected == type;
              final isHovered = _hovered == type;

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _hovered = type),
                onExit: (_) => setState(() => _hovered = null),
                child: GestureDetector(
                  onTap: () => widget.onSelect(type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryBlue
                          : isHovered
                              ? AppTheme.infoBlue
                              : Colors.white,
                      borderRadius: AppTheme.hoverRadius,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        color: (isSelected || isHovered)
                            ? Colors.white
                            : AppTheme.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Table
// ---------------------------------------------------------------------------

class _ApprovalsTable extends StatelessWidget {
  const _ApprovalsTable({
    required this.rows,
    required this.selected,
    required this.onToggle,
    required this.onToggleAll,
  });

  final List<_Approval> rows;
  final Set<int> selected;
  final ValueChanged<int> onToggle;
  final VoidCallback onToggleAll;

  static const _headerStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppTheme.textMuted,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    final allSelected = rows.isNotEmpty && selected.length == rows.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppTheme.bgLight,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              const Expanded(
                flex: 4,
                child: Text('SUBMITTED BY', style: _headerStyle),
              ),
              const Expanded(
                flex: 3,
                child: Text('ENTITY TYPE', style: _headerStyle),
              ),
              const Expanded(
                flex: 3,
                child: Text('DETAILS', style: _headerStyle),
              ),
              const Expanded(
                flex: 2,
                child: Text('STATUS', style: _headerStyle),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        ...List.generate(rows.length, (i) {
          return Column(
            children: [
              _ApprovalRow(
                approval: rows[i],
                isSelected: selected.contains(i),
                onToggle: () => onToggle(i),
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

// ── Table row ─────────────────────────────────────────────────────────────────

class _ApprovalRow extends StatefulWidget {
  const _ApprovalRow({
    required this.approval,
    required this.isSelected,
    required this.onToggle,
  });

  final _Approval approval;
  final bool isSelected;
  final VoidCallback onToggle;

  @override
  State<_ApprovalRow> createState() => _ApprovalRowState();
}

class _ApprovalRowState extends State<_ApprovalRow> {
  bool _hovered = false;

  String _entityLabel(_RequestType t) => switch (t) {
        _RequestType.all => '',
        _RequestType.purchaseRequest => 'Purchase Request',
        _RequestType.purchaseOrder => 'Purchase Order',
        _RequestType.bill => 'Bill',
      };

  String _statusLabel(_ApprovalStatus s) => switch (s) {
        _ApprovalStatus.approved => 'APPROVED',
        _ApprovalStatus.pending => 'PENDING',
        _ApprovalStatus.rejected => 'REJECTED',
      };

  Color _statusColor(_ApprovalStatus s) => switch (s) {
        _ApprovalStatus.approved => AppTheme.successTextDark,
        _ApprovalStatus.pending => AppTheme.warningTextDark,
        _ApprovalStatus.rejected => AppTheme.errorTextDark,
      };

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      final parts = amount.toStringAsFixed(2).split('.');
      final intPart = parts[0];
      final decPart = parts[1];
      final buf = StringBuffer();
      int count = 0;
      for (int i = intPart.length - 1; i >= 0; i--) {
        buf.write(intPart[i]);
        count++;
        if (count == 3 && i != 0) {
          buf.write(',');
          count = 0;
        }
      }
      return '${buf.toString().split('').reversed.join()}.$decPart';
    }
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.approval;
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.pushNamed(
          AppRoutes.procurementApprovalsOverview,
          pathParameters: {'orgSystemId': orgSystemId},
          queryParameters: {'ref': a.referenceNumber},
        ),
        child: Container(
        color: widget.isSelected
            ? AppTheme.primaryBlue.withValues(alpha: 0.04)
            : _hovered
                ? AppTheme.bgDisabled
                : Colors.white,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: _SubmitterCell(
                name: a.submitter,
                submittedOn: a.submittedOn,
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _entityLabel(a.requestType),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textBody,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    a.referenceNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Amount: ₹${_formatAmount(a.amount)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _statusLabel(a.status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(a.status),
                    letterSpacing: 0.4,
                  ),
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

// ── Submitter cell ────────────────────────────────────────────────────────────

class _SubmitterCell extends StatelessWidget {
  const _SubmitterCell({required this.name, required this.submittedOn});

  final String name;
  final String submittedOn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textBody,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          'Submitted on: $submittedOn',
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }
}
