import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/modules/auth/controller/auth_controller.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/routing/app_router.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/controllers/items_controller.dart';
import 'package:zerpai_erp/modules/sales/customers/providers/customers_provider.dart';
import 'package:zerpai_erp/modules/sales/sales_return/models/sales_return_model.dart';
import 'package:zerpai_erp/modules/sales/sales_return/providers/sales_return_provider.dart';
import 'package:zerpai_erp/modules/purchases/purchase_returns/providers/purchases_purchase_returns_provider.dart';
import 'package:zerpai_erp/core/providers/entity_provider.dart';
import 'package:zerpai_erp/shared/models/column_config.dart';
import 'package:zerpai_erp/shared/widgets/tables/column_customizer.dart';
import 'package:zerpai_erp/shared/widgets/tables/z_module_table.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
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

  /// Shared with the sales returns overview page so a view starred in one place
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

  final Map<String, double> _colWidths = {
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

  FavoriteFilterOption _activeOption = _srFilterOptions.first;
  String get _selectedView => _activeOption.label;
  bool _columnMenuOpen = false;
  String _textMode = 'clip';
  String _sortColumn = _createdSortColumn;
  bool _sortAscending = false;
  List<ColumnConfig> _columns = _defaultColumns();
  final Set<int> _selectedIndices = {};
  final _moreMenuKey = GlobalKey();

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
        ColumnConfig(id: 'status', label: 'Status', orderIndex: 4, isLocked: true),
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

  /// Row chrome outside the columns: 16(pad) + 28(icon) + 32(checkbox) + 16(pad).
  static const double _kRowChrome = 92;

  /// Column widths grown to fill [available], so the table spans the viewport
  /// instead of leaving dead space down the right-hand side.
  ///
  /// Surplus is shared out in proportion to each column's own width, so a
  /// column the user widened stays proportionally wider. When the viewport is
  /// narrower than the declared widths they are returned untouched and the
  /// table scrolls horizontally as before.
  Map<String, double> _stretchedColWidths(
    List<ColumnConfig> cols,
    double available,
  ) {
    final base = <String, double>{
      for (final c in cols) c.id: _colWidths[c.id] ?? 120,
    };
    final baseSum = base.values.fold(0.0, (a, b) => a + b);
    if (baseSum <= 0) return base;

    final surplus = available - (baseSum + _kRowChrome);
    if (surplus <= 0) return base;

    return {
      for (final entry in base.entries)
        entry.key: entry.value + surplus * (entry.value / baseSum),
    };
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

  /// Value of a return, as `Σ(return_qty × product selling price)`.
  ///
  /// Returns null when it cannot be known in full — no lines, or any line whose
  /// product has no selling price on record. A partial sum is deliberately not
  /// shown: this figure drives approvals, and a number that silently omits
  /// unpriced lines reads as a complete, smaller total.
  ///
  /// Note this is the product's *current* selling price, not the price the
  /// customer was invoiced at — sales_return_items carries no rate, and there is
  /// no FK back to invoice_items to recover one.
  double? _returnValue(SalesReturn r, Map<String, double> priceMap) {
    if (r.items.isEmpty) return null;
    var total = 0.0;
    for (final item in r.items) {
      final price = priceMap[item.productId];
      if (price == null || price <= 0) return null;
      total += item.returnQty * price;
    }
    return total;
  }

  List<_SalesReturnRow> _buildRows(
    List<SalesReturn> returns,
    Map<String, String> customerMap,
    Map<String, String> productMap,
    Map<String, double> priceMap,
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
        reason: r.reason,
        createdAt: DateTime.tryParse(r.createdAt),
        totalAmount: _returnValue(r, priceMap),
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

  /// One entry per return currently in view — who sent goods back, when, and
  /// why. What the customer calls their purchase return is our sales return.
  ///
  /// Deliberately not per line item: a single return can carry many products,
  /// which would bury the customer under repeated rows.
  ///
  /// Honours the active view filter and sort, so the popover always mirrors the
  /// table beneath it.
  List<_ReturnedItemEntry> _returnedItemEntries() {
    final state = ref.read(purchaseReturnsProvider).valueOrNull;
    final allReturns = state?.returns ?? const [];
    if (allReturns.isEmpty) return const [];

    final entityId = ref.read(entityProvider).entityId;
    final returns = allReturns.where((r) => r.entityId == entityId).toList();

    return [
      for (final row in returns)
        _ReturnedItemEntry(
          rmaNumber: row.returnNumber,
          date: row.returnDate != null
              ? DateFormat('dd MMM yyyy').format(row.returnDate!)
              : '',
          customerName: row.vendorName ?? '',
          reason: row.status,
          totalAmount: row.total,
        ),
    ];
  }

  /// Opens the create form pre-filled from the ticked returns.
  ///
  /// The RMA numbers travel as a query parameter and the create page loads the
  /// returns itself. Passing a `SalesReturnEditData` via `state.extra` does not
  /// work here: the app's top-level redirect rewrites every path to add the org
  /// system id, and GoRouter drops `extra` across a redirect — the page would
  /// receive null. A query param also survives a browser refresh.
  void _convertToSalesReturn(List<String> rmaNumbers) {
    if (rmaNumbers.isEmpty) return;

    final returns = ref.read(salesReturnsListProvider(null)).valueOrNull ?? [];
    final selected =
        returns.where((r) => rmaNumbers.contains(r.rmaNumber)).toList();

    if (selected.isEmpty) {
      ZerpaiToast.show(context, 'Could not load the selected returns.',
          isError: true);
      return;
    }

    if (selected.map((r) => r.customerId).toSet().length > 1) {
      ZerpaiToast.show(
        context,
        'Selected returns belong to different customers — convert one customer at a time.',
        isError: true,
      );
      return;
    }

    if (selected.every((r) => r.items.isEmpty)) {
      ZerpaiToast.show(
        context,
        'The selected return has no line items to convert.',
        isError: true,
      );
      return;
    }

    final query = Uri.encodeQueryComponent(
      selected.map((r) => r.rmaNumber).join(','),
    );
    context.go('${AppRoutes.salesReturnsCreate}?from_rma=$query');
  }

  /// Placeholder for the approval decision — see the note in the popover.
  void _rejectReturns(List<String> rmaNumbers) {
    if (rmaNumbers.isEmpty) return;
    ZerpaiToast.show(
      context,
      'Rejecting ${rmaNumbers.length} return${rmaNumbers.length == 1 ? '' : 's'} '
      'is not wired yet — no status update endpoint exists.',
      isError: true,
    );
  }

  void _showReturnedItemsPopover(BuildContext context) {
    final entries = _returnedItemEntries();

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
          // Flush to the top of the viewport, horizontally centred — no top
          // inset, so the card starts at y = 0.
          Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: _ReturnedItemsPopover(
                entries: entries,
                onClose: () => Navigator.of(dialogContext).pop(),
                onConvert: (rmaNumbers) {
                  Navigator.of(dialogContext).pop();
                  _convertToSalesReturn(rmaNumbers);
                },
                onReject: (rmaNumbers) {
                  Navigator.of(dialogContext).pop();
                  _rejectReturns(rmaNumbers);
                },
              ),
            ),
          ),
        ],
      ),
    );
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
    ref.watch(purchaseReturnsProvider);
    final customers = ref.watch(customersProvider).valueOrNull ?? [];
    final customerMap = {for (final c in customers) c.id: c.displayName};
    final products = ref.watch(itemsControllerProvider).items;
    final productMap = <String, String>{
      for (final p in products)
        if (p.id != null) p.id!: p.productName,
    };
    final priceMap = <String, double>{
      for (final p in products)
        if (p.id != null && p.sellingPrice != null) p.id!: p.sellingPrice!,
    };
    final allRows = returnsAsync.valueOrNull == null
        ? <_SalesReturnRow>[]
        : _buildRows(
            returnsAsync.valueOrNull!, customerMap, productMap, priceMap);
    final rows = _filteredRows(allRows);

    final visibleColumns = _visibleColumns;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildToolbar(context),
                  const Divider(height: 1, color: AppTheme.borderLight),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: returnsAsync.isLoading
                          ? const KeyedSubtree(
                              key: ValueKey("sales-returns-report-loading"),
                              child: _SalesReturnsReportSkeleton(),
                            )
                          : returnsAsync.hasError
                            ? KeyedSubtree(
                                key: const ValueKey("sales-returns-report-error"),
                                child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Failed to load sales returns',
                                        style: TextStyle(
                                          color: AppTheme.errorRed,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '${returnsAsync.error}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      ZButton.secondary(
                                        label: 'Retry',
                                        onPressed: () => ref.invalidate(
                                          salesReturnsListProvider,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ),
                              )
                            : KeyedSubtree(
                                key: const ValueKey("sales-returns-report-content"),
                                child: _buildFullTable(visibleColumns, rows),
                              ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    final user = ref.watch(authUserProvider);
    final isOrg = (user?.activeTenantType ?? '').trim().toUpperCase() == 'ORG';

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          FavoriteFilterDropdown(
            moduleName: 'sales_returns',
            options: _srFilterOptions,
            selectedOption: _activeOption,
            showChevron: true,
            onChanged: (opt) {
              setState(() {
                _activeOption = opt;
                _columnMenuOpen = false;
                _selectedIndices.clear();
              });
            },
          ),
          const Spacer(),
          if (isOrg) ...[
            SizedBox(
              height: 36,
              child: TextButton.icon(
                onPressed: () => _showReturnedItemsPopover(context),
                icon: const Icon(LucideIcons.clipboardCheck,
                    size: 16, color: AppTheme.textPrimary),
                label: const Text(
                  'Purchase Return Approval',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: AppTheme.borderLight),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          _FilledActionSquare(
            icon: LucideIcons.plus,
            onTap: () => context.go(AppRoutes.salesReturnsCreate),
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
    );
  }

  String _formatStatus(String status) {
    if (status.isEmpty) return status;
    return status.split('_').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

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

  Widget _cellForColumn(_SalesReturnRow row, String id) {
    switch (id) {
      case 'date':
        return Text(
          row.date,
          maxLines: _textMode == 'wrap' ? null : 1,
          overflow: _textMode == 'wrap' ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        );
      case 'rmaNumber':
        return Text(
          row.rmaNumber,
          maxLines: _textMode == 'wrap' ? null : 1,
          overflow: _textMode == 'wrap' ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.primaryBlueDark,
            fontWeight: FontWeight.w600,
          ),
        );
      case 'salesOrderNumber':
        return const SizedBox.shrink();
      case 'customerName':
        return Text(
          row.customerName,
          maxLines: _textMode == 'wrap' ? null : 1,
          overflow: _textMode == 'wrap' ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        );
      case 'status':
        final String displayStatus;
        if (row.status.toUpperCase() == 'RECEIVED') {
          displayStatus = 'Approved';
        } else {
          displayStatus = _formatStatus(row.status);
        }
        return Text(
          displayStatus,
          maxLines: _textMode == 'wrap' ? null : 1,
          overflow: _textMode == 'wrap' ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        );
      case 'receiveStatus':
        return Text(
          _formatStatus(row.receiveStatus),
          maxLines: _textMode == 'wrap' ? null : 1,
          overflow: _textMode == 'wrap' ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: _statusColor(row.receiveStatus),
            fontWeight: FontWeight.w500,
          ),
        );
      case 'refundStatus':
        return Text(
          _formatStatus(row.refundStatus),
          maxLines: _textMode == 'wrap' ? null : 1,
          overflow: _textMode == 'wrap' ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: _statusColor(row.refundStatus),
            fontWeight: FontWeight.w500,
          ),
        );
      case 'returned':
        return Text(
          row.returned,
          maxLines: _textMode == 'wrap' ? null : 1,
          overflow: _textMode == 'wrap' ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        );
      case 'amountRefunded':
        return Text(
          row.amountRefunded,
          maxLines: _textMode == 'wrap' ? null : 1,
          overflow: _textMode == 'wrap' ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFullTable(
      List<ColumnConfig> visibleColumns, List<_SalesReturnRow> rows) {
    final rowCount = rows.length;
    final allSelected = _selectedIndices.isNotEmpty && _selectedIndices.length == rowCount;
    return LayoutBuilder(builder: (context, constraints) {
      final colWidths = _stretchedColWidths(visibleColumns, constraints.maxWidth);
      final tWidth =
          colWidths.values.fold(0.0, (a, b) => a + b) + _kRowChrome;

      return Scrollbar(
      controller: _hScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
      controller: _hScrollController,
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SizedBox(
          width: tWidth,
          child: ZModuleTable<_SalesReturnRow>(
            rows: rows,
            visibleColumns: visibleColumns,
            rowId: (row) => row.rmaNumber,
            horizontalInset: 0,
            allSelected: allSelected,
            isSelected: (id) {
              final index = rows.indexWhere((r) => r.rmaNumber == id);
              return _selectedIndices.contains(index);
            },
            wrapText: _textMode == 'wrap',
            sortKey: _sortColumn,
            sortAscending: _sortAscending,
            headerBuilder: (context, column) => Text(
              column.label.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0,
              ),
            ),
            onHeaderTap: (key) => setState(() {
              if (_sortColumn == key) {
                _sortAscending = !_sortAscending;
              } else {
                _sortColumn = key;
                _sortAscending = true;
              }
            }),
            onHoveredRowChanged: (id) {},
            onAllSelectedChanged: (selected) {
              setState(() {
                if (selected) {
                  _selectedIndices.addAll(List.generate(rowCount, (i) => i));
                } else {
                  _selectedIndices.clear();
                }
              });
            },
            onRowSelectChanged: (id, selected) {
              final index = rows.indexWhere((r) => r.rmaNumber == id);
              if (index != -1) {
                setState(() {
                  if (selected) {
                    _selectedIndices.add(index);
                  } else {
                    _selectedIndices.remove(index);
                  }
                });
              }
            },
            onWrapTextChanged: (val) {
              setState(() {
                _textMode = val ? 'wrap' : 'clip';
              });
            },
            onCustomizeColumns: _openColumnCustomizer,
            columnWidthBuilder: (id) => colWidths[id] ?? 120,
            cellBuilder: (context, row, column) {
              return InkWell(
                onTap: () {
                  context.go(
                    Uri(
                      path: AppRoutes.salesReturnsOverview,
                      queryParameters: {
                        'rma': row.rmaNumber,
                        'view': 'overview',
                      },
                    ).toString(),
                  );
                },
                child: _cellForColumn(row, column.id),
              );
            },
          ),
        ),
      ),
      ),
      );
    });
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
    this.reason,
    this.totalAmount,
    this.itemLines = const [],
    this.createdAt,
  });

  /// `sales_returns.created_at` — when the record was saved, as opposed to
  /// [date], which is the user-entered return date and can be backdated.
  final DateTime? createdAt;

  final String date;
  final String rmaNumber;
  final String salesOrderNumber;
  final String customerName;
  final String status;
  final String receiveStatus;
  final String refundStatus;
  final String returned;
  final String amountRefunded;

  /// Why the customer sent the goods back — `sales_returns.reason`.
  final String? reason;

  /// Value of the returned goods, or null when it cannot be fully determined.
  /// See [_SalesReturnsReportPageState._returnValue].
  final double? totalAmount;
  final List<_ItemLine> itemLines;
}

