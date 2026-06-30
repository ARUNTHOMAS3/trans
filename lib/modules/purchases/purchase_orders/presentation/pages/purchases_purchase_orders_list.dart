import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../../../core/theme/app_theme.dart';
import '../../../../../../shared/widgets/z_button.dart';
import '../../../../../../shared/widgets/zerpai_layout.dart';
import '../../../../../../shared/widgets/tables/table_header_menu.dart';
import '../../../../../../shared/widgets/tables/table_more_menu.dart';
import '../../../../../../shared/widgets/skeleton.dart';
import '../../providers/purchases_purchase_orders_provider.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import '../../../../../../app/providers/org_settings_provider.dart';
import '../../../../../../core/models/org_settings_model.dart';
import '../../../../../../shared/widgets/email_composer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/providers/purchase_receives_provider.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/models/purchases_purchase_receives_model.dart';
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:zerpai_erp/shared/widgets/z_expandable_tabs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../shared/models/column_config.dart';
import '../../../../../../shared/widgets/tables/column_customizer.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../../core/providers/entity_provider.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/po_item_details_sidebar_widget.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';

import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:web/web.dart' as web;

const _poFilterOptions = <FavoriteFilterOption>[
  FavoriteFilterOption(label: 'All', value: 'all'),
  FavoriteFilterOption(label: 'Draft', value: 'Draft'),
  FavoriteFilterOption(label: 'Issued', value: 'Issued'),
  FavoriteFilterOption(label: 'Closed', value: 'Closed'),
];


