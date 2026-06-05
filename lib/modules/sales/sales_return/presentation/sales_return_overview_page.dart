import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/sales/sales_orders/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/modules/sales/sales_return/models/sales_return_model.dart';
import 'package:zerpai_erp/modules/sales/sales_return/providers/sales_return_provider.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/inventory_bin_batch_foc.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/dialogs/zerpai_confirmation_dialog.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class SalesReturnsOverviewPage extends ConsumerStatefulWidget {
  final String? initialRmaNumber;
  final String? initialSalesReturnId;
  final int? initialTab;
  final bool initialReceiveMode;
  final bool initialPdfMode;
  const SalesReturnsOverviewPage({
    super.key,
    this.initialRmaNumber,
    this.initialSalesReturnId,
    this.initialTab,
    this.initialReceiveMode = false,
    this.initialPdfMode = false,
  });

  @override
  ConsumerState<SalesReturnsOverviewPage> createState() =>
      _SalesReturnsOverviewPageState();
}

final _inFmt = NumberFormat('#,##,##0.00', 'en_IN');

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
                  border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
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
                  border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
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
                      ...List.generate(3, (_) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                      )),
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

  static const _viewOptions = [
    'All',
    'Draft',
    'Pending Approval',
    'Approved',
    'Declined',
    'Received',
    'Closed',
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

  void _onColumnResize(String id, double delta) {
    final current = _colWidths[id] ?? 120;
    final next = (current + delta).clamp(60.0, 600.0);
    if ((next - current).abs() < 0.5) return;
    setState(() => _colWidths = {..._colWidths, id: next});
  }

  String _selectedView = 'All';
  bool _dropdownOpen = false;
  bool _columnMenuOpen = false;
  bool _favoritesExpanded = true;
  bool _defaultFiltersExpanded = true;
  String _textMode = 'clip';
  String _sortColumn = 'salesOrderNumber';
  bool _sortAscending = true;
  final Set<String> _starredViews = {'Draft', 'Approved'};
  List<ColumnConfig> _columns = _defaultColumns();
  int? _detailIndex;
  final _moreMenuKey = GlobalKey();
  bool _showPdfView = false;
  bool _showReceiveForm = false;
  int _activeTab = 0; // 0 = Receives, 1 = Sales Orders
  bool _tabExpanded = true;

  bool _didApplyInitialSelection = false;

  @override
  void initState() {
    super.initState();
    final requestedTab = widget.initialTab;
    if (requestedTab == 0 || requestedTab == 1) {
      _activeTab = requestedTab!;
    }
    _showReceiveForm = widget.initialReceiveMode;
    _showPdfView = widget.initialPdfMode && !_showReceiveForm;
  }

  static List<ColumnConfig> _defaultColumns() => [
        ColumnConfig(id: 'date', label: 'Date', orderIndex: 0, isLocked: true),
        ColumnConfig(id: 'rmaNumber', label: 'RMA#', orderIndex: 1, isLocked: true),
        ColumnConfig(id: 'salesOrderNumber', label: 'Sales Order#', orderIndex: 2),
        ColumnConfig(id: 'customerName', label: 'Customer Name', orderIndex: 3),
        ColumnConfig(id: 'status', label: 'Status', orderIndex: 4),
        ColumnConfig(id: 'receiveStatus', label: 'Receive Status', orderIndex: 5),
        ColumnConfig(id: 'refundStatus', label: 'Refund Status', orderIndex: 6),
        ColumnConfig(id: 'returned', label: 'Returned', orderIndex: 7),
        ColumnConfig(id: 'amountRefunded', label: 'Amount Refunded', orderIndex: 8),
      ];

  List<ColumnConfig> get _visibleColumns => _columns
      .where((c) => c.isVisible)
      .map((c) => ColumnConfig(id: c.id, label: c.label, isVisible: c.isVisible, orderIndex: c.orderIndex, isLocked: c.isLocked))
      .toList()
    ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  double get _tableWidth {
    final colSum = _visibleColumns.fold(
        0.0, (sum, c) => sum + (_colWidths[c.id] ?? 120));
    return colSum + 64;
  }

  int _compare(_SalesReturnRow a, _SalesReturnRow b, String column) {
    switch (column) {
      case 'date':
      case 'createdTime':
      case 'lastModifiedTime':
        try {
          final partsA = a.date.split('-');
          final partsB = b.date.split('-');
          final dtA = DateTime(int.parse(partsA[2]), int.parse(partsA[1]), int.parse(partsA[0]));
          final dtB = DateTime(int.parse(partsB[2]), int.parse(partsB[1]), int.parse(partsB[0]));
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
          final numA = int.parse(a.salesOrderNumber.replaceAll(RegExp(r'\D'), ''));
          final numB = int.parse(b.salesOrderNumber.replaceAll(RegExp(r'\D'), ''));
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
        final double amtA = double.tryParse(a.amountRefunded.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
        final double amtB = double.tryParse(b.amountRefunded.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
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
    final productMap = {for (final p in products) if (p.id != null) p.id!: p};
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
        customerName: customerMap[r.customerId] ?? r.customerId,
        status: r.status,
        receiveStatus: r.status == 'received' ? 'Received' : 'Pending',
        refundStatus: '-',
        returned: '-',
        amountRefunded: '-',
        salesReturnId: r.id,
        warehouseId: r.warehouseId,
        items: List.generate(r.items.length, (i) {
          final sri = r.items[i];
          final product = productMap[sri.productId];
          final price = product?.sellingPrice;
          final qty = sri.returnQty.round();
          final rateStr = price != null
              ? '₹${_inFmt.format(price)}'
              : '-';
          final amountStr = price != null
              ? '₹${_inFmt.format(price * qty)}'
              : '-';
          return _LineItem(
            number: i + 1,
            name: product?.productName ?? sri.productId,
            hsn: product?.hsnCode ?? '',
            quantity: qty,
            unit: '',
            rate: rateStr,
            amount: amountStr,
            productId: sri.productId,
            salesReturnItemId: sri.id,
          );
        }),
      );
    }).toList();
  }

  List<_SalesReturnRow> get _filteredRows {
    final rows = _buildRows();
    // Resolve initial index once data is available.
    if (!_didApplyInitialSelection && rows.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          if (widget.initialSalesReturnId != null &&
              widget.initialSalesReturnId!.isNotEmpty) {
            final index = rows.indexWhere(
              (r) => r.salesReturnId == widget.initialSalesReturnId,
            );
            _detailIndex = index != -1 ? index : 0;
          } else if (widget.initialRmaNumber != null &&
              widget.initialRmaNumber!.isNotEmpty) {
            final index = rows.indexWhere(
              (r) => r.rmaNumber == widget.initialRmaNumber,
            );
            _detailIndex = index != -1 ? index : 0;
          } else {
            _detailIndex = 0;
          }
          _didApplyInitialSelection = true;
        });
      });
    }
    final list = _selectedView == 'All'
        ? List<_SalesReturnRow>.from(rows)
        : rows.where((r) => r.status.toLowerCase() == _selectedView.toLowerCase()).toList();
    list.sort((a, b) {
      final cmp = _compare(a, b, _sortColumn);
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  void _syncDetailDeepLink(_SalesReturnRow row) {
    final uri = Uri(
      path: '${AppRoutes.salesReturnsOverview}/${row.salesReturnId}',
      queryParameters: {
        'rma': row.rmaNumber,
        'tab': _activeTab.toString(),
        if (_showReceiveForm) 'receive': '1',
        if (_showPdfView) 'pdf': '1',
      },
    );
    if (GoRouterState.of(context).uri.toString() == uri.toString()) return;
    context.go(uri.toString());
  }

  void _selectDetailRow(int index, {bool resetPanels = true}) {
    final rows = _filteredRows;
    if (index < 0 || index >= rows.length) return;
    setState(() {
      _detailIndex = index;
      if (resetPanels) {
        _showReceiveForm = false;
        _showPdfView = false;
      }
    });
    _syncDetailDeepLink(rows[index]);
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
              _columns = columns.map((c) => ColumnConfig(id: c.id, label: c.label, isVisible: c.isVisible, orderIndex: c.orderIndex, isLocked: c.isLocked)).toList();
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
    final selected = _filteredRows.where((r) => r.salesReturnId == salesReturnId);
    if (selected.isNotEmpty) {
      _syncDetailDeepLink(selected.first);
    }
    // Refresh DB-backed providers so status persists across reloads
    ref.invalidate(salesReturnReceivesProvider(salesReturnId));
    ref.invalidate(salesReturnsListProvider(null));
    ZerpaiToast.success(context, 'Receipt ${receive.receiveNumber} created successfully.');
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
    final visibleColumns = _visibleColumns;
    final tableWidth = _tableWidth;

    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useTopPadding: false,
      useHorizontalPadding: false,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (_dropdownOpen || _columnMenuOpen) {
            setState(() {
              _dropdownOpen = false;
              _columnMenuOpen = false;
            });
          }
        },
        child: Container(
          color: AppTheme.backgroundColor,
          child: Stack(
            children: [
              if (returnsAsync.isLoading)
                const _SalesReturnsOverviewSkeleton()
              else if (_detailIndex != null)
                Positioned.fill(child: _buildSplitView(visibleColumns, tableWidth))
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildToolbar(context),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    Expanded(
                      child: _buildFullTable(visibleColumns, tableWidth),
                    ),
                  ],
                ),
              // View dropdown overlay
              if (_dropdownOpen)
                Positioned(
                  top: _detailIndex != null ? 94 : 60,
                  left: _detailIndex != null ? 30 : 24,
                  child: Material(
                    elevation: 0,
                    color: Colors.transparent,
                    child: Container(
                      width: 240,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 480),
                        child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() =>
                                      _favoritesExpanded = !_favoritesExpanded),
                                  child: _DropdownSectionHeader(
                                    label: 'FAVORITES',
                                    count: _starredViews.length,
                                    countColor: AppTheme.primaryBlue,
                                    expanded: _favoritesExpanded,
                                  ),
                                ),
                                if (_favoritesExpanded && _starredViews.isNotEmpty)
                                  ..._viewOptions
                                      .where((opt) => _starredViews.contains(opt))
                                      .map((opt) => _ViewFilterOption(
                                            label: opt,
                                            selected: opt == _selectedView,
                                            starred: true,
                                            onStarTap: () => setState(
                                                () => _starredViews.remove(opt)),
                                            onTap: () => setState(() {
                                              _selectedView = opt;
                                              _dropdownOpen = false;
                                            }),
                                          )),
                                GestureDetector(
                                  onTap: () => setState(() =>
                                      _defaultFiltersExpanded = !_defaultFiltersExpanded),
                                  child: _DropdownSectionHeader(
                                    label: 'DEFAULT FILTERS',
                                    count: _viewOptions.length,
                                    countColor: AppTheme.accentGreen,
                                    expanded: _defaultFiltersExpanded,
                                  ),
                                ),
                                if (_defaultFiltersExpanded)
                                  ..._viewOptions.map(
                                    (opt) => _ViewFilterOption(
                                      label: opt,
                                      selected: opt == _selectedView,
                                      starred: _starredViews.contains(opt),
                                      onStarTap: () => setState(() {
                                        if (_starredViews.contains(opt)) {
                                          _starredViews.remove(opt);
                                        } else {
                                          _starredViews.add(opt);
                                        }
                                      }),
                                      onTap: () => setState(() {
                                        _selectedView = opt;
                                        _dropdownOpen = false;
                                      }),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ),
                    ),
                  ),
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
                            label: _textMode == 'clip' ? 'Clip Text' : 'Wrap Text',
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
            ],
          ),
        ),
      ),
    );
  }

  // ── Full table view ──────────────────────────────────────────────────────────

  Widget _buildFullTable(List<ColumnConfig> visibleColumns, double tableWidth) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width,
        ),
        child: SizedBox(
          width: tableWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TableHeader(
                columns: visibleColumns,
                colWidths: _colWidths,
                columnMenuOpen: _columnMenuOpen,
                onColumnMenuTap: () => setState(() {
                  _dropdownOpen = false;
                  _columnMenuOpen = !_columnMenuOpen;
                }),
                textMode: _textMode,
                sortColumn: _sortColumn,
                sortAscending: _sortAscending,
                onColumnResize: _onColumnResize,
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _filteredRows.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppTheme.borderLight),
                  itemBuilder: (context, index) => _TableRow(
                    row: _filteredRows[index],
                    columns: visibleColumns,
                    colWidths: _colWidths,
                    textMode: _textMode,
                    onTap: () => _selectDetailRow(index, resetPanels: false),
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

  Widget _buildCompactList() {
    return Container(
      width: 460,
      color: AppTheme.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, size: 20, color: AppTheme.textPrimary),
                  onPressed: () => context.go('/sales/returns'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedView == 'All'
                            ? 'All Sales Returns'
                            : _selectedView,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _dropdownOpen
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 15,
                        color: AppTheme.primaryBlueDark,
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                ZButton.primary(
                  label: 'New',
                  icon: LucideIcons.plus,
                  onPressed: () => context.go(AppRoutes.salesReturnsCreate),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  key: _moreMenuKey,
                  width: 32,
                  height: 32,
                  child: TextButton(
                    onPressed: () => _showMoreMenu(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Icon(LucideIcons.moreHorizontal,
                        size: 16, color: AppTheme.textPrimary),
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
                selected: index == _detailIndex,
                onTap: () => _selectDetailRow(index),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel() {
    if (_detailIndex == null ||
        _detailIndex! < 0 ||
        _detailIndex! >= _filteredRows.length) {
      return const Center(
        child: Text(
          'Select a sales return to view details.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }
    final rawRow = _filteredRows[_detailIndex!];
    final dbReceivesAsync =
        ref.watch(salesReturnReceivesProvider(rawRow.salesReturnId));
    final dbReceives = dbReceivesAsync.valueOrNull ?? [];

    if (_showReceiveForm) {
      return _SrReceiveForm(
        row: rawRow,
        salesReturnId: rawRow.salesReturnId,
        warehouseId: rawRow.warehouseId,
        onBack: () {
          setState(() => _showReceiveForm = false);
          _syncDetailDeepLink(rawRow);
        },
        onSubmit: (receive) =>
            _onReceiveSubmitted(rawRow.salesReturnId, receive),
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
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
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
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor(rawRow.status).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rawRow.status[0].toUpperCase() +
                        rawRow.status.substring(1).toLowerCase(),
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
                  onTap: () {},
                ),
                Container(
                  width: 1,
                  height: 28,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  color: AppTheme.borderLight,
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _detailIndex = null;
                      _showReceiveForm = false;
                      _showPdfView = false;
                      _didApplyInitialSelection = true;
                    });
                    if (GoRouterState.of(context).uri.path !=
                        AppRoutes.salesReturnsOverview) {
                      context.go(AppRoutes.salesReturnsOverview);
                    }
                  },
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(LucideIcons.x,
                        size: 20, color: AppTheme.errorRed),
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
                  bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
            ),
            child: Row(
              children: [
                _DetailActionBtn(
                  icon: LucideIcons.pencil,
                  label: 'Edit',
                  onTap: () => context.go(AppRoutes.salesReturnsCreate),
                ),
                const _DetailActionDivider(),
                if (dbReceives.isEmpty)
                  _DetailActionBtn(
                    icon: LucideIcons.packageCheck,
                    label: 'Receive',
                    onTap: () {
                      setState(() {
                        _showReceiveForm = true;
                        _showPdfView = false;
                      });
                      _syncDetailDeepLink(rawRow);
                    },
                  )
                else
                  _DetailActionBtn(
                    icon: LucideIcons.filePlus,
                    label: 'Create Credit Note',
                    onTap: () {
                      final item = rawRow.items.isNotEmpty ? rawRow.items.first : null;
                      final queryParams = {
                        'customer': rawRow.customerName,
                        if (item != null) 'itemName': item.name,
                        if (item != null) 'quantity': item.quantity.toString(),
                        if (item != null) 'rate': item.rate.replaceAll('₹', '').replaceAll(',', '').trim(),
                      };
                      final uri = Uri(
                        path: AppRoutes.salesCreditNotesCreate,
                        queryParameters: queryParams,
                      );
                      context.go(uri.toString());
                    },
                  ),
                const _DetailActionDivider(),
                const _PdfPrintBtn(),
                const _DetailMoreBtn(),
              ],
            ),
          ),
          // Receives / Sales Orders tab — fixed at top, never scrolls away
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
                        onChanged: (v) {
                          setState(() => _showPdfView = v);
                          _syncDetailDeepLink(rawRow);
                        },
                        activeThumbColor: AppTheme.primaryBlue,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Document preview
                  if (_showPdfView)
                    _SrPdfPreview(row: rawRow)
                  else
                    _SrDocumentPreview(row: rawRow),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceivesTab(
      _SalesReturnRow row, List<SalesReturnReceive> dbReceives) {
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
                border:
                    Border(bottom: BorderSide(color: AppTheme.borderLight)),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(5)),
              ),
              child: Row(
                children: [
                  if (dbReceives.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() => _activeTab = 0);
                        _syncDetailDeepLink(row);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: _activeTab == 0
                              ? const Border(
                                  bottom: BorderSide(
                                      color: AppTheme.primaryBlue, width: 2))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Text('Receives',
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _activeTab == 0
                                        ? AppTheme.primaryBlue
                                        : AppTheme.textSecondary)),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: _activeTab == 0
                                    ? AppTheme.primaryBlue
                                    : AppTheme.borderLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${dbReceives.length}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (row.salesOrderNumber != '-')
                  GestureDetector(
                    onTap: () {
                      setState(() => _activeTab = 1);
                      _syncDetailDeepLink(row);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: (_activeTab == 1 || dbReceives.isEmpty)
                            ? const Border(
                                bottom: BorderSide(
                                    color: AppTheme.primaryBlue, width: 2))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Text('Sales Orders',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: (_activeTab == 1 ||
                                          dbReceives.isEmpty)
                                      ? AppTheme.primaryBlue
                                      : AppTheme.textSecondary)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: (_activeTab == 1 ||
                                      dbReceives.isEmpty)
                                  ? AppTheme.primaryBlue
                                  : AppTheme.borderLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('1',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _tabExpanded = !_tabExpanded),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: AnimatedRotation(
                        turns: _tabExpanded ? 0 : -0.5,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(LucideIcons.chevronDown,
                            size: 16, color: AppTheme.textSecondary),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Row(
                children: [
                  Expanded(
                    child: Text('Receive#',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary)),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text('Received On',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary)),
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
              return Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(receive.receiveNumber,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w500)),
                    ),
                    SizedBox(
                      width: 140,
                      child: Text(displayDate,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textPrimary)),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final confirmed =
                            await showZerpaiConfirmationDialog(
                          context,
                          title: 'Delete Return Receipt',
                          message:
                              'Do you really want to delete this Return Receipt?',
                          confirmLabel: 'Delete',
                          variant: ZerpaiConfirmationVariant.warning,
                        );
                        if (!confirmed) return;
                        try {
                          final deleteReceive = ref.read(
                            deleteSalesReturnReceiveProvider,
                          );
                          await deleteReceive(
                            row.salesReturnId,
                            receive.id,
                          );
                          ref.invalidate(
                            salesReturnReceivesProvider(row.salesReturnId),
                          );
                          ref.invalidate(salesReturnsListProvider(null));
                          if (mounted) {
                            ZerpaiToast.success(
                              context,
                              'Return receipt deleted successfully.',
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ZerpaiToast.error(
                              context,
                              'Failed to delete return receipt. Please try again.',
                            );
                          }
                        }
                      },
                      child: const Icon(LucideIcons.trash2,
                          size: 16, color: AppTheme.textSecondary),
                    ),
                  ],
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
                    child: Text('Sales Order#',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text('Date',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text('Status',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.salesOrderNumber,
                      style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: Text(
                      row.date,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: Text(
                      row.status[0].toUpperCase() +
                          row.status.substring(1).toLowerCase(),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _statusColor(row.status)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _dropdownOpen = !_dropdownOpen),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedView == 'All' ? 'All Sales Returns' : _selectedView,
                  style: AppTheme.pageTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _dropdownOpen
                      ? LucideIcons.chevronUp
                      : LucideIcons.chevronDown,
                  size: 18,
                  color: AppTheme.primaryBlueDark,
                ),
              ],
            ),
          ),
          const Spacer(),
          ZButton.primary(
            label: 'New',
            icon: LucideIcons.plus,
            onPressed: () => context.go(AppRoutes.salesReturnsCreate),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 36,
            height: 36,
            child: TextButton(
              onPressed: () => _showMoreMenu(context),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Icon(LucideIcons.moreHorizontal,
                  size: 18, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Document preview ──────────────────────────────────────────────────────────

class _SrDocumentPreview extends StatelessWidget {
  const _SrDocumentPreview({required this.row});
  final _SalesReturnRow row;

  static const Color _divider = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
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
                    Text(
                      row.customerName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryBlue,
                      ),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  color: AppTheme.primaryBlue,
                  child: Text(
                    row.status,
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              border: Border(
                bottom: BorderSide(color: _divider),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: const Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text('#',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      )),
                ),
                Expanded(
                  child: Text('ITEMS & DESCRIPTION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      )),
                ),
                SizedBox(
                  width: 90,
                  child: Text('QUANTITY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      )),
                ),
                SizedBox(
                  width: 80,
                  child: Text('RATE',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      )),
                ),
                SizedBox(
                  width: 90,
                  child: Text('AMOUNT',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      )),
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
  final Set<int> _removedItemIndices = <int>{};

  bool _manualMode = false;
  final List<TextEditingController> _manualItemCtrlrs = [];
  final List<TextEditingController> _manualQtyCtrlrs = [];
  final Map<int, List<Map<String, String>>> _batchDataByItemIndex = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateCtrl = TextEditingController(
        text: '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}');
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
      _manualQtyCtrlrs
          .add(TextEditingController(text: '${item.quantity}'));
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

  DateTime? _parseDialogDate(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    try {
      return DateFormat('dd-MM-yyyy').parse(text);
    } catch (_) {
      try {
        return DateTime.parse(text);
      } catch (_) {
        return null;
      }
    }
  }

  List<int> get _activeItemIndexes => List<int>.generate(
        widget.row.items.length,
        (index) => index,
      ).where((index) => !_removedItemIndices.contains(index)).toList();

  Future<void> _submitReceive() async {
    final dateText = _dateCtrl.text.trim();
    if (dateText.isEmpty) {
      ZerpaiToast.error(context, 'Please enter a receive date.');
      return;
    }

    // Parse dd-MM-yyyy → yyyy-MM-dd for the API
    String isoDate = dateText;
    try {
      final parts = dateText.split('-');
      if (parts.length == 3) {
        isoDate = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    } catch (_) {}

    final visibleIndexes = _activeItemIndexes;
    if (visibleIndexes.isEmpty) {
      ZerpaiToast.error(context, 'Please keep at least one item to receive.');
      return;
    }

    final items = <CreateReceiveItemPayload>[];
    for (final index in visibleIndexes) {
      final item = widget.row.items[index];
      final batchRows = _batchDataByItemIndex[index] ?? const <Map<String, String>>[];
      if (item.productId.trim().isNotEmpty && batchRows.isEmpty) {
        ZerpaiToast.error(
          context,
          'Please add batches for ${item.name}.',
        );
        return;
      }

      final payloadBatches = batchRows.map((batch) {
        final batchId = batch['batchId']?.toString().trim() ?? '';
        final binId = batch['binId']?.toString().trim() ?? '';
        final layerId = batch['layerId']?.toString().trim() ?? '';
        if (batchId.isEmpty || binId.isEmpty) {
          throw StateError('Missing batch mapping for ${item.name}.');
        }
        return CreateReceiveBatchPayload(
          batchId: batchId,
          layerId: layerId.isEmpty ? null : layerId,
          warehouseId: widget.warehouseId,
          binId: binId,
          quantity: double.tryParse(batch['qtyOut']?.toString().trim() ?? '') ??
              _quantityForItem(index),
          focQuantity: double.tryParse(batch['foc']?.toString().trim() ?? '') ??
              0,
          purchaseRate:
              double.tryParse(batch['prate']?.toString().trim() ?? ''),
          mrp: double.tryParse(batch['mrp']?.toString().trim() ?? ''),
          expiryDate: _parseDialogDate(batch['expDate']?.toString()),
          mfgDate: _parseDialogDate(batch['mfgDate']?.toString()),
          mfgBatchNo: batch['mfgBatch']?.toString().trim(),
        );
      }).toList();

      items.add(
        CreateReceiveItemPayload(
          productId: item.productId,
          salesReturnItemId: item.salesReturnItemId.isNotEmpty
              ? item.salesReturnItemId
              : null,
          receivingQty: _quantityForItem(index),
          returnQty: item.quantity.toDouble(),
          batches: payloadBatches,
        ),
      );
    }

    final payload = CreateReceivePayload(
      receiveDate: isoDate,
      warehouseId: widget.warehouseId,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      items: items,
    );

    setState(() => _isSaving = true);
    try {
      final createFn = ref.read(createSalesReturnReceiveProvider);
      final receive = await createFn(widget.salesReturnId, payload);
      if (mounted) widget.onSubmit(receive);
    } catch (e) {
      if (mounted) {
        ZerpaiToast.error(context, 'Failed to save receive. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _openBatchesForItem(int index) async {
    final item = widget.row.items[index];
    final result = await showDialog<PicklistBatchDialogResult>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => PicklistSelectBatchesDialog(
        itemName: item.name,
        productId: item.productId,
        warehouseName: item.warehouseName,
        warehouseId: item.warehouseId,
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
      ? _manualQtyCtrlrs.fold(
          0, (sum, c) => sum + (int.tryParse(c.text) ?? 0))
      : _activeItemIndexes.fold(
          0,
          (sum, index) => sum + widget.row.items[index].quantity,
        );

  static const _colReturned = 110.0;
  static const _colReceived = 110.0;
  static const _colQty = 170.0;

  Widget _vDivider() =>
      Container(width: 1, color: AppTheme.borderLight);

  Widget _hDivider() =>
      Container(height: 1, color: AppTheme.borderLight);

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
                    horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('ITEMS & DESCRIPTION',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary)),
                    if (showAddAll) ...[
                      const SizedBox(height: 2),
                      GestureDetector(
                        onTap: _addAllItems,
                        child: const Text('Add All Items',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.w500)),
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
                child: Text('RETURNED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
              ),
            ),
            _vDivider(),
            SizedBox(
              width: _colReceived,
              child: const Center(
                child: Text('RECEIVED',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
              ),
            ),
            _vDivider(),
            SizedBox(
              width: _colQty,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text('QUANTITY TO RECEIVE',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary)),
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
                      const Icon(LucideIcons.chevronLeft,
                          size: 14, color: AppTheme.primaryBlue),
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
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
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
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide:
                                  const BorderSide(color: AppTheme.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide:
                                  const BorderSide(color: AppTheme.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryBlue, width: 1.5),
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
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8ED),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFFFDFA0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(LucideIcons.info,
                            size: 16, color: Color(0xFFE8A825)),
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
                                            color: AppTheme.textPrimary),
                                      ),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _manualMode = false),
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
                                            color: AppTheme.textPrimary),
                                      ),
                                      WidgetSpan(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _manualMode = true),
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
                            if (_removedItemIndices.contains(i)) {
                              return const SizedBox.shrink();
                            }
                            final item = widget.row.items[i];
                            final savedBatches =
                                _batchDataByItemIndex[i] ??
                                    <Map<String, String>>[];
                            return Column(
                              children: [
                                if (i > 0) _hDivider(),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Items & Description
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets
                                              .fromLTRB(16, 14, 16, 14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(item.name,
                                                  style: const TextStyle(
                                                      fontSize: 13,
                                                      color:
                                                          AppTheme.textPrimary)),
                                              if (item.description
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(item.description,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppTheme
                                                            .textSecondary)),
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
                                            '${item.quantity}(${item.unit})',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppTheme.textSecondary),
                                          ),
                                        ),
                                      ),
                                      _vDivider(),
                                      // Received
                                      const SizedBox(
                                        width: _colReceived,
                                        child: Center(
                                          child: Text('0(pcs)',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppTheme.textSecondary)),
                                        ),
                                      ),
                                      _vDivider(),
                                      // Quantity to receive
                                      SizedBox(
                                        width: _colQty,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              12, 12, 12, 12),
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
                                                      controller:
                                                          _qtyCtrlrs[i],
                                                      textAlign:
                                                          TextAlign.right,
                                                      keyboardType:
                                                          TextInputType.number,
                                                      style: const TextStyle(
                                                          fontSize: 13),
                                                      decoration:
                                                          InputDecoration(
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 6),
                                                        border: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: AppTheme
                                                                      .borderLight),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          borderSide:
                                                              const BorderSide(
                                                                  color: AppTheme
                                                                      .borderLight),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          borderSide: const BorderSide(
                                                              color: AppTheme
                                                                  .primaryBlue,
                                                              width: 1.5),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _removedItemIndices.add(i);
                                                      });
                                                    },
                                                    child: const Icon(
                                                        LucideIcons.xCircle,
                                                        size: 18,
                                                        color:
                                                            AppTheme.errorRed),
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
                                                        color: savedBatches
                                                                .isEmpty
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
                                            style:
                                                const TextStyle(fontSize: 13),
                                            decoration: InputDecoration(
                                              hintText:
                                                  'Type or click to select an item.',
                                              hintStyle: const TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppTheme.textSecondary),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 10),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                    color: AppTheme.borderLight),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                    color: AppTheme.borderLight),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                borderSide: const BorderSide(
                                                    color: AppTheme.primaryBlue,
                                                    width: 1.5),
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
                                            onTap: () =>
                                                _removeManualRow(i),
                                            child: const Icon(
                                                LucideIcons.xCircle,
                                                size: 18,
                                                color: AppTheme.errorRed),
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
                          const Icon(LucideIcons.plus,
                              size: 14, color: AppTheme.primaryBlue),
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
                        fontSize: 13, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 24),

                  // Notes
                  const Text(
                    'Notes (For Internal Use)',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textPrimary),
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
                        borderSide:
                            const BorderSide(color: AppTheme.borderLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide:
                            const BorderSide(color: AppTheme.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                            color: AppTheme.primaryBlue, width: 1.5),
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
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Receive',
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _isSaving ? null : widget.onBack,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          side: const BorderSide(color: AppTheme.borderLight),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary)),
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

class _SrPdfPreview extends StatelessWidget {
  const _SrPdfPreview({required this.row});
  final _SalesReturnRow row;

  static const Color _tableHeaderBg = Color(0xFF3D3D3D);
  static const Color _rowDivider = Color(0xFFE5E7EB);
  static const Color _outerBorder = Color(0xFFDDDDDD);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
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
          padding: const EdgeInsets.all(40),
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
                        Container(
                          width: 200,
                          height: 80,
                          color: const Color(0xFF1A1A2E),
                          alignment: Alignment.center,
                          child: const Text(
                            'Logo',
                            style: TextStyle(color: Colors.white54, fontSize: 13),
                          ),
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
                        const Text('PERINTHALMANNA', style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                        const Text('MALAPPURAM Kerala 679322', style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                        const Text('India', style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                        const SizedBox(height: 4),
                        const Text('GSTIN 32AACCZ4912F1ZL', style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                        const Text('8086355500', style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
                        const Text('zabnixprivatelimited@gmail.com', style: TextStyle(fontSize: 12, color: Color(0xFF444444))),
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
                        style: TextStyle(fontSize: 13, color: Color(0xFF444444)),
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
                        style: TextStyle(fontSize: 13, color: Color(0xFF444444)),
                      ),
                      const SizedBox(width: 32),
                      Text(
                        row.date,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF111111)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Items table: dark header ────────────────────────────────
              Container(
                color: _tableHeaderBg,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Row(
                  children: const [
                    SizedBox(
                      width: 32,
                      child: Text('#',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    Expanded(
                      child: Text('Item & Description',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text('HSN/SAC',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text('Returned\nQty',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    SizedBox(
                      width: 80,
                      child: Text('Rate',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    SizedBox(
                      width: 90,
                      child: Text('Amount',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 32,
                        child: Text(
                          '${item.number}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF444444)),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF111111))),
                            if (item.description.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(item.description,
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          item.hsn.isEmpty ? '' : item.hsn,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF444444)),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          '${item.quantity}.00',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF111111)),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          item.rate.replaceAll('₹', ''),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF111111)),
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text(
                          item.amount.replaceAll('₹', ''),
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF111111)),
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
                    final raw = item.amount.replaceAll('₹', '').replaceAll(',', '').trim();
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
              const SizedBox(height: 32),
            ],
          ),
        ),

        // ── Corner status ribbon ────────────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          child: ClipRect(
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                children: [
                  Positioned(
                    top: 18,
                    left: -28,
                    child: Transform.rotate(
                      angle: -0.785,
                      child: Container(
                        width: 130,
                        height: 36,
                        color: row.status.toUpperCase() == 'APPROVED'
                            ? const Color(0xFF5DADE2)
                            : row.status.toUpperCase() == 'RECEIVED'
                                ? AppTheme.successGreen
                                : row.status.toUpperCase() == 'DECLINED'
                                    ? AppTheme.errorRed
                                    : const Color(0xFF7F8C8D),
                        alignment: Alignment.center,
                        child: Text(
                          row.status[0].toUpperCase() +
                              row.status.substring(1).toLowerCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
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
      ],
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
            // Quantity — grey background fills full row height
            Container(
              width: 90,
              color: const Color(0xFFF3F4F6),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${item.quantity} ${item.unit}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Text(
                    'Returned',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
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
    required this.onTap,
  });
  final _SalesReturnRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SrCompactItem> createState() => _SrCompactItemState();
}

class _SrCompactItemState extends State<_SrCompactItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppTheme.primaryBlue.withValues(alpha: 0.06)
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
                widget.row.status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _SalesReturnsOverviewPageState._statusColor(
                      widget.row.status),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared detail panel widgets ───────────────────────────────────────────────

class _DetailHeaderIconButton extends StatefulWidget {
  const _DetailHeaderIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_DetailHeaderIconButton> createState() =>
      _DetailHeaderIconButtonState();
}

class _DetailHeaderIconButtonState
    extends State<_DetailHeaderIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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
          child: Icon(widget.icon,
              size: 16, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

class _DetailActionDivider extends StatelessWidget {
  const _DetailActionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      color: AppTheme.borderLight,
    );
  }
}

class _DetailActionBtn extends StatefulWidget {
  const _DetailActionBtn({
    this.icon,
    this.label,
    required this.onTap,
  });
  final IconData? icon;
  final String? label;
  final VoidCallback onTap;

  @override
  State<_DetailActionBtn> createState() => _DetailActionBtnState();
}

class _DetailActionBtnState extends State<_DetailActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null)
                Icon(widget.icon, size: 13, color: AppTheme.textSecondary),
              if (widget.icon != null && widget.label != null)
                const SizedBox(width: 5),
              if (widget.label != null)
                Text(widget.label!,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textPrimary)),
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
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: (isOpen || _hovered)
                  ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.fileText, size: 13,
                    color: AppTheme.textSecondary),
                const SizedBox(width: 5),
                const Text('PDF/Print',
                    style: TextStyle(fontSize: 13, color: AppTheme.textPrimary)),
                const SizedBox(width: 3),
                Icon(
                  isOpen ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 11,
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
  const _DetailMoreBtn();

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
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 6)),
        ),
        menuChildren: [
          _MenuOption(
            label: 'Mark as Declined',
            onTap: () => _controller.close(),
          ),
          _MenuOption(
            label: 'Delete',
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: (isOpen || _hovered)
                  ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              LucideIcons.moreHorizontal,
              size: 15,
              color: (isOpen || _hovered)
                  ? AppTheme.primaryBlue
                  : AppTheme.textSecondary,
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
                Icon(widget.icon, size: 15,
                    color: _hovered ? Colors.white : AppTheme.textSecondary),
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
        return _BodyText(widget.row.rmaNumber,
            color: AppTheme.primaryBlueDark,
            fontWeight: FontWeight.w600,
            textMode: widget.textMode);
      case 'salesOrderNumber':
        return _BodyText(widget.row.salesOrderNumber, textMode: widget.textMode);
      case 'customerName':
        return _BodyText(widget.row.customerName, textMode: widget.textMode);
      case 'status':
        return _BodyText(widget.row.status,
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
            textMode: widget.textMode);
      case 'receiveStatus':
        return _BodyText(widget.row.receiveStatus,
            color: AppTheme.successGreen,
            fontWeight: FontWeight.w500,
            textMode: widget.textMode);
      case 'refundStatus':
        return _BodyText(widget.row.refundStatus,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
            textMode: widget.textMode);
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
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: isWrap ? 10 : 0),
          child: Row(
            crossAxisAlignment:
                isWrap ? CrossAxisAlignment.start : CrossAxisAlignment.center,
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

// ── Dropdown widgets ──────────────────────────────────────────────────────────

class _DropdownSectionHeader extends StatelessWidget {
  const _DropdownSectionHeader({
    required this.label,
    required this.count,
    required this.countColor,
    required this.expanded,
  });
  final String label;
  final int count;
  final Color countColor;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: const Color(0xFFF5F6FA),
      child: Row(
        children: [
          Icon(
            expanded ? LucideIcons.chevronDown : LucideIcons.chevronRight,
            size: 13,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.4,
                )),
          ),
          if (count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: countColor,
                  borderRadius: BorderRadius.circular(10)),
              child: Text('$count',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  )),
            ),
        ],
      ),
    );
  }
}

class _ViewFilterOption extends StatefulWidget {
  const _ViewFilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onStarTap,
    this.starred = false,
  });
  final String label;
  final bool selected;
  final bool starred;
  final VoidCallback onTap;
  final VoidCallback onStarTap;

  @override
  State<_ViewFilterOption> createState() => _ViewFilterOptionState();
}

class _ViewFilterOptionState extends State<_ViewFilterOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppTheme.primaryBlue
                : _hovered
                    ? AppTheme.primaryBlue.withValues(alpha: 0.06)
                    : Colors.transparent,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: widget.selected
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: widget.selected
                          ? Colors.white
                          : AppTheme.textPrimary,
                    )),
              ),
              GestureDetector(
                onTap: widget.onStarTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  child: Icon(
                    widget.starred ? Icons.star : Icons.star_border,
                    size: 16,
                    color: widget.selected
                        ? Colors.white.withValues(alpha: 0.85)
                        : widget.starred
                            ? const Color(0xFFE8A838)
                            : AppTheme.borderLight,
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
    final iconColor =
        filled ? AppTheme.backgroundColor : AppTheme.primaryBlue;

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
                    ? Border.all(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.3))
                    : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: foreground,
                      fontWeight: widget.selected
                          ? FontWeight.w500
                          : FontWeight.w400,
                    )),
              ),
              if (widget.selected)
                Icon(LucideIcons.check,
                    size: 14,
                    color: filled
                        ? AppTheme.backgroundColor
                        : AppTheme.primaryBlue),
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
          color: showActive
              ? AppTheme.primaryBlue
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15,
                color: showActive ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: showActive ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (hasChevron)
              Icon(LucideIcons.chevronRight, size: 14,
                  color: showActive ? Colors.white : AppTheme.textSecondary),
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
                          ZerpaiToast.success(context, 'Exporting Sales Return...');
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
            color: showActive
                ? AppTheme.primaryBlue
                : Colors.transparent,
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
                  widget.sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
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
    this.hsn = '',
    this.productId = '',
    this.salesReturnItemId = '',
    required this.quantity,
    required this.unit,
    required this.rate,
    required this.amount,
  });

  final int number;
  final String name;
  final String description = '';
  final String hsn;
  final String productId;
  final String salesReturnItemId;
  final String warehouseName = 'ZABNIX PRIVATE LIMITED';
  final String warehouseId = 'sales-return-overview';
  final int quantity;
  final String unit;
  final String rate;
  final String amount;
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
    this.warehouseId,
    this.items = const [],
  });

  final String date;
  final String rmaNumber;
  final String salesOrderNumber;
  final String customerName;
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
          color: showActive
              ? AppTheme.primaryBlue
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15,
                color: showActive ? Colors.white : AppTheme.textSecondary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: showActive ? Colors.white : AppTheme.textPrimary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            if (hasChevron)
              Icon(LucideIcons.chevronRight, size: 14,
                  color: showActive ? Colors.white : AppTheme.textSecondary),
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
                          ZerpaiToast.success(context, 'Exporting Sales Return...');
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
            color: showActive
                ? AppTheme.primaryBlue
                : Colors.transparent,
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
                    color: showActive ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(
                  widget.sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown,
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

class _SubmenuItem extends StatefulWidget {
  const _SubmenuItem({
    required this.label,
    required this.onTap,
  });

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
            color: _hovered
                ? AppTheme.primaryBlue
                : Colors.transparent,
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
