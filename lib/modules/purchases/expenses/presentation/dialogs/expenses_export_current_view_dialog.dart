import 'dart:convert' show utf8;
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:web/web.dart' as web;
import 'package:zerpai_erp/core/theme/app_text_styles.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/modules/purchases/expenses/models/expense_record.dart';
import 'package:zerpai_erp/shared/utils/zerpai_toast.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ExpensesCurrentViewExportColumn {
  const ExpensesCurrentViewExportColumn({
    required this.label,
    required this.valueBuilder,
  });

  final String label;
  final String Function(ExpenseRecord row) valueBuilder;
}

Future<void> showExpensesExportCurrentViewDialog(
  BuildContext context, {
  required List<ExpenseRecord> rows,
  required List<ExpensesCurrentViewExportColumn> columns,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) =>
        ExpensesExportCurrentViewDialog(rows: rows, columns: columns),
  );
}

class ExpensesExportCurrentViewDialog extends StatefulWidget {
  const ExpensesExportCurrentViewDialog({
    super.key,
    required this.rows,
    required this.columns,
  });

  final List<ExpenseRecord> rows;
  final List<ExpensesCurrentViewExportColumn> columns;

  @override
  State<ExpensesExportCurrentViewDialog> createState() =>
      _ExpensesExportCurrentViewDialogState();
}

