import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:zerpai_erp/app/routing/app_router.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class SalesReturnsOverviewPage extends ConsumerStatefulWidget {
  const SalesReturnsOverviewPage({super.key});

  @override
  ConsumerState<SalesReturnsOverviewPage> createState() =>
      _SalesReturnsOverviewPageState();
}

class _SalesReturnsOverviewPageState
    extends ConsumerState<SalesReturnsOverviewPage> {
  bool _isLoading = true;
  String? _error;
  List<_SalesReturnRow> _rows = const [];

  List<dynamic> _extractSalesReturnsRows(dynamic payload) {
    if (payload is List) return payload;
    if (payload is! Map) return const [];

    final directData = payload['data'];
    if (directData is List) return directData;

    if (directData is Map) {
      final nestedData = directData['data'];
      if (nestedData is List) return nestedData;
      if (nestedData is Map<String, dynamic>) return [nestedData];
    }

    if (payload['id'] != null || payload['rma_number'] != null) {
      return [payload];
    }

    return const [];
  }

  @override
  void initState() {
    super.initState();
    _loadRows();
  }

  Future<void> _loadRows() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .get(
            'sales/returns',
            queryParameters: const {'page': 1, 'limit': 200},
          );
      final rawData = _extractSalesReturnsRows(response.data);
      final rows = rawData
          .whereType<Map<String, dynamic>>()
          .map(_SalesReturnRow.fromJson)
          .toList();
      if (!mounted) return;
      setState(() => _rows = rows);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Failed to load sales returns');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ZerpaiLayout(
      pageTitle: '',
      enableBodyScroll: false,
      useTopPadding: false,
      useHorizontalPadding: false,
      child: Container(
        color: AppTheme.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SalesReturnsToolbar(onRefresh: _loadRows),
            const Divider(height: 1, color: AppTheme.borderLight),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: SizedBox(
                    width: 1400,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _SalesReturnsTableHeader(),
                        const Divider(height: 1, color: AppTheme.borderLight),
                        Expanded(child: _buildBody()),
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

  Widget _buildBody() {
    if (_isLoading) {
      return Skeletonizer(
        enabled: true,
        child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: 8,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: AppTheme.borderLight),
          itemBuilder: (context, index) => _SalesReturnsTableRow(
            row: _SalesReturnRow.skeleton(),
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: const TextStyle(fontSize: 13, color: AppTheme.errorRed),
        ),
      );
    }
    if (_rows.isEmpty) {
      return const Center(
        child: Text(
          'No sales returns found',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: _rows.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: AppTheme.borderLight),
      itemBuilder: (context, index) => _SalesReturnsTableRow(row: _rows[index]),
    );
  }
}

class _SalesReturnsToolbar extends StatelessWidget {
  const _SalesReturnsToolbar({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          InkWell(
            onTap: () {},
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'All Sales Returns',
                  style: AppTheme.pageTitle.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 18,
                  color: AppTheme.primaryBlueDark,
                ),
              ],
            ),
          ),
          const Spacer(),
          ZButton.primary(
            label: 'New',
            icon: LucideIcons.plus,
            onPressed: () => context.go(AppRoutes.salesReturnsCreate),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              onPressed: onRefresh,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesReturnsTableHeader extends StatelessWidget {
  const _SalesReturnsTableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppTheme.bgLight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        children: [
          SizedBox(
            width: 48,
            child: Icon(
              LucideIcons.slidersHorizontal,
              size: 16,
              color: AppTheme.primaryBlue,
            ),
          ),
          _HeaderCell(width: 140, label: 'DATE'),
          _HeaderCell(width: 140, label: 'RMA#'),
          _HeaderCell(width: 160, label: 'SALES ORDER#'),
          _HeaderCell(width: 180, label: 'CUSTOMER NAME'),
          _HeaderCell(width: 140, label: 'STATUS'),
          _HeaderCell(width: 140, label: 'RECEIVE STATUS'),
          _HeaderCell(width: 140, label: 'REFUND STATUS'),
          _HeaderCell(width: 120, label: 'RETURNED'),
          _HeaderCell(width: 120, label: 'AMOUNT REFUNDED'),
        ],
      ),
    );
  }
}