/// One return, reduced to the three things the popover showcases: when the
/// customer sent the goods back, who they are, and why.
class _ReturnedItemEntry {
  const _ReturnedItemEntry({
    required this.rmaNumber,
    required this.date,
    required this.customerName,
    this.reason,
    this.totalAmount,
  });

  /// Stable selection key — survives re-sorting, unlike a row index.
  final String rmaNumber;
  final String date;
  final String customerName;
  final String? reason;

  /// Null when the value cannot be fully determined — rendered as an em dash
  /// rather than a misleading partial figure.
  final double? totalAmount;
}

/// Anchored popover listing what customers have sent back, with the date,
/// who returned it and why.
class _ReturnedItemsPopover extends StatefulWidget {
  const _ReturnedItemsPopover({
    required this.entries,
    required this.onClose,
    required this.onConvert,
    required this.onReject,
  });

  final List<_ReturnedItemEntry> entries;
  final VoidCallback onClose;

  /// Invoked with the RMA numbers ticked in the list.
  final void Function(List<String> rmaNumbers) onConvert;
  final void Function(List<String> rmaNumbers) onReject;

  @override
  State<_ReturnedItemsPopover> createState() => _ReturnedItemsPopoverState();
}

class _ReturnedItemsPopoverState extends State<_ReturnedItemsPopover> {
  /// Selected returns, keyed by RMA# so the set survives re-sorting.
  final Set<String> _selected = {};

