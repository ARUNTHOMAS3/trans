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
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/z_expandable_tabs.dart';
import 'package:zerpai_erp/shared/widgets/email_composer.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/lock_record_dialog.dart';
import 'package:zerpai_erp/shared/widgets/form_row.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_currency_display.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/po_item_details_sidebar_widget.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/providers/accountant_chart_of_accounts_provider.dart';
import 'package:zerpai_erp/modules/accounts/chart_of_accounts/models/accountant_chart_of_accounts_account_model.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/shared/widgets/z_adaptive_menu.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_item_model.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/data/models/sales_order_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:zerpai_erp/modules/inventory/packages/providers/inventory_packages_provider.dart';
import 'package:zerpai_erp/modules/inventory/picklists/providers/inventory_picklists_provider.dart';
import 'package:zerpai_erp/modules/inventory/packages/models/inventory_package_model.dart';
import 'package:zerpai_erp/modules/inventory/picklists/models/inventory_picklist_model.dart';
import 'package:zerpai_erp/modules/sales/customers/data/models/sales_customer_model.dart';

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
    );
  } catch (_) {
    return order;
  }
});

final _hasStockShortageProvider = FutureProvider.family<bool, String>((ref, orderId) async {
  final order = await ref.watch(_salesOrderDetailProvider(orderId).future);
  final items = order.items ?? [];
  if (items.isEmpty) return false;

  final productIds = items
      .map((i) => i.itemId)
      .where((id) => id.isNotEmpty)
      .toList();
  if (productIds.isEmpty) return false;

  try {
    final response = await ref.read(apiClientProvider).post(
      '/branch_inventory/bulk',
      data: {'product_ids': productIds},
    );
    final responseData = response.data['data'] ?? response.data;
    final stocks = responseData['stocks'] as List<dynamic>? ?? [];

    final Map<String, double> tempMap = {};
    for (final row in stocks) {
      final pId = row['product_id']?.toString() ?? '';
      final stock = ((row['available_stock'] ?? row['current_stock']) ?? 0).toDouble();
      tempMap[pId] = (tempMap[pId] ?? 0.0) + stock;
    }

    for (final item in items) {
      if (item.itemId.isEmpty) continue;
      final stock = tempMap[item.itemId] ?? 0.0;
      if (item.quantity > stock) {
        return true;
      }
    }
  } catch (e) {
    debugPrint('Error checking stock shortage: $e');
  }
  return false;
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

const _soFilterOptions = <FavoriteFilterOption>[
  FavoriteFilterOption(label: 'All', value: 'All'),
  FavoriteFilterOption(label: 'Draft', value: 'Draft'),
  FavoriteFilterOption(label: 'Pending Approval', value: 'Pending Approval'),
  FavoriteFilterOption(label: 'Approved', value: 'Approved'),
  FavoriteFilterOption(label: 'Confirmed', value: 'Confirmed'),
  FavoriteFilterOption(label: 'For Packaging', value: 'For Packaging'),
  FavoriteFilterOption(label: 'To be Shipped', value: 'To be Shipped'),
  FavoriteFilterOption(label: 'Shipped', value: 'Shipped'),
  FavoriteFilterOption(label: 'Onhold', value: 'Onhold'),
  FavoriteFilterOption(label: 'Fulfilled', value: 'Fulfilled'),
  FavoriteFilterOption(label: 'Closed', value: 'Closed'),
  FavoriteFilterOption(label: 'Customer Viewed', value: 'Customer Viewed'),
  FavoriteFilterOption(label: 'Manually Fulfilled', value: 'Manually Fulfilled'),
  FavoriteFilterOption(label: 'For Invoicing', value: 'For Invoicing'),
  FavoriteFilterOption(label: 'Drop Shipped', value: 'Drop Shipped'),
  FavoriteFilterOption(label: 'Backorder', value: 'Backorder'),
  FavoriteFilterOption(label: 'Marketplace', value: 'Marketplace'),
  FavoriteFilterOption(label: 'Void', value: 'Void'),
  FavoriteFilterOption(label: 'Invoiced', value: 'Invoiced'),
  FavoriteFilterOption(label: 'Shipped & Not Invoiced', value: 'Shipped & Not Invoiced'),
  FavoriteFilterOption(label: 'Invoiced & Not Shipped', value: 'Invoiced & Not Shipped'),
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
  FavoriteFilterOption _activeOption = _soFilterOptions.first;
  _SalesOrderView _activeView = _salesOrderViews.first;
  _SalesOrderSortField _activeSortField = _SalesOrderSortField.salesOrderNumber;
  bool _isAscending = true;
  bool _clipText = true;
  Set<String> _selectedSaleIds = <String>{};
  late List<_SalesOrderColumnConfig> _columnConfigs;
  Map<String, double>? _customColumnWidths;

  List<_SalesOrderColumnConfig> get _visibleColumns =>
      _columnConfigs.where((column) => column.visible).toList();

  final Map<String, _SoStatusSummary> _statusSummaries = {};
  String get _orgId => GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
  List<SalesOrder>? _lastLoadedOrders;
  OverlayEntry? _statsOverlayEntry;
  final LayerLink _statsLink = LayerLink();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(salesOrderControllerProvider);
      ref.invalidate(warehousesProvider);
      ref.read(inventoryPackagesProvider.notifier).fetchPackages();
    });
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
    if (widget.initialFilter != null) {
      final found = _soFilterOptions.where(
        (v) => v.label.toLowerCase() == widget.initialFilter!.toLowerCase(),
      );
      if (found.isNotEmpty) {
        _activeOption = found.first;
        _activeView = _salesOrderViews.firstWhere(
          (v) => v.label == (_activeOption.label == 'All' ? 'All Sales Orders' : _activeOption.label),
          orElse: () => _salesOrderViews.first,
        );
      }
    }
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
    _statsOverlayEntry?.remove();
    _statsOverlayEntry = null;
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

  void _handleCreateAction(String actionLabel, SalesOrder order) {
    switch (actionLabel) {
      case 'Picklist':
        context.go('${AppRoutes.picklistsCreate}?salesOrderId=${order.id}');
        return;
      case 'Package':
        context.go('${AppRoutes.packagesCreate}?salesOrderId=${order.id}');
        return;
      case 'Shipment':
        context.go('${AppRoutes.shipmentsCreate}?salesOrderId=${order.id}');
        return;
      case 'Instant Invoice':
        context.go('${AppRoutes.salesInvoicesCreate}?fromOrderId=${order.id}');
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

  Future<void> _fetchStatusSummaries(List<SalesOrder> sales) async {
    if (sales.isEmpty) return;

    final orderIds = sales.map((o) => o.id).toList();
    if (_lastLoadedOrders != null && _lastLoadedOrders!.length == sales.length) {
      final match = _lastLoadedOrders!.every((o) => orderIds.contains(o.id));
      if (match) return;
    }
    _lastLoadedOrders = List.from(sales);

    try {
      final supabase = Supabase.instance.client;

      // 1. Invoices
      final invLinks = await supabase
          .from('invoice_sales_orders')
          .select('sales_order_id, invoice_id')
          .inFilter('sales_order_id', orderIds);
      final invLinkList = List<Map<String, dynamic>>.from(invLinks as List);
      final invoiceIds = invLinkList.map((l) => l['invoice_id'] as String).toList();

      List<Map<String, dynamic>> invoiceItemsList = [];
      if (invoiceIds.isNotEmpty) {
        final invItems = await supabase
            .from('invoice_items')
            .select('invoice_id, product_id, quantity')
            .inFilter('invoice_id', invoiceIds);
        invoiceItemsList = List<Map<String, dynamic>>.from(invItems as List);
      }

      final Map<String, Map<String, double>> orderInvoicedQtys = {};
      for (final link in invLinkList) {
        final soId = link['sales_order_id'] as String;
        final invId = link['invoice_id'] as String;
        final items = invoiceItemsList.where((i) => i['invoice_id'] == invId);

        orderInvoicedQtys.putIfAbsent(soId, () => {});
        for (final item in items) {
          final prodId = item['product_id'] as String;
          final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
          orderInvoicedQtys[soId]![prodId] = (orderInvoicedQtys[soId]![prodId] ?? 0.0) + qty;
        }
      }

      // 2. Packages
      final packItems = await supabase
          .from('inventory_package_items')
          .select('sales_order_id, product_id, quantity')
          .inFilter('sales_order_id', orderIds);
      final packItemsList = List<Map<String, dynamic>>.from(packItems as List);

      final Map<String, Map<String, double>> orderPackQtys = {};
      for (final item in packItemsList) {
        final soId = item['sales_order_id'] as String?;
        if (soId == null) continue;
        final prodId = item['product_id'] as String;
        final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;

        orderPackQtys.putIfAbsent(soId, () => {});
        orderPackQtys[soId]![prodId] = (orderPackQtys[soId]![prodId] ?? 0.0) + qty;
      }

      // 3. Shipments
      final shipLinks = await supabase
          .from('inventory_shipment_sales_orders')
          .select('sales_order_id, shipment_id')
          .inFilter('sales_order_id', orderIds);
      final shipLinkList = List<Map<String, dynamic>>.from(shipLinks as List);
      final shipmentIds = shipLinkList.map((l) => l['shipment_id'] as String).toList();

      List<Map<String, dynamic>> shipPackList = [];
      if (shipmentIds.isNotEmpty) {
        final shipPacks = await supabase
            .from('inventory_shipment_packages')
            .select('shipment_id, package_id')
            .inFilter('shipment_id', shipmentIds);
        shipPackList = List<Map<String, dynamic>>.from(shipPacks as List);
      }
      final shipPackageIds = shipPackList.map((l) => l['package_id'] as String).toList();

      List<Map<String, dynamic>> shipPackItemsList = [];
      if (shipPackageIds.isNotEmpty) {
        final packItems = await supabase
            .from('inventory_package_items')
            .select('package_id, product_id, quantity')
            .inFilter('package_id', shipPackageIds);
        shipPackItemsList = List<Map<String, dynamic>>.from(packItems as List);
      }

      final Map<String, Map<String, double>> orderShippedQtys = {};
      for (final link in shipLinkList) {
        final soId = link['sales_order_id'] as String;
        final shipId = link['shipment_id'] as String;
        final packages = shipPackList.where((p) => p['shipment_id'] == shipId).map((p) => p['package_id'] as String).toSet();
        final items = shipPackItemsList.where((i) => packages.contains(i['package_id']));

        orderShippedQtys.putIfAbsent(soId, () => {});
        for (final item in items) {
          final prodId = item['product_id'] as String;
          final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
          orderShippedQtys[soId]![prodId] = (orderShippedQtys[soId]![prodId] ?? 0.0) + qty;
        }
      }

      // 4. Picklists
      final pickItems = await supabase
          .from('picklist_items')
          .select('sales_order_id, product_id, qty_ordered, qty_picked')
          .inFilter('sales_order_id', orderIds);
      final pickItemsList = List<Map<String, dynamic>>.from(pickItems as List);

      final Map<String, Map<String, double>> orderPickedQtys = {};
      for (final item in pickItemsList) {
        final soId = item['sales_order_id'] as String?;
        if (soId == null) continue;
        final prodId = item['product_id'] as String;
        final qty = double.tryParse(item['qty_picked']?.toString() ?? '0') ?? 0.0;

        orderPickedQtys.putIfAbsent(soId, () => {});
        orderPickedQtys[soId]![prodId] = (orderPickedQtys[soId]![prodId] ?? 0.0) + qty;
      }

      // 4.5. Sales Order Items
      final orderItemsList = await supabase
          .from('sales_order_items')
          .select('sales_order_id, product_id, quantity')
          .inFilter('sales_order_id', orderIds);
      final List<Map<String, dynamic>> orderItems = List<Map<String, dynamic>>.from(orderItemsList as List);

      // 5. Enforce Status Calculation
      for (final order in sales) {
        final items = orderItems.where((i) => i['sales_order_id'] == order.id).toList();
        if (items.isEmpty) {
          _statusSummaries[order.id] = const _SoStatusSummary(
            invoiceStatus: 'none',
            packageStatus: 'none',
            shipmentStatus: 'none',
            picklistStatus: 'none',
          );
          continue;
        }

        double totalOrdered = 0.0;
        double totalInvoiced = 0.0;
        double totalPackaged = 0.0;
        double totalShipped = 0.0;
        double totalPicked = 0.0;

        for (final item in items) {
          final qty = double.tryParse(item['quantity']?.toString() ?? '0') ?? 0.0;
          totalOrdered += qty;

          final prodId = item['product_id'] as String?;
          if (prodId != null && prodId.isNotEmpty) {
            totalInvoiced += orderInvoicedQtys[order.id]?[prodId] ?? 0.0;
            totalPackaged += orderPackQtys[order.id]?[prodId] ?? 0.0;
            totalShipped += orderShippedQtys[order.id]?[prodId] ?? 0.0;
            totalPicked += orderPickedQtys[order.id]?[prodId] ?? 0.0;
          }
        }

        final invStatus = totalInvoiced <= 0.0
            ? 'none'
            : totalInvoiced < totalOrdered - 0.001
            ? 'partial'
            : 'full';

        final pkgStatus = totalPackaged <= 0.0
            ? 'none'
            : totalPackaged < totalOrdered - 0.001
            ? 'partial'
            : 'full';

        final shpStatus = totalShipped <= 0.0
            ? 'none'
            : totalShipped < totalOrdered - 0.001
            ? 'partial'
            : 'full';

        final pckStatus = totalPicked <= 0.0
            ? 'none'
            : totalPicked < totalOrdered - 0.001
            ? 'partial'
            : 'full';

        _statusSummaries[order.id] = _SoStatusSummary(
          invoiceStatus: invStatus,
          packageStatus: pkgStatus,
          shipmentStatus: shpStatus,
          picklistStatus: pckStatus,
        );
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error fetching status summaries: $e');
    }
  }

  Widget _buildStatusCircle(String status, Color color, double width, String tooltip) {
    Widget ball;
    if (status == 'full') {
      ball = Icon(
        Icons.circle,
        color: color,
        size: 12,
      );
    } else if (status == 'partial') {
      ball = Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            Icons.circle_outlined,
            color: color,
            size: 12,
          ),
          ClipRect(
            child: Align(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5,
              child: Icon(
                Icons.circle,
                color: color,
                size: 12,
              ),
            ),
          ),
        ],
      );
    } else {
      ball = const Icon(
        Icons.circle,
        color: Colors.grey,
        size: 12,
      );
    }
    return SizedBox(
      width: width,
      child: Center(
        child: ZTooltip(
          message: tooltip,
          child: ball,
        ),
      ),
    );
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _fetchStatusSummaries(sales);
          });
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
              child: FavoriteFilterDropdown(
                moduleName: 'sales_orders',
                options: _soFilterOptions,
                selectedOption: _activeOption,
                showChevron: true,
                onChanged: (opt) {
                  setState(() {
                    _activeOption = opt;
                    _activeView = _salesOrderViews.firstWhere(
                      (v) => v.label == (opt.label == 'All' ? 'All Sales Orders' : opt.label),
                      orElse: () => _salesOrderViews.first,
                    );
                  });
                },
              ),
            ),

          const Spacer(),
          if (!hasSelection) ...[
            if (ref.watch(entityProvider).type == 'ORG')
              TextButton(
                onPressed: () {
                  _showRemainingPoApprovalDialog(context);
                },
                child: const Text('Purchase Order Approval'),
              ),
            const SizedBox(width: 12),
            CompositedTransformTarget(
              link: _statsLink,
              child: TextButton(
                onPressed: () {
                  _showOrderStatsPopover(context);
                },
                child: const Text('View Order Stats'),
              ),
            ),
            const SizedBox(width: 12),
            ZButton.primary(
              onPressed: () => context.go('/sales/orders/create'),
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

  List<Widget> _buildMoreMenuChildren() {
    return [
      SubmenuButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        menuStyle: ZTableMoreMenu.submenuMenuStyle(),
        alignmentOffset: const Offset(4, 0),
        leadingIcon: const Icon(LucideIcons.arrowUpDown, size: 16),
        menuChildren: [
          _buildSortMenuItem('Sales Order#', _SalesOrderSortField.salesOrderNumber),
          _buildSortMenuItem('Date', _SalesOrderSortField.date),
          _buildSortMenuItem('Customer Name', _SalesOrderSortField.customerName),
          _buildSortMenuItem('Amount', _SalesOrderSortField.amount),
          _buildSortMenuItem('Created Time', _SalesOrderSortField.createdTime),
          _buildSortMenuItem('Last Modified Time', _SalesOrderSortField.lastModifiedTime),
          _buildSortMenuItem('Expected Shipment Date', _SalesOrderSortField.expectedShipmentDate),
        ],
        child: const Text('Sort by'),
      ),
      MenuItemButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        leadingIcon: const Icon(LucideIcons.download, size: 16),
        onPressed: () {},
        child: const Text('Import Sales Orders'),
      ),
      SubmenuButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        menuStyle: ZTableMoreMenu.submenuMenuStyle(),
        alignmentOffset: const Offset(4, 0),
        leadingIcon: const Icon(LucideIcons.upload, size: 16),
        menuChildren: [
          MenuItemButton(
            style: ZTableMoreMenu.menuItemButtonStyle(),
            onPressed: () {},
            child: const Text('Export Sales Orders'),
          ),
          MenuItemButton(
            style: ZTableMoreMenu.menuItemButtonStyle(),
            onPressed: () {},
            child: const Text('Export Current View'),
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
        leadingIcon: const Icon(LucideIcons.refreshCw, size: 16),
        onPressed: () => ref
            .read(salesOrderControllerProvider.notifier)
            .loadSalesOrders(),
        child: const Text('Refresh List'),
      ),
    ];
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
      final selectedIds = _selectedSaleIds.toList();
      final response = await supabase
          .from('sales_orders')
          .select('id, sale_number')
          .filter('id', 'in', selectedIds);
      
      for (final row in response) {
        final id = row['id'] as String;
        final currentNum = row['sale_number'] as String;
        final newNum = currentNum.startsWith('SD-') ? currentNum : 'SD-$currentNum';
        await supabase
            .from('sales_orders')
            .update({
              'is_delete': true,
              'sale_number': newNum,
            })
            .eq('id', id);
      }

      ZerpaiToast.success(
        context,
        'Deleted ${selectedIds.length} sales order(s)',
      );
      _clearSelection();
      ref
          .read(salesOrderControllerProvider.notifier)
          .deleteOrdersLocally(selectedIds);
    } catch (e) {
      ZerpaiToast.error(context, 'Error deleting sales orders: $e');
    }
  }

  MenuItemButton _detailActionMenuItem(String label, SalesOrder order, {IconData? icon}) {
    return MenuItemButton(
      style: _menuItemStyle(),
      onPressed: () => _handleDetailAction(label, order),
      leadingIcon: icon != null ? Icon(icon, size: 16) : null,
      child: SizedBox(
        width: 180,
        child: Text(label),
      ),
    );
  }

  void _handleDetailAction(String action, SalesOrder order) {
    if (action == 'Delete') {
      _deleteSingleOrder(order.id);
    } else if (action == 'Convert to Invoice') {
      context.go('${AppRoutes.salesInvoicesCreate}?fromOrderId=${order.id}');
    } else if (action == 'Convert to Purchase Order') {
      _convertToPurchaseOrder(order);
    } else if (action == 'Cancel Items') {
      _cancelSalesOrderItems(order);
    } else if (action == 'Reopen cancelled items') {
      _reopenCancelledItems(order);
    } else if (action == 'Void') {
      _voidSalesOrder(order);
    } else if (action == 'Clone') {
      _cloneSalesOrder(order);
    } else if (action == 'Dropship') {
      _showDropshipTypeDialog(order);
    } else if (action == 'Convert to Confirmed') {
      _showReasonDialog(context, order, 'confirmed');
    } else if (action == 'Backorder') {
      _showBackorderDialog(order);
    } else if (action == 'Lock sales order') {
      _showLockSalesOrderDialog(order);
    } else {
      _showUnavailableAction(action);
    }
  }

  void _showLockSalesOrderDialog(SalesOrder order) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (dialogCtx) {
        return LockRecordDialog(
          title: 'Lock sales order',
          onLock: (config, reason) {
            Navigator.of(dialogCtx).pop();
            if (mounted) {
              ZerpaiToast.success(
                context,
                '${order.saleNumber} has been locked successfully.',
              );
            }
          },
        );
      },
    );
  }

  void _reopenCancelledItems(SalesOrder order) async {
    try {
      final supabase = Supabase.instance.client;
      for (final item in order.items ?? []) {
        if (item.id == null) continue;
        await supabase
            .from('sales_order_items')
            .update({'cancelled_quantity': 0.0})
            .eq('id', item.id!);
      }

      final isCancelled = order.status.toLowerCase() == 'cancelled' || order.status.toLowerCase() == 'canceled';
      final newStatus = isCancelled ? 'Draft' : order.status;

      await supabase
          .from('sales_orders')
          .update({'status': newStatus})
          .eq('id', order.id);

      ref.invalidate(salesOrderControllerProvider);
      ref.invalidate(_salesOrderDetailProvider(order.id));

      if (mounted) {
        ZerpaiToast.success(context, 'Canceled items reopened successfully');
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to reopen items: $e');
      }
    }
  }

  String? _getAccountName(String? purchaseAccountId) {
    if (purchaseAccountId == null || purchaseAccountId.isEmpty) return null;
    final accountsState = ref.read(chartOfAccountsProvider);
    final List<AccountNode> availableAccounts = [];
    void collect(List<AccountNode> nodes) {
      for (final node in nodes) {
        availableAccounts.add(node);
        collect(node.children);
      }
    }
    collect(accountsState.roots);
    try {
      return availableAccounts.firstWhere((acc) => acc.id == purchaseAccountId).name;
    } catch (_) {
      return null;
    }
  }

  void _convertToPurchaseOrder(SalesOrder order) {
    final po = PurchaseOrder(
      orderNumber: '',
      orderDate: DateTime.now(),
      vendorId: '', // User will select vendor
      notes: order.customerNotes,
      termsAndConditions: order.termsAndConditions,
      discount: order.discountTotal,
      discountType: 'percentage', // default
      adjustment: order.adjustment,
      subTotal: order.subTotal,
      taxAmount: order.taxTotal,
      total: order.total,
      items: (order.items ?? []).map((item) {
        final purchaseAccountId = item.item?.purchaseAccountId;
        final purchaseAccountName = _getAccountName(purchaseAccountId);
        return PurchaseOrderItem(
          productId: item.itemId,
          productName: item.item?.productName ?? item.description,
          hsnCode: item.hsnCode ?? item.item?.hsnCode,
          itemCode: item.item?.itemCode,
          description: item.description,
          accountId: purchaseAccountId,
          accountName: purchaseAccountName,
          quantity: item.quantity,
          rate: item.rate,
          amount: item.itemTotal,
          taxId: item.taxId,
          taxRate: item.taxPercentage,
          taxAmount: item.taxAmount,
          discount: item.discount,
          discountType: item.discountType == '%' ? 'percentage' : 'fixed',
        );
      }).toList(),
    );

    context.push('/$_orgId/purchases/purchase-orders/create', extra: po);
  }

  void _showReasonDialog(BuildContext context, SalesOrder order, String targetStatus) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _ReasonInputDialog(
          order: order,
          targetStatus: targetStatus,
          onConfirm: (reason) async {
            try {
              await ref
                  .read(salesOrderControllerProvider.notifier)
                  .updateSalesOrderStatus(order.id, targetStatus, reason);

              ref.read(apiClientProvider).clearCache('sales');
              ref.invalidate(_salesOrderDetailProvider(order.id));

              if (context.mounted) {
                ZerpaiToast.success(
                  context,
                  targetStatus == 'void'
                      ? 'Sales order marked as Void'
                      : targetStatus == 'completed'
                          ? 'Sales order marked as Completed'
                          : 'Sales order converted to Confirmed',
                );
              }
            } catch (e) {
              if (context.mounted) {
                ZerpaiToast.error(
                  context,
                  'Failed to update status: $e',
                );
              }
            }
          },
        );
      },
    );
  }

  Future<void> _voidSalesOrder(SalesOrder order) async {
    _showReasonDialog(context, order, 'void');
  }

  void _showBackorderDialog(SalesOrder order) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) {
        return Dialog(
          alignment: Alignment.topCenter,
          insetPadding: const EdgeInsets.only(top: 0),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: _BackorderDialog(
              order: order,
              orgId: _orgId,
            ),
          ),
        );
      },
    );
  }

  void _cloneSalesOrder(SalesOrder order) {
    context.push(
      '/$_orgId/sales/orders/create?clone=true&cloneId=${order.id}',
      extra: order,
    );
  }

  void _showDropshipTypeDialog(SalesOrder order) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) {
        return Dialog(
          alignment: Alignment.topCenter,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          insetPadding: const EdgeInsets.only(top: 0, left: 40, right: 40, bottom: 40),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _DropshipTypeDialog(order: order, orgId: _orgId),
          ),
        );
      },
    );
  }

  void _cancelSalesOrderItems(SalesOrder order) {
    bool hasCancellableItems = false;
    for (final item in order.items ?? []) {
      final remaining = item.quantity - item.cancelledQuantity;
      if (remaining > 0) {
        hasCancellableItems = true;
        break;
      }
    }

    if (!hasCancellableItems) {
      ZerpaiToast.error(
        context,
        'There are no Item(s) available to be cancelled in this Sales Order.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _CancelSalesItemsDialog(
        order: order,
        onProceed: () {
          ref.invalidate(salesOrderControllerProvider);
          ref.invalidate(_salesOrderDetailProvider(order.id));
        },
      ),
    );
  }

  Future<void> _deleteSingleOrder(String id) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('sales_orders')
          .select('sale_number')
          .eq('id', id)
          .maybeSingle();

      String? newNum;
      if (response != null && response['sale_number'] != null) {
        final currentNum = response['sale_number'] as String;
        newNum = currentNum.startsWith('SD-') ? currentNum : 'SD-$currentNum';
      }

      await supabase
          .from('sales_orders')
          .update({
            'is_delete': true,
            if (newNum != null) 'sale_number': newNum,
          })
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
    final configs = working.map((c) => ColumnConfig(
      id: c.key.name,
      label: c.label,
      isVisible: c.visible,
      isLocked: c.locked,
      orderIndex: working.indexOf(c),
    )).toList();

    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      builder: (dialogContext) => ColumnCustomizerDialog(
        columns: configs,
        onSave: (saved) {
          final List<_SalesOrderColumnConfig> newColumns = [];
          for (final cc in saved) {
            final originalCol = working.firstWhere((c) => c.key.name == cc.id);
            originalCol.visible = cc.isVisible;
            newColumns.add(originalCol);
          }
          Navigator.of(dialogContext).pop();
          setState(() {
            _columnConfigs = newColumns;
          });
          ZerpaiToast.success(context, 'Column preferences saved');
        },
      ),
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
                      moduleName: 'sales_orders',
                      options: _soFilterOptions,
                      selectedOption: _activeOption,
                      showChevron: true,
                      isCompact: true,
                      onChanged: (opt) {
                        setState(() {
                          _activeOption = opt;
                          _activeView = _salesOrderViews.firstWhere(
                            (v) => v.label == (opt.label == 'All' ? 'All Sales Orders' : opt.label),
                            orElse: () => _salesOrderViews.first,
                          );
                        });
                      },
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => context.go('/sales/orders/create'),
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

        final packagesState = ref.watch(inventoryPackagesProvider);
        final packages = packagesState.packages;
        final orderPackages = packages
            .where((p) =>
                p.salesOrderIds.contains(order.id) ||
                p.salesOrderNumbers.contains(order.saleNumber))
            .toList();

        final picklistsAsync = ref.watch(picklistsProvider);
        final picklists = picklistsAsync.valueOrNull ?? [];
        final orderPicklists = picklists
            .where((p) =>
                p.salesOrderIds.contains(order.id) ||
                p.salesOrderNumbers.contains(order.saleNumber) ||
                p.salesOrderNumber == order.saleNumber ||
                p.items.any((item) => item.salesOrderId == order.id))
            .toList();

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
                        style: AppTheme.sectionHeader.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
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
                      if (order.status.toLowerCase() == 'void') ...[
                        _buildPdfPrintDropdown(order, orgSettings),
                        _buildDivider(),
                        _buildMoreButton(order),
                      ] else if (order.status.toLowerCase() == 'draft') ...[
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
                          LucideIcons.checkCircle,
                          'Mark as Confirmed',
                          onPressed: () => _showReasonDialog(context, order, 'confirmed'),
                        ),
                        _buildDivider(),
                        _ActionSplitMenu(
                          icon: LucideIcons.plusCircle,
                          label: 'Create',
                          onPrimaryTap: () => _showUnavailableAction('Create'),
                          onSelected: (action) => _handleCreateAction(action, order),
                        ),
                        _buildDivider(),
                        _buildMoreButton(order),
                      ] else ...[
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
                          icon: LucideIcons.plusCircle,
                          label: 'Create',
                          onPrimaryTap: () => _showUnavailableAction('Create'),
                          onSelected: (action) => _handleCreateAction(action, order),
                        ),
                        _buildDivider(),
                        _buildMoreButton(order),
                      ],
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
                                    children: [
                                      const TextSpan(
                                        text: 'WHAT\'S NEXT? ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: order.status.toLowerCase() == 'draft'
                                            ? 'Send this Sales Order to your customer by email or mark it as Confirmed.'
                                            : 'Convert the sales order into packages, shipments, or invoices.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (order.status.toLowerCase() == 'draft') ...[
                                SizedBox(
                                  height: 34,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      context.push(
                                        AppRoutes.salesOrdersEmail.replaceAll(
                                          ':id',
                                          order.id,
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF22A95E),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    child: const Text(
                                      'Send Sales Order',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 34,
                                  child: OutlinedButton(
                                    onPressed: () => _showReasonDialog(context, order, 'confirmed'),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                                      foregroundColor: const Color(0xFF4B5563),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    child: const Text(
                                      'Mark as Confirmed',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                SizedBox(
                                  height: 34,
                                  width: 100,
                                  child: MenuAnchor(
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
                                    builder: (context, controller, child) {
                                      return ElevatedButton(
                                        onPressed: () {
                                          if (controller.isOpen) {
                                            controller.close();
                                          } else {
                                            controller.open();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Convert',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 4),
                                            Icon(
                                              Icons.keyboard_arrow_down,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    menuChildren: [
                                      MenuItemButton(
                                        style: ZTableMoreMenu.menuItemButtonStyle().copyWith(
                                          minimumSize: const WidgetStatePropertyAll(Size(130, 44)),
                                          shape: const WidgetStatePropertyAll(
                                            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                          ),
                                        ),
                                        onPressed: () {
                                          context.go('${AppRoutes.salesInvoicesCreate}?fromOrderId=${order.id}');
                                        },
                                        child: const Text('Convert to Invoice'),
                                      ),
                                      MenuItemButton(
                                        style: ZTableMoreMenu.menuItemButtonStyle().copyWith(
                                          minimumSize: const WidgetStatePropertyAll(Size(130, 44)),
                                          shape: const WidgetStatePropertyAll(
                                            RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                          ),
                                        ),
                                        onPressed: () {
                                          final hasNonBatchTrackedItem = (order.items ?? []).any((item) {
                                            return item.item?.trackBatches != true;
                                          });
                                          if (hasNonBatchTrackedItem) {
                                            ZerpaiToast.error(
                                              context,
                                              'non batch track items cannot be instant invoiced.',
                                            );
                                            return;
                                          }
                                          context.go(
                                            '${AppRoutes.salesInvoicesCreate}?fromOrderId=${order.id}&instant=true',
                                          );
                                        },
                                        child: const Text('Instant Invoice'),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 34,
                                  child: ZButton.secondary(
                                    label: 'Create Package',
                                    onPressed: () {
                                      context.go('${AppRoutes.packagesCreate}?salesOrderId=${order.id}');
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        ZExpandableTabs(
                          contentPadding: EdgeInsets.zero,
                          tabs: [
                            'Packages ${orderPackages.length}',
                            'Picklists ${orderPicklists.length}',
                          ],
                          children: [
                            _buildPackagesTab(orderPackages),
                            _buildPicklistsTab(orderPicklists),
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
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      builder: (context, controller, _) => SizedBox(
        width: 100,
        child: _buildToolbarButton(
          LucideIcons.printer,
          'PDF/Print',
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        ),
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
            animationDuration: Duration.zero,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
                  ? AppTheme.primaryBlue
                  : Colors.transparent,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
                  ? Colors.white
                  : AppTheme.textSecondary,
            ),
            iconColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
                  ? Colors.white
                  : AppTheme.textSecondary,
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            minimumSize: const WidgetStatePropertyAll(Size(100, 44)),
            alignment: Alignment.centerLeft,
            shape: WidgetStateProperty.all<OutlinedBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          leadingIcon: const Icon(LucideIcons.fileText, size: 16),
          child: const Text('PDF', style: TextStyle(fontSize: 14)),
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
            animationDuration: Duration.zero,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
                  ? AppTheme.primaryBlue
                  : Colors.transparent,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
                  ? Colors.white
                  : AppTheme.textSecondary,
            ),
            iconColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)
                  ? Colors.white
                  : AppTheme.textSecondary,
            ),
            padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            minimumSize: const WidgetStatePropertyAll(Size(100, 44)),
            alignment: Alignment.centerLeft,
            shape: WidgetStateProperty.all<OutlinedBorder>(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
          ),
          leadingIcon: const Icon(LucideIcons.printer, size: 16),
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
    bool isHovered = false;
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isHovered ? Colors.white : Colors.transparent,
                border: Border.all(
                  color: isHovered ? const Color(0xFFD3D9E3) : Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoreButton(SalesOrder order) {
    bool isHovered = false;
    final hasShortage = ref.watch(_hasStockShortageProvider(order.id)).value ?? false;
    final hasCancelledItems = (order.items ?? []).any((item) => item.cancelledQuantity > 0);
    return StatefulBuilder(
      builder: (context, setState) {
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: MenuAnchor(
            style: _menuStyle(),
            builder: (context, controller, child) {
              return GestureDetector(
                onTap: () => controller.isOpen ? controller.close() : controller.open(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: isHovered || controller.isOpen ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: isHovered || controller.isOpen ? const Color(0xFFD3D9E3) : Colors.transparent,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    LucideIcons.moreHorizontal,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            },
            menuChildren: order.status.toLowerCase() == 'draft'
                ? [
                    _detailActionMenuItem('Convert to Invoice', order),
                    _detailActionMenuItem('Convert to Purchase Order', order),
                    _detailActionMenuItem('Clone', order),
                    _detailActionMenuItem('Delete', order),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    _detailActionMenuItem(
                      'Lock sales order',
                      order,
                      icon: LucideIcons.lock,
                    ),
                  ]
                : order.status.toLowerCase() == 'void'
                    ? [
                        _detailActionMenuItem('Convert to Confirmed', order),
                        if (hasCancelledItems) _detailActionMenuItem('Reopen cancelled items', order),
                        _detailActionMenuItem('Clone', order),
                        _detailActionMenuItem('Delete', order),
                        const Divider(height: 1, color: AppTheme.borderLight),
                        _detailActionMenuItem(
                          'Lock sales order',
                          order,
                          icon: LucideIcons.lock,
                        ),
                      ]
                    : [
                        _detailActionMenuItem('Convert to Purchase Order', order),
                        _detailActionMenuItem('Dropship', order),
                        _detailActionMenuItem('Cancel Items', order),
                        if (hasCancelledItems) _detailActionMenuItem('Reopen cancelled items', order),
                        _detailActionMenuItem('Void', order),
                        if (hasShortage) _detailActionMenuItem('Backorder', order),
                        _detailActionMenuItem('Clone', order),
                        _detailActionMenuItem('Delete', order),
                        const Divider(height: 1, color: AppTheme.borderLight),
                        _detailActionMenuItem(
                          'Lock sales order',
                          order,
                          icon: LucideIcons.lock,
                        ),
                      ],
          ),
        );
      },
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
                          item.item?.productName ??
                              item.item?.billingName ??
                              item.description ??
                              item.item?.itemCode ??
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
        final status = _statusSummaries[sale.id]?.invoiceStatus ?? 'none';
        final tooltip = status == 'full'
            ? 'Invoiced'
            : status == 'partial'
                ? 'Partially Invoiced'
                : 'Not Invoiced';
        return _buildStatusCircle(status, Colors.green, w, tooltip);
      case _SalesOrderColumnKey.payment:
        return _StateDot(
          width: w,
          active: _isPaid(sale),
          tooltip: _paymentLabel(sale),
          activeIcon: LucideIcons.creditCard,
        );

      case _SalesOrderColumnKey.packed:
        final status = _statusSummaries[sale.id]?.packageStatus ?? 'none';
        final tooltip = status == 'full'
            ? 'Packed'
            : status == 'partial'
                ? 'Partially Packed'
                : 'Not Packed';
        return _buildStatusCircle(status, Colors.orange, w, tooltip);
      case _SalesOrderColumnKey.shipped:
        final status = _statusSummaries[sale.id]?.shipmentStatus ?? 'none';
        final tooltip = status == 'full'
            ? 'Shipped'
            : status == 'partial'
                ? 'Partially Shipped'
                : 'Not Shipped';
        return _buildStatusCircle(status, Colors.red, w, tooltip);
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
        final status = _statusSummaries[sale.id]?.picklistStatus ?? 'none';
        final tooltip = status == 'full'
            ? 'Picked'
            : status == 'partial'
                ? 'Partially Picked'
                : 'Not Picked';
        return _buildStatusCircle(status, Colors.blue, w, tooltip);
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
                                (() {
                                  bool isItemHovered = false;
                                  return StatefulBuilder(
                                    builder: (innerContext, setStateItem) => InkWell(
                                      onHover: (val) {
                                        setStateItem(() => isItemHovered = val);
                                      },
                                      onTap: () {
                                        if (item.itemId.isNotEmpty) {
                                          POItemDetailsSidebar.show(
                                            innerContext,
                                            PurchaseOrderItem(
                                              productId: item.itemId,
                                              productName: item.item?.productName ?? item.description,
                                              quantity: item.quantity,
                                              rate: item.rate,
                                              amount: item.itemTotal,
                                            ),
                                          );
                                        }
                                      },
                                      hoverColor: AppTheme.primaryBlue,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isItemHovered ? AppTheme.primaryBlue : Colors.transparent,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          item.item?.productName ??
                                              item.item?.billingName ??
                                              item.description ??
                                              item.item?.itemCode ??
                                              'Unnamed item',
                                          style: AppTheme.linkText.copyWith(
                                            color: isItemHovered ? Colors.white : AppTheme.primaryBlue,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                })(),
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
                          return '';
                        }(),
                        style: AppTheme.bodyText.copyWith(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.pickedQuantity.toInt()} Picked',
                            style: AppTheme.bodyText.copyWith(fontSize: 11),
                          ),
                          Text(
                            '${item.packedQuantity.toInt()} Packed',
                            style: AppTheme.bodyText.copyWith(fontSize: 11),
                          ),
                          Text(
                            '${item.shippedQuantity.toInt()} Shipped',
                            style: AppTheme.bodyText.copyWith(fontSize: 11),
                          ),
                          Text(
                            '${item.invoicedQuantity.toInt()} Invoiced',
                            style: AppTheme.bodyText.copyWith(fontSize: 11),
                          ),
                          if (item.cancelledQuantity > 0)
                            Text(
                              item.cancelledQuantity >= item.quantity
                                  ? 'Cancelled'
                                  : '${item.cancelledQuantity.toInt()} Cancelled',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 11,
                                color: AppTheme.errorRed,
                              ),
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

  void _showOrderStatsPopover(BuildContext context) {
    if (_statsOverlayEntry != null) {
      _statsOverlayEntry!.remove();
      _statsOverlayEntry = null;
      return;
    }

    _statsOverlayEntry = ZAdaptiveMenu.show(
      context: context,
      link: _statsLink,
      width: 280,
      alignLeft: false,
      onClose: () {
        _statsOverlayEntry?.remove();
        _statsOverlayEntry = null;
      },
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final salesAsync = ref.watch(salesOrderControllerProvider);
            return salesAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, __) => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Error loading stats'),
              ),
              data: (sales) {
                final usedOrders = sales.length;
                final availableOrders = 7500 - usedOrders;
                const purchasedOrders = 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.info,
                            size: 15,
                            color: AppTheme.textDisabled,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'View Order Stats',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                      child: Column(
                        children: [
                          _buildStatsRow('Available Orders', '$availableOrders'),
                          const SizedBox(height: 8),
                          _buildStatsRow('Used Orders', '$usedOrders'),
                          const SizedBox(height: 8),
                          _buildStatsRow('Purchased Orders', '$purchasedOrders'),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            LucideIcons.info,
                            size: 14,
                            color: AppTheme.textDisabled,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'The stats displayed above are only for the current billing cycle.',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatsRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: AppTheme.bodyText.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPicklistsTab(List<Picklist> picklists) {
    if (picklists.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: Text(
          'No picklists found for this sales order.',
          style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(4),
          3: FlexColumnWidth(3),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight, width: 0.8),
              ),
            ),
            children: [
              'Picklist#',
              'Date',
              'Assignee',
              'Status',
            ].map((h) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                h.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Inter',
                  letterSpacing: 0.3,
                ),
              ),
            )).toList(),
          ),
          ...picklists.map((pl) {
            final dateStr = pl.date != null ? DateFormat('dd-MM-yyyy').format(pl.date!) : '--';
            final assigneeName = pl.assignee ?? 'N/A';
            
            final statusStr = pl.status.toUpperCase().replaceAll('_', ' ');
            Color statusColor = AppTheme.textSecondary;
            if (statusStr == 'COMPLETED' || statusStr == 'APPROVED') {
              statusColor = const Color(0xFF10B981);
            } else if (statusStr == 'IN PROGRESS') {
              statusColor = const Color(0xFFD97706);
            } else if (statusStr == 'CANCELLED') {
              statusColor = const Color(0xFFEF4444);
            }

            return TableRow(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 0.5),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: InkWell(
                    onTap: () {
                      if (pl.id != null) {
                        context.go('/inventory/picklists/${pl.id}');
                      }
                    },
                    child: Text(
                      pl.picklistNumber,
                      style: AppTheme.bodyText.copyWith(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    dateStr,
                    style: AppTheme.bodyText.copyWith(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    assigneeName,
                    style: AppTheme.bodyText.copyWith(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    statusStr,
                    style: AppTheme.bodyText.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPackagesTab(List<InventoryPackage> packages) {
    if (packages.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: Text(
          'No packages found for this sales order.',
          style: AppTheme.bodyText.copyWith(color: AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(3),
          1: FlexColumnWidth(4),
          2: FlexColumnWidth(3),
          3: FlexColumnWidth(3),
          4: FlexColumnWidth(3),
          5: FlexColumnWidth(3),
          6: FixedColumnWidth(50),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight, width: 0.8),
              ),
            ),
            children: [
              'Date',
              'Package',
              'Status',
              'Carrier',
              'Shipped on',
              'Delivered On',
              '',
            ].map((h) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                h.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Inter',
                  letterSpacing: 0.3,
                ),
              ),
            )).toList(),
          ),
          ...packages.map((pkg) {
            final dateStr = pkg.packageDate != null ? DateFormat('dd-MM-yyyy').format(pkg.packageDate!) : '--';
            final shipDateStr = pkg.shipmentDate != null ? DateFormat('dd-MM-yyyy').format(pkg.shipmentDate!) : '--';
            final carrierStr = pkg.carrier ?? '--';
            
            final statusStr = pkg.status.toUpperCase().replaceAll('_', ' ');
            Color statusColor = AppTheme.textSecondary;
            if (statusStr == 'SHIPPED') {
              statusColor = const Color(0xFF10B981);
            } else if (statusStr == 'NOT SHIPPED') {
              statusColor = const Color(0xFF9CA3AF);
            } else if (statusStr == 'DELIVERED') {
              statusColor = AppTheme.primaryBlue;
            }

            return TableRow(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 0.5),
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    dateStr,
                    style: AppTheme.bodyText.copyWith(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: InkWell(
                    onTap: () {
                      if (pkg.id != null) {
                        context.go('/inventory/packages/${pkg.id}');
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.package,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          pkg.packageNumber,
                          style: AppTheme.bodyText.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    statusStr,
                    style: AppTheme.bodyText.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    carrierStr,
                    style: AppTheme.bodyText.copyWith(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    shipDateStr,
                    style: AppTheme.bodyText.copyWith(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    '--',
                    style: AppTheme.bodyText.copyWith(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Center(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: _buildPackageRowActionMenu(pkg),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPackageRowActionMenu(InventoryPackage pkg) {
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    return MenuAnchor(
      alignmentOffset: const Offset(-80, 4),
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        elevation: WidgetStateProperty.all(8),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppTheme.borderLight),
          ),
        ),
      ),
      menuChildren: [
        if (pkg.status.toUpperCase() != 'SHIPPED' && pkg.status.toUpperCase() != 'DELIVERED')
          MenuItemButton(
            onPressed: () {
              if (pkg.id != null) {
                context.go('/inventory/shipments/create?packageId=${pkg.id}');
              }
            },
            style: ZTableMoreMenu.menuItemButtonStyle(),
            child: const Text('Ship via Carrier'),
          ),
        MenuItemButton(
          onPressed: () async {
            try {
              final bytes = await _generatePackagePdf(pkg, orgSettings);
              await Printing.layoutPdf(
                onLayout: (_) async => bytes,
                name: pkg.packageNumber,
              );
            } catch (e) {
              ZerpaiToast.error(context, 'Error printing package slip: $e');
            }
          },
          style: ZTableMoreMenu.menuItemButtonStyle(),
          child: const Text('Print Package Slip'),
        ),
        MenuItemButton(
          onPressed: () async {
            try {
              final bytes = await _generatePackagePdf(pkg, orgSettings);
              await Printing.sharePdf(
                bytes: bytes,
                filename: '${pkg.packageNumber}.pdf',
              );
            } catch (e) {
              ZerpaiToast.error(context, 'Error downloading package slip: $e');
            }
          },
          style: ZTableMoreMenu.menuItemButtonStyle(),
          child: const Text('Download Package Slip'),
        ),
        MenuItemButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Package'),
                content: Text('Are you sure you want to delete package ${pkg.packageNumber}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true && pkg.id != null) {
              final success = await ref.read(inventoryPackagesProvider.notifier).deletePackage(pkg.id!);
              if (success && mounted) {
                ZerpaiToast.success(context, 'Package deleted successfully');
                ref.read(inventoryPackagesProvider.notifier).fetchPackages();
              }
            }
          },
          style: ZTableMoreMenu.menuItemButtonStyle(),
          child: const Text('Delete Package Slip'),
        ),
      ],
      builder: (context, controller, _) => IconButton(
        icon: const Icon(LucideIcons.moreVertical, size: 16, color: AppTheme.textBody),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 18,
        onPressed: () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  Future<Uint8List> _generatePackagePdf(InventoryPackage pkg, OrgSettings? org) async {
    final doc = pw.Document();
    SalesCustomer? customer;
    if (pkg.customerId != null) {
      try {
        customer = await ref.read(salesCustomerByIdProvider(pkg.customerId!).future);
      } catch (_) {}
    }

    pw.MemoryImage? logoImage;
    if (org?.logoUrl != null && org!.logoUrl!.trim().isNotEmpty) {
      try {
        final res = await Dio().get<List<int>>(
          org.logoUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null) {
          logoImage = pw.MemoryImage(Uint8List.fromList(res.data!));
        }
      } catch (_) {}
    }

    final dateStr = pkg.packageDate != null
        ? DateFormat('dd-MM-yyyy').format(pkg.packageDate!)
        : '-';
    final soNumber = pkg.salesOrderNumbers.isNotEmpty
        ? pkg.salesOrderNumbers.join(', ')
        : (pkg.salesOrderNumber ?? '-');

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
                            child: pw.Text('LOGO',
                                style: pw.TextStyle(color: PdfColors.white, fontSize: 12)),
                          ),
                        ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        org?.name.trim().toUpperCase() ?? 'YOUR COMPANY',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                      ),
                      if (org?.paymentStubAddress?.trim().isNotEmpty == true)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(
                            _formatAddress(org!.paymentStubAddress!.trim()),
                            style: const pw.TextStyle(fontSize: 9, lineSpacing: 2),
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PACKAGE',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 28,
                          letterSpacing: 2,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Package# ${pkg.packageNumber}',
                        style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),
              pw.Row(
                children: [
                  _pwInfoCell('Package#', pkg.packageNumber),
                  _pwInfoCell('Order Date', dateStr),
                  _pwInfoCell('Package Date', dateStr),
                  _pwInfoCell('Sales Order#', soNumber),
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
                        pw.Text('Bill To',
                            style: pw.TextStyle(
                                color: PdfColors.blue,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(pkg.customerName ?? '',
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        if (customer != null && customer.fullBillingAddress != 'N/A')
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              customer.fullBillingAddress,
                              style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
                            ),
                          ),
                        if (customer != null && customer.billingAddressPhone != null)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              'Phone: ${customer.billingAddressPhone}',
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
                        pw.Text('Ship To',
                            style: pw.TextStyle(
                                color: PdfColors.blue,
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(pkg.customerName ?? '',
                            style: pw.TextStyle(
                                fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        if (customer != null && customer.fullShippingAddress != 'N/A')
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2),
                            child: pw.Text(
                              customer.fullShippingAddress,
                              style: const pw.TextStyle(fontSize: 10, lineSpacing: 2),
                            ),
                          ),
                        if (customer != null && customer.shippingAddressPhone != null)
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
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF1F2937)),
                    children: [
                      _pwHeaderCell('#'),
                      _pwHeaderCell('Item & Description'),
                      _pwHeaderCell('HSN/SAC'),
                      _pwHeaderCell('Qty', align: pw.Alignment.centerRight),
                    ],
                  ),
                  ...pkg.items.asMap().entries.map((e) {
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: e.key.isEven ? PdfColors.white : const PdfColor.fromInt(0xFFF9FAFB),
                        border: const pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey200),
                        ),
                      ),
                      children: [
                        _pwDataCell('${e.key + 1}'),
                        _pwDataCell(e.value.itemName ?? ''),
                        _pwDataCell(''),
                        _pwDataCell(
                          e.value.quantity.toStringAsFixed(0),
                          align: pw.Alignment.centerRight,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  void _showRemainingPoApprovalDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _RemainingPoApprovalDialog(),
    );
  }
}

class _RemainingPoApprovalDialog extends ConsumerStatefulWidget {
  const _RemainingPoApprovalDialog();

  @override
  ConsumerState<_RemainingPoApprovalDialog> createState() => _RemainingPoApprovalDialogState();
}

class _RemainingPoApprovalDialogState extends ConsumerState<_RemainingPoApprovalDialog> {
  final Set<String> _selectedPoIds = {};
  bool _isSubmitting = false;

  Widget _buildAlignedCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Center(
      child: SizedBox(
        width: 18,
        height: 18,
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: const BorderSide(color: Color(0xFF6B7280), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeBranchName = ref.watch(entityProvider).name ?? 'Main Branch';
    final poAsync = ref.watch(awaitingPoApprovalsProvider);

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0, bottom: 24, left: 40, right: 40),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: AppTheme.borderLight),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      hoverColor: AppTheme.borderLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Awaiting Purchase Order Approval',
                    style: AppTheme.sectionHeader.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppTheme.borderLight),
              const SizedBox(height: 16),
              Expanded(
                child: poAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      'Failed to load purchase orders: $error',
                      style: AppTheme.bodyText.copyWith(color: AppTheme.errorRed),
                    ),
                  ),
                  data: (orders) {
                    final awaitingApproval = orders;

                    final isAllSelected = awaitingApproval.isNotEmpty &&
                        awaitingApproval.every((po) => _selectedPoIds.contains(po.id ?? ''));

                    return Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: AppTheme.borderLight,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Column(
                          children: [
                            Table(
                              columnWidths: const {
                                0: FixedColumnWidth(48),
                                1: FlexColumnWidth(1.2),
                                2: FlexColumnWidth(1.5),
                                3: FlexColumnWidth(1.2),
                                4: FlexColumnWidth(1.3),
                                5: FlexColumnWidth(1.8),
                              },
                              border: TableBorder(
                                horizontalInside: const BorderSide(color: AppTheme.borderLight),
                                bottom: const BorderSide(color: AppTheme.borderLight),
                              ),
                              children: [
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: AppTheme.borderLight,
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: _buildAlignedCheckbox(
                                        value: isAllSelected,
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedPoIds.addAll(
                                                awaitingApproval.map((po) => po.id ?? ''),
                                              );
                                            } else {
                                              _selectedPoIds.removeAll(
                                                awaitingApproval.map((po) => po.id ?? ''),
                                              );
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    _buildHeaderCell('Date'),
                                    _buildHeaderCell('Purchase Order#'),
                                    _buildHeaderCell('Status'),
                                    _buildHeaderCell('Credit Limit'),
                                    _buildHeaderCell('Customer'),
                                  ],
                                ),
                                ...awaitingApproval.map((po) {
                                  final poDate = DateFormat('dd-MM-yyyy').format(po.orderDate);
                                  final isSelected = _selectedPoIds.contains(po.id ?? '');
                                  final creditLimitFormatted = po.creditLimit != null
                                      ? '₹${po.creditLimit!.toStringAsFixed(2)}'
                                      : '₹0.00';
                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        child: _buildAlignedCheckbox(
                                          value: isSelected,
                                          onChanged: (val) {
                                            setState(() {
                                              if (val == true) {
                                                _selectedPoIds.add(po.id ?? '');
                                              } else {
                                                _selectedPoIds.remove(po.id ?? '');
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      _buildDataCell(poDate),
                                      _buildDataCell(po.orderNumber, isBold: true),
                                      _buildStatusCell(po.status),
                                      _buildDataCell(creditLimitFormatted),
                                      _buildDataCell(po.branchName ?? activeBranchName),
                                    ],
                                  );
                                }),
                              ],
                            ),
                            if (awaitingApproval.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 48),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        LucideIcons.fileText,
                                        size: 48,
                                        color: AppTheme.textDisabled,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No purchase orders awaiting approval.',
                                        style: AppTheme.bodyText.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ZButton.primary(
                    label: _isSubmitting ? 'Approving...' : 'Approve',
                    onPressed: _selectedPoIds.isEmpty || _isSubmitting
                        ? null
                        : () async {
                            setState(() {
                              _isSubmitting = true;
                            });
                            try {
                              await ref
                                  .read(salesOrderApiServiceProvider)
                                  .approvePurchaseOrders(_selectedPoIds.toList());
                              
                              if (context.mounted) {
                                ZerpaiToast.success(
                                  context,
                                  'Purchase orders approved successfully.',
                                );
                                ref.invalidate(awaitingPoApprovalsProvider);
                                ref.invalidate(salesOrderControllerProvider);
                                Navigator.of(context).pop();
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ZerpaiToast.error(
                                  context,
                                  'Failed to approve purchase orders: $e',
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isSubmitting = false;
                                });
                              }
                            }
                          },
                  ),
                  const SizedBox(width: 10),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.bodyText.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDataCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: AppTheme.bodyText.copyWith(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildStatusCell(String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        status.toUpperCase(),
        style: AppTheme.linkText.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
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
              constraints: const BoxConstraints(minWidth: 120, maxWidth: 120),
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
                      padding: EdgeInsets.zero,
                      child: _ActionMenuItem(item: item),
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

class _ActionMenuItem extends StatefulWidget {
  final String item;
  const _ActionMenuItem({required this.item});

  @override
  State<_ActionMenuItem> createState() => _ActionMenuItemState();
}

class _ActionMenuItemState extends State<_ActionMenuItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          widget.item,
          style: AppTheme.bodyText.copyWith(
            fontSize: 13,
            color: _isHovered ? Colors.white : AppTheme.textPrimary,
          ),
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


MenuStyle _menuStyle() {
  return MenuStyle(
    backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
    surfaceTintColor: WidgetStateProperty.all<Color>(Colors.white),
    shadowColor: WidgetStateProperty.all<Color>(
      Colors.black.withValues(alpha: 0.08),
    ),
    elevation: WidgetStateProperty.all<double>(8),
    padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
      EdgeInsets.zero,
    ),
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
      final highlighted =
          states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused);
      if (isActive || highlighted) {
        return AppTheme.primaryBlue;
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
    iconColor: WidgetStateProperty.resolveWith<Color>((states) {
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
    shape: WidgetStateProperty.all<OutlinedBorder>(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
        final orgSettings = ref.read(orgSettingsProvider).asData?.value;
        final orgName = orgSettings?.name.trim().isNotEmpty == true ? orgSettings!.name.trim() : 'Our Organization';

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
$orgName''';

        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading order for email: $e');
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
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final orgName = orgSettings?.name.trim().isNotEmpty == true ? orgSettings!.name.trim() : 'Our Organization';
    final orgEmail = orgSettings?.email?.trim().isNotEmpty == true ? orgSettings!.email!.trim() : 'org@example.com';

    return EmailComposerScreen(
      title: 'Email To $customerName',
      initialFrom: '$orgName <$orgEmail>',
      initialTo:
          '$customerName <${order.customer?.email ?? "customer@example.com"}>',
      initialSubject:
          'Sales Order from $orgName (Sales Order #: [${order.saleNumber}])',
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

class _SoStatusSummary {
  final String invoiceStatus; // 'full', 'partial', 'none'
  final String packageStatus; // 'full', 'partial', 'none'
  final String shipmentStatus; // 'full', 'partial', 'none'
  final String picklistStatus; // 'full', 'partial', 'none'

  const _SoStatusSummary({
    required this.invoiceStatus,
    required this.packageStatus,
    required this.shipmentStatus,
    required this.picklistStatus,
  });
}

class _CancelSalesItemsDialog extends StatefulWidget {
  final SalesOrder order;
  final VoidCallback onProceed;

  const _CancelSalesItemsDialog({
    required this.order,
    required this.onProceed,
  });

  @override
  State<_CancelSalesItemsDialog> createState() => _CancelSalesItemsDialogState();
}

class _CancelSalesItemsDialogState extends State<_CancelSalesItemsDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final List<SalesOrderItem> _cancellableItems = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadQuantities();
  }

  void _loadQuantities() {
    setState(() {
      _cancellableItems.clear();
      for (final item in widget.order.items ?? []) {
        final lockedQty = [
          item.pickedQuantity,
          item.packedQuantity,
          item.shippedQuantity,
          item.invoicedQuantity,
        ].reduce((a, b) => a > b ? a : b);

        final remaining = item.quantity - lockedQty - item.cancelledQuantity;
        if (remaining > 0) {
          _cancellableItems.add(item);
          _controllers[item.itemId] = TextEditingController(
            text: remaining.toInt().toString(),
          );
        }
      }
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _proceed() async {
    if (_isSaving) return;

    final List<Map<String, dynamic>> itemUpdates = [];
    bool anyUpdated = false;

    for (final item in widget.order.items ?? []) {
      double currentQty = item.quantity;
      double cancelQty = 0.0;

      if (_controllers.containsKey(item.itemId)) {
        cancelQty = double.tryParse(_controllers[item.itemId]!.text) ?? 0.0;
      }

      final lockedQty = [
        item.pickedQuantity,
        item.packedQuantity,
        item.shippedQuantity,
        item.invoicedQuantity,
      ].reduce((a, b) => a > b ? a : b);

      final maxCancel = currentQty - lockedQty - item.cancelledQuantity;

      if (cancelQty > maxCancel) {
        ZerpaiToast.error(
          context,
          'Cancellation quantity for ${item.item?.productName ?? item.description ?? "item"} cannot exceed remaining quantity (${maxCancel.toInt()})',
        );
        return;
      }

      if (cancelQty > 0) {
        anyUpdated = true;
        itemUpdates.add({
          'id': item.id,
          'cancelled_quantity': item.cancelledQuantity + cancelQty,
        });
      }
    }

    if (!anyUpdated) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final supabase = Supabase.instance.client;
      for (final up in itemUpdates) {
        await supabase
            .from('sales_order_items')
            .update({
              'cancelled_quantity': up['cancelled_quantity'],
            })
            .eq('id', up['id']!);
      }

      double totalOriginalQuantity = 0.0;
      double totalCancelled = 0.0;

      for (final item in widget.order.items ?? []) {
        totalOriginalQuantity += item.quantity;
        double currentCancel = item.cancelledQuantity;
        if (_controllers.containsKey(item.itemId)) {
          double cancelQty = double.tryParse(_controllers[item.itemId]!.text) ?? 0.0;
          totalCancelled += currentCancel + cancelQty;
        } else {
          totalCancelled += currentCancel;
        }
      }

      String newStatus = widget.order.status;
      if (totalCancelled >= totalOriginalQuantity) {
        newStatus = 'Cancelled';
      }

      await supabase
          .from('sales_orders')
          .update({
            'status': newStatus,
          })
          .eq('id', widget.order.id);

      widget.onProceed();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ZerpaiToast.error(context, 'Failed to cancel items: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 950,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cancel Items',
                  style: AppTheme.pageTitle.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.red, size: 18),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 24, color: AppTheme.borderLight),
            const Text(
              'Choose the items and the quantity to be canceled',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else if (_cancellableItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'All items in this sales order have been fully shipped/cancelled.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Container(
                      color: const Color(0xFFF9FAFB),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        children: const [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'ITEM DETAILS',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'SKU',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'ORDERED',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'PICKED',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'PACKED',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'SHIPPED',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'INVOICED',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'QUANTITY TO CANCEL',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                          ),
                          SizedBox(width: 32),
                        ],
                      ),
                    ),
                    ..._cancellableItems.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppTheme.borderLight)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                item.item?.productName ?? item.description ?? 'Unnamed Item',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                item.item?.itemCode ?? '-',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                item.quantity.toInt().toString(),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                item.pickedQuantity.toInt().toString(),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                item.packedQuantity.toInt().toString(),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                item.shippedQuantity.toInt().toString(),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                item.invoicedQuantity.toInt().toString(),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(
                                height: 32,
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFD1D5DB)),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: TextField(
                                  controller: _controllers[item.itemId],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 13),
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 24,
                              child: IconButton(
                                icon: const Icon(LucideIcons.xCircle, color: Colors.red, size: 16),
                                onPressed: () {
                                  _controllers[item.itemId]?.text = '0';
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading || _cancellableItems.isEmpty || _isSaving ? null : _proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22A95E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Proceed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    foregroundColor: const Color(0xFF4B5563),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DropshipTypeDialog extends ConsumerStatefulWidget {
  final SalesOrder order;
  final String orgId;
  const _DropshipTypeDialog({required this.order, required this.orgId});

  @override
  ConsumerState<_DropshipTypeDialog> createState() => _DropshipTypeDialogState();
}

class _DropshipTypeDialogState extends ConsumerState<_DropshipTypeDialog> {
  bool _isHoveringComplete = false;
  bool _isHoveringPartial = false;

  String? _getAccountName(String? purchaseAccountId) {
    if (purchaseAccountId == null || purchaseAccountId.isEmpty) return null;
    final accountsState = ref.read(chartOfAccountsProvider);
    final List<AccountNode> availableAccounts = [];
    void collect(List<AccountNode> nodes) {
      for (final node in nodes) {
        availableAccounts.add(node);
        collect(node.children);
      }
    }
    collect(accountsState.roots);
    try {
      return availableAccounts.firstWhere((acc) => acc.id == purchaseAccountId).name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose Dropship Type',
                style: AppTheme.sectionHeader.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.red, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHoveringComplete = true),
                  onExit: (_) => setState(() => _isHoveringComplete = false),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _handleCompleteDropship();
                    },
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: _isHoveringComplete ? const Color(0xFFEFF6FF) : Colors.white,
                        border: Border.all(
                          color: _isHoveringComplete ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTruckIcon(solidCheck: true),
                          const SizedBox(height: 16),
                          const Text(
                            'Complete Dropship',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHoveringPartial = true),
                  onExit: (_) => setState(() => _isHoveringPartial = false),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _showPartialDropshipItemsDialog();
                    },
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: _isHoveringPartial ? const Color(0xFFEFF6FF) : Colors.white,
                        border: Border.all(
                          color: _isHoveringPartial ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildTruckIcon(solidCheck: false),
                          const SizedBox(height: 16),
                          const Text(
                            'Partial Dropship',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTruckIcon({required bool solidCheck}) {
    return SizedBox(
      width: 100,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(LucideIcons.truck, size: 54, color: Color(0xFF3B82F6)),
          Positioned(
            right: 28,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF3B82F6),
                  width: 1.5,
                  style: solidCheck ? BorderStyle.solid : BorderStyle.none,
                ),
              ),
              child: Icon(
                LucideIcons.check,
                size: 14,
                color: solidCheck ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6).withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCompleteDropship() {
    final customer = widget.order.customer;
    final shippingAddressStr = customer != null ? customer.fullShippingAddress : '';
    final customerName = customer?.displayName ?? '';

    final po = PurchaseOrder(
      orderNumber: '',
      orderDate: DateTime.now(),
      vendorId: '', // User will select vendor
      notes: widget.order.customerNotes,
      termsAndConditions: widget.order.termsAndConditions,
      discount: widget.order.discountTotal,
      discountType: 'percentage', // default
      adjustment: widget.order.adjustment,
      subTotal: widget.order.subTotal,
      taxAmount: widget.order.taxTotal,
      total: widget.order.total,
      items: (widget.order.items ?? []).map((item) {
        final purchaseAccountId = item.item?.purchaseAccountId;
        final purchaseAccountName = _getAccountName(purchaseAccountId);
        final qty = item.quantity - item.cancelledQuantity;
        final rate = item.rate;
        return PurchaseOrderItem(
          productId: item.itemId,
          productName: item.item?.productName ?? item.description,
          hsnCode: item.hsnCode ?? item.item?.hsnCode,
          itemCode: item.item?.itemCode,
          description: item.description,
          accountId: purchaseAccountId,
          accountName: purchaseAccountName,
          quantity: qty,
          rate: rate,
          amount: qty * rate,
          taxId: item.taxId,
          taxRate: item.taxPercentage,
          taxAmount: item.taxAmount,
          discount: item.discount,
          discountType: item.discountType == '%' ? 'percentage' : 'fixed',
        );
      }).toList(),
    );

    final encodedName = Uri.encodeComponent(customerName);
    final encodedAddress = Uri.encodeComponent(shippingAddressStr);

    context.push(
      '/${widget.orgId}/purchases/purchase-orders/create?isDropship=true&dropshipCustomerName=$encodedName&dropshipAddress=$encodedAddress',
      extra: po,
    );
  }

  void _showPartialDropshipItemsDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: _PartialDropshipItemsDialog(
              order: widget.order,
              orgId: widget.orgId,
            ),
          ),
        );
      },
    );
  }
}

class _PartialDropshipItemsDialog extends ConsumerStatefulWidget {
  final SalesOrder order;
  final String orgId;
  const _PartialDropshipItemsDialog({required this.order, required this.orgId});

  @override
  ConsumerState<_PartialDropshipItemsDialog> createState() => _PartialDropshipItemsDialogState();
}

class _PartialDropshipItemsDialogState extends ConsumerState<_PartialDropshipItemsDialog> {
  bool _isLoading = true;
  Map<String, double> _productStockMap = {};
  final Set<String> _selectedItemIds = {};
  bool _copyDescriptions = false;

  @override
  void initState() {
    super.initState();
    _loadStockData();
    // Default to all selected
    if (widget.order.items != null) {
      for (final item in widget.order.items!) {
        if (item.itemId.isNotEmpty) {
          _selectedItemIds.add(item.id ?? item.itemId);
        }
      }
    }
  }

  Future<void> _loadStockData() async {
    try {
      final productIds = widget.order.items
          ?.map((i) => i.itemId)
          .where((id) => id.isNotEmpty)
          .toList() ?? [];

      if (productIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await ref.read(apiClientProvider).post(
        '/branch_inventory/bulk',
        data: {'product_ids': productIds},
      );
      final responseData = response.data['data'] ?? response.data;
      final stocks = responseData['stocks'] as List<dynamic>? ?? [];

      final Map<String, double> tempMap = {};
      for (final row in stocks) {
        final pId = row['product_id']?.toString() ?? '';
        final stock = ((row['available_stock'] ?? row['current_stock']) ?? 0).toDouble();
        tempMap[pId] = (tempMap[pId] ?? 0.0) + stock;
      }

      setState(() {
        _productStockMap = tempMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stock data: $e');
      setState(() => _isLoading = false);
    }
  }

  String? _getAccountName(String? purchaseAccountId) {
    if (purchaseAccountId == null || purchaseAccountId.isEmpty) return null;
    final accountsState = ref.read(chartOfAccountsProvider);
    final List<AccountNode> availableAccounts = [];
    void collect(List<AccountNode> nodes) {
      for (final node in nodes) {
        availableAccounts.add(node);
        collect(node.children);
      }
    }
    collect(accountsState.roots);
    try {
      return availableAccounts.firstWhere((acc) => acc.id == purchaseAccountId).name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.order.items ?? [];
    final allSelected = items.isNotEmpty &&
        items.every((item) => _selectedItemIds.contains(item.id ?? item.itemId));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose the items to be dropshipped',
                style: AppTheme.sectionHeader.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.red, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(4),
              ),
              constraints: const BoxConstraints(maxHeight: 250),
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(48),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(2),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      children: [
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Checkbox(
                            value: allSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  for (final item in items) {
                                    _selectedItemIds.add(item.id ?? item.itemId);
                                  }
                                } else {
                                  _selectedItemIds.clear();
                                }
                              });
                            },
                          ),
                        ),
                        const TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              'ITEM DETAILS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ),
                        const TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              'QUANTITY ORDERED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ),
                        const TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Text(
                              'STOCK ON HAND',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ...items.map((item) {
                      final itemId = item.id ?? item.itemId;
                      final isSelected = _selectedItemIds.contains(itemId);
                      final stock = _productStockMap[item.itemId] ?? 0.0;
                      final unit = item.item?.unitName ?? 'pcs';

                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        children: [
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedItemIds.add(itemId);
                                  } else {
                                    _selectedItemIds.remove(itemId);
                                  }
                                });
                              },
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 12.0,
                              ),
                              child: Text(
                                item.item?.productName ?? item.description ?? 'Unnamed Item',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                '${item.quantity.toInt()} ($unit)',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                              ),
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                '${stock.toInt()} ($unit)',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFEF3C7)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item Description Preference',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _copyDescriptions,
                        onChanged: (val) {
                          setState(() {
                            _copyDescriptions = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "Copy the sales order's item descriptions to the new purchase order",
                          style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton(
                onPressed: _isLoading || _selectedItemIds.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);
                        _proceedDropship();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Dropship', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  foregroundColor: const Color(0xFF4B5563),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _proceedDropship() {
    final customer = widget.order.customer;
    final shippingAddressStr = customer != null ? customer.fullShippingAddress : '';
    final customerName = customer?.displayName ?? '';

    final selectedItems = (widget.order.items ?? []).where((item) {
      final itemId = item.id ?? item.itemId;
      return _selectedItemIds.contains(itemId);
    }).map((item) {
      final purchaseAccountId = item.item?.purchaseAccountId;
      final purchaseAccountName = _getAccountName(purchaseAccountId);
      final qty = item.quantity - item.cancelledQuantity;
      final rate = item.rate;
      return PurchaseOrderItem(
        productId: item.itemId,
        productName: item.item?.productName ?? item.description,
        hsnCode: item.hsnCode ?? item.item?.hsnCode,
        itemCode: item.item?.itemCode,
        description: _copyDescriptions ? item.description : null,
        accountId: purchaseAccountId,
        accountName: purchaseAccountName,
        quantity: qty,
        rate: rate,
        amount: qty * rate,
        taxId: item.taxId,
        taxRate: item.taxPercentage,
        taxAmount: item.taxAmount,
        discount: item.discount,
        discountType: item.discountType == '%' ? 'percentage' : 'fixed',
      );
    }).toList();

    final po = PurchaseOrder(
      orderNumber: '',
      orderDate: DateTime.now(),
      vendorId: '', // User will select vendor
      notes: widget.order.customerNotes,
      termsAndConditions: widget.order.termsAndConditions,
      discount: widget.order.discountTotal,
      discountType: 'percentage', // default
      adjustment: widget.order.adjustment,
      subTotal: widget.order.subTotal,
      taxAmount: widget.order.taxTotal,
      total: widget.order.total,
      items: selectedItems,
    );

    final encodedName = Uri.encodeComponent(customerName);
    final encodedAddress = Uri.encodeComponent(shippingAddressStr);

    context.push(
      '/${widget.orgId}/purchases/purchase-orders/create?isDropship=true&dropshipCustomerName=$encodedName&dropshipAddress=$encodedAddress',
      extra: po,
    );
  }
}

class _ReasonInputDialog extends StatefulWidget {
  final SalesOrder order;
  final String targetStatus;
  final Future<void> Function(String reason) onConfirm;

  const _ReasonInputDialog({
    required this.order,
    required this.targetStatus,
    required this.onConfirm,
  });

  @override
  State<_ReasonInputDialog> createState() => _ReasonInputDialogState();
}

class _ReasonInputDialogState extends State<_ReasonInputDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVoid = widget.targetStatus == 'void';
    final isCompleted = widget.targetStatus == 'completed';
    final title = isVoid
        ? 'Enter a reason for marking this transaction as Void.'
        : isCompleted
            ? 'Note down the reason as to why you want to convert this transaction to Completed.'
            : 'Note down the reason as to why you want to convert this void transaction to Confirmed.';
    
    final confirmLabel = isVoid 
        ? 'Void it' 
        : isCompleted 
            ? 'Convert to Completed' 
            : 'Convert to Confirmed';

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: const EdgeInsets.only(top: 0),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.normal,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: _submitting
                      ? null
                      : () async {
                          final text = _reasonController.text.trim();
                          if (text.isEmpty) {
                            ZerpaiToast.error(
                              context,
                              'Reason cannot be empty',
                            );
                            return;
                          }
                          setState(() => _submitting = true);
                          await widget.onConfirm(text);
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981), // Emerald green
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFA7F3D0),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E293B),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackorderDialog extends ConsumerStatefulWidget {
  final SalesOrder order;
  final String orgId;
  const _BackorderDialog({required this.order, required this.orgId});

  @override
  ConsumerState<_BackorderDialog> createState() => _BackorderDialogState();
}

class _BackorderDialogState extends ConsumerState<_BackorderDialog> {
  bool _isLoading = true;
  Map<String, double> _productStockMap = {};
  final Set<String> _selectedItemIds = {};
  bool _copyDescriptions = false;

  /// Items that have stock shortage (ordered > stock)
  List<SalesOrderItem> _shortageItems = [];

  @override
  void initState() {
    super.initState();
    _loadStockData();
  }

  Future<void> _loadStockData() async {
    try {
      final productIds = widget.order.items
          ?.map((i) => i.itemId)
          .where((id) => id.isNotEmpty)
          .toList() ?? [];

      if (productIds.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await ref.read(apiClientProvider).post(
        '/branch_inventory/bulk',
        data: {'product_ids': productIds},
      );
      final responseData = response.data['data'] ?? response.data;
      final stocks = responseData['stocks'] as List<dynamic>? ?? [];

      final Map<String, double> tempMap = {};
      for (final row in stocks) {
        final pId = row['product_id']?.toString() ?? '';
        final stock = ((row['available_stock'] ?? row['current_stock']) ?? 0).toDouble();
        tempMap[pId] = (tempMap[pId] ?? 0.0) + stock;
      }

      // Filter to items where ordered > stock (available for sale is negative)
      final shortage = (widget.order.items ?? []).where((item) {
        final stock = tempMap[item.itemId] ?? 0.0;
        return item.quantity > stock;
      }).toList();

      // Default all shortage items selected
      for (final item in shortage) {
        _selectedItemIds.add(item.id ?? item.itemId);
      }

      setState(() {
        _productStockMap = tempMap;
        _shortageItems = shortage;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stock data for backorder: $e');
      setState(() => _isLoading = false);
    }
  }

  String? _getAccountName(String? purchaseAccountId) {
    if (purchaseAccountId == null || purchaseAccountId.isEmpty) return null;
    final accountsState = ref.read(chartOfAccountsProvider);
    final List<AccountNode> availableAccounts = [];
    void collect(List<AccountNode> nodes) {
      for (final node in nodes) {
        availableAccounts.add(node);
        collect(node.children);
      }
    }
    collect(accountsState.roots);
    try {
      return availableAccounts.firstWhere((acc) => acc.id == purchaseAccountId).name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _shortageItems.isNotEmpty &&
        _shortageItems.every((item) => _selectedItemIds.contains(item.id ?? item.itemId));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Choose the items to be backordered',
                style: AppTheme.sectionHeader.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, color: Colors.red, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_shortageItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: const Center(
                child: Text(
                  'No items require backordering. All items have sufficient stock.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ),
            )
          else ...[
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(4),
              ),
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: Table(
                  columnWidths: const {
                    0: FixedColumnWidth(48),
                    1: FlexColumnWidth(3),
                    2: FlexColumnWidth(2),
                    3: FlexColumnWidth(1.5),
                    4: FlexColumnWidth(1.5),
                    5: FlexColumnWidth(1.5),
                  },
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      children: [
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Checkbox(
                            value: allSelected,
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  for (final item in _shortageItems) {
                                    _selectedItemIds.add(item.id ?? item.itemId);
                                  }
                                } else {
                                  _selectedItemIds.clear();
                                }
                              });
                            },
                          ),
                        ),
                        ...[
                          'ITEM DETAILS',
                          'LOCATION NAME',
                          'QUANTITY ORDERED',
                          'STOCK ON HAND',
                          'BACKORDER QUANTITY',
                        ].map((header) => TableCell(
                          verticalAlignment: TableCellVerticalAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              header,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                    ..._shortageItems.map((item) {
                      final itemId = item.id ?? item.itemId;
                      final isSelected = _selectedItemIds.contains(itemId);
                      final stock = _productStockMap[item.itemId] ?? 0.0;
                      final backorderQty = item.quantity - stock;
                      final unit = item.item?.unitName ?? 'pcs';

                      // Resolve warehouse/location name
                      String locationName = '-';
                      final whs = ref.watch(warehousesProvider).value;
                      final whId = item.warehouseId ?? widget.order.warehouseId;
                      if (whs != null && whId != null) {
                        try {
                          locationName = whs.firstWhere((w) => w.id == whId).name;
                        } catch (_) {}
                      }

                      return TableRow(
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                        ),
                        children: [
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedItemIds.add(itemId);
                                  } else {
                                    _selectedItemIds.remove(itemId);
                                  }
                                });
                              },
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 12.0,
                              ),
                              child: Text(
                                item.item?.productName ?? item.description ?? 'Unnamed Item',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                locationName,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                              ),
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                '${item.quantity.toInt()} ($unit)',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                              ),
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                '${stock.toInt()} ($unit)',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                              ),
                            ),
                          ),
                          TableCell(
                            verticalAlignment: TableCellVerticalAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                '${backorderQty.toInt()} ($unit)',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                border: Border.all(color: const Color(0xFFBAE6FD)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Note:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• A new purchase order will be created for the backordered items.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                  ),
                  Text(
                    '• The backorder quantity is based on the stock shortfall.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                  ),
                  Text(
                    '• You can modify the quantities in the purchase order before saving.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFFEF3C7)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Item Description Preference',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: _copyDescriptions,
                        onChanged: (val) {
                          setState(() {
                            _copyDescriptions = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          "Copy the sales order's item descriptions to the new purchase order",
                          style: TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              ElevatedButton(
                onPressed: _isLoading || _selectedItemIds.isEmpty || _shortageItems.isEmpty
                    ? null
                    : () {
                        Navigator.pop(context);
                        _proceedBackorder();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Backorder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  foregroundColor: const Color(0xFF4B5563),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Cancel', style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _proceedBackorder() {
    final selectedItems = _shortageItems.where((item) {
      final itemId = item.id ?? item.itemId;
      return _selectedItemIds.contains(itemId);
    }).map((item) {
      final purchaseAccountId = item.item?.purchaseAccountId;
      final purchaseAccountName = _getAccountName(purchaseAccountId);
      final stock = _productStockMap[item.itemId] ?? 0.0;
      final backorderQty = item.quantity - stock;
      final rate = item.rate;
      return PurchaseOrderItem(
        productId: item.itemId,
        productName: item.item?.productName ?? item.description,
        hsnCode: item.hsnCode ?? item.item?.hsnCode,
        itemCode: item.item?.itemCode,
        description: _copyDescriptions ? item.description : null,
        accountId: purchaseAccountId,
        accountName: purchaseAccountName,
        quantity: backorderQty,
        rate: rate,
        amount: backorderQty * rate,
        taxId: item.taxId,
        taxRate: item.taxPercentage,
        taxAmount: item.taxAmount,
        discount: item.discount,
        discountType: item.discountType == '%' ? 'percentage' : 'fixed',
      );
    }).toList();

    final po = PurchaseOrder(
      orderNumber: '',
      orderDate: DateTime.now(),
      vendorId: '',
      notes: widget.order.customerNotes,
      termsAndConditions: widget.order.termsAndConditions,
      discount: 0,
      discountType: 'percentage',
      adjustment: 0,
      subTotal: 0,
      taxAmount: 0,
      total: 0,
      items: selectedItems,
    );

    context.push(
      '/${widget.orgId}/purchases/purchase-orders/create',
      extra: po,
    );
  }
}