class _SalesReturnsTableRow extends StatelessWidget {
  const _SalesReturnsTableRow({required this.row});

  final _SalesReturnRow row;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: null,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SizedBox(width: 48),
            _BodyCell(width: 140, child: _BodyText(row.date)),
            _BodyCell(
              width: 140,
              child: _BodyText(
                row.rmaNumber,
                color: AppTheme.primaryBlueDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            _BodyCell(width: 160, child: _BodyText(row.salesOrderNumber)),
            _BodyCell(width: 180, child: _BodyText(row.customerName)),
            _BodyCell(
              width: 140,
              child: _BodyText(
                row.status,
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
            _BodyCell(width: 140, child: _BodyText(row.receiveStatus)),
            _BodyCell(width: 140, child: _BodyText(row.refundStatus)),
            _BodyCell(width: 120, child: _BodyText(row.returned)),
            _BodyCell(width: 120, child: _BodyText(row.amountRefunded)),
          ],
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({required this.width, required this.label});

  final double width;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(
    this.text, {
    this.color = AppTheme.textPrimary,
    this.fontWeight = FontWeight.w400,
  });

  final String text;
  final Color color;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13, fontWeight: fontWeight, color: color),
    );
  }
}

class _SalesReturnRow {
  const _SalesReturnRow({
    required this.id,
    required this.date,
    required this.rmaNumber,
    required this.salesOrderNumber,
    required this.customerName,
    required this.status,
    required this.receiveStatus,
    required this.refundStatus,
    required this.returned,
    required this.amountRefunded,
  });

  factory _SalesReturnRow.fromJson(Map<String, dynamic> json) {
    final customer = (json['customer'] as Map<String, dynamic>?) ?? const {};
    final displayName = (customer['display_name'] ?? '').toString().trim();
    final firstName = (customer['first_name'] ?? '').toString().trim();
    final lastName = (customer['last_name'] ?? '').toString().trim();
    final companyName = (customer['company_name'] ?? '').toString().trim();
    final customerName = displayName.isNotEmpty
        ? displayName
        : companyName.isNotEmpty
        ? companyName
        : '$firstName $lastName'.trim();

    final returnDateRaw = (json['return_date'] ?? '').toString();
    DateTime? returnDate;
    if (returnDateRaw.isNotEmpty) {
      returnDate = DateTime.tryParse(returnDateRaw);
    }
    final date = returnDate != null
        ? DateFormat('dd-MM-yyyy').format(returnDate)
        : '-';

    final status = (json['status'] ?? '-').toString().toUpperCase();
    final items = (json['items'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
    double returnedTotal = 0;
    for (final row in items) {
      final returnQty = (row['return_qty'] as num?)?.toDouble() ?? 0;
      final receivableQty = (row['receivable_qty'] as num?)?.toDouble() ?? 0;
      final creditOnlyQty = (row['credit_only_qty'] as num?)?.toDouble() ?? 0;
      returnedTotal += returnQty > 0
          ? returnQty
          : (receivableQty + creditOnlyQty);
    }

    return _SalesReturnRow(
      id: (json['id'] ?? '').toString(),
      date: date,
      rmaNumber: (json['rma_number'] ?? '-').toString(),
      salesOrderNumber: (json['reference_number'] ?? '-').toString(),
      customerName: customerName.isEmpty ? '-' : customerName,
      status: status,
      receiveStatus: status == 'APPROVED' ? 'RECEIVED' : '-',
      refundStatus: '-',
      returned: returnedTotal.toStringAsFixed(2),
      amountRefunded: '-',
    );
  }

  factory _SalesReturnRow.skeleton() {
    return const _SalesReturnRow(
      id: 'skeleton',
      date: '15-05-2026',
      rmaNumber: 'RMA-00000',
      salesOrderNumber: 'SO-00000',
      customerName: 'Customer Name',
      status: 'DRAFT',
      receiveStatus: 'RECEIVED',
      refundStatus: '-',
      returned: '0.00',
      amountRefunded: '0.00',
    );
  }

  final String date;
  final String id;
  final String rmaNumber;
  final String salesOrderNumber;
  final String customerName;
  final String status;
  final String receiveStatus;
  final String refundStatus;
  final String returned;
  final String amountRefunded;
}
