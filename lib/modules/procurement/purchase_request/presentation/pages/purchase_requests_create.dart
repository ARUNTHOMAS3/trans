// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';

// ---------------------------------------------------------------------------
// Demand pool pre-fill payload
// ---------------------------------------------------------------------------

class DemandPoolLineItem {
  const DemandPoolLineItem({
    required this.productId,
    required this.productName,
    required this.entityId,
    required this.reqQty,
    required this.plannedQty,
    required this.pendingQty,
    this.vendorId,
    this.vendorName,
    this.demandPoolIds = const [],
  });
  final String productId;
  final String productName;
  final String entityId;
  final int reqQty;
  final int plannedQty;
  final int pendingQty;
  final String? vendorId;
  final String? vendorName;
  final List<String> demandPoolIds;
}

class DemandPoolPayload {
  const DemandPoolPayload({
    required this.lineItems,
    this.assigneeId,
    this.assigneeName,
    this.expectedDate,
  });
  final List<DemandPoolLineItem> lineItems;
  final String? assigneeId;
  final String? assigneeName;
  final DateTime? expectedDate;
}

// ---------------------------------------------------------------------------
// Line item model
// ---------------------------------------------------------------------------

class _LineItem {
  _LineItem()
      : itemNameCtrl = TextEditingController(),
        descCtrl = TextEditingController(),
        qtyCtrl = TextEditingController(text: '1.00'),
        planQtyCtrl = TextEditingController(text: '0.00'),
        pendingQtyCtrl = TextEditingController(text: '0.00'),
        rateCtrl = TextEditingController(text: '0.00'),
        discountCtrl = TextEditingController(text: '0.00');

  final TextEditingController itemNameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController qtyCtrl;
  final TextEditingController planQtyCtrl;
  final TextEditingController pendingQtyCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController discountCtrl;

  String? category;
  String? preferredVendor; // display name shown in the vendor dropdown
  String? productId;
  String? entityId;
  String? vendorId; // UUID used for DB saves
  bool vendorChanged = false; // true once user manually picks a vendor in this row
  List<String> substitutionChain = []; // original → replaced names, in order
  List<String> demandPoolIds = [];
  String currency = 'INR';
  bool discountIsPercent = true;

  // expand / reporting-tag state
  bool expanded = false;
  String? adgf;
  String? schedule;
  String? demoReportingTag;

  void dispose() {
    itemNameCtrl.dispose();
    descCtrl.dispose();
    qtyCtrl.dispose();
    planQtyCtrl.dispose();
    pendingQtyCtrl.dispose();
    rateCtrl.dispose();
    discountCtrl.dispose();
  }

  double get estimatedAmount {
    final qty = double.tryParse(qtyCtrl.text.replaceAll(',', '')) ?? 0;
    final rate = double.tryParse(rateCtrl.text.replaceAll(',', '')) ?? 0;
    final disc = double.tryParse(discountCtrl.text.replaceAll(',', '')) ?? 0;
    final subtotal = qty * rate;
    if (discountIsPercent) return subtotal - (subtotal * disc / 100);
    return subtotal - disc;
  }
}

class _DeliveryAddress {
  const _DeliveryAddress({
    required this.name,
    required this.street1,
    required this.street2,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    required this.phone,
  });

  final String name;
  final String street1;
  final String street2;
  final String city;
  final String state;
  final String zip;
  final String country;
  final String phone;
}

class _AssigneeOption {
  const _AssigneeOption({
    required this.id,
    required this.fullName,
    required this.email,
  });
  final String id;
  final String fullName;
  final String email;
  String get displayName => fullName.isNotEmpty ? fullName : email;
}

