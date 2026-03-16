import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/zerpai_layout.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/routing/app_routes.dart';

class ReportsDashboardScreen extends StatelessWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: 'Reports',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 32),
          Text(
            'All Reports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          _buildReportsGrid(context),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _summaryCard(
          'Total Sales',
          'rs 1,24,500',
          Icons.trending_up,
          Color(0xFF10B981),
        ),
        const SizedBox(width: 16),
        _summaryCard(
          'Total Customers',
          '1,240',
          Icons.people_outline,
          Color(0xFF2563EB),
        ),
        const SizedBox(width: 16),
        _summaryCard(
          'Pending Invoices',
          '14',
          Icons.description_outlined,
          Color(0xFFF59E0B),
        ),
        const SizedBox(width: 16),
        _summaryCard(
          'Escaped Profits',
          'rs 8,400',
          Icons.money_off,
          Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsGrid(BuildContext context) {
    final reportCategories = [
      {
        'title': 'Sales',
        'items': [
          'Daily Sales',
          'Sales by Customer',
          'Sales by Item',
          'Sales by Sales Person',
          'Sales Returns',
        ],
        'icon': Icons.point_of_sale,
      },
      {
        'title': 'Inventory',
        'items': [
          'Stock Summary',
          'Inventory Valuation',
          'ABC Analysis',
          'Warehouse Stock',
        ],
        'icon': Icons.inventory_2,
      },
      {
        'title': 'Receivables',
        'items': ['Customer Balances', 'Aging Summary', 'Invoice Details'],
        'icon': Icons.account_balance_wallet,
      },
      {
        'title': 'Tax',
        'items': ['GST Summary', 'Tax Liability Report'],
        'icon': Icons.receipt_long,
      },
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: reportCategories
          .map((cat) => _categoryCard(context, cat))
          .toList(),
    );
  }

  Widget _categoryCard(BuildContext context, Map<String, dynamic> cat) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                cat['icon'] as IconData,
                color: const Color(0xFF4B5563),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                cat['title'] as String,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...(cat['items'] as List<String>).map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: InkWell(
                onTap: () {
                  if (item == 'Daily Sales') {
                    context.push(AppRoutes.reportDailySales);
                  }
                },
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
