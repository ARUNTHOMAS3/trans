import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_header_menu.dart';
import 'package:zerpai_erp/shared/widgets/tables/table_more_menu.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import '../../models/purchases_purchase_receives_model.dart';
import '../../providers/purchase_receives_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:dio/dio.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/app/providers/org_settings_provider.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/presentation/widgets/po_item_details_sidebar_widget.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/items/items/repositories/items_repository_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:web/web.dart' as web;
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/providers/lookup_providers.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';

class _ClearReceiveSelectionIntent extends Intent {
  const _ClearReceiveSelectionIntent();
}

const _receiveFilterOptions = <FavoriteFilterOption>[
  FavoriteFilterOption(label: 'All', value: 'all'),
  FavoriteFilterOption(label: 'In Transit', value: 'intransit'),
  FavoriteFilterOption(label: 'Received', value: 'received'),
  FavoriteFilterOption(label: 'Billed', value: 'billed'),
  FavoriteFilterOption(label: 'Partially Billed', value: 'partially_billed'),
];

Color _getStatusColor(String status) {
  final clean = status.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
  switch (clean) {
    case 'received':
      return const Color(0xFF22A95E); // Green
    case 'intransit':
      return const Color(0xFFFF8800); // Orange
    case 'draft':
      return Colors.grey;
    default:
      return const Color(0xFF6B7280);
  }
}

class PurchasesPurchaseReceivesListScreen extends ConsumerStatefulWidget {
  final String? initialFilter;
  final String? initialSelectedId;

  const PurchasesPurchaseReceivesListScreen({
    super.key,
    this.initialFilter,
    this.initialSelectedId,
  });

  @override
  ConsumerState<PurchasesPurchaseReceivesListScreen> createState() =>
      _PurchasesPurchaseReceivesListScreenState();
}

