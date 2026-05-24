import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/z_expandable_tabs.dart';
import 'package:zerpai_erp/shared/widgets/email_composer.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';
import 'package:zerpai_erp/shared/widgets/form_row.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_currency_display.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';

import '../controllers/sales_order_controller.dart';
import '../models/sales_order_item_model.dart';
import '../models/sales_order_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';

final _salesOrderDetailProvider = FutureProvider.family<SalesOrder, String>((
  ref,
  id,
) async {
  final api = ref.watch(salesOrderApiServiceProvider);
  final order = await api.getSalesOrderById(id);

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

class _SalesOrderView {
  final String label;
  final Set<String>? statuses;
  const _SalesOrderView(this.label, {this.statuses});
}

enum _SalesOrderSortField {
  createdTime,
  lastModifiedTime,
  date,
  salesOrderNumber,
  reference,
  customerName,
  orderStatus,
  invoiced,
  payment,
  packed,
  shipped,
  amount,
  deliveryMethod,
  expectedShipmentDate,
  companyName,
  invoicedAmount,
  location,
  picked,
  salesPerson,
  status,
}

enum _SalesOrderColumnKey {
  date,
  salesOrderNumber,
  reference,
  customerName,
  orderStatus,
  invoiced,
  payment,
  packed,
  shipped,
  amount,
  deliveryMethod,
  expectedShipmentDate,
  companyName,
  invoicedAmount,
  location,
  picked,
  salesPerson,
  status,
}

class _SalesOrderColumnConfig {
  final _SalesOrderColumnKey key;
  final String label;
  final double width;
  final bool locked;
  bool visible;

  _SalesOrderColumnConfig({
    required this.key,
    required this.label,
    required this.width,
    this.locked = false,
    required this.visible,
  });

  _SalesOrderColumnConfig copy() => _SalesOrderColumnConfig(
    key: key,
    label: label,
    width: width,
    locked: locked,
    visible: visible,
  );
}

const List<String> _bulkUpdateFields = [
  'PDF Template',
  'Order Date',
  'Exchange Rate',
  'Sales Person',
  'Customer Notes',
  'Terms & Conditions',
  'Payment Terms',
  'Delivery Method',
  'Reference #',
  'Expected Shipment Date',
];

const _salesOrderViews = <_SalesOrderView>[
  _SalesOrderView('All Sales Orders'),
  _SalesOrderView('All'),
  _SalesOrderView('Draft', statuses: {'draft'}),
  _SalesOrderView('Pending Approval', statuses: {'pending approval'}),
  _SalesOrderView('Approved', statuses: {'approved'}),
  _SalesOrderView('Confirmed', statuses: {'confirmed'}),
  _SalesOrderView('For Packaging', statuses: {'for packaging', 'packing'}),
  _SalesOrderView('To be Shipped', statuses: {'to be shipped'}),
  _SalesOrderView('Shipped', statuses: {'shipped'}),
  _SalesOrderView('Onhold', statuses: {'onhold', 'on hold'}),
  _SalesOrderView('Fulfilled', statuses: {'fulfilled'}),
  _SalesOrderView('Closed', statuses: {'closed'}),
  _SalesOrderView('Customer Viewed', statuses: {'customer viewed'}),
  _SalesOrderView('Manually Fulfilled', statuses: {'manually fulfilled'}),
  _SalesOrderView('For Invoicing', statuses: {'for invoicing'}),
  _SalesOrderView('Drop Shipped', statuses: {'drop shipped'}),
  _SalesOrderView('Backorder', statuses: {'backorder'}),
  _SalesOrderView('Marketplace', statuses: {'marketplace'}),
  _SalesOrderView('Void', statuses: {'void'}),
  _SalesOrderView('Invoiced', statuses: {'invoiced'}),
  _SalesOrderView('Shipped & Not Invoiced'),
  _SalesOrderView('Invoiced & Not Shipped'),
];

class SalesOrderOverviewScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;
  final String? initialSelectedId;

  /// Deep-link support: pre-select a status filter tab on load
  /// (e.g. 'draft', 'confirmed', 'closed').
  final String? initialFilter;

  const SalesOrderOverviewScreen({
    super.key,
    this.initialSearchQuery,
    this.initialSelectedId,
    this.initialFilter,
  });

  @override
  ConsumerState<SalesOrderOverviewScreen> createState() =>
      _SalesOrderOverviewScreenState();
}

class _SalesOrderOverviewScreenState
    extends ConsumerState<SalesOrderOverviewScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  final ScrollController _horizontalScrollController = ScrollController();
  String _searchQuery = '';
  _SalesOrderView _activeView = _salesOrderViews.first;
  _SalesOrderSortField _activeSortField = _SalesOrderSortField.salesOrderNumber;
  bool _isAscending = true;
  bool _clipText = true;
  Set<String> _selectedSaleIds = <String>{};
  late List<_SalesOrderColumnConfig> _columnConfigs;
  Map<String, double>? _customColumnWidths;

  List<_SalesOrderColumnConfig> get _visibleColumns =>
      _columnConfigs.where((column) => column.visible).toList();

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
      if (next != _searchQuery) {
        setState(() => _searchQuery = next);
      }
    });
    _loadColumnSettings();
  }

  Future<void> _loadColumnSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final widthsJson = prefs.getString('sales_order_column_widths');
      if (widthsJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(widthsJson);
        setState(() {
          _customColumnWidths = decoded.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading column settings: $e');
    }
  }

  Future<void> _saveColumnSettings() async {
    try {
      if (_customColumnWidths == null) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'sales_order_column_widths',
        jsonEncode(_customColumnWidths),
      );
    } catch (e) {
      debugPrint('Error saving column settings: $e');
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showUnavailableAction(String label) {
    if (!mounted) return;
    ZerpaiToast.info(context, '$label is not available yet');
  }

  void _editSalesOrder(SalesOrder order) {
    context.push('/sales/orders/${order.id}/edit', extra: order);
  }

  void _handleCreateAction(String actionLabel) {
    switch (actionLabel) {
      case 'Picklist':
        context.go(AppRoutes.picklistsCreate);
        return;
      case 'Package':
        context.go(AppRoutes.packagesCreate);
        return;
      case 'Shipment':
        context.go(AppRoutes.shipmentsCreate);
        return;
      case 'Instant Invoice':
        context.go(AppRoutes.salesInvoicesCreate);
        return;
      default:
        _showUnavailableAction(actionLabel);
    }
  }

  List<_SalesOrderColumnConfig> _defaultColumnConfigs() {
    return [
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.salesOrderNumber,
        label: 'Sales Order#',
        width: 130,
        locked: true,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.invoiced,
        label: 'Invoiced',
        width: 90,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.date,
        label: 'Date',
        width: 110,
        locked: true,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.customerName,
        label: 'Customer Name',
        width: 180,
        locked: true,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.orderStatus,
        label: 'Order Status',
        width: 110,
        locked: true,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.payment,
        label: 'Payment',
        width: 90,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.packed,
        label: 'Packed',
        width: 90,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.shipped,
        label: 'Shipped',
        width: 90,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.amount,
        label: 'Amount',
        width: 120,
        locked: true,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.deliveryMethod,
        label: 'Delivery Method',
        width: 160,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.picked,
        label: 'Picked',
        width: 90,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.reference,
        label: 'Reference#',
        width: 120,
        visible: false,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.expectedShipmentDate,
        label: 'Expected Shipment Date',
        width: 180,
        visible: false,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.companyName,
        label: 'Company Name',
        width: 170,
        visible: false,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.invoicedAmount,
        label: 'Invoiced Amount',
        width: 140,
        visible: false,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.location,
        label: 'Location',
        width: 160,
        visible: false,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.salesPerson,
        label: 'Sales person',
        width: 140,
        visible: false,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.status,
        label: 'Status',
        width: 110,
        visible: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesOrderControllerProvider);

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      searchFocusNode: _searchFocusNode,
      child: salesAsync.when(
        loading: () => const SalesOrderTableSkeleton(),
        error: (error, _) => _message(
          icon: LucideIcons.alertCircle,
          title: 'Unable to load sales orders',
          subtitle: '$error',
        ),
        data: (sales) {
          _selectedSaleIds = _selectedSaleIds
              .where((id) => sales.any((sale) => sale.id == id))
              .toSet();
          final filteredSales = _applyFilters(sales);
          final hasSelection = widget.initialSelectedId != null;

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1100;
              return Column(
                children: [
                  if (!hasSelection) ...[
                    _selectedSaleIds.isNotEmpty
                        ? _selectionToolbar()
                        : _toolbar(context, hasSelection),
                    const Divider(height: 1, color: AppTheme.borderLight),
                  ],
                  Expanded(
                    child: sales.isEmpty
                        ? _message(
                            icon: LucideIcons.receipt,
                            title: 'No sales orders yet',
                            subtitle:
                                'Create a sales order to begin tracking fulfillment.',
                          )
                        : filteredSales.isEmpty
                        ? _message(
                            icon: LucideIcons.searchX,
                            title: 'No matching orders',
                            subtitle: 'Adjust the active view or search term.',
                          )
                        : hasSelection
                        ? _workspace(filteredSales, sales, compact)
                        : _table(filteredSales),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _toolbar(BuildContext context, bool hasSelection) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          if (!hasSelection)
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
                                ? 'All Sales Orders'
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
                  ..._salesOrderViews.map(
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
                  const Divider(height: 1, color: AppTheme.borderLight),
                  MenuItemButton(
                    style: _menuItemStyle(),
                    onPressed: _showNewCustomViewDialog,
                    child: const SizedBox(
                      width: 250,
                      child: Text('+ New Custom View'),
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),
          if (!hasSelection) ...[
            TextButton(onPressed: () {}, child: const Text('View Order Stats')),
            const SizedBox(width: 12),
            ZButton.primary(
              onPressed: () => context.go('/sales/orders/create'),
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
                    _buildSortMenuItem(
                      'Created Time',
                      _SalesOrderSortField.createdTime,
                    ),
                    _buildSortMenuItem(
                      'Last Modified Time',
                      _SalesOrderSortField.lastModifiedTime,
                    ),
                    _buildSortMenuItem('Date', _SalesOrderSortField.date),
                    _buildSortMenuItem(
                      'Sales Order#',
                      _SalesOrderSortField.salesOrderNumber,
                    ),
                    _buildSortMenuItem(
                      'Reference#',
                      _SalesOrderSortField.reference,
                    ),
                  ],
                  child: const Text('Sort by'),
                ),
                MenuItemButton(
                  style: ZTableMoreMenu.menuItemButtonStyle(),
                  child: const Text('Import Sales Orders'),
                ),
                SubmenuButton(
                  style: ZTableMoreMenu.menuItemButtonStyle(),
                  menuChildren: [
                    MenuItemButton(
                      style: ZTableMoreMenu.menuItemButtonStyle(),
                      child: const Text('Export Sales Orders'),
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
                  child: const Text('Manage Custom Fields'),
                ),
                MenuItemButton(
                  style: ZTableMoreMenu.menuItemButtonStyle(),
                  onPressed: () => ref
                      .read(salesOrderControllerProvider.notifier)
                      .loadSalesOrders(),
                  child: const Text('Refresh List'),
                ),
              ],
            ),
            const SizedBox(width: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildSortMenuItem(String label, _SalesOrderSortField field) {
    final isSelected = _activeSortField == field;
    return MenuItemButton(
      style: ZTableMoreMenu.menuItemButtonStyle(isActive: isSelected),
      onPressed: () {
        setState(() => _toggleSort(field));
      },
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

  void _toggleSaleSelection(String saleId, bool selected) {
    setState(() {
      if (selected) {
        _selectedSaleIds.add(saleId);
      } else {
        _selectedSaleIds.remove(saleId);
      }
    });
  }

  void _toggleSelectAll(List<SalesOrder> sales, bool selected) {
    final ids = sales.map((sale) => sale.id).toSet();
    setState(() {
      if (selected) {
        _selectedSaleIds.addAll(ids);
      } else {
        _selectedSaleIds.removeAll(ids);
      }
    });
  }

  bool _allVisibleSelected(List<SalesOrder> sales) =>
      sales.isNotEmpty &&
      sales.every((sale) => _selectedSaleIds.contains(sale.id));

  void _clearSelection() {
    setState(() => _selectedSaleIds.clear());
  }

  void _handleBulkAction(String label) {
    if (_selectedSaleIds.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one sales order');
      return;
    }
    if (label == 'Delete') {
      _handleDeleteAction();
      return;
    }
    if (label == 'Mark as confirmed') {
      final salesState = ref.read(salesOrderControllerProvider);
      final sales = salesState.valueOrNull ?? const <SalesOrder>[];
      final selected = sales.where(
        (sale) => _selectedSaleIds.contains(sale.id),
      );
      final hasConfirmed = selected.any(
        (sale) => sale.status.trim().toLowerCase() == 'confirmed',
      );
      if (hasConfirmed) {
        ZerpaiToast.error(context, 'This item is already confirmed');
        return;
      }
    }
    if (label == 'PDF export') {
      _runBulkPdfExport();
      return;
    }
    if (label == 'Print') {
      _runBulkPrint();
      return;
    }
    ZerpaiToast.success(
      context,
      '$label applied to ${_selectedSaleIds.length} sales order(s)',
    );
  }

  Future<void> _handleDeleteAction() async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('sales_orders')
          .update({'is_delete': true})
          .filter('id', 'in', _selectedSaleIds.toList());

      ZerpaiToast.success(
        context,
        'Deleted ${_selectedSaleIds.length} sales order(s)',
      );
      _clearSelection();
      ref
          .read(salesOrderControllerProvider.notifier)
          .deleteOrdersLocally(_selectedSaleIds.toList());
    } catch (e) {
      ZerpaiToast.error(context, 'Error deleting sales orders: $e');
    }
  }

  MenuItemButton _detailActionMenuItem(String label, SalesOrder order) {
    return MenuItemButton(
      style: _menuItemStyle(),
      onPressed: () => _handleDetailAction(label, order),
      child: SizedBox(width: 240, child: Text(label)),
    );
  }

  void _handleDetailAction(String action, SalesOrder order) {
    if (action == 'Delete') {
      _deleteSingleOrder(order.id);
    } else {
      _showUnavailableAction(action);
    }
  }

  Future<void> _deleteSingleOrder(String id) async {
    final supabase = Supabase.instance.client;
    try {
      await supabase
          .from('sales_orders')
          .update({'is_delete': true})
          .eq('id', id);

      ZerpaiToast.success(context, 'Sales order deleted');
      ref.read(salesOrderControllerProvider.notifier).deleteOrdersLocally([id]);
    } catch (e) {
      ZerpaiToast.error(context, 'Error deleting sales order: $e');
    }
  }

  Future<void> _runBulkPdfExport() async {
    final salesState = ref.read(salesOrderControllerProvider);
    final sales = salesState.valueOrNull ?? const <SalesOrder>[];
    final selected = sales
        .where((sale) => _selectedSaleIds.contains(sale.id))
        .toList();
    if (selected.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one sales order');
      return;
    }
    final order = selected.first;
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    final bytes = await _generateSalesOrderPdf(order, orgSettings);
    await Printing.sharePdf(bytes: bytes, filename: '${order.saleNumber}.pdf');
  }

  Future<void> _runBulkPrint() async {
    final salesState = ref.read(salesOrderControllerProvider);
    final sales = salesState.valueOrNull ?? const <SalesOrder>[];
    final selected = sales
        .where((sale) => _selectedSaleIds.contains(sale.id))
        .toList();
    if (selected.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one sales order');
      return;
    }
    final order = selected.first;
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    final bytes = await _generateSalesOrderPdf(order, orgSettings);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> _showBulkUpdateDialog() async {
    if (_selectedSaleIds.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one sales order');
      return;
    }

    final result = await showDialog<_BulkUpdateResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (context) => const _SalesOrderBulkUpdateDialog(),
    );
    if (result == null) return;
    ZerpaiToast.success(
      context,
      '${result.field} updated for ${_selectedSaleIds.length} sales order(s)',
    );
  }

  Future<void> _showCustomizeColumnsDialog() async {
    final working = _columnConfigs.map((column) => column.copy()).toList();
    final result = await showDialog<List<_SalesOrderColumnConfig>>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (dialogContext) =>
          _SalesOrderCustomizeColumnsDialog(columns: working),
    );
    if (result == null) return;
    setState(() => _columnConfigs = result);
    ZerpaiToast.success(context, 'Column preferences saved');
  }

  Future<void> _showNewCustomViewDialog() async {
    final result = await showDialog<_SalesOrderCustomViewResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (dialogContext) => const _SalesOrderNewCustomViewDialog(),
    );
    if (result == null) return;
    ZerpaiToast.success(
      context,
      'Custom view "${result.name}" saved for ${result.visibilityLabel}',
    );
  }

  Widget _workspace(
    List<SalesOrder> filteredSales,
    List<SalesOrder> allSales,
    bool compact,
  ) {
    final orderId = widget.initialSelectedId!;
    final summary = allSales.cast<SalesOrder?>().firstWhere(
      (sale) => sale?.id == orderId,
      orElse: () => null,
    );

    if (compact) {
      return _detailPane(orderId, summary);
    }

    return Row(
      children: [
        SizedBox(width: 360, child: _selectionList(filteredSales, orderId)),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppTheme.borderLight,
        ),
        Expanded(child: _detailPane(orderId, summary)),
      ],
    );
  }

  Widget _selectionList(List<SalesOrder> sales, String selectedId) {
    return Column(
      children: [
        _selectedSaleIds.isNotEmpty
            ? _splitSelectionBanner()
            : Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Sales Orders',
                        style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/sales/orders/create'),
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
                            _buildSortMenuItem(
                              'Created Time',
                              _SalesOrderSortField.createdTime,
                            ),
                            _buildSortMenuItem(
                              'Last Modified Time',
                              _SalesOrderSortField.lastModifiedTime,
                            ),
                            _buildSortMenuItem(
                              'Date',
                              _SalesOrderSortField.date,
                            ),
                            _buildSortMenuItem(
                              'Sales Order#',
                              _SalesOrderSortField.salesOrderNumber,
                            ),
                            _buildSortMenuItem(
                              'Reference#',
                              _SalesOrderSortField.reference,
                            ),
                          ],
                          child: const Text('Sort by'),
                        ),
                        MenuItemButton(
                          style: ZTableMoreMenu.menuItemButtonStyle(),
                          child: const Text('Import Sales Orders'),
                        ),
                        SubmenuButton(
                          style: ZTableMoreMenu.menuItemButtonStyle(),
                          menuChildren: [
                            MenuItemButton(
                              style: ZTableMoreMenu.menuItemButtonStyle(),
                              child: const Text('Export Sales Orders'),
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
                          child: const Text('Manage Custom Fields'),
                        ),
                        MenuItemButton(
                          style: ZTableMoreMenu.menuItemButtonStyle(),
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
            itemCount: sales.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final sale = sales[index];
              final selected = sale.id == selectedId;
              return InkWell(
                onTap: () => context.go('/sales/orders/${sale.id}'),
                child: Container(
                  color: selected ? AppTheme.selectionActiveBg : Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: _buildCheckboxWidget(
                          _selectedSaleIds.contains(sale.id),
                          onTap: () => _toggleSaleSelection(
                            sale.id,
                            !_selectedSaleIds.contains(sale.id),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _customerName(sale),
                              style: AppTheme.bodyText.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${sale.saleNumber}  ${_date(sale.saleDate)}',
                              style: AppTheme.metaHelper,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sale.status.toUpperCase(),
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12,
                                color: AppTheme.primaryBlueDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _currency(sale.total),
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

  Widget _detailPane(String orderId, SalesOrder? summary) {
    final detailAsync = ref.watch(_salesOrderDetailProvider(orderId));
    return detailAsync.when(
      loading: () => const SalesOrderDetailSkeleton(),
      error: (error, _) => _message(
        icon: LucideIcons.alertTriangle,
        title: 'Unable to load order details',
        subtitle: '$error',
      ),
      data: (order) {
        var showPdfView = false;
        final items = order.items ?? const <SalesOrderItem>[];
        final orgSettings = ref.watch(orgSettingsProvider).asData?.value;

        return StatefulBuilder(
          builder: (context, setInnerState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Customer: ${_customerName(order)}',
                            style: AppTheme.metaHelper.copyWith(fontSize: 12),
                          ),
                          const Spacer(),
                          _ActionSquare(
                            icon: LucideIcons.paperclip,
                            color: AppTheme.textSecondary,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _ActionSquare(
                            icon: LucideIcons.messageSquare,
                            color: AppTheme.textSecondary,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _ActionSquare(
                            icon: LucideIcons.x,
                            color: AppTheme.errorRed,
                            onTap: () => context.go('/sales/orders'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.saleNumber,
                        style: AppTheme.sectionHeader.copyWith(fontSize: 22),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(color: Color(0xFFF8F9FA)),
                  child: Row(
                    children: [
                      _buildToolbarButton(
                        LucideIcons.pencil,
                        'Edit',
                        onPressed: () => _editSalesOrder(order),
                      ),
                      _buildDivider(),
                      _buildToolbarButton(
                        LucideIcons.mail,
                        'Send Email',
                        onPressed: () {
                          context.push(
                            AppRoutes.salesOrdersEmail.replaceAll(
                              ':id',
                              order.id,
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildPdfPrintDropdown(order, orgSettings),
                      _buildDivider(),
                      _buildToolbarButton(
                        LucideIcons.fileText,
                        'Convert to Invoice',
                        onPressed: () =>
                            _showUnavailableAction('Convert to Invoice'),
                      ),
                      _buildDivider(),
                      _ActionSplitMenu(
                        icon: LucideIcons.plusCircle, // test
                        label: 'Create',
                        onPrimaryTap: () => _showUnavailableAction('Create'),
                        onSelected: _handleCreateAction,
                      ),
                      _buildDivider(),
                      MenuAnchor(
                        style: _menuStyle(),
                        builder: (context, controller, child) {
                          return IconButton(
                            onPressed: () => controller.isOpen
                                ? controller.close()
                                : controller.open(),
                            icon: const Icon(
                              LucideIcons.moreHorizontal,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        },
                        menuChildren: [
                          _detailActionMenuItem(
                            'Convert to Purchase Order',
                            order,
                          ),
                          _detailActionMenuItem(
                            'Mark shipment as fulfilled',
                            order,
                          ),
                          _detailActionMenuItem('Dropship', order),
                          _detailActionMenuItem('Cancel Items', order),
                          _detailActionMenuItem('Void', order),
                          _detailActionMenuItem('Backorder', order),
                          _detailActionMenuItem('Clone', order),
                          _detailActionMenuItem('Delete', order),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.sparkles,
                                size: 16,
                                color: AppTheme.primaryBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTheme.bodyText,
                                    children: const [
                                      TextSpan(
                                        text: 'WHAT\'S NEXT? ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'Convert the sales order into packages, shipments, or invoices.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(
                                height: 34,
                                child: ZButton.primary(
                                  label: 'Convert',
                                  onPressed: () {},
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 34,
                                child: ZButton.secondary(
                                  label: 'Create Package',
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        ZExpandableTabs(
                          tabs: const ['Packages', 'Picklists'],
                          children: [
                            _banner(
                              icon: LucideIcons.info,
                              text:
                                  'Package tracking will appear here when fulfillment data is available from the backend.',
                            ),
                            _banner(
                              icon: LucideIcons.info,
                              text:
                                  'Picklist tracking will appear here when fulfillment data is available from the backend.',
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Text(
                              'Invoice Status : ',
                              style: AppTheme.bodyText.copyWith(fontSize: 12),
                            ),
                            Text(
                              _invoiceLabel(order),
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12,
                                color: _invoiceColor(order),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Shipment : ',
                              style: AppTheme.bodyText.copyWith(fontSize: 12),
                            ),
                            Text(
                              _shipmentLabel(order),
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12,
                                color: _shipmentColor(order),
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'Show PDF View',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Transform.scale(
                              scale: 0.8,
                              child: Switch(
                                value: showPdfView,
                                onChanged: (value) {
                                  showPdfView = value;
                                  setInnerState(() {});
                                },
                                activeTrackColor: AppTheme.primaryBlue,
                                activeThumbColor: Colors.white,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: showPdfView
                              ? _pdfCard(order, items, orgSettings)
                              : _detailCard(order, items),
                        ),
                      ],
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

  Widget _buildPdfPrintDropdown(SalesOrder order, OrgSettings? orgSettings) {
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
          onPressed: () async {
            final bytes = await _generateSalesOrderPdf(order, orgSettings);
            await Printing.sharePdf(
              bytes: bytes,
              filename: '${order.saleNumber}.pdf',
            );
          },
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
          onPressed: () async {
            final bytes = await _generateSalesOrderPdf(order, orgSettings);
            await Printing.layoutPdf(
              onLayout: (_) async => bytes,
              name: order.saleNumber,
            );
          },
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



  Future<Uint8List> _generateSalesOrderPdf(
    SalesOrder order,
    OrgSettings? org,
  ) async {
    final doc = pw.Document();
    final items = order.items ?? [];

    pw.MemoryImage? logoImage;
    if (org?.logoUrl != null && org!.logoUrl!.trim().isNotEmpty) {
      try {
        final dio = Dio();
        final res = await dio.get(
          org.logoUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null) {
          logoImage = pw.MemoryImage(Uint8List.fromList(res.data));
        }
      } catch (_) {}
    }

    final dateStr = _date(order.saleDate);
    final customer = order.customer;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          width: 130,
                          height: 56,
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                          ),
                          child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                        )
                      else
                        pw.Container(
                          width: 130,
                          height: 56,
                          color: const PdfColor.fromInt(0xFF101820),
                          child: pw.Center(
                            child: pw.Text(
                              'LOGO',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        (org?.name ?? 'YOUR COMPANY').trim().toUpperCase(),
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      if (org?.paymentStubAddress?.trim().isNotEmpty == true)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(
                            _formatAddress(org!.paymentStubAddress!.trim()),
                            style: const pw.TextStyle(
                              fontSize: 9,
                              lineSpacing: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'SALES ORDER',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 28,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Sales Order# ${order.saleNumber}',
                        style: pw.TextStyle(
                          fontSize: 13,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.Row(
                children: [
                  _pwInfoCell('Sales Order#', order.saleNumber),
                  _pwInfoCell('Order Date', dateStr),
                  _pwInfoCell(
                    'Expected Shipment Date',
                    order.expectedShipmentDate != null
                        ? _date(order.expectedShipmentDate!)
                        : '-',
                  ),
                  _pwInfoCell('Reference#', order.reference ?? '-'),
                ],
              ),
              pw.Divider(color: PdfColors.grey300, height: 24),
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Bill To',
                          style: pw.TextStyle(
                            color: PdfColors.blue,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _customerName(order),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (customer != null &&
                            customer.fullBillingAddress != 'N/A')
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              customer.fullBillingAddress,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                lineSpacing: 2,
                              ),
                            ),
                          ),
                        if (customer != null && customer.phone != null)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              'Phone: ${customer.phone}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Ship To',
                          style: pw.TextStyle(
                            color: PdfColors.blue,
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _customerName(order),
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        if (customer != null &&
                            customer.fullShippingAddress != 'N/A')
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              customer.fullShippingAddress,
                              style: const pw.TextStyle(
                                fontSize: 10,
                                lineSpacing: 2,
                              ),
                            ),
                          ),
                        if (customer != null &&
                            customer.shippingAddressPhone != null)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              'Phone: ${customer.shippingAddressPhone}',
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.Table(
                columnWidths: const {
                  0: pw.FixedColumnWidth(32),
                  1: pw.FlexColumnWidth(5),
                  2: pw.FlexColumnWidth(2),
                  3: pw.FixedColumnWidth(60),
                  4: pw.FixedColumnWidth(80),
                  5: pw.FixedColumnWidth(100),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1F2937),
                    ),
                    children: [
                      _pwHeaderCell('#'),
                      _pwHeaderCell('Item & Description'),
                      _pwHeaderCell('HSN/SAC'),
                      _pwHeaderCell('Qty', align: pw.Alignment.centerRight),
                      _pwHeaderCell('Rate', align: pw.Alignment.centerRight),
                      _pwHeaderCell('Amount', align: pw.Alignment.centerRight),
                    ],
                  ),
                  ...items.asMap().entries.map((e) {
                    final item = e.value;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: e.key % 2 == 0
                            ? PdfColors.white
                            : const PdfColor.fromInt(0xFFF9FAFB),
                        border: const pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey200),
                        ),
                      ),
                      children: [
                        _pwDataCell('${e.key + 1}'),
                        _pwDataCell(
                          item.description ??
                              item.item?.billingName ??
                              'Unnamed item',
                        ),
                        _pwDataCell((item.hsnCode ?? item.item?.hsnCode) ?? ''),
                        _pwDataCell(
                          item.quantity.toStringAsFixed(0),
                          align: pw.Alignment.centerRight,
                        ),
                        _pwDataCell(
                          _currency(item.rate).replaceAll('₹', ''),
                          align: pw.Alignment.centerRight,
                        ),
                        _pwDataCell(
                          _currency(_lineAmount(item)).replaceAll('₹', ''),
                          align: pw.Alignment.centerRight,
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 200,
                    child: pw.Column(
                      children: [
                        _pwTotalRow('Sub Total', _currency(order.subTotal)),
                        _pwTotalRow('Tax Total', _currency(order.taxTotal)),
                        if (order.shippingCharges != 0)
                          _pwTotalRow(
                            'Shipping Charges',
                            _currency(order.shippingCharges),
                          ),
                        if (order.adjustment != 0)
                          _pwTotalRow(
                            'Adjustment',
                            _currency(order.adjustment),
                          ),
                        pw.Divider(color: PdfColors.grey300),
                        _pwTotalRow(
                          'Total',
                          _currency(order.total),
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  pw.Widget _pwInfoCell(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _pwHeaderCell(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Align(
        alignment: align,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  pw.Widget _pwDataCell(
    String text, {
    pw.Alignment align = pw.Alignment.centerLeft,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Align(
        alignment: align,
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
      ),
    );
  }

  pw.Widget _pwTotalRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: isBold ? pw.FontWeight.bold : null,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, double> _calculateColumnWidths(double totalWidth) {
    const double staticPrefixWidth = 84.0; // Slider + Checkbox space

    // min width + flex weight for each visible column
    final Map<String, ({double min, double flex})> metrics = {
      'date': (min: 100.0, flex: 1.0),
      'salesOrderNumber': (min: 120.0, flex: 1.4),
      'reference': (min: 110.0, flex: 1.2),
      'customerName': (min: 150.0, flex: 2.0),
      'orderStatus': (min: 110.0, flex: 1.2),
      'invoiced': (min: 80.0, flex: 0.8),
      'payment': (min: 80.0, flex: 0.8),
      'packed': (min: 80.0, flex: 0.8),
      'shipped': (min: 80.0, flex: 0.8),
      'amount': (min: 110.0, flex: 1.2),
      'deliveryMethod': (min: 130.0, flex: 1.5),
      'expectedShipmentDate': (min: 130.0, flex: 1.5),
      'companyName': (min: 150.0, flex: 2.0),
      'invoicedAmount': (min: 120.0, flex: 1.2),
      'location': (min: 120.0, flex: 1.2),
      'picked': (min: 80.0, flex: 0.8),
      'salesPerson': (min: 120.0, flex: 1.2),
      'status': (min: 100.0, flex: 1.0),
    };


    double totalMinWidth = staticPrefixWidth;
    double totalFlex = 0;

    for (final col in _visibleColumns) {
      final colKey = col.key.name;
      final m = metrics[colKey] ?? (min: 120.0, flex: 1.0);
      totalMinWidth += m.min;
      totalFlex += m.flex;
    }

    final extraSpace = math.max(0.0, totalWidth - totalMinWidth);
    final results = <String, double>{};
    for (final col in _visibleColumns) {
      final colKey = col.key.name;
      final m = metrics[colKey] ?? (min: 120.0, flex: 1.0);
      results[colKey] = m.min + (m.flex / totalFlex) * extraSpace;
    }
    return results;
  }

  void _resizeColumn(String key, double dx) {
    setState(() {
      if (_customColumnWidths == null) {
        // Use current screen width to initialize if not yet set
        _customColumnWidths = _calculateColumnWidths(
          context.size?.width ?? 1200,
        );
      }
      final current = _customColumnWidths![key] ?? 120.0;
      _customColumnWidths![key] = (current + dx).clamp(50.0, 2000.0);
    });
    _saveColumnSettings();
  }

  Widget _table(List<SalesOrder> sales) {
    final allSelected = _allVisibleSelected(sales);
    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columnWidths =
                _customColumnWidths ??
                _calculateColumnWidths(constraints.maxWidth);
            const double actualPrefixWidth = 84.0; // Slider + Checkbox space
            final double totalColumnsWidth = columnWidths.values.fold(
              0.0,
              (sum, w) => sum + w,
            );
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
                      _buildTableHeader(sales, allSelected, columnWidths),
                      Expanded(
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: sales.length,
                          itemExtent: 40,
                          itemBuilder: (context, index) {
                            return _buildVirtualRow(sales[index], columnWidths);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTableHeader(
    List<SalesOrder> sales,
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
          _buildCheckboxWidget(
            allSelected,
            isPartially: _selectedSaleIds.isNotEmpty && !allSelected,
            onTap: () => _toggleSelectAll(sales, !allSelected),
          ),
          const SizedBox(width: 12),
          ..._visibleColumns.map((col) {
            final w = columnWidths[col.key.name] ?? col.width;
            return _ResizableHeaderCell(
              width: w,
              onResize: (dx) => _resizeColumn(col.key.name, dx),
              child: _buildHeaderForColumn(col, w),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCheckboxWidget(
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

  Widget _buildVirtualRow(SalesOrder sale, Map<String, double> columnWidths) {
    final isSelected = _selectedSaleIds.contains(sale.id);
    return InkWell(
      onTap: () => context.go('/sales/orders/${sale.id}'),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7FF) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: AppTheme.bgDisabled)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 8),
            const SizedBox(
              width: 28,
            ), // Slider placeholder to match HeaderMenuButton
            const SizedBox(width: 12),
            _buildCheckboxWidget(
              isSelected,
              onTap: () => _toggleSaleSelection(sale.id, !isSelected),
            ),
            const SizedBox(width: 12),
            ..._visibleColumns.map(
              (col) => _buildCellForColumn(col, sale, columnWidths),
            ),
          ],
        ),
      ),
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
            icon: LucideIcons.fileText,
            onTap: () => _handleBulkAction('PDF export'),
          ),
          _BulkIconButton(
            icon: LucideIcons.printer,
            onTap: () => _handleBulkAction('Print'),
          ),
          _BulkIconButton(
            icon: LucideIcons.mail,
            onTap: () => _handleBulkAction('Email'),
          ),
          _BulkDivider(),
          _BulkActionButton(
            label: 'Mark shipment as fulfilled',
            onTap: () => _handleBulkAction('Shipment fulfilment'),
          ),
          _BulkActionButton(
            label: 'Backorder',
            onTap: () => _handleBulkAction('Backorder'),
          ),
          _BulkActionButton(
            label: 'Dropship',
            onTap: () => _handleBulkAction('Dropship'),
          ),
          _BulkActionButton(
            label: 'Generate picklist',
            onTap: () => _handleBulkAction('Picklist generation'),
          ),
          _BulkDivider(),
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
              '${_selectedSaleIds.length}',
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

  Widget _splitSelectionBanner() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white,
      child: Row(
        children: [
          _buildCheckboxWidget(true, onTap: _clearSelection),
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
              _bulkActionMenuItem('Print', 'Print'),
              _bulkActionMenuItem('Send Emails', 'Email'),
              const Divider(height: 1, color: AppTheme.borderLight),
              _bulkActionMenuItem('Convert to Invoice', 'Convert to invoice'),
              _bulkActionMenuItem('Mark as Confirmed', 'Mark as confirmed'),
              _bulkActionMenuItem(
                'Mark shipment as fulfilled',
                'Shipment fulfilment',
              ),
              _bulkActionMenuItem('Backorder', 'Backorder'),
              _bulkActionMenuItem('Dropship', 'Dropship'),
              _bulkActionMenuItem('Generate picklist', 'Picklist generation'),
              _bulkActionMenuItem('Create Quick Shipments', 'Quick shipments'),
              _bulkActionMenuItem('Merge Sales Orders', 'Merge sales orders'),
              _bulkActionMenuItem('Bulk Cancel Items', 'Bulk cancel items'),
              _bulkActionMenuItem(
                'Bulk reopen canceled items',
                'Bulk reopen canceled items',
              ),
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
              '${_selectedSaleIds.length}',
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

  Widget _buildHeaderForColumn(_SalesOrderColumnConfig column, double width) {
    final sortField = _sortFieldForColumn(column.key);
    final isSorted = sortField != null && _activeSortField == sortField;
    final align =
        (column.key == _SalesOrderColumnKey.invoiced ||
            column.key == _SalesOrderColumnKey.payment ||
            column.key == _SalesOrderColumnKey.packed ||
            column.key == _SalesOrderColumnKey.shipped ||
            column.key == _SalesOrderColumnKey.picked ||
            column.key == _SalesOrderColumnKey.salesOrderNumber ||
            column.key == _SalesOrderColumnKey.orderStatus ||
            column.key == _SalesOrderColumnKey.amount ||
            column.key == _SalesOrderColumnKey.invoicedAmount ||
            column.key == _SalesOrderColumnKey.deliveryMethod)
        ? TextAlign.center
        : TextAlign.left;
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: InkWell(
          onTap: sortField == null
              ? null
              : () => setState(() => _toggleSort(sortField)),
          child: Row(
            mainAxisAlignment: align == TextAlign.center
                ? MainAxisAlignment.center
                : (column.key == _SalesOrderColumnKey.amount ||
                      column.key == _SalesOrderColumnKey.invoicedAmount)
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  column.label.toUpperCase(),
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

  Widget _buildCellForColumn(
    _SalesOrderColumnConfig column,
    SalesOrder sale,
    Map<String, double> columnWidths,
  ) {
    final w = columnWidths[column.key.name] ?? column.width;
    switch (column.key) {
      case _SalesOrderColumnKey.date:
        return _Cell(width: w, child: _tableText(_date(sale.saleDate)));
      case _SalesOrderColumnKey.salesOrderNumber:
        return _Cell(
          width: w,
          child: Text(
            sale.saleNumber,
            textAlign: TextAlign.center,
            style: AppTheme.tableCell.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
          alignCenter: true,
        );
      case _SalesOrderColumnKey.reference:
        return _Cell(width: w, child: _tableText(sale.reference ?? '—'));
      case _SalesOrderColumnKey.customerName:
        return _Cell(width: w, child: _tableText(_customerName(sale)));
      case _SalesOrderColumnKey.orderStatus:
      case _SalesOrderColumnKey.status:
        return _Cell(
          width: w,
          child: Text(
            sale.status.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTheme.linkText.copyWith(
              fontSize: 12,
              decoration: TextDecoration.none,
            ),
          ),
          alignCenter: true,
        );
      case _SalesOrderColumnKey.invoiced:
        return _StateDot(
          width: w,
          active: _isInvoiced(sale),
          tooltip: _invoiceLabel(sale),
          activeIcon: LucideIcons.fileText,
        );
      case _SalesOrderColumnKey.payment:
        return _StateDot(
          width: w,
          active: _isPaid(sale),
          tooltip: _paymentLabel(sale),
          activeIcon: LucideIcons.creditCard,
        );

      case _SalesOrderColumnKey.packed:
        return _StateDot(
          width: w,
          active: _isPacked(sale),
          tooltip: _isPacked(sale) ? 'Packed' : 'Not Packed',
          activeIcon: LucideIcons.package,
        );
      case _SalesOrderColumnKey.shipped:
        return _StateDot(
          width: w,
          active: _isShipped(sale),
          tooltip: _shipmentLabel(sale),
          activeIcon: LucideIcons.truck,
        );
      case _SalesOrderColumnKey.amount:
        return _Cell(
          width: w,
          alignRight: true,
          child: Align(
            alignment: Alignment.center,
            child: ZCurrencyDisplay(
              amount: sale.total,
              style: AppTheme.tableCell.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        );
      case _SalesOrderColumnKey.deliveryMethod:
        return _Cell(
          width: w,
          alignCenter: true,
          child: _tableText(
            sale.deliveryMethod ?? '—',
            textAlign: TextAlign.center,
          ),
        );
      case _SalesOrderColumnKey.expectedShipmentDate:
        return _Cell(
          width: w,
          child: _tableText(
            sale.expectedShipmentDate != null
                ? _date(sale.expectedShipmentDate!)
                : '—',
          ),
        );
      case _SalesOrderColumnKey.companyName:
        return _Cell(
          width: w,
          child: _tableText(sale.customer?.companyName ?? '—'),
        );
      case _SalesOrderColumnKey.invoicedAmount:
        return _Cell(
          width: w,
          alignRight: true,
          child: Align(
            alignment: Alignment.centerRight,
            child: _isInvoiced(sale)
                ? ZCurrencyDisplay(
                    amount: sale.total,
                    style: AppTheme.tableCell,
                  )
                : Text(
                    '—',
                    style: AppTheme.tableCell,
                    textAlign: TextAlign.right,
                  ),
          ),
        );
      case _SalesOrderColumnKey.location:
        return _Cell(
          width: w,
          child: _tableText(sale.customer?.billingAddressStateId ?? '—'),
        );
      case _SalesOrderColumnKey.picked:
        return _StateDot(
          width: w,
          active: _isPacked(sale),
          tooltip: _isPacked(sale) ? 'Picked' : 'Not Picked',
          activeIcon: LucideIcons.checkSquare,
        );
      case _SalesOrderColumnKey.salesPerson:
        return _Cell(width: w, child: _tableText(sale.salesperson ?? '—'));
    }
  }

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

  _SalesOrderSortField? _sortFieldForColumn(_SalesOrderColumnKey key) {
    switch (key) {
      case _SalesOrderColumnKey.date:
        return _SalesOrderSortField.date;
      case _SalesOrderColumnKey.salesOrderNumber:
        return _SalesOrderSortField.salesOrderNumber;
      case _SalesOrderColumnKey.reference:
        return _SalesOrderSortField.reference;
      case _SalesOrderColumnKey.customerName:
        return _SalesOrderSortField.customerName;
      case _SalesOrderColumnKey.orderStatus:
        return _SalesOrderSortField.orderStatus;
      case _SalesOrderColumnKey.invoiced:
        return _SalesOrderSortField.invoiced;
      case _SalesOrderColumnKey.payment:
        return _SalesOrderSortField.payment;
      case _SalesOrderColumnKey.packed:
        return _SalesOrderSortField.packed;
      case _SalesOrderColumnKey.shipped:
        return _SalesOrderSortField.shipped;
      case _SalesOrderColumnKey.amount:
        return _SalesOrderSortField.amount;
      case _SalesOrderColumnKey.deliveryMethod:
        return _SalesOrderSortField.deliveryMethod;
      case _SalesOrderColumnKey.expectedShipmentDate:
        return _SalesOrderSortField.expectedShipmentDate;
      case _SalesOrderColumnKey.companyName:
        return _SalesOrderSortField.companyName;
      case _SalesOrderColumnKey.invoicedAmount:
        return _SalesOrderSortField.invoicedAmount;
      case _SalesOrderColumnKey.location:
        return _SalesOrderSortField.location;
      case _SalesOrderColumnKey.picked:
        return _SalesOrderSortField.picked;
      case _SalesOrderColumnKey.salesPerson:
        return _SalesOrderSortField.salesPerson;
      case _SalesOrderColumnKey.status:
        return _SalesOrderSortField.status;
    }
  }

  Widget _detailCard(SalesOrder order, List<SalesOrderItem> items) {
    return Container(
      key: const ValueKey('detail'),
      padding: const EdgeInsets.all(24),
      decoration: _paperDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SALES ORDER',
                      style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sales Order# ${order.saleNumber}',
                      style: AppTheme.bodyText.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _statusSummary(order),
                    const SizedBox(height: 24),
                    _meta('ORDER DATE', _date(order.saleDate)),
                    const SizedBox(height: 12),
                    _meta(
                      'PAYMENT TERMS',
                      order.paymentTerms ?? 'Not specified',
                    ),
                    const SizedBox(height: 12),
                    _meta('SALESPERSON', order.salesperson ?? 'Not assigned'),
                  ],
                ),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _addressBlock(
                      'BILLING ADDRESS',
                      _customerName(order),
                      _address(order.customer?.fullBillingAddress),
                      order.customer?.phone,
                    ),
                    const SizedBox(height: 16),
                    _addressBlock(
                      'SHIPPING ADDRESS',
                      _customerName(order),
                      _address(order.customer?.fullShippingAddress),
                      order.customer?.shippingAddressPhone,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SizedBox(height: 28),
          _itemsTable(items, order),
          const SizedBox(height: 26),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: _totals(order, items),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'More Information',
            style: AppTheme.sectionHeader.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 42,
            runSpacing: 16,
            children: [
              _infoPair('Salesperson', order.salesperson ?? 'Not assigned'),
              _infoPair(
                'Customer Notes',
                order.customerNotes ?? 'No customer notes',
              ),
              _infoPair(
                'Terms & Conditions',
                order.termsAndConditions ?? 'No terms attached',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pdfCard(
    SalesOrder order,
    List<SalesOrderItem> items,
    OrgSettings? orgSettings,
  ) {
    return Container(
      key: const ValueKey('pdf'),
      margin: const EdgeInsets.symmetric(horizontal: 110),
      decoration: _paperDecoration(),
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: _PdfCornerRibbon(
                label: 'CONFIRMED',
                color: AppTheme.primaryBlue,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(56, 56, 56, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _pdfLogo(orgSettings),
                            const SizedBox(height: 16),
                            Text(
                              orgSettings?.name.trim().isNotEmpty == true
                                  ? orgSettings!.name.trim()
                                  : 'YOUR COMPANY NAME',
                              style: AppTheme.bodyText.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (orgSettings?.paymentStubAddress
                                    ?.trim()
                                    .isNotEmpty ==
                                true)
                              Text(
                                _formatAddress(
                                  orgSettings!.paymentStubAddress!.trim(),
                                ),
                                style: AppTheme.bodyText.copyWith(fontSize: 13),
                              ),
                            if (orgSettings?.companyIdentityLine?.isNotEmpty ==
                                true)
                              Padding(
                                padding: EdgeInsets.only(
                                  top:
                                      orgSettings?.paymentStubAddress
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? 6
                                      : 0,
                                ),
                                child: Text(
                                  orgSettings!.companyIdentityLine!,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            if ((orgSettings?.paymentStubAddress
                                        ?.trim()
                                        .isNotEmpty !=
                                    true) &&
                                (orgSettings?.companyIdentityLine?.isNotEmpty !=
                                    true))
                              Text(
                                'Address Line 1\nCity, State PIN',
                                style: AppTheme.bodyText.copyWith(fontSize: 13),
                              ),
                          ],
                        ),
                      ),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SALES ORDER',
                            style: AppTheme.sectionHeader.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Sales Order# ${order.saleNumber}',
                            style: AppTheme.bodyText.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _pdfAddress(
                          'Bill To',
                          _customerName(order),
                          _address(order.customer?.fullBillingAddress),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: _pdfAddress(
                          'Ship To',
                          _customerName(order),
                          _address(order.customer?.fullShippingAddress),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            'Order Date : ${_date(order.saleDate)}',
                            style: AppTheme.bodyText.copyWith(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _pdfItems(items),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: _totals(order, items, dense: true),
                    ),
                  ),
                  const SizedBox(height: 34),
                  Row(
                    children: [
                      Text(
                        'Authorized Signature',
                        style: AppTheme.bodyText.copyWith(fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 42,
                    runSpacing: 16,
                    children: [
                      _infoPair(
                        'Salesperson',
                        order.salesperson ?? 'Not assigned',
                      ),
                      _infoPair(
                        'Customer Notes',
                        order.customerNotes ?? 'No customer notes',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pdfLogo(OrgSettings? orgSettings) {
    final logoUrl = orgSettings?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: 240,
        height: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _pdfLogoFallback(),
        ),
      );
    }
    return _pdfLogoFallback();
  }

  Widget _pdfLogoFallback() {
    return Container(
      width: 240,
      height: 96,
      color: const Color(0xFF101820),
      child: const Center(
        child: Text(
          'LOGO / LETTERHEAD',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _statusSummary(SalesOrder order) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 3, height: 118, color: AppTheme.warningOrange),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order', style: AppTheme.bodyText),
            const SizedBox(height: 12),
            Text('Invoice', style: AppTheme.bodyText),
            const SizedBox(height: 12),
            Text('Payment', style: AppTheme.bodyText),
            const SizedBox(height: 12),
            Text('Shipment', style: AppTheme.bodyText),
          ],
        ),
        const SizedBox(width: 28),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: AppTheme.primaryBlue,
              child: Text(
                order.status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _invoiceLabel(order),
              style: AppTheme.bodyText.copyWith(color: _invoiceColor(order)),
            ),
            const SizedBox(height: 12),
            Text(
              _paymentLabel(order),
              style: AppTheme.bodyText.copyWith(color: _paymentColor(order)),
            ),
            const SizedBox(height: 12),
            Text(
              _shipmentLabel(order),
              style: AppTheme.bodyText.copyWith(color: _shipmentColor(order)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _addressBlock(
    String label,
    String primary,
    String address,
    String? phone,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.metaHelper.copyWith(fontSize: 12, letterSpacing: 0.3),
        ),
        const SizedBox(height: 10),
        Text(
          primary,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.primaryBlueDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(address, style: AppTheme.bodyText.copyWith(height: 1.5)),
        if ((phone ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(phone!, style: AppTheme.bodyText),
        ],
      ],
    );
  }

  Widget _meta(String label, String value) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.metaHelper.copyWith(
              fontSize: 12,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _itemsTable(List<SalesOrderItem> items, SalesOrder order) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            color: AppTheme.bgLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: const [
                Expanded(
                  flex: 4,
                  child: Text(
                    'ITEMS & DESCRIPTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ORDERED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'LOCATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'RATE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'DISCOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'TAX',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'AMOUNT',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No line items available.'),
            )
          else
            ...items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.borderLight)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppTheme.bgLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: const Icon(
                              LucideIcons.image,
                              size: 16,
                              color: AppTheme.textDisabled,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.item?.productName ??
                                      item.item?.billingName ??
                                      item.description ??
                                      item.item?.itemCode ??
                                      'Unnamed item',
                                  style: AppTheme.linkText,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _quantity(item.quantity),
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _quantity(item.quantity),
                        style: AppTheme.bodyText,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        () {
                          final whs = ref.watch(warehousesProvider).value;
                          if (whs != null && item.warehouseId != null) {
                            final match = whs.firstWhere(
                              (w) => w.id == item.warehouseId,
                              orElse: () => whs.firstWhere(
                                (w) => w.isDefaultForBranch,
                                orElse: () => whs.first,
                              ),
                            );
                            return match.name;
                          }
                          if (whs != null && order.warehouseId != null) {
                            final match = whs.firstWhere(
                              (w) => w.id == order.warehouseId,
                              orElse: () => whs.firstWhere(
                                (w) => w.isDefaultForBranch,
                                orElse: () => whs.first,
                              ),
                            );
                            return match.name;
                          }
                          return 'Main Warehouse';
                        }(),
                        style: AppTheme.bodyText.copyWith(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isShipped(order) ? '${item.quantity.toInt()} Shipped' : '0 Shipped',
                            style: AppTheme.bodyText.copyWith(fontSize: 11),
                          ),
                          Text(
                            order.status.toUpperCase() == 'FULFILLED' ? '${item.quantity.toInt()} Invoiced' : '0 Invoiced',
                            style: AppTheme.bodyText.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _currency(item.rate),
                        style: AppTheme.bodyText,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _discountLabel(item),
                        style: AppTheme.bodyText,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.taxAmount == 0 ? '—' : _currency(item.taxAmount),
                        style: AppTheme.bodyText,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _currency(_lineAmount(item)),
                        style: AppTheme.bodyText.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _totals(
    SalesOrder order,
    List<SalesOrderItem> items, {
    bool dense = false,
  }) {
    final quantity = items.fold<double>(0, (sum, item) => sum + item.quantity);
    final spacing = dense ? 12.0 : 14.0;
    Widget row(
      String label,
      String value, {
      bool total = false,
      Color? valueColor,
    }) {
      final style = AppTheme.bodyText.copyWith(
        fontSize: total ? 16 : 14,
        fontWeight: total ? FontWeight.w700 : FontWeight.w500,
      );
      return Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(
            value,
            style: style.copyWith(color: valueColor ?? AppTheme.textPrimary),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row('Sub Total', _currency(order.subTotal)),
        SizedBox(height: spacing),
        row(
          'Total Quantity',
          _quantity(quantity),
          valueColor: AppTheme.textSecondary,
        ),
        SizedBox(height: spacing),
        row('CGST / SGST', _currency(order.taxTotal)),
        if (order.adjustment != 0) ...[
          SizedBox(height: spacing),
          row('Round Off', _currency(order.adjustment)),
        ],
        if (order.shippingCharges != 0) ...[
          SizedBox(height: spacing),
          row('Shipping', _currency(order.shippingCharges)),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.bgLight,
            borderRadius: BorderRadius.circular(6),
          ),
          child: row('Total', _currency(order.total), total: true),
        ),
      ],
    );
  }

  Widget _pdfAddress(String title, String primary, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          primary,
          style: AppTheme.bodyText.copyWith(color: AppTheme.primaryBlueDark),
        ),
        const SizedBox(height: 6),
        Text(
          address,
          style: AppTheme.bodyText.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _pdfItems(List<SalesOrderItem> items) {
    Widget header(String text, {TextAlign align = TextAlign.left}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        textAlign: align,
      ),
    );
    Widget cell(String text, {TextAlign align = TextAlign.left}) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: AppTheme.bodyText.copyWith(fontSize: 13),
        textAlign: align,
      ),
    );

    return Table(
      border: TableBorder.symmetric(
        inside: const BorderSide(color: AppTheme.borderLight),
        outside: const BorderSide(color: AppTheme.borderLight),
      ),
      columnWidths: const {
        0: FixedColumnWidth(42),
        1: FlexColumnWidth(3.6),
        2: FlexColumnWidth(1.4),
        3: FlexColumnWidth(1.1),
        4: FlexColumnWidth(1.1),
        5: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFF3F3F3C)),
          children: [
            header('#'),
            header('Item & Description'),
            header('HSN/SAC'),
            header('Qty'),
            header('Rate'),
            header('Amount', align: TextAlign.right),
          ],
        ),
        ...List.generate(items.length, (index) {
          final item = items[index];
          return TableRow(
            children: [
              cell('${index + 1}'),
              cell(
                item.item?.productName ??
                    item.item?.billingName ??
                    item.description ??
                    item.item?.itemCode ??
                    'Item',
              ),
              cell((item.hsnCode ?? item.item?.hsnCode) ?? '—'),
              cell(_quantity(item.quantity)),
              cell(_currency(item.rate)),
              cell(_currency(_lineAmount(item)), align: TextAlign.right),
            ],
          );
        }),
      ],
    );
  }

  Widget _banner({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.warningBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE7B8)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.warningTextDark),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.warningTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPair(String label, String value) {
    return SizedBox(
      width: 280,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTheme.metaHelper.copyWith(fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: AppTheme.bodyText.copyWith(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  BoxDecoration _paperDecoration() {
    return BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppTheme.borderLight),
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  List<SalesOrder> _applyFilters(List<SalesOrder> sales) {
    Iterable<SalesOrder> result = sales.where((sale) => !sale.isDelete);
    if (_activeView.statuses != null && _activeView.statuses!.isNotEmpty) {
      result = result.where(
        (sale) =>
            _activeView.statuses!.contains(sale.status.trim().toLowerCase()),
      );
    }
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((sale) {
        return sale.saleNumber.toLowerCase().contains(query) ||
            (sale.reference?.toLowerCase().contains(query) ?? false) ||
            _customerName(sale).toLowerCase().contains(query);
      });
    }
    final sorted = result.toList()
      ..sort((a, b) {
        int comparison;
        switch (_activeSortField) {
          case _SalesOrderSortField.createdTime:
          case _SalesOrderSortField.lastModifiedTime:
            comparison = (a.createdAt ?? a.saleDate).compareTo(
              b.createdAt ?? b.saleDate,
            );
            break;
          case _SalesOrderSortField.date:
            comparison = a.saleDate.compareTo(b.saleDate);
            break;
          case _SalesOrderSortField.salesOrderNumber:
            comparison = a.saleNumber.toLowerCase().compareTo(
              b.saleNumber.toLowerCase(),
            );
            break;
          case _SalesOrderSortField.reference:
            comparison = (a.reference ?? '').toLowerCase().compareTo(
              (b.reference ?? '').toLowerCase(),
            );
            break;
          case _SalesOrderSortField.customerName:
            comparison = _customerName(
              a,
            ).toLowerCase().compareTo(_customerName(b).toLowerCase());
            break;
          case _SalesOrderSortField.orderStatus:
          case _SalesOrderSortField.status:
            comparison = a.status.toLowerCase().compareTo(
              b.status.toLowerCase(),
            );
            break;
          case _SalesOrderSortField.invoiced:
            comparison = _boolSortValue(
              _isInvoiced(a),
            ).compareTo(_boolSortValue(_isInvoiced(b)));
            break;
          case _SalesOrderSortField.payment:
            comparison = _boolSortValue(
              _isPaid(a),
            ).compareTo(_boolSortValue(_isPaid(b)));
            break;
          case _SalesOrderSortField.packed:
          case _SalesOrderSortField.picked:
            comparison = _boolSortValue(
              _isPacked(a),
            ).compareTo(_boolSortValue(_isPacked(b)));
            break;
          case _SalesOrderSortField.shipped:
            comparison = _boolSortValue(
              _isShipped(a),
            ).compareTo(_boolSortValue(_isShipped(b)));
            break;
          case _SalesOrderSortField.amount:
            comparison = a.total.compareTo(b.total);
            break;
          case _SalesOrderSortField.deliveryMethod:
            comparison = (a.deliveryMethod ?? '').toLowerCase().compareTo(
              (b.deliveryMethod ?? '').toLowerCase(),
            );
            break;
          case _SalesOrderSortField.expectedShipmentDate:
            comparison = (a.expectedShipmentDate ?? a.saleDate).compareTo(
              b.expectedShipmentDate ?? b.saleDate,
            );
            break;
          case _SalesOrderSortField.companyName:
            comparison = (a.customer?.companyName ?? '')
                .toLowerCase()
                .compareTo((b.customer?.companyName ?? '').toLowerCase());
            break;
          case _SalesOrderSortField.invoicedAmount:
            comparison = (_isInvoiced(a) ? a.total : 0).compareTo(
              _isInvoiced(b) ? b.total : 0,
            );
            break;
          case _SalesOrderSortField.location:
            comparison = (a.customer?.billingAddressStateId ?? '')
                .toLowerCase()
                .compareTo(
                  (b.customer?.billingAddressStateId ?? '').toLowerCase(),
                );
            break;
          case _SalesOrderSortField.salesPerson:
            comparison = (a.salesperson ?? '').toLowerCase().compareTo(
              (b.salesperson ?? '').toLowerCase(),
            );
            break;
        }
        return _isAscending ? comparison : -comparison;
      });
    return sorted;
  }

  void _toggleSort(_SalesOrderSortField field) {
    if (_activeSortField == field) {
      _isAscending = !_isAscending;
    } else {
      _activeSortField = field;
      _isAscending = true;
    }
  }

  Widget _message({
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
              style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

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
      child: Container(
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
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Align(
          alignment: alignCenter
              ? Alignment.center
              : (alignRight ? Alignment.centerRight : Alignment.centerLeft),
          child: child,
        ),
      ),
    );
  }
}

class _StateDot extends StatelessWidget {
  final double width;
  final bool active;
  final String tooltip;
  final IconData? activeIcon;

  const _StateDot({
    required this.width,
    required this.active,
    required this.tooltip,
    this.activeIcon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: ZTooltip(
          message: tooltip,
          child: active
              ? Icon(
                  activeIcon ?? LucideIcons.badgeCheck,
                  size: 15,
                  color: AppTheme.textSecondary,
                )
              : Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.borderMid,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ActionSplitMenu extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPrimaryTap;
  final ValueChanged<String> onSelected;

  const _ActionSplitMenu({
    required this.icon,
    required this.label,
    required this.onPrimaryTap,
    required this.onSelected,
  });

  static const _menuItems = <String>[
    'Picklist',
    'Package',
    'Shipment',
    'Instant Invoice',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(6),
          color: Colors.white,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onPrimaryTap,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                bottomLeft: Radius.circular(6),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: const Color(0xFF4B5563)),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(width: 1, height: 22, color: AppTheme.borderLight),
            PopupMenuButton<String>(
              tooltip: '',
              color: Colors.white,
              elevation: 8,
              splashRadius: 18,
              padding: EdgeInsets.zero,
              offset: const Offset(0, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.borderLight),
              ),
              onSelected: onSelected,
              itemBuilder: (context) => _menuItems
                  .map(
                    (item) => PopupMenuItem<String>(
                      value: item,
                      labelTextStyle:
                          WidgetStateProperty.resolveWith<TextStyle>((states) {
                            if (states.contains(WidgetState.hovered)) {
                              return AppTheme.bodyText.copyWith(
                                fontSize: 13,
                                color: Colors.white,
                              );
                            }
                            return AppTheme.bodyText.copyWith(fontSize: 13);
                          }),
                      textStyle: AppTheme.bodyText.copyWith(fontSize: 13),
                      child: Text(
                        item,
                        style: AppTheme.bodyText.copyWith(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              child: Theme(
                data: Theme.of(context).copyWith(
                  hoverColor: AppTheme.primaryBlue,
                  highlightColor: AppTheme.primaryBlue,
                  focusColor: AppTheme.primaryBlue,
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Icon(
                    LucideIcons.chevronDown,
                    size: 14,
                    color: AppTheme.textBody,
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

class _BulkDivider extends StatelessWidget {
  const _BulkDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppTheme.borderLight,
    );
  }
}



class _BulkUpdateResult {
  final String field;
  final String value;

  const _BulkUpdateResult({required this.field, required this.value});
}

enum _CustomViewVisibility { onlyMe, selectedUsers, everyone }

class _SalesOrderCustomViewResult {
  final String name;
  final String visibilityLabel;

  const _SalesOrderCustomViewResult({
    required this.name,
    required this.visibilityLabel,
  });
}

class _SalesOrderBulkUpdateDialog extends StatefulWidget {
  const _SalesOrderBulkUpdateDialog();

  @override
  State<_SalesOrderBulkUpdateDialog> createState() =>
      _SalesOrderBulkUpdateDialogState();
}

class _SalesOrderBulkUpdateDialogState
    extends State<_SalesOrderBulkUpdateDialog> {
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
                    'Bulk Update Sales Orders',
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
                'Note: All the selected sales orders will be updated with the new information and you cannot undo this action.',
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

class _SalesOrderNewCustomViewDialog extends StatefulWidget {
  const _SalesOrderNewCustomViewDialog();

  @override
  State<_SalesOrderNewCustomViewDialog> createState() =>
      _SalesOrderNewCustomViewDialogState();
}

class _SalesOrderNewCustomViewDialogState
    extends State<_SalesOrderNewCustomViewDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _criteriaValueController =
      TextEditingController();
  _CustomViewVisibility _visibility = _CustomViewVisibility.onlyMe;
  String? _selectedField;
  String? _selectedComparator;

  bool get _isDirty =>
      _nameController.text.trim().isNotEmpty ||
      (_selectedField?.isNotEmpty ?? false) ||
      (_selectedComparator?.isNotEmpty ?? false) ||
      _criteriaValueController.text.trim().isNotEmpty ||
      _visibility != _CustomViewVisibility.onlyMe;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refresh);
    _criteriaValueController.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameController.removeListener(_refresh);
    _criteriaValueController.removeListener(_refresh);
    _nameController.dispose();
    _criteriaValueController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _closeAttempt() async {
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    final discard = await showUnsavedChangesDialog(
      context,
      title: 'Discard this custom view?',
      message:
          'You have unsaved custom view changes. If you leave now, they will be discarded.',
      stayLabel: 'Stay Here',
      discardLabel: 'Discard Changes',
    );
    if (discard && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ZerpaiToast.info(context, 'Enter a custom view name');
      return;
    }
    Navigator.of(context).pop(
      _SalesOrderCustomViewResult(
        name: name,
        visibilityLabel: _visibilityLabel(_visibility),
      ),
    );
  }

  String _visibilityLabel(_CustomViewVisibility value) {
    switch (value) {
      case _CustomViewVisibility.onlyMe:
        return 'Only Me';
      case _CustomViewVisibility.selectedUsers:
        return 'Selected Users';
      case _CustomViewVisibility.everyone:
        return 'Everyone';
    }
  }

  @override
  Widget build(BuildContext context) {
    const fields = <String>[
      'Status',
      'Customer Name',
      'Sales Order#',
      'Reference#',
      'Delivery Method',
      'Sales person',
    ];
    const comparators = <String>['is', 'is not', 'contains', 'starts with'];

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 760,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
              ),
              child: Row(
                children: [
                  Text(
                    'New Custom View',
                    style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _closeAttempt,
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ZerpaiFormCard(
                    children: [
                      ZerpaiFormRow(
                        label: 'Name',
                        required: true,
                        child: TextField(
                          controller: _nameController,
                          decoration: _dialogInputDecoration(
                            'Sales Orders for Packaging',
                          ),
                        ),
                      ),
                      kZerpaiFormDivider,
                      ZerpaiFormRow(
                        label: 'Define Criteria',
                        crossAxisAlignment: CrossAxisAlignment.start,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: FormDropdown<String>(
                                    value: _selectedField,
                                    items: fields,
                                    hint: 'Select field',
                                    onChanged: (value) =>
                                        setState(() => _selectedField = value),
                                    displayStringForValue: (value) => value,
                                    searchStringForValue: (value) => value,
                                    showSearch: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FormDropdown<String>(
                                    value: _selectedComparator,
                                    items: comparators,
                                    hint: 'Comparator',
                                    onChanged: (value) => setState(
                                      () => _selectedComparator = value,
                                    ),
                                    displayStringForValue: (value) => value,
                                    searchStringForValue: (value) => value,
                                    showSearch: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _criteriaValueController,
                                    decoration: _dialogInputDecoration('Value'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Example: Status is Confirmed',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      kZerpaiFormDivider,
                      ZerpaiFormRow(
                        label: 'Visibility Preference',
                        crossAxisAlignment: CrossAxisAlignment.start,
                        child: ZerpaiRadioGroup<_CustomViewVisibility>(
                          options: _CustomViewVisibility.values,
                          current: _visibility,
                          onChanged: (value) =>
                              setState(() => _visibility = value),
                          orientation: Axis.vertical,
                          labelBuilder: _visibilityLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    height: 36,
                    child: ZButton.secondary(
                      label: 'Cancel',
                      onPressed: _closeAttempt,
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 36,
                    child: ZButton.primary(label: 'Save', onPressed: _save),
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

class _SalesOrderCustomizeColumnsDialog extends StatefulWidget {
  final List<_SalesOrderColumnConfig> columns;

  const _SalesOrderCustomizeColumnsDialog({required this.columns});

  @override
  State<_SalesOrderCustomizeColumnsDialog> createState() =>
      _SalesOrderCustomizeColumnsDialogState();
}

class _SalesOrderCustomizeColumnsDialogState
    extends State<_SalesOrderCustomizeColumnsDialog> {
  late final List<_SalesOrderColumnConfig> _columns;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _columns = widget.columns.map((column) => column.copy()).toList();
  }

  Widget _buildColumnTile(
    _SalesOrderColumnConfig column, {
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
                        onChanged: (value) =>
                            setState(() => column.visible = value ?? false),
                        activeColor: AppTheme.primaryBlue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    final filtered = _columns.where((column) {
      final query = _searchQuery.trim().toLowerCase();
      return query.isEmpty || column.label.toLowerCase().contains(query);
    }).toList();
    final selectedCount = _columns.where((column) => column.visible).length;

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
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
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
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
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
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                                    borderRadius: BorderRadius.circular(4),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
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
                      onPressed: () => Navigator.of(context).pop(_columns),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 32,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppTheme.borderLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
      final highlighted =
          states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused);
      if (isActive) return AppTheme.primaryBlue;
      if (highlighted) {
        return AppTheme.primaryBlueDark;
      }
      return Colors.white;
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      final highlighted =
          states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused);
      if (isActive || highlighted) {
        return Colors.white;
      }
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

InputDecoration _dialogInputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTheme.bodyText.copyWith(
      fontSize: 13,
      color: AppTheme.textMuted,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

String _customerName(SalesOrder order) {
  final customer = order.customer;
  if (customer == null) return 'Unknown customer';
  if (customer.displayName.trim().isNotEmpty)
    return customer.displayName.trim();
  final combined = '${customer.firstName ?? ''} ${customer.lastName ?? ''}'
      .trim();
  return combined.isEmpty ? 'Unknown customer' : combined;
}

String _date(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

String _currency(double value) =>
    '${NumberFormat('#,##,##0.00', 'en_IN').format(value)}';

String _quantity(double value) =>
    value % 1 == 0 ? '${value.toInt()} pcs' : '${value.toStringAsFixed(2)} pcs';

String _discountLabel(SalesOrderItem item) => item.discount == 0
    ? '0'
    : item.discountType == '%'
    ? '${item.discount.toStringAsFixed(0)}%'
    : _currency(item.discount);

int _boolSortValue(bool value) => value ? 1 : 0;

double _lineAmount(SalesOrderItem item) {
  if (item.itemTotal != 0) return item.itemTotal;
  final gross = item.quantity * item.rate;
  return item.discountType == '%'
      ? gross - ((gross * item.discount) / 100)
      : gross - item.discount;
}

bool _isInvoiced(SalesOrder order) =>
    order.status.toLowerCase().contains('invoice') ||
    order.status.toLowerCase().contains('paid');

bool _isPaid(SalesOrder order) => order.status.toLowerCase().contains('paid');

bool _isPacked(SalesOrder order) => order.status.toLowerCase().contains('pack');

bool _isShipped(SalesOrder order) =>
    order.status.toLowerCase().contains('ship') ||
    order.status.toLowerCase().contains('deliver');

String _invoiceLabel(SalesOrder order) =>
    _isInvoiced(order) ? 'INVOICED' : 'NOT INVOICED';

Color _invoiceColor(SalesOrder order) =>
    _isInvoiced(order) ? AppTheme.successDark : AppTheme.textSecondary;

String _paymentLabel(SalesOrder order) => _isPaid(order) ? 'PAID' : 'UNPAID';

Color _paymentColor(SalesOrder order) =>
    _isPaid(order) ? AppTheme.successDark : AppTheme.warningOrange;

String _shipmentLabel(SalesOrder order) =>
    _isShipped(order) ? 'SHIPPED' : 'PENDING';

Color _shipmentColor(SalesOrder order) =>
    _isShipped(order) ? AppTheme.successDark : AppTheme.warningOrange;

String _address(String? value) {
  final normalized = (value ?? '').trim();
  return normalized.isEmpty || normalized == 'N/A'
      ? 'Address not available'
      : normalized.replaceAll(', ', '\n');
}

String _formatAddress(String address) {
  if (address.isEmpty) return address;

  if (address.trim().startsWith('{')) {
    try {
      final data = json.decode(address);
      if (data is Map) {
        final List<String> parts = [];

        if (data['attention'] != null &&
            data['attention'].toString().isNotEmpty) {
          parts.add(data['attention'].toString());
        }
        if (data['street1'] != null && data['street1'].toString().isNotEmpty) {
          parts.add(data['street1'].toString());
        }
        if (data['street2'] != null && data['street2'].toString().isNotEmpty) {
          parts.add(data['street2'].toString());
        }

        final cityStateZip = [
          data['city'],
          data['state_name'] ?? data['state'],
          data['pincode'] ?? data['zip_code'],
        ].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

        if (cityStateZip.isNotEmpty) {
          parts.add(cityStateZip);
        }

        if (data['phone'] != null && data['phone'].toString().isNotEmpty) {
          parts.add('Phone: ${data['phone']}');
        }

        if (parts.isNotEmpty) {
          return parts.join('\n');
        }
      }
    } catch (_) {
      // Fallback to raw string if JSON parsing fails
    }
  }

  return address;
}

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

class _ActionSquare extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _ActionSquare({required this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Icon(icon, size: 16, color: color ?? AppTheme.textBody),
      ),
    );
  }
}

class SalesOrderEmailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const SalesOrderEmailScreen({super.key, required this.orderId});

  @override
  ConsumerState<SalesOrderEmailScreen> createState() =>
      _SalesOrderEmailScreenState();
}

class _SalesOrderEmailScreenState extends ConsumerState<SalesOrderEmailScreen> {
  final _bodyCtrl = TextEditingController();
  bool _isLoading = true;
  SalesOrder? _order;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    try {
      final order = await ref
          .read(salesOrderApiServiceProvider)
          .getSalesOrderById(widget.orderId);
      setState(() {
        _order = order;
        final customerName = order.customer?.displayName ?? 'Customer';

        _bodyCtrl.text =
            '''Dear $customerName,

Thanks for your interest in our services. Please find our sales order attached with this mail.

An overview of the sales order is available below for your reference:

--------------------------------------------------
Sales Order # : [${order.saleNumber}]
--------------------------------------------------

Order Date : ${order.saleDate.toString().substring(0, 10)}
Amount : ₹${order.total.toStringAsFixed(2)}

--------------------------------------------------

Assuring you of our best services at all times.

Regards,
zabnixprivatelimited
ZABNIX PRIVATE LIMITED''';

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading order for email: \$e');
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to load order data');
        context.pop();
      }
    }
  }

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final order = _order!;
    final customerName = order.customer?.displayName ?? 'Customer';

    return EmailComposerScreen(
      title: 'Email To $customerName',
      initialFrom: 'zabnixprivatelimited <zabnixprivatelimited@gmail.com>',
      initialTo:
          '$customerName <${order.customer?.email ?? "customer@example.com"}>',
      initialSubject:
          'Sales Order from ZABNIX PRIVATE LIMITED (Sales Order #: [${order.saleNumber}])',
      initialBody: _bodyCtrl.text,
      attachmentName: '[${order.saleNumber}]',
      onSend: (from, to, subject, body, attachPdf) {
        // Handle send logic here or call backend
        ZerpaiToast.success(context, 'Email sent successfully');
        context.pop();
      },
    );
  }
}
