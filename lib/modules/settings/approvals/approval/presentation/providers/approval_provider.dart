import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApprovalRecord {
  const ApprovalRecord({
    required this.seriesName,
    required this.vendorPayment,
    required this.retainerInvoice,
    required this.purchaseOrder,
    required this.creditNote,
    required this.customerPayment,
    required this.deliveryChallan,
    required this.billOfSupply,
    required this.invoice,
    required this.salesOrder,
    required this.selfInvoice,
    required this.associatedLocations,
  });

  final String seriesName;
  final String vendorPayment;
  final String retainerInvoice;
  final String purchaseOrder;
  final String creditNote;
  final String customerPayment;
  final String deliveryChallan;
  final String billOfSupply;
  final String invoice;
  final String salesOrder;
  final String selfInvoice;
  final String associatedLocations;

  List<String> toTableValues() => [
    seriesName,
    vendorPayment,
    retainerInvoice,
    purchaseOrder,
    creditNote,
    customerPayment,
    deliveryChallan,
    billOfSupply,
    invoice,
    salesOrder,
    selfInvoice,
    associatedLocations,
  ];
}

class ApprovalNotifier
    extends StateNotifier<List<ApprovalRecord>> {
  ApprovalNotifier() : super(_defaultApproval);

  void addSeries(ApprovalRecord record) {
    state = [...state, record];
  }

  void updateSeries(int index, ApprovalRecord record) {
    if (index < 0 || index >= state.length) return;
    final next = [...state];
    next[index] = record;
    state = next;
  }
}

final ApprovalProvider =
    StateNotifierProvider<
      ApprovalNotifier,
      List<ApprovalRecord>
    >((ref) => ApprovalNotifier());

const List<ApprovalRecord> _defaultApproval = [
  ApprovalRecord(
    seriesName: 'Vendor Payment - Simple approval',
    vendorPayment: '',
    retainerInvoice: '',
    purchaseOrder: '',
    creditNote: '',
    customerPayment: '',
    deliveryChallan: '',
    billOfSupply: '',
    invoice: '',
    salesOrder: '',
    selfInvoice: '',
    associatedLocations: '--',
  ),
  ApprovalRecord(
    seriesName: 'Purchase Order - Multi-level Approval',
    vendorPayment: '',
    retainerInvoice: '',
    purchaseOrder: '',
    creditNote: '',
    customerPayment: '',
    deliveryChallan: '',
    billOfSupply: '',
    invoice: '',
    salesOrder: '',
    selfInvoice: '',
    associatedLocations: '--',
  ),
  ApprovalRecord(
    seriesName: 'Invoice - Simple approval',
    vendorPayment: '',
    retainerInvoice: '',
    purchaseOrder: '',
    creditNote: '',
    customerPayment: '',
    deliveryChallan: '',
    billOfSupply: '',
    invoice: '',
    salesOrder: '',
    selfInvoice: '',
    associatedLocations: '--',
  ),
  ApprovalRecord(
    seriesName: 'Sales Order - Multi-level Approval',
    vendorPayment: '',
    retainerInvoice: '',
    purchaseOrder: '',
    creditNote: '',
    customerPayment: '',
    deliveryChallan: '',
    billOfSupply: '',
    invoice: '',
    salesOrder: '',
    selfInvoice: '',
    associatedLocations: '--',
  ),
];
