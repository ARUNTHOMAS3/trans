import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import '../providers/dashboard_provider.dart';
import '../../../../shared/widgets/skeleton.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardProvider);
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    if (state.error != null) {
      return ZerpaiLayout(
        pageTitle: 'Business Overview',
        child: Center(
          child: Text(
            'Error: ${state.error}',
            style: TextStyle(color: AppTheme.textPrimary),
          ),
        ),
      );
    }

    return ZerpaiLayout(
      pageTitle: 'Business Overview',
      child: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).fetchSummary(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // KPI Row
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      title: 'Total Receivables',
                      value: currencyFormat.format(state.receivables),
                      icon: LucideIcons.arrowUpRight,
                      color: const Color(0xFF2563EB),
                      isLoading: state.isLoading,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: _KpiCard(
                      title: 'Total Payables',
                      value: currencyFormat.format(state.payables),
                      icon: LucideIcons.arrowDownLeft,
                      color: const Color(0xFFDC2626),
                      isLoading: state.isLoading,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: _KpiCard(
                      title: 'Cash on Hand',
                      value: currencyFormat.format(state.cashOnHand),
                      icon: LucideIcons.wallet,
                      color: const Color(0xFF16A34A),
                      isLoading: state.isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space24),

              // Charts Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: _ChartCard(
                      title: 'Sales Trend (Last 30 Days)',
                      child: _SalesLineChart(
                        data: state.salesTrend,
                        isLoading: state.isLoading,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(flex: 1, child: _QuickActionsCard()),
                ],
              ),
              const SizedBox(height: AppTheme.space24),

              // Bottom Row (Placeholder for now)
              Row(
                children: [
                  Expanded(
                    child: _InfoCard(
                      title: 'Top Customers',
                      child: _TopMetricList(
                        rows: state.topCustomers,
                        emptyMessage: 'No customer sales data available',
                        valueKey: 'amount',
                        valueLabelBuilder: (value) => currencyFormat.format(value),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.space16),
                  Expanded(
                    child: _InfoCard(
                      title: 'Top Inventory Items',
                      child: _TopMetricList(
                        rows: state.topItems,
                        emptyMessage: 'No inventory movement data available',
                        valueKey: 'stockOnHand',
                        valueLabelBuilder: (value) => '${value.toStringAsFixed(0)} units',
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
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.space12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.space12),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space12),
            if (isLoading)
              const Skeleton(height: 28, width: 140)
            else
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.space12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space24),
            SizedBox(height: 300, child: child),
          ],
        ),
      ),
    );
  }
}

class _SalesLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final bool isLoading;

  const _SalesLineChart({required this.data, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data.isEmpty) {
      return const Center(
        child: Text(
          'No data for the selected period',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    // Convert data to FlSpots
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value['amount'] as num).toDouble(),
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFFE5E7EB), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 5,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) return const SizedBox();
                final date = DateTime.parse(data[index]['date']);
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    DateFormat('dd').format(date),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    NumberFormat.compact().format(value),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF2563EB),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2563EB).withAlpha(20),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.space12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            _ActionButton(
              label: 'Create Invoice',
              icon: LucideIcons.filePlus,
              color: const Color(0xFF2563EB),
              onTap: () => context.go(AppRoutes.salesInvoicesCreate),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Add Customer',
              icon: LucideIcons.userPlus,
              color: const Color(0xFF16A34A),
              onTap: () => context.go(AppRoutes.salesCustomersCreate),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'Log Expense',
              icon: LucideIcons.receipt,
              color: const Color(0xFFDC2626),
              onTap: () => context.go(AppRoutes.expensesCreate),
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'New Purchase Order',
              icon: LucideIcons.shoppingBag,
              color: const Color(0xFF9333EA),
              onTap: () => context.go(AppRoutes.purchaseOrdersCreate),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isCompact = constraints.maxWidth < 176;
            if (isCompact) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              );
            }

            return Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.space12),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: AppTheme.space16),
            SizedBox(height: 120, child: child),
          ],
        ),
      ),
    );
  }
}

class _TopMetricList extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final String emptyMessage;
  final String valueKey;
  final String Function(double value) valueLabelBuilder;

  const _TopMetricList({
    required this.rows,
    required this.emptyMessage,
    required this.valueKey,
    required this.valueLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final visibleRows = rows.take(5).toList();
    return Column(
      children: visibleRows.asMap().entries.map((entry) {
        final row = entry.value;
        final value = (row[valueKey] as num?)?.toDouble() ?? 0;
        return Container(
          padding: EdgeInsets.only(
            top: entry.key == 0 ? 0 : 12,
            bottom: 12,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: entry.key == visibleRows.length - 1
                    ? Colors.transparent
                    : AppTheme.borderColor,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  (row['name'] ?? 'Unknown').toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                valueLabelBuilder(value),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
