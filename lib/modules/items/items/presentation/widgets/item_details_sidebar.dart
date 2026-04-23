import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/items/items/models/item_model.dart';

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

  static const _tabs = ['Item Details', 'Stock Locations', 'Transactions'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = ref.watch(itemDetailsSidebarProvider);

    return Drawer(
      backgroundColor: Colors.white,
      width: 400,
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
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item?.productName ?? 'Item Details',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
                fontFamily: 'Inter',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
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
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
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
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection('Basic Information', [
          _buildRow('Item code', item.itemCode),
          if (item.sku != null) _buildRow('SKU', item.sku!),
          _buildRow('Type', item.type == 'goods' ? 'Goods' : 'Service'),
          if (item.billingName != null)
            _buildRow('Billing name', item.billingName!),
          if (item.categoryName != null)
            _buildRow('Category', item.categoryName!),
          if (item.unitName != null) _buildRow('Unit', item.unitName!),
          _buildRow('Active', item.isActive ? 'Yes' : 'No'),
        ]),
        if (item.sellingPrice != null || item.costPrice != null || item.mrp != null)
          _buildSection('Pricing', [
            if (item.mrp != null)
              _buildRow('MRP', '₹${item.mrp!.toStringAsFixed(2)}'),
            if (item.sellingPrice != null)
              _buildRow(
                  'Selling price', '₹${item.sellingPrice!.toStringAsFixed(2)}'),
            if (item.ptr != null)
              _buildRow('PTR', '₹${item.ptr!.toStringAsFixed(2)}'),
            if (item.costPrice != null)
              _buildRow(
                  'Cost price', '₹${item.costPrice!.toStringAsFixed(2)}'),
          ]),
        _buildSection('Tax & Regulatory', [
          if (item.hsnCode != null) _buildRow('HSN code', item.hsnCode!),
          if (item.taxPreference != null)
            _buildRow('Tax preference', item.taxPreference!),
          if (item.intraStateTaxName != null)
            _buildRow('Intra-state tax', item.intraStateTaxName!),
          if (item.interStateTaxName != null)
            _buildRow('Inter-state tax', item.interStateTaxName!),
        ]),
        _buildSection('Inventory', [
          _buildRow(
              'Track inventory', item.isTrackInventory ? 'Yes' : 'No'),
          if (item.stockOnHand != null)
            _buildRow(
                'Stock on hand', item.stockOnHand!.toStringAsFixed(2)),
          if (item.reorderPoint > 0)
            _buildRow(
                'Reorder point', item.reorderPoint.toString()),
          if (item.storageName != null)
            _buildRow('Storage', item.storageName!),
          if (item.rackName != null) _buildRow('Rack', item.rackName!),
        ]),
      ],
    );
  }

  Widget _buildStockLocations(Item item) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSection('Stock Summary', [
          _buildRow('Stock on hand',
              '${item.stockOnHand?.toStringAsFixed(2) ?? '0.00'}'),
          _buildRow('Opening stock',
              '${item.openingStock?.toStringAsFixed(2) ?? '0.00'}'),
          if (item.committedStock != null)
            _buildRow('Committed', item.committedStock!.toStringAsFixed(2)),
          if (item.toBeReceived != null)
            _buildRow(
                'To be received', item.toBeReceived!.toStringAsFixed(2)),
          if (item.toBeShipped != null)
            _buildRow('To be shipped', item.toBeShipped!.toStringAsFixed(2)),
        ]),
        if (item.storageName != null)
          _buildSection('Location', [
            if (item.storageName != null)
              _buildRow('Storage', item.storageName!),
            if (item.rackName != null) _buildRow('Rack', item.rackName!),
          ]),
        const SizedBox(height: 8),
        const Text(
          'Detailed per-location breakdown is available in the Inventory module.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildTransactions(Item item) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (item.toBeInvoiced != null)
          _buildSection('Pending', [
            if (item.toBeInvoiced != null)
              _buildRow(
                  'To be invoiced', item.toBeInvoiced!.toStringAsFixed(2)),
            if (item.toBeBilled != null)
              _buildRow('To be billed', item.toBeBilled!.toStringAsFixed(2)),
          ]),
        const SizedBox(height: 8),
        const Text(
          'Full transaction history is available in the Reports module.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.4,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: rows,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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
}
