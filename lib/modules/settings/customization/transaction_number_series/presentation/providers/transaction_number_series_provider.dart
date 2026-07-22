import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/core/services/api_client.dart';

class TransactionNumberSeriesRecord {
  const TransactionNumberSeriesRecord({
    this.id,
    required this.seriesName,
    this.vendorPayment = '',
    this.retainerInvoice = '',
    this.purchaseOrder = '',
    this.creditNote = '',
    this.customerPayment = '',
    this.deliveryChallan = '',
    this.billOfSupply = '',
    this.invoice = '',
    this.salesOrder = '',
    this.selfInvoice = '',
    this.associatedLocations = '',
  });

  final String? id;
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

  List<String> toTableValues() => <String>[
    seriesName,
    invoice,
    salesOrder,
    purchaseOrder,
    creditNote,
    vendorPayment,
  ];
}

final transactionNumberSeriesProvider =
    StateNotifierProvider<
      TransactionNumberSeriesNotifier,
      List<TransactionNumberSeriesRecord>
    >((ref) => TransactionNumberSeriesNotifier(ref.watch(apiClientProvider)));

class TransactionNumberSeriesNotifier
    extends StateNotifier<List<TransactionNumberSeriesRecord>> {
  TransactionNumberSeriesNotifier(this._apiClient) : super(const []) {
    load();
  }

  final ApiClient _apiClient;

  Future<void> load({bool forceRefresh = false}) async {
    final response = await _apiClient.get(
      'transaction-series',
      useCache: !forceRefresh,
    );
    final rows = response.data is List ? response.data as List : const [];
    state = rows
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .toList(growable: false);
  }

  Future<void> addSeries(TransactionNumberSeriesRecord record) async {
    final response = await _apiClient.post(
      'transaction-series',
      data: _toPayload(record),
    );
    final created = _fromJson(Map<String, dynamic>.from(response.data as Map));
    state = [...state, created];
  }

  Future<void> updateSeries(
    int index,
    TransactionNumberSeriesRecord record,
  ) async {
    if (index < 0 || index >= state.length) return;
    final id = state[index].id;
    if (id == null || id.isEmpty) return;

    final response = await _apiClient.patch(
      'transaction-series/$id',
      data: _toPayload(record),
    );
    final updated = _fromJson(Map<String, dynamic>.from(response.data as Map));
    final next = [...state]..[index] = updated;
    state = next;
  }

  TransactionNumberSeriesRecord _fromJson(Map<String, dynamic> json) {
    final modules = json['modules'] is Map
        ? Map<String, dynamic>.from(json['modules'] as Map)
        : <String, dynamic>{};

    return TransactionNumberSeriesRecord(
      id: json['id']?.toString(),
      seriesName: json['name']?.toString() ?? '',
      vendorPayment: _moduleValue(modules, 'vendor_payment'),
      retainerInvoice: _moduleValue(modules, 'retainer_invoice'),
      purchaseOrder: _moduleValue(modules, 'purchase_order'),
      creditNote: _moduleValue(modules, 'credit_note'),
      customerPayment: _moduleValue(modules, 'customer_payment'),
      deliveryChallan: _moduleValue(modules, 'delivery_challan'),
      billOfSupply: _moduleValue(modules, 'bill_of_supply'),
      invoice: _moduleValue(modules, 'invoice'),
      salesOrder: _moduleValue(modules, 'sales_order'),
      selfInvoice: _moduleValue(modules, 'self_invoice'),
      associatedLocations: '--',
    );
  }

  Map<String, dynamic> _toPayload(TransactionNumberSeriesRecord record) {
    return <String, dynamic>{
      'name': record.seriesName,
      'code': _seriesCode(record.seriesName),
      'modules': <String, dynamic>{
        'vendor_payment': _modulePayload(record.vendorPayment),
        'retainer_invoice': _modulePayload(record.retainerInvoice),
        'purchase_order': _modulePayload(record.purchaseOrder),
        'credit_note': _modulePayload(record.creditNote),
        'customer_payment': _modulePayload(record.customerPayment),
        'delivery_challan': _modulePayload(record.deliveryChallan),
        'bill_of_supply': _modulePayload(record.billOfSupply),
        'invoice': _modulePayload(record.invoice),
        'sales_order': _modulePayload(record.salesOrder),
        'self_invoice': _modulePayload(record.selfInvoice),
      },
    };
  }

  String _moduleValue(Map<String, dynamic> modules, String key) {
    final raw = modules[key];
    if (raw is! Map) return '';
    final module = Map<String, dynamic>.from(raw);
    final prefix = module['prefix']?.toString() ?? '';
    final starting = module['starting_number']?.toString() ?? '';
    return '$prefix$starting';
  }

  Map<String, dynamic> _modulePayload(String value) {
    final match = RegExp(r'^(.*?)(\d+)$').firstMatch(value.trim());
    if (match == null) {
      return <String, dynamic>{'prefix': value.trim(), 'starting_number': 1};
    }
    return <String, dynamic>{
      'prefix': match.group(1) ?? '',
      'starting_number': int.tryParse(match.group(2) ?? '') ?? 1,
    };
  }

  String _seriesCode(String name) {
    final code = name
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return code.isEmpty ? 'SERIES' : code;
  }
}
