// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/auth/models/user_model.dart';
import 'package:zerpai_erp/modules/auth/providers/user_provider.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/widgets/texts/substituted_product_text.dart';
import 'package:zerpai_erp/modules/purchases/vendors/models/purchases_vendors_vendor_model.dart';
import 'package:zerpai_erp/modules/purchases/vendors/providers/vendor_provider.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/modules/procurement/purchase_request/presentation/pages/purchase_requests_create.dart'
    show DemandPoolLineItem, DemandPoolPayload;

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

/// Opens the demand pool dialog and returns the payload (items + assignee),
/// or null if the user cancelled.
Future<DemandPoolPayload?> showDemandPoolDialog(BuildContext context) {
  return showDialog<DemandPoolPayload>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => const _DemandPoolDialog(),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Selectable values for the multi-select Status filter, shared by the Items
/// and Customers group-by layouts.
///
/// Covers every state [_normaliseDpStatus] can produce except Fulfilled, which
/// `_loadRows` excludes from the query outright. "Substituted" is not a pipeline
/// stage — see `_matchesStatusFilter`.
const List<String> _kStatusFilterOptions = [
  'Open',
  'Partially Planned',
  'PR Created',
  'PO Created',
  'Ordered',
  'PO Received',
  'Received',
  'Substituted',
  'Cancel',
];

String _normaliseDpStatus(String raw) => switch (raw.toUpperCase()) {
  'OPEN'              => 'Open',
  'PR_CREATED'        => 'PR Created',
  'PO_CREATED'        => 'PO Created',
  'PO_RECEIVED'       => 'PO Received',
  'PARTIALLY_PLANNED' => 'Partially Planned',
  'ORDERED'           => 'Ordered',
  'RECEIVED'          => 'Received',
  'SUBSTITUTED'       => 'Substituted',
  'FULFILLED'         => 'Fulfilled',
  'CANCEL' || 'CANCELLED' => 'Cancel',
  _                   => raw,
};

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class _DpItem {
  _DpItem({
    required this.rowId,
    required this.productId,
    required this.entityId,
    required this.product,
    String? replacement,
    required this.soNo,
    required this.soDate,
    required this.branch,
    required this.customerName,
    required this.reqQty,
    required this.orderedQty,
    required this.plannedQty,
    required this.receivedQty,
    required this.pendingQty,
  }) : _substitutions = replacement != null ? [replacement] : [];

  final String rowId;      // demand_pool.id
  final String productId;  // demand_pool.product_id
  final String entityId;   // demand_pool.entity_id
  String? salesOrderId;     // demand_pool.sales_order_id
  String? salesOrderItemId; // demand_pool.sales_order_item_id
  final String product;
  final List<String> _substitutions;
  String? vendorId;        // demand_pool.preferred_vendor_id
  bool vendorChanged = false; // true once user selects a different vendor
  String? purchaseRequestId; // demand_pool.purchase_request_id — the PR that consumed this row

  // Qty planned in the most recent PR round only, derived at read time from
  // purchase_request_items (never stored on demand_pool). planned_qty on the
  // row stays cumulative because pending_qty = required_qty - planned_qty.
  int lastPlannedQty = 0;

  // Balance left after the latest planning round: prev required - last planned.
  //
  // Once a round has been approved, planned_qty already absorbed the latest
  // amount, so prev_required - last_planned collapses to plain pending_qty:
  //   pending_before - last = (required - (cum - last)) - last = required - cum
  // A PR that is only created (not yet approved) has not moved planned_qty, so
  // its planned amount is subtracted explicitly. Zero until something is planned.
  int get prevPendingQty {
    if (plannedQty > 0) return pendingQty;
    if (lastPlannedQty > 0) return (pendingQty - lastPlannedQty).clamp(0, pendingQty);
    return 0;
  }

  // Latest substitution (or null if none applied)
  String? get replacement => _substitutions.isEmpty ? null : _substitutions.last;

  // Append a new substitution to the chain
  set replacement(String? value) {
    if (value != null) _substitutions.add(value);
  }

  // Full ordered chain: [firstSub, secondSub, ...]
  List<String> get substitutionChain => List.unmodifiable(_substitutions);

  final String soNo;
  final String soDate;
  final String branch;
  final String customerName;

  // Customer on the linked sales order; falls back to the branch when the demand
  // row has no SO (e.g. manually seeded demand).
  String get customerLabel => customerName.isNotEmpty ? customerName : branch;

  final int reqQty;
  final int orderedQty;
  final int plannedQty;
  final int receivedQty;
  final int pendingQty;
  List<String> preferredVendors = [];
  String status = 'Open';
}


// Aggregated view for "Group By: Items" — one entry per distinct product,
// holding all constituent demand_pool rows + their global _rows indices.
class _AggregatedItem {
  _AggregatedItem({
    required this.product,
    required this.orders,
    required this.globalIndices,
  }) : preferredVendors = [];

  final String product;
  final List<_DpItem> orders;
  final List<int> globalIndices; // indices into _DemandPoolDialogState._rows
  List<String> preferredVendors;

  int get totalReqQty     => orders.fold(0, (s, o) => s + o.reqQty);
  int get totalPendingQty => orders.fold(0, (s, o) => s + o.pendingQty);

  // Qty planned in the latest PR round, not the running total.
  int get totalLastPlanned => orders.fold(0, (s, o) => s + o.lastPlannedQty);

  // Balance left after the latest planning round: required - last planned.
  // A brand-new pool row (never planned) contributes 0.
  int get totalPrevPending => orders.fold(0, (s, o) => s + o.prevPendingQty);

  // Open if ANY order is still open
  String get status =>
      orders.any((o) => o.status == 'Open') ? 'Open' : orders.first.status;

  List<String> get substitutionChain => orders.first.substitutionChain;

  // DB identifiers — taken from the first constituent order
  String get productId   => orders.first.productId;
  String get entityId    => orders.first.entityId;
  String? get vendorId   => orders.firstWhere((o) => o.vendorId != null, orElse: () => orders.first).vendorId;
  List<String> get demandPoolIds => orders.map((o) => o.rowId).toList();
}

class _VendorInfo {
  const _VendorInfo({
    required this.id,
    required this.name,
    this.companyName,
  });
  final String id;
  final String name;
  final String? companyName;
}

// ---------------------------------------------------------------------------
// Dialog
// ---------------------------------------------------------------------------

class _DemandPoolDialog extends ConsumerStatefulWidget {
  const _DemandPoolDialog();

  @override
  ConsumerState<_DemandPoolDialog> createState() => _DemandPoolDialogState();
}

class _DemandPoolDialogState extends ConsumerState<_DemandPoolDialog> {
  // header fields
  Warehouse? _selectedWarehouse;
  User? _assignee;
  DateTime? _expectedDate;
  final _expectedDateCtrl = TextEditingController();
  final _expectedDateKey = GlobalKey();
  final _notesCtrl = TextEditingController();
  String _groupBy = 'Items';

  // pending filter fields (multi-select) — user's current selection
  List<String> _filterCustomers = [];
  List<String> _filterItems = [];
  List<String> _filterSos = [];
  List<String> _filterVendors = [];
  // Default the status filter to Open only. Other states remain selectable from
  // the filter dropdown when the user wants to see them.
  static const List<String> _defaultStatuses = ['Open'];
  List<String> _filterStatuses = List.from(_defaultStatuses);

  bool get _hasAnyPendingFilter =>
      _filterCustomers.isNotEmpty ||
      _filterItems.isNotEmpty ||
      _filterSos.isNotEmpty ||
      _filterVendors.isNotEmpty ||
      _filterStatuses.isNotEmpty;

  // applied filters — set when Search is clicked
  List<String> _appliedCustomers = [];
  List<String> _appliedItems     = [];
  List<String> _appliedSos       = [];
  List<String> _appliedVendors   = [];
  List<String> _appliedStatuses  = List.from(_defaultStatuses);

  // filter product names — fetched directly from products table (all records)
  List<String> _productNames = [];

  // table state
  _TableTab _activeTab = _TableTab.all;
  final Set<int> _selected = {};
  OverlayEntry? _orderDetailsOverlay;
  List<_DpItem> _rows = [];
  bool _isLoadingRows = true;
  List<_VendorInfo> _vendorInfoList = [];

  // tracked during build so the Generate button can read them without setState
  List<_AggregatedItem> _lastAggRows = [];
  Set<int> _lastAggSelected = {};

  void _showOrderDetailsOverlay(_AggregatedItem agg) {
    _removeOrderDetailsOverlay();
    _orderDetailsOverlay = OverlayEntry(
      builder: (_) => Material(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Dismiss barrier
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeOrderDetailsOverlay,
                behavior: HitTestBehavior.opaque,
                child: Container(
                    color: Colors.black.withValues(alpha: 0.18)),
              ),
            ),
            // Popover — centered, pinned to top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: _OrderDetailsPopover(
                  agg: agg,
                  onClose: _removeOrderDetailsOverlay,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_orderDetailsOverlay!);
  }

  void _removeOrderDetailsOverlay() {
    _orderDetailsOverlay?.remove();
    _orderDetailsOverlay = null;
  }

  void _showPreferredVendorPopoverForAgg({
    required String vendorName,
    required String? vendorId,
    required List<String> demandPoolIds,
  }) {
    late OverlayEntry entry;
    var dismissed = false;

    void dismiss() {
      if (dismissed) return;
      dismissed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _PreferredVendorPopover(
        vendorName: vendorName,
        onConfirm: () {
          dismiss();
          if (vendorId != null) {
            for (final rowId in demandPoolIds) {
              Supabase.instance.client
                  .from('demand_pool')
                  .update({'preferred_vendor_id': vendorId})
                  .eq('id', rowId)
                  .then((_) {})
                  .catchError((e) {
                AppLogger.error('Failed to save preferred vendor',
                    error: e, module: 'DemandPool');
              });
            }
          }
        },
        onCancel: dismiss,
      ),
    );
    Overlay.of(context).insert(entry);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorProvider.notifier).loadVendors();
      _loadDemandPool();
      _loadVendors();
      _loadProductNames();
    });
  }

  Future<void> _loadDemandPool() async {
    try {
      final supabase = Supabase.instance.client;
      final entityState = ref.read(entityProvider);
      var query = supabase
          .from('demand_pool')
          .select('id, entity_id, product_id, purchase_request_id, sales_order_id, sales_order_item_id, required_qty, planned_qty, ordered_qty, received_qty, pending_qty, status, preferred_vendor_id, products(product_name), sales_orders(sale_number, sale_date, customers(display_name)), vendors!preferred_vendor_id(display_name)')
          .neq('status', 'FULFILLED');

      if (entityState.entityId != null) {
        query = query.eq('entity_id', entityState.entityId!);
      }

      final response = await query.order('created_at');

      if (!mounted) return;
      setState(() {
        _rows = (response as List<dynamic>).map((json) {
          final map = json as Map<String, dynamic>;
          final product = (map['products'] as Map<String, dynamic>?)?['product_name'] as String? ?? '';
          final soMap = map['sales_orders'] as Map<String, dynamic>?;
          final soNo = soMap?['sale_number'] as String? ?? '';
          final rawDate = soMap?['sale_date'];
          final soDate = rawDate != null ? rawDate.toString().substring(0, 10) : '';
          final customerName = (soMap?['customers'] as Map<String, dynamic>?)?['display_name'] as String? ?? '';
          final status = map['status'] as String? ?? 'OPEN';
          final vendorName = (map['vendors'] as Map<String, dynamic>?)?['display_name'] as String?;
          final item = _DpItem(
            rowId:     map['id'] as String? ?? '',
            productId: map['product_id'] as String? ?? '',
            entityId:  map['entity_id'] as String? ?? '',
            product: product,
            soNo: soNo,
            soDate: soDate,
            branch: 'Main',
            customerName: customerName,
            reqQty:      ((map['required_qty']  as num?)?.toInt()) ?? 0,
            orderedQty:  ((map['ordered_qty']   as num?)?.toInt()) ?? 0,
            plannedQty:  ((map['planned_qty']   as num?)?.toInt()) ?? 0,
            receivedQty: ((map['received_qty']  as num?)?.toInt()) ?? 0,
            pendingQty:  ((map['pending_qty']   as num?)?.toInt()) ?? 0,
          )..status = _normaliseDpStatus(status);
          item.vendorId = map['preferred_vendor_id'] as String?;
          item.purchaseRequestId = map['purchase_request_id'] as String?;
          item.salesOrderId = map['sales_order_id'] as String?;
          item.salesOrderItemId = map['sales_order_item_id'] as String?;
          if (vendorName != null && vendorName.isNotEmpty) {
            item.preferredVendors = [vendorName];
          }
          return item;
        }).toList();
        _isLoadingRows = false;
      });
      await _loadSubstitutions();
      await _loadLastPlannedQty();
    } catch (e) {
      AppLogger.error('Failed to load demand pool', error: e, module: 'DemandPool');
      if (mounted) setState(() => _isLoadingRows = false);
    }
  }

  /// Rebuild each row's substitution chain from `procurement_substitutions`.
  ///
  /// The chain lives only in memory otherwise, so without this a substituted row
  /// comes back looking untouched after a reload. Rows are replayed oldest-first
  /// so a product substituted more than once keeps its full chain order.
  Future<void> _loadSubstitutions() async {
    final rowIds =
        _rows.map((r) => r.rowId).where((id) => id.isNotEmpty).toList();
    if (rowIds.isEmpty) return;

    try {
      final res = await Supabase.instance.client
          .from('procurement_substitutions')
          .select('demand_pool_id, '
              'products!substitute_product_id(product_name)')
          .inFilter('demand_pool_id', rowIds)
          .eq('substitution_status', 'ACTIVE')
          .order('created_at');

      if (!mounted) return;

      final chains = <String, List<String>>{};
      for (final row in (res as List<dynamic>)) {
        final map = row as Map<String, dynamic>;
        final dpId = map['demand_pool_id'] as String?;
        final name = (map['products'] as Map<String, dynamic>?)?['product_name']
            as String?;
        if (dpId == null || name == null || name.isEmpty) continue;
        chains.putIfAbsent(dpId, () => []).add(name);
      }
      if (chains.isEmpty) return;

      setState(() {
        for (final row in _rows) {
          for (final name in chains[row.rowId] ?? const <String>[]) {
            row.replacement = name;
          }
        }
      });
    } catch (e) {
      AppLogger.error('Failed to load substitutions',
          error: e, module: 'DemandPool');
    }
  }

  /// Resolve each row's most recent planned qty from `purchase_request_items`.
  ///
  /// `demand_pool.planned_qty` is a running total across every approved PR, so
  /// the latest round's figure is not recoverable from it. The PR that consumed
  /// a row is recorded on `purchase_request_id`, and that PR's line item holds
  /// the qty planned for the product as a whole. Approval splits that qty across
  /// the PR's rows proportionally by `required_qty`
  /// (procurement_approvals_overview.dart), so the same split is applied here to
  /// land each row's share.
  Future<void> _loadLastPlannedQty() async {
    final prIds = _rows
        .map((r) => r.purchaseRequestId)
        .whereType<String>()
        .toSet()
        .toList();
    if (prIds.isEmpty) return;

    try {
      final response = await Supabase.instance.client
          .from('purchase_request_items')
          .select('purchase_request_id, product_id, planned_qty')
          .inFilter('purchase_request_id', prIds);

      // (purchaseRequestId, productId) -> qty that PR planned for the product.
      final plannedByPrProduct = <String, double>{};
      for (final json in response as List<dynamic>) {
        final map = json as Map<String, dynamic>;
        final key = '${map['purchase_request_id']}|${map['product_id']}';
        plannedByPrProduct[key] = (plannedByPrProduct[key] ?? 0) +
            ((map['planned_qty'] as num?)?.toDouble() ?? 0);
      }

      // Group the rows the same way approval does, then split by required_qty.
      final rowsByPrProduct = <String, List<_DpItem>>{};
      for (final row in _rows) {
        if (row.purchaseRequestId == null) continue;
        (rowsByPrProduct['${row.purchaseRequestId}|${row.productId}'] ??= [])
            .add(row);
      }

      for (final entry in rowsByPrProduct.entries) {
        final planned = plannedByPrProduct[entry.key] ?? 0;
        if (planned <= 0) continue;
        final siblings = entry.value;
        final totalWeight =
            siblings.fold<double>(0, (s, r) => s + r.reqQty);
        for (final row in siblings) {
          final share = totalWeight > 0 ? row.reqQty / totalWeight : 1.0 / siblings.length;
          row.lastPlannedQty = (planned * share).round().clamp(0, row.reqQty);
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      AppLogger.error('Failed to load last planned qty',
          error: e, module: 'DemandPool');
    }
  }

  Future<void> _loadVendors() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('vendors')
          .select('id, display_name, company_name')
          .order('display_name');
      if (!mounted) return;
      setState(() {
        _vendorInfoList = (response as List<dynamic>).map((json) {
          final map = json as Map<String, dynamic>;
          return _VendorInfo(
            id: map['id'] as String? ?? '',
            name: map['display_name'] as String? ?? '',
            companyName: map['company_name'] as String?,
          );
        }).toList();
      });
    } catch (e) {
      AppLogger.error('Failed to load vendors', error: e, module: 'DemandPool');
    }
  }

  Future<void> _loadProductNames() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('products')
          .select('product_name')
          .eq('is_active', true)
          .order('product_name');
      if (!mounted) return;
      setState(() {
        _productNames = (response as List<dynamic>)
            .map((r) => (r as Map<String, dynamic>)['product_name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      });
    } catch (e) {
      AppLogger.error('Failed to load product names', error: e, module: 'DemandPool');
    }
  }

  @override
  void dispose() {
    _removeOrderDetailsOverlay();
    _expectedDateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1080,
          minWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: _buildDialogContent(),
      ),
    );
  }

  Widget _buildDialogContent() {
    return Column(
      children: [
        _buildTitleBar(),
        const Divider(height: 1, color: AppTheme.borderColor),
        // Everything between title and footer scrolls as one unit
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeaderFields(),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.borderColor),
                const SizedBox(height: 12),
                _buildFilterRow(),
                const SizedBox(height: 16),
                _buildTableSection(),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        _buildFooter(),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Title bar
  // ---------------------------------------------------------------------------

  Widget _buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
      child: Row(
        children: [
          const Text(
            'DEMAND POOL',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () => Navigator.of(context).pop(),
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

  // ---------------------------------------------------------------------------
  // Header fields
  // ---------------------------------------------------------------------------

  Widget _buildHeaderFields() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FieldLabel(
                label: 'Warehouse',
                required: true,
                labelColor: AppTheme.errorRed,
                child: Builder(builder: (context) {
                  final warehousesAsync = ref.watch(warehousesProvider);
                  final warehouses = warehousesAsync.valueOrNull ?? [];
                  return FormDropdown<Warehouse>(
                    value: _selectedWarehouse,
                    items: warehouses,
                    hint: 'Select warehouse',
                    displayStringForValue: (w) => w.name,
                    searchStringForValue: (w) => w.name,
                    onChanged: (w) => setState(() => _selectedWarehouse = w),
                  );
                }),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _FieldLabel(
                label: 'Assignee',
                child: Builder(builder: (context) {
                  final users =
                      ref.watch(supabaseUsersProvider).valueOrNull ?? [];
                  return FormDropdown<User>(
                    value: _assignee,
                    items: users,
                    hint: 'Select assignee',
                    displayStringForValue: (u) => u.fullName.isNotEmpty ? u.fullName : u.email,
                    searchStringForValue: (u) =>
                        '${u.fullName} ${u.email} ${u.department ?? ''} ${u.position ?? ''}',
                    onChanged: (u) => setState(() => _assignee = u),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FieldLabel(
                label: 'Expected Date',
                child: GestureDetector(
                  key: _expectedDateKey,
                  onTap: () async {
                    final today = DateTime.now();
                    final firstAllowed = DateTime(today.year, today.month, today.day);
                    final picked = await ZerpaiDatePicker.show(
                      context,
                      initialDate: _expectedDate != null && _expectedDate!.isAfter(firstAllowed)
                          ? _expectedDate!
                          : firstAllowed,
                      firstDate: firstAllowed,
                      targetKey: _expectedDateKey,
                    );
                    if (picked != null) {
                      setState(() {
                        _expectedDate = picked;
                        _expectedDateCtrl.text =
                            '${picked.month.toString().padLeft(2, '0')}/'
                            '${picked.day.toString().padLeft(2, '0')}/'
                            '${picked.year}';
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: CustomTextField(
                      controller: _expectedDateCtrl,
                      hintText: 'mm/dd/yyyy',
                      height: 40,
                      suffixWidget: const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: _FieldLabel(
                label: 'Internal Notes',
                child: CustomTextField(
                  controller: _notesCtrl,
                  hintText: 'Enter notes here...',
                  maxLines: 5,
                  height: 90,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppTheme.borderColor),
        const SizedBox(height: 16),
        Row(
          children: [
            SizedBox(
              width: 260,
              child: _FieldLabel(
                label: 'Group By',
                child: FormDropdown<String>(
                  value: _groupBy,
                  items: const ['Items', 'Customers'],
                  hint: 'Select group',
                  displayStringForValue: (v) => v,
                  onChanged: (v) => setState(() => _groupBy = v ?? 'Items'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Filter row
  // ---------------------------------------------------------------------------

  Widget _buildFilterRow() {
    final allVendors = ref.watch(vendorProvider).vendors;
    final allCustomers =
        ref.watch(salesCustomersProvider).valueOrNull ?? <SalesCustomer>[];
    final allSalesOrders =
        ref.watch(salesOrderControllerProvider).valueOrNull ?? <SalesOrder>[];

    // Deduplicate by display name — if allVendors has two entries with the same
    // displayName, the where-by-name filter would produce duplicate chips.
    final _seenVendorNames = <String>{};
    final selectedFilterVendors = allVendors
        .where((v) =>
            _filterVendors.contains(v.displayName) &&
            _seenVendorNames.add(v.displayName))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_groupBy == 'Items') ...[
          // Items group-by: Items + Vendor — both multi-select
          Row(
            children: [
              Expanded(
                child: _FieldLabel(
                  label: 'Items',
                  hasSelection: _filterItems.isNotEmpty,
                  onClear: () => setState(() {
                    _filterItems = [];
                    _appliedItems = [];
                  }),
                  child: FormDropdown<String>(
                    value: null,
                    selectedValues: _filterItems,
                    multiSelect: true,
                    hideSelectedItemsInMultiSelect: true,
                    items: _productNames,
                    hint: 'Click or Type to select',
                    displayStringForValue: (n) => n,
                    onChanged: (_) {},
                    onSelectedValuesChanged: (vals) =>
                        setState(() => _filterItems = vals),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FieldLabel(
                  label: 'Vendor',
                  hasSelection: _filterVendors.isNotEmpty,
                  onClear: () => setState(() {
                    _filterVendors = [];
                    _appliedVendors = [];
                  }),
                  child: FormDropdown<_VendorInfo>(
                    value: null,
                    selectedValues: _vendorInfoList
                        .where((v) => _filterVendors.contains(v.name))
                        .toList(),
                    multiSelect: true,
                    hideSelectedItemsInMultiSelect: true,
                    items: _vendorInfoList,
                    hint: 'Click or Type to select',
                    displayStringForValue: (v) => v.name,
                    searchStringForValue: (v) =>
                        '${v.name} ${v.companyName ?? ''}',
                    onChanged: (_) {},
                    onSelectedValuesChanged: (vals) => setState(
                        () => _filterVendors = vals.map((v) => v.name).toList()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FieldLabel(
                  label: 'Status',
                  hasSelection: _filterStatuses.isNotEmpty,
                  onClear: () => setState(() {
                    _filterStatuses = [];
                    _appliedStatuses = [];
                  }),
                  child: FormDropdown<String>(
                    value: null,
                    multiSelect: true,
                    selectedValues: _filterStatuses,
                    items: _kStatusFilterOptions,
                    hint: 'All statuses',
                    displayStringForValue: (v) => v,
                    showSearch: false,
                    onChanged: (_) {},
                    onSelectedValuesChanged: (vals) =>
                        setState(() => _filterStatuses = vals),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Customers group-by: Customer Name, Items, Sales Orders, Vendor — all multi-select
          Row(
            children: [
              Expanded(
                child: _FieldLabel(
                  label: 'Customer Name',
                  hasSelection: _filterCustomers.isNotEmpty,
                  onClear: () => setState(() {
                    _filterCustomers = [];
                    _appliedCustomers = [];
                  }),
                  child: FormDropdown<SalesCustomer>(
                    value: null,
                    selectedValues: allCustomers
                        .where((c) => _filterCustomers.contains(c.displayName))
                        .toList(),
                    multiSelect: true,
                    hideSelectedItemsInMultiSelect: true,
                    items: allCustomers,
                    hint: 'Select customer',
                    displayStringForValue: (c) => c.displayName,
                    searchStringForValue: (c) =>
                        '${c.displayName} ${c.customerNumber ?? ''} ${c.phone ?? ''}',
                    onChanged: (_) {},
                    onSelectedValuesChanged: (vals) => setState(
                        () => _filterCustomers =
                            vals.map((c) => c.displayName).toList()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FieldLabel(
                  label: 'Items',
                  hasSelection: _filterItems.isNotEmpty,
                  onClear: () => setState(() {
                    _filterItems = [];
                    _appliedItems = [];
                  }),
                  child: FormDropdown<String>(
                    value: null,
                    selectedValues: _filterItems,
                    multiSelect: true,
                    hideSelectedItemsInMultiSelect: true,
                    items: _productNames,
                    hint: 'Click or Type to select',
                    displayStringForValue: (n) => n,
                    onChanged: (_) {},
                    onSelectedValuesChanged: (vals) =>
                        setState(() => _filterItems = vals),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FieldLabel(
                  label: 'Sales Orders',
                  hasSelection: _filterSos.isNotEmpty,
                  onClear: () => setState(() {
                    _filterSos = [];
                    _appliedSos = [];
                  }),
                  child: FormDropdown<SalesOrder>(
                    value: null,
                    selectedValues: allSalesOrders
                        .where((o) => _filterSos.contains(o.saleNumber))
                        .toList(),
                    multiSelect: true,
                    hideSelectedItemsInMultiSelect: true,
                    items: allSalesOrders,
                    hint: 'Click or Type to select',
                    displayStringForValue: (o) => o.saleNumber,
                    searchStringForValue: (o) =>
                        '${o.saleNumber} ${o.reference ?? ''} ${o.customer?.displayName ?? ''}',
                    onChanged: (_) {},
                    onSelectedValuesChanged: (vals) => setState(
                        () => _filterSos =
                            vals.map((o) => o.saleNumber).toList()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FieldLabel(
                  label: 'Vendor',
                  hasSelection: _filterVendors.isNotEmpty,
                  onClear: () => setState(() {
                    _filterVendors = [];
                    _appliedVendors = [];
                  }),
                  child: FormDropdown<Vendor>(
                    value: null,
                    selectedValues: selectedFilterVendors,
                    multiSelect: true,
                    hideSelectedItemsInMultiSelect: true,
                    items: allVendors,
                    hint: 'Click or Type to select',
                    displayStringForValue: (v) => v.displayName,
                    searchStringForValue: (v) =>
                        '${v.displayName} ${v.vendorNumber ?? ''}',
                    onChanged: (_) {},
                    onSelectedValuesChanged: (vals) => setState(
                        () => _filterVendors = vals.map((v) => v.displayName).toList()),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FieldLabel(
                  label: 'Status',
                  hasSelection: _filterStatuses.isNotEmpty,
                  onClear: () => setState(() {
                    _filterStatuses = [];
                    _appliedStatuses = [];
                  }),
                  child: FormDropdown<String>(
                    value: null,
                    multiSelect: true,
                    selectedValues: _filterStatuses,
                    items: _kStatusFilterOptions,
                    hint: 'All statuses',
                    displayStringForValue: (v) => v,
                    showSearch: false,
                    onChanged: (_) {},
                    onSelectedValuesChanged: (vals) =>
                        setState(() => _filterStatuses = vals),
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(
                begin: const Color(0xFFB2DFCA),
                end: _hasAnyPendingFilter ? AppTheme.successGreen : const Color(0xFFB2DFCA),
              ),
              duration: const Duration(milliseconds: 250),
              builder: (_, color, __) => ElevatedButton.icon(
                onPressed: () => setState(() {
                  _appliedCustomers = List.from(_filterCustomers);
                  _appliedItems     = List.from(_filterItems);
                  _appliedSos       = List.from(_filterSos);
                  _appliedVendors   = List.from(_filterVendors);
                  _appliedStatuses  = List.from(_filterStatuses);
                  _activeTab = _TableTab.all;
                  _selected.clear();
                }),
                icon: const Icon(LucideIcons.search, size: 14),
                label: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            if (_hasAnyPendingFilter ||
                _appliedItems.isNotEmpty ||
                _appliedVendors.isNotEmpty ||
                _appliedStatuses.isNotEmpty ||
                _appliedCustomers.isNotEmpty ||
                _appliedSos.isNotEmpty) ...[
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => setState(() {
                  _filterCustomers = [];
                  _filterItems     = [];
                  _filterSos       = [];
                  _filterVendors   = [];
                  _filterStatuses  = [];
                  _appliedCustomers = [];
                  _appliedItems     = [];
                  _appliedSos       = [];
                  _appliedVendors   = [];
                  _appliedStatuses  = [];
                  _activeTab = _TableTab.all;
                  _selected.clear();
                }),
                icon: const Icon(LucideIcons.x, size: 13),
                label: const Text('Clear'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Table section
  // ---------------------------------------------------------------------------

  Widget _buildTableSection() {
    if (_isLoadingRows) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    // Apply filters to _rows — empty list = no filter (show all)
    bool _matchesFilter(_DpItem r) {
      if (_appliedItems.isNotEmpty &&
          !_appliedItems.contains(r.product)) return false;
      if (_appliedCustomers.isNotEmpty &&
          !_appliedCustomers.contains(r.branch)) return false;
      if (_appliedSos.isNotEmpty &&
          !_appliedSos.contains(r.soNo)) return false;
      if (_appliedVendors.isNotEmpty &&
          !r.preferredVendors.any(_appliedVendors.contains)) return false;
      if (_appliedStatuses.isNotEmpty && !_matchesStatusFilter(r)) return false;
      return true;
    }

    final baseRows = _rows.where(_matchesFilter).toList();

    // Compute which rows to display + mapping back to global indices
    final List<_DpItem> visibleRows;
    final List<int> globalIdxMap;

    if (_activeTab == _TableTab.selected) {
      visibleRows  = [];
      globalIdxMap = [];
      for (int i = 0; i < _rows.length; i++) {
        if (_selected.contains(i) && _matchesFilter(_rows[i])) {
          visibleRows.add(_rows[i]);
          globalIdxMap.add(i);
        }
      }
    } else {
      visibleRows  = baseRows;
      globalIdxMap = [
        for (int i = 0; i < _rows.length; i++)
          if (_matchesFilter(_rows[i])) i,
      ];
    }

    // -----------------------------------------------------------------------
    // Aggregate by product for "Items" group-by view
    // -----------------------------------------------------------------------
    List<_AggregatedItem> _aggregateByProduct() {
      final map = <String, List<(int, _DpItem)>>{};
      for (int i = 0; i < visibleRows.length; i++) {
        (map[visibleRows[i].product] ??= []).add((globalIdxMap[i], visibleRows[i]));
      }
      return map.entries.map((e) {
        final idxItems = e.value;
        final agg = _AggregatedItem(
          product: e.key,
          orders: idxItems.map((t) => t.$2).toList(),
          globalIndices: idxItems.map((t) => t.$1).toList(),
        );
        final withVendors = idxItems
            .map((t) => t.$2)
            .where((o) => o.preferredVendors.isNotEmpty)
            .firstOrNull;
        if (withVendors != null) {
          agg.preferredVendors = List.from(withVendors.preferredVendors);
        }
        return agg;
      }).toList();
    }

    final aggRows = _aggregateByProduct();

    // Tab counts differ by view
    final int allCount = _groupBy == 'Customers'
        ? visibleRows.length
        : aggRows.length;
    final int selectedCount = _selected.length;

    // -----------------------------------------------------------------------
    // Customers-view helpers (local indices into visibleRows)
    // -----------------------------------------------------------------------
    int toGlobal(int local) => globalIdxMap[local];
    List<int> branchToGlobal(List<int> locals) => locals.map(toGlobal).toList();

    final visibleSelected = <int>{
      for (int li = 0; li < visibleRows.length; li++)
        if (_selected.contains(globalIdxMap[li])) li,
    };

    void toggleOne(int local) => setState(() {
          final g = toGlobal(local);
          _selected.contains(g) ? _selected.remove(g) : _selected.add(g);
        });

    void toggleAll() => setState(() {
          if (_selected.length == _rows.length) {
            _selected.clear();
          } else {
            _selected
              ..clear()
              ..addAll(List.generate(_rows.length, (i) => i));
          }
        });

    // -----------------------------------------------------------------------
    // Items-view helpers (indices into aggRows)
    // -----------------------------------------------------------------------
    final aggSelected = <int>{
      for (int i = 0; i < aggRows.length; i++)
        if (aggRows[i].globalIndices.every(_selected.contains)) i,
    };

    // Track so Generate button can read without an extra aggregation pass
    _lastAggRows = aggRows;
    _lastAggSelected = aggSelected;

    void toggleAgg(int aggIdx) => setState(() {
          final agg = aggRows[aggIdx];
          final allIn = agg.globalIndices.every(_selected.contains);
          if (allIn) {
            _selected.removeAll(agg.globalIndices);
          } else {
            _selected.addAll(agg.globalIndices);
          }
        });

    void toggleAllAgg() => setState(() {
          final allGlobals =
              aggRows.expand((a) => a.globalIndices).toList();
          final allIn = allGlobals.every(_selected.contains);
          if (allIn) {
            _selected.removeAll(allGlobals);
          } else {
            _selected.addAll(allGlobals);
          }
        });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tabs + Group By label
        Row(
          children: [
            _DpTab(
              label: 'All Items($allCount)',
              isActive: _activeTab == _TableTab.all,
              onTap: () => setState(() => _activeTab = _TableTab.all),
            ),
            const SizedBox(width: 4),
            _DpTab(
              label: 'Selected Items($selectedCount)',
              isActive: _activeTab == _TableTab.selected,
              onTap: () => setState(() => _activeTab = _TableTab.selected),
            ),
            const Spacer(),
            Text(
              'Group By: $_groupBy',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: AppTheme.borderColor),
        _groupBy == 'Customers'
            ? _BranchGroupTable(
                rows: visibleRows,
                selected: visibleSelected,
                vendors: _vendorInfoList,
                onToggle: toggleOne,
                onToggleAll: toggleAll,
                onToggleBranch: (localIndices) => setState(() {
                  final globals = branchToGlobal(localIndices);
                  final allIn   = globals.every(_selected.contains);
                  if (allIn) {
                    _selected.removeAll(globals);
                  } else {
                    _selected.addAll(globals);
                  }
                }),
                onVendorChanged: (local, v) => setState(() {
                  final gi = toGlobal(local);
                  _rows[gi].preferredVendors = v;
                  _rows[gi].vendorChanged = true;
                  _rows[gi].vendorId = v.isNotEmpty
                      ? _vendorInfoList.where((vi) => vi.name == v.first).firstOrNull?.id
                      : null;
                }),
                onSubstitute: (local, v) =>
                    _applySubstitution([toGlobal(local)], v),
              )
            : _ItemsGroupTable(
                rows: aggRows,
                selected: aggSelected,
                vendors: _vendorInfoList,
                onToggle: toggleAgg,
                onToggleAll: toggleAllAgg,
                onVendorChanged: (aggIdx, v) => setState(() {
                  final newVendorId = v.isNotEmpty
                      ? _vendorInfoList.where((vi) => vi.name == v.first).firstOrNull?.id
                      : null;
                  for (final gi in aggRows[aggIdx].globalIndices) {
                    _rows[gi].preferredVendors = v;
                    _rows[gi].vendorChanged = true;
                    _rows[gi].vendorId = newVendorId;
                  }
                }),
                onDropdownVendorPicked: (aggIdx, vendorName, vendorId) {
                  _showPreferredVendorPopoverForAgg(
                    vendorName: vendorName,
                    vendorId: vendorId,
                    demandPoolIds: aggRows[aggIdx].demandPoolIds,
                  );
                },
                onShowOrderDetails: _showOrderDetailsOverlay,
                onSubstitute: (aggIdx, v) =>
                    _applySubstitution(aggRows[aggIdx].globalIndices, v),
              ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Substitution → update the on-screen chain and record it in the DB
  // ---------------------------------------------------------------------------

  /// Whether [r] satisfies the multi-select Status filter. Selecting several
  /// statuses is an OR — a row matching any one of them is kept.
  ///
  /// "Substituted" is deliberately not compared against `status`. Substitution
  /// is a second dimension, not a pipeline stage: a row can be Open *and*
  /// substituted, and it keeps progressing to PR Created, PO Created and so on
  /// afterwards. Writing SUBSTITUTED into `demand_pool.status` would erase
  /// whichever stage the row was really at, and the next planning round would
  /// overwrite it straight back. So it is matched on the substitution itself,
  /// which `_hydrateSubstitutions` rebuilds from `procurement_substitutions`
  /// on every load.
  bool _matchesStatusFilter(_DpItem r) {
    return _appliedStatuses.any(
      (s) => s == 'Substituted' ? r.replacement != null : r.status == s,
    );
  }

  /// Applies [substitute] to every demand pool row in [globalIndices] and writes
  /// one `procurement_substitutions` row per demand pool row, so a substitution
  /// made against an aggregated item is traceable back to each order it covered.
  Future<void> _applySubstitution(List<int> globalIndices, Item? substitute) async {
    if (substitute == null || globalIndices.isEmpty) return;

    final substituteId = substitute.id;
    final substituteName = substitute.billingName?.isNotEmpty == true
        ? substitute.billingName!
        : substitute.productName;

    setState(() {
      for (final gi in globalIndices) {
        _rows[gi].replacement = substituteName;
      }
    });

    // Without a product id there is nothing to point the FK at — keep the UI
    // change (the user still sees the swap) but skip the insert.
    if (substituteId == null || substituteId.isEmpty) {
      AppLogger.warning(
        'Substitute product has no id — substitution not recorded',
        module: 'DemandPool',
      );
      return;
    }

    final payload = globalIndices.map((gi) {
      final row = _rows[gi];
      return {
        'entity_id': row.entityId,
        'warehouse_id': _selectedWarehouse?.id,
        'source_module': 'DEMAND_POOL',
        'demand_pool_id': row.rowId,
        // Carried from the demand pool row so the sales order that raised this
        // demand can show the substitution without walking back through the pool.
        'sales_order_id': row.salesOrderId,
        'sales_order_item_id': row.salesOrderItemId,
        'original_product_id': row.productId,
        'substitute_product_id': substituteId,
        'original_qty': row.reqQty,
        'substitute_qty': row.reqQty,
        'vendor_id': row.vendorId,
      };
    }).toList();

    try {
      await Supabase.instance.client
          .from('procurement_substitutions')
          .insert(payload);
    } catch (e) {
      AppLogger.error('Failed to save substitution',
          error: e, module: 'DemandPool');
    }
  }

  // ---------------------------------------------------------------------------
  // Generate Purchase Request → pop with line items so caller can navigate
  // ---------------------------------------------------------------------------

  void _generatePurchaseRequest() {
    if (_selectedWarehouse == null) return;

    final toGenerate = _lastAggSelected.isNotEmpty
        ? _lastAggSelected.map((i) => _lastAggRows[i]).toList()
        : List<_AggregatedItem>.from(_lastAggRows);

    if (toGenerate.isEmpty) return;

    final lineItems = toGenerate
        .map((agg) {
          // Pull only the remaining balance still to procure — the same
          // "Total Required" (pending) shown in the REQ QTY column / Order
          // Details. Planned reflects approved PRs; a fresh PR plans none yet.
          final balance = agg.totalPendingQty.clamp(0, agg.totalReqQty);
          return DemandPoolLineItem(
            productId: agg.productId,
            productName: agg.product,
            entityId: agg.entityId,
            reqQty: balance,
            plannedQty: 0,
            pendingQty: balance,
            vendorId: agg.vendorId,
            vendorName: agg.preferredVendors.isNotEmpty ? agg.preferredVendors.first : null,
            demandPoolIds: agg.demandPoolIds,
          );
        })
        .toList();

    if (!mounted) return;
    Navigator.of(context).pop(DemandPoolPayload(
      lineItems: lineItems,
      assigneeId: _assignee?.id,
      assigneeName: _assignee != null
          ? (_assignee!.fullName.isNotEmpty
              ? _assignee!.fullName
              : _assignee!.email)
          : null,
      expectedDate: _expectedDate,
    ));
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildFooter() {
    // Warehouse is mandatory — no PR can be generated until one is picked.
    final canGenerate = _selectedWarehouse != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: canGenerate ? _generatePurchaseRequest : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              disabledBackgroundColor: AppTheme.successGreen.withValues(alpha: 0.38),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: const Text('Generate Purchase Request'),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textBody,
              side: const BorderSide(color: AppTheme.borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab enum + widget
// ---------------------------------------------------------------------------

enum _TableTab { all, selected }

class _DpTab extends StatelessWidget {
  const _DpTab({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppTheme.successGreen : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Branch group table
// ---------------------------------------------------------------------------

class _BranchGroupTable extends StatelessWidget {
  const _BranchGroupTable({
    required this.rows,
    required this.selected,
    required this.vendors,
    required this.onToggle,
    required this.onToggleAll,
    required this.onToggleBranch,
    required this.onVendorChanged,
    required this.onSubstitute,
  });

  final List<_DpItem> rows;
  final Set<int> selected;
  final List<_VendorInfo> vendors;
  final ValueChanged<int> onToggle;
  final VoidCallback onToggleAll;
  final void Function(List<int> indices) onToggleBranch;
  final void Function(int, List<String>) onVendorChanged;
  final void Function(int, Item?) onSubstitute;

  static const TextStyle _hStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppTheme.textMuted,
    letterSpacing: 0.5,
  );

  @override
  Widget build(BuildContext context) {
    final allSelected = rows.isNotEmpty && selected.length == rows.length;
    final customers = rows.map((r) => r.customerLabel).toSet().toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header row
        Container(
          color: AppTheme.bgLight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Checkbox(
                  value: allSelected,
                  onChanged: (_) => onToggleAll(),
                  activeColor: AppTheme.primaryBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(flex: 5, child: Text('PRODUCT', style: _hStyle)),
              const SizedBox(width: 72, child: Text('REQ QTY', style: _hStyle, textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              const SizedBox(width: 96, child: Text('PLANNED QTY', style: _hStyle, textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              const SizedBox(width: 104, child: Text('PREV. PENDING', style: _hStyle, textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              const SizedBox(width: 100, child: Text('STATUS', style: _hStyle)),
              const Expanded(flex: 3, child: Text('PREFERRED VENDOR', style: _hStyle)),
              const SizedBox(width: 28),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        // Customer groups
        ...customers.map((customer) {
          final customerRows = rows.where((r) => r.customerLabel == customer).toList();
          final customerIndices = customerRows.map((r) => rows.indexOf(r)).toList();
          final allCustomerSelected = customerIndices.isNotEmpty &&
              customerIndices.every(selected.contains);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customer group header — "Customer: <name>" label
              Container(
                color: const Color(0xFFEFF6FF),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Checkbox(
                        value: allCustomerSelected,
                        onChanged: (_) => onToggleBranch(customerIndices),
                        activeColor: AppTheme.primaryBlue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'CUSTOMER: $customer',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              ...customerRows.map((item) {
                final globalIdx = rows.indexOf(item);
                return _BranchRow(
                  item: item,
                  globalIdx: globalIdx,
                  isSelected: selected.contains(globalIdx),
                  vendors: vendors,
                  onToggle: () => onToggle(globalIdx),
                  onVendorChanged: (v) => onVendorChanged(globalIdx, v),
                  onSubstitute: (v) => onSubstitute(globalIdx, v),
                );
              }),
              const Divider(height: 1, color: AppTheme.borderColor),
            ],
          );
        }),
      ],
    );
  }
}

class _BranchRow extends StatefulWidget {
  const _BranchRow({
    required this.item,
    required this.globalIdx,
    required this.isSelected,
    required this.vendors,
    required this.onToggle,
    required this.onVendorChanged,
    required this.onSubstitute,
  });

  final _DpItem item;
  final int globalIdx;
  final bool isSelected;
  final List<_VendorInfo> vendors;
  final VoidCallback onToggle;
  final ValueChanged<List<String>> onVendorChanged;
  final ValueChanged<Item?> onSubstitute;

  @override
  State<_BranchRow> createState() => _BranchRowState();
}

class _BranchRowState extends State<_BranchRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.04)
              : _hovered
                  ? AppTheme.bgDisabled
                  : Colors.white,
          borderRadius: AppTheme.hoverRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Checkbox(
                value: widget.isSelected,
                onChanged: (_) => widget.onToggle(),
                activeColor: AppTheme.primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            // Product name
            Expanded(
              flex: 5,
              child: SubstitutedProductText(
                product: item.product,
                substitutionChain: item.substitutionChain,
              ),
            ),
            // Req Qty
            SizedBox(
              width: 72,
              child: Text(
                '${item.reqQty}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            const SizedBox(width: 12),
            // Planned Qty
            SizedBox(
              width: 96,
              child: Text(
                '${item.lastPlannedQty}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            const SizedBox(width: 12),
            // Prev. Pending = required - last planned; 0 for a brand-new pool
            // row (nothing has been planned against it yet).
            SizedBox(
              width: 104,
              child: Text(
                '${item.prevPendingQty}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            const SizedBox(width: 12),
            // Status
            SizedBox(
              width: 100,
              child: _DpStatusText(item.status),
            ),
            // Preferred Vendor
            Expanded(
              flex: 3,
              child: _VendorRichDropdown(
                values: item.preferredVendors,
                vendors: widget.vendors,
                onChanged: widget.onVendorChanged,
              ),
            ),
            // ⋮ menu
            SizedBox(
              width: 28,
              child: _RowMenu(item: item, onSubstitute: widget.onSubstitute, isCustomersView: true),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Items group table
// ---------------------------------------------------------------------------

class _ItemsGroupTable extends StatelessWidget {
  const _ItemsGroupTable({
    required this.rows,
    required this.selected,
    required this.vendors,
    required this.onToggle,
    required this.onToggleAll,
    required this.onVendorChanged,
    required this.onShowOrderDetails,
    required this.onSubstitute,
    this.onDropdownVendorPicked,
  });

  final List<_AggregatedItem> rows;
  final Set<int> selected;
  final List<_VendorInfo> vendors;
  final ValueChanged<int> onToggle;
  final VoidCallback onToggleAll;
  final void Function(int, List<String>) onVendorChanged;
  final ValueChanged<_AggregatedItem> onShowOrderDetails;
  final void Function(int, Item?) onSubstitute;
  final void Function(int idx, String vendorName, String? vendorId)? onDropdownVendorPicked;

  static const TextStyle _hStyle = TextStyle(
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
        // Header
        Container(
          color: AppTheme.bgLight,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Checkbox(
                  value: allSelected,
                  onChanged: (_) => onToggleAll(),
                  activeColor: AppTheme.primaryBlue,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(flex: 3, child: Text('PRODUCT', style: _hStyle)),
              const SizedBox(width: 72, child: Text('REQ QTY', style: _hStyle, textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              const SizedBox(width: 96, child: Text('PLANNED QTY', style: _hStyle, textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              const SizedBox(width: 104, child: Text('PREV. PENDING', style: _hStyle, textAlign: TextAlign.center)),
              const SizedBox(width: 12),
              const SizedBox(width: 100, child: Text('STATUS', style: _hStyle)),
              const Expanded(flex: 3, child: Text('PREFERRED VENDOR', style: _hStyle)),
              const SizedBox(width: 28),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderColor),
        ...List.generate(rows.length, (i) {
          final agg = rows[i];
          return Column(
            children: [
              _ItemsRow(
                agg: agg,
                idx: i,
                isSelected: selected.contains(i),
                vendors: vendors,
                onToggle: () => onToggle(i),
                onVendorChanged: (v) => onVendorChanged(i, v),
                onShowOrderDetails: () => onShowOrderDetails(agg),
                onSubstitute: (v) => onSubstitute(i, v),
                onDropdownVendorPicked: onDropdownVendorPicked != null
                    ? (name, id) => onDropdownVendorPicked!(i, name, id)
                    : null,
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

class _ItemsRow extends StatefulWidget {
  const _ItemsRow({
    required this.agg,
    required this.idx,
    required this.isSelected,
    required this.vendors,
    required this.onToggle,
    required this.onVendorChanged,
    required this.onShowOrderDetails,
    required this.onSubstitute,
    this.onDropdownVendorPicked,
  });

  final _AggregatedItem agg;
  final int idx;
  final bool isSelected;
  final List<_VendorInfo> vendors;
  final VoidCallback onToggle;
  final ValueChanged<List<String>> onVendorChanged;
  final VoidCallback onShowOrderDetails;
  final ValueChanged<Item?> onSubstitute;
  final void Function(String vendorName, String? vendorId)? onDropdownVendorPicked;

  @override
  State<_ItemsRow> createState() => _ItemsRowState();
}

class _ItemsRowState extends State<_ItemsRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final agg = widget.agg;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isSelected
              ? AppTheme.primaryBlue.withValues(alpha: 0.04)
              : _hovered
                  ? AppTheme.bgDisabled
                  : Colors.white,
          borderRadius: AppTheme.hoverRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Checkbox(
                value: widget.isSelected,
                onChanged: (_) => widget.onToggle(),
                activeColor: AppTheme.primaryBlue,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            // Product
            Expanded(
              flex: 3,
              child: SubstitutedProductText(
                product: agg.product,
                substitutionChain: agg.substitutionChain,
              ),
            ),
            // Req Qty — shows Total Required (pending to procure), matching the
            // Order Details "Total Required". Tappable to open the breakdown.
            SizedBox(
              width: 72,
              child: GestureDetector(
                onTap: widget.onShowOrderDetails,
                child: Text(
                  '${agg.totalPendingQty}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Planned Qty
            SizedBox(
              width: 96,
              child: Text(
                '${agg.totalLastPlanned}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            const SizedBox(width: 12),
            // Prev. Pending = pending carried from an earlier PR round; 0 for a
            // brand-new pool item (nothing was pending before it was added).
            SizedBox(
              width: 104,
              child: Text(
                '${agg.totalPrevPending}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
              ),
            ),
            const SizedBox(width: 12),
            // Status
            SizedBox(
              width: 100,
              child: _DpStatusText(agg.status),
            ),
            // Preferred Vendor — single-select in Items view
            Expanded(
              flex: 3,
              child: _VendorRichDropdown(
                values: agg.preferredVendors,
                vendors: widget.vendors,
                onChanged: widget.onVendorChanged,
                singleSelect: true,
                onDropdownVendorPicked: widget.onDropdownVendorPicked,
              ),
            ),
            // ⋮ menu
            SizedBox(
              width: 28,
              child: _RowMenu(
                item: agg.orders.first,
                onSubstitute: widget.onSubstitute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Order Details popover
// ---------------------------------------------------------------------------

class _OrderDetailsPopover extends StatelessWidget {
  const _OrderDetailsPopover({required this.agg, required this.onClose});

  final _AggregatedItem agg;
  final VoidCallback onClose;

  static const TextStyle _colHeaderStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppTheme.textMuted,
    letterSpacing: 0.4,
  );

  static const TextStyle _valueStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppTheme.textBody,
  );

  static const TextStyle _totalLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
  );

  static const TextStyle _totalValueStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
  );

  @override
  Widget build(BuildContext context) {
    final orders = agg.orders;

    return Container(
      width: 980,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Title bar ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'ORDER DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(LucideIcons.x, size: 15, color: AppTheme.errorRed),
                ),
              ],
            ),
          ),
          // ── Item subheading ──
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.bgLight,
              border: Border(left: BorderSide(color: AppTheme.borderColor, width: 3)),
            ),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ITEM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  agg.product,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          // ── Column headers ──
          Container(
            color: AppTheme.bgLight,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: const Row(
              children: [
                SizedBox(width: 100, child: Text('SO NO', style: _colHeaderStyle)),
                Expanded(child: Text('CUSTOMER', style: _colHeaderStyle)),
                SizedBox(width: 75, child: Text('ORDERED', style: _colHeaderStyle, textAlign: TextAlign.center)),
                SizedBox(width: 70, child: Text('PICKED', style: _colHeaderStyle, textAlign: TextAlign.center)),
                SizedBox(width: 70, child: Text('PACKED', style: _colHeaderStyle, textAlign: TextAlign.center)),
                SizedBox(width: 75, child: Text('INVOICED', style: _colHeaderStyle, textAlign: TextAlign.center)),
                SizedBox(width: 105, child: Text('PURCHASE ORDER', style: _colHeaderStyle, textAlign: TextAlign.center)),
                SizedBox(width: 65, child: Text('BILLS', style: _colHeaderStyle, textAlign: TextAlign.center)),
                SizedBox(width: 72, child: Text('REQUIRED', style: _colHeaderStyle, textAlign: TextAlign.center)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          // ── One row per customer order ──
          ...orders.asMap().entries.map((entry) {
            final i = entry.key;
            final order = entry.value;
            return Column(
              children: [
                Container(
                  color: i.isOdd ? AppTheme.bgLight : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // SO No
                      SizedBox(
                        width: 100,
                        child: Text(
                          order.soNo.isNotEmpty ? order.soNo : '—',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      // Customer from the linked sales order
                      Expanded(
                        child: Text(
                          order.customerLabel.isNotEmpty ? order.customerLabel : '—',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textBody,
                          ),
                        ),
                      ),
                      // Ordered (= required qty from SO)
                      SizedBox(
                        width: 75,
                        child: Text('${order.reqQty}', style: _valueStyle, textAlign: TextAlign.center),
                      ),
                      // Picked = reqQty − pendingQty (fulfilled from stock)
                      SizedBox(
                        width: 70,
                        child: Text('${order.reqQty - order.pendingQty}', style: _valueStyle, textAlign: TextAlign.center),
                      ),
                      // Packed
                      const SizedBox(width: 70, child: Text('0', style: _valueStyle, textAlign: TextAlign.center)),
                      // Invoiced
                      const SizedBox(width: 75, child: Text('0', style: _valueStyle, textAlign: TextAlign.center)),
                      // Purchase Order
                      const SizedBox(width: 105, child: Text('0', style: _valueStyle, textAlign: TextAlign.center)),
                      // Bills
                      const SizedBox(width: 65, child: Text('0', style: _valueStyle, textAlign: TextAlign.center)),
                      // Required = pendingQty (still unmet)
                      SizedBox(
                        width: 72,
                        child: Text(
                          '${order.pendingQty}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textBody,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
              ],
            );
          }),
          // ── Total row ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const SizedBox(width: 100),
                const Expanded(child: Text('Total Required', style: _totalLabelStyle)),
                const SizedBox(width: 75),
                const SizedBox(width: 70),
                const SizedBox(width: 70),
                const SizedBox(width: 75),
                const SizedBox(width: 105),
                const SizedBox(width: 65),
                SizedBox(
                  width: 72,
                  child: Text(
                    '${agg.totalPendingQty}',
                    style: _totalValueStyle.copyWith(color: AppTheme.primaryBlue),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets
// ---------------------------------------------------------------------------

class _VendorRichDropdown extends StatefulWidget {
  const _VendorRichDropdown({
    required this.values,
    required this.vendors,
    required this.onChanged,
    this.singleSelect = false,
    this.onDropdownVendorPicked,
  });

  final List<String> values;
  final List<_VendorInfo> vendors;
  final ValueChanged<List<String>> onChanged;
  // When true: selecting a vendor replaces the current selection (no chips).
  final bool singleSelect;
  final void Function(String vendorName, String? vendorId)? onDropdownVendorPicked;

  @override
  State<_VendorRichDropdown> createState() => _VendorRichDropdownState();
}

class _VendorRichDropdownState extends State<_VendorRichDropdown> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;
  late List<String> _localValues;
  bool _blockToggleOnce = false;

  @override
  void initState() {
    super.initState();
    _localValues = List.from(widget.values);
  }

  @override
  void didUpdateWidget(_VendorRichDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // only sync external changes (e.g. row reset), not our own toggle-driven updates
    if (!_localListEquals(widget.values, _localValues)) {
      _localValues = List.from(widget.values);
      _overlay?.markNeedsBuild();
    }
  }

  bool _localListEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _toggleOpen() {
    if (_blockToggleOnce) {
      _blockToggleOnce = false;
      return;
    }
    _overlay == null ? _open() : _close();
  }

  void _open() {
    _overlay = OverlayEntry(builder: (_) => _buildPanel());
    Overlay.of(context).insert(_overlay!);
    setState(() {});
  }

  void _close() {
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() {});
  }

  void _toggleVendor(String name) {
    if (widget.singleSelect) {
      // Single-select: pick this vendor and close
      final next = _localValues.contains(name) ? <String>[] : [name];
      setState(() => _localValues = next);
      widget.onChanged(List.from(_localValues));
      _close();
      if (next.isNotEmpty && widget.onDropdownVendorPicked != null) {
        final info = widget.vendors.firstWhere(
          (v) => v.name == name,
          orElse: () => _VendorInfo(id: '', name: name),
        );
        widget.onDropdownVendorPicked!(name, info.id.isEmpty ? null : info.id);
      }
      return;
    }
    setState(() {
      if (_localValues.contains(name)) {
        _localValues.remove(name);
      } else {
        _localValues.add(name);
      }
    });
    widget.onChanged(List.from(_localValues));
    _overlay?.markNeedsBuild();
  }

  void _removeVendor(String name) {
    _blockToggleOnce = true;
    setState(() {
      _localValues.remove(name);
    });
    widget.onChanged(List.from(_localValues));
  }

  Widget _buildPanel() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 3),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < widget.vendors.length; i++) ...[
                          _VendorItem(
                            info: widget.vendors[i],
                            isSelected: _localValues.contains(widget.vendors[i].name),
                            isFirst: i == 0,
                            isLast: i == widget.vendors.length - 1,
                            onTap: () => _toggleVendor(widget.vendors[i].name),
                          ),
                          if (i < widget.vendors.length - 1)
                            const Divider(height: 1, color: AppTheme.borderColor),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _overlay?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOpen = _overlay != null;

    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggleOpen,
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isOpen ? AppTheme.primaryBlue : AppTheme.borderColor,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _localValues.isEmpty
                    ? const Text(
                        'Select Vendor',
                        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                      )
                    : widget.singleSelect
                        // Single-select: plain text, no chips
                        ? Text(
                            _localValues.first,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textBody,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          )
                        // Multi-select: chip list
                        : Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: _localValues.map((name) {
                              return Container(
                                padding: const EdgeInsets.fromLTRB(6, 2, 4, 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.primaryBlue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    GestureDetector(
                                      onTap: () => _removeVendor(name),
                                      child: const Icon(
                                        LucideIcons.x,
                                        size: 10,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
              ),
              Icon(
                isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 14,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VendorItem extends StatefulWidget {
  const _VendorItem({
    required this.info,
    required this.isSelected,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final _VendorInfo info;
  final bool isSelected;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  State<_VendorItem> createState() => _VendorItemState();
}

class _VendorItemState extends State<_VendorItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isSelected || _hovered;
    final radius = BorderRadius.only(
      topLeft: widget.isFirst ? const Radius.circular(8) : Radius.zero,
      topRight: widget.isFirst ? const Radius.circular(8) : Radius.zero,
      bottomLeft: widget.isLast ? const Radius.circular(8) : Radius.zero,
      bottomRight: widget.isLast ? const Radius.circular(8) : Radius.zero,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryBlue : Colors.white,
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.info.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppTheme.textPrimary,
                ),
              ),
              if (widget.info.companyName != null && widget.info.companyName!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  widget.info.companyName!,
                  style: TextStyle(
                    fontSize: 11,
                    color: active
                        ? Colors.white.withValues(alpha: 0.82)
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({
    required this.item,
    required this.onSubstitute,
    this.isCustomersView = false,
  });

  final _DpItem item;
  final ValueChanged<Item?> onSubstitute;
  final bool isCustomersView;

  void _showPreferredVendorConfirm(OverlayState overlay) {
    late OverlayEntry entry;
    var _dismissed = false;

    void dismiss() {
      if (_dismissed) return;
      _dismissed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _PreferredVendorPopover(
        vendorName: item.preferredVendors.isEmpty ? 'selected vendor' : item.preferredVendors.first,
        onConfirm: () {
          dismiss();
          if (item.vendorId != null) {
            Supabase.instance.client
                .from('demand_pool')
                .update({'preferred_vendor_id': item.vendorId})
                .eq('id', item.rowId)
                .then((_) {})
                .catchError((e) {
              AppLogger.error('Failed to save preferred vendor',
                  error: e, module: 'DemandPool');
            });
          }
        },
        onCancel: dismiss,
      ),
    );
    overlay.insert(entry);
  }

  void _showItemRegistrationPopover(OverlayState overlay) {
    late OverlayEntry entry;
    var _dismissed = false;

    void dismiss() {
      if (_dismissed) return;
      _dismissed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _ItemRegistrationPopover(
        itemName: item.replacement ?? item.product,
        sourceDemandPoolId: item.rowId,
        onCancel: dismiss,
        onSubmit: dismiss,
      ),
    );
    overlay.insert(entry);
  }

  void _showCancelItemsSimplePopover(OverlayState overlay) {
    late OverlayEntry entry;
    var _dismissed = false;

    void dismiss() {
      if (_dismissed) return;
      _dismissed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _CancelItemsSimplePopover(
        item: item,
        onCancel: dismiss,
        onConfirm: dismiss,
      ),
    );
    overlay.insert(entry);
  }

  void _showCancelItemsPopover(OverlayState overlay) {
    late OverlayEntry entry;
    var _dismissed = false;

    void dismiss() {
      if (_dismissed) return;
      _dismissed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _CancelItemsPopover(
        item: item,
        onCancel: dismiss,
        onConfirm: dismiss,
      ),
    );
    overlay.insert(entry);
  }

  void _showSubstitutePopover(OverlayState overlay) {
    late OverlayEntry entry;
    var _dismissed = false;

    void dismiss() {
      if (_dismissed) return;
      _dismissed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (_) => _SubstitutePopover(
        originalItem: item.replacement ?? item.product,
        onCancel: dismiss,
        onApply: (substitute) {
          onSubstitute(substitute);
          dismiss();
        },
      ),
    );
    overlay.insert(entry);
  }

  // Fixed menu width, and the width of the ⋮ trigger (icon 14 + padding 4×2).
  static const double _menuWidth = 220;
  static const double _triggerWidth = 22;

  // Nudge past flush-right so the menu sits slightly right of the dots.
  // The dialog edge is only ~50px beyond the trigger, so this is near the
  // limit before the menu starts spilling outside the dialog.
  static const double _nudgeRight = 48;

  @override
  Widget build(BuildContext context) {
    final overlay = Overlay.of(context);
    return MenuAnchor(
      // Hang the menu under the ⋮: pull it left by (menu − trigger) to bring its
      // right edge flush with the dots, then nudge it back right a little.
      alignmentOffset:
          const Offset(-(_menuWidth - _triggerWidth) + _nudgeRight, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(6),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        // Pin the width so the offset above lines up exactly.
        minimumSize: const WidgetStatePropertyAll(Size(_menuWidth, 0)),
        maximumSize: const WidgetStatePropertyAll(Size(_menuWidth, double.infinity)),
      ),
      menuChildren: [
        if (item.vendorChanged)
          _MenuEntry(
            label: 'Set vendor as preferred vendor',
            onTap: () => _showPreferredVendorConfirm(overlay),
          ),
        _MenuEntry(label: 'Substitute', onTap: () => _showSubstitutePopover(overlay)),
        _MenuEntry(
          label: 'Cancel items',
          onTap: () => isCustomersView
              ? _showCancelItemsPopover(overlay)
              : _showCancelItemsSimplePopover(overlay),
        ),
        _MenuEntry(label: 'Item registration request', onTap: () => _showItemRegistrationPopover(overlay)),
      ],
      builder: (context, controller, _) => InkWell(
        onTap: () => controller.isOpen ? controller.close() : controller.open(),
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(LucideIcons.moreVertical, size: 14, color: AppTheme.textMuted),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preferred vendor confirmation popover
// ---------------------------------------------------------------------------

class _PreferredVendorPopover extends StatelessWidget {
  const _PreferredVendorPopover({
    required this.vendorName,
    required this.onConfirm,
    required this.onCancel,
  });

  final String vendorName;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dismiss barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: onCancel,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
          ),
          // Confirmation popover — pinned to top, centered
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 420,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header bar
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.store,
                              size: 16,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Set as Preferred Vendor',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: onCancel,
                            borderRadius: BorderRadius.circular(4),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Description
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(
                                  text: 'Are you sure you want to set ',
                                ),
                                TextSpan(
                                  text: vendorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      ' as the preferred vendor for this item? '
                                      'This will update the vendor preference.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Vendor name highlight card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(
                                    LucideIcons.store,
                                    size: 14,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Selected Vendor',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      vendorName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.primaryBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Action buttons
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: onConfirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 11),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                child: const Text('Yes, Set as Preferred'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: onCancel,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textBody,
                                  side: const BorderSide(color: AppTheme.borderColor),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22, vertical: 11),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6)),
                                  textStyle: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ],
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

// ---------------------------------------------------------------------------
// Substitute item popover
// ---------------------------------------------------------------------------

class _SubstitutePopover extends ConsumerStatefulWidget {
  const _SubstitutePopover({
    required this.originalItem,
    required this.onCancel,
    required this.onApply,
  });

  final String originalItem;
  final VoidCallback onCancel;

  /// Carries the whole [Item] — the substitution row needs its product id, not
  /// just the display name.
  final ValueChanged<Item?> onApply;

  @override
  ConsumerState<_SubstitutePopover> createState() => _SubstitutePopoverState();
}

class _SubstitutePopoverState extends ConsumerState<_SubstitutePopover> {
  Item? _substituteItem;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Dismiss barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onCancel,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
          // Popover — same position/size as _PreferredVendorPopover
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.successGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.arrowLeftRight,
                            size: 18,
                            color: AppTheme.successGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Substitute Item',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: widget.onCancel,
                          child: const Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Original item — read-only
                    const Text(
                      'ORIGINAL ITEM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight,
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.originalItem,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Substitute item dropdown
                    const Text(
                      'SUBSTITUTE ITEM',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Builder(builder: (context) {
                      final items = ref.watch(itemsControllerProvider).items;
                      return FormDropdown<Item>(
                        value: _substituteItem,
                        items: items,
                        hint: 'Select substitute product',
                        placeholder: 'Search products...',
                        menuMaxHeight: 260,
                        displayStringForValue: (item) =>
                            (item.billingName?.isNotEmpty == true)
                                ? item.billingName!
                                : item.productName,
                        searchStringForValue: (item) =>
                            '${item.productName} ${item.itemCode} ${item.sku ?? ''}',
                        onChanged: (v) => setState(() => _substituteItem = v),
                      );
                    }),
                    const SizedBox(height: 24),
                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textBody,
                            side: const BorderSide(color: AppTheme.borderColor),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => widget.onApply(_substituteItem),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Apply Substitution'),
                        ),
                      ],
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

// ---------------------------------------------------------------------------
// Item Registration Request popover
// ---------------------------------------------------------------------------

class _ItemRegistrationPopover extends ConsumerStatefulWidget {
  const _ItemRegistrationPopover({
    required this.itemName,
    required this.sourceDemandPoolId,
    required this.onCancel,
    required this.onSubmit,
  });

  final String itemName;

  /// The demand pool row the request was raised from — recorded on the product
  /// as `temp_source_id` so a temp product can be traced back to its origin.
  final String sourceDemandPoolId;

  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  ConsumerState<_ItemRegistrationPopover> createState() =>
      _ItemRegistrationPopoverState();
}

class _ItemRegistrationPopoverState
    extends ConsumerState<_ItemRegistrationPopover> {
  late final TextEditingController _nameCtrl;
  final _packSizeCtrl = TextEditingController();
  final _mrpCtrl      = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.itemName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _packSizeCtrl.dispose();
    _mrpCtrl.dispose();
    super.dispose();
  }

  /// Registers the requested item as a *temp* product: it becomes selectable
  /// straight away, while `is_temp_product` / `product_status` mark it as
  /// awaiting proper setup in Items.
  ///
  /// Pack size is collected but not stored — `products.unit_pack_id` is a FK to
  /// the pack size master and a bare number cannot identify a row there.
  Future<void> _submit() async {
    if (_isSaving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('products').insert({
        'product_name': name,
        'mrp': double.tryParse(_mrpCtrl.text.trim()),
        'is_temp_product': true,
        'product_status': 'TEMP',
        'temp_source_module': 'DEMAND_POOL',
        'temp_source_id': widget.sourceDemandPoolId.isEmpty
            ? null
            : widget.sourceDemandPoolId,
      });

      // Pull the new product into the item list so it is immediately selectable.
      await ref.read(itemsControllerProvider.notifier).loadItems();

      if (!mounted) return;
      widget.onSubmit();
    } catch (e) {
      AppLogger.error('Failed to register temp product',
          error: e, module: 'DemandPool');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Barrier
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onCancel,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
          // Popover
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 560,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 18, 16, 18),
                      child: Row(
                        children: [
                          const Text(
                            'Item Registration Request',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: widget.onCancel,
                            child: const Icon(LucideIcons.x, size: 16, color: AppTheme.errorRed),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Form body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          _IrrRow(
                            label: 'Name',
                            required: true,
                            child: CustomTextField(controller: _nameCtrl, hintText: ''),
                          ),
                          const SizedBox(height: 14),
                          // Pack Size
                          _IrrRow(
                            label: 'Pack Size',
                            required: true,
                            child: CustomTextField(
                              controller: _packSizeCtrl,
                              hintText: '',
                              keyboardType: const TextInputType.numberWithOptions(decimal: false),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            ),
                          ),
                          const SizedBox(height: 14),
                          // MRP
                          _IrrRow(
                            label: 'MRP',
                            child: CustomTextField(
                              controller: _mrpCtrl,
                              hintText: '',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Footer — buttons left-aligned
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isSaving ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: Text(_isSaving ? 'Submitting…' : 'Submit'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: widget.onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textBody,
                              side: const BorderSide(color: AppTheme.borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Cancel'),
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

// Label + input row used inside the registration form
class _IrrRow extends StatelessWidget {
  const _IrrRow({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 130,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: required ? AppTheme.errorRed : AppTheme.textSecondary,
                ),
              ),
              if (required)
                const Text(' *', style: TextStyle(fontSize: 13, color: AppTheme.errorRed)),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cancel Items — simple popover (Items group view)
// ---------------------------------------------------------------------------

class _CancelItemsSimplePopover extends StatefulWidget {
  const _CancelItemsSimplePopover({
    required this.item,
    required this.onCancel,
    required this.onConfirm,
  });

  final _DpItem item;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  State<_CancelItemsSimplePopover> createState() => _CancelItemsSimplePopoverState();
}

class _CancelItemsSimplePopoverState extends State<_CancelItemsSimplePopover> {
  static const TextStyle _colHeaderStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppTheme.textMuted,
    letterSpacing: 0.4,
  );
  static const TextStyle _valueStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppTheme.textBody,
  );

  final _cancelQtyCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _cancelQtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onCancel,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 1020,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title bar
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'CANCEL ITEMS',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onCancel,
                            child: const Icon(LucideIcons.x, size: 15, color: AppTheme.errorRed),
                          ),
                        ],
                      ),
                    ),
                    // Item subheading
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        border: Border(left: BorderSide(color: AppTheme.primaryBlue, width: 3)),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ITEM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.replacement ?? item.product,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Column headers
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: const [
                          SizedBox(width: 100, child: Text('SO NO',          style: _colHeaderStyle)),
                          Expanded(child: Text('CUSTOMER', style: _colHeaderStyle)),
                          SizedBox(width: 80, child: Text('ORDERED',        style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 80, child: Text('PICKED',         style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 80, child: Text('PACKED',         style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 80, child: Text('INVOICED',       style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 120, child: Text('PURCHASE ORDER', style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 80, child: Text('BILLS',          style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 72,  child: Text('REQUIRED',      style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 100, child: Text('CANCEL QTY',    style: _colHeaderStyle, textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Data row
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // SO No
                          SizedBox(
                            width: 100,
                            child: Text(
                              item.soNo.isNotEmpty ? item.soNo : '—',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                            ),
                          ),
                          // Customer from the linked sales order
                          Expanded(
                            child: Text(
                              item.customerLabel.isNotEmpty ? item.customerLabel : '—',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textBody),
                            ),
                          ),
                          SizedBox(width: 80, child: Text('${item.reqQty}',               style: _valueStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 80, child: Text('${item.reqQty - item.pendingQty}', style: _valueStyle, textAlign: TextAlign.center)),
                          const SizedBox(width: 80, child: Text('0',           style: _valueStyle, textAlign: TextAlign.center)),
                          const SizedBox(width: 80, child: Text('0',           style: _valueStyle, textAlign: TextAlign.center)),
                          const SizedBox(width: 120, child: Text('0',          style: _valueStyle, textAlign: TextAlign.center)),
                          const SizedBox(width: 80, child: Text('0',           style: _valueStyle, textAlign: TextAlign.center)),
                          SizedBox(
                            width: 72,
                            child: Text('${item.pendingQty}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textBody),
                                textAlign: TextAlign.center),
                          ),
                          // Cancel Qty input
                          SizedBox(
                            width: 100,
                            child: Center(
                              child: SizedBox(
                                width: 80,
                                child: CustomTextField(
                                  controller: _cancelQtyCtrl,
                                  hintText: '0',
                                  height: 32,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Footer
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: widget.onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textBody,
                              side: const BorderSide(color: AppTheme.borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: widget.onConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Confirm'),
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

// ---------------------------------------------------------------------------
// Cancel Items — advanced popover (Customers group view)
// ---------------------------------------------------------------------------

class _CancelItemsPopover extends StatefulWidget {
  const _CancelItemsPopover({
    required this.item,
    required this.onCancel,
    required this.onConfirm,
  });

  final _DpItem item;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  State<_CancelItemsPopover> createState() => _CancelItemsPopoverState();
}

class _CancelItemsPopoverState extends State<_CancelItemsPopover> {
  late final TextEditingController _cancelQtyCtrl;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _cancelQtyCtrl =
        TextEditingController(text: '${widget.item.reqQty}');
  }

  @override
  void dispose() {
    _cancelQtyCtrl.dispose();
    super.dispose();
  }

  static const TextStyle _colHeaderStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppTheme.textMuted,
    letterSpacing: 0.4,
  );
  static const TextStyle _valueStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppTheme.textBody,
  );

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onCancel,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.18)),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 1020,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  border: Border.all(color: AppTheme.borderColor),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'CANCEL ITEMS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onCancel,
                            child: const Icon(LucideIcons.x, size: 15, color: AppTheme.errorRed),
                          ),
                        ],
                      ),
                    ),
                    // Item subheading
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        border: Border(left: BorderSide(color: AppTheme.primaryBlue, width: 3)),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ITEM',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.replacement ?? item.product,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Column headers
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        children: const [
                          SizedBox(width: 100, child: Text('SO NO',          style: _colHeaderStyle)),
                          Expanded(child: Text('CUSTOMER', style: _colHeaderStyle)),
                          SizedBox(width: 80,  child: Text('ORDERED',        style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 80,  child: Text('PICKED',         style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 80,  child: Text('PACKED',         style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 80,  child: Text('INVOICED',       style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 120, child: Text('PURCHASE ORDER', style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 80,  child: Text('RECEIVE',        style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 80,  child: Text('BILLS',          style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 72,  child: Text('REQUIRED',       style: _colHeaderStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 100, child: Text('CANCEL QTY',     style: _colHeaderStyle, textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Data row
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // SO No
                          SizedBox(
                            width: 100,
                            child: Text(
                              item.soNo.isNotEmpty ? item.soNo : '—',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryBlue),
                            ),
                          ),
                          // Customer from the linked sales order
                          Expanded(
                            child: Text(
                              item.customerLabel.isNotEmpty ? item.customerLabel : '—',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textBody),
                            ),
                          ),
                          SizedBox(width: 80,  child: Text('${item.reqQty}',     style: _valueStyle, textAlign: TextAlign.center)),
                          SizedBox(width: 80,  child: Text('${item.reqQty - item.pendingQty}', style: _valueStyle, textAlign: TextAlign.center)),
                          const SizedBox(width: 80,  child: Text('0',            style: _valueStyle, textAlign: TextAlign.center)),
                          const SizedBox(width: 80,  child: Text('0',            style: _valueStyle, textAlign: TextAlign.center)),
                          const SizedBox(width: 120, child: Text('0',            style: _valueStyle, textAlign: TextAlign.center)),
                          const SizedBox(width: 80,  child: Text('—',            style: _valueStyle, textAlign: TextAlign.center)),
                          const SizedBox(width: 80,  child: Text('0',            style: _valueStyle, textAlign: TextAlign.center)),
                          SizedBox(
                            width: 72,
                            child: Text('${item.pendingQty}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textBody),
                                textAlign: TextAlign.center),
                          ),
                          SizedBox(
                            width: 100,
                            child: Center(
                              child: SizedBox(
                                width: 80,
                                child: CustomTextField(
                                  controller: _cancelQtyCtrl,
                                  hintText: '0',
                                  height: 32,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Note + warning checkbox
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              children: [
                                TextSpan(
                                  text: 'Note: ',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                ),
                                TextSpan(text: 'The drop shipped line items from the order will not be listed here.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: () => setState(() => _agreed = !_agreed),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _agreed,
                                    onChanged: (v) => setState(() => _agreed = v ?? false),
                                    activeColor: AppTheme.primaryBlue,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'I understand that the back ordered items will be dissociated from their respective purchase orders once they\'re cancelled.',
                                      style: TextStyle(fontSize: 12, color: AppTheme.textBody),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    // Footer
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: widget.onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textBody,
                              side: const BorderSide(color: AppTheme.borderColor),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: _agreed ? widget.onConfirm : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              disabledBackgroundColor: AppTheme.successGreen.withValues(alpha: 0.5),
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Proceed'),
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

class _DpStatusText extends StatelessWidget {
  const _DpStatusText(this.status);
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color textColor = switch (status) {
      'PR Created'       => AppTheme.infoBlue,
      'Partially Planned'=> AppTheme.warningOrange,
      'Ordered'          => AppTheme.primaryBlue,
      'Received'         => AppTheme.successGreen,
      'Substituted'      => AppTheme.infoTextDark,
      'Cancel'           => AppTheme.errorRed,
      _                  => AppTheme.textMuted,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: textColor.withValues(alpha: 0.25)),
          ),
          child: Text(
            status,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor),
          ),
        ),
      ],
    );
  }
}

class _MenuEntry extends StatefulWidget {
  const _MenuEntry({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_MenuEntry> createState() => _MenuEntryState();
}

class _MenuEntryState extends State<_MenuEntry> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color: _hovered ? Colors.white : AppTheme.textBody,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Field label wrapper
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.child,
    this.required = false,
    this.labelColor,
    this.hasSelection = false,
    this.onClear,
  });

  final String label;
  final Widget child;
  final bool required;
  final Color? labelColor;
  final bool hasSelection;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: labelColor ?? AppTheme.textSecondary,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(fontSize: 12, color: AppTheme.errorRed),
              ),
            if (hasSelection && onClear != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onClear,
                child: const Icon(LucideIcons.x, size: 12, color: AppTheme.errorRed),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
