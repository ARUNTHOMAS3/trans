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
import '../providers/purchases_purchase_orders_provider.dart';
import '../models/purchases_purchase_orders_order_model.dart';

class PurchaseOrderOverviewScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;
  const PurchaseOrderOverviewScreen({super.key, this.initialSearchQuery});

  @override
  ConsumerState<PurchaseOrderOverviewScreen> createState() => _PurchaseOrderOverviewScreenState();
}

class _PurchaseOrderOverviewScreenState extends ConsumerState<PurchaseOrderOverviewScreen> {
  String? _activePurchaseOrderId;
  final Set<String> _selectedIds = {};
  String _sortField = 'order_date';
  bool _sortAscending = false;
  bool _shouldWrapText = false;
  String _filterType = 'All';
  Map<String, double>? _customColumnWidths;
  final ScrollController _horizontalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
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
      child: purchaseOrdersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyState();
          }

          final filtered = orders.where((o) {
            if (_filterType == 'All') return true;
            return o.status == _filterType;
          }).toList();

          final sorted = _getSortedList(filtered);

          return Column(
            children: [
              _buildMainToolbar(context),
              _buildFilterBar(orders),
              Expanded(child: _buildTableView(sorted)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => _buildErrorWidget(err.toString()),
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

  Widget _buildMainToolbar(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 20),
            child: Text(
              'All Purchase Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const Spacer(),
          ZButton.primary(
            onPressed: () {
              context.push('/purchases/purchase-orders/create');
            },
            icon: LucideIcons.plus,
            label: 'New',
          ),
          const SizedBox(width: 4),
          ZTableMoreMenu(
            width: 32,
            height: 32,
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
          const SizedBox(width: 24),
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
            Icon(_sortAscending ? LucideIcons.arrowUp : LucideIcons.arrowDown, size: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterBar(List<PurchaseOrder> orders) {
    final statuses = orders.map((o) => o.status).toSet().toList();
    statuses.insert(0, 'All');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        children: [
          Text(
            'Filter By :',
            style: AppTheme.bodyText.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => statuses.map((status) => PopupMenuItem(value: status, child: Text(status))).toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  Text(
                    'Status: $_filterType',
                    style: AppTheme.bodyText.copyWith(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(LucideIcons.chevronDown, size: 14, color: AppTheme.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxWidget(bool isSelected, {bool isPartially = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: isSelected || isPartially
          ? Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(3)),
              child: Center(child: Icon(isPartially ? LucideIcons.minus : LucideIcons.check, size: 14, color: Colors.white)),
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
        final columnWidths = _customColumnWidths ?? _calculateColumnWidths(constraints.maxWidth);
        
        const double actualPrefixWidth = 78.0; // Slider + Checkbox space
        final double totalColumnsWidth = columnWidths.values.fold(0.0, (sum, w) => sum + w);
        
        final screenWidth = math.max(constraints.maxWidth, totalColumnsWidth + actualPrefixWidth + 40);

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
        _customColumnWidths = _calculateColumnWidths(context.size?.width ?? 1200);
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
      'status': (80.0, 0.8), // Reduced width as requested
      'received': (80.0, 0.8),
      'billed': (80.0, 0.8),
      'amount': (100.0, 1.0),
      'delivery_date': (100.0, 1.0),
    };

    double totalMinWidth = staticPrefixWidth;
    double totalFlex = 0;

    metrics.forEach((key, m) {
      totalMinWidth += m.$1;
      totalFlex += m.$2;
    });

    final extraSpace = math.max(0.0, totalWidth - totalMinWidth);
    final results = <String, double>{};

    metrics.forEach((key, m) {
      results[key] = m.$1 + (m.$2 / totalFlex) * extraSpace;
    });

    return results;
  }

  Widget _buildTableHeader(Map<String, double> columnWidths, List<PurchaseOrder> orders) {
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
            onCustomize: () {},
          ),
          const SizedBox(width: 12),
          _buildSelectAllCheckbox(orders),
          const SizedBox(width: 12),
          ...columnWidths.keys.map((colId) {
            final width = columnWidths[colId]!;
            final align = (colId == 'received' || colId == 'billed') ? TextAlign.center : TextAlign.left;

            return _ResizableHeaderCell(
              width: width,
              onResize: (dx) => _resizeColumn(colId, dx),
              child: _buildHeaderCell(
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

  Widget _buildHeaderCell(String text, String colId, {double? width, TextAlign? align}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: align == TextAlign.center
            ? Center(child: Text(text, style: AppTheme.metaHelper.copyWith(fontWeight: FontWeight.bold)))
            : Text(text, style: AppTheme.metaHelper.copyWith(fontWeight: FontWeight.bold), textAlign: align),
      ),
    );
  }

  Widget _buildSelectAllCheckbox(List<PurchaseOrder> orders) {
    final isAllSelected = orders.isNotEmpty && _selectedIds.length == orders.length;
    final isPartiallySelected = _selectedIds.isNotEmpty && _selectedIds.length < orders.length;

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

  Widget _buildVirtualRow(PurchaseOrder order, Map<String, double> columnWidths) {
    final isSelected = _selectedIds.contains(order.id);

    return InkWell(
      onTap: () {
        setState(() {
          _activePurchaseOrderId = order.id;
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
            ...columnWidths.keys.map((colId) {
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
        content = Text(DateFormat('dd-MM-yyyy').format(order.orderDate), style: AppTheme.tableCell);
        break;
      case 'location':
        content = Text(order.warehouseName ?? 'ZABNIX PRIVATE LIMITED', style: AppTheme.tableCell);
        break;
      case 'order_number':
        content = InkWell(
          onTap: () => context.push('/purchases/purchase-orders/${order.id}'),
          child: Text(order.orderNumber, style: AppTheme.tableCell.copyWith(color: AppTheme.primaryBlue)),
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
        content = Center(child: Icon(Icons.circle, color: order.status == 'Closed' ? Colors.green : Colors.orange, size: 12));
        break;
      case 'billed':
        content = Center(child: Icon(Icons.circle, color: order.status == 'Closed' ? Colors.blue : Colors.grey, size: 12));
        break;
      case 'amount':
        content = Text('₹${order.total.toStringAsFixed(2)}', style: AppTheme.tableCell);
        break;
      case 'delivery_date':
        content = Text(order.expectedDeliveryDate != null ? DateFormat('dd-MM-yyyy').format(order.expectedDeliveryDate!) : '-', style: AppTheme.tableCell);
        break;
      default:
        content = const Text('');
    }

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: content,
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
        color = AppTheme.successGreen;
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: AppTheme.space16),
          Text('No purchase orders yet', style: AppTheme.sectionHeader.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: AppTheme.space8),
          Text('Create your first purchase order to get started', style: AppTheme.metaHelper),
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
          Text('Failed to load purchase orders', style: AppTheme.sectionHeader.copyWith(color: AppTheme.errorRed)),
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
                onHorizontalDragUpdate: (details) => widget.onResize(details.delta.dx),
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Container(
                    color: _isHovering ? AppTheme.primaryBlue.withValues(alpha: 0.2) : Colors.transparent,
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


