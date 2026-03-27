import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_search_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/unsaved_changes_dialog.dart';
import 'package:zerpai_erp/shared/widgets/form_row.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/z_currency_display.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';

import '../controllers/sales_order_controller.dart';
import '../models/sales_order_item_model.dart';
import '../models/sales_order_model.dart';

final _salesOrderDetailProvider = FutureProvider.family<SalesOrder, String>((
  ref,
  id,
) {
  return ref.watch(salesOrderApiServiceProvider).getSalesOrderById(id);
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
  'Sales person',
  'Customer Notes',
  'Terms & Conditions',
  'Payment Terms',
  'Delivery Method',
  'Reference#',
  'Expected Shipment Date',
];

const _salesOrderViews = <_SalesOrderView>[
  _SalesOrderView('Sales Orders for Packaging'),
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
  late final ScrollController _bodyScrollCtrl;
  late final ScrollController _headerScrollCtrl;
  String _searchQuery = '';
  _SalesOrderView _activeView = _salesOrderViews.first;
  _SalesOrderSortField _activeSortField = _SalesOrderSortField.salesOrderNumber;
  bool _isAscending = true;
  bool _clipText = true;
  Set<String> _selectedSaleIds = <String>{};
  late List<_SalesOrderColumnConfig> _columnConfigs;

  List<_SalesOrderColumnConfig> get _visibleColumns =>
      _columnConfigs.where((column) => column.visible).toList();

  double get _tableWidth =>
      58 + _visibleColumns.fold<double>(0, (sum, column) => sum + column.width);

  @override
  void initState() {
    super.initState();
    _columnConfigs = _defaultColumnConfigs();
    _bodyScrollCtrl = ScrollController();
    _headerScrollCtrl = ScrollController();
    _bodyScrollCtrl.addListener(() {
      if (_headerScrollCtrl.hasClients &&
          _bodyScrollCtrl.offset != _headerScrollCtrl.offset) {
        _headerScrollCtrl.jumpTo(_bodyScrollCtrl.offset);
      }
    });
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
  }

  @override
  void dispose() {
    _bodyScrollCtrl.dispose();
    _headerScrollCtrl.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showUnavailableAction(String label) {
    // TODO(sales-orders): Replace these placeholder toasts with live
    // integrations once email, PDF/print, invoice conversion, and follow-up
    // document creation flows are connected to backend workflows.
    if (!mounted) return;
    ZerpaiToast.info(context, '$label is not available yet');
  }

  void _editSalesOrder(SalesOrder order) {
    context.push('/sales/orders/${order.id}/edit', extra: order);
  }

  void _handleCreateAction(String actionLabel) {
    // TODO(sales-orders): Wire create-follow-up document actions to their
    // actual Picklist/Package/Shipment/Instant Invoice flows and routes.
    _showUnavailableAction(actionLabel);
  }

  List<_SalesOrderColumnConfig> _defaultColumnConfigs() {
    return [
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.date,
        label: 'Date',
        width: 110,
        locked: true,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.salesOrderNumber,
        label: 'Sales Order#',
        width: 130,
        locked: true,
        visible: true,
      ),
      _SalesOrderColumnConfig(
        key: _SalesOrderColumnKey.reference,
        label: 'Reference#',
        width: 120,
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
        key: _SalesOrderColumnKey.invoiced,
        label: 'Invoiced',
        width: 90,
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
        key: _SalesOrderColumnKey.picked,
        label: 'Picked',
        width: 90,
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
                  _toolbar(context),
                  const Divider(height: 1, color: AppTheme.borderLight),
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
    ZerpaiToast.success(
      context,
      '$label applied to ${_selectedSaleIds.length} sales order(s)',
    );
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

  Widget _toolbar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 14),
      child: Row(
        children: [
          MenuAnchor(
            style: _menuStyle(),
            builder: (context, controller, child) {
              return InkWell(
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
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
                        _activeView.label,
                        style: AppTheme.sectionHeader.copyWith(fontSize: 16),
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
          const SizedBox(width: 18),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: ZSearchField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Search in Sales Orders',
                width: 320,
                onChanged: (value) =>
                    setState(() => _searchQuery = value.trim()),
              ),
            ),
          ),
          const SizedBox(width: 16),
          TextButton(onPressed: () {}, child: const Text('View Order Stats')),
          const SizedBox(width: 12),
          SizedBox(
            height: 36,
            child: ZButton.primary(
              label: '+ New',
              onPressed: () => context.go('/sales/orders/create'),
            ),
          ),
          const SizedBox(width: 8),
          MenuAnchor(
            style: _menuStyle(),
            builder: (context, controller, child) {
              return InkWell(
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: const Icon(
                    LucideIcons.moreHorizontal,
                    size: 16,
                    color: AppTheme.textBody,
                  ),
                ),
              );
            },
            menuChildren: [
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    style: _sortMenuItemStyle(
                      isSelected:
                          _activeSortField == _SalesOrderSortField.createdTime,
                    ),
                    onPressed: () => setState(
                      () => _toggleSort(_SalesOrderSortField.createdTime),
                    ),
                    child: const SizedBox(
                      width: 170,
                      child: Text('Created Time'),
                    ),
                  ),
                  MenuItemButton(
                    style: _sortMenuItemStyle(
                      isSelected:
                          _activeSortField ==
                          _SalesOrderSortField.lastModifiedTime,
                    ),
                    onPressed: () => setState(
                      () => _toggleSort(_SalesOrderSortField.lastModifiedTime),
                    ),
                    child: const SizedBox(
                      width: 170,
                      child: Text('Last Modified Time'),
                    ),
                  ),
                  MenuItemButton(
                    style: _sortMenuItemStyle(
                      isSelected: _activeSortField == _SalesOrderSortField.date,
                    ),
                    onPressed: () =>
                        setState(() => _toggleSort(_SalesOrderSortField.date)),
                    trailingIcon: _activeSortField == _SalesOrderSortField.date
                        ? Icon(
                            _isAscending
                                ? LucideIcons.arrowUp
                                : LucideIcons.arrowDown,
                            size: 14,
                            color: AppTheme.primaryBlueDark,
                          )
                        : null,
                    child: const SizedBox(width: 170, child: Text('Date')),
                  ),
                  MenuItemButton(
                    style: _sortMenuItemStyle(
                      isSelected:
                          _activeSortField ==
                          _SalesOrderSortField.salesOrderNumber,
                    ),
                    onPressed: () => setState(
                      () => _toggleSort(_SalesOrderSortField.salesOrderNumber),
                    ),
                    trailingIcon:
                        _activeSortField ==
                            _SalesOrderSortField.salesOrderNumber
                        ? Icon(
                            _isAscending
                                ? LucideIcons.arrowUp
                                : LucideIcons.arrowDown,
                            size: 14,
                            color: AppTheme.primaryBlueDark,
                          )
                        : null,
                    child: const SizedBox(
                      width: 170,
                      child: Text('Sales Order#'),
                    ),
                  ),
                  MenuItemButton(
                    style: _sortMenuItemStyle(
                      isSelected:
                          _activeSortField == _SalesOrderSortField.reference,
                    ),
                    onPressed: () => setState(
                      () => _toggleSort(_SalesOrderSortField.reference),
                    ),
                    trailingIcon:
                        _activeSortField == _SalesOrderSortField.reference
                        ? Icon(
                            _isAscending
                                ? LucideIcons.arrowUp
                                : LucideIcons.arrowDown,
                            size: 14,
                            color: AppTheme.primaryBlueDark,
                          )
                        : null,
                    child: const SizedBox(
                      width: 170,
                      child: Text('Reference#'),
                    ),
                  ),
                ],
                child: const SizedBox(width: 170, child: Text('Sort by')),
              ),
              MenuItemButton(
                style: _menuItemStyle(),
                onPressed: () {},
                child: const SizedBox(
                  width: 170,
                  child: Text('Import Sales Orders'),
                ),
              ),
              SubmenuButton(
                menuChildren: [
                  MenuItemButton(
                    style: _menuItemStyle(),
                    onPressed: () {},
                    child: const SizedBox(
                      width: 170,
                      child: Text('Export Sales Orders'),
                    ),
                  ),
                  MenuItemButton(
                    style: _menuItemStyle(),
                    onPressed: () {},
                    child: const SizedBox(
                      width: 170,
                      child: Text('Export Current View'),
                    ),
                  ),
                ],
                child: const SizedBox(width: 170, child: Text('Export')),
              ),
              MenuItemButton(
                style: _menuItemStyle(),
                onPressed: () {},
                child: const SizedBox(width: 170, child: Text('Preferences')),
              ),
              MenuItemButton(
                style: _menuItemStyle(),
                onPressed: () {},
                child: const SizedBox(
                  width: 170,
                  child: Text('Manage Custom Fields'),
                ),
              ),
              MenuItemButton(
                style: _menuItemStyle(),
                onPressed: () => ref
                    .read(salesOrderControllerProvider.notifier)
                    .loadSalesOrders(),
                child: const SizedBox(width: 170, child: Text('Refresh List')),
              ),
            ],
          ),
        ],
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
        Padding(
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
                    color: AppTheme.accentGreen,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    LucideIcons.plus,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
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
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(
                          LucideIcons.square,
                          size: 14,
                          color: AppTheme.textDisabled,
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
                              '${sale.saleNumber}  •  ${_date(sale.saleDate)}',
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
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer: ${_customerName(order)}',
                              style: AppTheme.metaHelper.copyWith(fontSize: 12),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.saleNumber,
                              style: AppTheme.sectionHeader.copyWith(
                                fontSize: 22,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _ActionText(
                        icon: LucideIcons.pencil,
                        label: 'Edit',
                        onTap: () => _editSalesOrder(order),
                      ),
                      _ActionText(
                        icon: LucideIcons.mail,
                        label: 'Send Email',
                        onTap: () => _showUnavailableAction('Send Email'),
                      ),
                      _ActionText(
                        icon: LucideIcons.printer,
                        label: 'PDF/Print',
                        onTap: () => _showUnavailableAction('PDF/Print'),
                      ),
                      _ActionText(
                        icon: LucideIcons.fileText,
                        label: 'Convert to Invoice',
                        onTap: () =>
                            _showUnavailableAction('Convert to Invoice'),
                      ),
                      _ActionSplitMenu(
                        icon: LucideIcons.plusCircle,
                        label: 'Create',
                        onPrimaryTap: () => _showUnavailableAction('Create'),
                        onSelected: _handleCreateAction,
                      ),
                      const SizedBox(width: 10),
                      _ActionSquare(
                        icon: LucideIcons.x,
                        color: AppTheme.errorRed,
                        onTap: () => context.go('/sales/orders'),
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
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.borderLight),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              _tab('Packages'),
                              _tab('Picklists', count: items.length),
                              const Spacer(),
                              const Padding(
                                padding: EdgeInsets.only(right: 16),
                                child: Icon(
                                  LucideIcons.chevronRight,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        _banner(
                          icon: LucideIcons.info,
                          text:
                              'Package, picklist, and shipment tracking will appear here when fulfillment data is available from the backend.',
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
                            Text(
                              'Show PDF View',
                              style: AppTheme.bodyText.copyWith(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: showPdfView,
                              onChanged: (value) {
                                showPdfView = value;
                                setInnerState(() {});
                              },
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

  Widget _table(List<SalesOrder> sales) {
    final allSelected = _allVisibleSelected(sales);
    return Column(
      children: [
        if (_selectedSaleIds.isNotEmpty) _selectionToolbar(),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(AppTheme.space8),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Fixed header — scrolls horizontally with the body
                SizedBox(
                  height: 44,
                  child: SingleChildScrollView(
                    controller: _headerScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      width: _tableWidth,
                      child: Row(
                        children: [
                          SizedBox(width: 28, child: _headerMenuButton()),
                          SizedBox(
                            width: 30,
                            child: Checkbox(
                              value: allSelected,
                              onChanged: (value) =>
                                  _toggleSelectAll(sales, value ?? false),
                              activeColor: AppTheme.primaryBlueDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                          ..._visibleColumns.map(_buildHeaderForColumn),
                        ],
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderColor),
                // Body — vertical list inside horizontal scroll
                Expanded(
                  child: RawScrollbar(
                    controller: _bodyScrollCtrl,
                    thumbVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(3),
                    child: SingleChildScrollView(
                      controller: _bodyScrollCtrl,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: _tableWidth,
                        child: ListView.separated(
                          itemCount: sales.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, color: AppTheme.borderLight),
                          itemBuilder: (context, index) {
                            final sale = sales[index];
                            return InkWell(
                              onTap: () => context.go('/sales/orders/${sale.id}'),
                              hoverColor: AppTheme.selectionActiveBg,
                              child: Container(
                                height: _clipText ? 46 : 56,
                                child: Row(
                                  children: [
                                    const SizedBox(width: 28),
                                    SizedBox(
                                      width: 30,
                                      child: Checkbox(
                                        value: _selectedSaleIds.contains(sale.id),
                                        onChanged: (value) => _toggleSaleSelection(
                                          sale.id,
                                          value ?? false,
                                        ),
                                        activeColor: AppTheme.primaryBlueDark,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                    ..._visibleColumns.map(
                                      (column) => _buildCellForColumn(column, sale),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectionToolbar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _BulkActionButton(
              label: 'Bulk Update',
              onTap: _showBulkUpdateDialog,
            ),
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
            MenuAnchor(
              style: _menuStyle(),
              builder: (context, controller, child) {
                return InkWell(
                  onTap: () => controller.isOpen
                      ? controller.close()
                      : controller.open(),
                  borderRadius: BorderRadius.circular(6),
                  child: const _BulkMoreButton(),
                );
              },
              menuChildren: [
                MenuItemButton(
                  style: _menuItemStyle(),
                  onPressed: () => _handleBulkAction('Quick shipments'),
                  child: const SizedBox(
                    width: 210,
                    child: Text('Create Quick Shipments'),
                  ),
                ),
                MenuItemButton(
                  style: _menuItemStyle(),
                  onPressed: () => _handleBulkAction('Merge sales orders'),
                  child: const SizedBox(
                    width: 210,
                    child: Text('Merge Sales Orders'),
                  ),
                ),
                MenuItemButton(
                  style: _menuItemStyle(),
                  onPressed: () => _handleBulkAction('Bulk cancel items'),
                  child: const SizedBox(
                    width: 210,
                    child: Text('Bulk Cancel Items'),
                  ),
                ),
                MenuItemButton(
                  style: _menuItemStyle(),
                  onPressed: () =>
                      _handleBulkAction('Bulk reopen canceled items'),
                  child: const SizedBox(
                    width: 210,
                    child: Text('Bulk reopen canceled items'),
                  ),
                ),
                MenuItemButton(
                  style: _menuItemStyle(),
                  onPressed: () => _handleBulkAction('Delete'),
                  child: const SizedBox(width: 210, child: Text('Delete')),
                ),
              ],
            ),
            _BulkDivider(),
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
      ),
    );
  }

  Widget _headerMenuButton() {
    return MenuAnchor(
      style: _menuStyle(),
      builder: (context, controller, child) {
        return InkWell(
          onTap: () =>
              controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(8),
          child: const Center(
            child: Icon(
              LucideIcons.slidersHorizontal,
              size: 14,
              color: AppTheme.primaryBlue,
            ),
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          style: _menuItemStyle(),
          onPressed: _showCustomizeColumnsDialog,
          leadingIcon: const Icon(LucideIcons.slidersHorizontal, size: 15),
          child: const SizedBox(width: 170, child: Text('Customize Columns')),
        ),
        MenuItemButton(
          style: _menuItemStyle(isActive: _clipText),
          onPressed: () => setState(() => _clipText = !_clipText),
          leadingIcon: Icon(
            _clipText ? LucideIcons.alignLeft : LucideIcons.wrapText,
            size: 15,
          ),
          child: const SizedBox(width: 170, child: Text('Clip Text')),
        ),
      ],
    );
  }

  Widget _buildHeaderForColumn(_SalesOrderColumnConfig column) {
    final sortField = _sortFieldForColumn(column.key);
    final isSorted = sortField != null && _activeSortField == sortField;
    return _Header(
      label: column.label.toUpperCase(),
      width: column.width,
      sorted: isSorted,
      ascending: _isAscending,
      onTap: sortField == null
          ? null
          : () => setState(() => _toggleSort(sortField)),
      alignRight:
          column.key == _SalesOrderColumnKey.amount ||
          column.key == _SalesOrderColumnKey.invoicedAmount,
    );
  }

  Widget _buildCellForColumn(_SalesOrderColumnConfig column, SalesOrder sale) {
    switch (column.key) {
      case _SalesOrderColumnKey.date:
        return _Cell(
          width: column.width,
          child: _tableText(_date(sale.saleDate)),
        );
      case _SalesOrderColumnKey.salesOrderNumber:
        return _Cell(
          width: column.width,
          child: Text(sale.saleNumber, style: AppTheme.linkText),
        );
      case _SalesOrderColumnKey.reference:
        return _Cell(
          width: column.width,
          child: _tableText(sale.reference ?? '—'),
        );
      case _SalesOrderColumnKey.customerName:
        return _Cell(
          width: column.width,
          child: _tableText(_customerName(sale)),
        );
      case _SalesOrderColumnKey.orderStatus:
      case _SalesOrderColumnKey.status:
        return _Cell(
          width: column.width,
          child: Text(
            sale.status.toUpperCase(),
            style: AppTheme.linkText.copyWith(fontSize: 12),
          ),
        );
      case _SalesOrderColumnKey.invoiced:
        return _StateDot(
          width: column.width,
          active: _isInvoiced(sale),
          tooltip: _invoiceLabel(sale),
        );
      case _SalesOrderColumnKey.payment:
        return _StateDot(
          width: column.width,
          active: _isPaid(sale),
          tooltip: _paymentLabel(sale),
        );
      case _SalesOrderColumnKey.packed:
        return _StateDot(
          width: column.width,
          active: _isPacked(sale),
          tooltip: _isPacked(sale) ? 'Packed' : 'Not Packed',
        );
      case _SalesOrderColumnKey.shipped:
        return _StateDot(
          width: column.width,
          active: _isShipped(sale),
          tooltip: _shipmentLabel(sale),
        );
      case _SalesOrderColumnKey.amount:
        return _Cell(
          width: column.width,
          alignRight: true,
          child: Align(
            alignment: Alignment.centerRight,
            child: ZCurrencyDisplay(
              amount: sale.total,
              style: AppTheme.tableCell.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        );
      case _SalesOrderColumnKey.deliveryMethod:
        return _Cell(
          width: column.width,
          child: _tableText(sale.deliveryMethod ?? '—'),
        );
      case _SalesOrderColumnKey.expectedShipmentDate:
        return _Cell(
          width: column.width,
          child: _tableText(
            sale.expectedShipmentDate != null
                ? _date(sale.expectedShipmentDate!)
                : '—',
          ),
        );
      case _SalesOrderColumnKey.companyName:
        return _Cell(
          width: column.width,
          child: _tableText(sale.customer?.companyName ?? '—'),
        );
      case _SalesOrderColumnKey.invoicedAmount:
        return _Cell(
          width: column.width,
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
          width: column.width,
          child: _tableText(sale.customer?.billingAddressStateId ?? '—'),
        );
      case _SalesOrderColumnKey.picked:
        return _Cell(
          width: column.width,
          child: _tableText(_isPacked(sale) ? 'Yes' : 'No'),
        );
      case _SalesOrderColumnKey.salesPerson:
        return _Cell(
          width: column.width,
          child: _tableText(sale.salesperson ?? '—'),
        );
    }
  }

  Widget _tableText(String value) {
    return Text(
      value,
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
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _addressBlock(
                        'BILLING ADDRESS',
                        _customerName(order),
                        _address(order.customer?.fullBillingAddress),
                        order.customer?.phone,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: _addressBlock(
                        'SHIPPING ADDRESS',
                        _customerName(order),
                        _address(order.customer?.fullShippingAddress),
                        order.customer?.shippingAddressPhone,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 44,
            runSpacing: 18,
            children: [
              _meta('ORDER DATE', _date(order.saleDate)),
              _meta('PAYMENT TERMS', order.paymentTerms ?? 'Not specified'),
              _meta('SALESPERSON', order.salesperson ?? 'Not assigned'),
              _meta(
                'EXPECTED SHIPMENT',
                order.expectedShipmentDate != null
                    ? _date(order.expectedShipmentDate!)
                    : 'Not scheduled',
              ),
              _meta('DELIVERY METHOD', order.deliveryMethod ?? 'Not specified'),
              _meta('REFERENCE#', order.reference ?? '—'),
            ],
          ),
          const SizedBox(height: 28),
          _itemsTable(items),
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
      padding: const EdgeInsets.fromLTRB(56, 56, 56, 48),
      decoration: _paperDecoration(),
      child: Stack(
        children: [
          Positioned(
            left: -56,
            top: -20,
            child: Transform.rotate(
              angle: -0.75,
              child: Container(
                color: AppTheme.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 6,
                ),
                child: const Text(
                  'Confirmed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Column(
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
                          _customerName(order),
                          style: AppTheme.bodyText.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _address(order.customer?.fullBillingAddress),
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
                    child: Container(height: 1, color: AppTheme.textPrimary),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 42,
                runSpacing: 16,
                children: [
                  _infoPair('Salesperson', order.salesperson ?? 'Not assigned'),
                  _infoPair(
                    'Customer Notes',
                    order.customerNotes ?? 'No customer notes',
                  ),
                ],
              ),
            ],
          ),
        ],
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

  Widget _itemsTable(List<SalesOrderItem> items) {
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
                Expanded(flex: 4, child: Text('ITEMS & DESCRIPTION')),
                Expanded(child: Text('ORDERED')),
                Expanded(child: Text('RATE')),
                Expanded(child: Text('DISCOUNT')),
                Expanded(child: Text('TAX')),
                Expanded(child: Text('AMOUNT', textAlign: TextAlign.right)),
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
                                  item.description ??
                                      item.item?.billingName ??
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
                item.description ??
                    item.item?.billingName ??
                    item.item?.itemCode ??
                    'Item',
              ),
              cell(item.item?.hsnCode ?? '—'),
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

  Widget _tab(String label, {int? count}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w600),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: AppTheme.bodyText.copyWith(
                color: AppTheme.primaryBlueDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
    Iterable<SalesOrder> result = sales;
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

class _Header extends StatelessWidget {
  final String label;
  final double width;
  final bool alignRight;
  final bool sorted;
  final bool ascending;
  final VoidCallback? onTap;

  const _Header({
    required this.label,
    required this.width,
    this.alignRight = false,
    this.sorted = false,
    this.ascending = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Row(
            mainAxisAlignment: alignRight
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: AppTheme.metaHelper.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: sorted ? AppTheme.primaryBlue : AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (sorted) ...[
                const SizedBox(width: 4),
                Icon(
                  ascending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                  size: 12,
                  color: AppTheme.primaryBlue,
                ),
              ] else ...[
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.arrowUpDown,
                  size: 12,
                  color: AppTheme.textDisabled,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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

class _StateDot extends StatelessWidget {
  final double width;
  final bool active;
  final String tooltip;

  const _StateDot({
    required this.width,
    required this.active,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: ZTooltip(
          message: tooltip,
          child: active
              ? const Icon(
                  LucideIcons.badgeCheck,
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

class _ActionText extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionText({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.textBody),
              const SizedBox(width: 6),
              Text(label, style: AppTheme.bodyText.copyWith(fontSize: 13)),
            ],
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
                    Icon(icon, size: 16, color: AppTheme.textBody),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: AppTheme.bodyText.copyWith(fontSize: 13),
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
                      child: Text(
                        item,
                        style: AppTheme.bodyText.copyWith(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: AppTheme.textBody,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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

class _BulkMoreButton extends StatelessWidget {
  const _BulkMoreButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: const Icon(
        LucideIcons.moreHorizontal,
        size: 16,
        color: AppTheme.textBody,
      ),
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
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _valueController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
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
                        const SizedBox(height: 10),
                        Text(
                          _selectedField == null
                              ? 'Selected sales orders will be updated with the new value.'
                              : 'Selected sales orders will be updated with the new $_selectedField value.',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                  const SizedBox(width: 10),
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

  @override
  Widget build(BuildContext context) {
    final filtered = _columns.where((column) {
      final query = _searchQuery.trim().toLowerCase();
      return query.isEmpty || column.label.toLowerCase().contains(query);
    }).toList();
    final selectedCount = _columns.where((column) => column.visible).length;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: ZSearchField(
                hintText: 'Search',
                width: 480,
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final column = filtered[index];
                    return Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F9FC),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          const Icon(
                            LucideIcons.gripVertical,
                            size: 14,
                            color: AppTheme.textMuted,
                          ),
                          const SizedBox(width: 8),
                          if (column.locked)
                            const Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: Icon(
                                LucideIcons.lock,
                                size: 14,
                                color: AppTheme.textMuted,
                              ),
                            )
                          else
                            Checkbox(
                              value: column.visible,
                              onChanged: (value) => setState(
                                () => column.visible = value ?? false,
                              ),
                              activeColor: AppTheme.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              column.label,
                              style: AppTheme.bodyText.copyWith(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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

ButtonStyle _sortMenuItemStyle({bool isSelected = false}) {
  return ButtonStyle(
    backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
      final highlighted =
          states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused);
      if (highlighted) {
        return AppTheme.primaryBlueDark;
      }
      if (isSelected) {
        return AppTheme.bgDisabled;
      }
      return Colors.white;
    }),
    foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
      final highlighted =
          states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused);
      if (highlighted) {
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
    '₹${NumberFormat('#,##,##0.00', 'en_IN').format(value)}';

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
