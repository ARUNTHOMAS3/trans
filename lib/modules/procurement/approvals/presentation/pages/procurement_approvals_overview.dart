// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/procurement/approvals/presentation/widgets/procurement_approvals_flow_panel.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum _ApprovalStatus { approved, pending, rejected }

enum _EntityType { purchaseRequest, purchaseOrder, bill }

enum _StatusFilter { all, pending, approved, rejected }

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class _ProcessingStatus {
  const _ProcessingStatus({
    required this.rfqStatus,
    required this.poStatus,
    required this.receiveStatus,
    required this.billStatus,
  });
  final String rfqStatus;
  final String poStatus;
  final String receiveStatus;
  final String billStatus;
}

class _ApprovalItem {
  const _ApprovalItem({
    required this.name,
    required this.category,
    required this.description,
    required this.preferredVendor,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.discount,
    required this.estimatedAmount,
  });
  final String name;
  final String category;
  final String description;
  final String preferredVendor;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double discount;
  final double estimatedAmount;
}

class _ApprovalDetail {
  const _ApprovalDetail({
    required this.approvalId,
    required this.submitter,
    required this.submittedOn,
    required this.entityType,
    required this.referenceNumber,
    required this.amount,
    required this.status,
    required this.expectedDate,
    required this.processingStatus,
    required this.approver,
    this.approverEmail,
    this.reason,
    this.notesToApprover,
    this.internalNotes,
    this.rejectionReason,
    this.prReferenceNumber,
    required this.deliveryAddress,
    required this.items,
  });

  final String approvalId;
  final String submitter;
  final String submittedOn;
  final _EntityType entityType;
  /// The PR's own document number (PR-00001) — identifies the request.
  final String referenceNumber;
  final double amount;
  final _ApprovalStatus status;
  final String expectedDate;
  final _ProcessingStatus processingStatus;
  final String approver;
  final String? approverEmail;
  /// Requester-entered fields from the create form.
  final String? reason;
  final String? notesToApprover;
  final String? internalNotes;
  /// The approver's rejection note — unrelated to [reason].
  final String? rejectionReason;
  /// The requester's own Reference# (e.g. an external doc number).
  final String? prReferenceNumber;
  final String? deliveryAddress;
  final List<_ApprovalItem> items;
}

/// Empty/unset text fields render as an em dash rather than a blank gap.
String _display(String? value) =>
    (value == null || value.trim().isEmpty) ? '—' : value.trim();

// ---------------------------------------------------------------------------
// Default processing status — RFQ/PO/receive/bill flows are not wired up yet
// ---------------------------------------------------------------------------

const _kDefaultProcessing = _ProcessingStatus(
  rfqStatus: 'Yet to be Created',
  poStatus: 'Yet to be Ordered',
  receiveStatus: 'Yet to be Received',
  billStatus: 'Yet to be Billed',
);

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ProcurementApprovalsOverviewPage extends ConsumerStatefulWidget {
  const ProcurementApprovalsOverviewPage({super.key, this.initialRef});

  final String? initialRef;

  @override
  ConsumerState<ProcurementApprovalsOverviewPage> createState() =>
      _ProcurementApprovalsOverviewPageState();
}