class _PurchasesPurchaseReceivesListScreenState
    extends ConsumerState<PurchasesPurchaseReceivesListScreen> {
  FavoriteFilterOption _activeOption = _receiveFilterOptions.first;
  final Set<String> _selectedIds = {};
  String? _activeReceiveId;

  List<ColumnConfig> _allColumns = [];
  final List<String> _visibleColumns = [];
  bool _shouldWrapText = false;
  Map<String, double>? _customColumnWidths;
  final ScrollController _horizontalScrollController = ScrollController();

  String _sortField = 'created_time';
  bool _sortAscending = false;

  final Map<String, String> _columnLabels = {
    'date': 'DATE',
    'pr#': 'PURCHASE RECEIVE#',
    'po#': 'PURCHASE ORDER#',
    'vendor': 'VENDOR NAME',
    'status': 'STATUS',
    'billed': 'BILLED',
    'qty': 'QUANTITY',
    'bill_no': 'BILL NO#',
    'bill_date': 'BILL DATE',
    'invoice_total': 'INVOICE TOTAL',
    'created_time': 'CREATED TIME',
    'modified_time': 'LAST MODIFIED TIME',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(purchaseReceivesProvider);
      ref.invalidate(warehousesProvider);
    });
    _activeReceiveId = widget.initialSelectedId;
    _initializeColumns();
    _loadColumnSettings();
    if (widget.initialFilter != null) {
      final found = _receiveFilterOptions.where(
        (v) =>
            v.value.toLowerCase() == widget.initialFilter!.toLowerCase() ||
            v.label.toLowerCase() == widget.initialFilter!.toLowerCase(),
      );
      if (found.isNotEmpty) {
        _activeOption = found.first;
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseReceivesProvider.notifier).fetchReceives();
    });
  }

  @override
  void dispose() {
    POItemDetailsSidebar.hide();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _initializeColumns() {
    _allColumns = [
      ColumnConfig(id: 'date', label: 'DATE', orderIndex: 0, isLocked: true),
      ColumnConfig(
        id: 'pr#',
        label: 'PURCHASE RECEIVE#',
        orderIndex: 1,
        isLocked: true,
      ),
      ColumnConfig(id: 'po#', label: 'PURCHASE ORDER#', orderIndex: 2),
      ColumnConfig(id: 'vendor', label: 'VENDOR NAME', orderIndex: 3),
      ColumnConfig(
        id: 'status',
        label: 'STATUS',
        orderIndex: 4,
        isLocked: true,
      ),
      ColumnConfig(id: 'billed', label: 'BILLED', orderIndex: 5),
      ColumnConfig(id: 'qty', label: 'QUANTITY', orderIndex: 6),
      ColumnConfig(
        id: 'bill_no',
        label: 'BILL NO#',
        orderIndex: 7,
        isVisible: false,
      ),
      ColumnConfig(
        id: 'bill_date',
        label: 'BILL DATE',
        orderIndex: 8,
        isVisible: false,
      ),
      ColumnConfig(
        id: 'invoice_total',
        label: 'INVOICE TOTAL',
        orderIndex: 9,
        isVisible: false,
      ),
      ColumnConfig(id: 'created_time', label: 'CREATED TIME', orderIndex: 10),
      ColumnConfig(
        id: 'modified_time',
        label: 'LAST MODIFIED TIME',
        orderIndex: 11,
      ),
    ];
    _updateVisibleColumns();
  }

  void _updateVisibleColumns() {
    _allColumns.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
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
      final jsonStr = prefs.getString('pr_table_columns_config');
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
      await prefs.setString('pr_table_columns_config', jsonStr);
    } catch (e) {
      debugPrint('Error saving column settings: $e');
    }
  }

  void _toggleSelection(String id) {
    if (id.isEmpty) return;
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleAll(List<PurchaseReceive> receives) {
    setState(() {
      if (_selectedIds.length == receives.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.clear();
        for (final r in receives) {
          if (r.id != null) {
            _selectedIds.add(r.id!);
          }
        }
      }
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  Future<void> _applyBulkStatus(String status) async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;

    final repo = ref.read(purchaseReceiveRepositoryProvider);
    final state = ref.read(purchaseReceivesProvider).value;
    if (state == null) return;

    // Check if any selected item is already in target status
    bool anyAlreadyInStatus = false;
    for (final id in ids) {
      final receive = state.receives.firstWhere((r) => r.id == id);
      if (receive.status.toLowerCase() == status.toLowerCase()) {
        anyAlreadyInStatus = true;
        break;
      }
    }

    if (anyAlreadyInStatus) {
      ZerpaiToast.error(
        context,
        'One or more selected items are already in $status status',
      );
      return;
    }

    for (final id in ids) {
      final receive = state.receives.firstWhere((r) => r.id == id);
      final updated = receive.copyWith(status: status.toLowerCase());
      await repo.updatePurchaseReceive(id, updated);
      // Invalidate provider to force refresh in detail panel
      ref.invalidate(purchaseReceiveByIdProvider(id));
    }

    // Refresh list ONCE after all updates
    await ref.read(purchaseReceivesProvider.notifier).fetchReceives();

    _clearSelection();
    ZerpaiToast.success(
      context,
      'Updated ${ids.length} items to ${status.replaceAll('_', ' ')}',
    );
  }

  Future<void> _deleteSelectedReceives() async {
    final ids = _selectedIds.toList();
    if (ids.isEmpty) return;

    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Purchase Receives',
      message:
          'Are you sure you want to delete ${ids.length} items? This action cannot be undone.',
      confirmLabel: 'Delete',
      variant: ZerpaiConfirmationVariant.danger,
    );

    if (confirmed == true) {
      final notifier = ref.read(purchaseReceivesProvider.notifier);
      int successCount = 0;
      for (final id in ids) {
        await notifier.deleteReceive(id);
        successCount++;
      }
      _clearSelection();
      ZerpaiToast.success(
        context,
        'Successfully deleted $successCount purchase receives',
      );
    }
  }

  Widget _buildSelectionActionsPopupBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Close/Deselect all icon
          InkWell(
            onTap: _clearSelection,
            child: const Icon(
              LucideIcons.x,
              size: 20,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          _buildSelectionButton(
            'Mark as Received',
            () => _applyBulkStatus('RECEIVED'),
          ),
          const SizedBox(width: 12),
          _buildSelectionButton(
            'Mark as In Transit',
            () => _applyBulkStatus('INTRANSIT'),
          ),
          const SizedBox(width: 12),
          _buildSelectionButton('Delete', _deleteSelectedReceives),
          const SizedBox(width: 16),
          Container(width: 1, height: 20, color: AppTheme.borderColor),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_selectedIds.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Selected',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          const Text(
            'Esc',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _clearSelection,
            icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.errorRed),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        backgroundColor: AppTheme.bgLight,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBulkActionsDropdown() {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
        elevation: const WidgetStatePropertyAll(8),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      builder: (context, controller, child) {
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: InkWell(
            onTap: () =>
                controller.isOpen ? controller.close() : controller.open(),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bulk Actions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: () => _applyBulkStatus('RECEIVED'),
          child: const SizedBox(width: 180, child: Text('Mark as Received')),
        ),
        const Divider(height: 1),
        MenuItemButton(
          onPressed: () => _applyBulkStatus('INTRANSIT'),
          child: const SizedBox(width: 180, child: Text('Mark as In Transit')),
        ),
        const Divider(height: 1),
        MenuItemButton(
          onPressed: _deleteSelectedReceives,
          child: const SizedBox(
            width: 180,
            child: Text('Delete', style: TextStyle(color: AppTheme.errorRed)),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftSplitHeader() {
    if (_selectedIds.isNotEmpty) {
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
        ),
        child: Row(
          children: [
            InkWell(onTap: _clearSelection, child: _buildCheckboxWidget(true)),
            const SizedBox(width: 12),
            _buildBulkActionsDropdown(),
            const SizedBox(width: 16),
            Container(width: 1, height: 20, color: AppTheme.borderColor),
            const SizedBox(width: 16),
            Text(
              '${_selectedIds.length} Selected',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: _clearSelection,
              icon: const Icon(
                LucideIcons.x,
                size: 18,
                color: AppTheme.errorRed,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Expanded(child: _buildViewSelector(isCompact: true)),
          _buildNewButton(isIconOnly: true),
          const SizedBox(width: 8),
          _buildMoreMenu(),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final receivesAsync = ref.watch(purchaseReceivesProvider);

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape):
            const _ClearReceiveSelectionIntent(),
      },
      child: Actions(
        actions: {
          _ClearReceiveSelectionIntent:
              CallbackAction<_ClearReceiveSelectionIntent>(
                onInvoke: (intent) {
                  _clearSelection();
                  return null;
                },
              ),
        },
        child: Focus(
          autofocus: true,
          child: ZerpaiLayout(
            pageTitle: '',
            enableBodyScroll: false,
            useHorizontalPadding: false,
            useTopPadding: false,
            child: receivesAsync.when(
              data: (state) {
                final filtered = state.receives.where((r) {
                  final val = _activeOption.value;
                  if (val == 'all') return true;
                  if (val == 'intransit')
                    return r.status
                            .toLowerCase()
                            .replaceAll(' ', '')
                            .replaceAll('_', '') ==
                        'intransit';
                  if (val == 'received')
                    return r.status.toLowerCase() == 'received';
                  if (val == 'billed') {
                    final bStatus = r.billStatus.toLowerCase();
                    return bStatus == 'full' || bStatus == 'billed';
                  }
                  if (val == 'partially_billed') {
                    final bStatus = r.billStatus.toLowerCase();
                    return bStatus == 'partial' ||
                        bStatus == 'partially_billed' ||
                        bStatus == 'partially billed';
                  }
                  return true;
                }).toList();
                final sorted = _getSortedList(filtered);
                return Stack(
                  children: [
                    _activeReceiveId == null
                        ? Column(
                            children: [
                              _buildMainToolbar(sorted),
                              const Divider(
                                height: 1,
                                color: AppTheme.borderColor,
                              ),
                              Expanded(child: _buildVirtualizedTable(sorted)),
                            ],
                          )
                        : _buildSplitView(sorted),
                    if (_selectedIds.isNotEmpty && _activeReceiveId == null)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: _buildSelectionActionsPopupBar(),
                      ),
                  ],
                );
              },
              loading: _buildLoadingState,
              error: (err, stack) => ZErrorPlaceholder(
                error: err,
                message: 'Failed to load purchase receives',
                onRetry: () {
                  ref.read(purchaseReceivesProvider.notifier).fetchReceives();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSplitView(List<PurchaseReceive> receives) {
    final sorted = _getSortedList(receives);
    PurchaseReceive? selected;
    for (final r in sorted) {
      if (r.id == _activeReceiveId) {
        selected = r;
        break;
      }
    }
    return Row(
      children: [
        SizedBox(
          width: 360,
          child: Column(
            children: [
              _buildLeftSplitHeader(),
              const Divider(height: 1, color: AppTheme.borderColor),
              Expanded(child: _buildCompactList(sorted)),
            ],
          ),
        ),
        const VerticalDivider(width: 1, color: AppTheme.borderColor),
        Expanded(
          child: selected == null
              ? _buildEmptyState()
              : _buildReceiveDetailPanel(selected),
        ),
      ],
    );
  }

  List<PurchaseReceive> _getSortedList(List<PurchaseReceive> receives) {
    final list = List<PurchaseReceive>.from(receives);
    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case 'date':
          cmp = (a.receivedDate ?? DateTime(0)).compareTo(
            b.receivedDate ?? DateTime(0),
          );
          break;
        case 'pr#':
          cmp = a.purchaseReceiveNumber.compareTo(b.purchaseReceiveNumber);
          break;
        case 'po#':
          cmp = (a.purchaseOrderNumber ?? '').compareTo(
            b.purchaseOrderNumber ?? '',
          );
          break;
        case 'vendor':
          cmp = (a.vendorName ?? '').compareTo(b.vendorName ?? '');
          break;
        case 'qty':
          cmp = _getTotalQuantityDouble(a).compareTo(_getTotalQuantityDouble(b));
          break;
        case 'bill_no':
          cmp = (a.billNo ?? '').compareTo(b.billNo ?? '');
          break;
        case 'bill_date':
          cmp = (a.billDate ?? DateTime(0)).compareTo(
            b.billDate ?? DateTime(0),
          );
          break;
        case 'invoice_total':
          cmp = a.invoiceTotal.compareTo(b.invoiceTotal);
          break;
        case 'created_time':
          cmp = (a.createdAt ?? DateTime(0)).compareTo(
            b.createdAt ?? DateTime(0),
          );
          break;
        case 'modified_time':
          cmp = (a.updatedAt ?? DateTime(0)).compareTo(
            b.updatedAt ?? DateTime(0),
          );
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  Widget _buildMoreMenu() {
    return ZTableMoreMenu(
      menuChildren: [
        SubmenuButton(
          menuStyle: MenuStyle(
            backgroundColor: const WidgetStatePropertyAll(
              AppTheme.backgroundColor,
            ),
            surfaceTintColor: const WidgetStatePropertyAll(
              AppTheme.backgroundColor,
            ),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            elevation: const WidgetStatePropertyAll(8),
          ),
          style: ZTableMoreMenu.menuItemButtonStyle(isHeader: true),
          menuChildren: [
            _buildSortMenuItem('Date', 'date'),
            _buildSortMenuItem('Purchase Receive#', 'pr#'),
            _buildSortMenuItem('Purchase Order#', 'po#'),
            _buildSortMenuItem('Vendor Name', 'vendor'),
            _buildSortMenuItem('Quantity', 'qty'),
            _buildSortMenuItem('Created Time', 'created_time'),
            _buildSortMenuItem('Last Modified Time', 'modified_time'),
          ],
          child: Row(
            children: const [
              Icon(LucideIcons.arrowUpDown, size: 16),
              SizedBox(width: 12),
              Text(
                'Sort by',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.bgDisabled),
        MenuItemButton(
          onPressed: () {},
          style: ZTableMoreMenu.menuItemButtonStyle(),
          child: Row(
            children: const [
              Icon(LucideIcons.download, size: 16),
              SizedBox(width: 12),
              const Text(
                'Import Purchase Receives',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        MenuItemButton(
          onPressed: () {},
          style: ZTableMoreMenu.menuItemButtonStyle(),
          child: Row(
            children: const [
              Icon(LucideIcons.upload, size: 16),
              SizedBox(width: 12),
              const Text(
                'Export Purchase Receives',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.bgDisabled),
        MenuItemButton(
          onPressed: () =>
              ref.read(purchaseReceivesProvider.notifier).fetchReceives(),
          style: ZTableMoreMenu.menuItemButtonStyle(),
          child: Row(
            children: const [
              Icon(LucideIcons.refreshCw, size: 16),
              SizedBox(width: 12),
              const Text('Refresh List', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainToolbar(List<PurchaseReceive> receives) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          _buildViewSelector(),
          const Spacer(),
          InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => _ExtraQuantityDialog(receives: receives),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppTheme.borderColor),
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                'Extra Quantity',
                style: AppTheme.bodyText.copyWith(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildNewButton(),
          const SizedBox(width: 12),
          _buildMoreMenu(),
        ],
      ),
    );
  }

  Widget _buildSortMenuItem(String label, String field) {
    final isActive = _sortField == field;
    return MenuItemButton(
      onPressed: () {
        setState(() {
          if (_sortField == field) {
            _sortAscending = !_sortAscending;
          } else {
            _sortField = field;
            _sortAscending = true;
          }
        });
      },
      style: ZTableMoreMenu.menuItemButtonStyle(isActive: isActive),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
          if (isActive)
            Icon(
              _sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
              size: 16,
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final int skeletonColumns = math.max(5, _visibleColumns.length + 1);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ZTableSkeleton(rows: 10, columns: skeletonColumns),
    );
  }

  Widget _buildViewSelector({bool isCompact = false}) {
    return FavoriteFilterDropdown(
      moduleName: 'purchase_receives',
      options: _receiveFilterOptions,
      selectedOption: _activeOption,
      isCompact: isCompact,
      onChanged: (opt) {
        setState(() {
          _activeOption = opt;
        });
      },
    );
  }

  Widget _buildNewButton({bool isIconOnly = false}) {
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
    if (isIconOnly) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF22A95E),
          borderRadius: BorderRadius.circular(4),
        ),
        child: IconButton(
          onPressed: () => context.pushNamed(
            AppRoutes.purchaseReceivesCreate,
            pathParameters: {'orgSystemId': orgId},
          ),
          icon: const Icon(LucideIcons.plus, size: 16, color: Colors.white),
          padding: EdgeInsets.zero,
        ),
      );
    }
    return ElevatedButton(
      onPressed: () => context.pushNamed(
        AppRoutes.purchaseReceivesCreate,
        pathParameters: {'orgSystemId': orgId},
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF22A95E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.plus, size: 16),
          SizedBox(width: 6),
          Text(
            'New',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildVirtualizedTable(List<PurchaseReceive> receives) {
    if (receives.isEmpty) {
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
                  _buildTableHeader(columnWidths, receives),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: receives.length,
                      itemExtent: 40, // High density Zoho style
                      itemBuilder: (context, index) {
                        return _buildVirtualRow(receives[index], columnWidths);
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
      'date': (102.0, 1.0),
      'pr#': (120.0, 2.0),
      'po#': (120.0, 2.0),
      'vendor': (180.0, 4.0),
      'status': (110.0, 1.0),
      'billed': (90.0, 1.0),
      'qty': (80.0, 1.0),
      'bill_no': (120.0, 1.5),
      'bill_date': (110.0, 1.2),
      'invoice_total': (120.0, 1.5),
      'created_time': (160.0, 1.5),
      'modified_time': (160.0, 1.5),
    };

    double totalMinWidth = staticPrefixWidth;
    double totalFlex = 0;

    for (final colId in _visibleColumns) {
      final m = metrics[colId] ?? (150.0, 1.5);
      totalMinWidth += m.$1;
      totalFlex += m.$2;
    }

    final extraSpace = math.max(0.0, totalWidth - totalMinWidth);
    final results = <String, double>{};

    for (final colId in _visibleColumns) {
      final m = metrics[colId] ?? (150.0, 1.5);
      results[colId] = m.$1 + (m.$2 / totalFlex) * extraSpace;
    }

    return results;
  }

  Widget _buildTableHeader(
    Map<String, double> columnWidths,
    List<PurchaseReceive> receives,
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
          _buildSelectAllCheckbox(receives),
          const SizedBox(width: 12),
          ..._visibleColumns.map((colId) {
            final width = columnWidths[colId]!;
            final align = (colId == 'qty' || colId == 'billed')
                ? TextAlign.center
                : TextAlign.left;

            return _ResizableHeaderCell(
              width: width,
              onResize: (dx) => _resizeColumn(colId, dx),
              child: _buildHeaderCell(
                _columnLabels[colId]!,
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

  Widget _buildVirtualRow(
    PurchaseReceive receive,
    Map<String, double> columnWidths,
  ) {
    final isSelected = _selectedIds.contains(receive.id);

    return InkWell(
      onTap: () {
        setState(() {
          _activeReceiveId = receive.id;
        });
      },
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
            InkWell(
              onTap: () => _toggleSelection(receive.id ?? ''),
              child: _buildCheckboxWidget(isSelected),
            ),
            const SizedBox(width: 12),
            ..._visibleColumns.map((colId) {
              return _buildCell(receive, colId, width: columnWidths[colId]!);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactList(List<PurchaseReceive> receives) {
    return ListView.builder(
      itemCount: receives.length,
      itemBuilder: (context, index) {
        final receive = receives[index];
        final isActive = receive.id == _activeReceiveId;
        final isSelected = _selectedIds.contains(receive.id);
        return InkWell(
          onTap: () => setState(() => _activeReceiveId = receive.id),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF0F7FF) : Colors.white,
              border: const Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => _toggleSelection(receive.id ?? ''),
                  child: _buildCheckboxWidget(isSelected),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receive.vendorName ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${receive.purchaseReceiveNumber}  •  ${receive.purchaseOrderNumber ?? '-'}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        receive.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(receive.status),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _getTotalQuantity(receive),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReceiveDetailPanel(PurchaseReceive receive) {
    return _PurchaseReceiveDetailPanel(
      id: receive.id!,
      onClose: () => setState(() => _activeReceiveId = null),
    );
  }

  Widget _buildSelectAllCheckbox(List<PurchaseReceive> receives) {
    final isAllSelected =
        receives.isNotEmpty && _selectedIds.length == receives.length;
    final isPartiallySelected =
        _selectedIds.isNotEmpty && _selectedIds.length < receives.length;

    return InkWell(
      onTap: () => _toggleAll(receives),
      child: _buildCheckboxWidget(
        isAllSelected,
        isPartially: isPartiallySelected,
      ),
    );
  }

  Widget _buildCheckboxWidget(bool isSelected, {bool isPartially = false}) {
    return isSelected || isPartially
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
          );
  }

  Widget _buildHeaderCell(
    String text,
    String colId, {
    double? width,
    TextAlign? align,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_sortField == colId) {
            _sortAscending = !_sortAscending;
          } else {
            _sortField = colId;
            _sortAscending = true;
          }
        });
      },
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: align == TextAlign.right
            ? Alignment.centerRight
            : (align == TextAlign.center
                  ? Alignment.center
                  : Alignment.centerLeft),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.tableHeader.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(PurchaseReceive receive, String colId, {double? width}) {
    Widget content;
    TextAlign align = (colId == 'billed' || colId == 'qty')
        ? TextAlign.center
        : TextAlign.left;

    switch (colId) {
      case 'date':
        content = Text(
          DateFormat(
            'dd-MM-yyyy',
          ).format(receive.receivedDate ?? DateTime.now()),
          style: AppTheme.tableCell,
        );
        break;
      case 'pr#':
        content = Text(
          receive.purchaseReceiveNumber,
          style: AppTheme.tableCell.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        );
        break;
      case 'po#':
        final orgId =
            GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
        content = InkWell(
          onTap:
              (receive.purchaseOrderId == null ||
                  receive.purchaseOrderId!.isEmpty)
              ? null
              : () => context.go(
                  '/$orgId/purchases/purchase-orders/${receive.purchaseOrderId}',
                ),
          child: Text(
            receive.purchaseOrderNumber ?? '-',
            style: AppTheme.tableCell.copyWith(
              color: AppTheme.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
        break;
      case 'vendor':
        content = Text(receive.vendorName ?? '-', style: AppTheme.tableCell);
        break;
      case 'status':
        content = Text(
          receive.status.toUpperCase(),
          style: AppTheme.tableCell.copyWith(
            color: _getStatusColor(receive.status),
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        );
        break;
      case 'billed':
        Widget ball;
        final bStatus = receive.billStatus.toLowerCase();
        if (bStatus == 'full' || bStatus == 'billed') {
          ball = const Icon(Icons.circle, color: Colors.green, size: 12);
        } else if (bStatus == 'partial' ||
            bStatus == 'partially billed' ||
            bStatus == 'partially_billed') {
          ball = Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.circle_outlined, color: Colors.green, size: 12),
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
          ball = const Icon(Icons.circle, color: Colors.grey, size: 12);
        }
        content = Center(child: ball);
        break;
      case 'qty':
        content = Text(_getTotalQuantity(receive), style: AppTheme.tableCell);
        break;
      case 'bill_no':
        content = Text(receive.billNo ?? '-', style: AppTheme.tableCell);
        break;
      case 'bill_date':
        content = Text(
          receive.billDate != null
              ? DateFormat('dd-MM-yyyy').format(receive.billDate!)
              : '-',
          style: AppTheme.tableCell,
        );
        break;
      case 'invoice_total':
        content = Text(
          '₹${receive.invoiceTotal.toStringAsFixed(2)}',
          style: AppTheme.tableCell.copyWith(fontWeight: FontWeight.w600),
        );
        break;
      case 'created_time':
        content = Text(
          DateFormat(
            'dd-MM-yyyy hh:mm a',
          ).format(DateTime.now()), // Placeholder
          style: AppTheme.tableCell.copyWith(color: AppTheme.textSecondary),
        );
        break;
      case 'modified_time':
        content = Text(
          DateFormat(
            'dd-MM-yyyy hh:mm a',
          ).format(DateTime.now()), // Placeholder
          style: AppTheme.tableCell.copyWith(color: AppTheme.textSecondary),
        );
        break;
      default:
        content = const Text('-');
    }

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: align == TextAlign.right
          ? Alignment.centerRight
          : (align == TextAlign.center
                ? Alignment.center
                : Alignment.centerLeft),
      child: DefaultTextStyle(
        style: AppTheme.tableCell.copyWith(
          overflow: _shouldWrapText
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        ),
        maxLines: _shouldWrapText ? null : 1,
        softWrap: _shouldWrapText,
        child: content,
      ),
    );
  }

  String _formatQuantity(double value) {
    final intVal = value.toInt();
    return value == intVal ? intVal.toString() : value.toStringAsFixed(2);
  }

  double _getTotalQuantityDouble(PurchaseReceive receive) {
    double total = 0;
    for (var item in receive.items) {
      if (item.batches.isNotEmpty) {
        total += item.batches.fold<double>(0, (sum, b) => sum + b.quantity + b.foc);
      } else {
        total += item.quantityToReceive;
      }
    }
    if (total > 0) return total;
    return receive.quantity;
  }

  String _getTotalQuantity(PurchaseReceive receive) {
    final total = _getTotalQuantityDouble(receive);
    return total > 0 ? _formatQuantity(total) : '0';
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.package, size: 48, color: AppTheme.bgDisabled),
          SizedBox(height: 16),
          Text(
            'No purchase receives found',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseReceiveDetailPanel extends ConsumerStatefulWidget {
  final String id;
  final VoidCallback onClose;

  const _PurchaseReceiveDetailPanel({required this.id, required this.onClose});

  @override
  ConsumerState<_PurchaseReceiveDetailPanel> createState() =>
      _PurchaseReceiveDetailPanelState();
}

class _PurchaseReceiveDetailPanelState
    extends ConsumerState<_PurchaseReceiveDetailPanel> {
  bool _showPdfView = false;
  int _activeTabIndex = 0;
  String? _localStatus;
  bool _isTabsExpanded = false;
  final Set<String> _expandedItems = {};
  bool _isBatchesExpanded = true;

  bool _showCommentsSidebar = false;
  final LayerLink _attachmentBadgeLink = LayerLink();
  OverlayEntry? _attachmentListOverlay;
  List<Map<String, dynamic>> _receiveAttachments = [];
  bool _isLoadingAttachments = false;

  String? _lastLoadedReceiveId;
  List<Map<String, dynamic>>? _poBills;
  List<Map<String, dynamic>>? _poReceives;
  String? _poStatus;

  Future<void> _loadAdditionalData(PurchaseReceive receive) async {
    if (receive.purchaseOrderId == null || receive.purchaseOrderId!.isEmpty) {
      return;
    }
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch the Purchase Order to get its actual status
      final poResp = await supabase
          .from('purchase_orders')
          .select('status, order_date')
          .eq('id', receive.purchaseOrderId!)
          .maybeSingle();

      // 2. Fetch all receives for this PO to perform FIFO allocation
      final receivesResp = await supabase
          .from('purchase_receives')
          .select(
            'id, purchase_receive_number, received_date, status, purchase_receive_items(item_id, quantity_to_receive)',
          )
          .eq('purchase_order_id', receive.purchaseOrderId!)
          .order('created_at', ascending: true);

      // 3. Fetch all bills for this PO
      final billsResp = await supabase
          .from('bills')
          .select(
            'id, bill_number, order_number, bill_date, status, grand_total, due_date, bill_items(product_id, quantity)',
          )
          .ilike('order_number', '%${receive.purchaseOrderNumber ?? ''}%')
          .order('created_at', ascending: true);

      final normalizedPoNum = (receive.purchaseOrderNumber ?? '').trim().toLowerCase();
      final rawBills = (billsResp as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      final filteredBills = rawBills.where((b) {
        final orderNumStr = (b['order_number'] ?? '').toString().toLowerCase();
        final parts = orderNumStr.split(',').map((p) => p.trim()).toList();
        return parts.contains(normalizedPoNum);
      }).toList();

      if (mounted) {
        setState(() {
          _poStatus = poResp != null ? poResp['status'] as String? : null;
          _poReceives = (receivesResp as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _poBills = filteredBills;
        });
      }
    } catch (e) {
      debugPrint('Error loading additional receive data: $e');
    }
  }

  Future<void> _loadReceiveAttachments(String? receiveId) async {
    if (receiveId == null || receiveId.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _isLoadingAttachments = true;
    });
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('purchase_receive_attachments')
          .select('id, file_name, file_path, file_size, file_type, uploaded_at')
          .eq('purchase_receive_id', receiveId)
          .order('uploaded_at', ascending: false);
      if (mounted) {
        setState(() {
          _receiveAttachments = (res as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoadingAttachments = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading receive attachments: $e');
      if (mounted) {
        setState(() {
          _isLoadingAttachments = false;
        });
      }
    }
  }

  void _toggleAttachmentListOverlay(PurchaseReceive receive) {
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
              child: _ReceiveAttachmentOverlayContent(
                receive: receive,
                ref: ref,
                onRefresh: () => _loadReceiveAttachments(receive.id),
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

  String _getReceiveBillStatus(PurchaseReceive receive) {
    if (_poBills == null || _poReceives == null) {
      return 'Not Billed Yet';
    }

    final Map<String, double> billedQuantities = {};
    for (final bill in _poBills!) {
      final statusStr = bill['status']?.toString().toLowerCase() ?? '';
      if (statusStr == 'void') continue;

      final items = bill['bill_items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final prodId = item['product_id']?.toString() ?? '';
        final qty =
            double.tryParse(item['quantity']?.toString() ?? '0.0') ?? 0.0;
        billedQuantities[prodId] = (billedQuantities[prodId] ?? 0.0) + qty;
      }
    }

    double totalReceiveQty = 0.0;
    double totalBilledForThisReceive = 0.0;

    for (final rx in _poReceives!) {
      final rxId = rx['id']?.toString() ?? '';
      final rxItems = rx['purchase_receive_items'] as List<dynamic>? ?? [];

      final isTargetReceive = (rxId == receive.id);

      for (final item in rxItems) {
        final prodId = item['item_id']?.toString() ?? '';
        final qtyToReceive =
            double.tryParse(item['quantity_to_receive']?.toString() ?? '0.0') ??
            0.0;

        if (isTargetReceive) {
          totalReceiveQty += qtyToReceive;
        }

        final availableBilled = billedQuantities[prodId] ?? 0.0;
        final allocated = availableBilled >= qtyToReceive
            ? qtyToReceive
            : availableBilled;

        billedQuantities[prodId] = availableBilled - allocated;

        if (isTargetReceive) {
          totalBilledForThisReceive += allocated;
        }
      }
    }

    if (totalReceiveQty <= 0.0) {
      return 'Not Billed Yet';
    }
    if (totalBilledForThisReceive <= 0.0) {
      return 'Not Billed Yet';
    }
    if (totalBilledForThisReceive < totalReceiveQty) {
      return 'Partially Billed';
    }
    return 'Billed';
  }

  double _getItemBilledQty(PurchaseReceive receive, String? itemId) {
    if (itemId == null || itemId.isEmpty) return 0.0;
    if (_poBills == null || _poReceives == null) return 0.0;

    final Map<String, double> billedQuantities = {};
    for (final bill in _poBills!) {
      final statusStr = bill['status']?.toString().toLowerCase() ?? '';
      if (statusStr == 'void') continue;

      final items = bill['bill_items'] as List<dynamic>? ?? [];
      for (final item in items) {
        final prodId = item['product_id']?.toString() ?? '';
        final qty =
            double.tryParse(item['quantity']?.toString() ?? '0.0') ?? 0.0;
        billedQuantities[prodId] = (billedQuantities[prodId] ?? 0.0) + qty;
      }
    }

    double itemBilledForThisReceive = 0.0;

    for (final rx in _poReceives!) {
      final rxId = rx['id']?.toString() ?? '';
      final rxItems = rx['purchase_receive_items'] as List<dynamic>? ?? [];

      final isTargetReceive = (rxId == receive.id);

      for (final item in rxItems) {
        final prodId = item['item_id']?.toString() ?? '';
        final qtyToReceive =
            double.tryParse(item['quantity_to_receive']?.toString() ?? '0.0') ??
            0.0;

        final availableBilled = billedQuantities[prodId] ?? 0.0;
        final allocated = availableBilled >= qtyToReceive
            ? qtyToReceive
            : availableBilled;

        billedQuantities[prodId] = availableBilled - allocated;

        if (isTargetReceive && prodId == itemId) {
          itemBilledForThisReceive += allocated;
        }
      }
    }

    return itemBilledForThisReceive;
  }

  String _fmtQty(double value) {
    final intVal = value.toInt();
    return value == intVal ? intVal.toString() : value.toStringAsFixed(2);
  }

  Color _getPoStatusColor(String status) {
    final clean = status.toLowerCase().trim();
    if (clean == 'closed' || clean == 'received') {
      return const Color(0xFF22A95E); // Green
    }
    if (clean == 'issued' || clean == 'open') {
      return const Color(0xFF0088FF); // Blue
    }
    if (clean == 'draft') {
      return Colors.grey;
    }
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final receiveAsync = ref.watch(purchaseReceiveByIdProvider(widget.id));
    receiveAsync.whenData((receive) {
      if (receive != null && _lastLoadedReceiveId != receive.id) {
        _lastLoadedReceiveId = receive.id;
        _isTabsExpanded = false;
        Future.microtask(() {
          _loadAdditionalData(receive);
          _loadReceiveAttachments(receive.id);
        });
      }
    });

    Widget detailContent = Column(
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: receiveAsync.when(
            data: (receive) => receive == null
                ? const SizedBox.shrink()
                : Row(
                    children: [
                      Text(
                        receive.purchaseReceiveNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      CompositedTransformTarget(
                        link: _attachmentBadgeLink,
                        child: InkWell(
                          onTap: () => _toggleAttachmentListOverlay(receive),
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
                                if (_receiveAttachments.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_receiveAttachments.length}',
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
                          setState(() {
                            _showCommentsSidebar = !_showCommentsSidebar;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _ActionSquare(
                        icon: LucideIcons.x,
                        color: AppTheme.errorRed,
                        onTap: widget.onClose,
                      ),
                    ],
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: AppTheme.bgLight,
            border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
          ),
          child: receiveAsync.when(
            data: (receive) {
              if (receive == null) return const SizedBox.shrink();
              final currentStatus = (_localStatus ?? receive.status)
                  .toLowerCase()
                  .replaceAll(' ', '')
                  .replaceAll('_', '');
              return Row(
                children: [
                  _buildToolbarButton(
                    LucideIcons.edit,
                    'Edit',
                    onPressed: () {
                      final orgId = GoRouterState.of(
                        context,
                      ).pathParameters['orgSystemId']!;
                      context.pushNamed(
                        AppRoutes.purchaseReceivesEdit,
                        pathParameters: {
                          'orgSystemId': orgId,
                          'id': receive.id!,
                        },
                      );
                    },
                  ),
                  _buildDivider(),
                  _buildPdfPrintDropdown(receive),
                  _buildDivider(),
                  if (!(currentStatus == 'received' &&
                      _getReceiveBillStatus(receive).toLowerCase() ==
                          'billed')) ...[
                    _buildToolbarButton(
                      LucideIcons.fileText,
                      'Convert to Bill',
                      onPressed: () {
                        final orgId = GoRouterState.of(
                          context,
                        ).pathParameters['orgSystemId']!;
                        context.pushNamed(
                          AppRoutes.billsCreate,
                          pathParameters: {'orgSystemId': orgId},
                          queryParameters: {'receiveId': receive.id!},
                        );
                      },
                    ),
                    _buildDivider(),
                  ],
                  if (currentStatus == 'draft' ||
                      currentStatus == 'intransit') ...[
                    _buildToolbarButton(
                      LucideIcons.checkCircle,
                      'Mark as Received',
                      onPressed: () => _updateStatus(receive, 'RECEIVED'),
                    ),
                    _buildDivider(),
                  ],
                  if (currentStatus == 'received') ...[
                    _buildToolbarButton(
                      LucideIcons.truck,
                      'Mark as In Transit',
                      onPressed: () => _updateStatus(receive, 'INTRANSIT'),
                    ),
                    _buildDivider(),
                  ],
                  _buildToolbarButton(
                    LucideIcons.trash2,
                    'Delete',
                    color: AppTheme.errorRed,
                    onPressed: () => _deleteReceive(receive.id!),
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),
        Expanded(
          child: receiveAsync.when(
            data: (receive) {
              if (receive == null)
                return const Center(child: Text('Purchase receive not found'));
              if (_showPdfView) {
                return Column(
                  children: [
                    _buildToggleRow(),
                    Expanded(
                      child: _PurchaseReceivePdfView(
                        receive: receive,
                        billStatus: _getReceiveBillStatus(receive),
                      ),
                    ),
                  ],
                );
              }
              return _buildStandardView(receive);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );

    if (_showCommentsSidebar) {
      final receive = receiveAsync.valueOrNull;
      return Row(
        children: [
          Expanded(child: detailContent),
          if (receive != null) ...[
            const VerticalDivider(
              width: 1,
              thickness: 1,
              color: AppTheme.borderLight,
            ),
            _buildCommentsSidebar(receive),
          ],
        ],
      );
    } else {
      return detailContent;
    }
  }

  Future<void> _updateStatus(PurchaseReceive receive, String status) async {
    final success = await ref
        .read(purchaseReceivesProvider.notifier)
        .updateReceive(
          receive.id!,
          receive.copyWith(status: status.toLowerCase(), items: []),
        );
    if (success && mounted) {
      ZerpaiToast.success(
        context,
        'Status updated to ${status.replaceAll('_', ' ')}',
      );
      setState(() {
        _localStatus = status.toLowerCase();
      });
      // Force refresh the detailed view and wait for it
      ref.invalidate(purchaseReceiveByIdProvider(widget.id));
      await ref.read(purchaseReceiveByIdProvider(widget.id).future);
    } else if (mounted) {
      ZerpaiToast.error(context, 'Failed to update status');
    }
  }

  Widget _buildToolbarButton(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
    Color? color,
    bool hasDropdownArrow = false,
  }) {
    final btnColor = color ?? AppTheme.textSubtle;
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

  Future<void> _deleteReceive(String id) async {
    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Purchase Receive',
      message:
          'Are you sure you want to delete this purchase receive? This action cannot be undone.',
      confirmLabel: 'Delete',
      variant: ZerpaiConfirmationVariant.danger,
    );

    if (confirmed == true) {
      final success = await ref
          .read(purchaseReceivesProvider.notifier)
          .deleteReceive(id);
      if (success && mounted) {
        ZerpaiToast.success(context, 'Purchase receive deleted successfully');
        widget.onClose();
      } else if (mounted) {
        ZerpaiToast.error(context, 'Failed to delete purchase receive');
      }
    }
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 16,
      color: AppTheme.borderColor,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildPdfPrintDropdown(PurchaseReceive receive) {
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
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
      menuChildren: [
        MenuItemButton(
          onPressed: () async {
            final bytes = await _generatePdf(receive, orgSettings);
            await Printing.sharePdf(
              bytes: bytes,
              filename: '${receive.purchaseReceiveNumber}.pdf',
            );
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? AppTheme.primaryBlue
                  : Colors.white,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? Colors.white
                  : AppTheme.textPrimary,
            ),
            iconColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? Colors.white
                  : AppTheme.primaryBlue,
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
            final bytes = await _generatePdf(receive, orgSettings);
            await Printing.layoutPdf(
              onLayout: (_) async => bytes,
              name: receive.purchaseReceiveNumber,
            );
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? AppTheme.primaryBlue
                  : Colors.white,
            ),
            foregroundColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? Colors.white
                  : AppTheme.textPrimary,
            ),
            iconColor: WidgetStateProperty.resolveWith(
              (s) => s.contains(WidgetState.hovered)
                  ? Colors.white
                  : AppTheme.primaryBlue,
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
      builder: (context, controller, _) => _buildToolbarButton(
        LucideIcons.fileText,
        'PDF/Print',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }

  Future<Uint8List> _generatePdf(
    PurchaseReceive receive,
    OrgSettings? org,
  ) async {
    final doc = pw.Document();

    // Attempt to load company logo
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

    final dateStr = receive.receivedDate != null
        ? DateFormat('dd-MM-yyyy').format(receive.receivedDate!)
        : '-';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context ctx) {
          return pw.Stack(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ── Header ──────────────────────────────────────────────────
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
                              child: pw.Image(
                                logoImage,
                                fit: pw.BoxFit.contain,
                              ),
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
                            org?.name.trim().toUpperCase() ?? 'YOUR COMPANY',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'PURCHASE RECEIVE',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 24,
                              letterSpacing: 1.5,
                            ),
                          ),
                          pw.SizedBox(height: 6),
                          pw.Text(
                            'Receive# ${receive.purchaseReceiveNumber}',
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
                  // ── Info row ────────────────────────────────────────────────
                  pw.Row(
                    children: [
                      _pwInfoCell('Receive#', receive.purchaseReceiveNumber),
                      _pwInfoCell('Receive Date', dateStr),
                      _pwInfoCell('Vendor', receive.vendorName ?? '-'),
                      _pwInfoCell(
                        'Purchase Order#',
                        receive.purchaseOrderNumber ?? '-',
                      ),
                    ],
                  ),
                  pw.Divider(color: PdfColors.grey300, height: 24),
                  pw.SizedBox(height: 16),
                  // ── Items table ──────────────────────────────────────────────
                  pw.Table(
                    columnWidths: const {
                      0: pw.FixedColumnWidth(32),
                      1: pw.FlexColumnWidth(5),
                      2: pw.FixedColumnWidth(80),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF1F2937),
                        ),
                        children: [
                          _pwHeaderCell('#'),
                          _pwHeaderCell('Item & Description'),
                          _pwHeaderCell('Qty', align: pw.Alignment.centerRight),
                        ],
                      ),
                      ...receive.items.asMap().entries.map((e) {
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
                            _pwDataCell('${e.key + 1}'),
                            _pwDataCell(e.value.itemName),
                            _pwDataCell(
                              (() {
                                final totalQty = e.value.batches.isNotEmpty
                                    ? e.value.batches.fold<double>(
                                        0,
                                        (sum, b) => sum + b.quantity,
                                      )
                                    : e.value.quantityToReceive;
                                final totalFoc = e.value.batches.isNotEmpty
                                    ? e.value.batches.fold<double>(
                                        0,
                                        (sum, b) => sum + b.foc,
                                      )
                                    : 0.0;
                                final displaySum = totalQty + totalFoc;
                                return totalFoc > 0
                                    ? '${_fmtQty(displaySum)} pcs\n(${_fmtQty(totalQty)}pcs + ${_fmtQty(totalFoc)}foc)'
                                    : '${_fmtQty(displaySum)} pcs';
                              })(),
                              align: pw.Alignment.centerRight,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ),
              if (receive.status
                      .toLowerCase()
                      .replaceAll(' ', '')
                      .replaceAll('_', '') ==
                  'intransit')
                pw.Positioned(
                  top: 20,
                  left: -20,
                  child: pw.Transform.rotate(
                    angle: -math.pi / 4,
                    child: pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 6,
                      ),
                      color: const PdfColor.fromInt(0xFFFF8800), // Orange
                      child: pw.Text(
                        'IN TRANSIT',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
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

  Widget _buildDetailTabs(PurchaseReceive receive, {bool inScrollView = false}) {
    final hasPurchaseOrder = receive.purchaseOrderId != null;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: inScrollView ? 0 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isTabsExpanded = !_isTabsExpanded),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  _buildDropdownOption(
                    'Purchase Order',
                    hasPurchaseOrder ? 1 : 0,
                    _activeTabIndex == 0,
                    () => setState(() {
                      _activeTabIndex = 0;
                      _isTabsExpanded = true;
                    }),
                  ),
                  _buildDropdownOption(
                    'Associated bills',
                    _poBills?.length ?? 0,
                    _activeTabIndex == 1,
                    () => setState(() {
                      _activeTabIndex = 1;
                      _isTabsExpanded = true;
                    }),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Icon(
                      _isTabsExpanded
                          ? LucideIcons.chevronDown
                          : LucideIcons.chevronRight,
                      size: 16,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isTabsExpanded)
            Container(
              child: _activeTabIndex == 0
                  ? (hasPurchaseOrder
                        ? _buildPOTable(receive)
                        : _buildEmptyState('No purchase order found'))
                  : _buildBillsTable(receive),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownOption(
    String label,
    int count,
    bool isActive,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.only(
          top: 12,
          bottom: 10,
          left: 16,
          right: 16,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? const Color(0xFF0088FF) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive
                    ? const Color(0xFF111827)
                    : const Color(0xFF6B7280),
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
                count.toString(),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF0088FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF6B7280),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildPOTable(PurchaseReceive receive) {
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFF9FAFB),
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'PO#',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () => context.go(
                    '/$orgId/purchases/purchase-orders/${receive.purchaseOrderId}',
                  ),
                  child: Text(
                    receive.purchaseOrderNumber ?? '-',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  DateFormat(
                    'dd-MM-yyyy',
                  ).format(receive.receivedDate ?? DateTime.now()),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  (_poStatus ?? receive.status).toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    color: _getPoStatusColor(_poStatus ?? receive.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillsTable(PurchaseReceive receive) {
    if (_poBills == null || _poBills!.isEmpty) {
      return _buildEmptyState('No associated bills found');
    }
    final orgId = GoRouterState.of(context).pathParameters['orgSystemId']!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFF9FAFB),
          child: Row(
            children: const [
              Expanded(
                flex: 3,
                child: Text(
                  'BILL#',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Date',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Amount',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
        ..._poBills!.map((bill) {
          final billId = bill['id']?.toString() ?? '';
          final billNo = bill['bill_number']?.toString() ?? '-';
          final billDateStr = bill['bill_date']?.toString();
          DateTime? billDate;
          if (billDateStr != null) {
            billDate = DateTime.tryParse(billDateStr);
          }
          final status = bill['status']?.toString() ?? 'draft';
          final grandTotal =
              double.tryParse(
                bill['grand_total']?.toString() ??
                    bill['total']?.toString() ??
                    '0.0',
              ) ??
              0.0;

          Color statusColor;
          switch (status.toLowerCase()) {
            case 'paid':
              statusColor = const Color(0xFF22A95E); // Green
              break;
            case 'open':
            case 'overdue':
              statusColor = const Color(0xFFFF8800); // Orange
              break;
            case 'void':
              statusColor = Colors.red;
              break;
            default:
              statusColor = Colors.grey;
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: billId.isEmpty
                        ? null
                        : () => context.go('/$orgId/purchases/bills/$billId'),
                    child: Text(
                      billNo,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    billDate != null
                        ? DateFormat('dd-MM-yyyy').format(billDate)
                        : '-',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '₹${grandTotal.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStandardView(PurchaseReceive receive) {
    final bStatus = _getReceiveBillStatus(receive);
    final bColor = bStatus == 'Billed'
        ? const Color(0xFF22A95E) // Green
        : bStatus == 'Partially Billed'
        ? const Color(0xFFFF8800) // Orange
        : const Color(0xFF6B7280); // Gray

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailTabs(receive, inScrollView: true),
          _buildToggleRow(inScrollView: true),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PURCHASE RECEIVE',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Receive# ${receive.purchaseReceiveNumber}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VENDOR NAME',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    receive.vendorName?.toUpperCase() ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0088FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 64),
            ],
          ),
          const SizedBox(height: 40),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection(
                'STATUS',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusRow(
                      'Receive',
                      (_localStatus ?? receive.status).toUpperCase(),
                      _getStatusColor(_localStatus ?? receive.status),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusRow('Bill', bStatus, bColor, isLabelOnly: true),
                  ],
                ),
              ),
              const SizedBox(width: 120),
              _buildInfoSection(
                'PURCHASE ORDER#',
                InkWell(
                  onTap:
                      (receive.purchaseOrderId == null ||
                          receive.purchaseOrderId!.isEmpty)
                      ? null
                      : () {
                          final orgId = GoRouterState.of(
                            context,
                          ).pathParameters['orgSystemId']!;
                          context.go(
                            '/$orgId/purchases/purchase-orders/${receive.purchaseOrderId}',
                          );
                        },
                  child: Text(
                    receive.purchaseOrderNumber ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0088FF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 64),
              _buildInfoSection(
                'DATE',
                Text(
                  DateFormat(
                    'dd-MM-yyyy',
                  ).format(receive.receivedDate ?? DateTime.now()),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          _buildItemsTable(receive),
          const SizedBox(height: 32),
          _buildBottomDetails(receive),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomDetails(PurchaseReceive receive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.primaryBlue,
                      width: _isBatchesExpanded ? 2 : 0,
                    ),
                  ),
                ),
                child: const Text(
                  'Batches',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isBatchesExpanded) ...[
          const SizedBox(height: 16),
          ...() {
            final Map<String, (String? itemId, List<BatchInfo> batches)>
            grouped = {};
            for (var item in receive.items) {
              grouped[item.itemName] = (item.itemId, item.batches);
            }

            return grouped.entries.map((itemEntry) {
              final itemName = itemEntry.key;
              final itemId = itemEntry.value.$1;
              final batches = itemEntry.value.$2;
              final isExpanded = _expandedItems.contains(itemName);

              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() {
                      if (isExpanded) {
                        _expandedItems.remove(itemName);
                      } else {
                        _expandedItems.add(itemName);
                      }
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: (itemId == null || itemId.isEmpty)
                                ? null
                                : () async {
                                    try {
                                      final item = await ref
                                          .read(itemRepositoryProvider)
                                          .getItemById(itemId);
                                      if (item != null) {
                                        if (context.mounted) {
                                          POItemDetailsSidebar.show(
                                            context,
                                            PurchaseOrderItem(
                                              productId: item.id ?? '',
                                              productName: item.productName,
                                              itemCode:
                                                  item.sku ?? item.itemCode,
                                              productType: item.type,
                                              rate: item.costPrice ?? 0.0,
                                              accountName:
                                                  item.purchaseAccountName ??
                                                  'Cost of Goods Sold',
                                              quantity: 1.0,
                                              amount: item.costPrice ?? 0.0,
                                              trackBatches: item.trackBatches,
                                              trackSerialNumber:
                                                  item.trackSerialNumber,
                                              trackBinLocation:
                                                  item.trackBinLocation,
                                            ),
                                            vendorName: receive.vendorName,
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ZerpaiToast.error(
                                            context,
                                            'Item details not found',
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ZerpaiToast.error(
                                          context,
                                          'Error loading item: $e',
                                        );
                                      }
                                    }
                                  },
                            child: Text(
                              itemName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${batches.length} Batches',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isExpanded
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronRight,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: const Color(0xFFF9FAFB),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'BATCH DETAILS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  'QUANTITY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...batches.map((batch) {
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            batch.batchNo,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (batch.manufactureBatch.isNotEmpty)
                                            Text(
                                              'Manufacturer Batch# : ${batch.manufactureBatch}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          if (batch.manufactureDate != null)
                                            Text(
                                              'Manufactured date : ${DateFormat('dd-MM-yyyy').format(batch.manufactureDate!)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          if (batch.expiryDate != null)
                                            Text(
                                              'Expiry Date: ${DateFormat('dd-MM-yyyy').format(batch.expiryDate!)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          if (batch.binLabel != null && batch.binLabel!.isNotEmpty)
                                            Text(
                                              'Bin: ${batch.binLabel}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _fmtQty(batch.quantity + batch.foc),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (batch.foc > 0) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_fmtQty(batch.quantity)} + ${_fmtQty(batch.foc)} foc',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (batch != batches.last)
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE5E7EB),
                                  ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            }).toList();
          }(),
        ],
      ],
    );
  }

  Widget _buildInfoSection(String label, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildStatusRow(
    String label,
    String status,
    Color color, {
    bool isLabelOnly = false,
  }) {
    return Row(
      children: [
        Container(width: 2, height: 16, color: color),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
        ),
        const SizedBox(width: 24),
        if (isLabelOnly)
          Text(
            status,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              status,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemsTable(PurchaseReceive receive) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            border: Border(
              top: BorderSide(color: Color(0xFFE5E7EB)),
              bottom: BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          child: Row(
            children: const [
              SizedBox(
                width: 32,
                child: Text(
                  '#',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'ITEMS & DESCRIPTION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              SizedBox(
                width: 150,
                child: Text(
                  'QUANTITY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'BILL STATUS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
        ...receive.items.asMap().entries.map((e) {
          final i = e.value;
          final totalQty = i.batches.isNotEmpty
              ? i.batches.fold<double>(0, (sum, b) => sum + b.quantity)
              : i.quantityToReceive;
          final totalFoc = i.batches.isNotEmpty
              ? i.batches.fold<double>(0, (sum, b) => sum + b.foc)
              : 0.0;
          final displaySum = totalQty + totalFoc;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${e.key + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          LucideIcons.image,
                          size: 20,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: (i.itemId == null || i.itemId!.isEmpty)
                            ? null
                            : () async {
                                try {
                                  final item = await ref
                                      .read(itemRepositoryProvider)
                                      .getItemById(i.itemId!);
                                  if (item != null) {
                                    if (context.mounted) {
                                      POItemDetailsSidebar.show(
                                        context,
                                        PurchaseOrderItem(
                                          productId: item.id ?? '',
                                          productName: item.productName,
                                          itemCode: item.sku ?? item.itemCode,
                                          productType: item.type,
                                          rate: item.costPrice ?? 0.0,
                                          accountName:
                                              item.purchaseAccountName ??
                                              'Cost of Goods Sold',
                                          quantity: 1.0,
                                          amount: item.costPrice ?? 0.0,
                                          trackBatches: item.trackBatches,
                                          trackSerialNumber:
                                              item.trackSerialNumber,
                                          trackBinLocation:
                                              item.trackBinLocation,
                                        ),
                                        vendorName: receive.vendorName,
                                      );
                                    }
                                  } else {
                                    if (context.mounted) {
                                      ZerpaiToast.error(
                                        context,
                                        'Item details not found',
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ZerpaiToast.error(
                                      context,
                                      'Error loading item: $e',
                                    );
                                  }
                                }
                              },
                        child: Text(
                          i.itemName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0088FF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_fmtQty(displaySum)} pcs',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (totalQty > i.ordered)
                            ExtraQtyPopoverButton(
                              poNumber: i.purchaseOrderNumber ?? receive.purchaseOrderNumber ?? '',
                              ordered: i.ordered,
                              received: totalQty,
                              extra: totalQty - i.ordered,
                            ),
                        ],
                      ),
                      if (totalFoc > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '${_fmtQty(totalQty)}pcs + ${_fmtQty(totalFoc)}foc',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: () {
                    final itemBilledQty = _getItemBilledQty(receive, i.itemId);
                    return Text(
                      _fmtQty(itemBilledQty),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: itemBilledQty > 0
                            ? const Color(0xFF22A95E)
                            : const Color(0xFF6B7280),
                      ),
                    );
                  }(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildToggleRow({bool inScrollView = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: inScrollView ? 0 : 32,
        vertical: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Show PDF View',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _showPdfView,
              onChanged: (val) => setState(() => _showPdfView = val),
              activeTrackColor: const Color(0xFF0088FF),
              activeThumbColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSidebar(PurchaseReceive receive) {
    final List<_HistoryEvent> events = [];
    final user = ref.read(authUserProvider);
    final currentUsername = user?.fullName ?? user?.email.split('@').first ?? 'system';

    events.add(
      _HistoryEvent(
        username: currentUsername,
        time: receive.createdAt ?? receive.receivedDate ?? DateTime.now(),
        content: 'Purchase Receive ${receive.purchaseReceiveNumber} created',
        icon: LucideIcons.fileSpreadsheet,
      ),
    );

    for (final a in _receiveAttachments) {
      final uploadedAtStr = a['uploaded_at']?.toString();
      final dt = uploadedAtStr != null ? DateTime.tryParse(uploadedAtStr) : null;
      events.add(
        _HistoryEvent(
          username: currentUsername,
          time: dt ?? receive.createdAt ?? receive.receivedDate ?? DateTime.now(),
          content: 'Attachment modified',
          icon: LucideIcons.fileText,
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
}

class _PurchaseReceivePdfView extends ConsumerStatefulWidget {
  final PurchaseReceive receive;
  final String billStatus;
  const _PurchaseReceivePdfView({
    required this.receive,
    required this.billStatus,
  });

  @override
  ConsumerState<_PurchaseReceivePdfView> createState() =>
      _PurchaseReceivePdfViewState();
}

class _PurchaseReceivePdfViewState
    extends ConsumerState<_PurchaseReceivePdfView> {
  final Set<String> _expandedItems = {};
  bool _isBatchesExpanded = true;

  String _fmtQty(double value) {
    final intVal = value.toInt();
    return value == intVal ? intVal.toString() : value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final receivesAsync = ref.watch(purchaseReceivesProvider);
    final receiveFromList = receivesAsync.whenOrNull(
      data: (state) =>
          state.receives.where((r) => r.id == widget.receive.id).firstOrNull,
    );
    final status = receiveFromList?.status ?? widget.receive.status;

    final bStatusStr = widget.billStatus.toUpperCase();
    final Color bColor;
    if (bStatusStr == 'BILLED' || bStatusStr == 'FULL') {
      bColor = const Color(0xFF22A95E); // Green
    } else if (bStatusStr == 'PARTIALLY BILLED' || bStatusStr == 'PARTIAL') {
      bColor = const Color(0xFFFF8800); // Orange
    } else {
      bColor = const Color(0xFF6B7280); // Gray
    }

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 260, right: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          const TextSpan(
                            text: 'Receive Status : ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          TextSpan(
                            text: status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const TextSpan(
                            text: '  Bill Status : ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          TextSpan(
                            text: bStatusStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: bColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 800,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRect(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        child: _PdfCornerRibbon(
                          label: status,
                          color: _getPdfStatusColor(status),
                        ),
                      ),
                      Column(
                        children: [
                          _buildPdfHeader(orgSettings),
                          _buildPdfContent(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (widget.receive.notes != null &&
                  widget.receive.notes!.isNotEmpty) ...[
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Receive Notes',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          LucideIcons.paperclip,
                          size: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.receive.notes!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _buildBottomDetails(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfHeader(OrgSettings? orgSettings) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              _buildPdfLogo(orgSettings),
              const SizedBox(height: 16),
              Text(
                orgSettings?.name.trim().isNotEmpty == true
                    ? orgSettings!.name.trim().toUpperCase()
                    : 'YOUR COMPANY NAME',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'PURCHASE RECEIVE',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Receive# ${widget.receive.purchaseReceiveNumber}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPdfLogo(OrgSettings? orgSettings) {
    final logoUrl = orgSettings?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: 140,
        height: 60,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _pdfLogoFallback(),
        ),
      );
    }
    return _pdfLogoFallback();
  }

  Widget _pdfLogoFallback() {
    return Container(
      width: 140,
      height: 60,
      color: const Color(0xFF101820),
      child: const Center(
        child: Text(
          'LOGO',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Color _getPdfStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'RECEIVED':
        return const Color(0xFF1E8E3E);
      case 'DRAFT':
        return const Color(0xFF78909C);
      case 'IN TRANSIT':
        return const Color(0xFFFF8800);
      default:
        return const Color(0xFFC4C4C4);
    }
  }

  Widget _buildPdfContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildInfo('Receive#', widget.receive.purchaseReceiveNumber),
              _buildInfo(
                'Receive Date',
                widget.receive.receivedDate != null
                    ? DateFormat(
                        'dd-MM-yyyy',
                      ).format(widget.receive.receivedDate!)
                    : '-',
              ),
              _buildInfo('Vendor', widget.receive.vendorName ?? '-'),
              _buildInfo(
                'Purchase Order#',
                widget.receive.purchaseOrderNumber ?? '-',
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildItemsTable(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildBottomDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.primaryBlue,
                      width: _isBatchesExpanded ? 2 : 0,
                    ),
                  ),
                ),
                child: const Text(
                  'Batches',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isBatchesExpanded) ...[
          const SizedBox(height: 16),
          ...() {
            final Map<String, (String? itemId, List<BatchInfo> batches)>
            grouped = {};
            for (var item in widget.receive.items) {
              grouped[item.itemName] = (item.itemId, item.batches);
            }

            return grouped.entries.map((itemEntry) {
              final itemName = itemEntry.key;
              final itemId = itemEntry.value.$1;
              final batches = itemEntry.value.$2;
              final isExpanded = _expandedItems.contains(itemName);

              return Column(
                children: [
                  InkWell(
                    onTap: () => setState(() {
                      if (isExpanded) {
                        _expandedItems.remove(itemName);
                      } else {
                        _expandedItems.add(itemName);
                      }
                    }),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: (itemId == null || itemId.isEmpty)
                                ? null
                                : () async {
                                    try {
                                      final item = await ref
                                          .read(itemRepositoryProvider)
                                          .getItemById(itemId);
                                      if (item != null) {
                                        if (context.mounted) {
                                          POItemDetailsSidebar.show(
                                            context,
                                            PurchaseOrderItem(
                                              productId: item.id ?? '',
                                              productName: item.productName,
                                              itemCode:
                                                  item.sku ?? item.itemCode,
                                              productType: item.type,
                                              rate: item.costPrice ?? 0.0,
                                              accountName:
                                                  item.purchaseAccountName ??
                                                  'Cost of Goods Sold',
                                              quantity: 1.0,
                                              amount: item.costPrice ?? 0.0,
                                              trackBatches: item.trackBatches,
                                              trackSerialNumber:
                                                  item.trackSerialNumber,
                                              trackBinLocation:
                                                  item.trackBinLocation,
                                            ),
                                            vendorName:
                                                widget.receive.vendorName,
                                          );
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ZerpaiToast.error(
                                            context,
                                            'Item details not found',
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ZerpaiToast.error(
                                          context,
                                          'Error loading item: $e',
                                        );
                                      }
                                    }
                                  },
                            child: Text(
                              itemName.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${batches.length} Batches',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isExpanded
                                  ? LucideIcons.chevronUp
                                  : LucideIcons.chevronRight,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            color: const Color(0xFFF9FAFB),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  'BATCH DETAILS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                Text(
                                  'QUANTITY',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...batches.map((batch) {
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            batch.batchNo,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          if (batch.manufactureBatch.isNotEmpty)
                                            Text(
                                              'Manufacturer Batch# : ${batch.manufactureBatch}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          if (batch.manufactureDate != null)
                                            Text(
                                              'Manufactured date : ${DateFormat('dd-MM-yyyy').format(batch.manufactureDate!)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          if (batch.expiryDate != null)
                                            Text(
                                              'Expiry Date: ${DateFormat('dd-MM-yyyy').format(batch.expiryDate!)}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          if (batch.binLabel != null && batch.binLabel!.isNotEmpty)
                                            Text(
                                              'Bin: ${batch.binLabel}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _fmtQty(batch.quantity + batch.foc),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (batch.foc > 0) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${_fmtQty(batch.quantity)} + ${_fmtQty(batch.foc)} foc',
                                              style: const TextStyle(
                                                fontSize: 10,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (batch != batches.last)
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFE5E7EB),
                                  ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              );
            }).toList();
          }(),
        ],
      ],
    );
  }

  Widget _buildInfo(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsTable() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: const Color(0xFF1F2937),
            child: Row(
              children: const [
                SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: Text(
                    '#',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Text(
                    'Item & Description',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'HSN/SAC',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Received Qty',
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(widget.receive.items.length, (index) {
            final item = widget.receive.items[index];
            final totalQty = item.batches.isNotEmpty
                ? item.batches.fold<double>(0, (sum, b) => sum + b.quantity)
                : item.quantityToReceive;
            final totalFoc = item.batches.isNotEmpty
                ? item.batches.fold<double>(0, (sum, b) => sum + b.foc)
                : 0.0;
            final displaySum = totalQty + totalFoc;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                children: [
                  SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: Text(
                      (index + 1).toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      item.itemName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.batches.isNotEmpty
                          ? (item.batches.first.hsnCode ?? '30045037')
                          : '30045037',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_fmtQty(displaySum)} pcs',
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (totalFoc > 0)
                          Text(
                            '${_fmtQty(totalQty)}pcs + ${_fmtQty(totalFoc)}foc',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                      ],
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

class _ReceiveAttachmentOverlayContent extends StatefulWidget {
  final PurchaseReceive receive;
  final WidgetRef ref;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  const _ReceiveAttachmentOverlayContent({
    required this.receive,
    required this.ref,
    required this.onRefresh,
    required this.onClose,
  });

  @override
  State<_ReceiveAttachmentOverlayContent> createState() =>
      _ReceiveAttachmentOverlayContentState();
}

class _ReceiveAttachmentOverlayContentState extends State<_ReceiveAttachmentOverlayContent> {
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
          .from('purchase_receive_attachments')
          .select('id,file_name,file_path,file_size,file_type,uploaded_at')
          .eq('purchase_receive_id', widget.receive.id ?? '')
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
            'prefix': 'purchase_receives',
          },
        );

        final fileKey =
            response.data['fileKey'] ?? 'purchase_receives/${file.name}';

        final double sizeInKb = file.size / 1024;
        final String formattedSize = sizeInKb >= 1024
            ? '${(sizeInKb / 1024).toStringAsFixed(2)} MB'
            : '${sizeInKb.toStringAsFixed(2)} KB';

        // Save to DB
        await supabase.from('purchase_receive_attachments').insert({
          'purchase_receive_id': widget.receive.id,
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
      widget.ref.invalidate(purchaseReceiveByIdProvider(widget.receive.id ?? ''));
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

      await supabase.from('purchase_receive_attachments').delete().eq('id', id);

      await _loadAttachments();
      widget.ref.invalidate(purchaseReceiveByIdProvider(widget.receive.id ?? ''));
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

class ExtraQtyPopoverButton extends StatefulWidget {
  final String poNumber;
  final double ordered;
  final double received;
  final double extra;

  const ExtraQtyPopoverButton({
    Key? key,
    required this.poNumber,
    required this.ordered,
    required this.received,
    required this.extra,
  }) : super(key: key);

  @override
  State<ExtraQtyPopoverButton> createState() => _ExtraQtyPopoverButtonState();
}

class _ExtraQtyPopoverButtonState extends State<ExtraQtyPopoverButton> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void dispose() {
    _closePopover();
    super.dispose();
  }

  void _closePopover() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _togglePopover() {
    if (_overlayEntry != null) {
      _closePopover();
    } else {
      _showPopover();
    }
  }

  void _showPopover() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePopover,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 0),
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: CustomPaint(
                      size: const Size(12, 8),
                      painter: ArrowPainter(
                        color: Colors.white,
                        borderColor: const Color(0xFFE5E7EB),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -1),
                    child: Container(
                      width: 320,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Extra Quantity Details',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Inter',
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.x, size: 14, color: Colors.red),
                                onPressed: _closePopover,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 8),
                          Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2.0),
                              1: FlexColumnWidth(1.2),
                              2: FlexColumnWidth(1.2),
                              3: FlexColumnWidth(1.2),
                            },
                            children: [
                              const TableRow(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text('po number', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, fontFamily: 'Inter', color: Color(0xFF6B7280))),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text('ordered', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, fontFamily: 'Inter', color: Color(0xFF6B7280))),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text('received', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, fontFamily: 'Inter', color: Color(0xFF6B7280))),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 6),
                                    child: Text('extra', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, fontFamily: 'Inter', color: Color(0xFF6B7280))),
                                  ),
                                ],
                              ),
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      widget.poNumber,
                                      style: const TextStyle(fontSize: 11, fontFamily: 'Inter', color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      widget.ordered == widget.ordered.roundToDouble() ? widget.ordered.toInt().toString() : widget.ordered.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 11, fontFamily: 'Inter', color: Color(0xFF374151)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      widget.received == widget.received.roundToDouble() ? widget.received.toInt().toString() : widget.received.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 11, fontFamily: 'Inter', color: Color(0xFF374151)),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      widget.extra == widget.extra.roundToDouble() ? widget.extra.toInt().toString() : widget.extra.toStringAsFixed(2),
                                      style: const TextStyle(fontSize: 11, fontFamily: 'Inter', color: Colors.red, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
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
    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _togglePopover,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(
            LucideIcons.info,
            size: 15,
            color: Color(0xFF2A95BF),
          ),
        ),
      ),
    );
  }
}

class ArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;

  ArrowPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

    final borderPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, 0)
      ..lineTo(size.width, size.height);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ExtraQuantityDialog extends ConsumerStatefulWidget {
  final List<PurchaseReceive> receives;

  const _ExtraQuantityDialog({required this.receives});

  @override
  ConsumerState<_ExtraQuantityDialog> createState() => _ExtraQuantityDialogState();
}

class _ExtraQuantityDialogState extends ConsumerState<_ExtraQuantityDialog> {
  late final Future<List<_ExtraQuantityRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _loadExtraQuantities();
  }

  Future<List<_ExtraQuantityRecord>> _loadExtraQuantities() async {
    final prRepository = ref.read(purchaseReceiveRepositoryProvider);
    final warehousesAsync = ref.read(allWarehousesProvider);
    final warehouses = warehousesAsync.asData?.value ?? [];

    final List<_ExtraQuantityRecord> records = [];

    for (final receiveSummary in widget.receives) {
      if (receiveSummary.id == null) continue;
      final receive = await prRepository.getPurchaseReceive(receiveSummary.id!);
      if (receive == null) continue;

      final whName = warehouses.firstWhere(
        (w) => w['id']?.toString() == receive.warehouseId,
        orElse: () => <String, dynamic>{},
      )['name']?.toString() ?? '-';

      for (final receiveItem in receive.items) {
        if (receiveItem.itemId == null) continue;

        final double totalQty = receiveItem.batches.isNotEmpty
            ? receiveItem.batches.fold<double>(0, (sum, b) => sum + b.quantity)
            : receiveItem.quantityToReceive;

        if (totalQty > receiveItem.ordered) {
          records.add(_ExtraQuantityRecord(
            date: receive.receivedDate ?? receive.createdAt ?? DateTime.now(),
            itemName: receiveItem.itemName,
            purchaseOrderNumber: receive.purchaseOrderNumber ?? '-',
            purchaseReceiveNumber: receive.purchaseReceiveNumber,
            vendorName: receive.vendorName ?? '-',
            warehouseName: whName,
            quantity: totalQty - receiveItem.ordered,
          ));
        }
      }
    }
    return records;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Extra Quantity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            FutureBuilder<List<_ExtraQuantityRecord>>(
              future: _recordsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: ZTableSkeleton(
                        rows: 3,
                        columns: 6,
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppTheme.errorRed)),
                  );
                }

                final records = snapshot.data ?? [];

                return ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 450),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          color: AppTheme.bgLight,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: const Row(
                            children: [
                              Expanded(flex: 2, child: Text('DATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary))),
                              Expanded(flex: 3, child: Text('ITEM NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary))),
                              Expanded(flex: 2, child: Text('PURCHASE ORDER', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary))),
                              Expanded(flex: 3, child: Text('VENDOR NAME', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary))),
                              Expanded(flex: 2, child: Text('WAREHOUSE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary))),
                              SizedBox(width: 80, child: Text('QUANTITY', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppTheme.textSecondary))),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppTheme.borderColor),
                        if (records.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'No extra quantity records found.',
                                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                              ),
                            ),
                          )
                        else
                          // Table Rows
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: records.length,
                            separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderColor),
                            itemBuilder: (context, index) {
                              final r = records[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text(DateFormat('dd-MM-yyyy').format(r.date), style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
                                    Expanded(flex: 3, child: Text(r.itemName, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            r.purchaseOrderNumber,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.primaryBlue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (r.purchaseReceiveNumber != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              r.purchaseReceiveNumber!,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Expanded(flex: 3, child: Text(r.vendorName, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
                                    Expanded(flex: 2, child: Text(r.warehouseName, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary))),
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        r.quantity == r.quantity.roundToDouble()
                                            ? r.quantity.toInt().toString()
                                            : r.quantity.toStringAsFixed(2),
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Divider(height: 1, color: AppTheme.borderColor),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ZButton.secondary(
                    label: 'Close',
                    onPressed: () => Navigator.pop(context),
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

class _ExtraQuantityRecord {
  final DateTime date;
  final String itemName;
  final String purchaseOrderNumber;
  final String? purchaseReceiveNumber;
  final String vendorName;
  final String warehouseName;
  final double quantity;

  _ExtraQuantityRecord({
    required this.date,
    required this.itemName,
    required this.purchaseOrderNumber,
    this.purchaseReceiveNumber,
    required this.vendorName,
    required this.warehouseName,
    required this.quantity,
  });
}
