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
import 'package:zerpai_erp/shared/widgets/inputs/z_tooltip.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_date_picker.dart';
import 'package:zerpai_erp/shared/widgets/inputs/zerpai_radio_group.dart';
import 'package:zerpai_erp/shared/widgets/texts/zerpai_link_text.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

Future<void> showExpensesExportDialog(
  BuildContext context, {
  required List<ExpenseRecord> rows,
  bool exportCurrentView = false,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) =>
        ExpensesExportDialog(rows: rows, exportCurrentView: exportCurrentView),
  );
}

class ExpensesExportDialog extends StatefulWidget {
  const ExpensesExportDialog({
    super.key,
    required this.rows,
    this.exportCurrentView = false,
  });

  final List<ExpenseRecord> rows;
  final bool exportCurrentView;

  @override
  State<ExpensesExportDialog> createState() => _ExpensesExportDialogState();
}

class _ExpensesExportDialogState extends State<ExpensesExportDialog> {
  static const double _compactFieldHeight = 32;
  static const List<String> _exportHeaders = <String>[
    'Expense Date',
    'Expense Description',
    'Expense Account',
    'Expense Account Code',
    'Paid Through',
    'Paid Through Account Code',
    'Vendor',
    'Vendor Number',
    'Location Name',
    'Project Name',
    'HSN/SAC',
    'GST Treatment',
    'Destination of Supply',
    'Source of Supply',
    'GST Identification Number (GSTIN)',
    'Entry Number',
    'Currency Code',
    'Exchange Rate',
    'Is Inclusive Tax',
    'Mileage Rate',
    'Mileage Unit',
    'Distance',
    'Start Odometer Reading',
    'End Odometer Reading',
    'Mileage Type',
    'Vehicle Name',
    'Claimant Email',
    'Tax Name',
    'Tax Percentage',
    'Tax Type',
    'CGST Rate %',
    'SGST Rate %',
    'IGST Rate %',
    'CESS Rate %',
    'CGST(FCY)',
    'SGST(FCY)',
    'IGST(FCY)',
    'CESS(FCY)',
    'CGST',
    'SGST',
    'IGST',
    'CESS',
    'Item Exemption Code',
    'Tax Amount',
    'ITC Eligibility',
    'Expense Type',
    'Reverse Charge Tax Name',
    'Reverse Charge Tax Rate',
    'Reverse Charge Tax Type',
    'Expense Amount',
    'Total',
    'Supply Type',
    'Reference#',
    'Is Billable',
    'Customer Name',
    'Customer Number',
    'Expense Reference ID',
    'Recurrence Name',
    'ExpenseReport Name',
    'Is Reimbursable',
    'LINEITEM.TAG.ADGF',
    'LINEITEM.TAG.shedule',
    'LINEITEM.TAG.demo adavced reporting tag',
    'TAG.erhj',
  ];
  static const List<String> _moduleOptions = <String>['Expenses'];
  static const List<String> _decimalFormats = <String>['1234567.89'];
  static const List<String> _periodOptions = <String>[
    'All Expenses',
    'Specific Period',
  ];
  static const List<String> _filterCriteriaOptions = <String>['Expense Date'];
  static const List<String> _fileFormatOptions = <String>[
    'CSV (Comma Separated Value)',
    'XLS (Microsoft Excel 1997-2004 Compatible)',
    'XLSX (Microsoft Excel)',
  ];

  final GlobalKey _fromDateKey = GlobalKey();
  final GlobalKey _toDateKey = GlobalKey();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _module = _moduleOptions.first;
  String _period = _periodOptions.first;
  String? _exportTemplate;
  String _decimalFormat = _decimalFormats.first;
  String _fileFormat = _fileFormatOptions.first;
  String _filterCriteria = _filterCriteriaOptions.first;
  bool _includeSensitiveInfo = false;
  bool _obscurePassword = true;
  DateTime? _fromDate;
  DateTime? _toDate;

