import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:zerpai_erp/core/theme/app_theme.dart';
import 'package:zerpai_erp/shared/widgets/inputs/custom_text_field.dart';
import 'package:zerpai_erp/shared/widgets/inputs/dropdown_input.dart';

Future<void> showSalesReturnBulkUpdateDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: AppTheme.textPrimary.withValues(alpha: 0.68),
    useSafeArea: false,
    builder: (context) => const SalesReturnBulkUpdateDialog(),
  );
}

class SalesReturnBulkUpdateDialog extends StatefulWidget {
  const SalesReturnBulkUpdateDialog({super.key});

  @override
  State<SalesReturnBulkUpdateDialog> createState() =>
      _SalesReturnBulkUpdateDialogState();
}

class _SalesReturnBulkUpdateDialogState
    extends State<SalesReturnBulkUpdateDialog> {
  static const _fieldOptions = <String>[
    'Status',
    'Reference#',
    'Warehouse',
    'Customer Notes',
  ];

  static const _statusOptions = <String>[
    'Draft',
    'Approved',
    'Declined',
  ];

  final _valueController = TextEditingController();
  final _valueFocusNode = FocusNode();
  String? _selectedField;
  String? _selectedStatus;

  bool get _isTextAreaField => _selectedField == 'Customer Notes';
  bool get _isStatusField => _selectedField == 'Status';
  bool get _isDropdownField => _isStatusField;

  @override
  void dispose() {
    _valueController.dispose();
    _valueFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.zero,
      backgroundColor: AppTheme.backgroundColor,
      surfaceTintColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 18, 0),
                child: Row(
                  children: [
                    const Text(
                      'Bulk Update Sales Returns',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: Icon(
                          LucideIcons.x,
                          size: 18,
                          color: AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose a field from the dropdown and update with new information.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Field selector
                      SizedBox(
                        width: 220,
                        child: FormDropdown<String>(
                          value: _selectedField,
                          items: _fieldOptions,
                          hint: 'Select a field',
                          height: 36,
                          showSearch: false,
                          menuMaxHeight: 240,
                          fillColor: AppTheme.backgroundColor,
                          displayStringForValue: (v) => v,
                          itemBuilder: (val, isSelected, isHovered) =>
                              Container(
                            height: 36,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            alignment: Alignment.centerLeft,
                            color: isHovered ? AppTheme.primaryBlue : Colors.white,
                            child: Text(
                              val,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: isHovered
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _selectedField = value;
                              _selectedStatus = null;
                              _valueController.clear();
                            });
                            if (!_isDropdownField && !_isTextAreaField) {
                              _valueFocusNode.requestFocus();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Value input
                      Expanded(
                        child: _isStatusField
                            ? FormDropdown<String>(
                                value: _selectedStatus,
                                items: _statusOptions,
                                hint: 'Select status',
                                height: 36,
                                showSearch: false,
                                menuMaxHeight: 160,
                                fillColor: AppTheme.backgroundColor,
                                displayStringForValue: (v) => v,
                                itemBuilder: (val, isSelected, isHovered) =>
                                    Container(
                                  height: 36,
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  alignment: Alignment.centerLeft,
                                  color: isHovered
                                      ? AppTheme.primaryBlue
                                      : Colors.white,
                                  child: Text(
                                    val,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isHovered
                                          ? Colors.white
                                          : AppTheme.textPrimary,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ),
                                onChanged: (val) =>
                                    setState(() => _selectedStatus = val),
                              )
                            : _isTextAreaField
                                ? TextField(
                                    controller: _valueController,
                                    focusNode: _valueFocusNode,
                                    autofocus: true,
                                    maxLines: 5,
                                    minLines: 5,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: AppTheme.backgroundColor,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(
                                            color: AppTheme.borderColor),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(
                                            color: AppTheme.borderColor),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(4),
                                        borderSide: const BorderSide(
                                            color: AppTheme.primaryBlue),
                                      ),
                                    ),
                                  )
                                : CustomTextField(
                                    controller: _valueController,
                                    focusNode: _valueFocusNode,
                                    autoFocus: _selectedField != null,
                                    height: 36,
                                    hintText: '',
                                    fillColor: AppTheme.backgroundColor,
                                    borderRadius: BorderRadius.circular(4),
                                    textStyle: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: AppTheme.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: 'Note: ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text:
                              'All the selected sales returns will be updated with the new information and you cannot undo this action.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.borderLight),

            // Footer
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
                child: Row(
                  children: [
                    _BulkDialogBtn(
                      label: 'Update',
                      primary: true,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 10),
                    _BulkDialogBtn(
                      label: 'Cancel',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkDialogBtn extends StatefulWidget {
  const _BulkDialogBtn({
    required this.label,
    required this.onTap,
    this.primary = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_BulkDialogBtn> createState() => _BulkDialogBtnState();
}

class _BulkDialogBtnState extends State<_BulkDialogBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.primary
        ? AppTheme.accentGreen
        : _hovered
            ? AppTheme.bgLight
            : AppTheme.backgroundColor;
    final textColor =
        widget.primary ? Colors.white : AppTheme.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 34,
          padding: EdgeInsets.symmetric(
              horizontal: widget.primary ? 14 : 12),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(4),
            border: widget.primary
                ? null
                : Border.all(color: AppTheme.borderColor),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
