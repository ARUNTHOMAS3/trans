import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/skeleton.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

import '../controllers/sales_order_controller.dart';
import '../models/sales_order_model.dart';
import '../models/sales_order_item_model.dart';

// ── Per-order detail provider ─────────────────────────────────────────────────

final salesOrderDetailProvider =
    FutureProvider.family<SalesOrder, String>((ref, id) {
  return ref.watch(salesOrderApiServiceProvider).getSalesOrderById(id);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class SalesDocumentDetailScreen extends ConsumerWidget {
  final String id;
  final String documentType;

  /// Deep-link support: open a specific tab on load (e.g. 'overview',
  /// 'comments', 'history'). Ignored if the screen doesn't render tabs.
  final String? initialTab;

  const SalesDocumentDetailScreen({
    super.key,
    required this.id,
    required this.documentType,
    this.initialTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(salesOrderDetailProvider(id));

    return async.when(
      loading: () => ZerpaiLayout(
        pageTitle: '...',
        enableBodyScroll: false,
        child: const DocumentDetailSkeleton(),
      ),
      error: (err, _) => ZerpaiLayout(
        pageTitle: 'Error',
        child: Center(child: Text('Error: $err')),
      ),
      data: (sale) => ZerpaiLayout(
        pageTitle: sale.saleNumber,
        enableBodyScroll: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActionBar(sale: sale, documentType: documentType),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            _StatusBar(sale: sale),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PdfDocument(sale: sale),
                        const SizedBox(height: 20),
                        _MoreInformation(sale: sale),
                        const SizedBox(height: 40),
                      ],
                    ),
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

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final SalesOrder sale;
  final String documentType;

  const _ActionBar({required this.sale, required this.documentType});

  @override
  Widget build(BuildContext context) {
    const btnStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);
    const iconSize = 14.0;
    const gap = SizedBox(width: 6);

    return Container(
      height: 46,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Edit
          OutlinedButton.icon(
            onPressed: () =>
                context.push('/sales/orders/create', extra: sale),
            icon: const Icon(LucideIcons.pencil, size: iconSize),
            label: const Text('Edit', style: btnStyle),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
            ),
          ),
          gap,
          // Send Email
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.mail, size: iconSize),
            label: const Text('Send Email', style: btnStyle),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
            ),
          ),
          gap,
          // PDF/Print
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.printer, size: iconSize),
            label: const Text('PDF/Print', style: btnStyle),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
            ),
          ),
          gap,
          // Convert to Invoice
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(LucideIcons.fileText, size: iconSize),
            label: const Text('Convert to Invoice', style: btnStyle),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              minimumSize: Size.zero,
            ),
          ),
          gap,
          // Create ▾
          MenuAnchor(
            builder: (ctx, ctrl, _) => OutlinedButton.icon(
              onPressed: () =>
                  ctrl.isOpen ? ctrl.close() : ctrl.open(),
              icon: const Icon(LucideIcons.plusCircle, size: iconSize),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('Create', style: btnStyle),
                  SizedBox(width: 3),
                  Icon(LucideIcons.chevronDown, size: 12),
                ],
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF374151),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 7),
                minimumSize: Size.zero,
              ),
            ),
            menuChildren: [
              _actionMenuItem('Invoice',           () {}),
              _actionMenuItem('Package',           () {}),
              _actionMenuItem('Shipment',          () {}),
              _actionMenuItem('Delivery Challan',  () {}),
            ],
          ),
          gap,
          // ... More
          MenuAnchor(
            builder: (ctx, ctrl, _) => IconButton(
              icon: const Icon(LucideIcons.moreHorizontal,
                  size: 16, color: Color(0xFF6B7280)),
              onPressed: () =>
                  ctrl.isOpen ? ctrl.close() : ctrl.open(),
              padding: EdgeInsets.zero,
            ),
            menuChildren: [
              _actionMenuItem('Delete',     () {}, color: const Color(0xFFDC2626)),
              _actionMenuItem('Clone',      () {}),
              _actionMenuItem('Mark as Sent', () {}),
            ],
          ),
          const Spacer(),
          // Back
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(LucideIcons.chevronLeft,
                size: 14, color: Color(0xFF6B7280)),
            label: const Text('Back',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280))),
          ),
        ],
      ),
    );
  }

  MenuItemButton _actionMenuItem(String label, VoidCallback onTap,
      {Color? color}) {
    return MenuItemButton(
      onPressed: onTap,
      child: SizedBox(
        width: 180,
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                color: color ?? const Color(0xFF374151))),
      ),
    );
  }
}

