import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import '../controllers/sales_order_controller.dart';
import '../../../shared/widgets/zerpai_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

class SalesOrderOverviewScreen extends ConsumerWidget {
  const SalesOrderOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesOrderControllerProvider);

    return ZerpaiLayout(
      pageTitle: 'Sales Orders',

      enableBodyScroll: false,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.salesOrdersCreate),
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text(
          'New Sales Order',
          style: TextStyle(color: Colors.white),
        ),
      ),
      child: salesAsync.when(
        data: (sales) => sales.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.receipt,
                      size: 64,
                      color: Color(0xFFD1D5DB),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No sales orders found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a sales order to start selling',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => context.go(AppRoutes.salesOrdersCreate),
                      icon: const Icon(LucideIcons.plus),
                      label: const Text('Create Sales Order'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: sales.length,
                itemBuilder: (context, index) {
                  final sale = sales[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    child: ListTile(
                      title: Text(
                        sale.saleNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      subtitle: Text(
                        '${sale.customer?.displayName ?? "Unknown Customer"} • ${DateFormat('MMM dd, yyyy').format(sale.saleDate)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${sale.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                sale.status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              sale.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(sale.status),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        context.go(
                          AppRoutes.salesOrdersDetail.replaceAll(
                            ':id',
                            sale.id,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        loading: () => const ListSkeleton(),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.grey;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'paid':
        return Colors.teal;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.black;
    }
  }
}
