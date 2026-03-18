// PATH: lib/modules/printing/repositories/print_template_repository.dart

import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import '../models/print_template.dart';

class PrintTemplateRepository {
  PrintTemplateRepository({required ApiClient apiClient});

  /// Get all print templates
  Future<List<PrintTemplate>> getTemplates({String? type}) async {
    try {
      return [];
    } catch (e) {
      debugPrint('Error fetching templates: $e');
      return [];
    }
  }

  /// Get template by ID
  Future<PrintTemplate?> getTemplateById(String templateId) async {
    return null;
  }

  /// Get default template for a type
  Future<PrintTemplate?> getDefaultTemplate(String type) async {
    return null;
  }

  /// Create new template
  Future<PrintTemplate> createTemplate(PrintTemplate template) async {
    throw UnimplementedError('Print template backend is not implemented yet.');
  }

  /// Update existing template
  Future<PrintTemplate> updateTemplate(PrintTemplate template) async {
    throw UnimplementedError('Print template backend is not implemented yet.');
  }

  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    throw UnimplementedError('Print template backend is not implemented yet.');
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

}
