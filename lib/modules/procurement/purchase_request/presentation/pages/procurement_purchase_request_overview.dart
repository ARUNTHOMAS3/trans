import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/procurement/approvals/presentation/widgets/procurement_approvals_flow_panel.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/document/zerpai_document_view.dart';

class _PrItem {
  const _PrItem({
    required this.productName,
    required this.requiredQty,
    this.category,
    this.description,
    this.preferredVendor,
    this.plannedQty = 0,
    this.pendingQty = 0,
    this.estimatedRate = 0,
    this.discountPercentage = 0,
    this.estimatedAmount = 0,
    this.lineStatus = 'PENDING',
  });
  final String productName;
  final int requiredQty;
  final String? category;
  final String? description;
  final String? preferredVendor;
  final int plannedQty;
  final int pendingQty;
  final double estimatedRate;
  final double discountPercentage;
  final double estimatedAmount;
  final String lineStatus;
}

class _PrListItem {
  const _PrListItem({
    required this.requestNumber,
    required this.status,
    this.expectedDate,
    this.totalAmount = 0,
  });
  final String requestNumber;
  final String status;
  final String? expectedDate;
  final double totalAmount;
}

class ProcurementPurchaseRequestOverviewPage extends ConsumerStatefulWidget {
  const ProcurementPurchaseRequestOverviewPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ProcurementPurchaseRequestOverviewPage> createState() =>
      _OverviewPageState();
}