class _VendorOption {
  const _VendorOption({required this.id, required this.displayName});
  final String id;
  final String displayName;
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class ProcurementPurchaseRequestsCreatePage extends ConsumerStatefulWidget {
  const ProcurementPurchaseRequestsCreatePage({
    super.key,
    this.editId,
    this.fromDemandPool,
  });

  final String? editId;
  final DemandPoolPayload? fromDemandPool;

  @override
  ConsumerState<ProcurementPurchaseRequestsCreatePage> createState() =>
      _ProcurementPurchaseRequestsCreatePageState();
}

class _ProcurementPurchaseRequestsCreatePageState
    extends ConsumerState<ProcurementPurchaseRequestsCreatePage> {
  DateTime? _expectedDate;
  bool _expectedDateReadOnly = false;
  final _expectedDateKey = GlobalKey();
  final _expectedDateCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _internalNotesCtrl = TextEditingController();
  final _notesToApproverCtrl = TextEditingController();
  _AssigneeOption? _selectedAssignee;
  List<_AssigneeOption> _assignees = [];
  bool _assigneeReadOnly = false;

  bool _showDeliveryAddress = true;
  bool _allExpanded = false;
  bool _isSaving = false;
  String? _editPrUuid; // resolved UUID of the PR being edited (editId is the request_number)

  final _addressLayerLink = LayerLink();
  final _addressCardKey = GlobalKey();
  OverlayEntry? _addressOverlay;
  int _selectedAddressIdx = 0;
  final List<_DeliveryAddress> _addresses = [
    _DeliveryAddress(
      name: 'DEMO ADDRESS',
      street1: 'DEMO ST1',
      street2: 'DEMO ST2',
      city: 'TIRUR',
      state: 'Kerala',
      zip: '679322',
      country: 'India',
      phone: '08606259910',
    ),
  ];

  final List<_LineItem> _items = [];
  List<String> _categoryNames = [];
  List<_VendorOption> _vendorOptions = [];

  final _addRowLink = LayerLink();
  OverlayEntry? _addRowOverlay;
  OverlayEntry? _itemDetailsSidebarOverlay;
  final _pageScrollCtrl  = ScrollController();
  final _tableScrollCtrl = ScrollController();
  final _proxyScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) {
      _prefillForEdit(widget.editId!);
    } else if (widget.fromDemandPool != null &&
        widget.fromDemandPool!.lineItems.isNotEmpty) {
      _prefillFromDemandPool(widget.fromDemandPool!.lineItems);
      final payload = widget.fromDemandPool!;
      if (payload.expectedDate != null) {
        final d = payload.expectedDate!;
        _expectedDate = d;
        _expectedDateReadOnly = true;
        _expectedDateCtrl.text =
            '${d.day.toString().padLeft(2, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.year}';
      }
      if (payload.assigneeId != null && payload.assigneeName != null) {
        _selectedAssignee = _AssigneeOption(
          id: payload.assigneeId!,
          fullName: payload.assigneeName!,
          email: '',
        );
        _assigneeReadOnly = true;
      }
    } else {
      _items.add(_LineItem());
    }
    _loadUsers();
    _loadCategories();
    _loadVendors();
    _loadDemandPoolRates();
    _tableScrollCtrl.addListener(_onTableScroll);
    _proxyScrollCtrl.addListener(_onProxyScroll);
  }

  /// Batch-fetches cost_price for every pre-filled demand pool item and
  /// populates each row's Estimated Rate field so the amount auto-computes.
  Future<void> _loadDemandPoolRates() async {
    final productIds = _items
        .where((i) => i.productId != null)
        .map((i) => i.productId!)
        .toSet()
        .toList();
    if (productIds.isEmpty) return;

    try {
      final res = await Supabase.instance.client
          .from('products')
          .select('id, cost_price')
          .inFilter('id', productIds);

      if (!mounted) return;

      final priceMap = <String, double>{};
      for (final row in (res as List<dynamic>)) {
        final m = row as Map<String, dynamic>;
        final id = m['id'] as String?;
        final price = (m['cost_price'] as num?)?.toDouble() ?? 0;
        if (id != null) priceMap[id] = price;
      }

      setState(() {
        for (final item in _items) {
          if (item.productId != null) {
            final rate = priceMap[item.productId!] ?? 0;
            // Only overwrite if DB has a real cost price; preserve demo fallback otherwise
            if (rate > 0) {
              item.rateCtrl.text = rate.toStringAsFixed(2);
            }
          }
        }
      });
    } catch (e) {
      AppLogger.error('Failed to load product rates', error: e, module: 'PRCreate');
    }
  }

  Future<void> _loadUsers() async {
    try {
      final res = await Supabase.instance.client
          .from('users')
          .select('id, full_name, email')
          .eq('is_active', true)
          .order('full_name');
      if (!mounted) return;
      setState(() {
        _assignees = (res as List<dynamic>).map((row) {
          final m = row as Map<String, dynamic>;
          return _AssigneeOption(
            id: m['id'] as String? ?? '',
            fullName: m['full_name'] as String? ?? '',
            email: m['email'] as String? ?? '',
          );
        }).toList();
      });
    } catch (e) {
      AppLogger.error('Failed to load users', error: e, module: 'PRCreate');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final res = await Supabase.instance.client
          .from('categories')
          .select('name')
          .eq('is_active', true)
          .order('name');
      if (!mounted) return;
      setState(() {
        _categoryNames = (res as List<dynamic>)
            .map((row) => (row as Map<String, dynamic>)['name'] as String? ?? '')
            .where((n) => n.isNotEmpty)
            .toList();
      });
    } catch (e) {
      AppLogger.error('Failed to load categories', error: e, module: 'PRCreate');
    }
  }

  Future<void> _loadVendors() async {
    try {
      final res = await Supabase.instance.client
          .from('vendors')
          .select('id, display_name')
          .eq('is_active', true)
          .order('display_name');
      if (!mounted) return;
      setState(() {
        _vendorOptions = (res as List<dynamic>).map((row) {
          final m = row as Map<String, dynamic>;
          return _VendorOption(
            id: m['id'] as String? ?? '',
            displayName: m['display_name'] as String? ?? '',
          );
        }).where((v) => v.id.isNotEmpty && v.displayName.isNotEmpty).toList();
        _backfillVendorNames();
      });
    } catch (e) {
      AppLogger.error('Failed to load vendors', error: e, module: 'PRCreate');
    }
  }

  void _backfillVendorNames() {
    if (_vendorOptions.isEmpty) return;
    for (final item in _items) {
      if (item.vendorId != null && item.preferredVendor == null) {
        final match = _vendorOptions.where((v) => v.id == item.vendorId).firstOrNull;
        if (match != null) item.preferredVendor = match.displayName;
      }
    }
  }

  Future<void> _prefillForEdit(String requestNumber) async {
    try {
      final supabase = Supabase.instance.client;
      final fullNumber = requestNumber.startsWith('PR-')
          ? requestNumber
          : 'PR-$requestNumber';

      final prRes = await supabase
          .from('purchase_requests')
          .select('id, expected_date, assignee_id, users!assignee_id(full_name, email)')
          .eq('request_number', fullNumber)
          .maybeSingle();

      if (prRes == null || !mounted) return;
      final prId = prRes['id'] as String;
      _editPrUuid = prId;

      // Expected date (stored as YYYY-MM-DD)
      final rawDate = prRes['expected_date'] as String?;
      if (rawDate != null) {
        final parts = rawDate.split('-');
        if (parts.length == 3) {
          final d = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          _expectedDate = d;
          _expectedDateCtrl.text =
              '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }

      // Assignee
      final userMap = prRes['users'] as Map<String, dynamic>?;
      final assigneeId = prRes['assignee_id'] as String?;
      if (assigneeId != null && userMap != null) {
        _selectedAssignee = _AssigneeOption(
          id: assigneeId,
          fullName: userMap['full_name'] as String? ?? '',
          email: userMap['email'] as String? ?? '',
        );
      }

      // Line items — join vendors so display name is available immediately
      final itemsRes = await supabase
          .from('purchase_request_items')
          .select(
              'product_id, required_qty, planned_qty, pending_qty, '
              'estimated_rate, preferred_vendor_id, '
              'products(product_name), '
              'vendors!preferred_vendor_id(display_name)')
          .eq('purchase_request_id', prId);

      if (!mounted) return;
      setState(() {
        _items.clear();
        for (final row in itemsRes as List<dynamic>) {
          final m = row as Map<String, dynamic>;
          final product = m['products'] as Map<String, dynamic>?;
          final vendor  = m['vendors']  as Map<String, dynamic>?;
          final item = _LineItem()
            ..itemNameCtrl.text =
                product?['product_name'] as String? ?? ''
            ..qtyCtrl.text =
                ((m['required_qty'] as num?)?.toStringAsFixed(2)) ?? '0.00'
            ..planQtyCtrl.text =
                ((m['planned_qty'] as num?)?.toStringAsFixed(2)) ?? '0.00'
            ..pendingQtyCtrl.text =
                ((m['pending_qty'] as num?)?.toStringAsFixed(2)) ?? '0.00'
            ..rateCtrl.text =
                ((m['estimated_rate'] as num?)?.toStringAsFixed(2)) ?? '0.00'
            ..productId = m['product_id'] as String?
            ..vendorId = m['preferred_vendor_id'] as String?
            ..preferredVendor = vendor?['display_name'] as String?;
          _items.add(item);
        }
        if (_items.isEmpty) _items.add(_LineItem());
        // Race-condition guard: if _loadVendors() already ran, back-fill now
        _backfillVendorNames();
      });
    } catch (e) {
      AppLogger.error('Failed to load PR for edit', error: e, module: 'PRCreate');
      if (mounted) setState(() { if (_items.isEmpty) _items.add(_LineItem()); });
    }
  }

  // Fallback demo rates used when cost_price is 0 in the DB
  static const _kDemoRates = [120.00, 85.50, 200.00, 45.00, 150.00, 75.00, 95.00, 60.00];

  void _prefillFromDemandPool(List<DemandPoolLineItem> dpItems) {
    for (int idx = 0; idx < dpItems.length; idx++) {
      final dp = dpItems[idx];
      final item = _LineItem()
        ..itemNameCtrl.text = dp.productName
        ..qtyCtrl.text = dp.reqQty.toStringAsFixed(2)
        ..planQtyCtrl.text = dp.plannedQty.toStringAsFixed(2)
        ..pendingQtyCtrl.text = dp.pendingQty.toStringAsFixed(2)
        ..rateCtrl.text = _kDemoRates[idx % _kDemoRates.length].toStringAsFixed(2)
        ..productId = dp.productId
        ..entityId = dp.entityId
        ..vendorId = dp.vendorId
        ..preferredVendor = dp.vendorName
        ..demandPoolIds = List<String>.from(dp.demandPoolIds);
      _items.add(item);
    }
  }

  void _onTableScroll() {
    if (_proxyScrollCtrl.hasClients &&
        _proxyScrollCtrl.offset != _tableScrollCtrl.offset) {
      _proxyScrollCtrl.jumpTo(_tableScrollCtrl.offset);
    }
  }

  void _onProxyScroll() {
    if (_tableScrollCtrl.hasClients &&
        _tableScrollCtrl.offset != _proxyScrollCtrl.offset) {
      _tableScrollCtrl.jumpTo(_proxyScrollCtrl.offset);
    }
  }

  @override
  void dispose() {
    _addRowOverlay?.remove();
    _addRowOverlay = null;
    _itemDetailsSidebarOverlay?.remove();
    _itemDetailsSidebarOverlay = null;
    _addressOverlay?.remove();
    _addressOverlay = null;
    _pageScrollCtrl.dispose();
    _tableScrollCtrl.removeListener(_onTableScroll);
    _proxyScrollCtrl.removeListener(_onProxyScroll);
    _tableScrollCtrl.dispose();
    _proxyScrollCtrl.dispose();
    _expectedDateCtrl.dispose();
    _referenceCtrl.dispose();
    _reasonCtrl.dispose();
    _internalNotesCtrl.dispose();
    _notesToApproverCtrl.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _showItemDetailsSidebar(int index) {
    _closeItemDetailsSidebar();
    final item = _items[index];
    _itemDetailsSidebarOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          GestureDetector(
            onTap: _closeItemDetailsSidebar,
            child: Container(color: Colors.black.withValues(alpha: 0.25)),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Material(
              color: Colors.transparent,
              child: _ItemDetailsSidebar(
                item: item,
                onClose: _closeItemDetailsSidebar,
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_itemDetailsSidebarOverlay!);
  }

  void _closeItemDetailsSidebar() {
    _itemDetailsSidebarOverlay?.remove();
    _itemDetailsSidebarOverlay = null;
  }

  void _addRow() => setState(() => _items.add(_LineItem()));

  void _removeRow(int index) {
    if (_items.length <= 1) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPageHeader(),
          const Divider(height: 1, color: AppTheme.borderColor),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: Scrollbar(
                    controller: _pageScrollCtrl,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _pageScrollCtrl,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTopFields(),
                          const SizedBox(height: 24),
                          _buildTableToolbar(),
                          const SizedBox(height: 8),
                          _buildTable(),
                          const SizedBox(height: 12),
                          Align(alignment: Alignment.centerLeft, child: _buildAddRowButton()),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _FieldLabel(
                                  label: 'Notes to Approver',
                                  child: CustomTextField(
                                    controller: _notesToApproverCtrl,
                                    hintText: '',
                                    maxLines: 20,
                                    height: 120,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              const Expanded(child: SizedBox.shrink()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Divider(height: 1, color: AppTheme.borderColor),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Sticky horizontal scrollbar — always at viewport bottom ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 52, 4),
                  child: Scrollbar(
                    controller: _proxyScrollCtrl,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: SingleChildScrollView(
                      controller: _proxyScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(width: _kTotalTableWidth, height: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Page header
  // ---------------------------------------------------------------------------

  Widget _buildPageHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(
            widget.editId != null ? LucideIcons.pencil : LucideIcons.clipboardList,
            size: 20,
            color: AppTheme.textPrimary,
          ),
          const SizedBox(width: 10),
          Text(
            widget.editId != null
                ? 'Edit Purchase Request – ${widget.editId}'
                : 'New Purchase Request',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.procurementPurchaseRequests);
              }
            },
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
  // Header form fields — matches screenshot layout
  // ---------------------------------------------------------------------------

  Widget _buildTopFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row 1: Expected Date (left half)
        SizedBox(
          width: 420,
          child: _FieldLabel(
            label: 'Expected Date',
            required: true,
            child: _expectedDateReadOnly
                ? AbsorbPointer(
                    child: CustomTextField(
                      controller: _expectedDateCtrl,
                      hintText: 'eg: 31-01-2025',
                      fillColor: AppTheme.bgLight,
                      suffixWidget: const Icon(
                        LucideIcons.lock,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  )
                : GestureDetector(
                    key: _expectedDateKey,
                    onTap: () async {
                      final picked = await ZerpaiDatePicker.show(
                        context,
                        initialDate: _expectedDate ?? DateTime.now(),
                        targetKey: _expectedDateKey,
                      );
                      if (picked != null) {
                        setState(() {
                          _expectedDate = picked;
                          _expectedDateCtrl.text =
                              '${picked.day.toString().padLeft(2, '0')}-'
                              '${picked.month.toString().padLeft(2, '0')}-'
                              '${picked.year}';
                        });
                      }
                    },
                    child: AbsorbPointer(
                      child: CustomTextField(
                        controller: _expectedDateCtrl,
                        hintText: 'eg: 31-01-2025',
                        suffixWidget: const Icon(
                          Icons.calendar_today_outlined,
                          size: 15,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        // Row 2: Delivery Address (left half)
        _buildDeliveryAddress(),
        const SizedBox(height: 16),
        // Row 3: Reference# | Reason (two equal columns)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FieldLabel(
                label: 'Reference#',
                child: CustomTextField(
                  controller: _referenceCtrl,
                  hintText: '',
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _FieldLabel(
                label: 'Reason',
                child: CustomTextField(
                  controller: _reasonCtrl,
                  hintText: '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Row 4: Internal Notes | Assignee
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FieldLabel(
                label: 'Internal Notes',
                child: CustomTextField(
                  controller: _internalNotesCtrl,
                  hintText: 'Enter notes here...',
                  maxLines: 20,
                  height: 120,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _FieldLabel(
                label: 'Assignee',
                child: _assigneeReadOnly
                    ? Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgDisabled,
                          border: Border.all(color: AppTheme.borderColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _selectedAssignee?.displayName ?? '—',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textBody,
                          ),
                        ),
                      )
                    : FormDropdown<_AssigneeOption>(
                        value: _selectedAssignee,
                        items: _assignees,
                        hint: 'Select assignee',
                        height: 36,
                        displayStringForValue: (u) => u.displayName,
                        onChanged: (u) =>
                            setState(() => _selectedAssignee = u),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDeliveryAddress() {
    return SizedBox(
      width: 420,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Address',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (_showDeliveryAddress)
                GestureDetector(
                  onTap: () {
                    _hideAddressOverlay();
                    setState(() => _showDeliveryAddress = false);
                  },
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (_showDeliveryAddress)
            CompositedTransformTarget(
              link: _addressLayerLink,
              child: _AddressPickerCard(
                key: _addressCardKey,
                addr: _addresses[_selectedAddressIdx],
                onTap: () => _toggleAddressOverlay(context),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => setState(() => _showDeliveryAddress = true),
              icon: const Icon(LucideIcons.plus, size: 14),
              label: const Text('Add Delivery Address'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.successGreen,
                side: const BorderSide(color: AppTheme.successGreen),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
        ],
      ),
    );
  }

  void _toggleAddressOverlay(BuildContext context) {
    if (_addressOverlay != null) {
      _hideAddressOverlay();
      return;
    }
    final RenderBox box =
        _addressCardKey.currentContext!.findRenderObject()! as RenderBox;
    final cardHeight = box.size.height;

    _addressOverlay = OverlayEntry(
      builder: (_) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hideAddressOverlay,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _addressLayerLink,
            showWhenUnlinked: false,
            offset: Offset(0, cardHeight + 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: _AddressDropdownPanel(
                addresses: _addresses,
                selectedIdx: _selectedAddressIdx,
                onSelect: (i) {
                  setState(() => _selectedAddressIdx = i);
                  _hideAddressOverlay();
                },
                onAddNew: () {
                  _hideAddressOverlay();
                  _showNewAddressDialog(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_addressOverlay!);
    setState(() {});
  }

  void _hideAddressOverlay() {
    _addressOverlay?.remove();
    _addressOverlay = null;
    if (mounted) setState(() {});
  }

  void _showNewAddressDialog(BuildContext context) {
    showDialog<_DeliveryAddress>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _NewAddressDialog(
        onSave: (addr) {
          setState(() {
            _addresses.add(addr);
            _selectedAddressIdx = _addresses.length - 1;
            _showDeliveryAddress = true;
          });
        },
      ),
    );
  }

  // _buildMiddleFields removed — merged into _buildTopFields above

  // ---------------------------------------------------------------------------
  // Table toolbar
  // ---------------------------------------------------------------------------

  Widget _buildTableToolbar() {
    return Row(
      children: [
        _ToolbarAction(
          icon: LucideIcons.chevronsUpDown,
          label: _allExpanded ? 'Collapse all' : 'Expand all',
          color: AppTheme.infoBlue,
          onTap: () => setState(() {
            _allExpanded = !_allExpanded;
            for (final item in _items) {
              item.expanded = _allExpanded;
            }
          }),
        ),
        _dot(),
        _ToolbarAction(
          icon: LucideIcons.arrowUpDown,
          label: 'Change order',
          color: AppTheme.infoBlue,
          onTap: () {},
        ),
        _dot(),
        _ToolbarAction(
          icon: LucideIcons.edit,
          label: 'Bulk Update Line Items',
          color: AppTheme.infoBlue,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _dot() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Text('•', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
      );

  // ---------------------------------------------------------------------------
  // Table — horizontal-scroll grid matching CreditNote pattern
  // ---------------------------------------------------------------------------

  // Column width constants
  static const double _colNum        = 50;
  static const double _colItem       = 280;
  static const double _colCategory   = 140;
  static const double _colDesc       = 220;
  static const double _colVendor     = 150;
  static const double _colQty        = 130; // Required Qty
  static const double _colPlanQty    = 110; // Planned Qty
  static const double _colPendingQty = 110; // Pending Qty
  static const double _colRate       = 190;
  static const double _colDiscount   = 120;
  static const double _colAmount     = 220;
  // Row heights used to align external delete buttons with table rows
  static const double _kHeaderRowHeight = 37.0; // vertical:10 + ~17px text + vertical:10
  static const double _kBodyRowHeight   = 48.0; // vertical:8  + 32px content + vertical:8
  static const double _kSubRowHeight    = 44.0; // padding 6+8  + 30px content

// Total content width of the table — used to size the external scrollbar proxy.
  static const double _kTotalTableWidth =
      _colNum + _colItem + _colCategory + _colDesc + _colVendor +
      _colQty + _colPlanQty + _colPendingQty + _colRate + _colDiscount + _colAmount;

  Widget _buildTable() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Scrollable table ──
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.hardEdge,
                child: SingleChildScrollView(
                  controller: _tableScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTableHeader(),
                      Container(height: 1, color: AppTheme.borderColor),
                      ...List.generate(_items.length, (i) => _PrGridRow(
                        item: _items[i],
                        index: i,
                        showBottomBorder: i < _items.length - 1,
                        onRemove: () => _removeRow(i),
                        onChanged: () => setState(() {}),
                        onShowDetails: () => _showItemDetailsSidebar(i),
                        categories: _categoryNames,
                        vendors: _vendorOptions,
                      )),
                    ],
                  ),
                ),
              ),
            ),
            // ── Three-dots menu + X delete buttons — outside the table border ──
            SizedBox(
              width: 56,
              child: Column(
                children: [
                  const SizedBox(height: _kHeaderRowHeight + 1),
                  ...List.generate(_items.length, (i) => SizedBox(
                    height: _items[i].expanded
                        ? _kBodyRowHeight + _kSubRowHeight
                        : _kBodyRowHeight,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        height: _kBodyRowHeight,
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _PrRowMenu(
                                index: i,
                                item: _items[i],
                                onRemoveRow: () => setState(() => _removeRow(i)),
                                onChanged: () => setState(() {}),
                              ),
                              const SizedBox(width: 2),
                              _PrDeleteButton(onTap: () => _removeRow(i)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFF9FAFB),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GCell(width: _colNum,        label: '#'),
          _GCell(width: _colItem,       label: 'ITEM NAME',          required: true),
          _GCell(width: _colCategory,   label: 'CATEGORY',           required: true),
          _GCell(width: _colDesc,       label: 'DESCRIPTION'),
          _GCell(width: _colVendor,     label: 'PREFERRED VENDOR'),
          _GCell(width: _colQty,        label: 'REQUIRED QTY',       required: true),
          _GCell(width: _colPlanQty,    label: 'PLANNED QTY'),
          _GCell(width: _colPendingQty, label: 'PENDING QTY'),
          _GCell(width: _colRate,       label: 'ESTIMATED RATE',     required: true),
          _GCell(width: _colDiscount,   label: 'DISCOUNT'),
          _GCell(width: _colAmount,     label: 'ESTIMATED AMOUNT',   showDivider: false),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Add Row button
  // ---------------------------------------------------------------------------

  Widget _buildAddRowButton() {
    return CompositedTransformTarget(
      link: _addRowLink,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _addRow,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                bottomLeft: Radius.circular(4),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, size: 14, color: Color(0xFF2563EB)),
                    SizedBox(width: 6),
                    Text(
                      'Add New Row',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 1, height: 20, color: const Color(0xFFE5E7EB)),
            InkWell(
              onTap: _toggleAddRowOverlay,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF6B7280)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleAddRowOverlay() {
    if (_addRowOverlay != null) {
      _addRowOverlay?.remove();
      _addRowOverlay = null;
      setState(() {});
      return;
    }

    _addRowOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _addRowOverlay?.remove();
                _addRowOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _addRowLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 36),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: InkWell(
                  onTap: () {
                    _addRowOverlay?.remove();
                    _addRowOverlay = null;
                    setState(() {});
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: double.infinity,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Add New Header',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_addRowOverlay!);
    setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  String? _toIsoDate(String ddMMyyyy) {
    final parts = ddMMyyyy.split('-');
    if (parts.length != 3) return null;
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  Future<void> _savePurchaseRequest({String status = 'OPEN'}) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      final supabase = Supabase.instance.client;

      // Auto-generate request_number (PR-00001 … PR-99999)
      final countRes = await supabase
          .from('purchase_requests')
          .select('request_number')
          .order('created_at', ascending: false)
          .limit(1);
      int nextNum = 1;
      if ((countRes as List<dynamic>).isNotEmpty) {
        final last = countRes.first['request_number'] as String? ?? '';
        final m = RegExp(r'(\d+)$').firstMatch(last);
        if (m != null) nextNum = int.parse(m.group(1)!) + 1;
      }
      final requestNumber = 'PR-${nextNum.toString().padLeft(5, '0')}';

      // Entity id from pre-filled demand pool items (or fallback)
      final entityItem = _items.firstWhere(
        (i) => i.entityId != null,
        orElse: () => _items.first,
      );
      final entityId = entityItem.entityId ?? '66d79887-be98-40ab-ac40-9e0a008f9d8a';

      // Insert purchase_requests header
      final prRes = await supabase
          .from('purchase_requests')
          .insert({
            'entity_id': entityId,
            'request_number': requestNumber,
            'status': status,
            if (_expectedDateCtrl.text.isNotEmpty)
              'expected_date': _toIsoDate(_expectedDateCtrl.text),
            if (_selectedAssignee != null)
              'assignee_id': _selectedAssignee!.id,
          })
          .select('id')
          .single();
      final prId = prRes['id'] as String;

      // Insert purchase_request_items for every line that has a product_id
      final itemInserts = _items
          .where((i) => i.productId != null)
          .map((i) => {
                'purchase_request_id': prId,
                'product_id': i.productId!,
                if (i.vendorId != null) 'preferred_vendor_id': i.vendorId,
                'required_qty':
                    double.tryParse(i.qtyCtrl.text.replaceAll(',', '')) ?? 0,
                'planned_qty':
                    double.tryParse(i.planQtyCtrl.text.replaceAll(',', '')) ?? 0,
                'pending_qty': double.tryParse(
                        i.pendingQtyCtrl.text.replaceAll(',', '')) ??
                    0,
                'estimated_rate':
                    double.tryParse(i.rateCtrl.text.replaceAll(',', '')) ?? 0,
                'estimated_amount': i.estimatedAmount,
                'line_status': 'PENDING',
              })
          .toList();

      if (itemInserts.isNotEmpty) {
        await supabase.from('purchase_request_items').insert(itemInserts);
      }

      // Push the on-screen pending_qty into demand_pool as the new required_qty.
      // pending_qty = 0 → FULFILLED (removed from pool); > 0 → PR_CREATED (stays in pool).
      final allDpIds = _items.expand((i) => i.demandPoolIds).toSet().toList();

      // Shared helper: distributes each item's screen pending_qty across its
      // demand_pool rows proportionally (by their current required_qty weight).
      Future<void> _syncRows(
        List<dynamic> dpRows, {
        required Map<String, double> pendingByProduct,
        bool linkPrId = false,
      }) async {
        final byProduct = <String, List<Map<String, dynamic>>>{};
        for (final r in dpRows) {
          final pid = (r as Map<String, dynamic>)['product_id'] as String? ?? '';
          (byProduct[pid] ??= []).add(r);
        }

        final futures = <Future>[];
        for (final entry in byProduct.entries) {
          final rows         = entry.value;
          final totalPending = pendingByProduct[entry.key] ?? 0;
          final totalWeight  = rows.fold<double>(
            0, (s, r) => s + (((r['required_qty'] as num?)?.toDouble()) ?? 0),
          );

          for (final r in rows) {
            final id        = r['id'] as String;
            final rowWeight = ((r['required_qty'] as num?)?.toDouble()) ?? 0;
            final share     = totalWeight > 0 ? rowWeight / totalWeight : 1.0;
            final rowPending = (totalPending * share).clamp(0.0, double.infinity);

            futures.add(
              supabase.from('demand_pool').update({
                if (linkPrId) 'purchase_request_id': prId,
                'required_qty': rowPending,
                'planned_qty':  0,
                'pending_qty':  rowPending,
                'status': rowPending <= 0 ? 'FULFILLED' : 'PR_CREATED',
              }).eq('id', id),
            );
          }
        }
        if (futures.isNotEmpty) await Future.wait(futures);
      }

      // Use pendingQtyCtrl (what's shown on screen) as the source of truth.
      final pendingByProduct = <String, double>{
        for (final item in _items)
          if (item.productId != null)
            item.productId!:
                double.tryParse(item.pendingQtyCtrl.text.replaceAll(',', '')) ?? 0,
      };

      if (allDpIds.isNotEmpty) {
        final dpRows = await supabase
            .from('demand_pool')
            .select('id, product_id, required_qty')
            .inFilter('id', allDpIds);
        await _syncRows(dpRows as List<dynamic>,
            pendingByProduct: pendingByProduct, linkPrId: true);

      } else if (_editPrUuid != null) {
        final dpRows = await supabase
            .from('demand_pool')
            .select('id, product_id, required_qty')
            .eq('purchase_request_id', _editPrUuid!);
        await _syncRows(dpRows as List<dynamic>,
            pendingByProduct: pendingByProduct);
      }

      // Create approval record when sent for approval
      if (status == 'PENDING_APPROVAL') {
        await supabase.from('purchase_request_approval').insert({
          'entity_id': entityId,
          'purchase_request_id': prId,
          'status': 'PENDING',
        });
      }

      if (!mounted) return;
      final orgSystemId =
          GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
      context.goNamed(
        AppRoutes.procurementPurchaseRequests,
        pathParameters: {'orgSystemId': orgSystemId},
      );
    } catch (e) {
      AppLogger.error('Failed to save purchase request', error: e, module: 'PRCreate');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Footer
  // ---------------------------------------------------------------------------

  Widget _buildFooter() {
    final btnPadding =
        const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    final btnRadius = BorderRadius.circular(6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Primary: save + submit for approval
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () => _savePurchaseRequest(status: 'PENDING_APPROVAL'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successGreen,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.successGreen.withOpacity(0.6),
              padding: btnPadding,
              elevation: 0,
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: btnRadius),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save & Send to Approve'),
          ),
          const SizedBox(width: 10),
          // Secondary: save as draft
          OutlinedButton(
            onPressed: _isSaving
                ? null
                : () => _savePurchaseRequest(status: 'DRAFT'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlue,
              side: const BorderSide(color: AppTheme.primaryBlue),
              padding: btnPadding,
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(borderRadius: btnRadius),
            ),
            child: const Text('Draft & Update'),
          ),
          const SizedBox(width: 10),
          // Cancel
          OutlinedButton(
            onPressed: _isSaving ? null : () => context.pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textBody,
              side: const BorderSide(color: AppTheme.borderColor),
              padding: btnPadding,
              textStyle:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              shape: RoundedRectangleBorder(borderRadius: btnRadius),
            ),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grid row
// ---------------------------------------------------------------------------

class _PrGridRow extends ConsumerStatefulWidget {
  const _PrGridRow({
    required this.item,
    required this.index,
    required this.onRemove,
    required this.onChanged,
    required this.onShowDetails,
    required this.categories,
    required this.vendors,
    this.showBottomBorder = false,
  });

  final _LineItem item;
  final int index;
  final VoidCallback onRemove;
  final VoidCallback onChanged;
  final VoidCallback onShowDetails;
  final List<String> categories;
  final List<_VendorOption> vendors;
  final bool showBottomBorder;

  @override
  ConsumerState<_PrGridRow> createState() => _PrGridRowState();
}

class _PrGridRowState extends ConsumerState<_PrGridRow> {
  // Which column is currently active (input visible). Updated on cell enter.
  // Only cleared when the physical pointer leaves the entire row — NOT when
  // a dropdown overlay captures the pointer, so dropdowns stay open.
  String? _hoveredCol;
  bool _rateCurrencyHovered = false;

  static const _kItem       = 'item';
  static const _kCat        = 'cat';
  static const _kDesc       = 'desc';
  static const _kVendor     = 'vendor';
  static const _kQty        = 'qty';
  static const _kPlanQty    = 'planqty';
  static const _kPendingQty = 'pendingqty';
  static const _kRate       = 'rate';
  static const _kDiscount   = 'disc';

  static const Map<String, String> _currencyNames = {
    'AED': 'UAE Dirham',
    'AUD': 'Australian Dollar',
    'BDT': 'Bangladeshi Taka',
    'BHD': 'Bahraini Dinar',
    'BND': 'Brunei Dollar',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'CNY': 'Yuan Renminbi',
    'EUR': 'Euro',
    'GBP': 'Pound Sterling',
    'HKD': 'Hong Kong Dollar',
    'IDR': 'Indonesian Rupiah',
    'INR': 'Indian Rupee',
    'JPY': 'Japanese Yen',
    'KWD': 'Kuwaiti Dinar',
    'LKR': 'Sri Lankan Rupee',
    'MYR': 'Malaysian Ringgit',
    'NPR': 'Nepalese Rupee',
    'NZD': 'New Zealand Dollar',
    'OMR': 'Omani Rial',
    'PHP': 'Philippine Peso',
    'PKR': 'Pakistani Rupee',
    'QAR': 'Qatari Riyal',
    'SAR': 'Saudi Riyal',
    'SGD': 'Singapore Dollar',
    'THB': 'Thai Baht',
    'USD': 'US Dollar',
    'VND': 'Vietnamese Dong',
    'ZAR': 'South African Rand',
  };
  static List<String> get _currencies =>
      _currencyNames.keys.toList()..sort();

  bool _is(String col) => _hoveredCol == col;

  // Wraps a cell widget so entering it sets the active column key.
  // Also restores _rowHovered so the delete button reappears if the pointer
  // returns to the row from a dropdown overlay.
  Widget _col(String key, Widget cell) => MouseRegion(
        onEnter: (_) => setState(() => _hoveredCol = key),
        child: cell,
      );

  Widget _cellText(String value) => SizedBox(
        height: 32,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: AppTheme.textBody),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );

  // Keeps the FormDropdown widget mounted at all times so its OverlayEntry
  // can close itself even when _hoveredCol changes (e.g. mouse enters the
  // overlay barrier). Without this, the overlay orphans and freezes the page.
  Widget _dropdownCell({
    required String key,
    required String displayText,
    required Widget input,
  }) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0;
      return SizedBox(
        width: w,
        height: 32,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Visibility(
              visible: _is(key),
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: input,
            ),
            if (!_is(key))
              Align(
                alignment: Alignment.centerLeft,
                child: _cellText(displayText),
              ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final mainRow = MouseRegion(
      onExit: (_) => setState(() {}),
      child: Container(
        color: Colors.white,
        // showBottomBorder is handled by the outer wrapper Column container
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // # — chevron toggle + row number
            MouseRegion(
              onEnter: (_) => setState(() => _hoveredCol = null),
              child: _GCell(
                width: _ProcurementPurchaseRequestsCreatePageState._colNum,
                isHeader: false,
                child: GestureDetector(
                  onTap: () {
                    setState(() => widget.item.expanded = !widget.item.expanded);
                    widget.onChanged();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.expanded
                            ? LucideIcons.chevronDown
                            : LucideIcons.chevronRight,
                        size: 11,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${widget.index + 1}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ITEM NAME
            _col(_kItem, _GCell(
              width: _ProcurementPurchaseRequestsCreatePageState._colItem,
              isHeader: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onShowDetails,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 26, height: 26,
                        decoration: BoxDecoration(
                          color: AppTheme.bgDisabled,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: const Icon(LucideIcons.image, size: 13, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: item.itemNameCtrl.text.isEmpty
                        ? FormDropdown<Item>(
                            value: null,
                            items: ref.watch(itemsControllerProvider).items,
                            hint: 'Type or select item',
                            height: 32,
                            hideBorderDefault: true,
                            displayStringForValue: (p) => p.productName,
                            searchStringForValue: (p) =>
                                '${p.productName} ${p.sku ?? ''} ${p.itemCode}',
                            itemBuilder: (product, isSelected, isHovered) {
                              final active = isSelected || isHovered;
                              return Container(
                                color: active
                                    ? AppTheme.primaryBlue
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      product.productName,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: active
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    if (product.sku != null &&
                                        product.sku!.isNotEmpty)
                                      Text(
                                        'SKU: ${product.sku}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: active
                                              ? Colors.white70
                                              : AppTheme.textMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                            onChanged: (product) {
                              if (product != null) {
                                setState(() {
                                  item.itemNameCtrl.text = product.productName;
                                  if (product.salesDescription != null &&
                                      product.salesDescription!.isNotEmpty) {
                                    item.descCtrl.text =
                                        product.salesDescription!;
                                  }
                                  final cost = product.costPrice ?? 0.0;
                                  if (cost > 0) {
                                    item.rateCtrl.text =
                                        cost.toStringAsFixed(2);
                                  }
                                });
                                widget.onChanged();
                              }
                            },
                          )
                        : _PrProductCell(
                            product: item.substitutionChain.isNotEmpty
                                ? item.substitutionChain.first
                                : item.itemNameCtrl.text,
                            substitutionChain: item.substitutionChain.length > 1
                                ? item.substitutionChain.sublist(1)
                                : const [],
                          ),
                  ),
                ],
              ),
            )),

            // CATEGORY
            _col(_kCat, _GCell(
              width: _ProcurementPurchaseRequestsCreatePageState._colCategory,
              isHeader: false,
              child: _dropdownCell(
                key: _kCat,
                displayText: item.category ?? '',
                input: FormDropdown<String>(
                  value: item.category,
                  items: widget.categories,
                  hint: 'Select',
                  height: 32,
                  menuWidth: 280,
                  displayStringForValue: (v) => v,
                  onChanged: (v) { setState(() => item.category = v); widget.onChanged(); },
                ),
              ),
            )),

            // DESCRIPTION
            _col(_kDesc, _GCell(
              width: _ProcurementPurchaseRequestsCreatePageState._colDesc,
              isHeader: false,
              child: _is(_kDesc)
                  ? CustomTextField(
                      controller: item.descCtrl,
                      hintText: '',
                      height: 32,
                    )
                  : _cellText(item.descCtrl.text),
            )),

            // PREFERRED VENDOR
            _col(_kVendor, _GCell(
              width: _ProcurementPurchaseRequestsCreatePageState._colVendor,
              isHeader: false,
              child: _dropdownCell(
                key: _kVendor,
                displayText: item.preferredVendor ?? '',
                input: FormDropdown<String>(
                  value: item.preferredVendor,
                  items: widget.vendors.map((v) => v.displayName).toList(),
                  hint: 'Select',
                  height: 32,
                  menuWidth: 300,
                  displayStringForValue: (v) => v,
                  onChanged: (name) {
                    if (name == null) return;
                    final match = widget.vendors
                        .where((v) => v.displayName == name)
                        .firstOrNull;
                    _showVendorChangePopover(
                      vendorName: name,
                      onConfirm: () {
                        setState(() {
                          item.preferredVendor = name;
                          item.vendorId = match?.id;
                          item.vendorChanged = true;
                        });
                        widget.onChanged();
                      },
                    );
                  },
                ),
              ),
            )),

            // REQUIRED QTY — read-only
            _col(_kQty, _GCell(
              width: _ProcurementPurchaseRequestsCreatePageState._colQty,
              isHeader: false,
              child: _cellText(item.qtyCtrl.text),
            )),

            // PLANNED QTY
            _col(_kPlanQty, _GCell(
              width: _ProcurementPurchaseRequestsCreatePageState._colPlanQty,
              isHeader: false,
              child: _is(_kPlanQty)
                  ? CustomTextField(
                      controller: item.planQtyCtrl,
                      hintText: '0.00',
                      height: 32,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      onChanged: (_) {
                        final required = double.tryParse(item.qtyCtrl.text.replaceAll(',', '')) ?? 0;
                        final planned  = double.tryParse(item.planQtyCtrl.text.replaceAll(',', '')) ?? 0;
                        final pending  = (required - planned).clamp(0.0, double.infinity);
                        item.pendingQtyCtrl.text = pending.toStringAsFixed(2);
                        widget.onChanged();
                      },
                    )
                  : _cellText(item.planQtyCtrl.text),
            )),

            // PENDING QTY — auto-computed: required - planned
            _col(_kPendingQty, _GCell(
              width: _ProcurementPurchaseRequestsCreatePageState._colPendingQty,
              isHeader: false,
              child: _cellText(item.pendingQtyCtrl.text),
            )),

            // ESTIMATED RATE — always shows split currency + rate inputs.
            _col(_kRate, _GCell(
              width: _ProcurementPurchaseRequestsCreatePageState._colRate,
              isHeader: false,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(4),
                ),
                clipBehavior: Clip.hardEdge,
                child: Row(
                  children: [
                    MouseRegion(
                      onEnter: (_) => setState(() => _rateCurrencyHovered = true),
                      onExit: (_) => setState(() => _rateCurrencyHovered = false),
                      child: SizedBox(
                        width: 75,
                        child: FormDropdown<String>(
                          value: item.currency,
                          items: _currencies,
                          hint: 'INR',
                          height: 32,
                          showRightBorder: true,
                          isHovered: _rateCurrencyHovered,
                          menuWidth:
                              _ProcurementPurchaseRequestsCreatePageState
                                  ._colRate,
                          borderRadius: BorderRadius.zero,
                          displayStringForValue: (v) => v,
                          searchStringForValue: (v) =>
                              '$v ${_currencyNames[v] ?? ''}',
                          itemBuilder: (code, isSelected, isHovered) {
                            final active = isSelected || isHovered;
                            return Container(
                              color: active
                                  ? AppTheme.primaryBlue
                                  : Colors.transparent,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              child: Text(
                                '$code- ${_currencyNames[code] ?? code}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: active
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              ),
                            );
                          },
                          onChanged: (v) {
                            setState(() => item.currency = v ?? 'INR');
                            widget.onChanged();
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomTextField(
                        controller: item.rateCtrl,
                        hintText: '0.00',
                        height: 32,
                        hideBorderDefault: true,
                        borderRadius: BorderRadius.zero,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        onChanged: (_) {
                          setState(() {});
                          widget.onChanged();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )),

            // DISCOUNT
            _col(_kDiscount, _GCell(
              width: _ProcurementPurchaseRequestsCreatePageState._colDiscount,
              isHeader: false,
              child: _is(_kDiscount)
                  ? Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: item.discountCtrl,
                            hintText: '0.00',
                            height: 32,
                            hideBorderDefault: true,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              bottomLeft: Radius.circular(4),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            onChanged: (_) {
                              setState(() {});
                              widget.onChanged();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 48,
                          child: FormDropdown<String>(
                            value: item.discountIsPercent ? '%' : '₹',
                            items: const ['%', '₹'],
                            height: 32,
                            showSearch: false,
                            showRightBorder: true,
                            menuWidth: 56,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(4),
                              bottomRight: Radius.circular(4),
                            ),
                            displayStringForValue: (v) => v,
                            itemBuilder: (symbol, isSelected, isHovered) {
                              final active = isSelected || isHovered;
                              return Container(
                                color: active
                                    ? AppTheme.primaryBlue
                                    : Colors.transparent,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Icon(
                                  symbol == '%'
                                      ? LucideIcons.percent
                                      : LucideIcons.indianRupee,
                                  size: 15,
                                  color: active
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
                              );
                            },
                            onChanged: (v) {
                              if (v != null) {
                                setState(() =>
                                    item.discountIsPercent = v == '%');
                                widget.onChanged();
                              }
                            },
                          ),
                        ),
                      ],
                    )
                  : _cellText(
                      '${item.discountCtrl.text} ${item.discountIsPercent ? '%' : '₹'}'),
            )),

            // ESTIMATED AMOUNT — always plain text; entering resets active column
            MouseRegion(
              onEnter: (_) => setState(() => _hoveredCol = null),
              child: _GCell(
                width: _ProcurementPurchaseRequestsCreatePageState._colAmount,
                isHeader: false,
                showDivider: false,
                cellColor: const Color(0xFFF9FAFB),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('₹', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    const SizedBox(width: 2),
                    Text(
                      item.estimatedAmount.toStringAsFixed(2),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.textBody),
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: widget.showBottomBorder
            ? const Border(bottom: BorderSide(color: AppTheme.borderColor))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mainRow,
          if (item.expanded) _buildSubRow(item),
        ],
      ),
    );
  }

  Widget _buildSubRow(_LineItem item) {
    const colNum  = _ProcurementPurchaseRequestsCreatePageState._colNum;
    return Container(
      color: Colors.white,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Spacer that exactly matches the # column width → content starts
          // directly under the ITEM NAME column.
          const SizedBox(width: colNum),
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8, right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SubDropdown(
                  label: 'ADGF',
                  value: item.adgf,
                  onChanged: (v) { setState(() => item.adgf = v); widget.onChanged(); },
                ),
                const SizedBox(width: 24),
                _SubDropdown(
                  label: 'SCHEDULE',
                  value: item.schedule,
                  onChanged: (v) { setState(() => item.schedule = v); widget.onChanged(); },
                ),
                const SizedBox(width: 24),
                _SubDropdown(
                  label: 'DEMO ADVANCED REPORTING TAG',
                  value: item.demoReportingTag,
                  onChanged: (v) { setState(() => item.demoReportingTag = v); widget.onChanged(); },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVendorChangePopover({
    required String vendorName,
    required VoidCallback onConfirm,
  }) {
    late OverlayEntry entry;
    var dismissed = false;
    void dismiss() {
      if (dismissed) return;
      dismissed = true;
      entry.remove();
    }
    entry = OverlayEntry(
      builder: (_) => _PrVendorChangePopover(
        vendorName: vendorName,
        onConfirm: () { dismiss(); onConfirm(); },
        onCancel: dismiss,
      ),
    );
    Overlay.of(context).insert(entry);
  }

}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.child,
    this.required = false,
  });

  final String label;
  final Widget child;
  final bool required;

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
                color: required ? AppTheme.errorRed : AppTheme.textSecondary,
              ),
            ),
            if (required)
              const Text(
                ' *',
                style: TextStyle(fontSize: 12, color: AppTheme.errorRed),
              ),
          ],
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _PrRowMenu — three-dots (⋮) context menu per table row
// ---------------------------------------------------------------------------

class _PrRowMenu extends StatelessWidget {
  const _PrRowMenu({
    required this.index,
    required this.item,
    required this.onRemoveRow,
    required this.onChanged,
  });

  final int index;
  final _LineItem item;
  final VoidCallback onRemoveRow;
  final VoidCallback onChanged;

  void _openSubstituteOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    var _dismissed = false;
    void dismiss() {
      if (_dismissed) return;
      _dismissed = true;
      entry.remove();
    }
    entry = OverlayEntry(
      builder: (_) => _PrSubstitutePopover(
        originalItem: item.itemNameCtrl.text,
        onCancel: dismiss,
        onApply: (substitute) {
          if (substitute != null && substitute.isNotEmpty) {
            final prev = item.substitutionChain.isEmpty
                ? item.itemNameCtrl.text
                : item.substitutionChain.last;
            if (item.substitutionChain.isEmpty) {
              item.substitutionChain.add(item.itemNameCtrl.text);
            }
            if (prev != substitute) item.substitutionChain.add(substitute);
            item.itemNameCtrl.text = substitute;
            item.productId = null;
            onChanged();
          }
          dismiss();
        },
      ),
    );
    overlay.insert(entry);
  }

  void _openCancelItemOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    var _dismissed = false;
    void dismiss() {
      if (_dismissed) return;
      _dismissed = true;
      entry.remove();
    }
    entry = OverlayEntry(
      builder: (_) => _PrCancelItemPopover(
        itemName: item.itemNameCtrl.text,
        onCancel: dismiss,
        onConfirm: () {
          dismiss();
          onRemoveRow();
        },
      ),
    );
    overlay.insert(entry);
  }

  void _openItemRegistrationOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    var _dismissed = false;
    void dismiss() {
      if (_dismissed) return;
      _dismissed = true;
      entry.remove();
    }
    entry = OverlayEntry(
      builder: (_) => _PrItemRegistrationPopover(
        itemName: item.itemNameCtrl.text,
        onCancel: dismiss,
        onSubmit: dismiss,
      ),
    );
    overlay.insert(entry);
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-220, 0),
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
        minimumSize: const WidgetStatePropertyAll(Size(220, 0)),
        maximumSize: const WidgetStatePropertyAll(Size(260, double.infinity)),
      ),
      menuChildren: [
        if (item.vendorChanged)
          _PrMenuEntry(label: 'Set vendor as preferred vendor', onTap: () {}),
        _PrMenuEntry(label: 'Substitute', onTap: () => _openSubstituteOverlay(context)),
        _PrMenuEntry(label: 'Cancel items', onTap: () => _openCancelItemOverlay(context)),
        _PrMenuEntry(label: 'Item registration request', onTap: () => _openItemRegistrationOverlay(context)),
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

class _PrMenuEntry extends StatefulWidget {
  const _PrMenuEntry({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_PrMenuEntry> createState() => _PrMenuEntryState();
}

class _PrMenuEntryState extends State<_PrMenuEntry> {
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
// _PrDeleteButton — X button rendered outside the table border
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// _SubDropdown — inline label + borderless dropdown for expanded sub-row
// ---------------------------------------------------------------------------

class _SubDropdown extends StatelessWidget {
  const _SubDropdown({
    required this.label,
    this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 100,
          child: FormDropdown<String>(
            value: value,
            items: const [],
            hint: 'None',
            height: 28,
            hideBorderDefault: true,
            displayStringForValue: (v) => v,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _PrDeleteButton extends StatefulWidget {
  const _PrDeleteButton({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_PrDeleteButton> createState() => _PrDeleteButtonState();
}

class _PrDeleteButtonState extends State<_PrDeleteButton> {
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
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.errorRed.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            LucideIcons.x,
            size: 14,
            color: AppTheme.errorRed,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GCell — reusable grid cell (header + body)
// ---------------------------------------------------------------------------

class _GCell extends StatelessWidget {
  const _GCell({
    required this.width,
    this.label,
    this.required = false,
    this.child,
    this.isHeader = true,
    bool? showDivider,
    this.cellColor,
  }) : showDivider = showDivider ?? true;

  final double width;
  final String? label;
  final bool required;
  final Widget? child;
  final bool isHeader;
  final bool showDivider;
  final Color? cellColor;

  @override
  Widget build(BuildContext context) {
    final bg = cellColor ?? (isHeader ? const Color(0xFFF9FAFB) : Colors.transparent);
    final content = isHeader
        ? Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label ?? ''),
                if (required) const TextSpan(text: ' *'),
              ],
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: required ? AppTheme.errorRed : AppTheme.textMuted,
              ),
            ),
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          )
        : child ?? const SizedBox.shrink();

    // Use right-border on the cell itself so divider always matches cell height
    return Container(
      width: width,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: bg,
        border: showDivider
            ? const Border(
                right: BorderSide(color: AppTheme.borderColor, width: 1),
              )
            : null,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: isHeader ? 10 : 8,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: content,
      ),
    );
  }
}


class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: c,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Address picker card (hover → blue border) ────────────────────────────────

class _AddressPickerCard extends StatefulWidget {
  const _AddressPickerCard({super.key, required this.addr, required this.onTap});
  final _DeliveryAddress addr;
  final VoidCallback onTap;

  @override
  State<_AddressPickerCard> createState() => _AddressPickerCardState();
}

class _AddressPickerCardState extends State<_AddressPickerCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.addr;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered ? AppTheme.primaryBlue : AppTheme.borderColor,
              width: _hovered ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                a.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (a.street1.isNotEmpty) _AddressLine(a.street1),
              if (a.street2.isNotEmpty) _AddressLine(a.street2),
              if (a.city.isNotEmpty || a.state.isNotEmpty)
                _AddressLine('${a.city} , ${a.state}'),
              if (a.country.isNotEmpty || a.zip.isNotEmpty)
                _AddressLine('${a.country} , ${a.zip}'),
              if (a.phone.isNotEmpty) _AddressLine(a.phone),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Address dropdown overlay panel ───────────────────────────────────────────

class _AddressDropdownPanel extends StatefulWidget {
  const _AddressDropdownPanel({
    required this.addresses,
    required this.selectedIdx,
    required this.onSelect,
    required this.onAddNew,
  });
  final List<_DeliveryAddress> addresses;
  final int selectedIdx;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddNew;

  @override
  State<_AddressDropdownPanel> createState() => _AddressDropdownPanelState();
}

class _AddressDropdownPanelState extends State<_AddressDropdownPanel> {
  int? _hovered;
  bool _addNewHovered = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Address list
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: widget.addresses.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFFE5E7EB)),
                itemBuilder: (_, i) {
                  final a = widget.addresses[i];
                  final isSelected = i == widget.selectedIdx;
                  final isHovered = _hovered == i;

                  final bg = isSelected
                      ? AppTheme.primaryBlue
                      : isHovered
                          ? const Color(0xFFF1F5F9)
                          : Colors.white;
                  final nameColor =
                      isSelected ? Colors.white : AppTheme.textPrimary;
                  final lineColor = isSelected
                      ? Colors.white.withValues(alpha: 0.85)
                      : AppTheme.textBody;

                  return MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _hovered = i),
                    onExit: (_) => setState(() => _hovered = null),
                    child: GestureDetector(
                      onTap: () => widget.onSelect(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 100),
                        color: bg,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: nameColor,
                              ),
                            ),
                            if (a.street1.isNotEmpty)
                              _DropdownAddressLine(a.street1, lineColor),
                            if (a.street2.isNotEmpty)
                              _DropdownAddressLine(a.street2, lineColor),
                            if (a.city.isNotEmpty || a.state.isNotEmpty)
                              _DropdownAddressLine(
                                  '${a.city} , ${a.state}', lineColor),
                            if (a.country.isNotEmpty || a.zip.isNotEmpty)
                              _DropdownAddressLine(
                                  '${a.country} , ${a.zip}', lineColor),
                            if (a.phone.isNotEmpty)
                              _DropdownAddressLine(a.phone, lineColor),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            // Add New Address button
            MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _addNewHovered = true),
              onExit: (_) => setState(() => _addNewHovered = false),
              child: GestureDetector(
                onTap: widget.onAddNew,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  color: _addNewHovered
                      ? const Color(0xFFF1F5F9)
                      : Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.plus,
                          size: 15, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      const Text(
                        'Add New Address',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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

class _DropdownAddressLine extends StatelessWidget {
  const _DropdownAddressLine(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(text,
          style: TextStyle(fontSize: 12, color: color)),
    );
  }
}

// ── New Address dialog ────────────────────────────────────────────────────────

class _NewAddressDialog extends StatefulWidget {
  const _NewAddressDialog({required this.onSave});
  final ValueChanged<_DeliveryAddress> onSave;

  @override
  State<_NewAddressDialog> createState() => _NewAddressDialogState();
}

class _NewAddressDialogState extends State<_NewAddressDialog> {
  final _attentionCtrl = TextEditingController();
  final _street1Ctrl   = TextEditingController();
  final _street2Ctrl   = TextEditingController();
  final _cityCtrl      = TextEditingController();
  final _stateCtrl     = TextEditingController();
  final _zipCtrl       = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  String? _country;

  static const _kCountries = [
    'India', 'United States', 'United Kingdom',
    'UAE', 'Singapore', 'Canada', 'Australia',
  ];

  @override
  void dispose() {
    _attentionCtrl.dispose();
    _street1Ctrl.dispose();
    _street2Ctrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 13, color: AppTheme.textMuted),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppTheme.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
        ),
        filled: false,
      );

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: required ? Colors.red : AppTheme.textSecondary,
            ),
          ),
          if (required)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                children: [
                  const Text(
                    'New Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.x,
                          size: 18, color: AppTheme.errorRed),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Attention
              _label('Attention'),
              TextField(
                controller: _attentionCtrl,
                decoration: _dec(''),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Street 1
              _label('Street 1'),
              TextField(
                controller: _street1Ctrl,
                maxLines: 3,
                decoration: _dec('').copyWith(contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              // Street 2
              _label('Street 2'),
              TextField(
                controller: _street2Ctrl,
                maxLines: 3,
                decoration: _dec('').copyWith(contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 16),
              // City + State
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('City'),
                        TextField(
                          controller: _cityCtrl,
                          decoration: _dec(''),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('State'),
                        TextField(
                          controller: _stateCtrl,
                          decoration: _dec(''),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // ZIP + Country
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('ZIP Code'),
                        TextField(
                          controller: _zipCtrl,
                          decoration: _dec(''),
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Country', required: true),
                        FormDropdown<String>(
                          value: _country,
                          items: _kCountries,
                          hint: 'Select',
                          height: 36,
                          displayStringForValue: (v) => v,
                          onChanged: (v) =>
                              setState(() => _country = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Phone
              _label('Phone'),
              TextField(
                controller: _phoneCtrl,
                decoration: _dec(''),
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 24),
              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: _country == null ? null : () {
                      widget.onSave(_DeliveryAddress(
                        name: _attentionCtrl.text.trim().isEmpty
                            ? 'New Address'
                            : _attentionCtrl.text.trim(),
                        street1: _street1Ctrl.text.trim(),
                        street2: _street2Ctrl.text.trim(),
                        city: _cityCtrl.text.trim(),
                        state: _stateCtrl.text.trim(),
                        zip: _zipCtrl.text.trim(),
                        country: _country!,
                        phone: _phoneCtrl.text.trim(),
                      ));
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGreen,
                      disabledBackgroundColor: AppTheme.successGreen,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textBody,
                      side: const BorderSide(color: AppTheme.borderColor),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Address line (used in main card) ─────────────────────────────────────────

class _AddressLine extends StatelessWidget {
  const _AddressLine(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: AppTheme.textBody),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item Details Sidebar
// ---------------------------------------------------------------------------

class _ItemDetailsSidebar extends StatefulWidget {
  const _ItemDetailsSidebar({
    required this.item,
    required this.onClose,
  });

  final _LineItem item;
  final VoidCallback onClose;

  @override
  State<_ItemDetailsSidebar> createState() => _ItemDetailsSidebarState();
}

class _ItemDetailsSidebarState extends State<_ItemDetailsSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  int _activeTab = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleClose() {
    _controller.reverse().then((_) => widget.onClose());
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(left: BorderSide(color: Color(0xFFE5E7EB))),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              child: Row(
                children: [
                  const Text(
                    'Item Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _handleClose,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),

            // Item info card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Icon(
                        LucideIcons.image,
                        color: Color(0xFF9CA3AF),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Inventory Item',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.item.itemNameCtrl.text.isEmpty
                                ? 'No item selected'
                                : widget.item.itemNameCtrl.text,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.item.category != null
                                ? 'Category: ${widget.item.category}'
                                : 'No category assigned',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTab('ITEM DETAILS', 0),
                  const SizedBox(width: 24),
                  _buildTab('STOCK INFO', 1),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),

            // Tab body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _activeTab == 0 ? _buildItemDetailsTab() : _buildStockInfoTab(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppTheme.primaryBlue : AppTheme.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildItemDetailsTab() {
    final item = widget.item;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Category', item.category ?? '—'),
        _row('Preferred Vendor', item.preferredVendor ?? '—'),
        _row('Description', item.descCtrl.text.isEmpty ? '—' : item.descCtrl.text),
        const Divider(height: 28, color: AppTheme.borderColor),
        _row('Required Qty', item.qtyCtrl.text),
        _row('Planned Qty', item.planQtyCtrl.text),
        _row('Pending Qty', item.pendingQtyCtrl.text),
        const Divider(height: 28, color: AppTheme.borderColor),
        _row('Currency', item.currency),
        _row(
          'Estimated Rate',
          item.rateCtrl.text.isEmpty ? '—' : '${item.currency} ${item.rateCtrl.text}',
        ),
        _row(
          'Discount',
          (item.discountCtrl.text.isEmpty || item.discountCtrl.text == '0.00')
              ? '—'
              : '${item.discountCtrl.text} ${item.discountIsPercent ? '%' : item.currency}',
        ),
        const Divider(height: 28, color: AppTheme.borderColor),
        _rowHighlighted('Estimated Amount', '₹${_fmt(item.estimatedAmount)}'),
      ],
    );
  }

  Widget _buildStockInfoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('Stock on Hand', '—'),
        _row('Committed Stock', '—'),
        _row('Available for Sale', '—'),
        _row('Reorder Point', '—'),
        const Divider(height: 28, color: AppTheme.borderColor),
        _row('Last Purchase Price', '—'),
        _row('Average Cost', '—'),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowHighlighted(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 155,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v == 0) return '0.00';
    final parts = v.toStringAsFixed(2).split('.');
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
}

// ---------------------------------------------------------------------------
// _PrSubstitutePopover — same as demand pool substitute, but self-contained
// ---------------------------------------------------------------------------

class _PrSubstitutePopover extends ConsumerStatefulWidget {
  const _PrSubstitutePopover({
    required this.originalItem,
    required this.onCancel,
    required this.onApply,
  });

  final String originalItem;
  final VoidCallback onCancel;
  final ValueChanged<String?> onApply;

  @override
  ConsumerState<_PrSubstitutePopover> createState() =>
      _PrSubstitutePopoverState();
}

class _PrSubstitutePopoverState extends ConsumerState<_PrSubstitutePopover> {
  Item? _substituteItem;

  @override
  Widget build(BuildContext context) {
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
                          child: const Icon(LucideIcons.x,
                              size: 16, color: AppTheme.errorRed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgLight,
                        border: Border.all(color: AppTheme.borderColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.originalItem,
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: widget.onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textBody,
                            side: const BorderSide(color: AppTheme.borderColor),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () => widget.onApply(
                            _substituteItem == null
                                ? null
                                : (_substituteItem!.billingName?.isNotEmpty ==
                                        true
                                    ? _substituteItem!.billingName!
                                    : _substituteItem!.productName),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.successGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
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
// _PrCancelItemPopover — confirm before removing a row from the PR
// ---------------------------------------------------------------------------

class _PrCancelItemPopover extends StatelessWidget {
  const _PrCancelItemPopover({
    required this.itemName,
    required this.onCancel,
    required this.onConfirm,
  });

  final String itemName;
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
              onTap: onCancel,
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
                width: 380,
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
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.xCircle,
                              size: 18, color: AppTheme.errorRed),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Cancel Item',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onCancel,
                          child: const Icon(LucideIcons.x,
                              size: 16, color: AppTheme.errorRed),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Remove "$itemName" from this purchase request?',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: onCancel,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textBody,
                            side: const BorderSide(color: AppTheme.borderColor),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Keep'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: onConfirm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Remove'),
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
// _PrItemRegistrationPopover — request to add a new product to the catalog
// ---------------------------------------------------------------------------

class _PrItemRegistrationPopover extends StatefulWidget {
  const _PrItemRegistrationPopover({
    required this.itemName,
    required this.onCancel,
    required this.onSubmit,
  });

  final String itemName;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  State<_PrItemRegistrationPopover> createState() =>
      _PrItemRegistrationPopoverState();
}

class _PrItemRegistrationPopoverState
    extends State<_PrItemRegistrationPopover> {
  late final TextEditingController _nameCtrl;
  final _packSizeCtrl = TextEditingController();
  final _mrpCtrl = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
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
                            child: const Icon(LucideIcons.x,
                                size: 16, color: AppTheme.errorRed),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PrFormRow(
                            label: 'Name',
                            required: true,
                            child: CustomTextField(
                                controller: _nameCtrl, hintText: ''),
                          ),
                          const SizedBox(height: 14),
                          _PrFormRow(
                            label: 'Pack Size',
                            required: true,
                            child: CustomTextField(
                              controller: _packSizeCtrl,
                              hintText: '',
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: false),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _PrFormRow(
                            label: 'MRP',
                            child: CustomTextField(
                              controller: _mrpCtrl,
                              hintText: '',
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'))
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: widget.onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Submit'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: widget.onCancel,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textBody,
                              side:
                                  const BorderSide(color: AppTheme.borderColor),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
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

// ---------------------------------------------------------------------------
// _PrProductCell — mirrors demand pool's _ProductCell for substitution display
// ---------------------------------------------------------------------------

class _PrProductCell extends StatelessWidget {
  const _PrProductCell({
    required this.product,
    this.substitutionChain = const [],
  });

  final String product;
  final List<String> substitutionChain;

  @override
  Widget build(BuildContext context) {
    const fontSize = 13.0;

    if (substitutionChain.isEmpty) {
      return Text(
        product,
        style: const TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: AppTheme.textBody,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }

    const arcWidth = 11.0;
    const halfLineH = fontSize * 0.72;
    const itemGap = 2.0;

    final allItems = [product, ...substitutionChain];
    final arcFrom = allItems[allItems.length - 2];
    final arcTo = allItems[allItems.length - 1];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: arcWidth,
            child: CustomPaint(
                painter: _PrLeftArcArrowPainter(halfLineH: halfLineH)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: 0.4,
                  child: Text(
                    arcFrom,
                    style: const TextStyle(
                      fontSize: fontSize,
                      color: AppTheme.textBody,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppTheme.textBody,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: itemGap),
                Text(
                  arcTo,
                  style: const TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrLeftArcArrowPainter extends CustomPainter {
  const _PrLeftArcArrowPainter({required this.halfLineH});
  final double halfLineH;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryBlue
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final startY = halfLineH;
    final endY = size.height - halfLineH;

    final path = Path()
      ..moveTo(size.width, startY)
      ..cubicTo(
        -size.width * 0.8, startY,
        -size.width * 0.8, endY,
        size.width, endY,
      );
    canvas.drawPath(path, paint);

    const ah = 3.0;
    canvas.drawLine(
        Offset(size.width, endY), Offset(size.width - ah, endY - ah), paint);
    canvas.drawLine(
        Offset(size.width, endY), Offset(size.width - ah, endY + ah), paint);
  }

  @override
  bool shouldRepaint(_PrLeftArcArrowPainter old) =>
      old.halfLineH != halfLineH;
}

// ---------------------------------------------------------------------------
// _PrFormRow — label + input row for registration form
// ---------------------------------------------------------------------------

class _PrFormRow extends StatelessWidget {
  const _PrFormRow({
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
                const Text(' *',
                    style: TextStyle(fontSize: 13, color: AppTheme.errorRed)),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Vendor change confirmation popover
// ---------------------------------------------------------------------------

class _PrVendorChangePopover extends StatelessWidget {
  const _PrVendorChangePopover({
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
          Positioned.fill(
            child: GestureDetector(
              onTap: onCancel,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withValues(alpha: 0.35)),
            ),
          ),
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
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(LucideIcons.store, size: 16, color: AppTheme.successGreen),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Set as Preferred Vendor',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                              children: [
                                const TextSpan(text: 'Are you sure you want to set '),
                                TextSpan(
                                  text: vendorName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                ),
                                const TextSpan(text: ' as the preferred vendor for this item? This will update the vendor preference.'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.store, size: 15, color: AppTheme.successGreen),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    vendorName,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: onConfirm,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.successGreen,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                                child: const Text('Yes, Set as Preferred'),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: onCancel,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textBody,
                                  side: const BorderSide(color: AppTheme.borderColor),
                                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
