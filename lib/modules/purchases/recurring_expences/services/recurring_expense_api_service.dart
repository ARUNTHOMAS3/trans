import 'package:dio/dio.dart';
import 'package:zerpai_erp/core/logging/app_logger.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/config/recurring_expense_api_config.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';
import '../models/bulk_update_recurring_expense_request.dart';
import '../models/bulk_update_recurring_expense_response.dart';
import '../models/create_recurring_expense_request.dart';
import '../models/recurring_expense_audit_history_model.dart';
import '../models/recurring_expense_details_model.dart';
import '../models/recurring_expense_history_model.dart';
import '../models/recurring_expense_receipt_model.dart';
import '../models/recurring_expense_request_model.dart';
import '../models/recurring_expense_response_model.dart';
import '../models/update_recurring_expense_request.dart';

class RecurringExpenseApiService {
  final ApiClient _apiClient;

  RecurringExpenseApiService(this._apiClient);

  static const RecurringExpenseTaxOption _nonTaxableOption =
      RecurringExpenseTaxOption(
        id: 'non_taxable',
        label: 'Non-Taxable',
        section: RecurringExpenseTaxOption.sectionUngrouped,
      );

  static const Set<String> _ungroupedTaxLabels = <String>{
    'NON-TAXABLE',
    'NON TAXABLE',
  };

  static const Set<String> _hiddenTaxRateLabels = <String>{
    'EXEMPT',
    'OUT OF SCOPE',
    'REVERSE CHARGE',
    'ZERO RATED',
    'NON-GST SUPPLY',
    'NON GST SUPPLY',
  };

  bool _isUngroupedTaxLabel(String label) {
    return _ungroupedTaxLabels.contains(label.trim().toUpperCase());
  }

  bool _isHiddenTaxRateLabel(String label) {
    return _hiddenTaxRateLabels.contains(label.trim().toUpperCase());
  }

  bool _isGstTaxGroupLabel(String label) {
    final normalized = label.trim().toUpperCase();
    return normalized.contains('GST') &&
        !normalized.contains('IGST') &&
        !normalized.contains('CGST') &&
        !normalized.contains('SGST');
  }

