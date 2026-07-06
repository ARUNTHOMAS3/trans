// ignore_for_file: unused_import, unused_field
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:dio/dio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/z_button.dart';
import '../../../../../shared/widgets/zerpai_layout.dart';
import '../../../../../shared/widgets/tables/table_header_menu.dart';
import '../../../../../shared/widgets/tables/table_more_menu.dart';
import '../../../../../shared/widgets/skeleton.dart';
import '../../providers/purchases_bills_provider.dart';
import '../../repositories/purchases_bills_repository.dart';
import '../../models/purchases_bills_bill_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../shared/models/column_config.dart';
import '../../../../../shared/widgets/tables/column_customizer.dart';
import '../../../../../shared/widgets/inputs/dropdown_input.dart';
import '../../../../../shared/widgets/inputs/custom_text_field.dart';
import '../../../../../shared/widgets/inputs/shared_field_layout.dart';
import '../../../../../shared/widgets/inputs/z_date_picker_field.dart';
import '../../../../../shared/widgets/inputs/zerpai_date_picker.dart';
import '../../../../../shared/widgets/inputs/zerpai_radio_group.dart';
import '../../../../../shared/widgets/inputs/z_tooltip.dart';
import '../../../../../shared/providers/lookup_providers.dart';
import '../../../../../app/providers/org_settings_provider.dart';
import '../../../../../core/models/org_settings_model.dart';
import '../../../../../shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/providers/purchase_receives_provider.dart';
import 'package:zerpai_erp/modules/purchases/purchase_receives/models/purchases_purchase_receives_model.dart';
import 'package:zerpai_erp/modules/purchases/purchase_orders/providers/purchases_purchase_orders_provider.dart' hide warehousesProvider;
import 'package:zerpai_erp/modules/purchases/purchase_orders/models/purchases_purchase_orders_order_model.dart';
import 'package:zerpai_erp/modules/inventory/providers/warehouse_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:web/web.dart' as web;
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';

class _ClearBillsSelectionIntent extends Intent {
  const _ClearBillsSelectionIntent();
}

// ─── View filter options ────────────────────────────────────────────────────

const _billFilterOptions = <FavoriteFilterOption>[
  FavoriteFilterOption(label: 'All', value: 'all'),
  FavoriteFilterOption(label: 'Draft', value: 'draft'),
  FavoriteFilterOption(label: 'Pending Approval', value: 'pending_approval'),
  FavoriteFilterOption(label: 'Open', value: 'open'),
  FavoriteFilterOption(label: 'Overdue', value: 'overdue'),
  FavoriteFilterOption(label: 'Unpaid', value: 'unpaid'),
  FavoriteFilterOption(label: 'Partially Paid', value: 'partially_paid'),
  FavoriteFilterOption(label: 'Paid', value: 'paid'),
  FavoriteFilterOption(label: 'Void', value: 'void'),
  FavoriteFilterOption(label: 'Yet To Be Received', value: 'yet_to_be_received'),
  FavoriteFilterOption(label: 'Received', value: 'received'),
  FavoriteFilterOption(label: 'MSME Vendor Bills Unpaid for 40+ Days', value: 'msme_unpaid_40'),
];

// ─── Main screen ────────────────────────────────────────────────────────────

class PurchasesBillsListScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;
  final String? initialSelectedId;
  final String? initialFilter;

  const PurchasesBillsListScreen({
    super.key,
    this.initialSearchQuery,
    this.initialSelectedId,
    this.initialFilter,
  });

  @override
  ConsumerState<PurchasesBillsListScreen> createState() =>
      _PurchasesBillsListScreenState();
}

