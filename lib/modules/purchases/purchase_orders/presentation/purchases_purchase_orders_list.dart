import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/z_button.dart';
import '../../../../../shared/widgets/zerpai_layout.dart';
import '../../../../../shared/widgets/tables/table_header_menu.dart';
import '../../../../../shared/widgets/tables/table_more_menu.dart';
import '../../../../../shared/widgets/skeleton.dart';
import '../providers/purchases_purchase_orders_provider.dart';
import '../models/purchases_purchase_orders_order_model.dart';
import '../../../../../core/providers/org_settings_provider.dart';
import '../../../../../core/models/org_settings_model.dart';
import '../../../../../shared/widgets/email_composer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:zerpai_erp/shared/widgets/z_expandable_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../shared/models/column_config.dart';
import '../../../../../shared/widgets/tables/column_customizer.dart';

class _PurchaseOrderView {
  final String label;
  final String? status;
  const _PurchaseOrderView(this.label, {this.status});
}

const _purchaseOrderViews = <_PurchaseOrderView>[
  _PurchaseOrderView('All Purchase Orders'),
  _PurchaseOrderView('All'),
  _PurchaseOrderView('Draft', status: 'Draft'),
  _PurchaseOrderView('Issued', status: 'Issued'),
  _PurchaseOrderView('Partially Received', status: 'Partially Received'),
  _PurchaseOrderView('Received', status: 'Received'),
  _PurchaseOrderView('Pending', status: 'Pending'),
  _PurchaseOrderView('Approved', status: 'Approved'),
  _PurchaseOrderView('Closed', status: 'Closed'),
  _PurchaseOrderView('Canceled', status: 'Canceled'),
];

class _PoTxnSummary {
  final List<Map<String, dynamic>> receives;
  final List<Map<String, dynamic>> bills;
  final String receiveStatus;
  final String billStatus;
  const _PoTxnSummary({
    required this.receives,
    required this.bills,
    required this.receiveStatus,
    required this.billStatus,
  });
}

class PurchaseOrderOverviewScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;
  final String? initialSelectedId;
  final String? initialFilter;

  const PurchaseOrderOverviewScreen({
    super.key,
    this.initialSearchQuery,
    this.initialSelectedId,
    this.initialFilter,
  });

  @override
  ConsumerState<PurchaseOrderOverviewScreen> createState() =>
      _PurchaseOrderOverviewScreenState();
}

