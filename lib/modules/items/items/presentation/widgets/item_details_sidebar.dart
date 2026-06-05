import 'package:zerpai_erp/shared/utils/org_scope_resolver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:web/web.dart' as web;
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';
import 'package:zerpai_erp/modules/items/items/models/items_stock_models.dart';
import 'package:zerpai_erp/modules/items/items/repositories/items_repository_provider.dart';
import 'package:zerpai_erp/shared/widgets/z_skeletons.dart';

/// StateProvider that holds the currently selected item for the sidebar.
/// Set this before opening the endDrawer:
///   ref.read(itemDetailsSidebarProvider.notifier).state = selectedItem;
final itemDetailsSidebarProvider = StateProvider<Item?>((ref) => null);

class ItemDetailsSidebar extends ConsumerStatefulWidget {
  const ItemDetailsSidebar({super.key});

  @override
  ConsumerState<ItemDetailsSidebar> createState() => _ItemDetailsSidebarState();
}

class _ItemDetailsSidebarState extends ConsumerState<ItemDetailsSidebar>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _loadedItemId;
  String? _warehouseStocksLoadedForItemId;
  String? _transactionsLoadedForItemId;
  bool _loadingWarehouseStocks = false;
  bool _loadingTransactions = false;
  List<WarehouseStockRow> _warehouseStocks = const <WarehouseStockRow>[];
  List<TransactionData> _transactions = const <TransactionData>[];
  String _stockMode = 'Physical Stock';
  String _transactionType = 'Sales Orders';
  String _transactionStatus = 'All';
  bool _showOtherDetails = false;

  static const _tabs = ['Item Details', 'Stock Locations', 'Transactions'];
  static const _stockModes = ['Physical Stock', 'Accounting Stock'];
  static const _transactionTypes = [
    'Sales Orders',
    'Invoices',
    'Delivery Challans',
    'Credit Notes',
    'Purchase Orders',
    'Bills',
    'Vendor Credits',
    'Inventory Adjustments',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(itemDetailsSidebarProvider);
    if (item?.id != _loadedItemId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadItemContext(item);
        }
      });
    }

    return Drawer(
      backgroundColor: Colors.white,
      width: 456,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, item),
            _buildTabBar(),
            Expanded(
              child: item == null
                  ? _buildEmpty()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildItemDetails(item),
                        _buildStockLocations(item),
                        _buildTransactions(item),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Item? item) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 8, 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Item Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppTheme.errorRed),
            onPressed: () => Scaffold.of(context).closeEndDrawer(),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          fontFamily: 'Inter',
        ),
        labelColor: AppTheme.primaryBlue,
        unselectedLabelColor: AppTheme.textSecondary,
        indicatorColor: AppTheme.primaryBlue,
        indicatorWeight: 2,
        tabs: _tabs.map((t) => Tab(text: t.toUpperCase())).toList(),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Text(
        'No item selected.',
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondary,
          fontFamily: 'Inter',
        ),
      ),
    );
  }

  Widget _buildItemDetails(Item item) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeroCard(item),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: LucideIcons.truck,
                      label: 'To Be Shipped',
                      value: _formatQty(item.toBeShipped),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: LucideIcons.packageCheck,
                      label: 'To Be Received',
                      value: _formatQty(item.toBeReceived),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              _buildInfoSection(
                'Sales Information',
                <Widget>[
                  _buildSimpleInfoRow(
                    'Price',
                    _formatCurrency(item.sellingPrice),
                  ),
                  _buildSimpleInfoRow(
                    'Account',
                    item.salesAccountName ?? 'n/a',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildInfoSection(
                'Purchase Information',
                <Widget>[
                  _buildSimpleInfoRow(
                    'Price',
                    _formatCurrency(item.costPrice),
                  ),
                  _buildSimpleInfoRow(
                    'Account',
                    item.purchaseAccountName ?? 'n/a',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              InkWell(
                onTap: () {
                  setState(() => _showOtherDetails = !_showOtherDetails);
                },
                child: Text(
                  _showOtherDetails ? 'Other Details ▾' : 'Other Details ▸',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              if (_showOtherDetails) ...[
                const SizedBox(height: 12),
                _buildSimpleInfoRow(
                  'Inventory Account',
                  item.inventoryAccountName ?? 'n/a',
                ),
                if ((item.inventoryValuationMethod ?? '').isNotEmpty)
                  _buildSimpleInfoRow(
                    'Inventory Valuation',
                    item.inventoryValuationMethod!,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStockLocations(Item item) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(
          children: [
            _buildMenuSelector(
              value: _stockMode,
              options: _stockModes,
              onSelected: (value) => setState(() => _stockMode = value),
              width: 168,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadingWarehouseStocks)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ZTableSkeleton(rows: 4, columns: 4),
          )
        else if (_warehouseStocks.isEmpty)
          const Text(
            'No stock locations found.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontFamily: 'Inter',
            ),
          )
        else
          Column(
            children: [
              _buildStockHeader(),
              ..._warehouseStocks.map(
                (row) => _buildStockRow(row, mode: _stockMode),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTransactions(Item item) {
    final filtered = _filteredTransactions;
    final statusOptions = _statusOptionsForType(_transactionType);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(
          children: [
            _buildMenuSelector(
              value: _transactionType,
              options: _transactionTypes,
              onSelected: (value) {
                setState(() {
                  _transactionType = value;
                  _transactionStatus = 'All';
                });
              },
              width: 170,
              menuWidth: 190,
              maxMenuHeight: 300,
              outlineWhenOpen: true,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Text(
                  'Status:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(width: 4),
                _buildMenuSelector(
                  value: _transactionStatus,
                  options: statusOptions,
                  onSelected: (value) {
                    setState(() => _transactionStatus = value);
                  },
                  width: 78,
                  menuWidth: 150,
                  maxMenuHeight: 300,
                  showFieldChrome: false,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_loadingTransactions)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: ZTableSkeleton(rows: 5, columns: 4),
          )
        else if (filtered.isEmpty)
          const Text(
            'No transactions found.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontFamily: 'Inter',
            ),
          )
        else
          Column(
            children: filtered
                .map((entry) => _buildTransactionRow(entry))
                .toList(growable: false),
          ),
      ],
    );
  }

  Widget _buildHeroCard(Item item) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFFF3F8FE),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              LucideIcons.image,
              size: 34,
              color: AppTheme.borderColor,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory Items',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: item.id == null
                      ? null
                      : () {
                          final orgSystemId =
                              resolveOrgSystemId(context);
                          final targetPath =
                              '/$orgSystemId/items/detail/${item.id!}?tab=overview';
                          if (kIsWeb) {
                            web.window.open(targetPath, '_blank');
                            Scaffold.of(context).closeEndDrawer();
                            return;
                          }
                          Scaffold.of(context).closeEndDrawer();
                          context.go(targetPath);
                        },
                  child: Text(
                    item.productName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryBlue,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(item.unitName ?? 'pcs').toLowerCase()} • ${(item.brandName ?? 'Other Brands').toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 14),
        ...children,
        const Divider(height: 30, color: Color(0xFFF0F2F5)),
      ],
    );
  }

  Widget _buildSimpleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 32,
            child: Text(
              'LOCATION\nNAME',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              'STOCK ON\nHAND',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              'COMMITTED\nSTOCK',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              'AVAILABLE FOR\nSALE',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockRow(WarehouseStockRow row, {required String mode}) {
    final numbers = mode == 'Accounting Stock' ? row.accounting : row.physical;
    final available = numbers.onHand - numbers.committed;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 32,
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: row.displayName),
                  if (row.isPrimary)
                    const TextSpan(
                      text: ' ★',
                      style: TextStyle(color: Color(0xFFF4B400)),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              _formatQty(numbers.onHand),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              _formatQty(numbers.committed),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
          Expanded(
            flex: 20,
            child: Text(
              available.toStringAsFixed(2),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(TransactionData entry) {
    final leftTitle = _transactionPrimaryTitle(entry);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  leftTitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${entry.documentNumber}  ${entry.date}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryBlue,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Item Price  ${_formatCurrency(entry.price)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_quantityLabelForType()}  ${entry.quantitySold.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _transactionPrimaryTitle(TransactionData entry) {
    if (_transactionType == 'Inventory Adjustments') {
      final reason = entry.reason.trim();
      return reason.isEmpty ? '-' : reason;
    }
    final customer = entry.customerName.trim();
    if (customer.isNotEmpty) return customer;
    final vendor = entry.vendorName.trim();
    if (vendor.isNotEmpty) return vendor;
    return '-';
  }

  Widget _buildMenuSelector({
    required String value,
    required List<String> options,
    required ValueChanged<String> onSelected,
    double width = 160,
    double? menuWidth,
    double maxMenuHeight = 360,
    TextStyle? textStyle,
    bool showFieldChrome = true,
    bool outlineWhenOpen = false,
  }) {
    final resolvedMenuWidth = menuWidth ?? width;
    return MenuAnchor(
      style: MenuStyle(
        backgroundColor: WidgetStateProperty.all(Colors.white),
        surfaceTintColor: WidgetStateProperty.all(Colors.white),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        minimumSize: WidgetStateProperty.all(Size(resolvedMenuWidth, 0)),
        maximumSize: WidgetStateProperty.all(Size(resolvedMenuWidth, maxMenuHeight)),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        elevation: WidgetStateProperty.all(4),
      ),
      menuChildren: <Widget>[
        for (final option in options)
          MenuItemButton(
            onPressed: () => onSelected(option),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (option == value || states.contains(WidgetState.hovered)) {
                  return AppTheme.primaryBlue;
                }
                return Colors.white;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                if (option == value || states.contains(WidgetState.hovered)) {
                  return Colors.white;
                }
                return AppTheme.textPrimary;
              }),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              minimumSize: WidgetStateProperty.all(Size(resolvedMenuWidth, 0)),
              maximumSize: WidgetStateProperty.all(Size(resolvedMenuWidth, 46)),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            child: SizedBox(
              width: resolvedMenuWidth - 12,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
      ],
      builder: (context, controller, child) {
        return InkWell(
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            constraints: BoxConstraints(minWidth: width),
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            decoration: showFieldChrome || outlineWhenOpen
                ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: outlineWhenOpen && controller.isOpen
                          ? AppTheme.primaryBlue
                          : (showFieldChrome
                                ? AppTheme.borderColor
                                : Colors.transparent),
                    ),
                  )
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: textStyle ??
                        const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Inter',
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppTheme.textPrimary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadItemContext(Item? item) async {
    _loadedItemId = item?.id;
    if (item?.id == null || item!.id!.isEmpty) {
      if (mounted) {
        setState(() {
          _warehouseStocks = const <WarehouseStockRow>[];
          _transactions = const <TransactionData>[];
          _warehouseStocksLoadedForItemId = null;
          _transactionsLoadedForItemId = null;
        });
      }
      return;
    }

    final isSameItem = _warehouseStocksLoadedForItemId == item.id &&
        _transactionsLoadedForItemId == item.id;
    if (!isSameItem) {
      setState(() {
        _loadingWarehouseStocks = false;
        _loadingTransactions = false;
        _warehouseStocks = const <WarehouseStockRow>[];
        _transactions = const <TransactionData>[];
        _warehouseStocksLoadedForItemId = null;
        _transactionsLoadedForItemId = null;
        _stockMode = 'Physical Stock';
        _transactionType = 'Sales Orders';
        _transactionStatus = 'All';
        _showOtherDetails = false;
      });
    }

    _loadTabDataIfNeeded(item.id!);
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      final item = ref.read(itemDetailsSidebarProvider);
      final itemId = item?.id;
      if (itemId != null && itemId.isNotEmpty) {
        _loadTabDataIfNeeded(itemId);
      }
    }
  }

  void _loadTabDataIfNeeded(String itemId) {
    if (!mounted || _loadedItemId != itemId) return;
    switch (_tabController.index) {
      case 1:
        _loadWarehouseStocksIfNeeded(itemId);
        break;
      case 2:
        _loadTransactionsIfNeeded(itemId);
        break;
      default:
        break;
    }
  }

  Future<void> _loadWarehouseStocksIfNeeded(String itemId) async {
    if (_warehouseStocksLoadedForItemId == itemId || _loadingWarehouseStocks) {
      return;
    }
    setState(() => _loadingWarehouseStocks = true);
    final repo = ref.read(itemRepositoryProvider);
    try {
      final stocks = await repo.getItemWarehouseStocks(itemId);
      if (!mounted || _loadedItemId != itemId) return;
      setState(() {
        _warehouseStocks = stocks;
        _warehouseStocksLoadedForItemId = itemId;
        _loadingWarehouseStocks = false;
      });
    } catch (_) {
      if (!mounted || _loadedItemId != itemId) return;
      setState(() => _loadingWarehouseStocks = false);
    }
  }

  Future<void> _loadTransactionsIfNeeded(String itemId) async {
    if (_transactionsLoadedForItemId == itemId || _loadingTransactions) {
      return;
    }
    setState(() => _loadingTransactions = true);
    final repo = ref.read(itemRepositoryProvider);
    try {
      final transactions = await repo.getItemStockTransactions(itemId);
      if (!mounted || _loadedItemId != itemId) return;
      setState(() {
        _transactions = transactions;
        _transactionsLoadedForItemId = itemId;
        _loadingTransactions = false;
      });
    } catch (_) {
      if (!mounted || _loadedItemId != itemId) return;
      setState(() => _loadingTransactions = false);
    }
  }

  List<TransactionData> get _filteredTransactions {
    final type = _transactionType;
    final status = _transactionStatus;
    final selectedStatusKey = _normalizeStatusKey(status);
    return _transactions.where((entry) {
      if (_normalizeTransactionType(entry.documentType) != type) {
        return false;
      }
      if (selectedStatusKey != 'all' &&
          _normalizeStatusKey(entry.status) != selectedStatusKey) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }

  List<String> _statusOptionsForType(String type) {
    return _statusLabelsForCurrentType(type);
  }

  String _normalizeStatusKey(String raw) {
    return raw.trim().toLowerCase().replaceAll(RegExp(r'[\s_-]'), '');
  }

  List<String> _statusLabelsForCurrentType(String type) {
    switch (type) {
      case 'Sales Orders':
        return const [
          'All',
          'Draft',
          'Partially Invoiced',
          'Invoiced',
          'Closed',
          'Void',
          'Confirmed',
          'Partially shipped',
          'Shipped',
          'Dropshipped',
          'Backordered',
          'On Hold',
        ];
      case 'Invoices':
        return const [
          'All',
          'Draft',
          'Client Viewed',
          'Partially Paid',
          'Unpaid',
          'Overdue',
          'Paid',
          'Void',
          'Sent',
        ];
      case 'Delivery Challans':
        return const ['All', 'Draft', 'Open', 'Delivered', 'Returned'];
      case 'Credit Notes':
      case 'Vendor Credits':
        return const ['All', 'Open', 'Closed', 'Void'];
      case 'Purchase Orders':
        return const [
          'All',
          'Draft',
          'Billed',
          'Partially Billed',
          'Canceled',
          'Issued',
          'Received',
          'Partially Received',
          'Dropshipped',
        ];
      case 'Bills':
        return const [
          'All',
          'Open',
          'Overdue',
          'Unpaid',
          'Partially Paid',
          'Paid',
          'Void',
        ];
      case 'Inventory Adjustments':
        return const ['All', 'Draft', 'Adjusted'];
      default:
        return const ['All'];
    }
  }

  String _normalizeTransactionType(String raw) {
    final value = raw.trim().toLowerCase();
    final compact = value.replaceAll(RegExp(r'[\s_-]'), '');
    if (value.contains('sales order') || compact == 'salesorders') {
      return 'Sales Orders';
    }
    if (value.contains('invoice') || compact == 'invoices') return 'Invoices';
    if (value.contains('delivery') || compact == 'deliverychallans') {
      return 'Delivery Challans';
    }
    if (value.contains('credit note') || compact == 'creditnotes') {
      return 'Credit Notes';
    }
    if (value.contains('purchase order') || compact == 'purchaseorders') {
      return 'Purchase Orders';
    }
    if (value == 'bill' || value.contains('bills')) return 'Bills';
    if (value.contains('vendor credit') || compact == 'vendorcredits') {
      return 'Vendor Credits';
    }
    if (compact == 'inventoryadjustments') return 'Inventory Adjustments';
    return _transactionTypes.first;
  }

  String _quantityLabelForType() {
    switch (_transactionType) {
      case 'Purchase Orders':
      case 'Bills':
      case 'Vendor Credits':
        return 'Quantity Purchased';
      default:
        return 'Quantity Sold';
    }
  }

  String _formatCurrency(double? value) {
    if (value == null) return 'n/a';
    return '₹${value.toStringAsFixed(2)}';
  }

  String _formatQty(double? value) {
    return (value ?? 0).toStringAsFixed(2);
  }
}