class _PurchasesBillsListScreenState
    extends ConsumerState<PurchasesBillsListScreen> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  final Set<String> _selectedIds = {};
  String _searchQuery = '';
  String _sortField = 'bill_date';
  bool _sortAscending = false;
  bool _shouldWrapText = false;
  FavoriteFilterOption _activeOption = _billFilterOptions.first;
  Map<String, double>? _customColumnWidths;
  final ScrollController _horizontalScrollController = ScrollController();
  bool _showPdfView = false;
  String? _showPaymentFormForId;
  final Set<String> _expandedBatchesItems = {};
  bool _isBatchesExpanded = true;
  String _bottomActiveTab = 'batches';
  bool _showCalendarView = false;
  DateTime _calendarMonth = DateTime(2026, 6);

  bool _showCommentsSidebar = false;
  final LayerLink _attachmentBadgeLink = LayerLink();
  OverlayEntry? _attachmentListOverlay;
  List<Map<String, dynamic>> _billAttachments = [];
  bool _isLoadingAttachments = false;
  String? _lastLoadedBillId;

  List<ColumnConfig> _allColumns = [];
  final List<String> _visibleColumns = [];

  final Map<String, String> _columnLabels = {
    'date': 'DATE',
    'location': 'WAREHOUSE',
    'bill_number': 'BILL#',
    'order_number': 'REFERENCE NUMBER',
    'vendor_name': 'VENDOR NAME',
    'status': 'STATUS',
    'due_date': 'DUE DATE',
    'amount': 'AMOUNT',
    'balance_due': 'BALANCE DUE',
  };

  void _initializeColumns() {
    _allColumns = [
      ColumnConfig(id: 'date', label: 'DATE', orderIndex: 0),
      ColumnConfig(
        id: 'location',
        label: 'WAREHOUSE',
        orderIndex: 1,
        isVisible: true,
      ),
      ColumnConfig(id: 'bill_number', label: 'BILL#', orderIndex: 2),
      ColumnConfig(
        id: 'order_number',
        label: 'REFERENCE NUMBER',
        orderIndex: 3,
        isVisible: true,
      ),
      ColumnConfig(id: 'vendor_name', label: 'VENDOR NAME', orderIndex: 4),
      ColumnConfig(id: 'status', label: 'STATUS', orderIndex: 5),
      ColumnConfig(id: 'due_date', label: 'DUE DATE', orderIndex: 6),
      ColumnConfig(id: 'amount', label: 'AMOUNT', orderIndex: 7),
      ColumnConfig(id: 'balance_due', label: 'BALANCE DUE', orderIndex: 8),
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
      final jsonStr = prefs.getString('bills_table_columns_config');
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
      await prefs.setString('bills_table_columns_config', jsonStr);
    } catch (e) {
      debugPrint('Error saving column settings: $e');
    }
  }

  Future<void> _loadBillAttachments(String billId) async {
    if (!mounted) return;
    setState(() {
      _isLoadingAttachments = true;
    });
    try {
      final supabase = Supabase.instance.client;
      final res = await supabase
          .from('bill_attachments')
          .select('id, file_name, file_url, file_size, file_type, created_at')
          .eq('bill_id', billId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _billAttachments = (res as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _isLoadingAttachments = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading bill attachments: $e');
      if (mounted) {
        setState(() {
          _isLoadingAttachments = false;
        });
      }
    }
  }

  void _toggleAttachmentListOverlay(PurchasesBill bill) {
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
              child: _BillAttachmentOverlayContent(
                bill: bill,
                ref: ref,
                onRefresh: () => _loadBillAttachments(bill.id),
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(billsProvider);
      ref.invalidate(warehousesProvider);
    });
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
      final found = _billFilterOptions.where(
        (v) => v.label.toLowerCase() == widget.initialFilter!.toLowerCase(),
      );
      if (found.isNotEmpty) {
        _activeOption = found.first;
      }
    }
    // Load bills
    Future.microtask(() => ref.read(billsProvider.notifier).loadBills());
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
    final state = ref.watch(billsProvider);

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.escape):
            const _ClearBillsSelectionIntent(),
      },
      child: Actions(
        actions: {
          _ClearBillsSelectionIntent:
              CallbackAction<_ClearBillsSelectionIntent>(
                onInvoke: (intent) {
                  setState(() => _selectedIds.clear());
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
            searchFocusNode: _searchFocusNode,
            child: state.isLoading && state.bills.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: TableSkeleton(rows: 10, columns: 6),
                  )
                : state.error != null && state.bills.isEmpty
                ? _buildErrorWidget(state.error!)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final filtered = _applyFilters(state.bills);
                      final sorted = _getSortedList(filtered);
                      final compact = constraints.maxWidth < 1100;
                      final hasSelection = widget.initialSelectedId != null;

                      return Column(
                        children: [
                          if (!hasSelection) ...[
                            _selectedIds.isNotEmpty
                                ? _selectionToolbar()
                                : _buildMainToolbar(
                                    context,
                                    hasSelection,
                                    sorted,
                                  ),
                            const Divider(
                              height: 1,
                              color: AppTheme.borderLight,
                            ),
                          ],
                          Expanded(
                            child: _showCalendarView
                                ? _buildCalendarView(sorted)
                                : state.bills.isEmpty
                                ? _buildEmptyState()
                                : filtered.isEmpty
                                ? _buildNoMatchingState()
                                : hasSelection
                                ? _workspace(sorted, state.bills, compact)
                                : _buildTableView(sorted),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Widget _workspace(
    List<PurchasesBill> filteredBills,
    List<PurchasesBill> allBills,
    bool compact,
  ) {
    final billId = widget.initialSelectedId!;
    final summary = allBills.cast<PurchasesBill?>().firstWhere(
      (bill) => bill?.id == billId,
      orElse: () => null,
    );

    if (compact) {
      return _detailPane(billId, summary);
    }

    return Row(
      children: [
        SizedBox(width: 360, child: _selectionList(filteredBills, billId)),
        const VerticalDivider(
          width: 1,
          thickness: 1,
          color: AppTheme.borderLight,
        ),
        Expanded(child: _detailPane(billId, summary)),
      ],
    );
  }

  Widget _selectionList(List<PurchasesBill> bills, String selectedId) {
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
                      moduleName: 'bills',
                      options: _billFilterOptions,
                      selectedOption: _activeOption,
                      onChanged: (opt) {
                        setState(() {
                          _activeOption = opt;
                        });
                      },
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => context.go('/purchases/bills/create'),
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
            itemCount: bills.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final bill = bills[index];
              final selected = bill.id == selectedId;
              return InkWell(
                onTap: () => context.go('/purchases/bills/${bill.id}'),
                child: Container(
                  color: selected ? AppTheme.selectionActiveBg : Colors.white,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: _buildCheckboxWidget(
                          _selectedIds.contains(bill.id),
                          onTap: () {
                            setState(() {
                              if (_selectedIds.contains(bill.id)) {
                                _selectedIds.remove(bill.id);
                              } else {
                                _selectedIds.add(bill.id);
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
                                    bill.vendorName,
                                    style: AppTheme.bodyText.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '₹${bill.total.toStringAsFixed(2)}',
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
                                    bill.billNumber ?? '-',
                                    style: AppTheme.metaHelper.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                Text(
                                  bill.billDate != null
                                      ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(bill.billDate!)
                                      : '-',
                                  style: AppTheme.metaHelper,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            _buildStatusBadge(bill.status),
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
              _bulkActionMenuItem('Mark as Open', 'Mark as Open'),
              _bulkActionMenuItem('Record Payment', 'Record Payment'),
              _bulkActionMenuItem('Export as PDF', 'PDF export'),
              _bulkActionMenuItem('Print', 'Print'),
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
        if (isActive) return const Color(0xFF3B82F6);
        if (highlighted) {
          return const Color(0xFF3B82F6);
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

  Widget _detailPane(String billId, PurchasesBill? summary) {
    final detailAsync = ref.watch(purchaseBillProvider(billId));
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
            Text('Unable to load bill details', style: AppTheme.sectionHeader),
            const SizedBox(height: 8),
            Text('$error', style: AppTheme.metaHelper),
          ],
        ),
      ),
      data: (bill) {
        if (_lastLoadedBillId != bill.id) {
          _lastLoadedBillId = bill.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadBillAttachments(bill.id);
          });
        }
        if (_showPaymentFormForId == bill.id) {
          return _PurchasesBillPaymentForm(
            bill: bill,
            onCancel: () => setState(() => _showPaymentFormForId = null),
            onSaveSuccess: () {
              setState(() => _showPaymentFormForId = null);
              ZerpaiToast.success(context, 'Payment recorded successfully');
            },
          );
        }
        return StatefulBuilder(
          builder: (context, setInnerState) {
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
                            'Vendor: ${bill.vendorName}',
                            style: AppTheme.metaHelper.copyWith(fontSize: 12),
                          ),
                          const Spacer(),
                          CompositedTransformTarget(
                            link: _attachmentBadgeLink,
                            child: InkWell(
                              onTap: () => _toggleAttachmentListOverlay(bill),
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
                                    if (_billAttachments.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_billAttachments.length}',
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
                                _showCommentsSidebar = !_showCommentsSidebar;
                              });
                              setState(() {});
                            },
                          ),
                          const SizedBox(width: 8),
                          _ActionSquare(
                            icon: LucideIcons.x,
                            color: AppTheme.errorRed,
                            onTap: () => context.go('/purchases/bills'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            bill.billNumber ?? 'Bill',
                            style: AppTheme.sectionHeader.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
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
                      if (bill.status.toLowerCase() == 'void') ...[
                        _buildPdfPrintDropdown(bill),
                        _buildDivider(),
                        _buildToolbarButton(
                          LucideIcons.rotateCcw,
                          'Convert to Draft',
                          onPressed: () {
                            _showReasonDialog(context, bill, 'draft');
                          },
                        ),
                        _buildDivider(),
                        _buildMoreButton(bill),
                      ] else if (bill.status.toLowerCase() == 'draft') ...[
                        _buildToolbarButton(
                          LucideIcons.pencil,
                          'Edit',
                          onPressed: () {
                            context.go(
                              '/purchases/bills/create?editId=${bill.id}',
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildPdfPrintDropdown(bill),
                        _buildDivider(),
                        _buildToolbarButton(
                          LucideIcons.fileCheck,
                          'Convert to Open',
                          onPressed: () {
                            _handleConvertBillToOpen(bill);
                          },
                        ),
                        _buildDivider(),
                        _buildToolbarButton(
                          LucideIcons.wallet,
                          'Record Payment',
                          onPressed: () {
                            setState(() {
                              _showPaymentFormForId = bill.id;
                            });
                          },
                        ),
                        _buildDivider(),
                        _buildMoreButton(bill),
                      ] else ...[
                        _buildToolbarButton(
                          LucideIcons.pencil,
                          'Edit',
                          onPressed: () {
                            context.go(
                              '/purchases/bills/create?editId=${bill.id}',
                            );
                          },
                        ),
                        _buildDivider(),
                        _buildPdfPrintDropdown(bill),
                        if (bill.status.toLowerCase() != 'paid' &&
                            bill.status.toLowerCase() != 'void') ...[
                          _buildDivider(),
                          _buildToolbarButton(
                            LucideIcons.wallet,
                            'Record Payment',
                            onPressed: () {
                              setState(() {
                                _showPaymentFormForId = bill.id;
                              });
                            },
                          ),
                        ],
                        _buildDivider(),
                        _buildMoreButton(bill),
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
                        if (bill.status.toLowerCase() == 'draft') ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
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
                                    text: const TextSpan(
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 13,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'WHAT\'S NEXT? ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              'Approve or mark this bill as Open to start tracking payments.',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  height: 32,
                                  child: ZButton.primary(
                                    label: 'Mark as Open',
                                    onPressed: () async {
                                      try {
                                        final supabase =
                                            Supabase.instance.client;
                                        await supabase
                                            .from('bills')
                                            .update({'status': 'open'})
                                            .eq('id', bill.id);

                                        ref
                                            .read(apiClientProvider)
                                            .clearCache('bills');

                                        ref.invalidate(
                                          purchaseBillProvider(bill.id),
                                        );
                                        ref
                                            .read(billsProvider.notifier)
                                            .loadBills();

                                        if (context.mounted) {
                                          ZerpaiToast.success(
                                            context,
                                            'Bill marked as Open',
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
                        ] else if (bill.status.toLowerCase() == 'open' ||
                            bill.status.toLowerCase() == 'overdue' ||
                            bill.status.toLowerCase() == 'partially_paid') ...[
                          _detailBanners(bill),
                          const SizedBox(height: 16),
                        ],
                        Row(
                          children: [
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
                              ? _a4SimulatedBill(bill)
                              : _overviewCard(bill),
                        ),
                        const SizedBox(height: 24),
                        _buildBottomDetails(bill, setInnerState),
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
                  _buildCommentsSidebar(bill),
                ],
              );
            } else {
              return detailContent;
            }
          },
        );
      },
    );
  }

  Widget _overviewCard(PurchasesBill bill) {
    return Container(
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
                      'BILL',
                      style: AppTheme.sectionHeader.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bill# ${bill.billNumber ?? '-'}',
                      style: AppTheme.bodyText.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _statusSummary(bill),
                    const SizedBox(height: 24),
                    const SizedBox(height: 24),
                    Table(
                      columnWidths: const {
                        0: FixedColumnWidth(140),
                        1: FlexColumnWidth(),
                      },
                      children: [
                        _tableRow(
                          'BILL DATE',
                          bill.billDate != null
                              ? DateFormat('dd-MM-yyyy').format(bill.billDate!)
                              : '-',
                        ),
                        _tableRow(
                          'DUE DATE',
                          bill.dueDate != null
                              ? DateFormat('dd-MM-yyyy').format(bill.dueDate!)
                              : '-',
                        ),
                        _tableRow(
                          'PAYMENT TERMS',
                          bill.paymentTerms ?? '',
                        ),
                        _tableRow(
                          'BALANCE DUE',
                          '₹${bill.total.toStringAsFixed(2)}',
                          isBoldValue: true,
                        ),
                        _tableRow(
                          'TOTAL',
                          '₹${bill.total.toStringAsFixed(2)}',
                          isBoldValue: true,
                        ),
                      ],
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
                      bill.vendorName,
                      bill.vendorAddress ?? '',
                      bill.vendorPhone ?? bill.vendorNumber,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _itemsTable(bill.lineItems),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: _totalsSummary(bill),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusSummary(PurchasesBill bill) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 3, height: 40, color: AppTheme.primaryBlue),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text('Status', style: AppTheme.bodyText)],
        ),
        const SizedBox(width: 48),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: _statusColor(bill.status),
              child: Text(
                bill.status.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return AppTheme.warningOrange;
      case 'open':
        return AppTheme.primaryBlue;
      case 'paid':
        return AppTheme.successGreen;
      case 'overdue':
        return AppTheme.errorRed;
      default:
        return AppTheme.textSecondary;
    }
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
        if (address.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            address,
            style: AppTheme.bodyText.copyWith(fontSize: 13, height: 1.5),
            textAlign: align == CrossAxisAlignment.end
                ? TextAlign.right
                : TextAlign.left,
          ),
        ],
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

  TableRow _tableRow(String label, String value, {bool isBoldValue = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: AppTheme.metaHelper.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            value,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _itemsTable(List<PurchasesBillLineItem> items) {
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
                  flex: 2,
                  child: Text(
                    'ACCOUNT',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      'QUANTITY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                Expanded(
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
                Expanded(
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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: AppTheme.borderLight),
                    ),
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
                                    item.itemName ?? 'Unnamed Item',
                                    style: AppTheme.linkText.copyWith(
                                      fontSize: 13,
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
                        child: Text(
                          item.accountName ?? 'Purchase Account',
                          style: AppTheme.bodyText.copyWith(fontSize: 13),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                (item.freeQuantity > 0
                                        ? (item.quantity + item.freeQuantity)
                                        : item.quantity)
                                    .toStringAsFixed(2),
                                style: AppTheme.bodyText.copyWith(fontSize: 13),
                              ),
                              if (item.freeQuantity > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${item.quantity == item.quantity.toInt() ? item.quantity.toInt() : item.quantity.toStringAsFixed(2)} pcs + ${item.freeQuantity == item.freeQuantity.toInt() ? item.freeQuantity.toInt() : item.freeQuantity.toStringAsFixed(2)} foc',
                                  style: AppTheme.bodyText.copyWith(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
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
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _totalsSummary(PurchasesBill bill) {
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

    final subtotal = bill.subTotal;
    final total = bill.total;
    final bool isKerala =
        bill.placeOfSupply == null ||
        bill.placeOfSupply!.toLowerCase().contains('kerala') ||
        bill.placeOfSupply!.toLowerCase().contains('[kl]');
    final double totalTaxRate = (bill.subTotal > 0)
        ? (bill.taxAmount / bill.subTotal) * 100
        : 0.0;

    return Column(
      children: [
        row('Sub Total', '₹${subtotal.toStringAsFixed(2)}', isBold: true),
        if (bill.taxAmount > 0) ...[
          if (isKerala) ...[
            (() {
              final double cgstPct = double.parse(
                (totalTaxRate / 2).toStringAsFixed(1),
              );
              final halfStr = cgstPct == cgstPct.toInt()
                  ? '${cgstPct.toInt()}'
                  : '${cgstPct.toStringAsFixed(1)}';
              final pctLabel = '$halfStr%';
              return Column(
                children: [
                  row(
                    'CGST$halfStr ($pctLabel)',
                    '₹${(bill.taxAmount / 2).toStringAsFixed(2)}',
                  ),
                  row(
                    'SGST$halfStr ($pctLabel)',
                    '₹${(bill.taxAmount / 2).toStringAsFixed(2)}',
                  ),
                ],
              );
            })(),
          ] else ...[
            (() {
              final igstLabel = totalTaxRate == totalTaxRate.toInt()
                  ? '${totalTaxRate.toInt()}%'
                  : '${totalTaxRate.toStringAsFixed(1)}%';
              return row(
                'IGST$igstLabel ($igstLabel)',
                '₹${bill.taxAmount.toStringAsFixed(2)}',
              );
            })(),
          ],
        ],
        if (bill.discountAmount > 0)
          row('Discount', '-₹${bill.discountAmount.toStringAsFixed(2)}'),
        if (bill.adjustment != 0)
          row(
            bill.adjustmentLabel ?? 'Adjustment',
            '₹${bill.adjustment.toStringAsFixed(2)}',
          ),
        const Divider(height: 24),
        row('Total', '₹${total.toStringAsFixed(2)}', isTotal: true),
      ],
    );
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

  Widget _buildMoreButton(PurchasesBill bill) {
    bool isHovered = false;
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
            menuChildren: _menuChildrenForStatus(bill),
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

  Widget _buildPdfPrintDropdown(PurchasesBill bill) {
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
          style: _menuItemStyle(),
          onPressed: () => _handlePdfPrintAction(bill, 'Download PDF'),
          child: const Text('Download PDF'),
        ),
        MenuItemButton(
          style: _menuItemStyle(),
          onPressed: () => _handlePdfPrintAction(bill, 'Print'),
          child: const Text('Print'),
        ),
      ],
    );
  }

  Future<void> _handlePdfPrintAction(PurchasesBill bill, String action) async {
    final orgSettings = ref.read(orgSettingsProvider).asData?.value;
    final fullBill = await ref.read(purchaseBillProvider(bill.id).future);
    final bytes = await _generatePdfForBill(fullBill, orgSettings);
    if (action == 'Download PDF') {
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${bill.billNumber ?? "bill"}.pdf',
      );
    } else if (action == 'Print') {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    }
  }

  Future<Uint8List> _generatePdfForBill(
    PurchasesBill bill,
    OrgSettings? org,
  ) async {
    final doc = pw.Document();

    // Load fonts to draw ₹ symbol and italic styles safely
    pw.ThemeData pdfTheme;
    try {
      final regularData = await rootBundle.load(
        'assets/fonts/Inter-Regular.ttf',
      );
      final boldData = await rootBundle.load('assets/fonts/Inter-Bold.ttf');
      final regularFont = pw.Font.ttf(regularData);
      final boldFont = pw.Font.ttf(boldData);
      pdfTheme = pw.ThemeData.withFont(base: regularFont, bold: boldFont);
    } catch (_) {
      pdfTheme = pw.ThemeData.withFont();
    }

    final billingAddress = bill.vendorAddress ?? 'N/A';
    final formattedBillingAddress = _formatAddress(billingAddress);

    // Resolve organization logo image if available
    pw.MemoryImage? logoImage;
    final logoUrl = org?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      try {
        final dio = Dio();
        final res = await dio.get(
          logoUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        if (res.data != null) {
          logoImage = pw.MemoryImage(Uint8List.fromList(res.data));
        }
      } catch (_) {}
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 40, 40, 40),
        theme: pdfTheme,
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Top Section: Company Info & Bill metadata
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (logoImage != null)
                          pw.Container(
                            width: 140,
                            height: 56,
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                          ),
                        pw.SizedBox(height: 16),
                        pw.Text(
                          org?.name.trim().isNotEmpty == true
                              ? org!.name.trim()
                              : '',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        if (org?.resolvedPaymentStubAddress
                                ?.trim()
                                .isNotEmpty ==
                            true)
                          pw.Text(
                            _formatAddress(
                              org!.resolvedPaymentStubAddress!.trim(),
                            ),
                            style: const pw.TextStyle(
                              fontSize: 10,
                              lineSpacing: 1.3,
                            ),
                          ),
                        if (org?.companyIdentityLine?.isNotEmpty == true)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4),
                            child: pw.Text(
                              org!.companyIdentityLine!,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        if (org?.phone?.isNotEmpty == true &&
                            org?.resolvedPaymentStubAddress?.contains(
                                  org.phone!,
                                ) !=
                                true)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4),
                            child: pw.Text(
                              org!.phone!,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                        if (org?.email?.isNotEmpty == true)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 4),
                            child: pw.Text(
                              org!.email!,
                              style: const pw.TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'BILL',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Bill# ${bill.billNumber ?? '-'}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'Balance Due',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '₹${bill.total.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 32),

              // Address Row: Bill From & Meta Dates
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Bill From',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.grey600,
                          ),
                        ),
                        pw.SizedBox(height: 6),
                        pw.Text(
                          bill.vendorName,
                          style: pw.TextStyle(
                            color: const PdfColor.fromInt(0xFF3B82F6),
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          formattedBillingAddress,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            lineSpacing: 1.3,
                          ),
                        ),
                        if (bill.vendorGstin != null &&
                            bill.vendorGstin!.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text(
                            bill.vendorGstin!.startsWith('GSTIN')
                                ? bill.vendorGstin!
                                : 'GSTIN ${bill.vendorGstin!}',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 30),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _pwA4MetaRow(
                          'Bill Date :',
                          bill.billDate != null
                              ? DateFormat('dd-MM-yyyy').format(bill.billDate!)
                              : '-',
                        ),
                        _pwA4MetaRow(
                          'Due Date :',
                          bill.dueDate != null
                              ? DateFormat('dd-MM-yyyy').format(bill.dueDate!)
                              : '-',
                        ),
                        _pwA4MetaRow(
                          'Terms :',
                          bill.paymentTerms ?? '',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Items Table
              _pwPdfItems(bill.lineItems),
              pw.SizedBox(height: 18),

              // Totals Block
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(width: 300, child: _pwTotals(bill)),
              ),
              pw.SizedBox(height: 34),

              // Signature Line
              pw.Row(
                children: [
                  pw.Text(
                    'Authorized Signature',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(height: 0.5, color: PdfColors.black),
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

  pw.Widget _pwA4MetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(width: 24),
          pw.Container(
            width: 100,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pwPdfItems(List<PurchasesBillLineItem> items) {
    return pw.Column(
      children: [
        // Header
        pw.Container(
          color: const PdfColor.fromInt(0xFF333333),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  '#  ITEM & DESCRIPTION',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'HSN/SAC',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  'QTY',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'RATE',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'AMOUNT',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Rows
        ...List.generate(items.length, (index) {
          final item = items[index];
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${index + 1}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              item.itemName ?? '',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            if (item.description?.isNotEmpty == true)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 2),
                                child: pw.Text(
                                  item.description!,
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColors.grey600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    item.hsnCode ?? '—',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '${item.quantity}',
                        textAlign: pw.TextAlign.right,
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.Text(
                        item.unitPack ?? 'pcs',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    item.rate.toStringAsFixed(2),
                    textAlign: pw.TextAlign.right,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    (item.quantity * item.rate).toStringAsFixed(2),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _pwTotals(PurchasesBill bill) {
    final bool isKerala =
        bill.placeOfSupply == null ||
        bill.placeOfSupply!.toLowerCase().contains('kerala') ||
        bill.placeOfSupply!.toLowerCase().contains('[kl]');
    final double totalTaxRate = (bill.subTotal > 0)
        ? (bill.taxAmount / bill.subTotal) * 100
        : 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _pwA4TotalRow('Sub Total', bill.subTotal.toStringAsFixed(2)),
        pw.SizedBox(height: 6),
        if (bill.taxAmount > 0) ...[
          if (isKerala) ...[
            (() {
              final double cgstPct = double.parse(
                (totalTaxRate / 2).toStringAsFixed(1),
              );
              final halfStr = cgstPct == cgstPct.toInt()
                  ? '${cgstPct.toInt()}'
                  : '${cgstPct.toStringAsFixed(1)}';
              final pctLabel = '$halfStr%';
              return pw.Column(
                children: [
                  _pwA4TotalRow(
                    'CGST$halfStr ($pctLabel)',
                    (bill.taxAmount / 2).toStringAsFixed(2),
                  ),
                  pw.SizedBox(height: 6),
                  _pwA4TotalRow(
                    'SGST$halfStr ($pctLabel)',
                    (bill.taxAmount / 2).toStringAsFixed(2),
                  ),
                  pw.SizedBox(height: 6),
                ],
              );
            })(),
          ] else ...[
            (() {
              final igstLabel = totalTaxRate == totalTaxRate.toInt()
                  ? '${totalTaxRate.toInt()}%'
                  : '${totalTaxRate.toStringAsFixed(1)}%';
              return pw.Column(
                children: [
                  _pwA4TotalRow(
                    'IGST$igstLabel ($igstLabel)',
                    bill.taxAmount.toStringAsFixed(2),
                  ),
                  pw.SizedBox(height: 6),
                ],
              );
            })(),
          ],
        ],
        if (bill.discountAmount > 0) ...[
          _pwA4TotalRow(
            'Discount${bill.discountPercent > 0 ? '(${bill.discountPercent.toStringAsFixed(2)}%)' : ''}',
            '-${bill.discountAmount.toStringAsFixed(2)}',
          ),
          pw.SizedBox(height: 6),
        ],
        if (bill.adjustment != 0) ...[
          _pwA4TotalRow(
            bill.adjustmentLabel ?? 'Adjustment',
            bill.adjustment.toStringAsFixed(2),
          ),
          pw.SizedBox(height: 6),
        ],
        _pwA4TotalRow(
          'Total',
          '₹${bill.total.toStringAsFixed(2)}',
          isBold: true,
        ),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const PdfColor.fromInt(0xFFF3F4F6),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Balance Due',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              pw.Text(
                '₹${bill.total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _pwA4TotalRow(String label, String value, {bool isBold = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: isBold ? PdfColors.black : PdfColors.grey800,
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
    );
  }

  List<Widget> _menuChildrenForStatus(PurchasesBill bill) {
    if (bill.status.toLowerCase() == 'void') {
      return [
        _detailActionMenuItem('Clone', bill),
        const Divider(height: 1, color: AppTheme.borderLight),
        _detailActionMenuItem('Delete', bill),
      ];
    }
    if (bill.status.toLowerCase() == 'draft') {
      return [
        _detailActionMenuItem('Void', bill),
        _detailActionMenuItem('Clone', bill),
        _detailActionMenuItem('Create Vendor Credits', bill),
        const Divider(height: 1, color: AppTheme.borderLight),
        _detailActionMenuItem('Delete', bill),
      ];
    }
    return [
      _detailActionMenuItem('Void', bill),
      _detailActionMenuItem('Expected Payment Date', bill),
      _detailActionMenuItem('Allocate Landed Cost from a Bill', bill),
      _detailActionMenuItem('Clone', bill),
      _detailActionMenuItem('Create Vendor Credits', bill),
      const Divider(height: 1, color: AppTheme.borderLight),
      _detailActionMenuItem('Delete', bill),
      _detailActionMenuItem('Undo Receive', bill),
    ];
  }

  MenuItemButton _detailActionMenuItem(String label, PurchasesBill bill) {
    return MenuItemButton(
      style: _menuItemStyle(),
      onPressed: () async {
        if (label == 'Void') {
          _showReasonDialog(context, bill, 'void');
        } else if (label == 'Expected Payment Date') {
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => ExpectedPaymentDateDialog(bill: bill),
          );
          if (result != null && context.mounted) {
            final date = result['date'] as DateTime;
            final notes = result['notes'] as String;
            try {
              final supabase = Supabase.instance.client;
              await supabase
                  .from('bills')
                  .update({
                    'notes':
                        '[Expected Payment: ${DateFormat('dd-MM-yyyy').format(date)}] $notes',
                  })
                  .eq('id', bill.id);

              ref.read(apiClientProvider).clearCache('bills');

              ref.invalidate(purchaseBillProvider(bill.id));
              ref.read(billsProvider.notifier).loadBills();
              ZerpaiToast.success(
                context,
                'Expected payment date updated successfully',
              );
            } catch (e) {
              ZerpaiToast.error(
                context,
                'Failed to update expected payment date: $e',
              );
            }
          }
        } else if (label == 'Clone') {
          context.push('/purchases/bills/create?cloneId=${bill.id}');
        } else if (label == 'Create Vendor Credits') {
          context.push('/purchases/vendor-credits/create?billId=${bill.id}');
        } else if (label == 'Delete') {
          final confirmed = await showZerpaiConfirmationDialog(
            context,
            title: 'Delete Bill',
            message: 'Are you sure you want to delete this bill?',
            confirmLabel: 'Delete',
            cancelLabel: 'Cancel',
            variant: ZerpaiConfirmationVariant.danger,
          );
          if (!confirmed) return;
          try {
            final supabase = Supabase.instance.client;
            final originalNumber = bill.billNumber;
            final newNumber = originalNumber != null ? (originalNumber.startsWith('SD-') ? originalNumber : 'SD-$originalNumber') : null;
            await supabase
                .from('bills')
                .update({
                  'is_delete': true,
                  if (newNumber != null) 'bill_number': newNumber,
                })
                .eq('id', bill.id);

            ref.read(apiClientProvider).clearCache('bills');

            ref.read(billsProvider.notifier).loadBills();
            if (context.mounted) {
              ZerpaiToast.success(context, 'Bill deleted successfully');
              context.go('/purchases/bills');
            }
          } catch (e) {
            if (context.mounted) {
              ZerpaiToast.error(context, 'Failed to delete bill: $e');
            }
          }
        } else {
          ZerpaiToast.success(context, '$label applied successfully');
        }
      },
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTheme.bodyText.fontFamily,
          fontSize: AppTheme.bodyText.fontSize,
          fontWeight: AppTheme.bodyText.fontWeight,
        ),
      ),
    );
  }

  // ─── Filters & Sorting ──────────────────────────────────────────────────

  List<PurchasesBill> _applyFilters(List<PurchasesBill> bills) {
    var result = bills;

    if (_activeOption.value != 'all') {
      result = result
          .where(
            (b) =>
                b.status.toLowerCase() == _activeOption.value.toLowerCase(),
          )
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((b) {
        return (b.billNumber?.toLowerCase().contains(q) ?? false) ||
            b.vendorName.toLowerCase().contains(q) ||
            (b.orderNumber?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }

  List<PurchasesBill> _getSortedList(List<PurchasesBill> bills) {
    final list = List<PurchasesBill>.from(bills);
    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case 'bill_date':
          cmp = (a.billDate ?? DateTime(2000)).compareTo(
            b.billDate ?? DateTime(2000),
          );
          break;
        case 'bill_number':
          cmp = (a.billNumber ?? '').compareTo(b.billNumber ?? '');
          break;
        case 'vendor_name':
          cmp = a.vendorName.compareTo(b.vendorName);
          break;
        case 'total':
          cmp = a.total.compareTo(b.total);
          break;
        case 'due_date':
          cmp = (a.dueDate ?? DateTime(2000)).compareTo(
            b.dueDate ?? DateTime(2000),
          );
          break;
        case 'created_at':
          cmp = (a.createdAt ?? DateTime(2000)).compareTo(
            b.createdAt ?? DateTime(2000),
          );
          break;
        case 'updated_at':
          cmp = (a.updatedAt ?? DateTime(2000)).compareTo(
            b.updatedAt ?? DateTime(2000),
          );
          break;
        case 'balance_due':
          cmp = a.total.compareTo(b.total);
          break;
        default:
          cmp = 0;
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  // ─── Main Toolbar ───────────────────────────────────────────────────────

  Widget _buildMainToolbar(
    BuildContext context,
    bool hasSelection,
    List<PurchasesBill> bills,
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
            moduleName: 'bills',
            options: _billFilterOptions,
            selectedOption: _activeOption,
            onChanged: (opt) {
              setState(() {
                _activeOption = opt;
              });
            },
          ),
          const Spacer(),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _showCalendarView = false;
                    });
                    context.go('/purchases/bills');
                  },
                  child: Container(
                    width: 32,
                    height: 30,
                    color: (!hasSelection && !_showCalendarView)
                        ? const Color(0xFFF3F4F6)
                        : Colors.transparent,
                    child: Icon(
                      LucideIcons.menu,
                      size: 15,
                      color: (!hasSelection && !_showCalendarView)
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
                Container(width: 1, height: 30, color: AppTheme.borderLight),
                InkWell(
                  onTap: () {
                    setState(() {
                      _showCalendarView = true;
                    });
                  },
                  child: Container(
                    width: 32,
                    height: 30,
                    color: _showCalendarView
                        ? const Color(0xFFF3F4F6)
                        : Colors.transparent,
                    child: Icon(
                      LucideIcons.calendar,
                      size: 15,
                      color: _showCalendarView
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF28A745),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    context.push('/purchases/bills/create');
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.plus,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'New',
                          style: AppTheme.bodyText.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                MenuAnchor(
                  style: _menuStyle(),
                  builder: (context, controller, child) {
                    return InkWell(
                      onTap: () => controller.isOpen
                          ? controller.close()
                          : controller.open(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          LucideIcons.chevronDown,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                  menuChildren: [
                    MenuItemButton(
                      onPressed: () => context.push('/purchases/bills/create'),
                      child: const Text('Standard Bill'),
                    ),
                    MenuItemButton(
                      onPressed: () {
                        ZerpaiToast.info(
                          context,
                          'New Recurring Bill creation',
                        );
                      },
                      child: const Text('Recurring Bill'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ZTableMoreMenu(
            width: 32,
            height: 32,
            menuChildren: _buildMoreMenuChildren(),
          ),
        ],
      ),
    );
  }

  // ─── Selection Toolbar ──────────────────────────────────────────────────

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
          _BulkActionButton(
            label: 'Bulk Update',
            onTap: () => _handleBulkAction('Bulk Update'),
          ),
          _BulkIconButton(
            icon: LucideIcons.fileText,
            onTap: () => _handleBulkAction('Export as PDF'),
          ),
          _BulkIconButton(
            icon: LucideIcons.printer,
            onTap: () => _handleBulkAction('Print'),
          ),
          const _BulkDivider(),
          _BulkActionButton(
            label: 'Record Bulk Payment',
            onTap: () => _handleBulkAction('Record Bulk Payment'),
          ),
          _BulkActionButton(
            label: 'Link to existing Purchase Order',
            onTap: () => _handleBulkAction('Link to existing Purchase Order'),
          ),
          _BulkActionButton(
            label: 'Mark as Received',
            onTap: () => _handleBulkAction('Mark as Received'),
          ),
          _BulkActionButton(
            label: 'Undo Receive',
            onTap: () => _handleBulkAction('Undo Receive'),
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
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: const Icon(LucideIcons.moreHorizontal, size: 16),
                ),
              );
            },
            menuChildren: [
              MenuItemButton(
                onPressed: () => _handleBulkAction('Delete'),
                child: const Text('Delete'),
              ),
            ],
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

  // ─── Bulk Actions ───────────────────────────────────────────────────────

  void _handleBulkAction(String actionLabel) async {
    if (_selectedIds.isEmpty) {
      ZerpaiToast.info(context, 'Select at least one bill');
      return;
    }

    if (actionLabel == 'Mark as Open') {
      try {
        final supabase = Supabase.instance.client;
        await supabase
            .from('bills')
            .update({'status': 'open'})
            .filter('id', 'in', _selectedIds.toList());

        ref.read(apiClientProvider).clearCache('bills');

        ref.read(billsProvider.notifier).loadBills();
        ZerpaiToast.success(context, 'Selected bills marked as Open');
        setState(() => _selectedIds.clear());
      } catch (e) {
        ZerpaiToast.error(context, 'Failed to update status: $e');
      }
    } else if (actionLabel == 'Delete') {
      final confirmed = await showZerpaiConfirmationDialog(
        context,
        title: 'Delete Bills',
        message:
            'Are you sure you want to delete the selected ${_selectedIds.length} bill(s)?',
        confirmLabel: 'Delete',
        cancelLabel: 'Cancel',
        variant: ZerpaiConfirmationVariant.danger,
      );
      if (!confirmed) return;
      try {
        final supabase = Supabase.instance.client;
        final selectedIds = _selectedIds.toList();
        final response = await supabase
            .from('bills')
            .select('id, bill_number')
            .filter('id', 'in', selectedIds);

        for (final row in response) {
          final id = row['id'] as String;
          final currentNum = row['bill_number'] as String?;
          final newNum = currentNum != null ? (currentNum.startsWith('SD-') ? currentNum : 'SD-$currentNum') : null;
          await supabase
              .from('bills')
              .update({
                'is_delete': true,
                if (newNum != null) 'bill_number': newNum,
              })
              .eq('id', id);
        }

        ref.read(apiClientProvider).clearCache('bills');

        ref.read(billsProvider.notifier).loadBills();
        ZerpaiToast.success(context, 'Selected bills deleted');
        setState(() => _selectedIds.clear());
      } catch (e) {
        ZerpaiToast.error(context, 'Failed to delete: $e');
      }
    } else if (actionLabel == 'Bulk Update') {
      showDialog(
        context: context,
        builder: (dialogCtx) => _BulkUpdateBillsDialog(
          selectedIds: _selectedIds.toList(),
          bills: ref.read(billsProvider).bills,
          onUpdate: (field, value) async {
            try {
              final supabase = Supabase.instance.client;
              Map<String, dynamic> updateData = {};
              if (field == 'Billing Address') {
                updateData['vendor_address'] = value;
              } else if (field == 'Order Number') {
                updateData['order_number'] = value;
              } else if (field == 'Date') {
                updateData['bill_date'] = (value as DateTime).toIso8601String();
              } else if (field == 'Expected Payment Date') {
                updateData['due_date'] = (value as DateTime).toIso8601String();
              } else if (field == 'Notes') {
                updateData['notes'] = value;
              }

              if (updateData.isNotEmpty) {
                await supabase
                    .from('bills')
                    .update(updateData)
                    .filter('id', 'in', _selectedIds.toList());

                ref.read(apiClientProvider).clearCache('bills');

                ref.read(billsProvider.notifier).loadBills();
                if (context.mounted) {
                  ZerpaiToast.success(
                    context,
                    'Bulk update applied successfully',
                  );
                }
              }
              setState(() => _selectedIds.clear());
            } catch (e) {
              if (context.mounted) {
                ZerpaiToast.error(context, 'Failed to perform bulk update: $e');
              }
            }
          },
        ),
      );
    } else if (actionLabel == 'Export as PDF' || actionLabel == 'PDF export') {
      final billsList = ref.read(billsProvider).bills;
      final selectedBills = billsList
          .where((b) => _selectedIds.contains(b.id))
          .toList();
      if (selectedBills.isNotEmpty) {
        final orgSettings = ref.read(orgSettingsProvider).asData?.value;
        final billSummary = selectedBills.first;
        final fullBill = await ref.read(
          purchaseBillProvider(billSummary.id).future,
        );
        final bytes = await _generatePdfForBill(fullBill, orgSettings);
        await Printing.sharePdf(
          bytes: bytes,
          filename: '${fullBill.billNumber ?? "bill"}.pdf',
        );
      }
      setState(() => _selectedIds.clear());
    } else if (actionLabel == 'Print') {
      final billsList = ref.read(billsProvider).bills;
      final selectedBills = billsList
          .where((b) => _selectedIds.contains(b.id))
          .toList();
      if (selectedBills.isNotEmpty) {
        final orgSettings = ref.read(orgSettingsProvider).asData?.value;
        final billSummary = selectedBills.first;
        final fullBill = await ref.read(
          purchaseBillProvider(billSummary.id).future,
        );
        final bytes = await _generatePdfForBill(fullBill, orgSettings);
        await Printing.layoutPdf(onLayout: (_) async => bytes);
      }
      setState(() => _selectedIds.clear());
    } else if (actionLabel == 'Record Bulk Payment') {
      final ids = _selectedIds.toList();
      setState(() => _selectedIds.clear());
      if (context.mounted) {
        context.go('/purchases/payments-made/create?billIds=${ids.join(",")}');
      }
    } else if (actionLabel == 'Link to existing Purchase Order') {
      ZerpaiToast.success(
        context,
        'Linked ${_selectedIds.length} bill(s) to existing Purchase Order',
      );
      setState(() => _selectedIds.clear());
    } else if (actionLabel == 'Mark as Received') {
      final ids = _selectedIds.toList();
      setState(() => _selectedIds.clear());
      
      try {
        final repo = ref.read(purchaseReceiveRepositoryProvider);
        int receivedCount = 0;
        int failedCount = 0;

        for (final id in ids) {
          final bill = await ref.read(purchaseBillProvider(id).future);

          // Check if any item has batches or serial number or bin tracking
          final hasTrackedItems = bill.lineItems.any((item) {
            return item.trackBatches || item.trackSerialNumber || item.trackBinLocation;
          });

          if (hasTrackedItems) {
            failedCount++;
            continue;
          }

          // If track_batches is false (i.e., hasTrackedItems is false), create a new purchase receive
          final nextNumberData = await repo.getNextPurchaseReceiveNumber();
          final nextReceiveNumber = nextNumberData['formatted'] ?? '';

          final receive = PurchaseReceive(
            purchaseReceiveNumber: nextReceiveNumber,
            receivedDate: DateTime.now(),
            vendorId: bill.vendorId,
            vendorName: bill.vendorName,
            purchaseOrderId: null,
            purchaseOrderNumber: bill.orderNumber,
            warehouseId: bill.warehouseId,
            status: 'received',
            notes: 'Automatically created via Bill Mark as Received',
            billNo: bill.billNumber,
            billDate: bill.billDate,
            invoiceTotal: bill.total,
            items: bill.lineItems.map((item) {
              return PurchaseReceiveItem(
                itemId: item.itemId,
                itemName: item.itemName ?? '',
                description: item.description,
                ordered: item.quantity,
                received: 0,
                inTransit: 0,
                cancelled: 0,
                quantityToReceive: item.quantity,
                batches: [],
                purchaseOrderNumber: bill.orderNumber,
              );
            }).toList(),
          );

          await repo.createPurchaseReceive(receive);
          receivedCount++;
        }

        ref.read(apiClientProvider).clearCache('bills');
        ref.read(billsProvider.notifier).loadBills();
        ref.read(purchaseReceivesProvider.notifier).fetchReceives();

        if (context.mounted) {
          if (failedCount > 0) {
            ZerpaiToast.info(
              context,
              'Marked $receivedCount bill(s) as Received. $failedCount bill(s) skipped because they contain tracked items.',
            );
          } else {
            ZerpaiToast.success(
              context,
              'Marked $receivedCount bill(s) as Received successfully',
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ZerpaiToast.error(context, 'Failed to mark as received: $e');
        }
      }
    } else if (actionLabel == 'Undo Receive') {
      ZerpaiToast.success(
        context,
        'Undid receive for ${_selectedIds.length} bill(s)',
      );
      setState(() => _selectedIds.clear());
    } else {
      ZerpaiToast.success(
        context,
        '$actionLabel applied to ${_selectedIds.length} bills',
      );
    }
  }

  // ─── Sort Menu Item ─────────────────────────────────────────────────────

  List<Widget> _buildMoreMenuChildren() {
    return [
      SubmenuButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        menuStyle: ZTableMoreMenu.submenuMenuStyle(),
        alignmentOffset: const Offset(4, 0),
        leadingIcon: const Icon(LucideIcons.arrowUpDown, size: 16),
        menuChildren: [
          _buildSortMenuItem('Created Time', 'created_at'),
          _buildSortMenuItem('Date', 'bill_date'),
          _buildSortMenuItem('Bill#', 'bill_number'),
          _buildSortMenuItem('Vendor Name', 'vendor_name'),
          _buildSortMenuItem('Due Date', 'due_date'),
          _buildSortMenuItem('Amount', 'total'),
          _buildSortMenuItem('Balance Due', 'balance_due'),
          _buildSortMenuItem('Last Modified Time', 'updated_at'),
        ],
        child: const Text('Sort by'),
      ),
      MenuItemButton(
        style: ZTableMoreMenu.menuItemButtonStyle(),
        leadingIcon: const Icon(LucideIcons.download, size: 16),
        onPressed: () {},
        child: const Text('Import Bills'),
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
            child: const Text('Export Bills'),
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
        leadingIcon: const Icon(LucideIcons.refreshCw, size: 16),
        onPressed: () {
          ref.read(billsProvider.notifier).loadBills();
        },
        child: const Text('Refresh List'),
      ),
    ];
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
      trailingIcon: isSelected
          ? Icon(
              _sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
              size: 12,
            )
          : null,
      child: Text(label),
    );
  }

  // ─── Checkbox ───────────────────────────────────────────────────────────

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

  // ─── Table View ─────────────────────────────────────────────────────────

  Widget _buildTableView(List<PurchasesBill> bills) {
    if (bills.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidths =
            _customColumnWidths ?? _calculateColumnWidths(constraints.maxWidth);

        const double actualPrefixWidth = 78.0;
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
                  _buildTableHeader(columnWidths, bills),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: bills.length,
                      itemExtent: 40,
                      itemBuilder: (context, index) {
                        return _buildVirtualRow(bills[index], columnWidths);
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
      'location': (160.0, 1.2),
      'bill_number': (120.0, 1.2),
      'order_number': (130.0, 1.2),
      'vendor_name': (160.0, 1.5),
      'status': (100.0, 0.8),
      'due_date': (100.0, 1.0),
      'amount': (110.0, 1.0),
      'balance_due': (110.0, 1.0),
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
    List<PurchasesBill> bills,
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
          _buildSelectAllCheckbox(bills),
          const SizedBox(width: 12),
          ..._visibleColumns.map((colId) {
            final width = columnWidths[colId]!;
            return _ResizableHeaderCell(
              width: width,
              onResize: (dx) => _resizeColumn(colId, dx),
              child: _buildHeaderCell(
                _columnLabels[colId] ??
                    colId.toUpperCase().replaceAll('_', ' '),
                colId,
                width: width,
              ),
            );
          }),
          const SizedBox(width: 12),
          const Icon(
            LucideIcons.search,
            size: 14,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
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
        child: Text(
          text,
          style: AppTheme.metaHelper.copyWith(fontWeight: FontWeight.bold),
          textAlign: align,
        ),
      ),
    );
  }

  Widget _buildSelectAllCheckbox(List<PurchasesBill> bills) {
    final isAllSelected =
        bills.isNotEmpty && _selectedIds.length == bills.length;
    final isPartiallySelected =
        _selectedIds.isNotEmpty && _selectedIds.length < bills.length;

    return _buildCheckboxWidget(
      isAllSelected,
      isPartially: isPartiallySelected,
      onTap: () {
        setState(() {
          if (isAllSelected) {
            _selectedIds.clear();
          } else {
            _selectedIds.clear();
            for (final b in bills) {
              _selectedIds.add(b.id);
            }
          }
        });
      },
    );
  }

  Widget _buildVirtualRow(
    PurchasesBill bill,
    Map<String, double> columnWidths,
  ) {
    final isSelected = _selectedIds.contains(bill.id);

    return InkWell(
      onTap: () {
        context.go('/purchases/bills/${bill.id}');
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
            _buildCheckboxWidget(
              isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedIds.remove(bill.id);
                  } else {
                    _selectedIds.add(bill.id);
                  }
                });
              },
            ),
            const SizedBox(width: 12),
            ..._visibleColumns.map((colId) {
              return _buildCell(bill, colId, width: columnWidths[colId]!);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(PurchasesBill bill, String colId, {double? width}) {
    Widget content;
    switch (colId) {
      case 'date':
        content = Text(
          bill.billDate != null
              ? DateFormat('dd-MM-yyyy').format(bill.billDate!)
              : '-',
          style: AppTheme.tableCell,
        );
        break;
      case 'location':
        content = Text(bill.warehouseName ?? '-', style: AppTheme.tableCell);
        break;
      case 'bill_number':
        content = Text(
          bill.billNumber ?? '-',
          style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue),
        );
        break;
      case 'order_number':
        content = Text(bill.orderNumber ?? '-', style: AppTheme.tableCell);
        break;
      case 'vendor_name':
        content = Text(bill.vendorName, style: AppTheme.tableCell);
        break;
      case 'status':
        content = _buildStatusBadge(bill.status);
        break;
      case 'due_date':
        content = Text(
          bill.dueDate != null
              ? DateFormat('dd-MM-yyyy').format(bill.dueDate!)
              : '-',
          style: AppTheme.tableCell,
        );
        break;
      case 'amount':
        content = Text(
          '₹${bill.total.toStringAsFixed(2)}',
          style: AppTheme.tableCell,
        );
        break;
      case 'balance_due':
        content = Text(
          '₹${bill.total.toStringAsFixed(2)}',
          style: AppTheme.tableCell.copyWith(
            color: bill.status == 'overdue' ? AppTheme.errorRed : null,
          ),
        );
        break;
      default:
        content = const Text('');
    }

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Align(
          alignment: Alignment.centerLeft,
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

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'draft':
        color = AppTheme.warningOrange;
        break;
      case 'open':
        color = AppTheme.primaryBlue;
        break;
      case 'paid':
        color = AppTheme.successGreen;
        break;
      case 'partially_paid':
      case 'partially paid':
        color = AppTheme.warningOrange;
        break;
      case 'overdue':
        color = AppTheme.errorRed;
        break;
      case 'void':
        color = AppTheme.textSecondary;
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

  // ─── Empty / Error / No Match States ────────────────────────────────────

  Widget _buildNoMatchingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.searchX, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text('No matching bills', style: AppTheme.sectionHeader),
          const SizedBox(height: 8),
          Text(
            'Adjust the active view or search term.',
            style: AppTheme.metaHelper,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'No bills yet',
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            'Create your first bill to start managing payables',
            style: AppTheme.metaHelper,
          ),
          const SizedBox(height: AppTheme.space24),
          ZButton.primary(
            label: 'Create Bill',
            onPressed: () {
              context.push('/purchases/bills/create');
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
            'Failed to load bills',
            style: AppTheme.sectionHeader.copyWith(color: AppTheme.errorRed),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(error, style: AppTheme.metaHelper, textAlign: TextAlign.center),
          const SizedBox(height: AppTheme.space24),
          ZButton.primary(
            label: 'Retry',
            onPressed: () {
              ref.read(billsProvider.notifier).loadBills();
            },
          ),
        ],
      ),
    );
  }

  // ─── Menu Styles ────────────────────────────────────────────────────────

  MenuStyle _menuStyle() {
    return MenuStyle(
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      elevation: const WidgetStatePropertyAll(8),
      backgroundColor: const WidgetStatePropertyAll(Colors.white),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
    );
  }



  Widget _detailBanners(PurchasesBill bill) {
    if (bill.status.toLowerCase() == 'draft') {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Padding(
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
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: "WHAT'S NEXT? ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text:
                            "Bill has been created. Convert this draft bill to open status to record payment. ",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () => _handleConvertBillToOpen(bill),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28A745),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  minimumSize: const Size(0, 32),
                  fixedSize: const Size.fromHeight(32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text(
                  'Convert to Open',
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
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                    children: [
                      TextSpan(text: 'Credits Available: '),
                      TextSpan(
                        text: '₹100.00 ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => ZerpaiToast.success(
                      context,
                      'Credits applied successfully',
                    ),
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
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF374151),
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: "WHAT'S NEXT? ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                          text:
                              "Payment for this bill is overdue. Apply available credits or record the payment for bill if paid already. ",
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () =>
                      setState(() => _showPaymentFormForId = bill.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 32),
                    fixedSize: const Size.fromHeight(32),
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
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => ZerpaiToast.success(
                    context,
                    'Credits applied successfully',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 32),
                    fixedSize: const Size.fromHeight(32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    'Apply Credits',
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
        ],
      ),
    );
  }

  Widget _a4SimulatedBill(PurchasesBill bill) {
    final orgSettings = ref.watch(orgSettingsProvider).asData?.value;
    final billingAddress = bill.vendorAddress ?? 'N/A';
    final isPaid = bill.status.trim().toLowerCase() == 'paid';

    Color ribbonColor;
    switch (bill.status.toLowerCase()) {
      case 'paid':
        ribbonColor = AppTheme.successDark;
        break;
      case 'open':
        ribbonColor = AppTheme.primaryBlue;
        break;
      case 'draft':
        ribbonColor = AppTheme.warningOrange;
        break;
      case 'overdue':
        ribbonColor = AppTheme.errorRed;
        break;
      case 'void':
        ribbonColor = AppTheme.textSecondary;
        break;
      default:
        ribbonColor = AppTheme.primaryBlue;
    }

    return Container(
      color: const Color(0xFFF0F0F0),
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          width: 755 + 24,
          height: 1000,
          decoration: _paperDecoration(),
          child: ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  child: _PdfCornerRibbon(
                    label: bill.status,
                    color: ribbonColor,
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
                                      : '',
                                  style: AppTheme.bodyText.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (orgSettings?.resolvedPaymentStubAddress
                                        ?.trim()
                                        .isNotEmpty ==
                                    true)
                                  Text(
                                    _formatAddress(
                                      orgSettings!.resolvedPaymentStubAddress!
                                          .trim(),
                                    ),
                                    style: AppTheme.bodyText.copyWith(
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                if (orgSettings
                                        ?.companyIdentityLine
                                        ?.isNotEmpty ==
                                    true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      orgSettings!.companyIdentityLine!,
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                if (orgSettings?.phone?.isNotEmpty == true &&
                                    orgSettings?.resolvedPaymentStubAddress
                                            ?.contains(orgSettings.phone!) !=
                                        true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      orgSettings!.phone!,
                                      style: AppTheme.bodyText.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                if (orgSettings?.email?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      orgSettings!.email!,
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
                                'BILL',
                                style: AppTheme.sectionHeader.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Bill# ${bill.billNumber ?? '-'}',
                                style: AppTheme.bodyText.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Balance Due',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${bill.total.toStringAsFixed(2)}',
                                style: AppTheme.bodyText.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
                              'Bill From',
                              bill.vendorName,
                              billingAddress,
                              bill.vendorGstin,
                            ),
                          ),
                          const SizedBox(width: 30),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _a4MetaRow(
                                  'Bill Date :',
                                  bill.billDate != null
                                      ? DateFormat(
                                          'dd-MM-yyyy',
                                        ).format(bill.billDate!)
                                      : '-',
                                ),
                                _a4MetaRow(
                                  'Due Date :',
                                  bill.dueDate != null
                                      ? DateFormat(
                                          'dd-MM-yyyy',
                                        ).format(bill.dueDate!)
                                      : '-',
                                ),
                                _a4MetaRow(
                                  'Terms :',
                                  bill.paymentTerms ?? '',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Expanded(child: _pdfItems(bill.lineItems)),
                      const SizedBox(height: 18),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: _totals(bill),
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
                    ],
                  ),
                ),
                if (isPaid)
                  Positioned(
                    right: 40,
                    top: 100,
                    child: Transform.rotate(
                      angle: -0.2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 3),
                        ),
                        child: const Text(
                          'PAID',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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

  Widget _pdfAddress(
    String title,
    String primary,
    String address,
    String? gstin,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyText.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          primary,
          style: AppTheme.bodyText.copyWith(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          address,
          style: AppTheme.bodyText.copyWith(fontSize: 13, height: 1.4),
        ),
        if (gstin != null && gstin.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            gstin.startsWith('GSTIN') ? gstin : 'GSTIN $gstin',
            style: AppTheme.bodyText.copyWith(fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _a4MetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: AppTheme.bodyText.copyWith(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 24),
          SizedBox(
            width: 100,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTheme.bodyText.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pdfItems(List<PurchasesBillLineItem> items) {
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
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
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
                                  item.itemName ?? '',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${item.quantity}',
                            textAlign: TextAlign.right,
                            style: AppTheme.bodyText.copyWith(fontSize: 13),
                          ),
                          Text(
                            item.unitPack ?? 'pcs',
                            style: AppTheme.bodyText.copyWith(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
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
                        (item.quantity * item.rate).toStringAsFixed(2),
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
        ),
        const Divider(height: 1, color: AppTheme.textPrimary),
      ],
    );
  }

  Widget _totals(PurchasesBill bill) {
    final bool isKerala =
        bill.placeOfSupply == null ||
        bill.placeOfSupply!.toLowerCase().contains('kerala') ||
        bill.placeOfSupply!.toLowerCase().contains('[kl]');
    final double totalTaxRate = (bill.subTotal > 0)
        ? (bill.taxAmount / bill.subTotal) * 100
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _a4TotalRow('Sub Total', bill.subTotal.toStringAsFixed(2)),
        const SizedBox(height: 8),
        if (bill.taxAmount > 0) ...[
          if (isKerala) ...[
            (() {
              final double cgstPct = double.parse(
                (totalTaxRate / 2).toStringAsFixed(1),
              );
              final halfStr = cgstPct == cgstPct.toInt()
                  ? '${cgstPct.toInt()}'
                  : '${cgstPct.toStringAsFixed(1)}';
              final pctLabel = '$halfStr%';
              return Column(
                children: [
                  _a4TotalRow(
                    'CGST$halfStr ($pctLabel)',
                    (bill.taxAmount / 2).toStringAsFixed(2),
                  ),
                  const SizedBox(height: 8),
                  _a4TotalRow(
                    'SGST$halfStr ($pctLabel)',
                    (bill.taxAmount / 2).toStringAsFixed(2),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            })(),
          ] else ...[
            (() {
              final igstLabel = totalTaxRate == totalTaxRate.toInt()
                  ? '${totalTaxRate.toInt()}%'
                  : '${totalTaxRate.toStringAsFixed(1)}%';
              return Column(
                children: [
                  _a4TotalRow(
                    'IGST$igstLabel ($igstLabel)',
                    bill.taxAmount.toStringAsFixed(2),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            })(),
          ],
        ],
        if (bill.discountAmount > 0) ...[
          _a4TotalRow(
            'Discount${bill.discountPercent > 0 ? '(${bill.discountPercent.toStringAsFixed(2)}%)' : ''}',
            '-${bill.discountAmount.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 8),
        ],
        if (bill.adjustment != 0) ...[
          _a4TotalRow(
            bill.adjustmentLabel ?? 'Adjustment',
            bill.adjustment.toStringAsFixed(2),
          ),
          const SizedBox(height: 8),
        ],
        _a4TotalRow('Total', '₹${bill.total.toStringAsFixed(2)}', isBold: true),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: const Color(0xFFF3F4F6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Balance Due',
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                '₹${bill.total.toStringAsFixed(2)}',
                style: AppTheme.bodyText.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
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

  Widget _a4TotalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Inter',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _fetchBillJournals(String billId) async {
    final supabase = Supabase.instance.client;
    final res = await supabase
        .from('account_transactions')
        .select('*, account:accounts(user_account_name, system_account_name)')
        .eq('source_id', billId)
        .eq('source_type', 'BILL');
    return List<Map<String, dynamic>>.from(res);
  }

  Widget _buildJournalsTab(PurchasesBill bill) {
    final warehouses = ref.watch(warehousesProvider).value ?? [];
    String resolvedWarehouseName = '-';
    if (bill.warehouseName != null && bill.warehouseName!.isNotEmpty) {
      resolvedWarehouseName = bill.warehouseName!;
    } else if (bill.warehouseId != null) {
      for (var w in warehouses) {
        if (w.id == bill.warehouseId) {
          resolvedWarehouseName = w.name;
          break;
        }
      }
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchBillJournals(bill.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Failed to load journals: ${snapshot.error}',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          );
        }
        final txs = snapshot.data ?? [];
        if (txs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No journal entries found for this bill.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ),
          );
        }

        // Check if debits and credits match
        double totalDebit = 0;
        double totalCredit = 0;
        for (var tx in txs) {
          totalDebit += double.tryParse(tx['debit']?.toString() ?? '0') ?? 0;
          totalCredit += double.tryParse(tx['credit']?.toString() ?? '0') ?? 0;
        }
        final bool isBalanced = (totalDebit - totalCredit).abs() < 0.01;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            if (isBalanced) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          LucideIcons.checkCircle2,
                          size: 13,
                          color: Color(0xFF065F46),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Debits/Credits match',
                          style: TextStyle(
                            color: Color(0xFF065F46),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Table(
              columnWidths: const {
                0: FlexColumnWidth(4),
                1: FlexColumnWidth(4),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB)),
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text(
                        'ACCOUNT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text(
                        'WAREHOUSE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text(
                        'DEBIT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Text(
                        'CREDIT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                ...txs.map((tx) {
                  final accountName = tx['account']?['user_account_name'] ??
                      tx['account']?['system_account_name'] ??
                      '-';
                  final debit = double.tryParse(tx['debit']?.toString() ?? '0') ?? 0;
                  final credit = double.tryParse(tx['credit']?.toString() ?? '0') ?? 0;

                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFF3F4F6)),
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Text(
                          accountName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Text(
                          resolvedWarehouseName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Text(
                          debit > 0 ? debit.toStringAsFixed(2) : '0.00',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        child: Text(
                          credit > 0 ? credit.toStringAsFixed(2) : '0.00',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1F2937),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  );
                }),
                TableRow(
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                    ),
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    const SizedBox.shrink(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Text(
                        totalDebit.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      child: Text(
                        totalCredit.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomDetails(PurchasesBill bill, StateSetter setInnerState) {
    final hasBatches = bill.lineItems.any(
      (item) => item.batches != null && item.batches!.isNotEmpty,
    );

    // Auto-resolve tab when current bill lacks batches
    if (!hasBatches && _bottomActiveTab == 'batches') {
      _bottomActiveTab = 'journals';
    }

    final binsAsync = ref.watch(binsLookupProvider(bill.warehouseId));
    final bins = binsAsync.value ?? [];

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
              if (hasBatches) ...[
                InkWell(
                  onTap: () {
                    setInnerState(() {
                      _bottomActiveTab = 'batches';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _bottomActiveTab == 'batches'
                              ? AppTheme.primaryBlue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'Batches',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _bottomActiveTab == 'batches'
                            ? AppTheme.primaryBlue
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
              InkWell(
                onTap: () {
                  setInnerState(() {
                    _bottomActiveTab = 'journals';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _bottomActiveTab == 'journals'
                            ? AppTheme.primaryBlue
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    'Journals',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _bottomActiveTab == 'journals'
                          ? AppTheme.primaryBlue
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_bottomActiveTab == 'batches' && hasBatches) ...[
          const SizedBox(height: 16),
          ...() {
            final Map<String, Map<String, List<Map<String, dynamic>>>> grouped =
                {};
            for (var item in bill.lineItems) {
              final itemName = item.itemName ?? 'Unnamed Item';
              if (item.batches != null && item.batches!.isNotEmpty) {
                for (var b in item.batches!) {
                  if (b is Map<String, dynamic> || b is Map) {
                    final Map<String, dynamic> bMap = Map<String, dynamic>.from(
                      b,
                    );
                    final batchNo =
                        bMap['batch']?['batch_no']?.toString() ??
                        bMap['batch']?['batchNo']?.toString() ??
                        bMap['manufacture_batch_no']?.toString() ??
                        bMap['batch_id']?.toString() ??
                        '-';
                    grouped.putIfAbsent(itemName, () => {});
                    grouped[itemName]!.putIfAbsent(batchNo, () => []);
                    grouped[itemName]![batchNo]!.add(bMap);
                  }
                }
              }
            }

            return grouped.entries.map((itemEntry) {
              final itemName = itemEntry.key;
              final batches = itemEntry.value;
              final isExpanded = _expandedBatchesItems.contains(itemName);

              return Column(
                children: [
                  InkWell(
                    onTap: () => setInnerState(() {
                      if (isExpanded) {
                        _expandedBatchesItems.remove(itemName);
                      } else {
                        _expandedBatchesItems.add(itemName);
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
                          Text(
                            itemName.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryBlue,
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
                                  'QUANTITY IN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...batches.entries.map((batchEntry) {
                            final batchNo = batchEntry.key;
                            final batchList = batchEntry.value;
                            final firstBatch = batchList.first;
                            final totalQty = batchList.fold(
                              0.0,
                              (sum, b) =>
                                  sum +
                                  ((b['quantity'] as num?)?.toDouble() ?? 0.0),
                            );
                            final totalFoc = batchList.fold(
                              0.0,
                              (sum, b) =>
                                  sum +
                                  ((b['foc_quantity'] as num?)?.toDouble() ??
                                      (b['focQuantity'] as num?)?.toDouble() ??
                                      0.0),
                            );

                            final expiryRaw =
                                firstBatch['expiry_date'] ??
                                firstBatch['batch']?['expiry_date'] ??
                                firstBatch['batch']?['expiryDate'] ??
                                firstBatch['expiryDate'];
                            final expiryStr = expiryRaw != null
                                ? DateFormat(
                                    'dd-MM-yyyy',
                                  ).format(DateTime.parse(expiryRaw.toString()))
                                : null;
                            final mfgDateRaw =
                                firstBatch['manufacture_date'] ??
                                firstBatch['batch']?['manufacture_date'] ??
                                firstBatch['batch']?['manufactureDate'] ??
                                firstBatch['manufactureDate'] ??
                                firstBatch['manufacture_date'];
                            final mfgDateStr = mfgDateRaw != null
                                ? DateFormat('dd-MM-yyyy').format(
                                    DateTime.parse(mfgDateRaw.toString()),
                                  )
                                : null;
                            final mfgBatchNo =
                                firstBatch['manufacture_batch_no'] ??
                                firstBatch['batch']?['manufacture_batch_no'] ??
                                firstBatch['batch']?['manufactureBatchNo'] ??
                                firstBatch['manufactureBatchNo'];

                            final binId =
                                firstBatch['bin_id'] ?? firstBatch['binId'];
                            final binMatch = bins.firstWhere(
                              (bin) => bin['id'] == binId,
                              orElse: () => <String, String>{},
                            );
                            final binCode = binMatch['bin_code'];

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
                                          ...() {
                                            final isBatchNoUuid = RegExp(
                                              r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                                            ).hasMatch(batchNo);
                                            final isMfgBatchUuid = mfgBatchNo !=
                                                    null &&
                                                RegExp(
                                                  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                                                ).hasMatch(
                                                  mfgBatchNo.toString(),
                                                );
                                            final showTitle = !isBatchNoUuid;
                                            final showMfgSubtitle =
                                                mfgBatchNo != null &&
                                                mfgBatchNo
                                                    .toString()
                                                    .isNotEmpty &&
                                                !isMfgBatchUuid &&
                                                (isBatchNoUuid ||
                                                    mfgBatchNo.toString() !=
                                                        batchNo);

                                            return [
                                              if (showTitle)
                                                Text(
                                                  batchNo,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppTheme.primaryBlue,
                                                  ),
                                                ),
                                              if (showMfgSubtitle) ...[
                                                if (showTitle)
                                                  const SizedBox(height: 6),
                                                Text(
                                                  'Manufacturer Batch# : $mfgBatchNo',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF6B7280),
                                                  ),
                                                ),
                                              ],
                                            ];
                                          }(),
                                          if (mfgDateStr != null)
                                            Text(
                                              'Manufactured date : $mfgDateStr',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          if (expiryStr != null)
                                            Text(
                                              'Expiry Date: $expiryStr',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          if (binCode != null &&
                                              binCode.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                ZTooltip(
                                                  message:
                                                      'Bin Location: $binCode',
                                                  child: const Text(
                                                    'Associated Bins',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppTheme.primaryBlue,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${(totalFoc > 0 ? (totalQty + totalFoc) : totalQty).toStringAsFixed(0)} box',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (totalFoc > 0) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '${totalQty.toInt()} box + ${totalFoc.toInt()} foc',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (batchEntry.key != batches.keys.last)
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
        if (_bottomActiveTab == 'journals') ...[
          _buildJournalsTab(bill),
        ],
      ],
    );
  }

  void _showReasonDialog(BuildContext context, PurchasesBill bill, String targetStatus) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _ReasonInputDialog(
          bill: bill,
          targetStatus: targetStatus,
          onConfirm: (reason) async {
            try {
              await ref.read(billsProvider.notifier).updateBillStatus(
                bill.id,
                targetStatus,
                reason,
              );
              
              ref.read(apiClientProvider).clearCache('bills');
              ref.invalidate(purchaseBillProvider(bill.id));
              ref.read(billsProvider.notifier).loadBills();
              
              if (context.mounted) {
                ZerpaiToast.success(
                  context,
                  targetStatus == 'void'
                      ? 'Bill marked as Void'
                      : 'Bill converted to Draft',
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

  Future<void> _handleConvertBillToOpen(PurchasesBill bill) async {
    try {
      await ref.read(billsProvider.notifier).updateBillStatus(
        bill.id,
        'open',
        '',
      );

      ref.read(apiClientProvider).clearCache('bills');
      ref.invalidate(purchaseBillProvider(bill.id));
      ref.read(billsProvider.notifier).loadBills();

      if (context.mounted) {
        ZerpaiToast.success(context, 'Bill converted to Open');
      }
    } catch (e) {
      if (context.mounted) {
        ZerpaiToast.error(context, 'Failed to convert bill to Open: $e');
      }
    }
  }

  Widget _buildCalendarView(List<PurchasesBill> bills) {
    return Column(
      children: [
        _buildCalendarHeader(),
        _buildWeekdayHeader(),
        Expanded(child: _buildCalendarGrid(bills)),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    final now = DateTime.now();
    final thisMonthVal = DateTime(now.year, now.month);
    
    final List<DateTime> tabMonths = [];
    for (int i = -3; i <= 1; i++) {
      tabMonths.add(DateTime(_calendarMonth.year, _calendarMonth.month + i));
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Title row ──
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              const Text(
                'Bills Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 6),
              ZTooltip(
                message: 'Displays month view of Bills, summarized on the basis of their due date.',
                child: const Icon(
                  LucideIcons.helpCircle,
                  size: 15,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
        // ── Month tabs banner ──
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF9FAFB),
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              _buildMonthTab(
                label: 'This Month',
                isSelected: _calendarMonth.year == thisMonthVal.year && _calendarMonth.month == thisMonthVal.month,
                onTap: () {
                  setState(() {
                    _calendarMonth = thisMonthVal;
                  });
                },
              ),
              const SizedBox(width: 8),
              ...tabMonths.map((m) {
                final label = DateFormat('MMM yyyy').format(m);
                final isSelected = _calendarMonth.year == m.year && _calendarMonth.month == m.month;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildMonthTab(
                    label: label,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _calendarMonth = m;
                      });
                    },
                  ),
                );
              }),
              const SizedBox(width: 12),
              _CalendarMonthPickerPopover(
                initialMonth: _calendarMonth,
                onMonthSelected: (date) {
                  setState(() {
                    _calendarMonth = date;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(
                    LucideIcons.calendar,
                    size: 15,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonthTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFFF9FAFB),
          border: isSelected
              ? Border.all(color: const Color(0xFFE5E7EB))
              : Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }


  Widget _buildWeekdayHeader() {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: weekdays.map((day) {
          return Expanded(
            child: Text(
              day,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
              textAlign: TextAlign.center,
            ),
          );
        }).toList(),
      ),
    );
  }

  List<DateTime> getCalendarDays(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final weekday = firstDayOfMonth.weekday;
    final daysBefore = weekday == 7 ? 0 : weekday;
    final start = firstDayOfMonth.subtract(Duration(days: daysBefore));
    
    final List<DateTime> days = [];
    for (int i = 0; i < 35; i++) {
      days.add(start.add(Duration(days: i)));
    }
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    if (days.last.isBefore(endOfMonth)) {
      for (int i = 35; i < 42; i++) {
        days.add(start.add(Duration(days: i)));
      }
    }
    return days;
  }

  double getDailyTotal(DateTime date, List<PurchasesBill> bills) {
    double total = 0.0;
    for (final bill in bills) {
      if (bill.billDate != null) {
        final d = bill.billDate!;
        if (d.year == date.year && d.month == date.month && d.day == date.day) {
          total += bill.total;
        }
      }
    }
    return total;
  }

  Widget _buildCalendarGrid(List<PurchasesBill> bills) {
    final days = getCalendarDays(_calendarMonth);
    final List<List<DateTime>> weeks = [];
    for (int i = 0; i < days.length; i += 7) {
      weeks.add(days.sublist(i, i + 7));
    }

    final today = DateTime.now();

    return Column(
      children: weeks.map((week) {
        return Expanded(
          child: Row(
            children: week.map((date) {
              final isCurrentMonth = date.month == _calendarMonth.month;
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              
              final dailyTotal = getDailyTotal(date, bills);
              final dateBills = bills.where((b) {
                if (b.billDate == null) return false;
                final d = b.billDate!;
                return d.year == date.year && d.month == date.month && d.day == date.day;
              }).toList();
              final billCount = dateBills.length;
              
              final bgColor = isToday
                  ? const Color(0xFFFEFBF0)
                  : (isCurrentMonth ? Colors.white : const Color(0xFFFAFAFA));

              String dateText = '${date.day}';
              if (date.day == 1) {
                dateText = '1 ${DateFormat('MMM').format(date)}';
              }

              return Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 0.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: date.day == 1 || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCurrentMonth
                                ? const Color(0xFF111827)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (dailyTotal > 0)
                        Center(
                          child: _BillAmountTooltip(
                            message: 'Total Count: $billCount',
                            child: _BillDetailsPopover(
                              date: date,
                              bills: bills,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  '₹${dailyTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF25C3D),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommentsSidebar(PurchasesBill bill) {
    final List<_HistoryEvent> events = [];
    final user = ref.read(authUserProvider);
    final currentUsername = user?.fullName ?? user?.email.split('@').first ?? 'system';

    events.add(
      _HistoryEvent(
        username: currentUsername,
        time: bill.createdAt ?? bill.billDate ?? DateTime.now(),
        content: 'Bill ${bill.billNumber ?? "Unknown"} created',
        icon: LucideIcons.fileSpreadsheet,
      ),
    );

    for (final a in _billAttachments) {
      final uploadedAtStr = a['created_at']?.toString();
      final dt = uploadedAtStr != null ? DateTime.tryParse(uploadedAtStr) : null;
      events.add(
        _HistoryEvent(
          username: currentUsername,
          time: dt ?? bill.createdAt ?? bill.billDate ?? DateTime.now(),
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

// ─── Resizable Header Cell ────────────────────────────────────────────────

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

// ─── Bulk Action Helper Widgets ───────────────────────────────────────────

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

class _ActionSquare extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionSquare({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderLight),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

class _PurchasesBillPaymentForm extends ConsumerStatefulWidget {
  final PurchasesBill bill;
  final VoidCallback onCancel;
  final VoidCallback onSaveSuccess;

  const _PurchasesBillPaymentForm({
    required this.bill,
    required this.onCancel,
    required this.onSaveSuccess,
  });

  @override
  ConsumerState<_PurchasesBillPaymentForm> createState() =>
      _PurchasesBillPaymentFormState();
}

class _PurchasesBillPaymentFormState
    extends ConsumerState<_PurchasesBillPaymentForm> {
  late final TextEditingController amountCtrl;
  late final TextEditingController paymentNumberCtrl;
  late final TextEditingController referenceCtrl;
  late final TextEditingController notesCtrl;
  late final TextEditingController bankChargesCtrl;
  late final TextEditingController paymentReceivedOnCtrl;

  DateTime paymentDate = DateTime.now();
  String paymentMode = 'Cash';
  String? paidFrom = 'Petty Cash';
  bool _isTaxDeducted = false;

  @override
  void initState() {
    super.initState();
    amountCtrl = TextEditingController(
      text: widget.bill.total.toStringAsFixed(2),
    );
    paymentNumberCtrl = TextEditingController(
      text: 'PAY-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}',
    );
    referenceCtrl = TextEditingController();
    notesCtrl = TextEditingController();
    bankChargesCtrl = TextEditingController();
    paymentReceivedOnCtrl = TextEditingController();
    paymentDate = DateTime.now();
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    paymentNumberCtrl.dispose();
    referenceCtrl.dispose();
    notesCtrl.dispose();
    bankChargesCtrl.dispose();
    paymentReceivedOnCtrl.dispose();
    super.dispose();
  }

  Widget _dualFieldRow(Widget leftField, Widget rightField) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: leftField),
        const SizedBox(width: 32),
        Expanded(flex: 5, child: rightField),
      ],
    );
  }

  Widget _labeledField(
    String label,
    Widget child, {
    bool required = false,
    String? subLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SharedFieldLayout(
        label: label,
        required: required,
        labelColor: required ? AppTheme.errorRed : AppTheme.textSecondary,
        labelWidth: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            child,
            if (subLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                subLabel,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVendorDetailsCard() {
    return Container(
      margin: const EdgeInsets.only(right: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF4C556D),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "${widget.bill.vendorName}'s Details",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 24),
          const Icon(LucideIcons.chevronRight, color: Colors.white, size: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warehousesAsync = ref.watch(warehousesProvider);
    final List<String> warehouseNames = warehousesAsync.maybeWhen(
      data: (list) => list.map((w) => w.name).toList(),
      orElse: () => <String>[],
    );
    final titleText = 'Payment for ${widget.bill.billNumber ?? widget.bill.id}';

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
            child: Text(
              titleText,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          // Scrollable Form Fields
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Grey Top Section
                  Container(
                    color: AppTheme.bgLight,
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              _labeledField(
                                'Vendor Name',
                                FormDropdown<String>(
                                  value: widget.bill.vendorId,
                                  height: 36,
                                  items: [widget.bill.vendorId],
                                  hint: 'Select a vendor',
                                  displayStringForValue: (id) =>
                                      widget.bill.vendorName,
                                  onChanged: (_) {},
                                ),
                                required: true,
                              ),
                              _labeledField(
                                'Payment #',
                                CustomTextField(
                                  controller: paymentNumberCtrl,
                                  height: 36,
                                ),
                                required: true,
                              ),
                              _labeledField(
                                'Transaction Series',
                                FormDropdown<String>(
                                  value: 'Default Transaction Series',
                                  height: 36,
                                  items: const ['Default Transaction Series'],
                                  onChanged: (_) {},
                                ),
                                required: true,
                              ),
                              _labeledField(
                                'Location',
                                FormDropdown<String>(
                                  value: widget.bill.warehouseName ?? (warehouseNames.isNotEmpty ? warehouseNames.first : '-'),
                                  height: 36,
                                  items: [
                                    if (widget.bill.warehouseName != null) widget.bill.warehouseName!,
                                    ...warehouseNames.where((name) => name != widget.bill.warehouseName),
                                    if (widget.bill.warehouseName == null && warehouseNames.isEmpty) '-',
                                  ],
                                  onChanged: (_) {},
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: _buildVendorDetailsCard(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // White Bottom Section
                  Container(
                    padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _dualFieldRow(
                          _labeledField(
                            'Amount Paid (INR)',
                            CustomTextField(
                              controller: amountCtrl,
                              height: 36,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.right,
                            ),
                            required: true,
                            subLabel: 'PAN: ABACS3075R',
                          ),
                          _labeledField(
                            'Bank Charges (if any)',
                            CustomTextField(
                              controller: bankChargesCtrl,
                              height: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _labeledField(
                          'Tax deducted?',
                          ZerpaiRadioGroup<bool>(
                            options: const [false, true],
                            current: _isTaxDeducted,
                            onChanged: (val) =>
                                setState(() => _isTaxDeducted = val),
                            labelBuilder: (val) => val
                                ? 'Yes, TDS (Income Tax)'
                                : 'No Tax deducted',
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(color: AppTheme.borderLight),
                        const SizedBox(height: 24),
                        _dualFieldRow(
                          _labeledField(
                            'Payment Date',
                            ZDatePickerField(
                              selectedDate: paymentDate,
                              onDateSelected: (d) =>
                                  setState(() => paymentDate = d),
                            ),
                            required: true,
                          ),
                          _labeledField(
                            'Payment Mode',
                            FormDropdown<String>(
                              value: paymentMode,
                              height: 36,
                              items: const [
                                'Cash',
                                'Check',
                                'Credit Card',
                                'Bank Transfer',
                                'Other',
                              ],
                              onChanged: (v) =>
                                  setState(() => paymentMode = v!),
                            ),
                          ),
                        ),
                        _dualFieldRow(
                          _labeledField(
                            'Payment Made On',
                            CustomTextField(
                              controller: paymentReceivedOnCtrl,
                              height: 36,
                              hintText: 'dd-MM-yyyy',
                            ),
                          ),
                          _labeledField(
                            'Paid From',
                            FormDropdown<String>(
                              value: paidFrom,
                              height: 36,
                              items: const [
                                'Petty Cash',
                                'Undeposited Funds',
                                'Bank Account',
                              ],
                              onChanged: (v) => setState(() => paidFrom = v),
                            ),
                            required: true,
                          ),
                        ),
                        _dualFieldRow(
                          _labeledField(
                            'Reference#',
                            CustomTextField(
                              controller: referenceCtrl,
                              height: 36,
                            ),
                          ),
                          _labeledField(
                            'Notes',
                            CustomTextField(controller: notesCtrl, maxLines: 3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    minimumSize: const Size(0, 32),
                    fixedSize: const Size.fromHeight(32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Save as Draft'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _savePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    minimumSize: const Size(0, 32),
                    fixedSize: const Size.fromHeight(32),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: const Text('Save as Paid'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    minimumSize: const Size(0, 32),
                    fixedSize: const Size.fromHeight(32),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _savePayment() async {
    try {
      final supabase = Supabase.instance.client;
      await supabase
          .from('bills')
          .update({'status': 'paid'})
          .eq('id', widget.bill.id);

      ref.read(apiClientProvider).clearCache('bills');

      ref.invalidate(purchaseBillProvider(widget.bill.id));
      ref.read(billsProvider.notifier).loadBills();

      widget.onSaveSuccess();
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to record payment: $e');
      }
    }
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

class _BulkUpdateBillsDialog extends StatefulWidget {
  final List<String> selectedIds;
  final List<PurchasesBill> bills;
  final Future<void> Function(String field, dynamic value) onUpdate;

  const _BulkUpdateBillsDialog({
    required this.selectedIds,
    required this.bills,
    required this.onUpdate,
  });

  @override
  State<_BulkUpdateBillsDialog> createState() => _BulkUpdateBillsDialogState();
}

class _BulkUpdateBillsDialogState extends State<_BulkUpdateBillsDialog> {
  String? _selectedField;
  final TextEditingController _textController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  final List<String> _fields = const [
    'Billing Address',
    'Order Number',
    'Date',
    'Notes',
    'Expected Payment Date',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedBills = widget.bills
        .where((b) => widget.selectedIds.contains(b.id))
        .toList();
    final uniqueVendorIds = selectedBills.map((b) => b.vendorId).toSet();
    final isMultipleVendors = uniqueVendorIds.length > 1;

    final bool showBillingAddressError =
        _selectedField == 'Billing Address' && isMultipleVendors;

    return Dialog(
      alignment: Alignment.center,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
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
                    'Bulk Update Bills',
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

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a field from the dropdown and update with new information.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textBody),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FormDropdown<String>(
                          value: _selectedField,
                          height: 36,
                          items: _fields,
                          hint: 'Select a field',
                          onChanged: (val) {
                            setState(() {
                              _selectedField = val;
                              _textController.clear();
                              _selectedDate = null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildRightInput(showBillingAddressError),
                      ),
                    ],
                  ),

                  if (showBillingAddressError) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Icon(
                            LucideIcons.alertTriangle,
                            size: 16,
                            color: Color(0xFFE11D48),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You cannot update the billing address for multiple vendors at once. Kindly select the Bills of a single vendor to proceed.',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: Color(0xFF9F1239),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),
                  const Text(
                    'Note: All the selected bills will be updated with the new information and you cannot undo this action.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppTheme.borderColor),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed:
                        _isLoading ||
                            _selectedField == null ||
                            showBillingAddressError
                        ? null
                        : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28A745),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0x8028A745),
                      disabledForegroundColor: const Color(0xB3FFFFFF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      minimumSize: const Size(0, 32),
                      fixedSize: const Size.fromHeight(32),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Update'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      minimumSize: const Size(0, 32),
                      fixedSize: const Size.fromHeight(32),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightInput(bool showBillingAddressError) {
    if (_selectedField == null || showBillingAddressError) {
      return Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    if (_selectedField == 'Billing Address' ||
        _selectedField == 'Order Number') {
      return CustomTextField(
        controller: _textController,
        height: 36,
        hintText: 'Enter new ${_selectedField!.toLowerCase()}',
      );
    }

    if (_selectedField == 'Notes') {
      return CustomTextField(
        controller: _textController,
        hintText: 'Enter notes',
        maxLines: 4,
        height: 80,
      );
    }

    if (_selectedField == 'Date' || _selectedField == 'Expected Payment Date') {
      final formattedDate = _selectedDate != null
          ? DateFormat('dd-MM-yyyy').format(_selectedDate!)
          : 'dd-MM-yyyy';

      final GlobalKey key = GlobalKey();
      return GestureDetector(
        key: key,
        onTap: () async {
          final picked = await ZerpaiDatePicker.show(
            context,
            initialDate: _selectedDate ?? DateTime.now(),
            targetKey: key,
          );
          if (picked != null) {
            setState(() {
              _selectedDate = picked;
            });
          }
        },
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: TextStyle(
                  fontSize: 13,
                  color: _selectedDate != null
                      ? AppTheme.textPrimary
                      : AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container();
  }

  void _handleUpdate() async {
    setState(() => _isLoading = true);
    dynamic value;
    if (_selectedField == 'Billing Address' ||
        _selectedField == 'Order Number' ||
        _selectedField == 'Notes') {
      value = _textController.text;
    } else if (_selectedField == 'Date' ||
        _selectedField == 'Expected Payment Date') {
      value = _selectedDate ?? DateTime.now();
    }

    if (value != null) {
      await widget.onUpdate(_selectedField!, value);
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }
}

class ExpectedPaymentDateDialog extends StatefulWidget {
  final PurchasesBill bill;
  const ExpectedPaymentDateDialog({super.key, required this.bill});

  @override
  State<ExpectedPaymentDateDialog> createState() =>
      _ExpectedPaymentDateDialogState();
}

class _ExpectedPaymentDateDialogState extends State<ExpectedPaymentDateDialog> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expected Payment Date',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    color: Color(0xFFE05A47),
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            const SizedBox(height: 16),
            // Calendar
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFE05A47), // coral
                  onPrimary: Colors.white,
                  onSurface: AppTheme.textPrimary,
                ),
              ),
              child: SizedBox(
                height: 300,
                child: CalendarDatePicker(
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onDateChanged: (date) {
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Notes Label
            Row(
              children: [
                Text(
                  'Notes',
                  style: AppTheme.bodyText.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text('*', style: TextStyle(color: Colors.red)),
              ],
            ),
            const SizedBox(height: 8),
            // Notes Text Area
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter notes here...',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: AppTheme.primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_notesController.text.trim().isEmpty) {
                      ZerpaiToast.error(context, 'Please enter notes');
                      return;
                    }
                    Navigator.pop(context, {
                      'date': _selectedDate,
                      'notes': _notesController.text,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('Save'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.borderLight),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonInputDialog extends StatefulWidget {
  final PurchasesBill bill;
  final String targetStatus;
  final Future<void> Function(String reason) onConfirm;

  const _ReasonInputDialog({
    required this.bill,
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
    final title = isVoid
        ? 'Enter a reason for marking this transaction as Void.'
        : 'Note down the reason as to why you want to undo a void transaction.';
    
    final confirmLabel = isVoid ? 'Void it' : 'Convert to Draft';

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

// ─── Month Picker Custom Popover ──────────────────────────────────────────

class _CalendarMonthPickerPopover extends StatefulWidget {
  final Widget child;
  final DateTime initialMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const _CalendarMonthPickerPopover({
    required this.child,
    required this.initialMonth,
    required this.onMonthSelected,
  });

  @override
  State<_CalendarMonthPickerPopover> createState() => _CalendarMonthPickerPopoverState();
}

class _CalendarMonthPickerPopoverState extends State<_CalendarMonthPickerPopover> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_overlayEntry != null) {
      _closeOverlay();
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 6),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _MonthPickerPopoverContent(
                    initialMonth: widget.initialMonth,
                    onMonthSelected: (date) {
                      widget.onMonthSelected(date);
                      _closeOverlay();
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void deactivate() {
    _closeOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _showOverlay,
        borderRadius: BorderRadius.circular(4),
        child: widget.child,
      ),
    );
  }
}

class _MonthPickerPopoverContent extends StatefulWidget {
  final DateTime initialMonth;
  final ValueChanged<DateTime> onMonthSelected;

  const _MonthPickerPopoverContent({
    required this.initialMonth,
    required this.onMonthSelected,
  });

  @override
  State<_MonthPickerPopoverContent> createState() => _MonthPickerPopoverContentState();
}

class _MonthPickerPopoverContentState extends State<_MonthPickerPopoverContent> {
  late int _pickerYear;

  @override
  void initState() {
    super.initState();
    _pickerYear = widget.initialMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _pickerYear--;
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    '«',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
              Text(
                '$_pickerYear',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _pickerYear++;
                  });
                },
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Text(
                    '»',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.borderLight),
          const SizedBox(height: 8),
          ...List.generate(3, (rowIndex) {
            return Padding(
              padding: EdgeInsets.only(top: rowIndex > 0 ? 8 : 0),
              child: Row(
                children: List.generate(4, (colIndex) {
                  final monthNum = rowIndex * 4 + colIndex + 1;
                  final isSelected = widget.initialMonth.year == _pickerYear &&
                      widget.initialMonth.month == monthNum;
                  final monthName =
                      DateFormat('MMM').format(DateTime(_pickerYear, monthNum));
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: colIndex > 0 ? 8 : 0),
                      child: InkWell(
                        onTap: () {
                          widget.onMonthSelected(DateTime(_pickerYear, monthNum));
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFF3F4F6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            monthName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF4B5563),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Bill Details Custom Popover ──────────────────────────────────────────

class _BillDetailsPopover extends StatefulWidget {
  final Widget child;
  final DateTime date;
  final List<PurchasesBill> bills;

  const _BillDetailsPopover({
    required this.child,
    required this.date,
    required this.bills,
  });

  @override
  State<_BillDetailsPopover> createState() => _BillDetailsPopoverState();
}

class _BillDetailsPopoverState extends State<_BillDetailsPopover> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (_overlayEntry != null) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final position = renderBox.localToGlobal(Offset.zero);

    // Determine space right vs left to decide positioning direction
    final double screenWidth = MediaQuery.of(context).size.width;
    final double spaceRight = screenWidth - position.dx - renderBox.size.width;
    final double spaceLeft = position.dx;

    final bool showOnRight = spaceRight >= 430 || spaceRight > spaceLeft;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              targetAnchor: showOnRight ? Alignment.centerRight : Alignment.centerLeft,
              followerAnchor: showOnRight ? Alignment.centerLeft : Alignment.centerRight,
              offset: Offset(showOnRight ? 10 : -10, 0),
              child: Material(
                color: Colors.transparent,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showOnRight)
                      CustomPaint(
                        size: const Size(8, 14),
                        painter: _BillDetailsPopoverArrowPainter(
                          color: Colors.white,
                          borderColor: const Color(0xFFE5E7EB),
                          pointingLeft: true,
                        ),
                      ),
                    Container(
                      width: 420,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _BillDetailsPopoverContent(
                        date: widget.date,
                        bills: widget.bills,
                        onClose: _closeOverlay,
                      ),
                    ),
                    if (!showOnRight)
                      CustomPaint(
                        size: const Size(8, 14),
                        painter: _BillDetailsPopoverArrowPainter(
                          color: Colors.white,
                          borderColor: const Color(0xFFE5E7EB),
                          pointingLeft: false,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void deactivate() {
    _closeOverlay();
    super.deactivate();
  }

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _showOverlay,
        child: widget.child,
      ),
    );
  }
}

class _BillDetailsPopoverContent extends StatelessWidget {
  final DateTime date;
  final List<PurchasesBill> bills;
  final VoidCallback onClose;

  const _BillDetailsPopoverContent({
    required this.date,
    required this.bills,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final dateBills = bills.where((b) {
      if (b.billDate == null) return false;
      final d = b.billDate!;
      return d.year == date.year && d.month == date.month && d.day == date.day;
    }).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM dd, yyyy').format(date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              InkWell(
                onTap: onClose,
                child: const Icon(
                  LucideIcons.x,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        // Table Header
        Container(
          color: const Color(0xFFF9FAFB),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  'BILL DETAILS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'AMOUNT',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'BALANCE',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.borderLight),
        // Rows
        ...dateBills.map((bill) {
          final isLast = bill == dateBills.last;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: () {
                              onClose();
                              context.go('/purchases/bills/${bill.id}');
                            },
                            child: Text(
                              bill.billNumber ?? '-',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            bill.vendorName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '₹${bill.total.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        '₹${bill.total.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1, color: AppTheme.borderLight),
            ],
          );
        }),
      ],
    );
  }
}

class _BillDetailsPopoverArrowPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final bool pointingLeft;

  _BillDetailsPopoverArrowPainter({
    required this.color,
    required this.borderColor,
    required this.pointingLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    if (pointingLeft) {
      path.moveTo(size.width, 0);
      path.lineTo(0, size.height / 2);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width, size.height / 2);
      path.lineTo(0, size.height);
    }
    path.close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    final mergePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (pointingLeft) {
      canvas.drawLine(Offset(size.width, 1), Offset(size.width, size.height - 1), mergePaint);
    } else {
      canvas.drawLine(const Offset(0, 1), Offset(0, size.height - 1), mergePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BillDetailsPopoverArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.pointingLeft != pointingLeft;
  }
}

// ─── Local Bill Amount Tooltip ────────────────────────────────────────────

class _BillAmountTooltip extends StatefulWidget {
  final String message;
  final Widget child;

  const _BillAmountTooltip({
    required this.message,
    required this.child,
  });

  @override
  State<_BillAmountTooltip> createState() => _BillAmountTooltipState();
}

class _BillAmountTooltipState extends State<_BillAmountTooltip> {
  OverlayEntry? _entry;
  final LayerLink _layerLink = LayerLink();


  void _showTooltip() {
    if (_entry != null) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    _entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topCenter,
                followerAnchor: Alignment.bottomCenter,
                offset: const Offset(0, -6),
                child: Material(
                  color: Colors.transparent,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937), // Dark slate
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -5,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: CustomPaint(
                            size: const Size(10, 5),
                            painter: _TooltipDownArrowPainter(const Color(0xFF1F2937)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_entry!);
  }

  void _hideTooltip() {
    if (_entry != null) {
      _entry?.remove();
      _entry = null;
    }
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) {
          _showTooltip();
        },
        onExit: (_) {
          _hideTooltip();
        },
        child: widget.child,
      ),
    );
  }
}

class _TooltipDownArrowPainter extends CustomPainter {
  final Color color;
  _TooltipDownArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TooltipDownArrowPainter oldDelegate) => false;
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


class _BillAttachmentOverlayContent extends StatefulWidget {
  final PurchasesBill bill;
  final WidgetRef ref;
  final VoidCallback onRefresh;
  final VoidCallback onClose;

  const _BillAttachmentOverlayContent({
    required this.bill,
    required this.ref,
    required this.onRefresh,
    required this.onClose,
  });

  @override
  State<_BillAttachmentOverlayContent> createState() =>
      _BillAttachmentOverlayContentState();
}

class _BillAttachmentOverlayContentState extends State<_BillAttachmentOverlayContent> {
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
          .from('bill_attachments')
          .select('id,file_name,file_url,file_size,file_type,created_at')
          .eq('bill_id', widget.bill.id)
          .order('created_at', ascending: false);
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
      final filePath = attachment['file_url']?.toString();
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
      final filePath = attachment['file_url']?.toString();
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
            'prefix': 'bills',
          },
        );

        final fileKey =
            response.data['fileKey'] ?? 'bills/${file.name}';

        final double sizeInKb = file.size / 1024;
        final String formattedSize = sizeInKb >= 1024
            ? '${(sizeInKb / 1024).toStringAsFixed(2)} MB'
            : '${sizeInKb.toStringAsFixed(2)} KB';

        // Save to DB
        await supabase.from('bill_attachments').insert({
          'bill_id': widget.bill.id,
          'file_name': file.name,
          'original_file_name': file.name,
          'file_url': fileKey,
          'file_size': formattedSize,
          'file_type': file.extension ?? 'bin',
          'uploaded_by': widget.ref.read(authUserProvider)?.id ?? '00000000-0000-0000-0000-000000000000',
          'entity_id':
              widget.ref.read(entityProvider).entityId ??
              '00000000-0000-0000-0000-000000000000',
        });
      }

      await _loadAttachments();
      widget.ref.invalidate(purchaseBillProvider(widget.bill.id));
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
      final filePath = attachment['file_url']?.toString();

      if (filePath != null) {
        final apiClient = ApiClient();
        await apiClient.delete(
          '/lookups/uploads',
          data: {'fileKey': filePath},
        );
      }

      await supabase.from('bill_attachments').delete().eq('id', id);

      await _loadAttachments();
      widget.ref.invalidate(purchaseBillProvider(widget.bill.id));
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
