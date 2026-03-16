import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/modules/sales/controllers/sales_order_controller.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';

class ReportDailySalesScreen extends ConsumerWidget {
  const ReportDailySalesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesInvoicesProvider);

    return ZerpaiLayout(
      pageTitle: 'Daily Sales Report',
      enableBodyScroll: true,
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: salesAsync.when(
            data: (sales) {
              if (sales.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No sales data available for the report.'),
                  ),
                );
              }

              // Filter for current month/year or just show all grouped by day
              // For simplicity, let's group all by date (ignoring time)
              final Map<String, _DailyStats> dailyStats = {};

              for (var sale in sales) {
                final dateKey = DateFormat('yyyy-MM-dd').format(sale.saleDate);
                if (!dailyStats.containsKey(dateKey)) {
                  dailyStats[dateKey] = _DailyStats(date: sale.saleDate);
                }
                final stats = dailyStats[dateKey]!;
                stats.count++;
                stats.totalAmount += sale.total;
              }

              // Sort by date descending
              final sortedKeys = dailyStats.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Daily Sales Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    columnWidths: const {
                      0: FlexColumnWidth(2),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                    },
                    children: [
                      // Header
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade50),
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'DATE',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'INVOICE COUNT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'TOTAL SALES',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Data Rows
                      ...sortedKeys.map((key) {
                        final stats = dailyStats[key]!;
                        return TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                DateFormat('dd MMM yyyy').format(stats.date),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                stats.count.toString(),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                '₹${stats.totalAmount.toStringAsFixed(2)}',
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      // Total Row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade50),
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              sales.length.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              '₹${sales.fold<double>(0, (p, s) => p + s.total).toStringAsFixed(2)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const TableSkeleton(rows: 5, columns: 3),
            error: (err, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Error loading sales data: $err',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyStats {
  final DateTime date;
  int count = 0;
  double totalAmount = 0.0;

  _DailyStats({required this.date});
}
