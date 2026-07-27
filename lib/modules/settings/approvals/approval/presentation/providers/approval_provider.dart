import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

class ApprovalRecord {
  const ApprovalRecord({
    this.id,
    required this.module,
    required this.approvalType,
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
    this.approvers = const [],
  });

  final String? id;
  final String module;
  final String approvalType;
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
  final List<String> approvers;

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

class ApprovalNotifier extends StateNotifier<List<ApprovalRecord>> {
  ApprovalNotifier(this._apiClient) : super(const []) {
    load();
  }

  final ApiClient _apiClient;

  Future<void> load() async {
    final response = await _apiClient.get(
      'settings-customization/approval-rules',
      useCache: false,
    );
    state = (response.data as List? ?? const [])
        .whereType<Map>()
        .map((row) => _fromBackend(Map<String, dynamic>.from(row)))
        .toList();
  }

  Future<void> addSeries(ApprovalRecord record) async {
    final response = await _apiClient.post(
      'settings-customization/approval-rules',
      data: _toBackend(record),
    );
    state = [
      ...state,
      _fromBackend(Map<String, dynamic>.from(response.data as Map)),
    ];
  }

  Future<void> updateSeries(int index, ApprovalRecord record) async {
    if (index < 0 || index >= state.length) return;
    final id = state[index].id;
    if (id == null) return;
    final response = await _apiClient.patch(
      'settings-customization/approval-rules/$id',
      data: _toBackend(record),
    );
    final next = [...state];
    next[index] = _fromBackend(Map<String, dynamic>.from(response.data as Map));
    state = next;
  }

  Future<void> deactivateSeries(int index) async {
    if (index < 0 || index >= state.length) return;
    final id = state[index].id;
    if (id == null) return;
    await _apiClient.delete('settings-customization/approval-rules/$id');
    state = [...state]..removeAt(index);
  }

  ApprovalRecord _fromBackend(Map<String, dynamic> row) {
    final conditions = row['conditions'] is Map
        ? Map<String, dynamic>.from(row['conditions'] as Map)
        : <String, dynamic>{};
    final series = conditions['series'] is Map
        ? Map<String, dynamic>.from(conditions['series'] as Map)
        : <String, dynamic>{};
    final approvers = row['approvers'] is List
        ? (row['approvers'] as List).map((value) => value.toString()).toList()
        : <String>[];
    String value(String key) => series[key]?.toString() ?? '';
    return ApprovalRecord(
      id: row['id']?.toString(),
      module: row['module']?.toString() ?? '',
      approvalType: row['approval_type']?.toString() ?? '',
      seriesName: row['rule_name']?.toString() ?? '',
      vendorPayment: value('vendor_payment'),
      retainerInvoice: value('retainer_invoice'),
      purchaseOrder: value('purchase_order'),
      creditNote: value('credit_note'),
      customerPayment: value('customer_payment'),
      deliveryChallan: value('delivery_challan'),
      billOfSupply: value('bill_of_supply'),
      invoice: value('invoice'),
      salesOrder: value('sales_order'),
      selfInvoice: value('self_invoice'),
      associatedLocations:
          conditions['associated_locations']?.toString() ?? '--',
      approvers: approvers,
    );
  }

  Map<String, dynamic> _toBackend(ApprovalRecord record) => {
    'module': record.module,
    'approval_type': record.approvalType,
    'rule_name': record.seriesName,
    'conditions': {
      'associated_locations': record.associatedLocations,
      'series': {
        'vendor_payment': record.vendorPayment,
        'retainer_invoice': record.retainerInvoice,
        'purchase_order': record.purchaseOrder,
        'credit_note': record.creditNote,
        'customer_payment': record.customerPayment,
        'delivery_challan': record.deliveryChallan,
        'bill_of_supply': record.billOfSupply,
        'invoice': record.invoice,
        'sales_order': record.salesOrder,
        'self_invoice': record.selfInvoice,
      },
    },
    'approvers': record.approvers,
    'is_active': true,
  };
}

final ApprovalProvider =
    StateNotifierProvider<ApprovalNotifier, List<ApprovalRecord>>(
      (ref) => ApprovalNotifier(ref.watch(apiClientProvider)),
    );
