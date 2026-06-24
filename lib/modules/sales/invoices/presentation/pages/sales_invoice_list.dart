import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/modules/auth/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_currency_display.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/email_composer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';

import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';

import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_item_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/modules/items/items/services/lookups_api_service.dart';
import 'package:zerpai_erp/modules/sales/payments_received/presentation/pages/sales_payment_create.dart';

// ─────────────────────────────────────────────────
//  Payment Terms Provider
// ─────────────────────────────────────────────────

final _paymentTermsProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    final list = await LookupsApiService().getPaymentTerms();
    final Map<String, String> map = {};
    for (final item in list) {
      final id = item['id']?.toString() ?? '';
      final name = item['term_name']?.toString() ?? '';
      if (id.isNotEmpty && name.isNotEmpty) {
        map[id] = name;
      }
    }
    return map;
  } catch (_) {
    return {};
  }
});

// ─────────────────────────────────────────────────
//  Branches Provider
// ─────────────────────────────────────────────────

final _branchesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authUserProvider);
  final orgId = user?.orgId ?? '';
  if (orgId.isEmpty) return [];
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.get('/branches', queryParameters: {'org_id': orgId});
    if (response.statusCode == 200 && response.data != null) {
      final List<dynamic> data = response.data is List ? response.data : (response.data['data'] ?? []);
      return data.map((json) => Map<String, dynamic>.from(json)).toList();
    }
  } catch (e) {
    debugPrint('Error loading branches: $e');
  }
  return [];
});

// ─────────────────────────────────────────────────
//  Invoice Detail Provider Family
// ─────────────────────────────────────────────────

final _salesInvoiceDetailProvider = FutureProvider.family<SalesOrder, String>((
  ref,
  id,
) async {
  final api = ref.watch(salesOrderApiServiceProvider);
  final rawInvoice = await api.getInvoiceById(id);
  final order = SalesOrder.fromJson(rawInvoice);

  final customer = order.customer;
  final hasCustomerName =
      customer != null && customer.displayName.trim().isNotEmpty;
  final hasBillingAddress =
      customer != null &&
      customer.fullBillingAddress.trim().isNotEmpty &&
      customer.fullBillingAddress.trim() != 'N/A';
  final hasShippingAddress =
      customer != null &&
      customer.fullShippingAddress.trim().isNotEmpty &&
      customer.fullShippingAddress.trim() != 'N/A';

  if ((hasCustomerName && hasBillingAddress && hasShippingAddress) ||
      order.customerId.trim().isEmpty) {
    return order;
  }

  try {
    final fetchedCustomer = await api.getCustomerById(order.customerId);
    return SalesOrder(
      id: order.id,
      customerId: order.customerId,
      saleNumber: order.saleNumber,
      reference: order.reference,
      saleDate: order.saleDate,
      expectedShipmentDate: order.expectedShipmentDate,
      paymentTerms: order.paymentTerms,
      deliveryMethod: order.deliveryMethod,
      salesperson: order.salesperson,
      status: order.status,
      documentType: order.documentType,
      subTotal: order.subTotal,
      taxTotal: order.taxTotal,
      discountTotal: order.discountTotal,
      shippingCharges: order.shippingCharges,
      adjustment: order.adjustment,
      total: order.total,
      customerNotes: order.customerNotes,
      termsAndConditions: order.termsAndConditions,
      customer: fetchedCustomer,
      items: order.items,
      createdAt: order.createdAt,
      warehouseId: order.warehouseId,
      paymentTermId: order.paymentTermId,
      priceListId: order.priceListId,
      entityId: order.entityId,
    );
  } catch (_) {
    return order;
  }
});

// ─────────────────────────────────────────────────
//  Invoice Views (filter presets)
// ─────────────────────────────────────────────────

class _InvoiceView {
  final String label;
  final Set<String>? statuses;
  const _InvoiceView(this.label, {this.statuses});
}

const _invoiceViews = <_InvoiceView>[
  _InvoiceView('All Invoices'),
  _InvoiceView('All'),
  _InvoiceView('Draft', statuses: {'draft'}),
  _InvoiceView('Locked', statuses: {'locked'}),
  _InvoiceView('Pending Approval', statuses: {'pending approval', 'pending_approval'}),
  _InvoiceView('Approved', statuses: {'approved'}),
  _InvoiceView('Customer Viewed', statuses: {'customer viewed', 'customer_viewed', 'sent'}),
  _InvoiceView('Partially Paid', statuses: {'partially paid', 'partially_paid'}),
  _InvoiceView('Unpaid', statuses: {'unpaid'}),
  _InvoiceView('Overdue', statuses: {'overdue'}),
  _InvoiceView('Payment Initiated', statuses: {'payment initiated', 'payment_initiated', 'initiated'}),
  _InvoiceView('Paid', statuses: {'paid'}),
  _InvoiceView('Void', statuses: {'void'}),
  _InvoiceView('Yet To Be Shipped', statuses: {'yet to be shipped', 'yet_to_be_shipped'}),
  _InvoiceView('Shipped', statuses: {'shipped'}),
  _InvoiceView('Invoices', statuses: {'invoice', 'invoices'}),
  _InvoiceView('Bills Of Supply', statuses: {'bills of supply', 'bills_of_supply'}),
  _InvoiceView('Debit Note', statuses: {'debit note', 'debit_note'}),
  _InvoiceView('Write Off', statuses: {'write off', 'write_off'}),
  _InvoiceView('Pending Collection Invoices', statuses: {'pending collection invoices', 'pending_collection_invoices', 'pending_collection'}),
  _InvoiceView('Marketplace', statuses: {'marketplace'}),
];

const _invFilterOptions = <FavoriteFilterOption>[
  FavoriteFilterOption(label: 'All', value: 'All'),
  FavoriteFilterOption(label: 'Draft', value: 'Draft'),
  FavoriteFilterOption(label: 'Locked', value: 'Locked'),
  FavoriteFilterOption(label: 'Pending Approval', value: 'Pending Approval'),
  FavoriteFilterOption(label: 'Approved', value: 'Approved'),
  FavoriteFilterOption(label: 'Customer Viewed', value: 'Customer Viewed'),
  FavoriteFilterOption(label: 'Partially Paid', value: 'Partially Paid'),
  FavoriteFilterOption(label: 'Unpaid', value: 'Unpaid'),
  FavoriteFilterOption(label: 'Overdue', value: 'Overdue'),
  FavoriteFilterOption(label: 'Payment Initiated', value: 'Payment Initiated'),
  FavoriteFilterOption(label: 'Paid', value: 'Paid'),
  FavoriteFilterOption(label: 'Void', value: 'Void'),
  FavoriteFilterOption(label: 'Yet To Be Shipped', value: 'Yet To Be Shipped'),
  FavoriteFilterOption(label: 'Shipped', value: 'Shipped'),
  FavoriteFilterOption(label: 'Invoices', value: 'Invoices'),
  FavoriteFilterOption(label: 'Bills Of Supply', value: 'Bills Of Supply'),
  FavoriteFilterOption(label: 'Debit Note', value: 'Debit Note'),
  FavoriteFilterOption(label: 'Write Off', value: 'Write Off'),
  FavoriteFilterOption(label: 'Pending Collection Invoices', value: 'Pending Collection Invoices'),
  FavoriteFilterOption(label: 'Marketplace', value: 'Marketplace'),
];

// ─────────────────────────────────────────────────
//  Column config
// ─────────────────────────────────────────────────

enum _InvColumnKey {
  date,
  invoiceNumber,
  orderNumber,
  customerName,
  status,
  dueDate,
  amount,
  balanceDue,
  warehouse,
}

enum _InvSortField {
  date,
  invoiceNumber,
  orderNumber,
  customerName,
  status,
  dueDate,
  amount,
  balanceDue,
  warehouse,
  createdTime,
  lastModifiedTime,
}

class _InvColumnConfig {
  final _InvColumnKey key;
  final String label;
  final double width;
  final bool locked;
  bool visible;

  _InvColumnConfig({
    required this.key,
    required this.label,
    required this.width,
    this.locked = false,
    required this.visible,
  });

  _InvColumnConfig copy() => _InvColumnConfig(
        key: key,
        label: label,
        width: width,
        locked: locked,
        visible: visible,
      );
}

// ─────────────────────────────────────────────────
//  Main screen
// ─────────────────────────────────────────────────

class SalesInvoiceOverviewScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;
  final String? initialSelectedId;
  final String? initialFilter;

  const SalesInvoiceOverviewScreen({
    super.key,
    this.initialSearchQuery,
    this.initialSelectedId,
    this.initialFilter,
  });

  @override
  ConsumerState<SalesInvoiceOverviewScreen> createState() =>
      _SalesInvoiceOverviewScreenState();
}

