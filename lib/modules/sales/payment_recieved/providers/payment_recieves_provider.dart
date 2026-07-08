import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/widgets/inputs/favorite_filter_dropdown.dart';
import '../models/payment_record.dart';
import '../data/services/payments_received_api_service.dart';

class PaymentRecievesState {
  final List<PaymentRecord> records;
  final String sortField;
  final bool sortAscending;
  final List<String> paymentModes;
  final String defaultPaymentMode;
  final FavoriteFilterOption selectedFilter;

  const PaymentRecievesState({
    required this.records,
    required this.sortField,
    required this.sortAscending,
    required this.paymentModes,
    required this.defaultPaymentMode,
    required this.selectedFilter,
  });

  PaymentRecievesState copyWith({
    List<PaymentRecord>? records,
    String? sortField,
    bool? sortAscending,
    List<String>? paymentModes,
    String? defaultPaymentMode,
    FavoriteFilterOption? selectedFilter,
  }) {
    return PaymentRecievesState(
      records: records ?? this.records,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      paymentModes: paymentModes ?? this.paymentModes,
      defaultPaymentMode: defaultPaymentMode ?? this.defaultPaymentMode,
      selectedFilter: selectedFilter ?? this.selectedFilter,
    );
  }
}

class PaymentRecievesNotifier extends StateNotifier<PaymentRecievesState> {
  PaymentRecievesNotifier()
      : super(
          const PaymentRecievesState(
            records: [
              PaymentRecord(
                date: '23-04-2026',
                paymentNo: 'PR-000097',
                reference: 'REF-82910',
                customer: 'STARLEX HEALTH SERVICES & PRODUCTS PVT LTD',
                invoiceNo: 'INV-2026-001',
                mode: 'Cash',
                amount: 15000.0,
                unusedAmount: 0.0,
                status: 'PAID',
                location: 'ZABNIX PRIVATE LIMITED',
                attachments: [],
              ),
              PaymentRecord(
                date: '19-11-2025',
                paymentNo: 'PR-000096',
                reference: 'REF-73821',
                customer: 'GYANKAAR TECHNOLOGIES PRIVATE LIMITED',
                invoiceNo: 'INV-2025-084',
                mode: 'Bank Transfer',
                amount: 7080.0,
                unusedAmount: 7080.0,
                status: 'PAID',
                location: 'ZABNIX PRIVATE LIMITED',
                attachments: [],
              ),
              PaymentRecord(
                date: '10-11-2025',
                paymentNo: 'PR-000095',
                reference: 'REF-62512',
                customer: 'FIRST LOGIC META LAB PRIVATE LIMITED',
                invoiceNo: 'INV-2025-082',
                mode: 'Cash',
                amount: 133000.0,
                unusedAmount: 133000.0,
                status: 'PAID',
                location: 'ZABNIX PRIVATE LIMITED',
                attachments: [],
              ),
            ],
            sortField: 'date',
            sortAscending: false,
            paymentModes: ['Cash', 'Bank Transfer', 'Cheque', 'Credit Card', 'UPI'],
            defaultPaymentMode: 'Cash',
            selectedFilter: FavoriteFilterOption(
              label: 'All Payments',
              value: 'all',
            ),
          ),
        );

  final PaymentsReceivedApiService _api = PaymentsReceivedApiService();
  bool _loaded = false;

  /// Loads payments from the backend once. Pass [force] to reload (e.g. pull to
  /// refresh). On failure the existing records are kept so the list never blanks.
  Future<void> loadPayments({bool force = false}) async {
    if (_loaded && !force) return;
    try {
      final records = await _api.getPayments();
      _loaded = true;
      state = state.copyWith(records: records);
    } catch (_) {
      // Keep current records; surfacing the error is the caller's concern.
    }
  }

  Future<void> refresh() async {
    await loadPayments(force: true);
  }

  void sort(String field, bool ascending) {
    final sortedList = List<PaymentRecord>.from(state.records);
    sortedList.sort((a, b) {
      dynamic valA;
      dynamic valB;
      switch (field) {
        case 'date':
          valA = a.date;
          valB = b.date;
          break;
        case 'payment':
        case 'paymentNo':
          valA = a.paymentNo;
          valB = b.paymentNo;
          break;
        case 'reference':
          valA = a.reference;
          valB = b.reference;
          break;
        case 'customer':
          valA = a.customer;
          valB = b.customer;
          break;
        case 'invoice':
        case 'invoiceNo':
          valA = a.invoiceNo;
          valB = b.invoiceNo;
          break;
        case 'mode':
          valA = a.mode;
          valB = b.mode;
          break;
        case 'amount':
          valA = a.amount;
          valB = b.amount;
          break;
        case 'unused':
        case 'unusedAmount':
          valA = a.unusedAmount;
          valB = b.unusedAmount;
          break;
        case 'status':
          valA = a.status;
          valB = b.status;
          break;
        case 'location':
          valA = a.location;
          valB = b.location;
          break;
        default:
          valA = '';
          valB = '';
      }

      if (valA is num && valB is num) {
        return ascending ? valA.compareTo(valB) : valB.compareTo(valA);
      }
      return ascending
          ? valA.toString().compareTo(valB.toString())
          : valB.toString().compareTo(valA.toString());
    });

    state = state.copyWith(
      records: sortedList,
      sortField: field,
      sortAscending: ascending,
    );
  }