class _OverviewPageState
    extends ConsumerState<ProcurementPurchaseRequestOverviewPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  bool _isProcessed = false;
  bool _isOnHold    = false;
  String _prStatus  = '';

  List<_PrItem> _prItems = [];
  bool _itemsLoading = true;

  String? _expectedDate;   // DD-MM-YYYY for display
  double  _totalAmount = 0;
  String? _assigneeName;

  // Header text fields captured on the create form
  String? _reason;
  String? _referenceNumber;
  String? _internalNotes;
  String? _notesToApprover;
  String? _deliveryAddress;

  // Approval flow panel data
  String? _assigneeEmail;
  String? _submittedOn;    // DD-MM-YYYY — purchase_requests.created_at
  String? _approvedOn;     // DD-MM-YYYY — purchase_requests.approved_at
  OverlayEntry? _approvalFlowOverlay;

  final _createLink = LayerLink();
  final _createKey  = GlobalKey();
  OverlayEntry? _createOverlay;

  final _moreLink = LayerLink();
  final _moreKey  = GlobalKey();
  OverlayEntry? _moreOverlay;

  OverlayEntry? _markProcessedOverlay;
  OverlayEntry? _undoProcessedOverlay;
  OverlayEntry? _markOnHoldOverlay;
  OverlayEntry? _undoOnHoldOverlay;

  // Left panel list
  List<_PrListItem> _allPrs = [];
  bool _listLoading = true;
  String _selectedPrId = '';

  // PDF view toggle
  bool _showPdfView = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _selectedPrId = widget.id.startsWith('PR-') ? widget.id : 'PR-${widget.id}';
    _loadItems();
    _loadPrList();
  }

  Future<void> _loadPrList() async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('purchase_requests')
          .select('request_number, status, expected_date, purchase_request_items(estimated_amount)')
          .order('created_at', ascending: false);

      if (!mounted) return;
      final prs = (res as List<dynamic>).map((row) {
        final map = row as Map<String, dynamic>;
        final rawDate = map['expected_date'] as String?;
        String? displayDate;
        if (rawDate != null) {
          final parts = rawDate.split('-');
          if (parts.length == 3) displayDate = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
        final itemsList = map['purchase_request_items'] as List<dynamic>? ?? [];
        final total = itemsList.fold<double>(
          0,
          (s, i) => s + ((i as Map)['estimated_amount'] as num? ?? 0).toDouble(),
        );
        return _PrListItem(
          requestNumber: map['request_number'] as String? ?? '',
          status: (map['status'] as String? ?? '').toUpperCase(),
          expectedDate: displayDate,
          totalAmount: total,
        );
      }).where((p) => p.requestNumber.isNotEmpty).toList();

      setState(() {
        _allPrs = prs;
        _listLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load PR list', error: e, module: 'PurchaseRequestOverview');
      if (mounted) setState(() => _listLoading = false);
    }
  }

  Future<void> _loadItems() async {
    try {
      final supabase = Supabase.instance.client;
      final fullRequestNumber = _selectedPrId;

      final prRes = await supabase
          .from('purchase_requests')
          .select('id, expected_date, status, reason, reference_number, '
              'internal_notes, notes_to_approver, delivery_address, '
              'created_at, approved_at, users!assignee_id(full_name, email)')
          .eq('request_number', fullRequestNumber)
          .maybeSingle();

      if (!mounted) return;
      if (prRes == null) {
        setState(() => _itemsLoading = false);
        return;
      }

      // Parse expected date YYYY-MM-DD → DD-MM-YYYY
      final rawDate = prRes['expected_date'] as String?;
      String? displayDate;
      if (rawDate != null) {
        final parts = rawDate.split('-');
        if (parts.length == 3) {
          displayDate = '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }
      final dbStatus = (prRes['status'] as String? ?? '').toUpperCase();
      final userMap = prRes['users'] as Map<String, dynamic>?;
      final assigneeName = userMap?['full_name'] as String?;
      final assigneeEmail = userMap?['email'] as String?;
      final submittedOn = _formatTimestamp(prRes['created_at'] as String?);
      final approvedOn = _formatTimestamp(prRes['approved_at'] as String?);

      final prId = prRes['id'] as String;
      final itemsRes = await supabase
          .from('purchase_request_items')
          .select(
              'required_qty, planned_qty, pending_qty, estimated_rate, '
              'discount_percentage, estimated_amount, line_status, description, '
              'products(product_name), categories(name), '
              'vendors!preferred_vendor_id(display_name)')
          .eq('purchase_request_id', prId);

      if (!mounted) return;
      final items = (itemsRes as List<dynamic>).map((row) {
        final map = row as Map<String, dynamic>;
        final product = map['products'] as Map<String, dynamic>?;
        final category = map['categories'] as Map<String, dynamic>?;
        final vendor = map['vendors'] as Map<String, dynamic>?;
        return _PrItem(
          productName:
              product?['product_name'] as String? ?? 'Unknown Product',
          requiredQty: (map['required_qty'] as num?)?.toInt() ?? 0,
          category: category?['name'] as String?,
          description: map['description'] as String?,
          preferredVendor: vendor?['display_name'] as String?,
          plannedQty: (map['planned_qty'] as num?)?.toInt() ?? 0,
          pendingQty: (map['pending_qty'] as num?)?.toInt() ?? 0,
          estimatedRate: (map['estimated_rate'] as num?)?.toDouble() ?? 0,
          discountPercentage: (map['discount_percentage'] as num?)?.toDouble() ?? 0,
          estimatedAmount: (map['estimated_amount'] as num?)?.toDouble() ?? 0,
          lineStatus: map['line_status'] as String? ?? 'PENDING',
        );
      }).toList();

      setState(() {
        _prItems = items;
        _totalAmount = items.fold(0, (sum, i) => sum + i.estimatedAmount);
        _expectedDate = displayDate;
        _assigneeName = assigneeName;
        _assigneeEmail = assigneeEmail;
        _submittedOn = submittedOn;
        _approvedOn = approvedOn;
        _prStatus = dbStatus;
        _isOnHold = dbStatus == 'ON_HOLD';
        _isProcessed = dbStatus == 'PROCESSED';
        _reason = prRes['reason'] as String?;
        _referenceNumber = prRes['reference_number'] as String?;
        _internalNotes = prRes['internal_notes'] as String?;
        _notesToApprover = prRes['notes_to_approver'] as String?;
        _deliveryAddress = prRes['delivery_address'] as String?;
        _itemsLoading = false;
      });
    } catch (e) {
      AppLogger.error('Failed to load PR items', error: e, module: 'PurchaseRequestOverview');
      if (mounted) setState(() => _itemsLoading = false);
    }
  }

  @override
  void dispose() {
    _moreOverlay?.remove();
    _createOverlay?.remove();
    _markProcessedOverlay?.remove();
    _undoProcessedOverlay?.remove();
    _markOnHoldOverlay?.remove();
    _undoOnHoldOverlay?.remove();
    _approvalFlowOverlay?.remove();
    _tabCtrl.dispose();
    super.dispose();
  }

  // Empty/unset text fields render as an em dash rather than a blank gap.
  String _display(String? value) =>
      (value == null || value.trim().isEmpty) ? '—' : value.trim();

  // ISO timestamp → DD-MM-YYYY for display; null when absent.
  String? _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return '${dt.day.toString().padLeft(2, '0')}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.year}';
  }

  ApprovalFlowStatus get _approvalFlowStatus => switch (_prStatus) {
        'APPROVED' || 'PROCESSED' => ApprovalFlowStatus.approved,
        'REJECTED' => ApprovalFlowStatus.rejected,
        _ => ApprovalFlowStatus.pending,
      };

  void _showApprovalFlow() {
    _approvalFlowOverlay?.remove();
    _approvalFlowOverlay = OverlayEntry(
      builder: (_) => ApprovalFlowPanel(
        entry: ApprovalFlowEntry(
          approver: _assigneeName ?? '—',
          approverEmail: _assigneeEmail,
          status: _approvalFlowStatus,
          submittedOn: _submittedOn ?? '—',
          decidedOn: _approvedOn,
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

  void _showMarkAsProcessedDialog() {
    _markProcessedOverlay?.remove();
    _markProcessedOverlay = OverlayEntry(
      builder: (_) => _MarkAsProcessedDialog(
        onCancel: () {
          _markProcessedOverlay?.remove();
          _markProcessedOverlay = null;
        },
        onConfirm: () {
          _markProcessedOverlay?.remove();
          _markProcessedOverlay = null;
          setState(() => _isProcessed = true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                  SizedBox(width: 10),
                  Text('Purchase request processed'),
                ],
              ),
              backgroundColor: AppTheme.successGreen,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
      ),
    );
    Overlay.of(context).insert(_markProcessedOverlay!);
  }

  void _showUndoProcessedDialog() {
    _undoProcessedOverlay?.remove();
    _undoProcessedOverlay = OverlayEntry(
      builder: (_) => _UndoProcessedDialog(
        onCancel: () {
          _undoProcessedOverlay?.remove();
          _undoProcessedOverlay = null;
        },
        onConfirm: () {
          _undoProcessedOverlay?.remove();
          _undoProcessedOverlay = null;
          setState(() => _isProcessed = false);
        },
      ),
    );
    Overlay.of(context).insert(_undoProcessedOverlay!);
  }

  void _showMarkAsOnHoldDialog() {
    _markOnHoldOverlay?.remove();
    _markOnHoldOverlay = OverlayEntry(
      builder: (_) => _MarkAsOnHoldDialog(
        onCancel: () {
          _markOnHoldOverlay?.remove();
          _markOnHoldOverlay = null;
        },
        onConfirm: () {
          _markOnHoldOverlay?.remove();
          _markOnHoldOverlay = null;
          setState(() => _isOnHold = true);
        },
      ),
    );
    Overlay.of(context).insert(_markOnHoldOverlay!);
  }

  void _showUndoOnHoldDialog() {
    _undoOnHoldOverlay?.remove();
    _undoOnHoldOverlay = OverlayEntry(
      builder: (_) => _UndoOnHoldDialog(
        onCancel: () {
          _undoOnHoldOverlay?.remove();
          _undoOnHoldOverlay = null;
        },
        onConfirm: () {
          _undoOnHoldOverlay?.remove();
          _undoOnHoldOverlay = null;
          setState(() => _isOnHold = false);
        },
      ),
    );
    Overlay.of(context).insert(_undoOnHoldOverlay!);
  }

  /// Raise a purchase order from this request. The PR number travels as a query
  /// param, so the prefilled PO create page is deep-linkable and survives a
  /// refresh — `state.extra` would not.
  void _createPurchaseOrder() {
    if (_prStatus != 'APPROVED') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only an approved purchase request can be ordered.'),
        ),
      );
      return;
    }
    final orgId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
    context.goNamed(
      AppRoutes.purchaseOrdersCreate,
      pathParameters: {'orgSystemId': orgId},
      queryParameters: {'from_pr': _selectedPrId},
    );
  }

  void _toggleCreateOverlay(BuildContext context) {
    if (_createOverlay != null) {
      _createOverlay!.remove();
      _createOverlay = null;
      setState(() {});
      return;
    }
    _createOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _createOverlay?.remove();
                _createOverlay = null;
                if (mounted) setState(() {});
              },
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _createLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 4),
            child: Align(
              alignment: Alignment.topRight,
              child: _CreateDropdown(
                onSelect: (label) {
                  _createOverlay?.remove();
                  _createOverlay = null;
                  if (mounted) setState(() {});
                  if (label == 'Purchase Order') _createPurchaseOrder();
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_createOverlay!);
    setState(() {});
  }

  void _toggleMoreOverlay(BuildContext context) {
    if (_moreOverlay != null) {
      _moreOverlay!.remove();
      _moreOverlay = null;
      setState(() {});
      return;
    }

    _moreOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _moreOverlay?.remove();
                _moreOverlay = null;
                if (mounted) setState(() {});
              },
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _moreLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 4),
            child: Align(
              alignment: Alignment.topRight,
              child: _MoreDropdown(
                isProcessed: _isProcessed,
                isOnHold: _isOnHold,
                onSelect: (label) {
                  _moreOverlay?.remove();
                  _moreOverlay = null;
                  if (mounted) setState(() {});
                  if (label == 'Mark As Processed') {
                    _showMarkAsProcessedDialog();
                  } else if (label == 'Mark As On Hold') {
                    _showMarkAsOnHoldDialog();
                  } else if (label == 'Undo On Hold') {
                    _showUndoOnHoldDialog();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_moreOverlay!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        children: [
          // ── Left panel: PR list (360px) ───────────────────────────────────
          SizedBox(width: 360, child: _buildLeftPanel()),
          const VerticalDivider(width: 1, thickness: 1, color: AppTheme.borderLight),
          // ── Right panel: PR detail ─────────────────────────────────────────
          Expanded(child: _buildDetailPanel()),
        ],
      ),
    );
  }

  // ── Left panel ─────────────────────────────────────────────────────────────

  Widget _buildLeftPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Purchase Requests',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final orgId = GoRouterState.of(context)
                            .pathParameters['orgSystemId'] ?? '';
                    context.goNamed(
                      AppRoutes.procurementPurchaseRequestsCreate,
                      pathParameters: {'orgSystemId': orgId},
                    );
                  },
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: _listLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : _allPrs.isEmpty
                    ? const Center(
                        child: Text(
                          'No purchase requests',
                          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _allPrs.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppTheme.borderLight),
                        itemBuilder: (context, i) => _PrCompactItem(
                          pr: _allPrs[i],
                          selected: _allPrs[i].requestNumber == _selectedPrId,
                          onTap: () {
                            if (_allPrs[i].requestNumber == _selectedPrId) return;
                            setState(() {
                              _selectedPrId = _allPrs[i].requestNumber;
                              _itemsLoading = true;
                              _showPdfView = false;
                            });
                            _loadItems();
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ── Right detail panel ─────────────────────────────────────────────────────

  Widget _buildDetailPanel() {
    return Column(
      children: [
        _buildDetailHeader(),
        _buildDetailStatusBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showPdfView)
                  _buildPdfPreview()
                else ...[
                  _buildStatusBanner(),
                  const SizedBox(height: 16),
                  _buildTopCard(),
                  const SizedBox(height: 16),
                  _buildInfoCard(),
                  const SizedBox(height: 16),
                  _buildTabsCard(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Status bar with PDF view toggle
  Widget _buildDetailStatusBar() {
    final statusLabel = _prStatus.isEmpty
        ? '—'
        : _prStatus.replaceAll('_', ' ');
    final statusColor = _isOnHold
        ? const Color(0xFFD97706)
        : (_isProcessed || _prStatus == 'APPROVED')
            ? AppTheme.successGreen
            : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          const Text(
            'Status: ',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          Text(
            statusLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
          const Spacer(),
          const Text(
            'Show PDF View',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _showPdfView,
              onChanged: (v) => setState(() => _showPdfView = v),
              activeTrackColor: AppTheme.primaryBlue,
              activeThumbColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  // PDF preview card — uses shared ZerpaiDocumentView (logo + letterhead)
  Widget _buildPdfPreview() {
    final ribbonColor = _isOnHold
        ? const Color(0xFFD97706)
        : (_isProcessed || _prStatus == 'APPROVED')
            ? AppTheme.successGreen
            : AppTheme.textSecondary;
    final ribbonLabel = _prStatus.isEmpty ? '—' : _prStatus.replaceAll('_', ' ');

    return ZerpaiDocumentView(
      documentType: 'PURCHASE REQUEST',
      documentNumber: _selectedPrId,
      status: ribbonLabel,
      statusColor: ribbonColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZerpaiDocumentMetaRow(
            children: [
              ZerpaiDocumentInfoBlock(
                label: 'Purchase Request#',
                value: _selectedPrId,
              ),
              ZerpaiDocumentInfoBlock(
                label: 'Expected Date',
                value: _expectedDate ?? '—',
              ),
              if (_assigneeName != null)
                ZerpaiDocumentInfoBlock(
                  label: 'Assigned To',
                  value: _assigneeName!,
                ),
            ],
          ),
          const SizedBox(height: 16),
          ZerpaiDocumentTableHeader(
            children: [
              const ZerpaiDocumentHeaderCell('ITEM', flex: 4),
              const ZerpaiDocumentHeaderCell('QTY', width: 80, align: TextAlign.right),
              const ZerpaiDocumentHeaderCell('RATE', width: 100, align: TextAlign.right),
              const ZerpaiDocumentHeaderCell('AMOUNT', width: 100, align: TextAlign.right),
            ],
          ),
          if (_itemsLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            ..._prItems.map(
              (item) => ZerpaiDocumentTableRow(
                children: [
                  ZerpaiDocumentDataCell(
                    item.discountPercentage > 0
                        ? '${item.productName}\nDiscount: ${item.discountPercentage.toStringAsFixed(2)}%'
                        : item.productName,
                    flex: 4,
                  ),
                  ZerpaiDocumentDataCell(
                    '${item.requiredQty}',
                    width: 80,
                    align: TextAlign.right,
                  ),
                  ZerpaiDocumentDataCell(
                    item.estimatedRate > 0
                        ? '₹${item.estimatedRate.toStringAsFixed(2)}'
                        : '—',
                    width: 100,
                    align: TextAlign.right,
                  ),
                  ZerpaiDocumentDataCell(
                    '₹${item.estimatedAmount.toStringAsFixed(2)}',
                    width: 100,
                    align: TextAlign.right,
                    fontWeight: FontWeight.w600,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Spacer(),
              const Text(
                'Total Estimated Amount',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 24),
              Text(
                '₹${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Detail panel header (CN-style) ────────────────────────────────────────

  Widget _buildDetailHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.only(left: 20, right: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          // PR number + status sub-label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Status: ${_prStatus.isEmpty ? "—" : _prStatus.replaceAll("_", " ")}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 3),
                Text(
                  _selectedPrId,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          if (_isProcessed) ...[
            OutlinedButton(
              onPressed: _showUndoProcessedDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textBody,
                side: const BorderSide(color: AppTheme.borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('Undo Processed'),
            ),
            const SizedBox(width: 8),
          ] else ...[
            _HeaderIconBtn(
              icon: LucideIcons.pencil,
              onTap: () {
                final orgId = GoRouterState.of(context)
                        .pathParameters['orgSystemId'] ?? '';
                context.goNamed(
                  AppRoutes.procurementPurchaseRequestsCreate,
                  pathParameters: {'orgSystemId': orgId},
                  queryParameters: {'id': _selectedPrId},
                );
              },
            ),
            if (_prStatus == 'APPROVED') ...[
              const SizedBox(width: 6),
              CompositedTransformTarget(
                link: _createLink,
                child: ElevatedButton(
                  key: _createKey,
                  onPressed: () => _toggleCreateOverlay(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Create'),
                      SizedBox(width: 4),
                      Icon(LucideIcons.chevronDown, size: 13),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
          ],
          // Vertical divider
          Container(
            width: 1, height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            color: AppTheme.borderLight,
          ),
          CompositedTransformTarget(
            link: _moreLink,
            child: _HeaderIconBtn(
              key: _moreKey,
              icon: LucideIcons.moreHorizontal,
              onTap: () => _toggleMoreOverlay(context),
            ),
          ),
          const SizedBox(width: 4),
          _HeaderIconBtn(
            icon: LucideIcons.x,
            color: AppTheme.errorRed,
            onTap: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutes.procurementPurchaseRequests),
          ),
        ],
      ),
    );
  }

  // ── Status banner ──────────────────────────────────────────────────────────

  Widget _buildStatusBanner() {
    if (!_isOnHold) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          const Text('⏳', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          const Text(
            'This purchase request has been put on hold.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top card (Expected Date + Amount + Processing Summary) ─────────────────

  Widget _buildTopCard() {
    return Container(
      color: Colors.white,
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
                  const Text('Expected Date',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    _expectedDate ?? '—',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Estimated Amount',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Processing Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Processing Summary',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(
                      child: _SummaryItem(
                        label: 'Request for Quote Status',
                        value: 'Yet to be Created',
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: 'Purchase Order Status',
                        value: 'Yet to be Ordered',
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: 'Purchase Receive Status',
                        value: 'Yet to be Received',
                      ),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: 'Bill Status',
                        value: 'Yet to be Billed',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info card (Approver / Notes / Reason / Delivery Address / Reference / Documents) ──

  Widget _buildInfoCard() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Approver (left) + Reason (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Approver',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEDE9FE),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Z',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _assigneeName ?? '—',
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _showApprovalFlow,
                        child: const Text(
                          'View approval flow',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _InfoField(label: 'Reason', value: _display(_reason)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Row 2: Notes to Approver (left) + Delivery Address (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoField(
                  label: 'Notes To Approver',
                  value: _display(_notesToApprover),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _InfoField(
                  label: 'Delivery Address',
                  value: _display(_deliveryAddress),
                  bold: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Row 3: Internal Notes (left) + Reference# (right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _InfoField(
                  label: 'Internal Notes',
                  value: _display(_internalNotes),
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _InfoField(
                  label: 'Reference#',
                  value: _display(_referenceNumber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Row 4: Documents
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('Documents',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {},
                          borderRadius: BorderRadius.circular(4),
                          child: const Icon(LucideIcons.plus,
                              size: 15,
                              color: AppTheme.primaryBlue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('-',
                        style: TextStyle(
                            fontSize: 13, color: AppTheme.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Tabs card ──────────────────────────────────────────────────────────────

  Widget _buildTabsCard() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: const Color(0xFFF3F4F6),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppTheme.successGreen,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.successGreen,
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: _itemsLoading ? 'ITEMS' : 'ITEMS  ${_prItems.length}'),
                const Tab(text: 'ASSOCIATED TRANSACTIONS'),
                const Tab(text: 'HISTORY'),
              ],
            ),
          ),
          SizedBox(
            height: _itemsLoading || _prItems.isEmpty
                ? 160
                : (_prItems.length * 120.0 + 44.0).clamp(160.0, 600.0),
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildItemsTab(),
                _buildEmptyTab('No associated transactions'),
                _buildEmptyTab('No history'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTab() {
    if (_itemsLoading) {
      return const TableSkeleton(rows: 6, columns: 5, showHeader: true);
    }
    if (_prItems.isEmpty) {
      return const Center(
        child: Text(
          'No items found',
          style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      itemCount: _prItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final item = _prItems[i];
        return _ItemCard(
          itemName: item.productName,
          category: _display(item.category),
          description: _display(item.description),
          preferredVendor: _display(item.preferredVendor),
          quantityLabel: '${item.requiredQty} units',
          unitPriceLabel: item.estimatedRate > 0
              ? '₹${item.estimatedRate.toStringAsFixed(2)} / unit'
              : '-',
          remainingLabel: 'Pending: ${item.pendingQty}',
          discount: item.discountPercentage > 0
              ? '${item.discountPercentage.toStringAsFixed(2)}%'
              : '—',
          estimatedAmount: '₹${item.estimatedAmount.toStringAsFixed(2)}',
        );
      },
    );
  }

  Widget _buildEmptyTab(String message) {
    return Center(
      child: Text(message,
          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
    );
  }
}

// ── Header icon button ─────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  const _HeaderIconBtn({super.key, required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: color ?? AppTheme.textBody),
      ),
    );
  }
}

// ── Processing Summary item ────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            LucideIcons.clock,
            size: 16,
            color: Color(0xFFEA580C),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 3),
              Text(value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  )),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Info field ─────────────────────────────────────────────────────────────

class _InfoField extends StatelessWidget {
  const _InfoField({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final lines = value.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        for (int i = 0; i < lines.length; i++)
          Text(
            lines[i],
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textBody,
              fontWeight:
                  (bold && i == 0) ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
      ],
    );
  }
}

// ── Item card ──────────────────────────────────────────────────────────────

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.itemName,
    required this.category,
    required this.description,
    required this.preferredVendor,
    required this.quantityLabel,
    required this.unitPriceLabel,
    required this.remainingLabel,
    required this.discount,
    required this.estimatedAmount,
  });

  final String itemName;
  final String category;
  final String description;
  final String preferredVendor;
  final String quantityLabel;
  final String unitPriceLabel;
  final String remainingLabel;
  final String discount;
  final String estimatedAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image placeholder
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Icon(LucideIcons.image,
                size: 22, color: AppTheme.textMuted),
          ),
          const SizedBox(width: 16),

          // Item details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Item Details',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                const SizedBox(height: 3),
                Text(itemName,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _TagBadge(label: 'Category', value: category),
                    _TagBadge(label: 'Description', value: description),
                    _TagBadge(
                        label: 'Preferred vendor', value: preferredVendor),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Quantity
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quantity',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 3),
              Text(quantityLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  )),
              Text(unitPriceLabel,
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textMuted)),
              const SizedBox(height: 2),
              Text(remainingLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFEA580C),
                  )),
            ],
          ),
          const SizedBox(width: 32),

          // Discount
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Discount',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
              const SizedBox(height: 3),
              Text(discount,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textBody)),
            ],
          ),
          const SizedBox(width: 32),

          // Estimated Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Estimated Amount',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFEA580C),
                    fontWeight: FontWeight.w500,
                  )),
              const SizedBox(height: 3),
              Text(estimatedAmount,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEA580C),
                  )),
            ],
          ),
          const SizedBox(width: 16),

          // Circle + button
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppTheme.primaryBlue, width: 1.5),
            ),
            child: const Icon(LucideIcons.plus,
                size: 14, color: AppTheme.primaryBlue),
          ),
        ],
      ),
    );
  }
}

// ── More (...) dropdown ────────────────────────────────────────────────────

class _MoreDropdown extends StatefulWidget {
  const _MoreDropdown({required this.onSelect, required this.isProcessed, required this.isOnHold});
  final ValueChanged<String> onSelect;
  final bool isProcessed;
  final bool isOnHold;

  @override
  State<_MoreDropdown> createState() => _MoreDropdownState();
}

class _MoreDropdownState extends State<_MoreDropdown> {
  String? _hovered;

  static const _kIconItems = [
    (LucideIcons.fileText, 'PDF'),
    (LucideIcons.printer,  'Print'),
    (LucideIcons.upload,   'Export'),
  ];

  Widget _item({
    required String label,
    IconData? icon,
  }) {
    final isHovered = _hovered == label;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = label),
      onExit:  (_) => setState(() => _hovered = null),
      child: GestureDetector(
        onTap: () => widget.onSelect(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: double.infinity,
          decoration: BoxDecoration(
            color: isHovered ? AppTheme.primaryBlue : Colors.white,
            borderRadius: AppTheme.hoverRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 15,
                    color: isHovered ? Colors.white : AppTheme.textSecondary),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isHovered ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
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
      child: Container(
        width: 200,
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
          children: [
            if (!widget.isProcessed) ...[
              _item(label: 'Mark As Processed'),
              if (widget.isOnHold)
                _item(label: 'Undo On Hold')
              else
                _item(label: 'Mark As On Hold'),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
            ],
            ..._kIconItems.map((e) => _item(label: e.$2, icon: e.$1)),
          ],
        ),
      ),
    );
  }
}

// ── Create dropdown ────────────────────────────────────────────────────────

class _CreateDropdown extends StatefulWidget {
  const _CreateDropdown({required this.onSelect});
  final ValueChanged<String> onSelect;

  @override
  State<_CreateDropdown> createState() => _CreateDropdownState();
}

class _CreateDropdownState extends State<_CreateDropdown> {
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

// ── Mark As Processed dialog ───────────────────────────────────────────────

class _MarkAsProcessedDialog extends StatelessWidget {
  const _MarkAsProcessedDialog({required this.onCancel, required this.onConfirm});
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCancel,
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 560,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 24),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Mark As Processed',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                          ),
                          GestureDetector(
                            onTap: onCancel,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: const Icon(LucideIcons.x, size: 14, color: AppTheme.textBody),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Body
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Text(
                        'Are you sure you want to mark this purchase request as processed?',
                        style: TextStyle(fontSize: 14, color: AppTheme.textBody, height: 1.5),
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Mark As Processed', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textBody,
                              side: const BorderSide(color: AppTheme.borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Undo Processed dialog ──────────────────────────────────────────────────

class _UndoProcessedDialog extends StatefulWidget {
  const _UndoProcessedDialog({required this.onCancel, required this.onConfirm});
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  State<_UndoProcessedDialog> createState() => _UndoProcessedDialogState();
}

class _UndoProcessedDialogState extends State<_UndoProcessedDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onCancel,
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 560,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Undo Processed',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onCancel,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: const Icon(LucideIcons.x, size: 14, color: AppTheme.textBody),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Specify a reason for reverting the Mark as Processed status. Once you undo, the status of the purchase request will be reverted to Approved.',
                            style: TextStyle(fontSize: 14, color: AppTheme.textBody, height: 1.5),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderColor),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextField(
                              controller: _reasonCtrl,
                              maxLines: 5,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                                hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                              ),
                              style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: _reasonCtrl.text.trim().isNotEmpty ? widget.onConfirm : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              disabledBackgroundColor: AppTheme.successGreen.withValues(alpha: 0.5),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Confirm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: widget.onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textBody,
                              side: const BorderSide(color: AppTheme.borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mark As On Hold dialog ─────────────────────────────────────────────────

class _MarkAsOnHoldDialog extends StatefulWidget {
  const _MarkAsOnHoldDialog({required this.onCancel, required this.onConfirm});
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  State<_MarkAsOnHoldDialog> createState() => _MarkAsOnHoldDialogState();
}

class _MarkAsOnHoldDialogState extends State<_MarkAsOnHoldDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onCancel,
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 560,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Mark As On Hold',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onCancel,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: const Icon(LucideIcons.x, size: 14, color: AppTheme.textBody),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Please specify the reason for marking the request as on hold.',
                            style: TextStyle(fontSize: 14, color: AppTheme.textBody, height: 1.5),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.borderColor),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TextField(
                              controller: _reasonCtrl,
                              maxLines: 5,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(12),
                              ),
                              style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: _reasonCtrl.text.trim().isNotEmpty ? widget.onConfirm : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              disabledBackgroundColor: AppTheme.successGreen.withValues(alpha: 0.5),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Confirm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: widget.onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textBody,
                              side: const BorderSide(color: AppTheme.borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Undo On Hold dialog ────────────────────────────────────────────────────

class _UndoOnHoldDialog extends StatelessWidget {
  const _UndoOnHoldDialog({required this.onCancel, required this.onConfirm});
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCancel,
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 560,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEA580C), size: 22),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Undo On Hold',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                          ),
                          GestureDetector(
                            onTap: onCancel,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: const Icon(LucideIcons.x, size: 14, color: AppTheme.textBody),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Body
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Text(
                        'Once you undo, the status of the purchase request will be reverted to Approved.',
                        style: TextStyle(fontSize: 14, color: AppTheme.textBody, height: 1.5),
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Footer
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Confirm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textBody,
                              side: const BorderSide(color: AppTheme.borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PR compact list item (left panel) ────────────────────────────────────

class _PrCompactItem extends StatefulWidget {
  const _PrCompactItem({
    required this.pr,
    required this.selected,
    required this.onTap,
  });
  final _PrListItem pr;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PrCompactItem> createState() => _PrCompactItemState();
}

class _PrCompactItemState extends State<_PrCompactItem> {
  bool _hovered = false;

  Color _statusColor(String status) {
    return switch (status.toUpperCase()) {
      'APPROVED'  => AppTheme.successGreen,
      'ON_HOLD'   => const Color(0xFFD97706),
      'PROCESSED' => AppTheme.successGreen,
      'REJECTED'  => AppTheme.errorRed,
      _           => AppTheme.primaryBlue,
    };
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppTheme.primaryBlue.withValues(alpha: 0.06)
        : _hovered
            ? AppTheme.primaryBlue.withValues(alpha: 0.03)
            : Colors.white;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: bg,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pr.requestNumber,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.pr.expectedDate != null)
                      Text(
                        widget.pr.expectedDate!,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      widget.pr.status.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _statusColor(widget.pr.status),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.pr.totalAmount > 0)
                Text(
                  '₹${widget.pr.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tag badge ──────────────────────────────────────────────────────────────

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(color: AppTheme.textBody),
            ),
          ],
        ),
      ),
    );
  }
}
