import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import 'package:zerpai_erp/core/utils/error_handler.dart';
import 'package:zerpai_erp/modules/purchases/expenses/config/expenses_api_config.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_attachment_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_employee_option.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_history_entry_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_journal_entry_model.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_record.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_request_models.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expenses_list_query.dart';
import 'package:zerpai_erp/modules/purchases/recurring_expences/presentation/models/recurring_expense_lookup_models.dart';

class ExpensesListResponse {
  const ExpensesListResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  final List<ExpenseRecord> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;
}

class ExpensesApiService {
  ExpensesApiService(this._apiClient);

  final ApiClient _apiClient;

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

  Future<ExpensesListResponse> getExpenses(ExpensesListQuery query) async {
    try {
      final Response response = await _apiClient.get(
        ExpensesApiConfig.basePath,
        queryParameters: query.toQueryParameters(),
        useCache: false,
      );
      final data = _asMap(response.data);
      final rawItems = _unwrapList(response.data);
      final extraMeta = _asMap(response.extra['meta']);
      final pagination = _asMap(data['pagination']);
      final bodyMeta = _asMap(data['meta']);

      final resolvedPage = _asInt(
        extraMeta['page'] ?? bodyMeta['page'] ?? pagination['page'],
        fallback: query.page,
      );
      final resolvedLimit = _asInt(
        extraMeta['limit'] ?? bodyMeta['limit'] ?? pagination['limit'],
        fallback: query.limit,
      );
      final resolvedTotal = _asInt(
        extraMeta['total'] ??
            extraMeta['count'] ??
            bodyMeta['total'] ??
            bodyMeta['count'] ??
            data['total'] ??
            data['count'] ??
            pagination['total'],
        fallback: rawItems.length,
      );
      final resolvedTotalPagesRaw = _asInt(
        extraMeta['totalPages'] ??
            extraMeta['total_pages'] ??
            bodyMeta['totalPages'] ??
            bodyMeta['total_pages'] ??
            pagination['totalPages'] ??
            pagination['total_pages'],
      );
      final computedTotalPages = resolvedLimit > 0
          ? ((resolvedTotal + resolvedLimit - 1) ~/ resolvedLimit)
          : 1;
      final parsedTotalPages = resolvedTotalPagesRaw > 0
          ? resolvedTotalPagesRaw
          : (computedTotalPages > 0 ? computedTotalPages : 1);

      return ExpensesListResponse(
        items: rawItems.map(ExpenseRecord.fromJson).toList(growable: false),
        total: resolvedTotal,
        page: resolvedPage,
        limit: resolvedLimit,
        totalPages: parsedTotalPages,
      );
    } catch (error) {
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<ExpenseRecord?> getExpenseById(String id) async {
    try {
      final Response response = await _apiClient.get(
        ExpensesApiConfig.detail(id),
      );
      final rawRecord = _unwrapDataMap(response.data);
      return ExpenseRecord.fromJson(rawRecord);
    } catch (error) {
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<List<ExpenseHistoryEntryModel>> getExpenseHistory(String id) async {
    try {
      final Response response = await _apiClient.get(
        ExpensesApiConfig.history(id),
      );
      final raw = _unwrapList(response.data);
      return raw.map(ExpenseHistoryEntryModel.fromJson).toList(growable: false);
    } catch (error) {
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<List<ExpenseJournalEntryModel>> getExpenseJournal(String id) async {
    try {
      final Response response = await _apiClient.get(
        ExpensesApiConfig.journal(id),
      );
      final raw = _unwrapList(response.data);
      return raw.map(ExpenseJournalEntryModel.fromJson).toList(growable: false);
    } catch (error) {
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<List<ExpenseAttachmentModel>> getExpenseAttachments(String id) async {
    try {
      final Response response = await _apiClient.get(
        ExpensesApiConfig.attachments(id),
      );
      final raw = _unwrapList(response.data);
      return raw.map(ExpenseAttachmentModel.fromJson).toList(growable: false);
    } catch (error) {
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<List<RecurringExpenseTaxOption>> getTaxRates() async {
    try {
      final responses =
          await Future.wait<Response<dynamic>>(<Future<Response<dynamic>>>[
            _apiClient.get(ExpensesApiConfig.taxRates),
            _apiClient.get(ExpensesApiConfig.taxGroups),
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
                      item['taxGroupName'] ??
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
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<List<ExpenseEmployeeOption>> getEmployees() async {
    try {
      final Response response = await _apiClient.get(
        ExpensesApiConfig.employees,
      );
      final raw = _unwrapList(response.data);
      return raw.map(ExpenseEmployeeOption.fromJson).toList(growable: false);
    } catch (error) {
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  bool _isNonTaxableOption(RecurringExpenseTaxOption option) {
    final label = option.label.trim().toUpperCase();
    return label == 'NON-TAXABLE' || label == 'NON TAXABLE';
  }

  Future<ExpenseRecord> createExpense(UpsertExpenseRequest request) async {
    try {
      final payload = request.toJson();
      final Response response = await _apiClient.post(
        ExpensesApiConfig.basePath,
        data: payload,
      );
      return ExpenseRecord.fromJson(_unwrapDataMap(response.data));
    } catch (error) {
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<ExpenseRecord?> updateExpense(UpdateExpenseRequest request) async {
    try {
      final payload = request.expense.toJson();
      final Response response = await _apiClient.put(
        ExpensesApiConfig.detail(request.id),
        data: payload,
      );
      return ExpenseRecord.fromJson(_unwrapDataMap(response.data));
    } catch (error) {
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      await _apiClient.delete(ExpensesApiConfig.detail(id));
      return true;
    } catch (error) {
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<ExpenseAttachmentModel> addAttachmentMetadata({
    required String expenseId,
    required ExpenseAttachmentModel attachment,
  }) async {
    try {
      final Response response = await _apiClient.post(
        ExpensesApiConfig.attachments(expenseId),
        data: attachment.toAttachmentRequestJson(),
      );
      return ExpenseAttachmentModel.fromJson(_unwrapDataMap(response.data));
    } catch (error) {
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<bool> deleteAttachment({
    required String expenseId,
    required String attachmentId,
  }) async {
    try {
      await _apiClient.delete(
        ExpensesApiConfig.attachmentById(expenseId, attachmentId),
      );
      return true;
    } catch (error) {
      throw Exception(ErrorHandler.getFriendlyMessage(error));
    }
  }

  Future<List<ExpenseAttachmentModel>> uploadReceiptFiles({
    required String expenseId,
    required List<PlatformFile> files,
  }) async {
    final uploaded = <ExpenseAttachmentModel>[];
    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        continue;
      }

      final Response uploadResponse = await _apiClient.post(
        ExpensesApiConfig.uploadLookup,
        data: <String, dynamic>{
          'fileName': file.name,
          'fileData': base64Encode(bytes),
          'mimeType': _mimeTypeForFileName(file.name),
          'prefix': 'expenses',
        },
      );
      final uploadData = _asMap(uploadResponse.data);
      final fileUrl =
          (uploadData['fileUrl'] ??
                  uploadData['file_url'] ??
                  uploadData['fileKey'] ??
                  uploadData['path'] ??
                  '')
              .toString();
      if (fileUrl.isEmpty) {
        throw Exception('Failed to upload receipt ${file.name}.');
      }

      uploaded.add(
        await addAttachmentMetadata(
          expenseId: expenseId,
          attachment: ExpenseAttachmentModel(
            id: '',
            expenseId: expenseId,
            fileName: file.name,
            fileUrl: fileUrl,
            fileSize: file.size,
            fileType: file.extension,
            originalFileName: file.name,
          ),
        ),
      );
    }
    return uploaded;
  }

  String _mimeTypeForFileName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'application/octet-stream';
  }

  Map<String, dynamic> _unwrapDataMap(dynamic data) {
    final map = _asMap(data);
    final raw = map['data'] ?? map;
    return _asMap(raw);
  }

  List<Map<String, dynamic>> _unwrapList(dynamic data) {
    final raw = data is Map<String, dynamic>
        ? (data['data'] ?? data['items'] ?? data['rows'] ?? const [])
        : data;
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return <String, dynamic>{};
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }
}
