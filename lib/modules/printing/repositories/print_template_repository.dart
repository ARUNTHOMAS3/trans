// PATH: lib/modules/printing/repositories/print_template_repository.dart

import 'package:flutter/foundation.dart';
import 'package:zerpai_erp/core/services/api_client.dart';
import '../models/print_template.dart';

class PrintTemplateRepository {
  PrintTemplateRepository({required ApiClient apiClient});

  /// Get all print templates
  Future<List<PrintTemplate>> getTemplates({String? type}) async {
    try {
      // Return mock data since we're in build phase
      return _getDefaultTemplates();
    } catch (e) {
      debugPrint('Error fetching templates: $e');
      return _getDefaultTemplates();
    }
  }

  /// Get template by ID
  Future<PrintTemplate?> getTemplateById(String templateId) async {
    try {
      final templates = _getDefaultTemplates();
      return templates.firstWhere((template) => template.id == templateId);
    } catch (e) {
      debugPrint('Error fetching template: $e');
      return null;
    }
  }

  /// Get default template for a type
  Future<PrintTemplate?> getDefaultTemplate(String type) async {
    try {
      final templates = _getDefaultTemplates();
      return templates.firstWhere(
        (template) => template.type == type && template.isDefault,
      );
    } catch (e) {
      debugPrint('Error fetching default template: $e');
      return _getDefaultTemplateForType(type);
    }
  }

  /// Create new template
  Future<PrintTemplate> createTemplate(PrintTemplate template) async {
    try {
      // In build phase, just return the template
      return template;
    } catch (e) {
      debugPrint('Error creating template: $e');
      rethrow;
    }
  }

  /// Update existing template
  Future<PrintTemplate> updateTemplate(PrintTemplate template) async {
    try {
      // In build phase, just return the template
      return template;
    } catch (e) {
      debugPrint('Error updating template: $e');
      rethrow;
    }
  }

  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    try {
      // In build phase, just simulate success
      debugPrint('Template $templateId deleted');
    } catch (e) {
      debugPrint('Error deleting template: $e');
      rethrow;
    }
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

  /// Private methods for default data
  List<PrintTemplate> _getDefaultTemplates() {
    return [
      PrintTemplate(
        id: 'default_invoice',
        name: 'Default Invoice Template',
        type: TemplateType.invoice,
        content: _getDefaultInvoiceTemplate(),
        variables: {
          'company_name': 'Your Company Name',
          'company_address': 'Company Address',
          'document_number': 'INV-001',
          'document_date': DateTime.now().toString(),
          'party_name': 'Customer Name',
          'item_list': '[Items will be populated here]',
          'total_amount': '0.00',
        },
        description:
            'Standard invoice template with company header and itemized billing',
        isDefault: true,
        isActive: true,
        createdBy: 'system',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      PrintTemplate(
        id: 'default_receipt',
        name: 'Default Receipt Template',
        type: TemplateType.receipt,
        content: _getDefaultReceiptTemplate(),
        variables: {
          'company_name': 'Your Company Name',
          'document_number': 'RCPT-001',
          'document_date': DateTime.now().toString(),
          'party_name': 'Customer Name',
          'total_amount': '0.00',
        },
        description: 'Simple receipt template for payment acknowledgment',
        isDefault: true,
        isActive: true,
        createdBy: 'system',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }

  PrintTemplate? _getDefaultTemplateForType(String type) {
    final templates = _getDefaultTemplates();
    try {
      return templates.firstWhere((template) => template.type == type);
    } catch (e) {
      return null;
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

  String _getDefaultInvoiceTemplate() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; margin-bottom: 30px; }
        .company-name { font-size: 24px; font-weight: bold; }
        .document-info { margin: 20px 0; }
        .party-info { margin: 20px 0; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .total-row { font-weight: bold; }
        .footer { margin-top: 30px; text-align: center; }
    </style>
</head>
<body>
    <div class="header">
        <div class="company-name">{{company_name}}</div>
        <div>{{company_address}}</div>
    </div>
    
    <div class="document-info">
        <h2>INVOICE</h2>
        <p>Invoice #: {{document_number}}</p>
        <p>Date: {{document_date}}</p>
    </div>
    
    <div class="party-info">
        <h3>Bill To:</h3>
        <p>{{party_name}}</p>
        <p>{{party_address}}</p>
    </div>
    
    <table>
        <thead>
            <tr>
                <th>Description</th>
                <th>Quantity</th>
                <th>Rate</th>
                <th>Amount</th>
            </tr>
        </thead>
        <tbody>
            {{item_list}}
        </tbody>
        <tfoot>
            <tr class="total-row">
                <td colspan="3">Total</td>
                <td>{{total_amount}}</td>
            </tr>
        </tfoot>
    </table>
    
    <div class="footer">
        <p>Thank you for your business!</p>
    </div>
</body>
</html>
''';
  }

  String _getDefaultReceiptTemplate() {
    return '''
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; text-align: center; }
        .header { margin-bottom: 30px; }
        .company-name { font-size: 20px; font-weight: bold; }
        .receipt-title { font-size: 24px; margin: 20px 0; }
        .details { margin: 20px 0; text-align: left; display: inline-block; }
        .amount-box { 
            border: 2px solid #000; 
            padding: 20px; 
            margin: 20px 0; 
            display: inline-block;
        }
        .amount { font-size: 20px; font-weight: bold; }
        .signature { margin-top: 40px; text-align: right; }
    </style>
</head>
<body>
    <div class="header">
        <div class="company-name">{{company_name}}</div>
    </div>
    
    <div class="receipt-title">PAYMENT RECEIPT</div>
    
    <div class="details">
        <p>Receipt #: {{document_number}}</p>
        <p>Date: {{document_date}}</p>
        <p>Received From: {{party_name}}</p>
    </div>
    
    <div class="amount-box">
        <div>AMOUNT RECEIVED</div>
        <div class="amount">{{currency_symbol}} {{total_amount}}</div>
    </div>
    
    <div class="signature">
        <p>Authorized Signature: ____________________</p>
    </div>
</body>
</html>
''';
  }
}