  bool get _isSpecificPeriod => _period == _periodOptions.last;
  List<ExpenseRecord> get _rowsForExport {
    final rows = widget.rows;
    if (!_isSpecificPeriod || _fromDate == null || _toDate == null) {
      return rows;
    }
    final start = DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day);
    final end = DateTime(
      _toDate!.year,
      _toDate!.month,
      _toDate!.day,
      23,
      59,
      59,
      999,
    );
    return rows
        .where((row) {
          final date = _tryParseDate(row.date);
          if (date == null) {
            return false;
          }
          return !date.isBefore(start) && !date.isAfter(end);
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({
    required GlobalKey targetKey,
    required DateTime? currentValue,
    required ValueChanged<DateTime> onSelected,
  }) async {
    final picked = await ZerpaiDatePicker.show(
      context,
      initialDate: currentValue ?? DateTime.now(),
      targetKey: targetKey,
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return '';
    }
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString().padLeft(4, '0');
    return '$day-$month-$year';
  }

  void _syncDateControllers() {
    _fromDateController.text = _formatDate(_fromDate);
    _toDateController.text = _formatDate(_toDate);
  }

  DateTime? _tryParseDate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final direct = DateTime.tryParse(trimmed);
    if (direct != null) {
      return direct;
    }
    final parts = trimmed.split('-');
    if (parts.length != 3) {
      return null;
    }
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    final third = int.tryParse(parts[2]);
    if (first == null || second == null || third == null) {
      return null;
    }
    if (first > 31) {
      return DateTime.tryParse(
        '${parts[0].padLeft(4, '0')}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}',
      );
    }
    return DateTime(third, second, first);
  }

  String _formatExportDate(String raw) {
    final date = _tryParseDate(raw);
    if (date == null) {
      return raw;
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _decimal3(double value) => value.toStringAsFixed(3);
  String _decimal6(double value) => value.toStringAsFixed(6);

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

  String _normalizeGstTreatment(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }
    return normalized
        .replaceAll(' - ', '_')
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  String _normalizeExpenseType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }
    if (normalized == 'services') {
      return 'service';
    }
    if (normalized == 'goods') {
      return 'goods';
    }
    return normalized;
  }

  String _expenseDescription(ExpenseRecord row) {
    if (row.notes.trim().isNotEmpty) {
      return row.notes.trim();
    }
    final firstItemNote = row.items
        .map((item) => item.notes?.trim() ?? '')
        .firstWhere((note) => note.isNotEmpty, orElse: () => '');
    if (firstItemNote.isNotEmpty) {
      return firstItemNote;
    }
    return '';
  }

  List<String> _buildRowValues(ExpenseRecord row) {
    final mileage = row.mileage;
    final taxName = row.gst.trim();
    final mileageType = mileage == null
        ? 'NonMileage'
        : (mileage.calculationType.trim().isEmpty
              ? 'Mileage'
              : mileage.calculationType);
    final taxType = taxName.isEmpty && row.taxAmount == 0 ? '' : 'ItemAmount';
    return <String>[
      _formatExportDate(row.date),
      _expenseDescription(row),
      row.expenseAccount,
      '',
      row.paidThrough,
      '',
      row.vendorName,
      '',
      '',
      '',
      row.hsnSacCode,
      _normalizeGstTreatment(row.gstTreatment),
      row.destinationOfSupply,
      row.sourceOfSupply,
      '',
      row.expenseNumber,
      row.currencyCode.isEmpty ? 'INR' : row.currencyCode,
      '1.00',
      (row.amountTaxMode.toUpperCase() == 'INCLUSIVE').toString(),
      mileage == null ? '0.00' : mileage.ratePerKm.toStringAsFixed(2),
      mileage?.distanceUnit ?? '',
      mileage == null ? '' : mileage.distance.toStringAsFixed(2),
      mileage?.odometerStart?.toStringAsFixed(2) ?? '',
      mileage?.odometerEnd?.toStringAsFixed(2) ?? '',
      mileageType,
      '',
      '',
      taxName,
      '',
      taxType,
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      _decimal6(row.taxAmount),
      'eligible',
      _normalizeExpenseType(row.expenseType),
      '',
      '',
      '',
      _decimal6(row.amount),
      _decimal3(row.totalAmount == 0 ? row.amount : row.totalAmount),
      '',
      row.reference,
      row.isBillable.toString(),
      row.customerName,
      '',
      row.id,
      row.recurringExpenseId,
      '',
      'false',
      '',
      '',
      '',
      '',
    ];
  }

  String _buildCsv(List<ExpenseRecord> rows) {
    final buffer = StringBuffer()
      ..writeln(_exportHeaders.map(_csvEscape).join(','));
    for (final row in rows) {
      buffer.writeln(_buildRowValues(row).map(_csvEscape).join(','));
    }
    return buffer.toString();
  }

  String _buildSpreadsheetXml(List<ExpenseRecord> rows) {
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln(
        '<Workbook xmlns="urn:schemas-microsoft-com:office:spreadsheet"',
      )
      ..writeln('  xmlns:ss="urn:schemas-microsoft-com:office:spreadsheet">')
      ..writeln('  <Worksheet ss:Name="Expenses">')
      ..writeln('    <Table>');

    void stringCell(String value) {
      buffer.writeln(
        '        <Cell><Data ss:Type="String">${_xmlEscape(value)}</Data></Cell>',
      );
    }

    buffer.writeln('      <Row>');
    for (final header in _exportHeaders) {
      stringCell(header);
    }
    buffer.writeln('      </Row>');

    for (final row in rows) {
      buffer.writeln('      <Row>');
      for (final value in _buildRowValues(row)) {
        stringCell(value);
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
    if (_isSpecificPeriod) {
      if (_fromDate == null || _toDate == null) {
        ZerpaiToast.error(context, 'Please select both From Date and To Date');
        return;
      }
      if (_toDate!.isBefore(_fromDate!)) {
        ZerpaiToast.error(context, 'To Date cannot be earlier than From Date');
        return;
      }
    }
    final rows = _rowsForExport;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final String content;
    final String fileName;
    final String mimeType;
    switch (_fileFormat) {
      case 'CSV (Comma Separated Value)':
        content = _buildCsv(rows);
        fileName = 'expenses_$timestamp.csv';
        mimeType = 'text/csv;charset=utf-8;';
        break;
      case 'XLS (Microsoft Excel 1997-2004 Compatible)':
        content = _buildSpreadsheetXml(rows);
        fileName = 'expenses_$timestamp.xls';
        mimeType = 'application/vnd.ms-excel';
        break;
      case 'XLSX (Microsoft Excel)':
        content = _buildSpreadsheetXml(rows);
        fileName = 'expenses_$timestamp.xlsx';
        mimeType =
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        break;
      default:
        content = _buildCsv(rows);
        fileName = 'expenses_$timestamp.csv';
        mimeType = 'text/csv;charset=utf-8;';
    }
    _downloadFile(content: content, fileName: fileName, mimeType: mimeType);
    if (mounted) {
      Navigator.of(context).pop();
      ZerpaiToast.success(
        context,
        widget.exportCurrentView
            ? 'Expense export for the current view started.'
            : 'Expense export started.',
      );
    }
  }

  Widget _buildSectionLabel(
    String label, {
    bool required = false,
    Widget? trailing,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          required ? '$label*' : label,
          style: required ? AppTextStyles.labelRequired : AppTextStyles.label,
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppTheme.space4),
          trailing,
        ],
      ],
    );
  }