class _ExpensesExportCurrentViewDialogState
    extends State<ExpensesExportCurrentViewDialog> {
  static const double _compactFieldHeight = 32;
  static const List<String> _decimalFormats = <String>['1234567.89'];
  static const List<String> _fileFormatOptions = <String>[
    'CSV (Comma Separated Value)',
    'XLS (Microsoft Excel 1997-2004 Compatible)',
    'XLSX (Microsoft Excel)',
  ];

  final TextEditingController _passwordController = TextEditingController();

  String _decimalFormat = _decimalFormats.first;
  String _fileFormat = _fileFormatOptions.first;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String _csvEscape(String value) {
    final normalized = value.replaceAll('"', '""');
    return '"$normalized"';
  }

  String _xmlEscape(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _buildCsv() {
    final buffer = StringBuffer()
      ..writeln(
        widget.columns.map((column) => _csvEscape(column.label)).join(','),
      );
    for (final row in widget.rows) {
      buffer.writeln(
        widget.columns
            .map((column) => _csvEscape(column.valueBuilder(row)))
            .join(','),
      );
    }
    return buffer.toString();
  }

  String _buildSpreadsheetXml() {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"',
      )
      ..writeln('  xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">')
      ..writeln('  <Worksheet ss:Name="Expenses Current View">')
      ..writeln('    <Table>');

    void stringCell(String value) {
      buffer.writeln(
        '        <Cell><Data ss:Type="String">${_xmlEscape(value)}</Data></Cell>',
      );
    }

    buffer.writeln('      <Row>');
    for (final column in widget.columns) {
      stringCell(column.label);
    }
    buffer.writeln('      </Row>');

    for (final row in widget.rows) {
      buffer.writeln('      <Row>');
      for (final column in widget.columns) {
        stringCell(column.valueBuilder(row));
      }
      buffer.writeln('      </Row>');
    }

    buffer
      ..writeln('    </Table>')
      ..writeln('  </Worksheet>')
      ..writeln('</Workbook>');
    return buffer.toString();
  }

  void _downloadFile({
    required String content,
    required String fileName,
    required String mimeType,
  }) {
    final blob = web.Blob(
      [utf8.encode(content).toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  void _submit() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final String content;
    final String fileName;
    final String mimeType;
    switch (_fileFormat) {
      case 'CSV (Comma Separated Value)':
        content = _buildCsv();
        fileName = 'expenses_current_view_$timestamp.csv';
        mimeType = 'text/csv;charset=utf-8;';
        break;
      case 'XLS (Microsoft Excel 1997-2004 Compatible)':
        content = _buildSpreadsheetXml();
        fileName = 'expenses_current_view_$timestamp.xls';
        mimeType = 'application/vnd.ms-excel';
        break;
      case 'XLSX (Microsoft Excel)':
        content = _buildSpreadsheetXml();
        fileName = 'expenses_current_view_$timestamp.xlsx';
        mimeType =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        break;
      default:
        content = _buildCsv();
        fileName = 'expenses_current_view_$timestamp.csv';
        mimeType = 'text/csv;charset=utf-8;';
    }
    _downloadFile(content: content, fileName: fileName, mimeType: mimeType);
    if (mounted) {
      Navigator.of(context).pop();
      ZerpaiToast.success(context, 'Current view export started.');
    }
  }

  Widget _buildSectionLabel(String label, {bool required = false}) {
    return Text(
      required ? '$label*' : label,
      style: required ? AppTextStyles.labelRequired : AppTextStyles.label,
    );
  }

  Widget _buildPasswordHelper() {
    return Text(
      'Your password must be at least 12 characters and include one uppercase letter, lowercase letter, number, and special character.',
      style: AppTextStyles.helper.copyWith(
        color: AppTheme.textSecondary,
        height: 1.8,
      ),
    );
  }

  Widget _buildNote() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppTheme.space4,
      runSpacing: AppTheme.space4,
      children: [
        Text(
          'Note: You can export only the first 10,000 rows. If you have more rows, please initiate a backup for the data in Zerpai, and download it.',
          style: AppTextStyles.body.copyWith(
            color: AppTheme.textSecondary,
            height: 1.7,
          ),
        ),
        ZerpaiLinkText(
          text: 'Backup Your Data',
          onTap: () {
            ZerpaiToast.info(context, 'Backup Your Data is not wired yet.');
          },
          style: AppTextStyles.body.copyWith(height: 1.7),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      backgroundColor: AppTheme.backgroundColor,
      surfaceTintColor: AppTheme.backgroundColor,
      insetPadding: const EdgeInsets.fromLTRB(
        AppTheme.space40,
        0,
        AppTheme.space40,
        AppTheme.space32,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.of(context).size.height - 48,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space20,
                AppTheme.space18,
                AppTheme.space12,
                AppTheme.space16,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Export Current View',
                      style: AppTextStyles.subtitle,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 18,
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppTheme.errorRed,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.space18,
                  AppTheme.space18,
                  AppTheme.space18,
                  AppTheme.space16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.space14,
                        vertical: AppTheme.space12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.infoBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 1),
                            child: Icon(
                              LucideIcons.info,
                              size: 14,
                              color: AppTheme.infoBlue,
                            ),
                          ),
                          const SizedBox(width: AppTheme.space8),
                          Expanded(
                            child: Text(
                              'Only the current view with its visible columns will be exported from Zerpai in CSV or XLS/XLSX format.',
                              style: AppTextStyles.body.copyWith(
                                color: AppTheme.textBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    _buildSectionLabel('Decimal Format', required: true),
                    const SizedBox(height: AppTheme.space6),
                    SizedBox(
                      width: 316,
                      child: FormDropdown<String>(
                        value: _decimalFormat,
                        items: _decimalFormats,
                        placeholder: 'Select Decimal Format',
                        height: _compactFieldHeight,
                        showSearch: false,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _decimalFormat = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    _buildSectionLabel('Export File Format', required: true),
                    const SizedBox(height: AppTheme.space6),
                    ZerpaiRadioGroup<String>(
                      options: _fileFormatOptions,
                      current: _fileFormat,
                      orientation: Axis.vertical,
                      onChanged: (value) {
                        setState(() => _fileFormat = value);
                      },
                    ),
                    const SizedBox(height: AppTheme.space16),
                    _buildSectionLabel('File Protection Password'),
                    const SizedBox(height: AppTheme.space6),
                    SizedBox(
                      width: 316,
                      child: CustomTextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        height: _compactFieldHeight,
                        suffixWidget: IconButton(
                          splashRadius: 18,
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? LucideIcons.eyeOff
                                : LucideIcons.eye,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.space6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 316),
                      child: _buildPasswordHelper(),
                    ),
                    const SizedBox(height: AppTheme.space8),
                    _buildNote(),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space20,
                AppTheme.space14,
                AppTheme.space20,
                AppTheme.space18,
              ),
              child: Row(
                children: [
                  ZButton.primary(label: 'Export', onPressed: _submit),
                  const SizedBox(width: AppTheme.space8),
                  ZButton.secondary(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