// ── Status bar ─────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  final SalesOrder sale;
  const _StatusBar({required this.sale});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statusItem('Invoice Status', 'NOT INVOICED',
              const Color(0xFFD97706)),
          const SizedBox(width: 2),
          const Text('|',
              style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14)),
          const SizedBox(width: 12),
          _statusItem('Shipment', 'PENDING', const Color(0xFF6B7280)),
          const SizedBox(width: 2),
          const Text('|',
              style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 14)),
          const SizedBox(width: 12),
          _statusItem('Order Status', sale.status.toUpperCase(),
              _statusColor(sale.status)),
        ],
      ),
    );
  }

  Widget _statusItem(String label, String value, Color valueColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label : ',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B7280))),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: valueColor)),
      ],
    );
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':  return const Color(0xFF2563EB);
      case 'paid':
      case 'delivered':  return const Color(0xFF059669);
      case 'cancelled':  return const Color(0xFFDC2626);
      case 'sent':
      case 'shipped':    return const Color(0xFFD97706);
      default:           return const Color(0xFF6B7280);
    }
  }
}

// ── PDF Document card ─────────────────────────────────────────────────────────

class _PdfDocument extends StatelessWidget {
  final SalesOrder sale;
  const _PdfDocument({required this.sale});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##,##0.00', 'en_IN');
    final dateStr = DateFormat('dd-MM-yyyy').format(sale.saleDate);
    final customer = sale.customer;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Document header ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 28, 32, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: org info placeholder
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'YOUR COMPANY NAME',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Address Line 1\nCity, State PIN\nGSTIN: —',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF6B7280),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right: document type + number
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'SALES ORDER',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sales Order# ${sale.saleNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 20),

          // ── Bill To / Ship To / Order Info ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bill To
                Expanded(
                  child: _addressBlock(
                    'Bill To',
                    customer?.displayName ?? '—',
                    _buildAddress([
                      customer?.billingAddressStreet1,
                      customer?.billingAddressStreet2,
                      customer?.billingAddressCity,
                      customer?.billingAddressZip,
                    ]),
                  ),
                ),
                // Ship To
                Expanded(
                  child: _addressBlock(
                    'Ship To',
                    customer?.displayName ?? '—',
                    _buildAddress([
                      customer?.shippingAddressStreet1,
                      customer?.shippingAddressStreet2,
                      customer?.shippingAddressCity,
                      customer?.shippingAddressZip,
                    ]),
                  ),
                ),
                // Order meta
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _metaRow('Order Date', dateStr),
                    if (sale.reference != null && sale.reference!.isNotEmpty)
                      _metaRow('Reference#', sale.reference!),
                    if (sale.expectedShipmentDate != null)
                      _metaRow(
                        'Expected Shipment',
                        DateFormat('dd-MM-yyyy')
                            .format(sale.expectedShipmentDate!),
                      ),
                    if (sale.paymentTerms != null &&
                        sale.paymentTerms!.isNotEmpty)
                      _metaRow('Payment Terms', sale.paymentTerms!),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Items table ───────────────────────────────────────────────────
          _ItemsTable(items: sale.items ?? [], fmt: fmt),

          // ── Totals ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                _TotalsBlock(sale: sale, fmt: fmt),
              ],
            ),
          ),

          // ── Signature ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                        width: 220,
                        child: Divider(color: Color(0xFF374151), thickness: 1)),
                    const SizedBox(height: 4),
                    const Text(
                      'Authorized Signature',
                      style: TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addressBlock(String title, String name, String address) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF6B7280),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2563EB),
          ),
        ),
        if (address.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              address,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF4B5563), height: 1.5),
            ),
          ),
      ],
    );
  }

  String _buildAddress(List<String?> parts) {
    return parts.where((p) => p != null && p.isNotEmpty).join('\n');
  }

  Widget _metaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label : ',
            style: const TextStyle(
                fontSize: 12, color: Color(0xFF6B7280)),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }
}

// ── Items table ───────────────────────────────────────────────────────────────

