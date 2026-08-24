import 'package:zerpai_erp/modules/inventory/models/warehouse_model.dart';
import 'package:zerpai_erp/core/constants/api_endpoints.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/modules/sales/credit_note/models/credit_note_model.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';

abstract class CreditNoteRepository {
  Future<List<CreditNoteModel>> getCreditNotes({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  });



  Future<String?> createCreditNote(Map<String, dynamic> payload);

  /// Loads a single credit note with its customer and line items, for editing.
  Future<CreditNoteModel> getCreditNote(String id);

  /// Loads the exact journal accounting lines for a credit note.
  Future<Map<String, dynamic>> getCreditNoteJournal(String id);

  /// Replaces the note's header and full line set. The server reposts the
  /// accounting ledger to match.
  Future<void> updateCreditNote(String id, Map<String, dynamic> payload);

  /// Deletes the note along with its line items and posted ledger entries. The
  /// server owns the cascade; this is a single call.
  Future<void> deleteCreditNote(String id);
  Future<CreditNoteInvoiceApplicationData> getEligibleInvoices(String id);

  Future<CreditNoteInvoiceApplicationData> applyToInvoices(
    String id,
    List<CreditNoteInvoiceAllocation> allocations, {
    String? appliedOn,
  });

  /// Fetches warehouses specifically for the credit notes module.
  Future<List<Warehouse>> getWarehouses();
}

class CreditNoteRepositoryImpl implements CreditNoteRepository {
  CreditNoteRepositoryImpl(this._apiClient);
  final ApiClient _apiClient;

  @override
  Future<List<CreditNoteModel>> getCreditNotes({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) async {
    final response = await _apiClient.get(
      ApiEndpoints.creditNotes,
      queryParameters: {
        'page': page,
        'limit': limit,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null &&
            status.isNotEmpty &&
            status.toLowerCase() != 'all')
          'status': status,
      },
    );
    final data = response.data;
    final List<dynamic> list = data is List
        ? data
        : (data['data'] as List<dynamic>? ?? const []);
    return list
        .whereType<Map<String, dynamic>>()
        .map(CreditNoteModel.fromJson)
        .toList();
  }



  @override
  Future<String?> createCreditNote(Map<String, dynamic> payload) async {
    try {
      final response = await _apiClient.post(
        ApiEndpoints.creditNotes,
        data: payload,
      );
      final body = response.data as Map<String, dynamic>;
      return body['id'] as String?;
    } catch (e, st) {
      AppLogger.error(
        'Failed to create credit note',
        error: e,
        stackTrace: st,
        module: 'credit_note',
      );
      rethrow;
    }
  }

