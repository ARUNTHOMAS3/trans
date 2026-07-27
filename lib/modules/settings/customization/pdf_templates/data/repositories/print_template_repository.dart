// PATH: lib/modules/printing/repositories/print_template_repository.dart

import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import '../models/print_template.dart';

class PrintTemplateRepository {
  PrintTemplateRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Get all print templates
  Future<List<PrintTemplate>> getTemplates({String? type}) async {
    final response = await _apiClient.get(
      'settings-customization/print-templates',
      queryParameters: type == null ? null : {'module': type},
      useCache: false,
    );
    return (response.data as List? ?? const [])
        .whereType<Map>()
        .map((row) => _fromBackend(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Get template by ID
  Future<PrintTemplate?> getTemplateById(String templateId) async {
    return (await getTemplates())
        .where((template) => template.id == templateId)
        .firstOrNull;
  }

  /// Get default template for a type
  Future<PrintTemplate?> getDefaultTemplate(String type) async {
    return (await getTemplates(
      type: type,
    )).where((template) => template.isDefault).firstOrNull;
  }

  /// Create new template
  Future<PrintTemplate> createTemplate(PrintTemplate template) async {
    final response = await _apiClient.post(
      'settings-customization/print-templates',
      data: _toBackend(template),
    );
    return _fromBackend(Map<String, dynamic>.from(response.data as Map));
  }

  /// Update existing template
  Future<PrintTemplate> updateTemplate(PrintTemplate template) async {
    final response = await _apiClient.patch(
      'settings-customization/print-templates/${template.id}',
      data: _toBackend(template),
    );
    return _fromBackend(Map<String, dynamic>.from(response.data as Map));
  }

  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    await _apiClient.delete(
      'settings-customization/print-templates/$templateId',
    );
  }

  /// Get template variables for a type
  Future<List<String>> getTemplateVariables(String type) async {
    try {
      return _getDefaultVariablesForType(type);
    } catch (e) {
      debugPrint('Error fetching template variables: $e');
      return _getDefaultVariablesForType(type);
    }
  }

  /// Preview template with data
  Future<String> previewTemplate({
    required String templateId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final template = await getTemplateById(templateId);
      if (template == null) {
        throw Exception('Template not found');
      }

      return _processTemplate(template.content, data);
    } catch (e) {
      debugPrint('Error previewing template: $e');
      rethrow;
    }
  }

  List<String> _getDefaultVariablesForType(String type) {
    switch (type) {
      case TemplateType.invoice:
        return [
          TemplateVariables.companyName,
          TemplateVariables.companyAddress,
          TemplateVariables.documentNumber,
          TemplateVariables.documentDate,
          TemplateVariables.partyName,
          TemplateVariables.partyAddress,
          TemplateVariables.itemList,
          TemplateVariables.subtotal,
          TemplateVariables.taxAmount,
          TemplateVariables.totalAmount,
        ];
      case TemplateType.receipt:
        return [
          TemplateVariables.companyName,
          TemplateVariables.documentNumber,
          TemplateVariables.documentDate,
          TemplateVariables.partyName,
          TemplateVariables.totalAmount,
        ];
      default:
        return [
          TemplateVariables.companyName,
          TemplateVariables.documentNumber,
          TemplateVariables.documentDate,
          TemplateVariables.partyName,
          TemplateVariables.totalAmount,
        ];
    }
  }

  String _processTemplate(String templateContent, Map<String, dynamic> data) {
    var processedContent = templateContent;

    // Replace all template variables with actual data
    data.forEach((key, value) {
      final variable = '{{$key}}';
      processedContent = processedContent.replaceAll(
        variable,
        value.toString(),
      );
    });

    // Handle special cases like item lists
    if (data.containsKey('items') && data['items'] is List) {
      processedContent = _processItemList(
        processedContent,
        data['items'] as List,
      );
    }

    return processedContent;
  }

  String _processItemList(String content, List items) {
    final itemListPattern = RegExp(r'{{item_list}}');

    if (!itemListPattern.hasMatch(content)) return content;

    final itemRows = items
        .map((item) {
          return '''
        <tr>
          <td>${item['description'] ?? ''}</td>
          <td>${item['quantity'] ?? ''}</td>
          <td>${item['rate'] ?? ''}</td>
          <td>${item['amount'] ?? ''}</td>
        </tr>
      ''';
        })
        .join('\n');

    return content.replaceAll('{{item_list}}', itemRows);
  }

  PrintTemplate _fromBackend(Map<String, dynamic> row) {
    final content = row['content'] is Map
        ? Map<String, dynamic>.from(row['content'] as Map)
        : <String, dynamic>{};
    final createdAt =
        DateTime.tryParse(row['created_at']?.toString() ?? '') ??
        DateTime.now();
    return PrintTemplate(
      id: row['id']?.toString() ?? '',
      name: row['template_name']?.toString() ?? '',
      type: row['module']?.toString() ?? '',
      content: content['html']?.toString() ?? '',
      variables: content['variables'] is Map
          ? Map<String, dynamic>.from(content['variables'] as Map)
          : <String, dynamic>{},
      description: content['description']?.toString(),
      isDefault: row['is_default'] == true,
      isActive: row['is_active'] != false,
      createdBy: content['created_by']?.toString() ?? '',
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(row['updated_at']?.toString() ?? '') ?? createdAt,
    );
  }

  Map<String, dynamic> _toBackend(PrintTemplate template) => {
    'module': template.type,
    'template_name': template.name,
    'template_type': 'pdf',
    'content': {
      'html': template.content,
      'variables': template.variables,
      'description': template.description,
      'created_by': template.createdBy,
    },
    'is_default': template.isDefault,
    'is_active': template.isActive,
  };
}