class _ItemsTable extends StatelessWidget {
  final List<SalesOrderItem> items;
  final NumberFormat fmt;
  const _ItemsTable({required this.items, required this.fmt});

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );
    const cellStyle =
        TextStyle(fontSize: 12.5, color: Color(0xFF111827));
    const divColor = Color(0xFFE5E7EB);

    return Column(
      children: [
        // Header
        Container(
          color: const Color(0xFF374151),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
          child: Row(
            children: [
              const SizedBox(
                  width: 28,
                  child: Text('#', style: headerStyle)),
              const Expanded(
                  flex: 5,
                  child: Text('Item & Description',
                      style: headerStyle)),
              const SizedBox(
                  width: 80,
                  child: Text('Qty',
                      style: headerStyle,
                      textAlign: TextAlign.center)),
              const SizedBox(
                  width: 90,
                  child: Text('Rate',
                      style: headerStyle,
                      textAlign: TextAlign.right)),
              if (items.any((i) => i.discount > 0))
                const SizedBox(
                    width: 90,
                    child: Text('Discount',
                        style: headerStyle,
                        textAlign: TextAlign.right)),
              const SizedBox(
                  width: 100,
                  child: Text('Amount',
                      style: headerStyle,
                      textAlign: TextAlign.right)),
            ],
          ),
        ),
        // Rows
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final hasDiscount = items.any((it) => it.discount > 0);
          final name =
              item.item?.productName ?? item.description ?? 'Item ${i + 1}';
          final desc = item.description != null &&
                  item.description!.isNotEmpty &&
                  item.description != name
              ? item.description
              : null;

          return Container(
            color: i.isOdd
                ? const Color(0xFFFAFAFA)
                : Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 12.5, color: Color(0xFF6B7280))),
                ),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: cellStyle),
                      if (desc != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            desc,
                            style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF6B7280)),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    _fmtQty(item.quantity),
                    style: cellStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 90,
                  child: Text(
                    fmt.format(item.rate),
                    style: cellStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
                if (hasDiscount)
                  SizedBox(
                    width: 90,
                    child: Text(
                      item.discount > 0
                          ? item.discountType == 'value'
                              ? fmt.format(item.discount)
                              : '${item.discount.toStringAsFixed(0)}%'
                          : '—',
                      style: cellStyle,
                      textAlign: TextAlign.right,
                    ),
                  ),
                SizedBox(
                  width: 100,
                  child: Text(
                    fmt.format(item.itemTotal),
                    style: cellStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
        const Divider(height: 1, color: divColor),
      ],
    );
  }

  String _fmtQty(double qty) {
    return qty == qty.truncateToDouble()
        ? qty.toInt().toString()
        : qty.toStringAsFixed(2);
  }
}

// ── Totals block ──────────────────────────────────────────────────────────────

class _TotalsBlock extends StatelessWidget {
  final SalesOrder sale;
  final NumberFormat fmt;
  const _TotalsBlock({required this.sale, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final rows = <_TotalRow>[];

    rows.add(_TotalRow('Sub Total', sale.subTotal));

    if (sale.discountTotal > 0) {
      rows.add(_TotalRow('Discount', -sale.discountTotal));
    }
    if (sale.shippingCharges > 0) {
      rows.add(_TotalRow('Shipping Charges', sale.shippingCharges));
    }
    if (sale.taxTotal > 0) {
      rows.add(_TotalRow('Tax Total', sale.taxTotal));
    }
    if (sale.adjustment != 0) {
      rows.add(_TotalRow('Adjustment', sale.adjustment));
    }

    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          ...rows.map((r) => _totalLine(r.label, r.amount, fmt)),
          const Divider(height: 20, color: Color(0xFFE5E7EB)),
          // Total row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                Text(
                  '₹${fmt.format(sale.total)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _totalLine(String label, double amount, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 12.5, color: Color(0xFF4B5563)),
            ),
          ),
          Text(
            fmt.format(amount.abs()),
            style: TextStyle(
              fontSize: 12.5,
              color: amount < 0
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow {
  final String label;
  final double amount;
  const _TotalRow(this.label, this.amount);
}

// ── More Information ──────────────────────────────────────────────────────────

class _MoreInformation extends StatelessWidget {
  final SalesOrder sale;
  const _MoreInformation({required this.sale});

  @override
  Widget build(BuildContext context) {
    final fields = <_InfoField>[
      if (sale.salesperson != null && sale.salesperson!.isNotEmpty)
        _InfoField('Salesperson', sale.salesperson!),
      if (sale.paymentTerms != null && sale.paymentTerms!.isNotEmpty)
        _InfoField('Payment Terms', sale.paymentTerms!),
      if (sale.deliveryMethod != null && sale.deliveryMethod!.isNotEmpty)
        _InfoField('Delivery Method', sale.deliveryMethod!),
      if (sale.reference != null && sale.reference!.isNotEmpty)
        _InfoField('Reference#', sale.reference!),
    ];

    final hasNotes = sale.customerNotes != null &&
        sale.customerNotes!.isNotEmpty;
    final hasTerms = sale.termsAndConditions != null &&
        sale.termsAndConditions!.isNotEmpty;

    if (fields.isEmpty && !hasNotes && !hasTerms) return const SizedBox();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'More Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          if (fields.isNotEmpty)
            Wrap(
              spacing: 40,
              runSpacing: 12,
              children: fields
                  .map((f) => _infoField(f.label, f.value))
                  .toList(),
            ),
          if (hasNotes) ...[
            const SizedBox(height: 16),
            const Text('Customer Notes',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(sale.customerNotes!,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF374151))),
          ],
          if (hasTerms) ...[
            const SizedBox(height: 16),
            const Text('Terms & Conditions',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    letterSpacing: 0.4)),
            const SizedBox(height: 4),
            Text(sale.termsAndConditions!,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF374151))),
          ],
        ],
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }
}

class _InfoField {
  final String label;
  final String value;
  const _InfoField(this.label, this.value);
}
