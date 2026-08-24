import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/core/models/org_settings_model.dart';
import 'package:zerpai_erp/core/providers/org_settings_provider.dart';
import 'package:dio/dio.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/shared/widgets/pdf_corner_ribbon.dart';
import 'package:zerpai_erp/modules/sales/sales_return/providers/sales_return_provider.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/sales_return/models/sales_return_model.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/inventory_bin_batch_foc.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';
// dart:math imported above for ribbon painter

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/modules/sales/sales_return/presentation/pages/sales_return_bulk_update_dialog.dart';

class SalesReturnsOverviewPage extends ConsumerStatefulWidget {
  final String? initialRmaNumber;
  const SalesReturnsOverviewPage({super.key, this.initialRmaNumber});

  @override
  ConsumerState<SalesReturnsOverviewPage> createState() =>
      _SalesReturnsOverviewPageState();
}

final _inFmt = NumberFormat('#,##,##0.00', 'en_IN');

String _formatStatusText(String status) {
  if (status.toUpperCase() == 'RECEIVED') {
    return 'Approved';
  }
  if (status.isEmpty) return '';
  return status[0].toUpperCase() + status.substring(1).toLowerCase();
}

// ── Loading skeleton ──────────────────────────────────────────────────────────

class _SalesReturnsOverviewSkeleton extends StatelessWidget {
  const _SalesReturnsOverviewSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel — compact list skeleton
        SizedBox(
          width: 320,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toolbar
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: const [
                    Skeleton(width: 110, height: 16),
                    Spacer(),
                    Skeleton(width: 70, height: 28),
                    SizedBox(width: 8),
                    Skeleton(width: 28, height: 28),
                  ],
                ),
              ),
              // List items
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: 8,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppTheme.borderLight),
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Skeleton(width: 140, height: 13),
                        SizedBox(height: 6),
                        Skeleton(width: 100, height: 11),
                        SizedBox(height: 4),
                        Skeleton(width: 60, height: 11),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Vertical divider
        const VerticalDivider(width: 1, color: AppTheme.borderLight),
        // Right panel — detail skeleton
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: const [
                    Skeleton(width: 120, height: 18),
                    SizedBox(width: 12),
                    Skeleton(width: 70, height: 22, borderRadius: 12),
                    Spacer(),
                    Skeleton(width: 28, height: 28),
                    SizedBox(width: 8),
                    Skeleton(width: 28, height: 28),
                  ],
                ),
              ),
              // Action bar
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: AppTheme.bgLight,
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  children: const [
                    Skeleton(width: 50, height: 14),
                    SizedBox(width: 20),
                    Skeleton(width: 60, height: 14),
                    SizedBox(width: 20),
                    Skeleton(width: 80, height: 14),
                    SizedBox(width: 20),
                    Skeleton(width: 28, height: 14),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton(width: 180, height: 20),
                      const SizedBox(height: 8),
                      const Skeleton(width: 120, height: 14),
                      const SizedBox(height: 24),
                      const Skeleton(height: 40),
                      const SizedBox(height: 24),
                      // Items table header
                      Container(
                        height: 36,
                        color: const Color(0xFFF3F4F6),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: const [
                            Skeleton(width: 24, height: 12),
                            SizedBox(width: 16),
                            Expanded(child: Skeleton(height: 12)),
                            SizedBox(width: 16),
                            Skeleton(width: 70, height: 12),
                            SizedBox(width: 16),
                            Skeleton(width: 60, height: 12),
                            SizedBox(width: 16),
                            Skeleton(width: 70, height: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 1),
                      // Items rows
                      ...List.generate(
                        3,
                        (_) => Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          child: Row(
                            children: const [
                              Skeleton(width: 24, height: 12),
                              SizedBox(width: 16),
                              Expanded(child: Skeleton(height: 12)),
                              SizedBox(width: 16),
                              Skeleton(width: 70, height: 12),
                              SizedBox(width: 16),
                              Skeleton(width: 60, height: 12),
                              SizedBox(width: 16),
                              Skeleton(width: 70, height: 12),
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
        ),
      ],
    );
  }
}

class _SalesReturnsOverviewPageState
    extends ConsumerState<SalesReturnsOverviewPage> {
  /// Shared with the sales returns report page so a view starred in one place
  /// shows up as a favorite in the other (same `sales_returns` module bucket).
  static const _srFilterOptions = <FavoriteFilterOption>[
    FavoriteFilterOption(label: 'All', value: 'All'),
    FavoriteFilterOption(label: 'Draft', value: 'Draft'),
    FavoriteFilterOption(label: 'Pending Approval', value: 'Pending Approval'),
    FavoriteFilterOption(label: 'Approved', value: 'Approved'),
    FavoriteFilterOption(label: 'Declined', value: 'Declined'),
    FavoriteFilterOption(label: 'Received', value: 'Received'),
    FavoriteFilterOption(label: 'Closed', value: 'Closed'),
  ];

  Map<String, double> _colWidths = {
    'date': 140,
    'rmaNumber': 140,
    'salesOrderNumber': 160,
    'customerName': 180,
    'status': 140,
    'receiveStatus': 140,
    'refundStatus': 140,
    'returned': 120,
    'amountRefunded': 120,
  };

  // ignore: unused_element
  void _onColumnResize(String id, double delta) {
    final current = _colWidths[id] ?? 120;
    final next = (current + delta).clamp(60.0, 600.0);
    if ((next - current).abs() < 0.5) return;
    setState(() => _colWidths = {..._colWidths, id: next});
  }

  FavoriteFilterOption _activeOption = _srFilterOptions.first;
  String get _selectedView => _activeOption.label;
  bool _columnMenuOpen = false;
  bool _messageSidebarOpen = false;
  String _textMode = 'clip';
  String _sortColumn = _createdSortColumn;
  bool _sortAscending = false;
  List<ColumnConfig> _columns = _defaultColumns();
  int? _detailIndex;
  final Set<int> _selectedIndices = {};
  // ignore: prefer_final_fields
  bool _isLoadingEdit = false;
  bool _isDeleting = false;
  bool _isApproving = false;
  bool _isDeclining = false;
  final LayerLink _compactBulkLink = LayerLink();
  OverlayEntry? _compactBulkOverlay;
  final _moreMenuKey = GlobalKey();
  bool _showPdfView = false;
  bool _showReceiveForm = false;
  SalesReturnReceive? _selectedReceive;
  int _activeTab = 0; // 0 = Receives, 1 = Sales Orders
  bool _tabExpanded = true;

  static List<ColumnConfig> _defaultColumns() => [
    ColumnConfig(id: 'date', label: 'Date', orderIndex: 0, isLocked: true),
    ColumnConfig(id: 'rmaNumber', label: 'RMA#', orderIndex: 1, isLocked: true),
    ColumnConfig(id: 'salesOrderNumber', label: 'Sales Order#', orderIndex: 2),
    ColumnConfig(id: 'customerName', label: 'Customer Name', orderIndex: 3),
    ColumnConfig(id: 'status', label: 'Status', orderIndex: 4, isLocked: true),
    ColumnConfig(id: 'receiveStatus', label: 'Receive Status', orderIndex: 5),
    ColumnConfig(id: 'refundStatus', label: 'Refund Status', orderIndex: 6),
    ColumnConfig(id: 'returned', label: 'Returned', orderIndex: 7),
    ColumnConfig(id: 'amountRefunded', label: 'Amount Refunded', orderIndex: 8),
  ];

  List<ColumnConfig> get _visibleColumns =>
      _columns
          .where((c) => c.isVisible)
          .map(
            (c) => ColumnConfig(
              id: c.id,
              label: c.label,
              isVisible: c.isVisible,
              orderIndex: c.orderIndex,
              isLocked: c.isLocked,
            ),
          )
          .toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  double get _tableWidth {
    final colSum = _visibleColumns.fold(
      0.0,
      (sum, c) => sum + (_colWidths[c.id] ?? 120),
    );
    return colSum + 64;
  }

  /// Default sort: newest saved record first. Not a table column — no header
  /// carries it — so the arrow only appears once the user sorts explicitly.
  static const String _createdSortColumn = 'createdAt';

  int _compare(_SalesReturnRow a, _SalesReturnRow b, String column) {
    switch (column) {
      case _createdSortColumn:
        // Rows with no timestamp sort last rather than jumping to the top.
        final createdA = a.createdAt;
        final createdB = b.createdAt;
        if (createdA == null && createdB == null) return 0;
        if (createdA == null) return -1;
        if (createdB == null) return 1;
        return createdA.compareTo(createdB);
      case 'date':
      case 'createdTime':
      case 'lastModifiedTime':
        try {
          final partsA = a.date.split('-');
          final partsB = b.date.split('-');
          final dtA = DateTime(
            int.parse(partsA[2]),
            int.parse(partsA[1]),
            int.parse(partsA[0]),
          );
          final dtB = DateTime(
            int.parse(partsB[2]),
            int.parse(partsB[1]),
            int.parse(partsB[0]),
          );
          return dtA.compareTo(dtB);
        } catch (_) {
          return a.date.compareTo(b.date);
        }
      case 'rmaNumber':
        try {
          final numA = int.parse(a.rmaNumber.replaceAll(RegExp(r'\D'), ''));
          final numB = int.parse(b.rmaNumber.replaceAll(RegExp(r'\D'), ''));
          return numA.compareTo(numB);
        } catch (_) {
          return a.rmaNumber.compareTo(b.rmaNumber);
        }
      case 'salesOrderNumber':
        try {
          final numA = int.parse(
            a.salesOrderNumber.replaceAll(RegExp(r'\D'), ''),
          );
          final numB = int.parse(
            b.salesOrderNumber.replaceAll(RegExp(r'\D'), ''),
          );
          return numA.compareTo(numB);
        } catch (_) {
          return a.salesOrderNumber.compareTo(b.salesOrderNumber);
        }
      case 'customerName':
        return a.customerName.compareTo(b.customerName);
      case 'status':
        return a.status.compareTo(b.status);
      case 'receiveStatus':
        return a.receiveStatus.compareTo(b.receiveStatus);
      case 'refundStatus':
        return a.refundStatus.compareTo(b.refundStatus);
      case 'returned':
        final double qtyA = double.tryParse(a.returned) ?? 0.0;
        final double qtyB = double.tryParse(b.returned) ?? 0.0;
        return qtyA.compareTo(qtyB);
      case 'amountRefunded':
        final double amtA =
            double.tryParse(
              a.amountRefunded.replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0.0;
        final double amtB =
            double.tryParse(
              b.amountRefunded.replaceAll(RegExp(r'[^0-9.]'), ''),
            ) ??
            0.0;
        return amtA.compareTo(amtB);
      default:
        return 0;
    }
  }

  List<_SalesReturnRow> _buildRows() {
    final returnsAsync = ref.watch(salesReturnsListProvider(null));
    final returns = returnsAsync.valueOrNull ?? [];
    final customers = ref.watch(salesCustomersProvider).valueOrNull ?? [];
    final customerMap = {for (final c in customers) c.id: c.displayName};
    final products = ref.watch(itemsControllerProvider).items;
    final productMap = {
      for (final p in products)
        if (p.id != null) p.id!: p,
    };
    return returns.map((r) {
      String formattedDate = r.returnDate;
      try {
        final dt = DateTime.parse(r.returnDate);
        formattedDate = DateFormat('dd-MM-yyyy').format(dt);
      } catch (_) {}
      return _SalesReturnRow(
        date: formattedDate,
        rmaNumber: r.rmaNumber,
        salesOrderNumber: r.referenceNumber ?? '-',
        customerName:
            r.customerName ?? customerMap[r.customerId] ?? r.customerId,
        customerId: r.customerId,
        status: r.status,
        receiveStatus: r.status == 'received' ? 'Received' : 'Pending',
        refundStatus: '-',
        returned: '-',
        amountRefunded: '-',
        salesReturnId: r.id,
        warehouseId: r.warehouseId,
        createdAt: DateTime.tryParse(r.createdAt),
        items: List.generate(r.items.length, (i) {
          final sri = r.items[i];
          final product = productMap[sri.productId];
          final price = product?.sellingPrice;
          final qty = sri.returnQty.round();
          final rateStr = price != null ? '₹${_inFmt.format(price)}' : '-';
          final amountStr = price != null
              ? '₹${_inFmt.format(price * qty)}'
              : '-';
          return _LineItem(
            number: i + 1,
            name: product?.productName ?? sri.productId,
            hsn: product?.hsnCode ?? '',
            quantity: qty,
            receivedQuantity: sri.receivedQty.round(),
            unit: product?.unitName ?? '',
            rate: rateStr,
            amount: amountStr,
            productId: sri.productId,
            salesReturnItemId: sri.id,
            warehouseId: r.warehouseId ?? '',
          );
        }),
      );
    }).toList();
  }

  @override
  void didUpdateWidget(covariant SalesReturnsOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRmaNumber != oldWidget.initialRmaNumber &&
        widget.initialRmaNumber != null) {
      final rows = _filteredRows;
      final index = rows.indexWhere(
        (r) => r.rmaNumber == widget.initialRmaNumber,
      );
      if (index != -1) {
        setState(() {
          _detailIndex = index;
          _selectedReceive = null;
        });
      }
    }
  }

  int get _effectiveDetailIndex {
    final rows = _filteredRows;
    if (rows.isEmpty) return 0;
    if (_detailIndex != null &&
        _detailIndex! >= 0 &&
        _detailIndex! < rows.length) {
      return _detailIndex!;
    }
    if (widget.initialRmaNumber != null) {
      final index = rows.indexWhere(
        (r) => r.rmaNumber == widget.initialRmaNumber,
      );
      if (index != -1) return index;
    }
    return 0;
  }

  List<_SalesReturnRow> get _filteredRows {
    final rows = _buildRows();
    final list = _selectedView == 'All'
        ? List<_SalesReturnRow>.from(rows)
        : rows
              .where(
                (r) => r.status.toLowerCase() == _selectedView.toLowerCase(),
              )
              .toList();
    list.sort((a, b) {
      final cmp = _compare(a, b, _sortColumn);
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  void _showMoreMenu(BuildContext context) {
    final box = _moreMenuKey.currentContext?.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.of(context).size.width;
    double menuTop = 65;
    // Left-align: pin the LEFT edge of the main menu (200px wide) so its
    // right edge sits at the button's right edge. Submenu then expands rightward.
    double menuLeft = 8;
    if (box != null) {
      final pos = box.localToGlobal(Offset.zero);
      menuTop = pos.dy + box.size.height + 4;
      menuLeft = (pos.dx + box.size.width - 200).clamp(0.0, screenWidth - 200);
    }
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      useRootNavigator: true,
      builder: (dialogContext) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(dialogContext).pop(),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: menuTop,
            left: menuLeft,
            child: Material(
              color: Colors.transparent,
              child: _SrMoreMenu(
                sortColumn: _sortColumn,
                sortAscending: _sortAscending,
                onSortChanged: (col, asc) {
                  Navigator.of(dialogContext).pop();
                  setState(() {
                    _sortColumn = col;
                    _sortAscending = asc;
                  });
                },
                onExport: () => Navigator.of(dialogContext).pop(),
                onManageCustomFields: () {
                  Navigator.of(dialogContext).pop();
                  _openColumnCustomizer();
                },
                onRefreshList: () => Navigator.of(dialogContext).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openColumnCustomizer() {
    setState(() => _columnMenuOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) => ColumnCustomizerDialog(
          columns: _columns,
          onSave: (columns) {
            setState(() {
              _columns = columns
                  .map(
                    (c) => ColumnConfig(
                      id: c.id,
                      label: c.label,
                      isVisible: c.isVisible,
                      orderIndex: c.orderIndex,
                      isLocked: c.isLocked,
                    ),
                  )
                  .toList();
            });
            Navigator.of(dialogContext, rootNavigator: true).pop();
          },
        ),
      );
    });
  }

  void _onReceiveSubmitted(String salesReturnId, SalesReturnReceive receive) {
    setState(() {
      _showReceiveForm = false;
      _activeTab = 0;
    });
    // Refresh DB-backed providers so status persists across reloads
    ref.invalidate(salesReturnReceivesProvider(salesReturnId));
    ref.invalidate(salesReturnsListProvider(null));
    ZerpaiToast.success(
      context,
      'Receipt ${receive.receiveNumber} created successfully.',
    );
  }

  bool get _allSelected =>
      _filteredRows.isNotEmpty &&
      _selectedIndices.length == _filteredRows.length;

  void _toggleSelectAll(bool? value) {
    setState(() {
      if (value == true) {
        _selectedIndices.addAll(List.generate(_filteredRows.length, (i) => i));
      } else {
        _selectedIndices.clear();
      }
    });
  }

  void _toggleRow(int index, bool? value) {
    setState(() {
      if (value == true) {
        _selectedIndices.add(index);
      } else {
        _selectedIndices.remove(index);
      }
    });
  }

  void _showCompactBulkMenu(BuildContext context) {
    if (_compactBulkOverlay != null) return;
    final overlay = Overlay.of(context);
    _compactBulkOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closeCompactBulkMenu,
              child: Container(color: Colors.transparent),
            ),
          ),
          CompositedTransformFollower(
            link: _compactBulkLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 38),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
              child: Container(
                width: 180,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.borderLight),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SrBulkMenuOption(
                      label: 'Bulk Update',
                      onTap: () {
                        _closeCompactBulkMenu();
                        showSalesReturnBulkUpdateDialog(context);
                      },
                    ),
                    _SrBulkMenuOption(
                      label: 'Export as PDF',
                      onTap: _closeCompactBulkMenu,
                    ),
                    _SrBulkMenuOption(
                      label: 'Print',
                      onTap: _closeCompactBulkMenu,
                    ),
                    _SrBulkMenuOption(
                      label: 'Delete',
                      onTap: () {
                        _closeCompactBulkMenu();
                        setState(() => _selectedIndices.clear());
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_compactBulkOverlay!);
  }

  void _closeCompactBulkMenu() {
    _compactBulkOverlay?.remove();
    _compactBulkOverlay = null;
  }

  /// Opens the create form in edit mode for this return.
  ///
  /// The id travels as a query parameter and the form loads the record itself.
  /// Passing a `SalesReturnEditData` via `state.extra` silently does not work:
  /// the app's top-level redirect rewrites the path to add the org system id,
  /// and GoRouter drops `extra` across a redirect — the form would open blank.
  /// A query param also makes the edit URL refresh-safe and shareable.
  void _openEditPage(_SalesReturnRow row) {
    final id = row.salesReturnId;
    if (id.isEmpty) {
      ZerpaiToast.error(context, 'This return cannot be edited.');
      return;
    }
    context.go('${AppRoutes.salesReturnsCreate}?edit_id=$id');
  }

  /// Approves a draft return. The server stamps `approved_by`/`approved_at`
  /// and flips `status` to `approved`, which unblocks receiving.
  Future<void> _approveSalesReturn(_SalesReturnRow row) async {
    final id = row.salesReturnId;
    if (id.isEmpty) {
      ZerpaiToast.error(context, 'This return cannot be approved.');
      return;
    }

    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Approve Sales Return',
      message:
          'Approve ${row.rmaNumber}? The return moves out of draft and can '
          'then be received.',
      confirmLabel: 'Approve',
      variant: ZerpaiConfirmationVariant.success,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isApproving = true);
    try {
      await ref.read(updateSalesReturnStatusProvider)(id, 'approved');
      if (!mounted) return;
      ref.invalidate(salesReturnsListProvider(null));
      ZerpaiToast.success(context, 'Sales return approved.');
    } catch (e, st) {
      AppLogger.error(
        'Failed to approve sales return',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to approve sales return.');
      }
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  /// Declines the return. Terminal for the approval path — a declined return
  /// is never received, so the action is hidden once goods are back in.
  Future<void> _markSalesReturnDeclined(_SalesReturnRow row) async {
    final id = row.salesReturnId;
    if (id.isEmpty) {
      ZerpaiToast.error(context, 'This return cannot be declined.');
      return;
    }
    if (_isDeclining) return;

    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Mark as Declined',
      message:
          'Decline ${row.rmaNumber}? The customer will not be credited for '
          'this return.',
      confirmLabel: 'Mark as Declined',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeclining = true);
    try {
      await ref.read(updateSalesReturnStatusProvider)(id, 'declined');
      if (!mounted) return;
      ref.invalidate(salesReturnsListProvider(null));
      ZerpaiToast.success(context, 'Sales return marked as declined.');
    } catch (e, st) {
      AppLogger.error(
        'Failed to decline sales return',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to decline sales return.');
      }
    } finally {
      if (mounted) setState(() => _isDeclining = false);
    }
  }

  /// Deletes the return after confirmation. The server cascades to
  /// `sales_return_items` and any receives, so this is one call.
  Future<void> _deleteSalesReturn(_SalesReturnRow row) async {
    final id = row.salesReturnId;
    if (id.isEmpty) {
      ZerpaiToast.error(context, 'This return cannot be deleted.');
      return;
    }

    final confirmed = await showZerpaiConfirmationDialog(
      context,
      title: 'Delete Sales Return',
      message:
          'Do you really want to delete ${row.rmaNumber}? Its line items and '
          'any return receipts will be deleted too. This cannot be undone.',
      confirmLabel: 'Delete',
      variant: ZerpaiConfirmationVariant.danger,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(deleteSalesReturnProvider)(id);
      if (!mounted) return;
      // Close the detail pane first — the record it renders is gone.
      setState(() {
        _detailIndex = null;
        _showReceiveForm = false;
        _showPdfView = false;
        _selectedReceive = null;
      });
      ref.invalidate(salesReturnsListProvider(null));
      ref.invalidate(salesReturnReceivesProvider(id));
      ZerpaiToast.success(context, 'Sales return deleted successfully.');
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete sales return',
        error: e,
        stackTrace: st,
        module: 'sales_return',
      );
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to delete sales return.');
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  static Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return AppTheme.primaryBlue;
      case 'RECEIVED':
        return AppTheme.successGreen;
      case 'DECLINED':
        return AppTheme.errorRed;
      case 'DRAFT':
        return AppTheme.textSecondary;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(salesReturnsListProvider(null));
    final customersAsync = ref.watch(salesCustomersProvider);
    final visibleColumns = _visibleColumns;
    final tableWidth = _tableWidth;
    final rows = _filteredRows;
    final selectedHistoryId = rows.isEmpty
        ? null
        : rows[_effectiveDetailIndex].salesReturnId;
    final messageDrawerWidth = MediaQuery.sizeOf(
      context,
    ).width.clamp(320.0, 400.0).toDouble();

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useTopPadding: false,
      useHorizontalPadding: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_columnMenuOpen) {
            setState(() => _columnMenuOpen = false);
          }
        },
        child: Container(
          color: AppTheme.backgroundColor,
          child: Stack(
            children: [
              if ((returnsAsync.isLoading && !returnsAsync.hasValue) ||
                  (customersAsync.isLoading && !customersAsync.hasValue))
                const _SalesReturnsOverviewSkeleton()
              else
                Positioned.fill(
                  child: _buildSplitView(visibleColumns, tableWidth),
                ),
              // Column menu overlay
              if (_columnMenuOpen)
                Positioned(
                  top: 148,
                  left: 14,
                  child: Material(
                    elevation: 0,
                    color: Colors.transparent,
                    child: Container(
                      width: 200,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.textPrimary.withValues(alpha: 0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _ColumnMenuOption(
                            label: 'Customize Columns',
                            icon: LucideIcons.columns,
                            selected: false,
                            onTap: _openColumnCustomizer,
                          ),
                          _ColumnMenuOption(
                            label: _textMode == 'clip'
                                ? 'Clip Text'
                                : 'Wrap Text',
                            icon: _textMode == 'clip'
                                ? LucideIcons.minus
                                : LucideIcons.alignLeft,
                            selected: false,
                            onTap: () => setState(() {
                              _textMode = _textMode == 'clip' ? 'wrap' : 'clip';
                              _columnMenuOpen = false;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                top: 0,
                bottom: 0,
                width: messageDrawerWidth,
                right: _messageSidebarOpen ? 0 : -messageDrawerWidth,
                child: IgnorePointer(
                  ignoring: !_messageSidebarOpen,
                  child: _SalesReturnHistorySidebar(
                    salesReturnId: selectedHistoryId,
                    onClose: () => setState(() => _messageSidebarOpen = false),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Split view ───────────────────────────────────────────────────────────────

  Widget _buildSplitView(List<ColumnConfig> visibleColumns, double tableWidth) {
    return Row(
      children: [
        _buildCompactList(),
        const VerticalDivider(width: 1, color: AppTheme.borderLight),
        Expanded(child: _buildDetailPanel()),
      ],
    );
  }

  Widget _buildCompactBulkToolbar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Checkbox(
              value: _selectedIndices.isNotEmpty,
              tristate: false,
              onChanged: (v) => _toggleSelectAll(_allSelected ? false : true),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: AppTheme.primaryBlue,
              side: const BorderSide(color: Color(0xFFADB5BD), width: 1.5),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          CompositedTransformTarget(
            link: _compactBulkLink,
            child: _SrBulkActionBtn(
              label: 'Bulk Actions',
              trailingIcon: LucideIcons.chevronDown,
              onTap: () => _showCompactBulkMenu(context),
            ),
          ),
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: AppTheme.borderLight,
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${_selectedIndices.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Selected',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(() => _selectedIndices.clear()),
            child: const Icon(
              LucideIcons.x,
              size: 20,
              color: Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactList() {
    return Container(
      width: 460,
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _selectedIndices.isNotEmpty
              ? _buildCompactBulkToolbar()
              : Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.borderLight, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          LucideIcons.arrowLeft,
                          size: 20,
                          color: AppTheme.textPrimary,
                        ),
                        onPressed: () =>
                            context.go(AppRoutes.salesReturnsReport),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      FavoriteFilterDropdown(
                        moduleName: 'sales_returns',
                        options: _srFilterOptions,
                        selectedOption: _activeOption,
                        showChevron: true,
                        isCompact: true,
                        onChanged: (opt) {
                          setState(() {
                            _activeOption = opt;
                            _columnMenuOpen = false;
                            _selectedIndices.clear();
                          });
                        },
                      ),
                      const Spacer(),
                      _FilledActionSquare(
                        icon: LucideIcons.plus,
                        onTap: () =>
                            context.go(AppRoutes.salesReturnsCreate),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        key: _moreMenuKey,
                        child: _OutlineActionSquare(
                          icon: LucideIcons.moreHorizontal,
                          onTap: () => _showMoreMenu(context),
                        ),
                      ),
                    ],
                  ),
                ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _filteredRows.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppTheme.borderLight),
              itemBuilder: (context, index) => _SrCompactItem(
                row: _filteredRows[index],
                selected: index == _effectiveDetailIndex,
                checked: _selectedIndices.contains(index),
                onCheckChanged: (v) => _toggleRow(index, v),
                onTap: () => setState(() {
                  _detailIndex = index;
                  _showReceiveForm = false;
                  _showPdfView = false;
                  _selectedReceive = null;
                  _messageSidebarOpen = false;
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    final rows = _filteredRows;
    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No sales returns found',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    final rawRow = rows[_effectiveDetailIndex];
    final dbReceivesAsync = ref.watch(
      salesReturnReceivesProvider(rawRow.salesReturnId),
    );
    final dbReceives = dbReceivesAsync.valueOrNull ?? [];

    if (_showReceiveForm) {
      return _SrReceiveForm(
        row: rawRow,
        salesReturnId: rawRow.salesReturnId,
        warehouseId: rawRow.warehouseId,
        onBack: () => setState(() => _showReceiveForm = false),
        onSubmit: (receive) =>
            _onReceiveSubmitted(rawRow.salesReturnId, receive),
      );
    }
    if (_selectedReceive != null) {
      final products = ref.watch(itemsControllerProvider).items;
      final productMap = {for (var p in products) p.id!: p};
      return Container(
        color: AppTheme.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Receive Detail Header
            Container(
              height: 64,
              padding: const EdgeInsets.only(left: 20, right: 8),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: () => setState(() => _selectedReceive = null),
                        child: Text(
                          '< ${rawRow.rmaNumber}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedReceive!.receiveNumber,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 20, color: AppTheme.textSecondary),
                    onPressed: () async {
                      final confirmed = await showZerpaiConfirmationDialog(
                        context,
                        title: 'Delete Return Receipt',
                        message: 'Do you really want to delete this Return Receipt?',
                        confirmLabel: 'Delete',
                        variant: ZerpaiConfirmationVariant.warning,
                      );
                      if (!confirmed || !mounted) return;
                      try {
                        final deleteFn = ref.read(deleteSalesReturnReceiveProvider);
                        await deleteFn(rawRow.salesReturnId, _selectedReceive!.id);
                        if (mounted) {
                          ref.invalidate(salesReturnReceivesProvider(rawRow.salesReturnId));
                          ref.invalidate(salesReturnsListProvider(null));
                          ZerpaiToast.success(context, 'Return receipt deleted successfully.');
                          setState(() => _selectedReceive = null);
                        }
                      } catch (_) {
                        if (mounted) ZerpaiToast.error(context, 'Failed to delete return receipt.');
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20, color: AppTheme.textSecondary),
                    onPressed: () => setState(() => _selectedReceive = null),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _SrReceiveDetailInlineView(
                receive: _selectedReceive!,
                row: rawRow,
                productMap: productMap,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            height: 64,
            padding: const EdgeInsets.only(left: 20, right: 8),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                Text(
                  rawRow.rmaNumber,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(rawRow.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatStatusText(rawRow.status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _statusColor(rawRow.status),
                    ),
                  ),
                ),
                const Spacer(),
                _DetailHeaderIconButton(
                  icon: LucideIcons.messageSquare,
                  onTap: () {
                    final willOpen = !_messageSidebarOpen;
                    setState(() => _messageSidebarOpen = willOpen);
                    if (willOpen) {
                      ref.invalidate(
                        salesReturnHistoryProvider(rawRow.salesReturnId),
                      );
                    }
                  },
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: AppTheme.borderLight,
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => context.go(AppRoutes.salesReturns),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: Icon(
                        LucideIcons.x,
                        size: 20,
                        color: AppTheme.errorRed,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Action bar
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: AppTheme.bgLight,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                _DetailActionBtn(
                  icon: _isLoadingEdit
                      ? LucideIcons.loader
                      : LucideIcons.pencil,
                  label: _isLoadingEdit ? 'Loading...' : 'Edit',
                  onTap: _isLoadingEdit ? () {} : () => _openEditPage(rawRow),
                ),
                const _DetailActionDivider(),
                // Only a draft can be approved; past that the return is already
                // through the gate and Receive takes over.
                if (rawRow.status.toLowerCase() == 'draft') ...[
                  _DetailActionBtn(
                    icon: _isApproving
                        ? LucideIcons.loader
                        : LucideIcons.checkCircle,
                    label: _isApproving ? 'Approving...' : 'Approve',
                    onTap: _isApproving
                        ? () {}
                        : () => _approveSalesReturn(rawRow),
                  ),
                  const _DetailActionDivider(),
                ],
                if (dbReceives.isEmpty)
                  _DetailActionBtn(
                    icon: LucideIcons.packageCheck,
                    label: 'Receive',
                    onTap: () => setState(() {
                      _showReceiveForm = true;
                      _showPdfView = false;
                    }),
                  )
                else
                  _DetailActionBtn(
                    icon: LucideIcons.filePlus,
                    label: 'Create Credit Note',
                    // Pass the RMA# and let the credit note form load the return
                    // itself, so every line comes across rather than just the
                    // first — and so the params match what the route reads.
                    onTap: () => context.go(
                      Uri(
                        path: AppRoutes.salesCreditNotesCreate,
                        queryParameters: {'from_rma': rawRow.rmaNumber},
                      ).toString(),
                    ),
                  ),
                const _DetailActionDivider(),
                const _PdfPrintBtn(),
                _DetailMoreBtn(
                  onDelete: _isDeleting
                      ? null
                      : () => _deleteSalesReturn(rawRow),
                  // Received goods are already back in stock, and a declined
                  // return has nowhere further to go.
                  onMarkDeclined:
                      _isDeclining ||
                          const {
                            'declined',
                            'received',
                          }.contains(rawRow.status.toLowerCase())
                      ? null
                      : () => _markSalesReturnDeclined(rawRow),
                ),
              ],
            ),
          ),
          // Receives / Sales Orders tab — fixed at top, never scrolls away.
          // Dropped entirely when neither tab has anything behind it, so the
          // pane never shows a bare strip with just a chevron in it.
          if (_hasReceivesTab(rawRow, dbReceives))
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _buildReceivesTab(rawRow, dbReceives),
            ),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // (Receives/Sales Orders tab is fixed above the scroll view)
                  const SizedBox(height: 16),
                  // Show PDF View toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Text(
                        'Show PDF View',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Switch(
                        value: _showPdfView,
                        onChanged: (v) => setState(() => _showPdfView = v),
                        activeThumbColor: AppTheme.primaryBlue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Document preview — capped and centred so the page reads as
                  // a document rather than stretching the full detail pane.
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: _showPdfView
                          ? _SrPdfPreview(row: rawRow)
                          : _SrDocumentPreview(row: rawRow),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The tab strip only earns its space when one of its two tabs has rows:
  /// a receive against the return, or an originating sales order.
  bool _hasReceivesTab(
    _SalesReturnRow row,
    List<SalesReturnReceive> dbReceives,
  ) => dbReceives.isNotEmpty || row.salesOrderNumber != '-';

  Widget _buildReceivesTab(
    _SalesReturnRow row,
    List<SalesReturnReceive> dbReceives,
  ) {
    if (!_hasReceivesTab(row, dbReceives)) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab header row
          GestureDetector(
            onTap: () => setState(() => _tabExpanded = !_tabExpanded),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
                borderRadius: BorderRadius.vertical(top: Radius.circular(5)),
              ),
              child: Row(
                children: [
                  if (dbReceives.isNotEmpty)
                    GestureDetector(
                      onTap: () => setState(() => _activeTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: _activeTab == 0
                              ? const Border(
                                  bottom: BorderSide(
                                    color: AppTheme.primaryBlue,
                                    width: 2,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Receives',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _activeTab == 0
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: _activeTab == 0
                                    ? AppTheme.primaryBlue
                                    : AppTheme.borderLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${dbReceives.length}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (row.salesOrderNumber != '-')
                    GestureDetector(
                      onTap: () => setState(() => _activeTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: (_activeTab == 1 || dbReceives.isEmpty)
                              ? const Border(
                                  bottom: BorderSide(
                                    color: AppTheme.primaryBlue,
                                    width: 2,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Sales Orders',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: (_activeTab == 1 || dbReceives.isEmpty)
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: (_activeTab == 1 || dbReceives.isEmpty)
                                    ? AppTheme.primaryBlue
                                    : AppTheme.borderLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '1',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _tabExpanded = !_tabExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: AnimatedRotation(
                        turns: _tabExpanded ? 0 : -0.5,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          LucideIcons.chevronDown,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab content
          if (_tabExpanded && _activeTab == 0 && dbReceives.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Receive#',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Received On',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(width: 32),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            ...dbReceives.map((receive) {
              String displayDate = receive.receiveDate;
              try {
                final dt = DateTime.parse(receive.receiveDate);
                displayDate =
                    '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
              } catch (_) {}
              return InkWell(
                onTap: () {
                  setState(() => _selectedReceive = receive);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          receive.receiveNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(
                          displayDate,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                    ],
                  ),
                ),
              );
            }),
          ] else if (_tabExpanded && row.salesOrderNumber != '-') ...[
            // Sales Orders tab — header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Sales Order#',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            InkWell(
              onTap: () async {
                try {
                  final supabase = Supabase.instance.client;
                  final res = await supabase
                      .from('sales_orders')
                      .select('id')
                      .eq('sales_order_number', row.salesOrderNumber)
                      .maybeSingle();
                  
                  if (!mounted) return;
                  if (res != null && res['id'] != null) {
                    final orgSystemId = GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
                    context.pushNamed(
                      AppRoutes.salesOrdersDetail,
                      pathParameters: {'orgSystemId': orgSystemId, 'id': res['id']},
                    );
                  } else {
                    ZerpaiToast.error(context, 'Sales Order not found.');
                  }
                } catch (e) {
                  if (!mounted) return;
                  ZerpaiToast.error(context, 'Error loading Sales Order.');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.salesOrderNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        row.date,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text(
                        _formatStatusText(row.status),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(row.status),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `BILL TO` name, linked through to the customer's overview page. Renders as
/// plain text when the return carries no resolvable customer id, so a bad link
/// is never offered.
class _SrCustomerLink extends StatefulWidget {
  const _SrCustomerLink({required this.name, required this.customerId});

  final String name;
  final String? customerId;

  @override
  State<_SrCustomerLink> createState() => _SrCustomerLinkState();
}

class _SrCustomerLinkState extends State<_SrCustomerLink> {
  bool _hovered = false;

  void _openCustomer() {
    final id = widget.customerId;
    if (id == null || id.isEmpty) return;
    // The customer route is nested under the org shell, so the id of the
    // active org has to travel with it.
    final orgSystemId =
        GoRouterState.of(context).pathParameters['orgSystemId'] ?? '';
    context.goNamed(
      AppRoutes.salesCustomersDetail,
      pathParameters: {'orgSystemId': orgSystemId, 'id': id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final linkable = widget.customerId != null && widget.customerId!.isNotEmpty;
    final text = Text(
      widget.name,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: linkable ? AppTheme.primaryBlue : AppTheme.textPrimary,
        decoration: _hovered ? TextDecoration.underline : TextDecoration.none,
        decorationColor: AppTheme.primaryBlue,
      ),
    );

    if (!linkable) return text;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _openCustomer,
        behavior: HitTestBehavior.opaque,
        child: ZTooltip(message: 'View customer details', child: text),
      ),
    );
  }
}

// ── Document preview ──────────────────────────────────────────────────────────

class _SrDocumentPreview extends ConsumerWidget {
  const _SrDocumentPreview({required this.row});
  final _SalesReturnRow row;

  static const Color _divider = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Title row: SALES RETURN (left) + BILL TO (right) ──────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: title + RMA#
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SALES RETURN',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text(
                            'RMA# ',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            row.rmaNumber,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right: BILL TO
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'BILL TO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _SrCustomerLink(
                      name: row.customerName,
                      customerId: row.customerId,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ── Return Status ─────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFFE89A1B), width: 3),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Return Status',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  color: AppTheme.primaryBlue,
                  child: Text(
                    _formatStatusText(row.status),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (row.status == 'received') ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0xFFE89A1B), width: 3),
                ),
              ),
              child: const Row(
                children: [
                  Text(
                    'Receive Status',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  SizedBox(width: 24),
                  Text(
                    'Received',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // ── DATE ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const SizedBox(
                  width: 140,
                  child: Text(
                    'DATE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  row.date,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // ── Items table header ────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              border: Border(bottom: BorderSide(color: _divider)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: const Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'ITEMS & DESCRIPTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 120,
                  child: Text(
                    'QUANTITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'RATE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 90,
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
          // ── Items body ────────────────────────────────────────────────
          if (row.items.isEmpty)
            const SizedBox(height: 48)
          else
            ...row.items.map((item) => _SrLineItemRow(item: item)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Receive form ──────────────────────────────────────────────────────────────

class _SrReceiveForm extends ConsumerStatefulWidget {
  const _SrReceiveForm({
    required this.row,
    required this.salesReturnId,
    this.warehouseId,
    required this.onBack,
    required this.onSubmit,
  });
  final _SalesReturnRow row;
  final String salesReturnId;
  final String? warehouseId;
  final VoidCallback onBack;
  final void Function(SalesReturnReceive receive) onSubmit;

  @override
  ConsumerState<_SrReceiveForm> createState() => _SrReceiveFormState();
}

class _SrReceiveFormState extends ConsumerState<_SrReceiveForm> {
  bool _isSaving = false;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _notesCtrl;
  late final List<TextEditingController> _qtyCtrlrs;
  final Set<int> _removedItemIndices = {};

  bool _manualMode = false;
  final List<TextEditingController> _manualItemCtrlrs = [];
  final List<TextEditingController> _manualQtyCtrlrs = [];
  final Map<int, List<Map<String, String>>> _batchDataByItemIndex = {};

  /// The warehouse the batch dialog actually binned into.
  ///
  /// Most returns carry no `warehouse_id`, so the dialog falls back to the
  /// branch default. The receive payload must send that same warehouse — the
  /// backend rejects batches whose header has none, and the batch rows
  /// themselves have NOT NULL `warehouse_id`.
  Warehouse? _receivingWarehouse;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl = TextEditingController(
      text:
          '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}',
    );
    _notesCtrl = TextEditingController();
    _qtyCtrlrs = widget.row.items
        .map((item) => TextEditingController(text: '${item.quantity}'))
        .toList();
    _addManualRow();
  }

  void _addManualRow() {
    _manualItemCtrlrs.add(TextEditingController());
    _manualQtyCtrlrs.add(TextEditingController());
  }

  void _removeManualRow(int i) {
    _manualItemCtrlrs[i].dispose();
    _manualQtyCtrlrs[i].dispose();
    setState(() {
      _manualItemCtrlrs.removeAt(i);
      _manualQtyCtrlrs.removeAt(i);
      if (_manualItemCtrlrs.isEmpty) _addManualRow();
    });
  }

  void _addAllItems() {
    for (final item in widget.row.items) {
      _manualItemCtrlrs.add(TextEditingController(text: item.name));
      _manualQtyCtrlrs.add(TextEditingController(text: '${item.quantity}'));
    }
    setState(() {});
  }

  double _quantityForItem(int index) {
    return double.tryParse(_qtyCtrlrs[index].text.trim()) ??
        widget.row.items[index].quantity.toDouble();
  }

  String _formatQuantity(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }

  Future<void> _submitReceive() async {
    final dateText = _dateCtrl.text.trim();
    if (dateText.isEmpty) {
      ZerpaiToast.error(context, 'Please enter a receive date.');
      return;
    }

    // Block save if any non-removed item has no batch selected
    for (var i = 0; i < widget.row.items.length; i++) {
      if (_removedItemIndices.contains(i)) continue;
      final batches = _batchDataByItemIndex[i] ?? [];
      if (batches.isEmpty) {
        final itemName = widget.row.items[i].name;
        ZerpaiToast.error(
          context,
          'Please add a batch for "$itemName" before saving.',
        );
        return;
      }
    }

    // Parse dd-MM-yyyy → yyyy-MM-dd for the API
    String isoDate = dateText;
    try {
      final parts = dateText.split('-');
      if (parts.length == 3) {
        isoDate = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    } catch (_) {}

    // The warehouse the batches were actually binned into. `widget.warehouseId`
    // is null on most returns, and sending null with batches is rejected by the
    // backend outright.
    final warehouseId = _receivingWarehouse?.id ?? widget.warehouseId ?? '';

    final hasBatches = _batchDataByItemIndex.values.any(
      (list) => list.isNotEmpty,
    );
    if (hasBatches && warehouseId.isEmpty) {
      ZerpaiToast.error(
        context,
        'No warehouse resolved for these batches — reopen Add Batches and try again.',
      );
      return;
    }

    // batch_id and bin_id are NOT NULL uuids; an empty string is not a valid
    // uuid and fails at insert with an opaque error. Catch it here instead.
    for (final entry in _batchDataByItemIndex.entries) {
      for (final b in entry.value) {
        if ((b['batchId'] ?? '').isEmpty || (b['binId'] ?? '').isEmpty) {
          final name = widget.row.items[entry.key].name;
          ZerpaiToast.error(
            context,
            'Select a bin and batch for "$name" before saving.',
          );
          return;
        }
      }
    }

    final items = List.generate(widget.row.items.length, (i) {
      if (_removedItemIndices.contains(i)) return null;
      final item = widget.row.items[i];
      final batchMaps = _batchDataByItemIndex[i] ?? [];
      final batches = batchMaps.map((b) {
        return CreateReceiveBatchPayload(
          batchId: b['batchId'] ?? '',
          layerId: b['layerId'],
          warehouseId: warehouseId,
          binId: b['binId'] ?? '',
          quantity: double.tryParse(b['qtyOut'] ?? '0') ?? 0,
          focQuantity: double.tryParse(b['foc'] ?? '0') ?? 0,
          purchaseRate: double.tryParse(b['prate'] ?? ''),
          mrp: double.tryParse(b['mrp'] ?? ''),
          expiryDate: b['expDate'],
          mfgDate: b['mfgDate'],
          mfgBatchNo: b['mfgBatch'],
        );
      }).toList();
      return CreateReceiveItemPayload(
        productId: item.productId,
        salesReturnItemId: item.salesReturnItemId.isNotEmpty
            ? item.salesReturnItemId
            : null,
        receivingQty: _quantityForItem(i),
        returnQty: item.quantity.toDouble(),
        batches: batches,
      );
    }).whereType<CreateReceiveItemPayload>().toList();

    final payload = CreateReceivePayload(
      receiveDate: isoDate,
      warehouseId: warehouseId.isEmpty ? null : warehouseId,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      items: items,
    );

    setState(() => _isSaving = true);
    try {
      final createFn = ref.read(createSalesReturnReceiveProvider);
      final receive = await createFn(widget.salesReturnId, payload);
      if (mounted) widget.onSubmit(receive);
    } catch (e) {
      // The generic message hid the real cause (a missing warehouse, a bad FK).
      // Log the detail and show whatever the server actually said.
      AppLogger.error(
        'Failed to save sales return receive',
        error: e,
        module: 'SalesReturnOverview',
        data: {
          'salesReturnId': widget.salesReturnId,
          'warehouseId': warehouseId,
        },
      );
      if (mounted) {
        ZerpaiToast.error(context, _receiveErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Pulls the server's message out of a Dio error so the user sees the actual
  /// reason ("Warehouse is required to save receive batches") rather than a
  /// generic retry prompt that gives them nothing to act on.
  String _receiveErrorMessage(Object error) {
    const fallback = 'Failed to save receive. Please try again.';
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['error'];
        if (message is String && message.trim().isNotEmpty) return message;
        if (message is List && message.isNotEmpty) {
          return message.join(', ');
        }
      }
    }
    return fallback;
  }

  /// Resolves the warehouse the returned goods are being received into.
  ///
  /// Bins are warehouse-scoped, so this must land on exactly one warehouse
  /// before the batch dialog opens. The return's own warehouse always wins; the
  /// branch default is only a fallback for returns saved without one. Never
  /// prompts — receiving should not stop to ask.
  Warehouse? _resolveReceivingWarehouse(
    _LineItem item,
    List<Warehouse> warehouses,
  ) {
    if (warehouses.isEmpty) return null;

    Warehouse? byId(String? id) {
      if (id == null || id.isEmpty || id == 'sales-return-overview') {
        return null;
      }
      return warehouses.where((w) => w.id == id).firstOrNull;
    }

    // 1. The warehouse recorded on this return — the line's, then the header's.
    //    `sales_return_items` has no warehouse column, so both resolve to
    //    `sales_returns.warehouse_id`; the line is checked first in case a
    //    future per-line warehouse lands.
    final explicit = byId(item.warehouseId) ?? byId(widget.warehouseId);
    if (explicit != null) return explicit;

    // 2. Nothing recorded on the return. Fall back rather than interrupt.
    final active = warehouses.where((w) => w.isActive).toList();
    final pool = active.isEmpty ? warehouses : active;
    return pool.where((w) => w.isDefaultForBranch).firstOrNull ?? pool.first;
  }

  Future<void> _openBatchesForItem(int index) async {
    final item = widget.row.items[index];

    // Await the master rather than reading a snapshot: on a cold open the list
    // is still in flight, and an empty snapshot would leave bins unscoped.
    List<Warehouse> warehouses;
    try {
      warehouses = await ref.read(salesReturnsWarehousesProvider.future);
    } catch (e) {
      AppLogger.error(
        'Failed to load warehouses for batch selection',
        error: e,
        module: 'SalesReturnOverview',
      );
      warehouses = const [];
    }
    if (!mounted) return;

    final warehouse = _resolveReceivingWarehouse(item, warehouses);
    if (warehouse == null) {
      ZerpaiToast.show(
        context,
        'No warehouse is available — bins are warehouse-specific.',
        isError: true,
      );
      return;
    }

    // Remember it: the receive payload must declare the same warehouse the
    // batches were binned into.
    _receivingWarehouse = warehouse;

    final warehouseId = warehouse.id;
    final resolvedWarehouseName = warehouse.name;

    final result = await showDialog<PicklistBatchDialogResult>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => PicklistSelectBatchesDialog(
        itemName: item.name,
        productId: item.productId,
        warehouseName: resolvedWarehouseName,
        warehouseId: warehouseId,
        totalQuantity: _quantityForItem(index),
        savedBatchData: _batchDataByItemIndex[index],
      ),
    );

    if (result == null || !mounted) return;
    setState(() {
      _batchDataByItemIndex[index] =
          result.batchDataList ?? <Map<String, String>>[];
      if (result.overwriteLineItem) {
        _qtyCtrlrs[index].text = _formatQuantity(result.appliedQuantity);
      }
    });
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    for (final c in _qtyCtrlrs) {
      c.dispose();
    }
    for (final c in _manualItemCtrlrs) {
      c.dispose();
    }
    for (final c in _manualQtyCtrlrs) {
      c.dispose();
    }
    super.dispose();
  }

  int get _totalItems => _manualMode
      ? _manualQtyCtrlrs.fold(0, (sum, c) => sum + (int.tryParse(c.text) ?? 0))
      : widget.row.items
            .asMap()
            .entries
            .where((e) => !_removedItemIndices.contains(e.key))
            .fold(0, (sum, e) => sum + e.value.quantity);

  static const _colReturned = 110.0;
  static const _colReceived = 110.0;
  static const _colQty = 170.0;

  Widget _vDivider() => Container(width: 1, color: AppTheme.borderLight);

  Widget _hDivider() => Container(height: 1, color: AppTheme.borderLight);

  Widget _buildTableHeader({required bool showAddAll}) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ITEMS & DESCRIPTION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    if (showAddAll) ...[
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: _addAllItems,
                        child: const Text(
                          'Add All Items',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            _vDivider(),
            SizedBox(
              width: _colReturned,
              child: const Center(
                child: Text(
                  'RETURNED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            _vDivider(),
            SizedBox(
              width: _colReceived,
              child: const Center(
                child: Text(
                  'RECEIVED',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
            _vDivider(),
            SizedBox(
              width: _colQty,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text(
                  'QUANTITY TO RECEIVE',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Top bar ────────────────────────────────────────────────────
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: widget.onBack,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.chevronLeft,
                        size: 14,
                        color: AppTheme.primaryBlue,
                      ),
                      Text(
                        widget.row.rmaNumber,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'New Sales Return Receipt',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // ── Scrollable body ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Receive Date field
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 140,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'Receive Date',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.errorRed,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: '*',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.errorRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _dateCtrl,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: AppTheme.borderLight,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: AppTheme.borderLight,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryBlue,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8ED),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFFDFA0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          LucideIcons.info,
                          size: 16,
                          color: Color(0xFFE8A825),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _manualMode
                              ? Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text:
                                            'You can also add all items from the sales return and manually adjust their quantities. ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _manualMode = false,
                                          ),
                                          child: const Text(
                                            'Add Manually',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Text.rich(
                                  TextSpan(
                                    children: [
                                      const TextSpan(
                                        text:
                                            'You can also select or scan the items to be included from the sales return. ',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _manualMode = true,
                                          ),
                                          child: const Text(
                                            'Select or Scan items',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.primaryBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Items table
                  if (!_manualMode) ...[
                    // Pre-populated mode: items from the sales return
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTableHeader(showAddAll: false),
                          ...List.generate(widget.row.items.length, (i) {
                            if (_removedItemIndices.contains(i))
                              // ignore: curly_braces_in_flow_control_structures
                              return const SizedBox.shrink();
                            final item = widget.row.items[i];
                            final savedBatches =
                                _batchDataByItemIndex[i] ??
                                <Map<String, String>>[];
                            final isFirst = !List.generate(
                              i,
                              (j) => j,
                            ).any((j) => !_removedItemIndices.contains(j));
                            return Column(
                              children: [
                                if (!isFirst) _hDivider(),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Items & Description
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16,
                                            14,
                                            16,
                                            14,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                item.name,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: AppTheme.textPrimary,
                                                ),
                                              ),
                                              if (item
                                                  .description
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.description,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color:
                                                        AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                      _vDivider(),
                                      // Returned
                                      SizedBox(
                                        width: _colReturned,
                                        child: Center(
                                          child: Text(
                                            '${item.quantity}(${item.unit.isNotEmpty ? item.unit : 'pcs'})',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      _vDivider(),
                                      // Received
                                      SizedBox(
                                        width: _colReceived,
                                        child: Center(
                                          child: Text(
                                            '0(${item.unit.isNotEmpty ? item.unit : 'pcs'})',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      _vDivider(),
                                      // Quantity to receive
                                      SizedBox(
                                        width: _colQty,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            12,
                                            12,
                                            12,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  SizedBox(
                                                    width: 72,
                                                    height: 32,
                                                    child: TextField(
                                                      controller: _qtyCtrlrs[i],
                                                      textAlign:
                                                          TextAlign.right,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                      decoration: InputDecoration(
                                                        contentPadding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 6,
                                                            ),
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppTheme
                                                                    .borderLight,
                                                              ),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppTheme
                                                                    .borderLight,
                                                              ),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                4,
                                                              ),
                                                          borderSide:
                                                              const BorderSide(
                                                                color: AppTheme
                                                                    .primaryBlue,
                                                                width: 1.5,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: () => setState(
                                                      () => _removedItemIndices
                                                          .add(i),
                                                    ),
                                                    child: const Icon(
                                                      LucideIcons.xCircle,
                                                      size: 18,
                                                      color: AppTheme.errorRed,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              GestureDetector(
                                                onTap: () =>
                                                    _openBatchesForItem(i),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Icon(
                                                      savedBatches.isEmpty
                                                          ? LucideIcons
                                                                .alertTriangle
                                                          : LucideIcons
                                                                .checkCircle,
                                                      size: 13,
                                                      color:
                                                          savedBatches.isEmpty
                                                          ? AppTheme.errorRed
                                                          : AppTheme
                                                                .successGreen,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      savedBatches.isEmpty
                                                          ? 'Add Batches'
                                                          : '${savedBatches.length} ${savedBatches.length == 1 ? 'batch' : 'batches'} added',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            savedBatches.isEmpty
                                                            ? AppTheme.errorRed
                                                            : AppTheme
                                                                  .successGreen,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
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
                    ),
                  ] else ...[
                    // Manual / scan mode: searchable empty rows
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTableHeader(showAddAll: true),
                          ...List.generate(_manualItemCtrlrs.length, (i) {
                            return Column(
                              children: [
                                if (i > 0) _hDivider(),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Items & Description — searchable input
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: TextField(
                                            controller: _manualItemCtrlrs[i],
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Type or click to select an item.',
                                              hintStyle: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSecondary,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 10,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.borderLight,
                                                ),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.borderLight,
                                                ),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                  color: AppTheme.primaryBlue,
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      _vDivider(),
                                      // Returned — empty
                                      SizedBox(width: _colReturned),
                                      _vDivider(),
                                      // Received — empty
                                      SizedBox(width: _colReceived),
                                      _vDivider(),
                                      // Quantity to receive — X button
                                      SizedBox(
                                        width: _colQty,
                                        child: Center(
                                          child: GestureDetector(
                                            onTap: () => _removeManualRow(i),
                                            child: const Icon(
                                              LucideIcons.xCircle,
                                              size: 18,
                                              color: AppTheme.errorRed,
                                            ),
                                          ),
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
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => setState(() => _addManualRow()),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.plus,
                            size: 14,
                            color: AppTheme.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add New Row',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Total items
                  Text(
                    'Total Items : $_totalItems',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notes
                  const Text(
                    'Notes (For Internal Use)',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppTheme.borderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppTheme.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _isSaving ? null : _submitReceive,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Receive',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isSaving ? null : widget.onBack,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          side: const BorderSide(color: AppTheme.borderLight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── PDF-style document preview ────────────────────────────────────────────────

class _SrPdfPreview extends ConsumerWidget {
  const _SrPdfPreview({required this.row});
  final _SalesReturnRow row;

  static const Color _tableHeaderBg = Color(0xFF3D3D3D);
  static const Color _rowDivider = Color(0xFFE5E7EB);
  static const Color _outerBorder = Color(0xFFDDDDDD);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgSettings = ref.watch(orgSettingsProvider).valueOrNull;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _outerBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRect(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 80, 40, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Top header: logo+company (left) / title (right) ────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: logo placeholder + company details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OrgLogoBox(
                              orgSettings: orgSettings,
                              width: 200,
                              height: 80,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'ZABNIX PRIVATE LIMITED',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111111),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'PERINTHALMANNA',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF444444),
                              ),
                            ),
                            const Text(
                              'MALAPPURAM Kerala 679322',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF444444),
                              ),
                            ),
                            const Text(
                              'India',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF444444),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'GSTIN 32AACCZ4912F1ZL',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF444444),
                              ),
                            ),
                            const Text(
                              '8086355500',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF444444),
                              ),
                            ),
                            const Text(
                              'zabnixprivatelimited@gmail.com',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF444444),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Right: document title + RMA#
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'SALES RETURN',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'RMA# ${row.rmaNumber}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Bill To (left) + Date (right) ──────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill To',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF444444),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            row.customerName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Text(
                            'Date : ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF444444),
                            ),
                          ),
                          const SizedBox(width: 32),
                          Text(
                            row.date,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111111),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Items table: dark header ────────────────────────────────
                  Container(
                    color: _tableHeaderBg,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 13,
                    ),
                    child: Row(
                      children: const [
                        SizedBox(
                          width: 32,
                          child: Text(
                            '#',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Item & Description',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            'HSN/SAC',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            'Returned\nQty',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Rate',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            'Amount',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Item rows
                  ...row.items.map(
                    (item) => Container(
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: _rowDivider)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${item.number}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF444444),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF111111),
                                  ),
                                ),
                                if (item.description.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.description,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF888888),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(
                              item.hsn.isEmpty ? '' : item.hsn,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF444444),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(
                              '${item.quantity}.00',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: Text(
                              item.rate.replaceAll('₹', ''),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text(
                              item.amount.replaceAll('₹', ''),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF111111),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Totals (right-aligned) ─────────────────────────────────
                  Builder(
                    builder: (_) {
                      final subTotal = row.items.fold<double>(0, (sum, item) {
                        final raw = item.amount
                            .replaceAll('₹', '')
                            .replaceAll(',', '')
                            .trim();
                        return sum + (double.tryParse(raw) ?? 0);
                      });
                      final subTotalStr = _inFmt.format(subTotal);
                      final totalStr = '₹$subTotalStr';
                      return Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _totalRow('Sub Total', subTotalStr),
                            const SizedBox(height: 8),
                            _totalRow('Total', totalStr, bold: true),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Corner status ribbon ────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              // Shared widget, scaled to the capped paper width. Band only —
              // no triangular corner fold.
              child: PdfCornerRibbon(
                label: _formatStatusText(row.status),
                color: _SalesReturnsOverviewPageState._statusColor(row.status),
                size: 88,
                showFold: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: const Color(0xFF444444),
          ),
        ),
        const SizedBox(width: 48),
        SizedBox(
          width: 90,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: const Color(0xFF111111),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Document item row ─────────────────────────────────────────────────────────

class _SrLineItemRow extends StatelessWidget {
  const _SrLineItemRow({required this.item});
  final _LineItem item;

  static const Color _divider = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left section: # + image + name/description
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${item.number}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        border: Border.all(color: _divider),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        LucideIcons.image,
                        size: 18,
                        color: Color(0xFFB0B7C3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          if (item.description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.description,
                              style: const TextStyle(
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
            ),
            // Quantity — green background fills full row height
            Container(
              width: 120,
              color: const Color(0xFFEAF9EB),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity} ${item.unit.isEmpty ? 'pcs' : item.unit} Returned',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.receivedQuantity} ${item.unit.isEmpty ? 'pcs' : item.unit} Received',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            // Rate + Amount
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 12, 24, 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      item.rate,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    child: Text(
                      item.amount,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
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

// ── Compact list item ─────────────────────────────────────────────────────────

class _SrCompactItem extends StatefulWidget {
  const _SrCompactItem({
    required this.row,
    required this.selected,
    required this.checked,
    required this.onCheckChanged,
    required this.onTap,
  });
  final _SalesReturnRow row;
  final bool selected;
  final bool checked;
  final ValueChanged<bool?> onCheckChanged;
  final VoidCallback onTap;

  @override
  State<_SrCompactItem> createState() => _SrCompactItemState();
}

class _SrCompactItemState extends State<_SrCompactItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Selected uses the same token as the sales order list so a picked row
    // reads identically across modules. Hover is left as-is.
    final bg = widget.selected
        ? AppTheme.selectionActiveBg
        : _hovered
        ? AppTheme.primaryBlue.withValues(alpha: 0.04)
        : AppTheme.backgroundColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => widget.onCheckChanged(!widget.checked),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: widget.checked,
                    onChanged: widget.onCheckChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: AppTheme.primaryBlue,
                    side: const BorderSide(
                      color: Color(0xFFADB5BD),
                      width: 1.5,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.row.customerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          widget.row.returned,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${widget.row.rmaNumber} • ${widget.row.date}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (widget.row.salesOrderNumber != '-')
                          Text(
                            '[${widget.row.salesOrderNumber}]',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                     _formatStatusText(widget.row.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _SalesReturnsOverviewPageState._statusColor(
                          widget.row.status,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bulk action widgets ────────────────────────────────────────────────────────

class _SrBulkActionBtn extends StatefulWidget {
  const _SrBulkActionBtn({
    this.label,
    // ignore: unused_element_parameter
    this.icon,
    this.trailingIcon,
    required this.onTap,
  });
  final String? label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  @override
  State<_SrBulkActionBtn> createState() => _SrBulkActionBtnState();
}

class _SrBulkActionBtnState extends State<_SrBulkActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                : Colors.transparent,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 16, color: AppTheme.textPrimary),
              if (widget.icon != null && widget.label != null)
                const SizedBox(width: 6),
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                  ),
                ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.trailingIcon,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SrBulkMenuOption extends StatefulWidget {
  const _SrBulkMenuOption({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_SrBulkMenuOption> createState() => _SrBulkMenuOptionState();
}

class _SrBulkMenuOptionState extends State<_SrBulkMenuOption> {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              color: _hovered ? Colors.white : AppTheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared detail panel widgets ───────────────────────────────────────────────

class _SalesReturnHistorySidebar extends ConsumerWidget {
  const _SalesReturnHistorySidebar({
    required this.salesReturnId,
    required this.onClose,
  });

  final String? salesReturnId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = salesReturnId;
    final entriesAsync = id == null || id.isEmpty
        ? const AsyncValue<List<SalesReturnHistoryEntry>>.data([])
        : ref.watch(salesReturnHistoryProvider(id));

    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(left: BorderSide(color: AppTheme.borderLight)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.textPrimary.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(-4, 0),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 82,
                padding: const EdgeInsets.fromLTRB(26, 24, 14, 18),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'History',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onClose,
                        child: const Padding(
                          padding: EdgeInsets.fromLTRB(8, 2, 8, 8),
                          child: Icon(
                            LucideIcons.x,
                            size: 19,
                            color: AppTheme.errorRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: entriesAsync.when(
                  skipLoadingOnReload: true,
                  skipLoadingOnRefresh: true,
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppTheme.space24),
                    child: ZListSkeleton(itemCount: 4),
                  ),
                  error: (_, __) => const _SalesReturnHistoryEmptyState(
                    label: 'History could not be loaded.',
                  ),
                  data: (entries) {
                    if (entries.isEmpty) {
                      return const _SalesReturnHistoryEmptyState(
                        label: 'No history available yet.',
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(28, 28, 18, 28),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 30),
                      itemBuilder: (context, index) =>
                          _SalesReturnHistoryEntryTile(
                            entry: entries[index],
                            isLast: index == entries.length - 1,
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SalesReturnHistoryEmptyState extends StatelessWidget {
  const _SalesReturnHistoryEmptyState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.space24),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _SalesReturnHistoryEntryTile extends StatelessWidget {
  const _SalesReturnHistoryEntryTile({
    required this.entry,
    required this.isLast,
  });

  final SalesReturnHistoryEntry entry;
  final bool isLast;

  String get _timestamp {
    final parsed = DateTime.tryParse(entry.timestamp)?.toLocal();
    if (parsed == null) return entry.timestamp;
    return DateFormat('dd-MM-yyyy hh:mm a').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final isCreditNote = entry.kind == 'credit_note';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30,
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.backgroundColor,
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Icon(
                  isCreditNote
                      ? LucideIcons.fileText
                      : LucideIcons.messageSquare,
                  size: 14,
                  color: isCreditNote
                      ? AppTheme.warningOrange
                      : AppTheme.primaryBlue,
                ),
              ),
              if (!isLast)
                Container(width: 1, height: 86, color: AppTheme.borderLight),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Text(
                    isCreditNote ? 'Credit Note' : 'Sales Return',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    '• $_timestamp',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailHeaderIconButton extends StatefulWidget {
  const _DetailHeaderIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_DetailHeaderIconButton> createState() =>
      _DetailHeaderIconButtonState();
}

class _DetailHeaderIconButtonState extends State<_DetailHeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.05)
                : AppTheme.bgLight,
            border: Border.all(color: AppTheme.borderLight),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(widget.icon, size: 16, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _DetailActionDivider extends StatelessWidget {
  const _DetailActionDivider();

  @override
  Widget build(BuildContext context) {
    // 16px tall with 4px gutters, matching the sales order detail toolbar so
    // the hover chip clears the rule on both sides.
    return Container(
      width: 1,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppTheme.borderLight,
    );
  }
}

class _DetailActionBtn extends StatefulWidget {
  const _DetailActionBtn({
    this.icon,
    this.label,
    // ignore: unused_element_parameter
    this.trailingIcon,
    required this.onTap,
  });
  final IconData? icon;
  final String? label;
  final IconData? trailingIcon;
  final VoidCallback onTap;

  @override
  State<_DetailActionBtn> createState() => _DetailActionBtnState();
}

class _DetailActionBtnState extends State<_DetailActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Matches the sales order detail toolbar: the button lifts onto a white
    // chip with a light border on hover, rather than tinting blue.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? Colors.white : Colors.transparent,
            border: Border.all(
              color: _hovered ? AppTheme.borderColor : Colors.transparent,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 14, color: AppTheme.textSecondary),
              if (widget.icon != null && widget.label != null)
                const SizedBox(width: 6),
              if (widget.label != null)
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 4),
                Icon(
                  widget.trailingIcon,
                  size: 12,
                  color: AppTheme.textSecondary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── PDF/Print dropdown ────────────────────────────────────────────────────────

class _PdfPrintBtn extends StatefulWidget {
  const _PdfPrintBtn();

  @override
  State<_PdfPrintBtn> createState() => _PdfPrintBtnState();
}

class _PdfPrintBtnState extends State<_PdfPrintBtn> {
  bool _hovered = false;
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final isOpen = _controller.isOpen;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: MenuAnchor(
        controller: _controller,
        alignmentOffset: const Offset(0, 4),
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(4),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 6),
          ),
        ),
        menuChildren: [
          _MenuOption(
            icon: LucideIcons.fileText,
            label: 'PDF',
            onTap: () => _controller.close(),
          ),
          _MenuOption(
            icon: LucideIcons.printer,
            label: 'Print',
            onTap: () => _controller.close(),
          ),
        ],
        child: GestureDetector(
          onTap: () {
            if (_controller.isOpen) {
              _controller.close();
            } else {
              _controller.open();
            }
            setState(() {});
          },
          // Same hover chip as the neighbouring action buttons. The open menu
          // keeps the chip visible so the trigger stays anchored to its menu.
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: (isOpen || _hovered) ? Colors.white : Colors.transparent,
              border: Border.all(
                color: (isOpen || _hovered)
                    ? AppTheme.borderColor
                    : Colors.transparent,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  LucideIcons.fileText,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'PDF/Print',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 12,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Detail three-dot dropdown ─────────────────────────────────────────────────

class _DetailMoreBtn extends StatefulWidget {
  const _DetailMoreBtn({this.onDelete, this.onMarkDeclined});

  /// Fired after the menu closes, so the confirmation dialog is not competing
  /// with the menu overlay for focus.
  final VoidCallback? onDelete;

  /// Null hides the entry — a return that is already declined or has goods
  /// back in stock cannot be declined.
  final VoidCallback? onMarkDeclined;

  @override
  State<_DetailMoreBtn> createState() => _DetailMoreBtnState();
}

class _DetailMoreBtnState extends State<_DetailMoreBtn> {
  bool _hovered = false;
  final _controller = MenuController();

  @override
  Widget build(BuildContext context) {
    final isOpen = _controller.isOpen;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: MenuAnchor(
        controller: _controller,
        alignmentOffset: const Offset(0, 4),
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(4),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: AppTheme.borderLight),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 6),
          ),
        ),
        menuChildren: [
          if (widget.onMarkDeclined != null)
            _MenuOption(
              label: 'Mark as Declined',
              onTap: () {
                _controller.close();
                widget.onMarkDeclined?.call();
              },
            ),
          _MenuOption(
            label: 'Delete',
            onTap: () {
              _controller.close();
              widget.onDelete?.call();
            },
          ),
        ],
        child: GestureDetector(
          onTap: () {
            if (_controller.isOpen) {
              _controller.close();
            } else {
              _controller.open();
            }
            setState(() {});
          },
          // Same hover chip as the rest of the action bar — it sits directly
          // beside PDF/Print, so a different treatment would read as a bug.
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: (isOpen || _hovered) ? Colors.white : Colors.transparent,
              border: Border.all(
                color: (isOpen || _hovered)
                    ? AppTheme.borderColor
                    : Colors.transparent,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              LucideIcons.moreHorizontal,
              size: 15,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// Shared hover menu item for MenuAnchor-based dropdowns
class _MenuOption extends StatefulWidget {
  const _MenuOption({this.icon, required this.label, required this.onTap});
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_MenuOption> createState() => _MenuOptionState();
}

class _MenuOptionState extends State<_MenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 40,
          width: 160,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 15,
                  color: _hovered ? Colors.white : AppTheme.textSecondary,
                ),
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? Colors.white : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _ColumnText extends StatelessWidget {
  const _ColumnText({required this.columns});
  final List<ColumnConfig> columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        'Columns: ${columns.map((c) => c.label).join(', ')}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

// ignore: unused_element
class _TableHeader extends StatelessWidget {
  const _TableHeader({
    required this.columns,
    required this.colWidths,
    required this.columnMenuOpen,
    required this.onColumnMenuTap,
    required this.textMode,
    required this.sortColumn,
    required this.sortAscending,
    required this.onColumnResize,
  });

  final List<ColumnConfig> columns;
  final Map<String, double> colWidths;
  final bool columnMenuOpen;
  final VoidCallback onColumnMenuTap;
  final String textMode;
  final String sortColumn;
  final bool sortAscending;
  final void Function(String id, double delta) onColumnResize;

  @override
  Widget build(BuildContext context) {
    final isWrap = textMode == 'wrap';
    return Container(
      height: isWrap ? null : 40,
      constraints: isWrap ? const BoxConstraints(minHeight: 40) : null,
      color: AppTheme.bgLight,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: isWrap ? 10 : 0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 48,
              child: GestureDetector(
                onTap: onColumnMenuTap,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Icon(
                    LucideIcons.slidersHorizontal,
                    size: 16,
                    color: columnMenuOpen
                        ? AppTheme.primaryBlueDark
                        : AppTheme.primaryBlue,
                  ),
                ),
              ),
            ),
            for (final col in columns)
              _HeaderCell(
                width: colWidths[col.id] ?? 120,
                label: col.label.toUpperCase(),
                sorted: col.id == sortColumn,
                sortAscending: sortAscending,
                textMode: textMode,
                onResize: (delta) => onColumnResize(col.id, delta),
              ),
          ],
        ),
      ),
    );
  }
}

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.row,
    required this.columns,
    required this.colWidths,
    required this.textMode,
    required this.onTap,
  });
  final _SalesReturnRow row;
  final List<ColumnConfig> columns;
  final Map<String, double> colWidths;
  final String textMode;
  final VoidCallback onTap;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  Widget _cellForColumn(String id) {
    switch (id) {
      case 'date':
        return _BodyText(widget.row.date, textMode: widget.textMode);
      case 'rmaNumber':
        return _BodyText(
          widget.row.rmaNumber,
          color: AppTheme.primaryBlueDark,
          fontWeight: FontWeight.w600,
          textMode: widget.textMode,
        );
      case 'salesOrderNumber':
        return _BodyText(
          widget.row.salesOrderNumber,
          textMode: widget.textMode,
        );
      case 'customerName':
        return _BodyText(widget.row.customerName, textMode: widget.textMode);
       case 'status':
        return _BodyText(
          _formatStatusText(widget.row.status),
          color: AppTheme.primaryBlue,
          fontWeight: FontWeight.w500,
          textMode: widget.textMode,
        );
      case 'receiveStatus':
        return _BodyText(
          widget.row.receiveStatus,
          color: AppTheme.successGreen,
          fontWeight: FontWeight.w500,
          textMode: widget.textMode,
        );
      case 'refundStatus':
        return _BodyText(
          widget.row.refundStatus,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
          textMode: widget.textMode,
        );
      case 'returned':
        return _BodyText(widget.row.returned, textMode: widget.textMode);
      case 'amountRefunded':
        return _BodyText(widget.row.amountRefunded, textMode: widget.textMode);
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWrap = widget.textMode == 'wrap';
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: isWrap ? null : const BoxConstraints(minHeight: 48),
          height: isWrap ? null : 48,
          color: _hovered
              ? AppTheme.primaryBlue.withValues(alpha: 0.03)
              : Colors.transparent,
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: isWrap ? 10 : 0,
          ),
          child: Row(
            crossAxisAlignment: isWrap
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              const SizedBox(width: 48),
              for (final col in widget.columns)
                SizedBox(
                  width: widget.colWidths[col.id] ?? 120,
                  child: _cellForColumn(col.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCell extends StatefulWidget {
  const _HeaderCell({
    required this.width,
    required this.label,
    this.sorted = false,
    this.sortAscending = true,
    this.textMode = 'clip',
    this.onResize,
  });

  final double width;
  final String label;
  final bool sorted;
  final bool sortAscending;
  final String textMode;
  final ValueChanged<double>? onResize;

  @override
  State<_HeaderCell> createState() => _HeaderCellState();
}

class _HeaderCellState extends State<_HeaderCell> {
  bool _resizeHovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final showHandle = _resizeHovered || _dragging;

    return MouseRegion(
      cursor: widget.onResize == null
          ? MouseCursor.defer
          : SystemMouseCursors.resizeColumn,
      onEnter: (_) {
        if (widget.onResize != null) setState(() => _resizeHovered = true);
      },
      onExit: (_) {
        if (widget.onResize != null) setState(() => _resizeHovered = false);
      },
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          if (widget.onResize != null) setState(() => _dragging = true);
        },
        onPointerMove: (event) {
          if (_dragging && widget.onResize != null) {
            widget.onResize!(event.delta.dx);
          }
        },
        onPointerUp: (_) => setState(() => _dragging = false),
        onPointerCancel: (_) => setState(() => _dragging = false),
        child: SizedBox(
          width: widget.width,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      if (widget.sorted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          widget.sortAscending
                              ? LucideIcons.arrowUp
                              : LucideIcons.arrowDown,
                          size: 14,
                          color: AppTheme.primaryBlue,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Drag resize handle
              if (widget.onResize != null)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeColumn,
                    onEnter: (_) => setState(() => _resizeHovered = true),
                    onExit: (_) => setState(() => _resizeHovered = false),
                    child: IgnorePointer(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        width: 12,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: showHandle
                                  ? AppTheme.primaryBlue
                                  : AppTheme.borderLight,
                              width: showHandle ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(
    this.text, {
    this.color = AppTheme.textPrimary,
    this.fontWeight = FontWeight.w400,
    this.textMode = 'clip',
  });
  final String text;
  final Color color;
  final FontWeight fontWeight;
  final String textMode;

  @override
  Widget build(BuildContext context) {
    final isWrap = textMode == 'wrap';
    return Text(
      text,
      maxLines: isWrap ? null : 1,
      overflow: isWrap ? TextOverflow.visible : TextOverflow.ellipsis,
      softWrap: isWrap,
      style: TextStyle(fontSize: 13, fontWeight: fontWeight, color: color),
    );
  }
}

class _ColumnMenuOption extends StatefulWidget {
  const _ColumnMenuOption({
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  State<_ColumnMenuOption> createState() => _ColumnMenuOptionState();
}

class _ColumnMenuOptionState extends State<_ColumnMenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final filled = _hovered;
    final foreground = filled
        ? AppTheme.backgroundColor
        : widget.selected
        ? AppTheme.primaryBlue
        : AppTheme.textPrimary;
    final iconColor = filled ? AppTheme.backgroundColor : AppTheme.primaryBlue;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 32,
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: filled
                ? AppTheme.primaryBlue.withValues(alpha: 0.9)
                : widget.selected
                ? AppTheme.primaryBlue.withValues(alpha: 0.07)
                : AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: filled
                ? Border.all(color: AppTheme.primaryBlueDark, width: 2)
                : widget.selected
                ? Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3))
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: foreground,
                    fontWeight: widget.selected
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ),
              if (widget.selected)
                Icon(
                  LucideIcons.check,
                  size: 14,
                  color: filled
                      ? AppTheme.backgroundColor
                      : AppTheme.primaryBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewMoreMenu extends StatefulWidget {
  const _OverviewMoreMenu({
    required this.sortColumn,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onExport,
    required this.onManageCustomFields,
    required this.onRefreshList,
  });

  final String sortColumn;
  final bool sortAscending;
  final void Function(String col, bool asc) onSortChanged;
  final VoidCallback onExport;
  final VoidCallback onManageCustomFields;
  final VoidCallback onRefreshList;

  @override
  State<_OverviewMoreMenu> createState() => _OverviewMoreMenuState();
}

class _OverviewMoreMenuState extends State<_OverviewMoreMenu> {
  bool _sortItemHovered = false;
  bool _sortSubmenuHovered = false;
  bool _exportItemHovered = false;
  bool _exportSubmenuHovered = false;
  bool _customFieldsHovered = false;
  bool _refreshHovered = false;

  bool get _sortSubmenuVisible => _sortItemHovered || _sortSubmenuHovered;
  bool get _exportSubmenuVisible => _exportItemHovered || _exportSubmenuHovered;

  static const _sortOptions = [
    ('date', 'Date'),
    ('rmaNumber', 'RMA#'),
    ('salesOrderNumber', 'Sales Order#'),
    ('customerName', 'Customer Name'),
    ('createdTime', 'Created Time'),
    ('lastModifiedTime', 'Last Modified Time'),
  ];

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: AppTheme.borderLight),
    boxShadow: [
      BoxShadow(
        color: AppTheme.textPrimary.withValues(alpha: 0.12),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );

  Widget _menuItem({
    required String label,
    required IconData icon,
    required bool hovered,
    required bool active,
    bool hasChevron = false,
    VoidCallback? onTap,
  }) {
    final showActive = active || hovered;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: showActive ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: showActive ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: showActive ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (hasChevron)
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: showActive ? Colors.white : AppTheme.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topRight,
        children: [
          Container(
            width: 200,
            decoration: _cardDecoration,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _sortItemHovered = true),
                  onExit: (_) => setState(() => _sortItemHovered = false),
                  child: _menuItem(
                    label: 'Sort by',
                    icon: LucideIcons.arrowUpDown,
                    hovered: _sortItemHovered,
                    active: _sortSubmenuVisible,
                    hasChevron: true,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _exportItemHovered = true),
                  onExit: (_) => setState(() => _exportItemHovered = false),
                  child: _menuItem(
                    label: 'Export',
                    icon: LucideIcons.upload,
                    hovered: _exportItemHovered,
                    active: _exportSubmenuVisible,
                    hasChevron: true,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _customFieldsHovered = true),
                  onExit: (_) => setState(() => _customFieldsHovered = false),
                  child: _menuItem(
                    label: 'Manage Custom Fields',
                    icon: LucideIcons.columns,
                    hovered: _customFieldsHovered,
                    active: false,
                    onTap: widget.onManageCustomFields,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _refreshHovered = true),
                  onExit: (_) => setState(() => _refreshHovered = false),
                  child: _menuItem(
                    label: 'Refresh List',
                    icon: LucideIcons.refreshCw,
                    hovered: _refreshHovered,
                    active: false,
                    onTap: widget.onRefreshList,
                  ),
                ),
              ],
            ),
          ),
          if (_sortSubmenuVisible)
            Positioned(
              top: 0,
              right: 200,
              child: MouseRegion(
                onEnter: (_) => setState(() => _sortSubmenuHovered = true),
                onExit: (_) => setState(() => _sortSubmenuHovered = false),
                child: Container(
                  width: 184,
                  decoration: _cardDecoration,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _sortOptions.map((opt) {
                      final isSelected = widget.sortColumn == opt.$1;
                      return _OverviewSortOption(
                        label: opt.$2,
                        isSelected: isSelected,
                        sortAscending: widget.sortAscending,
                        onTap: () => widget.onSortChanged(
                          opt.$1,
                          isSelected ? !widget.sortAscending : true,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          if (_exportSubmenuVisible)
            Positioned(
              top: 40,
              right: 200,
              child: MouseRegion(
                onEnter: (_) => setState(() => _exportSubmenuHovered = true),
                onExit: (_) => setState(() => _exportSubmenuHovered = false),
                child: Container(
                  width: 184,
                  decoration: _cardDecoration,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SubmenuItem(
                        label: 'Export Sales Return',
                        onTap: () {
                          Navigator.of(context).pop();
                          ZerpaiToast.success(
                            context,
                            'Exporting Sales Return...',
                          );
                        },
                      ),
                      _SubmenuItem(
                        label: 'Export Receives',
                        onTap: () {
                          Navigator.of(context).pop();
                          ZerpaiToast.success(context, 'Exporting Receives...');
                        },
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

class _OverviewSortOption extends StatefulWidget {
  const _OverviewSortOption({
    required this.label,
    required this.isSelected,
    required this.sortAscending,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool sortAscending;
  final VoidCallback onTap;

  @override
  State<_OverviewSortOption> createState() => _OverviewSortOptionState();
}

class _OverviewSortOptionState extends State<_OverviewSortOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final showActive = widget.isSelected || _hovered;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: showActive ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: showActive
                ? Border.all(color: Colors.white, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: showActive ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(
                  widget.sortAscending
                      ? LucideIcons.arrowUp
                      : LucideIcons.arrowDown,
                  size: 14,
                  color: Colors.white,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _LineItem {
  const _LineItem({
    required this.number,
    required this.name,
    // ignore: unused_element_parameter
    this.description = '',
    this.hsn = '',
    this.productId = '',
    this.salesReturnItemId = '',
    // ignore: unused_element_parameter
    this.warehouseName = '',
    this.warehouseId = '',
    required this.quantity,
    required this.receivedQuantity,
    required this.unit,
    required this.rate,
    required this.amount,
  });

  final int number;
  final String name;
  final String description;
  final String hsn;
  final String productId;
  final String salesReturnItemId;
  final String warehouseName;
  final String warehouseId;
  final int quantity;
  final int receivedQuantity;
  final String unit;
  final String rate;
  final String amount;
}

class _SrReceiveDetailInlineView extends StatelessWidget {
  const _SrReceiveDetailInlineView({
    required this.receive,
    required this.row,
    required this.productMap,
  });

  final SalesReturnReceive receive;
  final dynamic row;
  final Map<String, Item> productMap;

  @override
  Widget build(BuildContext context) {
    String displayDate = '';
    try {
      final parsed = DateTime.parse(receive.receiveDate);
      displayDate = DateFormat('dd-MM-yyyy').format(parsed);
    } catch (_) {
      displayDate = receive.receiveDate;
    }

    final itemsWithBatches = receive.items.where((i) => i.batches.isNotEmpty).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'RETURN RECEIPT',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              text: 'Receive# ',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              children: [
                TextSpan(
                  text: receive.receiveNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const SizedBox(
                width: 150,
                child: Text(
                  'DATE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              Text(
                displayDate,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: AppTheme.bgLight,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text(
                    '#',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'ITEMS & DESCRIPTION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'QUANTITY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          if (receive.items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No items in this receive.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          else
            ...receive.items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final product = productMap[item.productId];
              final name = product?.productName ?? 'Unknown Product';
              final desc = product?.salesDescription ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: AppTheme.borderLight),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.bgLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: const Icon(
                              LucideIcons.image,
                              color: AppTheme.textSecondary,
                              size: 20,
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    style: const TextStyle(
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
                      flex: 1,
                      child: RichText(
                        text: TextSpan(
                          text: '${item.receivingQty.toStringAsFixed(0)} ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimary,
                          ),
                          children: const [
                            TextSpan(
                              text: 'pcs',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          if (itemsWithBatches.isNotEmpty) ...[
            const SizedBox(height: 32),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.primaryBlue,
                          width: 2,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Batches',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...itemsWithBatches.map((item) {
              final product = productMap[item.productId];
              final name = product?.productName ?? 'Unknown Product';
              return _SrBatchCard(name: name, item: item);
            }),
          ],
        ],
      ),
    );
  }
}


class _SrBatchCard extends StatefulWidget {
  const _SrBatchCard({
    required this.name,
    required this.item,
  });

  final String name;
  final SalesReturnReceiveItem item;

  @override
  State<_SrBatchCard> createState() => _SrBatchCardState();
}

class _SrBatchCardState extends State<_SrBatchCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${widget.item.batches.length} Batches',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryBlue,
                        ),
                        child: Icon(
                          _expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Container(
              color: AppTheme.bgLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BATCH DETAILS',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'QUANTITY IN',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            ...widget.item.batches.map((b) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      b.batchNumber.isNotEmpty ? b.batchNumber : b.batchId,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                    Text(
                      '${b.quantity.toStringAsFixed(0)} pcs',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _SalesReturnRow {
  const _SalesReturnRow({
    required this.date,
    required this.rmaNumber,
    required this.salesOrderNumber,
    required this.customerName,
    required this.status,
    required this.receiveStatus,
    required this.refundStatus,
    required this.returned,
    required this.amountRefunded,
    required this.salesReturnId,
    this.customerId,
    this.warehouseId,
    this.items = const [],
    this.createdAt,
  });

  /// `sales_returns.created_at` — when the record was saved, as opposed to
  /// [date], which is the user-entered return date and can be backdated.
  final DateTime? createdAt;

  final String date;
  final String rmaNumber;
  final String salesOrderNumber;
  final String customerName;

  /// `customers.id` behind [customerName], so the document preview can link
  /// through to the customer. Null when the return carries no resolvable id.
  final String? customerId;
  final String status;
  final String receiveStatus;
  final String refundStatus;
  final String returned;
  final String amountRefunded;
  final String salesReturnId;
  final String? warehouseId;
  final List<_LineItem> items;
}

// ── More menu ─────────────────────────────────────────────────────────────────

class _SrMoreMenu extends StatefulWidget {
  const _SrMoreMenu({
    required this.sortColumn,
    required this.sortAscending,
    required this.onSortChanged,
    required this.onExport,
    required this.onManageCustomFields,
    required this.onRefreshList,
  });

  final String sortColumn;
  final bool sortAscending;
  final void Function(String col, bool asc) onSortChanged;
  final VoidCallback onExport;
  final VoidCallback onManageCustomFields;
  final VoidCallback onRefreshList;

  @override
  State<_SrMoreMenu> createState() => _SrMoreMenuState();
}

class _SrMoreMenuState extends State<_SrMoreMenu> {
  bool _sortItemHovered = false;
  bool _sortSubmenuHovered = false;
  bool _exportItemHovered = false;
  bool _exportSubmenuHovered = false;
  bool _customFieldsHovered = false;
  bool _refreshHovered = false;

  bool get _sortSubmenuVisible => _sortItemHovered || _sortSubmenuHovered;
  bool get _exportSubmenuVisible => _exportItemHovered || _exportSubmenuHovered;

  static const _sortOptions = [
    ('date', 'Date'),
    ('rmaNumber', 'RMA#'),
    ('salesOrderNumber', 'Sales Order#'),
    ('customerName', 'Customer Name'),
    ('createdTime', 'Created Time'),
    ('lastModifiedTime', 'Last Modified Time'),
  ];

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: AppTheme.borderLight),
    boxShadow: [
      BoxShadow(
        color: AppTheme.textPrimary.withValues(alpha: 0.12),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ],
  );

  Widget _menuItem({
    required String label,
    required IconData icon,
    required bool hovered,
    required bool active,
    bool hasChevron = false,
    VoidCallback? onTap,
  }) {
    final showActive = active || hovered;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: showActive ? AppTheme.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: showActive ? Colors.white : AppTheme.textSecondary,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: showActive ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (hasChevron)
              Icon(
                LucideIcons.chevronRight,
                size: 14,
                color: showActive ? Colors.white : AppTheme.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main menu card (always on the LEFT)
          Container(
            width: 200,
            decoration: _cardDecoration,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MouseRegion(
                  onEnter: (_) => setState(() => _sortItemHovered = true),
                  onExit: (_) => setState(() => _sortItemHovered = false),
                  child: _menuItem(
                    label: 'Sort by',
                    icon: LucideIcons.arrowUpDown,
                    hovered: _sortItemHovered,
                    active: _sortSubmenuVisible,
                    hasChevron: true,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _exportItemHovered = true),
                  onExit: (_) => setState(() => _exportItemHovered = false),
                  child: _menuItem(
                    label: 'Export',
                    icon: LucideIcons.upload,
                    hovered: _exportItemHovered,
                    active: _exportSubmenuVisible,
                    hasChevron: true,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _customFieldsHovered = true),
                  onExit: (_) => setState(() => _customFieldsHovered = false),
                  child: _menuItem(
                    label: 'Manage Custom Fields',
                    icon: LucideIcons.columns,
                    hovered: _customFieldsHovered,
                    active: false,
                    onTap: widget.onManageCustomFields,
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _refreshHovered = true),
                  onExit: (_) => setState(() => _refreshHovered = false),
                  child: _menuItem(
                    label: 'Refresh List',
                    icon: LucideIcons.refreshCw,
                    hovered: _refreshHovered,
                    active: false,
                    onTap: widget.onRefreshList,
                  ),
                ),
              ],
            ),
          ),
          // Submenu card (RIGHT side, appears when Sort by or Export hovered)
          if (_sortSubmenuVisible)
            Container(
              width: 184,
              margin: const EdgeInsets.only(top: 0),
              child: MouseRegion(
                onEnter: (_) => setState(() => _sortSubmenuHovered = true),
                onExit: (_) => setState(() => _sortSubmenuHovered = false),
                child: Container(
                  decoration: _cardDecoration,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _sortOptions.map((opt) {
                      final isSelected = widget.sortColumn == opt.$1;
                      return _SrSortOption(
                        label: opt.$2,
                        isSelected: isSelected,
                        sortAscending: widget.sortAscending,
                        onTap: () => widget.onSortChanged(
                          opt.$1,
                          isSelected ? !widget.sortAscending : true,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            )
          else if (_exportSubmenuVisible)
            Container(
              width: 184,
              margin: const EdgeInsets.only(top: 40),
              child: MouseRegion(
                onEnter: (_) => setState(() => _exportSubmenuHovered = true),
                onExit: (_) => setState(() => _exportSubmenuHovered = false),
                child: Container(
                  decoration: _cardDecoration,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SubmenuItem(
                        label: 'Export Sales Return',
                        onTap: () {
                          Navigator.of(context).pop();
                          ZerpaiToast.success(
                            context,
                            'Exporting Sales Return...',
                          );
                        },
                      ),
                      _SubmenuItem(
                        label: 'Export Receives',
                        onTap: () {
                          Navigator.of(context).pop();
                          ZerpaiToast.success(context, 'Exporting Receives...');
                        },
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

class _SrSortOption extends StatefulWidget {
  const _SrSortOption({
    required this.label,
    required this.isSelected,
    required this.sortAscending,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool sortAscending;
  final VoidCallback onTap;

  @override
  State<_SrSortOption> createState() => _SrSortOptionState();
}

class _SrSortOptionState extends State<_SrSortOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Selected and hover are distinct states: the active sort sits on grey, and
    // hover paints blue. Hover wins when both apply, so the row under the
    // cursor is always the highlighted one.
    final Color background = _hovered
        ? AppTheme.primaryBlue
        : widget.isSelected
        ? AppTheme.bgHover
        : Colors.transparent;
    final Color foreground = _hovered ? Colors.white : AppTheme.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: widget.isSelected
                        ? FontWeight.w500
                        : FontWeight.w400,
                    color: foreground,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(
                  widget.sortAscending
                      ? LucideIcons.arrowUp
                      : LucideIcons.arrowDown,
                  size: 14,
                  color: foreground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmenuItem extends StatefulWidget {
  const _SubmenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_SubmenuItem> createState() => _SubmenuItemState();
}

class _SubmenuItemState extends State<_SubmenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 36,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _hovered ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared org logo widget ────────────────────────────────────────────────────

class _OrgLogoBox extends StatelessWidget {
  const _OrgLogoBox({
    required this.orgSettings,
    this.width = 160,
    this.height = 64,
  });

  final OrgSettings? orgSettings;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final logoUrl = orgSettings?.logoUrl;
    if (logoUrl != null && logoUrl.trim().isNotEmpty) {
      return Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Image.network(
          logoUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildFallback(),
        ),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: const Text(
        'LOGO',
        style: TextStyle(
          color: Colors.white54,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _OutlineActionSquare extends StatelessWidget {
  const _OutlineActionSquare({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppTheme.borderLight),
          color: AppTheme.backgroundColor,
        ),
        child: Icon(icon, size: 16, color: AppTheme.textPrimary),
      ),
    );
  }
}

class _FilledActionSquare extends StatelessWidget {
  const _FilledActionSquare({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.successGreen,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: AppTheme.backgroundColor),
      ),
    );
  }
}