class _ProcurementApprovalsOverviewPageState
    extends ConsumerState<ProcurementApprovalsOverviewPage> {
  int _selectedIndex = 0;
  _StatusFilter _statusFilter = _StatusFilter.all;
  OverlayEntry? _approvalFlowOverlay;
  OverlayEntry? _toastOverlay;
  bool _isOnHold = false;
  String _holdReason = '';
  bool _isApproved = false;
  bool _isProcessed = false;
  bool _isRejected = false;
  String _rejectReason = '';
  List<_ApprovalDetail> _approvals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApprovals();
  }

  @override
  void dispose() {
    _approvalFlowOverlay?.remove();
    _approvalFlowOverlay = null;
    _toastOverlay?.remove();
    _toastOverlay = null;
    super.dispose();
  }

  Future<void> _loadApprovals() async {
    setState(() => _isLoading = true);
    try {
      final res = await Supabase.instance.client
          .from('purchase_request_approval')
          .select('id, status, rejection_reason, notes, created_at, '
              'purchase_requests!inner('
              'request_number, expected_date, reason, reference_number, '
              'internal_notes, notes_to_approver, delivery_address, '
              'users!assignee_id(full_name, email), '
              'purchase_request_items('
              'required_qty, estimated_rate, estimated_amount, '
              'discount_percentage, description, '
              'products!inner(product_name), '
              'categories(name), '
              'vendors!preferred_vendor_id(display_name)'
              ')'
              ')')
          .order('created_at', ascending: false);

      final approvals = (res as List<dynamic>).map((row) {
        final m = row as Map<String, dynamic>;
        final pr = m['purchase_requests'] as Map<String, dynamic>;
        final assigneeUser = pr['users'] as Map<String, dynamic>?;
        final assigneeName = assigneeUser?['full_name'] as String? ?? '—';
        final assigneeEmail = assigneeUser?['email'] as String?;

        final rawItems = (pr['purchase_request_items'] as List<dynamic>?) ?? [];
        final total = rawItems.fold<double>(
          0,
          (s, i) => s + ((i as Map<String, dynamic>)['estimated_amount'] as num? ?? 0).toDouble(),
        );

        final approvalItems = rawItems.map((item) {
          final im = item as Map<String, dynamic>;
          final productName =
              (im['products'] as Map<String, dynamic>?)?['product_name'] as String? ?? '—';
          final categoryName =
              (im['categories'] as Map<String, dynamic>?)?['name'] as String?;
          final vendorName =
              (im['vendors'] as Map<String, dynamic>?)?['display_name'] as String?;
          return _ApprovalItem(
            name: productName,
            category: _display(categoryName),
            description: _display(im['description'] as String?),
            preferredVendor: _display(vendorName),
            quantity: ((im['required_qty'] as num?)?.toDouble() ?? 0).round(),
            unit: 'pcs',
            unitPrice: (im['estimated_rate'] as num?)?.toDouble() ?? 0,
            discount: (im['discount_percentage'] as num?)?.toDouble() ?? 0,
            estimatedAmount: (im['estimated_amount'] as num?)?.toDouble() ?? 0,
          );
        }).toList();

        final statusStr = m['status'] as String? ?? 'PENDING';
        final approvalStatus = switch (statusStr) {
          'APPROVED' => _ApprovalStatus.approved,
          'REJECTED' => _ApprovalStatus.rejected,
          _ => _ApprovalStatus.pending,
        };

        final createdAt =
            DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now();
        final submittedOn =
            '${createdAt.day.toString().padLeft(2, '0')}-'
            '${createdAt.month.toString().padLeft(2, '0')}-'
            '${createdAt.year}';

        final expectedDateRaw = pr['expected_date'] as String?;
        String expectedDate = '—';
        if (expectedDateRaw != null && expectedDateRaw.isNotEmpty) {
          final parts = expectedDateRaw.split('-');
          if (parts.length == 3) expectedDate = '${parts[2]}-${parts[1]}-${parts[0]}';
        }

        return _ApprovalDetail(
          approvalId: m['id'] as String,
          submitter: assigneeName,
          submittedOn: submittedOn,
          entityType: _EntityType.purchaseRequest,
          referenceNumber: pr['request_number'] as String? ?? '—',
          amount: total,
          status: approvalStatus,
          expectedDate: expectedDate,
          processingStatus: _kDefaultProcessing,
          approver: assigneeName,
          approverEmail: assigneeEmail,
          reason: pr['reason'] as String?,
          notesToApprover: pr['notes_to_approver'] as String?,
          internalNotes: pr['internal_notes'] as String?,
          rejectionReason: m['rejection_reason'] as String?,
          prReferenceNumber: pr['reference_number'] as String?,
          deliveryAddress: pr['delivery_address'] as String?,
          items: approvalItems,
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _approvals = approvals;
        _isLoading = false;
        if (widget.initialRef != null) {
          final idx = _approvals.indexWhere((a) => a.referenceNumber == widget.initialRef);
          if (idx >= 0) _selectedIndex = idx;
        }
      });
    } catch (e) {
      AppLogger.error('Failed to load approvals', error: e, module: 'ApprovalsOverview');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(BuildContext ctx, String message) {
    _toastOverlay?.remove();
    _toastOverlay = OverlayEntry(
      builder: (_) => _ActionToast(message: message),
    );
    Overlay.of(ctx).insert(_toastOverlay!);
    Future.delayed(const Duration(milliseconds: 2500), () {
      _toastOverlay?.remove();
      _toastOverlay = null;
    });
  }

  void _confirmApproved(BuildContext ctx) {
    final selected = _filtered.isEmpty
        ? null
        : _filtered[_selectedIndex.clamp(0, _filtered.length - 1)];
    if (selected != null) {
      final supabase = Supabase.instance.client;
      supabase
          .from('purchase_request_approval')
          .update({'status': 'APPROVED', 'approved_at': DateTime.now().toIso8601String()})
          .eq('id', selected.approvalId)
          .then((_) => supabase
              .from('purchase_requests')
              .update({'status': 'APPROVED'})
              .eq('request_number', selected.referenceNumber))
          // Only now (on approval) does this PR's qty count against the demand
          // pool: planned_qty increases and pending (balance) reduces.
          .then((_) => _applyApprovedQtyToDemandPool(selected.referenceNumber))
          .catchError((e) => AppLogger.error('Failed to approve PR', error: e, module: 'ApprovalsOverview'));
    }
    setState(() {
      _isApproved = true;
      _isRejected = false;
      _rejectReason = '';
    });
    _showToast(ctx, 'Purchase request approved');
  }

  /// On approval, allocate this PR's procured quantities against its linked
  /// demand_pool rows: planned_qty accumulates, pending (balance) = required −
  /// planned, and a fully-planned row is marked FULFILLED (drops off the pool).
  Future<void> _applyApprovedQtyToDemandPool(String requestNumber) async {
    final supabase = Supabase.instance.client;

    final pr = await supabase
        .from('purchase_requests')
        .select('id')
        .eq('request_number', requestNumber)
        .maybeSingle();
    if (pr == null) return;
    final prId = pr['id'] as String;

    // Qty this PR actually plans to procure, per product. Use planned_qty (what
    // the buyer entered), NOT required_qty (the full read-only demand). Reducing
    // by required_qty would always zero the pool balance and drop the item even
    // when only part of it was planned.
    final items = await supabase
        .from('purchase_request_items')
        .select('product_id, planned_qty')
        .eq('purchase_request_id', prId);
    final procuredByProduct = <String, double>{};
    for (final it in items as List<dynamic>) {
      final m = it as Map<String, dynamic>;
      final pid = m['product_id'] as String? ?? '';
      if (pid.isEmpty) continue;
      procuredByProduct[pid] =
          (procuredByProduct[pid] ?? 0) + ((m['planned_qty'] as num?)?.toDouble() ?? 0);
    }
    if (procuredByProduct.isEmpty) return;

    // Demand pool rows linked to this PR.
    final dpRows = await supabase
        .from('demand_pool')
        .select('id, product_id, required_qty, planned_qty')
        .eq('purchase_request_id', prId);

    final byProduct = <String, List<Map<String, dynamic>>>{};
    for (final r in dpRows as List<dynamic>) {
      final m = r as Map<String, dynamic>;
      (byProduct[m['product_id'] as String? ?? ''] ??= []).add(m);
    }

    final futures = <Future>[];
    for (final entry in byProduct.entries) {
      final rows = entry.value;
      final procured = procuredByProduct[entry.key] ?? 0;
      // Distribute the procured qty across rows proportionally by required_qty.
      final totalWeight = rows.fold<double>(
        0, (s, r) => s + (((r['required_qty'] as num?)?.toDouble()) ?? 0),
      );
      for (final r in rows) {
        final id = r['id'] as String;
        final reqQty = ((r['required_qty'] as num?)?.toDouble()) ?? 0;
        final curPlanned = ((r['planned_qty'] as num?)?.toDouble()) ?? 0;
        final share = totalWeight > 0 ? reqQty / totalWeight : 1.0;
        final newPlanned = (curPlanned + procured * share).clamp(0.0, reqQty);
        final newPending = (reqQty - newPlanned).clamp(0.0, double.infinity);
        futures.add(
          supabase.from('demand_pool').update({
            'planned_qty': newPlanned,
            'pending_qty': newPending,
            'status': newPending <= 0 ? 'FULFILLED' : 'PR_CREATED',
          }).eq('id', id),
        );
      }
    }
    if (futures.isNotEmpty) await Future.wait(futures);
  }

  void _confirmProcessed(BuildContext ctx) {
    setState(() => _isProcessed = true);
    _showToast(ctx, 'Purchase request processed');
  }

  void _confirmReject(BuildContext ctx, String reason) {
    final selected = _filtered.isEmpty
        ? null
        : _filtered[_selectedIndex.clamp(0, _filtered.length - 1)];
    if (selected != null) {
      Supabase.instance.client
          .from('purchase_request_approval')
          .update({
            'status': 'REJECTED',
            'rejection_reason': reason,
            'rejected_at': DateTime.now().toIso8601String(),
          })
          .eq('id', selected.approvalId)
          .catchError((e) => AppLogger.error('Failed to reject PR', error: e, module: 'ApprovalsOverview'));
    }
    setState(() {
      _isRejected = true;
      _rejectReason = reason;
    });
    _showToast(ctx, 'Purchase request rejected');
  }

  void _showApprovalFlow(BuildContext context, _ApprovalDetail approval) {
    _approvalFlowOverlay?.remove();
    _approvalFlowOverlay = OverlayEntry(
      builder: (_) => ApprovalFlowPanel(
        entry: ApprovalFlowEntry(
          approver: approval.approver,
          approverEmail: approval.approverEmail,
          status: switch (approval.status) {
            _ApprovalStatus.approved => ApprovalFlowStatus.approved,
            _ApprovalStatus.rejected => ApprovalFlowStatus.rejected,
            _ApprovalStatus.pending => ApprovalFlowStatus.pending,
          },
          submittedOn: approval.submittedOn,
        ),
        onClose: _hideApprovalFlow,
      ),
    );
    Overlay.of(context).insert(_approvalFlowOverlay!);
  }

  void _hideApprovalFlow() {
    _approvalFlowOverlay?.remove();
    _approvalFlowOverlay = null;
  }

  List<_ApprovalDetail> get _filtered => switch (_statusFilter) {
        _StatusFilter.all => _approvals,
        _StatusFilter.pending =>
          _approvals.where((a) => a.status == _ApprovalStatus.pending).toList(),
        _StatusFilter.approved =>
          _approvals.where((a) => a.status == _ApprovalStatus.approved).toList(),
        _StatusFilter.rejected =>
          _approvals.where((a) => a.status == _ApprovalStatus.rejected).toList(),
      };

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return ZerpaiLayout(
        pageTitle: '',
        useHorizontalPadding: false,
        useTopPadding: false,
        enableBodyScroll: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left panel skeleton — approval list
            Container(
              width: 460,
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppTheme.borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Tab bar
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: Row(
                      children: [
                        Skeleton(width: 60, height: 14),
                        SizedBox(width: 20),
                        Skeleton(width: 80, height: 14),
                        SizedBox(width: 20),
                        Skeleton(width: 70, height: 14),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  Expanded(
                    child: ListView.separated(
                      itemCount: 8,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: AppTheme.borderColor),
                      itemBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Skeleton(width: 90, height: 13),
                                Spacer(),
                                Skeleton(width: 60, height: 22, borderRadius: 4),
                              ],
                            ),
                            SizedBox(height: 8),
                            Skeleton(width: 160, height: 12),
                            SizedBox(height: 6),
                            Skeleton(width: 120, height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Right panel skeleton — approval detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header bar
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Skeleton(width: 180, height: 22),
                              SizedBox(height: 8),
                              Skeleton(width: 120, height: 14),
                            ],
                          ),
                        ),
                        Skeleton(width: 80, height: 34, borderRadius: 6),
                        SizedBox(width: 8),
                        Skeleton(width: 100, height: 34, borderRadius: 6),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppTheme.borderColor),
                  // Items table
                  const Expanded(
                    child: TableSkeleton(rows: 8, columns: 5, showHeader: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final filtered = _filtered;
    final safeIndex = _selectedIndex.clamp(0, (filtered.length - 1).clamp(0, 9999));
    final selected = filtered.isEmpty ? null : filtered[safeIndex];

    return ZerpaiLayout(
      pageTitle: '',
      useHorizontalPadding: false,
      useTopPadding: false,
      enableBodyScroll: false,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 460,
            child: _LeftPanel(
              approvals: filtered,
              selectedIndex: safeIndex,
              statusFilter: _statusFilter,
              onSelect: (i) => setState(() {
                _selectedIndex = i;
                _isApproved = false;
                _isOnHold = false;
                _holdReason = '';
                _isProcessed = false;
                _isRejected = false;
                _rejectReason = '';
              }),
              onFilterChanged: (f) => setState(() {
                _statusFilter = f;
                _selectedIndex = 0;
                _isApproved = false;
                _isOnHold = false;
                _holdReason = '';
                _isProcessed = false;
                _isRejected = false;
                _rejectReason = '';
              }),
            ),
          ),
          const VerticalDivider(
              width: 1, thickness: 1, color: AppTheme.borderColor),
          Expanded(
            child: selected == null
                ? const Center(
                    child: Text(
                      'No approvals found.',
                      style: TextStyle(
                          fontSize: 14, color: AppTheme.textSecondary),
                    ),
                  )
                : _DetailPanel(
                    approval: selected,
                    onViewApprovalFlow: () =>
                        _showApprovalFlow(context, selected),
                    isOnHold: _isOnHold,
                    holdReason: _holdReason,
                    onConfirmOnHold: (reason) => setState(() {
                      _isOnHold = true;
                      _holdReason = reason;
                    }),
                    onUndoOnHold: () => setState(() {
                      _isOnHold = false;
                      _holdReason = '';
                    }),
                    isProcessed: _isProcessed,
                    onConfirmProcessed: () => _confirmProcessed(context),
                    onUndoProcessed: () =>
                        setState(() => _isProcessed = false),
                    isApproved: _isApproved,
                    onConfirmApproved: () => _confirmApproved(context),
                    isRejected: _isRejected,
                    rejectReason: _rejectReason,
                    onConfirmReject: (reason) =>
                        _confirmReject(context, reason),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Left panel
// ---------------------------------------------------------------------------

class _LeftPanel extends StatelessWidget {
  const _LeftPanel({
    required this.approvals,
    required this.selectedIndex,
    required this.statusFilter,
    required this.onSelect,
    required this.onFilterChanged,
  });

  final List<_ApprovalDetail> approvals;
  final int selectedIndex;
  final _StatusFilter statusFilter;
  final ValueChanged<int> onSelect;
  final ValueChanged<_StatusFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LeftPanelHeader(
          statusFilter: statusFilter,
          onFilterChanged: onFilterChanged,
        ),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
        Expanded(
          child: ListView.separated(
            itemCount: approvals.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.borderColor),
            itemBuilder: (context, i) => _ApprovalListTile(
              approval: approvals[i],
              isSelected: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Left panel header ─────────────────────────────────────────────────────────

class _LeftPanelHeader extends StatefulWidget {
  const _LeftPanelHeader(
      {required this.statusFilter, required this.onFilterChanged});

  final _StatusFilter statusFilter;
  final ValueChanged<_StatusFilter> onFilterChanged;

  @override
  State<_LeftPanelHeader> createState() => _LeftPanelHeaderState();
}

class _LeftPanelHeaderState extends State<_LeftPanelHeader> {
  final _layerLink = LayerLink();
  final _chipKey = GlobalKey();
  OverlayEntry? _overlay;

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  String get _label => switch (widget.statusFilter) {
        _StatusFilter.all => 'All Approvals',
        _StatusFilter.pending => 'Pending',
        _StatusFilter.approved => 'Approved',
        _StatusFilter.rejected => 'Rejected',
      };

  void _toggle(BuildContext context) {
    if (_overlay != null) {
      _overlay!.remove();
      _overlay = null;
      setState(() {});
      return;
    }
    final box = _chipKey.currentContext!.findRenderObject()! as RenderBox;
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
              child: _StatusFilterDropdown(
                selected: widget.statusFilter,
                onSelect: (f) {
                  _overlay?.remove();
                  _overlay = null;
                  if (mounted) setState(() {});
                  widget.onFilterChanged(f);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: CompositedTransformTarget(
        link: _layerLink,
        child: GestureDetector(
          key: _chipKey,
          onTap: () => _toggle(context),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryBlue, width: 1.5),
                borderRadius: BorderRadius.circular(8),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _overlay != null
                        ? LucideIcons.chevronUp
                        : LucideIcons.chevronDown,
                    size: 16,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Status filter dropdown ────────────────────────────────────────────────────

class _StatusFilterDropdown extends StatelessWidget {
  const _StatusFilterDropdown(
      {required this.selected, required this.onSelect});

  final _StatusFilter selected;
  final ValueChanged<_StatusFilter> onSelect;

  static const _options = [
    (_StatusFilter.all, 'All'),
    (_StatusFilter.pending, 'Pending'),
    (_StatusFilter.approved, 'Approved'),
    (_StatusFilter.rejected, 'Rejected'),
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
            children: _options
                .map((opt) => _StatusFilterOption(
                      label: opt.$2,
                      isSelected: selected == opt.$1,
                      onTap: () => onSelect(opt.$1),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _StatusFilterOption extends StatefulWidget {
  const _StatusFilterOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_StatusFilterOption> createState() => _StatusFilterOptionState();
}

class _StatusFilterOptionState extends State<_StatusFilterOption> {
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
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

// ── List tile ─────────────────────────────────────────────────────────────────

class _ApprovalListTile extends StatefulWidget {
  const _ApprovalListTile({
    required this.approval,
    required this.isSelected,
    required this.onTap,
  });

  final _ApprovalDetail approval;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_ApprovalListTile> createState() => _ApprovalListTileState();
}

class _ApprovalListTileState extends State<_ApprovalListTile> {
  bool _hovered = false;

  String _entityLabel(_EntityType t) => switch (t) {
        _EntityType.purchaseRequest => 'Purchase Request',
        _EntityType.purchaseOrder => 'Purchase Order',
        _EntityType.bill => 'Bill',
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

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final dec = parts[1];
    if (intPart.length <= 3) return '₹$intPart.$dec';
    final buf = StringBuffer();
    int count = 0;
    for (var i = intPart.length - 1; i >= 0; i--) {
      buf.write(intPart[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write(',');
        count = 0;
      }
    }
    return '₹${buf.toString().split('').reversed.join('')}.$dec';
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.approval;
    final bg = widget.isSelected
        ? AppTheme.primaryBlue.withValues(alpha: 0.06)
        : _hovered
            ? AppTheme.bgDisabled
            : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      a.submitter,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _fmt(a.amount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    a.referenceNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Text('•',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textMuted)),
                  ),
                  Text(
                    a.submittedOn,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const Spacer(),
                  Text(
                    _statusLabel(a.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(a.status),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _entityLabel(a.entityType),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail panel
// ---------------------------------------------------------------------------

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.approval,
    required this.onViewApprovalFlow,
    required this.isOnHold,
    required this.holdReason,
    required this.onConfirmOnHold,
    required this.onUndoOnHold,
    required this.isProcessed,
    required this.onConfirmProcessed,
    required this.onUndoProcessed,
    required this.isApproved,
    required this.onConfirmApproved,
    required this.isRejected,
    required this.rejectReason,
    required this.onConfirmReject,
  });

  final _ApprovalDetail approval;
  final VoidCallback onViewApprovalFlow;
  final bool isOnHold;
  final String holdReason;
  final ValueChanged<String> onConfirmOnHold;
  final VoidCallback onUndoOnHold;
  final bool isProcessed;
  final VoidCallback onConfirmProcessed;
  final VoidCallback onUndoProcessed;
  final bool isApproved;
  final VoidCallback onConfirmApproved;
  final bool isRejected;
  final String rejectReason;
  final ValueChanged<String> onConfirmReject;

  static const _labelStyle =
      TextStyle(fontSize: 13, color: AppTheme.textSecondary);

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final dec = parts[1];
    if (intPart.length <= 3) return '₹$intPart.$dec';
    final buf = StringBuffer();
    int count = 0;
    for (var i = intPart.length - 1; i >= 0; i--) {
      buf.write(intPart[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write(',');
        count = 0;
      }
    }
    return '₹${buf.toString().split('').reversed.join('')}.$dec';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHeader(
          approval: approval,
          isOnHold: isOnHold,
          onConfirmOnHold: onConfirmOnHold,
          onUndoOnHold: onUndoOnHold,
          isApproved: isApproved,
          onConfirmApproved: onConfirmApproved,
          isProcessed: isProcessed,
          onConfirmProcessed: onConfirmProcessed,
          onUndoProcessed: onUndoProcessed,
          isRejected: isRejected,
          onConfirmReject: onConfirmReject,
        ),
        const Divider(height: 1, thickness: 1, color: AppTheme.borderColor),
        if (isOnHold) _OnHoldBanner(reason: holdReason),
        if (isRejected) _RejectedBanner(reason: rejectReason),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Expected Date + Estimated Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Expected Date', style: _labelStyle),
                        const SizedBox(height: 4),
                        Text(
                          approval.expectedDate,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Estimated Amount', style: _labelStyle),
                        const SizedBox(height: 4),
                        Text(
                          _fmt(approval.amount),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Processing Summary
                _ProcessingSummaryCard(status: approval.processingStatus),
                const SizedBox(height: 24),
                // Approver
                Text('Approver', style: _labelStyle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _Avatar(name: approval.approver, size: 28),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            approval.approver,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onViewApprovalFlow,
                        child: const Text(
                          'View approval flow',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Reason
                Text('Reason', style: _labelStyle),
                const SizedBox(height: 6),
                Text(
                  _display(approval.reason),
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textBody),
                ),
                const SizedBox(height: 20),
                // Notes to Approver
                Text('Notes To Approver', style: _labelStyle),
                const SizedBox(height: 6),
                Text(
                  _display(approval.notesToApprover),
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textBody),
                ),
                const SizedBox(height: 20),
                // Internal Notes
                Text('Internal Notes', style: _labelStyle),
                const SizedBox(height: 6),
                Text(
                  _display(approval.internalNotes),
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textBody),
                ),
                const SizedBox(height: 20),
                // Delivery Address
                Text('Delivery Address', style: _labelStyle),
                const SizedBox(height: 6),
                Text(
                  _display(approval.deliveryAddress),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 20),
                // Reference#
                Text('Reference#', style: _labelStyle),
                const SizedBox(height: 6),
                Text(
                  _display(approval.prReferenceNumber),
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textBody),
                ),
                const SizedBox(height: 20),
                // Documents
                Row(
                  children: [
                    Text('Documents', style: _labelStyle),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Icon(LucideIcons.plus,
                            size: 14, color: AppTheme.primaryBlue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('-',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textBody)),
                const SizedBox(height: 28),
                // Items
                _ItemsSection(items: approval.items),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Detail header ─────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.approval,
    required this.isOnHold,
    required this.onConfirmOnHold,
    required this.onUndoOnHold,
    required this.isApproved,
    required this.onConfirmApproved,
    required this.isProcessed,
    required this.onConfirmProcessed,
    required this.onUndoProcessed,
    required this.isRejected,
    required this.onConfirmReject,
  });

  final _ApprovalDetail approval;
  final bool isOnHold;
  final ValueChanged<String> onConfirmOnHold;
  final VoidCallback onUndoOnHold;
  final bool isApproved;
  final VoidCallback onConfirmApproved;
  final bool isProcessed;
  final VoidCallback onConfirmProcessed;
  final VoidCallback onUndoProcessed;
  final bool isRejected;
  final ValueChanged<String> onConfirmReject;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          _Avatar(name: approval.submitter, size: 36),
          const SizedBox(width: 12),
          Text(
            approval.referenceNumber,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          // Single main action button
          if (isApproved && !isRejected && isProcessed)
            OutlinedButton(
              onPressed: () => showDialog(
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.45),
                builder: (_) =>
                    _UndoProcessedDialog(onConfirm: onUndoProcessed),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textBody,
                side: const BorderSide(color: AppTheme.borderColor),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Undo Processed'),
            )
          else if (isApproved && !isRejected)
            OutlinedButton(
              onPressed: () => showDialog(
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.45),
                builder: (_) => _MarkAsProcessedDialog(
                    onConfirm: onConfirmProcessed),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textBody,
                side: const BorderSide(color: AppTheme.borderColor),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Mark As Processed'),
            )
          else ...[
            if (!isRejected) ...[
              OutlinedButton(
                onPressed: () => showDialog(
                  context: context,
                  barrierColor: Colors.black.withValues(alpha: 0.45),
                  builder: (_) => _RejectDialog(onConfirm: onConfirmReject),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorRed,
                  side: const BorderSide(color: AppTheme.errorRed),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Reject'),
              ),
              const SizedBox(width: 8),
            ],
            ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                barrierColor: Colors.black.withValues(alpha: 0.45),
                builder: (_) =>
                    _ApproveDialog(onConfirm: onConfirmApproved),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 9),
                textStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Approve'),
            ),
          ],
          const SizedBox(width: 8),
          _MoreMenuButton(
            isOnHold: isOnHold,
            onConfirmOnHold: onConfirmOnHold,
            onUndoOnHold: onUndoOnHold,
            isApproved: isApproved,
            onConfirmReject: onConfirmReject,
          ),
          const SizedBox(width: 8),
          _IconBtn(
            icon: LucideIcons.x,
            onTap: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  const _IconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
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
            color: _hovered ? AppTheme.bgDisabled : Colors.white,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(widget.icon,
              size: 16, color: AppTheme.errorRed),
        ),
      ),
    );
  }
}

// ── More (…) menu button ──────────────────────────────────────────────────────

class _MoreMenuButton extends StatefulWidget {
  const _MoreMenuButton({
    required this.isOnHold,
    required this.onConfirmOnHold,
    required this.onUndoOnHold,
    required this.isApproved,
    required this.onConfirmReject,
  });

  final bool isOnHold;
  final ValueChanged<String> onConfirmOnHold;
  final VoidCallback onUndoOnHold;
  final bool isApproved;
  final ValueChanged<String> onConfirmReject;

  @override
  State<_MoreMenuButton> createState() => _MoreMenuButtonState();
}

class _MoreMenuButtonState extends State<_MoreMenuButton> {
  final _layerLink = LayerLink();
  OverlayEntry? _overlay;
  bool _hovered = false;

  static const _menuWidth = 210.0;
  static const _btnSize = 34.0;

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
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(_btnSize - _menuWidth, _btnSize + 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: _MoreMenuPanel(
                pageContext: context,
                isOnHold: widget.isOnHold,
                onConfirmOnHold: widget.onConfirmOnHold,
                onUndoOnHold: widget.onUndoOnHold,
                isApproved: widget.isApproved,
                onConfirmReject: widget.onConfirmReject,
                onClose: () {
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
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => _toggle(context),
          child: Container(
            width: _btnSize,
            height: _btnSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _hovered ? AppTheme.bgDisabled : Colors.white,
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(LucideIcons.moreHorizontal,
                size: 16, color: AppTheme.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _MoreMenuPanel extends StatelessWidget {
  const _MoreMenuPanel({
    required this.onClose,
    required this.pageContext,
    required this.isOnHold,
    required this.onConfirmOnHold,
    required this.onUndoOnHold,
    required this.isApproved,
    required this.onConfirmReject,
  });

  final VoidCallback onClose;
  final BuildContext pageContext;
  final bool isOnHold;
  final ValueChanged<String> onConfirmOnHold;
  final VoidCallback onUndoOnHold;
  final bool isApproved;
  final ValueChanged<String> onConfirmReject;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isOnHold)
                _MoreMenuItem(
                  label: 'Undo On Hold',
                  onTap: () {
                    onClose();
                    onUndoOnHold();
                  },
                )
              else
                _MoreMenuItem(
                  label: 'Mark As On Hold',
                  onTap: () {
                    onClose();
                    showDialog(
                      context: pageContext,
                      barrierColor:
                          Colors.black.withValues(alpha: 0.45),
                      builder: (_) => _MarkOnHoldDialog(
                        onConfirm: onConfirmOnHold,
                      ),
                    );
                  },
                ),
              if (isApproved)
                _MoreMenuItem(
                  label: 'Reject',
                  onTap: () {
                    onClose();
                    showDialog(
                      context: pageContext,
                      barrierColor:
                          Colors.black.withValues(alpha: 0.45),
                      builder: (_) => _RejectDialog(
                        onConfirm: onConfirmReject,
                      ),
                    );
                  },
                ),
              const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE5E7EB)),
              _MoreMenuItem(
                  icon: LucideIcons.fileText,
                  label: 'PDF',
                  onTap: onClose),
              _MoreMenuItem(
                  icon: LucideIcons.printer,
                  label: 'Print',
                  onTap: onClose),
              _MoreMenuItem(
                  icon: LucideIcons.upload,
                  label: 'Export',
                  onTap: onClose),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuItem extends StatefulWidget {
  const _MoreMenuItem(
      {this.icon, required this.label, required this.onTap});

  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_MoreMenuItem> createState() => _MoreMenuItemState();
}

class _MoreMenuItemState extends State<_MoreMenuItem> {
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
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.infoBlue : Colors.transparent,
            borderRadius: AppTheme.hoverRadius,
          ),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    size: 14,
                    color: _hovered
                        ? Colors.white
                        : AppTheme.textSecondary),
                const SizedBox(width: 10),
              ] else
                const SizedBox(width: 24),
              Text(
                widget.label,
                style: TextStyle(
                    fontSize: 13,
                    color: _hovered
                        ? Colors.white
                        : AppTheme.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Processing summary card
// ---------------------------------------------------------------------------

class _ProcessingSummaryCard extends StatelessWidget {
  const _ProcessingSummaryCard({required this.status});

  final _ProcessingStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Processing Summary',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProcessingStatusItem(
                  label: 'Request for\nQuote Status',
                  value: status.rfqStatus,
                ),
              ),
              Expanded(
                child: _ProcessingStatusItem(
                  label: 'Purchase\nOrder Status',
                  value: status.poStatus,
                ),
              ),
              Expanded(
                child: _ProcessingStatusItem(
                  label: 'Purchase\nReceive Status',
                  value: status.receiveStatus,
                ),
              ),
              Expanded(
                child: _ProcessingStatusItem(
                  label: 'Bill Status',
                  value: status.billStatus,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProcessingStatusItem extends StatelessWidget {
  const _ProcessingStatusItem(
      {required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(LucideIcons.clock,
                size: 15, color: Color(0xFFE65100)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Items section
// ---------------------------------------------------------------------------

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.items});

  final List<_ApprovalItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab header
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(
              bottom: BorderSide(color: AppTheme.borderColor, width: 1),
            ),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ITEMS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${items.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 2, color: AppTheme.successGreen),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Text('-',
              style:
                  TextStyle(fontSize: 13, color: AppTheme.textBody))
        else
          ...items.map((item) => _ItemCard(item: item)),
      ],
    );
  }
}

// ── Item card ─────────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final _ApprovalItem item;

  String _fmt(double v) {
    final parts = v.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final dec = parts[1];
    if (intPart.length <= 3) return '₹$intPart.$dec';
    final buf = StringBuffer();
    int count = 0;
    for (var i = intPart.length - 1; i >= 0; i--) {
      buf.write(intPart[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write(',');
        count = 0;
      }
    }
    return '₹${buf.toString().split('').reversed.join('')}.$dec';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: const Center(
                child: Icon(LucideIcons.image,
                    size: 22, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(width: 16),
            // Item details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item Details',
                    style: TextStyle(
                        fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoChip(label: 'Category: ', value: item.category),
                  const SizedBox(height: 5),
                  _InfoChip(
                      label: 'Description: ',
                      value: item.description),
                  const SizedBox(height: 5),
                  _InfoChip(
                      label: 'Preferred Vendor: ',
                      value: item.preferredVendor),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Quantity
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quantity',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  '${item.quantity} ${item.unit}',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textBody),
                ),
                const SizedBox(height: 2),
                Text(
                  '1 ${item.unit} = ${_fmt(item.unitPrice)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Discount
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Discount',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary)),
                const SizedBox(height: 4),
                Text(
                  item.discount > 0
                      ? '${item.discount.toStringAsFixed(2)}%'
                      : '—',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textBody),
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Estimated Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimated\nAmount',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFFE65100)),
                ),
                const SizedBox(height: 4),
                Text(
                  _fmt(item.estimatedAmount),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            // + button
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border:
                    Border.all(color: AppTheme.primaryBlue, width: 1.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.plus,
                  size: 14, color: AppTheme.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textBody,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// On-hold banner
// ---------------------------------------------------------------------------

class _OnHoldBanner extends StatelessWidget {
  const _OnHoldBanner({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFFBEB),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(LucideIcons.hourglass,
                size: 15, color: Color(0xFFD97706)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text:
                        'This purchase request has been put on hold.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  if (reason.trim().isNotEmpty)
                    TextSpan(
                      text: '  Reason: $reason',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF92400E),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mark As On Hold dialog
// ---------------------------------------------------------------------------

class _MarkOnHoldDialog extends StatefulWidget {
  const _MarkOnHoldDialog({required this.onConfirm});

  final ValueChanged<String> onConfirm;

  @override
  State<_MarkOnHoldDialog> createState() => _MarkOnHoldDialogState();
}

class _MarkOnHoldDialogState extends State<_MarkOnHoldDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Mark As On Hold',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppTheme.bgDisabled,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x,
                            size: 16,
                            color: AppTheme.errorRed),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please specify the reason for marking the request as on hold.',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textBody),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: 6,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderColor),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(_controller.text);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Confirm'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBody,
                      side: const BorderSide(
                          color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mark As Processed confirmation dialog
// ---------------------------------------------------------------------------

class _MarkAsProcessedDialog extends StatelessWidget {
  const _MarkAsProcessedDialog({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle,
                      size: 20, color: Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  const Text(
                    'Mark As Processed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppTheme.bgDisabled,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x,
                            size: 16,
                            color: AppTheme.errorRed),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                'Are you sure you want to mark this purchase request as processed?',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textBody),
              ),
            ),
            const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderColor),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Mark As Processed'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBody,
                      side: const BorderSide(
                          color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Approve dialog
// ---------------------------------------------------------------------------

class _ApproveDialog extends StatelessWidget {
  const _ApproveDialog({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle,
                      size: 20, color: Color(0xFFD97706)),
                  const SizedBox(width: 10),
                  const Text(
                    'Approve Purchase Request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppTheme.bgDisabled,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x,
                            size: 16,
                            color: AppTheme.errorRed),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Text(
                'Are you sure you want to approve this purchase request?',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textBody),
              ),
            ),
            const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderColor),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBody,
                      side: const BorderSide(
                          color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reject dialog
// ---------------------------------------------------------------------------

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.onConfirm});

  final ValueChanged<String> onConfirm;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Reject Purchase Request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppTheme.bgDisabled,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x,
                            size: 16,
                            color: AppTheme.errorRed),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please specify the reason for rejecting this request.',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textBody),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    autofocus: true,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderColor),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.onConfirm(_controller.text);
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Confirm'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBody,
                      side: const BorderSide(
                          color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rejected banner
// ---------------------------------------------------------------------------

class _RejectedBanner extends StatelessWidget {
  const _RejectedBanner({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF1F2),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFFECACA),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(LucideIcons.thumbsDown,
                size: 14, color: Color(0xFFDC2626)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text:
                        'This purchase request has been rejected.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  if (reason.trim().isNotEmpty)
                    TextSpan(
                      text: '  Reason: $reason',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Undo Processed dialog
// ---------------------------------------------------------------------------

class _UndoProcessedDialog extends StatefulWidget {
  const _UndoProcessedDialog({required this.onConfirm});

  final VoidCallback onConfirm;

  @override
  State<_UndoProcessedDialog> createState() =>
      _UndoProcessedDialogState();
}

class _UndoProcessedDialogState extends State<_UndoProcessedDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 16, 16),
              child: Row(
                children: [
                  const Text(
                    'Undo Processed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppTheme.bgDisabled,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.x,
                            size: 16,
                            color: AppTheme.errorRed),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Specify a reason for reverting the Mark as Processed status. Once you undo, the status of the purchase request will be reverted to Approved.',
                    style: TextStyle(
                        fontSize: 14, color: AppTheme.textBody),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryBlue, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
                height: 1,
                thickness: 1,
                color: AppTheme.borderColor),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      widget.onConfirm();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                    child: const Text('Confirm'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBody,
                      side: const BorderSide(
                          color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Action toast (processed / rejected)
// ---------------------------------------------------------------------------

class _ActionToast extends StatelessWidget {
  const _ActionToast({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: 64,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.check,
                            size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar
// ---------------------------------------------------------------------------

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size});

  final String name;
  final double size;

  String get _initial =>
      name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFEDE9FE),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6D28D9),
        ),
      ),
    );
  }
}