  Widget _buildDateField({
    required GlobalKey targetKey,
    required TextEditingController controller,
    required String hintText,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      key: targetKey,
      child: InkWell(
        onTap: onTap,
        child: IgnorePointer(
          child: CustomTextField(
            controller: controller,
            hintText: hintText,
            height: _compactFieldHeight,
            readOnly: true,
            suffixWidget: const Icon(
              LucideIcons.calendar,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
          ),
          child: Checkbox(
            value: _includeSensitiveInfo,
            onChanged: (value) {
              setState(() => _includeSensitiveInfo = value ?? false);
            },
            activeColor: AppTheme.primaryBlueDark,
            side: const BorderSide(color: AppTheme.textSubtle, width: 1),
          ),
        ),
        const SizedBox(width: AppTheme.space8),
        Expanded(
          child: Text(
            'Include Sensitive Personally Identifiable Information (PII) while exporting.',
            style: AppTextStyles.body.copyWith(color: AppTheme.textPrimary),
          ),
        ),
      ],
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
          'Note: You can export only the first 25,000 rows. If you have more rows, please initiate a backup for the data in Zerpai, and download it.',
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
    _syncDateControllers();
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
                      'Export Expenses',
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
                              'You can export your data from Zerpai in CSV, XLS or XLSX format.',
                              style: AppTextStyles.body.copyWith(
                                color: AppTheme.textBody,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    _buildSectionLabel('Module', required: true),
                    const SizedBox(height: AppTheme.space6),
                    SizedBox(
                      width: 316,
                      child: FormDropdown<String>(
                        value: _module,
                        items: _moduleOptions,
                        placeholder: 'Expenses',
                        height: _compactFieldHeight,
                        showSearch: false,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _module = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    const SizedBox(height: AppTheme.space12),
                    ZerpaiRadioGroup<String>(
                      options: _periodOptions,
                      current: _period,
                      orientation: Axis.vertical,
                      onChanged: (value) {
                        setState(() {
                          _period = value;
                          if (!_isSpecificPeriod) {
                            _fromDate = null;
                            _toDate = null;
                          }
                          _syncDateControllers();
                        });
                      },
                    ),
                    if (_isSpecificPeriod) ...[
                      const SizedBox(height: AppTheme.space6),
                      SizedBox(
                        width: 316,
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildDateField(
                                targetKey: _fromDateKey,
                                controller: _fromDateController,
                                hintText: 'dd-MM-yyyy',
                                onTap: () {
                                  _pickDate(
                                    targetKey: _fromDateKey,
                                    currentValue: _fromDate,
                                    onSelected: (date) {
                                      setState(() {
                                        _fromDate = date;
                                        _syncDateControllers();
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Text(
                              '-',
                              style: AppTextStyles.body.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(width: AppTheme.space12),
                            Expanded(
                              child: _buildDateField(
                                targetKey: _toDateKey,
                                controller: _toDateController,
                                hintText: 'dd-MM-yyyy',
                                onTap: () {
                                  _pickDate(
                                    targetKey: _toDateKey,
                                    currentValue: _toDate ?? _fromDate,
                                    onSelected: (date) {
                                      setState(() {
                                        _toDate = date;
                                        _syncDateControllers();
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.space12),
                      _buildSectionLabel('Filter Criteria', required: true),
                      const SizedBox(height: AppTheme.space6),
                      ZerpaiRadioGroup<String>(
                        options: _filterCriteriaOptions,
                        current: _filterCriteria,
                        orientation: Axis.vertical,
                        onChanged: (value) {
                          setState(() => _filterCriteria = value);
                        },
                      ),
                    ],
                    const SizedBox(height: AppTheme.space16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildSectionLabel('Export Template'),
                        const SizedBox(width: AppTheme.space4),
                        const ZTooltip(
                          message:
                              'Choose a saved export template if one is available.',
                          direction: ZTooltipDirection.bottom,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.space6),
                    SizedBox(
                      width: 316,
                      child: FormDropdown<String>(
                        value: _exportTemplate,
                        items: const <String>[],
                        placeholder: 'Select an Export Template',
                        height: _compactFieldHeight,
                        showSearch: false,
                        onChanged: (value) {
                          setState(() => _exportTemplate = value);
                        },
                      ),
                    ),
                    const SizedBox(height: AppTheme.space16),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    const SizedBox(height: AppTheme.space12),
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
                    const SizedBox(height: AppTheme.space6),
                    _buildCheckboxRow(),
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
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
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
