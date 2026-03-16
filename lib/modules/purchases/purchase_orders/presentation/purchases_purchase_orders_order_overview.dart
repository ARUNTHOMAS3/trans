// FILE: lib/modules/purchases/purchase_orders/presentation/purchases_purchase_orders_order_overview.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../shared/widgets/zerpai_layout.dart';
import '../../../../../shared/widgets/z_button.dart';
import '../providers/purchases_purchase_orders_provider.dart';
import '../models/purchases_purchase_orders_order_model.dart';

class PurchaseOrderOverviewScreen extends ConsumerWidget {
  const PurchaseOrderOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchaseOrdersAsync = ref.watch(
      purchaseOrdersProvider(
        PurchaseOrderFilter(page: 1, limit: 100),
      ),
    );

    return ZerpaiLayout(
      pageTitle: 'Purchase Orders',
      actions: [
        ZButton.primary(
          label: 'New Purchase Order',
          onPressed: () => context.push('/purchases/orders/create'),
        ),
      ],
      child: Column(
        children: [
          // Search and filters
          _buildSearchBar(ref),
          const SizedBox(height: AppTheme.space20),
          
          // Data table
          Expanded(
            child: purchaseOrdersAsync.when(
              data: (orders) => _buildOrdersTable(orders),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _buildErrorWidget(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.space8),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppTheme.textSecondary),
          const SizedBox(width: AppTheme.space12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search purchase orders...',
                border: InputBorder.none,
                hintStyle: AppTheme.metaHelper,
              ),
              onChanged: (value) {
                // TODO: Implement search with debouncing
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.textSecondary),
            onPressed: () {
              // TODO: Show filter dialog
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTable(List<PurchaseOrder> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateColor.resolveWith(
          (states) => AppTheme.tableHeaderBg,
        ),
        dataRowMinHeight: 56,
        headingRowHeight: 48,
        columns: const [
          DataColumn(label: Text('Order Number')),
          DataColumn(label: Text('Vendor')),
          DataColumn(label: Text('Order Date')),
          DataColumn(label: Text('Expected Delivery')),
          DataColumn(label: Text('Amount')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: orders.map((order) => _buildOrderRow(order)).toList(),
      ),
    );
  }

  DataRow _buildOrderRow(PurchaseOrder order) {
    return DataRow(
      cells: [
        DataCell(Text(order.orderNumber)),
        DataCell(Text('Vendor Name')), // TODO: Fetch vendor name
        DataCell(Text(
          '${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
        )),
        DataCell(
          Text(
            order.expectedDeliveryDate != null
                ? '${order.expectedDeliveryDate!.day}/${order.expectedDeliveryDate!.month}/${order.expectedDeliveryDate!.year}'
                : '-',
          ),
        ),
        DataCell(Text('₹${order.totalAmount.toStringAsFixed(2)}')),
        DataCell(_buildStatusBadge(order.status)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () {
                  // TODO: Navigate to order detail
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  // TODO: Navigate to edit order
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () {
                  // TODO: Delete order
                },
              ),
            ],
          ),
        ),
      ],
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

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: AppTheme.space4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppTheme.space20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: AppTheme.metaHelper.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
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
              // TODO: Navigate to create order
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.errorRed,
          ),
          const SizedBox(height: AppTheme.space16),
          Text(
            'Failed to load purchase orders',
            style: AppTheme.sectionHeader.copyWith(
              color: AppTheme.errorRed,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Text(
            error,
            style: AppTheme.metaHelper,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppTheme.space24),
          ZButton.primary(
            label: 'Retry',
            onPressed: () {
              // TODO: Retry loading
            },
          ),
        ],
      ),
    );
  }
}
