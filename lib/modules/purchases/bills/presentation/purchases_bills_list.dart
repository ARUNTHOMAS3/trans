import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:zerpai_erp/core/routing/app_routes.dart';
import 'package:zerpai_erp/modules/purchases/bills/models/purchases_bills_bill_model.dart';
import 'package:zerpai_erp/modules/purchases/bills/providers/purchases_bills_provider.dart';
import 'package:zerpai_erp/shared/widgets/zerpai_layout.dart';

class PurchasesBillsListScreen extends ConsumerStatefulWidget {
  const PurchasesBillsListScreen({super.key});

  @override
  ConsumerState<PurchasesBillsListScreen> createState() =>
      _PurchasesBillsListScreenState();
}

class _PurchasesBillsListScreenState
    extends ConsumerState<PurchasesBillsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final ScrollController _verticalScrollCtrl = ScrollController();
  String _selectedFilter = 'All';

  final List<String> _filterOptions = [
    'All',
    'Draft',
    'Open',
    'Overdue',
    'Paid',
    'Void',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(billsProvider.notifier).loadBills());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _verticalScrollCtrl.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    ref.read(billsProvider.notifier).loadBills(search: query);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(billsProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.slash): () {
          _searchFocus.requestFocus();
        },
      },
      child: ZerpaiLayout(
        pageTitle: 'Bills',
        enableBodyScroll: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBanner(state),
            _buildFilterBar(state),
            Expanded(child: _buildContent(state)),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────── TOP BANNER ───────────────────────

  Widget _buildTopBanner(BillsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          _buildViewSelector(),
          const Spacer(),
          // Summary chips
          _buildSummaryChip(
            'OUTSTANDING PAYABLES',
            state.bills
                .where((b) => b.status == 'open' || b.status == 'overdue')
                .fold(0.0, (sum, b) => sum + b.total),
          ),
          const SizedBox(width: 12),
          _buildSummaryChip(
            'OVERDUE BILLS',
            state.bills
                .where((b) => b.status == 'overdue')
                .fold(0.0, (sum, b) => sum + b.total),
          ),
          const SizedBox(width: 16),
          _buildNewButton(),
          const SizedBox(width: 8),
          _buildMoreActionsButton(),
        ],
      ),
    );
  }

  Widget _buildViewSelector() {
    return PopupMenuButton<String>(
      onSelected: (val) {
        setState(() => _selectedFilter = val);
        ref
            .read(billsProvider.notifier)
            .loadBills(status: val == 'All' ? null : val.toLowerCase());
      },
      itemBuilder: (_) => _filterOptions
          .map((f) => PopupMenuItem(value: f, child: Text(f)))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_selectedFilter Bills',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: Color(0xFF2563EB),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryChip(String label, double amount) {
    final fmt = NumberFormat('#,##0.00', 'en_IN');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
          ),
          Text(
            '₹ ${fmt.format(amount)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewButton() {
    return ElevatedButton.icon(
      onPressed: () => context.push(AppRoutes.billsCreate),
      icon: const Icon(Icons.add, size: 18, color: Colors.white),
      label: const Text(
        'New',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF10B981),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        elevation: 0,
      ),
    );
  }

  Widget _buildMoreActionsButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD1D5DB)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_horiz, size: 18, color: Color(0xFF374151)),
        padding: EdgeInsets.zero,
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'import', child: Text('Import')),
          PopupMenuItem(value: 'export', child: Text('Export')),
          PopupMenuItem(value: 'refresh', child: Text('Refresh List')),
        ],
      ),
    );
  }

  // ─────────────────────────────────────── FILTER BAR ───────────────────────

  Widget _buildFilterBar(BillsState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, size: 18, color: Color(0xFF6B7280)),
          const SizedBox(width: 12),
          SizedBox(
            width: 320,
            height: 32,
            child: TextField(
              controller: _searchCtrl,
              focusNode: _searchFocus,
              onChanged: _handleSearch,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search in Bills ( / )',
                prefixIcon: const Icon(Icons.search, size: 16),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(
                    color: Color(0xFF2563EB),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          if (state.isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────── CONTENT ──────────────────────────

  Widget _buildContent(BillsState state) {
    if (state.isLoading && state.bills.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return _buildErrorState(state.error!);
    }
    if (state.bills.isEmpty) {
      return _buildEmptyState();
    }
    return _buildTable(state.bills);
  }

  Widget _buildTable(List<PurchasesBill> bills) {
    final fmt = NumberFormat('#,##0.00', 'en_IN');
    final dateFmt = DateFormat('dd MMM yyyy');

    return LayoutBuilder(
      builder: (ctx, constraints) => Scrollbar(
        controller: _verticalScrollCtrl,
        child: SingleChildScrollView(
          controller: _verticalScrollCtrl,
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowHeight: 40,
                dataRowMaxHeight: 56,
                dataRowMinHeight: 48,
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF9FAFB),
                ),
                checkboxHorizontalMargin: 16,
                headingTextStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
                dataTextStyle: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF374151),
                ),
                columns: const [
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('BILL#')),
                  DataColumn(label: Text('VENDOR NAME')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('DUE DATE')),
                  DataColumn(label: Text('AMOUNT')),
                  DataColumn(label: Text('BALANCE DUE')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: bills.map((bill) {
                  return DataRow(
                    cells: [
                      DataCell(
                        Text(
                          bill.billDate != null
                              ? dateFmt.format(bill.billDate!)
                              : '-',
                        ),
                      ),
                      DataCell(
                        Text(
                          bill.billNumber ?? '-',
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      DataCell(Text(bill.vendorName)),
                      DataCell(_buildStatusBadge(bill.status)),
                      DataCell(
                        Text(
                          bill.dueDate != null
                              ? dateFmt.format(bill.dueDate!)
                              : '-',
                        ),
                      ),
                      DataCell(Text('₹ ${fmt.format(bill.total)}')),
                      DataCell(
                        Text(
                          '₹ ${fmt.format(bill.total)}',
                          style: TextStyle(
                            color: bill.status == 'overdue' ? Colors.red : null,
                          ),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 16,
                                color: Color(0xFF6B7280),
                              ),
                              onPressed: () {},
                              tooltip: 'Edit',
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  _showDeleteConfirmation(context, bill),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg, fg;
    switch (status.toLowerCase()) {
      case 'open':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF16A34A);
        break;
      case 'overdue':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        break;
      case 'paid':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        break;
      case 'void':
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF9CA3AF);
        break;
      default: // draft
        bg = const Color(0xFFFEF9C3);
        fg = const Color(0xFFCA8A04);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.read(billsProvider.notifier).loadBills(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Bills yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first bill to start managing payables.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.billsCreate),
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text(
              'New Bill',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PurchasesBill bill) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Bill'),
        content: Text(
          'Are you sure you want to delete Bill# ${bill.billNumber ?? ''}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(billsProvider.notifier).deleteBill(bill.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
