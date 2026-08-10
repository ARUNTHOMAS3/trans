import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';
import 'package:zerpai_erp/shared/widgets/z_button.dart';

class ReportMoreFiltersPanel extends StatefulWidget {
  final VoidCallback? onRunReport;
  final VoidCallback? onCancel;
  final VoidCallback? onChanged;

  const ReportMoreFiltersPanel({
    super.key,
    this.onRunReport,
    this.onCancel,
    this.onChanged,
  });

  @override
  State<ReportMoreFiltersPanel> createState() => _ReportMoreFiltersPanelState();
}

class _ReportMoreFiltersPanelState extends State<ReportMoreFiltersPanel> {
  static const List<String> _fieldOptions = <String>[
    'Invoice Number',
    'Customer Name',
    'Status',
    'Amount',
    'Reference',
  ];

  static const List<String> _conditionOptions = <String>[
    'Equals',
    'Contains',
    'Starts With',
    'Ends With',
    'Is Empty',
  ];

  final List<_MoreFilterRowData> _rows = <_MoreFilterRowData>[
    _MoreFilterRowData(),
  ];

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    setState(() {
      _rows.add(_MoreFilterRowData());
    });
  }

  void _removeRow(int index) {
    if (_rows.length == 1) {
      _rows[index].controller.clear();
      setState(() {
        _rows[index] = _MoreFilterRowData();
      });
      return;
    }

    final row = _rows.removeAt(index);
    row.dispose();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        border: Border.all(color: AppTheme.borderLight),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.space8),
          bottomRight: Radius.circular(AppTheme.space8),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.textPrimary.withValues(alpha: 0.08),
            blurRadius: AppTheme.space20,
            offset: const Offset(0, AppTheme.space8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space24,
              AppTheme.space24,
              AppTheme.space24,
              AppTheme.space18,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < _rows.length; index++) ...[
                  _MoreFiltersRow(
                    rowNumber: index + 1,
                    data: _rows[index],
                    fieldOptions: _fieldOptions,
                    conditionOptions: _conditionOptions,
                    onAdd: _addRow,
                    onDelete: () => _removeRow(index),
                    onChanged: () {
                      widget.onChanged?.call();
                      setState(() {});
                    },
                  ),
                  if (index != _rows.length - 1)
                    const SizedBox(height: AppTheme.space14),
                ],
                const SizedBox(height: AppTheme.space16),
                InkWell(
                  onTap: _addRow,
                  borderRadius: BorderRadius.circular(AppTheme.space4),
                  hoverColor: AppTheme.bgHover,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space4,
                      vertical: AppTheme.space4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.plusCircle,
                          size: AppTheme.space16,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: AppTheme.space8),
                        Text(
                          'Add More',
                          style: AppTheme.bodyText.copyWith(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 96),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.space24,
              AppTheme.space20,
              AppTheme.space24,
              AppTheme.space20,
            ),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
            ),
            child: Row(
              children: [
                ZButton.primary(
                  label: 'Run Report',
                  onPressed: widget.onRunReport,
                ),
                const SizedBox(width: AppTheme.space10),
                ZButton.secondary(label: 'Cancel', onPressed: widget.onCancel),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreFiltersRow extends StatelessWidget {
  final int rowNumber;
  final _MoreFilterRowData data;
  final List<String> fieldOptions;
  final List<String> conditionOptions;
  final VoidCallback onAdd;
  final VoidCallback onDelete;
  final VoidCallback onChanged;

  const _MoreFiltersRow({
    required this.rowNumber,
    required this.data,
    required this.fieldOptions,
    required this.conditionOptions,
    required this.onAdd,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: AppTheme.buttonHeight,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.space8),
            border: Border.all(color: AppTheme.borderLight),
            color: AppTheme.backgroundColor,
          ),
          child: Text(
            '$rowNumber',
            style: AppTheme.bodyText.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        SizedBox(
          width: 202,
          child: FormDropdown<String>(
            value: data.field,
            items: fieldOptions,
            hint: 'Select a field',
            onChanged: (value) {
              data.field = value;
              onChanged();
            },
            showSearch: false,
            menuWidth: 202,
            itemHeight: AppTheme.buttonHeight,
            menuMaxHeight: 220,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        SizedBox(
          width: 126,
          child: FormDropdown<String>(
            value: data.condition,
            items: conditionOptions,
            hint: 'Select a condition',
            onChanged: (value) {
              data.condition = value;
              onChanged();
            },
            showSearch: false,
            menuWidth: 168,
            itemHeight: AppTheme.buttonHeight,
            menuMaxHeight: 220,
          ),
        ),
        const SizedBox(width: AppTheme.space12),
        SizedBox(
          width: 268,
          height: AppTheme.buttonHeight,
          child: TextField(
            controller: data.controller,
            onChanged: (value) {
              data.value = value;
              onChanged();
            },
            style: AppTheme.bodyText,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space10,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.space8),
                borderSide: const BorderSide(color: AppTheme.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.space8),
                borderSide: const BorderSide(color: AppTheme.primaryBlue),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space16),
        InkWell(
          onTap: onAdd,
          borderRadius: BorderRadius.circular(AppTheme.space4),
          hoverColor: AppTheme.bgHover,
          child: const Padding(
            padding: EdgeInsets.all(AppTheme.space4),
            child: Icon(
              LucideIcons.plus,
              size: AppTheme.space18,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: AppTheme.space8),
        InkWell(
          onTap: onDelete,
          borderRadius: BorderRadius.circular(AppTheme.space4),
          hoverColor: AppTheme.bgHover,
          child: const Padding(
            padding: EdgeInsets.all(AppTheme.space4),
            child: Icon(
              LucideIcons.trash2,
              size: AppTheme.space18,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _MoreFilterRowData {
  String? field;
  String? condition;
  String value;
  final TextEditingController controller;

  _MoreFilterRowData() : value = '', controller = TextEditingController();

  void dispose() {
    controller.dispose();
  }
}
