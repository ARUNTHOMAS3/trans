import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/retainer_invoices_model.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class RetainerInvoicesState {
  final List<RetainerInvoice> invoices;
  final bool isLoading;
  final RetainerStatus? activeFilter; // null = show all
  final String searchQuery;

  const RetainerInvoicesState({
    required this.invoices,
    this.isLoading = false,
    this.activeFilter,
    this.searchQuery = '',
  });

  List<RetainerInvoice> get filteredInvoices {
    var list = invoices;

    if (activeFilter != null) {
      list = list.where((inv) => inv.status == activeFilter).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      list = list.where((inv) {
        return inv.invoiceNo.toLowerCase().contains(q) ||
            inv.customerName.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  // ── Summary aggregates ────────────────────────────────────────────────────

  int get totalCount => invoices.length;

  int get pendingCount => invoices
      .where(
        (i) =>
            i.status == RetainerStatus.draft || i.status == RetainerStatus.sent,
      )
      .length;

  double get totalCollected => invoices
      .where(
        (i) =>
            i.status == RetainerStatus.paid ||
            i.status == RetainerStatus.partiallyPaid ||
            i.status == RetainerStatus.closed,
      )
      .fold(0.0, (sum, i) => sum + i.totalAmount);

  double get totalApplied => invoices.fold(0.0, (sum, i) => sum + i.amountUsed);

  RetainerInvoicesState copyWith({
    List<RetainerInvoice>? invoices,
    bool? isLoading,
    RetainerStatus? activeFilter,
    bool clearFilter = false,
    String? searchQuery,
  }) {
    return RetainerInvoicesState(
      invoices: invoices ?? this.invoices,
      isLoading: isLoading ?? this.isLoading,
      activeFilter: clearFilter ? null : (activeFilter ?? this.activeFilter),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class RetainerInvoicesNotifier extends StateNotifier<RetainerInvoicesState> {
  RetainerInvoicesNotifier()
    : super(RetainerInvoicesState(invoices: _seedData()));

  // ── CRUD ──────────────────────────────────────────────────────────────────

  void loadInvoices() {
    // Refresh / reload invoices from DB or seed
  }

  void addInvoice(RetainerInvoice invoice) {
    state = state.copyWith(invoices: [invoice, ...state.invoices]);
  }

  void updateInvoice(RetainerInvoice updated) {
    state = state.copyWith(
      invoices: state.invoices
          .map((i) => i.id == updated.id ? updated : i)
          .toList(),
    );
  }

  void deleteInvoice(String id) {
    state = state.copyWith(
      invoices: state.invoices.where((i) => i.id != id).toList(),
    );
  }

  // ── Status actions ────────────────────────────────────────────────────────

  void markAsSent(String id) => _updateStatus(id, RetainerStatus.sent);
  void markAsPaid(String id) => _updateStatus(id, RetainerStatus.paid);
  void voidInvoice(String id) => _updateStatus(id, RetainerStatus.voided);

  void _updateStatus(String id, RetainerStatus status) {
    state = state.copyWith(
      invoices: state.invoices.map((i) {
        if (i.id == id) return i.copyWith(status: status);
        return i;
      }).toList(),
    );
  }

  /// Legacy string-based update for compatibility.
  void updateInvoiceStatus(String id, String newStatus) {
    _updateStatus(id, RetainerStatus.fromLabel(newStatus));
  }

  // ── Clone ──────────────────────────────────────────────────────────────────

  RetainerInvoice cloneInvoice(String id, String newId, String newInvoiceNo) {
    final original = state.invoices.firstWhere((i) => i.id == id);
    final clone = original.copyWith(
      id: newId,
      invoiceNo: newInvoiceNo,
      date: DateTime.now(),
      status: RetainerStatus.draft,
      amountUsed: 0.0,
      applications: [],
    );
    addInvoice(clone);
    return clone;
  }

  // ── Filter / Search ───────────────────────────────────────────────────────

  void setFilter(RetainerStatus? filter) {
    if (filter == null) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(activeFilter: filter);
    }
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  // ── Next invoice number ───────────────────────────────────────────────────

  String nextInvoiceNo() {
    final count = state.invoices.length + 1;
    return 'RET-2026-${count.toString().padLeft(5, '0')}';
  }
}

// ─── Seeded demo data ─────────────────────────────────────────────────────────

List<RetainerInvoice> _seedData() => [
  RetainerInvoice.create(
    id: '1',
    invoiceNo: 'RET-2026-00001',
    date: DateTime.now().subtract(const Duration(days: 20)),
    expiryDate: DateTime.now().subtract(const Duration(days: 5)),
    customerId: 'cust-1',
    customerName: 'Acme Corporation',
    customerEmail: 'billing@acme.com',
    amount: 15000.00,
    taxLabel: 'GST 18%',
    taxRate: 0.18,
    amountUsed: 15000.00 * 1.18,
    paymentMode: 'Bank Transfer',
    referenceNo: 'TXN-4492211',
    status: RetainerStatus.paid,
    notes: 'Advance retainer for project consultation and design setup.',
    termsAndConditions:
        'Payment is non-refundable once services have commenced.',
    applications: [
      RetainerPaymentApplication(
        salesInvoiceNo: 'INV-2026-00012',
        amountApplied: 15000.00 * 1.18,
        appliedOn: DateTime.now().subtract(const Duration(days: 3)),
      ),
    ],
  ),
  RetainerInvoice.create(
    id: '2',
    invoiceNo: 'RET-2026-00002',
    date: DateTime.now().subtract(const Duration(days: 12)),
    customerId: 'cust-2',
    customerName: 'Wayne Enterprises',
    customerEmail: 'accounts@wayne.com',
    amount: 45000.00,
    taxLabel: 'GST 18%',
    taxRate: 0.18,
    amountUsed: 20000.00,
    paymentMode: 'Cheque',
    referenceNo: 'CHQ-009832',
    status: RetainerStatus.partiallyPaid,
    notes: 'Retainer deposit for high-grade equipment manufacturing services.',
    termsAndConditions: 'Balance to be settled within 30 days of invoice.',
  ),
  RetainerInvoice.create(
    id: '3',
    invoiceNo: 'RET-2026-00003',
    date: DateTime.now().subtract(const Duration(days: 5)),
    customerId: 'cust-3',
    customerName: 'Stark Industries',
    customerEmail: 'finance@stark.com',
    amount: 120000.00,
    taxLabel: 'GST 12%',
    taxRate: 0.12,
    amountUsed: 0.0,
    paymentMode: 'Bank Transfer',
    status: RetainerStatus.draft,
    notes: 'Retainer request for raw material supply line allocation.',
    termsAndConditions: 'Subject to board approval.',
  ),
  RetainerInvoice.create(
    id: '4',
    invoiceNo: 'RET-2026-00004',
    date: DateTime.now().subtract(const Duration(days: 2)),
    expiryDate: DateTime.now().add(const Duration(days: 28)),
    customerId: 'cust-4',
    customerName: 'Oscorp Industries',
    customerEmail: 'ap@oscorp.com',
    amount: 35000.00,
    taxLabel: 'GST 18%',
    taxRate: 0.18,
    amountUsed: 0.0,
    paymentMode: 'UPI',
    referenceNo: 'UPI-TXN-8823',
    status: RetainerStatus.sent,
    notes: 'Advance retainer for biochemical research and consultation.',
  ),
  RetainerInvoice.create(
    id: '5',
    invoiceNo: 'RET-2026-00005',
    date: DateTime.now().subtract(const Duration(days: 45)),
    customerId: 'cust-5',
    customerName: 'LexCorp',
    customerEmail: 'billing@lexcorp.com',
    amount: 80000.00,
    taxLabel: 'None',
    taxRate: 0.0,
    amountUsed: 0.0,
    paymentMode: 'Cash',
    status: RetainerStatus.voided,
    notes: 'Cancelled project retainer.',
  ),
];

// ─── Provider ─────────────────────────────────────────────────────────────────

final retainerInvoicesProvider =
    StateNotifierProvider<RetainerInvoicesNotifier, RetainerInvoicesState>((
      ref,
    ) {
      return RetainerInvoicesNotifier();
    });