  static const double _checkW = 44;
  static const double _dateW = 140;
  static const double _customerW = 300;
  static const double _reasonW = 340;
  static const double _amountW = 160;

  static final _money =
      NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

  List<_ReturnedItemEntry> get _entries => widget.entries;

  bool get _allSelected =>
      _entries.isNotEmpty && _selected.length == _entries.length;

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(_entries.map((e) => e.rmaNumber));
      }
    });
  }

  void _toggle(String rmaNumber, bool? value) {
    setState(() {
      if (value == true) {
        _selected.add(rmaNumber);
      } else {
        _selected.remove(rmaNumber);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Container(
      width: _checkW + _dateW + _customerW + _reasonW + _amountW + 40,
      constraints: const BoxConstraints(maxHeight: 620),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              children: [
                const Icon(LucideIcons.packageOpen,
                    size: 16, color: AppTheme.textPrimary),
                const SizedBox(width: 8),
                const Text(
                  'Returned Items',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${entries.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                // Sits with the title rather than the footer: rejecting is the
                // counterpart to the header selection, not a document action.
                ZButton.secondary(
                  label: 'Reject',
                  icon: LucideIcons.ban,
                  onPressed: _selected.isEmpty
                      ? null
                      : () => widget.onReject(_selected.toList()),
                ),
                const Spacer(),
                if (_selected.isNotEmpty) ...[
                  Text(
                    '${_selected.length} selected',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  onPressed: widget.onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                      width: 28, height: 28),
                  icon: const Icon(LucideIcons.x,
                      size: 16, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),
          if (entries.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Text(
                'No returned items in the current view.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
            )
          else ...[
            Container(
              color: AppTheme.bgLight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: _checkW,
                    child: Checkbox(
                      value: _allSelected,
                      onChanged: (_) => _toggleAll(),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      activeColor: AppTheme.primaryBlue,
                      side: const BorderSide(
                          color: AppTheme.borderLight, width: 1.5),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: _dateW, child: _PopoverHeaderCell('Date')),
                  const SizedBox(
                      width: _customerW, child: _PopoverHeaderCell('Vendor')),
                  const SizedBox(
                      width: _reasonW, child: _PopoverHeaderCell('Status')),
                  const SizedBox(
                      width: _amountW, child: _PopoverHeaderCell('Total Amount', alignRight: true)),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppTheme.borderLight),
                itemBuilder: (context, i) {
                  final e = entries[i];
                  final hasReason =
                      e.reason != null && e.reason!.trim().isNotEmpty;
                  final isSelected = _selected.contains(e.rmaNumber);
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: _checkW,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (v) => _toggle(e.rmaNumber, v),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            activeColor: AppTheme.primaryBlue,
                            side: const BorderSide(
                                color: AppTheme.borderLight, width: 1.5),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        SizedBox(width: _dateW, child: _PopoverCell(e.date)),
                        SizedBox(
                            width: _customerW,
                            child: _PopoverCell(e.customerName)),
                        SizedBox(
                          width: _reasonW,
                          child: _PopoverCell(
                            hasReason ? e.reason!.trim() : '—',
                            muted: !hasReason,
                          ),
                        ),
                        SizedBox(
                          width: _amountW,
                          child: _PopoverCell(
                            e.totalAmount == null
                                ? '—'
                                : _money.format(e.totalAmount),
                            muted: e.totalAmount == null,
                            alignRight: true,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const Divider(height: 1, color: AppTheme.borderLight),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ZButton.primary(
                  label: 'Convert to Sales Return',
                  icon: LucideIcons.arrowRightLeft,
                  // Disabled until something is ticked — the action is defined
                  // by the selection.
                  onPressed: _selected.isEmpty
                      ? null
                      : () => widget.onConvert(_selected.toList()),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PopoverHeaderCell extends StatelessWidget {
  const _PopoverHeaderCell(this.label, {this.alignRight = false});
  final String label;
  final bool alignRight;

  @override
  Widget build(BuildContext context) => Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      );
}

class _PopoverCell extends StatelessWidget {
  const _PopoverCell(this.value, {this.muted = false, this.alignRight = false});
  final String value;
  final bool muted;
  final bool alignRight;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(right: alignRight ? 0 : 8),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: TextStyle(
            fontSize: 13,
            color: muted ? AppTheme.textSecondary : AppTheme.textPrimary,
            fontFeatures:
                alignRight ? const [FontFeature.tabularFigures()] : null,
          ),
        ),
      );
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
    // Selected sits on grey, hover paints blue, and hover wins when both apply.
    // Mirrors the same menu on the overview page.
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