class _PoTxnSummary {
  final List<Map<String, dynamic>> receives;
  final List<Map<String, dynamic>> bills;
  final List<Map<String, dynamic>> attachments;
  final String receiveStatus;
  final String billStatus;
  const _PoTxnSummary({
    required this.receives,
    required this.bills,
    required this.attachments,
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
  FavoriteFilterOption _activeOption = _poFilterOptions.first;
  Map<String, double>? _customColumnWidths;
  bool _showPdfView = false;
  bool _showCommentsSidebar = false;
  final LayerLink _attachmentBadgeLink = LayerLink();
  OverlayEntry? _attachmentListOverlay;
  final ScrollController _horizontalScrollController = ScrollController();
  Future<_PoTxnSummary>? _currentPoTxnSummaryFuture;
  String? _currentPoTxnSummaryOrderId;
  String? _currentPoTxnStatus;
  DateTime? _currentPoTxnUpdatedAt;

  List<ColumnConfig> _allColumns = [];
  final List<String> _visibleColumns = [];

  final Map<String, String> _columnLabels = {
    'date': 'DATE',
    'location': 'WAREHOUSE',
    'order_number': 'ORDER NUMBER',
    'reference_number': 'REFERENCE NUMBER',
    'vendor_name': 'VENDOR NAME',
    'status': 'STATUS',
    'received': 'RECEIVED',
    'billed': 'BILLED',
    'amount': 'AMOUNT',
    'delivery_date': 'Delivery Date',
    'company_name': 'Company Name',
    'expected_delivery_date': 'Expected Delivery Date',
  };

  void _initializeColumns() {
    _allColumns = [
      ColumnConfig(id: 'date', label: 'DATE', orderIndex: 0, isLocked: true),
      ColumnConfig(id: 'location', label: 'WAREHOUSE', orderIndex: 1),
      ColumnConfig(
        id: 'order_number',
        label: 'ORDER NUMBER',
        orderIndex: 2,
        isLocked: true,
      ),
      ColumnConfig(
        id: 'reference_number',
        label: 'REFERENCE NUMBER',
        orderIndex: 3,
        isVisible: false,
      ),
      ColumnConfig(
        id: 'vendor_name',
        label: 'VENDOR NAME',
        orderIndex: 4,
        isLocked: true,
      ),
      ColumnConfig(
        id: 'status',
        label: 'STATUS',
        orderIndex: 5,
        isLocked: true,
      ),
      ColumnConfig(id: 'received', label: 'RECEIVED', orderIndex: 6),
      ColumnConfig(id: 'billed', label: 'BILLED', orderIndex: 7),
      ColumnConfig(
        id: 'amount',
        label: 'AMOUNT',
        orderIndex: 8,
        isLocked: true,
      ),
      ColumnConfig(
        id: 'delivery_date',
        label: 'Delivery Date',
        orderIndex: 9,
        isVisible: false,
      ),
      ColumnConfig(
        id: 'company_name',
        label: 'Company Name',
        orderIndex: 10,
        isVisible: false,
      ),
      ColumnConfig(
        id: 'expected_delivery_date',
        label: 'Expected Delivery Date',
        orderIndex: 11,
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
    List<dynamic> receivesList = [];
    try {
      final receivesResp = await supabase
          .from('purchase_receives')
          .select(
            'id,purchase_receive_number,received_date,status,bill_no,purchase_order_id,purchase_receive_items(id,item_id,ordered,received,quantity_to_receive,purchase_receive_item_batches(quantity,foc_qty))',
          )
          .eq('purchase_order_id', order.id ?? '')
          .order('created_at', ascending: false);
      receivesList = receivesResp as List<dynamic>;
    } catch (e) {
      debugPrint('Error loading PO receives: $e');
    }

    List<dynamic> billsList = [];
    try {
      final billsResp = await supabase
          .from('bills')
          .select(
            'id,bill_number,bill_date,status,total:grand_total,due_date,order_number,bill_items(product_id,quantity,purchase_receive_item_id)',
          )
          .ilike('order_number', '%${order.orderNumber}%')
          .order('created_at', ascending: false);
      final normalizedPoNum = order.orderNumber.trim().toLowerCase();
      billsList = (billsResp as List<dynamic>).where((b) {
        final orderNumStr = (b['order_number'] ?? '').toString().toLowerCase();
        final parts = orderNumStr.split(',').map((p) => p.trim()).toList();
        return parts.contains(normalizedPoNum);
      }).toList();
    } catch (e) {
      debugPrint('Error loading PO bills: $e');
    }

    List<dynamic> attachmentsList = [];
    try {
      final attachmentsResp = await supabase
          .from('purchase_order_attachments')
          .select('id,file_name,file_path,file_size,file_type,uploaded_at')
          .eq('purchase_order_id', order.id ?? '')
          .order('uploaded_at', ascending: false);
      attachmentsList = attachmentsResp as List<dynamic>;
    } catch (e) {
      debugPrint('Error loading PO attachments: $e');
    }

    final receives = receivesList
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final bills = billsList
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final attachments = attachmentsList
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final hasInTransit = receives.any(
      (r) {
        final statusStr = r['status']?.toString().toLowerCase() ?? '';
        return statusStr == 'in transit' || statusStr == 'intransit';
      },
    );

    double totalReceived = 0.0;
    for (final r in receives) {
      final itemsList =
          r['purchases_purchase_receive_items'] as List<dynamic>? ??
          r['purchase_receive_items'] as List<dynamic>? ??
          [];
      for (final item in itemsList) {
        final batches = item['purchase_receive_item_batches'] as List<dynamic>? ??
            item['purchases_purchase_receive_item_batches'] as List<dynamic>? ??
            [];
        if (batches.isNotEmpty) {
          for (final b in batches) {
            totalReceived += double.tryParse(b['quantity']?.toString() ?? '0.0') ?? 0.0;
          }
        } else {
          totalReceived += double.tryParse(item['quantity_to_receive']?.toString() ?? item['received']?.toString() ?? '0.0') ?? 0.0;
        }
      }
    }

    final expectedTotalQuantity = order.items.fold(
      0.0,
      (sum, item) => sum + (item.quantity - item.cancelledQuantity),
    );

    final receiveStatus = receives.isEmpty
        ? 'Yet to be Received'
        : hasInTransit
        ? 'In Transit'
        : totalReceived < expectedTotalQuantity
        ? 'Partially Received'
        : 'Received';

    final poReceiveItemIds = <String>{};
    for (final r in receives) {
      final itemsList =
          r['purchases_purchase_receive_items'] as List<dynamic>? ??
          r['purchase_receive_items'] as List<dynamic>? ??
          [];
      for (final item in itemsList) {
        final itemId = item['id']?.toString();
        if (itemId != null) {
          poReceiveItemIds.add(itemId);
        }
      }
    }

    double totalBilled = 0.0;
    for (final b in bills) {
      final statusStr = b['status']?.toString().toLowerCase() ?? '';
      if (statusStr == 'void') continue;
      
      final orderNumStr = (b['order_number'] ?? '').toString();
      final isMultiPo = orderNumStr.contains(',');
      
      final itemsList = b['bill_items'] as List<dynamic>? ?? [];
      for (final item in itemsList) {
        final prItemId = item['purchase_receive_item_id']?.toString();
        if (prItemId != null) {
          if (poReceiveItemIds.contains(prItemId)) {
            totalBilled += double.tryParse(item['quantity']?.toString() ?? '0.0') ?? 0.0;
          }
        } else if (!isMultiPo) {
          totalBilled += double.tryParse(item['quantity']?.toString() ?? '0.0') ?? 0.0;
        }
      }
    }

    final billStatus = totalBilled <= 0.0
        ? 'Yet to be Billed'
        : totalBilled < expectedTotalQuantity
        ? 'Partially Billed'
        : 'Billed';
    return _PoTxnSummary(
      receives: receives,
      bills: bills,
      attachments: attachments,
      receiveStatus: receiveStatus,
      billStatus: billStatus,
    );
  }

  void _refreshPoTxnSummary(PurchaseOrder order) {
    if (mounted) {
      setState(() {
        _currentPoTxnSummaryFuture = _loadPoTxnSummary(order);
      });
    }
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
      final found = _poFilterOptions.where(
        (v) => v.label.toLowerCase() == widget.initialFilter!.toLowerCase(),
      );
      if (found.isNotEmpty) {
        _activeOption = found.first;
      }
    }
  }

  @override
  void dispose() {
    POItemDetailsSidebar.hide();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchaseOrdersAsync = ref.watch(
      purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
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
                        : _buildMainToolbar(context, hasSelection, sorted),
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
    if (_activeOption.value != 'all') {
      result = result
          .where(
            (o) => o.status.toLowerCase() == _activeOption.value.toLowerCase(),
          )
          .toList();
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
        case 'delivery_date':
          cmp = (a.expectedDeliveryDate ?? a.orderDate).compareTo(
            b.expectedDeliveryDate ?? b.orderDate,
          );
          break;
        case 'created_at':
          cmp = (a.createdAt ?? a.orderDate).compareTo(
            b.createdAt ?? b.orderDate,
          );
          break;
        case 'updated_at':
          cmp = (a.updatedAt ?? a.orderDate).compareTo(
            b.updatedAt ?? b.orderDate,
          );
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  Widget _buildMainToolbar(
    BuildContext context,
    bool hasSelection,
    List<PurchaseOrder> orders,
  ) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FavoriteFilterDropdown(
            moduleName: 'purchase_orders',
            options: _poFilterOptions,
            selectedOption: _activeOption,
            onChanged: (opt) {
              setState(() {
                _activeOption = opt;
              });
            },
          ),
          const Spacer(),
          // In Transit Receives link button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.externalLink,
                size: 16,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(width: 8),
              ZerpaiLinkText(
                text: 'In Transit Receives',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                onTap: () {
                  context.go('/purchases/purchase-receives?filter=intransit');
                },
              ),
            ],
          ),
          const SizedBox(width: 16),
          ZButton.primary(
            onPressed: () {
              context.push('/purchases/purchase-orders/create');
            },
            icon: LucideIcons.plus,
            label: 'New',
          ),
          const SizedBox(width: 8),
          ZTableMoreMenu(
            width: 38,
            height: 38,
            menuChildren: _buildMoreMenuChildren(),
          ),
        ],
      ),
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
                      moduleName: 'purchase_orders',
                      options: _poFilterOptions,
                      selectedOption: _activeOption,
                      isCompact: true,
                      onChanged: (opt) {
                        setState(() {
                          _activeOption = opt;
                        });
                      },
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () =>
                          context.go('/purchases/purchase-orders/create'),
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
      animationDuration: Duration.zero,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
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

        ref.read(apiClientProvider).clearCache('purchase-orders');
        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        for (var id in _selectedIds) {
          ref.invalidate(purchaseOrderProvider(id));
        }

        ZerpaiToast.success(
          context,
          'Selected purchase orders marked as Issued',
        );
        setState(() {
          _currentPoTxnSummaryOrderId = null;
          _currentPoTxnStatus = null;
          _currentPoTxnUpdatedAt = null;
          _selectedIds.clear();
        });
      } catch (e) {
        ZerpaiToast.error(context, 'Failed to update status: $e');
      }
    } else if (actionLabel == 'Mark as Received') {
      try {
        final ids = _selectedIds.toList();
        setState(() => _selectedIds.clear());

        final repo = ref.read(purchaseReceiveRepositoryProvider);
        int receivedCount = 0;
        int failedCount = 0;

        for (final id in ids) {
          final order = await ref.read(purchaseOrderProvider(id).future);
          if (order == null) continue;

          final hasTrackedItems = order.items.any((item) {
            if (item.isHeader) return false;
            return item.trackBatches || item.trackSerialNumber || item.trackBinLocation;
          });

          if (hasTrackedItems) {
            failedCount++;
            continue;
          }

          final nextNumberData = await repo.getNextPurchaseReceiveNumber();
          final nextReceiveNumber = nextNumberData['formatted'] ?? '';

          final receive = PurchaseReceive(
            purchaseReceiveNumber: nextReceiveNumber,
            receivedDate: DateTime.now(),
            vendorId: order.vendorId,
            vendorName: order.vendorName,
            purchaseOrderId: order.id,
            purchaseOrderNumber: order.orderNumber,
            warehouseId: order.warehouseId ?? order.deliveryWarehouseId,
            status: 'received',
            notes: 'Automatically created via PO bulk Mark as Received',
            items: order.items.where((item) => !item.isHeader).map((item) {
              return PurchaseReceiveItem(
                itemId: item.productId,
                itemName: item.productName ?? '',
                description: item.description,
                ordered: item.quantity,
                received: 0,
                inTransit: 0,
                cancelled: item.cancelledQuantity,
                quantityToReceive: item.quantity - item.cancelledQuantity,
                batches: [],
                purchaseOrderId: order.id,
                purchaseOrderNumber: order.orderNumber,
              );
            }).toList(),
          );

          await repo.createPurchaseReceive(receive);

          final supabase = Supabase.instance.client;
          await supabase
              .from('purchase_orders')
              .update({'status': 'Closed'})
              .eq('id', order.id!);

          receivedCount++;
        }

        ref.read(apiClientProvider).clearCache('purchase-orders');
        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        for (var id in ids) {
          ref.invalidate(purchaseOrderProvider(id));
        }
        ref.read(purchaseReceivesProvider.notifier).fetchReceives();

        setState(() {
          _currentPoTxnSummaryOrderId = null;
          _currentPoTxnStatus = null;
          _currentPoTxnUpdatedAt = null;
        });

        if (context.mounted) {
          if (failedCount > 0) {
            ZerpaiToast.info(
              context,
              'Marked $receivedCount purchase order(s) as Received. $failedCount skipped because they contain tracked items.',
            );
          } else {
            ZerpaiToast.success(
              context,
              'Selected purchase orders marked as Received (Closed) & Receives created successfully',
            );
          }
        }
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

        ref.read(apiClientProvider).clearCache('purchase-orders');
        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        for (var id in _selectedIds) {
          ref.invalidate(purchaseOrderProvider(id));
        }

        ZerpaiToast.success(
          context,
          'Selected purchase orders marked as Unreceived (Issued)',
        );
        setState(() {
          _currentPoTxnSummaryOrderId = null;
          _currentPoTxnStatus = null;
          _currentPoTxnUpdatedAt = null;
          _selectedIds.clear();
        });
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

        ref.read(apiClientProvider).clearCache('purchase-orders');
        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        for (var id in _selectedIds) {
          ref.invalidate(purchaseOrderProvider(id));
        }

        ZerpaiToast.success(
          context,
          'Selected purchase orders items cancelled',
        );
        setState(() {
          _currentPoTxnSummaryOrderId = null;
          _currentPoTxnStatus = null;
          _currentPoTxnUpdatedAt = null;
          _selectedIds.clear();
        });
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

        ref.read(apiClientProvider).clearCache('purchase-orders');
        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        for (var id in _selectedIds) {
          ref.invalidate(purchaseOrderProvider(id));
        }

        ZerpaiToast.success(context, 'Selected purchase orders items reopened');
        setState(() {
          _currentPoTxnSummaryOrderId = null;
          _currentPoTxnStatus = null;
          _currentPoTxnUpdatedAt = null;
          _selectedIds.clear();
        });
      } catch (e) {
        ZerpaiToast.error(context, 'Failed to reopen items: $e');
      }
    } else if (actionLabel == 'Convert to Bill') {
      context.go('/purchases/bills/create?poId=$firstOrderId');
    } else if (actionLabel == 'Delete') {
      try {
        final supabase = Supabase.instance.client;
        final selectedIds = _selectedIds.toList();
        final response = await supabase
            .from('purchase_orders')
            .select('id, order_number')
            .filter('id', 'in', selectedIds);

        for (final row in response) {
          final id = row['id'] as String;
          final currentNum = row['order_number'] as String;
          final newNum = currentNum.startsWith('SD-') ? currentNum : 'SD-$currentNum';
          await supabase
              .from('purchase_orders')
              .update({
                'is_delete': true,
                'order_number': newNum,
              })
              .eq('id', id);
        }

        ref.read(apiClientProvider).clearCache('purchase-orders');
        ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
        ZerpaiToast.success(context, 'Selected purchase orders deleted');
        setState(() {
          _currentPoTxnSummaryOrderId = null;
          _currentPoTxnStatus = null;
          _currentPoTxnUpdatedAt = null;
          _selectedIds.clear();
        });
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
                          order.warehouseName ?? '-',
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
                        style: const pw.TextStyle(fontSize: 10),
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
                        _pwTotalRow(
                          'Sub Total',
                          'INR ${order.subTotal.toStringAsFixed(2)}',
                        ),
                        if (order.discount > 0)
                          _pwTotalRow(
                            'Discount (${order.discountType == 'percentage' ? '${order.discount}%' : 'Fixed'})',
                            '-INR ${(order.discountType == 'percentage' ? (order.subTotal * order.discount / 100) : order.discount).toStringAsFixed(2)}',
                          ),
                        if (order.taxAmount > 0)
                          _pwTotalRow(
                            'Tax',
                            'INR ${order.taxAmount.toStringAsFixed(2)}',
                          ),
                        if (order.adjustment != 0)
                          _pwTotalRow(
                            'Adjustment',
                            'INR ${order.adjustment.toStringAsFixed(2)}',
                          ),
                        pw.Divider(color: PdfColors.grey300),
                        pw.Container(
                          color: const PdfColor.fromInt(0xFFF9FAFB),
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
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
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(height: 1, color: PdfColors.black),
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

  List<Widget> _buildMoreMenuChildren() {
    return [
      SubmenuButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        menuStyle: ZTableMoreMenu.submenuMenuStyle(),
        alignmentOffset: const Offset(4, 0),
        leadingIcon: const Icon(LucideIcons.arrowUpDown, size: 16),
        menuChildren: [
          _buildSortMenuItem('Purchase Order#', 'order_number'),
          _buildSortMenuItem('Date', 'order_date'),
          _buildSortMenuItem('Vendor Name', 'vendor_name'),
          _buildSortMenuItem('Amount', 'total'),
          _buildSortMenuItem('Delivery Date', 'delivery_date'),
          _buildSortMenuItem('Created Time', 'created_at'),
          _buildSortMenuItem('Last Modified Time', 'updated_at'),
        ],
        child: const Text('Sort by'),
      ),
      MenuItemButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        leadingIcon: const Icon(LucideIcons.download, size: 16),
        onPressed: () {},
        child: const Text('Import Purchase Orders'),
      ),
      SubmenuButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        menuStyle: ZTableMoreMenu.submenuMenuStyle(),
        alignmentOffset: const Offset(4, 0),
        leadingIcon: const Icon(LucideIcons.upload, size: 16),
        menuChildren: [
          MenuItemButton(
            style: ZTableMoreMenu.menuItemButtonStyle(),
            child: const Text('Export Purchase Orders'),
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
        onPressed: () {
          ref.read(apiClientProvider).clearCache('purchase-orders');
          ref.invalidate(
            purchaseOrdersProvider(
              PurchaseOrderFilter(limit: 500),
            ),
          );
          if (widget.initialSelectedId != null) {
            ref.invalidate(purchaseOrderProvider(widget.initialSelectedId!));
            setState(() {
              _currentPoTxnSummaryOrderId = null;
              _currentPoTxnStatus = null;
              _currentPoTxnUpdatedAt = null;
            });
          }
        },
        child: const Text('Refresh List'),
      ),
      MenuItemButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        leadingIcon: const Icon(LucideIcons.rotateCcw, size: 16),
        onPressed: () async {
          setState(() {
            _customColumnWidths = null;
          });
        },
        child: const Text('Reset Column Width'),
      ),
    ];
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
      'company_name': (150.0, 1.5),
      'expected_delivery_date': (120.0, 1.2),
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
        content = Text(order.warehouseName ?? '-', style: AppTheme.tableCell);
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
        Widget ball;
        final recStatus = order.receiveStatus?.toLowerCase() ?? 'none';
        if (recStatus == 'full') {
          ball = const Icon(
            Icons.circle,
            color: Colors.orange,
            size: 12,
          );
        } else if (recStatus == 'partial') {
          ball = Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.circle_outlined,
                color: Colors.orange,
                size: 12,
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.5,
                  child: const Icon(
                    Icons.circle,
                    color: Colors.orange,
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
        content = Center(child: ball);
        break;
      case 'billed':
        Widget ball;
        final bStatus = order.billStatus?.toLowerCase() ?? 'none';
        if (bStatus == 'full') {
          ball = const Icon(
            Icons.circle,
            color: Colors.green,
            size: 12,
          );
        } else if (bStatus == 'partial') {
          ball = Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.circle_outlined,
                color: Colors.green,
                size: 12,
              ),
              ClipRect(
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.5,
                  child: const Icon(
                    Icons.circle,
                    color: Colors.green,
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
        content = Center(child: ball);
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
      case 'company_name':
        content = Text(order.vendor?.companyName ?? order.vendorName ?? '-', style: AppTheme.tableCell);
        break;
      case 'expected_delivery_date':
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
            style: AppTheme.tableCell.copyWith(
              overflow: _shouldWrapText ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            maxLines: _shouldWrapText ? null : 1,
            softWrap: _shouldWrapText,
            child: content,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return AppTheme.warningOrange;
      case 'approved':
      case 'closed':
        return AppTheme.successGreen;
      case 'pending':
      case 'issued':
        return AppTheme.primaryBlue;
      case 'rejected':
        return AppTheme.errorRed;
      case 'cancelled':
      case 'canceled':
        return const Color(0xFF6B7280); // Grey color
      default:
        return AppTheme.textSecondary;
    }
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    return Text(
      status.toUpperCase(),
      style: AppTheme.metaHelper.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  void _showItemDetailsSidebar(
    PurchaseOrderItem row, {
    String? vendorName,
    int initialTabIndex = 0,
  }) {
    POItemDetailsSidebar.show(
      context,
      row,
      initialTabIndex: initialTabIndex,
      vendorName: vendorName,
    );
  }

  Widget _detailPane(String orderId, PurchaseOrder? poSummary) {
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

        if (_currentPoTxnSummaryOrderId != order.id ||
            _currentPoTxnStatus != order.status ||
            _currentPoTxnUpdatedAt != order.updatedAt) {
          _currentPoTxnSummaryOrderId = order.id;
          _currentPoTxnStatus = order.status;
          _currentPoTxnUpdatedAt = order.updatedAt;
          _currentPoTxnSummaryFuture = _loadPoTxnSummary(order);
        }

        return FutureBuilder<_PoTxnSummary>(
          future: _currentPoTxnSummaryFuture,
          builder: (context, summarySnap) {
            if (summarySnap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: DetailContentSkeleton(),
              );
            }
            final summary =
                summarySnap.data ??
                const _PoTxnSummary(
                  receives: [],
                  bills: [],
                  attachments: [],
                  receiveStatus: 'Yet to be Received',
                  billStatus: 'Yet to be Billed',
                );

            return StatefulBuilder(
              builder: (context, setInnerState) {
                // Compute displayStatus: check whether ordered value = received/billed in purchase_receive_items/bill_items


                final poReceiveItemIds = <String>{};
                for (final r in summary.receives) {
                  final itemsList =
                      r['purchases_purchase_receive_items'] as List<dynamic>? ??
                      r['purchase_receive_items'] as List<dynamic>? ??
                      [];
                  for (final item in itemsList) {
                    final itemId = item['id']?.toString();
                    if (itemId != null) {
                      poReceiveItemIds.add(itemId);
                    }
                  }
                }

                bool isFullyBilled = false;
                if (order.items.isNotEmpty) {
                  isFullyBilled = true;
                  for (final poItem in order.items) {
                    if (poItem.isHeader) continue;
                    double totalBilledForProduct = 0.0;
                    for (final b in summary.bills) {
                      final status = (b['status']?.toString() ?? 'draft').toLowerCase();
                      if (status == 'void') continue;
                      
                      final orderNumStr = (b['order_number'] ?? '').toString();
                      final isMultiPo = orderNumStr.contains(',');
                      
                      final itemsList = b['bill_items'] as List<dynamic>? ?? [];
                      for (final item in itemsList) {
                        final billProdId = item['product_id']?.toString();
                        if (billProdId == poItem.productId) {
                          final prItemId = item['purchase_receive_item_id']?.toString();
                          if (prItemId != null) {
                            if (poReceiveItemIds.contains(prItemId)) {
                              totalBilledForProduct +=
                                  double.tryParse(item['quantity']?.toString() ?? '0.0') ?? 0.0;
                            }
                          } else if (!isMultiPo) {
                            totalBilledForProduct +=
                                double.tryParse(item['quantity']?.toString() ?? '0.0') ?? 0.0;
                          }
                        }
                      }
                    }
                    if (totalBilledForProduct < (poItem.quantity - poItem.cancelledQuantity) - 0.0001) {
                      isFullyBilled = false;
                      break;
                    }
                  }
                }

                String displayStatus = order.status;
                final lowerStatus = order.status.toLowerCase();
                if (lowerStatus != 'draft' && 
                    lowerStatus != 'cancelled' && 
                    lowerStatus != 'canceled') {
                  if (isFullyBilled) {
                    displayStatus = 'Closed';
                  } else {
                    displayStatus = 'Issued';
                  }
                }

                Widget detailContent = Column(
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
                                'Warehouse: ${order.warehouseName ?? '-'}',
                                style: AppTheme.metaHelper.copyWith(
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              CompositedTransformTarget(
                                link: _attachmentBadgeLink,
                                child: InkWell(
                                  onTap: () =>
                                      _toggleAttachmentListOverlay(order),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    height: 34,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.paperclip,
                                          size: 15,
                                          color: AppTheme.textSecondary,
                                        ),
                                        if (summary.attachments.isNotEmpty) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            '${summary.attachments.length}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _ActionSquare(
                                icon: LucideIcons.history,
                                color: AppTheme.textSecondary,
                                onTap: () {
                                  setInnerState(() {
                                    _showCommentsSidebar =
                                        !_showCommentsSidebar;
                                  });
                                  setState(() {});
                                },
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildStatusBadge(displayStatus),
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
                          if (displayStatus.toLowerCase() == 'draft') ...[
                            _buildToolbarButton(
                              LucideIcons.pencil,
                              'Edit',
                              onPressed: () => _editPurchaseOrder(order),
                            ),
                            _buildDivider(),
                          ],
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
                          if (order.status.toLowerCase() == 'closed' ||
                              displayStatus.toLowerCase() == 'closed' ||
                              summary.receives.isNotEmpty)
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
                            menuChildren: _menuChildrenForStatus(order, summary),
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
                                          children: const [
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

                                            ref.read(apiClientProvider).clearCache('purchase-orders');
                                            ref.invalidate(
                                              purchaseOrdersProvider(
                                                PurchaseOrderFilter(limit: 500),
                                              ),
                                            );
                                            ref.invalidate(
                                              purchaseOrderProvider(order.id!),
                                            );
                                            setState(() {
                                              _currentPoTxnSummaryOrderId = null;
                                              _currentPoTxnStatus = null;
                                              _currentPoTxnUpdatedAt = null;
                                            });

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
                            if ((order.status.toLowerCase() == 'issued' ||
                                    displayStatus.toLowerCase() == 'issued') &&
                                summary.receives.isEmpty) ...[
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
                                              text:
                                                  (order.status.toLowerCase() ==
                                                          'issued' &&
                                                      summary.receiveStatus
                                                              .toLowerCase() ==
                                                          'in transit' &&
                                                      summary.billStatus
                                                              .toLowerCase() ==
                                                          'yet to be billed')
                                                  ? 'Convert this to a bill to complete your purchase.'
                                                  : 'Record a receive or create a bill for this purchase order.',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (!(order.status.toLowerCase() ==
                                            'issued' &&
                                        summary.receiveStatus.toLowerCase() ==
                                            'in transit' &&
                                        summary.billStatus.toLowerCase() ==
                                            'yet to be billed') && !_isAllItemsReceived(order, summary))
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
                                      child:
                                          (order.status.toLowerCase() ==
                                                  'issued' &&
                                              summary.receiveStatus
                                                      .toLowerCase() ==
                                                  'in transit' &&
                                              summary.billStatus
                                                      .toLowerCase() ==
                                                  'yet to be billed')
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
                            if (order.status.toLowerCase() == 'closed' ||
                                displayStatus.toLowerCase() == 'closed' ||
                                summary.receives.isNotEmpty) ...[
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
                            if (summary.receives.isNotEmpty ||
                                summary.bills.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              ZExpandableTabs(
                                showBorder: true,
                                contentPadding: EdgeInsets.zero,
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
                                    _poReceivesBanner(summary, order),
                                ],
                              ),
                              const SizedBox(height: 12),
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
                                        : summary.billStatus == 'Partially Billed'
                                            ? AppTheme.warningOrange
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
                      ),
                    ),
                  ],
                );

                if (_showCommentsSidebar) {
                  return Row(
                    children: [
                      Expanded(child: detailContent),
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: AppTheme.borderLight,
                      ),
                      _buildCommentsSidebar(order, summary),
                    ],
                  );
                } else {
                  return detailContent;
                }
              },
            );
          },
        );
      },
    );
  }

  void _toggleAttachmentListOverlay(PurchaseOrder order) {
    if (_attachmentListOverlay != null) {
      _attachmentListOverlay?.remove();
      _attachmentListOverlay = null;
      setState(() {});
      return;
    }

    _attachmentListOverlay = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _attachmentListOverlay?.remove();
                _attachmentListOverlay = null;
                setState(() {});
              },
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _attachmentBadgeLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(-8, 4),
            child: Material(
              color: Colors.transparent,
              child: _AttachmentOverlayContent(
                order: order,
                ref: ref,
                onRefresh: () => _refreshPoTxnSummary(order),
                onClose: () {
                  _attachmentListOverlay?.remove();
                  _attachmentListOverlay = null;
                  setState(() {});
                },
              ),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_attachmentListOverlay!);
    setState(() {});
  }

  Widget _buildCommentsSidebar(PurchaseOrder order, _PoTxnSummary summary) {
    final List<_HistoryEvent> events = [];
    final user = ref.read(authUserProvider);
    final currentUsername = user?.fullName ?? user?.email.split('@').first ?? 'system';

    events.add(
      _HistoryEvent(
        username: currentUsername,
        time: order.createdAt ?? order.orderDate,
        content:
            'Purchase Order created for ₹${order.total.toStringAsFixed(2)}',
        icon: LucideIcons.fileSpreadsheet,
      ),
    );

    if (order.updatedAt != null &&
        order.createdAt != null &&
        order.updatedAt!.difference(order.createdAt!).inSeconds.abs() > 1) {
      events.add(
        _HistoryEvent(
          username: currentUsername,
          time: order.updatedAt!,
          content: 'Purchase Order edited',
          icon: LucideIcons.edit3,
        ),
      );
    }

    for (final a in summary.attachments) {
      final uploadedAtStr = a['uploaded_at']?.toString();
      final dt = uploadedAtStr != null
          ? DateTime.tryParse(uploadedAtStr)
          : null;
      events.add(
        _HistoryEvent(
          username: currentUsername,
          time: dt ?? order.createdAt ?? order.orderDate,
          content: 'Attachment modified',
          icon: LucideIcons.fileText,
        ),
      );
    }

    for (final r in summary.receives) {
      final createdAtStr =
          r['created_at']?.toString() ?? r['received_date']?.toString();
      final dt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
      events.add(
        _HistoryEvent(
          username: currentUsername,
          time: dt ?? order.createdAt ?? order.orderDate,
          content:
              'Purchase Receive ${r['purchase_receive_number'] ?? ''} created.',
          icon: LucideIcons.truck,
        ),
      );
    }

    for (final b in summary.bills) {
      final createdAtStr =
          b['created_at']?.toString() ?? b['bill_date']?.toString();
      final dt = createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
      events.add(
        _HistoryEvent(
          username: currentUsername,
          time: dt ?? order.createdAt ?? order.orderDate,
          content:
              'Bill ${b['bill_number'] ?? ''} created for ₹${(double.tryParse(b['total']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(2)}',
          icon: LucideIcons.receipt,
        ),
      );
    }

    // Sort events by time DESCENDING (newest first)
    events.sort((a, b) => b.time.compareTo(a.time));

    return Container(
      width: 320,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Text(
                  'History',
                  style: AppTheme.sectionHeader.copyWith(fontSize: 16),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showCommentsSidebar = false;
                    });
                  },
                  child: const Icon(
                    LucideIcons.x,
                    color: AppTheme.errorRed,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  'ALL COMMENTS',
                  style: AppTheme.metaHelper.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${events.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final e = events[index];
                final isLast = index == events.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Icon(
                              e.icon,
                              size: 12,
                              color: AppTheme.warningOrange,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 1.5,
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    e.username,
                                    style: AppTheme.bodyText.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.circle,
                                    size: 3,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    DateFormat(
                                      'dd-MM-yyyy hh:mm a',
                                    ).format(e.time),
                                    style: AppTheme.metaHelper.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  e.content,
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _editPurchaseOrder(PurchaseOrder order) {
    context.push('/purchases/purchase-orders/${order.id}/edit', extra: order);
  }

  Widget _buildToolbarButton(
    IconData icon,
    String label, {
    required VoidCallback onPressed,
    bool hasDropdownArrow = false,
  }) {
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
                  Icon(icon, size: 14, color: AppTheme.textPrimary),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasDropdownArrow) ...[
                    const SizedBox(width: 4),
                    const Icon(LucideIcons.chevronDown, size: 12, color: AppTheme.textPrimary),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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

  bool _isAllItemsReceived(PurchaseOrder order, _PoTxnSummary summary) {
    if (order.items.isEmpty) return false;
    for (final poItem in order.items) {
      if (poItem.isHeader) continue;
      double totalReceivedForProduct = 0.0;
      for (final r in summary.receives) {
        final rStatus = (r['status']?.toString() ?? '')
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('_', '');
        if (rStatus != 'received') continue;
        final itemsList =
            r['purchases_purchase_receive_items'] as List<dynamic>? ??
            r['purchase_receive_items'] as List<dynamic>? ??
            [];
        for (final item in itemsList) {
          final recProdId =
              (item['item_id'] ?? item['product_id'])?.toString();
          if (recProdId == poItem.productId) {
            final batches = item['purchase_receive_item_batches'] as List<dynamic>? ??
                item['purchases_purchase_receive_item_batches'] as List<dynamic>? ??
                [];
            if (batches.isNotEmpty) {
              for (final b in batches) {
                totalReceivedForProduct += double.tryParse(b['quantity']?.toString() ?? '0.0') ?? 0.0;
              }
            } else {
              totalReceivedForProduct +=
                  double.tryParse(item['quantity_to_receive']?.toString() ?? item['received']?.toString() ?? '0.0') ?? 0.0;
            }
          }
        }
      }
      if (totalReceivedForProduct < (poItem.quantity - poItem.cancelledQuantity) - 0.0001) {
        return false;
      }
    }
    return true;
  }

  List<Widget> _menuChildrenForStatus(PurchaseOrder order, _PoTxnSummary summary) {
    final isFullyReceived = _isAllItemsReceived(order, summary);
    if (isFullyReceived) {
      return [
        _detailActionMenuItem('Reopen canceled items', order, summary),
        _detailActionMenuItem('Clone', order, summary),
        _detailActionMenuItem('Delete', order, summary),
      ];
    }

    if (summary.receives.isNotEmpty) {
      final isTransitYetBilled = (summary.receiveStatus.toLowerCase() == 'in transit' ||
              summary.receiveStatus.toLowerCase() == 'partially received') &&
          summary.billStatus.toLowerCase() == 'yet to be billed';
      if (!isTransitYetBilled) {
        return [
          _detailActionMenuItem('Cancel Items', order, summary),
          _detailActionMenuItem('Clone', order, summary),
          _detailActionMenuItem('Delete', order, summary),
        ];
      }
    }

    final status = order.status.toLowerCase();
    if (status == 'draft') {
      return [
        _detailActionMenuItem('Mark as Issued', order, summary),
        _detailActionMenuItem('Convert to Bill', order, summary),
        _detailActionMenuItem('Create Receive', order, summary),
        _detailActionMenuItem('Clone', order, summary),
        _detailActionMenuItem('Delete', order, summary),
        _detailActionMenuItem('Mark as Received', order, summary),
      ];
    } else if (status == 'closed') {
      return [
        _detailActionMenuItem('Reopen canceled items', order, summary),
        _detailActionMenuItem('Clone', order, summary),
        _detailActionMenuItem('Delete', order, summary),
      ];
    } else if (status == 'issued') {
      return [
        _detailActionMenuItem('Expected Delivery Date', order, summary),
        _detailActionMenuItem('Cancel Items', order, summary),
        _detailActionMenuItem('Mark as Canceled', order, summary),
        _detailActionMenuItem('Clone', order, summary),
        _detailActionMenuItem('Delete', order, summary),
        _detailActionMenuItem('Mark as Received', order, summary),
      ];
    } else {
      return [
        _detailActionMenuItem('Expected Delivery Date', order, summary),
        _detailActionMenuItem('Cancel Items', order, summary),
        _detailActionMenuItem('Mark as Canceled', order, summary),
        _detailActionMenuItem('Clone', order, summary),
        _detailActionMenuItem('Delete', order, summary),
        _detailActionMenuItem('Mark as Received', order, summary),
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
          '₹${(double.tryParse(b['total']?.toString() ?? '0.0') ?? 0.0).toStringAsFixed(2)}',
        ];
      }).toList(),
    );
  }

  Widget _poReceivesBanner(_PoTxnSummary summary, PurchaseOrder order) {
    return _bannerTable(
      headers: const ['Purchase Receive#', 'received on', 'Status', 'Bill#', ''],
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.0),
        2: FlexColumnWidth(0.8),
        3: FlexColumnWidth(1.0),
        4: FlexColumnWidth(1.2),
      },
      rows: summary.receives.map((r) {
        final statusText = (r['status']?.toString() ?? '-')
            .split(' ')
            .map(
              (w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}',
            )
            .join(' ');

        return [
          InkWell(
            onTap: () {
              final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
              context.go('/$orgId/purchases/purchase-receives?id=${r['id']}');
            },
            child: Text(
              r['purchase_receive_number']?.toString() ?? '-',
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            _formatDateString(r['received_date']),
            style: AppTheme.bodyText.copyWith(fontSize: 13),
          ),
          Text(
            statusText,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: statusText == 'Received'
                  ? AppTheme.successGreen
                  : (statusText == 'In Transit' || statusText.toLowerCase() == 'intransit'
                      ? AppTheme.warningOrange
                      : AppTheme.textSecondary),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            r['bill_no']?.toString() ?? '',
            style: AppTheme.bodyText.copyWith(fontSize: 13),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
                  context.go('/$orgId/purchases/bills/create?poId=${order.id}');
                },
                child: Text(
                  'Convert to Bill',
                  style: AppTheme.bodyText.copyWith(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '|',
                style: TextStyle(
                  color: AppTheme.borderLight,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final confirm = await showZerpaiConfirmationDialog(
                    context,
                    title: 'Delete Purchase Receive',
                    message: 'Are you sure you want to delete this purchase receive?',
                  );
                  if (confirm == true) {
                    final success = await ref
                        .read(purchaseReceivesProvider.notifier)
                        .deleteReceive(r['id']?.toString() ?? '');
                    if (success) {
                      ref.read(apiClientProvider).clearCache('purchase-orders');
                      ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
                      ref.invalidate(purchaseOrderProvider(order.id!));
                      setState(() {
                        _currentPoTxnSummaryOrderId = null;
                        _currentPoTxnStatus = null;
                        _currentPoTxnUpdatedAt = null;
                      });
                      ZerpaiToast.success(context, 'Purchase receive deleted successfully');
                    } else {
                      ZerpaiToast.error(context, 'Failed to delete purchase receive');
                    }
                  }
                },
                child: const Icon(
                  LucideIcons.trash2,
                  size: 14,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
        ];
      }).toList(),
    );
  }

  Widget _bannerTable({
    required List<String> headers,
    required List<List<dynamic>> rows,
    Map<int, TableColumnWidth>? columnWidths,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Table(
        columnWidths: columnWidths ?? {
          for (int i = 0; i < headers.length; i++) i: const FlexColumnWidth(),
        },
        children: [
          TableRow(
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FA),
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight, width: 0.8),
              ),
            ),
            children: headers
                .map(
                  (h) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                      child: c is Widget
                          ? c
                          : Text(
                              c.toString(),
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

  MenuItemButton _detailActionMenuItem(String label, PurchaseOrder order, _PoTxnSummary summary) {
    return MenuItemButton(
      onPressed: () async {
        if (label == 'Expected Delivery Date') {
          showDialog(
            context: context,
            builder: (context) => _ExpectedDeliveryDateDialog(
              initialDate: order.expectedDeliveryDate ?? DateTime.now(),
              initialNotes: order.notes,
              onSave: (result) async {
                final pickedDate = result['date'] as DateTime;
                final notes = result['notes'] as String;
                try {
                  final supabase = Supabase.instance.client;
                  await supabase
                      .from('purchase_orders')
                      .update({
                        'delivery_date': pickedDate.toIso8601String(),
                        'notes': notes,
                      })
                      .eq('id', order.id!);

                  ref.read(apiClientProvider).clearCache('purchase-orders');
                  ref.invalidate(
                    purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
                  );
                  ref.invalidate(purchaseOrderProvider(order.id!));
                  setState(() {
                    _currentPoTxnSummaryOrderId = null;
                    _currentPoTxnStatus = null;
                    _currentPoTxnUpdatedAt = null;
                  });

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
              },
            ),
          );
        } else if (label == 'Mark as Issued') {
          try {
            final supabase = Supabase.instance.client;
            await supabase
                .from('purchase_orders')
                .update({'status': 'Issued'})
                .eq('id', order.id!);

            ref.read(apiClientProvider).clearCache('purchase-orders');
            ref.invalidate(
              purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
            );
            ref.invalidate(purchaseOrderProvider(order.id!));
            setState(() {
              _currentPoTxnSummaryOrderId = null;
              _currentPoTxnStatus = null;
              _currentPoTxnUpdatedAt = null;
            });

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

            ref.read(apiClientProvider).clearCache('purchase-orders');
            ref.invalidate(
              purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
            );
            ref.invalidate(purchaseOrderProvider(order.id!));
            setState(() {
              _currentPoTxnSummaryOrderId = null;
              _currentPoTxnStatus = null;
              _currentPoTxnUpdatedAt = null;
            });

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
          bool hasCancellableItems = false;
          for (final item in order.items) {
            if (item.isHeader) continue;
            double recQty = 0.0;
            for (final r in summary.receives) {
              final itemsList = r['purchases_purchase_receive_items'] as List<dynamic>? ??
                  r['purchase_receive_items'] as List<dynamic>? ??
                  [];
              for (final recItem in itemsList) {
                final recProdId = (recItem['item_id'] ?? recItem['product_id'])?.toString();
                if (recProdId == item.productId) {
                  final batches = recItem['purchase_receive_item_batches'] as List<dynamic>? ??
                      recItem['purchases_purchase_receive_item_batches'] as List<dynamic>? ??
                      [];
                  if (batches.isNotEmpty) {
                    for (final b in batches) {
                      recQty += double.tryParse(b['quantity']?.toString() ?? '0.0') ?? 0.0;
                    }
                  } else {
                    recQty += double.tryParse(recItem['quantity_to_receive']?.toString() ?? recItem['received']?.toString() ?? '0.0') ?? 0.0;
                  }
                }
              }
            }
            final remaining = item.quantity - recQty - item.cancelledQuantity;
            if (remaining > 0) {
              hasCancellableItems = true;
              break;
            }
          }

          if (!hasCancellableItems) {
            ZerpaiToast.error(
              context,
              'There are no Item(s) available to be cancelled in this Purchase Order.',
            );
            return;
          }

          showDialog(
            context: context,
            builder: (context) => _CancelItemsDialog(
              order: order,
              summary: summary,
              onProceed: () {
                ref.read(apiClientProvider).clearCache('purchase-orders');
                ref.invalidate(
                  purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
                );
                ref.invalidate(purchaseOrderProvider(order.id!));
                setState(() {
                  _currentPoTxnSummaryOrderId = null;
                  _currentPoTxnStatus = null;
                  _currentPoTxnUpdatedAt = null;
                });

                if (context.mounted) {
                  ZerpaiToast.success(context, 'Purchase order items cancelled');
                }
              },
            ),
          );
        } else if (label == 'Mark as Canceled') {
          try {
            final supabase = Supabase.instance.client;
            await supabase
                .from('purchase_orders')
                .update({'status': 'Cancelled'})
                .eq('id', order.id!);

            ref.read(apiClientProvider).clearCache('purchase-orders');
            ref.invalidate(
              purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
            );
            ref.invalidate(purchaseOrderProvider(order.id!));
            setState(() {
              _currentPoTxnSummaryOrderId = null;
              _currentPoTxnStatus = null;
              _currentPoTxnUpdatedAt = null;
            });

            if (context.mounted) {
              ZerpaiToast.success(context, 'Purchase order marked as Canceled');
            }
          } catch (e) {
            if (context.mounted) {
              ZerpaiToast.error(context, 'Failed to cancel: $e');
            }
          }
        } else if (label == 'Clone') {
          context.push(
            '/purchases/purchase-orders/create?clone=true&clone_from_id=${order.id}',
            extra: order,
          );
        } else if (label == 'Delete') {
          try {
            final supabase = Supabase.instance.client;
            final originalNumber = order.orderNumber;
            final newNumber = originalNumber.startsWith('SD-') ? originalNumber : 'SD-$originalNumber';
            await supabase
                .from('purchase_orders')
                .update({
                  'is_delete': true,
                  'order_number': newNumber,
                })
                .eq('id', order.id!);

            ref.read(apiClientProvider).clearCache('purchase-orders');
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
          final hasTrackedItems = order.items.any((item) {
            if (item.isHeader) return false;
            return item.trackBatches || item.trackSerialNumber || item.trackBinLocation;
          });

          if (hasTrackedItems) {
            ZerpaiToast.error(
              context,
              'You cannot mark this purchase order as received because it contains items tracked by serial number, batch number, or bins. You can create a receive for these items instead.',
            );
            return;
          }

          try {
            final repo = ref.read(purchaseReceiveRepositoryProvider);
            final nextNumberData = await repo.getNextPurchaseReceiveNumber();
            final nextReceiveNumber = nextNumberData['formatted'] ?? '';

            final receive = PurchaseReceive(
              purchaseReceiveNumber: nextReceiveNumber,
              receivedDate: DateTime.now(),
              vendorId: order.vendorId,
              vendorName: order.vendorName,
              purchaseOrderId: order.id,
              purchaseOrderNumber: order.orderNumber,
              warehouseId: order.warehouseId ?? order.deliveryWarehouseId,
              status: 'received',
              notes: 'Automatically created via PO Mark as Received',
              items: order.items.where((item) => !item.isHeader).map((item) {
                return PurchaseReceiveItem(
                  itemId: item.productId,
                  itemName: item.productName ?? '',
                  description: item.description,
                  ordered: item.quantity,
                  received: 0,
                  inTransit: 0,
                  cancelled: item.cancelledQuantity,
                  quantityToReceive: item.quantity - item.cancelledQuantity,
                  batches: [],
                  purchaseOrderId: order.id,
                  purchaseOrderNumber: order.orderNumber,
                );
              }).toList(),
            );

            await repo.createPurchaseReceive(receive);

            final supabase = Supabase.instance.client;
            await supabase
                .from('purchase_orders')
                .update({'status': 'Closed'})
                .eq('id', order.id!);

            ref.read(apiClientProvider).clearCache('purchase-orders');
            ref.invalidate(
              purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)),
            );
            ref.invalidate(purchaseOrderProvider(order.id!));
            ref.read(purchaseReceivesProvider.notifier).fetchReceives();
            setState(() {
              _currentPoTxnSummaryOrderId = null;
              _currentPoTxnStatus = null;
              _currentPoTxnUpdatedAt = null;
            });

            if (context.mounted) {
              ZerpaiToast.success(context, 'Purchase order marked as Received & Receive created successfully');
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
      style: ZTableMoreMenu.menuItemButtonStyle(),
      child: Text(label),
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
          style: ZTableMoreMenu.menuItemButtonStyle(),
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
          style: ZTableMoreMenu.menuItemButtonStyle(),
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
                          order.paymentTermsName ?? order.paymentTerms ?? '',
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
                          order.warehouseName ?? '-',
                          'PERINTHALMANNA\nMALAPPURAM, Kerala\nIndia - 679322', // Placeholder or from warehouse model
                          '8086355500', // Placeholder
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _itemsTable(order.items, summary, order.warehouseName, order.vendorName),
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
        Container(width: 3, height: 100, color: _getStatusColor(order.status)),
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
              color: _getStatusColor(order.status),
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
                    : summary.billStatus == 'Partially Billed'
                        ? AppTheme.warningOrange
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: AppTheme.metaHelper.copyWith(fontSize: 12, letterSpacing: 0.3),
        ),
        Text(
          value,
          style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _itemsTable(
    List<PurchaseOrderItem> items,
    _PoTxnSummary summary,
    String? warehouseName,
    String? vendorName,
  ) {
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
                  flex: 5,
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
                  flex: 2,
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
                  flex: 3,
                  child: Text(
                    'WAREHOUSE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const Expanded(
                  flex: 3,
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
                  flex: 1,
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
                  flex: 2,
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
            double itemFocQty = 0.0;
            for (final r in summary.receives) {
              final itemsList =
                  r['purchases_purchase_receive_items'] as List<dynamic>? ??
                  r['purchase_receive_items'] as List<dynamic>? ??
                  [];
              for (final recItem in itemsList) {
                final recProdId = (recItem['item_id'] ?? recItem['product_id'])
                    ?.toString();
                if (recProdId == item.productId) {
                  final batches = recItem['purchase_receive_item_batches'] as List<dynamic>? ??
                      recItem['purchases_purchase_receive_item_batches'] as List<dynamic>? ??
                      [];
                  if (batches.isNotEmpty) {
                    for (final b in batches) {
                      itemReceivedQty += double.tryParse(b['quantity']?.toString() ?? '0.0') ?? 0.0;
                      itemFocQty += double.tryParse(b['foc_qty']?.toString() ?? '0.0') ?? 0.0;
                    }
                  } else {
                    itemReceivedQty +=
                        double.tryParse(recItem['quantity_to_receive']?.toString() ?? recItem['received']?.toString() ?? '0.0') ?? 0.0;
                  }
                }
              }
            }
            final poReceiveItemIds = <String>{};
            for (final r in summary.receives) {
              final itemsList =
                  r['purchases_purchase_receive_items'] as List<dynamic>? ??
                  r['purchase_receive_items'] as List<dynamic>? ??
                  [];
              for (final recItem in itemsList) {
                final itemId = recItem['id']?.toString();
                if (itemId != null) {
                  poReceiveItemIds.add(itemId);
                }
              }
            }

            double itemBilledQty = 0.0;
            for (final b in summary.bills) {
              final orderNumStr = (b['order_number'] ?? '').toString();
              final isMultiPo = orderNumStr.contains(',');
              final itemsList = b['bill_items'] as List<dynamic>? ?? [];
              for (final billItem in itemsList) {
                final billProdId = (billItem['product_id'] ?? billItem['item_id'])
                    ?.toString();
                if (billProdId == item.productId) {
                  final prItemId = billItem['purchase_receive_item_id']?.toString();
                  if (prItemId != null) {
                    if (poReceiveItemIds.contains(prItemId)) {
                      itemBilledQty +=
                          double.tryParse(billItem['quantity']?.toString() ?? '0.0') ?? 0.0;
                    }
                  } else if (!isMultiPo) {
                    itemBilledQty +=
                        double.tryParse(billItem['quantity']?.toString() ?? '0.0') ?? 0.0;
                  }
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
                    flex: 5,
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
                              InkWell(
                                onTap: item.productId.isEmpty
                                    ? null
                                    : () => _showItemDetailsSidebar(
                                          item,
                                          vendorName: vendorName,
                                        ),
                                child: Text(
                                  item.productName ?? 'Unnamed Item',
                                  style: AppTheme.linkText.copyWith(fontSize: 13),
                                ),
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
                    flex: 2,
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
                    flex: 3,
                    child: Text(
                      warehouseName ?? '-',
                      style: AppTheme.bodyText.copyWith(fontSize: 11),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemFocQty > 0
                              ? '${itemReceivedQty.toInt()} pcs + ${itemFocQty.toInt()} foc Received'
                              : '${itemReceivedQty.toInt()} Received',
                          style: AppTheme.bodyText.copyWith(fontSize: 11),
                          textAlign: TextAlign.left,
                        ),
                        Text(
                          '${itemBilledQty.toInt()} Billed',
                          style: AppTheme.bodyText.copyWith(fontSize: 11),
                          textAlign: TextAlign.left,
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
                            textAlign: TextAlign.left,
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      '₹${item.rate.toStringAsFixed(2)}',
                      style: AppTheme.bodyText.copyWith(fontSize: 13),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Expanded(
                    flex: 2,
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
        row(
          'Total Quantity : ${order.items.where((item) => !item.isHeader).fold<double>(0.0, (sum, item) => sum + item.quantity).toInt()}',
          '',
        ),
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
              ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
            },
          ),
        ],
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
                          order.warehouseName ?? '-',
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
                        flex: 1,
                        child: Container(
                          height: 1,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(flex: 3),
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
        final orgName = orgSettings?.name ?? '';
        final user = ref.read(authUserProvider);
        final orgEmail = orgSettings?.email ?? user?.email ?? 'info@zerpai.com';
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
      onCancel: () async {
        try {
          final supabase = Supabase.instance.client;
          await supabase
              .from('purchase_orders')
              .update({'status': 'Draft'})
              .eq('id', order.id!);

          ref.read(apiClientProvider).clearCache('purchase-orders');
          ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
          ref.invalidate(purchaseOrderProvider(order.id!));
        } catch (e) {
          AppLogger.error(
            'Failed to revert PO to Draft status on cancel',
            error: e,
            module: 'purchases',
          );
        }
        if (context.mounted) {
          context.go('/purchases/purchase-orders/${order.id}');
        }
      },
      onSend: (from, to, subject, body, attachPdf) async {
        try {
          final supabase = Supabase.instance.client;
          await supabase
              .from('purchase_orders')
              .update({'status': 'Issued'})
              .eq('id', order.id!);

          ref.read(apiClientProvider).clearCache('purchase-orders');
          ref.invalidate(purchaseOrdersProvider(PurchaseOrderFilter(limit: 500)));
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

class _HistoryEvent {
  final String username;
  final DateTime time;
  final String content;
  final IconData icon;

  const _HistoryEvent({
    required this.username,
    required this.time,
    required this.content,
    required this.icon,
  });
}

class _AttachmentOverlayContent extends StatefulWidget {
  final PurchaseOrder order;
  final WidgetRef ref;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  const _AttachmentOverlayContent({
    required this.order,
    required this.ref,
    required this.onRefresh,
    required this.onClose,
  });

  @override
  State<_AttachmentOverlayContent> createState() =>
      _AttachmentOverlayContentState();
}

class _AttachmentOverlayContentState extends State<_AttachmentOverlayContent> {
  bool _isUploading = false;
  List<Map<String, dynamic>> _attachments = [];
  bool _isLoading = true;
  bool _displayInPortal = false;
  String? _expandedAttachmentId;

  @override
  void initState() {
    super.initState();
    _loadAttachments();
  }

  Future<void> _loadAttachments() async {
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('purchase_order_attachments')
          .select('id,file_name,file_path,file_size,file_type,uploaded_at')
          .eq('purchase_order_id', widget.order.id ?? '')
          .order('uploaded_at', ascending: false);
      if (mounted) {
        setState(() {
          _attachments = (res as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatFileSize(dynamic size) {
    if (size == null) return 'File Size: 0 KB';
    if (size is num) {
      if (size / 1024 > 1024) {
        return 'File Size: ${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else {
        return 'File Size: ${(size / 1024).toStringAsFixed(1)} KB';
      }
    }
    final sizeStr = size.toString().trim();
    if (sizeStr.toLowerCase().contains('kb') ||
        sizeStr.toLowerCase().contains('mb') ||
        sizeStr.toLowerCase().contains('b')) {
      return 'File Size: $sizeStr';
    }
    final parsed = num.tryParse(sizeStr);
    if (parsed != null) {
      if (parsed / 1024 > 1024) {
        return 'File Size: ${(parsed / (1024 * 1024)).toStringAsFixed(1)} MB';
      } else {
        return 'File Size: ${(parsed / 1024).toStringAsFixed(1)} KB';
      }
    }
    return 'File Size: $sizeStr';
  }

  Future<String?> _getSignedUrl(String fileKey) async {
    try {
      final apiClient = ApiClient();
      final response = await apiClient.get(
        '/lookups/uploads/signed-url',
        queryParameters: {'fileKey': fileKey},
        useCache: false,
      );
      if (response.data is Map && response.data['signedUrl'] != null) {
        return response.data['signedUrl'].toString();
      }
    } catch (e) {
      debugPrint('Error getting signed URL: $e');
    }
    return null;
  }

  Future<void> _downloadAttachment(Map<String, dynamic> attachment) async {
    try {
      final filePath = attachment['file_path']?.toString();
      final fileName = attachment['file_name']?.toString() ?? 'download';
      if (filePath == null) return;

      final signedUrl = await _getSignedUrl(filePath);
      if (signedUrl != null) {
        final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
        anchor.href = signedUrl;
        anchor.download = fileName;
        anchor.click();
      } else {
        if (mounted) {
          ZerpaiToast.error(context, 'Failed to get download link');
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error downloading file: $e');
      }
    }
  }

  Future<void> _openAttachmentInNewTab(Map<String, dynamic> attachment) async {
    try {
      final filePath = attachment['file_path']?.toString();
      final fileType = attachment['file_type']?.toString() ?? '';
      if (filePath == null) return;

      String? mimeType;
      final ext = fileType.toLowerCase().replaceAll('.', '');
      if (ext == 'pdf') {
        mimeType = 'application/pdf';
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mimeType = 'image/jpeg';
      } else if (ext == 'png') {
        mimeType = 'image/png';
      } else if (ext == 'gif') {
        mimeType = 'image/gif';
      } else if (ext == 'webp') {
        mimeType = 'image/webp';
      } else if (ext == 'txt') {
        mimeType = 'text/plain';
      }

      final apiClient = ApiClient();
      final response = await apiClient.get(
        '/lookups/uploads/signed-url',
        queryParameters: {
          'fileKey': filePath,
          if (mimeType != null) 'mimeType': mimeType,
        },
        useCache: false,
      );

      if (response.data is Map && response.data['signedUrl'] != null) {
        web.window.open(response.data['signedUrl'].toString(), '_blank');
      } else {
        if (mounted) {
          ZerpaiToast.error(context, 'Failed to get file link');
        }
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Error opening file: $e');
      }
    }
  }

  Future<void> _uploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );
      if (result == null || !mounted) return;

      setState(() {
        _isUploading = true;
      });

      final supabase = Supabase.instance.client;
      final apiClient = ApiClient();
      for (final file in result.files) {
        if (file.bytes == null) continue;

        final base64Data = base64Encode(file.bytes!);
        final ext = file.extension?.toLowerCase() ?? '';
        String mimeType = 'application/octet-stream';
        if (ext == 'pdf') {
          mimeType = 'application/pdf';
        } else if (ext == 'jpg' || ext == 'jpeg') {
          mimeType = 'image/jpeg';
        } else if (ext == 'png') {
          mimeType = 'image/png';
        } else if (ext == 'gif') {
          mimeType = 'image/gif';
        } else if (ext == 'webp') {
          mimeType = 'image/webp';
        } else if (ext == 'txt') {
          mimeType = 'text/plain';
        }

        // Upload to Cloudflare R2 via backend
        final response = await apiClient.post(
          '/lookups/uploads',
          data: {
            'fileName': file.name,
            'fileData': base64Data,
            'mimeType': mimeType,
            'prefix': 'purchase_orders',
          },
        );

        final fileKey =
            response.data['fileKey'] ?? 'purchase_orders/${file.name}';

        final double sizeInKb = file.size / 1024;
        final String formattedSize = sizeInKb >= 1024
            ? '${(sizeInKb / 1024).toStringAsFixed(2)} MB'
            : '${sizeInKb.toStringAsFixed(2)} KB';

        // Save to DB
        await supabase.from('purchase_order_attachments').insert({
          'purchase_order_id': widget.order.id,
          'file_name': file.name,
          'file_path': fileKey,
          'file_size': formattedSize,
          'file_type': file.extension ?? 'bin',
          'entity_id':
              widget.ref.read(entityProvider).entityId ??
              '00000000-0000-0000-0000-000000000000',
        });
      }

      await _loadAttachments();
      widget.ref.invalidate(purchaseOrderProvider(widget.order.id!));
      widget.onRefresh();
      if (mounted) {
        ZerpaiToast.success(context, 'Attachments uploaded successfully');
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to upload attachments: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteAttachment(Map<String, dynamic> attachment) async {
    try {
      final supabase = Supabase.instance.client;
      final id = attachment['id'];
      final filePath = attachment['file_path']?.toString();

      if (filePath != null) {
        final apiClient = ApiClient();
        await apiClient.delete(
          '/lookups/uploads',
          data: {'fileKey': filePath},
        );
      }

      await supabase.from('purchase_order_attachments').delete().eq('id', id);

      await _loadAttachments();
      widget.ref.invalidate(purchaseOrderProvider(widget.order.id!));
      widget.onRefresh();
      if (mounted) {
        ZerpaiToast.success(context, 'Attachment deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to delete attachment: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Attachments',
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_isUploading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(LucideIcons.x, color: Colors.red, size: 16),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_attachments.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No attachments yet',
                style: AppTheme.metaHelper,
                textAlign: TextAlign.center,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.all(12),
                itemCount: _attachments.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final att = _attachments[index];
                  final name = att['file_name']?.toString() ?? 'Unnamed';
                  final isPdf = name.toLowerCase().endsWith('.pdf');

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isPdf
                                ? const Color(0xFFFEE2E2)
                                : const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.fileText,
                              color: isPdf
                                  ? Colors.red.shade700
                                  : Colors.blue.shade700,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatFileSize(att['file_size']),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (_expandedAttachmentId == att['id']?.toString()) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    InkWell(
                                      onTap: () => _downloadAttachment(att),
                                      child: const Text(
                                        'Download',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    InkWell(
                                      onTap: () => _deleteAttachment(att),
                                      child: const Text(
                                        'Remove',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    ZTooltip(
                                      message: 'Open in new tab',
                                      direction: ZTooltipDirection.bottom,
                                      child: InkWell(
                                        onTap: () => _openAttachmentInNewTab(att),
                                        child: const Icon(
                                          LucideIcons.externalLink,
                                          size: 14,
                                          color: Color(0xFF3B82F6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 16,
                            color: Colors.red,
                          ),
                          onPressed: () => _deleteAttachment(att),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 16,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.moreVertical,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              final idStr = att['id']?.toString();
                              if (_expandedAttachmentId == idStr) {
                                _expandedAttachmentId = null;
                              } else {
                                _expandedAttachmentId = idStr;
                              }
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 16,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Display attachments in vendor portal\nand emails',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _displayInPortal,
                    onChanged: (val) {
                      setState(() {
                        _displayInPortal = val;
                      });
                    },
                    activeTrackColor: AppTheme.primaryBlue,
                    activeThumbColor: Colors.white,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.all(16),
            child: DottedBorder(
              color: const Color(0xFFD1D5DB),
              strokeWidth: 1,
              dashPattern: const [4, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(8),
              child: InkWell(
                onTap: _uploadFile,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.uploadCloud,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Upload your Files',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevronDown,
                        color: AppTheme.textSecondary,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'You can upload a maximum of 10 files, 10MB each',
              style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpectedDeliveryDateDialog extends StatefulWidget {
  final DateTime initialDate;
  final String? initialNotes;
  final ValueChanged<Map<String, dynamic>> onSave;

  const _ExpectedDeliveryDateDialog({
    required this.initialDate,
    this.initialNotes,
    required this.onSave,
  });

  @override
  State<_ExpectedDeliveryDateDialog> createState() =>
      _ExpectedDeliveryDateDialogState();
}

class _ExpectedDeliveryDateDialogState extends State<_ExpectedDeliveryDateDialog> {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _notesController = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayZero = DateTime(today.year, today.month, today.day);

    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday % 7;
    final prevMonthDays = DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    final List<_CalendarDay> gridDays = [];

    for (int i = firstDayWeekday - 1; i >= 0; i--) {
      final d = prevMonthDays - i;
      gridDays.add(_CalendarDay(
        date: DateTime(_currentMonth.year, _currentMonth.month - 1, d),
        isCurrentMonth: false,
      ));
    }

    for (int d = 1; d <= daysInMonth; d++) {
      gridDays.add(_CalendarDay(
        date: DateTime(_currentMonth.year, _currentMonth.month, d),
        isCurrentMonth: true,
      ));
    }

    final totalCells = ((gridDays.length / 7).ceil() * 7);
    final nextMonthPad = totalCells - gridDays.length;
    for (int d = 1; d <= nextMonthPad; d++) {
      gridDays.add(_CalendarDay(
        date: DateTime(_currentMonth.year, _currentMonth.month + 1, d),
        isCurrentMonth: false,
      ));
    }

    final monthName = DateFormat('MMMM yyyy').format(_currentMonth);

    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expected Delivery Date',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(LucideIcons.chevronsRight, size: 18, color: Color(0xFF6B7280)),
                  onPressed: () {
                    setState(() {
                      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                  .map((w) => Center(
                        child: Text(
                          w,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: gridDays.length,
              itemBuilder: (context, idx) {
                final day = gridDays[idx];
                final dayZero = DateTime(day.date.year, day.date.month, day.date.day);
                final isSelected = dayZero == DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
                final isDisabled = !day.isCurrentMonth || dayZero.isBefore(todayZero);

                return InkWell(
                  onTap: isDisabled
                      ? null
                      : () {
                          setState(() {
                            _selectedDate = day.date;
                          });
                        },
                  child: Center(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF22A95E) : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        day.date.day.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Colors.white
                              : (isDisabled
                                  ? const Color(0xFFD1D5DB)
                                  : const Color(0xFF1E293B)),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Notes*',
              style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.all(10),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF22A95E)),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    widget.onSave({
                      'date': _selectedDate,
                      'notes': _notesController.text,
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22A95E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

class _CalendarDay {
  final DateTime date;
  final bool isCurrentMonth;
  _CalendarDay({required this.date, required this.isCurrentMonth});
}

class _CancelItemsDialog extends StatefulWidget {
  final PurchaseOrder order;
  final _PoTxnSummary summary;
  final VoidCallback onProceed;

  const _CancelItemsDialog({
    required this.order,
    required this.summary,
    required this.onProceed,
  });

  @override
  State<_CancelItemsDialog> createState() => _CancelItemsDialogState();
}

class _CancelItemsDialogState extends State<_CancelItemsDialog> {
  final Map<String, TextEditingController> _controllers = {};
  final List<PurchaseOrderItem> _cancellableItems = [];
  final Map<String, double> _receivedQuantities = {};
  final Map<String, double> _billedQuantities = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final item in widget.order.items) {
      if (item.isHeader) continue;

      // Received
      double recQty = 0.0;
      for (final r in widget.summary.receives) {
        final itemsList = r['purchases_purchase_receive_items'] as List<dynamic>? ??
            r['purchase_receive_items'] as List<dynamic>? ??
            [];
        for (final recItem in itemsList) {
          final recProdId = (recItem['item_id'] ?? recItem['product_id'])?.toString();
          if (recProdId == item.productId) {
            final batches = recItem['purchase_receive_item_batches'] as List<dynamic>? ??
                recItem['purchases_purchase_receive_item_batches'] as List<dynamic>? ??
                [];
            if (batches.isNotEmpty) {
              for (final b in batches) {
                recQty += double.tryParse(b['quantity']?.toString() ?? '0.0') ?? 0.0;
              }
            } else {
              recQty += double.tryParse(recItem['received']?.toString() ?? recItem['quantity_to_receive']?.toString() ?? '0.0') ?? 0.0;
            }
          }
        }
      }
      _receivedQuantities[item.productId] = recQty;

      // Billed
      final poReceiveItemIds = <String>{};
      for (final r in widget.summary.receives) {
        final itemsList = r['purchases_purchase_receive_items'] as List<dynamic>? ??
            r['purchase_receive_items'] as List<dynamic>? ??
            [];
        for (final recItem in itemsList) {
          final itemId = recItem['id']?.toString();
          if (itemId != null) {
            poReceiveItemIds.add(itemId);
          }
        }
      }

      double billQty = 0.0;
      for (final b in widget.summary.bills) {
        final orderNumStr = (b['order_number'] ?? '').toString();
        final isMultiPo = orderNumStr.contains(',');
        
        final itemsList = b['bill_items'] as List<dynamic>? ?? [];
        for (final billItem in itemsList) {
          final billProdId = (billItem['product_id'] ?? billItem['item_id'])?.toString();
          if (billProdId == item.productId) {
            final prItemId = billItem['purchase_receive_item_id']?.toString();
            if (prItemId != null) {
              if (poReceiveItemIds.contains(prItemId)) {
                billQty += double.tryParse(billItem['quantity']?.toString() ?? '0.0') ?? 0.0;
              }
            } else if (!isMultiPo) {
              billQty += double.tryParse(billItem['quantity']?.toString() ?? '0.0') ?? 0.0;
            }
          }
        }
      }
      _billedQuantities[item.productId] = billQty;

      final remaining = item.quantity - recQty - item.cancelledQuantity;
      if (remaining > 0) {
        _cancellableItems.add(item);
        _controllers[item.productId] = TextEditingController(
          text: remaining.toInt().toString(),
        );
      }
    }
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

    for (final item in widget.order.items) {
      if (item.isHeader) continue;
      double currentQty = item.quantity;
      double cancelQty = 0.0;

      if (_controllers.containsKey(item.productId)) {
        cancelQty = double.tryParse(_controllers[item.productId]!.text) ?? 0.0;
      }

      final recQty = _receivedQuantities[item.productId] ?? 0.0;
      final maxCancel = currentQty - recQty - item.cancelledQuantity;

      if (cancelQty > maxCancel) {
        ZerpaiToast.error(
          context,
          'Cancellation quantity for ${item.productName ?? "item"} cannot exceed remaining quantity (${maxCancel.toInt()})',
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
            .from('purchase_order_items')
            .update({
              'cancelled_quantity': up['cancelled_quantity'],
            })
            .eq('id', up['id']);
      }

      double totalOriginalQuantity = 0.0;
      double totalCancelled = 0.0;
      double totalReceived = 0.0;

      for (final item in widget.order.items) {
        if (item.isHeader) continue;
        totalOriginalQuantity += item.quantity;
        
        double currentCancel = item.cancelledQuantity;
        if (_controllers.containsKey(item.productId)) {
          double cancelQty = double.tryParse(_controllers[item.productId]!.text) ?? 0.0;
          totalCancelled += currentCancel + cancelQty;
        } else {
          totalCancelled += currentCancel;
        }

        totalReceived += _receivedQuantities[item.productId] ?? 0.0;
      }

      String newStatus = widget.order.status;
      if (totalCancelled >= totalOriginalQuantity) {
        newStatus = 'Canceled';
      } else if (totalOriginalQuantity <= (totalReceived + totalCancelled)) {
        newStatus = 'Closed';
      }

      await supabase
          .from('purchase_orders')
          .update({
            'status': newStatus,
          })
          .eq('id', widget.order.id!);

      widget.onProceed();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to cancel items: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
        width: 850,
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
            if (_cancellableItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'All items in this purchase order have been fully received.',
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
                              'QUANTITY ORDERED',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'RECEIVED',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'BILLED',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'RECEIVED AND BILLED',
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
                      final recQty = _receivedQuantities[item.productId] ?? 0.0;
                      final billQty = _billedQuantities[item.productId] ?? 0.0;
                      final recAndBill = recQty < billQty ? recQty : billQty;

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
                                item.productName ?? 'Unnamed Item',
                                style: AppTheme.linkText.copyWith(fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                item.itemCode ?? '-',
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
                                recQty.toInt().toString(),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                billQty.toInt().toString(),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                recAndBill.toInt().toString(),
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
                                  controller: _controllers[item.productId],
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
                                  _controllers[item.productId]?.text = '0';
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
                  onPressed: _cancellableItems.isEmpty || _isSaving ? null : _proceed,
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