  Future<RecurringExpenseResponse> getRecurringExpenses(
    RecurringExpenseRequest request,
  ) async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.basePath,
        queryParameters: request.toQueryParameters(),
        useCache: false,
      );
      return _parseResponse(response, request);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to fetch recurring expenses',
        error: error,
        stackTrace: stackTrace,
        module: 'recurring_expenses',
      );
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<RecurringExpenseDetails?> getRecurringExpenseById(String id) async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.byId(id),
      );
      final dynamic raw = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;
      if (raw is! Map<String, dynamic>) {
        return null;
      }

      return RecurringExpenseDetails.fromJson(raw);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to fetch recurring expense details',
        error: error,
        stackTrace: stackTrace,
        module: 'recurring_expenses',
      );
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<List<RecurringExpenseAuditHistoryEntry>> getRecurringExpenseHistory(
    String id,
  ) async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.history(id),
      );
      final dynamic raw = _extractRunsCollection(response.data);
      if (raw is! List) {
        return const <RecurringExpenseAuditHistoryEntry>[];
      }
      return raw
          .whereType<Map<String, dynamic>>()
          .map(RecurringExpenseAuditHistoryEntry.fromJson)
          .toList();
    } catch (error) {
      AppLogger.warning(
        'Recurring expense audit history endpoint unavailable',
        data: <String, dynamic>{'id': id, 'error': error.toString()},
        module: 'recurring_expenses',
      );
      return const <RecurringExpenseAuditHistoryEntry>[];
    }
  }

  Future<List<RecurringExpenseRun>> getRecurringExpenseRuns(String id) async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.runs(id),
      );
      final dynamic raw = _extractRunsCollection(response.data);
      if (raw is! List) {
        return const <RecurringExpenseRun>[];
      }
      return raw
          .whereType<Map<String, dynamic>>()
          .map(RecurringExpenseRun.fromJson)
          .toList();
    } catch (error) {
      AppLogger.warning(
        'Recurring expense runs endpoint unavailable',
        data: <String, dynamic>{'id': id, 'error': error.toString()},
        module: 'recurring_expenses',
      );
      return const <RecurringExpenseRun>[];
    }
  }

  Future<List<Map<String, dynamic>>> getRelatedExpenses(String id) async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.relatedExpenses(id),
      );
      final dynamic raw = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data['items'] ?? response.data)
          : response.data;
      if (raw is! List) {
        return const <Map<String, dynamic>>[];
      }
      return raw.whereType<Map<String, dynamic>>().toList();
    } catch (error) {
      AppLogger.warning(
        'Recurring expense related expenses endpoint unavailable',
        data: <String, dynamic>{'id': id, 'error': error.toString()},
        module: 'recurring_expenses',
      );
      return const <Map<String, dynamic>>[];
    }
  }

  dynamic _extractRunsCollection(dynamic data) {
    if (data is List) {
      return data;
    }
    if (data is! Map<String, dynamic>) {
      return data;
    }

    final dynamic nestedData = data['data'];
    if (nestedData is List) {
      return nestedData;
    }
    if (nestedData is Map<String, dynamic>) {
      final dynamic nestedItems =
          nestedData['items'] ?? nestedData['runs'] ?? nestedData['history'];
      if (nestedItems is List) {
        return nestedItems;
      }
    }

    final dynamic topLevelItems =
        data['items'] ?? data['runs'] ?? data['history'];
    if (topLevelItems is List) {
      return topLevelItems;
    }

    return nestedData ?? data;
  }

  Future<List<RecurringExpenseReceipt>> getReceipts(
    String recurringExpenseId,
  ) async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.receipts(recurringExpenseId),
      );
      final dynamic raw = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data['items'] ?? response.data)
          : response.data;
      if (raw is! List) {
        return const <RecurringExpenseReceipt>[];
      }
      return raw
          .whereType<Map<String, dynamic>>()
          .map(RecurringExpenseReceipt.fromJson)
          .toList();
    } catch (error) {
      AppLogger.warning(
        'Recurring expense receipts endpoint unavailable',
        data: <String, dynamic>{
          'recurringExpenseId': recurringExpenseId,
          'error': error.toString(),
        },
        module: 'recurring_expenses',
      );
      return const <RecurringExpenseReceipt>[];
    }
  }

  Future<RecurringExpenseReceipt> uploadReceipt({
    required String recurringExpenseId,
    required Object formData,
  }) async {
    try {
      final Response response = await _apiClient.post(
        RecurringExpenseApiConfig.receipts(recurringExpenseId),
        data: formData,
      );
      final dynamic raw = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;
      if (raw is! Map<String, dynamic>) {
        throw const FormatException(
          'Unexpected recurring expense receipt response shape',
        );
      }
      return RecurringExpenseReceipt.fromJson(raw);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to upload recurring expense receipt',
        error: error,
        stackTrace: stackTrace,
        module: 'recurring_expenses',
      );
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<bool> deleteReceipt({
    required String recurringExpenseId,
    required String receiptId,
  }) async {
    try {
      await _apiClient.delete(
        RecurringExpenseApiConfig.receiptById(recurringExpenseId, receiptId),
      );
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete recurring expense receipt',
        error: error,
        stackTrace: stackTrace,
        module: 'recurring_expenses',
      );
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<RecurringExpenseDetails> createRecurringExpense(
    CreateRecurringExpenseRequest request,
  ) async {
    try {
      final Response response = await _apiClient.post(
        RecurringExpenseApiConfig.basePath,
        data: request.toJson(),
      );
      return _parseDetailsResponse(response.data);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to create recurring expense',
        error: error,
        stackTrace: stackTrace,
        module: 'recurring_expenses',
      );
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<RecurringExpenseDetails?> updateRecurringExpense(
    UpdateRecurringExpenseRequest request,
  ) async {
    try {
      final Response response = await _apiClient.put(
        RecurringExpenseApiConfig.byId(request.id),
        data: request.toJson(),
      );
      return _parseDetailsResponse(response.data);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to update recurring expense',
        error: error,
        stackTrace: stackTrace,
        module: 'recurring_expenses',
      );
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<bool> deleteRecurringExpense(String id) async {
    try {
      await _apiClient.delete(RecurringExpenseApiConfig.byId(id));
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to delete recurring expense',
        error: error,
        stackTrace: stackTrace,
        module: 'recurring_expenses',
      );
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<bool> deleteRecurringExpensesBulk(List<String> ids) async {
    try {
      await _apiClient.delete(
        RecurringExpenseApiConfig.bulkDelete,
        data: <String, dynamic>{'ids': ids},
      );
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to bulk delete recurring expenses',
        error: error,
        stackTrace: stackTrace,
        module: 'recurring_expenses',
      );
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<BulkUpdateRecurringExpenseResponse> bulkUpdateRecurringExpenses(
    BulkUpdateRecurringExpenseRequest request,
  ) async {
    try {
      final Response response = await _apiClient.post(
        RecurringExpenseApiConfig.bulkUpdate,
        data: request.toJson(),
      );
      final dynamic raw = response.data is Map<String, dynamic>
          ? (response.data['data'] ?? response.data)
          : response.data;
      if (raw is! Map<String, dynamic>) {
        throw const FormatException(
          'Unexpected recurring expense bulk update response shape',
        );
      }
      return BulkUpdateRecurringExpenseResponse.fromJson(raw);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to bulk update recurring expenses',
        error: error,
        stackTrace: stackTrace,
        module: 'recurring_expenses',
      );
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<bool> stopRecurringExpense(String id) async {
    return _updateStatusAction(
      path: RecurringExpenseApiConfig.stop(id),
      action: 'stop',
    );
  }

  Future<bool> startRecurringExpense(String id) async {
    return _updateStatusAction(
      path: RecurringExpenseApiConfig.start(id),
      action: 'start',
    );
  }

  Future<bool> createExpenseFromRecurring(String id) async {
    try {
      await _apiClient.post(
        RecurringExpenseApiConfig.createExpense(id),
        data: <String, dynamic>{},
      );
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to create expense from recurring expense',
        error: error,
        stackTrace: stackTrace,
        module: 'recurring_expenses',
      );
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<List<ExpenseAccountLookupModel>> getExpenseAccounts({
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.accounts,
        queryParameters: <String, dynamic>{
          'is_active': true,
          'is_deleted': false,
          'account_group': 'Expenses',
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );
      return _normalizeListResponse(response.data)
          .map(ExpenseAccountLookupModel.fromJson)
          .map(_normalizeExpenseAccount)
          .where(_matchesExpenseAccountFilters)
          .toList();
    } catch (error) {
      AppLogger.warning(
        'Recurring expense accounts lookup unavailable',
        data: <String, dynamic>{
          'error': error.toString(),
          'search': search,
          'page': page,
          'limit': limit,
        },
        module: 'recurring_expenses',
      );
      return const <ExpenseAccountLookupModel>[];
    }
  }

  Future<List<VendorLookupModel>> getVendors({
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.vendors,
        queryParameters: <String, dynamic>{
          'is_active': true,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );
      return _normalizeListResponse(
        response.data,
      ).map(VendorLookupModel.fromJson).where(_isVendorActive).toList();
    } catch (error) {
      AppLogger.warning(
        'Recurring expense vendors lookup unavailable',
        data: <String, dynamic>{
          'error': error.toString(),
          'search': search,
          'page': page,
          'limit': limit,
        },
        module: 'recurring_expenses',
      );
      return const <VendorLookupModel>[];
    }
  }

  Future<List<CustomerLookupModel>> getCustomers({
    String? search,
    int? page,
    int? limit,
  }) async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.customers,
        queryParameters: <String, dynamic>{
          'status': 'active',
          'is_active': true,
          if (search != null && search.trim().isNotEmpty)
            'search': search.trim(),
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
        },
      );
      return _normalizeListResponse(
        response.data,
      ).map(CustomerLookupModel.fromJson).where(_isCustomerActive).toList();
    } catch (error) {
      AppLogger.warning(
        'Recurring expense customers lookup unavailable',
        data: <String, dynamic>{
          'error': error.toString(),
          'search': search,
          'page': page,
          'limit': limit,
        },
        module: 'recurring_expenses',
      );
      return const <CustomerLookupModel>[];
    }
  }

  Future<List<CurrencyLookupModel>> getCurrencies() async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.currencies,
      );
      final currencies =
          _normalizeListResponse(response.data)
              .map(CurrencyLookupModel.fromJson)
              .where((item) => item.isActive && item.code.trim().isNotEmpty)
              .toList()
            ..sort(
              (left, right) =>
                  left.name.toLowerCase().compareTo(right.name.toLowerCase()),
            );
      return currencies;
    } catch (error) {
      AppLogger.warning(
        'Recurring expense currencies lookup unavailable',
        data: <String, dynamic>{'error': error.toString()},
        module: 'recurring_expenses',
      );
      return const <CurrencyLookupModel>[];
    }
  }

  Future<List<GstTreatmentLookupModel>> getGstTreatments() async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.gstTreatments,
      );
      final treatments =
          _normalizeListResponse(response.data)
              .map(GstTreatmentLookupModel.fromJson)
              .where((item) => item.isActive && item.code.trim().isNotEmpty)
              .toList()
            ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
      return treatments;
    } catch (error) {
      AppLogger.warning(
        'Recurring expense GST treatments lookup unavailable',
        data: <String, dynamic>{'error': error.toString()},
        module: 'recurring_expenses',
      );
      return const <GstTreatmentLookupModel>[];
    }
  }

  Future<List<StateLookupModel>> getStates({String countryCode = 'IN'}) async {
    try {
      final Response response = await _apiClient.get(
        RecurringExpenseApiConfig.states(countryCode),
      );
      final states =
          _normalizeListResponse(response.data)
              .map(StateLookupModel.fromJson)
              .where((item) => item.isActive && item.name.trim().isNotEmpty)
              .toList()
            ..sort(
              (left, right) =>
                  left.name.toLowerCase().compareTo(right.name.toLowerCase()),
            );
      return states;
    } catch (error) {
      AppLogger.warning(
        'Recurring expense states lookup unavailable',
        data: <String, dynamic>{
          'error': error.toString(),
          'countryCode': countryCode,
        },
        module: 'recurring_expenses',
      );
      return const <StateLookupModel>[];
    }
  }

  Future<List<RecurringExpenseTaxOption>> getTaxes() async {
    try {
      final responses =
          await Future.wait<Response<dynamic>>(<Future<Response<dynamic>>>[
            _apiClient.get(RecurringExpenseApiConfig.taxRates),
            _apiClient.get(RecurringExpenseApiConfig.taxGroups),
          ]);

      final dynamic rawRates = responses[0].data is Map<String, dynamic>
          ? (responses[0].data['data'] ?? responses[0].data)
          : responses[0].data;
      final dynamic rawGroups = responses[1].data is Map<String, dynamic>
          ? (responses[1].data['data'] ?? responses[1].data)
          : responses[1].data;

      final List<RecurringExpenseTaxOption> ungroupedTaxes =
          <RecurringExpenseTaxOption>[];
      final List<RecurringExpenseTaxOption> taxRates =
          <RecurringExpenseTaxOption>[];
      final List<RecurringExpenseTaxOption> taxGroups =
          <RecurringExpenseTaxOption>[];

      if (rawRates is List) {
        for (final item in rawRates.whereType<Map<String, dynamic>>()) {
          final String id = (item['id'] ?? '').toString().trim();
          final String label =
              (item['tax_name'] ?? item['taxName'] ?? item['name'] ?? '')
                  .toString()
                  .trim();
          final double? rate = double.tryParse(
            (item['tax_rate'] ?? item['taxRate'] ?? '0').toString(),
          );
          final String? taxType = (item['tax_type'] ?? item['taxType'])
              ?.toString()
              .trim()
              .toUpperCase();
          if (id.isEmpty || label.isEmpty) {
            continue;
          }
          if (_isHiddenTaxRateLabel(label)) {
            continue;
          }
          final option = RecurringExpenseTaxOption(
            id: id,
            label: label,
            rate: rate,
            section: _isUngroupedTaxLabel(label)
                ? RecurringExpenseTaxOption.sectionUngrouped
                : RecurringExpenseTaxOption.sectionTaxRate,
            taxType: taxType?.isEmpty == true ? null : taxType,
          );
          if (option.isUngrouped) {
            ungroupedTaxes.add(option);
          } else {
            taxRates.add(option);
          }
        }
      }

      if (rawGroups is List) {
        for (final item in rawGroups.whereType<Map<String, dynamic>>()) {
          final String id = (item['id'] ?? '').toString().trim();
          final String label =
              (item['tax_group_name'] ??
                      item['tax_name'] ??
                      item['taxName'] ??
                      item['name'] ??
                      '')
                  .toString()
                  .trim();
          final double? rate = double.tryParse(
            (item['tax_rate'] ?? item['taxRate'] ?? '0').toString(),
          );
          if (id.isEmpty || label.isEmpty || !_isGstTaxGroupLabel(label)) {
            continue;
          }
          taxGroups.add(
            RecurringExpenseTaxOption(
              id: id,
              label: label,
              rate: rate,
              section: RecurringExpenseTaxOption.sectionTaxGroup,
            ),
          );
        }
      }

      if (!ungroupedTaxes.any(_isNonTaxableOption)) {
        ungroupedTaxes.insert(0, _nonTaxableOption);
      }

      return <RecurringExpenseTaxOption>[
        ...ungroupedTaxes,
        if (taxRates.isNotEmpty)
          const RecurringExpenseTaxOption(
            id: '__tax_header__',
            label: 'Tax',
            isHeader: true,
            section: RecurringExpenseTaxOption.sectionTaxRate,
          ),
        ...taxRates,
        if (taxGroups.isNotEmpty)
          const RecurringExpenseTaxOption(
            id: '__tax_group_header__',
            label: 'Tax Group',
            isHeader: true,
            section: RecurringExpenseTaxOption.sectionTaxGroup,
          ),
        ...taxGroups,
      ];
    } catch (error) {
      AppLogger.warning(
        'Falling back from recurring expense taxes lookup',
        data: <String, dynamic>{'error': error.toString()},
        module: 'recurring_expenses',
      );
      return const <RecurringExpenseTaxOption>[];
    }
  }

  bool _isNonTaxableOption(RecurringExpenseTaxOption option) {
    final label = option.label.trim().toUpperCase();
    return label == 'NON-TAXABLE' || label == 'NON TAXABLE';
  }

  RecurringExpenseResponse _parseResponse(
    Response response,
    RecurringExpenseRequest request,
  ) {
    final dynamic data = response.data;
    final Map<String, dynamic> normalized = <String, dynamic>{
      if (data is Map<String, dynamic>) ...data else 'data': data,
    };
    final Map<String, dynamic> extraMeta = _asMap(response.extra['meta']);
    final Map<String, dynamic> bodyMeta = _asMap(normalized['meta']);
    final Map<String, dynamic> pagination = _asMap(normalized['pagination']);

    if (bodyMeta.isEmpty && extraMeta.isNotEmpty) {
      normalized['meta'] = extraMeta;
    }
    if (pagination.isEmpty && extraMeta.isNotEmpty) {
      normalized['pagination'] = extraMeta;
    }

    final parsed = RecurringExpenseResponse.fromJson(normalized);
    final int safeLimit = parsed.limit > 0 ? parsed.limit : request.limit;
    final int safeTotalPages = parsed.totalPages > 0
        ? parsed.totalPages
        : (parsed.total > 0
              ? ((parsed.total + safeLimit - 1) ~/ safeLimit)
              : 1);

    return parsed.copyWith(
      page: parsed.page > 0 ? parsed.page : request.page,
      limit: safeLimit,
      totalPages: safeTotalPages,
    );
  }

  RecurringExpenseDetails _parseDetailsResponse(dynamic data) {
    final dynamic raw = data is Map<String, dynamic>
        ? (data['data'] ?? data)
        : data;
    if (raw is! Map<String, dynamic>) {
      throw const FormatException(
        'Unexpected recurring expense response shape',
      );
    }
    return RecurringExpenseDetails.fromJson(raw);
  }

  Future<bool> _updateStatusAction({
    required String path,
    required String action,
  }) async {
    try {
      await _apiClient.patch(path);
      return true;
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to $action recurring expense',
        error: error,
        stackTrace: stackTrace,
        module: 'recurring_expenses',
      );
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  List<Map<String, dynamic>> _normalizeListResponse(dynamic data) {
    final dynamic raw = data is Map<String, dynamic>
        ? (data['data'] ?? data['items'] ?? data['rows'] ?? data)
        : data;
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList();
    }
    return const <Map<String, dynamic>>[];
  }

  ExpenseAccountLookupModel _normalizeExpenseAccount(
    ExpenseAccountLookupModel account,
  ) {
    return account.copyWith(
      children: account.children.map(_normalizeExpenseAccount).toList(),
      systemAccountName: account.systemAccountName?.trim().isNotEmpty == true
          ? account.systemAccountName
          : account.userAccountName,
    );
  }

  bool _matchesExpenseAccountFilters(ExpenseAccountLookupModel account) {
    final normalizedGroup = (account.accountGroup ?? '').trim().toLowerCase();
    if (normalizedGroup.isNotEmpty && normalizedGroup != 'expenses') {
      return false;
    }
    return account.displayName.trim().isNotEmpty;
  }

  bool _isVendorActive(VendorLookupModel vendor) {
    return vendor.displayName.trim().isNotEmpty;
  }

  bool _isCustomerActive(CustomerLookupModel customer) {
    return customer.displayName.trim().isNotEmpty;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map(
        (key, dynamic mapValue) => MapEntry(key.toString(), mapValue),
      );
    }
    return const <String, dynamic>{};
  }
}