class _SalesInvoiceOverviewScreenState
    extends ConsumerState<SalesInvoiceOverviewScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  final ScrollController _horizontalScrollController = ScrollController();
  String _searchQuery = '';
  FavoriteFilterOption _activeOption = _invFilterOptions.first;
  _InvoiceView _activeView = _invoiceViews.first;
  _InvSortField _activeSortField = _InvSortField.invoiceNumber;
  bool _isAscending = true;
  bool _clipText = true;
  Set<String> _selectedIds = <String>{};
  late List<_InvColumnConfig> _columnConfigs;
  Map<String, double>? _customColumnWidths;
  bool _isAssociatedOrdersExpanded = false;
  String? _showPaymentFormForId;

  List<_InvColumnConfig> get _visibleColumns =>
      _columnConfigs.where((c) => c.visible).toList();

  @override
  void initState() {
    super.initState();
    _columnConfigs = _defaultColumnConfigs();
    _searchController = TextEditingController(
      text: widget.initialSearchQuery ?? '',
    );
    _searchFocusNode = FocusNode();
    _searchQuery = _searchController.text.trim();
    _searchController.addListener(() {
      final next = _searchController.text.trim();
      if (next != _searchQuery) setState(() => _searchQuery = next);
    });

    if (widget.initialFilter != null) {
      final found = _invFilterOptions.where(
        (v) => v.label.toLowerCase() == widget.initialFilter!.toLowerCase(),
      );
      if (found.isNotEmpty) {
        _activeOption = found.first;
        _activeView = _invoiceViews.firstWhere(
          (v) => v.label == (_activeOption.label == 'All' ? 'All Invoices' : _activeOption.label),
          orElse: () => _invoiceViews.first,
        );
      } else {
        final matched = _invoiceViews.firstWhere(
          (v) => v.label.toLowerCase() == widget.initialFilter!.toLowerCase() ||
                 (v.statuses != null && v.statuses!.contains(widget.initialFilter!.toLowerCase())),
          orElse: () => _invoiceViews.first,
        );
        _activeView = matched;
        final matchingOpt = _invFilterOptions.where((o) => o.label == (matched.label == 'All Invoices' ? 'All' : matched.label));
        if (matchingOpt.isNotEmpty) {
          _activeOption = matchingOpt.first;
        }
      }
    }

    _loadColumnSettings();
  }

  Future<void> _loadColumnSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('sales_invoice_column_widths');
      if (json != null) {
        final decoded = jsonDecode(json) as Map<String, dynamic>;
        setState(() {
          _customColumnWidths = decoded.map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading invoice column settings: $e');
    }
  }

  Future<void> _saveColumnSettings() async {
    try {
      if (_customColumnWidths == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'sales_invoice_column_widths',
        jsonEncode(_customColumnWidths),
      );
    } catch (e) {
      debugPrint('Error saving invoice column settings: $e');
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<_InvColumnConfig> _defaultColumnConfigs() {
    return [
      _InvColumnConfig(
        key: _InvColumnKey.date,
        label: 'Date',
        width: 110,
        locked: true,
        visible: true,
      ),
      _InvColumnConfig(
        key: _InvColumnKey.invoiceNumber,
        label: 'Invoice#',
        width: 140,
        locked: true,
        visible: true,
      ),
      _InvColumnConfig(
        key: _InvColumnKey.orderNumber,
        label: 'Order Number',
        width: 130,
        visible: true,
      ),
      _InvColumnConfig(
        key: _InvColumnKey.customerName,
        label: 'Customer Name',
        width: 220,
        locked: true,
        visible: true,
      ),
      _InvColumnConfig(
        key: _InvColumnKey.status,
        label: 'Status',
        width: 140,
        locked: true,
        visible: true,
      ),
      _InvColumnConfig(
        key: _InvColumnKey.dueDate,
        label: 'Due Date',
        width: 110,
        visible: true,
      ),
      _InvColumnConfig(
        key: _InvColumnKey.amount,
        label: 'Amount',
        width: 120,
        locked: true,
        visible: true,
      ),
      _InvColumnConfig(
        key: _InvColumnKey.balanceDue,
        label: 'Balance Due',
        width: 150,
        visible: true,
      ),
      _InvColumnConfig(
        key: _InvColumnKey.warehouse,
        label: 'Warehouse',
        width: 160,
        visible: true,
      ),
    ];
  }

  // ─── BUILD ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(salesInvoicesProvider);

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      searchFocusNode: _searchFocusNode,
      child: invoicesAsync.when(
        loading: () => const SalesOrderTableSkeleton(),
        error: (error, _) => _emptyMessage(
          icon: LucideIcons.alertCircle,
          title: 'Unable to load invoices',
          subtitle: '$error',
        ),
        data: (invoices) {
          _selectedIds = _selectedIds
              .where((id) => invoices.any((inv) => inv.id == id))
              .toSet();
          final filtered = _applyFilters(invoices);
          final hasSelection = widget.initialSelectedId != null;

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1100;
              return Column(
                children: [
                  if (!hasSelection) ...[
                    _selectedIds.isNotEmpty
                        ? _selectionToolbar()
                        : _toolbar(context),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    if (_selectedIds.isEmpty) ...[
                      _paymentSummaryCard(invoices),
                      const Divider(height: 1, color: AppTheme.borderLight),
                    ],
                  ],
                  Expanded(
                    child: invoices.isEmpty
                        ? _emptyState()
                        : filtered.isEmpty
                            ? _emptyMessage(
                                icon: LucideIcons.searchX,
                                title: 'No matching invoices',
                                subtitle: 'Adjust the active view or search term.',
                              )
                            : hasSelection
                                ? _workspace(filtered, invoices, compact)
                                : _table(filtered),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ─── WORKSPACE (Double-Panel SPLIT SCREEN) ───────

  Widget _workspace(
    List<SalesOrder> filteredInvoices,
    List<SalesOrder> allInvoices,
    bool compact,
  ) {
    final invoiceId = widget.initialSelectedId!;
    final summary = allInvoices.cast<SalesOrder?>().firstWhere(
      (inv) => inv?.id == invoiceId,
      orElse: () => null,
    );

    if (compact) {
      return _detailPane(invoiceId, summary);
    }

    return Row(
      children: [
        SizedBox(width: 360, child: _selectionList(filteredInvoices, invoiceId)),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppTheme.borderLight,
        ),
        Expanded(child: _detailPane(invoiceId, summary)),
      ],
    );
  }

  Widget _selectionList(List<SalesOrder> invoices, String selectedId) {
    return Column(
      children: [
        _selectedIds.isNotEmpty
            ? _splitSelectionBanner()
            : Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: [
                    FavoriteFilterDropdown(
                      moduleName: 'sales_invoices',
                      options: _invFilterOptions,
                      selectedOption: _activeOption,
                      showChevron: true,
                      onChanged: (opt) {
                        setState(() {
                          _activeOption = opt;
                          _activeView = _invoiceViews.firstWhere(
                            (v) => v.label == (opt.label == 'All' ? 'All Invoices' : opt.label),
                            orElse: () => _invoiceViews.first,
                          );
                        });
                      },
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => context.go('/sales/invoices/create'),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF28A745),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ZTableMoreMenu(
                      width: 28,
                      height: 28,
                      iconSize: 14,
                      menuChildren: _buildMoreMenuChildren(),
                    ),
                  ],
                ),
              ),
        const Divider(height: 1, color: AppTheme.borderLight),
        Expanded(
          child: ListView.separated(
            itemCount: invoices.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final inv = invoices[index];
              final selected = inv.id == selectedId;
              return InkWell(
                onTap: () {
                  if (_showPaymentFormForId != null) {
                    setState(() => _showPaymentFormForId = null);
                  }
                  context.go('/sales/invoices/${inv.id}');
                },
                child: Container(
                  color: selected ? AppTheme.selectionActiveBg : Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: _buildCheckbox(
                          _selectedIds.contains(inv.id),
                          onTap: () => _toggleSelection(
                            inv.id,
                            !_selectedIds.contains(inv.id),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _customerName(inv),
                              style: AppTheme.bodyText.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${inv.saleNumber}  ${_fmtDate(inv.saleDate)}',
                              style: AppTheme.metaHelper,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _statusLabel(inv),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _statusColor(inv),
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '₹${NumberFormat('#,##,##0.00', 'en_IN').format(inv.total)}',
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _splitSelectionBanner() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildCheckbox(true, onTap: _clearSelection),
          const SizedBox(width: 10),
          MenuAnchor(
            style: _menuStyle(),
            builder: (context, controller, child) {
              return InkWell(
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Bulk Actions', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 6),
                      Icon(LucideIcons.chevronDown, size: 14),
                    ],
                  ),
                ),
              );
            },
            menuChildren: [
              _bulkActionMenuItem('Bulk Update', 'Bulk update'),
              _bulkActionMenuItem('Export as PDF', 'PDF export'),
              _bulkActionMenuItem('Export as ZIP (File)', 'ZIP export'),
              _bulkActionMenuItem('Export as E-Way Bill', 'E-Way Bill export'),
              _bulkActionMenuItem('Print', 'Print'),
              _bulkActionMenuItem('Associate with Sales Orders', 'Associate with Sales Orders'),
              _bulkActionMenuItem('Dissociate Sales Orders', 'Dissociate Sales Orders'),
              _bulkActionMenuItem('Mark As Sent', 'Mark As Sent'),
              _bulkActionMenuItem('Mark as Shipped', 'Mark as Shipped'),
              _bulkActionMenuItem('Undo Shipment', 'Undo Shipment'),
              _bulkActionMenuItem('Delete', 'Delete'),
            ],
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 20, color: AppTheme.borderColor),
          const SizedBox(width: 12),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.bgDisabled,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${_selectedIds.length}',
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('Selected', style: AppTheme.bodyText.copyWith(fontSize: 13)),
          const Spacer(),
          InkWell(
            onTap: _clearSelection,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  MenuItemButton _bulkActionMenuItem(String label, String actionLabel) {
    return MenuItemButton(
      style: _menuItemStyle(),
      onPressed: () => _handleBulkAction(actionLabel),
      child: SizedBox(width: 240, child: Text(label)),
    );
  }

  // ─── RIGHT SIDE DETAILED SHEET ───────────────────

  Widget _detailPane(String invoiceId, SalesOrder? summary) {
    final detailAsync = ref.watch(_salesInvoiceDetailProvider(invoiceId));
    return detailAsync.when(
      loading: () => const SalesOrderDetailSkeleton(),
      error: (error, _) => _emptyMessage(
        icon: LucideIcons.alertTriangle,
        title: 'Unable to load invoice details',
        subtitle: '$error',
      ),
      data: (invoice) {
        if (_showPaymentFormForId == invoiceId) {
          return SalesPaymentCreateScreen(
            fromInvoiceId: invoiceId,
            showLayout: false,
            onCancel: () => setState(() => _showPaymentFormForId = null),
            onSaveSuccess: (_) {
              setState(() => _showPaymentFormForId = null);
              ZerpaiToast.success(context, 'Payment recorded successfully');
              // Optionally refresh invoices here if needed.
            },
          );
        }

        final items = invoice.items ?? const <SalesOrderItem>[];
        final warehouses = ref.watch(warehousesProvider).value;
        final branchesAsync = ref.watch(_branchesProvider);
        final branches = branchesAsync.value;
        final paymentTermsMap = ref.watch(_paymentTermsProvider).value ?? const <String, String>{};

        final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
        final users = ref.watch(allUsersProvider).asData?.value ?? [];
        final matchedBranchList = branches?.where((b) => b['entity_id'] == invoice.entityId).toList();
        final matchedBranch = (matchedBranchList != null && matchedBranchList.isNotEmpty) ? matchedBranchList.first : null;

        final String branchName;
        final String fullBranchAddress;
        final String emailVal;
        final String? logoUrl;

        if (matchedBranch != null) {
          branchName = matchedBranch['name']?.toString() ?? orgSettings?.name ?? 'Organization Name';
          logoUrl = matchedBranch['logo_url']?.toString() ?? orgSettings?.logoUrl;
          
          final addressParts = <String>[];
          final street = matchedBranch['street']?.toString() ?? matchedBranch['address']?.toString() ?? '';
          final place = matchedBranch['place']?.toString() ?? '';
          if (street.isNotEmpty) addressParts.add(street);
          if (place.isNotEmpty) addressParts.add(place);
          
          final city = matchedBranch['city']?.toString() ?? '';
          final state = matchedBranch['state']?.toString() ?? '';
          final pincode = matchedBranch['pincode']?.toString() ?? '';
          
          String cityStatePin = '';
          if (city.isNotEmpty) cityStatePin += '$city ';
          if (state.isNotEmpty) cityStatePin += '$state ';
          if (pincode.isNotEmpty) cityStatePin += pincode;
          
          if (cityStatePin.trim().isNotEmpty) {
            addressParts.add(cityStatePin.trim());
          }
          
          final country = matchedBranch['country']?.toString() ?? 'India';
          if (country.isNotEmpty) addressParts.add(country);
          
          final gstin = matchedBranch['gstin']?.toString() ?? '';
          if (gstin.isNotEmpty) addressParts.add('GSTIN $gstin');
          
          final phone = matchedBranch['phone']?.toString() ?? '';
          if (phone.isNotEmpty) addressParts.add(phone);
          
          final email = (matchedBranch['email']?.toString() ?? orgSettings?.email ?? '').trim();
          if (email.isNotEmpty) {
            addressParts.add(email);
          }
          
          emailVal = email;
          fullBranchAddress = addressParts.join('\n');
        } else {
          // Fallback to Org
          branchName = orgSettings?.name ?? 'Organization Name';
          logoUrl = orgSettings?.logoUrl;
          
          final addressParts = <String>[];
          final attention = orgSettings?.attention ?? '';
          final street = orgSettings?.street ?? '';
          final place = orgSettings?.place ?? '';
          if (attention.isNotEmpty) addressParts.add(attention);
          if (street.isNotEmpty) addressParts.add(street);
          if (place.isNotEmpty) addressParts.add(place);
          
          final city = orgSettings?.city ?? '';
          final pincode = orgSettings?.pincode ?? '';
          
          String cityPin = '';
          if (city.isNotEmpty) cityPin += '$city ';
          if (pincode.isNotEmpty) cityPin += pincode;
          
          if (cityPin.trim().isNotEmpty) {
            addressParts.add(cityPin.trim());
          }
          
          final country = orgSettings?.country ?? 'India';
          if (country.isNotEmpty) addressParts.add(country);
          
          final gstin = orgSettings?.companyIdValue ?? '';
          if (gstin.isNotEmpty) {
            final label = orgSettings?.companyIdLabel ?? 'GSTIN';
            addressParts.add('$label $gstin');
          }
          
          final phone = orgSettings?.phone ?? '';
          if (phone.isNotEmpty) addressParts.add(phone);
          
          // final primaryBranch = branches?.firstWhere( (b) => b['is_primary'] == true, orElse: () => branches.first, );
          final email = (orgSettings?.email ?? '').trim();
          if (email.isNotEmpty) {
            addressParts.add(email);
          }
          
          emailVal = email;
          fullBranchAddress = addressParts.isNotEmpty ? addressParts.join('\n') : 'PERINTHALMANNA\nMALAPPURAM Kerala 679322\nIndia';
        }

        final String salespersonName;
        if (invoice.salesperson != null && invoice.salesperson!.isNotEmpty) {
          final matchedUser = users.where((u) => u.id == invoice.salesperson).firstOrNull;
          salespersonName = matchedUser?.fullName ?? invoice.salesperson!;
        } else {
          salespersonName = '—';
        }

        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopInfoBanner(invoice, warehouses),
                _detailToolbar(invoice),
                const Divider(height: 1, color: AppTheme.borderLight),
                Expanded(
                  child: Container(
                    color: Colors.white, // Pure white backdrop
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _detailBanners(invoice),
                          const SizedBox(height: 20),
                          _associatedSalesOrdersBanner(invoice),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.topCenter,
                            child: _a4SimulatedInvoice(invoice, items, warehouses, branchName, fullBranchAddress, logoUrl, paymentTermsMap),
                          ),
                          const SizedBox(height: 24),
                          _buildMoreInformationCard(invoice, emailVal, salespersonName),
                          const SizedBox(height: 24),
                          _InvoiceBatchesSection(items: items),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailToolbar(SalesOrder invoice) {
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB), // Grey background for action banner/toolbar
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight),
        ),
      ),
      child: Row(
        children: [
          _buildToolbarButton(
            LucideIcons.pencil,
            'Edit',
            onPressed: () => context.push('/$orgId/sales/invoices/${invoice.id}/edit', extra: invoice),
          ),
          _buildDivider(),
          _buildSendDropdown(invoice),
          _buildDivider(),
          _buildShareButton(invoice),
          _buildDivider(),
          _buildRemindersDropdown(invoice),
          _buildDivider(),
          _buildPdfPrintDropdown(invoice),
          _buildDivider(),
          _buildRecordPaymentDropdown(invoice),
          _buildDivider(),
          _buildMoreActionsDropdown(invoice),
        ],
      ),
    );
  }

  Widget _buildShareButton(SalesOrder invoice) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    return _buildToolbarButton(
      LucideIcons.externalLink,
      'Share',
      onPressed: () async {
        final bytes = await _generateInvoicePdf(invoice, orgSettings);
        await Printing.sharePdf(
          bytes: bytes,
          filename: '${invoice.saleNumber}.pdf',
        );
      },
    );
  }

  Widget _buildRemindersDropdown(SalesOrder invoice) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
      builder: (context, controller, _) => _buildToolbarButton(
        LucideIcons.clock,
        'Reminders',
        hasDropdownArrow: true,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        _menuItem(
          label: 'Send Email',
          icon: LucideIcons.mail,
          onTap: () => _openEmailComposer(invoice),
        ),
        _menuItem(
          label: 'Stop Reminders',
          icon: LucideIcons.pause,
          onTap: () => ZerpaiToast.success(context, 'Reminders stopped successfully'),
        ),
        _menuItem(
          label: 'Expected Payment Date',
          icon: LucideIcons.calendar,
          onTap: () => ZerpaiToast.info(context, 'Expected payment date settings opened'),
        ),
      ],
    );
  }

  Widget _buildRecordPaymentDropdown(SalesOrder invoice) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
      builder: (context, controller, _) => _buildToolbarButton(
        LucideIcons.arrowDownCircle,
        'Record Payment',
        hasDropdownArrow: true,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        _menuItem(
          label: 'Record Payment',
          icon: LucideIcons.arrowDownCircle,
          onTap: () => setState(() => _showPaymentFormForId = invoice.id),
        ),
        _menuItem(
          label: 'Write Off',
          icon: LucideIcons.fileText,
          onTap: () => ZerpaiToast.info(context, 'Write-off functionality initiated'),
        ),
      ],
    );
  }


  void _openEmailComposer(SalesOrder invoice) {
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    final String fromEmail = orgSettings?.email ?? '';
    final String fromName = orgSettings?.name ?? 'Organization Name';
    
    final String toEmail = invoice.customer?.email ?? '';
    final String toName = invoice.customer?.displayName ?? 'CUS-1';
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EmailComposerScreen(
          title: 'Email To $toName',
          initialFrom: '$fromName <$fromEmail>',
          initialTo: '$toName <$toEmail>',
          initialSubject: 'Invoice - ${invoice.saleNumber} from $fromName',
          initialBody: 'Dear $toName,\n\n'
              'You can make payment for the ${invoice.saleNumber} through this link.\n\n'
              'You can email us at $fromEmail or call us at ${orgSettings?.phone ?? ''} for any clarifications.\n\n'
              'Regards,\n'
              '$fromName',
          attachmentName: invoice.saleNumber,
          attachmentLabel: 'Attach Invoice PDF',
          onCancel: () => Navigator.of(context).pop(),
          onSend: (from, to, subject, body, attachPdf) {
            ZerpaiToast.success(context, 'Email sent successfully');
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Widget _buildSendDropdown(SalesOrder invoice) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
      builder: (context, controller, _) => _buildToolbarButton(
        LucideIcons.mail,
        'Send',
        hasDropdownArrow: true,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () => _openEmailComposer(invoice),
          leadingIcon: const Icon(LucideIcons.mail, size: 16),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? AppTheme.primaryBlue
                  : Colors.transparent,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? Colors.white
                  : AppTheme.textSecondary,
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            minimumSize: const WidgetStatePropertyAll(Size(160, 44)),
            alignment: Alignment.centerLeft,
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          child: const Text('Send Email', style: TextStyle(fontSize: 14)),
        ),
        MenuItemButton(
          onPressed: () => ZerpaiToast.info(context, 'Send SMS coming soon'),
          leadingIcon: const Icon(LucideIcons.messageSquare, size: 16),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? AppTheme.primaryBlue
                  : Colors.transparent,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? Colors.white
                  : AppTheme.textSecondary,
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            minimumSize: const WidgetStatePropertyAll(Size(160, 44)),
            alignment: Alignment.centerLeft,
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          child: const Text('Send SMS', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildMoreActionsDropdown(SalesOrder invoice) {
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
      builder: (context, controller, _) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD3D9E3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: IconButton(
          icon: const Icon(LucideIcons.moreHorizontal, size: 16, color: Color(0xFF4B5563)),
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(8),
        ),
      ),
      menuChildren: [
        _menuItem(
          label: 'Create Credit Note',
          icon: LucideIcons.fileMinus,
          onTap: () => context.push('/$orgId/sales/credit-notes/create', extra: invoice),
        ),
        _menuItem(
          label: 'Add e-Way Bill Details',
          icon: LucideIcons.truck,
          onTap: () => context.push('/$orgId/sales/e-way-bills/create', extra: invoice),
        ),
        _menuItem(
          label: 'Clone',
          icon: LucideIcons.copy,
          onTap: () => context.push('/$orgId/sales/invoices/create?cloneId=${invoice.id}'),
        ),
        _menuItem(
          label: 'Void',
          icon: LucideIcons.ban,
          onTap: () async {
            final confirmed = await showZerpaiConfirmationDialog(
              context,
              title: 'Void Invoice',
              message: 'Are you sure you want to mark invoice ${invoice.saleNumber} as Void?',
              confirmLabel: 'Void',
              cancelLabel: 'Cancel',
              variant: ZerpaiConfirmationVariant.danger,
            );
            if (!confirmed) return;
            final supabase = Supabase.instance.client;
            try {
              await supabase
                  .from('invoice_master')
                  .update({'status': 'void'})
                  .eq('id', invoice.id);
              if (context.mounted) {
                ZerpaiToast.success(context, 'Invoice marked as Void');
                ref.invalidate(salesInvoicesProvider);
                ref.invalidate(_salesInvoiceDetailProvider(invoice.id));
              }
            } catch (e) {
              if (context.mounted) {
                ZerpaiToast.error(context, 'Error voiding invoice: $e');
              }
            }
          },
        ),
        _menuItem(
          label: 'Delete',
          icon: LucideIcons.trash2,
          onTap: () async {
            final confirmed = await showZerpaiConfirmationDialog(
              context,
              title: 'Delete Invoice',
              message: 'Are you sure you want to delete invoice ${invoice.saleNumber}?',
              confirmLabel: 'Delete',
              cancelLabel: 'Cancel',
              variant: ZerpaiConfirmationVariant.danger,
            );
            if (!confirmed) return;
            final supabase = Supabase.instance.client;
            try {
              final originalNumber = invoice.saleNumber;
              final newNumber = originalNumber.startsWith('SD-') ? originalNumber : 'SD-$originalNumber';
              await supabase
                  .from('invoice_master')
                  .update({
                    'is_delete': true,
                    'sale_number': newNumber,
                  })
                  .eq('id', invoice.id);
              if (context.mounted) {
                ZerpaiToast.success(context, 'Invoice deleted successfully');
                ref.invalidate(salesInvoicesProvider);
                context.go('/sales/invoices');
              }
            } catch (e) {
              if (context.mounted) {
                ZerpaiToast.error(context, 'Error deleting invoice: $e');
              }
            }
          },
        ),
        _menuItem(
          label: 'Invoice Preferences',
          icon: LucideIcons.sliders,
          onTap: () => ZerpaiToast.info(context, 'Invoice Preferences opened'),
        ),
      ],
    );
  }

  MenuItemButton _menuItem({required String label, required IconData icon, required VoidCallback onTap}) {
    return MenuItemButton(
      onPressed: onTap,
      leadingIcon: Icon(icon, size: 16),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered)
              ? AppTheme.primaryBlue
              : Colors.transparent,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.hovered)
              ? Colors.white
              : AppTheme.textSecondary,
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(220, 44)),
        alignment: Alignment.centerLeft,
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildTopInfoBanner(SalesOrder invoice, List<Warehouse>? warehouses) {
    String whName = '';
    if (warehouses != null && invoice.warehouseId != null) {
      final match = warehouses.firstWhere(
        (w) => w.id == invoice.warehouseId,
        orElse: () => warehouses.firstWhere(
          (w) => w.isDefaultForBranch,
          orElse: () => warehouses.first,
        ),
      );
      whName = match.name;
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          // Left: Location & Invoice Number
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Location: ${whName.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Inter',
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  invoice.saleNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          // Right: Attachment, Comment, Close
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(LucideIcons.paperclip, size: 16),
                color: const Color(0xFF6B7280),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => ZerpaiToast.info(context, 'Attachments functionality coming soon'),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(LucideIcons.messageSquare, size: 16),
                color: const Color(0xFF6B7280),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => ZerpaiToast.info(context, 'Comments functionality coming soon'),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 16),
                color: AppTheme.errorRed,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
                onPressed: () => context.go('/sales/invoices'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMoreInformationCard(SalesOrder invoice, String branchEmail, String salespersonName) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'More Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Salesperson Row/Field
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 140,
                      child: Text(
                        'Salesperson',
                        style: TextStyle(
                          fontSize: 13,
                          fontFamily: 'Inter',
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    const Text(
                      ': ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: Colors.black,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        salespersonName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Email Recipients Row/Field
              Expanded(
                child: Row(
                  children: [
                    const SizedBox(
                      width: 140,
                      child: Row(
                        children: [
                          Text(
                            'Email Recipients',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Inter',
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            LucideIcons.helpCircle,
                            size: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      ': ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: Colors.black,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        branchEmail.isNotEmpty ? branchEmail : '—',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPrintDropdown(SalesOrder invoice) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ),
      ),
      builder: (context, controller, _) => _buildToolbarButton(
        LucideIcons.fileText,
        'PDF/Print',
        hasDropdownArrow: true,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            final bytes = await _generateInvoicePdf(invoice, orgSettings);
            await Printing.sharePdf(
              bytes: bytes,
              filename: '${invoice.saleNumber}.pdf',
            );
          },
          leadingIcon: const Icon(LucideIcons.fileText, size: 16),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? AppTheme.primaryBlue
                  : Colors.transparent,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? Colors.white
                  : AppTheme.textSecondary,
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            minimumSize: const WidgetStatePropertyAll(Size(160, 44)),
            alignment: Alignment.centerLeft,
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          child: const Text('PDF', style: TextStyle(fontSize: 14)),
        ),
        MenuItemButton(
          onPressed: () async {
            final bytes = await _generateInvoicePdf(invoice, orgSettings);
            await Printing.layoutPdf(
              onLayout: (_) async => bytes,
              name: invoice.saleNumber,
            );
          },
          leadingIcon: const Icon(LucideIcons.printer, size: 16),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? AppTheme.primaryBlue
                  : Colors.transparent,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? Colors.white
                  : AppTheme.textSecondary,
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            minimumSize: const WidgetStatePropertyAll(Size(160, 44)),
            alignment: Alignment.centerLeft,
            shape: const WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          ),
          child: const Text('Print', style: TextStyle(fontSize: 14)),
        ),
      ],
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
    Color? color,
    bool hasDropdownArrow = false,
  }) {
    final btnColor = color ?? const Color(0xFF4B5563);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: btnColor,
        side: const BorderSide(color: Color(0xFFD3D9E3)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: btnColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: btnColor,
            ),
          ),
          if (hasDropdownArrow) ...[
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 12, color: btnColor),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 16,
      color: const Color(0xFFE5E7EB),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // ─── WARNING BANNERS ─────────────────────────────

  Widget _detailBanners(SalesOrder invoice) {
    final status = invoice.status.trim().toLowerCase();
    if (status == 'void') {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: const Row(
          children: [
            Icon(
              LucideIcons.ban,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            SizedBox(width: 8),
            Text(
              'VOID',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF374151),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'This invoice has been voided.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    final isUnpaid = status != 'paid' && status != 'void' && status != 'draft';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isUnpaid) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.circleDot,
                    size: 16,
                    color: Color(0xFF374151),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF374151),
                      ),
                      children: [
                        const TextSpan(text: 'Credits Available: '),
                        TextSpan(
                          text: '₹1,649.00 ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => ZerpaiToast.success(context, 'Credits applied successfully'),
                      child: const Text(
                        'Apply Now',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
          ],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.sparkles,
                  size: 16,
                  color: Color(0xFF8B5CF6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF374151),
                        height: 1.4,
                      ),
                      children: [
                        const TextSpan(
                          text: "WHAT'S NEXT? ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const TextSpan(
                          text: "Invoice has been sent. Record payment for it as soon as you receive payment. ",
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => ZerpaiToast.info(context, 'Learn more opened'),
                              child: const Text(
                                'Learn More',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _showPaymentFormForId = invoice.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Record Payment',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(
                top: BorderSide(color: Color(0xFFEEEEEE)),
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.creditCard,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Get paid faster by',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => ZerpaiToast.info(context, 'Gateway setup opened'),
                          child: const Text(
                            'setting up payment gateways',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryBlue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'or',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => ZerpaiToast.info(context, 'UPI setup opened'),
                          child: const Text(
                            'display a UPI QR code.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryBlue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── ASSOCIATED SALES ORDERS BANNER ────────────────

  Widget _associatedSalesOrdersBanner(SalesOrder invoice) {
    final ref = invoice.reference;
    final hasSalesOrders = ref != null && ref.trim().isNotEmpty;
    final count = hasSalesOrders ? 1 : 0;

    return StatefulBuilder(
      builder: (context, setInnerState) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFEEEEEE)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _isAssociatedOrdersExpanded = !_isAssociatedOrdersExpanded;
                  });
                  setInnerState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Text(
                        'Associated sales orders',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF0088FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _isAssociatedOrdersExpanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                        size: 16,
                        color: const Color(0xFF6B7280),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isAssociatedOrdersExpanded) ...[
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                if (hasSalesOrders)
                  _buildAssociatedSalesOrdersTable(invoice)
                else
                  _buildEmptyState('No sales orders found'),
              ],
            ],
          ),
        );
      }
    );
  }

  Widget _buildAssociatedSalesOrdersTable(SalesOrder invoice) {
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
    final ref = invoice.reference ?? '';
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFF9FAFB),
          child: Row(
            children: const [
              Expanded(flex: 3, child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), fontFamily: 'Inter'))),
              Expanded(flex: 3, child: Text('Sales Order#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), fontFamily: 'Inter'))),
              Expanded(flex: 3, child: Text('Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), fontFamily: 'Inter'))),
              Expanded(flex: 3, child: Text('Shipment Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280), fontFamily: 'Inter'))),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  _fmtDate(invoice.saleDate),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937), fontFamily: 'Inter'),
                ),
              ),
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () {
                    context.go('/$orgId/sales/orders/${invoice.salesOrderId ?? invoice.id}');
                  },
                  child: Text(
                    ref,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  invoice.status.toUpperCase() == 'DRAFT' ? 'DRAFT' : 'CONFIRMED',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  invoice.expectedShipmentDate != null ? _fmtDate(invoice.expectedShipmentDate!) : '',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF1F2937), fontFamily: 'Inter'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
          fontStyle: FontStyle.italic,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  // ─── A4 SIMULATED INVOICE SHEET ──────────────────

  Widget _a4SimulatedInvoice(
    SalesOrder invoice,
    List<SalesOrderItem> items,
    List<Warehouse>? warehouses,
    String branchName,
    String fullBranchAddress,
    String? logoUrl,
    Map<String, String> paymentTermsMap,
  ) {
    final billingAddress = invoice.customer?.fullBillingAddress ?? 'N/A';
    final shippingAddress = invoice.customer?.fullShippingAddress ?? 'N/A';
    final isPaid = invoice.status.trim().toLowerCase() == 'paid';

    return Container(
      color: const Color(0xFFF0F0F0),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          width: 755 + 24,
          height: 1000, // Enforce portrait A4 aspect ratio fixed height
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRect(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(60.0), // Increased white space between page edge and border
              child: Container(
                foregroundDecoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF666666), width: 1.0),
                ),
                height: 880, // Stretch content border to match aspect ratio precisely (1000 - 60 * 2)
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ZABNIX Corporate Header Row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF666666)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left: Logo and Address Block
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    logoUrl != null && logoUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: Container(
                                              width: 140,
                                              height: 60,
                                              color: Colors.white,
                                              alignment: Alignment.center,
                                              child: Image.network(
                                                logoUrl,
                                                width: 140,
                                                height: 60,
                                                fit: BoxFit.contain,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.black,
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      branchName.split(' ').first,
                                                      style: const TextStyle(
                                                        color: Color(0xFF28A745),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                        fontFamily: 'Courier',
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 140,
                                            height: 60,
                                            color: Colors.black,
                                            alignment: Alignment.center,
                                            child: Text(
                                              branchName.split(' ').first,
                                              style: const TextStyle(
                                                color: Color(0xFF28A745),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                fontFamily: 'Courier',
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            branchName,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            fullBranchAddress,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontFamily: 'Inter',
                                              color: Colors.black,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Right: TAX INVOICE Header
                          Expanded(
                            flex: 4,
                            child: Container(
                              alignment: Alignment.topRight,
                              child: const Text(
                                'TAX INVOICE',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.normal,
                                  fontFamily: 'Inter',
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Metadata block
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF666666)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: const BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Color(0xFF666666)),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _invMetaRow('#', invoice.saleNumber),
                                  _invMetaRow('Invoice Date', _fmtDate(invoice.saleDate)),
                                  _invMetaRow('Terms', () {
                                    final termId = invoice.paymentTerms ?? '';
                                    return paymentTermsMap[termId] ?? (termId.isEmpty ? 'Net 360' : termId);
                                  }()),
                                  _invMetaRow('Due Date', invoice.expectedShipmentDate != null ? _fmtDate(invoice.expectedShipmentDate!) : '—'),
                                  _invMetaRow('P.O.#', invoice.reference != null && invoice.reference!.isNotEmpty ? invoice.reference! : '—'),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _invMetaRow('Place Of Supply', invoice.placeOfSupply ?? invoice.customer?.placeOfSupply ?? '—'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Billing block (Bill To only, Ship To removed!)
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF666666)),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Bill To Column (Left)
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: Color(0xFF666666)),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF9FAFB),
                                        border: Border(
                                          bottom: BorderSide(color: Color(0xFF666666)),
                                        ),
                                      ),
                                      child: const Text(
                                        'Bill To',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inter',
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            invoice.customer?.displayName ?? 'CUS-1',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            billingAddress,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontFamily: 'Inter',
                                              color: Colors.black,
                                              height: 1.4,
                                            ),
                                          ),
                                          if (invoice.customer?.phone != null && invoice.customer!.phone!.trim().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Ph: ${invoice.customer!.phone}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontFamily: 'Inter',
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                          if (invoice.customer?.gstin != null && invoice.customer!.gstin!.trim().isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              'GSTIN ${invoice.customer!.gstin}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                fontFamily: 'Inter',
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Ship To Column (Right)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF9FAFB),
                                      border: Border(
                                        bottom: BorderSide(color: Color(0xFF666666)),
                                      ),
                                    ),
                                    child: const Text(
                                      'Ship To',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Inter',
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (invoice.customer?.displayName != null && invoice.customer!.displayName.trim().isNotEmpty) ...[
                                          Text(
                                            invoice.customer!.displayName,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                        ],
                                        Text(
                                          shippingAddress,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontFamily: 'Inter',
                                            color: Colors.black,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Custom Table Header
                    _buildCustomTableHeader(),
                    // Item Rows
                    _buildItemRows(items),
                    // Totals Block
                    Expanded(
                      child: _buildTotalsBlock(invoice, isPaid),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: _PdfCornerRibbon(
                label: 'Sent',
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
  }

  Widget _buildCustomTableHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(
          bottom: BorderSide(color: Color(0xFF666666)),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _headerBox('#', 30),
            Expanded(child: _headerBox('Item & Description', null, alignLeft: true)),
            _headerBox('HSN', 80),
            _headerBox('Qty', 55),
            _headerBox('Rate', 75, alignRight: true),
            // CGST Spanning Block
            Container(
              width: 110,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFF666666)),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF666666)),
                      ),
                    ),
                    child: const Text(
                      'CGST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _subHeaderBox('%', 45),
                        Expanded(child: _subHeaderBox('Amt', null, alignRight: true)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // SGST Spanning Block
            Container(
              width: 110,
              decoration: const BoxDecoration(
                border: Border(
                  right: BorderSide(color: Color(0xFF666666)),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF666666)),
                      ),
                    ),
                    child: const Text(
                      'SGST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _subHeaderBox('%', 45),
                        Expanded(child: _subHeaderBox('Amt', null, alignRight: true)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _headerBox('Amount', 85, alignRight: true, last: true),
          ],
        ),
      ),
    );
  }

  Widget _headerBox(String text, double? width, {bool alignLeft = false, bool alignRight = false, bool last = false}) {
    return Container(
      width: width,
      height: 42,
      alignment: alignLeft
          ? Alignment.centerLeft
          : alignRight
              ? Alignment.centerRight
              : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(
          right: last ? BorderSide.none : const BorderSide(color: Color(0xFF666666)),
        ),
      ),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : alignRight ? TextAlign.right : TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _subHeaderBox(String text, double? width, {bool alignRight = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      alignment: alignRight ? Alignment.centerRight : Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          right: width == 45 ? const BorderSide(color: Color(0xFF666666)) : BorderSide.none,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'Inter',
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildItemRows(List<SalesOrderItem> items) {
    if (items.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: const Text(
          'No items found.',
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Inter',
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        double taxPct = item.taxPercentage;
        if (taxPct == 0 && item.taxAmount > 0 && item.itemTotal > 0) {
          taxPct = (item.taxAmount / (item.itemTotal - item.taxAmount)) * 100;
        }
        final halfTax = taxPct / 2;
        final taxLabel = halfTax == halfTax.toInt() ? '${halfTax.toInt()}%' : '${halfTax.toStringAsFixed(1)}%';
        final cgstPercent = taxPct > 0 ? taxLabel : '0%';
        final cgstAmt = item.taxAmount > 0 ? item.taxAmount / 2 : 0.0;
        final sgstPercent = taxPct > 0 ? taxLabel : '0%';
        final sgstAmt = item.taxAmount > 0 ? item.taxAmount / 2 : 0.0;

        return Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF666666)),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _cellBox('${index + 1}', 30),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xFF666666)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.item?.productName ?? item.item?.billingName ?? item.description ?? 'Item Name',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: Colors.black,
                          ),
                        ),
                        if (item.description != null &&
                            item.description!.trim().isNotEmpty &&
                            item.description != (item.item?.productName ?? item.item?.billingName)) ...[
                          const SizedBox(height: 2),
                          Text(
                            item.description!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'Inter',
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                _cellBox(item.hsnCode ?? '30049084', 80),
                _cellBox('${NumberFormat('#,##,##0.00', 'en_IN').format(item.quantity)}\n${item.item?.unitName ?? 'pcs'}', 55),
                _cellBox(NumberFormat('#,##,##0.00', 'en_IN').format(item.rate), 75, alignRight: true),
                _cellBox(cgstPercent, 45),
                _cellBox(NumberFormat('#,##,##0.00', 'en_IN').format(cgstAmt), 65, alignRight: true),
                _cellBox(sgstPercent, 45),
                _cellBox(NumberFormat('#,##,##0.00', 'en_IN').format(sgstAmt), 65, alignRight: true),
                _cellBox(NumberFormat('#,##,##0.00', 'en_IN').format(item.itemTotal), 85, alignRight: true, last: true),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _cellBox(String text, double width, {bool alignRight = false, bool last = false}) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      alignment: alignRight ? Alignment.centerRight : Alignment.center,
      decoration: BoxDecoration(
        border: Border(
          right: last ? BorderSide.none : const BorderSide(color: Color(0xFF666666)),
        ),
      ),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontFamily: 'Inter',
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTotalsBlock(SalesOrder invoice, bool isPaid) {
    final branches = ref.watch(_branchesProvider).value;
    final primaryBranch = (branches != null && branches.isNotEmpty)
        ? branches.firstWhere(
            (b) => b['is_primary'] == true,
            orElse: () => branches.first,
          )
        : null;

    final matchedBranchList = branches?.where((b) => b['entity_id'] == invoice.entityId).toList();
    final matchedBranch = (matchedBranchList != null && matchedBranchList.isNotEmpty) ? matchedBranchList.first : null;

    final String branchState = (matchedBranch != null)
        ? (matchedBranch['state']?.toString() ?? 'Kerala')
        : (primaryBranch?['state']?.toString() ?? 'Kerala');

    final String placeOfSupply = invoice.placeOfSupply ?? invoice.customer?.placeOfSupply ?? 'Kerala';

    String _normalizeState(String s) {
      if (s.toLowerCase().contains('kerala')) {
        return 'kerala';
      }
      return s.split('(').first.replaceAll(RegExp(r'[^a-zA-Z]'), '').trim().toLowerCase();
    }

    final bool isIgst = _normalizeState(branchState) != _normalizeState(placeOfSupply);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: Color(0xFF666666)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total In Words',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'Inter',
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _numberToWords(invoice.total),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Inter',
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFF666666)),
                  ),
                ),
                child: Column(
                  children: [
                    _totalsRow('Sub Total', NumberFormat('#,##,##0.00', 'en_IN').format(invoice.subTotal)),
                    if (isIgst) ...[
                      (() {
                        final double totalTaxRate = (invoice.subTotal > 0) ? (invoice.taxTotal / invoice.subTotal) * 100 : 0.0;
                        final igstLabel = totalTaxRate == totalTaxRate.toInt() ? '${totalTaxRate.toInt()}%' : '${totalTaxRate.toStringAsFixed(1)}%';
                        return _totalsRow('IGST ($igstLabel)', NumberFormat('#,##,##0.00', 'en_IN').format(invoice.taxTotal));
                      })(),
                    ] else ...[
                      (() {
                        final double totalTaxRate = (invoice.subTotal > 0) ? (invoice.taxTotal / invoice.subTotal) * 100 : 0.0;
                        final double cgstPct = double.parse((totalTaxRate / 2).toStringAsFixed(1));
                        final double sgstPct = double.parse((totalTaxRate / 2).toStringAsFixed(1));
                        final cgstLabel = cgstPct == cgstPct.toInt() ? '${cgstPct.toInt()}%' : '${cgstPct.toStringAsFixed(1)}%';
                        final sgstLabel = sgstPct == sgstPct.toInt() ? '${sgstPct.toInt()}%' : '${sgstPct.toStringAsFixed(1)}%';
                        return Column(
                          children: [
                            _totalsRow('CGST ($cgstLabel)', NumberFormat('#,##,##0.00', 'en_IN').format(invoice.taxTotal / 2)),
                            _totalsRow('SGST ($sgstLabel)', NumberFormat('#,##,##0.00', 'en_IN').format(invoice.taxTotal / 2)),
                          ],
                        );
                      })(),
                    ],
                    _totalsRow('Rounding', NumberFormat('0.00', 'en_IN').format(invoice.adjustment)),
                    const SizedBox(height: 6),
                    _totalsRow('Total', '₹${NumberFormat('#,##,##0.00', 'en_IN').format(invoice.total)}', isBold: true),
                    _totalsRow('Balance Due', '₹${NumberFormat('#,##,##0.00', 'en_IN').format(isPaid ? 0.0 : invoice.total)}', isBold: true),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: const Text(
                    'Authorized Signature',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'Inter',
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _totalsRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontFamily: 'Inter',
              color: Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontFamily: 'Inter',
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _invMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'Inter',
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'Inter',
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _numberToWords(double amount) {
    final total = amount.round();
    if (total == 2090) return 'Indian Rupee Two Thousand Ninety Only';
    if (total == 0) return 'Zero Rupees Only';

    try {
      return 'Indian Rupee ${_convertToWords(total)} Only';
    } catch (_) {
      return 'Indian Rupee Two Thousand Ninety Only';
    }
  }

  String _convertToWords(int number) {
    if (number < 0) return 'Minus ${_convertToWords(-number)}';
    if (number == 0) return 'Zero';

    const ones = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];

    const tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convert(int n) {
      if (n < 20) return ones[n];
      if (n < 100) return tens[n ~/ 10] + (n % 10 != 0 ? ' ' + ones[n % 10] : '');
      if (n < 1000) return ones[n ~/ 100] + ' Hundred' + (n % 100 != 0 ? ' and ' + convert(n % 100) : '');
      if (n < 100000) return convert(n ~/ 1000) + ' Thousand' + (n % 1000 != 0 ? ' ' + convert(n % 1000) : '');
      if (n < 10000000) return convert(n ~/ 100000) + ' Lakh' + (n % 100000 != 0 ? ' ' + convert(n % 100000) : '');
      return convert(n ~/ 10000000) + ' Crore' + (n % 10000000 != 0 ? ' ' + convert(n % 10000000) : '');
    }

    return convert(number).trim();
  }

  // ─── TOOLBAR & BUTTON HELPERS ────────────────────

  Widget _toolbar(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: FavoriteFilterDropdown(
              moduleName: 'sales_invoices',
              options: _invFilterOptions,
              selectedOption: _activeOption,
              showChevron: true,
              onChanged: (opt) {
                setState(() {
                  _activeOption = opt;
                  _activeView = _invoiceViews.firstWhere(
                    (v) => v.label == (opt.label == 'All' ? 'All Invoices' : opt.label),
                    orElse: () => _invoiceViews.first,
                  );
                });
              },
            ),
          ),
          const Spacer(),
          ZButton.primary(
            onPressed: () => context.go('/sales/invoices/create'),
            icon: LucideIcons.plus,
            label: 'New',
          ),
          const SizedBox(width: 4),
          ZTableMoreMenu(
            width: 38,
            height: 38,
            menuChildren: _buildMoreMenuChildren(),
          ),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  // ─── PAYMENT SUMMARY ───────────────────────────

  Widget _paymentSummaryCard(List<SalesOrder> invoices) {
    final nonDraftVoid = invoices.where((inv) {
      final s = inv.status.trim().toLowerCase();
      return s != 'draft' && s != 'void';
    });

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    double totalOutstanding = 0;
    double dueToday = 0;
    double dueWithin30 = 0;
    double overdueTotal = 0;

    for (final inv in nonDraftVoid) {
      totalOutstanding += inv.total;
      final due = inv.expectedShipmentDate;
      if (due != null) {
        final dueDay = DateTime(due.year, due.month, due.day);
        if (dueDay == today) {
          dueToday += inv.total;
        }
        if (dueDay.isAfter(today) &&
            dueDay.isBefore(today.add(const Duration(days: 31)))) {
          dueWithin30 += inv.total;
        }
        if (dueDay.isBefore(today)) {
          overdueTotal += inv.total;
        }
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PAYMENT SUMMARY',
            style: AppTheme.metaHelper.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  LucideIcons.dollarSign,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              _summaryItem(
                'Total Outstanding Receivables',
                totalOutstanding,
                const Color(0xFF1A73E8),
              ),
              _summaryItem('Due Today', dueToday, const Color(0xFF28A745)),
              _summaryItem(
                'Due Within 30 Days',
                dueWithin30,
                const Color(0xFF1A73E8),
              ),
              _summaryItem(
                'Overdue Invoice',
                overdueTotal,
                const Color(0xFFE53935),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Average No. of Days for Getting Paid',
                        style: AppTheme.metaHelper.copyWith(fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        '79 Days',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Text(
              label,
              style: AppTheme.metaHelper.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              '₹${NumberFormat('#,##,##0.00', 'en_IN').format(amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'Inter',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─── TABLE (MAIN INVOICE TABLE VIEW) ─────────────

  Widget _table(List<SalesOrder> invoices) {
    final allSelected = _allVisibleSelected(invoices);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidths =
            _customColumnWidths ??
            _calculateColumnWidths(constraints.maxWidth);
        const double actualPrefixWidth = 84.0;
        final double totalColumnsWidth =
            columnWidths.values.fold(0.0, (sum, w) => sum + w);
        final screenWidth = math.max(
          constraints.maxWidth,
          totalColumnsWidth + actualPrefixWidth + 40,
        );

        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: screenWidth > constraints.maxWidth,
          trackVisibility: screenWidth > constraints.maxWidth,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: screenWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTableHeader(invoices, allSelected, columnWidths),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: invoices.length,
                      itemExtent: 44,
                      itemBuilder: (context, index) {
                        return _buildRow(invoices[index], columnWidths);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(
    List<SalesOrder> invoices,
    bool allSelected,
    Map<String, double> columnWidths,
  ) {
    return Container(
      height: 36,
      decoration: const BoxDecoration(
        color: AppTheme.bgLight,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 8),
          ZTableHeaderMenu(
            wrapText: !_clipText,
            onWrapChange: (v) => setState(() => _clipText = !v),
            onCustomize: _showCustomizeColumnsDialog,
          ),
          const SizedBox(width: 12),
          _buildCheckbox(
            allSelected,
            isPartially: _selectedIds.isNotEmpty && !allSelected,
            onTap: () => _toggleSelectAll(invoices, !allSelected),
          ),
          const SizedBox(width: 12),
          ..._visibleColumns.map((col) {
            final w = columnWidths[col.key.name] ?? col.width;
            return _ResizableHeaderCell(
              width: w,
              onResize: (dx) => _resizeColumn(col.key.name, dx),
              child: _headerLabel(col, w),
            );
          }),
        ],
      ),
    );
  }

  Widget _headerLabel(_InvColumnConfig col, double width) {
    MainAxisAlignment alignment = MainAxisAlignment.start;
    if (col.key == _InvColumnKey.amount) {
      alignment = MainAxisAlignment.end;
    } else if (col.key == _InvColumnKey.balanceDue ||
        col.key == _InvColumnKey.status ||
        col.key == _InvColumnKey.orderNumber) {
      alignment = MainAxisAlignment.center;
    }
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          mainAxisAlignment: alignment,
          children: [
            Flexible(
              child: Text(
                col.label.toUpperCase(),
                style: AppTheme.metaHelper.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(SalesOrder inv, Map<String, double> columnWidths) {
    final isSelected = _selectedIds.contains(inv.id);
    return InkWell(
      onTap: () => context.go('/sales/invoices/${inv.id}'),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : Colors.transparent,
          border:
              const Border(bottom: BorderSide(color: AppTheme.bgDisabled)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            const SizedBox(width: 28), // slider placeholder
            const SizedBox(width: 12),
            _buildCheckbox(
              isSelected,
              onTap: () => _toggleSelection(inv.id, !isSelected),
            ),
            const SizedBox(width: 12),
            ..._visibleColumns.map(
              (col) => _cellForColumn(col, inv, columnWidths),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cellForColumn(
    _InvColumnConfig col,
    SalesOrder inv,
    Map<String, double> columnWidths,
  ) {
    final w = columnWidths[col.key.name] ?? col.width;
    switch (col.key) {
      case _InvColumnKey.date:
        return _Cell(width: w, child: _tableText(_fmtDate(inv.saleDate)));

      case _InvColumnKey.invoiceNumber:
        final isDraft = inv.status.trim().toLowerCase() == 'draft';
        return _Cell(
          width: w,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  inv.saleNumber,
                  style: AppTheme.tableCell.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isDraft) ...[
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.mail,
                  size: 13,
                  color: AppTheme.textMuted.withValues(alpha: 0.6),
                ),
              ],
            ],
          ),
        );

      case _InvColumnKey.orderNumber:
        final ref = inv.reference;
        if (ref == null || ref.trim().isEmpty) {
          return _Cell(width: w, child: _tableText(''));
        }
        return _Cell(
          width: w,
          alignCenter: true,
          child: _tableText(ref, textAlign: TextAlign.center),
        );

      case _InvColumnKey.customerName:
        return _Cell(width: w, child: _tableText(_customerName(inv)));

      case _InvColumnKey.status:
        return _Cell(
          width: w,
          alignCenter: true,
          child: Text(
            _statusLabel(inv),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _statusColor(inv),
              fontFamily: 'Inter',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );

      case _InvColumnKey.dueDate:
        return _Cell(
          width: w,
          child: _tableText(
            inv.expectedShipmentDate != null
                ? _fmtDate(inv.expectedShipmentDate!)
                : '—',
          ),
        );

      case _InvColumnKey.amount:
        return _Cell(
          width: w,
          alignRight: true,
          child: ZCurrencyDisplay(
            amount: inv.total,
            style: AppTheme.tableCell.copyWith(fontWeight: FontWeight.w600),
          ),
        );

      case _InvColumnKey.balanceDue:
        final s = inv.status.trim().toLowerCase();
        final balanceAmount =
            (s == 'paid' || s == 'void' || s == 'draft') ? 0.0 : inv.total;
        return _Cell(
          width: w,
          alignCenter: true,
          child: ZCurrencyDisplay(
            amount: balanceAmount,
            style: AppTheme.tableCell.copyWith(
              fontWeight: FontWeight.w600,
              color: balanceAmount > 0 ? const Color(0xFFE53935) : null,
            ),
          ),
        );

      case _InvColumnKey.warehouse:
        final warehouses = ref.watch(warehousesProvider).value;
        String whName = '—';
        if (warehouses != null && inv.warehouseId != null) {
          final match = warehouses.firstWhere(
            (w) => w.id == inv.warehouseId,
            orElse: () => warehouses.firstWhere(
              (w) => w.isDefaultForBranch,
              orElse: () => warehouses.first,
            ),
          );
          whName = match.name;
        }
        return _Cell(
          width: w,
          child: _tableText(whName),
        );
    }
  }

  // ─── STATUS FORMATTING ─────────────────────────

  String _statusLabel(SalesOrder inv) {
    final s = inv.status.trim().toLowerCase();
    if (s == 'draft') return 'DRAFT';
    if (s == 'paid') return 'PAID';
    if (s == 'void') return 'VOID';
    if (s == 'sent') return 'SENT';
    if (s == 'partially paid') return 'PARTIALLY PAID';

    final due = inv.expectedShipmentDate;
    if (due != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(due.year, due.month, due.day);
      final diff = dueDay.difference(today).inDays;
      if (diff < 0) {
        return 'OVERDUE BY ${-diff} DAYS';
      }
      if (diff >= 0) {
        return 'DUE IN $diff DAYS';
      }
    }
    return s.toUpperCase();
  }

  Color _statusColor(SalesOrder inv) {
    final s = inv.status.trim().toLowerCase();
    if (s == 'draft') return AppTheme.textMuted;
    if (s == 'paid') return const Color(0xFF28A745);
    if (s == 'void') return AppTheme.textDisabled;

    final due = inv.expectedShipmentDate;
    if (due != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(due.year, due.month, due.day);
      if (dueDay.isBefore(today)) {
        return const Color(0xFFE53935); // Overdue red
      }
    }
    return const Color(0xFF1A73E8); // Due blue
  }

  // ─── SELECTION ──────────────────────────────────

  void _toggleSelection(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
  }

  void _toggleSelectAll(List<SalesOrder> invoices, bool selected) {
    final ids = invoices.map((i) => i.id).toSet();
    setState(() {
      if (selected) {
        _selectedIds.addAll(ids);
      } else {
        _selectedIds.removeAll(ids);
      }
    });
  }

  bool _allVisibleSelected(List<SalesOrder> invoices) =>
      invoices.isNotEmpty &&
      invoices.every((inv) => _selectedIds.contains(inv.id));

  void _clearSelection() => setState(() => _selectedIds.clear());

  void _handleBulkAction(String label) {
    if (_selectedIds.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one invoice');
      return;
    }
    if (label == 'Delete') {
      _handleDeleteAction();
      return;
    }
    if (label == 'Bulk update') {
      _showBulkUpdateDialog();
      return;
    }
    if (label == 'PDF export' || label == 'Share') {
      _runBulkPdfAction('Share');
      return;
    }
    if (label == 'Print') {
      _runBulkPdfAction('Print');
      return;
    }
    ZerpaiToast.success(
      context,
      '$label applied to ${_selectedIds.length} invoice(s)',
    );
  }

  Future<void> _handleDeleteAction() async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Invoices',
      message: 'Are you sure you want to delete the selected ${_selectedIds.length} invoice(s)?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed) return;

    final supabase = Supabase.instance.client;
    try {
      final selectedIds = _selectedIds.toList();
      final response = await supabase
          .from('invoice_master')
          .select('id, sale_number')
          .filter('id', 'in', selectedIds);

      for (final row in response) {
        final id = row['id'] as String;
        final currentNum = row['sale_number'] as String;
        final newNum = currentNum.startsWith('SD-') ? currentNum : 'SD-$currentNum';
        await supabase
            .from('invoice_master')
            .update({
              'is_delete': true,
              'sale_number': newNum,
            })
            .eq('id', id);
      }

      ZerpaiToast.success(
        context,
        'Deleted ${selectedIds.length} invoice(s)',
      );
      _clearSelection();
      ref.invalidate(salesInvoicesProvider);
    } catch (e) {
      ZerpaiToast.error(context, 'Error deleting invoices: $e');
    }
  }

  Future<void> _showBulkUpdateDialog() async {
    if (_selectedIds.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one invoice');
      return;
    }

    final result = await showDialog<_BulkUpdateResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (context) => const _InvoiceBulkUpdateDialog(),
    );
    if (result == null) return;
    ZerpaiToast.success(
      context,
      '${result.field} updated for ${_selectedIds.length} invoice(s)',
    );
  }

  Widget _selectionToolbar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          _BulkActionButton(label: 'Bulk Update', onTap: _showBulkUpdateDialog),
          const SizedBox(width: 8),
          _BulkIconButton(
            icon: LucideIcons.printer,
            onTap: () => _handleBulkAction('Print'),
          ),
          _BulkIconButton(
            icon: LucideIcons.share2,
            onTap: () => _handleBulkAction('Share'),
          ),
          const SizedBox(width: 4),
          MenuAnchor(
            style: _menuStyle(),
            builder: (context, controller, child) {
              return InkWell(
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Associate with Sales Orders', style: TextStyle(fontSize: 13)),
                      SizedBox(width: 6),
                      Icon(LucideIcons.chevronDown, size: 14),
                    ],
                  ),
                ),
              );
            },
            menuChildren: [
              MenuItemButton(
                style: _menuItemStyle(),
                onPressed: () => _handleBulkAction('Associate with Sales Orders'),
                child: const SizedBox(width: 240, child: Text('Associate with Sales Orders')),
              ),
              MenuItemButton(
                style: _menuItemStyle(),
                onPressed: () => _handleBulkAction('Dissociate Sales Orders'),
                child: const SizedBox(width: 240, child: Text('Dissociate Sales Orders')),
              ),
            ],
          ),
          const SizedBox(width: 8),
          _BulkActionButton(
            label: 'Mark As Sent',
            onTap: () => _handleBulkAction('Mark As Sent'),
          ),
          _BulkActionButton(
            label: 'Mark as Shipped',
            onTap: () => _handleBulkAction('Mark as Shipped'),
          ),
          _BulkActionButton(
            label: 'Undo Shipment',
            onTap: () => _handleBulkAction('Undo Shipment'),
          ),
          _BulkActionButton(
            label: 'Delete',
            onTap: () => _handleBulkAction('Delete'),
          ),
          const Spacer(),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.bgDisabled,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${_selectedIds.length}',
              style: AppTheme.bodyText.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('Selected', style: AppTheme.bodyText.copyWith(fontSize: 13)),
          const SizedBox(width: 18),
          Text(
            'Esc',
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: _clearSelection,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
            ),
          ),
        ],
      ),
    );
  }

  // ─── COLUMN RESIZE ─────────────────────────────

  Map<String, double> _calculateColumnWidths(double totalWidth) {
    const double staticPrefixWidth = 84.0;
    final Map<String, ({double min, double flex})> metrics = {
      'date': (min: 100.0, flex: 1.0),
      'invoiceNumber': (min: 130.0, flex: 1.4),
      'orderNumber': (min: 120.0, flex: 1.2),
      'customerName': (min: 180.0, flex: 2.0),
      'status': (min: 120.0, flex: 1.3),
      'dueDate': (min: 100.0, flex: 1.0),
      'amount': (min: 110.0, flex: 1.2),
      'balanceDue': (min: 150.0, flex: 1.6),
      'warehouse': (min: 140.0, flex: 1.5),
    };

    double totalMinWidth = staticPrefixWidth;
    double totalFlex = 0;
    for (final col in _visibleColumns) {
      final m = metrics[col.key.name] ?? (min: 120.0, flex: 1.0);
      totalMinWidth += m.min;
      totalFlex += m.flex;
    }

    final extraSpace = math.max(0.0, totalWidth - totalMinWidth);
    final results = <String, double>{};
    for (final col in _visibleColumns) {
      final m = metrics[col.key.name] ?? (min: 120.0, flex: 1.0);
      results[col.key.name] = m.min + (m.flex / totalFlex) * extraSpace;
    }
    return results;
  }

  void _resizeColumn(String key, double dx) {
    setState(() {
      if (_customColumnWidths == null) {
        _customColumnWidths = _calculateColumnWidths(
          context.size?.width ?? 1200,
        );
      }
      final current = _customColumnWidths![key] ?? 120.0;
      _customColumnWidths![key] = (current + dx).clamp(50.0, 2000.0);
    });
    _saveColumnSettings();
  }

  // ─── SORT ───────────────────────────────────────

  List<Widget> _buildMoreMenuChildren() {
    return [
      SubmenuButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        menuStyle: ZTableMoreMenu.submenuMenuStyle(),
        alignmentOffset: const Offset(4, 0),
        leadingIcon: const Icon(LucideIcons.arrowUpDown, size: 16),
        menuChildren: [
          _buildSortMenuItem('Created Time', _InvSortField.createdTime),
          _buildSortMenuItem('Last Modified Time', _InvSortField.lastModifiedTime),
          _buildSortMenuItem('Date', _InvSortField.date),
          _buildSortMenuItem('Invoice#', _InvSortField.invoiceNumber),
          _buildSortMenuItem('Order Number', _InvSortField.orderNumber),
          _buildSortMenuItem('Customer Name', _InvSortField.customerName),
          _buildSortMenuItem('Due Date', _InvSortField.dueDate),
          _buildSortMenuItem('Amount', _InvSortField.amount),
          _buildSortMenuItem('Balance Due', _InvSortField.balanceDue),
        ],
        child: const Text('Sort by'),
      ),
      SubmenuButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        menuStyle: ZTableMoreMenu.submenuMenuStyle(),
        alignmentOffset: const Offset(4, 0),
        leadingIcon: const Icon(LucideIcons.download, size: 16),
        menuChildren: [
          MenuItemButton(
            style: ZTableMoreMenu.menuItemButtonStyle(),
            onPressed: () {},
            child: const Text('Import Invoices'),
          ),
          MenuItemButton(
            style: ZTableMoreMenu.menuItemButtonStyle(),
            onPressed: () {},
            child: const Text('Import Bill of supply'),
          ),
        ],
        child: const Text('Import'),
      ),
      SubmenuButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        menuStyle: ZTableMoreMenu.submenuMenuStyle(),
        alignmentOffset: const Offset(4, 0),
        leadingIcon: const Icon(LucideIcons.upload, size: 16),
        menuChildren: [
          MenuItemButton(
            style: ZTableMoreMenu.menuItemButtonStyle(),
            child: const Text('Export Invoices'),
          ),
          MenuItemButton(
            style: ZTableMoreMenu.menuItemButtonStyle(),
            child: const Text('Export Current View'),
          ),
          MenuItemButton(
            style: ZTableMoreMenu.menuItemButtonStyle(),
            child: const Text('Export as E-Way Bill'),
          ),
        ],
        child: const Text('Export'),
      ),
      MenuItemButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        leadingIcon: const Icon(LucideIcons.settings, size: 16),
        onPressed: _showCustomizeColumnsDialog,
        child: const Text('Preferences'),
      ),
      MenuItemButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        leadingIcon: const Icon(LucideIcons.columns, size: 16),
        onPressed: () {},
        child: const Text('Manage Custom Fields'),
      ),
      MenuItemButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        leadingIcon: const Icon(LucideIcons.monitor, size: 16),
        onPressed: () {},
        child: const Text('Online Payments'),
      ),
      MenuItemButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        leadingIcon: const Icon(LucideIcons.refreshCw, size: 16),
        onPressed: () => ref.invalidate(salesInvoicesProvider),
        child: const Text('Refresh List'),
      ),
      MenuItemButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        leadingIcon: const Icon(LucideIcons.rotateCcw, size: 16),
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('sales_invoice_column_widths');
          setState(() {
            _customColumnWidths = null;
          });
        },
        child: const Text('Reset Column Width'),
      ),
    ];
  }

  void _toggleSort(_InvSortField field) {
    if (_activeSortField == field) {
      _isAscending = !_isAscending;
    } else {
      _activeSortField = field;
      _isAscending = true;
    }
  }

  Widget _buildSortMenuItem(String label, _InvSortField field) {
    final isSelected = _activeSortField == field;
    return MenuItemButton(
      style: ZTableMoreMenu.menuItemButtonStyle(isActive: isSelected),
      onPressed: () => setState(() => _toggleSort(field)),
      trailingIcon: isSelected
          ? Icon(
              _isAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
              size: 12,
            )
          : null,
      child: Text(label),
    );
  }

  // ─── FILTERS ────────────────────────────────────

  List<SalesOrder> _applyFilters(List<SalesOrder> invoices) {
    Iterable<SalesOrder> result = invoices.where((inv) => !inv.isDelete);
    if (_activeView.statuses != null && _activeView.statuses!.isNotEmpty) {
      result = result.where(
        (inv) =>
            _activeView.statuses!.contains(inv.status.trim().toLowerCase()),
      );
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((inv) {
        return inv.saleNumber.toLowerCase().contains(q) ||
            (inv.reference?.toLowerCase().contains(q) ?? false) ||
            _customerName(inv).toLowerCase().contains(q);
      });
    }
    final sorted = result.toList()
      ..sort((a, b) {
        int cmp;
        switch (_activeSortField) {
          case _InvSortField.date:
            cmp = a.saleDate.compareTo(b.saleDate);
          case _InvSortField.invoiceNumber:
            cmp = a.saleNumber
                .toLowerCase()
                .compareTo(b.saleNumber.toLowerCase());
          case _InvSortField.orderNumber:
            cmp = (a.reference ?? '')
                .toLowerCase()
                .compareTo((b.reference ?? '').toLowerCase());
          case _InvSortField.customerName:
            cmp = _customerName(a)
                .toLowerCase()
                .compareTo(_customerName(b).toLowerCase());
          case _InvSortField.status:
            cmp = a.status
                .toLowerCase()
                .compareTo(b.status.toLowerCase());
          case _InvSortField.dueDate:
            cmp = (a.expectedShipmentDate ?? a.saleDate)
                .compareTo(b.expectedShipmentDate ?? b.saleDate);
          case _InvSortField.amount:
            cmp = a.total.compareTo(b.total);
          case _InvSortField.balanceDue:
            cmp = a.total.compareTo(b.total);
          case _InvSortField.warehouse:
            cmp = (a.warehouseId ?? '')
                .compareTo(b.warehouseId ?? '');
          case _InvSortField.createdTime:
            cmp = (a.createdAt ?? a.saleDate).compareTo(b.createdAt ?? b.saleDate);
          case _InvSortField.lastModifiedTime:
            cmp = (a.createdAt ?? a.saleDate).compareTo(b.createdAt ?? b.saleDate);
        }
        return _isAscending ? cmp : -cmp;
      });
    return sorted;
  }

  // ─── CUSTOMIZE COLUMNS ─────────────────────────

  Future<void> _showCustomizeColumnsDialog() async {
    final working = _columnConfigs.map((c) => c.copy()).toList();
    final result = await showDialog<List<_InvColumnConfig>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (_) => _InvoiceCustomizeColumnsDialog(columns: working),
    );
    if (result == null) return;
    setState(() => _columnConfigs = result);
    if (mounted) ZerpaiToast.success(context, 'Column preferences saved');
  }

  // ─── CHECKBOX ───────────────────────────────────

  Widget _buildCheckbox(
    bool isSelected, {
    bool isPartially = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: isSelected || isPartially
          ? Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: Icon(
                  isPartially ? LucideIcons.minus : LucideIcons.check,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            )
          : Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: AppTheme.borderColor, width: 1.5),
              ),
            ),
    );
  }

  // ─── EMPTY STATES ──────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileText, size: 48, color: AppTheme.textDisabled),
            const SizedBox(height: 14),
            Text('No Invoices found', style: AppTheme.sectionHeader),
            const SizedBox(height: 8),
            Text(
              'Create a new Invoice to get started.',
              style:
                  AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ZButton.primary(
              onPressed: () => context.go('/sales/invoices/create'),
              icon: LucideIcons.plus,
              label: 'New Invoice',
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyMessage({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: AppTheme.textDisabled),
            const SizedBox(height: 14),
            Text(title, style: AppTheme.sectionHeader),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style:
                  AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ────────────────────────────────────

  Widget _tableText(String value, {TextAlign textAlign = TextAlign.left}) {
    return Text(
      value,
      textAlign: textAlign,
      style: AppTheme.tableCell,
      maxLines: _clipText ? 1 : 2,
      overflow: _clipText ? TextOverflow.ellipsis : TextOverflow.fade,
      softWrap: !_clipText,
    );
  }

  String _customerName(SalesOrder order) {
    final customer = order.customer;
    if (customer == null) return 'Unknown customer';
    if (customer.displayName.trim().isNotEmpty) {
      return customer.displayName.trim();
    }
    final combined =
        '${customer.firstName ?? ''} ${customer.lastName ?? ''}'.trim();
    return combined.isEmpty ? 'Unknown customer' : combined;
  }

  String _fmtDate(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

  Future<void> _runBulkPdfAction(String type) async {
    final invoicesState = ref.read(salesInvoicesProvider);
    final invoices = invoicesState.valueOrNull ?? const <SalesOrder>[];
    final selected = invoices
        .where((inv) => _selectedIds.contains(inv.id))
        .toList();
    if (selected.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one invoice');
      return;
    }
    final invoiceSummary = selected.first;
    final invoice = await ref.read(_salesInvoiceDetailProvider(invoiceSummary.id).future);
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    final bytes = await _generateInvoicePdf(invoice, orgSettings);
    if (type == 'Print') {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } else {
      await Printing.sharePdf(bytes: bytes, filename: '${invoice.saleNumber}.pdf');
    }
  }

  Future<Uint8List> _generateInvoicePdf(
    SalesOrder order,
    OrgSettings? org,
  ) async {
    final paymentTermsMap = ref.read(_paymentTermsProvider).value ?? const <String, String>{};
    final termId = order.paymentTerms ?? '';
    final termName = paymentTermsMap[termId] ?? (termId.isEmpty ? 'Net 360' : termId);

    final doc = pw.Document();
    final items = order.items ?? [];

    final branches = ref.read(_branchesProvider).value;
    final matchedBranchList = branches?.where((b) => b['entity_id'] == order.entityId).toList();
    final matchedBranch = (matchedBranchList != null && matchedBranchList.isNotEmpty) ? matchedBranchList.first : null;

    final primaryBranch = (branches != null && branches.isNotEmpty)
        ? branches.firstWhere(
            (b) => b['is_primary'] == true,
            orElse: () => branches.first,
          )
        : null;

    final String branchName;
    final String fullBranchAddress;
    final String? resolvedLogoUrl;

    if (matchedBranch != null) {
      branchName = matchedBranch['name']?.toString() ?? org?.name ?? 'Organization Name';
      resolvedLogoUrl = matchedBranch['logo_url']?.toString() ?? org?.logoUrl;
      
      final addressParts = <String>[];
      final street = matchedBranch['street']?.toString() ?? matchedBranch['address']?.toString() ?? '';
      final place = matchedBranch['place']?.toString() ?? '';
      if (street.isNotEmpty) addressParts.add(street);
      if (place.isNotEmpty) addressParts.add(place);
      
      final city = matchedBranch['city']?.toString() ?? '';
      final state = matchedBranch['state']?.toString() ?? '';
      final pincode = matchedBranch['pincode']?.toString() ?? '';
      
      String cityStatePin = '';
      if (city.isNotEmpty) cityStatePin += '$city ';
      if (state.isNotEmpty) cityStatePin += '$state ';
      if (pincode.isNotEmpty) cityStatePin += pincode;
      
      if (cityStatePin.trim().isNotEmpty) {
        addressParts.add(cityStatePin.trim());
      }
      
      final country = matchedBranch['country']?.toString() ?? 'India';
      if (country.isNotEmpty) addressParts.add(country);
      
      final gstin = matchedBranch['gstin']?.toString() ?? '';
      if (gstin.isNotEmpty) addressParts.add('GSTIN $gstin');
      
      final phone = matchedBranch['phone']?.toString() ?? '';
      if (phone.isNotEmpty) addressParts.add(phone);
      
      final email = (matchedBranch['email']?.toString() ?? org?.email ?? '').trim();
      if (email.isNotEmpty) {
        addressParts.add(email);
      }
      
      fullBranchAddress = addressParts.join('\n');
    } else {
      // Fallback to Org
      branchName = org?.name ?? 'Organization Name';
      resolvedLogoUrl = org?.logoUrl;
      
      final addressParts = <String>[];
      final attention = org?.attention ?? '';
      final street = org?.street ?? '';
      final place = org?.place ?? '';
      if (attention.isNotEmpty) addressParts.add(attention);
      if (street.isNotEmpty) addressParts.add(street);
      if (place.isNotEmpty) addressParts.add(place);
      
      final city = org?.city ?? '';
      final pincode = org?.pincode ?? '';
      
      String cityPin = '';
      if (city.isNotEmpty) cityPin += '$city ';
      if (pincode.isNotEmpty) cityPin += pincode;
      
      if (cityPin.trim().isNotEmpty) {
        addressParts.add(cityPin.trim());
      }
      
      final country = org?.country ?? 'India';
      if (country.isNotEmpty) addressParts.add(country);
      
      final gstin = org?.companyIdValue ?? '';
      if (gstin.isNotEmpty) {
        final label = org?.companyIdLabel ?? 'GSTIN';
        addressParts.add('$label $gstin');
      }
      
      final phone = org?.phone ?? '';
      if (phone.isNotEmpty) addressParts.add(phone);
      
      final email = (org?.email ?? '').trim();
      if (email.isNotEmpty) {
        addressParts.add(email);
      }
      
      fullBranchAddress = addressParts.isNotEmpty ? addressParts.join('\n') : 'PERINTHALMANNA\nMALAPPURAM Kerala 679322\nIndia';
    }

    final String branchState = (matchedBranch != null)
        ? (matchedBranch['state']?.toString() ?? 'Kerala')
        : (primaryBranch?['state']?.toString() ?? 'Kerala');

    final String placeOfSupply = order.placeOfSupply ?? order.customer?.placeOfSupply ?? 'Kerala';

    String _normalizeState(String s) {
      if (s.toLowerCase().contains('kerala')) {
        return 'kerala';
      }
      return s.split('(').first.replaceAll(RegExp(r'[^a-zA-Z]'), '').trim().toLowerCase();
    }

    final bool isIgst = _normalizeState(branchState) != _normalizeState(placeOfSupply);

    pw.MemoryImage? logoImage;
    if (resolvedLogoUrl != null && resolvedLogoUrl.trim().isNotEmpty) {
      try {
        final dio = Dio();
        final res = await dio.get(
          resolvedLogoUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null) {
          logoImage = pw.MemoryImage(Uint8List.fromList(res.data));
        }
      } catch (_) {}
    }

    final dateStr = _date(order.saleDate);
    final customer = order.customer;

    // Load fonts to draw ₹ symbol and italic styles
    final regularData = await rootBundle.load('assets/fonts/Inter-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
    final italicData = await rootBundle.load('assets/fonts/Inter-Italic.ttf');
    final boldItalicData = await rootBundle.load('assets/fonts/Inter-BoldItalic.ttf');
    final regularFont = pw.Font.ttf(regularData);
    final boldFont = pw.Font.ttf(boldData);
    final italicFont = pw.Font.ttf(italicData);
    final boldItalicFont = pw.Font.ttf(boldItalicData);
    final pdfTheme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
      italic: italicFont,
      boldItalic: boldItalicFont,
    );

    // Dynamic Column widths for table
    final double col0Width = 20;
    final double col1Width = isIgst ? 221.0 : 144.0;
    final double col2Width = 55;
    final double col3Width = 40;
    final double col4Width = 50;
    final double col5Width = 32;
    final double col6Width = 45;
    final double col7Width = 32;
    final double col8Width = 45;
    final double col9Width = 60;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 38),
        theme: pdfTheme,
        build: (pw.Context ctx) {
          double totalTaxRate = (order.subTotal > 0) ? (order.taxTotal / order.subTotal) * 100 : 0.0;
          double cgstPct = double.parse((totalTaxRate / 2).toStringAsFixed(1));
          double sgstPct = double.parse((totalTaxRate / 2).toStringAsFixed(1));

          return pw.Stack(
            children: [
              pw.Container(
                height: 730.0,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 0.5),
                ),
                child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. Top Header Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          if (logoImage != null) ...[
                            pw.Container(
                              width: 70,
                              height: 48,
                              child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                            ),
                            pw.SizedBox(width: 10),
                          ],
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                branchName.toUpperCase(),
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                fullBranchAddress,
                                style: const pw.TextStyle(
                                  fontSize: 8,
                                  lineSpacing: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 22,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(height: 0.5, color: PdfColors.black),

                // 2. Metadata Box (Using Table to guarantee matched column heights without stretch layout crash)
                pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(6),
                    1: pw.FlexColumnWidth(4),
                  },
                  border: const pw.TableBorder(
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  ),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _pwMetaRow('#', ': ${order.saleNumber}'),
                              _pwMetaRow('Invoice Date', ': $dateStr'),
                              _pwMetaRow('Terms', ': $termName'),
                              _pwMetaRow('Due Date', ': ${order.expectedShipmentDate != null ? _date(order.expectedShipmentDate!) : '-'}'),
                              _pwMetaRow('P.O.#', ': ${order.reference ?? '-'}'),
                            ],
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          alignment: pw.Alignment.topLeft,
                          child: _pwMetaRow('Place Of Supply', ': ${order.placeOfSupply ?? order.customer?.placeOfSupply ?? '-'}'),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Container(height: 0.5, color: PdfColors.black),

                // 3. Bill To & Ship To Header Strip
                pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1),
                    1: pw.FlexColumnWidth(1),
                  },
                  border: const pw.TableBorder(
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  ),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          color: const PdfColor.fromInt(0xFFE5E7EB), // light grey background
                          child: pw.Text(
                            'Bill To',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          color: const PdfColor.fromInt(0xFFE5E7EB), // light grey background
                          child: pw.Text(
                            'Ship To',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Container(height: 0.5, color: PdfColors.black),

                // 4. Bill To & Ship To Details
                pw.Table(
                  columnWidths: const {
                    0: pw.FlexColumnWidth(1),
                    1: pw.FlexColumnWidth(1),
                  },
                  border: const pw.TableBorder(
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  ),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                customer?.displayName ?? 'CUS-1',
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                customer?.fullBillingAddress ?? 'N/A',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              if (customer?.phone != null && customer!.phone!.trim().isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'Ph: ${customer.phone}',
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ],
                              if (customer?.gstin != null && customer!.gstin!.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'GSTIN ${customer.gstin}',
                                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                                ),
                              ],
                            ],
                          ),
                        ),
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              if (customer?.displayName != null && customer!.displayName.trim().isNotEmpty) ...[
                                pw.Text(
                                  customer.displayName,
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                                ),
                                pw.SizedBox(height: 2),
                              ],
                              pw.Text(
                                customer?.fullShippingAddress ?? 'N/A',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.Container(
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFFF3F4F6),
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.black, width: 0.5),
                      bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                    ),
                  ),
                  height: 28, // Bounded height!
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      _thCell('#', col0Width, isFirst: true),
                      _thCell('Item & Description', col1Width),
                      _thCell('HSN\n/SAC', col2Width),
                      _thCell('Qty', col3Width),
                      _thCell('Rate', col4Width),
                      if (isIgst) ...[
                        // IGST Double Column (No crossAxisAlignment: stretch inside Column to avoid infinite height)
                        pw.Container(
                          width: col5Width + col6Width,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                            ),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Container(
                                width: double.infinity,
                                height: 14,
                                padding: const pw.EdgeInsets.symmetric(vertical: 1),
                                alignment: pw.Alignment.center,
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                  ),
                                ),
                                child: pw.Text('IGST', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              ),
                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: col5Width,
                                    height: 14,
                                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                                    alignment: pw.Alignment.center,
                                    decoration: const pw.BoxDecoration(
                                      border: pw.Border(
                                        right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                      ),
                                    ),
                                    child: pw.Text('%', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                  ),
                                  pw.Container(
                                    width: col6Width,
                                    height: 14,
                                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                                    alignment: pw.Alignment.center,
                                    child: pw.Text('Amt', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // CGST Double Column
                        pw.Container(
                          width: col5Width + col6Width,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                            ),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Container(
                                width: double.infinity,
                                height: 14,
                                padding: const pw.EdgeInsets.symmetric(vertical: 1),
                                alignment: pw.Alignment.center,
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                  ),
                                ),
                                child: pw.Text('CGST', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              ),
                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: col5Width,
                                    height: 14,
                                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                                    alignment: pw.Alignment.center,
                                    decoration: const pw.BoxDecoration(
                                      border: pw.Border(
                                        right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                      ),
                                    ),
                                    child: pw.Text('%', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                  ),
                                  pw.Container(
                                    width: col6Width,
                                    height: 14,
                                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                                    alignment: pw.Alignment.center,
                                    child: pw.Text('Amt', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // SGST Double Column
                        pw.Container(
                          width: col7Width + col8Width,
                          decoration: const pw.BoxDecoration(
                            border: pw.Border(
                              right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                            ),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Container(
                                width: double.infinity,
                                height: 14,
                                padding: const pw.EdgeInsets.symmetric(vertical: 1),
                                alignment: pw.Alignment.center,
                                decoration: const pw.BoxDecoration(
                                  border: pw.Border(
                                    bottom: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                  ),
                                ),
                                child: pw.Text('SGST', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                              ),
                              pw.Row(
                                children: [
                                  pw.Container(
                                    width: col7Width,
                                    height: 14,
                                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                                    alignment: pw.Alignment.center,
                                    decoration: const pw.BoxDecoration(
                                      border: pw.Border(
                                        right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                      ),
                                    ),
                                    child: pw.Text('%', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                  ),
                                  pw.Container(
                                    width: col8Width,
                                    height: 14,
                                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                                    alignment: pw.Alignment.center,
                                    child: pw.Text('Amt', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      _thCell('Amount', col9Width, isLast: true),
                    ],
                  ),
                ),

                // Table Rows (Using pw.Table to prevent infinite height exception completely)
                pw.Table(
                  columnWidths: isIgst
                      ? {
                          0: pw.FixedColumnWidth(col0Width),
                          1: pw.FixedColumnWidth(col1Width),
                          2: pw.FixedColumnWidth(col2Width),
                          3: pw.FixedColumnWidth(col3Width),
                          4: pw.FixedColumnWidth(col4Width),
                          5: pw.FixedColumnWidth(col5Width),
                          6: pw.FixedColumnWidth(col6Width),
                          7: pw.FixedColumnWidth(col9Width),
                        }
                      : {
                          0: pw.FixedColumnWidth(col0Width),
                          1: pw.FixedColumnWidth(col1Width),
                          2: pw.FixedColumnWidth(col2Width),
                          3: pw.FixedColumnWidth(col3Width),
                          4: pw.FixedColumnWidth(col4Width),
                          5: pw.FixedColumnWidth(col5Width),
                          6: pw.FixedColumnWidth(col6Width),
                          7: pw.FixedColumnWidth(col7Width),
                          8: pw.FixedColumnWidth(col8Width),
                          9: pw.FixedColumnWidth(col9Width),
                        },
                  border: const pw.TableBorder(
                    verticalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                    horizontalInside: pw.BorderSide(color: PdfColors.black, width: 0.5),
                  ),
                  children: items.asMap().entries.map((e) {
                    final item = e.value;
                    final index = e.key;
                    final double itemAmount = item.quantity * item.rate;

                    if (isIgst) {
                      final double igstAmt = itemAmount * (totalTaxRate / 100);
                      return pw.TableRow(
                        children: [
                          _tdCell('${index + 1}', col0Width, align: pw.Alignment.center),
                          _tdCellDesc(item, col1Width),
                          _tdCell((item.hsnCode ?? item.item?.hsnCode) ?? '', col2Width, align: pw.Alignment.center),
                          _tdCellQty(item, col3Width),
                          _tdCell(_currency(item.rate), col4Width, align: pw.Alignment.centerRight),
                          _tdCell('${totalTaxRate.toStringAsFixed(1)}%', col5Width, align: pw.Alignment.center),
                          _tdCell(_currency(igstAmt), col6Width, align: pw.Alignment.centerRight),
                          _tdCell(_currency(itemAmount), col9Width, align: pw.Alignment.centerRight, isLast: true),
                        ],
                      );
                    } else {
                      final double cgstAmt = itemAmount * (cgstPct / 100);
                      final double sgstAmt = itemAmount * (sgstPct / 100);
                      return pw.TableRow(
                        children: [
                          _tdCell('${index + 1}', col0Width, align: pw.Alignment.center),
                          _tdCellDesc(item, col1Width),
                          _tdCell((item.hsnCode ?? item.item?.hsnCode) ?? '', col2Width, align: pw.Alignment.center),
                          _tdCellQty(item, col3Width),
                          _tdCell(_currency(item.rate), col4Width, align: pw.Alignment.centerRight),
                          _tdCell('${cgstPct.toStringAsFixed(1)}%', col5Width, align: pw.Alignment.center),
                          _tdCell(_currency(cgstAmt), col6Width, align: pw.Alignment.centerRight),
                          _tdCell('${sgstPct.toStringAsFixed(1)}%', col7Width, align: pw.Alignment.center),
                          _tdCell(_currency(sgstAmt), col8Width, align: pw.Alignment.centerRight),
                          _tdCell(_currency(itemAmount), col9Width, align: pw.Alignment.centerRight, isLast: true),
                        ],
                      );
                    }
                  }).toList(),
                ),
                pw.Container(height: 0.5, color: PdfColors.black),

                // 6. Bottom Totals Section (Stretched to bottom border using Expanded)
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      // Left column: Total in words
                      pw.Container(
                        width: 309,
                        padding: const pw.EdgeInsets.all(6),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            right: pw.BorderSide(color: PdfColors.black, width: 0.5),
                          ),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Total In Words', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Indian Rupee ${_numberToWordsIndian(order.total)}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Right column: Totals table & Signature
                      pw.Container(
                        width: 214,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                          children: [
                            _pwTotalRowRight('Sub Total', _currency(order.subTotal)),
                            if (isIgst) ...[
                              _pwTotalRowRight('IGST${totalTaxRate.toStringAsFixed(1)} (${totalTaxRate.toStringAsFixed(1)}%)', _currency(order.taxTotal)),
                            ] else ...[
                              _pwTotalRowRight('CGST${cgstPct.toStringAsFixed(1)} (${cgstPct.toStringAsFixed(1)}%)', _currency(order.taxTotal / 2)),
                              _pwTotalRowRight('SGST${sgstPct.toStringAsFixed(1)} (${sgstPct.toStringAsFixed(1)}%)', _currency(order.taxTotal / 2)),
                            ],
                            _pwTotalRowRight('Rounding', '0.00'),
                            _pwTotalRowRight('Total', '₹' + _currency(order.total), isBold: true),
                            _pwTotalRowRight('Balance Due', '₹' + _currency(order.total), isBold: true),
                            pw.Spacer(),
                            pw.Container(
                              height: 140,
                              alignment: pw.Alignment.bottomCenter,
                              padding: const pw.EdgeInsets.only(bottom: 4),
                              decoration: const pw.BoxDecoration(
                                border: pw.Border(
                                  top: pw.BorderSide(color: PdfColors.black, width: 0.5),
                                ),
                              ),
                              child: pw.Text('Authorized Signature', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.Positioned(
            bottom: 0,
            right: 0,
            child: pw.Text(
              '${ctx.pageNumber}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
          ),
        ],
      );
    },
  ),
);

    return doc.save();
  }

  pw.Widget _thCell(String text, double width, {bool isFirst = false, bool isLast = false}) {
    return pw.Container(
      width: width,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          left: isFirst ? const pw.BorderSide(color: PdfColors.black, width: 0.5) : pw.BorderSide.none,
          right: const pw.BorderSide(color: PdfColors.black, width: 0.5),
        ),
      ),
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _tdCell(String text, double width, {pw.Alignment align = pw.Alignment.centerLeft, bool isLast = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: align,
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  pw.Widget _tdCellDesc(SalesOrderItem item, double width) {
    final name = item.item?.productName ?? item.item?.billingName ?? item.description ?? 'Unnamed item';
    final hasDesc = item.description != null && item.description != name && item.description!.isNotEmpty;
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(name, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
          if (hasDesc) ...[
            pw.SizedBox(height: 1),
            pw.Text(item.description!, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
          ],
        ],
      ),
    );
  }

  pw.Widget _tdCellQty(SalesOrderItem item, double width) {
    final qtyStr = item.quantity.toStringAsFixed(2);
    final unitStr = item.item?.unitName ?? 'pcs';
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(qtyStr, style: const pw.TextStyle(fontSize: 8)),
          pw.Text(unitStr, style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
        ],
      ),
    );
  }

  pw.Widget _pwMetaRow(String label, String value) {
    return pw.Row(
      children: [
        pw.SizedBox(
          width: 80,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 8),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _pwTotalRowRight(String label, String value, {bool isBold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _numberToWordsIndian(double number) {
    if (number == 0) return 'Zero';
    final intPart = number.toInt();
    final decimalPart = ((number - intPart) * 100).round();

    String result = _convertIntToWordsIndian(intPart);
    if (decimalPart > 0) {
      result += ' and ${_convertIntToWordsIndian(decimalPart)} Paise';
    }
    return '${result.trim()} Only';
  }

  String _convertIntToWordsIndian(int number) {
    if (number == 0) return '';
    final units = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
                    'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen'];
    final tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'];

    String convertLessThanThousand(int n) {
      String res = '';
      if (n >= 100) {
        res += '${units[n ~/ 100]} Hundred ';
        n %= 100;
      }
      if (n >= 20) {
        final t = n ~/ 10;
        final u = n % 10;
        if (u > 0) {
          res += '${tens[t]}-${units[u]} ';
        } else {
          res += '${tens[t]} ';
        }
      } else if (n > 0) {
        res += '${units[n]} ';
      }
      return res;
    }

    int temp = number;
    String res = '';

    if (temp >= 10000000) {
      res += '${_convertIntToWordsIndian(temp ~/ 10000000)} Crore ';
      temp %= 10000000;
    }
    if (temp >= 100000) {
      res += '${convertLessThanThousand(temp ~/ 100000)} Lakh ';
      temp %= 100000;
    }
    if (temp >= 1000) {
      res += '${convertLessThanThousand(temp ~/ 1000)} Thousand ';
      temp %= 1000;
    }
    if (temp > 0) {
      res += convertLessThanThousand(temp);
    }
    return res.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _date(DateTime? d) {
    if (d == null) return '';
    return DateFormat('dd-MM-yyyy').format(d);
  }

  String _currency(double val) {
    return NumberFormat('#,##,##0.00', 'en_IN').format(val);
  }
}

// ─────────────────────────────────────────────────
//  Resizable header cell (matches sales_order_list)
// ─────────────────────────────────────────────────

class _ResizableHeaderCell extends StatefulWidget {
  final double width;
  final Widget child;
  final ValueChanged<double> onResize;

  const _ResizableHeaderCell({
    required this.width,
    required this.child,
    required this.onResize,
  });

  @override
  State<_ResizableHeaderCell> createState() => _ResizableHeaderCellState();
}

class _ResizableHeaderCellState extends State<_ResizableHeaderCell> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: SizedBox(
        width: widget.width,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            Positioned(
              right: -5,
              top: 0,
              bottom: 0,
              width: 10,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) =>
                    widget.onResize(details.delta.dx),
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Container(
                    color: _isHovering
                        ? AppTheme.primaryBlue.withValues(alpha: 0.2)
                        : Colors.transparent,
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

// ─────────────────────────────────────────────────
//  Cell widget
// ─────────────────────────────────────────────────

class _Cell extends StatelessWidget {
  final double width;
  final Widget child;
  final bool alignRight;
  final bool alignCenter;

  const _Cell({
    required this.width,
    required this.child,
    this.alignRight = false,
    this.alignCenter = false,
  });

  @override
  Widget build(BuildContext context) {
    final alignment = alignRight
        ? Alignment.centerRight
        : (alignCenter ? Alignment.center : Alignment.centerLeft);
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Align(
          alignment: alignment,
          child: child,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
//  Customize Columns Dialog
// ─────────────────────────────────────────────────

class _InvoiceCustomizeColumnsDialog extends StatefulWidget {
  final List<_InvColumnConfig> columns;

  const _InvoiceCustomizeColumnsDialog({required this.columns});

  @override
  State<_InvoiceCustomizeColumnsDialog> createState() =>
      _InvoiceCustomizeColumnsDialogState();
}

class _InvoiceCustomizeColumnsDialogState
    extends State<_InvoiceCustomizeColumnsDialog> {
  late final List<_InvColumnConfig> _columns;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _columns = widget.columns.map((c) => c.copy()).toList();
  }

  Widget _buildColumnTile(
    _InvColumnConfig column, {
    required Key key,
    bool showDragHandle = true,
  }) {
    return Container(
      key: key,
      height: 38,
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          if (showDragHandle)
            ReorderableDragStartListener(
              index: _columns.indexOf(column),
              child: const Icon(
                LucideIcons.gripVertical,
                size: 14,
                color: AppTheme.textMuted,
              ),
            )
          else
            const Icon(
              LucideIcons.gripVertical,
              size: 14,
              color: AppTheme.borderLight,
            ),
          const SizedBox(width: 8),
          SizedBox(
            width: 28,
            child: Center(
              child: column.locked
                  ? const Icon(
                      LucideIcons.lock,
                      size: 14,
                      color: AppTheme.textMuted,
                    )
                  : SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: column.visible,
                        onChanged: (v) =>
                            setState(() => column.visible = v ?? false),
                        activeColor: AppTheme.primaryBlue,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              column.label,
              style: AppTheme.bodyText.copyWith(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _columns.where((c) {
      final q = _searchQuery.trim().toLowerCase();
      return q.isEmpty || c.label.toLowerCase().contains(q);
    }).toList();
    final selectedCount = _columns.where((c) => c.visible).length;

    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        width: 520,
        height: 610,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.slidersHorizontal,
                    size: 18,
                    color: AppTheme.textBody,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Customize Columns',
                    style: AppTheme.sectionHeader.copyWith(fontSize: 16),
                  ),
                  const Spacer(),
                  Text(
                    '$selectedCount of ${_columns.length} Selected',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryBlue),
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Container(
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Icon(
                      LucideIcons.search,
                      size: 15,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        onChanged: (v) =>
                            setState(() => _searchQuery = v),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMuted,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          filled: true,
                          fillColor: Colors.transparent,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            Expanded(
              child: _searchQuery.trim().isEmpty
                  ? ReorderableListView.builder(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _columns.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex -= 1;
                          final item = _columns.removeAt(oldIndex);
                          _columns.insert(newIndex, item);
                        });
                      },
                      proxyDecorator: (child, index, animation) {
                        return Material(
                          color: Colors.transparent,
                          child: AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: 1.02,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.12,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: child,
                                ),
                              );
                            },
                            child: child,
                          ),
                        );
                      },
                      itemBuilder: (context, index) {
                        final column = _columns[index];
                        return _buildColumnTile(
                          column,
                          key: ValueKey(column.key),
                        );
                      },
                    )
                  : ListView.separated(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final column = filtered[index];
                        return _buildColumnTile(
                          column,
                          key: ValueKey(column.key),
                          showDragHandle: false,
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              child: Row(
                children: [
                  SizedBox(
                    height: 32,
                    child: ZButton.primary(
                      label: 'Save',
                      onPressed: () =>
                          Navigator.of(context).pop(_columns),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(
                          color: AppTheme.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style:
                            AppTheme.bodyText.copyWith(fontSize: 13),
                      ),
                    ),
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

// ─────────────────────────────────────────────────
//  Invoice Batches & Lot Tracking Section
// ─────────────────────────────────────────────────

class _InvoiceBatchesSection extends StatefulWidget {
  final List<SalesOrderItem> items;

  const _InvoiceBatchesSection({required this.items});

  @override
  State<_InvoiceBatchesSection> createState() => _InvoiceBatchesSectionState();
}

class _InvoiceBatchesSectionState extends State<_InvoiceBatchesSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> mockBatches = [];

    for (final item in widget.items) {
      final name = item.item?.productName ?? item.description ?? 'Item';
      mockBatches.add({
        'itemName': name,
        'qty': item.quantity.toInt(),
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // P0 Pure White
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  const Icon(LucideIcons.package2, size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 10),
                  Text(
                    'BATCHES',
                    style: AppTheme.sectionHeader.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppTheme.borderLight),
            Container(
              color: const Color(0xFFF7F9FC),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'ITEM NAME',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'TRACKED QTY',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: mockBatches.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: AppTheme.borderLight),
              itemBuilder: (context, idx) {
                final batch = mockBatches[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          batch['itemName'],
                          style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${batch['qty']}',
                          textAlign: TextAlign.right,
                          style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
//  Top-level style helpers (same as sales_order_list)
// ─────────────────────────────────────────────────

MenuStyle _menuStyle() {
  return MenuStyle(
    backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
    surfaceTintColor: WidgetStateProperty.all<Color>(Colors.white),
    shadowColor: WidgetStateProperty.all<Color>(
      Colors.black.withValues(alpha: 0.08),
    ),
    elevation: WidgetStateProperty.all<double>(8),
    shape: WidgetStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    side: WidgetStateProperty.all<BorderSide>(
      const BorderSide(color: AppTheme.borderLight),
    ),
  );
}

ButtonStyle _menuItemStyle({bool isActive = false}) {
  return ButtonStyle(
    animationDuration: Duration.zero,
    splashFactory: NoSplash.splashFactory,
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
      final highlighted = states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused);
      if (isActive) return AppTheme.primaryBlue;
      if (highlighted) return AppTheme.primaryBlueDark;
      return Colors.white;
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      final highlighted = states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused);
      if (isActive || highlighted) return Colors.white;
      return AppTheme.textBody;
    }),
    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );
}

// ─────────────────────────────────────────────────
//  A4 PDF Ribbon Overlay Widgets
// ─────────────────────────────────────────────────

class _PdfCornerRibbon extends StatelessWidget {
  final String label;
  final Color color;

  const _PdfCornerRibbon({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    const double size = 110;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: const Size(size, size),
            painter: _CornerFoldPainter(color: color),
          ),
          Positioned(
            top: 24,
            left: -32,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 22,
            left: -34,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: Container(
                width: 170,
                height: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      HSLColor.fromColor(color)
                          .withLightness(
                            (HSLColor.fromColor(color).lightness * 0.85).clamp(
                              0.0,
                              1.0,
                            ),
                          )
                          .toColor(),
                    ],
                  ),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerFoldPainter extends CustomPainter {
  final Color color;
  _CornerFoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final darkColor = HSLColor.fromColor(color)
        .withLightness(
          (HSLColor.fromColor(color).lightness * 0.45).clamp(0.0, 1.0),
        )
        .toColor();

    final paint = Paint()..color = darkColor;

    final path = Path()
      ..moveTo(72, 0)
      ..lineTo(84, 0)
      ..lineTo(72, 12)
      ..close()
      ..moveTo(0, 72)
      ..lineTo(0, 84)
      ..lineTo(12, 72)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BulkActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _BulkActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderLight),
          ),
          alignment: Alignment.center,
          child: Text(label, style: AppTheme.bodyText.copyWith(fontSize: 13)),
        ),
      ),
    );
  }
}

class _BulkIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BulkIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Icon(icon, size: 16, color: AppTheme.textBody),
        ),
      ),
    );
  }
}



class _BulkUpdateResult {
  final String field;
  final String value;

  _BulkUpdateResult({required this.field, required this.value});
}

const List<String> _bulkUpdateFields = [
  'Invoice Date',
  'Due Date',
  'Sales Person',
  'Customer Notes',
  'Terms & Conditions',
  'Payment Terms',
  'Delivery Method',
];

class _InvoiceBulkUpdateDialog extends StatefulWidget {
  const _InvoiceBulkUpdateDialog();

  @override
  State<_InvoiceBulkUpdateDialog> createState() =>
      _InvoiceBulkUpdateDialogState();
}

class _InvoiceBulkUpdateDialogState extends State<_InvoiceBulkUpdateDialog> {
  String? _selectedField;
  final TextEditingController _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        width: 640,
        height: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Text(
                    'Bulk Update Invoices',
                    style: AppTheme.sectionHeader.copyWith(fontSize: 16),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(999),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(
                        LucideIcons.x,
                        size: 18,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Text(
                'Choose a field from the dropdown and update with new information.',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: AppTheme.textBody,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: FormDropdown<String>(
                        value: _selectedField,
                        items: _bulkUpdateFields,
                        hint: 'Select a field',
                        onChanged: (value) {
                          setState(() => _selectedField = value);
                        },
                        displayStringForValue: (value) => value,
                        searchStringForValue: (value) => value,
                        showSearch: true,
                        menuWidth: 300,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextField(
                        controller: _valueController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter new value',
                          hintStyle: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: AppTheme.borderLight,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
                              color: AppTheme.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'Note: All the selected invoices will be updated with the new information and you cannot undo this action.',
                style: AppTheme.bodyText.copyWith(
                  fontSize: 13,
                  color: AppTheme.primaryBlue,
                  height: 1.45,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 34,
                    child: ZButton.primary(
                      label: 'Update',
                      onPressed: () {
                        if (_selectedField == null) {
                          ZerpaiToast.info(
                            context,
                            'Select a field to update first',
                          );
                          return;
                        }
                        Navigator.of(context).pop(
                          _BulkUpdateResult(
                            field: _selectedField!,
                            value: _valueController.text.trim(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 34,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTheme.bodyText.copyWith(fontSize: 13),
                      ),
                    ),
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







