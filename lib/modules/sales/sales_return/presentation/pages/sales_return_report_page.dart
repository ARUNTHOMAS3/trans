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
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class SalesReturnsReportPage extends ConsumerStatefulWidget {
  const SalesReturnsReportPage({super.key});

  @override
  ConsumerState<SalesReturnsReportPage> createState() =>
      _SalesReturnsReportPageState();
}

class _SalesReturnsReportPageState extends ConsumerState<SalesReturnsReportPage> {

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
  final Set<int> _selectedIndices = {};
  final _moreMenuKey = GlobalKey();
  final _columnSettingsKey = GlobalKey();
  final _hScrollController = ScrollController();

  @override
  void dispose() {
    _hScrollController.dispose();
    super.dispose();
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
    return colSum + 92; // 16(pad) + 28(icon) + 32(checkbox) + 16(pad)
  }

  int _compare(_SalesReturnRow a, _SalesReturnRow b, String column) {
    switch (column) {
      case 'date':
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
        return a.rmaNumber.compareTo(b.rmaNumber);
      case 'salesOrderNumber':
        return a.salesOrderNumber.compareTo(b.salesOrderNumber);
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

  List<_SalesReturnRow> _buildRows(
    List<SalesReturn> returns,
    Map<String, String> customerMap,
    Map<String, String> productMap,
  ) {
    return returns.map((r) {
      String formattedDate = r.returnDate;
      try {
        final dt = DateTime.parse(r.returnDate);
        formattedDate = DateFormat('dd-MM-yyyy').format(dt);
      } catch (_) {}
      final totalQty = r.items.fold<double>(0, (s, i) => s + i.returnQty);
      final itemCount = r.items.length;
      return _SalesReturnRow(
        date: formattedDate,
        rmaNumber: r.rmaNumber,
        salesOrderNumber: r.referenceNumber ?? '-',
        customerName: customerMap[r.customerId] ?? r.customerId,
        status: r.status,
        receiveStatus: r.status == 'received' ? 'Received' : 'Pending',
        refundStatus: 'Pending',
        returned: itemCount > 0
            ? '${totalQty % 1 == 0 ? totalQty.toInt() : totalQty}'
            : '-',
        amountRefunded: '-',
        itemLines: r.items.map<_ItemLine>((item) {
          final name = productMap[item.productId] ?? item.productId;
          return _ItemLine(
            productName: name,
            returnQty: item.returnQty,
            receivableQty: item.receivableQty,
          );
        }).toList(),
      );
    }).toList();
  }

  List<_SalesReturnRow> _filteredRows(List<_SalesReturnRow> rows) {
    final list = _selectedView == 'All'
        ? List<_SalesReturnRow>.from(rows)
        : rows.where((r) => r.status.toLowerCase() == _selectedView.toLowerCase()).toList();
    list.sort((a, b) {
      final cmp = _compare(a, b, _sortColumn);
      return _sortAscending ? cmp : -cmp;
    });
    return list;
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

  void _showMoreMenu(BuildContext context) {
    final box = _moreMenuKey.currentContext?.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.of(context).size.width;
    double menuTop = 65;
    double menuRight = 24;
    if (box != null) {
      final pos = box.localToGlobal(Offset.zero);
      menuTop = pos.dy + box.size.height + 4;
      menuRight = screenWidth - (pos.dx + box.size.width);
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
            right: menuRight,
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

  void _showColumnMenu(BuildContext context) {
    final box = _columnSettingsKey.currentContext?.findRenderObject() as RenderBox?;
    final screenWidth = MediaQuery.of(context).size.width;
    double menuTop = 148;
    double menuLeft = 14;
    if (box != null) {
      final pos = box.localToGlobal(Offset.zero);
      menuTop = pos.dy + box.size.height + 4;
      menuLeft = pos.dx.clamp(8.0, screenWidth - 208);
    }
    setState(() => _columnMenuOpen = true);
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
              onTap: () {
                Navigator.of(dialogContext).pop();
                setState(() => _columnMenuOpen = false);
              },
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: menuTop,
            left: menuLeft,
            child: Material(
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
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        setState(() => _columnMenuOpen = false);
                        _openColumnCustomizer();
                      },
                    ),
                    _ColumnMenuOption(
                      label: _textMode == 'clip' ? 'Clip Text' : 'Wrap Text',
                      icon: _textMode == 'clip'
                          ? LucideIcons.minus
                          : LucideIcons.alignLeft,
                      selected: false,
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        setState(() {
                          _textMode = _textMode == 'clip' ? 'wrap' : 'clip';
                          _columnMenuOpen = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      if (mounted && _columnMenuOpen) {
        setState(() => _columnMenuOpen = false);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final returnsAsync = ref.watch(salesReturnsListProvider(null));
    final customers = ref.watch(salesCustomersProvider).valueOrNull ?? [];
    final customerMap = {for (final c in customers) c.id: c.displayName};
    final products = ref.watch(itemsControllerProvider).items;
    final productMap = <String, String>{
      for (final p in products)
        if (p.id != null) p.id!: p.productName,
    };
    final allRows = returnsAsync.valueOrNull == null
        ? <_SalesReturnRow>[]
        : _buildRows(returnsAsync.valueOrNull!, customerMap, productMap);
    final rows = _filteredRows(allRows);

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildToolbar(context),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  Expanded(
                    child: returnsAsync.isLoading
                        ? const _SalesReturnsReportSkeleton()
                        : returnsAsync.hasError
                            ? Center(
                                child: Text(
                                  'Failed to load sales returns',
                                  style: TextStyle(color: AppTheme.errorRed),
                                ),
                              )
                            : _buildFullTable(visibleColumns, tableWidth, rows),
                  ),
                ],
              ),
              // View dropdown overlay
              if (_dropdownOpen)
                Positioned(
                  top: 60,
                  left: 24,
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
            ],
          ),
        ),
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
                  _selectedView == 'All' ? 'Sales Returns Report' : '$_selectedView Sales Returns',
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
            key: _moreMenuKey,
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

  Widget _buildFullTable(List<ColumnConfig> visibleColumns, double tableWidth, List<_SalesReturnRow> rows) {
    final rowCount = rows.length;
    final allSelected = _selectedIndices.isNotEmpty && _selectedIndices.length == rowCount;
    final someSelected = _selectedIndices.isNotEmpty && _selectedIndices.length < rowCount;
    final hasSelection = _selectedIndices.isNotEmpty;
    return Scrollbar(
      controller: _hScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
      controller: _hScrollController,
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
                onColumnMenuTap: () => _showColumnMenu(context),
                textMode: _textMode,
                sortColumn: _sortColumn,
                sortAscending: _sortAscending,
                onColumnResize: _onColumnResize,
                onSort: (colId) => setState(() {
                  if (_sortColumn == colId) {
                    _sortAscending = !_sortAscending;
                  } else {
                    _sortColumn = colId;
                    _sortAscending = true;
                  }
                }),
                columnSettingsKey: _columnSettingsKey,
                allSelected: allSelected,
                someSelected: someSelected,
                hasSelection: hasSelection,
                onSelectAll: (v) => setState(() {
                  if (v == true) {
                    _selectedIndices.addAll(List.generate(rowCount, (i) => i));
                  } else {
                    _selectedIndices.clear();
                  }
                }),
              ),
              const Divider(height: 1, color: AppTheme.borderLight),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: rows.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: AppTheme.borderLight),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return _TableRow(
                      row: row,
                      columns: visibleColumns,
                      colWidths: _colWidths,
                      textMode: _textMode,
                      selected: _selectedIndices.contains(index),
                      hasSelection: hasSelection,
                      onChanged: (v) => _toggleRow(index, v),
                      onTap: () {
                        context.go(
                          Uri(
                            path: AppRoutes.salesReturnsOverview,
                            queryParameters: {'rma': row.rmaNumber},
                          ).toString(),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

// Helper widgets local to this file

class _SalesReturnsReportSkeleton extends StatelessWidget {
  const _SalesReturnsReportSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar skeleton
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight)),
          ),
          child: Row(
            children: [
              const Skeleton(width: 48, height: 16),
              const SizedBox(width: 16),
              const Skeleton(width: 120, height: 28),
              const Spacer(),
              const Skeleton(width: 80, height: 28),
              const SizedBox(width: 8),
              const Skeleton(width: 80, height: 28),
              const SizedBox(width: 8),
              const Skeleton(width: 32, height: 28),
            ],
          ),
        ),
        // Header row skeleton
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: const Color(0xFFF3F4F6),
          child: Row(
            children: [
              const SizedBox(width: 60),
              ...List.generate(8, (i) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Skeleton(width: [80, 100, 120, 140, 80, 100, 80, 80][i].toDouble(), height: 13),
                ),
              )),
            ],
          ),
        ),
        // Row skeletons
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: 10,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppTheme.borderLight),
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const SizedBox(width: 60),
                  ...List.generate(8, (i) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Skeleton(
                        width: [60.0, 90.0, 80.0, 140.0, 70.0, 80.0, 70.0, 70.0][i],
                        height: 13,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ItemLine {
  const _ItemLine({
    required this.productName,
    required this.returnQty,
    required this.receivableQty,
  });
  final String productName;
  final double returnQty;
  final double receivableQty;
}

class _SalesReturnRow {
  _SalesReturnRow({
    required this.date,
    required this.rmaNumber,
    required this.salesOrderNumber,
    required this.customerName,
    required this.status,
    required this.receiveStatus,
    required this.refundStatus,
    required this.returned,
    required this.amountRefunded,
    this.itemLines = const [],
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
  final List<_ItemLine> itemLines;
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
    required this.onSort,
    required this.columnSettingsKey,
    required this.allSelected,
    required this.someSelected,
    required this.onSelectAll,
    required this.hasSelection,
  });

  final List<ColumnConfig> columns;
  final Map<String, double> colWidths;
  final bool columnMenuOpen;
  final VoidCallback onColumnMenuTap;
  final String textMode;
  final String sortColumn;
  final bool sortAscending;
  final void Function(String id, double delta) onColumnResize;
  final ValueChanged<String> onSort;
  final GlobalKey columnSettingsKey;
  final bool allSelected;
  final bool someSelected;
  final ValueChanged<bool?> onSelectAll;
  final bool hasSelection;

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
            if (!hasSelection)
              SizedBox(
                key: columnSettingsKey,
                width: 28,
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
            SizedBox(
              width: 32,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Checkbox(
                  value: allSelected || someSelected,
                  tristate: false,
                  onChanged: (v) => onSelectAll(allSelected ? false : true),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: AppTheme.primaryBlue,
                  side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
                  visualDensity: VisualDensity.compact,
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
                onTap: () => onSort(col.id),
              ),
          ],
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
    this.onTap,
  });

  final double width;
  final String label;
  final bool sorted;
  final bool sortAscending;
  final String textMode;
  final ValueChanged<double>? onResize;
  final VoidCallback? onTap;

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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: MouseRegion(
                  cursor: widget.onTap != null
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: Padding(
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
                ),
              ),
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

class _TableRow extends StatefulWidget {
  const _TableRow({
    required this.row,
    required this.columns,
    required this.colWidths,
    required this.textMode,
    required this.onTap,
    required this.selected,
    required this.hasSelection,
    required this.onChanged,
  });

  final _SalesReturnRow row;
  final List<ColumnConfig> columns;
  final Map<String, double> colWidths;
  final String textMode;
  final VoidCallback onTap;
  final bool selected;
  final bool hasSelection;
  final ValueChanged<bool?> onChanged;

  @override
  State<_TableRow> createState() => _TableRowState();
}

class _TableRowState extends State<_TableRow> {
  bool _hovered = false;

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'approved':
      case 'received':
      case 'refunded':
      case 'credited':
        return AppTheme.successGreen;
      case 'partial':
        return AppTheme.primaryBlue;
      default:
        return AppTheme.textSecondary;
    }
  }

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
        return const SizedBox.shrink();
      case 'customerName':
        return _BodyText(widget.row.customerName, textMode: widget.textMode);
      case 'status':
        return _BodyText(widget.row.status,
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
            textMode: widget.textMode);
      case 'receiveStatus':
        return _BodyText(
          widget.row.receiveStatus,
          color: _statusColor(widget.row.receiveStatus),
          fontWeight: FontWeight.w500,
          textMode: widget.textMode,
        );
      case 'refundStatus':
        return _BodyText(
          widget.row.refundStatus,
          color: _statusColor(widget.row.refundStatus),
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
          color: widget.selected
              ? AppTheme.primaryBlue.withValues(alpha: 0.07)
              : _hovered
              ? AppTheme.primaryBlue.withValues(alpha: 0.03)
              : Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: isWrap ? 10 : 0),
          child: Row(
            crossAxisAlignment:
                isWrap ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              if (!widget.hasSelection) const SizedBox(width: 28),
              SizedBox(
                height: isWrap ? null : 48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 32,
                    child: Checkbox(
                      value: widget.selected,
                      onChanged: widget.onChanged,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: AppTheme.primaryBlue,
                      side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ),
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
          height: 36,
          color: widget.selected
              ? AppTheme.primaryBlue.withValues(alpha: 0.08)
              : _hovered
                  ? const Color(0xFFF3F4F6)
                  : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w400,
                    color: widget.selected
                        ? AppTheme.primaryBlueDark
                        : AppTheme.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onStarTap,
                child: Icon(
                  widget.starred ? LucideIcons.star : LucideIcons.star,
                  size: 14,
                  color: widget.starred ? Colors.amber : const Color(0xFFD1D5DB),
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
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ColumnMenuOption> createState() => _ColumnMenuOptionState();
}

class _ColumnMenuOptionState extends State<_ColumnMenuOption> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final showActive = widget.selected || _hovered;
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
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: showActive ? Colors.white : AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: showActive ? Colors.white : AppTheme.textPrimary,
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
            Icon(icon,
                size: 15,
                color: showActive ? Colors.white : AppTheme.textSecondary),
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
              Icon(LucideIcons.chevronRight,
                  size: 14,
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
          // Submenu card — LEFT side, expands leftward away from the button
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
                              context, 'Exporting Sales Return...');
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
            )
          else
            // Spacer keeps main menu pinned to the right edge of the button
            const SizedBox(width: 184),
          // Main menu card — always on the RIGHT, right-aligned to button
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
            color: showActive ? AppTheme.primaryBlue : Colors.transparent,
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