class _PurchaseOrderOverviewScreenState
    extends ConsumerState<PurchaseOrderOverviewScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  String _sortField = 'order_date';
  bool _sortAscending = false;
  bool _shouldWrapText = false;
  _PurchaseOrderView _activeView = _purchaseOrderViews.first;
  Map<String, double>? _customColumnWidths;
  bool _showPdfView = false;
  final ScrollController _horizontalScrollController = ScrollController();

  List<ColumnConfig> _allColumns = [];
  final List<String> _visibleColumns = [];

  final Map<String, String> _columnLabels = {
    'date': 'DATE',
    'location': 'LOCATION',
    'order_number': 'ORDER NUMBER',
    'reference_number': 'REFERENCE NUMBER',
    'vendor_name': 'VENDOR NAME',
    'status': 'STATUS',
    'received': 'RECEIVED',
    'billed': 'BILLED',
    'amount': 'AMOUNT',
    'delivery_date': 'DELIVERY DATE',
  };

  void _initializeColumns() {
    _allColumns = [
      ColumnConfig(id: 'date', label: 'DATE', orderIndex: 0),
      ColumnConfig(id: 'location', label: 'LOCATION', orderIndex: 1),
      ColumnConfig(id: 'order_number', label: 'ORDER NUMBER', orderIndex: 2),
      ColumnConfig(
        id: 'reference_number',
        label: 'REFERENCE NUMBER',
        orderIndex: 3,
        isVisible: false,
      ),
      ColumnConfig(id: 'vendor_name', label: 'VENDOR NAME', orderIndex: 4),
      ColumnConfig(id: 'status', label: 'STATUS', orderIndex: 5),
      ColumnConfig(id: 'received', label: 'RECEIVED', orderIndex: 6),
      ColumnConfig(id: 'billed', label: 'BILLED', orderIndex: 7),
      ColumnConfig(id: 'amount', label: 'AMOUNT', orderIndex: 8),
      ColumnConfig(
        id: 'delivery_date',
        label: 'DELIVERY DATE',
        orderIndex: 9,
        isVisible: false,
      ),
    ];
    _updateVisibleColumns();
  }

  void _updateVisibleColumns() {
    _allColumns.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return a.orderIndex.compareTo(b.orderIndex);
    });
    _visibleColumns.clear();
    for (var col in _allColumns) {
      if (col.isVisible) {
        _visibleColumns.add(col.id);
      }
    }
  }

  Future<void> _loadColumnSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('po_table_columns_config');
      if (jsonStr != null) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        final Map<String, ColumnConfig> loadedMap = {
          for (var c in decoded.map(
            (e) => ColumnConfig.fromJson(Map<String, dynamic>.from(e)),
          ))
            c.id: c,
        };

        setState(() {
          for (var col in _allColumns) {
            if (loadedMap.containsKey(col.id)) {
              col.isVisible = loadedMap[col.id]!.isVisible;
              col.orderIndex = loadedMap[col.id]!.orderIndex;
              col.isPinned = loadedMap[col.id]!.isPinned;
            }
          }
          _updateVisibleColumns();
        });
      }
    } catch (e) {
      debugPrint('Error loading column settings: $e');
    }
  }

  Future<void> _saveColumnSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_allColumns.map((e) => e.toJson()).toList());
      await prefs.setString('po_table_columns_config', jsonStr);
    } catch (e) {
      debugPrint('Error saving column settings: $e');
    }
  }

  void _showCustomizeColumnsDialog() {
    showDialog(
      context: context,
      builder: (context) => ColumnCustomizerDialog(
        columns: _allColumns,
        onSave: (updated) {
          setState(() {
            _allColumns = updated;
            _updateVisibleColumns();
          });
          _saveColumnSettings();
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<_PoTxnSummary> _loadPoTxnSummary(PurchaseOrder order) async {
    final supabase = Supabase.instance.client;
    final receivesResp = await supabase
        .from('purchases_purchase_receives')
        .select(
          'id,purchase_receive_number,received_date,status,billed,bill_no,purchase_order_id,purchases_purchase_receive_items(product_id,ordered,received)',
        )
        .eq('purchase_order_id', order.id ?? '')
        .order('created_at', ascending: false);

    final billsResp = await supabase
        .from('purchases_bills')
        .select('id,bill_number,bill_date,status,total,due_date,order_number')
        .eq('order_number', order.orderNumber)
        .order('created_at', ascending: false);

    final receives = (receivesResp as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final bills = (billsResp as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final hasInTransit = receives.any(
      (r) => (r['status']?.toString().toLowerCase() ?? '') == 'in transit',
    );

    double totalReceived = 0.0;
    for (final r in receives) {
      final itemsList =
          r['purchases_purchase_receive_items'] as List<dynamic>? ?? [];
      for (final item in itemsList) {
        totalReceived += (item['received'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final receiveStatus = receives.isEmpty
        ? 'Yet to be Received'
        : hasInTransit
        ? 'In Transit'
        : totalReceived < order.totalQuantity
        ? 'Partially Received'
        : 'Received';

    final billStatus = bills.isEmpty ? 'Yet to be Billed' : 'Billed';
    return _PoTxnSummary(
      receives: receives,
      bills: bills,
      receiveStatus: receiveStatus,
      billStatus: billStatus,
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeColumns();
    _loadColumnSettings();
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
    if (widget.initialFilter != null) {
      final found = _purchaseOrderViews.where(
        (v) => v.label.toLowerCase() == widget.initialFilter!.toLowerCase(),
      );
      if (found.isNotEmpty) {
        _activeView = found.first;
      }
    }
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseOrdersAsync = ref.watch(
      purchaseOrdersProvider(PurchaseOrderFilter(page: 1, limit: 100)),
    );

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useHorizontalPadding: false,
      useTopPadding: false,
      searchFocusNode: _searchFocusNode,
      child: purchaseOrdersAsync.when(
        data: (orders) {
          final filtered = _applyFilters(orders);
          final sorted = _getSortedList(filtered);
          final hasSelection = widget.initialSelectedId != null;

          return LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 1100;
              return Column(
                children: [
                  if (!hasSelection) ...[
                    _selectedIds.isNotEmpty
                        ? _selectionToolbar()
                        : _buildMainToolbar(context, hasSelection),
                    const Divider(height: 1, color: AppTheme.borderLight),
                  ],
                  Expanded(
                    child: orders.isEmpty
                        ? _buildEmptyState()
                        : filtered.isEmpty
                        ? _buildNoMatchingState()
                        : hasSelection
                        ? _workspace(sorted, orders, compact)
                        : _buildTableView(sorted),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: TableSkeleton(rows: 10, columns: 6),
        ),
        error: (err, stack) => _buildErrorWidget(err.toString()),
      ),
    );
  }

  List<PurchaseOrder> _applyFilters(List<PurchaseOrder> orders) {
    var result = orders;

    // View filter
    if (_activeView.label != 'All' &&
        _activeView.label != 'All Purchase Orders') {
      if (_activeView.status != null) {
        result = result
            .where(
              (o) =>
                  o.status.toLowerCase() == _activeView.status!.toLowerCase(),
            )
            .toList();
      }
    }

    // Search filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((o) {
        return o.orderNumber.toLowerCase().contains(q) ||
            (o.vendorName?.toLowerCase().contains(q) ?? false) ||
            (o.referenceNumber?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }

  Widget _buildNoMatchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text('No matching orders', style: AppTheme.sectionHeader),
          const SizedBox(height: 8),
          Text(
            'Adjust the active view or search term.',
            style: AppTheme.metaHelper,
          ),
        ],
      ),
    );
  }

  List<PurchaseOrder> _getSortedList(List<PurchaseOrder> orders) {
    final list = List<PurchaseOrder>.from(orders);
    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case 'order_date':
          cmp = a.orderDate.compareTo(b.orderDate);
          break;
        case 'order_number':
          cmp = a.orderNumber.compareTo(b.orderNumber);
          break;
        case 'vendor_name':
          cmp = (a.vendorName ?? '').compareTo(b.vendorName ?? '');
          break;
        case 'total':
          cmp = a.total.compareTo(b.total);
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  Widget _buildMainToolbar(BuildContext context, bool hasSelection) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          MenuAnchor(
            style: _viewMenuStyle(),
            builder: (context, controller, child) {
              return InkWell(
                onTap: () =>
                    controller.isOpen ? controller.close() : controller.open(),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _activeView.label,
                        style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ],
                  ),
                ),
              );
            },
            menuChildren: _purchaseOrderViews.map((view) {
              final isSelected = _activeView == view;
              return MenuItemButton(
                style: _viewMenuItemStyle(isSelected),
                onPressed: () => setState(() => _activeView = view),
                child: Text(view.label),
              );
            }).toList(),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: AppTheme.bodyText,
                decoration: InputDecoration(
                  hintText: 'Search Purchase Orders...',
                  hintStyle: AppTheme.metaHelper,
                  prefixIcon: Icon(
                    LucideIcons.search,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(LucideIcons.x, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            _searchFocusNode.unfocus();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(top: 2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          ZButton.primary(
            onPressed: () {
              context.push('/purchases/purchase-orders/create');
            },
            icon: LucideIcons.plus,
            label: 'New',
          ),
          const SizedBox(width: 8),
          ZTableMoreMenu(
            width: 34,
            height: 34,
            menuChildren: [
              SubmenuButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                menuChildren: [
                  _buildSortMenuItem('Date', 'order_date'),
                  _buildSortMenuItem('Purchase Order#', 'order_number'),
                  _buildSortMenuItem('Vendor Name', 'vendor_name'),
                  _buildSortMenuItem('Amount', 'total'),
                ],
                child: const Text('Sort by'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                child: const Text('Import Purchase Orders'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                child: const Text('Export Purchase Orders'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                child: const Text('Preferences'),
              ),
              MenuItemButton(
                style: ZTableMoreMenu.menuItemButtonStyle(),
                child: const Text('Refresh List'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  MenuStyle _viewMenuStyle() {
    return MenuStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevation: const WidgetStatePropertyAll(8),
      backgroundColor: const WidgetStatePropertyAll(Colors.white),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
    );
  }

  Widget _workspace(
    List<PurchaseOrder> filteredOrders,
    List<PurchaseOrder> allOrders,
    bool compact,
  ) {
    final orderId = widget.initialSelectedId!;
    final summary = allOrders.cast<PurchaseOrder?>().firstWhere(
      (order) => order?.id == orderId,
      orElse: () => null,
    );

    if (compact) {
      return _detailPane(orderId, summary);
    }

    return Row(
      children: [
        SizedBox(width: 360, child: _selectionList(filteredOrders, orderId)),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppTheme.borderLight,
        ),
        Expanded(child: _detailPane(orderId, summary)),
      ],
    );
  }

  Widget _selectionList(List<PurchaseOrder> orders, String selectedId) {
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
                        'Purchase Orders',
                        style: AppTheme.sectionHeader.copyWith(fontSize: 18),
                      ),
                    ),
                    InkWell(
                      onTap: () =>
                          context.go('/purchases/purchase-orders/create'),
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
                            _buildSortMenuItem('Date', 'order_date'),
                            _buildSortMenuItem(
                              'Purchase Order#',
                              'order_number',
                            ),
                            _buildSortMenuItem('Vendor Name', 'vendor_name'),
                            _buildSortMenuItem('Amount', 'total'),
                          ],
                          child: const Text('Sort by'),
                        ),
                        MenuItemButton(
                          style: ZTableMoreMenu.menuItemButtonStyle(),
                          child: const Text('Import Purchase Orders'),
                        ),
                        MenuItemButton(
                          style: ZTableMoreMenu.menuItemButtonStyle(),
                          child: const Text('Export Purchase Orders'),
                        ),
                        MenuItemButton(
                          style: ZTableMoreMenu.menuItemButtonStyle(),
                          child: const Text('Preferences'),
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
            itemCount: orders.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final order = orders[index];
              final selected = order.id == selectedId;
              return InkWell(
                onTap: () =>
                    context.go('/purchases/purchase-orders/${order.id}'),
                child: Container(
                  color: selected ? AppTheme.selectionActiveBg : Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: _buildCheckboxWidget(
                          _selectedIds.contains(order.id),
                          onTap: () {
                            setState(() {
                              if (_selectedIds.contains(order.id)) {
                                _selectedIds.remove(order.id);
                              } else {
                                if (order.id != null)
                                  _selectedIds.add(order.id!);
                              }
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    order.vendorName ?? 'No Vendor',
                                    style: AppTheme.bodyText.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? AppTheme.primaryBlue
                                          : AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '₹${order.total.toStringAsFixed(2)}',
                                  style: AppTheme.metaHelper.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    order.orderNumber,
                                    style: AppTheme.metaHelper.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                  ).format(order.orderDate),
                                  style: AppTheme.metaHelper,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _buildStatusBadge(order.status),
                          ],
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
          const _BulkDivider(),
          _BulkActionButton(
            label: 'Mark as Issued',
            onTap: () => _handleBulkAction('Mark as Issued'),
          ),
          _BulkActionButton(
            label: 'Convert to Bill',
            onTap: () => _handleBulkAction('Convert to Bill'),
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
            onTap: () => setState(() => _selectedIds.clear()),
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
          _buildCheckboxWidget(
            true,
            onTap: () => setState(() => _selectedIds.clear()),
          ),
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
              _bulkActionMenuItem('Convert to Bill', 'Convert to Bill'),
              _bulkActionMenuItem('Mark as Issued', 'Mark as Issued'),
              _bulkActionMenuItem('Mark as Received', 'Mark as Received'),
              _bulkActionMenuItem('Mark as Unreceived', 'Mark as Unreceived'),
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
            onTap: () => setState(() => _selectedIds.clear()),
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

  void _handleBulkAction(String actionLabel) async {
    if (_selectedIds.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one purchase order');
      return;
    }
    final firstOrderId = _selectedIds.first;

    if (actionLabel == 'PDF export') {
      await _runBulkPdfExport();
    } else if (actionLabel == 'Print') {
      await _runBulkPrint();
    } else if (actionLabel == 'Email') {
      final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
      context.go('/$orgId/purchases/orders/$firstOrderId/email');
    } else if (actionLabel == 'Mark as Issued') {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('purchase_orders')
            .update({'status': 'Issued'})
            .filter('id', 'in', _selectedIds.toList());

        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        for (var id in _selectedIds) {
          ref.invalidate(purchaseOrderProvider(id));
        }

        ZerpaiToast.success(
          context,
          'Selected purchase orders marked as Issued',
        );
        setState(() => _selectedIds.clear());
      } catch (e) {
        ZerpaiToast.error(context, 'Failed to update status: $e');
      }
    } else if (actionLabel == 'Mark as Received') {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('purchase_orders')
            .update({'status': 'Closed'})
            .filter('id', 'in', _selectedIds.toList());

        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        for (var id in _selectedIds) {
          ref.invalidate(purchaseOrderProvider(id));
        }

        ZerpaiToast.success(
          context,
          'Selected purchase orders marked as Received (Closed)',
        );
        setState(() => _selectedIds.clear());
      } catch (e) {
        ZerpaiToast.error(context, 'Failed to update status: $e');
      }
    } else if (actionLabel == 'Mark as Unreceived') {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('purchase_orders')
            .update({'status': 'Issued'})
            .filter('id', 'in', _selectedIds.toList());

        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        for (var id in _selectedIds) {
          ref.invalidate(purchaseOrderProvider(id));
        }

        ZerpaiToast.success(
          context,
          'Selected purchase orders marked as Unreceived (Issued)',
        );
        setState(() => _selectedIds.clear());
      } catch (e) {
        ZerpaiToast.error(context, 'Failed to update status: $e');
      }
    } else if (actionLabel == 'Bulk cancel items') {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('purchase_orders')
            .update({'status': 'Closed'})
            .filter('id', 'in', _selectedIds.toList());

        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        for (var id in _selectedIds) {
          ref.invalidate(purchaseOrderProvider(id));
        }

        ZerpaiToast.success(
          context,
          'Selected purchase orders items cancelled',
        );
        setState(() => _selectedIds.clear());
      } catch (e) {
        ZerpaiToast.error(context, 'Failed to cancel items: $e');
      }
    } else if (actionLabel == 'Bulk reopen canceled items') {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('purchase_orders')
            .update({'status': 'Issued'})
            .filter('id', 'in', _selectedIds.toList());

        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        for (var id in _selectedIds) {
          ref.invalidate(purchaseOrderProvider(id));
        }

        ZerpaiToast.success(context, 'Selected purchase orders items reopened');
        setState(() => _selectedIds.clear());
      } catch (e) {
        ZerpaiToast.error(context, 'Failed to reopen items: $e');
      }
    } else if (actionLabel == 'Convert to Bill') {
      context.go('/purchases/bills/create?poId=$firstOrderId');
    } else if (actionLabel == 'Delete') {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('purchase_orders')
            .update({'is_delete': true})
            .filter('id', 'in', _selectedIds.toList());

        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        ZerpaiToast.success(context, 'Selected purchase orders deleted');
        setState(() => _selectedIds.clear());
      } catch (e) {
        ZerpaiToast.error(context, 'Failed to delete: $e');
      }
    } else if (actionLabel == 'Bulk update') {
      ZerpaiToast.success(
        context,
        'Bulk update applied to ${_selectedIds.length} purchase orders',
      );
      setState(() => _selectedIds.clear());
    } else {
      ZerpaiToast.success(
        context,
        '$actionLabel applied to ${_selectedIds.length} orders',
      );
    }
  }

  Future<void> _runBulkPdfExport() async {
    if (_selectedIds.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one purchase order');
      return;
    }
    final state = ref.read(
      purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
    );
    final orders = state.valueOrNull ?? const <PurchaseOrder>[];
    final selected = orders.where((o) => _selectedIds.contains(o.id)).toList();
    if (selected.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one purchase order');
      return;
    }
    final order = selected.first;
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    final bytes = await _generatePdf(order, orgSettings);
    await Printing.sharePdf(bytes: bytes, filename: '${order.orderNumber}.pdf');
  }

  Future<void> _runBulkPrint() async {
    if (_selectedIds.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one purchase order');
      return;
    }
    final state = ref.read(
      purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
    );
    final orders = state.valueOrNull ?? const <PurchaseOrder>[];
    final selected = orders.where((o) => _selectedIds.contains(o.id)).toList();
    if (selected.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one purchase order');
      return;
    }
    final order = selected.first;
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    final bytes = await _generatePdf(order, orgSettings);
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<Uint8List> _generatePdf(PurchaseOrder order, OrgSettings? org) async {
    final doc = pw.Document();
    final items = order.items;

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
                      pw.Container(
                        width: 140,
                        height: 48,
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFF0F172A),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            'LOGO / LETTERHEAD',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        org?.name.trim().toUpperCase() ?? 'YOUR COMPANY',
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
                              lineSpacing: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'PURCHASE ORDER',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'PO# ${order.orderNumber}',
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
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Vendor',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF1E3A8A),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          order.vendorName ?? 'No Vendor',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          _address(
                            _formatVendorAddress(order.vendor?.billingAddress),
                          ),
                          style: const pw.TextStyle(
                            fontSize: 9,
                            lineSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Ship To',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF1E3A8A),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          order.warehouseName ?? 'ZABNIX PRIVATE LIMITED',
                          style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Address Line 1\nCity, State PIN',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            lineSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Expanded(
                    child: pw.Align(
                      alignment: pw.Alignment.topRight,
                      child: pw.Text(
                        'Order Date : ${DateFormat('dd-MM-yyyy').format(order.orderDate)}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              pw.Divider(color: PdfColors.grey300, height: 24),
              pw.SizedBox(height: 16),
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
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: pw.Text(
                          '#',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: pw.Text(
                          'Item & Description',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: pw.Text(
                          'HSN/SAC',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            'Qty',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            'Rate',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                        child: pw.Align(
                          alignment: pw.Alignment.centerRight,
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...items.asMap().entries.map((e) {
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: e.key.isEven
                            ? PdfColors.white
                            : const PdfColor.fromInt(0xFFF9FAFB),
                        border: const pw.Border(
                          bottom: pw.BorderSide(color: PdfColors.grey200),
                        ),
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: pw.Text(
                            '${e.key + 1}',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: pw.Text(
                            e.value.productName ?? e.value.itemCode ?? '',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: pw.Text(
                            e.value.hsnCode ?? '—',
                            style: const pw.TextStyle(fontSize: 11),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              e.value.quantity.toStringAsFixed(2),
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              e.value.rate.toStringAsFixed(2),
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 10,
                          ),
                          child: pw.Align(
                            alignment: pw.Alignment.centerRight,
                            child: pw.Text(
                              e.value.amount.toStringAsFixed(2),
                              style: const pw.TextStyle(fontSize: 11),
                            ),
                          ),
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
                    width: 220,
                    child: pw.Column(
                      children: [
                        _pwTotalRow('Sub Total', 'INR ${order.subTotal.toStringAsFixed(2)}'),
                        if (order.discount > 0)
                          _pwTotalRow(
                            'Discount (${order.discountType == 'percentage' ? '${order.discount}%' : 'Fixed'})',
                            '-INR ${(order.discountType == 'percentage' ? (order.subTotal * order.discount / 100) : order.discount).toStringAsFixed(2)}',
                          ),
                        if (order.taxAmount > 0)
                          _pwTotalRow('Tax', 'INR ${order.taxAmount.toStringAsFixed(2)}'),
                        if (order.adjustment != 0)
                          _pwTotalRow(
                            'Adjustment',
                            'INR ${order.adjustment.toStringAsFixed(2)}',
                          ),
                        pw.Divider(color: PdfColors.grey300),
                        pw.Container(
                          color: const PdfColor.fromInt(0xFFF9FAFB),
                          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: _pwTotalRow(
                            'Total',
                            'INR ${order.total.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 34),
              pw.Row(
                children: [
                  pw.Text(
                    'Authorized Signature',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      height: 1,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.Spacer(),
                ],
              ),
            ],
          );
        },
      ),
    );
    return doc.save();
  }

  pw.Widget _pwTotalRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortMenuItem(String label, String field) {
    final isSelected = _sortField == field;
    return MenuItemButton(
      style: ZTableMoreMenu.menuItemButtonStyle(isActive: isSelected),
      onPressed: () {
        setState(() {
          if (isSelected) {
            _sortAscending = !_sortAscending;
          } else {
            _sortField = field;
            _sortAscending = false;
          }
        });
      },
      child: Row(
        children: [
          Text(label),
          if (isSelected) ...[
            const SizedBox(width: 4),
            Icon(
              _sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
              size: 12,
            ),
          ],
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

  Widget _buildTableView(List<PurchaseOrder> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidths =
            _customColumnWidths ?? _calculateColumnWidths(constraints.maxWidth);

        const double actualPrefixWidth = 78.0; // Slider + Checkbox space
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
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: screenWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTableHeader(columnWidths, orders),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: orders.length,
                      itemExtent: 40, // High density Zoho style
                      itemBuilder: (context, index) {
                        return _buildVirtualRow(orders[index], columnWidths);
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
  }

  Map<String, double> _calculateColumnWidths(double totalWidth) {
    const double staticPrefixWidth = 78.0;

    final Map<String, (double min, double flex)> metrics = {
      'date': (100.0, 1.0),
      'location': (150.0, 1.5),
      'order_number': (120.0, 1.2),
      'reference_number': (120.0, 1.2),
      'vendor_name': (150.0, 1.5),
      'status': (80.0, 0.8),
      'received': (80.0, 0.8),
      'billed': (80.0, 0.8),
      'amount': (100.0, 1.0),
      'delivery_date': (100.0, 1.0),
    };

    double totalMinWidth = staticPrefixWidth;
    double totalFlex = 0;

    for (final colId in _visibleColumns) {
      final m = metrics[colId] ?? (100.0, 1.0);
      totalMinWidth += m.$1;
      totalFlex += m.$2;
    }

    final extraSpace = math.max(0.0, totalWidth - totalMinWidth);
    final results = <String, double>{};

    for (final colId in _visibleColumns) {
      final m = metrics[colId] ?? (100.0, 1.0);
      results[colId] = m.$1 + (m.$2 / totalFlex) * extraSpace;
    }

    return results;
  }

  Widget _buildTableHeader(
    Map<String, double> columnWidths,
    List<PurchaseOrder> orders,
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
            wrapText: _shouldWrapText,
            onWrapChange: (v) => setState(() => _shouldWrapText = v),
            onCustomize: _showCustomizeColumnsDialog,
          ),
          const SizedBox(width: 12),
          _buildSelectAllCheckbox(orders),
          const SizedBox(width: 12),
          ..._visibleColumns.map((colId) {
            final width = columnWidths[colId]!;
            final align = (colId == 'received' || colId == 'billed')
                ? TextAlign.center
                : TextAlign.left;

            return _ResizableHeaderCell(
              width: width,
              onResize: (dx) => _resizeColumn(colId, dx),
              child: _buildHeaderCell(
                _columnLabels[colId] ??
                    colId.toUpperCase().replaceAll('_', ' '),
                colId,
                width: width,
                align: align,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(
    String text,
    String colId, {
    double? width,
    TextAlign? align,
  }) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: align == TextAlign.center
            ? Center(
                child: Text(
                  text,
                  style: AppTheme.metaHelper.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : Text(
                text,
                style: AppTheme.metaHelper.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: align,
              ),
      ),
    );
  }

  Widget _buildSelectAllCheckbox(List<PurchaseOrder> orders) {
    final isAllSelected =
        orders.isNotEmpty && _selectedIds.length == orders.length;
    final isPartiallySelected =
        _selectedIds.isNotEmpty && _selectedIds.length < orders.length;

    return _buildCheckboxWidget(
      isAllSelected,
      isPartially: isPartiallySelected,
      onTap: () {
        setState(() {
          if (isAllSelected) {
            _selectedIds.clear();
          } else {
            _selectedIds.clear();
            for (final o in orders) {
              if (o.id != null) {
                _selectedIds.add(o.id!);
              }
            }
          }
        });
      },
    );
  }

  Widget _buildVirtualRow(
    PurchaseOrder order,
    Map<String, double> columnWidths,
  ) {
    final isSelected = _selectedIds.contains(order.id);

    return InkWell(
      onTap: () => context.go('/purchases/purchase-orders/${order.id}'),
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
            const SizedBox(width: 28), // Slider placeholder
            const SizedBox(width: 12),
            _buildCheckboxWidget(
              isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedIds.remove(order.id);
                  } else {
                    if (order.id != null) _selectedIds.add(order.id!);
                  }
                });
              },
            ),
            const SizedBox(width: 12),
            ..._visibleColumns.map((colId) {
              return _buildCell(order, colId, width: columnWidths[colId]!);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(PurchaseOrder order, String colId, {double? width}) {
    Widget content;
    switch (colId) {
      case 'date':
        content = Text(
          DateFormat('dd-MM-yyyy').format(order.orderDate),
          style: AppTheme.tableCell,
        );
        break;
      case 'location':
        content = Text(
          order.warehouseName ?? 'ZABNIX PRIVATE LIMITED',
          style: AppTheme.tableCell,
        );
        break;
      case 'order_number':
        content = InkWell(
          onTap: () => context.go('/purchases/purchase-orders/${order.id}'),
          child: Text(
            order.orderNumber,
            style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
          ),
        );
        break;
      case 'reference_number':
        content = Text(order.referenceNumber ?? '', style: AppTheme.tableCell);
        break;
      case 'vendor_name':
        content = Text(order.vendorName ?? '', style: AppTheme.tableCell);
        break;
      case 'status':
        content = _buildStatusBadge(order.status);
        break;
      case 'received':
        content = Center(
          child: Icon(
            Icons.circle,
            color: order.status == 'Closed' || order.status == 'Received'
                ? Colors.green
                : Colors.orange,
            size: 12,
          ),
        );
        break;
      case 'billed':
        content = Center(
          child: Icon(
            Icons.circle,
            color: order.status == 'Closed' ? Colors.blue : Colors.grey,
            size: 12,
          ),
        );
        break;
      case 'amount':
        content = Text(
          '₹${order.total.toStringAsFixed(2)}',
          style: AppTheme.tableCell,
        );
        break;
      case 'delivery_date':
        content = Text(
          order.expectedDeliveryDate != null
              ? DateFormat('dd-MM-yyyy').format(order.expectedDeliveryDate!)
              : '-',
          style: AppTheme.tableCell,
        );
        break;
      default:
        content = const Text('');
    }

    final align = (colId == 'received' || colId == 'billed')
        ? TextAlign.center
        : TextAlign.left;

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Align(
          alignment: align == TextAlign.center
              ? Alignment.center
              : Alignment.centerLeft,
          child: DefaultTextStyle(
            style: AppTheme.tableCell,
            child: _shouldWrapText
                ? content
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: content,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'draft':
        color = AppTheme.warningOrange;
        break;
      case 'pending':
        color = AppTheme.primaryBlue;
        break;
      case 'approved':
      case 'received':
        color = AppTheme.successGreen;
        break;
      case 'partially received':
        color = AppTheme.warningOrange;
        break;
      case 'rejected':
        color = AppTheme.errorRed;
        break;
      default:
        color = AppTheme.textSecondary;
    }

    return Text(
      status.toUpperCase(),
      style: AppTheme.metaHelper.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _detailPane(String orderId, PurchaseOrder? summary) {
    final detailAsync = ref.watch(purchaseOrderProvider(orderId));
    return detailAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: DetailContentSkeleton(),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.alertTriangle, size: 48, color: AppTheme.errorRed),
            const SizedBox(height: 16),
            Text('Unable to load order details', style: AppTheme.sectionHeader),
            const SizedBox(height: 8),
            Text('$error', style: AppTheme.metaHelper),
          ],
        ),
      ),
      data: (order) {
        if (order == null) return Center(child: const Text('Order not found'));
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
                            'Vendor: ${order.vendorName ?? 'No Vendor'}',
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
                            onTap: () =>
                                context.go('/purchases/purchase-orders'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            order.orderNumber,
                            style: AppTheme.sectionHeader.copyWith(
                              fontSize: 22,
                            ),
                          ),
                        ],
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
                        onPressed: () => _editPurchaseOrder(order),
                      ),
                      _buildDivider(),
                      _buildToolbarButton(
                        LucideIcons.mail,
                        'Send Email',
                        onPressed: () {
                          context.go(
                            '/purchases/purchase-orders/${order.id}/email',
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildPdfPrintDropdown(order, orgSettings),
                      _buildDivider(),
                      if (order.status.toLowerCase() == 'closed')
                        _buildToolbarButton(
                          LucideIcons.fileText,
                          'Convert to Bill',
                          onPressed: () {
                            context.go(
                              '/purchases/bills/create?poId=${order.id}',
                            );
                          },
                        )
                      else
                        _buildToolbarButton(
                          LucideIcons.truck,
                          'Receive',
                          onPressed: () {
                            context.go(
                              '/purchases/purchase-receives/create?poId=${order.id}',
                            );
                          },
                        ),
                      _buildDivider(),
                      MenuAnchor(
                        style: _menuStyle(),
                        builder: (context, controller, child) {
                          return IconButton(
                            onPressed: () => controller.isOpen
                                ? controller.close()
                                : controller.open(),
                            icon: Icon(
                              LucideIcons.moreHorizontal,
                              size: 18,
                              color: AppTheme.textSecondary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          );
                        },
                        menuChildren: _menuChildrenForStatus(order),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppTheme.borderLight),
                Expanded(
                  child: FutureBuilder<_PoTxnSummary>(
                    future: _loadPoTxnSummary(order),
                    builder: (context, summarySnap) {
                      final summary =
                          summarySnap.data ??
                          const _PoTxnSummary(
                            receives: [],
                            bills: [],
                            receiveStatus: 'Yet to be Received',
                            billStatus: 'Yet to be Billed',
                          );
                      final showIssuedTransitYetBilled =
                          order.status.toLowerCase() == 'issued' &&
                          summary.receiveStatus.toLowerCase() == 'in transit' &&
                          summary.billStatus.toLowerCase() ==
                              'yet to be billed';
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (order.status.toLowerCase() == 'draft') ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                  ),
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
                                            TextSpan(
                                              text: 'WHAT\'S NEXT? ',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            TextSpan(
                                              text:
                                                  'Send this purchase order to your vendor or mark it as Issued.',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      height: 34,
                                      child: ZButton.primary(
                                        label: 'Send Purchase Order',
                                        onPressed: () {
                                          context.go(
                                            '/purchases/purchase-orders/${order.id}/email',
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      height: 34,
                                      child: ZButton.secondary(
                                        label: 'Mark as Issued',
                                        onPressed: () async {
                                          try {
                                            final supabase =
                                                Supabase.instance.client;
                                            await supabase
                                                .from('purchase_orders')
                                                .update({'status': 'Issued'})
                                                .eq('id', order.id!);

                                            ref.invalidate(
                                              purchaseOrdersProvider(
                                                PurchaseOrderFilter(limit: 500),
                                              ),
                                            );
                                            ref.invalidate(
                                              purchaseOrderProvider(order.id!),
                                            );

                                            if (context.mounted) {
                                              ZerpaiToast.success(
                                                context,
                                                'Purchase order marked as Issued',
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
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (order.status.toLowerCase() == 'issued') ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                  ),
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
                                              text: showIssuedTransitYetBilled
                                                  ? 'Convert this to a bill to complete your purchase.'
                                                  : 'Record a receive or create a bill for this purchase order.',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (!showIssuedTransitYetBilled)
                                      SizedBox(
                                        height: 34,
                                        child: ZButton.primary(
                                          label: 'Receive',
                                          onPressed: () {
                                            context.go(
                                              '/purchases/purchase-receives/create?poId=${order.id}',
                                            );
                                          },
                                        ),
                                      ),
                                    const SizedBox(width: 10),
                                    SizedBox(
                                      height: 34,
                                      child: showIssuedTransitYetBilled
                                          ? ZButton.primary(
                                              label: 'Convert to Bill',
                                              onPressed: () {
                                                context.go(
                                                  '/purchases/bills/create?poId=${order.id}',
                                                );
                                              },
                                            )
                                          : ZButton.secondary(
                                              label: 'Convert to Bill',
                                              onPressed: () {
                                                context.go(
                                                  '/purchases/bills/create?poId=${order.id}',
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (summary.receives.isNotEmpty ||
                                summary.bills.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              ZExpandableTabs(
                                tabs: [
                                  if (summary.bills.isNotEmpty)
                                    'Bills ${summary.bills.length}',
                                  if (summary.receives.isNotEmpty)
                                    'Receives ${summary.receives.length}',
                                ],
                                children: [
                                  if (summary.bills.isNotEmpty)
                                    _poBillsBanner(summary),
                                  if (summary.receives.isNotEmpty)
                                    _poReceivesBanner(summary),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
                            if (order.status.toLowerCase() == 'closed') ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 18,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppTheme.borderLight,
                                  ),
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
                                                  'Convert this to a bill to complete your purchase.',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      height: 34,
                                      child: ZButton.primary(
                                        label: 'Convert to Bill',
                                        onPressed: () {
                                          context.go(
                                            '/purchases/bills/create?poId=${order.id}',
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            Row(
                              children: [
                                Text(
                                  'Receive Status : ',
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  summary.receiveStatus,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                    color:
                                        summary.receiveStatus == 'In Transit' ||
                                            summary.receiveStatus ==
                                                'Partially Received'
                                        ? AppTheme.warningOrange
                                        : summary.receiveStatus == 'Received'
                                        ? AppTheme.successGreen
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Text(
                                  'Bill Status : ',
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  summary.billStatus,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                    color: summary.billStatus == 'Billed'
                                        ? AppTheme.successDark
                                        : AppTheme.textSecondary,
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
                                    value: _showPdfView,
                                    onChanged: (value) {
                                      setInnerState(() {
                                        _showPdfView = value;
                                      });
                                      setState(() {
                                        _showPdfView = value;
                                      });
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
                              child: _showPdfView
                                  ? _pdfCard(order, order.items, orgSettings)
                                  : _overviewCard(order, summary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editPurchaseOrder(PurchaseOrder order) {
    context.push('/purchases/purchase-orders/${order.id}/edit', extra: order);
  }

  Widget _buildToolbarButton(
    IconData icon,
    String label, {
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.textPrimary),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 16,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppTheme.borderLight,
    );
  }

  MenuStyle _menuStyle() {
    return MenuStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      elevation: const WidgetStatePropertyAll(8),
      backgroundColor: const WidgetStatePropertyAll(Colors.white),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
    );
  }

  List<Widget> _menuChildrenForStatus(PurchaseOrder order) {
    final status = order.status.toLowerCase();
    if (status == 'draft') {
      return [
        _detailActionMenuItem('Mark as Issued', order),
        _detailActionMenuItem('Convert to Bill', order),
        _detailActionMenuItem('Create Receive', order),
        _detailActionMenuItem('Clone', order),
        _detailActionMenuItem('Delete', order),
        _detailActionMenuItem('Mark as Received', order),
      ];
    } else if (status == 'closed') {
      return [
        _detailActionMenuItem('Reopen canceled items', order),
        _detailActionMenuItem('Clone', order),
        _detailActionMenuItem('Delete', order),
      ];
    } else if (status == 'issued') {
      return [
        _detailActionMenuItem('Expected Delivery Date', order),
        _detailActionMenuItem('Cancel Items', order),
        _detailActionMenuItem('Mark as Canceled', order),
        _detailActionMenuItem('Clone', order),
        _detailActionMenuItem('Delete', order),
        _detailActionMenuItem('Mark as Received', order),
      ];
    } else {
      return [
        _detailActionMenuItem('Expected Delivery Date', order),
        _detailActionMenuItem('Cancel Items', order),
        _detailActionMenuItem('Mark as Canceled', order),
        _detailActionMenuItem('Clone', order),
        _detailActionMenuItem('Delete', order),
        _detailActionMenuItem('Mark as Received', order),
      ];
    }
  }

  Widget _poBillsBanner(_PoTxnSummary summary) {
    return _bannerTable(
      headers: const ['Bill#', 'Date', 'Status', 'Due Date', 'Amount'],
      rows: summary.bills.map((b) {
        return [
          b['bill_number']?.toString() ?? '-',
          _formatDateString(b['bill_date']),
          b['status']?.toString().toUpperCase() ?? '-',
          _formatDateString(b['due_date']),
          '₹${(b['total'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
        ];
      }).toList(),
    );
  }

  Widget _poReceivesBanner(_PoTxnSummary summary) {
    return _bannerTable(
      headers: const ['Purchase Receive#', 'received on', 'Status', 'Bill#'],
      rows: summary.receives.map((r) {
        return [
          r['purchase_receive_number']?.toString() ?? '-',
          _formatDateString(r['received_date']),
          (r['status']?.toString() ?? '-')
              .split(' ')
              .map(
                (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
              )
              .join(' '),
          r['bill_no']?.toString() ?? '',
        ];
      }).toList(),
    );
  }

  Widget _bannerTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
        color: Colors.white,
      ),
      child: Table(
        columnWidths: {
          for (int i = 0; i < headers.length; i++) i: const FlexColumnWidth(),
        },
        children: [
          TableRow(
            children: headers
                .map(
                  (h) => Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      h,
                      style: AppTheme.metaHelper.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          ...rows.map(
            (row) => TableRow(
              children: row
                  .map(
                    (c) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Text(
                        c,
                        style: AppTheme.bodyText.copyWith(fontSize: 13),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateString(dynamic raw) {
    final s = raw?.toString();
    if (s == null || s.isEmpty) return '-';
    final dt = DateTime.tryParse(s);
    if (dt == null) return s;
    return DateFormat('dd-MM-yyyy').format(dt);
  }

  MenuItemButton _detailActionMenuItem(String label, PurchaseOrder order) {
    return MenuItemButton(
      onPressed: () async {
        if (label == 'Expected Delivery Date') {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: order.expectedDeliveryDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
            try {
              final supabase = Supabase.instance.client;
              await supabase
                  .from('purchase_orders')
                  .update({'delivery_date': picked.toIso8601String()})
                  .eq('id', order.id!);

              ref.invalidate(
                purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
              );
              ref.invalidate(purchaseOrderProvider(order.id!));

              if (context.mounted) {
                ZerpaiToast.success(context, 'Expected delivery date updated');
              }
            } catch (e) {
              if (context.mounted) {
                ZerpaiToast.error(
                  context,
                  'Failed to update delivery date: $e',
                );
              }
            }
          }
        } else if (label == 'Mark as Issued') {
          try {
            final supabase = Supabase.instance.client;
            await supabase
                .from('purchase_orders')
                .update({'status': 'Issued'})
                .eq('id', order.id!);

            ref.invalidate(
              purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
            );
            ref.invalidate(purchaseOrderProvider(order.id!));

            if (context.mounted) {
              ZerpaiToast.success(context, 'Purchase order marked as Issued');
            }
          } catch (e) {
            if (context.mounted) {
              ZerpaiToast.error(context, 'Failed to update status: $e');
            }
          }
        } else if (label == 'Convert to Bill') {
          context.go('/purchases/bills/create?poId=${order.id}');
        } else if (label == 'Create Receive') {
          context.go('/purchases/purchase-receives/create?poId=${order.id}');
        } else if (label == 'Reopen canceled items') {
          try {
            final supabase = Supabase.instance.client;
            await supabase
                .from('purchase_orders')
                .update({'status': 'Issued'})
                .eq('id', order.id!);

            ref.invalidate(
              purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
            );
            ref.invalidate(purchaseOrderProvider(order.id!));

            if (context.mounted) {
              ZerpaiToast.success(
                context,
                'Canceled items reopened successfully',
              );
            }
          } catch (e) {
            if (context.mounted) {
              ZerpaiToast.error(context, 'Failed to reopen items: $e');
            }
          }
        } else if (label == 'Cancel Items') {
          try {
            final supabase = Supabase.instance.client;
            await supabase
                .from('purchase_orders')
                .update({'status': 'Closed'})
                .eq('id', order.id!);

            ref.invalidate(
              purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
            );
            ref.invalidate(purchaseOrderProvider(order.id!));

            if (context.mounted) {
              ZerpaiToast.success(context, 'Purchase order items cancelled');
            }
          } catch (e) {
            if (context.mounted) {
              ZerpaiToast.error(context, 'Failed to cancel items: $e');
            }
          }
        } else if (label == 'Mark as Canceled') {
          try {
            final supabase = Supabase.instance.client;
            await supabase
                .from('purchase_orders')
                .update({'status': 'Closed'})
                .eq('id', order.id!);

            ref.invalidate(
              purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
            );
            ref.invalidate(purchaseOrderProvider(order.id!));

            if (context.mounted) {
              ZerpaiToast.success(context, 'Purchase order marked as Canceled');
            }
          } catch (e) {
            if (context.mounted) {
              ZerpaiToast.error(context, 'Failed to cancel: $e');
            }
          }
        } else if (label == 'Clone') {
          ZerpaiToast.success(context, 'Purchase order cloned successfully');
        } else if (label == 'Delete') {
          try {
            final supabase = Supabase.instance.client;
            await supabase
                .from('purchase_orders')
                .update({'is_delete': true})
                .eq('id', order.id!);

            ref.invalidate(
              purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
            );
            if (context.mounted) {
              ZerpaiToast.success(context, 'Purchase order deleted');
              context.go('/purchases/purchase-orders');
            }
          } catch (e) {
            if (context.mounted) {
              ZerpaiToast.error(context, 'Failed to delete: $e');
            }
          }
        } else if (label == 'Mark as Received') {
          try {
            final supabase = Supabase.instance.client;
            await supabase
                .from('purchase_orders')
                .update({'status': 'Closed'})
                .eq('id', order.id!);

            ref.invalidate(
              purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
            );
            ref.invalidate(purchaseOrderProvider(order.id!));

            if (context.mounted) {
              ZerpaiToast.success(context, 'Purchase order marked as Received');
            }
          } catch (e) {
            if (context.mounted) {
              ZerpaiToast.error(context, 'Failed to mark as received: $e');
            }
          }
        } else {
          ZerpaiToast.success(context, '$label action clicked');
        }
      },
      style: MenuItemButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label, style: AppTheme.bodyText),
    );
  }

  Widget _buildPdfPrintDropdown(PurchaseOrder order, OrgSettings? orgSettings) {
    return MenuAnchor(
      style: _menuStyle(),
      builder: (context, controller, child) {
        return _buildToolbarButton(
          LucideIcons.printer,
          'PDF/Print',
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            final bytes = await _generatePdf(order, orgSettings);
            await Printing.sharePdf(
              bytes: bytes,
              filename: '${order.orderNumber}.pdf',
            );
          },
          child: const Text('Download PDF'),
        ),
        MenuItemButton(
          onPressed: () async {
            final bytes = await _generatePdf(order, orgSettings);
            await Printing.layoutPdf(onLayout: (_) async => bytes);
          },
          child: const Text('Print'),
        ),
      ],
    );
  }

  Widget _overviewCard(PurchaseOrder order, _PoTxnSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(8),
          ),
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
                          'PURCHASE ORDER',
                          style: AppTheme.sectionHeader.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Purchase Order# ${order.orderNumber}',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _statusSummary(order, summary),
                        const SizedBox(height: 24),
                        _meta(
                          'ORDER DATE',
                          DateFormat('dd-MM-yyyy').format(order.orderDate),
                        ),
                        const SizedBox(height: 12),
                        _meta(
                          'PAYMENT TERMS',
                          order.paymentTerms ?? 'Due on Receipt',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _addressBlock(
                          'VENDOR ADDRESS',
                          order.vendorName ?? 'No Vendor',
                          _formatVendorAddress(order.vendor?.billingAddress),
                          null,
                        ),
                        const SizedBox(height: 24),
                        _addressBlock(
                          'DELIVERY ADDRESS',
                          order.warehouseName ?? 'ZABNIX PRIVATE LIMITED',
                          'PERINTHALMANNA\nMALAPPURAM, Kerala\nIndia - 679322', // Placeholder or from warehouse model
                          '8086355500', // Placeholder
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _itemsTable(order.items, summary),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: _totalsSummary(order),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusSummary(PurchaseOrder order, _PoTxnSummary summary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 3, height: 100, color: AppTheme.warningOrange),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order', style: AppTheme.bodyText),
            const SizedBox(height: 12),
            Text('Receive', style: AppTheme.bodyText),
            const SizedBox(height: 12),
            Text('Bill', style: AppTheme.bodyText),
          ],
        ),
        const SizedBox(width: 48),
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
              summary.receiveStatus,
              style: AppTheme.bodyText.copyWith(
                color:
                    summary.receiveStatus == 'In Transit' ||
                        summary.receiveStatus == 'Partially Received'
                    ? AppTheme.warningOrange
                    : summary.receiveStatus == 'Received'
                    ? AppTheme.successGreen
                    : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              summary.billStatus,
              style: AppTheme.bodyText.copyWith(
                color: summary.billStatus == 'Billed'
                    ? AppTheme.successDark
                    : AppTheme.textSecondary,
              ),
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
    String? phone, {
    CrossAxisAlignment align = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          style: AppTheme.metaHelper.copyWith(fontSize: 12, letterSpacing: 0.3),
        ),
        const SizedBox(height: 10),
        Text(
          primary,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w600,
          ),
          textAlign: align == CrossAxisAlignment.end
              ? TextAlign.right
              : TextAlign.left,
        ),
        const SizedBox(height: 6),
        Text(
          address,
          style: AppTheme.bodyText.copyWith(fontSize: 13, height: 1.5),
          textAlign: align == CrossAxisAlignment.end
              ? TextAlign.right
              : TextAlign.left,
        ),
        if ((phone ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            phone!,
            style: AppTheme.bodyText.copyWith(fontSize: 13),
            textAlign: align == CrossAxisAlignment.end
                ? TextAlign.right
                : TextAlign.left,
          ),
        ],
      ],
    );
  }

  Widget _meta(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.metaHelper.copyWith(fontSize: 12, letterSpacing: 0.3),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _itemsTable(List<PurchaseOrderItem> items, _PoTxnSummary summary) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            color: AppTheme.bgLight,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Expanded(
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
                const Expanded(
                  child: Center(
                    child: Text(
                      'ORDERED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'LOCATION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'STATUS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'RATE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const Expanded(
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
          ...items.map((item) {
            double itemReceivedQty = 0.0;
            for (final r in summary.receives) {
              final itemsList =
                  r['purchases_purchase_receive_items'] as List<dynamic>? ?? [];
              for (final recItem in itemsList) {
                final recProdId = recItem['product_id']?.toString();
                if (recProdId == item.productId) {
                  itemReceivedQty +=
                      (recItem['received'] as num?)?.toDouble() ?? 0.0;
                }
              }
            }
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          width: 32,
                          height: 32,
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName ?? 'Unnamed Item',
                                style: AppTheme.linkText.copyWith(fontSize: 13),
                              ),
                              if (item.description != null &&
                                  item.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.description!,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          item.quantity.toInt().toString(),
                          style: AppTheme.bodyText.copyWith(fontSize: 13),
                        ),
                        Text(
                          'pcs',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'ZABNIX PRIVATE LIMITED',
                      style: AppTheme.bodyText.copyWith(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${itemReceivedQty.toInt()} Received',
                          style: AppTheme.bodyText.copyWith(fontSize: 11),
                        ),
                        Text(
                          '0 Billed',
                          style: AppTheme.bodyText.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '₹${item.rate.toStringAsFixed(2)}',
                      style: AppTheme.bodyText.copyWith(fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '₹${(item.quantity * item.rate).toStringAsFixed(2)}',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
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

  Widget _totalsSummary(PurchaseOrder order) {
    Widget row(
      String label,
      String value, {
      bool isBold = false,
      bool isTotal = false,
    }) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTheme.bodyText.copyWith(
                color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                fontSize: isTotal ? 16 : 13,
              ),
            ),
            if (value.isNotEmpty)
              Text(
                value,
                style: AppTheme.bodyText.copyWith(
                  fontWeight: (isBold || isTotal)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontSize: isTotal ? 16 : 13,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        row('Sub Total', '₹${order.subTotal.toStringAsFixed(2)}', isBold: true),
        row('Total Quantity : ${order.totalQuantity.toInt()}', ''),
        if (order.discount > 0)
          row(
            'Discount (${order.discountType == 'percentage' ? '${order.discount}%' : 'Fixed'})',
            '-₹${(order.discountType == 'percentage' ? (order.subTotal * order.discount / 100) : order.discount).toStringAsFixed(2)}',
          ),
        const Divider(height: 24),
        row('Total', '₹${order.total.toStringAsFixed(2)}', isTotal: true),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'No purchase orders yet',
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Create your first purchase order to get started',
            style: AppTheme.metaHelper,
          ),
          const SizedBox(height: AppTheme.space24),
          ZButton.primary(
            label: 'Create Purchase Order',
            onPressed: () {
              context.push('/purchases/purchase-orders/create');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.errorRed),
          const SizedBox(height: AppTheme.space16),
          Text(
            'Failed to load purchase orders',
            style: AppTheme.sectionHeader.copyWith(color: AppTheme.errorRed),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(error, style: AppTheme.metaHelper, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.space24),
          ZButton.primary(
            label: 'Retry',
            onPressed: () {
              ref.invalidate(purchaseOrdersProvider);
            },
          ),
        ],
      ),
    );
  }

  ButtonStyle _viewMenuItemStyle(bool isSelected) {
    return MenuItemButton.styleFrom(
      foregroundColor: isSelected ? AppTheme.primaryBlue : AppTheme.textPrimary,
      backgroundColor: isSelected
          ? AppTheme.primaryBlue.withValues(alpha: 0.05)
          : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: AppTheme.bodyText.copyWith(
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
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
        child: Icon(icon, size: 16, color: color ?? AppTheme.textPrimary),
      ),
    );
  }
}



extension on _PurchaseOrderOverviewScreenState {
  Widget _pdfCard(
    PurchaseOrder order,
    List<PurchaseOrderItem> items,
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
                label: order.status.toUpperCase(),
                color: order.status.toLowerCase() == 'issued'
                    ? AppTheme.successDark
                    : AppTheme.primaryBlue,
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
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'PURCHASE ORDER',
                            style: AppTheme.sectionHeader.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Purchase Order# ${order.orderNumber}',
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
                          'Vendor',
                          order.vendorName ?? 'No Vendor',
                          _address(
                            _formatVendorAddress(order.vendor?.billingAddress),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: _pdfAddress(
                          'Ship To',
                          order.warehouseName ?? 'ZABNIX PRIVATE LIMITED',
                          'Address Line 1\nCity, State PIN', // Fallback for ship to
                        ),
                      ),
                      const SizedBox(width: 30),
                      Expanded(
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text(
                            'Order Date : ${_date(order.orderDate)}',
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
                        'Payment Terms',
                        order.paymentTerms ?? 'Net 30',
                      ),
                      _infoPair('Notes', order.notes ?? 'No notes available'),
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

  Widget _pdfItems(List<PurchaseOrderItem> items) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF333333),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  '#  ITEM & DESCRIPTION',
                  style: AppTheme.bodyText.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'HSN/SAC',
                  style: AppTheme.bodyText.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'QTY',
                  textAlign: TextAlign.right,
                  style: AppTheme.bodyText.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'RATE',
                  textAlign: TextAlign.right,
                  style: AppTheme.bodyText.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'AMOUNT',
                  textAlign: TextAlign.right,
                  style: AppTheme.bodyText.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) =>
              const Divider(height: 1, color: AppTheme.borderLight),
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${index + 1}',
                          style: AppTheme.bodyText.copyWith(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName ?? '',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (item.description?.isNotEmpty == true)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    item.description!,
                                    style: AppTheme.bodyText.copyWith(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.hsnCode ?? '—',
                      style: AppTheme.bodyText.copyWith(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${item.quantity}',
                      textAlign: TextAlign.right,
                      style: AppTheme.bodyText.copyWith(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.rate.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: AppTheme.bodyText.copyWith(fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.amount.toStringAsFixed(2),
                      textAlign: TextAlign.right,
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const Divider(height: 1, color: AppTheme.textPrimary),
      ],
    );
  }

  Widget _totals(
    PurchaseOrder order,
    List<PurchaseOrderItem> items, {
    bool dense = false,
  }) {
    return Column(
      children: [
        _totalRow('Sub Total', order.subTotal.toStringAsFixed(2), dense: dense),
        if (order.discount > 0)
          _totalRow(
            'Discount (${order.discountType == 'percentage' ? '${order.discount}%' : 'Fixed'})',
            '-${(order.discountType == 'percentage' ? (order.subTotal * order.discount / 100) : order.discount).toStringAsFixed(2)}',
            dense: dense,
          ),
        if (order.taxAmount > 0)
          _totalRow('Tax', order.taxAmount.toStringAsFixed(2), dense: dense),
        if (order.adjustment != 0)
          _totalRow(
            'Adjustment',
            order.adjustment.toStringAsFixed(2),
            dense: dense,
          ),
        const SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(
            vertical: dense ? 8 : 12,
            horizontal: 8,
          ),
          color: AppTheme.bgLight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: dense ? 14 : 16,
                ),
              ),
              Text(
                '₹ ${order.total.toStringAsFixed(2)}',
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: dense ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _totalRow(String label, String value, {bool dense = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dense ? 4 : 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: dense ? 13 : 14,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTheme.bodyText.copyWith(fontSize: dense ? 13 : 14),
          ),
        ],
      ),
    );
  }

  Widget _infoPair(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.metaHelper.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: AppTheme.bodyText.copyWith(fontSize: 13)),
      ],
    );
  }

  BoxDecoration _paperDecoration() {
    return BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  String _formatVendorAddress(Map<String, dynamic>? address) {
    if (address == null) return '';
    final List<String> parts = [];
    if (address['attention'] != null &&
        address['attention'].toString().isNotEmpty)
      parts.add(address['attention'].toString());
    if (address['street1'] != null && address['street1'].toString().isNotEmpty)
      parts.add(address['street1'].toString());
    if (address['street2'] != null && address['street2'].toString().isNotEmpty)
      parts.add(address['street2'].toString());
    if (address['city'] != null && address['city'].toString().isNotEmpty)
      parts.add(address['city'].toString());
    if (address['state'] != null && address['state'].toString().isNotEmpty)
      parts.add(address['state'].toString());
    if (address['zip'] != null && address['zip'].toString().isNotEmpty)
      parts.add(address['zip'].toString());
    if (address['country'] != null && address['country'].toString().isNotEmpty)
      parts.add(address['country'].toString());
    return parts.join(', ');
  }

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
          if (data['street1'] != null &&
              data['street1'].toString().isNotEmpty) {
            parts.add(data['street1'].toString());
          }
          if (data['street2'] != null &&
              data['street2'].toString().isNotEmpty) {
            parts.add(data['street2'].toString());
          }

          final cityStateZip =
              [
                    data['city'],
                    data['state_name'] ?? data['state'],
                    data['pincode'] ?? data['zip_code'] ?? data['zip'],
                  ]
                  .where((e) => e != null && e.toString().trim().isNotEmpty)
                  .join(', ');

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

    return address.replaceAll(', ', '\n');
  }

  String _date(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM/yyyy').format(date);
  }
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
            top: 29,
            left: -41,
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
            top: 27,
            left: -43,
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

class PurchaseOrderEmailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const PurchaseOrderEmailScreen({super.key, required this.orderId});

  @override
  ConsumerState<PurchaseOrderEmailScreen> createState() =>
      _PurchaseOrderEmailScreenState();
}

class _PurchaseOrderEmailScreenState
    extends ConsumerState<PurchaseOrderEmailScreen> {
  bool _isLoading = true;
  PurchaseOrder? _order;
  final _fromCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    try {
      final repository = ref.read(purchaseOrderRepositoryProvider);
      final order = await repository.getPurchaseOrder(widget.orderId);
      if (order != null) {
        final orgSettings = ref.read(orgSettingsProvider).asData?.value;
        final orgName = orgSettings?.name ?? 'ZABNIX PRIVATE LIMITED';
        const orgEmail = 'zabnixprivatelimited@gmail.com';
        final vendorName = order.vendorName ?? 'Vendor';
        final vendorEmail = order.vendor?.email ?? 'vendor@example.com';

        _fromCtrl.text = '$orgName <$orgEmail>';
        _toCtrl.text = '$vendorName <$vendorEmail>';
        _subjectCtrl.text =
            'Purchase Order from $orgName (Purchase Order #: ${order.orderNumber})';

        final dateStr = DateFormat('dd-MM-yyyy').format(order.orderDate);
        final amountStr = NumberFormat(
          '#,##,##0.00',
          'en_IN',
        ).format(order.total);

        _bodyCtrl.text =
            '''Dear $vendorName,

The purchase order (${order.orderNumber}) is attached with this email.

An overview of the purchase order is available below:
----------------------------------------------------------------------------------------------------

Purchase Order # : ${order.orderNumber}

----------------------------------------------------------------------------------------------------

Order Date : $dateStr
Amount : ₹$amountStr(in INR)

----------------------------------------------------------------------------------------------------

Please go through it and confirm the order. We look forward to working with you again.

Regards,
$orgName''';

        setState(() {
          _order = order;
          _isLoading = false;
        });
      } else {
        if (mounted) {
          ZerpaiToast.error(context, 'Purchase order not found');
          context.pop();
        }
      }
    } catch (e) {
      AppLogger.error(
        'Error loading order for email',
        error: e,
        module: 'purchases',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to load order data: $e');
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final order = _order!;
    final vendorName = order.vendorName ?? 'Vendor';

    return EmailComposerScreen(
      title: 'Email To $vendorName',
      initialFrom: _fromCtrl.text,
      initialTo: _toCtrl.text,
      initialSubject: _subjectCtrl.text,
      initialBody: _bodyCtrl.text,
      attachmentName: order.orderNumber,
      attachmentLabel: 'Attach Purchase Order PDF',
      onCancel: () {
        context.go('/purchases/purchase-orders/${order.id}');
      },
      onSend: (from, to, subject, body, attachPdf) async {
        try {
          final supabase = Supabase.instance.client;
          await supabase
              .from('purchase_orders')
              .update({'status': 'Issued'})
              .eq('id', order.id!);

          ref.invalidate(purchaseOrdersProvider);
          ref.invalidate(purchaseOrderProvider(order.id!));

          if (context.mounted) {
            ZerpaiToast.success(context, 'Email sent successfully');
            context.go('/purchases/purchase-orders/${order.id}');
          }
        } catch (e) {
          if (context.mounted) {
            ZerpaiToast.error(context, 'Failed to send email: $e');
          }
        }
      },
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


