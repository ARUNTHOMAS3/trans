// PATH: lib/modules/printing/services/print_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/print_template.dart';

class PrintService {
  /// Generate HTML document from template and data
  static Future<File> generateHtml({
    required PrintTemplate template,
    required Map<String, dynamic> data,
    String? outputPath,
  }) async {
    try {
      // Process template by replacing variables with data
      final processedContent = _processTemplate(template.content, data);

      // Save to file
      final outputDir = outputPath ?? (await getTemporaryDirectory()).path;
      final fileName =
          '${template.type}_${DateTime.now().millisecondsSinceEpoch}.html';
      final file = File('$outputDir/$fileName');

      await file.writeAsString(processedContent);
      return file;
    } catch (e) {
      debugPrint('Error generating HTML: $e');
      rethrow;
    }
  }

  /// Open document in browser/webview
  static Future<void> openDocument({
    required PrintTemplate template,
    required Map<String, dynamic> data,
  }) async {
    try {
      final file = await generateHtml(template: template, data: data);

      // In a real implementation, you would:
      // - Open in webview for mobile
      // - Open in browser for web
      // - Use platform-specific printing APIs

      debugPrint('Document generated at: ${file.path}');
    } catch (e) {
      debugPrint('Error opening document: $e');
      rethrow;
    }
  }

  /// Share document
  static Future<void> shareDocument({
    required PrintTemplate template,
    required Map<String, dynamic> data,
    String? fileName,
  }) async {
    try {
      final file = await generateHtml(
        template: template,
        data: data,
        outputPath: fileName,
      );

      // In a real implementation, you would use sharing plugins
      debugPrint('Document ready for sharing: ${file.path}');
    } catch (e) {
      debugPrint('Error sharing document: $e');
      rethrow;
    }
  }

  /// Process template by replacing variables with data
  static String _processTemplate(
    String templateContent,
    Map<String, dynamic> data,
  ) {
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

  /// Process item list specifically
  static String _processItemList(String content, List items) {
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

  /// Get printable formats
  static List<String> getSupportedFormats() {
    return ['HTML'];
  }

  /// Validate template data
  static bool validateTemplateData(
    PrintTemplate template,
    Map<String, dynamic> data,
  ) {
    // Check if all required variables are present
    final requiredVariables = _extractVariables(template.content);

    for (final variable in requiredVariables) {
      if (!data.containsKey(variable) || data[variable] == null) {
        debugPrint('Missing required variable: $variable');
        return false;
      }
    }

    return true;
  }

  /// Extract variables from template content
  static List<String> _extractVariables(String content) {
    final variablePattern = RegExp(r'{{([^}]+)}}');
    final matches = variablePattern.allMatches(content);
    return matches.map((match) => match.group(1)!).toList();
  }

  /// Format currency
  static String formatCurrency(double amount, {String symbol = '₹'}) {
    return '$symbol ${amount.toStringAsFixed(2)}';
  }

  /// Format date
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    // Simple date formatting - in real implementation use intl package
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Convert number to words (Indian numbering system)
  static String numberToWords(double number) {
    // Simplified implementation
    final units = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
    ];
    final teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen',
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety',
    ];

    if (number == 0) return 'Zero';
    if (number < 0) return 'Minus ${numberToWords(-number)}';

    final intPart = number.toInt();
    final decimalPart = ((number - intPart) * 100).round();

    String result = _convertHundreds(intPart, units, teens, tens);

    if (decimalPart > 0) {
      result +=
          ' and ${_convertHundreds(decimalPart, units, teens, tens)} Paise';
    }

    return '${result.trim()} Only';
  }

  static String _convertHundreds(
    int number,
    List<String> units,
    List<String> teens,
    List<String> tens,
  ) {
    if (number == 0) return '';

    String result = '';

    if (number >= 100) {
      result += '${units[(number ~/ 100)]} Hundred ';
      number %= 100;
    }

    if (number >= 20) {
      result += '${tens[number ~/ 10]} ';
      number %= 10;
    } else if (number >= 10) {
      result += '${teens[number - 10]} ';
      number = 0;
    }

    if (number > 0) {
      result += '${units[number]} ';
    }

    return result;
  }
}
