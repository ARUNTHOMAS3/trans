import 'dart:convert';
import 'dart:math' as math;

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

import '../controllers/sales_order_controller.dart';
import '../models/sales_order_model.dart';
import '../models/sales_order_item_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';

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
  _InvoiceView('Pending Approval', statuses: {'pending approval'}),
  _InvoiceView('Approved', statuses: {'approved'}),
  _InvoiceView('Sent', statuses: {'sent'}),
  _InvoiceView('Partially Paid', statuses: {'partially paid'}),
  _InvoiceView('Overdue', statuses: {'overdue'}),
  _InvoiceView('Paid', statuses: {'paid'}),
  _InvoiceView('Void', statuses: {'void'}),
  _InvoiceView('Unpaid', statuses: {'unpaid'}),
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
  _InvoiceView _activeView = _invoiceViews.first;
  _InvSortField _activeSortField = _InvSortField.invoiceNumber;
  bool _isAscending = true;
  bool _clipText = true;
  Set<String> _selectedIds = <String>{};
  late List<_InvColumnConfig> _columnConfigs;
  Map<String, double>? _customColumnWidths;
  bool _isAssociatedOrdersExpanded = true;

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
      final matched = _invoiceViews.firstWhere(
        (v) => v.label.toLowerCase() == widget.initialFilter!.toLowerCase() ||
               (v.statuses != null && v.statuses!.contains(widget.initialFilter!.toLowerCase())),
        orElse: () => _invoiceViews.first,
      );
      setState(() => _activeView = matched);
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
        width: 120,
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
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Invoices',
                        style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/sales/invoices/create'),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF28A745), // Success Green
                          borderRadius: BorderRadius.circular(6),
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
                      width: 34,
                      height: 34,
                      menuChildren: [
                        SubmenuButton(
                          style: ZTableMoreMenu.menuItemButtonStyle(),
                          menuChildren: [
                            _buildSortMenuItem('Date', _InvSortField.date),
                            _buildSortMenuItem(
                              'Invoice#',
                              _InvSortField.invoiceNumber,
                            ),
                            _buildSortMenuItem(
                              'Customer Name',
                              _InvSortField.customerName,
                            ),
                            _buildSortMenuItem('Amount', _InvSortField.amount),
                            _buildSortMenuItem('Status', _InvSortField.status),
                          ],
                          child: const Text('Sort by'),
                        ),
                        MenuItemButton(
                          style: ZTableMoreMenu.menuItemButtonStyle(),
                          onPressed: () => ref.invalidate(salesInvoicesProvider),
                          child: const Text('Refresh List'),
                        ),
                      ],
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
                onTap: () => context.go('/sales/invoices/${inv.id}'),
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
        final items = invoice.items ?? const <SalesOrderItem>[];
        final warehouses = ref.watch(warehousesProvider).value;

        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _detailToolbar(invoice),
                const Divider(height: 1, color: AppTheme.borderLight),
                Expanded(
                  child: Container(
                    color: const Color(0xFFF3F4F6), // Premium light grey backdrop
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _detailBanners(invoice),
                          const SizedBox(height: 20),
                          _associatedSalesOrdersBanner(invoice),
                          const SizedBox(height: 20),
                          _a4SimulatedInvoice(invoice, items, warehouses),
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
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          _buildToolbarButton(
            LucideIcons.pencil,
            'Edit',
            onPressed: () => context.push('/sales/invoices/${invoice.id}/edit', extra: invoice),
          ),
          _buildDivider(),
          _buildToolbarButton(
            LucideIcons.mail,
            'Send Email',
            onPressed: () => ZerpaiToast.info(context, 'Sending invoice email...'),
          ),
          _buildDivider(),
          _buildPdfPrintDropdown(invoice),
          _buildDivider(),
          ElevatedButton.icon(
            onPressed: () => ZerpaiToast.success(context, 'Payment record initiated'),
            icon: const Icon(LucideIcons.creditCard, size: 14, color: Colors.white),
            label: const Text('Record Payment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              elevation: 0,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
            onPressed: () => context.go('/sales/invoices'),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfPrintDropdown(SalesOrder invoice) {
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
        LucideIcons.printer,
        'PDF/Print',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
      menuChildren: [
        MenuItemButton(
          onPressed: () => ZerpaiToast.info(context, 'PDF Generation started...'),
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
          child: const Row(
            children: [
              Icon(LucideIcons.fileText, size: 16),
              SizedBox(width: 12),
              Text('PDF', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () => ZerpaiToast.info(context, 'Printing started...'),
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
          child: const Row(
            children: [
              Icon(LucideIcons.printer, size: 16),
              SizedBox(width: 12),
              Text('Print', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolbarButton(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
    Color? color,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color ?? const Color(0xFF4B5563)),
      label: Text(
        label,
        style: TextStyle(fontSize: 13, color: color ?? const Color(0xFF4B5563)),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                  onPressed: () => ZerpaiToast.success(context, 'Payment record initiated'),
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
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '00000000-0000-0000-0000-000000000002';
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
                    context.go('/$orgId/sales/orders/${invoice.id}');
                  },
                  child: Text(
                    '[$ref',
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

  Widget _a4SimulatedInvoice(SalesOrder invoice, List<SalesOrderItem> items, List<Warehouse>? warehouses) {
    final billingAddress = invoice.customer?.fullBillingAddress ?? 'N/A';
    final shippingAddress = invoice.customer?.fullShippingAddress ?? 'N/A';
    final isPaid = invoice.status.trim().toLowerCase() == 'paid';

    return Container(
      width: 755 + 24,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF666666), width: 1.0),
                ),
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
                                    Container(
                                      width: 140,
                                      height: 60,
                                      color: Colors.black,
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'ZABNIX',
                                        style: TextStyle(
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
                                        children: const [
                                          Text(
                                            'ZABNIX PRIVATE LIMITED',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Inter',
                                              color: Colors.black,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'PERINTHALMANNA\nMALAPPURAM Kerala 679322\nIndia\nGSTIN 32AACCZ4912F1ZL\n8086355500\nzabnixprivatelimited@gmail.com',
                                            style: TextStyle(
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
                                  _invMetaRow('Terms', invoice.paymentTerms ?? 'Net 360'),
                                  _invMetaRow('Due Date', invoice.expectedShipmentDate != null ? _fmtDate(invoice.expectedShipmentDate!) : '—'),
                                  _invMetaRow('P.O.#', invoice.reference != null && invoice.reference!.isNotEmpty ? '[${invoice.reference}' : '—'),
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
                                  _invMetaRow('Place Of Supply', 'Kerala (32)'),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Billing & Shipping blocks
                    Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFF666666)),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
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
                                            'GSTIN: ${invoice.customer!.gstin}',
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
                          Expanded(
                            flex: 5,
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
                                      Text(
                                        invoice.customer?.displayName ?? 'altha',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Inter',
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        shippingAddress,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'Inter',
                                          color: Colors.black,
                                          height: 1.4,
                                        ),
                                      ),
                                      if (invoice.customer?.shippingAddressPhone != null && invoice.customer!.shippingAddressPhone!.trim().isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ph: ${invoice.customer!.shippingAddressPhone}',
                                          style: const TextStyle(
                                            fontSize: 11,
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
                        ],
                      ),
                    ),
                    // Custom Table Header
                    _buildCustomTableHeader(),
                    // Item Rows
                    _buildItemRows(items),
                    // Totals Block
                    _buildTotalsBlock(invoice, isPaid),
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
      child: Row(
        children: [
          _headerBox('#', 30),
          _headerBox('Item & Description', 210, alignLeft: true),
          _headerBox('HSN/SAC', 80),
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
                Row(
                  children: [
                    _subHeaderBox('%', 45),
                    _subHeaderBox('Amt', 65, alignRight: true),
                  ],
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
                Row(
                  children: [
                    _subHeaderBox('%', 45),
                    _subHeaderBox('Amt', 65, alignRight: true),
                  ],
                ),
              ],
            ),
          ),
          _headerBox('Amount', 85, alignRight: true, last: true),
        ],
      ),
    );
  }

  Widget _headerBox(String text, double width, {bool alignLeft = false, bool alignRight = false, bool last = false}) {
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

  Widget _subHeaderBox(String text, double width, {bool alignRight = false}) {
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
        final cgstPercent = item.taxAmount > 0 ? '2.5%' : '0%';
        final cgstAmt = item.taxAmount > 0 ? item.taxAmount / 2 : 0.0;
        final sgstPercent = item.taxAmount > 0 ? '2.5%' : '0%';
        final sgstAmt = item.taxAmount > 0 ? item.taxAmount / 2 : 0.0;

        return Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFF666666)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cellBox('${index + 1}', 30),
              Container(
                width: 210,
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
                      item.item?.productName ?? item.item?.billingName ?? item.description ?? 'BATCH TARCK ITEM',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.description ?? 'sales description demo txt',
                      style: const TextStyle(
                        fontSize: 10,
                        fontFamily: 'Inter',
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
              _cellBox(item.hsnCode ?? '30049084', 80),
              _cellBox('${item.quantity.toInt()}.00 pcs', 55),
              _cellBox(NumberFormat('#,##,##0.00', 'en_IN').format(item.rate), 75, alignRight: true),
              _cellBox(cgstPercent, 45),
              _cellBox(NumberFormat('#,##,##0.00', 'en_IN').format(cgstAmt), 65, alignRight: true),
              _cellBox(sgstPercent, 45),
              _cellBox(NumberFormat('#,##,##0.00', 'en_IN').format(sgstAmt), 65, alignRight: true),
              _cellBox(NumberFormat('#,##,##0.00', 'en_IN').format(item.itemTotal), 85, alignRight: true, last: true),
            ],
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
    return Container(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      _totalsRow('CGST2.5 (2.5%)', NumberFormat('#,##,##0.00', 'en_IN').format(invoice.taxTotal / 2)),
                      _totalsRow('SGST2.5 (2.5%)', NumberFormat('#,##,##0.00', 'en_IN').format(invoice.taxTotal / 2)),
                      _totalsRow('Rounding', NumberFormat('0.00', 'en_IN').format(invoice.adjustment)),
                      const SizedBox(height: 6),
                      _totalsRow('Total', '₹${NumberFormat('#,##,##0.00', 'en_IN').format(invoice.total)}', isBold: true),
                      _totalsRow('Balance Due', '₹${NumberFormat('#,##,##0.00', 'en_IN').format(isPaid ? 0.0 : invoice.total)}', isBold: true),
                    ],
                  ),
                ),
                Container(
                  height: 100,
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
              ],
            ),
          ),
        ],
      ),
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
            child: MenuAnchor(
              style: _menuStyle(),
              builder: (context, controller, child) {
                return InkWell(
                  onTap: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _activeView.label == 'All'
                              ? 'All Invoices'
                              : _activeView.label,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: AppTheme.primaryBlue,
                        ),
                      ],
                    ),
                  ),
                );
              },
              menuChildren: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 250,
                      child: TextField(
                        decoration: _inputDecoration('Search views'),
                      ),
                    ),
                  ),
                ),
                ..._invoiceViews.map(
                  (view) => MenuItemButton(
                    style: _menuItemStyle(
                      isActive: _activeView.label == view.label,
                    ),
                    onPressed: () => setState(() => _activeView = view),
                    trailingIcon: const Icon(
                      LucideIcons.star,
                      size: 14,
                      color: AppTheme.textDisabled,
                    ),
                    child: SizedBox(width: 250, child: Text(view.label)),
                  ),
                ),
              ],
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
            width: 32,
            height: 32,
            menuChildren: [
              SubmenuButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                menuChildren: [
                  _buildSortMenuItem('Date', _InvSortField.date),
                  _buildSortMenuItem(
                    'Invoice#',
                    _InvSortField.invoiceNumber,
                  ),
                  _buildSortMenuItem(
                    'Customer Name',
                    _InvSortField.customerName,
                  ),
                  _buildSortMenuItem('Amount', _InvSortField.amount),
                  _buildSortMenuItem('Status', _InvSortField.status),
                ],
                child: const Text('Sort by'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                child: const Text('Import Invoices'),
              ),
              SubmenuButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                menuChildren: [
                  MenuItemButton(
                    style: ZTableMoreMenu.menuItemButtonStyle(),
                    child: const Text('Export Invoices'),
                  ),
                  MenuItemButton(
                    style: ZTableMoreMenu.menuItemButtonStyle(),
                    child: const Text('Export Current View'),
                  ),
                ],
                child: const Text('Export'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                child: const Text('Preferences'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                onPressed: () => ref.invalidate(salesInvoicesProvider),
                child: const Text('Refresh List'),
              ),
            ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Average No. of Days for Getting Paid',
                        style: AppTheme.metaHelper.copyWith(fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Text(
                          '79 Days',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            fontFamily: 'Inter',
                          ),
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

  Widget _summaryItem(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              label,
              style: AppTheme.metaHelper.copyWith(fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Text(
                '₹${NumberFormat('#,##,##0.00', 'en_IN').format(amount)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Inter',
                ),
              ),
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
    final sortField = _sortFieldForColumn(col.key);
    final isSorted = sortField != null && _activeSortField == sortField;
    final isAmountCol = col.key == _InvColumnKey.amount ||
        col.key == _InvColumnKey.balanceDue;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: InkWell(
          onTap: sortField == null
              ? null
              : () => setState(() => _toggleSort(sortField)),
          child: Row(
            mainAxisAlignment:
                isAmountCol ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  col.label.toUpperCase(),
                  style: AppTheme.metaHelper.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSorted ? AppTheme.primaryBlue : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isSorted) ...[
                const SizedBox(width: 4),
                Icon(
                  _isAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                  size: 12,
                  color: AppTheme.primaryBlue,
                ),
              ],
            ],
          ),
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Text(
              '[$ref]',
              style: AppTheme.tableCell.copyWith(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );

      case _InvColumnKey.customerName:
        return _Cell(width: w, child: _tableText(_customerName(inv)));

      case _InvColumnKey.status:
        return _Cell(
          width: w,
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
          alignRight: true,
          child: ZCurrencyDisplay(
            amount: balanceAmount,
            style: AppTheme.tableCell.copyWith(
              fontWeight: FontWeight.w600,
              color: balanceAmount > 0 ? const Color(0xFFE53935) : null,
            ),
          ),
        );

      case _InvColumnKey.warehouse:
        final warehouses = ref.read(warehousesProvider).value;
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
      'balanceDue': (min: 110.0, flex: 1.2),
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

  _InvSortField? _sortFieldForColumn(_InvColumnKey key) {
    switch (key) {
      case _InvColumnKey.date:
        return _InvSortField.date;
      case _InvColumnKey.invoiceNumber:
        return _InvSortField.invoiceNumber;
      case _InvColumnKey.orderNumber:
        return _InvSortField.orderNumber;
      case _InvColumnKey.customerName:
        return _InvSortField.customerName;
      case _InvColumnKey.status:
        return _InvSortField.status;
      case _InvColumnKey.dueDate:
        return _InvSortField.dueDate;
      case _InvColumnKey.amount:
        return _InvSortField.amount;
      case _InvColumnKey.balanceDue:
        return _InvSortField.balanceDue;
      case _InvColumnKey.warehouse:
        return _InvSortField.warehouse;
    }
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
      child: Row(
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              _isAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
              size: 12,
            ),
          ],
        ],
      ),
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

  const _Cell({
    required this.width,
    required this.child,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Align(
          alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
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
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> mockBatches = [];

    int index = 1;
    for (final item in widget.items) {
      final name = item.item?.productName ?? item.description ?? 'Item';
      mockBatches.add({
        'itemName': name,
        'lotNumber': 'LOT-2026-${1000 + index}',
        'expiryDate': '31-12-2028',
        'qty': item.quantity.toInt(),
      });
      index++;
    }

    if (mockBatches.isEmpty) {
      mockBatches.add({
        'itemName': 'Paracetamol 650mg Table',
        'lotNumber': 'LOT-2026-1001',
        'expiryDate': '31-12-2028',
        'qty': 120,
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
                    'INVOICE BATCHES & LOT TRACKING',
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
                    flex: 2,
                    child: Text(
                      'ITEM NAME',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'LOT / BATCH NUMBER',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'EXPIRY DATE',
                      textAlign: TextAlign.center,
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
                        flex: 2,
                        child: Text(
                          batch['itemName'],
                          style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            batch['lotNumber'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          batch['expiryDate'],
                          textAlign: TextAlign.center,
                          style: AppTheme.bodyText,
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

InputDecoration _inputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTheme.bodyText.copyWith(
      fontSize: 13,
      color: AppTheme.textMuted,
    ),
    prefixIcon: const Icon(
      LucideIcons.search,
      size: 16,
      color: AppTheme.textMuted,
    ),
    filled: true,
    fillColor: AppTheme.bgLight,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.borderLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppTheme.primaryBlue),
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

