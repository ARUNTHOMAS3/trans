import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:intl/intl.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';
import '../models/sales_order_model.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import '../controllers/sales_order_controller.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';

class SalesDocumentDetailScreen extends ConsumerWidget {
  final String id;
  final String documentType;

  const SalesDocumentDetailScreen({
    super.key,
    required this.id,
    required this.documentType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We could use a specific detail provider, but for now we'll fetch via API service
    final future = ref
        .watch(salesOrderApiServiceProvider)
        .getSalesOrderById(id);

    return ZerpaiLayout(
      pageTitle: '${_capitalize(documentType)} Details',

      child: FutureBuilder<SalesOrder>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const DocumentDetailSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final sale = snapshot.data!;
          return _buildDetailBody(context, sale);
        },
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return '';
    return s
        .split('_')
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Widget _buildDetailBody(BuildContext context, SalesOrder sale) {
    return Column(
      children: [
        _buildActionHeader(sale),
        const SizedBox(height: 24),
        _buildMainDetails(sale),
        const SizedBox(height: 24),
        _buildItemsTable(sale),
        const SizedBox(height: 24),
        _buildSummary(sale),
      ],
    );
  }

  Widget _buildActionHeader(SalesOrder sale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.edit2, size: 16),
          label: const Text('Edit'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(LucideIcons.printer, size: 16),
          label: const Text('Print'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(onPressed: () {}, child: const Text('Send Email')),
      ],
    );
  }

  Widget _buildMainDetails(SalesOrder sale) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoLabel('CUSTOMER NAME'),
                  Text(
                    sale.customer?.displayName ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoLabel('BILLING ADDRESS'),
                  Text(
                    sale.customer?.fullBillingAddress ?? 'N/A',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoLabel('${documentType.toUpperCase()} DATE'),
                  Text(
                    DateFormat('dd MMM yyyy').format(sale.saleDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _infoLabel('REFERENCE#'),
                  Text(
                    sale.reference ?? 'N/A',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoLabel('${documentType.toUpperCase()}#'),
                  Text(
                    sale.saleNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlueDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _infoLabel('STATUS'),
                  _statusBadge(sale.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: AppTheme.textSecondary,
      ),
    ),
  );

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: const TextStyle(
          color: Colors.green,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildItemsTable(SalesOrder sale) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.borderColor),
      ),
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(AppTheme.bgLight),
        columns: const [
          DataColumn(
            label: Text(
              'ITEM DETAILS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'QUANTITY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'RATE',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'AMOUNT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows:
            sale.items
                ?.map(
                  (item) => DataRow(
                    cells: [
                      DataCell(Text(item.description ?? 'Product')),
                      DataCell(Text(item.quantity.toString())),
                      DataCell(
                        Text(
                          NumberFormat.currency(symbol: 'rs').format(item.rate),
                        ),
                      ),
                      DataCell(
                        Text(
                          NumberFormat.currency(
                            symbol: 'rs',
                          ).format(item.itemTotal),
                        ),
                      ),
                    ],
                  ),
                )
                .toList() ??
            [],
      ),
    );
  }

  Widget _buildSummary(SalesOrder sale) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _summaryRow('Sub Total', sale.subTotal),
            const SizedBox(height: 8),
            _summaryRow('Tax Total', sale.taxTotal),
            const Divider(height: 24),
            _summaryRow('Total', sale.total, isBold: true),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          NumberFormat.currency(symbol: 'rs').format(amount),
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