  void toggleSelectAll(bool val, int startIndex, int endIndex) {
    final updatedList = List<PaymentRecord>.from(state.records);
    final limit = endIndex > updatedList.length ? updatedList.length : endIndex;
    for (var i = startIndex; i < limit; i++) {
      updatedList[i] = updatedList[i].copyWith(isSelected: val);
    }
    state = state.copyWith(records: updatedList);
  }

  void toggleRecordSelect(int index, bool val) {
    if (index < 0 || index >= state.records.length) return;
    final updatedList = List<PaymentRecord>.from(state.records);
    updatedList[index] = updatedList[index].copyWith(isSelected: val);
    state = state.copyWith(records: updatedList);
  }

  void bulkUpdate(String field, String value) {
    final updatedList = state.records.map((record) {
      if (record.isSelected) {
        switch (field) {
          case 'Payment Mode':
            return record.copyWith(mode: value);
          case 'Payment Date':
            return record.copyWith(date: value);
          case 'Deposit To':
            return record.copyWith(location: value);
          default:
            return record;
        }
      }
      return record;
    }).toList();
    state = state.copyWith(records: updatedList);
  }

  void deleteSelected() {
    final updatedList = state.records.where((record) => !record.isSelected).toList();
    state = state.copyWith(records: updatedList);
  }

  void updateFilter(FavoriteFilterOption filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void voidRecord(String paymentNo) {
    final updatedList = state.records.map((record) {
      if (record.paymentNo == paymentNo) {
        return record.copyWith(status: 'VOID');
      }
      return record;
    }).toList();
    state = state.copyWith(records: updatedList);
  }

  void deleteRecord(String paymentNo) {
    final updatedList = state.records.where((record) => record.paymentNo != paymentNo).toList();
    state = state.copyWith(records: updatedList);
  }

  void addAttachment(String paymentNo, String name, [dynamic file]) {
    final updatedList = state.records.map((record) {
      if (record.paymentNo == paymentNo) {
        final newAttachments = List<String>.from(record.attachments)..add(name);
        return record.copyWith(attachments: newAttachments);
      }
      return record;
    }).toList();
    state = state.copyWith(records: updatedList);
  }

  void removeAttachment(String paymentNo, String name) {
    final updatedList = state.records.map((record) {
      if (record.paymentNo == paymentNo) {
        final newAttachments = List<String>.from(record.attachments)..remove(name);
        return record.copyWith(attachments: newAttachments);
      }
      return record;
    }).toList();
    state = state.copyWith(records: updatedList);
  }

  void updatePaymentModes(List<String> modes, String defaultMode) {
    state = state.copyWith(
      paymentModes: modes,
      defaultPaymentMode: defaultMode,
    );
  }

  void refundRecord(String paymentNo, double amount) {
    final updatedList = state.records.map((record) {
      if (record.paymentNo == paymentNo) {
        final newUnused = record.unusedAmount - amount;
        return record.copyWith(
          unusedAmount: newUnused < 0 ? 0.0 : newUnused,
        );
      }
      return record;
    }).toList();
    state = state.copyWith(records: updatedList);
  }

  void upsertRecord(PaymentRecord record) {
    final index = state.records.indexWhere((r) => r.paymentNo == record.paymentNo);
    final updatedList = List<PaymentRecord>.from(state.records);
    if (index >= 0) {
      updatedList[index] = record;
    } else {
      updatedList.add(record);
    }
    state = state.copyWith(records: updatedList);
  }
}

final paymentRecievesProvider =
    StateNotifierProvider<PaymentRecievesNotifier, PaymentRecievesState>((ref) {
  return PaymentRecievesNotifier();
});

/// Customers that have invoices in `invoice_master`, loaded from the backend.
/// Sources the "Customer Name" dropdown on the invoice-payment create page.
final invoicePaymentCustomersProvider =
    FutureProvider<List<InvoiceCustomerOption>>((ref) async {
  return PaymentsReceivedApiService().getInvoiceCustomers();
});
