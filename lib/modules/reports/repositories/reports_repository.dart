import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zerpai_erp/shared/services/api_client.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';

class ReportsRepository {
  final ApiClient _apiClient;

  ReportsRepository(this._apiClient);

  Future<Map<String, dynamic>> getCurrentBranchHeader() async {
    try {
      final response = await _apiClient.get('reports/current-branch');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Reports current branch header',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfitAndLoss(
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await _apiClient.get(
        'reports/profit-and-loss',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Profit and Loss report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGeneralLedger(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/general-ledger',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch General Ledger report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDetailedGeneralLedger(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/detailed-general-ledger',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Detailed General Ledger report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }


  Future<Map<String, dynamic>> getJournalReport(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/journal-report',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Journal Report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getDayBook(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/day-book',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Day Book report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getPurchaseOrdersByVendor(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/purchase-orders-by-vendor',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Purchase Orders by Vendor report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getPurchaseOrdersByItem(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 200,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/purchase-orders-by-item',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Purchase Orders by Item report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getPaymentsMade(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/payments-made',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Payments Made report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getBillDetails({
    int page = 1,
    int limit = 25,
    String? search,
    String? vendorId,
    String? warehouseId,
    String? status,
    String? reportBy,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/bill-details',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (vendorId != null && vendorId.trim().isNotEmpty)
            'vendorId': vendorId,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (reportBy != null && reportBy.trim().isNotEmpty)
            'reportBy': reportBy,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Bill Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getVendorCreditsDetails({
    int page = 1,
    int limit = 25,
    String? search,
    String? vendorId,
    String? warehouseId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/vendor-credits-details',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (vendorId != null && vendorId.trim().isNotEmpty)
            'vendorId': vendorId,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Vendor Credits Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getPurchaseOrderDetails(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/purchase-order-details',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Purchase Order Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getInvoiceDetails(
    String startDate,
    String endDate, {
    String? basis,
    String? reportBy,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/invoice-details',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          if (reportBy != null && reportBy.isNotEmpty) 'reportBy': reportBy,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Invoice Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getCreditNoteDetails(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/credit-note-details',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Credit Note Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getRetainerInvoiceDetails(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/retainer-invoice-details',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Retainer Invoice Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getQuoteDetails(
    String startDate,
    String endDate, {
    String? basis,
    String? reportBy,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/quote-details',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          if (reportBy != null && reportBy.isNotEmpty) 'reportBy': reportBy,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Quote Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getDeliveryChallanDetails(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/delivery-challan-details',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Delivery Challan Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getSalesOrderDetails(
    String startDate,
    String endDate, {
    String? basis,
    String? status,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/sales-order-details',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          if (status != null && status.isNotEmpty) 'status': status,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Sales Order Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getTaxSummary(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/tax-summary',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Tax Summary report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getTdsSummary(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/tds-summary',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch TDS Summary report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getTrialBalance(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/trial-balance',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Trial Balance report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAccountTypeSummary(
    String startDate,
    String endDate, {
    String? basis,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/account-type-summary',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Account Type Summary report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAccountTypeTransactions(
    String startDate,
    String endDate, {
    String? basis,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/account-type-transactions',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Account Type Transactions report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getAccountTransactions(
    String? accountId,
    String startDate,
    String endDate, {
    String? contactId,
    String? contactType,
    String? basis,
    String? accountType,
    int page = 1,
    int pageSize = 25,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/account-transactions',
        queryParameters: {
          if (accountId != null && accountId.isNotEmpty) 'accountId': accountId,
          'startDate': startDate,
          'endDate': endDate,
          if (contactId != null) 'contactId': contactId,
          if (contactType != null) 'contactType': contactType,
          if (basis != null && basis.isNotEmpty) 'basis': basis,
          if (accountType != null && accountType.isNotEmpty)
            'accountType': accountType,
          'page': page,
          'pageSize': pageSize,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Account Transactions report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSalesByCustomer(
    String startDate,
    String endDate,
  ) async {
    try {
      final response = await _apiClient.get(
        'reports/sales-by-customer',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Sales by Customer report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Map<String, dynamic> _salesReportQuery(
    String startDate,
    String endDate, {
    List<String>? entities,
    String? groupBy,
    String? reportBy,
    int page = 1,
    int limit = 500,
  }) {
    return {
      'startDate': startDate,
      'endDate': endDate,
      'page': page,
      'limit': limit,
      if (entities != null && entities.isNotEmpty)
        'entities': entities.join(','),
      if (groupBy != null && groupBy.trim().isNotEmpty) 'groupBy': groupBy,
      if (reportBy != null && reportBy.trim().isNotEmpty) 'reportBy': reportBy,
    };
  }

  List<Map<String, dynamic>> _normalizeRows(dynamic value) {
    final rawRows = value is List
        ? value
        : value is Map && value['data'] is List
        ? value['data'] as List
        : value is Map && value['items'] is List
        ? value['items'] as List
        : const <dynamic>[];

    return rawRows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList(growable: false);
  }

  Map<String, dynamic> _normalizePagedReportResponse(
    dynamic data,
    Map<String, dynamic> extra, {
    required int page,
    required int limit,
  }) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    final rows = _normalizeRows(data);
    final rawMeta = extra['meta'];
    final meta = rawMeta is Map
        ? Map<String, dynamic>.from(rawMeta)
        : <String, dynamic>{
            'page': page,
            'limit': limit,
            'total': rows.length,
            'totalPages': rows.length <= limit
                ? 1
                : (rows.length / limit).ceil(),
          };

    meta['page'] ??= page;
    meta['limit'] ??= limit;
    meta['total'] ??= rows.length;
    meta['totalPages'] ??= rows.length <= limit
        ? 1
        : (rows.length / limit).ceil();

    return <String, dynamic>{'data': rows, 'meta': meta};
  }

  Future<Set<String>> getReportFavoriteNames() async {
    try {
      final response = await _apiClient.get('reports/favorites');
      return _normalizeRows(response.data)
          .map((row) => row['report']?.toString().trim() ?? '')
          .where((report) => report.isNotEmpty)
          .toSet();
    } catch (e) {
      AppLogger.error(
        'Failed to fetch report favorites',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<void> saveReportFavorite(String report) async {
    try {
      await _apiClient.post('reports/favorites', data: {'report': report});
    } catch (e) {
      AppLogger.error(
        'Failed to save report favorite',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<void> removeReportFavorite(String report) async {
    try {
      await _apiClient.delete(
        'reports/favorites',
        queryParameters: {'report': report},
      );
    } catch (e) {
      AppLogger.error(
        'Failed to remove report favorite',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _getSalesRows(
    String endpoint,
    Map<String, dynamic> queryParameters,
    String logLabel,
  ) async {
    try {
      final response = await _apiClient.get(
        endpoint,
        queryParameters: queryParameters,
      );
      return _normalizeRows(response.data);
    } catch (e) {
      AppLogger.error('Failed to fetch $logLabel', error: e, module: 'reports');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSalesByCustomerRows(
    String startDate,
    String endDate, {
    List<String>? entities,
  }) {
    return _getSalesRows(
      'reports/sales-by-customer',
      _salesReportQuery(startDate, endDate, entities: entities),
      'Sales by Customer report rows',
    );
  }

  Future<List<Map<String, dynamic>>> getSalesByItemRows(
    String startDate,
    String endDate, {
    List<String>? entities,
    String? groupBy,
  }) {
    return _getSalesRows(
      'reports/sales-by-item',
      _salesReportQuery(
        startDate,
        endDate,
        entities: entities,
        groupBy: groupBy,
      ),
      'Sales by Item report rows',
    );
  }

  Future<List<Map<String, dynamic>>> getSalesBySalespersonRows(
    String startDate,
    String endDate,
  ) {
    return _getSalesRows(
      'reports/sales-by-salesperson',
      _salesReportQuery(startDate, endDate),
      'Sales by Salesperson report rows',
    );
  }

  Future<List<Map<String, dynamic>>> getSalesSummaryRows(
    String startDate,
    String endDate, {
    String? groupBy,
  }) {
    return _getSalesRows(
      'reports/sales-summary',
      _salesReportQuery(startDate, endDate, groupBy: groupBy),
      'Sales Summary report rows',
    );
  }

  Future<List<Map<String, dynamic>>> getProfitByItemRows(
    String startDate,
    String endDate, {
    String? reportBy,
  }) {
    return _getSalesRows(
      'reports/profit-by-item',
      _salesReportQuery(startDate, endDate, reportBy: reportBy),
      'Profit by Item report rows',
    );
  }

  Future<List<Map<String, dynamic>>> getPaymentsReceivedRows(
    String startDate,
    String endDate, {
    String? transactionType,
    int page = 1,
    int limit = 500,
  }) {
    return _getSalesRows('reports/payments-received', {
      ..._salesReportQuery(startDate, endDate, page: page, limit: limit),
      if (transactionType != null && transactionType.trim().isNotEmpty)
        'transactionType': transactionType,
    }, 'Payments Received report rows');
  }

  Future<List<Map<String, dynamic>>> getRecurringInvoiceRows(
    String startDate,
    String endDate, {
    String? reportBy,
    int page = 1,
    int limit = 500,
  }) {
    return _getSalesRows(
      'reports/recurring-invoices',
      _salesReportQuery(
        startDate,
        endDate,
        reportBy: reportBy,
        page: page,
        limit: limit,
      ),
      'Recurring Invoices report rows',
    );
  }

  Future<List<Map<String, dynamic>>> getRecurringInvoiceDetailRows(
    String recurringInvoiceId,
    String startDate,
    String endDate, {
    String? reportBy,
  }) {
    return _getSalesRows(
      'reports/recurring-invoices/$recurringInvoiceId/details',
      _salesReportQuery(startDate, endDate, reportBy: reportBy),
      'Recurring Invoice Details report rows',
    );
  }

  Future<List<Map<String, dynamic>>> getSalesChannelIntegrationsSyncSummaryRows(
    String startDate,
    String endDate,
  ) {
    return _getSalesRows(
      'reports/sales-channel-integrations-sync-summary',
      _salesReportQuery(startDate, endDate),
      'Sales Channel Integrations Sync Summary report rows',
    );
  }

  Future<List<Map<String, dynamic>>> getSalesByCustomerTransactions(
    String customerId,
    String startDate,
    String endDate,
  ) {
    return _getSalesRows(
      'reports/sales-by-customer/$customerId/transactions',
      _salesReportQuery(startDate, endDate),
      'Sales by Customer transaction rows',
    );
  }

  Future<List<Map<String, dynamic>>> getSalesByItemTransactions(
    String itemId,
    String startDate,
    String endDate,
  ) {
    return _getSalesRows(
      'reports/sales-by-item/$itemId/transactions',
      _salesReportQuery(startDate, endDate),
      'Sales by Item transaction rows',
    );
  }

  Future<List<Map<String, dynamic>>> getSalesBySalespersonTransactions(
    String salespersonName,
    String startDate,
    String endDate,
  ) {
    return _getSalesRows(
      'reports/sales-by-salesperson/${Uri.encodeComponent(salespersonName)}/transactions',
      _salesReportQuery(startDate, endDate),
      'Sales by Salesperson transaction rows',
    );
  }

  Future<Map<String, dynamic>> getBatchDetails({
    int page = 1,
    int limit = 100,
    String? startDate,
    String? endDate,
    String? search,
    String? warehouseId,
    String? productId,
    String? status,
    bool hideEmptyBatches = false,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/batch-details',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (productId != null && productId.trim().isNotEmpty)
            'productId': productId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (hideEmptyBatches) 'hideEmptyBatches': 'true',
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Batch Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getSerialNumberDetails({
    int page = 1,
    int limit = 100,
    String? startDate,
    String? endDate,
    String? search,
    String? warehouseId,
    String? productId,
    String? status,
    String? reportBy,
  }) async {
    final meta = <String, dynamic>{
      'page': page,
      'limit': limit,
      'total': 0,
      'totalPages': 1,
    };

    return _normalizePagedReportResponse(
      <String, dynamic>{'data': const <Map<String, dynamic>>[], 'meta': meta},
      const <String, dynamic>{},
      page: page,
      limit: limit,
    );
  }
  Future<Map<String, dynamic>> getInventorySummary({
    int page = 1,
    int limit = 500,
    String? search,
    String? warehouseId,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/inventory-summary',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
        },
      );
      AppLogger.info(
        '[REPORTS FRONTEND] Inventory Summary API response before casting',
        module: 'reports',
        data: {
          'responseDataRuntimeType': response.data.runtimeType.toString(),
          'responseData': response.data,
          'responseExtraMeta': response.extra['meta'],
        },
      );

      final normalized = _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );

      AppLogger.info(
        '[REPORTS FRONTEND] Inventory Summary normalized response',
        module: 'reports',
        data: {
          'normalizedRuntimeType': normalized.runtimeType.toString(),
          'dataLength': _normalizeRows(normalized['data']).length,
          'meta': normalized['meta'],
        },
      );

      return normalized;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Inventory Summary report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStockSummary({
    int page = 1,
    int limit = 500,
    String? search,
    String? warehouseId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/stock-summary',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Stock Summary report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStockMovement({
    int page = 1,
    int limit = 500,
    String? search,
    String? warehouseId,
    String? productId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/stock-movement',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (productId != null && productId.trim().isNotEmpty)
            'productId': productId,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Stock Movement report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInventoryTurnoverByQuantity({
    int page = 1,
    int limit = 500,
    String? search,
    String? warehouseId,
    String? productId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/inventory-turnover-by-quantity',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (productId != null && productId.trim().isNotEmpty)
            'productId': productId,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Inventory Turnover By Quantity report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInventoryAdjustmentSummary({
    int page = 1,
    int limit = 500,
    String? search,
    String? warehouseId,
    String? productId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/inventory-adjustment-summary',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (productId != null && productId.trim().isNotEmpty)
            'productId': productId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Inventory Adjustment Summary report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInventoryAdjustmentDetails({
    int page = 1,
    int limit = 500,
    String? search,
    String? warehouseId,
    String? productId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/inventory-adjustment-details',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (productId != null && productId.trim().isNotEmpty)
            'productId': productId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Inventory Adjustment Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCommittedStockDetails({
    int page = 1,
    int limit = 500,
    String? search,
    String? warehouseId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/committed-stock-details',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Committed Stock Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAssemblyDetails({
    int page = 1,
    int limit = 500,
    String? search,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/assembly-details',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Assembly Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getInventoryAgingSummary({
    int page = 1,
    int limit = 500,
    String? search,
    String? warehouseId,
    String? endDate,
    int intervalCount = 6,
    int intervalDays = 3,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/inventory-aging-summary',
        queryParameters: {
          'page': page,
          'limit': limit,
          'intervalCount': intervalCount,
          'intervalDays': intervalDays,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Inventory Aging Summary report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getFifoCostLotTracking({
    int page = 1,
    int limit = 200,
    String? search,
    String? warehouseId,
    String? productId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/fifo-cost-lot-tracking',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (productId != null && productId.trim().isNotEmpty)
            'productId': productId,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch FIFO Cost Lot Tracking report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getLandedCostSummary({
    int page = 1,
    int limit = 100,
    String? startDate,
    String? endDate,
    String? search,
    String? warehouseId,
    String? productId,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/landed-cost-summary',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (productId != null && productId.trim().isNotEmpty)
            'productId': productId,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Landed Cost Summary report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getInventoryValuation({
    int page = 1,
    int limit = 100,
    String? endDate,
    String? stockAvailability,
    String? status,
    String? search,
    String? warehouseId,
    String? productId,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/inventory-valuation',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
          if (stockAvailability != null &&
              stockAvailability.trim().isNotEmpty &&
              stockAvailability.trim().toLowerCase() != 'no criteria')
            'stockAvailability': stockAvailability,
          if (status != null &&
              status.trim().isNotEmpty &&
              status.trim().toLowerCase() != 'all')
            'status': status,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (productId != null && productId.trim().isNotEmpty)
            'productId': productId,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Inventory Valuation report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getExpensesByCustomer({
    int page = 1,
    int limit = 500,
    String? search,
    String? vendorId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/expenses-by-customer',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (vendorId != null && vendorId.trim().isNotEmpty)
            'vendorId': vendorId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Expenses by Customer report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getExpensesByEmployee({
    int page = 1,
    int limit = 500,
    String? search,
    String? vendorId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/expenses-by-employee',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (vendorId != null && vendorId.trim().isNotEmpty)
            'vendorId': vendorId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Expenses by Employee report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getExpensesByCategory({
    int page = 1,
    int limit = 500,
    String? search,
    String? vendorId,
    String? status,
    String? filterBy,
    String? accountType,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/expenses-by-category',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (vendorId != null && vendorId.trim().isNotEmpty)
            'vendorId': vendorId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (filterBy != null && filterBy.trim().isNotEmpty)
            'filterBy': filterBy,
          if (accountType != null && accountType.trim().isNotEmpty)
            'accountType': accountType,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Expenses by Category report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getExpenseDetails({
    int page = 1,
    int limit = 500,
    String? search,
    String? vendorId,
    String? status,
    String? filterBy,
    String? accountType,
    String? categoryName,
    String? customerName,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/expense-details',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (vendorId != null && vendorId.trim().isNotEmpty)
            'vendorId': vendorId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (filterBy != null && filterBy.trim().isNotEmpty)
            'filterBy': filterBy,
          if (accountType != null && accountType.trim().isNotEmpty)
            'accountType': accountType,
          if (categoryName != null && categoryName.trim().isNotEmpty)
            'categoryName': categoryName,
          if (customerName != null && customerName.trim().isNotEmpty)
            'customerName': customerName,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Expense Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBillableExpenseDetails({
    int page = 1,
    int limit = 500,
    String? search,
    String? vendorId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/billable-expense-details',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (vendorId != null && vendorId.trim().isNotEmpty)
            'vendorId': vendorId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Billable Expense Details report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPurchasesByItem({
    int page = 1,
    int limit = 500,
    String? search,
    String? vendorId,
    String? warehouseId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/purchases-by-item',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (vendorId != null && vendorId.trim().isNotEmpty)
            'vendorId': vendorId,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Purchases by Item report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPurchasesByVendor({
    int page = 1,
    int limit = 500,
    String? search,
    String? vendorId,
    String? warehouseId,
    String? status,
    String? filterBy,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/purchases-by-vendor',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (vendorId != null && vendorId.trim().isNotEmpty)
            'vendorId': vendorId,
          if (warehouseId != null && warehouseId.trim().isNotEmpty)
            'warehouseId': warehouseId,
          if (status != null && status.trim().isNotEmpty) 'status': status,
          if (filterBy != null && filterBy.trim().isNotEmpty)
            'filterBy': filterBy,
          if (startDate != null && startDate.trim().isNotEmpty)
            'startDate': startDate,
          if (endDate != null && endDate.trim().isNotEmpty) 'endDate': endDate,
        },
      );
      return _normalizePagedReportResponse(
        response.data,
        response.extra,
        page: page,
        limit: limit,
      );
    } catch (e) {
      AppLogger.error(
        'Failed to fetch Purchases by Vendor report',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAuditLogs({
    int page = 1,
    int pageSize = 25,
    String? search,
    List<String>? tables,
    List<String>? actions,
    String? requestId,
    String? source,
    String? fromDate,
    String? toDate,
    String? scope,
  }) async {
    try {
      final response = await _apiClient.get(
        'reports/audit-logs',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (tables != null && tables.isNotEmpty) 'tables': tables.join(','),
          if (actions != null && actions.isNotEmpty)
            'actions': actions.join(','),
          if (requestId != null && requestId.trim().isNotEmpty)
            'requestId': requestId,
          if (source != null && source.trim().isNotEmpty) 'source': source,
          if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
          if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
          if (scope != null && scope.isNotEmpty) 'scope': scope,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      AppLogger.error(
        'Failed to fetch audit logs',
        error: e,
        module: 'reports',
      );
      rethrow;
    }
  }
}

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  return ReportsRepository(ref.watch(apiClientProvider));
});