  @override
  Future<CreditNoteModel> getCreditNote(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.creditNoteById(id));
      final raw = response.data;
      final map = raw is Map<String, dynamic>
          ? (raw.containsKey('data') && raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw)
          : <String, dynamic>{};
      return CreditNoteModel.fromJson(map);
    } catch (e, st) {
      AppLogger.error(
        'Failed to load credit note',
        error: e,
        stackTrace: st,
        module: 'credit_note',
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getCreditNoteJournal(String id) async {
    try {
      final response = await _apiClient.get(ApiEndpoints.creditNoteJournal(id));
      final raw = response.data;
      return raw is Map<String, dynamic>
          ? (raw.containsKey('data') && raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw)
          : <String, dynamic>{};
    } catch (e, st) {
      AppLogger.error(
        'Failed to load credit note journal',
        error: e,
        stackTrace: st,
        module: 'credit_note',
      );
      rethrow;
    }
  }

  @override
  Future<void> updateCreditNote(String id, Map<String, dynamic> payload) async {
    try {
      await _apiClient.put(ApiEndpoints.creditNoteUpdate(id), data: payload);
    } catch (e, st) {
      AppLogger.error(
        'Failed to update credit note',
        error: e,
        stackTrace: st,
        module: 'credit_note',
      );
      rethrow;
    }
  }


  @override
  Future<CreditNoteInvoiceApplicationData> getEligibleInvoices(String id) async {
    final response = await _apiClient.get('credit-notes/$id/eligible-invoices');
    return CreditNoteInvoiceApplicationData.fromResponse(response.data);
  }

  @override
  Future<CreditNoteInvoiceApplicationData> applyToInvoices(
    String id,
    List<CreditNoteInvoiceAllocation> allocations, {
    String? appliedOn,
  }) async {
    final response = await _apiClient.post(
      'credit-notes/$id/apply-to-invoices',
      data: {
        'allocations': allocations.map((allocation) => allocation.toJson()).toList(),
        if (appliedOn != null) 'appliedOn': appliedOn,
      },
    );
    return CreditNoteInvoiceApplicationData.fromResponse(response.data);
  }

  @override
  Future<void> deleteCreditNote(String id) async {
    try {
      await _apiClient.delete(ApiEndpoints.creditNoteById(id));
    } catch (e, st) {
      AppLogger.error(
        'Failed to delete credit note',
        error: e,
        stackTrace: st,
        module: 'credit_note',
      );
      rethrow;
    }
  }

  @override
  Future<List<Warehouse>> getWarehouses() async {
    try {
      final response = await _apiClient.get(
        '/credit-notes/lookups/warehouses',
        useCache: false,
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> rows = [];
        if (data is Map && data.containsKey('data')) {
          rows = data['data'] as List<dynamic>;
        } else if (data is List) {
          rows = data;
        }
        return rows
            .map((row) => Warehouse.fromJson(Map<String, dynamic>.from(row)))
            .toList();
      }
      return [];
    } catch (e) {
      AppLogger.warning('Failed to load warehouses for credit note', error: e);
      return [];
    }
  }
}


class CreditNoteInvoiceAllocation {
  const CreditNoteInvoiceAllocation({required this.invoiceId, required this.amount});

  final String invoiceId;
  final double amount;

  Map<String, dynamic> toJson() => {'invoiceId': invoiceId, 'amount': amount};
}

class CreditNoteEligibleInvoice {
  const CreditNoteEligibleInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.invoiceAmount,
    required this.allocatedAmount,
    required this.outstandingAmount,
  });

  final String id;
  final String invoiceNumber;
  final String? invoiceDate;
  final String? dueDate;
  final double invoiceAmount;
  final double allocatedAmount;
  final double outstandingAmount;

  factory CreditNoteEligibleInvoice.fromJson(Map<String, dynamic> json) =>
      CreditNoteEligibleInvoice(
        id: json['invoiceId']?.toString() ?? '',
        invoiceNumber: json['invoiceNumber']?.toString() ?? '-',
        invoiceDate: json['invoiceDate']?.toString(),
        dueDate: json['dueDate']?.toString(),
        invoiceAmount: _creditNoteNumber(json['invoiceAmount']),
        allocatedAmount: _creditNoteNumber(json['allocatedAmount']),
        outstandingAmount: _creditNoteNumber(json['outstandingAmount']),
      );
}

class CreditNoteAppliedInvoice {
  const CreditNoteAppliedInvoice({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.appliedOn,
    required this.amount,
  });

  final String invoiceId;
  final String invoiceNumber;
  final String? appliedOn;
  final double amount;

  factory CreditNoteAppliedInvoice.fromJson(Map<String, dynamic> json) =>
      CreditNoteAppliedInvoice(
        invoiceId: json['invoiceId']?.toString() ?? '',
        invoiceNumber: json['invoiceNumber']?.toString() ?? '-',
        appliedOn: json['appliedOn']?.toString(),
        amount: _creditNoteNumber(json['amount']),
      );
}

class CreditNoteInvoiceApplicationData {
  const CreditNoteInvoiceApplicationData({
    required this.invoices,
    required this.applications,
    required this.totalApplied,
    required this.remainingCredit,
    required this.status,
  });

  final List<CreditNoteEligibleInvoice> invoices;
  final List<CreditNoteAppliedInvoice> applications;
  final double totalApplied;
  final double remainingCredit;
  final String status;

  factory CreditNoteInvoiceApplicationData.fromResponse(dynamic response) {
    final root = Map<String, dynamic>.from(response as Map);
    final data = root['data'] is Map ? Map<String, dynamic>.from(root['data'] as Map) : root;
    List<Map<String, dynamic>> maps(dynamic value) => value is List
        ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList()
        : const [];
    return CreditNoteInvoiceApplicationData(
      invoices: maps(data['invoices']).map(CreditNoteEligibleInvoice.fromJson).toList(),
      applications: maps(data['applications']).map(CreditNoteAppliedInvoice.fromJson).toList(),
      totalApplied: _creditNoteNumber(data['totalApplied']),
      remainingCredit: _creditNoteNumber(data['remainingCredit']),
      status: data['status']?.toString() ?? 'OPEN',
    );
  }
}

double _creditNoteNumber(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;
